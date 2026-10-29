"""Native running contracts, elapsed-time boundaries and journalled continuation."""
from native import fresh, last, load_host
from support import ROOT
from fright import Dice, find_seed, succeeds

STATE = '''hp fp unconscious dead collapse rest elapsed sprint paced acceleration pace eligible
rng draws seconds unconscious_clock penalty_seconds penalty condition_ticks'''.split()
RESULT = 'status reason seconds fatigue injury checks'.split()


def do(s, code, *args):
    s.action(700, code, *args)


def state(s):
    s.action(990)
    return dict(zip(STATE, last(s, 'test.running-state'), strict=True))


def result(s):
    s.action(991)
    end = len(s.log) - 1
    start = max(i for i in range(end) if s.log[i]['id'] == 'test.running-result')
    checks = [e['values'] for e in s.log[start + 1:end] if e['id'] == 'test.running-check']
    return dict(zip(RESULT, s.log[start]['values'], strict=True)), checks


def preview(s):
    s.action(992)
    return last(s, 'test.running-preview')


def configure(s, ht=10, dx=10, fp=10, will=10, points=0):
    do(s, 2, ht, dx, fp - ht, will - 10, points)


def test_intervals(s):
    seed = find_seed(lambda d: d.roll() > 10)
    do(s, 1, seed)
    before = state(s)
    do(s, 3, 14)
    assert state(s)['draws'] == before['draws'] and state(s)['fp'] == 10
    do(s, 3, 1)
    r, checks = result(s)
    assert (r['fatigue'], r['checks'], checks[0][0]) == (1, 1, 10)
    assert state(s)['sprint'] == 0 and state(s)['fp'] == 9
    # Success incurs no fatigue, including on a hot day.
    do(s, 1, 1)  # first roll is 7
    do(s, 12, 2)
    do(s, 3, 15)
    assert result(s)[0]['fatigue'] == 0
    do(s, 4, 'paced')
    do(s, 3, 59)
    held = state(s)
    do(s, 1, seed)
    do(s, 3, 1)
    assert state(s)['paced'] == 0 and state(s)['fp'] == held['fp'] - 3
    assert result(s)[0]['checks'] == 1


def test_scores(s):
    for points, expected, chosen in [(0, 10, 'ht'), (1, 10, 'ht'), (2, 10, 'ht'),
                                      (4, 11, 'running'), (8, 12, 'running')]:
        configure(s, points=points)
        assert preview(s)[1:3] == [expected, chosen]
    do(s, 10, 3, 0)
    assert preview(s)[1:3] == [13, 'ht']
    do(s, 10, 0, -2)
    assert preview(s)[1:3] == [10, 'ht'], 'effective-score ties choose HT'
    do(s, 10, -3, 0)
    assert preview(s)[1:3] == [12, 'running']
    do(s, 1, 1)
    do(s, 3, 60)
    r, checks = result(s)
    assert r['checks'] == 4 and state(s)['draws'] == 12
    assert all(c[0] == 12 for c in checks)
    d = Dice(1)
    rolls = [d.roll() for _ in range(4)]
    assert [c[1] for c in checks] == rolls
    assert r['fatigue'] == sum(not succeeds(12, roll) for roll in rolls)


