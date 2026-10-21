"""Explicit dependencies and isolated compiler invocations for this project."""
from pathlib import Path
import os
import json
import platform
import sys
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
    def __init__(self, compiler, vhyl, out, runtime_cache=None, native_opt='O0', host_slice_on_timeout=False):
        if native_opt not in ('O0', 'O2'):
            raise ValueError('Native optimization must be O0 or O2')
        self.host_slice_on_timeout = host_slice_on_timeout
        self.native_opt = native_opt
        self.compiler, self.vhyl, self.out = compiler, vhyl, out
        self.runtime_cache = runtime_cache or out / 'runtime-cache'

    def arguments(self, command, source):
        return [self.compiler, command, source, '--include-dir', ROOT / 'lib',
                '--include-dir', self.vhyl / 'lib']

    def check(self, source):
        try:
            run(self.arguments('check', source), cwd=self.out)
        except RuntimeError as error:
            raise RuntimeError(f'{source}: {error}') from error

    def build(self, name, source):
        print(f'Building {name} ({self.native_opt})', flush=True)
        bundle = self.out / name
        try:
            run(self.arguments('build', source) + ['--emit', 'shared', '--opt', self.native_opt,
                '--out-dir', bundle, '--runtime-cache', self.runtime_cache],
                cwd=self.out, timeout=900)
        except RuntimeError as error:
            if not self.host_slice_on_timeout or sys.platform != 'darwin' or 'tool deadline exceeded' not in str(error):
                raise
            bundle = self.completed_host_slice(bundle, str(error))
        if sys.platform == 'darwin':
            self.configure_macos_test_host(bundle)
        return bundle

    def completed_host_slice(self, bundle, failure):
        """Retain the failed universal build; run only its completed host slice."""
        arch = platform.machine()
        if arch not in ('x86_64', 'arm64'):
            raise RuntimeError('No supported completed host slice')
        source = bundle / arch
        manifest = json.loads((bundle / 'manifest.json').read_text())
        game, runtime = manifest['bundle']['game'], manifest['bundle']['runtime']
        for name in (game, runtime, 'consumer', 'game-build.txt', 'consumer-build.txt', 'dependencies.txt'):
            if not (source / name).is_file():
                raise RuntimeError(f'Host slice did not complete: {source / name}')
        destination = bundle / 'host-validation'
        destination.mkdir()
        for name in (game, runtime):
            shutil.copy2(source / name, destination / name)
        shutil.copy2(bundle / 'consumer.c', destination / 'consumer.c')
        shutil.copy2(bundle / 'zeb_game.h', destination / 'zeb_game.h')
        manifest['bundle']['targets'] = ['macos-' + arch]
        manifest['validation_scope'] = 'completed host slice; universal compiler build timed out'
        (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        (destination / 'universal-build-failure.txt').write_text(failure + '\n')
        print(f'  Universal build timed out; validating completed {arch} slice only', flush=True)
        return destination

    def configure_macos_test_host(self, bundle):
        # The compiler's sample host uses the platform default worker stack
        # (512 KiB on macOS). Deep library dispatch requires an explicit host
        # stack; game libraries, identities and runtime quotas stay untouched.
        source = (bundle / 'consumer.c').read_text()
        original = 'pthread_t thread;\n    if (pthread_create(&thread, NULL, worker, NULL) != 0)'
        configured = ('pthread_t thread;\n    pthread_attr_t attrs;\n'
                      '    if (pthread_attr_init(&attrs) != 0 || '
                      'pthread_attr_setstacksize(&attrs, 64 * 1024 * 1024) != 0) return 70;\n'
                      '    if (pthread_create(&thread, &attrs, worker, NULL) != 0)')
        if source.count(original) != 1:
            raise RuntimeError('Compiler sample host changed: review the explicit stack configuration')
        host_source = bundle / 'consumer-test-host.c'
        host_source.write_text(source.replace(original, configured))
        libraries = list(bundle.glob('libzeb_game_*.dylib'))
        if len(libraries) != 1:
            raise RuntimeError('Expected one compiled game library for the native test host')
        run([os.environ.get('CC', '/usr/bin/clang'), host_source, libraries[0],
             '-Wl,-rpath,@executable_path', '-o', bundle / 'consumer'], cwd=bundle)
