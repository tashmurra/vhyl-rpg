"""Explicit dependencies and isolated compiler invocations for this project."""
from pathlib import Path
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def executable(value):
    found = shutil.which(str(value))
    if not found:
        raise ValueError(f'Compiler is not executable: {value}')
    return str(Path(found).resolve())


def compiler_path(argument):
    # A bad explicit setting must never fall back to a different compiler.
    if argument is not None:
        return executable(argument)
    if 'ZEBC' in os.environ:
        return executable(os.environ['ZEBC'])
    return executable('zebc')


def dependency_path(argument):
    value = argument if argument is not None else os.environ.get('VHYL_ROOT')
    if not value:
        raise ValueError('Supply --vhyl or VHYL_ROOT with a vhyl source directory')
    root = Path(value).resolve()
    for name in ('lib/vhyl.t', 'lib/vhyl.h', 'lib/vhyl-actions.t', 'lib/vhyl-dialogue.t'):
        if not (root / name).is_file():
            raise ValueError(f'vhyl dependency is missing {name}: {root}')
    return root


def run(arguments, *, cwd=ROOT, timeout=300, **kwargs):
    try:
        result = subprocess.run([str(a) for a in arguments], cwd=cwd,
                                capture_output=True, text=True, encoding='utf-8',
                                errors='backslashreplace', timeout=timeout, **kwargs)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f'Timed out: {arguments[0]}') from error
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {arguments[0]}\n'
                           f'{result.stdout[-12000:]}{result.stderr[-12000:]}')
    return result.stdout


class Build:
    def __init__(self, compiler, vhyl, out, runtime_cache=None):
        self.compiler, self.vhyl, self.out = compiler, vhyl, out
        self.runtime_cache = runtime_cache or out / 'runtime-cache'

    def arguments(self, command, source):
        return [self.compiler, command, source, '--include-dir', ROOT / 'lib',
                '--include-dir', self.vhyl / 'lib']

    def check(self, source):
        run(self.arguments('check', source), cwd=self.out)

    def build(self, name, source):
        bundle = self.out / name
        run(self.arguments('build', source) + ['--emit', 'shared', '--opt', 'O2',
            '--out-dir', bundle, '--runtime-cache', self.runtime_cache],
            cwd=self.out, timeout=900)
        return bundle