def test_speed(s):
    configure(s, ht=14, dx=14, fp=12)
    assert preview(s)[0] == 700
    do(s, 3, 1)
    assert preview(s)[0] == 840
    do(s, 5)
    assert preview(s)[0] == 700
    do(s, 3, 1)
    do(s, 6, 0)
    assert preview(s)[0] == 700
    do(s, 3, 1)
    do(s, 6, 1)
    assert preview(s)[0] == 700
    do(s, 3, 1)
    assert preview(s)[0] == 840
    do(s, 4, 'paced')
    assert preview(s)[0] == 420
    do(s, 4, 'sprint')
    assert preview(s)[0] == 700
    do(s, 3, 1)
    # Exactly 1/3 is not penalized; the legacy journey still is.
    do(s, 7, 8, 0, 0)
    assert preview(s)[0] == 840 and preview(s)[3] == 350
    do(s, 7, 7, 0, 0)
    assert preview(s)[0] == 840
    do(s, 7, 9, 0, 0)
    assert preview(s)[0] == 500  # Move 7 halves upward to 4, minimum sprint +1.
    do(s, 4, 'paced')
    assert preview(s)[0] == 250
    # Load affects Move, not the fatigue-check target.
    do(s, 7, 0, 0, 0)
    do(s, 11, 2001)  # Light load, ST 10.
    assert preview(s)[0] == 300 and preview(s)[1] == 14
    do(s, 11, 20001)  # Beyond extra-heavy: cannot run.
    before = state(s)
    do(s, 3, 60)
    assert result(s)[0]['reason'] == 'cannot-move'
    assert state(s)['seconds'] == before['seconds'] and preview(s)[0] == 0


def test_exhaustion(s):
    # First fatigue roll fails, following Will succeeds, next Will fails.
    seed = find_seed(lambda d: d.roll() > 10 and succeeds(10, d.roll()) and not succeeds(10, d.roll()))
    do(s, 1, seed)
    do(s, 7, 9, 0, 599)
    do(s, 3, 30)
    r, checks = result(s)
    assert (r['status'], r['reason'], r['seconds'], r['fatigue']) == ('stopped', 'cannot-act', 16, 1), r
    assert len(checks) == 3 and state(s)['fp'] == 0 and state(s)['collapse'] is True
    assert state(s)['rest'] == 0 and state(s)['acceleration'] == 0
    # A blocked follow-up consumes no time or dice.
    before = state(s)
    do(s, 3, 60)
    assert state(s) == before and result(s)[0]['status'] == 'blocked'
    do(s, 8, 599)
    assert state(s)['fp'] == 0
    do(s, 8, 1)
    assert state(s)['fp'] == 1 and state(s)['unconscious'] is None


def test_overflow(s):
    configure(s, fp=1, will=20)
    # Fifteen successful effort rolls; first running fatigue check then fails.
    def scenario(d):
        return all(succeeds(20, d.roll()) for _ in range(15)) and d.roll() > 10
    seed = find_seed(scenario)
    do(s, 1, seed)
    do(s, 7, 1, 0, 0)
    do(s, 3, 20)
    r, checks = result(s)
    assert (r['seconds'], r['injury'], r['fatigue'], r['status']) == (15, 1, 1, 'stopped'), r
    assert state(s)['hp'] == 9 and state(s)['fp'] == -1 and state(s)['unconscious'] is True
    assert len(checks) == 16 and checks[-1][0] == 10


def test_rest_and_switches(s):
    do(s, 3, 14)
    do(s, 5)
    do(s, 4, 'paced')
    do(s, 3, 59)
    assert (state(s)['sprint'], state(s)['paced']) == (14, 59)
    do(s, 4, 'sprint')
    do(s, 3, 1)
    assert result(s)[0]['checks'] == 1
    do(s, 4, 'paced')
    do(s, 3, 1)
    assert result(s)[0]['checks'] == 1
    do(s, 7, 4, 0, 0)
    do(s, 8, 599)
    assert state(s)['fp'] == 6
    do(s, 3, 1)
    assert state(s)['rest'] == 0
    do(s, 5)
    do(s, 8, 599)
    assert state(s)['fp'] == 6
    do(s, 8, 1)
    assert state(s)['fp'] == 7
    do(s, 18, 3)
    do(s, 8, 600)
    assert state(s)['fp'] == 7, 'rest recovered locked fatigue'


def test_injury_checks(s):
    configure(s, ht=20, fp=1, will=18)
    def scenario(d):
        return all(succeeds(18, d.roll()) and succeeds(20, d.roll()) for _ in range(15)) and d.roll() >= 17
    do(s, 1, find_seed(scenario))
    do(s, 7, 1, 19, 0)  # HP -9: overflow crosses the first death-check threshold.
    do(s, 3, 15)
    r, checks = result(s)
    assert r['seconds'] == 15 and r['injury'] == 1 and state(s)['hp'] == -10
    assert [c[0] for c in checks] == [18, 20] * 15 + [20, 20], checks
    assert r['checks'] == 32, 'receipt lost effort, consciousness or injury checks'


