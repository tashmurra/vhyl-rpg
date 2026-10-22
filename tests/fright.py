"""Fright Check expectations: modifiers, Rule of 14, every results row and recovery timing."""
from native import fresh, last, load_host
from support import ROOT

STATE = '''iq ht hp fp stunned unconscious posture panicked retching held kind fixed clock
recovery interval score elapsed days penalty penalty_seconds pending traits rng draws seconds cost'''.split()
RESULT = 'status reason roll score margin table total row fatigue injury panic acquisitions modifier'.split()
HP = 30  # ST 10 + 20: no fright injury in these tests reaches a major-wound check.


class Dice:
    """Independent model of the library's 16807 generator (see native.test_random)."""
    def __init__(self, state):
        self.state, self.draws = state, 0

    def die(self):
        self.state = self.state * 16807 % 2147483647
        self.draws += 1
        return self.state % 6 + 1

    def roll(self):
        return self.die() + self.die() + self.die()


def succeeds(score, roll):
    return roll <= 4 or (roll <= score and roll < 17)


def critical_failure(score, roll):
    return roll == 18 or (roll == 17 and score <= 15) or roll - score >= 10


def state(s):
    s.action(990)
    return dict(zip(STATE, last(s, 'test.fright-state'), strict=True))


def result(s):
    s.action(991)
    return dict(zip(RESULT, last(s, 'test.fright-result'), strict=True))


def score(s):
    s.action(992)
    return last(s, 'test.fright-score')


def pending(s):
    s.action(993)
    start = max(i for i, e in enumerate(s.log) if e['id'] == 'test.fright-pending-end')
    end = start
    while start > 0 and s.log[start - 1]['id'] == 'test.fright-pending':
        start -= 1
    return [s.log[i]['values'] for i in range(start, end)]


def do(s, code, *args):
    s.action(700, code, *args)


def setup(s, seed=1, iq=10, ht=10, will=0):
    do(s, 1, seed)
    do(s, 2, iq, ht, 20, will)


def situation(s, monster=0, count=1, body=0, mutilation=1, dependent=0, combat=0, touched=0,
              viewing=0, isolated=0, dark=0, alone=0, experienced=0, briefing=0, danger=0,
              charging=0, sworn=0, strange=0, modifier=0, threat=''):
    do(s, 4, monster, count, body, mutilation, dependent, combat, touched, viewing, isolated, dark,
       alone, experienced, briefing, danger, charging, sworn, strange, modifier, threat)


def advance(s, seconds):
    while seconds > 0:
        step = min(seconds, 86400)
        do(s, 7, step)
        seconds -= step


