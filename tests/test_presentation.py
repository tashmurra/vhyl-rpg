"""The example renders only values present in disclosed event envelopes."""
import importlib.util
import unittest
from support import ROOT

spec = importlib.util.spec_from_file_location('report_presentation', ROOT / 'examples/hybrid/presentation.py')
presentation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(presentation)


def event(name, values):
    return {'id': name, 'values': values}


class PresentationTests(unittest.TestCase):
    def test_exact_chance_and_costly_success(self):
        a = [1, 'records', 'force', 'pc', 'ready', None, 'check', 30, 2, None,
             216, 196, 160, 36, 16, 4, 0, 160, 4, 4]
        text = presentation.report_lines([event('rpg.assessment', a)])[0]
        self.assertIn('90.7% chance of achieving the goal', text)
        self.assertIn('16.7% with a cost', text)
        self.assertIn('30s', text)

    def test_roll_faces_and_modifier_explanation(self):
        r = [1, 'records', 'pick', 'pc', 'resolved', 'check', 'success', True,
             120, 1, 7, 5, None, None, None, None, 3, 0, 4, 1, 2]
        c = [1, 'roll', 'records', 'pick', 'pc', 'acting', 'survey.lockwork',
             'rpg.coordination', 'trained', 11, None, 11, 12, 2,
             'situation', 'rpg.modifier.situation', -2,
             'context', 'rpg.modifier.preparation', 3]
        lines = presentation.report_lines([event('rpg.roll', r), event('rpg.calculation', c)])
        self.assertIn('3d6: 4 + 1 + 2 = 7, against 12', lines[0])
        self.assertEqual(lines[1], 'Used: Lockwork 11 -2 difficulty +3 preparation = 12')

    def test_hidden_numbers_are_not_inferred(self):
        c = [1, 'assessment', 'records', 'pick', 'pc', 'acting', 'survey.lockwork',
             'rpg.coordination', 'trained', None, None, None, None, 0]
        self.assertEqual(presentation.report_lines([event('rpg.calculation', c)]), ['Would use: Lockwork'])

    def test_recorded_assessment_uses_past_tense(self):
        a = [1, 'records', 'pick', 'pc', 'settled', None, 'check', 0, 0, None] + [None] * 10
        c = [1, 'assessment', 'records', 'pick', 'pc', 'acting', 'survey.lockwork',
             'rpg.coordination', 'trained', None, None, None, None, 0]
        lines = presentation.report_lines([event('rpg.assessment', a), event('rpg.calculation', c)])
        self.assertIn('attempt already resolved', lines[0])
        self.assertEqual(lines[1], 'Previous attempt used: Lockwork')

    def test_automatic_has_no_fictitious_dice(self):
        r = [1, 'records', 'key', 'pc', 'resolved', 'automatic', 'success', True,
             5, 0, None, None, None, None, None, None, 0, 0]
        self.assertEqual(presentation.report_lines([event('rpg.roll', r)]), ['Automatic success; no dice rolled.'])
