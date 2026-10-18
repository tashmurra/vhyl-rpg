"""Keep public coverage claims tied to real modules, interfaces and tests."""
import ast
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ExpandedInventoryTests(unittest.TestCase):
    def test_detailed_inventory_references_and_completion_claims(self):
        """Structural integrity only; this does not validate source mechanics."""
        base = ROOT / 'docs/expanded'
        inventory = json.loads((base / 'coverage.json').read_text())
        modules = {row['id'] for row in inventory['modules']}
        features = {row['id'] for row in inventory['features']}
        identifiers = set()
        for filename in inventory['detailed_inventories']:
            path = base / filename
            self.assertTrue(path.resolve().is_relative_to(base.resolve()))
            detail = json.loads(path.read_text())
            self.assertEqual(detail['source'], 'full-2008')
            self.assertTrue(detail['entries'])
            self.assertTrue(detail['exclusions'])
            if inventory['inventory_complete']:
                self.assertTrue(detail['enumeration_complete'])
            for entry in detail['entries']:
                with self.subTest(entry=entry['id']):
                    self.assertNotIn(entry['id'], identifiers)
                    identifiers.add(entry['id'])
                    self.assertIn(entry['module'], modules)
                    self.assertEqual(entry['source'], detail['source'])
                    self.assertTrue(entry['pages'].startswith('B'))
                    self.assertTrue(entry['acceptance'])
                    self.assertIn(entry['kind'], {
                        'procedure', 'table', 'table-row', 'modifier',
                        'catalogue-entry', 'author-decision'})
                    self.assertIn(entry['status'], {
                        'pending', 'partial', 'implemented', 'adjudicated'})
                    if 'existing_feature' in entry:
                        self.assertIn(entry['existing_feature'], features)
                    if entry['status'] in {'implemented', 'adjudicated'}:
                        self.assertTrue(entry['tests'])
                        self.assertTrue(entry.get('interfaces'))
                    if entry['status'] == 'adjudicated':
                        self.assertTrue(entry.get('author_contract'))
                    for reference in entry['tests']:
                        test_path, name = reference.split('::')
                        tree = ast.parse((ROOT / test_path).read_text())
                        self.assertIn(name, {
                            node.name for node in ast.walk(tree)
                            if isinstance(node, ast.FunctionDef)})

    def test_inventory_and_catalogue_agree(self):
        inventory = json.loads((ROOT / 'docs/expanded/coverage.json').read_text())
        modules = inventory['modules']
        self.assertEqual(len(modules),18)
        self.assertEqual(len({row['id'] for row in modules}),18)
        catalogue = (ROOT / 'docs/libraries.md').read_text()
        for row in modules:
            name = row['id']
            with self.subTest(module=name):
                source = ROOT / f'lib/vhyl-rpg-expanded-{name}.t'
                self.assertEqual(source.is_file(), row['status'] != 'pending')
                self.assertTrue((ROOT / f'docs/expanded/{name}.md').is_file())
                self.assertIn(source.name,catalogue)
                if source.is_file():
                    self.assertTrue((ROOT / f'tests/fixtures/expanded-{name}-only.t').is_file())
        for source in (ROOT / 'lib').glob('*.t'):
            self.assertIn(source.name,catalogue)
        if not inventory['inventory_complete']:
            self.assertIn('incomplete',catalogue.lower())
            self.assertTrue(any(row['status'] == 'pending' for row in modules))

    def test_features_have_source_interfaces_and_executable_tests(self):
        inventory = json.loads((ROOT / 'docs/expanded/coverage.json').read_text())
        source = '\n'.join(p.read_text() for p in (ROOT / 'lib').glob('*.t'))
        for feature in inventory['features']:
            with self.subTest(feature=feature['id']):
                self.assertEqual(feature['source'],'full-2008')
                self.assertTrue(feature['pages'].startswith('B'))
                self.assertIn(feature['symbol'],source)
                self.assertTrue(feature['tests'])
                for reference in feature['tests']:
                    path,name = reference.split('::')
                    tree = ast.parse((ROOT / path).read_text())
                    self.assertIn(name,{node.name for node in tree.body if isinstance(node,ast.FunctionDef)})

    def test_public_guides_do_not_ship_private_references(self):
        for path in [ROOT / 'README.md',*(ROOT / 'docs').rglob('*.md'),*(ROOT / 'lib').glob('*.t')]:
            text = path.read_text()
            self.assertNotIn('192.168.',text,str(path))
            self.assertNotIn('library/originals/',text,str(path))
            self.assertNotIn('/private/tmp/',text,str(path))


if __name__ == '__main__':
    unittest.main()