def row_effects(row, d, ht=10):
    """The results table restated independently; dice are drawn in listed order."""
    e = dict(kind=None, fixed=None, recovery=None, interval=None, score=None, pending=[],
             fatigue=0, injury=0, iq_loss=0, ht_loss=0, panic=None, lying=False)
    def begin(kind, fixed, recovery, interval=1, mw=False):
        e.update(kind=kind, fixed=fixed, recovery=recovery, interval=interval, score=mw)
    def faint_as_18():
        begin('faint', d.die() * 60, 'ht', 60)
        if not succeeds(ht, d.roll()):
            e['injury'] += 1
    def coma():
        begin('coma', d.die() * 3600, 'ht')
    if row <= 5: begin('stun', 1, 'automatic')
    elif row <= 7: begin('stun', 1, 'will')
    elif row <= 9: begin('stun', 1, 'modified-will', mw=True)
    elif row == 10: begin('stun', d.die(), 'modified-will', mw=True)
    elif row == 11: begin('stun', d.die() + d.die(), 'modified-will', mw=True)
    elif row == 12: begin('retch', max(25 - ht, 0), 'ht')
    elif row == 13: e['pending'] = [['quirk', -1]]
    elif row <= 15:
        e['fatigue'] = d.die(); begin('stun', d.die(), 'modified-will', mw=True)
    elif row == 16:
        begin('stun', d.die(), 'modified-will', mw=True); e['pending'] = [['quirk', -1]]
    elif row == 17: begin('faint', d.die() * 60, 'ht', 60)
    elif row == 18: faint_as_18()
    elif row == 19:
        begin('faint', (d.die() + d.die()) * 60, 'ht', 60); e['injury'] = 1
    elif row == 20:
        begin('faint', (d.die() + d.die() + d.die() + d.die()) * 60, 'automatic'); e['fatigue'] = d.die()
    elif row == 21: begin('panic', d.die() * 60, 'will', 60)
    elif row in (22, 23, 24, 25, 34, 35, 36, 37):
        e['pending'] = [{22: ['delusion', -10], 23: ['mental', -10], 24: ['physical', -15],
                         25: ['worsen-or-mental', -10], 34: ['delusion', -15], 35: ['mental', -15],
                         36: ['physical', -20], 37: ['physical', -30]}[row]]
    elif row == 26: faint_as_18(); e['pending'] = [['delusion', -10]]
    elif row == 27: faint_as_18(); e['pending'] = [['mental', -10]]
    elif row == 28: begin('light-coma', 0, 'ht', 1800)
    elif row == 29: coma()
    elif row == 30: begin('catatonia', d.die() * 86400, 'ht')
    elif row == 31:
        begin('seizure', d.die() * 60, 'automatic'); e['fatigue'] = d.die()
        check = d.roll()
        if not succeeds(ht, check):
            e['injury'] = d.die()
        if critical_failure(ht, check):
            e['ht_loss'] = 1
    elif row == 32:
        e['lying'] = True; e['injury'] = d.die() + d.die()
    elif row == 33:
        begin('total-panic', 0, 'will'); e['panic'] = d.roll()
    elif row == 38: coma(); e['pending'] = [['delusion', -15]]
    else:
        coma(); e['pending'] = [['mental', -15]]; e['iq_loss'] = 1 if row >= 40 else 0
    return e


def assert_row(s, before, row, d, modified_will, actual_result):
    e = row_effects(row, d, before['ht'])
    after = state(s)
    assert after['draws'] - before['draws'] == d.draws, (row, after, d.draws)
    assert after['kind'] == e['kind'], (row, after)
    if e['kind'] is not None:
        assert [after['fixed'], after['recovery'], after['interval']] == [e['fixed'], e['recovery'], e['interval']], (row, after, e)
        assert after['score'] == (modified_will if e['score'] else None), (row, after)
        assert after['held']
        assert after['stunned'] == (True if e['kind'] in ('stun', 'seizure') else None), (row, after)
        assert after['unconscious'] == (True if e['kind'] in ('faint', 'light-coma', 'coma', 'catatonia') else None), (row, after)
        assert after['panicked'] == (True if e['kind'] in ('panic', 'total-panic') else None)
        assert after['retching'] == (True if e['kind'] == 'retch' else None)
    else:
        assert not after['held']
    if e['lying'] or e['kind'] in ('faint', 'light-coma', 'coma', 'catatonia', 'seizure'):
        assert after['posture'] == 'lying', (row, after)
    added = after['pending'] - before['pending']
    assert added == len(e['pending']), (row, after)
    if added:
        assert [p[:2] for p in pending(s)][-added:] == e['pending'], (row, pending(s))
    assert after['fp'] == before['fp'] - e['fatigue'] and after['hp'] == before['hp'] - e['injury'], (row, after, e)
    assert after['iq'] == before['iq'] - e['iq_loss'] and after['ht'] == before['ht'] - e['ht_loss'], (row, after, e)
    assert [actual_result['fatigue'], actual_result['injury'], actual_result['panic'], actual_result['acquisitions']] == [
        e['fatigue'], e['injury'], e['panic'], len(e['pending'])], (row, actual_result, e)
    return e


