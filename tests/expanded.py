"""Independent source examples and persistence checks for expanded mechanics."""
from native import fresh, last, load_host
from support import ROOT


def state(s):
    s.action(1101)
    return last(s, 'test.expanded-state')


def test_numbers(s):
    before = state(s)
    # Full-2008 B170. Enumerated offsets rather than the implementation formula.
    offsets = {1: [0,-1,-2,-3], 2: [1,0,-1,-2], 4: [2,1,0,-1],
               8: [3,2,1,0], 12: [4,3,2,1]}
    for points, row in offsets.items():
        for difficulty, relative in enumerate(row):
            s.action(1102, difficulty, points, 0)
            assert last(s, 'test.level') == [12 + relative]
        s.action(1102, 3, points * 3, 1)
        assert last(s, 'test.level') == [12 + row[3]]
    s.action(1102,3,2,1)
    assert last(s, 'test.level') == [None]
    for base, a, b, expected in [(10,50,-75,8),(10,0,-90,2),(1,0,-80,1),(15,20,0,18)]:
        s.action(1103,base,a,b)
        assert last(s, 'test.price') == [expected]
    for yards, expected in [(0,0),(2,0),(3,-1),(5,-2),(6,-3),(7,-3),(8,-4),
                            (20,-6),(21,-7),(70,-9),(101,-11),(1005,-17),
                            (200000,-30),(200001,-31),(100000000,-46)]:
        s.action(1104,yards)
        assert last(s, 'test.range') == [expected], (yards,last(s,'test.range'))
    for strength, expected in [(21,[[2,0],[4,-1]]),(28,[[3,-1],[5,1]]),
                               (40,[[4,1],[7,-1]]),(55,[[6,0],[8,1]]),(100,[[11,0],[13,0]])]:
        s.action(1105,strength)
        assert last(s, 'test.damage') == expected[0] + expected[1]
    s.action(1106,3)
    assert last(s, 'test.character') == ['valid',18,-8,13,9,21,7]
    s.action(1106,4)
    assert last(s, 'test.character')[0] == 'secondary-limit'
    # B173's paid-default example, and prohibition on double untrained defaults.
    for points_a, points_b, expected in [(4,0,[13,11,None,11]),(4,1,[13,12,10,11]),
                                        (8,1,[14,12,10,12]),(8,2,[14,13,11,12])]:
        s.action(1107,points_a,points_b)
        assert last(s, 'test.defaults') == expected
    for steps, seconds in [(0,101),(1,202),(2,404),(3,808),(4,1515),(5,3030),(-1,91),(-9,11)]:
        s.action(1108,steps,1)
        assert last(s, 'test.time') == ['ready',None,steps,seconds]
    s.action(1108,-10,1)
    assert last(s,'test.time')[:2] == ['blocked','instant-task-disabled']
    s.action(1108,1,0)
    assert last(s,'test.time')[:2] == ['blocked','task-time-inapplicable']
    s.action(1110)
    assert last(s,'test.template') == [4,2,28], 'template instances share investment or traits'
    s.action(1111)
    assert last(s,'test.invalid') == ['wildcard-disabled','wildcard-default','cyclic-paid-default','unsupported-strength-row']
    assert state(s) == before, 'numeric assessments mutated persistent state'


def test_negative_pricing(s):
    before = state(s)
    # B110's signed example and independent floor/ceiling boundary cases.
    for base, first, second, expected in [
            (-25, -10, 0, -22), (-25, -60, 0, -10),
            (-100, -65, 10, -45), (-15, 0, -90, -3),
            (-1, -80, 0, 0), (1, -80, 0, 1),
            (-10, 50, -75, -7), (0, 100, -50, 0)]:
        s.action(1112, base, first, second)
        assert last(s, 'test.signed-price') == [expected]
    # B121: discard fractional magnitude, rather than floor negative numbers.
    for base, expected in [(-5, [-10, -7, -5, -2]),
                           (-10, [-20, -15, -10, -5]),
                           (-15, [-30, -22, -15, -7])]:
        for rating, cost in zip([6, 9, 12, 15], expected):
            s.action(1113, base, rating)
            assert last(s, 'test.control-price') == [cost]
    s.action(1114)
    assert last(s, 'test.negative-accounting') == [-22, -22, -22, 'point-budget', True, 0]
    s.action(1115)
    assert last(s, 'test.negative-invalid') == [
        'self-control-rating', 'unapproved-trait', 'self-control-modifier-combination']
    assert state(s) == before, 'negative pricing spent time, points or randomness'


