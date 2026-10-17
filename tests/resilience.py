"""Native expectations for conditions, care, short conflicts and development."""
from pathlib import Path
import sys

from native import fresh, last, load_host
from support import ROOT, run

FIELDS = '''turn undo rng draws seconds injury hp shock stunned unconscious dead aid rest healing
energy charges earned bank revision aid_points brawl_points will iq ht max_energy passage permit
goal_revision slot_revision active finished outcome exchanges enemy_injury enemy_stun enemy_out
attitude aid_bought poise_bought nerves_removed bank_claimed throw_claimed new_points new_score
st max_hp npc_bank perception throw_bought development_open'''.split()


def state(session):
    session.action(950)
    return dict(zip(FIELDS, last(session, 'test.resilience'), strict=True))


def gameplay(value):
    return {k: v for k, v in value.items() if k not in ('turn', 'undo')}


def test_injury(s):
    before = state(s)
    for damage, armor, numerator, denominator, expected in (
        (0, 0, 1, 1, 0), (5, 8, 2, 1, 0), (1, 0, 1, 2, 1),
        (7, 2, 3, 2, 7), (7, 2, 2, 1, 10)):
        s.action(951, damage, armor, numerator, denominator)
        assert last(s, 'test.injury') == [expected]
    assert state(s) == before
    s.action(503)
    current = state(s)
    assert (current['injury'], current['hp'], current['shock'], current['draws']) == (6, 4, 3, 0)
    s.action(500)
    assert state(s)['shock'] == 4
    s.action(502)
    current = state(s)
    assert current['unconscious'] is True and current['dead'] is None
    before = current
    s.action(402)
    assert gameplay(state(s)) == gameplay(before), 'incapacitation allowed a challenge'
    s.action(410)
    current = state(s)
    assert current['hp'] == 1 and current['unconscious'] is None
    s.command('find permit')
    s.command('show permit')
    assert state(s)['passage'] is True, 'rescue did not preserve a reliable completion route'


def test_major_wound_and_lethality(s):
    s.action(501)
    current = state(s)
    assert current['hp'] == 1 and current['draws'] == 3 and current['shock'] == 4
    assert current['stunned'] is None, 'successful health roll caused stun'
    s.action(517)
    current = state(s)
    assert current['hp'] == -50 and current['dead'] is True and current['unconscious'] is True
    before = current
    s.action(404)
    assert gameplay(state(s)) == gameplay(before), 'rest revived a dead body'


def test_treatment(s):
    s.action(403)
    current = state(s)
    assert current['injury'] == 2 and current['aid'] == 0 and current['charges'] == 1
    assert current['seconds'] == 660 and current['draws'] == 4
    s.action(403)
    assert gameplay(state(s)) == gameplay(current), 'repeated treatment farmed healing or spent supplies'
    s.action(500)
    assert state(s)['aid'] == 2
    s.action(403)
    current = state(s)
    assert current['injury'] >= 2 and current['aid'] == 0 and current['charges'] == 0


def test_treatment_failure(s):
    s.action(530)
    s.action(403)
    current = state(s)
    assert current['injury'] == 2 and current['charges'] == 1 and current['draws'] == 3


def test_treatment_critical_failure(s):
    s.action(530)
    s.action(531)
    s.action(403)
    current = state(s)
    assert current['injury'] == 5 and current['aid'] == 0 and current['charges'] == 1
    assert current['draws'] == 3


def test_rest(s):
    s.action(518)
    current = state(s)
    assert current['rest'] == 599 and current['energy'] == 6 and current['draws'] == 0
    s.action(519)
    current = state(s)
    assert current['rest'] == 0 and current['energy'] == 7 and current['seconds'] == 600
    s.action(411)
    current = state(s)
    assert current['energy'] == 10 and current['injury'] == 2 and current['draws'] == 3
    assert current['seconds'] == 87000 and current['healing'] == 600
    before = current
    s.command('wait')
    assert gameplay(state(s)) == gameplay(before), 'ordinary WAIT automatically healed or rested'


