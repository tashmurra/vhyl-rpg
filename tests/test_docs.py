"""Reference extraction and links are checked without a compiler or MkDocs."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import build_docs as docs
from docscan import masked, parse_source


class ScannerTests(unittest.TestCase):
    def test_comments_and_strings_do_not_change_structure(self):
        source = '''/** A documented class. */
class Sample: object
    label = 'a ; } /* literal */'
    values = [1, 2] enabled = true
    /* A documented method. */
    run(c) { local text = "ignore } ;"; return c; }
;
helper(a, b) { /* } */ return a + b; }
'''
        symbols = parse_source('fixture.t', source)
        self.assertEqual([(s.name, s.kind) for s in symbols],
                         [('Sample', 'class'), ('helper', 'function')])
        sample = symbols[0]
        self.assertEqual(sample.description, 'A documented class.')
        members = {m.name: m for m in sample.members}
        self.assertEqual(set(members), {'label', 'values', 'enabled', 'run'})
        self.assertIn('/* literal */', members['label'].signature)
        self.assertEqual(members['values'].signature, 'values = [1, 2]')
        self.assertEqual(members['run'].signature, 'run(c)')
        self.assertEqual(members['run'].description, 'A documented method.')
        self.assertEqual(members['run'].line, 6)
        self.assertEqual(masked(source).count('\n'), source.count('\n'))

    def test_unterminated_syntax_fails(self):
        for text in ('/* unterminated', "'unterminated", 'class A: object x = 1'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                parse_source('bad.t', text)

    def test_merge_and_external_extensions_keep_source_locations(self):
        base = parse_source('core.t', 'class Approach: object cost = 0;')
        extra = parse_source('report.t', 'modify Approach disclosure = nil;\nmodify Thing profile = nil;')
        symbols = {s.name: s for s in docs.merge_symbols(base + extra)}
        self.assertEqual(symbols['Approach'].kind, 'class')
        self.assertEqual([(m.name, m.source) for m in symbols['Approach'].members],
                         [('cost', 'core.t'), ('disclosure', 'report.t')])
        self.assertEqual(symbols['Thing'].kind, 'extension')
        self.assertEqual(len(base[0].members), 1, 'merge must not mutate the original input')

    def test_duplicate_declarations_fail(self):
        with self.assertRaisesRegex(ValueError, 'duplicate declaration'):
            docs.merge_symbols(parse_source('duplicate.t', 'class A: object; class A: object;'))

    def test_inheritance_handles_overrides_and_detects_cycles(self):
        declarations = parse_source('inherit.t', '''
class Base: object shared = 1 baseOnly = 2;
class Child: Base shared = 3;
class Grandchild: Child;
''')
        named = {s.name: s for s in declarations}
        self.assertEqual(docs.inherited_members(named['Child'], named), {'baseOnly': 'Base'})
        self.assertEqual(docs.inherited_members(named['Grandchild'], named),
                         {'shared': 'Child', 'baseOnly': 'Base'})
        named['Base'].parent = 'Grandchild'
        with self.assertRaisesRegex(ValueError, 'inheritance cycle'):
            docs.inherited_members(named['Grandchild'], named)


class ReferenceTests(unittest.TestCase):
    def test_live_model_includes_reporting_extensions_and_all_attributes(self):
        named = {s.name: s for s in docs.model()}
        self.assertLessEqual(docs.PUBLIC, named.keys())
        self.assertIn('disclosureFor', {m.name for m in named['RpgApproach'].members})
        self.assertIn('odds', {m.name for m in named['RpgAssessment'].members})
        self.assertEqual(named['rpgInteger'].audience, 'internal helper')
        for name in ('RpgLiteProfile', 'RpgLiteBattle', 'RpgLiteExposure', 'rpgLiteClimbData'):
            self.assertEqual(named[name].audience, 'author / trusted game code')
            self.assertTrue(named[name].description)
        for name in ('rpgST', 'rpgDX', 'rpgIQ', 'rpgHT', 'rpgWill', 'rpgPerception'):
            self.assertEqual(named[name].kind, 'enum')

    def test_reference_links_source_escaping_and_indexes(self):
        with tempfile.TemporaryDirectory() as directory:
            stage = Path(directory)
            docs.render(docs.model(), stage, 'abc123')
            docs.check_links(stage)
            approach = (stage / 'reference/RpgApproach.md').read_text()
            self.assertIn('source/lib-vhyl-rpg-report-t.md#L', approach)
            self.assertIn('id="member-disclosureFor"', approach)
            self.assertIn('/blob/abc123/lib/vhyl-rpg.t#L', approach)
            full = (stage / 'reference/rpgFullDisclosure.md').read_text()
            self.assertIn('RpgDisclosure.md#member-estimateLabelId', full)
            source = (stage / 'reference/source/lib-vhyl-rpg-t.md').read_text()
            self.assertIn('id="L1"', source)
            self.assertIn('&lt;', source)
            self.assertIn('function-rpgPublishAssessment.md', (stage / 'reference/functions.md').read_text())
            self.assertTrue((stage / 'reference/function-rpgContext.md').is_file())
            self.assertIn('member-actor', (stage / 'reference/RpgContext.md').read_text())
            self.assertIn('RpgOdds.md#member-chanceBasisPoints', (stage / 'reference/members.md').read_text())
            self.assertFalse(list(stage.rglob('*.pyc')))

    def test_broken_links_and_anchors_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            stage = Path(directory)
            page = stage / 'index.md'
            for content in ('[missing](missing.md)', '[bad anchor](#unknown)', '[escape](../outside.md)'):
                with self.subTest(content=content):
                    page.write_text(content)
                    with self.assertRaisesRegex(ValueError, 'broken documentation links'):
                        docs.check_links(stage)
            page.write_text('<a id="good"></a>\n[valid](#good)\n[web](https://example.com)')
            docs.check_links(stage)


if __name__ == '__main__':
    unittest.main()
