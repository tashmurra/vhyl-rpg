#!/usr/bin/env python3
"""Build a committed release source package, offline reference and checksums."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
NUMBER = r'(?:0|[1-9][0-9]*)'
RELEASE = re.compile(rf'{NUMBER}\.{NUMBER}\.{NUMBER}(?:-(?:alpha|beta|rc)\.{NUMBER})?')


def validate_version(version: str) -> str:
    if not RELEASE.fullmatch(version):
        raise ValueError('VERSION must be X.Y.Z or X.Y.Z-(alpha|beta|rc).N')
    return version


def git(*args: str, root: Path = ROOT, quiet: bool = False) -> bytes:
    return subprocess.check_output(['git', *args], cwd=root,
                                   stderr=subprocess.DEVNULL if quiet else None)


def release_identity(root: Path = ROOT) -> tuple[str, str, int]:
    if git('status', '--porcelain', root=root).strip():
        raise ValueError('release builds require a clean committed checkout')
    version = validate_version((root / 'VERSION').read_text(encoding='utf-8').strip())
    revision = git('rev-parse', 'HEAD', root=root).decode().strip()
    committed = git('show', f'{revision}:VERSION', root=root).decode().strip()
    if version != committed:
        raise ValueError('VERSION does not match the committed source')
    epoch = int(git('show', '-s', '--format=%ct', revision, root=root))
    return version, revision, epoch


def source_archive(path: Path, revision: str, prefix: str, epoch: int, root: Path = ROOT) -> None:
    """Use Git's tracked snapshot; local dependencies and bundles cannot enter it."""
    archive = git('-c', 'core.autocrlf=false', 'archive', '--format=tar',
                  f'--prefix={prefix}/', revision, root=root)
    with path.open('wb') as output:
        with gzip.GzipFile(filename='', fileobj=output, mode='wb', mtime=epoch) as compressed:
            compressed.write(archive)


def docs_archive(path: Path, site: Path, prefix: str, epoch: int) -> None:
    if not (site / 'index.html').is_file() or not (site / 'search/search_index.json').is_file():
        raise ValueError('documentation build is missing its index or search data')
    with path.open('wb') as output:
        with gzip.GzipFile(filename='', fileobj=output, mode='wb', mtime=epoch) as compressed:
            with tarfile.open(fileobj=compressed, mode='w') as archive:
                for file in sorted(site.rglob('*')):
                    if not file.is_file():
                        continue
                    data = file.read_bytes()
                    info = tarfile.TarInfo(f'{prefix}/{file.relative_to(site).as_posix()}')
                    info.size, info.mtime, info.mode = len(data), epoch, 0o644
                    archive.addfile(info, io.BytesIO(data))


def checksums(directory: Path) -> None:
    lines = []
    for file in sorted(directory.iterdir()):
        if file.is_file() and file.name != 'SHA256SUMS':
            lines.append(f'{hashlib.sha256(file.read_bytes()).hexdigest()}  {file.name}\n')
    (directory / 'SHA256SUMS').write_text(''.join(lines), encoding='utf-8')


def build(out: Path) -> None:
    version, revision, epoch = release_identity()
    tag = 'v' + version
    if not (ROOT / f'docs/releases/{tag}.md').is_file():
        raise ValueError(f'missing release notes for {tag}')
    out = out.resolve()
    if out.exists():
        raise ValueError(f'output directory must be new: {out}')
    subprocess.run([sys.executable, str(ROOT / 'tools/build_docs.py'), '--revision', revision],
                   cwd=ROOT, check=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.release-', dir=out.parent) as directory:
        stage = Path(directory) / 'packages'
        stage.mkdir()
        name = f'vhyl-rpg-{tag}'
        source_archive(stage / f'{name}.tar.gz', revision, name, epoch)
        docs_archive(stage / f'{name}-docs.tar.gz', ROOT / 'build/site', name + '-docs', epoch)
        manifest = {
            'schema_version': 2,
            'version': version,
            'tag': tag,
            'revision': revision,
            'tree': git('rev-parse', f'{revision}^{{tree}}').decode().strip(),
            'commit_time': datetime.fromtimestamp(epoch, timezone.utc).isoformat(),
            'dependencies': json.loads((ROOT / 'dependencies.json').read_text(encoding='utf-8')),
            'artifacts': sorted(file.name for file in stage.iterdir()),
        }
        (stage / 'release-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
        checksums(stage)
        stage.rename(out)
    print(f'Built {tag} from {revision}: {out}', flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, default=ROOT / 'build/release', help='new output directory')
    build(parser.parse_args().out)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f'vhyl-rpg release: {error}', file=sys.stderr)
        raise SystemExit(1)
