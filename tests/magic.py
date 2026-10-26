"""Independent casting/accounting and delayed GM-reply integration checks."""
from native import fresh, last, load_host
from support import ROOT, run
from fright import Dice, find_seed
import sys
sys.path.insert(0, str(ROOT / 'hosts'))
from vhyl_gm import decode_request, Exchange, AuthoredAdjudicator


def do(s, code, *args): s.action(710, code, *args)
def state(s):
    s.action(990)
    return last(s, 'test.magic-state')
def assess(s):
    s.action(991)
    return last(s, 'test.magic-assess')
def result(s):
    s.action(992)
    return last(s, 'test.magic-result')
def gm(s):
    s.action(993)
    return last(s, 'test.gm-result')
def rule(s, mode='subtle'): do(s, 2, mode, 0)
def cast(s): do(s, 4)


def test_pure_and_duplicate(s):
    before = state(s)
    for _ in range(3): assert assess(s)[0] == 'needs-ruling'
    assert state(s) == before
    rule(s)
    assert assess(s)[:5] == ['ready', None, 16, 0, 1]
    assert state(s) == before
    do(s, 1, 1); cast(s)
    assert result(s)[2:10] == [16, Dice(1).roll(), None, 'full', True, 0, 1, 0]
    saved = state(s)
    assert saved[3:10] == [3, 1, 1, None, True, 'bronze', 1]
    s.action(994)
    assert last(s, 'test.magic-other')[0] == 'reused'
    cast(s)
    assert state(s) == saved


def test_reply_validation(s):
    do(s, 6)
    for effect, mode, modifier in [('missing', 'subtle', 0), ('inspect-material', 'guess', 0),
                                    ('inspect-material', 'subtle', 99)]:
        do(s, 7, effect, mode, modifier)
        assert gm(s)[0] == 'blocked', gm(s)
    do(s, 7, 'inspect-material', 'subtle', 0)
    assert gm(s)[0] == 'ruled'
    do(s, 7, 'inspect-material', 'subtle', 0)
    assert gm(s)[0] == 'reused'
    do(s, 7, 'inspect-material', 'overt', 0)
    assert gm(s)[0] == 'blocked'
    do(s, 5, 'iron')
    assert assess(s)[0] == 'needs-ruling'
    do(s, 7, 'inspect-material', 'subtle', 0)
    assert gm(s)[0] == 'blocked'
    do(s, 6); do(s, 24); do(s, 25)
    assert gm(s)[0] == 'blocked'
    assert state(s)[3:6] == [0, 0, 0]


def test_modifiers_and_practice(s):
    do(s, 3, 2, 1, 2); rule(s)
    assert assess(s)[2:5] == [19, 2, 2]  # 14 + 2 subtle + 4 reserve + 1 time - 2 unfamiliar
    cast(s)
    assert state(s)[0] == 0 and state(s)[4] == 2


def test_requirements(s):
    do(s, 30); rule(s)
    assert assess(s)[2] == 15  # min(14,14) - 1 conjunction + 2 subtle
    do(s, 26); rule(s)
    assert assess(s)[1] == 'magic-practice'
    do(s, 28); rule(s)
    assert gm(s)[0] == 'blocked'
    assert state(s)[3:6] == [0, 0, 0]


def test_target_limits(s):
    do(s, 37, 17); rule(s)
    assert assess(s)[1] == 'target-too-large'
    do(s, 37, 8); do(s, 36); rule(s)
    assert assess(s)[1] == 'touch-required'
    cast(s)
    assert state(s)[3:6] == [0, 0, 0]


def test_bound_relearning(s):
    do(s, 18, 0); rule(s)
    assert assess(s)[1] == 'magic-bound-tool'
    do(s, 9, 4, 1, 0); do(s, 18, 1); rule(s)
    assert assess(s)[1] == 'magic-permission'
    do(s, 19)
    assert state(s)[10:13] == [97, 1, 3]
    rule(s)
    assert assess(s)[2] == 18  # retained trained skill + bound bonus
    s.action(995)
    assert last(s, 'test.magic-costs') == [3, 13, 23, 33, 45, 165, 4, 1, 329]


def test_formula_and_preparation(s):
    do(s, 16); rule(s)
    assert assess(s)[2] == 19
    s.action(995)
    assert last(s, 'test.magic-costs')[-1] == 330
    do(s, 3, 0, 1, 0); rule(s)
    assert assess(s)[1] == 'magic-fixed-time'
    do(s, 3, 0, 0, 0); do(s, 1, 1); do(s, 17)
    prepared = state(s)
    do(s, 17)
    assert state(s) == prepared and prepared[3:5] == [3, 2]
    rule(s)
    assert assess(s)[2] == 20


def test_retries(s):
    do(s, 10, 100)
    for slot in (1, 2, 3):
        do(s, 11, slot); do(s, 1, 1); rule(s)
        assert assess(s)[2] == 17 - slot
        cast(s)
        assert result(s)[5] == 'insufficient' and state(s)[5] == slot
    do(s, 12); do(s, 11, 1); rule(s)
    assert assess(s)[0] == 'ready'  # explicit authored circumstance change


def test_critical_and_strain(s):
    seed = find_seed(lambda d: d.roll() == 18)
    do(s, 1, seed); rule(s); cast(s)
    assert result(s)[4:6] == ['failure', 'failure']
    assert state(s)[1] == 1 and state(s)[6] is True and state(s)[3] == 3
    do(s, 11, 2); rule(s)
    assert assess(s)[1] == 'magic-retry-limit'