def test_modifiers(s):
    setup(s)
    baseline = state(s)
    cases = [
        (dict(), 0), (dict(monster=-4), -4), (dict(body=1), 6), (dict(body=2), 2), (dict(body=3), 0),
        (dict(body=4, mutilation=3), -3), (dict(body=3, dependent=1), -6), (dict(combat=1), 5),
        (dict(touched=1), -1), (dict(viewing=1), 1), (dict(viewing=2), 3), (dict(isolated=1), -1),
        (dict(dark=1), -1), (dict(alone=1), -2), (dict(experienced=1), 1), (dict(briefing=3), 3),
        (dict(modifier=-7), -7), (dict(monster=-2, body=4, mutilation=2, dark=1, alone=1, touched=1), -8),
    ]
    for count, horde in ((1, 0), (4, 0), (5, -1), (9, -1), (10, -2), (19, -2), (20, -3), (49, -3),
                         (50, -4), (99, -4), (100, -5), (5000, -5)):
        cases.append((dict(count=count), horde))
    for fields, expected in cases:
        situation(s, **fields)
        modifier, modified, capped = score(s)
        assert modifier == expected and modified == 10 + expected, (fields, modifier, modified)
        assert capped == min(13, modified)
    # Rule of 14: the cap applies after modifiers, to Fright Checks only.
    do(s, 2, 10, 10, 20, 6)
    situation(s, combat=1)
    assert score(s) == [5, 21, 13]
    do(s, 2, 10, 10, 20, 0)
    # Always-on traits. Fearlessness and Combat Reflexes come from the shared Lite score.
    for trait, level, points, rating, fields, modifier, modified in (
        ('fearlessness', 3, 2, 0, {}, 0, 13), ('combat-reflexes', 1, 15, 0, {}, 0, 12),
        ('fearfulness', 2, -2, 0, {}, -2, 8), ('combat-paralysis', 1, -15, 0, {}, -2, 8),
        ('cowardice', 1, -10, 6, dict(danger=1), -4, 6), ('cowardice', 1, -10, 9, dict(danger=1), -3, 7),
        ('cowardice', 1, -10, 0, dict(danger=1), -2, 8), ('cowardice', 1, -10, 15, dict(danger=1), -1, 9),
        ('cowardice', 1, -10, 6, {}, 0, 10), ('xenophilia', 1, -10, 6, dict(strange=1), 4, 14),
        ('xenophilia', 1, -10, 15, dict(strange=1), 1, 11), ('xenophilia', 1, -10, 9, {}, 0, 10),
        ('daredevil', 1, 15, 0, dict(charging=1), 1, 11), ('daredevil', 1, 15, 0, {}, 0, 10),
        ('higher-purpose', 1, 5, 0, dict(sworn=1), 1, 11), ('higher-purpose', 1, 5, 0, {}, 0, 10),
    ):
        do(s, 13)
        do(s, 3, trait, level, points, rating)
        situation(s, **fields)
        assert score(s) == [modifier, modified, min(13, modified)], (trait, rating, fields, score(s))
    do(s, 13)
    for fields, reason in ((dict(body=5), 'fright-body'), (dict(viewing=3), 'fright-viewing'),
                           (dict(dependent=1), 'fright-dependent-without-body')):
        situation(s, **fields)
        do(s, 15)
        s.action(995)
        assert last(s, 'test.fright-last')[2] == reason, fields
    current = state(s)
    assert [current['rng'], current['draws'], current['seconds']] == [baseline['rng'], baseline['draws'], baseline['seconds']], \
        'pure score queries drew randomness or spent time'


def find_seed(predicate, start=1):
    for seed in range(start, start + 200000):
        if predicate(Dice(seed)):
            return seed
    raise AssertionError('no seed found')


