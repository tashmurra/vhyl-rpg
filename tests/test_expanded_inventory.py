"""Keep public coverage claims tied to real modules, interfaces and tests."""
import ast
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ExpandedInventoryTests(unittest.TestCase):
    def test_skill_summary_links_and_heading_exceptions(self):
        """Summary headings are cross-checks, not new purchasable definitions."""
        base = ROOT / 'docs/expanded/inventory'
        details = {
            (path.name, entry['id']): entry
            for path in base.glob('skills-catalogue-*.json')
            for entry in json.loads(path.read_text())['entries']
        }
        rows = {}
        for segment, count in [('a', 44), ('b', 103), ('c', 104), ('d', 24)]:
            path = base / f'skill-summary-{segment}.json'
            summary = [e['summary_data'] for e in json.loads(path.read_text())['entries']
                       if 'summary_data' in e]
            self.assertEqual(len(summary), count)
            self.assertEqual([row['row'] for row in summary], list(range(1, count + 1)))
            for row in summary:
                self.assertTrue(row['targets'])
                rows[row['neutral_key']] = row
                for target in row['targets']:
                    entry = details[(target['file'], target['entry'])]
                    data = entry.get('reference_data')
                    if data is None:
                        continue  # E.g. the combat art/sport construction procedure.
                    exceptions = {e['field']: e for e in row.get('heading_exceptions', [])
                                  if e['entry'] == entry['id']}
                    for field in ('attribute', 'difficulty', 'technology_qualified'):
                        if row[field] in ('dx-or-iq', 'varies'):
                            continue
                        if field in exceptions:
                            exception = exceptions[field]
                            self.assertEqual(exception['summary_value'], row[field])
                            self.assertEqual(exception['detail_value'], data[field])
                            self.assertTrue(exception['pages'])
                            self.assertTrue(exception['resolution'])
                        else:
                            self.assertEqual(row[field], data[field], (row['neutral_key'], field))
        weather = rows['weather-sense']
        self.assertTrue(weather['alias_only'])
        self.assertEqual(weather['targets'], rows['meteorology']['targets'])
        self.assertEqual(weather['alias_conditions'], {
            'maximum_technology_level': 4,
            'requires_planet_type_specialty': False,
            'home_area_bonus': 2,
        })

    def test_aiming_catalogue_default_edges(self):
        """Source-definition expectations, not proof of runtime integration."""
        entries = {}
        for suffix in ('a', 'c'):
            path = ROOT / f'docs/expanded/inventory/skills-catalogue-{suffix}.json'
            for entry in json.loads(path.read_text())['entries']:
                if 'reference_data' in entry:
                    entries[entry['id'].removeprefix('catalogue-skill-')] = entry['reference_data']
        families = [
            (['beam-weapons-pistol', 'beam-weapons-projector', 'beam-weapons-rifle'], -4),
            (['direct-heavy-fire-beams', 'direct-heavy-fire-cannon',
              'direct-heavy-fire-mechanical-bolts', 'direct-heavy-fire-machine-gun',
              'direct-heavy-fire-rockets'], -4),
            (['innate-aim-hand-beam', 'innate-aim-breath', 'innate-aim-gaze',
              'innate-aim-hand-projectile'], -2),
            (['liquid-projector-flame', 'liquid-projector-spray',
              'liquid-projector-squirt', 'liquid-projector-water-cannon'], -4),
        ]
        for family, modifier in families:
            for target in family:
                for source in family:
                    with self.subTest(target=target, source=source):
                        edges = dict(entries[target]['defaults'])
                        if source == target:
                            self.assertNotIn(source, edges)
                        else:
                            self.assertEqual(edges[source], modifier)
                self.assertEqual(dict(entries[target]['defaults'])['dx'], -4)

        # B198-B199: exceptional small arms have -4 edges in BOTH directions.
        ordinary = ['light-machine-gun', 'musket', 'pistol', 'rifle', 'shotgun',
                    'submachine-gun']
        exceptional = ['grenade-launcher', 'miniature-rocket', 'light-antitank']
        for target in ordinary + exceptional:
            edges = dict(entries['guns-' + target]['defaults'])
            for source in ordinary + exceptional:
                if source == target:
                    self.assertNotIn('guns-' + source, edges)
                    continue
                modifier = -4 if target in exceptional or source in exceptional else -2
                self.assertEqual(edges['guns-' + source], modifier)

        # B179: matching pistol/rifle edges depend on campaign technology.
        for specialty in ('pistol', 'rifle'):
            for target, source in [('beam-weapons', 'guns'), ('guns', 'beam-weapons')]:
                data = entries[target + '-' + specialty]
                key = source + '-' + specialty
                self.assertEqual(dict(data['defaults'])[key], -4)
                self.assertEqual(data['default_conditions'][key],
                                 'campaign includes both beam and projectile weapons')
        self.assertFalse(any(key.startswith('guns-') for key, _ in
                             entries['beam-weapons-projector']['defaults']))

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
                    if 'reference_data' in entry:
                        data = entry['reference_data']
                        self.assertEqual(entry['kind'], 'catalogue-entry')
                        self.assertIn(data['attribute'], {
                            'st', 'dx', 'iq', 'ht', 'will', 'perception'})
                        self.assertIn(data['difficulty'], {
                            'easy', 'average', 'hard', 'very-hard'})
                        self.assertIsInstance(data['technology_qualified'], bool)
                        self.assertIsInstance(data['prerequisites'], list)
                        for prerequisite in data['prerequisites']:
                            self.assertIsInstance(prerequisite, str)
                            self.assertTrue(prerequisite)
                        for default in data['defaults']:
                            self.assertEqual(len(default), 2)
                            self.assertIsInstance(default[0], str)
                            self.assertTrue(default[0])
                            self.assertIsInstance(default[1], int)
                            self.assertLessEqual(default[1], 0)
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
