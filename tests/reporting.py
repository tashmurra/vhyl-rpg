"""Probability oracles and disclosure/persistence checks for optional reports."""
from collections import Counter
from itertools import product
from native import fresh, last, result, state


def check(score, total):
    succeeds = total in (3, 4) or total <= min(score, 16)
    critical_failure = total == 18 or total == 17 and score <= 15 or total >= score + 10
    critical_success = total <= 4 or total == 5 and score >= 15 or total == 6 and score >= 16
    return succeeds, critical_success, critical_failure


def oracle(score, opposing, costly):
    # Enumerate actual die faces, independently of the source's weighted table.
    totals = [sum(dice) for dice in product(range(1, 7), repeat=3)]
    counter = Counter()
    for own, other in product(totals, totals if opposing else (None,)):
        succeeds, critical_success, critical_failure = check(score, own)
        if opposing:
            defended, _, _ = check(opposing, other)
            acting_rank = int(succeeds), score - own
            defending_rank = int(defended), opposing - other
            outcome = ('success' if acting_rank > defending_rank else 'tie'
                       if acting_rank == defending_rank else 'complication'
                       if critical_failure else 'setback')
        else:
            outcome = ('success' if succeeds else 'complication' if critical_failure
                       else 'costly-success' if costly and score < own <= score + costly else 'setback')
        counter['total'] += 1
        counter[outcome] += 1
        counter['achieved'] += outcome in ('success', 'costly-success')
        counter['raw'] += succeeds
        counter['critical-success'] += critical_success
        counter['critical-failure'] += critical_failure
    values = [counter[key] for key in ('total', 'achieved', 'success', 'costly-success',
              'setback', 'complication', 'tie', 'raw', 'critical-success', 'critical-failure')]
    values.append((values[1] * 10000 + values[0] // 2) // values[0])
    return values


def query(s, verb, *args):
    s.log.clear()
    s.action(verb, *args)
    return [e for e in s.log if e['id'].startswith('rpg.')]


def event(events, name):
    return next(e['values'] for e in events if e['id'] == name)


def calculations(events):
    return [e['values'] for e in events if e['id'] == 'rpg.calculation']


def test_probabilities(s):
    baseline = state(s)
    cases = [(score, 0, costly) for score in (3, 5, 10, 12, 15, 16, 20) for costly in (0, 2)]
    cases += [(a, b, 0) for a, b in ((3, 3), (5, 3), (3, 16), (10, 10),
                                    (11, 11), (15, 16), (16, 15), (20, 20))]
    for score, opposing, costly in cases:
        s.action(905, score, opposing, costly, 0)
        actual = last(s, 'test.odds')
        assert actual == oracle(score, opposing, costly), (score, opposing, costly, actual)
        assert sum(actual[2:7]) == actual[0]
        assert actual[1] == sum(actual[2:4])
    s.action(905, 12, 0, 0, 0)
    assert last(s, 'test.odds')[:2] == [216, 160]
    s.action(905, 12, 0, 2, 0)
    assert last(s, 'test.odds')[:4] == [216, 196, 160, 36]
    s.action(905, 0, 0, 0, 1)
    assert last(s, 'test.odds') == [1, 1, 1, 0, 0, 0, 0, None, None, None, 10000]
    assert state(s) == baseline, 'probabilities changed gameplay or randomness'


def test_assessments(s):
    baseline = state(s)
    for _ in range(10):
        events = query(s, 906, 4, 0)
        a = event(events, 'rpg.assessment')
        assert a[4:9] == ['ready', None, 'contest', 30, 1]
        assert a[10] == 46656 and len(calculations(events)) == 2
    assert state(s) == baseline, 'assessment changed history, RNG, costs or knowledge'
    events = query(s, 906, 1, 0)
    c = calculations(events)[0]
    assert c[6:14] == ['rpg.strength', 'rpg.strength', 'attribute', 10, None, 10, 5, 1], c
    assert c[14:] == ['situation', 'rpg.modifier.situation', -5]
    c = calculations(query(s, 906, 17, 0))[0]
    assert c[6:14] == ['test.default-skill', 'rpg.intelligence', 'default', 11, -5, 6, 6, 0], c
    c = calculations(query(s, 906, 15, 0))[0]
    assert c[6:14] == ['survey.inspection', 'rpg.perception', 'trained', 11, None, 12, 13, 1], c
    assert c[14:] == ['trait', 'survey.careful-eye', 1]
    for index, reason in ((8, 'training-required'), (9, 'too-difficult'),
                          (10, 'insufficient-energy'), (11, 'test.no-tools')):
        events = query(s, 906, index, 0)
        a = event(events, 'rpg.assessment')
        assert a[4:6] == ['blocked', reason] and a[10:] == [None] * 10, a
    result(s, 200)
    events = query(s, 906, 1, 0)
    a = event(events, 'rpg.assessment')
    assert a[4] == 'settled' and a[7:9] == [0, 0] and a[10:] == [None] * 10
    result(s, 203)
    a = event(query(s, 906, 3, 0), 'rpg.assessment')
    assert a[4] == 'complete' and a[10:] == [None] * 10


def test_disclosure(s):
    baseline = state(s)
    assert query(s, 906, 12, 1) == [], 'player preferences bypassed default denial'
    assert query(s, 906, 1, 3) == [], 'player could not suppress details'
    events = query(s, 906, 13, 1)
    a = event(events, 'rpg.assessment')
    assert a[4:6] == [None, None] and a[7:] == [None] * 13, a
    c = calculations(events)[0]
    assert c[6:9] == ['rpg.strength', 'rpg.strength', 'attribute']
    assert c[9:14] == [None, None, None, None, 0]
    assert query(s, 906, 1, 2)[-1]['values'][9:14] == [None, None, None, None, 0]
    events = query(s, 906, 14, 1)
    a = event(events, 'rpg.assessment')
    assert a[6] is None and a[9] == 'test.uncertain' and a[10:] == [None] * 10, a
    assert [c[5] for c in calculations(events)] == ['acting']
    assert state(s) == baseline
    result(s, 215)
    assert query(s, 907, 12, 1) == [], 'a recorded hidden check was disclosed'
    result(s, 216)
    events = query(s, 907, 13, 1)
    r = event(events, 'rpg.roll')
    assert r[6:] == [None] * 12, r
    assert calculations(events)[0][9:14] == [None, None, None, None, 0]
    result(s, 217)
    events = query(s, 907, 14, 1)
    r = event(events, 'rpg.roll')
    assert r[5] is None and r[13:16] == [None, None, None] and r[17] is None
    assert [c[5] for c in calculations(events)] == ['acting']


def test_roll_snapshots(s):
    baseline = state(s)
    assert query(s, 907, 1, 0) == [], 'an unattempted slot produced a roll report'
    result(s, 200)
    original = query(s, 907, 1, 0)
    r = event(original, 'rpg.roll')
    assert r[5:8] == ['check', 'setback', None]
    assert r[8:10] == [30, 1], 'original expenditure was not retained'
    assert r[10:18] == [7, -2, None, None, None, None, 3, 0], r
    assert r[18:] == [4, 1, 2], r
    assert calculations(original)[0][9:14] == [10, None, 10, 5, 1]
    first = state(s)
    for _ in range(10):
        assert query(s, 907, 1, 0) == original
    assert state(s) == first, 'reporting rerolled or charged a recorded attempt'
    s.action(3)
    assert state(s) == baseline
    assert query(s, 907, 1, 0) == [], 'undo left phantom dice or an explanation'
    result(s, 200)
    assert query(s, 907, 1, 0) == original
    s.action(218)
    assert query(s, 907, 1, 0) == original, 'report recalculated changed attributes or modifiers'
    # Retry still explains the original attempt, without a new roll.
    assert result(s, 200)[0] == 'reused'
    assert query(s, 907, 1, 0) == original


def test_contest_faces(s):
    result(s, 204)
    original = query(s, 907, 4, 0)
    r = event(original, 'rpg.roll')
    assert r[10:18] == [7, 4, None, 8, 3, None, 3, 3], r
    assert r[18:] == [4, 1, 2, 1, 5, 2]
    assert [c[12] for c in calculations(original)] == [11, 11]
    s.action(218)
    assert query(s, 907, 4, 0) == original


def test_automatic_report(s):
    result(s, 203)
    events = query(s, 907, 3, 0)
    r = event(events, 'rpg.roll')
    assert r[5:8] == ['automatic', 'success', True]
    assert r[10:18] == [None] * 6 + [0, 0]
    assert calculations(events) == []


def test_skill_snapshot(s):
    s.command('inspect panel')
    original = query(s, 907, 15, 0)
    assert calculations(original)[0][6:14] == [
        'survey.inspection', 'rpg.perception', 'trained', 11, None, 12, 13, 1]
    s.action(218)
    assert query(s, 907, 15, 0) == original, 'skill labels or training changes rewrote history'


def test_restore(Session, bundle, out):
    save = out / 'report.zsave'
    s = Session(bundle)
    try:
        result(s, 204)
        original = query(s, 907, 4, 0)
        s.action(218)
        s.command(f':save {save}\n@900')
        assert any('[save ok code=0]' in line for line in s.raw_lines)
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {save}\n@900')
        assert any('[restore ok code=0]' in line for line in s.raw_lines)
        restored = query(s, 907, 4, 0)
        # Logical restore refreshes runtime handles. Compare the preserved
        # report values and bind every actor to the restored profile's handle.
        actor = event(query(s, 906, 4, 0), 'rpg.assessment')[3]
        def portable(events):
            values = []
            for item in events:
                row = list(item['values'])
                row[4 if item['id'] == 'rpg.calculation' else 3] = 'actor'
                values.append((item['id'], row))
            return values
        assert all(item['values'][4 if item['id'] == 'rpg.calculation' else 3] == actor
                   for item in restored)
        assert portable(restored) == portable(original), 'saved report lost faces or original calculation'
    finally:
        s.close()


def test(Session, bundle, out):
    for case in (test_probabilities, test_assessments, test_disclosure, test_roll_snapshots,
                 test_contest_faces, test_automatic_report, test_skill_snapshot):
        fresh(Session, bundle, case)
        print(f'  {case.__name__}: passed', flush=True)
    test_restore(Session, bundle, out)
    print('  cross-process report restore: passed', flush=True)