def test_interruption_and_exhaustion(s):
    s.action(518)
    s.action(520)
    s.action(519)
    current = state(s)
    assert current['energy'] == 6 and current['rest'] == 1 and current['healing'] == 1
    s.action(504)
    s.action(952)
    assert last(s, 'test.strength') == [10, 5, 'condition', 'rpg.modifier.exhaustion', -5]
    s.action(406)
    before = state(s)
    s.action(407)
    assert gameplay(state(s)) == gameplay(before), 'exhausted attack consumed dice, time or an exchange'
    assert last(s, 'rpg.conflict')[3] == 'rpg.exhausted'
    s.action(412)
    assert state(s)['outcome'] == 'surrendered'


def test_stun(s):
    s.action(505)
    before = state(s)
    s.action(402)
    assert gameplay(state(s)) == gameplay(before)
    s.command('recover')
    current = state(s)
    assert current['stunned'] is None and current['draws'] == 3 and current['seconds'] == 1


def test_shock_assessment(s):
    s.action(500)
    before = state(s)
    s.action(405)
    calculation = last(s, 'rpg.calculation')
    assert calculation[11:13] == [11, 9]
    assert calculation[-3:] == ['condition', 'rpg.modifier.shock', -2]
    assert state(s) == before
    s.action(402)
    assert state(s)['shock'] == 0
    s.log.clear()
    s.action(954)
    assert last(s, 'rpg.calculation')[12] == 9, 'historical shock was recalculated after it expired'


def test_social(s):
    s.action(529)
    s.action(402)
    current = state(s)
    assert current['attitude'] == -1 and current['draws'] == 6 and current['slot_revision'] == 0
    s.action(954)
    original = [e for e in s.log if e['id'] in ('rpg.roll', 'rpg.calculation')][-2:]
    s.action(402)
    assert gameplay(state(s)) == gameplay(current), 'social retry changed disposition or rolled again'
    s.action(506)
    s.action(509)
    s.log.clear()
    s.action(954)
    assert [e for e in s.log if e['id'] in ('rpg.roll', 'rpg.calculation')] == original
    s.action(400)
    s.action(402)
    current = state(s)
    assert current['draws'] == 12 and current['slot_revision'] == 1


def test_social_permission(s):
    s.action(515)
    before = state(s)
    for _ in range(3):
        s.action(402)
    assert gameplay(state(s)) == gameplay(before), 'opposed dice overrode an explicit refusal'


def test_progression(s):
    before = state(s)
    assert before['new_points'] == 0 and before['new_score'] == 6
    s.action(414)
    assert gameplay(state(s)) == gameplay(before)
    s.action(506)
    before = state(s)
    s.action(505)
    incapacitated = state(s)
    s.command('train aid')
    assert gameplay(state(s)) == gameplay(incapacitated), 'stun allowed development practice'
    s.action(3)
    s.action(3)
    assert state(s) == before, 'undo did not restore the development window'
    for _ in range(20):
        s.action(405)
    assert state(s) == before, 'development or assessment queries changed state/history'
    s.action(414)
    current = state(s)
    assert current['bank'] == 58 and current['aid_points'] == 4 and current['aid_bought'] is True
    s.action(414)
    assert gameplay(state(s)) == gameplay(current), 'purchase charged twice'
    s.action(506)
    assert state(s)['bank'] == 58 and state(s)['earned'] == 60, 'milestone awarded twice'
    s.action(512)
    assert state(s)['new_points'] == 2 and state(s)['new_score'] == 11
    s.action(417)
    assert state(s)['poise_bought'] is True and state(s)['goal_revision'] == 1
    s.action(418)
    assert state(s)['nerves_removed'] is True
    s.action(513)
    before = state(s)
    s.action(415)
    assert gameplay(state(s)) == gameplay(before), 'purchase bypassed downtime'
    s.action(522)
    assert state(s)['npc_bank'] == 60 and state(s)['earned'] == 60


def test_attributes(s):
    s.action(506)
    s.action(416)
    assert state(s)['will'] == 12
    s.action(509)
    current = state(s)
    assert current['iq'] == 12 and current['will'] == 13 and current['perception'] == 12
    s.action(510)
    current = state(s)
    assert current['ht'] == 11 and current['max_energy'] == 11 and current['energy'] == 7
    s.action(511)
    current = state(s)
    assert current['st'] == 11 and current['max_hp'] == 11 and current['hp'] == 8


def test_attribute_limit(s):
    s.action(506)
    s.action(514)
    before = state(s)
    s.action(509)
    assert gameplay(state(s)) == gameplay(before)
    assert last(s, 'rpg.progress')[5] == 'rpg.attribute-limit'