def test_technique_bases(s):
    before = state(s)
    # B230-232: a zero-point intermediate technique still permits the default.
    for points, expected in [(0, [10, 12, 13, 50]),
                             (2, [11, 13, 14, 52]),
                             (4, [13, 15, 16, 54])]:
        s.action(1116, points)
        assert last(s, 'test.technique-chain') == expected
    s.action(1117)
    assert last(s, 'test.technique-bases') == [
        15, 'technique-cap', 27, 'technique-default-basis',
        'cyclic-technique-default', 'technique-ownership']
    assert state(s) == before, 'technique assessment changed persistent state'


def test_learning_requirements(s):
    before = state(s)
    # B169 requires paid prerequisite training, even when its default is higher.
    s.action(1118)
    assert last(s, 'test.learning-requirements') == [
        'skill-prerequisite', 'skill-prerequisite', None,
        'skill-prerequisite', None, None, 'cyclic-prerequisite']
    s.action(1119)
    assert last(s, 'test.learning-gates') == [
        'skill-prerequisite', 'skill-prerequisite', 10, 0, 0, 0, 'skill-prerequisite']
    assert state(s) == before, 'rejected learning spent time or randomness'


def familiarity_state(s):
    s.action(1120)
    return last(s, 'test.familiarity-state')


def test_familiarity(s):
    initial = familiarity_state(s)
    assert initial == [0, -2, 0, 1, 0, 6]
    s.action(1121, 28800)
    assert last(s, 'test.familiarity') == ['ready', None, 28800]
    assert familiarity_state(s) == initial
    s.action(1122)
    assert last(s, 'test.familiarity-invalid') == [
        0, 'initial-familiarity-limit', 'duplicate-familiarity', 'familiarity-context']
    s.action(1100, 6, 28799)
    boundary = familiarity_state(s)
    assert boundary == [28799, -2, 28799, 1, 0, 6]
    s.action(1100, 6, 2)
    assert last(s, 'test.familiarity') == ['blocked', 'familiarity-excess-time', 0]
    assert familiarity_state(s) == boundary
    s.action(1100, 7, 1)
    assert familiarity_state(s) == boundary, 'exception leaked familiarity/time'
    s.action(1100, 6, 1)
    complete = familiarity_state(s)
    assert complete == [28800, 0, 28800, 1, 0, 8]
    s.command('undo')
    assert familiarity_state(s) == boundary
    s.action(1100, 6, 1)
    assert familiarity_state(s) == complete
    s.action(1100, 6, 1)
    assert last(s, 'test.familiarity') == ['reused', None, 0]
    assert familiarity_state(s) == complete


def test_familiarity_persistence(Session, bundle, out):
    path = out / 'expanded-familiarity.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 6, 123)
        saved = familiarity_state(first)
        first.command(f':save {path}\n@1120')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
        first.action(1100, 6, 28677)
        continued = familiarity_state(first)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1120')
        assert familiarity_state(second) == saved
        second.action(1100, 6, 28677)
        assert familiarity_state(second) == continued
    finally:
        second.close()


def test_technology_modifiers(s):
    before = state(s)
    # B168: independent table rows, including the impossible boundary.
    for equipment, expected in [(0, -11), (1, -9), (2, -7), (3, -5),
                                (4, -3), (5, -1), (6, 0), (7, -5),
                                (8, -10), (9, -15), (10, None), (12, None)]:
        s.action(1123, 6, equipment, 1)
        assert last(s, 'test.technology-modifier') == [expected]
    for equipment, expected in [(0, -6), (4, -2), (5, -1), (6, 0),
                                (7, -1), (8, -2), (12, -6)]:
        s.action(1123, 6, equipment, 0)
        assert last(s, 'test.technology-modifier') == [expected]
    s.action(1124)
    assert last(s, 'test.technology-context') == [
        9, 11, 3, 1, None, 'technology-too-advanced', 'technology-skill-required']
    assert state(s) == before, 'technology assessment or impossible check consumed resources'