def test_checks(s):
    # Resisted, ordinary failures and a Rule-of-14 failure against modified Will 21.
    setup(s)
    situation(s, monster=-3)
    resisted = find_seed(lambda d: d.roll() <= 7)
    do(s, 1, resisted); do(s, 5)
    r = result(s)
    assert r['status'] == 'resisted' and r['score'] == 7 and r['row'] is None and state(s)['kind'] is None, r
    for seed in (2, 3, 5, 8, 13, 21, 34, 55):
        do(s, 1, seed)
        d = Dice(seed)
        roll = d.roll()
        if succeeds(7, roll):
            continue
        table = d.roll()
        before = state(s)
        do(s, 5)
        r = result(s)
        margin = 7 - roll
        assert [r['status'], r['roll'], r['score'], r['margin'], r['table'], r['total'], r['row']] == [
            'failed', roll, 7, margin, table, table - margin, min(table - margin, 40)], (seed, r)
        assert_row(s, before, r['row'], d, 7, r)
        do(s, 16)
    do(s, 2, 10, 10, 20, 6)
    situation(s, combat=1)
    def capped_failure(d):
        roll, table = d.roll(), d.roll()
        return 14 <= roll <= 16 and 8 <= table + roll - 13 <= 11
    seed = find_seed(capped_failure)
    d = Dice(seed)
    roll = d.roll(); table = d.roll()
    do(s, 1, seed)
    before = state(s)
    do(s, 5)
    r = result(s)
    assert r['status'] == 'failed' and r['score'] == 13 and r['margin'] == 13 - roll, r
    assert state(s)['score'] == 21, 'recovery rolls must use modified Will without the Rule of 14'
    assert_row(s, before, r['row'], d, 21, r)


def test_rows(s):
    setup(s)
    for row in list(range(4, 41)) + [57]:
        do(s, 1, 1000 + row)
        before = state(s)
        do(s, 6, row, 9)
        d = Dice(before['rng'])
        r = result(s)
        assert r['status'] == 'failed' and r['row'] == min(row, 40) and r['total'] == row, r
        assert_row(s, before, min(row, 40), d, 9, r)
        do(s, 16)
        assert state(s)['kind'] is None and state(s)['hp'] == HP


def recover_after(d, score):
    """Number of rolls until a success against score."""
    count = 0
    while True:
        count += 1
        if succeeds(score, d.roll()):
            return count


def test_stun_recovery(s):
    setup(s, seed=77)
    for row, recovery_score in ((6, 10), (8, 2), (8, 16)):
        before = state(s)
        do(s, 6, row, recovery_score)
        d = Dice(state(s)['rng'])
        advance(s, 1)
        assert state(s)['kind'] == 'stun' and state(s)['fixed'] == 0 and state(s)['draws'] == before['draws']
        rolls = recover_after(d, recovery_score)
        for second in range(1, rolls):
            advance(s, 1)
            assert state(s)['stunned'] is True, (row, second)
        advance(s, 1)
        after = state(s)
        assert after['kind'] is None and after['stunned'] is None and not after['held'], (row, after)
        assert after['draws'] - before['draws'] == 3 * rolls
    do(s, 6, 4, 9)
    advance(s, 1)
    assert state(s)['kind'] is None, 'rows 4-5 recover automatically after one second'