def test_contracts(s):
    do(s, 3, 4)
    do(s, 7, 2, 0, 123)
    before = state(s)
    for _ in range(4):
        preview(s)
    do(s, 3, 0)
    assert state(s) == before and result(s)[0]['seconds'] == 0
    do(s, 13, 'swim')
    s.action(993)
    assert last(s, 'test.running-error') == ['running-pace']
    assert state(s) == before
    for seconds in (-1, 86401, 'invalid'):
        do(s, 3, seconds)
        assert state(s) == before
    do(s, 9, 60)
    assert state(s) == before, 'exception did not roll back activity and health'
    do(s, 3, 60)
    after = state(s)
    s.action(3)  # undo
    assert state(s) == before
    do(s, 3, 60)
    assert state(s) == after


def test_legacy(s):
    configure(s, fp=12, points=16)
    do(s, 7, 8, 0, 0)
    assert preview(s)[3] == 250, 'including the extension changed the Lite FP boundary'
    do(s, 15, 15)
    # Legacy journey only sets its single check, not checks[].
    assert state(s)['draws'] == 3
    assert state(s)['elapsed'] == 0, 'legacy journey activated the expanded activity'


def test_partition(Session, bundle):
    def run(split):
        s = Session(bundle)
        try:
            configure(s, ht=10, fp=4, will=14)
            do(s, 1, 32)
            do(s, 14, 2, 8)
            # Test condition clocks as well as fatigue counters and draws.
            def advance(n):
                for amount in ([1] * n if split else [n]):
                    do(s, 3, amount)
            advance(14)
            assert state(s)['condition_ticks'] == 14 and state(s)['penalty'] == 0
            do(s, 4, 'paced')
            advance(59)
            do(s, 5)
            do(s, 4, 'sprint')
            advance(100)
            do(s, 4, 'paced')
            advance(60)
            return state(s)
        finally:
            s.close()
    assert run(False) == run(True), 'batching changed running or health state'


def test_persistence(Session, bundle, out):
    path = out / 'expanded-running.zsave'
    s = Session(bundle)
    try:
        configure(s, points=8)
        do(s, 1, 2024)
        do(s, 3, 14)
        do(s, 4, 'paced')
        do(s, 3, 59)
        do(s, 4, 'sprint')
        saved = state(s)
        s.command(f':save {path}\n@990')
        assert any('[save ok code=0]' in line for line in s.raw_lines)
        do(s, 3, 40)
        future = state(s)
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@990')
        assert any('[restore ok code=0]' in line for line in s.raw_lines)
        assert state(s) == saved
        do(s, 3, 40)
        assert state(s) == future
    finally:
        s.close()


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build('expanded-running', ROOT / 'tests/fixtures/expanded-running.t')
    for check in (test_intervals, test_scores, test_speed, test_exhaustion, test_overflow,
                  test_rest_and_switches, test_injury_checks, test_contracts, test_legacy):
        fresh(Session, bundle, check)
        print(f'  running {check.__name__}: passed', flush=True)
    test_partition(Session, bundle)
    test_persistence(Session, bundle, build.out)
    print('  running partition and persistence: passed', flush=True)
    # Run the complete Lite fixture with the extension present, too.
    fixture = (ROOT / 'tests/fixtures/lite.t').read_text()
    fixture = fixture.replace('liteRoom:', '#include <vhyl-rpg-expanded.t>\n'
        '#include <vhyl-rpg-expanded-skills.t>\n#include <vhyl-rpg-expanded-running.t>\nliteRoom:', 1)
    source = build.out / 'lite-with-running.t'
    source.write_text(fixture)
    import lite
    lite.test(build, build.build('lite-with-running', source))
