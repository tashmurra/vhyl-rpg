"""Dependency configuration must fail clearly instead of silently falling back."""
import tempfile
from pathlib import Path
import unittest
from unittest.mock import patch
from support import compiler_path, dependency_path


class DependencyTests(unittest.TestCase):
    def test_explicit_compiler_is_authoritative(self):
        with patch.dict('os.environ', {'ZEBC': 'python3'}):
            with self.assertRaises(ValueError):
                compiler_path('/nonexistent/compiler')

    def test_invalid_environment_compiler_is_authoritative(self):
        with patch.dict('os.environ', {'ZEBC': ''}):
            with self.assertRaises(ValueError):
                compiler_path(None)

    def test_dependency_is_required(self):
        with patch.dict('os.environ', {}, clear=True):
            with self.assertRaises(ValueError):
                dependency_path(None)

    def test_incomplete_dependency_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                dependency_path(Path(directory))


class HostSliceTests(unittest.TestCase):
    def test_incomplete_host_slice_is_rejected(self):
        import json
        from support import Build
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'manifest.json').write_text(json.dumps({'bundle': {'game': 'game.dylib', 'runtime': 'runtime.dylib'}}))
            build = Build('compiler', root, root)
            with patch('support.platform.machine', return_value='x86_64'):
                with self.assertRaisesRegex(RuntimeError, 'Host slice did not complete'):
                    build.completed_host_slice(root, 'tool deadline exceeded')

    def test_completed_slice_preserves_failed_universal_manifest(self):
        import json
        from support import Build
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = {'bundle': {'game': 'game.dylib', 'runtime': 'runtime.dylib', 'targets': ['macos-x86_64', 'macos-arm64']}}
            (root / 'manifest.json').write_text(json.dumps(original))
            (root / 'consumer.c').write_text('#include "zeb_game.h"\n')
            (root / 'zeb_game.h').write_text('/* exact game ABI */\n')
            arch = root / 'x86_64'; arch.mkdir()
            for name in ['game.dylib', 'runtime.dylib', 'consumer', 'game-build.txt', 'consumer-build.txt', 'dependencies.txt']:
                (arch / name).write_text(name)
            build = Build('compiler', root, root)
            with patch('support.platform.machine', return_value='x86_64'):
                result = build.completed_host_slice(root, 'tool deadline exceeded')
            self.assertEqual(json.loads((root / 'manifest.json').read_text()), original)
            self.assertEqual(json.loads((result / 'manifest.json').read_text())['bundle']['targets'], ['macos-x86_64'])
            self.assertEqual((result / 'zeb_game.h').read_text(), (root / 'zeb_game.h').read_text())
            self.assertIn('tool deadline exceeded', (result / 'universal-build-failure.txt').read_text())