def test_timed_recovery(s):
    setup(s, seed=4242)
    # Faint (17): 1d minutes, then HT each minute.
    d = Dice(state(s)['rng'])
    do(s, 6, 17, 9)
    minutes = d.die()
    advance(s, minutes * 60 - 1)
    assert state(s)['unconscious'] is True
    rolls = recover_after(d, 10)
    advance(s, 1 + 60 * rolls - 1)
    assert state(s)['unconscious'] is True
    advance(s, 1)
    assert state(s)['unconscious'] is None and state(s)['kind'] is None
    # Light coma (28): HT every 30 minutes, then -2 for six hours after waking.
    situation(s)
    do(s, 6, 28, 9)
    d = Dice(state(s)['rng'])
    rolls = recover_after(d, 10)
    advance(s, 1800 * rolls)
    woke = state(s)
    assert woke['kind'] is None and woke['penalty'] == 2 and woke['penalty_seconds'] == 21600, woke
    assert score(s)[1] == 8, 'lingering penalty did not reach the Will score'
    advance(s, 21599)
    assert state(s)['penalty'] == 2
    advance(s, 1)
    assert state(s)['penalty'] == 0 and score(s)[1] == 10
    # Coma (29): 1d hours, then HT; each failure adds 1d hours.
    d = Dice(state(s)['rng'])
    do(s, 6, 29, 9)
    hours = d.die()
    while not succeeds(10, d.roll()):
        hours += d.die()
    for hour in range(hours - 1):
        advance(s, 3600)
        assert state(s)['kind'] == 'coma', hour
    advance(s, 3600)
    after = state(s)
    assert after['kind'] is None and after['penalty_seconds'] == 21600, after
    advance(s, 21600)
    # Retching (12): 25 - HT seconds, then HT each second.
    do(s, 6, 12, 9)
    d = Dice(state(s)['rng'])
    rolls = recover_after(d, 10)
    advance(s, 15 + rolls - 1)
    assert state(s)['retching'] is True
    advance(s, 1)
    assert state(s)['retching'] is None and state(s)['kind'] is None
    # Panic (21): 1d minutes, then unmodified Will each minute.
    d = Dice(state(s)['rng'])
    do(s, 6, 21, 2)
    minutes = d.die(); rolls = recover_after(d, 10)
    advance(s, minutes * 60 + 60 * rolls - 1)
    assert state(s)['panicked'] is True
    advance(s, 1)
    assert state(s)['panicked'] is None
    # Faint bordering on shock (20): 4d minutes, then wakes automatically.
    d = Dice(state(s)['rng'])
    do(s, 6, 20, 9)
    minutes = d.die() + d.die() + d.die() + d.die()
    advance(s, minutes * 60 - 1)
    assert state(s)['unconscious'] is True
    advance(s, 1)
    assert state(s)['unconscious'] is None


def catatonia_days(d):
    days = d.die()
    while not succeeds(10, d.roll()):
        days += d.die()
    return days


def test_catatonia(s):
    setup(s)
    seed = find_seed(lambda d: catatonia_days(d) <= 4)
    for care in (False, True):
        do(s, 1, seed)
        before = state(s)
        do(s, 6, 30, 9)
        if care:
            do(s, 11)
        days = catatonia_days(Dice(seed))
        for day in range(1, days + 1):
            advance(s, 86400)
            current = state(s)
            lost = 0 if care else day * (day + 1) // 2
            assert current['hp'] == before['hp'] - lost, (care, day, current)
            assert (current['kind'] == 'catatonia') == (day < days), (care, day, current)
        assert state(s)['penalty_seconds'] == days * 86400 and state(s)['unconscious'] is None
        do(s, 16)


def test_total_panic(s):
    setup(s, seed=99)
    do(s, 6, 33, 9)
    first = result(s)['panic']
    held = state(s)
    advance(s, 3600)
    assert state(s)['kind'] == 'total-panic' and state(s)['draws'] == held['draws'], 'total panic ends only by Will'
    d = Dice(state(s)['rng'])
    while True:
        do(s, 10)
        s.action(995)
        nxt = last(s, 'test.fright-last')[0]
        if succeeds(10, d.roll()):
            assert nxt is None and state(s)['kind'] is None and state(s)['panicked'] is None
            break
        assert nxt == d.roll() and state(s)['kind'] == 'total-panic'
    assert 3 <= first <= 18