def test_rollbacks(s):
    s.action(506)
    for code in (507, 508, 523, 524, 525, 526):
        before = state(s)
        s.action(code)
        assert state(s) == before, f'exception {code} left a partial award, purchase or configuration'


def test_conflict(s):
    s.action(406)
    before = state(s)
    s.action(407)
    current = state(s)
    assert current['exchanges'] == 1 and current['seconds'] == 2 and current['energy'] == 5
    own = [e['values'] for e in s.log if e['id'] == 'rpg.strike' and e['values'][2] == 'acting'][-1]
    assert own[3:9] == ['defended', 11, 7, 8, 0, 0], own
    s.action(3)
    assert state(s) == before, 'undo did not restore the whole exchange'
    s.action(407)
    assert state(s) == current, 'replayed exchange changed dice or consequences'


def test_surrender(s):
    s.action(406)
    s.action(412)
    current = state(s)
    assert current['outcome'] == 'surrendered' and current['draws'] == 0 and current['exchanges'] == 0
    assert current['bank'] == 6 and current['finished'] is True and current['active'] is None
    s.action(406)
    s.action(412)
    assert gameplay(state(s)) == gameplay(current), 'finished encounter restarted or re-awarded points'


def test_escape(s):
    s.action(406)
    s.action(409)
    current = state(s)
    assert current['outcome'] == 'escaped' and current['draws'] == 6 and current['seconds'] == 2
    assert current['injury'] == 3 and current['bank'] == 6


def test_stalemate(s):
    s.action(528)
    s.action(406)
    s.action(407)
    s.action(407)
    current = state(s)
    assert current['outcome'] == 'stalemate' and current['exchanges'] == 2 and current['seconds'] == 4
    assert current['injury'] == 3 and current['enemy_injury'] == 0


def test_winning(s):
    s.action(406)
    s.action(532)
    s.action(407)
    current = state(s)
    assert current['outcome'] == 'won' and current['passage'] is True and current['bank'] == 12


def persistence(Session, bundle, out):
    save = out / 'resilience.zsave'
    s = Session(bundle)
    try:
        s.action(506)
        s.action(414)
        s.action(403)
        s.action(406)
        s.action(407)
        saved = state(s)
        s.command(f':save {save}\n@950')
        assert any('[save ok code=0]' in line for line in s.raw_lines)
        s.action(408)
        future = state(s)
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {save}\n@950')
        assert any('[restore ok code=0]' in line for line in s.raw_lines)
        assert gameplay(state(s)) == gameplay(saved)
        s.action(408)
        assert gameplay(state(s)) == gameplay(future), 'restored conflict did not continue identically'
    finally:
        s.close()


def parity(Session, bundle):
    values = []
    for route in ('parser', 'structured', 'choice'):
        s = Session(bundle)
        try:
            if route == 'parser':
                s.command('find permit')
                s.command('show permit')
            elif route == 'structured':
                s.action(400)
                s.action(401)
            else:
                s.action(80, 'gate.plan')
                s.select('find')
                s.select('show')
            values.append(gameplay(state(s)))
        finally:
            s.close()
    assert values[0] == values[1] == values[2], 'hybrid passage or milestone parity failed'


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build('resilience', ROOT / 'tests/fixtures/resilience.t')
    for case in (test_injury, test_major_wound_and_lethality, test_treatment, test_treatment_failure,
                 test_treatment_critical_failure, test_rest, test_interruption_and_exhaustion,
                 test_stun, test_shock_assessment, test_social, test_social_permission, test_progression, test_attributes,
                 test_attribute_limit, test_rollbacks, test_conflict, test_surrender,
                 test_escape, test_stalemate, test_winning):
        fresh(Session, bundle, case)
        print(f'  {case.__name__}: passed', flush=True)
    persistence(Session, bundle, build.out)
    parity(Session, bundle)
    output = run([sys.executable, ROOT / 'examples/resilience/host.py', bundle,
                  '--vhyl', build.vhyl, '--details'], timeout=60,
                 input=':plan\nfind permit\nshow permit\ntrain aid\n:odds\n:quit\n')
    assert 'Rain Gatehouse' in output and 'opens the road' in output and 'HP 7/10' in output, output
    assert '6 points; 6 unspent' in output and '2 points; 4 unspent' in output, output
    print('  resilience/progression cross-process restore, hybrid parity and playable host: passed', flush=True)
