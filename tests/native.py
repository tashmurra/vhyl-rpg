"""Independent expectations exercised through native public command transport."""
import importlib.util
import itertools
import sys
from support import ROOT, run


def load_host(vhyl):
    # Reuse the dependency's example decoder, not private compiler/runtime APIs.
    path = vhyl / 'examples/dialogue/host.py'
    spec = importlib.util.spec_from_file_location('vhyl_example_host', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    class DiagnosedSession(module.Session):
        def read_boundary(self):
            try:
                return super().read_boundary()
            except RuntimeError as error:
                code = self.proc.poll()
                if code is None:
                    raise
                raise RuntimeError(
                    f'{error}\nNative consumer exit: {code} (0x{code & 0xffffffff:08X}); '
                    f'bundle: {self.bundle}') from error
    return DiagnosedSession


def last(session, name):
    return next(e['values'] for e in reversed(session.log) if e['id'] == name)


def state(session):
    session.action(900)
    return last(session, 'test.state')


def result(session, verb):
    session.action(verb)
    return last(session, 'test.result')


def fresh(Session, bundle, test):
    session = Session(bundle)
    try:
        test(session)
    finally:
        session.close()


def test_numbers(s):
    baseline = state(s)
    distribution = {total: 0 for total in range(3, 19)}
    for dice in itertools.product(range(1, 7), repeat=3):
        distribution[sum(dice)] += 1
    # Explicit edge cases also protect the oracle's exceptional results.
    edges = {(3, 4): (True, 'success'), (3, 13): (False, 'failure'),
             (14, 5): (True, None), (15, 5): (True, 'success'),
             (15, 6): (True, None), (16, 6): (True, 'success'),
             (15, 17): (False, 'failure'), (16, 17): (False, None),
             (25, 18): (False, 'failure')}
    for score in range(-2, 26):
        start = len(s.log)
        s.action(901, score)
        checks = [e['values'] for e in s.log[start:] if e['id'] == 'test.check']
        assert len(checks) == 16
        successes = 0
        for row in checks:
            _, roll, status, success, critical, outcome, margin, reason = row
            if score < 3:
                assert [status, success, critical, outcome, margin, reason] == [
                    'blocked', None, None, None, None, 'too-difficult'], row
                continue
            expected = roll <= min(score, 16) or roll in (3, 4)
            high_critical = {3, 4} | ({5} if score >= 15 else set()) | ({6} if score >= 16 else set())
            bad_critical = {18} | ({17} if score <= 15 else set()) | {
                value for value in range(3, 19) if value >= score + 10}
            expected_critical = 'failure' if roll in bad_critical else 'success' if roll in high_critical else None
            assert status == 'resolved' and bool(success) == expected, row
            assert critical == expected_critical and margin == score - roll, row
            assert outcome == ('success' if expected else 'complication' if critical == 'failure' else 'setback'), row
            if (score, roll) in edges:
                assert (bool(success), critical) == edges[score, roll], row
            successes += distribution[roll] if success else 0
        if score == 10:
            assert successes == 108  # Exactly half the 216 possible throws.
        if score == 12:
            assert successes == 160
    # Independent cost/level expectations, including partly invested points.
    relative = {0: [-4, -5, -6], 1: [0, -1, -2], 2: [1, 0, -1],
                3: [1, 0, -1], 4: [2, 1, 0], 7: [2, 1, 0],
                8: [3, 2, 1], 12: [4, 3, 2], 16: [5, 4, 3]}
    for points, offsets in relative.items():
        for difficulty in range(3):
            s.action(902, 11, difficulty, points, -4 - difficulty)
            assert last(s, 'test.skill') == [11 + offsets[difficulty]]
    s.action(902, 25, 1, 0, -5)
    assert last(s, 'test.skill') == [15], 'untrained attribute was not capped'
    s.action(902, 11, 1, 0, 999)
    assert last(s, 'test.skill') == [None], 'a default was invented'
    assert state(s) == baseline, 'pure numeric queries changed gameplay/history'


def test_random(s):
    for seed in (1, 27, 127773, 2147483646):
        start = len(s.log)
        s.action(904, seed)
        actual = [e['values'] for e in s.log[start:] if e['id'] == 'test.random']
        value = seed
        expected = []
        for _ in range(12):
            # Python has unlimited integer arithmetic: no copy of the source's
            # overflow-avoidance calculation is used to derive expectations.
            value = value * 16807 % 2147483647
            expected.append([value % 6 + 1, value])
        assert actual == expected, (seed, actual, expected)


def test_retry(s):
    r = result(s, 200)
    assert r[:7] == ['resolved', 'setback', None, 5, 7, -2, None], r
    first = state(s)
    assert first[3:6] == [3, 9, 30] and first[13] == 1
    for _ in range(60):
        r = result(s, 200)
        assert r[:7] == ['reused', 'setback', None, 5, 7, -2, None]
        assert r[12:] == [0, 0]
    repeated = state(s)
    assert repeated[2:] == first[2:], 'retries charged or rerolled'
    s.command('look')
    assert result(s, 200)[0] == 'reused', 'an unrelated command reopened a challenge'
    s.action(201)
    assert state(s)[18] == 1
    r = result(s, 200)
    assert r[:7] == ['resolved', 'success', True, 8, 8, 0, None], r
    assert state(s)[3:6] == [6, 8, 60]
    assert state(s)[13] == 2
    assert result(s, 200)[0] == 'complete'
    assert state(s)[3:6] == [6, 8, 60]


def test_blocked(s):
    baseline = state(s)
    for code, reason in ((208, 'training-required'), (209, 'too-difficult'),
                         (210, 'insufficient-energy'), (211, 'test.no-tools')):
        r = result(s, code)
        assert r[0] == 'blocked' and r[11] == reason and r[12:] == [0, 0], r
    assert state(s)[2:] == baseline[2:], 'blocked attempts changed RPG state'


def test_automatic(s):
    r = result(s, 203)
    assert r[:7] == ['resolved', 'success', True, None, None, None, None], r
    assert state(s)[3:6] == [0, 9, 30]
    assert state(s)[13] == 1
    assert result(s, 203)[0] == 'complete'
    assert state(s)[13] == 1


def test_costly(s):
    r = result(s, 202)
    assert r[:7] == ['resolved', 'costly-success', True, 5, 7, -2, None], r
    assert state(s)[13:16] == [1, None, 2]


def test_contest(s, code, outcome, achieved, score, opposing):
    r = result(s, code)
    assert r[:6] == ['resolved', outcome, achieved, score, 7, score - 7], r
    assert r[7:10] == [opposing, 8, opposing - 8], r
    assert state(s)[3:6] == [6, 9, 30]


def test_undo(s):
    baseline = state(s)
    r = result(s, 200)
    after = state(s)
    s.action(3)
    assert state(s) == baseline, 'undo did not restore RNG, slot and costs together'
    assert result(s, 200) == r
    assert state(s) == after


def test_rollback(s):
    baseline = state(s)
    for code in (212, 213):
        s.action(code)
        assert state(s) == baseline, 'exception left partial attempt state'
    assert result(s, 200)[4] == 7, 'exception consumed randomness'


def test_npc(s):
    r = result(s, 214)
    assert r[:6] == ['resolved', 'success', True, 7, 7, 0], r
    current = state(s)
    assert current[4] == 10 and current[19] == 9
    s.action(903)
    assert last(s, 'rpg.result')[3] == last(s, 'test.entities')[3]


def test_preview(s):
    s.action(903)
    panel, hatch, key, keeper = last(s, 'test.entities')
    baseline = state(s)
    for _ in range(20):
        for verb, target in ((100, panel), (101, hatch), (102, hatch), (103, keeper), (104, key)):
            s.command(f'@83 i:{verb} h:{target}')
            assert s.log[-1]['id'] == 'action.preview'
    assert state(s) == baseline, 'previews rolled, charged, revealed clues or changed history'
    s.action(80, 'test-plan')
    opened = state(s)
    for _ in range(20):
        s.action(82)
    assert state(s) == opened, 'dialogue refresh mutated gameplay'
    s.select('sample')
    first = state(s)
    s.command('attempt')
    assert last(s, 'test.result')[0] == 'reused'
    assert state(s)[2:] == first[2:], 'parser did not share menu attempt state'


def test_hybrid(Session, bundle):
    outcomes = []
    for route in ('parser', 'structured', 'choice'):
        s = Session(bundle)
        try:
            if route == 'parser':
                s.command('inspect panel')
            elif route == 'structured':
                s.action(903)
                panel = last(s, 'test.entities')[0]
                s.command(f'@100 h:{panel}')
            else:
                s.action(80, 'survey-plan')
                s.select('inspect')
            current = state(s)
            assert current[11] is True and current[8] == 1
            outcomes.append((last(s, 'rpg.result')[4:], current[2:]))
        finally:
            s.close()
    assert outcomes[0] == outcomes[1] == outcomes[2], outcomes


def test_key(s):
    s.command('use key')
    assert last(s, 'rpg.result')[4:7] == ['blocked', None, 'survey.need-key']
    s.command('take key')
    s.command('use key')
    assert last(s, 'rpg.result')[4:6] == ['resolved', 'success']
    current = state(s)
    assert current[3:6] == [0, 10, 5] and current[12] is True
    s.command('force hatch')
    assert last(s, 'rpg.result')[4] == 'complete'
    assert state(s)[3:6] == [0, 10, 5]


def test_persistence(Session, bundle, out):
    saved = out / 'settled.zsave'
    s = Session(bundle)
    try:
        result(s, 200)
        before = state(s)
        s.command(f':save {saved}\n@900')
        assert any('[save ok code=0]' in line for line in s.raw_lines)
        s.action(201)
        result(s, 200)
    finally:
        s.close()
    # A new process proves the state is in the logical save, not a Python cache.
    s = Session(bundle)
    try:
        s.command(f':restore {saved}\n@900')
        assert any('[restore ok code=0]' in line for line in s.raw_lines)
        restored = state(s)
        assert restored[0] == before[0] and restored[1] == 0 and restored[2:] == before[2:]
        assert result(s, 200)[0] == 'reused'
        assert state(s)[2:] == restored[2:]
        s.action(201)
        assert result(s, 200)[:6] == ['resolved', 'success', True, 8, 8, 0]
    finally:
        s.close()


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build('mechanics', ROOT / 'tests/fixtures/mechanics.t')
    tests = [test_numbers, test_random, test_retry, test_blocked, test_automatic,
             test_costly, test_undo, test_rollback, test_npc, test_preview, test_key]
    for check in tests:
        fresh(Session, bundle, check)
        print(f'  {check.__name__}: passed', flush=True)
    for code, outcome, achieved, score, opposing in (
        (204, 'success', True, 11, 11), (205, 'setback', None, 5, 11),
        (206, 'success', True, 5, 3), (207, 'tie', None, 10, 11)):
        fresh(Session, bundle, lambda s: test_contest(s, code, outcome, achieved, score, opposing))
    print('  opposed outcomes: passed', flush=True)
    test_hybrid(Session, bundle)
    test_persistence(Session, bundle, build.out)
    print('  hybrid parity and cross-process restore: passed', flush=True)
    import reporting
    reporting.test(Session, bundle, build.out)
    example = build.build('hybrid', ROOT / 'examples/hybrid/main.t')
    fresh(Session, example, lambda s: s.command('examine panel'))
    host_save = build.out / 'example-host.zsave'
    output = run([sys.executable, ROOT / 'examples/hybrid/host.py', example,
                  '--vhyl', build.vhyl], timeout=60,
                 input=f':plan\n:1\n:save {host_save}\n:restore {host_save}\n:quit\n')
    assert ':1 Study the fine annotations' in output, output
    assert 'You identify a quiet release technique.' in output, output
    assert '[save ok code=0]' in output and '[restore ok code=0]' in output, output
    assert '3d6:' not in output, 'example displayed details without the player opting in'
    detailed = run([sys.executable, ROOT / 'examples/hybrid/host.py', example,
                    '--vhyl', build.vhyl, '--details'], timeout=60,
                   input=':odds\n:plan\n:1\n:odds\n:quit\n')
    assert '37.5% chance of achieving the goal' in detailed, detailed
    assert '74.1% chance of achieving the goal' in detailed, detailed
    assert '3d6: 4 + 1 + 2 = 7, against 13' in detailed, detailed
    assert 'Used: Inspection 12 +1 Careful eye = 13' in detailed, detailed
    assert 'Outcome uncertain' in detailed and 'Opposition would use:' not in detailed, detailed
    minimal = build.build('no-language', ROOT / 'tests/fixtures/no-language.t')
    def event_only(s):
        s.action(100)
        assert last(s, 'rpg.result')[4:6] == ['resolved', 'success']
    fresh(Session, minimal, event_only)
    print('  playable host and language-independent module: passed', flush=True)
    import resilience
    resilience.test(build)
    import lite
    lite.test(build)

    import expanded
    expanded.test(build)

    import bellwether
    bellwether.test(build)

    import character_social
    character_social.test(build)
