"""Release archives must identify the committed source and exclude local tools."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import build_release as release


class ReleaseTests(unittest.TestCase):
    def test_stable_and_explicit_prerelease_versions_are_accepted(self):
        for value in ('1.0.0', '0.1.0', '0.1.0-alpha.1', '1.2.3-beta.0', '1.0.0-rc.2'):
            self.assertEqual(release.validate_version(value), value)
        for value in ('1.0', '1.0.0-dev', '1.0.0+local', 'v0.1.0-alpha.1', '../secret', '01.0.0-alpha.1', '1.0.0-rc.01'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                release.validate_version(value)

    def test_source_is_committed_snapshot_and_dirty_checkouts_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def git(*args):
                return subprocess.check_output(['git', *args], cwd=root, stderr=subprocess.STDOUT)
            git('init', '-q')
            git('config', 'user.name', 'Release fixture')
            git('config', 'user.email', 'release@example.invalid')
            # Git archive otherwise applies the caller's checkout line endings.
            git('config', 'core.autocrlf', 'true')
            (root / 'VERSION').write_bytes(b'0.1.0-alpha.1\n')
            (root / '.gitignore').write_text('.tools/\nbuild/\n')
            (root / 'library.t').write_text('class Sample: object;\n')
            git('add', '.')
            git('commit', '-qm', 'Fixture')
            (root / '.tools').mkdir()
            (root / '.tools/private').write_text('ignored local tool')
            version, revision, epoch = release.release_identity(root)
            self.assertEqual(version, '0.1.0-alpha.1')
            (root / 'build').mkdir()
            path = root / 'build/source.tar.gz'
            release.source_archive(path, revision, 'package', epoch, root)
            with tarfile.open(path) as archive:
                self.assertIn('package/library.t', archive.getnames())
                self.assertFalse(any('.tools' in name for name in archive.getnames()))
                self.assertEqual(archive.extractfile('package/VERSION').read(), b'0.1.0-alpha.1\n')
            (root / 'library.t').write_text('uncommitted change')
            with self.assertRaisesRegex(ValueError, 'clean committed'):
                release.release_identity(root)

    def test_offline_docs_have_search_and_portable_archive_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            site = root / 'site'
            (site / 'search').mkdir(parents=True)
            (site / 'index.html').write_text('<h1>Reference</h1>')
            (site / 'search/search_index.json').write_text(json.dumps({'docs': []}))
            path = root / 'docs.tar.gz'
            release.docs_archive(path, site, 'package-docs', 1234)
            with tarfile.open(path) as archive:
                self.assertEqual(archive.getnames(), ['package-docs/index.html',
                                                     'package-docs/search/search_index.json'])
                self.assertTrue(all(m.uid == 0 and m.mtime == 1234 for m in archive.getmembers()))
            (site / 'search/search_index.json').unlink()
            with self.assertRaisesRegex(ValueError, 'search data'):
                release.docs_archive(root / 'bad.tar.gz', site, 'package-docs', 1234)

    def test_checksums_cover_each_asset(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ('source.tar.gz', 'docs.tar.gz', 'release-manifest.json'):
                (root / name).write_bytes(name.encode())
            release.checksums(root)
            sums = (root / 'SHA256SUMS').read_text().splitlines()
            self.assertEqual(len(sums), 3)
            for row in sums:
                expected, name = row.split('  ')
                self.assertEqual(expected, hashlib.sha256((root / name).read_bytes()).hexdigest())
            release.checksums(root)
            self.assertEqual(sums, (root / 'SHA256SUMS').read_text().splitlines())


if __name__ == '__main__':
    unittest.main()
