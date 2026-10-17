#!/usr/bin/env python3
"""Check all programs; --native also executes behavioral and persistence tests."""
import argparse
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tests'))
from support import Build, compiler_path, dependency_path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--vhyl', type=Path, help='vhyl sources; otherwise VHYL_ROOT')
    parser.add_argument('--zebc', help='compiler executable; otherwise ZEBC, then PATH')
    parser.add_argument('--native', action='store_true')
    parser.add_argument('--out', type=Path, help='new output directory; retained after success')
    parser.add_argument('--runtime-cache', type=Path, help='optional reusable native runtime cache')
    args = parser.parse_args()
    vhyl = dependency_path(args.vhyl)
    compiler = compiler_path(args.zebc)
    out = args.out.resolve() if args.out else Path(tempfile.mkdtemp(prefix='vhyl-rpg-'))
    if args.out:
        out.mkdir(parents=True, exist_ok=False)
    try:
        suite = unittest.defaultTestLoader.discover(str(ROOT / 'tests'), pattern='test_*.py')
        if not unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful():
            raise RuntimeError('Tool tests failed')
        build = Build(compiler, vhyl, out,
                      args.runtime_cache.resolve() if args.runtime_cache else None)
        programs = sorted((ROOT / 'examples').rglob('*.t')) + sorted((ROOT / 'tests/fixtures').glob('*.t'))
        for source in programs:
            build.check(source)
        print(f'{len(programs)} source programs passed', flush=True)
        if args.native:
            import native
            native.test(build)
            print('Native behavior checks passed on this host', flush=True)
    except BaseException:
        print(f'Output retained at {out}', file=sys.stderr)
        raise
    else:
        if not args.out:
            shutil.rmtree(out)
    print('All requested checks passed', flush=True)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, OSError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