def test_optional_specialties(s):
    before = state(s)
    # B170: hard general skill, average optional specialty; propagated -5 becomes -7.
    for narrow_points, general_points, expected in [
            (4, 0, [13, 11, 6, None, 1]), (8, 0, [14, 12, 7, None, 1]),
            (4, 1, [13, 11, 6, None, 1]), (4, 2, [13, 12, 7, None, 1])]:
        s.action(1125, narrow_points, general_points)
        assert last(s, 'test.optional-specialty') == expected
    s.action(1126)
    assert last(s, 'test.optional-invalid') == [
        'optional-specialty-approval', 'optional-specialty-definition',
        'optional-specialty-definition', 'skill-prerequisite', 'duplicate-optional-specialty']
    assert state(s) == before, 'optional specialty assessment mutated state'


def test_relative_skill(s):
    before = state(s)
    # B172's DX10/IQ14, skill17 example and the two fixed-base comparisons.
    s.action(1127)
    assert last(s, 'test.relative-skill') == [7, 21, 17, 19, 'relative-skill-context', 17, 15, 15]
    for iq, points, expected in [(14, 20, [14, 16]), (8, 32, [17, 19]),
                                 (12, 1, [8, 12]), (12, 0, [None, None])]:
        s.action(1128, iq, points)
        assert last(s, 'test.fixed-skill') == expected
    assert state(s) == before, 'relative skill queries changed state'


def test_study(s):
    initial = state(s)
    s.action(1109,43200)
    assert last(s,'test.study') == ['ready',None,0]
    assert state(s) == initial
    s.action(1100,1,43200)
    assert last(s,'test.study') == ['resolved',None,0]
    after = state(s)
    assert after[:5] == [43200,86400,0,1,0]
    s.action(1100,1,1)
    assert last(s,'test.study')[:2] == ['blocked','study-day-limit']
    assert state(s) == after
    s.action(1100,2,43200)
    s.action(1100,1,1)
    assert state(s)[:2] == [86401,86402]


def test_history(s):
    initial = state(s)
    s.action(1100,1,100)
    after = state(s)
    s.command('undo')
    assert state(s) == initial
    s.action(1100,1,100)
    assert state(s) == after
    s.action(1100,3,100)
    assert state(s) == after, 'throw did not roll back study/time'
    s.action(1100,5)
    s.action(1100,1,1)
    assert state(s)[:5] == [101,0,1,2,0], 'study should invest exactly one point, not award spendable points'


def test_persistence(Session,bundle,out):
    path = out / 'expanded.zsave'
    first = Session(bundle)
    try:
        first.action(1100,1,123)
        saved = state(first)
        first.command(f':save {path}\n@1101')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
        first.action(1100,1,456)
        continued = state(first)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1101')
        assert state(second) == saved
        second.action(1100,1,456)
        assert state(second) == continued
    finally:
        second.close()


def test_example(Session,bundle):
    outcomes = []
    for route in ['parser','structured','dialogue']:
        s = Session(bundle)
        try:
            if route == 'parser':
                s.command('study'); s.command('decode')
            elif route == 'structured':
                s.action(1201); s.action(1202)
            else:
                s.action(80,'workshop-plan'); s.select('study')
                s.action(80,'workshop-plan'); s.select('decode')
            s.log.clear(); s.action(1200)
            outcomes.append([e['values'] for e in s.log if e['id']=='survey.text'])
            assert any('Elapsed seconds: 3840' in row[0] for row in outcomes[-1]), outcomes[-1]
        finally:
            s.close()
    assert outcomes[0] == outcomes[1] == outcomes[2], outcomes


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build('expanded',ROOT / 'tests/fixtures/expanded.t')
    for check in [test_numbers,test_negative_pricing,test_technique_bases,test_learning_requirements,test_familiarity,test_technology_modifiers,test_optional_specialties,test_relative_skill,test_study,test_history]:
        fresh(Session,bundle,check)
        print(f'  expanded {check.__name__}: passed',flush=True)
    test_familiarity_persistence(Session,bundle,build.out)
    test_persistence(Session,bundle,build.out)
    print('  expanded cross-process persistence: passed',flush=True)
    example = build.build('expanded-example',ROOT / 'examples/expanded/main.t')
    test_example(Session,example)
    print('  expanded example parser/action/dialogue parity: passed',flush=True)
