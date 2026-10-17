#!/usr/bin/env python3
"""Reuse validated builds only when their tracked source tree matches exactly."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile

from build_release import ROOT, git, validate_version

NATIVE_JOBS = {f'Native checks ({platform})' for platform in
               ('ubuntu-24.04', 'windows-2025', 'macos-15')}
REQUIRED_JOBS = NATIVE_JOBS | {'Source and documentation packages'}


def api(endpoint: str):
    return json.loads(subprocess.check_output(['gh', 'api', endpoint], text=True))


def validated_run(run: dict, jobs: list[dict], repository: str) -> bool:
    if (run.get('conclusion') != 'success'
            or run.get('path') != '.github/workflows/release.yml'
            or run.get('head_repository', {}).get('full_name') != repository
            or not re.fullmatch(r'[0-9a-f]{40}', run.get('head_sha', ''))):
        return False
    if run.get('event') != 'pull_request' and not (
            run.get('event') in ('push', 'workflow_dispatch') and run.get('head_branch') == 'main'):
        return False
    passed = {job['name'] for job in jobs if job.get('conclusion') == 'success'}
    return REQUIRED_JOBS <= passed


def select_run(repository: str, *, root: Path = ROOT, fetch=api):
    """Use server-reported job results, repository identity and Git tree objects.

    Reused main runs skip native jobs and cannot manufacture fresh validation.
    Fork runs, expired artifacts and unmatched source trees require a new build.
    """
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise ValueError('invalid repository')
    tree = git('rev-parse', 'HEAD^{tree}', root=root).decode().strip()
    base = f'repos/{repository}'
    runs = fetch(base + '/actions/workflows/release.yml/runs?status=success&per_page=100')['workflow_runs']
    for run in runs:
        revision = run.get('head_sha', '')
        if not re.fullmatch(r'[0-9a-f]{40}', revision):
            continue
        try:
            candidate = git('rev-parse', f'{revision}^{{tree}}', root=root, quiet=True).decode().strip()
        except subprocess.CalledProcessError:
            continue
        if candidate != tree:
            continue
        jobs = fetch(base + f'/actions/runs/{run["id"]}/jobs?filter=latest&per_page=100')['jobs']
        if not validated_run(run, jobs, repository):
            continue
        if run['event'] == 'pull_request':
            pulls = fetch(base + f'/commits/{revision}/pulls?per_page=100')
            if not any(p.get('merged_at') and p.get('head', {}).get('sha') == revision
                       and p.get('base', {}).get('ref') == 'main'
                       and p.get('base', {}).get('repo', {}).get('full_name') == repository for p in pulls):
                continue
        artifacts = fetch(base + f'/actions/runs/{run["id"]}/artifacts?per_page=100')['artifacts']
        available = [a for a in artifacts if a['name'] == 'release-packages' and not a['expired']]
        if len(available) == 1:
            return run
    return None


def tar_files(archive: tarfile.TarFile) -> dict[str, bytes]:
    result = {}
    for member in archive.getmembers():
        if member.isdir():
            continue
        path = member.name
        if (not member.isfile() or path.startswith('/') or '..' in Path(path).parts
                or '\\' in path or path in result):
            raise ValueError(f'unsafe or duplicate archive member: {path}')
        result[path] = archive.extractfile(member).read()
    return result


def verify_packages(directory: Path, *, root: Path = ROOT) -> dict:
    version = validate_version((root / 'VERSION').read_text(encoding='utf-8').strip())
    name = f'vhyl-rpg-v{version}'
    names = {name + '.tar.gz', name + '-docs.tar.gz', 'release-manifest.json', 'SHA256SUMS'}
    if {p.name for p in directory.iterdir()} != names:
        raise ValueError('unexpected or missing release assets')
    rows = (directory / 'SHA256SUMS').read_text(encoding='utf-8').splitlines()
    covered = set()
    for row in rows:
        digest, filename = row.split('  ')
        if filename not in names - {'SHA256SUMS'} or filename in covered:
            raise ValueError('invalid checksum entry')
        covered.add(filename)
        if hashlib.sha256((directory / filename).read_bytes()).hexdigest() != digest:
            raise ValueError(f'checksum mismatch: {filename}')
    if covered != names - {'SHA256SUMS'}:
        raise ValueError('incomplete checksums')
    manifest = json.loads((directory / 'release-manifest.json').read_text(encoding='utf-8'))
    revision = manifest.get('revision', '')
    if not re.fullmatch(r'[0-9a-f]{40}', revision):
        raise ValueError('invalid build revision')
    tree = git('rev-parse', 'HEAD^{tree}', root=root).decode().strip()
    source_tree = git('rev-parse', f'{revision}^{{tree}}', root=root).decode().strip()
    if (manifest.get('schema_version') != 2 or manifest.get('tree') != tree or source_tree != tree
            or manifest.get('version') != version or manifest.get('tag') != 'v' + version
            or manifest.get('dependencies') != json.loads((root / 'dependencies.json').read_text(encoding='utf-8'))):
        raise ValueError('release manifest does not match the target source tree')
    expected = git('-c', 'core.autocrlf=false', 'archive', '--format=tar',
                   f'--prefix={name}/', 'HEAD', root=root)
    with tarfile.open(fileobj=io.BytesIO(expected)) as archive:
        tracked = tar_files(archive)
    with tarfile.open(directory / (name + '.tar.gz')) as archive:
        source = tar_files(archive)
    if source != tracked:
        raise ValueError('source archive differs from the target Git tree')
    with tarfile.open(directory / (name + '-docs.tar.gz')) as archive:
        docs = tar_files(archive)
    prefix = name + '-docs/'
    if (prefix + 'index.html' not in docs or prefix + 'search/search_index.json' not in docs
            or revision.encode() not in docs.get(prefix + 'reference/index.html', b'')):
        raise ValueError('offline reference does not identify the validated source')
    return manifest


def attest(directory: Path, repository: str, run_id: str, *, root: Path = ROOT) -> None:
    manifest = verify_packages(directory, root=root)
    if (not re.fullmatch(r'[0-9]+', run_id)
            or not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository)):
        raise ValueError('invalid validation run identity')
    provenance = {
        'schema_version': 1,
        'tag': manifest['tag'],
        'release_revision': git('rev-parse', 'HEAD', root=root).decode().strip(),
        'build_revision': manifest['revision'],
        'tree': manifest['tree'],
        'validation_run': f'https://github.com/{repository}/actions/runs/{run_id}',
        'assets': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(directory.iterdir())},
    }
    (directory / 'release-provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('select', 'verify', 'attest'))
    parser.add_argument('--directory', type=Path, default=ROOT / 'build/release')
    parser.add_argument('--repository', default=os.environ.get('GITHUB_REPOSITORY', 'tashmurra/vhyl-rpg'))
    parser.add_argument('--run-id', default=os.environ.get('GITHUB_RUN_ID', ''))
    args = parser.parse_args()
    if args.action == 'select':
        run = None if os.environ.get('GITHUB_EVENT_NAME') == 'pull_request' else select_run(args.repository)
        outputs = f'reused={"true" if run else "false"}\nrun_id={run["id"] if run else args.run_id}\n'
        with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as output:
            output.write(outputs)
        print('Reuse validated run ' + str(run['id']) if run else 'Fresh validation required')
    elif args.action == 'verify':
        manifest = verify_packages(args.directory)
        print('Verified packages for source tree ' + manifest['tree'])
    else:
        attest(args.directory, args.repository, args.run_id)
        print('Recorded tag-to-build provenance without changing the built archives')


if __name__ == '__main__':
    main()