def test_overt_and_capacity(s):
    do(s, 20, 1); do(s, 1, 1); rule(s, 'overt'); cast(s)
    assert result(s)[9] == 1
    do(s, 13, 25)
    assert state(s)[:3] == [0, 26, 0]
    do(s, 14, 3); do(s, 1, 1); do(s, 15)
    # 29 total, roll 10: strength 19, only temporary strain discharges.
    assert state(s)[:3] == [0, 7, 3] and state(s)[13] == 19
    assert state(s)[3] == 3  # seed reset: only the discharge drew dice


def test_consequence(s):
    do(s, 13, 29); do(s, 1, 1); do(s, 15)
    assert state(s)[13] == 19
    do(s, 34, 3); do(s, 33)
    assert state(s)[13] == 19, 'wrong-band handler consumed pending consequence'
    do(s, 34, 4); do(s, 33)
    assert state(s)[2] == 1 and state(s)[13] == 0
    do(s, 33); s.action(996)
    assert last(s, 'test.magic-resource')[:2] == [19, 1], 'consequence applied twice'


def test_storage(s):
    do(s, 35); do(s, 32, 10)
    assert state(s)[0] == 2, 'without power rank one, storage is limited to channel'
    s.action(996)
    assert last(s, 'test.magic-resource')[2:] == [2, 0]
    do(s, 32, 10)
    assert state(s)[0] == 2


def test_waiting_and_unsupported(s):
    do(s, 6); do(s, 31, 'needs-input')
    assert assess(s)[0] == 'needs-input'
    rule(s)
    assert gm(s)[0] == 'needs-input', 'authored provider must not override pending human input'
    assert state(s)[3:6] == [0, 0, 0]


def test_high_skill_natural_failure(s):
    do(s, 3, 2, 0, 0)
    do(s, 1, find_seed(lambda d: d.roll() == 17))
    rule(s, 'overt'); cast(s)
    assert result(s)[2:6] == [18, 17, None, 'failure']
    assert state(s)[:3] == [0, 1, 0]


def test_world_turn(s):
    rule(s); s.action(700, 2, 1)
    do(s, 22)
    s.action(994)
    assert last(s, 'test.magic-other') == ['blocked', 'magic-world-turn']
    assert state(s)[3] == 3


def test_rollback(s):
    do(s, 8); rule(s)
    before = state(s)
    cast(s)
    assert state(s) == before, 'throw must restore RNG, receipt, resources and delivery'


def test_undo(s):
    rule(s)
    before = state(s)
    cast(s)
    after = state(s)
    s.action(3)
    assert state(s) == before
    cast(s)
    assert state(s) == after


def test_host_roundtrip(s):
    start = len(s.log)
    do(s, 23)
    packet = decode_request(s.log[start:])
    bridge = Exchange()
    request = bridge.register(packet)
    reply = AuthoredAdjudicator({'inspect': ['inspect-material', 'subtle', 0, 'Host ruling.']}).adjudicate(request)
    checked = bridge.validate(reply)
    s.action(700, 1, 4, checked['serial'], checked['status'], *checked['ruling'])
    assert gm(s)[0] == 'ruled'
    assert assess(s)[0] == 'ready'


def test_partial(s):
    seed = find_seed(lambda d: d.roll() == 15)
    do(s, 1, seed); s.action(700, 2, 1); s.action(700, 2, 2)
    assert result(s)[5:7] == ['partial', True]
    assert state(s)[9] == 1


def test_persistence(Session, bundle, out):
    path = out / 'magic.zsave'
    s = Session(bundle)
    try:
        do(s, 6)
        s.command(f':save {path}\n@990')
        assert any('[save ok code=0]' in line for line in s.raw_lines)
    finally: s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@990')
        do(s, 7, 'inspect-material', 'subtle', 0)
        assert gm(s)[0] == 'ruled'
        cast(s)
        saved = state(s)
        s.command(f':save {path}\n@990')
    finally: s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@990')
        assert state(s) == saved
        cast(s)
        assert result(s)[0] == 'reused' and state(s) == saved
    finally: s.close()


def test_input_parity(Session, bundle):
    outcomes = []
    for route in ('parser', 'structured', 'dialogue'):
        s = Session(bundle)
        try:
            rule(s)
            if route == 'parser': s.command('inspect material')
            elif route == 'structured': s.action(700, 1, 2)
            else:
                s.action(80, 'workshop')
                s.select('inspect')
            outcomes.append((result(s), state(s)))
            saved = state(s)
            s.command('inspect material')
            assert result(s)[0] == 'reused' and state(s) == saved
        finally: s.close()
    assert outcomes[0] == outcomes[1] == outcomes[2]


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build('magic', ROOT / 'tests/fixtures/magic.t')
    for check in (test_pure_and_duplicate, test_reply_validation, test_modifiers_and_practice,
                  test_requirements, test_target_limits, test_bound_relearning, test_formula_and_preparation,
                  test_retries, test_critical_and_strain, test_overt_and_capacity, test_world_turn,
                  test_rollback, test_undo, test_host_roundtrip, test_partial, test_consequence,
                  test_storage, test_waiting_and_unsupported, test_high_skill_natural_failure):
        fresh(Session, bundle, check)
        print(f'  magic {check.__name__}: passed', flush=True)
    test_input_parity(Session, bundle)
    print('  magic parser/action/dialogue parity: passed', flush=True)
    test_persistence(Session, bundle, build.out)
    print('  magic cross-process persistence: passed', flush=True)

    example = build.build('magic-workshop', ROOT / 'examples/magic/main.t')
    output = run([sys.executable, ROOT / 'examples/magic/host.py', example,
                  '--vhyl', build.vhyl], timeout=60,
                 input='preview inspect\nrule inspect\npreview inspect\ncast inspect\ncast inspect\nquit\n')
    for status in ('needs-ruling', 'ready', 'resolved', 'reused'):
        assert f'inspect: {status};' in output, output
    print('  magic playable provider-neutral host: passed', flush=True)
