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
