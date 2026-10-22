"""Build reuse must bind successful trusted validation to an identical Git tree."""
from copy import deepcopy
import hashlib
import io
import json
import shutil
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import build_release as release
import promote_release as promotion

REPO = 'owner/library'
REVISION = 'b' * 40
TREE = 'a' * 40


class SelectionTests(unittest.TestCase):
    def setUp(self):
        self.run = dict(id=123, conclusion='success', event='pull_request', head_sha=REVISION,
                        path='.github/workflows/release.yml', head_repository={'full_name': REPO})
        self.jobs = [{'name': name, 'conclusion': 'success'} for name in promotion.REQUIRED_JOBS]
        self.artifact = dict(id=456, name='release-packages', expired=False)
        self.merged = True

    def fetch(self, endpoint):
        if '/workflows/' in endpoint:
            return {'workflow_runs': [self.run]}
        if '/jobs?' in endpoint:
            return {'jobs': self.jobs}
        if '/artifacts?' in endpoint:
            return {'artifacts': [self.artifact]}
        if '/pulls?' in endpoint:
            return [{'merged_at': '2026-10-17' if self.merged else None,
                     'head': {'sha': REVISION}, 'base': {'ref': 'main', 'repo': {'full_name': REPO}}}]
        raise AssertionError(endpoint)

    def test_successful_merged_pr_can_be_reused(self):
        with patch.object(promotion, 'git', return_value=TREE.encode()):
            self.assertEqual(promotion.select_run(REPO, fetch=self.fetch)['id'], 123)

    def test_source_change_requires_fresh_validation(self):
        with patch.object(promotion, 'git', side_effect=[TREE.encode(), b'c' * 40]):
            self.assertIsNone(promotion.select_run(REPO, fetch=self.fetch))

    def test_fork_other_workflow_failed_and_incomplete_jobs_are_rejected(self):
        for update in ({'conclusion': 'failure'}, {'head_repository': {'full_name': 'fork/library'}},
                       {'path': '.github/workflows/other.yml'}, {'event': 'push', 'head_branch': 'feature'}):
            run = deepcopy(self.run)
            run.update(update)
            with self.subTest(update=update):
                self.assertFalse(promotion.validated_run(run, self.jobs, REPO))
        for conclusion in ('skipped', 'failure', None):
            jobs = deepcopy(self.jobs)
            jobs[0]['conclusion'] = conclusion
            self.assertFalse(promotion.validated_run(self.run, jobs, REPO))

    def test_expired_assets_and_unmerged_pr_are_not_reused(self):
        with patch.object(promotion, 'git', return_value=TREE.encode()):
            self.artifact['expired'] = True
            self.assertIsNone(promotion.select_run(REPO, fetch=self.fetch))
            self.artifact['expired'] = False
            self.merged = False
            self.assertIsNone(promotion.select_run(REPO, fetch=self.fetch))

    def test_api_failure_does_not_forge_success(self):
        def failure(endpoint):
            raise RuntimeError('unavailable')
        with patch.object(promotion, 'git', return_value=TREE.encode()):
            with self.assertRaises(RuntimeError):
                promotion.select_run(REPO, fetch=failure)


class PackagePromotionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        def git(*args):
            return release.git(*args, root=self.root, quiet=True)
        self.git = git
        git('init', '-q')
        git('config', 'user.name', 'Promotion fixture')
        git('config', 'user.email', 'fixture@example.invalid')
        (self.root / 'VERSION').write_bytes(b'0.2.0-alpha.1\n')
        (self.root / 'dependencies.json').write_text('{}\n')
        (self.root / '.gitignore').write_text('build/\n')
        git('add', '.')
        git('commit', '-qm', 'Build source')
        self.revision = git('rev-parse', 'HEAD').decode().strip()
        self.tree = git('rev-parse', 'HEAD^{tree}').decode().strip()
        self.out = self.root / 'build/release'
        self.out.mkdir(parents=True)
        self.name = 'vhyl-rpg-v0.2.0-alpha.1'
        release.source_archive(self.out / (self.name + '.tar.gz'), self.revision, self.name, 1234, self.root)
        site = self.root / 'build/site'
        (site / 'reference').mkdir(parents=True)
        (site / 'search').mkdir()
        (site / 'index.html').write_text('<h1>Reference</h1>')
        (site / 'reference/index.html').write_text(self.revision)
        (site / 'search/search_index.json').write_text('{}')
        release.docs_archive(self.out / (self.name + '-docs.tar.gz'), site, self.name + '-docs', 1234)
        manifest = dict(schema_version=2, revision=self.revision, tree=self.tree,
                        version='0.2.0-alpha.1', tag='v0.2.0-alpha.1', dependencies={})
        (self.out / 'release-manifest.json').write_text(json.dumps(manifest))
        release.checksums(self.out)

    def test_different_commit_with_same_tree_promotes_identical_archives(self):
        self.git('commit', '--allow-empty', '-qm', 'Merge-equivalent commit')
        target = self.git('rev-parse', 'HEAD').decode().strip()
        self.assertNotEqual(target, self.revision)
        before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in self.out.iterdir()}
        promotion.attest(self.out, REPO, '123', root=self.root)
        for name, digest in before.items():
            self.assertEqual(hashlib.sha256((self.out / name).read_bytes()).hexdigest(), digest)
        proof = json.loads((self.out / 'release-provenance.json').read_text())
        self.assertEqual(proof['release_revision'], target)
        self.assertEqual(proof['build_revision'], self.revision)
        self.assertEqual(proof['tree'], self.tree)
        self.assertEqual(proof['assets'], before)

    def test_missing_build_commit_is_fetched_by_id(self):
        # The PR branch was deleted: the checkout has an identical tree but not the build commit.
        target = self.git('commit-tree', self.tree, '-m', 'Squash-merged commit').decode().strip()
        self.git('branch', 'main-after-merge', target)
        consumer = self.root / 'build/consumer'
        def consumer_git(*args):
            return release.git(*args, root=consumer, quiet=True)
        consumer.mkdir()
        consumer_git('init', '-q')
        consumer_git('remote', 'add', 'origin', str(self.root))
        consumer_git('fetch', '-q', '--no-tags', 'origin', 'main-after-merge')
        consumer_git('checkout', '-q', 'FETCH_HEAD')
        with self.assertRaises(release.subprocess.CalledProcessError):
            consumer_git('cat-file', '-e', self.revision + '^{commit}')
        shutil.copytree(self.out, consumer / 'build/release')
        manifest = promotion.verify_packages(consumer / 'build/release', root=consumer)
        self.assertEqual(manifest['revision'], self.revision)

    def test_changed_tree_cannot_promote_old_packages(self):
        (self.root / 'new.t').write_text('class Changed: object;')
        self.git('add', '.')
        self.git('commit', '-qm', 'Changed source')
        with self.assertRaisesRegex(ValueError, 'source tree'):
            promotion.verify_packages(self.out, root=self.root)

    def test_corruption_and_unexpected_assets_are_rejected(self):
        file = self.out / (self.name + '-docs.tar.gz')
        file.write_bytes(file.read_bytes() + b'tampered')
        with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
            promotion.verify_packages(self.out, root=self.root)
        (self.out / 'unexpected').write_text('not a release asset')
        with self.assertRaisesRegex(ValueError, 'unexpected'):
            promotion.verify_packages(self.out, root=self.root)

    def test_rehashed_source_tampering_is_detected_against_git(self):
        with tarfile.open(self.out / (self.name + '.tar.gz'), 'w:gz') as archive:
            data = b'changed source'
            member = tarfile.TarInfo(self.name + '/VERSION')
            member.size = len(data)
            archive.addfile(member, io.BytesIO(data))
        release.checksums(self.out)
        with self.assertRaisesRegex(ValueError, 'source archive differs'):
            promotion.verify_packages(self.out, root=self.root)

    def test_archive_traversal_is_rejected_without_extraction(self):
        buffer = io.BytesIO()
        with tarfile.open(fileobj=buffer, mode='w') as archive:
            member = tarfile.TarInfo('../escape')
            member.size = 1
            archive.addfile(member, io.BytesIO(b'x'))
        buffer.seek(0)
        with tarfile.open(fileobj=buffer) as archive:
            with self.assertRaisesRegex(ValueError, 'unsafe'):
                promotion.tar_files(archive)


if __name__ == '__main__':
    unittest.main()
