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
    assert last(s,'test.invalid') == ['wildcard-disabled','cyclic-paid-default','unsupported-strength-row']
    assert state(s) == before, 'numeric assessments mutated persistent state'


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
    for check in [test_numbers,test_study,test_history]:
        fresh(Session,bundle,check)
        print(f'  expanded {check.__name__}: passed',flush=True)
    test_persistence(Session,bundle,build.out)
    print('  expanded cross-process persistence: passed',flush=True)
    example = build.build('expanded-example',ROOT / 'examples/expanded/main.t')
    test_example(Session,example)
    print('  expanded example parser/action/dialogue parity: passed',flush=True)