def test_acquisitions(s):
    setup(s)
    do(s, 3, 'quirk', 1, -1, 0); do(s, 3, 'quirk', 1, -1, 0)
    do(s, 3, 'quirk', 1, -1, 0); do(s, 3, 'quirk', 1, -1, 0); do(s, 3, 'quirk', 1, -1, 0)
    do(s, 6, 13, 9)
    assert [p[:2] for p in pending(s)] == [['quirk', -1]]
    before = state(s)
    do(s, 8, 1, 'quirk', -2, 0)
    assert state(s) == before, 'wrong points must reject without changes'
    do(s, 8, 1, 'quirk', -1, 0)
    after = state(s)
    assert after['pending'] == 0 and after['traits'] == 6 and after['cost'] == before['cost'] - 1
    do(s, 14); s.action(995)
    assert last(s, 'test.fright-last')[1] is True, 'a quirk gained in play counts beyond the creation limit'
    # Row 25: worsen a related disadvantage's self-control one step, else add a new one.
    do(s, 3, 'cowardice', 1, -10, 12)
    do(s, 6, 25, 9)
    do(s, 9, 1, 'cowardice')
    s.action(994, 'cowardice')
    assert last(s, 'test.fright-trait')[:2] == [9, -15]
    do(s, 13); do(s, 3, 'cowardice', 1, -10, 6)
    do(s, 6, 25, 9)
    before = state(s)
    do(s, 9, 1, 'cowardice')
    assert state(s) == before, 'self-control 6 cannot worsen'
    do(s, 8, 1, 'phobia-crypts', -10, 0)
    s.action(994, 'phobia-crypts')
    assert last(s, 'test.fright-trait') == [None, -10, True]


def test_exposures_and_exemptions(s):
    setup(s, seed=5)
    situation(s, threat='ghoul')
    assert score(s)[0] == 0
    do(s, 5); do(s, 16)
    assert score(s)[0] == 1, 'an exposure in the last 24 hours gives +1'
    advance(s, 86400)
    assert score(s)[0] == 0, 'exposures older than 24 hours expire'
    do(s, 5); do(s, 16); advance(s, 600); do(s, 5); do(s, 16)
    assert score(s)[0] == 2, 'each exposure in 24 hours gives +1'
    advance(s, 86400)
    assert score(s)[0] == 0
    # Unfazeable characters make no check; unconscious characters cannot be frightened.
    do(s, 3, 'unfazeable', 1, 15, 0)
    before = state(s)
    do(s, 5)
    assert result(s)['status'] == 'exempt' and state(s)['draws'] == before['draws']
    do(s, 13)
    do(s, 6, 17, 9)
    before = state(s)
    do(s, 5)
    assert result(s)['status'] == 'blocked' and result(s)['reason'] == 'incapacitated' and state(s)['draws'] == before['draws']


def test_rollback_and_undo(s):
    setup(s, seed=31)
    situation(s, monster=-5)
    baseline = state(s)
    do(s, 12)
    assert state(s) == baseline, 'an exception left fright state behind'
    do(s, 5)
    after = state(s)
    s.action(3)
    assert state(s) == baseline, 'undo did not restore the check, randomness and conditions'
    do(s, 5)
    assert state(s) == after


def test_persistence(Session, bundle, out):
    path = out / 'expanded-fright.zsave'
    s = Session(bundle)
    try:
        setup(s, seed=2024)
        do(s, 6, 13, 9)
        do(s, 6, 29, 9)
        saved = state(s)
        s.command(f':save {path}\n@990')
        assert any('[save ok code=0]' in line for line in s.raw_lines)
        advance(s, 86400)
        continued = state(s)
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@990')
        assert any('[restore ok code=0]' in line for line in s.raw_lines)
        assert state(s) == saved, 'episode, pending quirk or randomness was not saved'
        advance(s, 86400)
        assert state(s) == continued, 'restored coma did not continue identically'
    finally:
        s.close()


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build('expanded-fright', ROOT / 'tests/fixtures/expanded-fright.t')
    for check in (test_modifiers, test_checks, test_rows, test_stun_recovery, test_timed_recovery,
                  test_catatonia, test_total_panic, test_acquisitions, test_exposures_and_exemptions,
                  test_rollback_and_undo):
        fresh(Session, bundle, check)
        print(f'  fright {check.__name__}: passed', flush=True)
    test_persistence(Session, bundle, build.out)
    print('  fright persistence: passed', flush=True)
