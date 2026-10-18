"""Independent source examples and persistence checks for expanded mechanics."""
from native import fresh, last, load_host
from support import ROOT


def state(s):
    s.action(1101)
    return last(s, 'test.expanded-state')


def test_wealth_advancement(s):
    def balances():
        s.action(1242)
        return last(s, 'test.wealth-advance-state')
    initial = balances()
    s.action(1243)
    assert last(s, 'test.wealth-advance-preview') == ['ready', 20, 5000]
    assert balances() == initial
    s.action(1100, 100)
    assert balances() == initial
    s.action(1100, 99)
    assert last(s, 'test.wealth-advance') == ['resolved', 20, 5000]
    assert balances() == [5000, 10, 'wealthy', 1, 1, initial[-2], initial[-1]]
    s.command('undo')
    assert balances() == initial
    s.action(1100, 99)
    after = balances()
    s.action(1100, 99)
    assert last(s, 'test.wealth-advance') == ['reused', 0, 5000]
    assert balances() == after
    for variant, reason, money, points in [
            (1, 'wealth-advancement-money', 4999, 20),
            (2, 'wealth-advancement-points', 5000, 19),
            (3, 'wealth-advancement-obligations', 5000, 20),
            (4, 'wealth-advancement-unapproved', 5000, 20),
            (5, 'wealth-advancement-after-creation', 5000, 20),
            (6, 'wealth-advancement-not-increase', 5000, 20)]:
        s.action(1244, variant)
        assert last(s, 'test.wealth-advance-boundary') == [reason, money, points, 0]
    assert balances() == after


def test_wealth_advancement_sequence(s):
    before = state(s)
    s.action(1245)
    assert last(s, 'test.wealth-advance-sequence') == [
        15, 1000, 30, 30, 20000, 0, 20000, 2, 'reused', 'very-wealthy',
        'first-clearance', 'wealth-advancement-duplicate',
        'wealth-advancement-retargeted', 0, 2]
    assert state(s) == before


def test_wealth_advancement_persistence(Session, bundle, out):
    for committed in [False, True]:
        path = out / f'expanded-wealth-advancement-{committed}.zsave'
        first = Session(bundle)
        try:
            if committed:
                first.action(1100, 99)
            first.action(1242)
            saved = last(first, 'test.wealth-advance-state')
            first.command(f':save {path}\n@1242')
            assert any('[save ok code=0]' in line for line in first.raw_lines)
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1242')
            second.action(1242)
            assert last(second, 'test.wealth-advance-state') == saved
            second.action(1100, 99)
            assert last(second, 'test.wealth-advance') == [
                'reused' if committed else 'resolved', 0 if committed else 20, 5000]
            second.action(1242)
            assert last(second, 'test.wealth-advance-state') == [
                5000, 10, 'wealthy', 1, 1, saved[-2], saved[-1]]
            second.action(1100, 99)
            assert last(second, 'test.wealth-advance') == ['reused', 0, 5000]
        finally:
            second.close()


def test_employment_wealth_requirements(s):
    before = state(s)
    s.action(1246)
    assert last(s, 'test.employment-wealth') == [
        'employment-wealth-unspecified', 'required', 'comfortable', 10, 2000, 0,
        'wealth-advancement-points', 'pending', 1, 10, 2, 'wealthy',
        'employment-wealth-priority', 'wealthy', 10, 'satisfied',
        0, 5000, 100, 2]
    assert state(s) == before


def test_employment_wealth_priority(s):
    before = state(s)
    s.action(1247)
    assert last(s, 'test.employment-wealth-priority') == [
        'pending', 1, 'employment-wealth-priority', 0,
        'employment-wealth-priority', 'employment-wealth-priority', 30, 5000,
        'resolved', 20, 'satisfied', 'resolved', 1, 19, 2]
    assert state(s) == before


def obligation_state(s):
    s.action(1248)
    return last(s, 'test.obligation-state')


def test_employment_wealth_transactions(s):
    before = obligation_state(s)
    s.action(1100, 104)
    assert obligation_state(s) == before
    s.action(1100, 101)
    pending = obligation_state(s)
    assert pending[:10] == [2000, 5, 'average', 1, 1, 1, 1, 0, 0, 0]
    s.command('undo')
    assert obligation_state(s) == before
    s.action(1100, 101)
    s.action(1100, 103)
    assert last(s, 'test.obligation-learning') == ['blocked', 'employment-wealth-priority']
    assert obligation_state(s) == pending
    s.action(1100, 105)
    assert obligation_state(s) == pending
    s.action(1100, 102)
    paid = obligation_state(s)
    assert paid[:10] == [2000, 5, 'comfortable', 1, 1, 1, 0, 0, 1, 10]
    assert paid[-2:] == before[-2:]
    s.command('undo')
    assert obligation_state(s) == pending
    s.action(1100, 102); s.action(1100, 102)
    assert obligation_state(s) == paid
    s.action(1100, 103)
    assert last(s, 'test.obligation-learning') == ['resolved', None]
    assert obligation_state(s)[:10] == [2000, 4, 'comfortable', 1, 1, 1, 0, 1, 2, 10]


def test_employment_wealth_persistence(Session, bundle, out):
    for paid in [False, True]:
        path = out / f'expanded-obligation-{paid}.zsave'
        first = Session(bundle)
        try:
            first.action(1100, 101)
            if paid:
                first.action(1100, 102)
            saved = obligation_state(first)
            first.command(f':save {path}\n@1248')
            assert any('[save ok code=0]' in line for line in first.raw_lines)
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1248')
            assert obligation_state(second) == saved
            second.action(1100, 101)
            assert obligation_state(second) == saved
            if not paid:
                second.action(1100, 103)
                assert last(second, 'test.obligation-learning') == ['blocked', 'employment-wealth-priority']
            second.action(1100, 102)
            assert last(second, 'test.obligation-payment') == ['reused' if paid else 'resolved', 0 if paid else 10]
            assert obligation_state(second)[:10] == [2000, 5, 'comfortable', 1, 1, 1, 0, 0, 1, 10]
        finally:
            second.close()


def test_employment_wealth_payroll(s):
    s.action(1100, 106)
    before = obligation_state(s)
    for code, reason in [(108, 'employment-wealth-review-required'),
                         (110, 'wealth-advancement-obligations')]:
        s.action(1100, code)
        assert last(s, 'test.obligation-payroll') == ['blocked', reason, 0, 0]
        assert obligation_state(s) == before
    s.action(1100, 109)
    assert obligation_state(s) == before
    s.action(1100, 107)
    assert last(s, 'test.obligation-payroll') == ['resolved', None, 100, 1]
    paid = obligation_state(s)
    assert paid == [2000, 5, 'average', 1, 0, 0, 1, 0, 0, 0, 100, 3]
    s.command('undo')
    assert obligation_state(s) == before
    s.action(1100, 107); s.action(1100, 107)
    assert last(s, 'test.obligation-payroll') == ['reused', None, 0, 0]
    assert obligation_state(s) == paid


def test_scaled_injury_shock(s):
    for capacity, injury, expected in [
            (10, 1, 1), (19, 3, 3), (20, 1, 0), (20, 2, 1),
            (29, 7, 3), (30, 2, 0), (30, 8, 2), (39, 11, 3),
            (40, 11, 2), (40, 16, 4), (100, 39, 3), (100, 100, 4)]:
        s.action(1600, capacity, injury)
        assert last(s, 'test.scaled-shock') == [expected]
    for enabled, resistant, expected in [
            (0, 0, [8, 4, 16, 4, 0]), (1, 0, [8, 2, 16, 4, 0]),
            (1, 1, [8, 0, 16, 0, 0])]:
        s.action(1601, enabled, resistant)
        assert last(s, 'test.shock-integration') == expected


def test_scaled_shock_turn_boundary(s):
    s.action(1602)
    assert last(s, 'test.shock-sensitive') == [
        'resolved', 8, 4, 1, 3]
    for enabled, resistant, retained in [(0, 0, 4), (1, 0, 2), (1, 1, 0)]:
        s.action(1603, enabled, resistant)
        assert last(s, 'test.shock-turn') == [retained, 'resolved', 0, 8, 0]


def test_knockdown_assessment(s):
    # Exact half is not major under the main injury procedure (B420).
    for capacity, injury, location, male, expected in [
            (10, 5, 'torso', 0, [0, 0, 0, 4]),
            (10, 6, 'torso', 0, [1, 1, 0, 4]),
            (10, 1, 'face', 0, [0, 1, 0, 1]),
            (10, 6, 'face', 0, [1, 1, -5, 4]),
            (10, 6, 'skull', 0, [1, 1, -10, 4]),
            (10, 6, 'vitals', 0, [1, 1, -5, 4]),
            (10, 5, 'groin', 1, [0, 0, 0, 4]),
            (10, 6, 'groin', 1, [1, 1, -5, 4]),
            (10, 6, 'groin', 0, [1, 1, 0, 4]),
            (30, 2, 'face', 0, [0, 0, 0, 0]),
            (30, 3, 'face', 0, [0, 1, 0, 1]),
            (10, 0, 'skull', 0, [0, 0, 0, 0])]:
        s.action(1604, capacity, injury, location, male)
        assert last(s, 'test.knockdown-assessment') == expected
    s.action(1605)
    assert last(s, 'test.knockdown-rejection') == [
        'expanded-knockdown-location-unavailable', 'expanded-knockdown-groin-context']


def test_critical_major_wound(s):
    for location, health, trait, male, modifier, score, knocked in [
            ('torso',10,'none',0,0,10,0),('face',10,'none',0,-5,5,1),
            ('skull',15,'none',0,-10,5,1),('vitals',10,'none',0,-5,5,1),
            ('groin',10,'none',1,-5,5,1),('groin',10,'none',0,0,10,0),
            ('skull',10,'no-brain',0,0,10,0),('vitals',10,'no-vitals',0,0,10,0)]:
        s.action(2022, location, health, trait, male)
        assert last(s,'test.critical-major-preview') == ['ready',None,modifier,0,0]
        assert last(s,'test.critical-major') == [1,knocked,score,10,1,1,'reused',3,0]
        assert last(s,'test.critical-major-binding') == ['expanded-wound-retargeted']
    s.action(2022, 'skull', 10, 'none', 0)
    assert last(s,'test.critical-major-preview') == ['blocked','expanded-knockdown-score-unavailable',-10,0,0]


def test_expanded_wound_commit(s):
    for injury, location, ht, shock, stunned, unconscious, checks in [
            (5, 'torso', 10, 4, 0, 0, 0),
            (6, 'torso', 10, 4, 0, 0, 1),
            (1, 'face', 10, 1, 0, 0, 1),
            (6, 'face', 10, 4, 1, 1, 1),
            (6, 'skull', 20, 4, 0, 0, 1)]:
        s.action(1606, injury, location, ht)
        assert last(s, 'test.wound-commit') == [
            'ready', None, 0, 0, 'resolved', injury, shock, stunned, unconscious,
            checks, 3 * checks, 'reused', 1]
    s.action(1606, 6, 'skull', 10)
    assert last(s, 'test.wound-commit') == [
        'blocked', 'expanded-knockdown-score-unavailable', 0, 0,
        'blocked', 0, 0, 0, 0, 0, 0, 'blocked', 0]
    s.action(1607)
    assert last(s, 'test.wound-gates') == [
        'expanded-wound-drop-unavailable', 'expanded-wound-anatomy-unavailable',
        'expanded-wound-shock-rule-required', 0, 0, 0]


def owned_wound_state(s):
    s.action(1611)
    return last(s, 'test.wound-state')


def test_owned_wound_transactions(s):
    initial = owned_wound_state(s)
    assert initial == [0, 0, 0, 0, 'standing', 0, 0, 6, 0, 0, 0]
    s.action(1612)
    assert last(s, 'test.wound-preview') == ['ready', 1]
    assert owned_wound_state(s) == initial
    s.action(1610, 2)
    assert owned_wound_state(s) == initial
    s.action(1610, 1)
    wounded = owned_wound_state(s)
    assert wounded == [6, 4, 1, 1, 'lying', 1, 1, 6, 10, 3, 0]
    s.command('undo')
    assert owned_wound_state(s) == initial
    s.action(1610, 1)
    assert owned_wound_state(s) == wounded
    for code in [1, 3, 4]:
        s.action(1610, code)
        assert owned_wound_state(s) == wounded
    s.action(1610, 1)
    assert last(s, 'test.owned-wound') == ['reused']


def test_critical_major_transactions(s):
    initial = owned_wound_state(s); initial_equipment = wound_drop_state(s)
    for code in [12,15]:
        s.action(1610,code)
        assert owned_wound_state(s) == initial
        assert wound_drop_state(s) == initial_equipment
    s.action(1610,14)
    assert last(s,'test.owned-wound') == ['blocked']
    assert owned_wound_state(s) == [0,0,0,0,'standing',0,0,1,0,0,0]
    s.command('undo')
    assert owned_wound_state(s) == initial
    s.action(1610,11)
    wounded = [1,1,1,1,'lying',1,1,1,10,3,0]
    dropped = [0,'floor',0,1,1,None,500,1,0]
    assert owned_wound_state(s) == wounded
    assert wound_drop_state(s) == dropped
    s.command('undo')
    assert owned_wound_state(s) == initial
    assert wound_drop_state(s) == initial_equipment
    s.action(1610,11)
    for code in [1,13,9]:
        s.action(1610,code)
        assert owned_wound_state(s) == wounded
        assert wound_drop_state(s) == dropped


def test_critical_major_persistence(Session, bundle, out):
    for wounded in [False,True]:
        path = out / f'expanded-critical-major-{int(wounded)}.zsave'
        first = Session(bundle)
        try:
            if wounded:
                first.action(1610,11)
            state_before = owned_wound_state(first); equipment_before = wound_drop_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1611')
            assert owned_wound_state(second) == state_before
            assert wound_drop_state(second) == equipment_before
            second.action(1610,1 if wounded else 11)
            for code in [1,13]:
                second.action(1610,code)
                assert owned_wound_state(second) == [1,1,1,1,'lying',1,1,1,10,3,0]
                assert wound_drop_state(second) == [0,'floor',0,1,1,None,500,1,0]
        finally:
            second.close()


def test_owned_wound_persistence(Session, bundle, out):
    for wounded in [False, True]:
        path = out / f'expanded-owned-wound-{wounded}.zsave'
        first = Session(bundle)
        try:
            if wounded:
                first.action(1610, 1)
            saved = owned_wound_state(first)
            first.command(f':save {path}\n@1611')
            assert any('[save ok code=0]' in line for line in first.raw_lines)
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1611')
            assert owned_wound_state(second) == saved
            second.action(1610, 1)
            assert last(second, 'test.owned-wound') == ['reused' if wounded else 'resolved']
            assert owned_wound_state(second) == [6, 4, 1, 1, 'lying', 1, 1, 6, 10, 3, 0]
            second.action(1610, 1)
            assert last(second, 'test.owned-wound') == ['reused']
            assert owned_wound_state(second)[-2:] == [3, 0]
        finally:
            second.close()


def wound_drop_state(s):
    s.action(1613)
    return last(s, 'test.wound-drop')


def test_knockdown_equipment_drop(s):
    initial = owned_wound_state(s)
    equipment = wound_drop_state(s)
    s.action(1610, 6)
    assert owned_wound_state(s) == initial
    assert wound_drop_state(s) == equipment
    s.action(1610, 7)
    assert last(s, 'test.owned-wound') == ['blocked']
    assert owned_wound_state(s) == initial
    s.command('undo')
    assert wound_drop_state(s) == equipment
    s.action(1610, 5)
    assert owned_wound_state(s) == [6, 4, 1, 1, 'lying', 1, 1, 6, 10, 3, 0]
    dropped = wound_drop_state(s)
    assert dropped == [0, 'floor', 0, 1, 1, None, 500, 1, 0]
    s.command('undo')
    assert owned_wound_state(s) == initial
    assert wound_drop_state(s) == equipment
    s.action(1610, 5); s.action(1610, 1)
    assert wound_drop_state(s) == dropped
    assert owned_wound_state(s)[-2:] == [3, 0]


def test_knockdown_equipment_retained(s):
    s.action(1610, 8)
    assert owned_wound_state(s) == [6, 4, 0, 0, 'standing', 1, 1, 6, 10, 3, 0]
    assert wound_drop_state(s) == [1, None, 1, 1, 1, None, 600, 0, 2]
    s.action(1610, 9)
    assert wound_drop_state(s) == [1, None, 1, 1, 1, None, 600, 0, 2]
    s.action(1610, 1)
    assert last(s, 'test.owned-wound') == ['reused']


def test_knockdown_drop_persistence(Session, bundle, out):
    for succeeds in [False, True]:
        path = out / f'expanded-drop-{succeeds}.zsave'
        first = Session(bundle)
        try:
            first.action(1610, 8 if succeeds else 5)
            wound = owned_wound_state(first)
            equipment = wound_drop_state(first)
            first.command(f':save {path}\n@1611')
            assert any('[save ok code=0]' in line for line in first.raw_lines)
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1611')
            assert owned_wound_state(second) == wound
            assert wound_drop_state(second) == equipment
            second.action(1610, 1)
            assert last(second, 'test.owned-wound') == ['reused']
            assert wound_drop_state(second) == equipment
            if not succeeds:
                second.action(1610, 10)
                assert last(second, 'test.owned-wound') == ['reused']
                assert wound_drop_state(second) == [1, None, 1, 1, 1, None, 600, 1, 0]
                assert owned_wound_state(second)[-2:] == [3, 0]
        finally:
            second.close()


def test_knockdown_anatomy_exceptions(s):
    for injury, location, trait, male, expected in [
            (1, 'face', 'no-brain', 0, [1, 0, 0, 0, 0, 1, 0]),
            (6, 'face', 'no-brain', 0, [6, 1, 0, 0, 3, 1, 0]),
            (6, 'skull', 'no-brain', 0, [6, 1, 0, 0, 3, 1, 0]),
            (1, 'vitals', 'no-vitals', 0, [1, 0, 0, 0, 0, 0, 1]),
            (6, 'vitals', 'no-vitals', 0, [6, 1, 0, 0, 3, 0, 1]),
            (6, 'groin', 'no-vitals', 1, [6, 1, 0, 0, 3, 0, 1]),
            (6, 'face', 'no-vitals', 0, [6, 1, -5, 1, 3, 0, 0]),
            (1, 'vitals', 'no-brain', 0, [1, 1, 0, 0, 3, 0, 0])]:
        s.action(1608, injury, location, trait, male)
        assert last(s, 'test.anatomy-wound') == ['resolved'] + expected


def test_crippling_thresholds(s):
    for capacity, injury, kind, count, severing, expected in [
            (10, 5, 'limb', 2, 0, [6, 5, 0, 0, 0]),
            (10, 6, 'limb', 2, 0, [6, 6, 1, 0, 0]),
            (10, 11, 'limb', 2, 1, [6, 6, 1, 0, 0]),
            (10, 12, 'limb', 2, 1, [6, 6, 1, 1, 1]),
            (10, 12, 'limb', 2, 0, [6, 6, 1, 1, 0]),
            (11, 6, 'limb', 2, 0, [6, 6, 1, 0, 0]),
            (10, 3, 'limb', 4, 0, [3, 3, 1, 0, 0]),
            (10, 6, 'limb', 4, 1, [3, 3, 1, 1, 1]),
            (10, 3, 'extremity', 2, 0, [4, 3, 0, 0, 0]),
            (10, 8, 'extremity', 2, 1, [4, 4, 1, 1, 1]),
            (10, 3, 'extremity', 3, 0, [3, 3, 1, 0, 0]),
            (10, 2, 'extremity', 4, 0, [2, 2, 1, 0, 0]),
            (10, 1, 'eye', 2, 0, [2, 1, 0, 0, 0]),
            (10, 2, 'eye', 2, 0, [2, 2, 1, 0, 0]),
            (10, 4, 'eye', 2, 1, [2, 4, 1, 1, 0]),
            (10, 20, 'eye', 4, 0, [2, 20, 1, 1, 0]),
            (1, 0, 'limb', 2, 0, [1, 0, 0, 0, 0])]:
        for _ in range(2):
            s.action(1609, capacity, injury, kind, count, severing)
            assert last(s, 'test.crippling-assessment') == expected + [0]


def immunity_state(s):
    s.action(1812)
    return last(s, 'test.immunity-state')


def test_immunity_transactions(s):
    s.action(1810, 0)
    before = immunity_state(s)
    assert before == [0,0,0,0,0,4]
    s.action(1810, 13)
    assert immunity_state(s) == before
    s.action(1810, 11)
    immune = immunity_state(s)
    assert immune == [1,3,1,0,3,4]
    s.command('undo')
    assert immunity_state(s) == before
    s.action(1810, 11)
    assert immunity_state(s) == immune
    s.action(1810, 14)
    assert immunity_state(s) == immune
    s.action(1810, 12)
    later = immunity_state(s)
    assert later == [1,3,1,1,3,5]
    s.command('undo')
    assert immunity_state(s) == immune
    for code in [12,12,11,9]:
        s.action(1810, code)
        assert immunity_state(s) == later


def test_immunity_persistence(Session, bundle, out):
    for code, roll in [(11,3),(15,4)]:
        for later in [False,True]:
            path = out / f'expanded-immunity-{roll}-{later}.zsave'
            first = Session(bundle)
            try:
                first.action(1810, 0); first.action(1810, code)
                if later:
                    first.action(1810, 12)
                saved = immunity_state(first)
                first.command(f':save {path}')
            finally:
                first.close()
            second = Session(bundle)
            try:
                second.command(f':restore {path}\n@1812')
                assert immunity_state(second) == saved
                second.action(1810, 9); second.action(1810, code)
                assert immunity_state(second) == saved
                second.action(1810, 12)
                assert immunity_state(second) == [1,roll,1,1,3,5]
            finally:
                second.close()


def hazard_state(s):
    s.action(1811)
    return last(s, 'test.hazard-state')


def test_infection_transactions(s):
    s.action(1810, 0)
    before = hazard_state(s)
    assert before == [4,2,0,0,0,0,1,0,0,0]
    s.action(1810, 2)
    assert hazard_state(s) == before
    s.action(1810, 1)
    acquired = hazard_state(s)
    assert acquired == [4,2,2,0,0,0,1,0,3,0]
    s.command('undo')
    assert hazard_state(s) == before
    s.action(1810, 1)
    for code in [1,8,9]:
        s.action(1810, code)
        assert hazard_state(s) == acquired
    s.action(1810, 3)
    due = hazard_state(s)
    s.action(1810, 10)
    assert last(s, 'test.hazard-operation') == ['ready',None]
    assert hazard_state(s) == due
    s.action(1810, 5)
    assert hazard_state(s) == due
    s.action(1810, 4)
    ill = hazard_state(s)
    assert ill == [5,3,2,1,1,0,2,86400,3,0]
    s.command('undo')
    assert hazard_state(s) == due
    s.action(1810, 4)
    assert hazard_state(s) == ill
    s.action(1810, 9)
    assert hazard_state(s) == ill
    s.action(1810, 3)
    due = hazard_state(s)
    s.action(1810, 7)
    assert hazard_state(s) == due
    s.action(1810, 6)
    recovered = hazard_state(s)
    assert recovered == [5,2,2,2,0,1,2,172800,3,0]
    s.command('undo')
    assert hazard_state(s) == due
    for code in [6,6,4,1,9]:
        s.action(1810, code)
        assert hazard_state(s) == recovered


def test_infection_persistence(Session, bundle, out):
    for stage in [0,1,2]:
        path = out / f'expanded-infection-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(1810, 0); first.action(1810, 1)
            if stage >= 1:
                first.action(1810, 3); first.action(1810, 4)
            if stage == 2:
                first.action(1810, 3); first.action(1810, 6)
            saved = hazard_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1811')
            assert hazard_state(second) == saved
            second.action(1810, 9); second.action(1810, 1)
            assert hazard_state(second) == saved
            if stage == 0:
                second.action(1810, 3); second.action(1810, 4)
            if stage < 2:
                second.action(1810, 3); second.action(1810, 6)
            second.action(1810, 6)
            assert hazard_state(second) == [5,2,2,2,0,1,2,172800,3,0]
        finally:
            second.close()


def test_infection_progression(s):
    s.action(1802)
    assert last(s, 'test.infection-day') == ['infection-day-not-due',1,'reused',5,3,1,0,3]
    assert last(s, 'test.infection-recovered') == [1,5,2,0,2,0,3]


def youth_state(s):
    s.action(1822)
    return last(s, 'test.youth-state')


def test_rejuvenation_transactions(s):
    s.action(1820, 1); s.action(1820, 7)
    before = youth_state(s)
    assert before == [10,0,0,20,0,0,0,12,0]
    s.action(1820, 9)
    assert youth_state(s) == before
    s.action(1820, 8)
    restored = youth_state(s)
    assert restored == [11,20,0,20,1,1,0,12,0]
    s.command('undo')
    assert youth_state(s) == before
    s.action(1820, 8)
    for code in [8,10,13,6]:
        s.action(1820, code)
        assert youth_state(s) == restored
    s.action(1820, 11)
    assert youth_state(s) == [10,0,0,20,1,1,0,12,0]
    s.action(1820, 12)
    final = youth_state(s)
    assert final == [11,20,0,20,2,1,1,12,0]
    for code in [12,8,6]:
        s.action(1820, code)
        assert youth_state(s) == final


def test_rejuvenation_persistence(Session, bundle, out):
    for stage in [0,1,2]:
        path = out / f'expanded-rejuvenation-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(1820, 1); first.action(1820, 7)
            if stage >= 1:
                first.action(1820, 8)
            if stage == 2:
                first.action(1820, 11)
            saved = youth_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1822')
            assert youth_state(second) == saved
            second.action(1820, 6)
            assert youth_state(second) == saved
            second.action(1820, 8)
            if stage < 2:
                second.action(1820, 11)
            second.action(1820, 12)
            assert youth_state(second) == [11,20,0,20,2,1,1,12,0]
            second.action(1820, 6)
        finally:
            second.close()


def aging_state(s):
    s.action(1821)
    return last(s, 'test.aging-state')


def test_aging_transactions(s):
    before = aging_state(s)
    assert before == [10,10,10,10,0,0,0,7,7,0,0,50]
    s.action(1820, 5)
    assert last(s, 'test.aging-operation') == ['ready',None]
    assert aging_state(s) == before
    s.action(1820, 2)
    assert aging_state(s) == before
    s.action(1820, 1)
    aged = aging_state(s)
    assert aged == [10,9,10,10,0,1,-20,7,7,12,0,50]
    s.command('undo')
    assert aging_state(s) == before
    s.action(1820, 1)
    for code in [1,3,4,6]:
        s.action(1820, code)
        assert aging_state(s) == aged


def test_aging_death_transactions(s):
    s.action(1820, 0)
    before = aging_state(s)
    assert before == [1,10,10,3,0,0,-160,7,7,0,0,50]
    s.action(1820, 2)
    assert aging_state(s) == before
    s.action(1820, 1)
    assert aging_state(s) == [0,9,9,2,1,1,-220,7,7,12,0,50]
    s.command('undo')
    assert aging_state(s) == before


def test_aging_persistence(Session, bundle, out):
    for terminal in [False,True]:
        for completed in [False,True]:
            path = out / f'expanded-aging-{terminal}-{completed}.zsave'
            first = Session(bundle)
            try:
                if terminal:
                    first.action(1820, 0)
                if completed:
                    first.action(1820, 1)
                saved = aging_state(first)
                first.command(f':save {path}')
            finally:
                first.close()
            second = Session(bundle)
            try:
                second.command(f':restore {path}\n@1821')
                assert aging_state(second) == saved
                second.action(1820, 1)
                expected = ([0,9,9,2,1,1,-220,7,7,12,0,50] if terminal
                            else [10,9,10,10,0,1,-20,7,7,12,0,50])
                assert aging_state(second) == expected
                second.action(1820, 1); second.action(1820, 6)
                assert aging_state(second) == expected
            finally:
                second.close()


def test_rejuvenation(s):
    s.action(1809, 0)
    assert last(s, 'test.youth-preview') == ['ready',None,10,0,0]
    assert last(s, 'test.youth-result') == ['resolved','reused',20,11,0,20,1,1,0,0]
    assert last(s, 'test.youth-cycle') == [1,20,11,2,2]
    s.action(1809, 1)
    assert last(s, 'test.youth-preview') == ['blocked','rejuvenation-partial-year-unavailable',10,0,0]
    assert last(s, 'test.youth-result') == ['blocked','blocked',0,10,0,20,0,0,0,0]


def cold_state(s):
    s.action(1841)
    return last(s, 'test.cold-state')


def test_cold_transactions(s):
    s.action(1840, 0)
    started = cold_state(s)
    assert started == [10,2,2,2,1,0,0,0,0,0]
    for code in [0,8,10]:
        s.action(1840, code)
        assert cold_state(s) == started
    s.action(1840, 1)
    before = cold_state(s)
    s.action(1840, 11)
    assert last(s, 'test.cold-operation') == ['blocked','cold-interval-not-due']
    assert cold_state(s) == before
    s.action(1840, 2)
    due = cold_state(s)
    s.action(1840, 5)
    assert last(s, 'test.cold-operation') == ['blocked','cold-unresolved-interval']
    assert cold_state(s) == due
    s.action(1840, 11)
    assert last(s, 'test.cold-operation') == ['ready',None]
    assert cold_state(s) == due
    s.action(1840, 4)
    assert cold_state(s) == due
    s.action(1840, 3)
    frozen = cold_state(s)
    assert frozen == [11,3,3,3,1,1,0,3,1800,0]
    s.command('undo')
    assert cold_state(s) == due
    s.action(1840, 3)
    for code in [3,7,6,9]:
        s.action(1840, code)
        assert cold_state(s) == frozen
    s.action(1840, 5)
    sheltered = cold_state(s)
    assert sheltered == [11,3,2,2,0,1,1,3,1800,0]
    s.command('undo')
    assert cold_state(s) == frozen
    for code in [5,5,3,9]:
        s.action(1840, code)
        assert cold_state(s) == sheltered


def test_cold_persistence(Session, bundle, out):
    for stage in [0,1,2,3]:
        path = out / f'expanded-cold-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(1840, 0)
            if stage >= 1:
                first.action(1840, 1); first.action(1840, 2)
            if stage >= 2:
                first.action(1840, 3)
            if stage == 3:
                first.action(1840, 5)
            saved = cold_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1841')
            assert cold_state(second) == saved
            second.action(1840, 9)
            assert cold_state(second) == saved
            if stage == 0:
                second.action(1840, 1); second.action(1840, 2)
            second.action(1840, 3); second.action(1840, 5)
            assert cold_state(second) == [11,3,2,2,0,1,1,3,1800,0]
            second.action(1840, 9)
        finally:
            second.close()


def swim_state(s):
    s.action(1911)
    return last(s, 'test.swim-state')


def test_swimming_transactions(s):
    s.action(1910, 0)
    started = swim_state(s)
    assert started == [0,'entry',0,60,0,0,1,0,0,0,'top-speed']
    for code in [0,2,9,10,12,14]:
        s.action(1910, code)
        assert swim_state(s) == started
    s.action(1910, 1)
    afloat = swim_state(s)
    assert afloat == [0,'stable',300,60,1,0,1,0,3,0,'top-speed']
    s.command('undo')
    assert swim_state(s) == started
    s.action(1910, 1)
    s.action(1910, 3)
    due = swim_state(s)
    assert due == [0,'stable',300,60,1,0,1,0,3,60,'top-speed']
    for code in [11,5,6,13,8]:
        s.action(1910, code)
        assert swim_state(s) == due
    s.action(1910, 4)
    tired = swim_state(s)
    assert tired == [1,'stable',300,120,1,1,1,0,6,60,'top-speed']
    s.command('undo')
    assert swim_state(s) == due
    s.action(1910, 4)
    for code in [4,7,9,8]:
        s.action(1910, code)
        assert swim_state(s) == tired
    s.action(1910, 6)
    ended = swim_state(s)
    assert ended == [1,'stable',300,120,1,1,0,1,6,60,'top-speed']
    s.command('undo')
    assert swim_state(s) == tired
    for code in [6,6,4,13,8]:
        s.action(1910, code)
        assert swim_state(s) == ended


def test_swimming_persistence(Session, bundle, out):
    for stage in range(5):
        path = out / f'expanded-swimming-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(1910, 0)
            for code in [1,3,4,6][:stage]:
                first.action(1910, code)
            saved = swim_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1911')
            assert swim_state(second) == saved
            second.action(1910, 8)
            for code in [1,3,4,6][stage:]:
                second.action(1910, code)
            assert swim_state(second) == [1,'stable',300,120,1,1,0,1,6,60,'top-speed']
            for code in [4,13,8]:
                second.action(1910, code)
                assert swim_state(second) == [1,'stable',300,120,1,1,0,1,6,60,'top-speed']
        finally:
            second.close()


def test_swimming_owned_endurance(s):
    s.action(1882)
    assert last(s, 'test.swim-endurance-owned') == [
        'swimming-endurance-not-due','swimming-unresolved-endurance',1,'reused',1,120,3]
    assert last(s, 'test.swim-endurance-exit') == [1,'resolved',2,6]
    s.action(1883)
    assert last(s, 'test.swim-endurance-tie') == [
        'swimming-balance-check-required',15,15,0,2,5,600,360,21]


def test_swimming_movement_endurance(s):
    for move, adapted, load, water, distance in [(1,0,0,1,10),(4,0,3,1,4),
            (9,0,0,1,10),(10,0,0,2,20),(15,0,4,3,6),
            (5,1,0,5,50),(5,1,3,5,20),(7,1,1,7,56)]:
        s.action(1878, move, adapted, load)
        assert last(s, 'test.swim-movement') == [water,distance,10]
    for points, weight, pace, score, trained, interval in [
            (0,0,'top-speed',10,0,60),(1,0,'slow',10,0,1800),
            (4,0,'floating',12,1,1800),(4,3000,'top-speed',10,0,60),
            (8,3000,'top-speed',11,1,60)]:
        s.action(1879, points, weight, pace)
        assert last(s, 'test.swim-endurance') == ['ready',score,trained,interval,1,0,0]


def test_swimming_encounter(s):
    s.action(1876)
    assert last(s, 'test.swim-entry') == [10,1,'struggling',5,3]
    assert last(s, 'test.swim-recover') == ['swimming-check-not-due','swimming-rescue-required','recovering',65,1,6]
    assert last(s, 'test.swim-stable') == ['stable',365,1,'resolved',0,9]


def test_swimming_context(s):
    for health, weight, trained, score in [(14,0,0,10),(30,0,0,16),
            (14,3000,0,8),(14,3000,1,12),(14,5000,1,10)]:
        s.action(1877, health, 0, weight, trained)
        assert last(s, 'test.swim-score') == ['ready',None,score,0,0]
    s.action(1877, 14, 0, 0, 0, 1)
    assert last(s, 'test.swim-score') == ['blocked','swimming-default-unavailable',None,0,0]
    s.action(1877, 10, 9, 0, 0)
    assert last(s, 'test.swim-score') == ['blocked','swimming-exhaustion-unavailable',None,9,0]
    s.action(1877, 10, 0, 20001, 0)
    assert last(s, 'test.swim-score') == ['blocked','swimming-overloaded',None,0,0]


def test_swimming_assessments(s):
    for intentional, encumbrance, build, modifier in [(0,0,'ordinary',0),(1,0,'ordinary',3),
            (0,3,'ordinary',-6),(1,4,'ordinary',-5),(0,2,'overweight',-3),
            (0,2,'fat',-1),(0,2,'very-fat',1)]:
        s.action(1873, intentional, encumbrance, build)
        assert last(s, 'test.swimming-modifier') == [modifier]
    for stage in ['entry','stable','struggling','recovering']:
        s.action(1874, stage, 10, 10)
        assert last(s, 'test.swimming-outcome') == [
            'recovering' if stage == 'struggling' else 'stable',60 if stage == 'struggling' else 300,0,0,0,0]
        for roll in [11,18]:
            s.action(1874, stage, 10, roll)
            assert last(s, 'test.swimming-outcome') == ['struggling',5,1,1,0,0]
    for strength, victim, bonus, score, roll, expected in [
            (10,10,0,10,10,[-5,1,0,0,0,0,0,0]),
            (12,9,2,10,11,[0,0,1,1,60,0,0,0]),
            (8,12,0,10,18,[-9,0,6,1,0,1,0,0]),
            (10,10,0,18,17,[-5,0,1,1,60,0,0,0])]:
        s.action(1875, strength, victim, bonus, score, roll)
        assert last(s, 'test.lifesaving') == expected


def test_owned_effort(s):
    for seed, trait, expected in [
            (1,'none',[1,0,0,0,10,0,0,0,0,3,0,'reused']),
            (9,'none',[0,1,0,0,10,0,1,0,0,3,0,'reused']),
            (5,'none',[0,1,0,0,10,0,1,0,0,6,0,'reused']),
            (11,'none',[0,1,1,1,20,1,1,1,1,6,0,'reused']),
            (11,'no-vitals',[0,1,0,1,10,0,1,0,1,6,0,'reused'])]:
        s.action(1950, seed, trait)
        assert last(s, 'test.effort-preview') == [10,0,0,0,0]
        assert last(s, 'test.effort-owned') == expected


def cinematic_state(s):
    s.action(2127)
    return last(s,'test.cinematic-state')


def test_cinematic_concepts(s):
    s.action(2126,0)
    initial = [0,None,0,0,1000000]
    for code in [3,2]:
        s.action(2126,code)
        assert cinematic_state(s) == initial
    for code,reason in [(4,'invention-campaign-option'),(5,'invention-capability-required'),
            (8,'rapid-proposal-execution-unavailable'),(10,'invention-world-physics')]:
        s.action(2126,code)
        assert last(s,'test.cinematic-concept')[:2] == ['blocked',reason]
        assert cinematic_state(s) == initial
        s.command('undo')
    s.action(2126,9)
    assert last(s,'test.cinematic-concept') == ['resolved',None,13]
    assert last(s,'test.cinematic-funding') == ['blocked','cinematic-advanced-defects-unavailable']
    completed = [1,'testable',3,0,1000000]
    assert cinematic_state(s) == completed
    s.command('undo')
    assert cinematic_state(s) == initial
    s.action(2126,1)
    s.action(2126,1)
    assert cinematic_state(s) == completed


def test_cinematic_prototypes(Session,bundle):
    for setup,complete,price,money,bugs,draws in [
            (0,1,1000,899000,0,3),(0,5,1000,899000,1,4),(4,1,7000,393000,0,3)]:
        s = Session(bundle)
        try:
            s.action(2128,setup)
            for preview in [3,2]:
                s.action(2128,preview)
                s.action(2110)
                assert last(s,'test.prototype-completion-state') == [1,'testable',0,None,None,0,0,0,345600]
            s.action(2128,6)
            assert last(s,'test.cinematic-prototype')[:2] == ['blocked','invention-campaign-option']
            s.command('undo')
            s.action(2128,complete)
            assert last(s,'test.cinematic-prototype') == ['resolved',None,price]
            s.action(2110)
            expected = [0,'testable',0 if bugs else 1,0,bugs,0,0,draws,345600]
            assert last(s,'test.prototype-completion-state') == expected
            s.action(2128,1)
            assert last(s,'test.cinematic-prototype') == ['reused',None,price]
            s.action(2110)
            assert last(s,'test.prototype-completion-state') == expected
            s.action(2119)
            assert last(s,'test.production-line-state')[0] == money
            if not bugs:
                s.action(2118,1)
                s.action(2119)
                assert last(s,'test.production-line-state')[0] == money - price * 20
                s.action(2120,1)
                s.action(2121)
                assert last(s,'test.production-order-state') == [money - price * 20 - price // 5,1,1,0,draws,345600,0]
        finally:
            s.close()


def test_cinematic_tools(Session,bundle):
    for setup,expected in [(7,[0,'testable',1,0,0,0,0,3,345600]),
            (8,[0,'testable',0,0,0,0,0,3,345600])]:
        s = Session(bundle)
        try:
            s.action(2128,setup)
            if setup == 7:
                s.action(2128,10)
                s.action(2110)
                assert last(s,'test.prototype-completion-state') == [1,'testable',0,None,None,0,0,0,345600]
            s.action(2128,1)
            s.action(2110)
            assert last(s,'test.prototype-completion-state') == expected
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.action(2128,9)
        s.action(2103)
        assert last(s,'test.facilities-state') == [1000000,0,None,0,0]
    finally:
        s.close()


def test_cinematic_prototype_persistence(Session,bundle,out):
    path = out / 'expanded-cinematic-prototype.zsave'
    first = Session(bundle)
    try:
        first.action(2128,4)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2110')
        second.action(2128,1)
        assert last(second,'test.cinematic-prototype') == ['resolved',None,7000]
        second.command(f':save {path}')
    finally:
        second.close()
    third = Session(bundle)
    try:
        third.command(f':restore {path}\n@2110')
        third.action(2128,1)
        assert last(third,'test.cinematic-prototype') == ['reused',None,7000]
        third.action(2118,1)
        third.action(2120,1)
        third.action(2121)
        assert last(third,'test.production-order-state') == [251600,1,1,0,3,345600,0]
        third.command('undo')
        third.action(2121)
        assert last(third,'test.production-order-state') == [253000,1,0,0,3,345600,0]
    finally:
        third.close()


def test_rapid_concepts(s):
    s.action(2129,0)
    initial = [0,None,0,0,1000000]
    for code in [3,2,7]:
        s.action(2129,code)
        assert cinematic_state(s) == initial
    for code,reason in [(4,'invention-campaign-option'),(5,'invention-capability-required'),
            (8,'rapid-concept-author-facts'),(9,'rapid-concept-timed-request-required')]:
        s.action(2129,code)
        assert last(s,'test.rapid-concept')[:2] == ['blocked',reason]
        assert cinematic_state(s) == initial
        s.command('undo')
    s.action(2129,10)
    assert last(s,'test.rapid-concept') == ['resolved',None,13,120]
    assert last(s,'test.rapid-funding') == ['blocked','rapid-prototype-components-unavailable']
    completed = [1,'testable',4,120,1000000]
    assert cinematic_state(s) == completed
    s.action(2129,1)
    assert last(s,'test.rapid-concept') == ['reused',None,13,120]
    assert cinematic_state(s) == completed
    s.command('undo')
    s.command('undo')
    assert cinematic_state(s) == initial


def test_rapid_concept_retry(s):
    s.action(2129,0)
    s.action(2129,6)
    assert last(s,'test.rapid-concept') == ['resolved',None,10,120]
    assert cinematic_state(s) == [1,None,4,120,1000000]
    s.action(2129,11)
    assert last(s,'test.rapid-concept') == ['resolved',None,13,120]
    assert cinematic_state(s) == [2,'testable',4,240,1000000]


def rapid_purchase_state(s):
    s.action(2131)
    return last(s,'test.rapid-purchase-state')


def test_rapid_purchases(Session,bundle):
    for setup,setup_cost,parts in [(0,1000,10),(5,6000,70)]:
        s = Session(bundle)
        try:
            s.action(2130,setup)
            initial = [1000000,0,0,0,0]
            for code in [3,2]:
                s.action(2130,code)
                assert rapid_purchase_state(s) == initial
            s.action(2130,7)
            assert last(s,'test.rapid-purchase')[:2] == ['blocked','rapid-purchase-author-facts']
            s.command('undo')
            s.action(2130,1)
            assert last(s,'test.rapid-purchase') == ['resolved',None,setup_cost + parts,setup_cost,parts]
            bought = [1000000 - setup_cost - parts,1,1,0,0]
            assert rapid_purchase_state(s) == bought
            for code in [1,8,9]:
                s.action(2130,code)
                assert rapid_purchase_state(s) == bought
            s.action(2130,10)
            assert last(s,'test.rapid-purchase') == ['resolved',None,parts,0,parts]
            assert rapid_purchase_state(s) == [1000000 - setup_cost - parts * 2,2,2,0,0]
            s.command('undo')
            assert rapid_purchase_state(s) == bought
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.action(2130,4)
        s.action(2130,1)
        assert last(s,'test.rapid-purchase')[:2] == ['blocked','rapid-purchase-fractional-ledger-unavailable']
        assert rapid_purchase_state(s) == [1000000,0,0,0,0]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2130,0)
        s.action(2130,6)
        assert last(s,'test.rapid-purchase')[:2] == ['blocked','equipment-unaffordable']
        assert rapid_purchase_state(s) == [1009,0,0,0,0]
    finally:
        s.close()


def rapid_search_state(s):
    s.action(2133)
    return last(s,'test.rapid-search-state')


def test_rapid_search(s):
    s.action(2132,0)
    initial = [1000000,0,0,0,0]
    for code in [3,2,6]:
        s.action(2132,code)
        assert rapid_search_state(s) == initial
    for code,reason in [(4,'rapid-search-scrounging-required'),(7,'rapid-search-author-facts'),
            (10,'invention-capability-required')]:
        s.action(2132,code)
        assert last(s,'test.rapid-search')[:2] == ['blocked',reason]
        assert rapid_search_state(s) == initial
        s.command('undo')
    s.action(2132,1)
    assert last(s,'test.rapid-search') == ['resolved',None,13,200]
    completed = [1000000,0,1,4,60]
    assert rapid_search_state(s) == completed
    s.action(2132,9)
    assert rapid_search_state(s) == completed
    s.action(2132,1)
    assert last(s,'test.rapid-search') == ['reused',None,13,200]
    assert rapid_search_state(s) == completed


def test_rapid_search_failure(s):
    s.action(2132,0)
    s.action(2132,5)
    assert last(s,'test.rapid-search') == ['resolved',None,9,None]
    assert rapid_search_state(s) == [1000000,0,1,3,60]


def rapid_salvage_state(s):
    s.action(2135)
    return last(s,'test.rapid-salvage-state')


def test_rapid_salvage(s):
    s.action(2134,0)
    initial = [1000000,0,0,0,4,60]
    for code in [3,2]:
        s.action(2134,code)
        assert rapid_salvage_state(s) == initial
    for code,reason in [(4,'equipment-unaffordable'),(6,'rapid-salvage-author-facts')]:
        s.action(2134,code)
        assert last(s,'test.rapid-salvage')[:2] == ['blocked',reason]
        s.command('undo')
        assert rapid_salvage_state(s) == initial
    s.action(2134,1)
    assert last(s,'test.rapid-salvage') == ['resolved',None,200]
    claimed = [999800,1,1,1,4,60]
    assert rapid_salvage_state(s) == claimed
    s.action(2134,8)
    assert last(s,'test.rapid-salvage')[:2] == ['blocked','rapid-salvage-already-claimed']
    assert rapid_salvage_state(s) == claimed
    s.action(2134,9)
    assert rapid_salvage_state(s) == claimed
    s.action(2134,1)
    assert last(s,'test.rapid-salvage') == ['reused',None,0]
    assert rapid_salvage_state(s) == claimed


def test_rapid_salvage_failed_search(s):
    s.action(2134,5)
    s.action(2134,1)
    assert last(s,'test.rapid-salvage')[:2] == ['blocked','rapid-salvage-success-required']
    assert rapid_salvage_state(s) == [1000000,0,0,0,3,60]


def rapid_start_state(s):
    s.action(2137)
    return last(s,'test.rapid-start-state')


def test_rapid_starts(Session,bundle):
    for setup,money,start_time in [(0,998990,0),(5,999800,60)]:
        s = Session(bundle)
        try:
            s.action(2136,setup)
            initial = [money,1,0,0,0,0,start_time]
            for code in [3,2]:
                s.action(2136,code)
                assert rapid_start_state(s) == initial
            for code,reason in [(4,'rapid-prototype-components-unavailable'),
                    (6,'rapid-prototype-components-reserved'),(7,'invention-campaign-option')]:
                s.action(2136,code)
                assert last(s,'test.rapid-start')[:2] == ['blocked',reason]
                s.command('undo')
                assert rapid_start_state(s) == initial
            s.action(2136,1)
            assert last(s,'test.rapid-start') == ['resolved',None,1800,0]
            begun = [money,1,1,1,0,1,start_time]
            assert rapid_start_state(s) == begun
            s.action(2136,9)
            assert rapid_start_state(s) == begun
            s.action(2136,1)
            assert last(s,'test.rapid-start') == ['reused',None,1800,0]
            assert rapid_start_state(s) == begun
            s.action(2136,11)
            assert rapid_start_state(s) == begun
            s.action(2136,10)
            assert last(s,'test.rapid-work') == ['resolved',None]
            worked = [money,1,1,1,1800,1,start_time+1800]
            assert rapid_start_state(s) == worked
            s.action(2136,10)
            assert rapid_start_state(s) == worked
            s.action(2136,12)
            assert last(s,'test.rapid-completion') == ['blocked','rapid-prototype-completion-unavailable']
        finally:
            s.close()


def rapid_material_state(s):
    s.action(2139)
    return last(s,'test.rapid-material-state')


def test_rapid_materials(Session,bundle):
    for setup,disposition,remaining in [(0,'incorporated',0),(4,'ruined',0),(5,'retained',1)]:
        s = Session(bundle)
        try:
            s.action(2138,setup)
            initial = [998990,1,None,1,0,1,1800]
            for code in [3,2]:
                s.action(2138,code)
                assert rapid_material_state(s) == initial
            s.action(2138,7)
            assert last(s,'test.rapid-materials')[:2] == ['blocked','rapid-prototype-components-unavailable']
            s.command('undo')
            s.action(2138,1)
            assert last(s,'test.rapid-materials') == ['resolved',None,disposition]
            settled = [998990,remaining,None if remaining else disposition,0,1,1,1800]
            assert rapid_material_state(s) == settled
            s.command('undo')
            assert rapid_material_state(s) == initial
            s.action(2138,1)
            s.action(2138,1)
            assert last(s,'test.rapid-materials') == ['reused',None,disposition]
            assert rapid_material_state(s) == settled
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.action(2138,6)
        s.action(2138,1)
        assert last(s,'test.rapid-materials')[:2] == ['blocked','prototype-work-incomplete']
        assert rapid_material_state(s) == [998990,1,None,1,0,1,0]
    finally:
        s.close()


def device_analysis_state(s):
    s.action(2141)
    return last(s,'test.device-analysis-state')


def test_device_analysis(Session,bundle):
    for setup,seconds in [(0,1200),(4,120)]:
        s = Session(bundle)
        try:
            s.action(2140,setup)
            initial = [0,None,0,1000000,0,0]
            for code in [3,2,6]:
                s.action(2140,code)
                assert device_analysis_state(s) == initial
            for code,reason in [(7,'device-analysis-author-facts'),(8,'invention-capability-required')]:
                s.action(2140,code)
                assert last(s,'test.device-analysis')[:2] == ['blocked',reason]
                s.command('undo')
                assert device_analysis_state(s) == initial
            s.action(2140,1)
            assert last(s,'test.device-analysis') == ['resolved',None,13,1,seconds,0]
            completed = [1,None,0,1000000,4,seconds]
            assert device_analysis_state(s) == completed
            s.action(2140,9)
            assert device_analysis_state(s) == completed
            s.action(2140,10)
            assert last(s,'test.device-analysis') == ['reused',None,13,1,seconds,0]
            assert device_analysis_state(s) == completed
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.action(2140,0)
        s.action(2140,5)
        assert last(s,'test.device-analysis') == ['resolved',None,9,0,1200,0]
        assert device_analysis_state(s) == [1,None,0,1000000,4,1200]
    finally:
        s.close()


def test_animal_training_tables(s):
    expected = {
        2: ([60,None,None,None],None),
        3: ([30,360,None,None],90),
        4: ([7,180,360,None],30),
        5: ([2,90,180,720],14),
    }
    for intelligence,(levels,trick) in expected.items():
        for level,days in enumerate(levels,2):
            s.action(2200,intelligence,level)
            assert last(s,'test.animal-days') == [days,trick]
    for args,expected in [
            ((1,0,0,0,0,0,14),[0,0,0]),
            ((0,1,3,1,1,0,15),[-13,-5,-1]),
            ((1,1,5,1,1,1,20),[-10,-10,-2]),
            ((0,0,0,0,1,0,19),[-5,-5,-1]),
            ((1,0,0,0,0,1,25),[0,-10,-2])]:
        s.action(2201,*args)
        assert last(s,'test.animal-modifiers') == expected


def test_animal_training_plans(Session,bundle):
    for code,status,reason,days,modifier in [
            (0,'ready',None,360,0),(1,'ready',None,360,-5),
            (2,'blocked','animal-training-author-facts',None,0),
            (3,'blocked','animal-training-specialty-required',None,0),
            (4,'blocked','animal-training-unattainable',None,0),
            (5,'ready',None,30,0),(6,'blocked','animal-training-intelligence-unavailable',None,0)]:
        s = Session(bundle)
        try:
            s.action(2202,code)
            assert last(s,'test.animal-plan') == [status,reason,days,modifier,14400,2,7200,0,0]
        finally:
            s.close()


def animal_handling_state(s):
    s.action(2204)
    return last(s,'test.animal-handling-state')


def test_animal_handling(s):
    initial = [0,0,0,0,0]
    for code in [3,2,6]:
        s.action(2203,code)
        assert animal_handling_state(s) == initial
    for code,reason in [(7,'animal-handling-training-required'),(8,'animal-performance-check-required'),
            (10,'animal-handling-participant-unavailable')]:
        s.action(2203,code)
        assert last(s,'test.animal-handling')[:2] == ['blocked',reason]
        s.command('undo')
        assert animal_handling_state(s) == initial
    s.action(2203,1)
    assert last(s,'test.animal-handling') == ['resolved',None,11,1,1]
    completed = [1,0,0,3,30]
    assert animal_handling_state(s) == completed
    s.command('undo')
    assert animal_handling_state(s) == initial
    s.action(2203,1)
    s.action(2203,9)
    assert animal_handling_state(s) == completed
    s.action(2203,1)
    assert last(s,'test.animal-handling') == ['reused',None,11,1,1]
    assert animal_handling_state(s) == completed


def test_animal_handling_modifiers(Session,bundle):
    for code,score in [(4,6),(5,6),(11,3)]:
        s = Session(bundle)
        try:
            s.action(2203,code)
            assert last(s,'test.animal-handling') == ['resolved',None,score,0,1]
            assert animal_handling_state(s) == [1,0,0,3,30]
        finally:
            s.close()


def animal_performance_state(s):
    s.action(2206)
    return last(s,'test.animal-performance-state')


def test_animal_performance(Session,bundle):
    for setup,completion,handling_success,score,success in [(0,1,1,12,1),(4,1,0,12,1),(0,5,1,9,0)]:
        s = Session(bundle)
        try:
            s.action(2205,setup)
            initial = [0,3,30]
            for code in [3,2]:
                s.action(2205,code)
                assert animal_performance_state(s) == initial
            s.action(2205,6)
            assert last(s,'test.animal-performance')[:2] == ['blocked','animal-performance-author-facts']
            s.command('undo')
            s.action(2205,completion)
            assert last(s,'test.animal-performance') == ['resolved',None,score,success,handling_success]
            finished = [1,6,30]
            assert animal_performance_state(s) == finished
            s.command('undo')
            assert animal_performance_state(s) == initial
            s.action(2205,completion)
            s.action(2205,8)
            assert last(s,'test.animal-performance')[:2] == ['blocked','animal-performance-already-resolved']
            assert animal_performance_state(s) == finished
            s.action(2205,9)
            assert animal_performance_state(s) == finished
            s.action(2205,1)
            assert last(s,'test.animal-performance') == ['reused',None,score,success,handling_success]
            assert animal_performance_state(s) == finished
        finally:
            s.close()


def animal_session_state(s):
    s.action(2208)
    return last(s,'test.animal-session-state')


def test_animal_sessions(s):
    initial = [0,0,0,None,0,0]
    for code in [3,2,6]:
        s.action(2207,code)
        assert animal_session_state(s) == initial
    s.action(2207,7)
    assert last(s,'test.animal-session')[:2] == ['blocked','animal-training-session-crosses-day']
    s.command('undo')
    assert animal_session_state(s) == initial
    s.action(2207,1)
    assert last(s,'test.animal-session') == ['resolved',None,1,0,7200]
    first = [1,1,0,None,0,7200]
    assert animal_session_state(s) == first
    s.action(2207,4)
    assert last(s,'test.animal-session')[:2] == ['blocked','animal-training-other-course-today']
    assert animal_session_state(s) == first
    s.action(2207,8)
    assert animal_session_state(s) == first
    s.action(2207,1)
    assert last(s,'test.animal-session') == ['reused',None,1,0,7200]
    assert animal_session_state(s) == first
    s.action(2207,5)
    assert last(s,'test.animal-session') == ['resolved',None,2,1,7200]
    second = [2,2,0,0,0,14400]
    assert animal_session_state(s) == second
    s.command('undo')
    assert animal_session_state(s) == first
    s.action(2207,5)
    s.action(2207,9)
    assert last(s,'test.animal-session')[:2] == ['blocked','animal-training-daily-check-required']
    assert animal_session_state(s) == second


def test_animal_session_persistence(Session,bundle,out):
    path = out / 'expanded-animal-session.zsave'
    first = Session(bundle)
    try:
        first.action(2207,1)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2208')
        second.action(2207,1)
        assert animal_session_state(second) == [1,1,0,None,0,7200]
        second.action(2207,5)
        assert animal_session_state(second) == [2,2,0,0,0,14400]
    finally:
        second.close()


def animal_daily_state(s):
    s.action(2210)
    return last(s,'test.animal-daily-state')


def test_animal_daily(s):
    s.action(2209,1)
    assert last(s,'test.animal-daily')[:2] == ['blocked','animal-training-check-attendance-required']
    s.action(2209,0)
    initial = [0,0,0,0,0,14400]
    for code in [3,2]:
        s.action(2209,code)
        assert animal_daily_state(s) == initial
    s.action(2209,6)
    assert last(s,'test.animal-daily')[:2] == ['blocked','animal-training-participant-unavailable']
    s.command('undo')
    s.action(2209,1)
    assert last(s,'test.animal-daily') == ['resolved',None,11,1,0]
    credited = [1,None,0,1,3,14400]
    assert animal_daily_state(s) == credited
    s.command('undo')
    assert animal_daily_state(s) == initial
    s.action(2209,1)
    s.action(2209,7)
    assert animal_daily_state(s) == credited
    s.action(2209,1)
    assert last(s,'test.animal-daily') == ['reused',None,11,1,0]
    assert animal_daily_state(s) == credited
    s.action(2209,8)
    assert last(s,'test.animal-daily')[:2] == ['blocked','animal-training-check-attendance-required']
    assert animal_daily_state(s) == credited


def test_animal_daily_failure(Session,bundle):
    for code,score in [(4,6),(5,7),(9,11)]:
        s = Session(bundle)
        try:
            s.action(2209,0)
            s.action(2209,code)
            assert last(s,'test.animal-daily') == ['resolved',None,score,0,1]
            pending = [0,0,1,1,3,14400]
            assert animal_daily_state(s) == pending
            s.action(2209,8)
            assert last(s,'test.animal-daily')[:2] == ['blocked','animal-training-failure-unresolved']
            s.action(2209,11)
            assert last(s,'test.animal-training-failure') == ['blocked','animal-training-attack-execution-unavailable']
            assert animal_daily_state(s) == pending
            s.command('undo')
            s.action(2209,10)
            assert last(s,'test.animal-training-failure') == ['resolved',None]
            resolved = [0,None,0,1,3,14400]
            assert animal_daily_state(s) == resolved
            s.command('undo')
            assert animal_daily_state(s) == pending
            s.action(2209,10)
            s.action(2209,10)
            assert last(s,'test.animal-training-failure') == ['reused',None]
            assert animal_daily_state(s) == resolved
        finally:
            s.close()


def animal_milestone_state(s):
    s.action(2212)
    return last(s,'test.animal-milestone-state')


def test_animal_milestones(Session,bundle):
    for setup,days,level,trick,elapsed in [(0,2,2,None,100800),(4,14,None,'retrieve-marked-object',1137600)]:
        s = Session(bundle)
        try:
            s.action(2211,setup)
            initial = [0,0,0,days,3,elapsed]
            for code in [3,2,5]:
                s.action(2211,code)
                assert animal_milestone_state(s) == initial
            s.action(2211,6)
            assert last(s,'test.animal-milestone')[:2] == ['blocked','animal-milestone-author-facts']
            s.command('undo')
            s.action(2211,1)
            assert last(s,'test.animal-milestone') == ['resolved',None,level,trick]
            learned = [level or 0,1 if trick else 0,1,days,3,elapsed]
            assert animal_milestone_state(s) == learned
            s.command('undo')
            assert animal_milestone_state(s) == initial
            s.action(2211,1)
            s.action(2211,9)
            assert animal_milestone_state(s) == learned
            s.action(2211,1)
            assert last(s,'test.animal-milestone') == ['reused',None,level,trick]
            assert animal_milestone_state(s) == learned
        finally:
            s.close()


def test_learned_animal_tasks(Session,bundle):
    for setup,reason,elapsed in [(0,'animal-task-level-required',100800),(4,'animal-task-trick-required',1137600)]:
        s = Session(bundle)
        try:
            s.action(2211,setup)
            s.action(2211,10)
            assert last(s,'test.learned-animal-task')[:2] == ['blocked',reason]
            assert animal_handling_state(s) == [0,0,0,3,elapsed]
            s.action(2211,1)
            s.action(2211,11)
            assert last(s,'test.learned-animal-task') == ['ready',None,11]
            assert animal_handling_state(s) == [0,0,0,3,elapsed]
            s.action(2211,10)
            assert last(s,'test.learned-animal-task') == ['resolved',None,11]
            completed = [1,0,0,6,elapsed+30]
            assert animal_handling_state(s) == completed
            s.command('undo')
            assert animal_handling_state(s) == [0,0,0,3,elapsed]
            s.action(2211,10)
            s.action(2211,12)
            assert animal_handling_state(s) == completed
            s.action(2211,10)
            assert last(s,'test.learned-animal-task') == ['reused',None,11]
            assert animal_handling_state(s) == completed
        finally:
            s.close()


def test_fear_quirks(Session,bundle,out):
    def state(s):
        s.action(2265)
        return last(s,'test.quirk-state')
    before = [-5,5,10,7,0,0,0,0,0]
    after = [-6,6,10,7,1,1,0,0,0]
    s = Session(bundle)
    try:
        s.action(2264,3)
        assert last(s,'test.quirk-valid') == [5]
        for code in [1,2]:
            s.action(2264,code)
            assert state(s) == before
        s.action(2264,0)
        assert last(s,'test.quirk-acquisition') == ['resolved',None,-1]
        assert state(s) == after
        s.command('undo')
        assert state(s) == before
        s.action(2264,0)
        s.action(2264,3)
        assert last(s,'test.quirk-valid') == [6]
        s.action(2264,0)
        assert state(s) == after
        for code in [5,6]:
            s.action(2264,code)
            assert state(s) == after
        s.action(2264,4)
        assert state(s) == [-6,6,10,7,1,1,1,0,0]
        s.action(2264,4)
        assert last(s,'test.quirk-portrayal') == ['reused',None]
    finally: s.close()
    for setup,reason in [(8,'fear-quirk-relation-required'),(9,'fear-quirk-after-creation')]:
        s = Session(bundle)
        try:
            s.action(2264,setup)
            s.action(2264,0)
            assert last(s,'test.quirk-acquisition') == ['blocked',reason,0]
            assert state(s) == before
        finally: s.close()
    s = Session(bundle)
    try:
        s.action(2264,3)
        s.action(2264,11) # An ordinary sixth quirk has no fear-event exemption.
        valid_count = sum(e['id']=='test.quirk-valid' for e in s.log)
        s.action(2264,3)
        assert sum(e['id']=='test.quirk-valid' for e in s.log) == valid_count
    finally: s.close()
    s = Session(bundle)
    try:
        for code in [0,7,4]: s.action(2264,code)
        assert last(s,'test.quirk-portrayal') == ['blocked','quirk-portrayal-decision']
        assert state(s) == after
    finally: s.close()
    path = out / 'expanded-fear-quirk.zsave'
    first = Session(bundle)
    try:
        first.action(2264,0)
        first.command(f':save {path}\n@2265')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally: first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2265')
        second.action(2264,0)
        assert state(second) == after
        second.action(2264,3)
        assert last(second,'test.quirk-valid') == [6]
        second.action(2264,4)
        assert state(second) == [-6,6,10,7,1,1,1,0,0]
    finally: second.close()


def test_fear_quirk_stun(Session,bundle,out):
    def state(s):
        s.action(2265)
        return last(s,'test.quirk-state'),last(s,'test.quirk-stun-state')
    before = ([-5,5,10,7,0,0,0,0,0],[0,None,0,0,0])
    after = ([-6,6,10,7,1,1,0,1,0],[1,2,0,0,0])
    s = Session(bundle)
    try:
        for code in [21,22]:
            s.action(2264,code)
            assert state(s) == before
        s.action(2264,20)
        assert state(s) == after
        s.command('undo')
        assert state(s) == before
        s.action(2264,20)
        s.action(2264,20)
        assert state(s) == after
        s.action(2264,24)
        assert last(s,'test.quirk-stun-recovery') == ['blocked','fear-recovery-initial-duration']
        assert state(s) == after
    finally: s.close()
    for code,reason in [(28,'fear-stun-quirk-required'),(29,'fear-quirk-module-required'),(8,'fear-quirk-relation-required')]:
        s = Session(bundle)
        try:
            s.action(2264,code)
            s.action(2264,20)
            assert last(s,'test.quirk-stun-start') == ['blocked',reason]
            assert state(s) == before
        finally: s.close()
    path = out / 'expanded-quirk-stun.zsave'
    first = Session(bundle)
    try:
        first.action(2264,20)
        first.command(f':save {path}\n@2265')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally: first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2265')
        second.action(2264,20)
        assert state(second) == after
        for code in [23,27,26,25]: second.action(2264,code)
        # Increasing Will changes character value by fifty, but gives no spendable points.
        assert state(second) == ([44,6,10,7,1,1,0,1,2],[1,2,0,0,0])
        second.action(2264,24)
        assert state(second) == ([44,6,10,7,1,1,0,4,3],[0,2,1,1,0])
    finally: second.close()


def test_fear_faint(Session,bundle,out):
    def state(s):
        s.action(2266)
        return last(s,'test.faint-state')
    s = Session(bundle)
    try:
        for code in [31,32]:
            s.action(2250,code,0)
            assert state(s) == [0,'standing',None,None,0,0,0,0]
        s.action(2250,30,0)
        assert state(s) == [1,'lying',120,None,1,0,1,0]
        for code in [34,35,36]:
            s.action(2250,code,0)
            assert state(s) == [1,'lying',120,None,1,0,1,0]
        assert last(s,'test.faint-recovery') == ['blocked','fear-faint-not-due']
        s.action(2250,33,121)
        assert state(s) == [1,'lying',120,None,1,0,1,0]
        s.action(2250,33,120)
        for code in [37,38]:
            s.action(2250,code,0)
            assert state(s) == [1,'lying',120,None,1,0,1,120]
        s.action(2250,36,0)
        assert state(s) == [1,'lying',180,None,1,1,4,120]
        s.command('undo')
        assert state(s) == [1,'lying',120,None,1,0,1,120]
        s.action(2250,36,0)
        s.action(2250,36,0)
        assert state(s) == [1,'lying',180,None,1,1,4,120]
    finally: s.close()
    path = out / 'expanded-fear-faint.zsave'
    first = Session(bundle)
    try:
        first.action(2250,30,0)
        first.action(2250,33,120)
        first.action(2250,36,0)
        first.command(f':save {path}\n@2266')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally: first.close()
    for other_cause in [False,True]:
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2266')
            assert state(second) == [1,'lying',180,None,1,1,4,120]
            second.action(2250,39,0)
            if other_cause: second.action(2250,41,0)
            second.action(2250,33,60)
            second.action(2250,40,0)
            expected = [int(other_cause),'lying',180,180,1,2,7,180]
            assert state(second) == expected
            second.action(2250,40,0)
            assert state(second) == expected
            second.action(2250,33,61) # A completed faint no longer holds the clock boundary.
            assert state(second)[-1] == 241
        finally: second.close()


def test_fear_faint_injury(Session,bundle,out):
    def state(s):
        s.action(2267)
        return last(s,'test.faint-injury')
    for row,high_health,injury,roll,deadline,draws in [(18,False,1,11,120,4),(18,True,0,11,120,4),(19,False,1,None,240,2)]:
        s = Session(bundle)
        try:
            s.action(2250,42,row)
            if high_health: s.action(2250,39,0)
            for code in [31,32]:
                s.action(2250,code,0)
                assert state(s) == [0,0,None,None,0,0]
            s.action(2250,30,0)
            expected = [injury,injury,roll,deadline,draws,0]
            assert state(s) == expected
            s.command('undo')
            assert state(s) == [0,0,None,None,0,0]
            s.action(2250,30,0)
            s.action(2250,30,0)
            assert state(s) == expected
            path = out / f'expanded-faint-{row}-{high_health}.zsave'
            s.command(f':save {path}\n@2267')
            assert any('[save ok code=0]' in line for line in s.raw_lines)
        finally: s.close()
        restored = Session(bundle)
        try:
            restored.command(f':restore {path}\n@2267')
            restored.action(2250,30,0)
            assert state(restored) == expected
            restored.action(2250,33,deadline)
            assert state(restored) == [injury,injury,roll,deadline,draws,deadline]
        finally: restored.close()
    for row in [18,19]:
        s = Session(bundle)
        try:
            s.action(2250,42,row)
            s.action(2250,43,0)
            s.action(2250,30,0)
            assert last(s,'test.faint-start') == ['blocked','expanded-wound-shock-rule-required']
            assert state(s) == [0,0,None,None,0,0]
        finally: s.close()


def test_fear_fatigue(Session,bundle):
    def state(s):
        s.action(2263)
        return last(s,'test.fear-fatigue-state')
    for setup,start in [(None,0),(23,9),(24,10),(25,19),(26,20)]:
        for amount in [1,2,6]:
            s = Session(bundle)
            try:
                if setup is not None: s.action(2250,setup,amount)
                before = [start,0,int(start==20),0,0,0,0]
                for operation in [21,22]:
                    s.action(2250,operation,amount)
                    assert state(s) == before
                s.action(2250,20,amount)
                injury = max(0,amount-max(0,10-start))
                fatigue = min(start+amount,20)
                expected = [fatigue,injury,int(fatigue==20),injury,1,0,0]
                assert state(s) == expected
                assert last(s,'test.fear-fatigue') == ['resolved',None,fatigue-start,injury]
                s.command('undo')
                assert state(s) == before
                s.action(2250,20,amount)
                s.action(2250,20,amount)
                assert last(s,'test.fear-fatigue') == ['reused',None,0,0]
                assert state(s) == expected
            finally: s.close()
    s = Session(bundle)
    try:
        for operation in [24,27,20]: s.action(2250,operation,6)
        assert last(s,'test.fear-fatigue')[:2] == ['blocked','expanded-wound-shock-rule-required']
        assert state(s) == [10,0,0,0,0,0,0]
    finally: s.close()


def test_fear_fatigue_stun(Session,bundle,out):
    for setup,start,after,collapse in [(24,10,12,0),(25,19,20,1)]:
        s = Session(bundle)
        try:
            s.action(2250,setup,14)
            s.action(2250,2,14)
            s.action(2263)
            assert last(s,'test.fear-fatigue-state') == [start,0,0,0,0,0,0]
            s.action(2250,0,14)
            s.action(2263)
            assert last(s,'test.fear-fatigue-state') == [after,2,collapse,2,1,2,0]
            s.action(2250,0,14)
            s.action(2263)
            assert last(s,'test.fear-fatigue-state') == [after,2,collapse,2,1,2,0]
        finally: s.close()
    s = Session(bundle)
    try:
        for operation in [24,27,0]: s.action(2250,operation,14)
        assert last(s,'test.fear-start') == ['blocked','expanded-wound-shock-rule-required']
        s.action(2263)
        assert last(s,'test.fear-fatigue-state') == [10,0,0,0,0,0,0]
    finally: s.close()
    path = out / 'expanded-fatigue-stun.zsave'
    first = Session(bundle)
    try:
        first.action(2250,0,15)
        first.command(f':save {path}\n@2263')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally: first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2263')
        second.action(2250,0,15)
        second.action(2263)
        assert last(second,'test.fear-fatigue-state') == [2,0,0,0,1,2,0]
        for operation in [3,3,8,5]: second.action(2250,operation,15)
        second.action(2251)
        assert last(second,'test.fear-state') == [0,1,2,1,5,3]
    finally: second.close()


def test_fear_stun(Session,bundle):
    def state(s):
        s.action(2251)
        return last(s,'test.fear-state')
    for row,duration,draws in [(4,1,0),(5,1,0),(6,1,0),(7,1,0),(8,1,0),(9,1,0),(10,2,1),(11,4,2),(14,2,2),(15,2,2)]:
        s=Session(bundle)
        try:
            for code in [1,2]:
                s.action(2250,code,row)
                assert state(s) == [0,0,None,0,0,0]
            s.action(2250,0,row)
            assert state(s) == [1,0,duration,0,draws,0]
            if row >= 14:
                s.action(2263)
                assert last(s,'test.fear-fatigue-state') == [2,0,0,0,1,2,0]
            s.action(2250,4,row) # Lite recovery cannot consume dice or clear owned fear.
            assert state(s) == [1,0,duration,0,draws,0]
            if row >= 6:
                s.action(2250,5,row)
                assert last(s,'test.fear-recovery')[:2] == ['blocked','fear-recovery-initial-duration']
            for second in range(duration): s.action(2250,3,row)
            if row <= 5:
                assert state(s) == [0,1,duration,0,draws,duration]
            else:
                s.action(2250,8,row) # Recovery is not subject to the initial thirteen-point cap.
                s.action(2250,6,row)
                assert state(s) == [1,0,duration,0,draws,duration]
                s.action(2250,7,row)
                assert state(s) == [1,0,duration,0,draws,duration]
                s.action(2250,5,row)
                assert last(s,'test.fear-recovery') == ['resolved',None,20]
                assert state(s) == [0,1,duration,1,draws+3,duration+1]
                s.action(2250,5,row)
                assert last(s,'test.fear-recovery')[:2] == ['reused',None]
                assert state(s) == [0,1,duration,1,draws+3,duration+1]
        finally: s.close()


def test_fear_stun_modifiers(Session,bundle):
    # Original scene modifiers apply only to rows 8+, and survive scene changes.
    for row,expected in [(6,20),(7,20),(8,19),(9,19),(10,19),(11,19)]:
        s = Session(bundle)
        try:
            s.action(2250,9,row)
            s.action(2250,0,row)
            s.action(2251)
            duration = last(s,'test.fear-state')[2]
            s.action(2250,10,row)
            s.action(2250,8,row)
            for second in range(duration): s.action(2250,3,row)
            s.action(2250,5,row)
            assert last(s,'test.fear-recovery') == ['resolved',None,expected]
            s.command('undo')
            s.action(2251)
            assert last(s,'test.fear-state')[0:4] == [1,0,duration,0]
            s.action(2250,5,row)
            assert last(s,'test.fear-recovery') == ['resolved',None,expected]
        finally: s.close()


def test_fear_stun_persistence(Session,bundle,out):
    # Save a failed recovery receipt: replay must not reroll or spend another second.
    path = out / 'expanded-fear-stun.zsave'
    first = Session(bundle)
    try:
        first.action(2250,0,6)
        first.action(2250,3,6)
        first.action(2250,11,6)
        first.action(2250,5,6)
        first.action(2251)
        assert last(first,'test.fear-state') == [1,0,1,1,3,2]
        first.command(f':save {path}\n@2251')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally: first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2251')
        second.action(2250,5,6)
        assert last(second,'test.fear-recovery') == ['reused',None,3]
        second.action(2251)
        assert last(second,'test.fear-state') == [1,0,1,1,3,2]
        second.action(2250,8,6)
        second.action(2250,12,6)
        assert last(second,'test.fear-recovery') == ['resolved',None,20]
        second.action(2251)
        assert last(second,'test.fear-state') == [0,1,1,2,6,3]
    finally: second.close()


def test_fear_combat(Session,bundle):
    def state(s):
        s.action(2253)
        return last(s,'test.fear-combat-state')
    for failed in [False,True]:
        s = Session(bundle)
        try:
            s.action(2252,0)
            assert state(s) == [1,0,1,0,0,0]
            s.action(2252,3)
            assert last(s,'test.fear-combat') == ['blocked','fear-recovery-initial-duration']
            assert state(s) == [1,0,1,0,0,0]
            s.action(2252,1)
            s.action(2252,2)
            assert state(s) == [1,0,1,1,1,0]
            if failed: s.action(2252,7)
            s.action(2252,4)
            s.action(2252,5)
            assert state(s) == [1,0,1,1,1,0]
            s.action(2252,3)
            expected = [int(failed),1,2,1,1,3]
            assert state(s) == expected
            s.command('undo')
            assert state(s) == [1,0,1,1,1,0]
            s.action(2252,3)
            assert state(s) == expected
            if failed:
                s.action(2252,8)
                assert last(s,'test.fear-extra') == ['blocked','fear-recovery-already-attempted']
                assert state(s) == expected
            s.action(2252,2)
            assert state(s) == [int(failed),1,1,2,2,3]
            s.action(2252,3)
            assert last(s,'test.fear-combat') == ['blocked','fear-recovery-maneuver-used']
            assert state(s) == [int(failed),1,1,2,2,3]
        finally: s.close()


def test_owned_retching(Session,bundle):
    def state(s):
        s.action(2256)
        return last(s,'test.retch-state')
    s = Session(bundle)
    try:
        for code in [1,2]:
            s.action(2255,code)
            assert state(s) == [0,0,0,0,0,0]
        s.action(2255,0)
        assert state(s) == [1,0,1,0,0,0]
        s.action(2257)
        assert last(s,'test.retch-scores') == [10,5,5,10,10,5,0,4,'retching-concentration-failure']
        s.action(2255,12)
        assert last(s,'test.retch-concentrate') == ['retching-concentration-failure']
        assert state(s) == [1,0,1,0,0,0]
        s.action(2255,10)
        s.action(2255,4)
        assert last(s,'test.retch-recovery') == ['blocked','retching-initial-duration']
        assert state(s) == [1,0,1,0,0,14]
        s.action(2255,11)
        for code in [6,5]:
            s.action(2255,code)
            assert state(s) == [1,0,1,0,0,15]
        s.action(2255,4)
        assert state(s) == [0,1,1,1,3,16]
        s.action(2257)
        assert last(s,'test.retch-scores') == [10,10,10,10,10,10,0,0,None]
        s.command('undo')
        assert state(s) == [1,0,1,0,0,15]
        s.action(2255,4)
        s.action(2255,4)
        assert last(s,'test.retch-recovery') == ['reused',None]
        assert state(s) == [0,1,1,1,3,16]
    finally: s.close()
    for code,reason in [(8,'retching-oral-review-changed'),(9,'retching-oral-review-required')]:
        s = Session(bundle)
        try:
            s.action(2255,0)
            s.action(2255,3)
            s.action(2255,code)
            before = state(s)
            s.action(2255,4)
            assert last(s,'test.retch-recovery') == ['blocked',reason]
            assert state(s) == before
        finally: s.close()


def test_retching_fatigue(Session,bundle):
    for code,fatigue,injury,collapse in [(14,9,0,0),(7,10,1,0),(13,19,1,1)]:
        for failed in [False,True]:
            s = Session(bundle)
            try:
                s.action(2255,0)
                s.action(2255,3)
                s.action(2255,code)
                if failed: s.action(2255,15)
                for operation in [6,5]:
                    s.action(2255,operation)
                    s.action(2256)
                    assert last(s,'test.retch-state') == [1,fatigue,1,0,0,15]
                    s.action(2258)
                    assert last(s,'test.retch-costs') == [0,0,0,0,0]
                s.action(2255,4)
                s.action(2256)
                assert last(s,'test.retch-state') == [int(failed),fatigue+(0 if failed else 1),1,1,3,16]
                s.action(2258)
                expected = [0,0,0,0,0] if failed else [injury,injury,collapse,1,injury]
                assert last(s,'test.retch-costs') == expected
                s.command('undo')
                s.action(2258)
                assert last(s,'test.retch-costs') == [0,0,0,0,0]
                s.action(2255,4)
                s.action(2255,4)
                s.action(2258)
                assert last(s,'test.retch-costs') == expected
            finally: s.close()
    s = Session(bundle)
    try:
        for code in [0,3,7,16,4]: s.action(2255,code)
        assert last(s,'test.retch-recovery') == ['blocked','expanded-wound-shock-rule-required']
        s.action(2256)
        assert last(s,'test.retch-state') == [1,10,1,0,0,15]
    finally: s.close()


def test_retching_meals(Session,bundle):
    def meals(s):
        s.action(2260)
        return last(s,'test.retch-meal-state')
    s = Session(bundle)
    try:
        s.action(2255,31)
        assert meals(s) == [0,0,0,0]
        s.action(2255,30)
        s.action(2255,30)
        assert last(s,'test.retch-meal') == ['reused',None]
        assert meals(s) == [1,0,0,1]
        s.action(2255,32)
        for code in [1,2]:
            s.action(2255,code)
            assert meals(s) == [1,0,0,1]
        s.action(2255,0)
        assert meals(s) == [0,0,1,1]
        s.command('undo')
        assert meals(s) == [1,0,0,1]
        s.action(2255,0)
        s.action(2255,30)
        assert meals(s) == [0,0,1,1]
        s.action(2255,35)
        s.action(2255,3)
        s.action(2255,4)
        assert last(s,'test.retch-recovery') == ['blocked','retching-oral-review-changed']
        s.action(2255,32)
        s.action(2255,4)
        assert last(s,'test.retch-recovery') == ['resolved',None]
        assert meals(s) == [0,0,1,1]
    finally: s.close()
    for setup,reason in [(32,'meal-credit-not-recorded'),(34,'meal-credit-cycle-consumed')]:
        s = Session(bundle)
        try:
            if setup == 34:
                s.action(2255,30)
                s.action(2255,34)
                assert meals(s) == [0,1,0,1] # A consumed meal cannot feed the next day again.
            s.action(2255,32)
            before = meals(s)
            s.action(2255,0)
            assert last(s,'test.retch-start') == ['blocked',reason]
            assert meals(s) == before
        finally: s.close()
    s = Session(bundle)
    try:
        for code in [30,33,0]: s.action(2255,code)
        assert meals(s) == [1,0,0,1]
        s.action(2256)
        assert last(s,'test.retch-state') == [0,0,0,0,0,0]
    finally: s.close()


def test_retching_remedy(Session,bundle):
    def state(s):
        s.action(2261)
        return last(s,'test.retch-remedy-state')
    s = Session(bundle)
    try:
        for code in [44,41]:
            s.action(2255,code)
            assert state(s) == [0,-2,0,0,0,0,0]
        s.action(2255,40)
        s.action(2255,40)
        assert state(s) == [2,0,1,0,1,0,0]
        s.action(2255,47)
        assert state(s) == [2,0,1,0,2,0,0] # Multiple remedies do not multiply the source bonus.
    finally: s.close()
    s = Session(bundle)
    try:
        for code in [40,45]: s.action(2255,code)
        assert state(s) == [2,0,1,0,1,0,59]
        s.action(2255,49)
        assert state(s) == [0,-2,0,0,1,0,60]
        s.command('undo')
        assert state(s) == [2,0,1,0,1,0,59]
    finally: s.close()
    s = Session(bundle)
    try:
        for code in [48,40]: s.action(2255,code)
        assert state(s) == [0,-2,0,0,1,0,0]
        s.action(2255,51)
        assert state(s) == [2,0,1,0,1,0,10]
    finally: s.close()
    s = Session(bundle)
    try:
        for code in [30,40,46]: s.action(2255,code)
        for code in [1,2]:
            s.action(2255,code)
            assert state(s) == [2,0,1,0,1,0,0]
            s.action(2260)
            assert last(s,'test.retch-meal-state') == [1,0,0,1]
        s.action(2255,0)
        assert state(s) == [0,-2,0,1,1,0,0]
        s.action(2260)
        assert last(s,'test.retch-meal-state') == [0,0,1,1]
        s.command('undo')
        assert state(s) == [2,0,1,0,1,0,0]
        s.action(2255,0)
        s.action(2255,40)
        assert state(s) == [0,-2,0,1,1,0,0]
    finally: s.close()
    for setup,reason in [([50],'nausea-remedy-timing-required'),([43],'nausea-remedy-expired'),([0],'nausea-remedy-retching')]:
        s = Session(bundle)
        try:
            for code in setup: s.action(2255,code)
            before = state(s)
            s.action(2255,40)
            assert last(s,'test.retch-remedy') == ['blocked',reason]
            assert state(s) == before
        finally: s.close()


def test_remedy_persistence(Session,bundle,out):
    for revoked in [False,True]:
        path = out / f'expanded-oral-remedy-{revoked}.zsave'
        first = Session(bundle)
        try:
            first.action(2255,40)
            if revoked:
                first.action(2255,42)
                first.action(2255,0)
            first.command(f':save {path}\n@2261')
            assert any('[save ok code=0]' in line for line in first.raw_lines)
        finally: first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2261')
            second.action(2255,40)
            second.action(2261)
            assert last(second,'test.retch-remedy-state') == ([0,-2,0,1,1,0,0] if revoked else [2,0,1,0,1,0,0])
            second.action(2255,43)
            second.action(2261)
            assert last(second,'test.retch-remedy-state') == [0,-2,0,int(revoked),1,0,60]
        finally: second.close()


def test_retching_combat(Session,bundle):
    for low_fatigue in [False,True]:
        for failed in [False,True]:
            s = Session(bundle)
            try:
                for code in [0,3,20]: s.action(2255,code)
                if low_fatigue: s.action(2255,7)
                if failed: s.action(2255,15)
                s.action(2255,27)
                assert last(s,'test.retch-turn') == ['blocked','retching-concentration-failure']
                for code in [25,24]:
                    s.action(2255,code)
                    s.action(2259)
                    assert last(s,'test.retch-clock') == [1,0,15,0]
                    s.action(2258)
                    assert last(s,'test.retch-costs') == [0,0,0,0,0]
                s.action(2255,23)
                s.action(2259)
                assert last(s,'test.retch-clock') == [2,0,15,3]
                s.action(2258)
                injury = int(low_fatigue)
                expected = [0,0,0,0,0] if failed else [injury,injury,0,1,injury]
                assert last(s,'test.retch-costs') == expected
                s.command('undo')
                s.action(2259)
                assert last(s,'test.retch-clock') == [1,0,15,0]
                s.action(2255,23)
                if failed:
                    s.action(2255,26)
                    assert last(s,'test.retch-extra') == ['blocked','retching-recovery-already-attempted']
                    s.action(2259)
                    assert last(s,'test.retch-clock') == [2,0,15,3]
                s.action(2255,22)
                s.action(2255,23)
                assert last(s,'test.retch-turn') == ['blocked','retching-recovery-maneuver-used']
                s.action(2259)
                assert last(s,'test.retch-clock') == [1,1,16,3]
            finally: s.close()


def test_retching_persistence(Session,bundle,out):
    path = out / 'expanded-retching.zsave'
    first = Session(bundle)
    try:
        first.action(2255,0)
        first.action(2255,10)
        first.command(f':save {path}\n@2256')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally: first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2256')
        second.action(2256)
        assert last(second,'test.retch-state') == [1,0,1,0,0,14]
        second.action(2255,11)
        second.action(2255,4)
        second.action(2255,4)
        second.action(2256)
        assert last(second,'test.retch-state') == [0,1,1,1,3,16]
    finally: second.close()


def test_fear_retching(s):
    for health,duration in [(1,24),(10,15),(15,10),(24,1)]:
        for attribute,modifier in [(1,0),(2,-5),(3,-5),(4,0),(5,0),(6,-5)]:
            for concentration in [0,1]:
                s.action(2254,health,attribute,concentration)
                assert last(s,'test.fear-retching') == ['ready',None,duration,health,1,
                    modifier,1-concentration,concentration,-4,1,1,0,0]
    for health in [25,30,1000]:
        s.action(2254,health,2,0)
        assert last(s,'test.fear-retching')[:4] == ['blocked','retching-duration-source-required',None,None]


def test_fear_context(s):
    for code,a,b,modifier,score in [
            (0,0,0,0,10),(1,0,0,6,13),(2,0,0,2,12),(3,0,0,0,10),
            (4,1,0,-1,9),(4,3,0,-3,7),(5,0,0,0,10),(6,0,0,5,13),
            (7,2,1,-3,7),(7,5,2,-7,3),(8,0,0,-1,9),
            (9,99,0,0,10),(9,100,0,1,11),(10,0,0,3,13),
            (11,0,0,-4,6),(12,2,3,6,13),
            (13,'fearlessness',2,2,12),(13,'fearfulness',2,-2,8),
            (13,'combat-reflexes',1,2,12),(13,'combat-paralysis',1,-2,8),
            (13,'cowardice',4,-4,6),(13,'xenophilia',4,4,13),
            (13,'daredevil',1,1,11),(13,'higher-purpose',1,1,11),
            (14,'fearfulness',2,4,13)]:
        s.action(2249,code,a,b)
        assert last(s,'test.fear-context') == ['ready',modifier,score,0]
    s.action(2249,13,'unfazeable',1)
    assert last(s,'test.fear-context') == ['ready',0,None,1]


def test_fear_assessments(s):
    for will,modifier,immune,status,reason,score in [(20,10,0,'ready',None,13),
            (13,0,0,'ready',None,13),(10,2,0,'ready',None,12),
            (10,-8,0,'blocked','fear-score-unavailable',2),(10,-20,1,'ready',None,None)]:
        s.action(2247,will,modifier,immune)
        assert last(s,'test.fear-assessment') == [status,reason,score,immune]
    # Literal source rows; later state-machine tests must verify the consequences themselves.
    rows=[
        (4,'stun',0,1,1,'automatic',0,None,0),(5,'stun',0,1,1,'automatic',0,None,0),
        (6,'stun',0,1,1,'unmodified-will',0,None,0),(7,'stun',0,1,1,'unmodified-will',0,None,0),
        (8,'stun',0,1,1,'modified-will',0,None,0),(9,'stun',0,1,1,'modified-will',0,None,0),
        (10,'stun',1,1,0,'modified-will',0,None,0),(11,'stun',2,1,0,'modified-will',0,None,0),
        (12,'retch',0,1,0,'health',0,None,0),(13,'trait',0,1,0,None,-1,'mental-quirk',0),
        (14,'stun',1,1,0,'modified-will',0,None,0),(15,'stun',1,1,0,'modified-will',0,None,0),
        (16,'stun',1,1,0,'modified-will',-1,'mental-quirk',0),
        (17,'faint',1,60,0,'health',0,None,0),(18,'faint',1,60,0,'immediate-health-injury-then-health',0,None,0),
        (19,'faint',2,60,0,'health',0,None,0),(20,'faint',4,60,0,'source-followup-required',0,None,0),
        (21,'panic',1,60,0,'unmodified-will',0,None,0),
        (22,'trait',0,1,0,None,-10,'delusion',0),(23,'trait',0,1,0,None,-10,'mental-disadvantage',0),
        (24,'trait',0,1,0,None,-15,'physical-disadvantages',0),
        (25,'trait',0,1,0,None,0,'worsen-self-control-or-mental-disadvantage',0),
        (26,'faint',1,60,0,'immediate-health-injury-then-health',-10,'delusion',0),
        (27,'faint',1,60,0,'immediate-health-injury-then-health',-10,'mental-disadvantage',0),
        (28,'coma',0,3600,0,'health',0,None,0),(29,'coma',1,3600,0,'health',0,None,0),
        (30,'catatonia',1,86400,0,'health',0,None,0),(31,'seizure',1,60,0,'immediate-health-injury',0,None,0),
        (32,'injury',0,1,0,None,0,None,0),(33,'extreme-panic',0,1,0,'unmodified-will-after-authored-reaction',0,None,0),
        (34,'trait',0,1,0,None,-15,'delusion',0),(35,'trait',0,1,0,None,-15,'mental-disadvantage',0),
        (36,'trait',0,1,0,None,-20,'physical-disadvantages',0),(37,'trait',0,1,0,None,-30,'physical-disadvantages',0),
        (38,'coma',1,3600,0,'health',-15,'delusion',0),(39,'coma',1,3600,0,'health',-15,'mental-disadvantage',0),
        (40,'coma',1,3600,0,'health',-15,'mental-disadvantage',1)]
    for row in rows:
        s.action(2248,row[0])
        assert last(s,'test.fear-table') == list(row)
    s.action(2248,100)
    assert last(s,'test.fear-table') == list(rows[-1])


def test_history_purchase(Session,bundle):
    def state(s):
        s.action(2246)
        return last(s,'test.history-purchase-state')
    s=Session(bundle)
    try:
        s.action(2245,7)
        assert last(s,'test.bought-history')[:2] == ['blocked','psionic-history-ability-required']
        for code in [1,2]:
            s.action(2245,code)
            assert state(s) == [0,20,0,0,2,0,0]
        s.action(2245,0)
        assert last(s,'test.history-purchase') == ['resolved',None,18]
        assert state(s) == [1,2,1,1,2,0,0]
        s.action(2245,0)
        assert last(s,'test.history-purchase') == ['reused',None,0]
        s.action(2245,7)
        assert last(s,'test.bought-history') == ['resolved',None,'Someone argued here.']
        assert state(s) == [1,2,1,1,2,3,1]
        s.command('undo')
        assert state(s) == [1,2,1,1,2,0,0]
    finally: s.close()
    for code,status,reason,points in [(3,'blocked','rpg.insufficient-points',18),
            (4,'resolved',None,18),(5,'blocked','psionic-new-power-permission',0),(6,'resolved',None,18)]:
        s=Session(bundle)
        try:
            s.action(2245,code)
            assert last(s,'test.history-purchase') == [status,reason,points]
        finally: s.close()
    s=Session(bundle)
    try:
        s.action(2245,8)
        assert last(s,'test.history-talent') == ['resolved',15]
        assert state(s) == [1,5,1,0,3,0,0]
    finally: s.close()


def test_psionic_history(Session,bundle):
    def state(s):
        s.action(2243)
        return last(s,'test.history-state')
    s=Session(bundle)
    try:
        for band,score in [(0,10),(1,9),(2,8),(3,7),(4,6),(5,5)]:
            s.action(2244,band)
            assert last(s,'test.history-age') == [score,'ready',0,0]
        for code in [3,2]:
            s.action(2242,code)
            assert state(s) == [0,0,18,0,0]
        s.action(2242,0)
        assert last(s,'test.history-reading') == ['resolved',None,'Someone argued here.']
        assert state(s) == [1,0,18,3,1]
        s.action(2242,0)
        assert last(s,'test.history-reading') == ['reused',None,'Someone argued here.']
        assert state(s) == [1,0,18,3,1]
    finally: s.close()
    for code,text in [(6,None),(7,'The cup was a peaceful wedding gift.'),
            (8,'You see two people arguing over the cup.'),(9,None)]:
        s=Session(bundle)
        try:
            s.action(2242,code)
            assert last(s,'test.history-reading') == ['resolved',None,text]
            assert state(s) == [1,0,18,3,1]
            if code in [6,7]:
                s.action(2242,10)
                assert last(s,'test.history-reading')[:2] == ['blocked','psionic-history-retry-delay']
                assert state(s) == [1,0,18,3,86400]
                s.action(2242,11)
                assert last(s,'test.history-reading') == ['resolved',None,'Someone argued here.']
                assert state(s) == [2,0,18,6,86402]
            s.command('undo')
        finally: s.close()
    for code,reason in [(4,'psionic-history-fright-integration-required'),(5,'psionic-history-author-facts')]:
        s=Session(bundle)
        try:
            s.action(2242,code)
            assert last(s,'test.history-reading')[:2] == ['blocked',reason]
            assert state(s) == [0,0,18,0,0]
        finally: s.close()


def test_psionic_purchase(Session,bundle,out):
    def state(s):
        s.action(2241)
        return last(s,'test.psionic-purchase-state')
    path=out / 'expanded-psionic-purchase.zsave'
    s=Session(bundle)
    try:
        s.action(2240,8)
        assert last(s,'test.purchased-warning')[:2] == ['blocked','psionic-danger-ability-required']
        for code in [1,2]:
            s.action(2240,code)
            assert state(s) == [0,20,0,0,0,0]
        s.action(2240,0)
        assert last(s,'test.psionic-purchase') == ['resolved',None,14]
        assert state(s) == [1,6,1,1,0,0]
        s.command(f':save {path}')
    finally: s.close()
    s=Session(bundle)
    try:
        s.command(f':restore {path}\n@2241')
        assert state(s) == [1,6,1,1,0,0]
        s.action(2240,0)
        assert last(s,'test.psionic-purchase') == ['reused',None,0]
        assert state(s) == [1,6,1,1,0,0]
        s.action(2240,8)
        assert last(s,'test.purchased-warning') == ['resolved',None,'Step back.']
        assert state(s) == [1,6,1,1,3,0]
        s.command('undo')
        assert state(s) == [1,6,1,1,0,0]
    finally: s.close()
    for code,status,reason,points in [(4,'blocked','rpg.insufficient-points',14),
            (5,'blocked','psionic-new-power-permission',0),(6,'resolved',None,14),
            (7,'blocked','rpg.downtime-required',0)]:
        s=Session(bundle)
        try:
            s.action(2240,code)
            assert last(s,'test.psionic-purchase') == [status,reason,points]
            s.command('undo')
            assert state(s) == [0,20,0,0,0,0]
        finally: s.close()


def test_psionic_advancement(Session,bundle):
    def state(s):
        s.action(2239)
        return last(s,'test.psionic-advance-state')
    s=Session(bundle)
    try:
        for code in [1,2]:
            s.action(2238,code)
            assert state(s) == [2,20,0,0,0,0]
        s.action(2238,0)
        assert last(s,'test.psionic-advance') == ['resolved',None,10]
        assert state(s) == [4,10,1,1,0,0]
        s.action(2238,0)
        assert last(s,'test.psionic-advance') == ['reused',None,0]
        assert state(s) == [4,10,1,1,0,0]
    finally: s.close()
    for code,status,reason,points in [
            (3,'blocked','rpg.insufficient-points',10),
            (4,'resolved',None,20),
            (5,'blocked','psionic-new-power-permission',0),
            (6,'resolved',None,20),
            (7,'blocked','rpg.downtime-required',0),
            (8,'blocked','psionic-talent-level-permission',0),
            (9,'resolved',None,15)]:
        s=Session(bundle)
        try:
            s.action(2238,code)
            assert last(s,'test.psionic-advance') == [status,reason,points]
            s.command('undo')
            assert state(s) == [2,20,0,0,0,0]
        finally: s.close()


def test_static_health_defaults(Session,bundle):
    def state(s):
        s.action(2237)
        return last(s,'test.static-health')
    for code,expected in [(7,[1,1,20,6,0]),(8,[1,0,0,6,1])]:
        s=Session(bundle)
        try:
            s.action(2235,0)
            assert state(s) == [0,0,0,6,0]
            s.action(2235,9)
            assert state(s) == [0,0,0,6,0]
            s.action(2235,code)
            assert state(s) == expected
            s.command('undo')
            assert state(s) == [0,0,0,6,0]
            s.action(2235,code)
            if code == 7:
                s.action(2235,10)
                assert state(s) == [1,0,20,6,0]
        finally: s.close()


def test_static_ready(s):
    def state():
        s.action(2236)
        return last(s,'test.static-ready-state')
    initial=[1,1,0,0,6]
    assert state() == initial
    for code,reason in [(4,'static-already-selected'),(5,'psionic-static-not-switchable'),(6,'stunned')]:
        s.action(2235,code)
        assert last(s,'test.static-ready')[1] == reason
        s.command('undo')
        assert state() == initial
    s.action(2235,2)
    assert state() == initial
    s.action(2235,0)
    assert state() == [0,2,0,0,6]
    s.action(2235,4)
    assert last(s,'test.static-ready')[1] == 'not-your-turn'
    s.action(2235,3)
    assert state() == [0,1,1,1,6]
    s.action(2235,4)
    assert state() == [1,2,1,1,6]
    s.command('undo')
    assert state() == [0,1,1,1,6]


def test_psionic_static(s):
    for args,cost,radius,blocked in [
            ((0,0,1,9,9,0,0,1),30,0,1),
            ((0,0,1,9,9,0,0,2),30,0,1),
            ((0,0,1,0,0,0,0,0),30,0,0),
            ((1,0,1,1,2,0,0,0),45,1,1),
            ((1,0,1,2,1,0,0,0),45,1,1),
            ((1,0,1,2,2,0,0,0),45,1,0),
            ((3,0,1,4,5,0,0,0),75,4,1),
            ((3,0,1,5,5,0,0,0),75,4,0),
            ((0,0,1,9,9,1,0,1),30,0,0),
            ((0,0,1,9,9,0,1,1),30,0,0),
            ((1,1,0,1,1,0,0,0),75,1,0)]:
        s.action(2234,*args)
        assert last(s,'test.psionic-static') == [cost,radius,'ready',None,blocked,0,0]
    s.action(2233,8,0,1,'iq')
    assert last(s,'test.psionic-resistance-reject') == ['psionic-resistance-always-on']


def test_psionic_resistance(Session,bundle):
    for degree,active,allowed,attribute,cost,status,modifier,immune,score,reason,draws in [
            (3,1,1,'iq',10,'ready',3,0,13,None,3),
            (8,1,1,'will',15,'ready',8,0,18,None,3),
            ('immune',1,1,'iq',30,'ready',0,1,None,'psionic-resistance-immune',0),
            ('immune',1,0,'will',30,'ready',0,0,None,'psionic-no-resistance-roll',0),
            (3,1,0,'iq',10,'ready',0,0,None,'psionic-no-resistance-roll',0),
            (3,1,1,'ht',10,'blocked',0,0,None,'psionic-resistance-attribute-unavailable',0)]:
        s=Session(bundle)
        try:
            s.action(2233,degree,active,allowed,attribute)
            assert last(s,'test.psionic-resistance') == [cost,status,modifier,immune,score,
                    'resolved' if score is not None else 'blocked',reason,draws]
        finally: s.close()


def test_psionic_warning(Session,bundle):
    def state(s):
        s.action(2232)
        return last(s,'test.warning-state')
    s=Session(bundle)
    try:
        for code in [1,2]:
            s.action(2231,code)
            assert state(s) == [0,0,0,0,14]
        s.action(2231,0)
        assert last(s,'test.warning') == ['resolved',None,'Pause: something is wrong.']
        assert state(s) == [1,0,3,0,14]
        s.action(2231,0)
        assert last(s,'test.warning') == ['reused',None,'Pause: something is wrong.']
        assert state(s) == [1,0,3,0,14]
        s.action(2231,10)
        assert last(s,'test.warning')[:2] == ['blocked','psionic-danger-situation-used']
        s.action(2231,9)
        assert state(s) == [1,0,3,0,14]
    finally: s.close()
    for code,status,reason,text,draws in [
            (4,'blocked','psionic-power-suppressed',None,0),
            (5,'resolved',None,None,3),
            (6,'resolved',None,'Pause: something is wrong.',3),
            (7,'resolved',None,'Loose masonry above the doorway is about to fall.',3),
            (8,'resolved',None,'Loose masonry above the doorway is about to fall.',3),
            (11,'blocked','psionic-power-suppressed',None,0),
            (12,'resolved',None,'Pause: something is wrong.',3),
            (13,'blocked','psionic-power-suppressed',None,0),
            (14,'resolved',None,'Pause: something is wrong.',3)]:
        s=Session(bundle)
        try:
            s.action(2231,code)
            assert last(s,'test.warning') == [status,reason,text]
            assert state(s) == [int(status == 'resolved'),0,draws,0,14]
            s.command('undo')
            assert state(s) == [0,0,0,0,14]
        finally: s.close()


def test_psionic_talents(s):
    for level,permission,active,mode,ability,cost,bonus,status,reason in [
            (1,0,1,0,'danger-sense',5,1,'ready',None),
            (4,0,1,0,'danger-sense',20,4,'ready',None),
            (5,1,1,0,'danger-sense',25,5,'ready',None),
            (2,0,0,0,'danger-sense',10,0,'ready',None),
            (2,0,1,1,'danger-sense',0,0,'blocked','psionic-latent-talent-required'),
            (2,0,1,0,'unrelated-ability',10,2,'blocked','psionic-ability-outside-power'),
            (2,0,1,3,'danger-sense',20,2,'ready',None)]:
        s.action(2230,level,permission,active,mode,ability)
        assert last(s,'test.psionic-talent') == [cost,bonus,status,reason,0,0]
    for level,mode,reason in [(5,0,'psionic-talent-level-permission'),
            (2,2,'psionic-talent-price-permission'),(2,4,'psionic-power-has-no-talent')]:
        s.action(2230,level,0,1,mode,'danger-sense')
        assert last(s,'test.psionic-reject') == [reason,0,0]



def test_swarm_persistence(Session,bundle,out):
    path = out / 'expanded-swarm-combat.zsave'
    first = Session(bundle)
    try:
        first.action(2220,0)
        first.action(2222,3)
        first.command(f':save {path}')
    finally: first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2221')
        assert last(second,'test.swarm-health') == [1,1,1,0,0]
        second.action(2220,0)
        assert last(second,'test.swarm-attack')[:2] == ['reused',None]
        second.action(2222,0)
        assert last(second,'test.swarm-counter')[:2] == ['reused',None]
        second.action(2223)
        assert last(second,'test.swarm-counter-state') == [2,0,1,1,0,0]
        second.action(2220,7)
        assert last(second,'test.swarm-attack') == ['resolved',None,1,1]
        # Same-second supplemental action is independently permitted after a swarm attack.
        second.action(2222,7)
        assert last(second,'test.swarm-counter') == ['resolved',None,2,0]
        second.action(2221)
        assert last(second,'test.swarm-health') == [2,2,2,0,1]
        second.action(2223)
        assert last(second,'test.swarm-counter-state') == [4,0,2,2,0,1]
        second.command('undo')
        second.action(2223)
        assert last(second,'test.swarm-counter-state') == [2,0,1,1,0,1]
    finally: second.close()


def test_swarm_exposure_persistence(Session,bundle,out):
    path = out / 'expanded-swarm-exposure.zsave'
    first=Session(bundle)
    try:
        first.action(2216,0)
        first.action(2216,7)
        assert last(first,'test.swarm-protection') == ['active',None,1,1,0]
        first.command(f':save {path}')
    finally: first.close()
    second=Session(bundle)
    try:
        second.command(f':restore {path}\n@2217')
        assert last(second,'test.swarm-state') == [0,0,1]
        second.action(2216,0)
        assert last(second,'test.swarm-protection') == ['active',None,1,1,0]
        second.action(2216,7)
        assert last(second,'test.swarm-protection') == ['active',None,2,0,0]
        second.command('undo')
        second.action(2216,1)
        assert last(second,'test.swarm-protection') == ['active',None,1,1,0]
    finally: second.close()


def test_swarm_counterattacks(Session,bundle):
    def state(s):
        s.action(2223)
        return last(s,'test.swarm-counter-state')
    for setup,amount,threshold in [(3,2,12),(4,1,6)]:
        s=Session(bundle)
        try:
            s.action(2222,setup)
            assert last(s,'test.swarm-counter') == ['resolved',None,amount,0]
            assert state(s) == [amount,0,1,1,0,0]
            s.action(2222,0)
            assert last(s,'test.swarm-counter')[:2] == ['reused',None]
            s.action(2222,7)
            assert last(s,'test.swarm-counter')[:2] == ['blocked','swarm-counterattack-turn-used']
            for turn in range(1,threshold//amount):
                s.action(2222,6)
                dispersed=int((turn+1)*amount == threshold)
                assert state(s) == [(turn+1)*amount,dispersed,turn+1,turn+1,0,turn]
            s.action(2222,6)
            assert last(s,'test.swarm-counter')[:2] == ['blocked','swarm-dispersed']
            s.command('undo')
            assert state(s) == [threshold,1,threshold//amount,threshold//amount,0,threshold//amount-1]
        finally: s.close()
    s=Session(bundle)
    try:
        for dtype,cap in [('imp',1),('pi-',1),('pi',1),('pi+',1),('pi++',1),('cut',2),('cr',2),('burn',2)]:
            for injury,area,expected in [(0,0,0),(1,0,1),(9,0,cap),(9,1,9)]:
                s.action(2224,injury,dtype,area)
                assert last(s,'test.diffuse') == [expected,0,0]
        s.action(2222,0)
        assert last(s,'test.swarm-counter')[:2] == ['blocked','swarm-stomp-ground-required']
        assert state(s) == [0,0,0,0,0,0]
        s.action(2222,8)
        assert last(s,'test.swarm-counter')[:2] == ['ready',None]
        assert state(s) == [0,0,0,0,0,0]
        s.action(2222,9)
        assert state(s) == [0,0,0,0,0,0]
    finally: s.close()


def test_swarm_attacks(Session,bundle):
    def state(s):
        s.action(2221)
        return last(s,'test.swarm-health')
    s=Session(bundle)
    try:
        s.action(2220,1)
        assert last(s,'test.swarm-attack')[:2] == ['ready',None]
        assert state(s) == [0,0,0,0,0]
        s.action(2220,2)
        assert state(s) == [0,0,0,0,0]
        s.action(2220,0)
        assert last(s,'test.swarm-attack') == ['resolved',None,1,1]
        assert state(s) == [1,1,1,0,0]
        s.action(2220,0)
        assert last(s,'test.swarm-attack')[:2] == ['reused',None]
        assert state(s) == [1,1,1,0,0]
        s.action(2220,8)
        assert last(s,'test.swarm-attack')[:2] == ['blocked','swarm-attack-turn-used']
        s.action(2220,7)
        assert state(s) == [2,2,2,0,1]
        s.command('undo')
        assert state(s) == [1,1,1,0,0]
    finally: s.close()
    for code,expected,health in [
            (4,['resolved',None,2,3],[3,1,1,1,0]),
            (5,['resolved',None,0,0],[0,0,1,0,0]),
            (6,['blocked','swarm-pursuit-ended',0,0],[0,0,0,0,0])]:
        s=Session(bundle)
        try:
            s.action(2220,code)
            assert last(s,'test.swarm-attack') == expected
            assert state(s) == health
        finally: s.close()


def test_swarm_protection(Session,bundle):
    for setup,limit,initial_immune,dr in [(0,2,1,0),(3,5,1,0),(4,6,0,5),(5,6,1,0)]:
        s=Session(bundle)
        try:
            s.action(2216,1)
            s.action(2217)
            assert last(s,'test.swarm-state') == [None,0,0]
            s.action(2216,2)
            s.action(2217)
            assert last(s,'test.swarm-state') == [None,0,0]
            s.action(2216,setup)
            assert last(s,'test.swarm-protection') == ['active',None,0,initial_immune,dr]
            s.action(2216,9)
            assert last(s,'test.swarm-protection')[:2] == ['blocked','swarm-exposure-already-recorded']
            for elapsed in range(1,limit+1):
                s.action(2216,7)
                immune = initial_immune if setup == 5 or elapsed < limit else 0
                assert last(s,'test.swarm-protection') == ['active',None,elapsed,immune,dr]
                s.action(2216,0)  # Repeated begin cannot reset ingress time.
                assert last(s,'test.swarm-protection') == ['active',None,elapsed,immune,dr]
            s.action(2216,8)
            s.action(2217)
            assert last(s,'test.swarm-state') == [0,0,limit]
        finally: s.close()


def test_animal_strength_damage(s):
    # Foundation-only creature fixture exercises table reuse without equipment includes.
    # Expected thrust values are independently transcribed from B16; B460 supplies anatomy.
    for strength,kind,anatomy,weak,horizontal,dx,skill,dice,adds,dtype in [
            (10,'bite','ordinary',0,0,10,10,1,-3,'cr'),
            (20,'kick','ordinary',0,0,10,10,2,-1,'cr'),
            (21,'bite','ordinary',1,0,10,10,2,-5,'cr'),
            (22,'kick','hooves',0,1,9,10,2,0,'cr'),
            (24,'kick','hooves',0,1,9,12,2,3,'cr'),
            (27,'striker','imp',0,0,8,None,3,2,'imp'),
            (40,'claw','sharp-claws',0,0,10,12,4,4,'cut'),
            (45,'striker','cr',0,0,12,None,5,5,'cr'),
            (100,'bite','fangs',0,0,10,12,11,10,'imp'),
            (110,'bite','fangs',0,0,10,12,12,11,'imp')]:
        s.action(2215,strength,kind,anatomy,weak,horizontal,dx,skill)
        assert last(s,'test.natural-strength') == ['ready',dice,adds,dtype,0,0]


def test_animal_natural_damage(s):
    # Independent B460 examples use raw thrust 2d-1, not precomputed creature attacks.
    for kind,anatomy,weak,horizontal,score,adds,dtype,anatomy_bonus,skill_bonus in [
            ('bite','ordinary',0,0,10,-2,'cr',-1,0),
            ('bite','sharp-teeth',0,0,11,-2,'cut',-1,0),
            ('bite','fangs',0,0,12,0,'imp',-1,2),
            ('bite','ordinary',1,0,10,-6,'cr',-5,0),
            ('bite','ordinary',1,0,12,-4,'cr',-5,2),
            ('claw','ordinary',0,0,10,-2,'cr',-1,0),
            ('claw','blunt-claws',0,0,10,0,'cr',1,0),
            ('claw','sharp-claws',0,0,12,0,'cut',-1,2),
            ('kick','ordinary',0,0,10,-1,'cr',0,0),
            ('kick','ordinary',0,1,10,-3,'cr',-2,0),
            ('kick','hooves',0,0,10,1,'cr',2,0),
            ('kick','hooves',0,1,10,-1,'cr',0,0),
            ('kick','blunt-claws',0,1,10,1,'cr',2,0),
            ('kick','sharp-claws',0,1,12,1,'cut',0,2),
            ('striker','cr',0,0,10,1,'cr',2,0),
            ('striker','cut',0,0,12,3,'cut',2,2),
            ('striker','imp',0,0,12,3,'imp',2,2)]:
        s.action(2214,2,-1,kind,anatomy,weak,horizontal,10,score)
        assert last(s,'test.natural-damage') == ['ready',2,adds,dtype,anatomy_bonus,skill_bonus,0,0]
    # Missing skill grants no bonus. Negative adds remain a formula, not premature damage clamping.
    s.action(2214,1,-6,'bite','ordinary',1,0,10,None)
    assert last(s,'test.natural-damage') == ['ready',1,-9,'cr',-3,0,0,0]


def test_animal_values(s):
    for args,numerator,denominator,money in [
            (('domestic',100,2,0),100,1,100),
            (('domestic',100,2,2),100,1,100),
            (('domestic',100,3,0),200,3,None),
            (('domestic',150,3,2),100,1,100),
            (('domestic',100,3,3),100,1,100),
            (('domestic',100,4,0),200,3,None),
            (('domestic',100,4,3),100,1,100),
            (('domestic',101,4,4),303,2,None),
            (('domestic',100,5,3),100,1,100),
            (('domestic',100,5,4),150,1,150),
            (('domestic',100,5,5),200,1,200),
            (('enhanced',1000,4,3,4),4000,1,4000),
            (('enhanced',1000,5,3,5),10000,1,10000),
            (('move',1000,0),1000,1,1000),
            (('move',1000,1),2000,1,2000),
            (('move',1000,2),4000,1,4000),
            (('war',4000,1),4000,1,4000),
            (('war',2000,0),4000,1,4000),
            (('domestic',0,3,0),0,1,0)]:
        s.action(2213,*args)
        assert last(s,'test.animal-value') == ['ready',None,numerator,denominator,money,0,0]
    for args,reason in [
            (('enhanced',1000,4,3,3),'animal-value-full-training-required'),
            (('enhanced',1000,4,4,4),'animal-value-intelligence-increase-unavailable'),
            (('enhanced',1000,5,2,5),'animal-value-intelligence-increase-unavailable')]:
        s.action(2213,*args)
        assert last(s,'test.animal-value') == ['blocked',reason,0,1,None,0,0]


def test_cinematic_advanced_concept(s):
    s.action(2126,0)
    s.action(2126,6)
    assert last(s,'test.cinematic-concept') == ['resolved',None,3]
    assert cinematic_state(s) == [1,None,3,0,1000000]


def test_cinematic_concept_persistence(Session,bundle,out):
    path = out / 'expanded-cinematic-concept.zsave'
    first = Session(bundle)
    try:
        first.action(2126,0)
        first.action(2126,1)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2127')
        second.action(2126,1)
        assert cinematic_state(second) == [1,'testable',3,0,1000000]
    finally:
        second.close()


def test_inventor_permission(Session,bundle):
    for code,reason,cost in [(0,'invention-campaign-option',25),(1,None,25),
            (2,'invention-capability-required',25),(3,'invention-capability-required',25),
            (4,'invention-campaign-option',25),(5,'invention-capability-required',25),
            (6,None,50),(7,'invention-world-physics',25),(8,None,25),(9,'invention-design-approval',25)]:
        s = Session(bundle)
        try:
            s.action(2125,code)
            assert last(s,'test.inventor-permission') == ['ready' if reason is None else 'blocked',reason,cost,0,0,0]
        finally:
            s.close()


def test_cinematic_invention_assessments(s):
    for args,expected in [
            (('simple',4000,8,8,0),[50000,4000]),
            (('average',4000,8,9,0),[350000,12000]),
            (('complex',4000,8,11,0),[1750000,60000]),
            (('complex',4000,8,11,1),[175000,60000]),
            (('amazing',100,8,10,0),[2500000,700]),
            (('simple',4000,8,7,0),[50000,4000])]:
        s.action(2122,*args)
        assert last(s,'test.cinematic-invention-cost') == expected + [0,0]
    for args,expected in [(('simple',0,8,8),0),(('average',0,8,8),-2),
            (('complex',0,8,11),-19),(('amazing',0,8,8),-8),
            (('software',6,8,9),-11),(('complex',0,10,8),-4)]:
        s.action(2123,*args)
        assert last(s,'test.cinematic-invention-modifier') == [expected]
    for args,expected in [(('simple',1,1,1),[120,60]),(('simple',6,6,6),[720,360]),
            (('average',2,1),[1800,120]),(('average',2,2),[1800,120]),
            (('average',2,3),[3600,120]),(('average',2,6),[14400,120]),
            (('complex',3,6),[21600,180]),(('amazing',4,6,6,6,6),[86400,240])]:
        s.action(2124,*args)
        assert last(s,'test.rapid-invention-duration') == expected + [0,0]


def production_order_state(s):
    s.action(2121)
    return last(s,'test.production-order-state')


def test_production_order(s):
    s.action(2120,0)
    initial = [899000,1,0,0,3,345600,0]
    for code in [3,2]:
        s.action(2120,code)
        assert production_order_state(s) == initial
    s.action(2120,5)
    assert last(s,'test.production-order') == ['blocked','production-order-funds',0,0]
    s.command('undo')
    s.action(2120,1)
    funded = [898800,1,1,0,3,345600,0]
    assert last(s,'test.production-order') == ['resolved',None,200,172800]
    assert production_order_state(s) == funded
    for code in [1,6,7,8]:
        s.action(2120,code)
        assert production_order_state(s) == funded
    s.action(2120,9)
    delivered = [898800,2,1,1,3,518400,0]
    assert production_order_state(s) == delivered
    s.command('undo')
    assert production_order_state(s) == funded
    s.action(2120,9)
    for code in [1,9]:
        s.action(2120,code)
        assert production_order_state(s) == delivered


def test_production_order_line(s):
    s.action(2120,0)
    s.action(2120,4)
    assert production_order_state(s) == [878800,1,1,0,3,345600,1]
    s.action(2120,9)
    assert production_order_state(s) == [878800,2,1,1,3,381600,0]


def test_production_order_persistence(Session,bundle,out):
    for complete in [False,True]:
        path = out / f'expanded-production-order-{complete}.zsave'
        first = Session(bundle)
        try:
            first.action(2120,0)
            first.action(2120,1)
            if complete: first.action(2120,9)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2121')
            second.action(2120,1)
            second.action(2120,9)
            assert production_order_state(second) == [898800,2,1,1,3,518400,0]
        finally:
            second.close()


def production_line_state(s):
    s.action(2119)
    return last(s,'test.production-line-state')


def test_production_line(s):
    s.action(2118,1)
    assert last(s,'test.production-line') == ['blocked','production-line-working-prototype-required',0]
    s.action(2118,0)
    initial = [899000,0,1,3,345600]
    for code in [3,2]:
        s.action(2118,code)
        assert production_line_state(s) == initial
    for code,reason in [(4,'production-line-funds'),(6,'production-line-author-facts')]:
        s.action(2118,code)
        assert last(s,'test.production-line') == ['blocked',reason,0]
        s.command('undo')
        assert production_line_state(s) == initial
    s.action(2118,1)
    assert last(s,'test.production-line') == ['resolved',None,20000]
    funded = [879000,1,1,3,345600]
    assert production_line_state(s) == funded
    s.command('undo')
    assert production_line_state(s) == initial
    s.action(2118,1)
    for code in [1,5]:
        s.action(2118,code)
        assert production_line_state(s) == funded


def test_production_line_persistence(Session,bundle,out):
    path = out / 'expanded-production-line.zsave'
    first = Session(bundle)
    try:
        first.action(2118,0)
        first.action(2118,1)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2119')
        second.action(2118,1)
        assert production_line_state(second) == [879000,1,1,3,345600]
    finally:
        second.close()


def test_production_assessments(s):
    for args,expected in [
            ((1000,345600,0,0),[0,200,1,172800,1]),
            ((1000,345600,0,1),[0,1000,1,172800,1]),
            ((1000,345600,1,0),[20000,200,1,36000,1]),
            ((1000,345600,1,1),[20000,500,1,36000,1]),
            ((2000,345600,1,1),[40000,1000,1,345600,7]),
            ((101,101,0,0),[0,101,5,101,2]),
            ((101,101,1,1),[2020,101,2,101,7]),
            ((1,252,1,0),[20,1,5,36,1]),
            ((1,251,1,0),[20,1,5,251,7]),
            ((0,86400,1,0),[0,0,1,0,1]),
            ((100000000,1000000000,1,1),[2000000000,50000000,1,1000000000,7])]:
        s.action(2117,*args)
        assert last(s,'test.production-assessment') == expected + [0,0]


def prototype_testing_state(s):
    s.action(2116)
    return last(s,'test.prototype-testing-state')


def test_prototype_testing(s):
    s.action(2115,0)
    initial = [0,0,0,0,0,345600]
    for code in [3,2,7]:
        s.action(2115,code)
        assert prototype_testing_state(s) == initial
    s.action(2115,8)
    assert last(s,'test.prototype-testing') == ['blocked','prototype-test-incident-policy-unavailable',0,0]
    assert prototype_testing_state(s) == initial
    s.command('undo')
    s.action(2115,1)
    completed = [1,0,1,0,3,950400]
    assert prototype_testing_state(s) == completed
    s.command('undo')
    assert prototype_testing_state(s) == initial
    s.action(2115,1)
    for code in [1,9]:
        s.action(2115,code)
        assert prototype_testing_state(s) == completed


def test_prototype_testing_outcomes(Session,bundle):
    for code,expected in [(4,[1,1,1,0,3,950400]),(5,[0,0,1,1,3,950400]),(6,[6,0,1,0,3,950400])]:
        s = Session(bundle)
        try:
            s.action(2115,0)
            s.action(2115,code)
            assert prototype_testing_state(s) == expected
            s.action(2115,1)
            assert prototype_testing_state(s) == expected
        finally:
            s.close()


def test_prototype_testing_persistence(Session,bundle,out):
    for code in [1,4,5,6]:
        path = out / f'expanded-prototype-testing-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(2115,0)
            first.action(2115,code)
            saved = prototype_testing_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2116')
            second.action(2115,1)
            assert prototype_testing_state(second) == saved
        finally:
            second.close()


def prototype_use_state(s):
    s.action(2114)
    return last(s,'test.prototype-use-state')


def test_prototype_operation(s):
    s.action(2113,0)
    initial = [0,0,0,0,0,345600]
    for code in [3,2,7]:
        s.action(2113,code)
        assert prototype_use_state(s) == initial
    s.action(2113,6)
    assert last(s,'test.prototype-use') == ['blocked','prototype-operation-fault-choice',None,None]
    s.command('undo')
    s.action(2113,1)
    assert last(s,'test.prototype-use') == ['resolved',None,10,'blur']
    activated = [1,1,0,1,3,345660]
    assert prototype_use_state(s) == activated
    s.command('undo')
    assert prototype_use_state(s) == initial
    s.action(2113,1)
    for code in [1,8]:
        s.action(2113,code)
        assert prototype_use_state(s) == activated


def test_prototype_operation_boundaries(Session,bundle):
    for code,expected in [(4,[0,0,0,1,3,345660]),(5,[0,0,1,1,3,345660])]:
        s = Session(bundle)
        try:
            s.action(2113,0)
            s.action(2113,code)
            assert prototype_use_state(s) == expected
            s.action(2113,1)
            assert prototype_use_state(s) == expected
        finally:
            s.close()


def test_prototype_operation_persistence(Session,bundle,out):
    path = out / 'expanded-prototype-operation.zsave'
    first = Session(bundle)
    try:
        first.action(2113,0)
        first.action(2113,1)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2114')
        second.action(2113,1)
        assert prototype_use_state(second) == [1,1,0,1,3,345660]
        assert prototype_operation_state(second) == [13,None,1,3,345660]
    finally:
        second.close()


def prototype_operation_state(s):
    s.action(2112)
    return last(s,'test.prototype-operation')


def test_prototype_defects(s):
    s.action(2111,0)
    initial = [None,'prototype-item-unavailable',0,5,345600]
    for code in [3,2]:
        s.action(2111,code)
        assert prototype_operation_state(s) == initial
    s.action(2111,4)
    assert last(s,'test.prototype-defects') == ['blocked','prototype-defect-count']
    s.command('undo')
    s.action(2111,1)
    delivered = [15,None,1,5,345600]
    assert prototype_operation_state(s) == delivered
    s.command('undo')
    assert prototype_operation_state(s) == initial
    s.action(2111,1)
    s.action(2111,1)
    assert prototype_operation_state(s) == delivered
    s.action(2111,5)
    assert prototype_operation_state(s) == [13,None,1,5,345600]
    s.action(2111,7)
    assert prototype_operation_state(s) == [13,None,1,5,345600]
    s.action(2111,6)
    assert prototype_operation_state(s) == [None,'prototype-defect-blocked',1,5,345600]
    s.action(2111,8)
    assert prototype_operation_state(s) == [None,'prototype-item-unavailable',1,5,345600]


def test_prototype_defects_persistence(Session,bundle,out):
    path = out / 'expanded-prototype-defects.zsave'
    first = Session(bundle)
    try:
        first.action(2111,0)
        first.action(2111,1)
        first.action(2111,5)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2112')
        assert prototype_operation_state(second) == [13,None,1,5,345600]
        second.action(2111,1)
        assert prototype_operation_state(second) == [13,None,1,5,345600]
    finally:
        second.close()


def prototype_completion_state(s):
    s.action(2110)
    return last(s,'test.prototype-completion-state')


def test_prototype_completion(s):
    s.action(2109,0)
    initial = [1,'testable',0,None,None,0,0,0,345600]
    for code in [7,2]:
        s.action(2109,code)
        assert prototype_completion_state(s) == initial
    s.action(2109,8)
    assert last(s,'test.prototype-completion') == ['blocked','prototype-accident-author-facts',None,0,0]
    s.command('undo')
    s.action(2109,1)
    failed = [0,'testable',0,0,0,0,0,3,345600]
    assert prototype_completion_state(s) == failed
    s.command('undo')
    assert prototype_completion_state(s) == initial
    s.action(2109,1)
    for code in [1,9]:
        s.action(2109,code)
        assert prototype_completion_state(s) == failed


def test_prototype_completion_outcomes(Session,bundle):
    for code,expected in [
            (3,[0,'testable',0,1,5,0,0,5,345600]),
            (4,[0,'testable',1,0,0,0,0,3,345600]),
            (5,[0,None,0,0,0,0,0,3,345600]),
            (6,[0,'testable',0,0,0,4,1,5,345600])]:
        s = Session(bundle)
        try:
            s.action(2109,0)
            s.action(2109,code)
            assert prototype_completion_state(s) == expected
            s.action(2109,1)
            assert prototype_completion_state(s) == expected
        finally:
            s.close()


def test_prototype_completion_persistence(Session,bundle,out):
    for code in [3,4,5,6]:
        path = out / f'expanded-prototype-completion-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(2109,0)
            first.action(2109,code)
            saved = prototype_completion_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2110')
            assert prototype_completion_state(second) == saved
            second.action(2109,1)
            assert prototype_completion_state(second) == saved
        finally:
            second.close()


def prototype_accident_state(s):
    s.action(2108)
    return last(s,'test.prototype-accident-state')


def test_prototype_accident(s):
    s.action(2107,0)
    initial = [0,0,0,899000,0,345600]
    for code in [3,2,5]:
        s.action(2107,code)
        assert prototype_accident_state(s) == initial
    s.action(2107,4)
    assert last(s,'test.prototype-accident') == ['blocked','prototype-accident-author-facts',0]
    s.command('undo')
    s.action(2107,1)
    hurt = [4,1,1,899000,2,345600]
    assert prototype_accident_state(s) == hurt
    s.command('undo')
    assert prototype_accident_state(s) == initial
    s.action(2107,1)
    for code in [1,7]:
        s.action(2107,code)
        assert prototype_accident_state(s) == hurt


def test_prototype_accident_protection(s):
    s.action(2107,0)
    s.action(2107,6)
    assert prototype_accident_state(s) == [0,1,1,899000,2,345600]


def test_prototype_accident_persistence(Session,bundle,out):
    path = out / 'expanded-prototype-accident.zsave'
    first = Session(bundle)
    try:
        first.action(2107,0)
        first.action(2107,1)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2108')
        second.action(2107,1)
        assert prototype_accident_state(second) == [4,1,1,899000,2,345600]
    finally:
        second.close()


def test_prototype_work(s):
    s.action(2106,0)
    initial = [899000,1,345600,0,2,0]
    for code in [3,2,6]:
        s.action(2106,code)
        assert prototype_start_state(s) == initial
    for code,reason in [(4,'prototype-work-author-facts'),(5,'prototype-facilities-required')]:
        s.action(2106,code)
        assert last(s,'test.prototype-work') == ['blocked',reason,0]
        s.command('undo')
        assert prototype_start_state(s) == initial
    s.action(2106,1)
    worked = [899000,1,345600,86400,2,86400]
    assert last(s,'test.prototype-work') == ['resolved',None,86400]
    assert prototype_start_state(s) == worked
    s.command('undo')
    assert prototype_start_state(s) == initial
    s.action(2106,1)
    for code in [1,8]:
        s.action(2106,code)
        assert prototype_start_state(s) == worked
    for day in [2,3,4]:
        s.action(2106,9)
        assert prototype_start_state(s) == [899000,1,345600,day*86400,2,day*86400]
    s.action(2106,7)
    assert last(s,'test.prototype-work') == ['blocked','prototype-work-exceeds-remaining',0]
    assert prototype_start_state(s) == [899000,1,345600,345600,2,345600]


def test_prototype_work_persistence(Session,bundle,out):
    path = out / 'expanded-prototype-work.zsave'
    first = Session(bundle)
    try:
        first.action(2106,0)
        first.action(2106,1)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2105')
        assert prototype_start_state(second) == [899000,1,345600,86400,2,86400]
        second.action(2106,1)
        assert prototype_start_state(second) == [899000,1,345600,86400,2,86400]
        second.action(2106,7)
        assert prototype_start_state(second) == [899000,1,345600,90000,2,90000]
    finally:
        second.close()


def prototype_start_state(s):
    s.action(2105)
    return last(s,'test.prototype-start-state')


def test_prototype_start(s):
    s.action(2104,0)
    initial = [900000,0,None,0,0,0]
    for code in [3,2]:
        s.action(2104,code)
        assert prototype_start_state(s) == initial
    for code,reason in [(4,'prototype-attempt-funds'),(5,'prototype-facilities-required'),(8,'prototype-participant-unavailable')]:
        s.action(2104,code)
        assert last(s,'test.prototype-start') == ['blocked',reason,0,0]
        s.command('undo')
        assert prototype_start_state(s) == initial
    s.action(2104,1)
    assert last(s,'test.prototype-start') == ['resolved',None,1000,345600]
    begun = [899000,1,345600,0,2,0]
    assert prototype_start_state(s) == begun
    s.command('undo')
    assert prototype_start_state(s) == initial
    s.action(2104,1)
    for code in [1,6]:
        s.action(2104,code)
        assert prototype_start_state(s) == begun
    s.action(2104,7)
    assert last(s,'test.prototype-start') == ['blocked','prototype-already-active',0,0]
    assert prototype_start_state(s) == begun


def test_prototype_start_calendar(s):
    s.action(2104,9)
    s.action(2104,1)
    assert last(s,'test.prototype-start') == ['blocked','prototype-calendar-required',0,0]
    assert prototype_start_state(s) == [750000,0,None,0,0,0]
    s.action(2104,10)
    assert last(s,'test.prototype-start') == ['resolved',None,1000,5097600]
    assert prototype_start_state(s) == [749000,1,5097600,0,1,0]


def test_prototype_start_persistence(Session,bundle,out):
    path = out / 'expanded-prototype-start.zsave'
    first = Session(bundle)
    try:
        first.action(2104,0)
        first.action(2104,1)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2105')
        assert prototype_start_state(second) == [899000,1,345600,0,2,0]
        second.action(2104,1)
        assert last(second,'test.prototype-start') == ['reused',None,0,345600]
        assert prototype_start_state(second) == [899000,1,345600,0,2,0]
    finally:
        second.close()


def test_invention_blueprints(s):
    initial = [0,0,None,0,0]
    for code in [11,12]:
        s.action(2097,code)
        assert concept_state(s) == initial
    for code in [13,15]:
        s.action(2097,code)
        assert last(s,'test.blueprint') == ['blocked','invention-blueprint-author-facts']
        assert concept_state(s) == initial
        s.command('undo')
    s.action(2097,10)
    entered = [0,0,'testable',0,0]
    assert last(s,'test.blueprint') == ['resolved',None]
    assert concept_state(s) == entered
    s.command('undo')
    assert concept_state(s) == initial
    s.action(2097,10)
    for code in [10,14]:
        s.action(2097,code)
        assert concept_state(s) == entered
    s.action(2097,7)
    assert last(s,'test.concept') == ['resolved',None,None,5,10]
    assert concept_state(s) == [0,1,'testable',3,0]
    s.action(2102,1)
    assert facilities_state(s) == [900000,1,'available',3,0]


def test_invention_blueprint_persistence(Session,bundle,out):
    path = out / 'expanded-invention-blueprint.zsave'
    first = Session(bundle)
    try:
        first.action(2097,10)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2098')
        assert concept_state(second) == [0,0,'testable',0,0]
        second.action(2097,10)
        assert last(second,'test.blueprint') == ['reused',None]
        assert concept_state(second) == [0,0,'testable',0,0]
        second.action(2102,1)
        assert facilities_state(second) == [900000,1,'available',0,0]
    finally:
        second.close()


def facilities_state(s):
    s.action(2103)
    return last(s,'test.facilities-state')


def test_invention_facilities(s):
    s.action(2102,1)
    assert last(s,'test.facilities') == ['blocked','invention-facilities-theory-required',0,0]
    s.action(2102,0)
    initial = [1000000,0,None,3,0]
    for code in [3,2]:
        s.action(2102,code)
        assert facilities_state(s) == initial
    for code,reason in [(4,'invention-facilities-funds'),(5,'invention-facilities-approval')]:
        s.action(2102,code)
        assert last(s,'test.facilities') == ['blocked',reason,0,0]
        s.command('undo')
        assert facilities_state(s) == initial
    s.action(2102,1)
    assert last(s,'test.facilities') == ['resolved',None,100000,0]
    funded = [900000,1,'available',3,0]
    assert facilities_state(s) == funded
    s.command('undo')
    assert facilities_state(s) == initial
    s.action(2102,1)
    for code in [1,8]:
        s.action(2102,code)
        assert facilities_state(s) == funded
    s.action(2102,7)
    assert last(s,'test.facilities') == ['blocked','invention-facilities-already-funded',0,0]
    s.action(2102,6)
    s.action(2102,1)
    assert facilities_state(s) == [900000,1,'destroyed',3,0]
    s.action(2102,7)
    assert last(s,'test.facilities') == ['resolved',None,100000,1]
    assert facilities_state(s) == [800000,2,'available',3,0]


def test_invention_facilities_reuse(s):
    s.action(2102,9)
    s.action(2102,1)
    assert last(s,'test.facilities') == ['resolved',None,10000,0]
    assert facilities_state(s) == [990000,1,'available',3,0]
    s.action(2102,6)
    s.action(2102,10)
    s.action(2102,7)
    assert last(s,'test.facilities') == ['resolved',None,100000,1]
    assert facilities_state(s) == [890000,2,'available',3,0]


def test_invention_facilities_persistence(Session,bundle,out):
    for stage in range(3):
        path = out / f'expanded-invention-facilities-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(2102,0)
            if stage >= 1: first.action(2102,1)
            if stage >= 2: first.action(2102,6)
            saved = facilities_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2103')
            assert facilities_state(second) == saved
            second.action(2102,1)
            assert facilities_state(second) == [900000,1,'destroyed' if stage == 2 else 'available',3,0]
        finally:
            second.close()


def test_prototype_assessments(s):
    for penalty in [0,1,10]:
        s.action(2101,penalty)
        assert last(s,'test.prototype-team') == [1-penalty,0,0]
    for args,expected in [
            (('simple',1,1),[1,1,'days',1]),(('simple',1,6),[4,1,'days',1]),
            (('simple',4,6),[4,4,'days',1]),(('average',2,3,4),[7,2,'days',1]),
            (('average',20,6,6),[20,20,'days',1]),(('complex',3,5),[5,3,'months',1]),
            (('amazing',4,2,3,4),[9,4,'months',1])]:
        s.action(2099,*args)
        assert last(s,'test.prototype-duration') == expected + [0,0]
    for args,expected in [
            ((12,10,0,5,6),['resolved',None,1,0,0,0,0,2,6]),
            ((13,10,0,5),['resolved',None,1,0,0,0,0,0,2]),
            ((13,10,0,1),['resolved',None,1,0,0,0,0,0,0]),
            ((12,4,0),['resolved',None,1,0,0,0,0,0,0]),
            ((12,13,0),['resolved',None,0,0,0,0,0,0,0]),
            ((12,17,0),['resolved',None,0,0,1,2,1,0,0]),
            ((12,10,1),['resolved',None,0,0,0,0,0,0,0]),
            ((12,4,1),['resolved',None,0,1,0,0,0,0,0]),
            ((12,17,1),['resolved',None,0,0,1,2,1,0,0]),
            ((2,4,0),['blocked','too-difficult',0,0,0,0,0,0,0])]:
        s.action(2100,*args)
        assert last(s,'test.prototype-outcome') == expected + [0,0]


def concept_state(s):
    s.action(2098)
    return last(s,'test.concept-state')


def test_invention_concept(s):
    initial = [0,0,None,0,0]
    for code in [2,1]:
        s.action(2097,code)
        assert concept_state(s) == initial
    s.action(2097,0)
    assert last(s,'test.concept') == ['resolved',None,None,5,10]
    failed = [1,1,None,3,0]
    assert concept_state(s) == failed
    for code in [0,8,9]:
        s.action(2097,code)
        assert concept_state(s) == failed
    for code in [6,7]:
        s.action(2097,code)
        assert last(s,'test.concept')[:2] == ['blocked','invention-concept-day-used']
        assert concept_state(s) == failed
    s.action(2097,5)
    s.action(2097,6)
    assert last(s,'test.concept') == ['resolved',None,None,10,11]
    assert concept_state(s) == [2,2,None,6,86400]
    s.command('undo')
    assert concept_state(s) == [1,1,None,3,86400]


def test_invention_theories(Session,bundle):
    for code,theory,score,roll in [(3,'testable',10,10),(4,'flawed',5,17)]:
        s = Session(bundle)
        try:
            s.action(2097,code)
            assert last(s,'test.concept') == ['resolved',None,theory,score,roll]
            saved = [1,1,theory,3,0]
            assert concept_state(s) == saved
            s.action(2097,5)
            s.action(2097,6)
            assert last(s,'test.concept')[:2] == ['blocked','invention-theory-already-held']
            assert concept_state(s) == saved[:-1] + [86400]
        finally:
            s.close()


def test_invention_concept_persistence(Session,bundle,out):
    path = out / 'expanded-invention-concept.zsave'
    first = Session(bundle)
    try:
        first.action(2097,0)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2098')
        assert concept_state(second) == [1,1,None,3,0]
        second.action(2097,0)
        assert concept_state(second) == [1,1,None,3,0]
        second.action(2097,5)
        second.action(2097,6)
        assert concept_state(second) == [2,2,None,6,86400]
    finally:
        second.close()


def test_invention_proposals(Session,bundle):
    for code,expected in [
            (0,['ready',None,15,'average',-10,100000,1000]),
            (1,['ready',None,13,'average',-10,100000,1000]),
            (2,['ready',None,15,'average',-15,300000,3000]),
            (3,['blocked','invention-technology-too-advanced',None,None,0,0,0]),
            (4,['ready',None,15,'average',-10,100000,1000]),
            (5,['ready',None,15,'average',-10,10000,1000]),
            (6,['ready',None,15,'complex',-12,250000,1000]),
            (7,['blocked','invention-proposal-approval',None,None,0,0,0]),
            (8,['blocked','invention-skill-not-trained',None,'average',0,0,0]),
            (9,['ready',None,15,'average',-8,100000,1000])]:
        s = Session(bundle)
        try:
            s.action(2095,code)
            assert last(s,'test.invention-proposal') == expected + [0,0]
        finally:
            s.close()
    s = Session(bundle)
    try:
        for price,skill,software,category in [(100,14,3,'simple'),(101,15,4,'average'),
                (10000,17,5,'average'),(10001,18,6,'complex'),(1000000,20,7,'complex'),
                (1000001,21,8,'amazing')]:
            s.action(2096,price,skill,software)
            assert last(s,'test.invention-category') == [category,category,category]
    finally:
        s.close()


def software_purchase_state(s):
    s.action(2094)
    return last(s,'test.software-purchase-state')


def test_software_purchase(s):
    initial = [1000,0,0,0,0,0,0]
    for code in [2,1]:
        s.action(2093,code)
        assert software_purchase_state(s) == initial
    for code,reason in [(3,'equipment-unaffordable'),(4,'equipment-permission'),(8,'software-copy-already-installed')]:
        s.action(2093,code)
        assert last(s,'test.software-purchase') == ['blocked',reason,0]
        s.command('undo')
        assert software_purchase_state(s) == initial
    s.action(2093,0)
    assert last(s,'test.software-purchase') == ['resolved',None,100]
    purchased = [900,1,1,0,1,0,0]
    assert software_purchase_state(s) == purchased
    s.command('undo')
    assert software_purchase_state(s) == initial
    s.action(2093,0)
    s.action(2093,7)
    assert software_purchase_state(s) == purchased
    s.action(2093,0)
    assert last(s,'test.software-purchase') == ['reused',None,0]
    s.action(2093,5)
    assert software_purchase_state(s) == [900,1,1,2,1,0,0]
    s.action(2093,6)
    s.action(2093,0)
    assert software_purchase_state(s) == [900,1,0,2,1,0,0]


def test_software_purchase_persistence(Session,bundle,out):
    for stage in range(3):
        path = out / f'expanded-software-purchase-{stage}.zsave'
        first = Session(bundle)
        try:
            if stage >= 1: first.action(2093,0)
            if stage >= 2: first.action(2093,6)
            saved = software_purchase_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2094')
            assert software_purchase_state(second) == saved
            second.action(2093,0)
            assert software_purchase_state(second) == [900,1,0 if stage == 2 else 1,0,1,0,0]
            second.action(2093,0)
            assert last(second,'test.software-purchase') == ['reused',None,0]
        finally:
            second.close()


def test_software_task_support(Session,bundle):
    for code,score,reason in [(0,11,None),(1,11,None),(2,None,'task-software-not-running'),
                            (3,None,'task-software-scope'),(4,None,'task-software-unavailable'),
                            (5,None,'task-software-capability-approval'),(6,10,None),
                            (7,None,'task-software-terminal'),(8,None,'task-software-operator-unavailable'),
                            (9,None,'task-software-copy'),(10,None,'task-software-scope'),
                            (11,12,None),(12,None,'task-software-unavailable')]:
        s = Session(bundle)
        try:
            s.action(2090,code)
            assert last(s,'test.software-score') == [score,reason,10,0,0]
        finally:
            s.close()
    s = Session(bundle)
    try:
        for level,complexity in [(7,2),(8,4),(9,6),(10,8),(11,10),(12,12)]:
            s.action(2091,level)
            assert last(s,'test.software-complexity') == [complexity]
    finally:
        s.close()


def test_software_requirements(Session,bundle):
    for code,expected in [
            (0,['ready',7,0,None,'required-software-complexity',5,None]),
            (1,['ready',8,1,None,None,10,None]),
            (2,['ready',7,0,None,'required-software-missing',5,None]),
            (3,['blocked',None,0,'required-software-complexity','required-software-complexity',None,'required-software-complexity']),
            (4,['blocked',None,0,'software-requirement-approval',None,None,'software-requirement-approval']),
            (5,['ready',7,0,None,'task-software-not-running',5,None]),
            (6,['ready',7,0,None,'required-software-complexity',10,None]),
            (7,['ready',8,1,None,None,11,None])]:
        s = Session(bundle)
        try:
            s.action(2092,code)
            assert last(s,'test.software-requirement') == expected + [8,10,0,0]
        finally:
            s.close()


def remote_terminal_state(s):
    s.action(2089)
    return last(s,'test.remote-state')


def test_remote_terminal(s):
    s.action(2080,120)
    initial = ['local',0,0,0,None]
    for code in [123,122,132]:
        s.action(2080,code)
        assert remote_terminal_state(s) == initial
    for code,reason in [(124,'terminal-connection-unavailable'),(125,'terminal-service-not-running'),
                         (126,'terminal-service-capability'),(127,'terminal-remote-complexity-unavailable'),
                         (128,'terminal-local-host-unavailable')]:
        s.action(2080,code)
        assert last(s,'test.remote-operation') == ['blocked',reason,0]
        assert remote_terminal_state(s)[:4] == initial[:4]
        s.command('undo')
        assert remote_terminal_state(s) == initial
    s.action(2080,121)
    assert remote_terminal_state(s) == ['remote',1,0,1,None]
    s.command('undo')
    assert remote_terminal_state(s) == initial
    s.action(2080,121); s.action(2080,130)
    assert remote_terminal_state(s) == ['remote',1,0,1,'terminal-connection-unavailable']
    s.action(2080,129)
    final = ['local',2,0,2,None]
    assert remote_terminal_state(s) == final
    s.action(2080,121)
    assert remote_terminal_state(s) == final


def test_remote_terminal_persistence(Session,bundle,out):
    for revoked in [False,True]:
        path = out / f'expanded-remote-terminal-{revoked}.zsave'
        first = Session(bundle)
        try:
            first.action(2080,120); first.action(2080,121)
            if revoked:
                first.action(2080,130)
            saved = remote_terminal_state(first); first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2089')
            assert remote_terminal_state(second) == saved
            second.action(2080,121)
            assert remote_terminal_state(second) == saved
            second.action(2080,129)
            second.action(2080,121)
            assert remote_terminal_state(second) == ['local',2,0,2,None]
        finally:
            second.close()


def computer_recording_state(s):
    s.action(2088)
    return last(s,'test.recording-state')


def test_computer_recording(s):
    s.action(2080,0)
    initial = [0,0,0,0,0,100]
    for code in [102,101,111]:
        s.action(2080,code)
        assert computer_recording_state(s) == initial
    for code,reason in [(103,'recording-technology-unavailable'),(104,'recording-sensor-unavailable'),
                         (105,'recording-sensor-unavailable'),(107,'computer-storage-full'),
                         (110,'computer-unavailable')]:
        s.action(2080,code)
        assert last(s,'test.recording-operation') == ['blocked',reason,0]
        assert computer_recording_state(s) == initial
        s.command('undo')
    for code,size in [(100,10),(106,10),(112,100)]:
        s.action(2080,code)
        assert computer_recording_state(s) == [size,1,1,5,0,100]
        s.command('undo')
        assert computer_recording_state(s) == initial
    s.action(2080,100)
    for code in [100,109]:
        s.action(2080,code)
        assert computer_recording_state(s) == [10,1,1,5,0,100]
    s.action(2080,108); s.action(2080,100)
    assert computer_recording_state(s) == [0,1,0,5,0,100]


def test_computer_recording_persistence(Session,bundle,out):
    for stage in range(3):
        path = out / f'expanded-recording-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(2080,0)
            if stage >= 1:
                first.action(2080,100)
            if stage == 2:
                first.action(2080,108)
            saved = computer_recording_state(first); first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2088')
            assert computer_recording_state(second) == saved
            second.action(2080,100)
            expected = [10 if stage < 2 else 0,1,1 if stage < 2 else 0,5,0,100]
            assert computer_recording_state(second) == expected
            second.action(2080,100)
            assert computer_recording_state(second) == expected
        finally:
            second.close()


def computer_transfer_state(s):
    s.action(2087)
    return last(s,'test.transfer-state')


def test_computer_transfers(s):
    s.action(2080,80)
    initial = [10,0,100,10,0,0,0,0]
    for code in [83,82,91]:
        s.action(2080,code)
        assert computer_transfer_state(s) == initial
    for code,reason in [(84,'data-transfer-author-facts'),(85,'data-transfer-software-unavailable'),
                         (86,'computer-storage-full'),(87,'data-transfer-link-unavailable'),
                         (88,'data-transfer-source-unavailable')]:
        s.action(2080,code)
        assert last(s,'test.transfer-operation') == ['blocked',reason,0]
        expected = initial.copy()
        if code == 85:
            expected[3] = 0
        if code == 88:
            expected[0] = 0
        assert computer_transfer_state(s) == expected
        s.command('undo')
        assert computer_transfer_state(s) == initial
    s.action(2080,81)
    delivered = [10,10,100,10,1,0,3,1]
    assert computer_transfer_state(s) == delivered
    s.command('undo')
    assert computer_transfer_state(s) == initial
    s.action(2080,81)
    for code in [81,90]:
        s.action(2080,code)
        assert computer_transfer_state(s) == delivered
    s.action(2080,89)
    removed = [10,0,100,10,1,0,3,0]
    s.action(2080,81)
    assert computer_transfer_state(s) == removed


def test_computer_transfer_persistence(Session,bundle,out):
    for stage in range(3):
        path = out / f'expanded-data-transfer-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(2080,80)
            if stage >= 1:
                first.action(2080,81)
            if stage == 2:
                first.action(2080,89)
            saved = computer_transfer_state(first); first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2087')
            assert computer_transfer_state(second) == saved
            second.action(2080,81)
            expected = [10,10 if stage < 2 else 0,100,10,1,0,3,1 if stage < 2 else 0]
            assert computer_transfer_state(second) == expected
            second.action(2080,81)
            assert computer_transfer_state(second) == expected
        finally:
            second.close()


def computer_link_state(s):
    s.action(2086)
    return last(s,'test.link-state')


def test_computer_links(s):
    initial = [0,0,0,0,0,0]
    for code in [62,61]:
        s.action(2080,code)
        assert computer_link_state(s) == initial
    for code, reason in [(65,'computer-link-incompatible'),(66,'computer-link-medium-unavailable'),
                         (67,'computer-link-address-unknown'),(68,'computer-link-credentials'),
                         (69,'computer-link-host-unavailable')]:
        s.action(2080,code)
        assert last(s,'test.link-operation') == ['blocked',reason]
        assert computer_link_state(s) == initial
        s.command('undo')
    s.action(2080,60)
    connected = [1,1,1,1,0,0]
    assert computer_link_state(s) == connected
    s.command('undo')
    assert computer_link_state(s) == initial
    s.action(2080,60); s.action(2080,71)
    assert computer_link_state(s) == [1,0,1,1,0,0]
    s.action(2080,60)
    assert computer_link_state(s) == [1,0,1,1,0,0]
    s.action(2080,72)
    assert computer_link_state(s) == connected
    s.action(2080,64)
    assert computer_link_state(s) == connected
    s.action(2080,63)
    disconnected = [0,0,1,1,0,0]
    assert computer_link_state(s) == disconnected
    s.command('undo')
    assert computer_link_state(s) == connected
    s.action(2080,63)
    for code in [60,63,70]:
        s.action(2080,code)
        assert computer_link_state(s) == disconnected


def test_computer_link_persistence(Session,bundle,out):
    for stage in range(3):
        path = out / f'expanded-computer-link-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(2080,60)
            if stage >= 1:
                first.action(2080,71)
            if stage == 2:
                first.action(2080,63)
            saved = computer_link_state(first); first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2086')
            assert computer_link_state(second) == saved
            second.action(2080,60)
            assert computer_link_state(second) == saved
            if stage == 1:
                second.action(2080,72)
                assert computer_link_state(second) == [1,1,1,1,0,0]
            second.action(2080,63)
            second.action(2080,60)
            assert computer_link_state(second) == [0,0,1,1,0,0]
        finally:
            second.close()


def computer_data_state(s):
    s.action(2083)
    return last(s,'test.data-state')


def test_computer_storage(s):
    for category, size in [('long-text',10),('national-road-map',100),('regional-navigation',1000),
            ('vehicle-plans',1000),('global-navigation',100000),('small-library',100000),
            ('city-library',1000000),('large-library',10000000),('research-library',100000000),('human-mind',100000000)]:
        s.action(2085,category)
        assert last(s,'test.reference-data') == [size]
    for amount, unit, expected in [(10,'MB',10),(1,'GB',1000),(100,'GB',100000),
                                   (1,'TB',1000000),(10,'TB',10000000),(100,'TB',100000000)]:
        s.action(2084,amount,unit)
        assert last(s,'test.storage-units') == [expected]
    s.action(2080,0)
    initial = [0,0,0,0,0,100]
    for code in [42,41]:
        s.action(2080,code)
        assert computer_data_state(s) == initial
    s.action(2080,40)
    assert computer_data_state(s) == [10,1,1,0,0,100]
    s.command('undo')
    assert computer_data_state(s) == initial
    s.action(2080,40); s.action(2080,43)
    full = [100,2,1,0,0,100]
    for code,reason in [(44,'computer-storage-full'),(50,'computer-unavailable')]:
        s.action(2080,code)
        assert last(s,'test.data-operation') == ['blocked',reason]
        assert computer_data_state(s) == full
        s.command('undo')
    s.action(2080,46)
    assert computer_data_state(s) == full
    s.action(2080,45)
    assert computer_data_state(s) == [90,2,0,0,0,100]
    s.command('undo')
    assert computer_data_state(s) == full
    s.action(2080,45); s.action(2080,48)
    final = [100,3,0,0,0,100]
    for code in [40,45,47]:
        s.action(2080,code)
        assert computer_data_state(s) == final
    s.action(2080,49)
    assert computer_data_state(s) == [10,3,0,0,0,100]


def test_computer_storage_persistence(Session,bundle,out):
    for stage in range(4):
        path = out / f'expanded-storage-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(2080,0); first.action(2080,40)
            for threshold,code in [(1,43),(2,45),(3,48)]:
                if stage >= threshold:
                    first.action(2080,code)
            saved = computer_data_state(first); first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2083')
            assert computer_data_state(second) == saved
            for threshold,code in [(1,43),(2,45),(3,48)]:
                if stage < threshold:
                    second.action(2080,code)
            for code in [40,45,47]:
                second.action(2080,code)
                assert computer_data_state(second) == [100,3,0,0,0,100]
        finally:
            second.close()


def terminal_state(s):
    s.action(2082)
    return last(s,'test.terminal-state')


def test_terminal_switches(s):
    s.action(2080,0)
    initial = ['original',0,0,0,100]
    assert terminal_state(s) == initial
    for code in [22,21]:
        s.action(2080,code)
        assert terminal_state(s) == initial
    for code,reason in [(25,'terminal-host-not-connected'),(26,'terminal-switch-unavailable')]:
        s.action(2080,code)
        assert last(s,'test.terminal-operation') == ['blocked',reason,0]
        assert terminal_state(s) == initial
        s.command('undo')
    s.action(2080,24)
    assert terminal_state(s) == ['original',1,0,0,100]
    s.command('undo')
    assert terminal_state(s) == initial
    s.action(2080,20)
    assert terminal_state(s) == ['other',1,0,1,100]
    s.command('undo')
    assert terminal_state(s) == initial
    s.action(2080,20); s.action(2080,23)
    final = ['original',2,0,2,100]
    assert terminal_state(s) == final
    for code in [20,23,27,28]:
        s.action(2080,code)
        assert terminal_state(s) == final


def test_computer_persistence(Session,bundle,out):
    for stage in range(4):
        path = out / f'expanded-computer-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(2080,0); first.action(2080,5)
            if stage >= 1:
                first.action(2080,20)
            if stage >= 2:
                first.action(2080,3)
            if stage >= 3:
                first.action(2080,23)
            saved = (computer_state(first),terminal_state(first))
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2082')
            assert (computer_state(second),terminal_state(second)) == saved
            if stage < 1:
                second.action(2080,20)
            if stage < 2:
                second.action(2080,3)
            if stage < 3:
                second.action(2080,23)
            expected = ([100,200,11,0,0,2],['original',2,0,2,100])
            assert (computer_state(second),terminal_state(second)) == expected
            for code in [0,3,20,23,28]:
                second.action(2080,code)
                assert (computer_state(second),terminal_state(second)) == expected
        finally:
            second.close()


def computer_state(s):
    s.action(2081)
    return last(s,'test.computer-state')


def test_computer_reservations(s):
    initial = [0,200,0,0,0,0]
    assert computer_state(s) == initial
    for code in [2,1]:
        s.action(2080,code)
        assert computer_state(s) == initial
    for code, reason in [(7,'program-complexity'),(8,'computer-unavailable')]:
        s.action(2080,code)
        assert last(s,'test.computer-operation') == ['blocked',reason]
        assert computer_state(s) == initial
        s.command('undo')
    s.action(2080,0)
    first = [100,200,1,1,0,0]
    assert computer_state(s) == first
    s.action(2080,0)
    assert computer_state(s) == first
    s.action(2080,5)
    full = [200,200,11,1,0,0]
    assert computer_state(s) == full
    s.action(2080,6)
    assert last(s,'test.computer-operation') == ['blocked','computer-capacity']
    assert computer_state(s) == full
    s.command('undo')
    s.action(2080,4)
    assert computer_state(s) == full
    s.action(2080,3)
    stopped = [100,200,11,0,0,0]
    assert computer_state(s) == stopped
    s.command('undo')
    assert computer_state(s) == full
    s.action(2080,3)
    for code in [3,0,9]:
        s.action(2080,code)
        assert computer_state(s) == stopped
    s.action(2080,10)
    assert computer_state(s) == [200,200,12,0,0,0]


def test_maintenance_prices(s):
    for people, base in [(1,-10),(2,-20),(3,-30),(5,-30),(6,-40),(10,-40),
            (11,-50),(20,-50),(21,-60),(50,-60),(51,-70),(100,-70),
            (101,-70),(199,-70),(200,-80),(399,-80),(400,-90),(6400,-130),
            (10000,-130),(12799,-130),(12800,-140)]:
        s.action(2070,people,'daily')
        assert last(s,'test.maintenance-price') == [base,base]
        assert last(s,'test.maintenance-purity') == [0,0]
    for frequency, cost in [('monthly',-2),('fortnightly',-3),('weekly',-5),
            ('alternate-days',-7),('daily',-10),('twice-daily',-20),
            ('three-to-five-daily',-30),('constant',-50)]:
        s.action(2070,1,frequency)
        assert last(s,'test.maintenance-price') == [-10,cost]
        assert last(s,'test.maintenance-purity') == [0,0]
    s.action(2070,10000,'fortnightly')
    assert last(s,'test.maintenance-price') == [-130,-43]


def parts_state(s):
    s.action(2064)
    return last(s,'test.parts-state')


def test_major_repair_parts(s):
    s.action(2060,30)
    initial = [1000,0,0,None,0,0,0]
    s.action(2060,32)
    assert parts_state(s) == initial
    s.action(2060,31)
    quoted = [1000,0,0,100,0,1,0]
    assert parts_state(s) == quoted
    s.action(2060,31)
    assert parts_state(s) == quoted
    s.action(2060,34)
    assert last(s,'test.parts-operation') == ['blocked','equipment-unaffordable']
    assert parts_state(s) == [99,0,0,100,0,1,0]
    s.command('undo')
    s.action(2060,38)
    assert parts_state(s) == quoted
    s.action(2060,33)
    purchased = [900,1,50,100,0,1,0]
    assert parts_state(s) == purchased
    s.action(2060,33)
    assert parts_state(s) == purchased
    s.action(2060,22)
    assert parts_state(s) == purchased
    s.action(2060,21)  # Skill 10, price +1, major repair -2: score 9; remaining seed stream rolls 11.
    assert repair_state(s)[:3] == [0,1,0]
    assert parts_state(s) == [900,0,0,100,1,4,1800]
    s.action(2060,36)
    assert repair_state(s) == [1,2,1,3,3600]
    assert parts_state(s) == [900,0,0,100,1,3,3600]
    for code in [31,33,37,21,0]:
        s.action(2060,code)
        assert parts_state(s) == [900,0,0,100,1,3,3600]
        assert repair_state(s)[0] == 1


def test_major_parts_preflight(s):
    s.action(2060,30); s.action(2060,31)
    quoted = parts_state(s)
    s.action(2060,39)
    assert last(s,'test.parts-operation') == ['blocked','repair-parts-already-quoted']
    assert parts_state(s) == quoted
    s.action(2060,23)
    assert last(s,'test.repair-operation') == ['blocked','repair-parts-not-purchased',0]
    assert parts_state(s) == quoted
    s.action(2060,33)
    purchased = parts_state(s)
    for code,reason in [(40,'repair-parts-not-carried'),(41,'repair-parts-duplicate-inventory')]:
        s.action(2060,code)
        assert last(s,'test.repair-operation') == ['blocked',reason,0]
        assert repair_state(s) == [0,0,0,1,0]
        s.command('undo')
        assert parts_state(s) == purchased


def test_major_parts_persistence(Session,bundle,out):
    for stage in range(5):
        path = out / f'expanded-major-parts-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(2060,30)
            for threshold,code in [(1,31),(2,33),(3,21),(4,36)]:
                if stage >= threshold:
                    first.action(2060,code)
            saved = (parts_state(first),repair_state(first))
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2064')
            assert (parts_state(second),repair_state(second)) == saved
            for threshold,code in [(1,31),(2,33),(3,21),(4,36)]:
                if stage < threshold:
                    second.action(2060,code)
            expected_parts = [900,0,0,100,1,3,3600]
            expected_repair = [1,2,1,3,3600]
            assert parts_state(second) == expected_parts
            assert repair_state(second) == expected_repair
            for code in [31,33,21,0,37]:
                second.action(2060,code)
                assert parts_state(second) == expected_parts
                assert repair_state(second) == expected_repair
        finally:
            second.close()


def repair_state(s):
    s.action(2062)
    return last(s,'test.repair-state')


def test_repair_prices(s):
    for price, modifier, die, parts in [(1000,1,1,100),(1001,0,1,101),
            (10000,0,6,6000),(10001,-1,6,6001),(100000,-1,1,10000),
            (100001,-2,1,10001),(1000000,-2,6,600000),(1000001,-3,6,600001)]:
        s.action(2063,price,die)
        assert last(s,'test.repair-prices') == [modifier,parts]
    s.action(2060,3); s.action(2060,21)
    assert last(s,'test.repair-operation') == ['blocked','breakdown-major-parts-unavailable',0]
    assert repair_state(s) == [0,0,0,3,0]


def test_breakdown_repair(s):
    s.action(2060,20)
    initial = [0,0,0,0,0]
    assert repair_state(s) == initial
    for code in [23,22]:
        s.action(2060,code)
        assert repair_state(s) == initial
    s.action(2060,24)
    assert last(s,'test.repair-operation') == ['blocked','breakdown-repair-author-facts',0]
    assert repair_state(s) == initial
    s.command('undo')
    s.action(2060,21)
    assert repair_state(s) == [1,1,1,3,1800]
    s.command('undo')
    assert repair_state(s) == initial
    s.action(2060,25)
    assert repair_state(s) == [0,1,0,3,1800]
    s.action(2060,26)
    assert repair_state(s) == [1,2,1,3,3600]
    for code in [21,27,0]:
        s.action(2060,code)
        assert repair_state(s) == [1,2,1,3,3600]


def test_breakdown_repair_persistence(Session,bundle,out):
    for failed in [False,True]:
        path = out / f'expanded-breakdown-repair-{failed}.zsave'
        first = Session(bundle)
        try:
            first.action(2060,20); first.action(2060,25 if failed else 21)
            saved = repair_state(first); first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2062')
            assert repair_state(second) == saved
            second.action(2060,21)
            assert repair_state(second) == saved
            if failed:
                second.action(2060,26)
                assert repair_state(second) == [1,2,1,3,3600]
            second.action(2060,0)
            assert repair_state(second)[0] == 1
        finally:
            second.close()


def breakdown_state(s):
    s.action(2061)
    return last(s,'test.breakdown-state')


def test_breakdown_transactions(s):
    initial = [1,0,None,None,0,0]
    assert breakdown_state(s) == initial
    for code in [7,1]:
        s.action(2060,code)
        assert breakdown_state(s) == initial
    for code,reason in [(10,'breakdown-maintenance-not-required'),(13,'breakdown-score-unavailable')]:
        s.action(2060,code)
        assert last(s,'test.breakdown-operation') == ['blocked',reason]
        assert breakdown_state(s) == initial
        s.command('undo')
    for code, expected in [(0,[1,1,None,14,3,0]),(2,[0,1,'minor',16,3,0]),
                           (3,[0,1,'major',14,3,0]),(8,[0,1,'minor',9,3,0])]:
        s.action(2060,code)
        assert breakdown_state(s) == expected
        s.command('undo')
        assert breakdown_state(s) == initial
    s.action(2060,3)
    expected = breakdown_state(s)
    for code in [0,6]:
        s.action(2060,code)
        assert breakdown_state(s) == expected


def test_breakdown_days(s):
    s.action(2060,4)
    s.action(2060,5)
    assert last(s,'test.breakdown-operation') == ['blocked','breakdown-day-already-checked']
    assert breakdown_state(s) == [1,1,None,14,3,0]
    s.action(2060,12)
    assert breakdown_state(s) == [1,2,None,14,6,0]
    s.command('undo')
    s.action(2060,11)
    assert breakdown_state(s) == [1,2,None,14,6,86400]
    s.action(2060,9)
    assert breakdown_state(s)[0] == 0  # Existing storage restriction still applies.


def test_breakdown_persistence(Session,bundle,out):
    for code in [0,2,3]:
        path = out / f'expanded-breakdown-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(2060,code); saved = breakdown_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2061')
            assert breakdown_state(second) == saved
            second.action(2060,0)
            assert last(second,'test.breakdown-operation') == ['reused',None]
            assert breakdown_state(second) == saved
            second.action(2060,6)
            assert breakdown_state(second) == saved
        finally:
            second.close()


def test_object_capacity(s):
    # Exact cube weights and adjacent hundredth-pound values exercise rounding.
    for construction, rows in [
            ('unliving',[(1,1),(100,4),(101,5),(800,8),(801,9),(2700,12),(2701,13),(1000000,87)]),
            ('homogenous',[(1,2),(100,8),(101,9),(800,16),(801,17),(2700,24),(2701,25),(1000000,173)])]:
        for weight, expected in rows:
            s.action(2051,weight,construction)
            assert last(s,'test.object-capacity') == [expected]
            assert last(s,'test.object-purity') == [0,0]


def test_object_injury_thresholds(s):
    for capacity, prior, injury, expected in [
            (12,0,8,[4,0,0,0,1,0]),
            (12,0,9,[3,0,0,1,1,0]),
            (10,0,5,[5,0,0,0,0,0]),
            (10,0,6,[4,0,0,0,1,0]),
            (10,9,1,[0,0,1,1,0,0]),
            (10,19,1,[-10,0,1,1,0,1,1]),
            (10,20,1,[-11,0,1,1,0,0]),
            (10,0,50,[-40,0,1,1,1,4,1,2,3,4]),
            (10,49,11,[-50,1,1,1,1,1,4]),
            (10,60,0,[-50,1,1,1,0,0])]:
        s.action(2052,capacity,prior,injury)
        assert last(s,'test.object-injury') == expected
        assert last(s,'test.object-purity') == [0,0]


def test_broken_weapons(s):
    def assess(family, die, weight=200, missile=0, state='disabled', reach=2):
        s.action(2050,state,weight,missile,family,die,reach)
        assert last(s,'test.broken-purity') == [0,0]
        return last(s,'test.broken-weapon')
    unusable = ['ready',None,0,0,0,None,None,None,0]
    assert assess('sword',0,state='destroyed') == unusable
    assert assess('sword',0,weight=100) == unusable
    assert assess('sword',0,weight=99) == unusable
    assert assess('spear',0,missile=1) == unusable
    assert assess('unlisted',0)[:2] == ['blocked','broken-weapon-analogy-required']
    assert assess('sword',0)[:2] == ['needs-roll','broken-weapon-die-required']
    # Independent B485 branch expectations, including all six supplied die faces.
    rows = {
        'axe-mace': [('light-club',None)]*3 + [(None,None)]*3,
        'polearm': [('long-spear',None)]*2 + [('quarterstaff','axe')]*2 + [('light-club','great-axe')]*2,
        'rapier': [('smallsword',None)]*3 + [(None,None)]*3,
        'smallsword': [('dagger',None)]*3 + [(None,None)]*3,
        'spear': [('quarterstaff',None)]*3 + [('baton','spear')]*3,
        'two-handed-axe-mace': [('quarterstaff',None)]*3 + [('light-club','axe')]*3,
        'sword': [('original',None)]*3 + [(None,None)]*3,
        'saber': [('original',None)]*3 + [(None,None)]*3,
    }
    for family, outcomes in rows.items():
        for die, (held,ground) in enumerate(outcomes,1):
            result = assess(family,die,weight=101)
            assert result[:3] == ['ready',None,int(held is not None)]
            assert result[-1] == int(held is not None)+int(ground is not None)
            if held:
                expected = [held,'held',0,None,None,None,None]
                if family == 'polearm' and die <= 2:
                    expected[4:] = ['thrust',2,'cr']
                if family in ['rapier','smallsword']:
                    expected[-1] = 'imp'
                assert last(s,'test.broken-held') == expected
            if ground:
                penalty = -4 if ground == 'axe' else -2 if ground == 'great-axe' else 0
                assert last(s,'test.broken-ground') == [ground,'ground',penalty,2 if ground == 'great-axe' else 1,None,None,None]
            if held == 'original':
                assert result[3:8] == [1,-2,'thrust','cr',1]
            else:
                assert result[3:8] == [0,0,None,None,None]
    assert assess('sword',1,reach=1)[7] == 1


def shield_ready_state(s):
    s.action(2041)
    return last(s,'test.shield-ready-state')


def test_shield_ready(s):
    initial = [1,1,0,0,0,0,0]
    assert shield_ready_state(s) == initial
    s.action(2040,1)
    assert last(s,'test.shield-ready-operation') == ['blocked','shield-ready-failure-required',None]
    assert shield_ready_state(s) == initial
    s.action(2040,0)
    lost = [0,1,0,0,0,1,0]
    assert shield_ready_state(s) == lost
    s.action(2040,2)
    assert shield_ready_state(s) == lost
    s.action(2040,1)
    assert shield_ready_state(s) == [1,2,0,0,0,1,0]
    s.command('undo')
    assert shield_ready_state(s) == lost
    s.action(2040,1); s.action(2040,3)
    restored = [1,1,1,1,0,1,0]
    assert shield_ready_state(s) == restored
    s.action(2040,4)
    assert shield_ready_state(s) == restored
    s.action(2040,1)
    assert last(s,'test.shield-ready-operation') == ['blocked','shield-already-ready',None]
    assert shield_ready_state(s) == restored


def test_shield_ready_health(s):
    s.action(2040,0); s.action(2040,5)
    s.action(2040,1)
    assert last(s,'test.shield-ready-operation') == ['blocked','shield-ready-health-adapter-required',None]
    assert shield_ready_state(s) == [0,1,0,0,0,1,0]
    s.action(2040,6)
    assert shield_ready_state(s) == [1,2,0,0,3,1,1]
    s.command('undo')
    assert shield_ready_state(s) == [0,1,0,0,0,1,0]


def test_shield_ready_routes(Session,bundle):
    for exhausted in [False,True]:
        outcomes = []
        for route in ['parser','structured','dialogue']:
            s = Session(bundle)
            try:
                s.action(2040,0)
                if exhausted:
                    s.action(2040,5); s.action(2040,8)
                initial = shield_ready_state(s)
                def perform(operation):
                    if route == 'parser':
                        s.command({'restore':'restore grip','rollback':'rollback grip',
                                   'wait':'wait opponent'}[operation])
                    elif route == 'structured':
                        s.action({'restore':2042,'rollback':2043,'wait':2044}[operation])
                    else:
                        s.action(80,'shield-plan'); s.select(operation)
                perform('rollback')
                assert shield_ready_state(s) == initial
                perform('restore')
                expected = [1,2,0,0,3 if exhausted else 0,1,1 if exhausted else 0]
                assert shield_ready_state(s) == expected
                assert last(s,'test.shield-ready-operation') == ['resolved',None,'ready']
                s.command('undo')
                assert shield_ready_state(s) == initial
                perform('restore'); perform('wait')
                expected[1:4] = [1,1,1]
                assert shield_ready_state(s) == expected
                perform('restore')
                assert last(s,'test.shield-ready-operation') == ['blocked','shield-already-ready',None]
                assert shield_ready_state(s) == expected
                outcomes.append(expected)
            finally:
                s.close()
        assert outcomes[0] == outcomes[1] == outcomes[2]


def test_shield_ready_persistence(Session,bundle,out):
    for exhausted in [False,True]:
        for stage in [0,1,2]:
            path = out / f'expanded-shield-ready-{exhausted}-{stage}.zsave'
            first = Session(bundle)
            try:
                first.action(2040,0)
                if exhausted:
                    first.action(2040,5); first.action(2040,8)
                if stage >= 1:
                    first.action(2042)
                if stage == 2:
                    first.action(2044)
                saved = shield_ready_state(first)
                first.command(f':save {path}')
            finally:
                first.close()
            second = Session(bundle)
            try:
                second.command(f':restore {path}\n@2041')
                assert shield_ready_state(second) == saved
                second.action(2040,7)
                if stage == 0:
                    second.action(2042)
                if stage < 2:
                    second.action(2044)
                expected = [1,1,1,1,3 if exhausted else 0,1,1 if exhausted else 0]
                assert shield_ready_state(second) == expected
                second.action(2040,4)
                second.action(2042)
                assert last(second,'test.shield-ready-operation') == ['blocked','shield-already-ready',None]
                assert shield_ready_state(second) == expected
            finally:
                second.close()


def critical_readiness_state(s):
    s.action(2032)
    return last(s,'test.critical-readiness-state')


def test_critical_readiness(s):
    initial = [1,2,0,0,0]
    assert critical_readiness_state(s) == initial
    for code in [23,21]:
        s.action(2030,code)
        assert critical_readiness_state(s) == initial
    for code in [20,26]:
        s.action(2030,code)
        assert critical_readiness_state(s) == [0,0,1,0,0]
        s.command('undo')
        assert critical_readiness_state(s) == initial
    s.action(2030,20)
    s.action(2030,24)
    for code in [22,25]:
        s.action(2030,code)
        assert critical_readiness_state(s) == [1,0,1,0,0]


def critical_defense_state(s):
    s.action(2033)
    return last(s,'test.critical-defense-state')


def test_critical_defense_failures(s):
    initial = critical_defense_state(s)
    assert initial == ['standing',1,0,0,0,9]
    for code in [39,31,33]:
        s.action(2030,code)
        assert critical_defense_state(s) == initial
    for code, reason in [(36,'critical-dodge-mobility-unavailable'),
                         (37,'critical-defense-not-critical')]:
        s.action(2030,code)
        assert last(s,'test.critical-defense-operation') == ['blocked',reason]
        assert critical_defense_state(s) == initial
        s.command('undo')
    for code, expected in [(30,['lying',1,1,0,0,6]), (32,['standing',0,1,0,0,8]),
                           (38,['lying',1,1,0,0,6])]:
        s.action(2030,code)
        assert critical_defense_state(s) == expected
        s.command('undo')
        assert critical_defense_state(s) == initial
    s.action(2030,32)
    s.action(2030,34)
    for code in [30,35]:
        s.action(2030,code)
        assert critical_defense_state(s) == ['standing',1,1,0,0,9]


def test_critical_readiness_persistence(Session,bundle,out):
    for code, state, restore_code in [(20,critical_readiness_state,24),
                                      (26,critical_readiness_state,24),
                                      (30,critical_defense_state,34),
                                      (32,critical_defense_state,34)]:
        path = out / f'expanded-critical-readiness-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(2030,code); saved = state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2032')
            assert state(second) == saved
            second.action(2030,8)
            second.action(2030,code)
            assert state(second) == saved
            second.action(2030,restore_code)
            restored = state(second)
            second.action(2030,code)
            assert state(second) == restored
        finally:
            second.close()


def weapon_miss_drop_state(s):
    s.action(2034)
    return last(s,'test.weapon-miss-drop-state')


def test_weapon_miss_drop(s):
    initial = [None,1,500,2,0,0,0]
    assert weapon_miss_drop_state(s) == initial
    for code in [49,41]:
        s.action(2030,code)
        assert weapon_miss_drop_state(s) == initial
    for code, status, reason in [(44,'blocked','weapon-miss-not-drop'),
                                 (45,'needs-roll','breakage-confirmation'),
                                 (46,'blocked','forced-drop-destination-required'),
                                 (54,'blocked','weapon-miss-not-drop')]:
        s.action(2030,code)
        assert last(s,'test.weapon-miss-drop-operation') == [status,reason]
        assert weapon_miss_drop_state(s) == initial
        s.command('undo')
    for code in [40,42,43,50,51,52,53]:
        s.action(2030,code)
        assert weapon_miss_drop_state(s) == ['yard',0,400,0,1,0,0]
        s.command('undo')
        assert weapon_miss_drop_state(s) == initial
    s.action(2030,40)
    s.action(2030,48)
    for code in [40,47,8]:
        s.action(2030,code)
        assert weapon_miss_drop_state(s) == [None,1,500,0,1,0,0]


def test_weapon_miss_drop_persistence(Session,bundle,out):
    for code in [40,42,43,50,51,52,53]:
        path = out / f'expanded-weapon-miss-drop-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(2030,code); saved = weapon_miss_drop_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2034')
            assert weapon_miss_drop_state(second) == saved
            second.action(2030,8)
            second.action(2030,code)
            assert weapon_miss_drop_state(second) == saved
            second.action(2030,48)
            picked = weapon_miss_drop_state(second)
            second.action(2030,code)
            assert last(second,'test.weapon-miss-drop-operation') == ['reused',None]
            assert weapon_miss_drop_state(second) == picked
        finally:
            second.close()


def critical_drop_state(s):
    s.action(2031)
    return last(s,'test.critical-drop-state')


def test_critical_drop_transactions(s):
    initial = critical_drop_state(s)
    assert initial == [None,None,None,1,None,500,0,0,2,0,0]
    for code in [9,1,3]:
        s.action(2030,code)
        assert critical_drop_state(s) == initial
    s.action(2030,4)
    assert last(s,'test.critical-drop-operation') == ['blocked','knockdown-drop-destination-required']
    assert critical_drop_state(s) == initial
    s.command('undo')
    for code, expected in [(0,['yard','yard','yard',1,None,200,1,3,0,0,0]),
                           (2,['yard',None,None,1,None,400,1,1,0,1,0]),
                           (11,[None,'yard',None,1,None,400,1,1,2,1,0])]:
        s.action(2030,code)
        assert critical_drop_state(s) == expected
        s.command('undo')
        assert critical_drop_state(s) == initial
    s.action(2030,2)
    dropped = critical_drop_state(s)
    for code in [6,5,8]:
        s.action(2030,code)
        assert critical_drop_state(s) == dropped
    s.action(2030,7)
    picked_up = [None,None,None,1,None,500,1,1,0,1,0]
    assert critical_drop_state(s) == picked_up
    s.action(2030,6)
    assert last(s,'test.critical-drop-operation') == ['reused',None]
    assert critical_drop_state(s) == picked_up


def test_critical_drop_persistence(Session,bundle,out):
    for code in [0,2,11]:
        path = out / f'expanded-critical-drop-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(2030,code); saved = critical_drop_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@2031')
            assert critical_drop_state(second) == saved
            for operation in [8,6,5]:
                second.action(2030,operation)
                assert critical_drop_state(second) == saved
            second.action(2030,7)
            picked_up = critical_drop_state(second)
            second.action(2030,6)
            assert critical_drop_state(second) == picked_up
        finally:
            second.close()


def test_unarmed_miss_assessments(s):
    keys = ['outcome','injury','dice','adds','location','recovery','disability','pain','damage',
            'divisor','natural','attack','defense','affected','guard','move','away','dx','forbid']
    base = dict(zip(keys,[None,0,0,0,None,0,0,0,None,1,0,0,0,0,1,0,0,0,0]))
    def assess(roll, expected, kind='attack', limb=1, natural=0, kick=0, penalty=999,
               health=10, iq=10, animal=0, flee=1, impaling=0, pain=0, mobility='ground'):
        s.action(2020,roll,kind,limb,natural,kick,penalty,health,iq,animal,flee,impaling,pain,mobility)
        assert dict(zip(keys,last(s,'test.unarmed-miss'))) == dict(base,**expected)
        assert last(s,'test.burst-purity') == [0,0]
    rows = {
        3: dict(outcome='unconscious',recovery=1800),
        4: dict(outcome='strained-limb',injury=1,location='used-limb',disability=1800),
        5: dict(outcome='self-damage',location='used-body-part',damage='own-thrust-crushing'),
        6: dict(outcome='self-damage',location='used-body-part',damage='own-thrust-crushing',divisor=2),
        7: dict(outcome='stumble-past',move=1,away=1),
        8: dict(outcome='fall'),
        9: dict(outcome='off-balance',defense=-2,forbid=1),
        12:dict(outcome='trip-check'),
        13:dict(outcome='open-guard',defense=-2,guard=2),
        15:dict(outcome='torn-muscle',dice=1,adds=-3,location='used-limb',attack=-1,defense=-1,affected=-3)}
    for roll,row in [(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,9),
                     (11,9),(12,12),(13,13),(14,7),(15,15),(16,5),(17,4),(18,3)]:
        assess(roll,rows[row])
    assess(4,dict(outcome='moderate-pain',pain=600),limb=0)
    assess(4,dict(outcome='moderate-pain',pain=60),limb=0,health=25)
    assess(5,dict(rows[5],damage='opponent-weapon-own-strength'),impaling=1)
    assess(5,rows[5],kind='parry',impaling=1)
    assess(6,dict(outcome='broken-natural-weapon',natural=-1),natural=1)
    assess(6,rows[6],kind='parry',natural=1)
    assess(7,dict(outcome='fall'),kind='parry')
    assess(8,dict(outcome='general-injury',dice=1,adds=-3,location='general'),mobility='cannot-fall')
    for mobility in ['flying','swimming']:
        assess(8,dict(outcome='awkward-position',attack=-4,defense=-3),mobility=mobility)
    assess(12,dict(outcome='trip-check',dx=-4),kick=1)
    assess(12,dict(outcome='trip-check',dx=-8),kick=1,penalty=-4)
    assess(15,dict(rows[15],location='neck',affected=-1),limb=0,pain=1)
    for iq in [3,4,5]:
        assess(17,dict(outcome='flee-next-turn'),animal=1,iq=iq)
        assess(17,dict(outcome='submit-next-turn'),animal=1,iq=iq,flee=0)
    for iq in [2,6]:
        assess(17,rows[4],animal=1,iq=iq)
    for die, injury in [(1,0),(2,0),(3,0),(4,1),(5,2),(6,3)]:
        s.action(2021,die)
        assert last(s,'test.unarmed-injury') == [injury]
        assert last(s,'test.burst-purity') == [0,0]


def test_weapon_miss_assessments(s):
    outcomes = {3:'break-weapon',4:'break-weapon',5:'self-hit',6:'self-hit',
                7:'off-balance',8:'weapon-unready',9:'drop-weapon',10:'drop-weapon',
                11:'drop-weapon',12:'weapon-unready',13:'off-balance',14:'flung-weapon',
                15:'strained-weapon-arm',16:'fall',17:'break-weapon',18:'break-weapon'}
    for roll, outcome in outcomes.items():
        s.action(2019, 'swing', 'cr', 0, 0, roll, 0, 0)
        assert last(s, 'test.weapon-miss') == ['ready',None,outcome,1,2 if roll == 6 else 1,
            -2 if roll in [7,13] else 0,1 if roll in [8,12] else 0,
            1800 if roll == 15 else 0,int(roll in [7,13]),int(roll in [5,6]),int(roll == 14)]
        assert last(s, 'test.burst-purity') == [0,0]
    for kind, damage, resistant, cheap, rolls, expected in [
            ('ranged','pi',0,0,[5,0,0],['needs-roll','self-hit-confirmation',None,1,1,0,0,0,0,0,0]),
            ('thrust','imp',0,0,[5,6,0],['ready',None,'self-hit',2,2,0,0,0,0,1,0]),
            ('ranged','pi',0,0,[6,5,0],['ready',None,'self-hit',2,1,0,0,0,0,1,0]),
            ('ranged','pi',0,0,[5,8,0],['ready',None,'weapon-unready',2,1,0,1,0,0,0,0]),
            ('swing','cr',1,0,[3,0,0],['needs-roll','breakage-confirmation',None,1,1,0,0,0,0,0,0]),
            ('swing','cr',1,0,[3,18,0],['ready',None,'break-weapon',2,1,0,0,0,0,0,0]),
            ('swing','cr',1,0,[3,5,0],['ready',None,'drop-weapon',2,1,0,0,0,0,0,0]),
            ('ranged','pi',1,0,[5,3,0],['needs-roll','breakage-confirmation',None,2,1,0,0,0,0,0,0]),
            ('ranged','pi',1,0,[5,3,4],['ready',None,'break-weapon',3,1,0,0,0,0,0,0]),
            ('swing','cr',0,1,[9,0,0],['ready',None,'break-weapon',1,1,0,0,0,0,0,0]),
            ('ranged','pi',0,0,[16,0,0],['ready',None,'off-balance',1,1,-2,0,0,1,0,0]),
            ('parry','imp',0,0,[5,0,0],['ready',None,'self-hit',1,1,0,0,0,0,1,0]),
            ('thrust','imp',0,0,[14,0,0],['ready',None,'drop-weapon',1,1,0,0,0,0,0,0])]:
        s.action(2019, kind, damage, resistant, cheap, *rolls)
        assert last(s, 'test.weapon-miss') == expected
        assert last(s, 'test.burst-purity') == [0,0]


def test_critical_hit_assessments(s):
    # Fields after location: multiplier, maximum, ignore DR, halve DR, round up,
    # major, double shock, temporary cripple, drop held, drop weapon, idle, deaf, scar, DR.
    general = {
        3: [3,0,0,0,0,0,0,0,0,0,0,0,0,5],
        4: [1,0,0,1,0,0,0,0,0,0,0,0,0,2],
        5: [2,0,0,0,0,0,0,0,0,0,0,0,0,5],
        6: [1,1,0,0,0,0,0,0,0,0,0,0,0,5],
        7: [1,0,0,0,0,1,0,0,0,0,0,0,0,5],
        8: [1,0,0,0,0,0,1,1,0,0,0,0,0,5],
        9: [1,0,0,0,0,0,0,0,0,0,0,0,0,5],
        12:[1,0,0,0,0,0,0,0,1,0,0,0,0,5]}
    for roll, row in [(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,9),
                      (11,9),(12,12),(13,7),(14,7),(15,6),(16,5),(17,4),(18,3)]:
        s.action(2016, roll, 'arm', 'cr', 0)
        assert last(s, 'test.critical-hit') == ['arm'] + general[row]
        assert last(s, 'test.burst-purity') == [0,0]
    head = {
        3: [1,1,1,0,0,0,0,0,0,0,0,0,0,0],
        4: [1,0,0,1,1,1,0,0,0,0,0,0,0,3],
        6: [1,0,0,0,0,0,0,0,0,0,0,0,0,5],
        8: [1,0,0,0,0,0,0,0,0,0,1,0,0,5],
        12:[1,0,0,0,0,0,0,0,0,0,0,1,0,5],
        14:[1,0,0,0,0,0,0,0,0,1,0,0,0,5],
        15:[1,1,0,0,0,0,0,0,0,0,0,0,0,5],
        16:[2,0,0,0,0,0,0,0,0,0,0,0,0,5],
        17:[1,0,0,1,1,0,0,0,0,0,0,0,0,3],
        18:[3,0,0,0,0,0,0,0,0,0,0,0,0,5]}
    for roll, row in [(3,3),(4,4),(5,4),(6,6),(7,6),(8,8),(9,6),(10,6),
                      (11,6),(12,12),(13,12),(14,14),(15,15),(16,16),(17,17),(18,18)]:
        s.action(2016, roll, 'skull', 'cr', 1)
        assert last(s, 'test.critical-hit') == ['eye' if roll in [6,7] else 'skull'] + head[row]
        assert last(s, 'test.burst-purity') == [0,0]
    for roll in [6,7]:
        s.action(2016, roll, 'face', 'cut', 0)
        assert last(s, 'test.critical-hit') == ['face'] + head[4]
    for damage, loss in [('cut',1),('imp',1),('burn',2),('cor',2)]:
        s.action(2016, 12, 'face', damage, 1)
        expected = head[6].copy(); expected[12] = loss
        assert last(s, 'test.critical-hit') == ['face'] + expected
    for roll, location, shock, penetrated, expected in [
            (3,'torso',3,1,[21,5,3]),(5,'torso',3,1,[14,5,3]),
            (6,'torso',3,1,[12,5,3]),(4,'torso',3,1,[7,2,3]),
            (8,'torso',3,1,[7,5,6]),(8,'torso',5,1,[7,5,8]),
            (8,'torso',3,0,[7,5,3]),(8,'torso',0,1,[7,5,0]),
            (3,'skull',3,1,[12,0,3]),(4,'skull',3,1,[7,3,3])]:
        s.action(2018, roll, location, shock, penetrated)
        assert last(s, 'test.critical-arithmetic') == expected
        assert last(s, 'test.burst-purity') == [0,0]
    for health, seconds in [(1,15),(10,6),(13,3),(14,2),(15,2),(20,2)]:
        s.action(2017, health)
        assert last(s, 'test.critical-cripple') == [seconds]
        assert last(s, 'test.burst-purity') == [0,0]


def test_combat_check_classification(s):
    for kind, score, roll, expected in [
            ('ranged',3,13,['resolved',None,0,None,'setback']),
            ('melee',3,13,['resolved',None,0,'failure','complication']),
            ('defense',0,10,['resolved',None,0,'failure','complication']),
            ('defense',-20,3,['resolved',None,1,'success','success']),
            ('ranged',15,17,['resolved',None,0,'failure','complication']),
            ('ranged',16,17,['resolved',None,0,None,'setback']),
            ('ranged',20,18,['resolved',None,0,'failure','complication']),
            ('ranged',15,5,['resolved',None,1,'success','success']),
            ('ranged',16,6,['resolved',None,1,'success','success']),
            ('ranged',14,5,['resolved',None,1,None,'success']),
            ('ranged',3,4,['resolved',None,1,'success','success']),
            ('ranged',2,3,['blocked','too-difficult',0,None,None])]:
        s.action(2014, kind, score, roll)
        assert last(s, 'test.combat-check') == expected
        assert last(s, 'test.burst-purity') == [0,0]
    for score, roll, threshold, expected in [
            (10,10,0,['ready',None,'potential-hit',0,1,None]),
            (10,3,0,['ready',None,'potential-hit',0,0,'hit']),
            (10,17,0,['ready',None,'miss',0,0,'miss']),
            (10,17,17,['ready',None,'malfunction',1,0,None]),
            (20,18,18,['ready',None,'malfunction',1,0,None]),
            (20,18,19,['ready',None,'miss',0,0,'miss']),
            (15,12,12,['ready',None,'malfunction',1,0,None]),
            (15,11,12,['ready',None,'potential-hit',0,1,None]),
            (2,18,17,['blocked','too-difficult',None,0,0,None])]:
        s.action(2015, score, roll, threshold)
        assert last(s, 'test.ranged-outcome') == expected
        assert last(s, 'test.burst-purity') == [0,0]


def test_rapid_fire_assessments(s):
    for shots, bonus in [(1,0),(2,0),(4,0),(5,1),(8,1),(9,2),(12,2),(13,3),
                         (16,3),(17,4),(24,4),(25,5),(49,5),(50,6),(99,6),
                         (100,7),(199,7),(200,8),(399,8),(400,9),(799,9),
                         (800,10),(1599,10),(1600,11),(1000000,20)]:
        s.action(2010, shots)
        assert last(s, 'test.burst-bonus') == [bonus]
        assert last(s, 'test.burst-purity') == [0,0]
    for shots, rate, loaded, recoil, expected in [
            (3,3,6,2,['ready',None,3,0]),(10,10,10,2,['ready',None,10,2]),
            (11,10,20,2,['blocked','burst-rate-exceeded',0,0]),
            (10,10,9,2,['blocked','burst-ammunition-insufficient',0,0]),
            (1,1,0,1,['blocked','burst-ammunition-insufficient',0,0])]:
        s.action(2011, shots, rate, loaded, recoil)
        assert last(s, 'test.burst-assessment') == expected
        assert last(s, 'test.burst-purity') == [0,0]
    for shots, recoil, margin, hits in [(10,2,0,1),(10,2,1,1),(10,2,2,2),
            (10,2,3,2),(10,2,4,3),(10,2,5,3),(10,2,6,4),(10,2,7,4),
            (3,1,10,3),(10,1,9,10),(1,3,20,1),(3,2,-1,1)]:
        s.action(2012, shots, recoil, margin)
        assert last(s, 'test.burst-hits') == [hits]
        assert last(s, 'test.burst-purity') == [0,0]
    for hits, score, roll, expected in [(4,10,8,[3,1,1,None]),
            (4,10,10,[1,3,1,None]),(4,10,11,[0,4,0,None]),
            (20,10,3,[20,0,1,'success']),(20,15,5,[20,0,1,'success']),
            (20,16,6,[20,0,1,'success']),(20,14,5,[10,10,1,None]),
            (20,20,17,[0,20,0,None]),(20,20,18,[0,20,0,'failure']),
            (4,0,4,[4,0,1,'success']),(4,0,5,[0,4,0,None]),
            (4,0,10,[0,4,0,'failure'])]:
        s.action(2013, hits, score, roll)
        assert last(s, 'test.burst-dodge') == expected
        assert last(s, 'test.burst-purity') == [0,0]


def test_collapse_defense(s):
    s.action(1993)
    assert last(s, 'test.collapse-defense') == [0,None,None,None,0,0]
    assert last(s, 'test.recovered-defense') == [9,0,4,0,600]


def test_fatigue_strength(s):
    for strength, health, fatigue, injury, enabled, expected in [
            (11,12,8,0,1,[11,11,10,11,11,2400,5,8,0,0]),
            (11,12,9,0,1,[6,6,10,11,11,2400,3,4,0,0]),
            (11,12,9,8,1,[6,6,10,11,11,2400,2,2,0,0]),
            (11,12,9,0,0,[11,11,10,11,11,2400,3,4,0,0]),
            (10,10,7,0,1,[5,5,10,10,10,2000,3,4,0,0]),
            (10,10,6,0,1,[10,10,10,10,10,2000,5,8,0,0])]:
        s.action(1990, strength, health, fatigue, injury, enabled)
        assert last(s, 'test.fatigue-strength') == expected
    s.action(1991)
    assert last(s, 'test.fatigue-strength-default') == ['fatigue-strength-default-unavailable',7,0,0]


def maneuver_state(s):
    s.action(1981)
    return last(s, 'test.maneuver-state')


def test_maneuver_transactions(s):
    initial = maneuver_state(s)
    assert initial == [1,0,0,10,10,0,0,0,0,0,0]
    for seed, committed in [(1,[2,0,0,10,10,1,0,1,0,6,1]),
                            (9,[2,0,0,10,10,0,1,1,0,3,1]),
                            (11,[2,0,0,20,10,1,1,1,1,6,1])]:
        s.action(1980, 5, seed)
        assert maneuver_state(s) == initial
        s.action(1980, 1, seed)
        assert maneuver_state(s) == initial
        s.action(1980, 0, seed)
        assert maneuver_state(s) == committed
        s.command('undo')
        assert maneuver_state(s) == initial
    s.action(1980, 0, 1)
    first = maneuver_state(s)
    for code in [0,3,4,6]:
        s.action(1980, code, 1)
        assert maneuver_state(s) == first
    s.action(1980, 2, 1)
    next_turn = [1,1,1,10,10,1,0,1,0,6,1]
    assert maneuver_state(s) == next_turn
    s.command('undo')
    assert maneuver_state(s) == first
    s.action(1980, 2, 1)
    s.action(1980, 0, 1)
    assert last(s, 'test.maneuver-operation') == ['blocked','maneuver-health-gate-used',None]
    assert maneuver_state(s) == next_turn


def test_maneuver_route_parity(Session, bundle):
    commands = {'first': 'first turn', 'second': 'second turn',
                'first-rollback': 'first rollback', 'second-rollback': 'second rollback'}
    verbs = {'first': 1983, 'second': 1984, 'first-rollback': 1985, 'second-rollback': 1986}
    for seed, injury, expected in [(1,0,[2,0,0,10,0,0,0,1,0,3,1]),
                                   (1,10,[2,0,0,10,10,1,0,1,0,6,1]),
                                   (9,10,[2,0,0,10,10,0,1,1,0,3,1]),
                                   (11,10,[2,0,0,20,10,1,1,1,1,6,1])]:
        outcomes = []
        for route in ['parser','structured','dialogue']:
            s = Session(bundle)
            try:
                s.action(1982, seed, injury)
                initial = maneuver_state(s)
                def perform(operation):
                    if route == 'parser':
                        s.command(commands[operation])
                    elif route == 'structured':
                        s.action(verbs[operation])
                    else:
                        s.action(80, 'maneuver-plan'); s.select(operation)
                perform('first-rollback')
                assert maneuver_state(s) == initial
                perform('first')
                assert last(s, 'test.maneuver-operation') == [
                    'resolved',None,'move' if injury == 0 else 'incapacitated']
                assert maneuver_state(s) == expected
                s.command('undo')
                assert maneuver_state(s) == initial
                perform('first')
                assert last(s, 'test.maneuver-operation') == [
                    'resolved',None,'move' if injury == 0 else 'incapacitated']
                assert maneuver_state(s) == expected
                perform('second-rollback')
                assert maneuver_state(s) == expected
                perform('second')
                next_turn = [1,1,1] + expected[3:]
                assert maneuver_state(s) == next_turn
                perform('first')
                receipt = last(s, 'test.maneuver-operation')
                assert receipt == ['blocked','maneuver-health-gate-used',None]
                assert maneuver_state(s) == next_turn
                outcomes.append((next_turn,receipt))
            finally:
                s.close()
        assert outcomes[0] == outcomes[1] == outcomes[2]


def test_maneuver_persistence(Session, bundle, out):
    for seed in [1,9,11]:
        for stage in range(3):
            path = out / f'expanded-maneuver-{seed}-{stage}.zsave'
            first = Session(bundle)
            try:
                if stage >= 1:
                    first.action(1980, 0, seed)
                if stage == 2:
                    first.action(1980, 2, seed)
                saved = maneuver_state(first)
                first.command(f':save {path}')
            finally:
                first.close()
            second = Session(bundle)
            try:
                second.command(f':restore {path}\n@1981')
                assert maneuver_state(second) == saved
                second.action(1980, 4, seed)
                if stage == 0:
                    second.action(1980, 0, seed)
                if stage < 2:
                    second.action(1980, 2, seed)
                final = maneuver_state(second)
                assert final == ([1,1,1,10,10,1,0,1,0,6,1] if seed == 1 else
                                 [1,1,1,10,10,0,1,1,0,3,1] if seed == 9 else
                                 [1,1,1,20,10,1,1,1,1,6,1])
                second.action(1980, 0, seed)
                assert last(second, 'test.maneuver-operation') == ['blocked','maneuver-health-gate-used',None]
                assert maneuver_state(second) == final
            finally:
                second.close()


def test_health_maneuver(s):
    for fatigue, injury, seed, kind, movement, expected in [
            (10,0,1,'move',0,['resolved',None,'move',0,0,1,3,2,0]),
            (10,0,9,'move',0,['resolved',None,'incapacitated',0,1,1,3,2,0]),
            (10,10,1,'move',0,['resolved',None,'incapacitated',1,0,1,6,2,0]),
            (10,0,11,'nothing',0,['resolved',None,'nothing',0,0,1,0,2,0]),
            (10,0,11,'move',99,['blocked','movement-limit',None,0,0,0,0,1,0])]:
        s.action(1971, fatigue, injury, seed, kind, movement)
        assert last(s, 'test.health-maneuver') == expected
        if expected[0] == 'resolved':
            assert last(s, 'test.health-maneuver-repeat') == [
                'blocked','maneuver-health-gate-used',1,expected[6],1,1]


def test_action_gate(s):
    for fatigue, injury, seed, purpose, expected in [
            (10,10,1,'action',[0,'action-gate-unconscious',10,11,1,0,0,6,'reused',0,11,0]),
            (10,10,9,'action',[0,'exhaustion-effort-failed',11,0,0,1,0,3,'reused',0,0,0]),
            (10,10,11,'action',[0,'exhaustion-effort-failed',17,0,1,1,1,6,'reused',0,0,0]),
            (0,10,1,'action',[1,None,0,10,0,0,0,3,'reused',1,10,0]),
            (0,10,5,'action',[0,'action-gate-unconscious',0,17,1,0,0,3,'reused',0,17,0]),
            (0,20,1,'action',[0,'action-gate-unconscious',0,10,1,0,0,3,'reused',0,10,0]),
            (10,10,11,'do-nothing',[1,None,0,0,0,0,0,0,'reused',1,0,0])]:
        s.action(1970, fatigue, injury, seed, purpose)
        assert last(s, 'test.action-gate-preview') == ['ready',0,0,0]
        assert last(s, 'test.action-gate') == expected


def effort_state(s):
    s.action(1961)
    return last(s, 'test.effort-state')


def test_effort_transactions(s):
    initial = effort_state(s)
    assert initial == [10,0,0,0,0,0,0,0,0]
    for seed, expected in [(1,[10,0,0,1,0,0,1,3,0]),
                           (9,[10,1,0,1,0,0,1,3,0]),
                           (5,[10,1,0,1,0,0,1,6,0]),
                           (11,[20,1,1,1,1,1,1,6,0])]:
        for code in [2,1]:
            s.action(1960, code, seed)
            assert effort_state(s) == initial
        s.action(1960, 0, seed)
        assert effort_state(s) == expected
        s.command('undo')
        assert effort_state(s) == initial
    s.action(1960, 0, 9)
    collapsed = effort_state(s)
    for code in [0,2,3,4,6]:
        s.action(1960, code, 1)
        assert effort_state(s) == collapsed
    s.action(1960, 5, 1)
    recovered = effort_state(s)
    assert recovered == [9,0,0,1,0,0,1,3,600]
    s.command('undo')
    assert effort_state(s) == collapsed
    for code in [5,0,3]:
        s.action(1960, code, 1)
        assert effort_state(s) == recovered
    s.action(1960, 7, 1)
    assert effort_state(s) == [9,0,0,2,0,0,1,3,600]


def test_effort_persistence(Session, bundle, out):
    for seed in [1,9,5,11]:
        path = out / f'expanded-effort-{seed}.zsave'
        first = Session(bundle)
        try:
            first.action(1960, 0, seed)
            saved = effort_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1961')
            for code in [3,2,0,4]:
                second.action(1960, code, 1)
                assert effort_state(second) == saved
            if seed == 11:
                second.action(1960, 7, 1)
                assert last(second, 'test.effort-operation') == ['blocked','effort-condition-unavailable']
                assert effort_state(second) == saved
            else:
                second.action(1960, 5, 1)
                second.action(1960, 0, 1)
                assert effort_state(second) == [9,0,0,1,0,0,1,saved[7],600]
                second.action(1960, 7, 1)
                assert effort_state(second) == [9,0,0,2,0,0,1,saved[7],600]
        finally:
            second.close()


def test_effort_recovery(s):
    s.action(1951)
    assert last(s, 'test.effort-collapse') == [0,0,'exhaustion-collapse',0,0]
    assert last(s, 'test.effort-recovery') == [9,0,0,1,3,3]


def test_exhaustion_assessments(s):
    for remaining, capacity, collapsed, purpose, will, roll, health, health_roll, expected in [
            (1,10,0,'action',0,0,0,0,[1,0,0,0,None,0,0,0,0]),
            (1,10,1,'action',0,0,0,0,[1,0,0,0,None,0,0,0,0]),
            (0,10,0,'talk',0,0,0,0,[1,0,0,0,None,0,0,0,0]),
            (-2,10,0,'rest',0,0,0,0,[1,0,0,0,None,0,0,0,0]),
            (0,10,0,'action',10,10,0,0,[1,0,0,0,None,1,0,0,0]),
            (0,10,0,'action',10,11,0,0,[0,1,0,0,'exhaustion-effort-failed',1,0,0,0]),
            (-2,10,0,'action',10,17,10,10,[0,1,0,0,'exhaustion-effort-failed',1,1,0,0]),
            (-2,10,0,'action',10,18,10,11,[0,1,0,1,'exhaustion-effort-failed',1,1,0,0]),
            (0,10,0,'action',18,17,0,0,[0,1,0,0,'exhaustion-effort-failed',1,0,0,0]),
            (0,10,1,'action',0,0,0,0,[0,1,0,0,'exhaustion-collapse',0,0,0,0]),
            (0,10,1,'rest',0,0,0,0,[1,1,0,0,None,0,0,0,0]),
            (-10,10,0,'action',0,0,0,0,[0,1,1,0,'exhaustion-unconscious',0,0,0,0]),
            (-10,10,0,'rest',0,0,0,0,[1,1,1,0,None,0,0,0,0])]:
        s.action(1940, remaining, capacity, collapsed, purpose, will, roll, health, health_roll)
        assert last(s, 'test.exhaustion-outcome') == expected
    for value, remaining, capacity, expected in [(7,4,12,7),(7,3,12,4),(8,3,12,4),
            (1,0,10,1),(0,0,10,0),(9,4,10,9),(9,3,10,5),(9,-10,10,5)]:
        s.action(1941, value, remaining, capacity)
        assert last(s, 'test.low-fatigue-value') == [expected]


def cardiac_state(s):
    s.action(1931)
    return last(s, 'test.cardiac-state')


def second_cardiac_state(s):
    s.action(1933)
    return last(s, 'test.second-cardiac-state')


def test_cardiac_clock_batch(s):
    initial = cardiac_state(s)
    second_initial = second_cardiac_state(s)
    assert second_initial == [0,1,0,0,None,0]
    s.action(1930, 24)
    assert cardiac_state(s) == initial
    assert second_cardiac_state(s) == second_initial
    s.action(1930, 21)
    onset = cardiac_state(s)
    second_onset = second_cardiac_state(s)
    assert onset == [20,2,1,0,0,0,0,0,1,1]
    assert second_onset == [10,1,0,1,None,2]
    # The fixture catches this rejection, so rollback cannot conceal a partial commit.
    s.action(1930, 22)
    assert last(s, 'test.cardiac-clock-rejection') == ['cardiac-other-death-unavailable']
    assert cardiac_state(s) == onset
    assert second_cardiac_state(s) == second_onset
    s.action(1930, 17)
    assert cardiac_state(s) == [20,20,0,0,0,1,0,201,1,1]
    assert second_cardiac_state(s) == [10,20,1,0,100,2]
    s.command('undo')
    assert cardiac_state(s) == onset
    assert second_cardiac_state(s) == second_onset
    s.action(1930, 23)
    assert cardiac_state(s) == [20,2,1,0,0,0,0,100,1,1]
    assert second_cardiac_state(s) == [10,20,1,0,100,2]
    s.action(1930, 23)
    s.action(1930, 25)
    assert cardiac_state(s) == [20,20,0,0,0,1,0,200,1,1]
    assert second_cardiac_state(s) == [10,20,1,0,100,2]


def test_cardiac_clock_batch_persistence(Session, bundle, out):
    path = out / 'expanded-cardiac-clock-batch.zsave'
    first = Session(bundle)
    try:
        first.action(1930, 21); first.action(1930, 23)
        saved = cardiac_state(first)
        second_saved = second_cardiac_state(first)
        first.command(f':save {path}')
    finally:
        first.close()
    restored = Session(bundle)
    try:
        restored.command(f':restore {path}\n@1931')
        assert cardiac_state(restored) == saved
        assert second_cardiac_state(restored) == second_saved
        restored.action(1930, 23); restored.action(1930, 25)
        assert cardiac_state(restored) == [20,20,0,0,0,1,0,200,1,1]
        assert second_cardiac_state(restored) == [10,20,1,0,100,2]
    finally:
        restored.close()


def test_cardiac_clock(s):
    s.action(1930, 13)
    s.action(1930, 14)
    before = cardiac_state(s)
    assert before == [20,2,1,0,0,0,0,199,1,1]
    for code in [16,19]:
        s.action(1930, code)
        assert cardiac_state(s) == before
    s.action(1930, 15)
    assert cardiac_state(s) == [20,20,0,0,0,1,0,200,1,1]
    s.action(1932)
    assert last(s, 'test.cardiac-clock') == [1,1,200,18]
    s.command('undo')
    assert cardiac_state(s) == before
    s.action(1930, 18)
    s.action(1930, 17)
    expired = cardiac_state(s)
    assert expired == [20,20,0,0,0,1,0,400,1,1]
    for code in [6,9]:
        s.action(1930, code)
        assert cardiac_state(s) == expired
    s.action(1932)
    assert last(s, 'test.cardiac-clock') == [1,1,200,18]


def test_cardiac_clock_immunity(s):
    for code in [20,13,17,9]:
        s.action(1930, code)
    assert cardiac_state(s) == [3,2,0,0,0,0,0,201,1,0]
    s.action(1932)
    assert last(s, 'test.cardiac-clock') == [0,0,0,0]


def test_cardiac_clock_revival(s):
    s.action(1930, 13)
    s.action(1930, 2)
    s.action(1930, 17)
    assert cardiac_state(s) == [20,10,0,1,1,0,3,261,1,1]
    s.action(1932)
    assert last(s, 'test.cardiac-clock') == [1,1,60,0]
    s.action(1930, 9)


def test_cardiac_clock_persistence(Session, bundle, out):
    for expired in [False,True]:
        path = out / f'expanded-cardiac-clock-{int(expired)}.zsave'
        first = Session(bundle)
        try:
            first.action(1930, 13); first.action(1930, 14)
            if expired:
                first.action(1930, 15)
            saved = cardiac_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1931')
            assert cardiac_state(second) == saved
            second.action(1930, 15)
            second.action(1930, 6); second.action(1930, 9)
            assert cardiac_state(second) == [20,20,0,0,0,1,0,201 if expired else 200,1,1]
            second.action(1932)
            assert last(second, 'test.cardiac-clock') == [1,1,200,18]
        finally:
            second.close()


def test_cardiac_transactions(s):
    initial = cardiac_state(s)
    assert initial == [3,2,0,0,0,0,0,0,0,0]
    s.action(1930, 1)
    assert cardiac_state(s) == initial
    s.action(1930, 0)
    onset = cardiac_state(s)
    assert onset == [20,2,1,0,0,0,0,0,1,1]
    s.command('undo')
    assert cardiac_state(s) == initial
    s.action(1930, 0)
    for code in [11,3,5,12,9]:
        s.action(1930, code)
        assert cardiac_state(s) == onset
    s.action(1930, 4)
    failed = cardiac_state(s)
    assert failed == [20,2,1,1,0,0,3,60,1,1]
    s.command('undo')
    assert cardiac_state(s) == onset
    s.action(1930, 4)
    s.action(1930, 2)
    revived = cardiac_state(s)
    assert revived == [20,10,0,2,1,0,3,120,1,1]
    s.command('undo')
    assert cardiac_state(s) == failed
    for code in [2,2,4,0,10,9]:
        s.action(1930, code)
        assert cardiac_state(s) == revived
    s.action(1930, 8)
    s.action(1930, 6)
    assert last(s, 'test.cardiac-operation') == ['blocked','cardiac-already-revived']
    assert cardiac_state(s) == [20,10,0,2,1,0,3,200,1,1]


def test_cardiac_deadline_transactions(s):
    s.action(1930, 0)
    s.action(1930, 8)
    due = cardiac_state(s)
    assert due == [20,2,1,0,0,0,0,200,1,1]
    s.action(1930, 7)
    assert cardiac_state(s) == due
    s.action(1930, 6)
    expired = cardiac_state(s)
    assert expired == [20,20,0,0,0,1,0,200,1,1]
    s.command('undo')
    assert cardiac_state(s) == due
    for code in [6,6,9]:
        s.action(1930, code)
        assert cardiac_state(s) == expired


def test_cardiac_persistence(Session, bundle, out):
    for stage in range(4):
        path = out / f'expanded-cardiac-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(1930, 0)
            if stage in [1,2]:
                first.action(1930, 4)
            if stage == 2:
                first.action(1930, 2)
            if stage == 3:
                first.action(1930, 8); first.action(1930, 6)
            saved = cardiac_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1931')
            assert cardiac_state(second) == saved
            second.action(1930, 9)
            if stage == 3:
                second.action(1930, 6)
                assert cardiac_state(second) == [20,20,0,0,0,1,0,200,1,1]
            else:
                if stage == 0:
                    second.action(1930, 4)
                for code in [2,2,4,9]:
                    second.action(1930, code)
                    assert cardiac_state(second) == [20,10,0,2,1,0,3,120,1,1]
        finally:
            second.close()


def test_cardiac_resuscitation(s):
    for kind, score in [('physician',12),('first-aid',10)]:
        s.action(1922, 10, 2, kind, 7, 1)
        assert last(s, 'test.cardiac-treatment') == ['ready','resolved',None,score,1,8,10,20,0,'reused',1,60,3]
    s.action(1922, 10, 15, 'physician', 7, 1)
    assert last(s, 'test.cardiac-treatment') == ['ready','resolved',None,12,1,0,15,20,0,'reused',1,60,3]
    s.action(1922, 10, 2, 'physician', 7, 5)
    assert last(s, 'test.cardiac-treatment') == ['ready','resolved',None,12,0,0,2,20,1,'reused',1,60,3]
    assert last(s, 'test.cardiac-retry') == ['resolved',1,10,2,120,3]
    s.action(1922, 3, 2, 'physician', 7, 1)
    assert last(s, 'test.cardiac-treatment') == ['blocked','blocked','resuscitation-insufficient-time',None,0,0,2,6,1,'blocked',0,0,0]
    s.action(1922, 10, 2, 'physician', 6, 1)
    assert last(s, 'test.cardiac-treatment') == ['blocked','blocked','resuscitation-technology-unavailable',None,0,0,2,20,1,'blocked',0,0,0]


def test_cardiac_condition(s):
    for capacity, injury, survived, total, added in [(10,2,1,10,8),(10,10,1,10,0),
            (10,15,1,15,0),(10,2,0,20,18),(10,25,0,25,0),(15,7,0,30,23)]:
        s.action(1920, capacity, injury, survived)
        assert last(s, 'test.cardiac-health') == [total,added]
    for health, injury in [(10,2),(11,25)]:
        s.action(1921, health, injury, 'none')
        assert last(s, 'test.cardiac-onset') == [0,2*health-3,2*health,injury,1,health*20,'reused',1,1,0]
        assert last(s, 'test.cardiac-expiry') == [1,'cardiac-deadline-not-reached',max(20-injury,0),
                                               max(20,injury),1,0,'reused',1,1,0]
    for trait in ['diffuse','homogenous','no-vitals']:
        s.action(1921, 10, 2, trait)
        assert last(s, 'test.cardiac-onset') == [1,0,3,2,0,None,'reused',1,1,0]
        assert last(s, 'test.cardiac-immune') == ['cardiac-immune',0]


def test_resuscitation_assessment(s):
    for kind, tl, trained, modern, cause, modifier in [
            ('physician',7,1,1,'heart-attack',0),('physician',8,1,0,'drowning',0),
            ('first-aid',7,1,1,'drowning',-2),('first-aid',7,1,1,'asphyxiation',-2),
            ('first-aid',7,0,1,'drowning',-4),('first-aid',7,1,0,'drowning',-4),
            ('first-aid',7,1,1,'heart-attack',-4)]:
        s.action(1893, kind, tl, trained, modern, cause)
        assert last(s, 'test.resuscitation-procedure') == ['ready',None,modifier,60]
    s.action(1893, 'physician', 6, 1, 1, 'drowning')
    assert last(s, 'test.resuscitation-procedure') == ['blocked','resuscitation-technology-unavailable',0,0]


def air_state(s):
    s.action(1901)
    return last(s, 'test.air-state')


def test_airless_transactions(s):
    initial = air_state(s)
    assert initial == [9,2,10,0,0,0,0,0,0,0,0]
    s.action(1900, 1)
    assert air_state(s) == initial
    s.action(1900, 0)
    started = air_state(s)
    assert started == [9,2,10,0,1,0,0,0,0,0,0]
    for code in [0,7,9,10,13]:
        s.action(1900, code)
        assert air_state(s) == started
    s.action(1900, 2)
    due = air_state(s)
    for code in [5,4]:
        s.action(1900, code)
        assert air_state(s) == due
    s.action(1900, 3)
    harmed = air_state(s)
    assert harmed == [10,2,10,1,1,1,0,3,1,1,0]
    s.command('undo')
    assert air_state(s) == due
    s.action(1900, 3)
    for code in [3,8,6,7]:
        s.action(1900, code)
        assert air_state(s) == harmed
    s.action(1900, 5)
    rescued = air_state(s)
    assert rescued == [10,2,10,0,0,1,1,3,1,1,0]
    s.command('undo')
    assert air_state(s) == harmed
    for code in [5,5,3,7]:
        s.action(1900, code)
        assert air_state(s) == rescued
    s.action(1900, 13)
    assert air_state(s) == [9,2,10,0,0,1,1,3,601,0,0]
    s.action(1900, 10)
    breathing = air_state(s)
    assert breathing == [9,2,10,0,0,1,1,3,601,0,1]
    for code in [0,5,7]:
        s.action(1900, code)
        assert air_state(s) == breathing


def test_airless_brain_transactions(s):
    for code in [11,0,12]:
        s.action(1900, code)
    deprived = air_state(s)
    assert deprived == [121,2,10,121,1,121,0,0,121,0,0]
    for code in [8,6,7]:
        s.action(1900, code)
        assert air_state(s) == deprived
    s.action(1900, 5)
    rescued = air_state(s)
    assert rescued == [121,2,9,0,0,121,1,3,121,0,0]
    s.command('undo')
    assert air_state(s) == deprived
    for code in [5,5,7]:
        s.action(1900, code)
        assert air_state(s) == rescued


def test_airless_breath_conflict(s):
    s.action(1900, 10)
    before = air_state(s)
    assert before == [9,2,10,0,0,0,0,0,0,0,1]
    s.action(1900, 0)
    assert air_state(s) == before
    s.action(1900, 7)


def test_airless_persistence(Session, bundle, out):
    for stage in range(4):
        path = out / f'expanded-airless-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(1900, 0)
            for code in [2,3,5][:stage]:
                first.action(1900, code)
            saved = air_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1901')
            assert air_state(second) == saved
            second.action(1900, 7)
            for code in [2,3,5][stage:]:
                second.action(1900, code)
            assert air_state(second) == [10,2,10,0,0,1,1,3,1,1,0]
            second.action(1900, 7)
        finally:
            second.close()


def test_airless_brain_persistence(Session, bundle, out):
    for rescued in [False,True]:
        path = out / f'expanded-airless-brain-{int(rescued)}.zsave'
        first = Session(bundle)
        try:
            for code in [11,0,12]:
                first.action(1900, code)
            if rescued:
                first.action(1900, 5)
            saved = air_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1901')
            assert air_state(second) == saved
            second.action(1900, 7)
            for code in [5,5,7]:
                second.action(1900, code)
                assert air_state(second) == [121,2,9,0,0,121,1,3,121,0,0]
        finally:
            second.close()


def test_airless_seconds(s):
    for fatigue, seed, injury, unconscious, draws in [(8,5,0,0,0),(9,5,0,1,3),
                                                    (9,1,0,0,3),(10,5,1,1,3),(20,5,1,1,0)]:
        charged = 0 if fatigue == 20 else 1
        s.action(1890, fatigue, seed)
        assert last(s, 'test.airless-second') == [
            'airless-second-not-due',charged,injury,fatigue+charged,2+injury,unconscious,1,'reused',draws]
        assert last(s, 'test.airless-rescue') == ['resolved','reused',0,10,fatigue+charged,draws]


def test_airless_duration(s):
    for seconds, iq, lost, draws in [(120,10,0,0),(121,9,1,3),(239,9,1,3)]:
        s.action(1891, seconds)
        assert last(s, 'test.airless-duration') == ['ready','resolved',None,seconds,0,iq,0,lost,0,draws]
    s.action(1891, 240)
    assert last(s, 'test.airless-duration') == ['blocked','blocked','airless-rescue-too-late',240,240,10,1,0,0,0]


def test_airless_scheduler_conflict(s):
    s.action(1892)
    assert last(s, 'test.airless-conflict') == [1,1,0,0,0]


def breath_state(s):
    s.action(1881)
    return last(s, 'test.breath-state')


def test_breath_transactions(s):
    initial = breath_state(s)
    assert initial == [0,0,0,0,0,0,0,0,0,'mild',2,0]
    s.action(1880, 1)
    assert breath_state(s) == initial
    s.action(1880, 0)
    started = breath_state(s)
    assert started == [1,1,1,0,40,40,0,0,0,'mild',2,0]
    s.command('undo')
    assert breath_state(s) == initial
    s.action(1880, 0)
    for code in [0,6,7,8,9,12]:
        s.action(1880, code)
        assert breath_state(s) == started
    s.action(1880, 2)
    assert breath_state(s) == [1,1,1,0,40,1,39,39,0,'mild',2,0]
    s.action(1880, 3)
    due = breath_state(s)
    assert due == [1,1,1,0,40,0,40,40,0,'mild',2,0]
    s.action(1880, 5)
    assert breath_state(s) == due
    s.action(1880, 4)
    ended = breath_state(s)
    assert ended == [0,1,1,1,40,0,40,40,0,'mild',2,0]
    s.command('undo')
    assert breath_state(s) == due
    for code in [4,4,0,7]:
        s.action(1880, code)
        assert breath_state(s) == ended
    s.action(1880, 9)
    second = breath_state(s)
    assert second == [1,2,1,1,40,0,40,40,0,'mild',2,0]
    # Historical calls must not clear the newer reserve or reset the clock.
    for code in [0,4,7,12]:
        s.action(1880, code)
        assert breath_state(s) == second


def test_breath_expired_transactions(s):
    for code in [0,2,3,10]:
        s.action(1880, code)
    expired = breath_state(s)
    assert expired == [1,1,1,0,40,0,41,41,0,'mild',2,0]
    for code in [0,4,8,9,12,7]:
        s.action(1880, code)
        assert breath_state(s) == expired


def test_breath_persistence(Session, bundle, out):
    for stage in range(5):
        path = out / f'expanded-breath-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(1880, 0)
            if stage >= 1:
                first.action(1880, 2)
            if stage >= 2:
                first.action(1880, 3)
            if stage == 3:
                first.action(1880, 4)
            if stage == 4:
                first.action(1880, 10)
            saved = breath_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1881')
            assert breath_state(second) == saved
            second.action(1880, 7)
            if stage == 0:
                second.action(1880, 2)
            if stage <= 1:
                second.action(1880, 3)
            second.action(1880, 4)
            if stage == 4:
                assert breath_state(second) == [1,1,1,0,40,0,41,41,0,'mild',2,0]
                assert last(second, 'test.breath-operation') == ['blocked','breath-suffocation-unresolved']
            else:
                assert breath_state(second) == [0,1,1,1,40,0,40,40,0,'mild',2,0]
            second.action(1880, 7)
        finally:
            second.close()


def test_breath_duration(s):
    for health, activity, prepared, ventilation, control, levels, seconds in [
            (10,'none',1,'none',0,0,100),(10,'mild',1,'none',0,0,40),
            (10,'heavy',1,'none',0,0,10),(11,'heavy',0,'none',0,0,5),
            (10,'heavy',1,'air',0,0,15),(10,'heavy',1,'oxygen',0,0,25),
            (10,'heavy',1,'air',1,0,22),(10,'heavy',1,'oxygen',1,0,37),
            (3,'heavy',0,'none',1,0,2),(3,'heavy',0,'none',1,1,4),
            (10,'mild',1,'oxygen',1,2,600)]:
        s.action(1870, health, activity, prepared, ventilation, control, levels)
        assert last(s, 'test.breath-duration') == ['ready',None,seconds,0,0]
    s.action(1870, 10, 'mild', 0, 'oxygen', 0, 0)
    assert last(s, 'test.breath-duration') == ['blocked','breath-ventilation-preparation',0,0,0]


def test_breath_reserve(s):
    for elapsed, remaining, exhausted, status, reason, active in [
            (39,1,0,'resolved',None,0),(40,0,1,'resolved',None,0),
            (41,0,1,'blocked','breath-suffocation-unresolved',1)]:
        s.action(1871, elapsed)
        assert last(s, 'test.breath-reserve') == [
            'resolved','reused',elapsed,remaining,exhausted,status,reason,active,elapsed,0,0]
    s.action(1872)
    assert last(s, 'test.breath-conflict') == ['breath-existing-exposure',1,0,0,0]


def immersion_state(s):
    s.action(1861)
    return last(s, 'test.immersion-state')


def test_immersion_transactions(s):
    s.action(1860, 0)
    assert immersion_state(s) == [10,2,1,0,0,0,0,0,2,2]
    s.action(1860, 1)
    due = immersion_state(s)
    for code in [9,3,4,6]:
        s.action(1860, code)
        assert immersion_state(s) == due
    s.action(1860, 2)
    immersed = immersion_state(s)
    assert immersed == [17,9,1,1,0,0,3,60,9,9]
    s.command('undo')
    assert immersion_state(s) == due
    s.action(1860, 2)
    for code in [2,5,8]:
        s.action(1860, code)
        assert immersion_state(s) == immersed
    s.action(1860, 4)
    exited = immersion_state(s)
    assert exited == [17,9,0,1,1,0,3,60,9,9]
    s.command('undo')
    assert immersion_state(s) == immersed
    s.action(1860, 4)
    s.action(1860, 7)
    assert immersion_state(s) == exited
    s.action(1860, 6)
    assert immersion_state(s) == [17,2,0,1,1,1,3,60,9,2]
    s.command('undo')
    assert immersion_state(s) == exited
    for code in [6,6,2,4,8]:
        s.action(1860, code)
        assert immersion_state(s) == [17,2,0,1,1,1,3,60,9,2]


def test_immersion_persistence(Session, bundle, out):
    for stage in range(5):
        path = out / f'expanded-immersion-{stage}.zsave'
        first = Session(bundle)
        try:
            first.action(1860, 0)
            for code in [1,2,4,6][:stage]:
                first.action(1860, code)
            saved = immersion_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1861')
            assert immersion_state(second) == saved
            second.action(1860, 8)
            for code in [1,2,4,6][stage:]:
                second.action(1860, code)
            assert immersion_state(second) == [17,2,0,1,1,1,3,60,9,2]
            second.action(1860, 8)
        finally:
            second.close()


def test_immersion_intervals(s):
    for seed, loss in [(1,1),(5,7)]:
        s.action(1853, 2, seed)
        assert last(s, 'test.immersion-interval') == [
            'resolved','reused','immersion-interval-not-due','ready','resolved',None,
            loss,2+loss,2+loss,3,0]
        assert last(s, 'test.immersion-recovery') == [
            'reused','immersion-not-exited','resolved','resolved',
            'immersion-recovery-shelter-and-heat','resolved',2+loss,2,0,3,0]


def test_immersion_overflow(s):
    for fatigue, seed, requested, charged, injury, collapsed in [
            (9,5,7,7,6,0),(10,5,7,7,7,0),(19,5,7,1,7,1),(20,5,7,0,7,1),
            (10,1,1,1,1,0)]:
        s.action(1855, fatigue, seed, 1)
        assert last(s, 'test.immersion-overflow') == [
            'resolved',None,requested,charged,injury,fatigue+charged,2+injury,
            2+charged,2+injury,collapsed,injury,3]
        assert last(s, 'test.immersion-overflow-recovery') == [fatigue+charged,2+injury,2,2,3]
    # A seven-point loss crosses a death boundary on its first overflow wound.
    # Seed eleven gives resistance 17 and survival 13: death stops further wounds.
    s.action(1855, 10, 11, 1, 19)
    assert last(s, 'test.immersion-overflow') == ['resolved',None,7,7,1,17,20,9,3,0,1,6]
    assert last(s, 'test.immersion-terminal') == [1,0]
    assert last(s, 'test.immersion-overflow-recovery') == [17,20,2,2,6]
    s.action(1855, 10, 5, 0)
    assert last(s, 'test.immersion-overflow') == [
        'blocked','expanded-wound-shock-rule-required',0,0,0,10,2,2,2,0,0,0]


def test_immersion_scheduler_conflict(s):
    s.action(1854)
    assert last(s, 'test.immersion-conflict') == ['cold-exposure-active',1,0,0]


def test_thermal_shock_assessments(s):
    # B430: success still costs one; failure uses its actual margin, even critical.
    for score, roll, fatigue in [(10,10,1),(10,3,1),(10,11,1),(10,16,6),
                                 (10,18,8),(3,4,1),(3,13,10),(16,17,1)]:
        s.action(1852, 0, score, roll)
        assert last(s, 'test.thermal-shock') == ['ready',None,0,60,fatigue,0,0]
    for score, roll in [(17,17),(18,18),(20,17)]:
        s.action(1852, 0, score, roll)
        assert last(s, 'test.thermal-shock') == [
            'blocked','thermal-shock-forced-failure-margin',0,60,0,0,0]
    # A dry suit selects ordinary cold before requiring an immersion resistance roll.
    s.action(1852, 1, 0, 0)
    assert last(s, 'test.thermal-shock') == ['ready',None,1,0,0,0,0]


def test_heat_assessments(s):
    for temperature, comfort, extra in [(80,90,0),(90,90,0),(91,90,1),(120,90,1),
                                        (121,90,2),(150,90,2),(111,110,1),(170,110,2)]:
        s.action(1850, temperature, comfort)
        assert last(s, 'test.heat-exertion') == ['ready',None,extra]
    s.action(1850, 151, 90)
    assert last(s, 'test.heat-exertion') == ['blocked','heat-exertion-band-unavailable',0]
    for score, roll, die, fatigue, stroke in [(10,10,0,0,0),(10,11,0,1,0),
                                            (10,17,1,1,1),(10,18,6,6,1),
                                            (18,17,0,1,0),(18,18,3,3,1),(6,16,4,4,1)]:
        s.action(1851, score, roll, die)
        assert last(s, 'test.heat-outcome') == [fatigue,stroke,0,0]


def test_cold_overflow(s):
    for fatigue, seed, expected, shelter in [
            (10,5,[1,1,11,3,3,3,0,3,0],[11,3,2,2,3]),
            (19,5,[1,1,20,3,3,3,1,3,0],[20,3,2,2,3]),
            (20,5,[0,1,20,3,2,3,1,3,0],[20,3,2,2,3]),
            (10,1,[0,0,10,2,2,2,0,3,0],[10,2,2,2,3])]:
        s.action(1833, fatigue, seed)
        assert last(s, 'test.cold-overflow') == expected
        assert last(s, 'test.cold-overflow-shelter') == shelter


def test_cold_intervals(s):
    s.action(1832)
    assert last(s, 'test.cold-interval') == ['cold-interval-not-due',1,'reused',3,3,1,3,0]
    assert last(s, 'test.cold-shelter') == ['cold-recovery-shelter-and-heat','resolved',3,2,0,1,0]


def test_cold_assessments(s):
    for args, expected in [
            ((35,0,'winter',0,35),[0,0,0,0]), ((34,9,'winter',0,35),[1,1800,0,1]),
            ((34,10,'winter',0,35),[1,900,0,1]), ((34,29,'winter',0,35),[1,900,0,1]),
            ((34,30,'winter',0,35),[1,600,0,1]), ((0,0,'light',0,35),[1,1800,-5,1]),
            ((-9,0,'arctic',0,35),[1,1800,5,1]), ((-10,0,'arctic',1,35),[1,1800,-1,1]),
            ((-20,30,'heated',1,35),[1,600,3,1]), ((20,0,'winter',0,20),[0,0,0,0])]:
        s.action(1830, *args)
        assert last(s, 'test.cold-weather') == expected
    for points, score, skill in [(1,10,0),(2,10,0),(4,11,1),(8,12,1)]:
        s.action(1831, points)
        assert last(s, 'test.cold-skill') == ['ready',score,skill,0,0]


def test_aging_events(s):
    for code, preview, expected in [
            (0,['ready',None,0],['resolved','reused',10,9,10,10,0,1,7,7,12,0,20]),
            (1,['ready',None,0],['resolved','reused',0,9,9,2,1,1,7,7,12,0,60]),
            (2,['blocked','aging-calendar-evidence',0],['blocked','blocked',10,10,10,10,0,0,7,7,0,0,0]),
            (3,['blocked','aging-before-onset',0],['blocked','blocked',10,10,10,10,0,0,7,7,0,0,0])]:
        s.action(1808, code)
        assert last(s, 'test.aging-event-preview') == preview
        assert last(s, 'test.aging-event') == expected


def test_aging_sequence(s):
    for strength, longevity, expected in [
            (10,0,[9,9,12,8,1,2,0,2,70,0,11,9,13,14,18,5]),
            (1,0,[0,9,12,8,1,2,0,2,70,1,2,9,13,14,18,5]),
            (10,1,[10,10,12,9,0,1,0,1,30,0,12,10,13,14,20,6])]:
        s.action(1807, strength, longevity)
        assert last(s, 'test.aging-sequence') == expected
        assert last(s, 'test.aging-purity') == [strength,11,12,10,7,7,2,0,0]


def test_aging_assessments(s):
    for short, extended, values in [
            (0,0,[18,50,'year',1,70,'month',6,90,'month',3]),
            (1,0,[9,25,'month',6,35,'month',3,45,'day',45]),
            (2,0,[4,12,'month',3,17,'day',45,22,'day',22]),
            (3,0,[2,6,'day',45,8,'day',22,11,'day',11]),
            (4,0,[1,3,'day',22,4,'day',11,5,'day',5]),
            (0,1,[36,100,'year',2,140,'month',12,180,'month',6]),
            (0,2,[72,200,'year',4,280,'month',24,360,'month',12])]:
        s.action(1805, short, extended)
        assert last(s, 'test.aging-schedule') == ['ready',None] + values
    s.action(1805, 1, 1)
    assert last(s, 'test.aging-schedule') == ['blocked','aging-conflicting-lifespan',0]
    for score, roll, longevity, loss in [(10,10,0,0),(10,11,0,1),(6,16,0,2),
                                       (18,17,0,2),(18,18,0,2),(10,4,0,0),
                                       (3,16,1,0),(10,17,1,1),(17,17,1,0),
                                       (17,18,1,1),(-2,16,1,0)]:
        s.action(1806, score, roll, longevity, 7, 2)
        assert last(s, 'test.aging-loss') == ['ready',None,loss,6]
    s.action(1806, 2, 10, 0, 0, -2)
    assert last(s, 'test.aging-loss') == ['blocked','aging-low-score-unavailable',0,-5]


def test_infection_supervision(s):
    for code, expected in [
            (0,['resolved',None,1,10,1,2,3,0]),
            (1,['resolved',None,1,13,1,2,3,0]),
            (2,['blocked','infection-physician-care-interval',0,0,0,2,0,0]),
            (3,['blocked','infection-physician-care-interval',0,0,0,2,0,0]),
            (4,['blocked','medical-physician-unavailable',0,0,0,2,0,0])]:
        s.action(1804, code)
        assert last(s, 'test.infection-supervision') == expected


def test_specific_natural_immunity(s):
    # Park-Miller first three dice: seed 48 -> 3, seed 55 -> 4.
    for seed, expected in [(48,[1,0,1,0,0,1,3,0,3,2,3]),
                           (55,[1,0,1,0,0,1,3,0,3,2,4]),
                           (1,[0,0,0,0,0,1,3,3,3,2,10])]:
        s.action(1803, seed)
        assert last(s, 'test.natural-immunity') == expected


def test_infection_acquisition(s):
    for seed, antibiotic, expected in [
            (1,0,[0,0,10,'reused','infection-exposure-already-resolved',2,3,0]),
            (5,0,[1,0,17,'reused','infection-exposure-already-resolved',2,3,0]),
            (5,1,[0,1,0,'reused','infection-exposure-already-resolved',2,0,0])]:
        s.action(1801, seed, antibiotic)
        assert last(s, 'test.infection-preview') == ['ready',0,0]
        assert last(s, 'test.infection-acquisition') == expected


def test_infection_assessments(s):
    for matter, locale, penalty in [(0,0,0),(1,0,-2),(0,1,-3),(1,1,-5)]:
        s.action(1800, 0, matter, locale, 0, 6, 0, 1)
        assert last(s, 'test.infection-context') == ['ready',None,3+penalty,1,0,0,0,0,0,0]
        for treated in [0, 1]:
            s.action(1800, 1, matter, locale, treated, 6, 0, 1)
            assert last(s, 'test.infection-context') == ['ready',None,penalty+3*treated,1,0,86400,1,1,0,0]
    s.action(1800, 0, 1, 1, 1, 6, 0, 1)
    assert last(s, 'test.infection-context') == ['ready',None,0,0,1,0,0,0,0,0]
    for args, reason in [((0,0,0,1,5,0,1),'infection-antibiotics-technology'),
                         ((1,0,0,1,5,0,1),'infection-antibiotics-technology'),
                         ((0,0,0,1,6,1,1),'infection-critical-treatment-adjudication'),
                         ((0,0,0,0,6,0,0),'infection-exposure-not-established')]:
        s.action(1800, *args)
        assert last(s, 'test.infection-context') == ['blocked',reason,0,0,0,0,0,0,0,0]


def test_surgery_assessments(s):
    for tl, modifier in [(1,-6),(2,-5),(3,-5),(4,-4),(5,-2),(6,0),(7,1),(8,2),(12,6),(13,7)]:
        s.action(1628, tl, 1, 1, 'other', 1, 1, 0, 0)
        assert last(s, 'test.surgery-context') == ['ready',None,modifier,int(tl < 5),0,0]
    for args, expected in [
            ((0,1,1,'other',1,1,0,0), ['blocked','surgery-technology-unavailable',0,0,0,0]),
            ((5,0,1,'other',1,1,0,1), ['ready',None,-4,1,0,0]),
            ((4,0,1,'other',1,1,0,0), ['ready',None,-4,1,0,0]),
            ((8,0,0,'head',0,0,0,0), ['ready',None,-16,0,0,0]),
            ((8,1,1,'chest',1,0,1,0), ['ready',None,-1,0,0,0]),
            ((8,1,1,'other',1,0,0,0), ['ready',None,-3,0,0,0])]:
        s.action(1628, *args)
        assert last(s, 'test.surgery-context') == expected
    for args, expected in [
            ((12,10,0,1,2,3),[1,None,0,0]),
            ((12,3,0,1,2,3),[1,'success',0,0]),
            ((12,13,1,2,6,0),[0,None,2,8]),
            ((12,13,0,2,3,6),[0,None,3,11]),
            ((12,18,0,6,6,6),[0,'failure',3,18])]:
        s.action(1629, *args)
        assert last(s, 'test.surgery-outcome') == expected


def aid_state(s):
    s.action(1701)
    return last(s, 'test.aid-state')


def test_aid_transactions(s):
    s.action(1700, 0)
    evidence = 'Warm, comfortable, calm and still throughout'
    before = aid_state(s)
    assert before == [9, 1, 1, 0, 0, 0, 60, 0, evidence]
    s.action(1700, 3)
    assert last(s, 'test.aid-action') == ['ready', None, 0, 0, 600]
    assert aid_state(s) == before
    for code in [2, 7]:
        s.action(1700, code)
        assert aid_state(s) == before
    s.action(1700, 6)
    assert aid_state(s) == [14, 2, 2, 1, 1, 1, 660, 3, evidence]
    s.command('undo')
    assert aid_state(s) == before
    s.action(1700, 1)
    committed = aid_state(s)
    assert committed == [3, 1, 1, 1, 1, 1, 660, 4, evidence]
    s.command('undo')
    assert aid_state(s) == before
    s.action(1700, 1)
    assert aid_state(s) == committed
    for code in [1, 4, 5]:
        s.action(1700, code)
        assert aid_state(s) == committed


def test_aid_persistence(Session, bundle, out):
    for completed in [0, 1, 6]:
        path = out / f'expanded-aid-{completed}.zsave'
        first = Session(bundle)
        try:
            first.action(1700, 0)
            if completed:
                first.action(1700, completed)
            saved = aid_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1701')
            assert aid_state(second) == saved
            second.action(1700, 1)
            assert last(second, 'test.aid-action')[0] == ('reused' if completed else 'resolved')
            if completed:
                assert aid_state(second) == saved
            else:
                assert aid_state(second) == [3, 1, 1, 1, 1, 1, 660, 4,
                                             'Warm, comfortable, calm and still throughout']
        finally:
            second.close()


def bandage_state(s):
    s.action(1691)
    return last(s, 'test.bandage-state')


def test_bandage_transactions(s):
    s.action(1690, 0)
    before = bandage_state(s)
    assert before == [4, 1, -1, 0, 0, 0, 0, 'Observed pressure-treatable injury']
    s.action(1690, 3)
    assert last(s, 'test.bandage-action') == ['ready', None, 3, 60]
    assert bandage_state(s) == before
    s.action(1690, 2)
    assert bandage_state(s) == before
    s.action(1690, 1)
    committed = bandage_state(s)
    assert committed == [1, 1, 1, 1, 3, 60, 0, 'Observed pressure-treatable injury']
    s.command('undo')
    assert bandage_state(s) == before
    s.action(1690, 1)
    assert bandage_state(s) == committed
    for code in [1, 4, 5]:
        s.action(1690, code)
        assert bandage_state(s) == committed


def test_bandage_persistence(Session, bundle, out):
    for treated in [False, True]:
        path = out / f'expanded-bandage-{treated}.zsave'
        first = Session(bundle)
        try:
            first.action(1690, 0)
            if treated:
                first.action(1690, 1)
            saved = bandage_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1691')
            assert bandage_state(second) == saved
            second.action(1690, 1)
            assert last(second, 'test.bandage-action') == [
                'reused' if treated else 'resolved', None, 3, 0 if treated else 60]
            assert bandage_state(second) == [1, 1, 1, 1, 3, 60, 0, 'Observed pressure-treatable injury']
        finally:
            second.close()


def test_first_aid_treatment(s):
    for seed, expected in [(1, ['resolved', 6, 0, 3, 600, 4, 'reused', 0, 1]),
                           (5, ['resolved', 0, 5, 14, 600, 3, 'reused', 0, 1])]:
        s.action(1627, seed)
        assert last(s, 'test.first-aid-preview') == ['ready', 9, 0, 0]
        assert last(s, 'test.first-aid-treatment') == expected


def test_bandage_rejections(s):
    for code, reason in [(1, 'bandage-evidence'), (2, 'bandage-eligible-injury'),
                         (3, 'bandage-eligible-injury'), (4, 'bandage-injury-eligibility-unavailable'),
                         (5, 'bandage-condition'), (6, 'bandage-condition'),
                         (7, 'bandage-earlier-wound-unavailable'), (8, 'bandage-already-treated')]:
        s.action(1626, code)
        assert last(s, 'test.bandage-gate') == ['blocked', reason, 0, 0, 0, 0]


def test_expanded_bandage(s):
    s.action(1625)
    assert last(s, 'test.bandage-preview') == ['ready', 3, 4, 0, 0]
    assert last(s, 'test.bandage-commit') == [
        'resolved', 3, 60, 'reused', 0, 'bandage-already-treated', 1, 60, 0]


def test_expanded_first_aid_values(s):
    for tl, seconds, adjustment in [(0,1800,-4), (1,1800,-4), (2,1800,-3),
                                    (3,1800,-3), (4,1800,-2), (5,1200,-2),
                                    (6,1200,-1), (7,1200,-1), (8,600,0),
                                    (9,600,1), (12,600,1), (13,600,1)]:
        s.action(1623, tl)
        assert last(s, 'test.first-aid-table') == [seconds, 60, adjustment]
    for args, expected in [
            ((10,0,12,10,1,1), [1,1,1,0,0,None]),
            ((10,0,12,10,6,1), [1,1,2,1,0,None]),
            ((10,9,12,10,6,1), [1,1,7,6,0,None]),
            ((30,8,12,10,4,3), [3,3,12,9,0,None]),
            ((30,8,12,10,4,1), [3,1,12,9,0,None]),
            ((30,9,12,3,0,3), [3,3,21,18,0,'success']),
            ((10,0,12,3,0,1), [1,1,2,1,0,'success']),
            ((30,8,12,13,0,3), [3,3,0,0,0,None]),
            ((30,8,12,17,0,3), [3,3,0,0,5,'failure']),
            ((10,8,12,18,0,1), [1,1,0,0,3,'failure']),
            ((30,8,12,17,0,0), [3,0,0,0,2,'failure'])]:
        for _ in range(2):
            s.action(1624, *args)
            assert last(s, 'test.first-aid-outcome') == expected
            assert last(s, 'test.first-aid-purity') == [0, 0]


def physician_state(s):
    s.action(1681)
    return last(s, 'test.physician-state')


def test_physician_outcomes(s):
    for capacity, score, roll, expected in [
            (10,12,3,[2,0,'success']), (10,12,4,[2,0,'success']),
            (10,15,5,[2,0,'success']), (10,16,6,[2,0,'success']),
            (10,12,12,[1,0,None]), (10,12,13,[0,0,None]),
            (10,12,17,[0,1,'failure']), (10,18,17,[0,0,None]),
            (10,18,18,[0,1,'failure']), (20,12,3,[4,0,'success']),
            (30,12,10,[3,0,None]), (30,12,17,[0,1,'failure'])]:
        s.action(1622, capacity, score, roll)
        assert last(s, 'test.physician-outcome') == expected


def test_physician_check_transactions(s):
    s.action(1680, 0); s.action(1680, 1)
    before = physician_state(s)
    assert before == [9, 0, 0, None, 0, 86399, 0]
    s.action(1680, 3)
    assert last(s, 'test.physician-check') == ['blocked','physician-check-not-due',0,0]
    assert physician_state(s) == before
    s.action(1680, 2)
    ready = physician_state(s)
    s.action(1680, 9)
    assert last(s, 'test.physician-check') == ['ready',None,0,0]
    assert physician_state(s) == ready
    s.action(1680, 4)
    assert physician_state(s) == ready
    s.action(1680, 8)
    assert last(s, 'test.physician-check') == ['resolved',None,0,1]
    assert physician_state(s) == [10, 1, 86400, 86400, 3, 86400, 1]
    s.command('undo')
    assert physician_state(s) == ready
    s.action(1680, 3)
    healed = physician_state(s)
    assert healed == [6, 1, 86400, 86400, 3, 86400, 0]
    for code in [3, 5, 6, 10]:
        s.action(1680, code)
        assert physician_state(s) == healed
    assert last(s, 'test.physician-check') == ['blocked','physician-check-not-due',0,0]


def test_physician_check_persistence(Session, bundle, out):
    for failure in [False, True]:
        path = out / f'expanded-physician-check-{failure}.zsave'
        first = Session(bundle)
        try:
            first.action(1680, 0); first.action(1680, 1); first.action(1680, 2)
            first.action(1680, 8 if failure else 3)
            saved = physician_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1681')
            assert physician_state(second) == saved
            second.action(1680, 3)
            assert last(second, 'test.physician-check')[0] == 'reused'
            assert physician_state(second) == saved
        finally:
            second.close()


def medical_roster(s):
    s.action(1671)
    return last(s, 'test.medical-roster')


def test_medical_supervision_transactions(s):
    initial = medical_roster(s)
    assert initial == [0, 0, 0, 5, 9, 0, 0, 0]
    s.action(1670, 5)
    assert medical_roster(s) == initial
    s.action(1670, 1)
    assigned = medical_roster(s)
    assert assigned == [1, 1, 1, 6, 9, 0, 0, 0]
    for code in [1, 3, 4, 6]:
        s.action(1670, code)
        assert medical_roster(s) == assigned
    s.action(1670, 7)
    assert last(s, 'test.supervised-rest') == [18]
    assert medical_roster(s) == [1, 1, 1, 6, 3, 0, 3, 172800]
    s.command('undo')
    assert medical_roster(s) == assigned
    s.action(1670, 2)
    assert medical_roster(s) == initial
    s.command('undo')
    assert medical_roster(s) == assigned


def test_medical_supervision_persistence(Session, bundle, out):
    for rested in [False, True]:
        path = out / f'expanded-medical-supervision-{rested}.zsave'
        first = Session(bundle)
        try:
            first.action(1670, 1)
            if rested:
                first.action(1670, 7)
            saved = medical_roster(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1671')
            assert medical_roster(second) == saved
            second.action(1670, 1)
            assert last(second, 'test.medical-admission') == ['reused']
            assert medical_roster(second) == saved
            second.action(1670, 2)
            assert medical_roster(second)[:4] == [0, 0, 0, 5]
        finally:
            second.close()


def test_medical_schedule(s):
    rows = [(0,0,0), (1,10,604800), (2,10,604800), (3,10,604800),
            (4,10,259200), (5,15,172800), (6,20,86400), (7,25,86400),
            (8,50,86400), (9,50,43200), (10,50,28800), (11,100,21600),
            (12,200,17280), (13,200,17280)]
    for tl, capacity, interval in rows:
        s.action(1620, tl)
        assert last(s, 'test.medical-schedule') == [
            'blocked' if tl == 0 else 'ready', 'medical-no-physicians' if tl == 0 else None,
            capacity, interval]
    for args, expected in [
            ((3,0,0,12,11), ['ready',None,3,10,604800,12,'blocked',10,1,0,0]),
            ((8,1,0,12,1), ['ready',None,8,50,86400,12,'resolved',1,1,0,0]),
            ((9,0,1,12,1), ['ready',None,6,20,86400,12,'resolved',1,1,0,0]),
            ((9,0,0,12,1), ['blocked','medical-equipment-fallback-unavailable',9,50,43200,0,None,0,0,0,0]),
            ((3,0,0,11,1), ['blocked','medical-physician-not-qualified',3,10,604800,11,None,0,0,0,0])]:
        s.action(1621, *args)
        assert last(s, 'test.medical-practice') == expected


def natural_state(s):
    s.action(1661)
    return last(s, 'test.natural-state')


def test_natural_recovery_transactions(s):
    assert natural_state(s) == [9, 0, 0, 0]
    s.action(1660, 1)
    assert natural_state(s) == [9, 86400, 0, 86400]
    s.action(1660, 2)
    assert natural_state(s) == [9, 86400, 0, 86400]
    s.action(1660, 3)
    before = natural_state(s)
    assert before == [9, 172799, 0, 172799]
    s.action(1660, 4)
    assert natural_state(s) == [3, 0, 3, 172800]
    s.command('undo')
    assert natural_state(s) == before
    s.action(1660, 4)
    assert natural_state(s) == [3, 0, 3, 172800]


def test_natural_recovery_persistence(Session, bundle, out):
    for completed in [False, True]:
        path = out / f'expanded-natural-{completed}.zsave'
        first = Session(bundle)
        try:
            first.action(1660, 1); first.action(1660, 3)
            if completed:
                first.action(1660, 4)
            saved = natural_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1661')
            assert natural_state(second) == saved
            if not completed:
                second.action(1660, 4)
            assert natural_state(second) == [3, 0, 3, 172800]
        finally:
            second.close()


def test_expanded_natural_recovery(s):
    for args, expected in [
            ((10, 2, 2, 0, 0, 1, 1, 0), [0, 2, 0, 0, 0, 86400]),
            ((10, 0, 0, 0, 0, 1, 1, 0), [0, 0, 0, 0, 0, 86400]),
            ((19, 5, 0, 0, 0, 1, 1, 0), [1, 4, 0, 3, 12, 86400]),
            ((20, 5, 0, 0, 0, 1, 1, 0), [2, 3, 0, 3, 12, 86400]),
            ((30, 9, 2, 0, 2, 1, 1, 0), [6, 3, 0, 3, 17, 86400]),
            ((30, 5, 2, 0, 3, 1, 1, 0), [3, 2, 0, 3, 17, 86400]),
            ((10, 5, 0, 1, 0, 1, 1, 0), [0, 5, 86400, 0, 0, 86400]),
            ((10, 5, 0, 1, 0, 1, 2, 0), [1, 4, 0, 3, 12, 172800]),
            ((10, 5, 0, 2, 0, 1, 3, 0), [0, 5, 259200, 0, 0, 259200]),
            ((10, 5, 0, 2, 0, 1, 4, 0), [1, 4, 0, 3, 12, 345600]),
            ((10, 5, 0, 3, 0, 1, 8, 0), [1, 4, 0, 3, 12, 691200]),
            ((30, 9, 2, 1, 2, 0, 1, 0), [1, 8, 0, 3, 12, 86400]),
            ((10, 5, 0, 0, 0, 1, 1, -2), [1, 4, 0, 3, 10, 86400]),
            ((10, 5, 0, 0, 0, 1, 1, -3), [0, 5, 0, 3, 9, 86400])]:
        s.action(1617, *args)
        assert last(s, 'test.natural-recovery') == expected
    for capacity, base, expected in [(1, 1, 1), (19, 3, 3), (20, 3, 6),
                                      (29, 2, 4), (30, 2, 6), (99, 1, 9), (100, 0, 0)]:
        s.action(1618, capacity, base)
        assert last(s, 'test.healing-scale') == [expected]
    for code, reason in [(1, 'natural-recovery-unhealing-context-required'),
                         (2, 'natural-recovery-score-unavailable'),
                         (3, 'natural-recovery-protected-injury'),
                         (4, 'natural-recovery-mortal-regimen-unavailable')]:
        s.action(1619, code)
        assert last(s, 'test.natural-recovery-gate') == [reason, 5, 0, 0, 0]


def later_care_state(s):
    s.action(1651)
    return last(s, 'test.later-care-state')


def test_later_crippling_care(s):
    s.action(1640, 0); s.action(1640, 1)
    initial = later_care_state(s)
    assert initial == [3, 0, 3, 3, 6, 1, 0, 1, 4, 0]
    s.action(1650, 0)
    assert last(s, 'test.later-care') == ['ready', None, 3, 2, 0]
    assert later_care_state(s) == initial
    for code in [6, 7]:
        s.action(1650, code)
        assert later_care_state(s) == initial
    s.action(1650, 1)
    low = later_care_state(s)
    assert low == [2, 1, 3, 3, 6, 1, 0, 1, 4, 0]
    s.action(1650, 3)
    assert last(s, 'test.later-care') == ['blocked', 'crippling-care-no-shorter-recovery', 2, 2, 0]
    assert later_care_state(s) == low
    for code in [4, 5]:
        s.action(1650, code)
        assert later_care_state(s) == low
    s.action(1650, 2)
    high = later_care_state(s)
    assert high == [1, 2, 3, 3, 6, 0, 1, 1, 4, 0]
    s.command('undo')
    assert later_care_state(s) == low
    s.action(1650, 2); s.action(1650, 2)
    assert last(s, 'test.later-care') == ['reused', None, 2, 1, 1]
    assert later_care_state(s) == high


def test_later_care_calendar(s):
    s.action(1650, 8)
    assert later_care_state(s) == [2, 0, 2, 3, 6, 1, 0, 0, 4, 0]
    s.action(1650, 1)
    assert last(s, 'test.later-care') == ['blocked', 'crippling-care-no-shorter-recovery', 2, 2, 0]
    s.action(1650, 2)
    assert later_care_state(s) == [1, 1, 2, 3, 6, 1, 0, 0, 4, 0]
    s.action(1640, 1)
    assert later_care_state(s) == [1, 1, 2, 3, 6, 0, 1, 1, 4, 0]


def test_later_care_persistence(Session, bundle, out):
    for improved in [False, True]:
        path = out / f'expanded-later-care-{improved}.zsave'
        first = Session(bundle)
        try:
            first.action(1640, 0); first.action(1640, 1); first.action(1650, 1)
            if improved:
                first.action(1650, 2)
            saved = later_care_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1651')
            assert later_care_state(second) == saved
            second.action(1650, 2 if improved else 1)
            assert last(second, 'test.later-care')[0] == 'reused'
            assert later_care_state(second) == saved
            second.action(1650, 2)
            assert later_care_state(second) == [1, 2, 3, 3, 6, 0, 1, 1, 4, 0]
        finally:
            second.close()


def test_last_wounds_option(s):
    # B420: low-health boundary is strict; the one-third injury exception is inclusive.
    for capacity, prior, amount, kind, critical, enabled, ignored, loss, draws, disabled in [
            (10, 7, 1, 'arm', 0, 1, 1, 0, 0, 0),
            (10, 7, 3, 'arm', 0, 1, 1, 0, 0, 0),
            (10, 7, 4, 'arm', 0, 1, 0, 4, 0, 0),
            (10, 7, 6, 'arm', 0, 1, 0, 6, 3, 1),
            (10, 7, 3, 'hand', 0, 1, 1, 0, 0, 0),
            (10, 7, 4, 'hand', 0, 1, 0, 4, 3, 1),
            (10, 7, 1, 'arm', 1, 1, 0, 1, 0, 0),
            (10, 7, 1, 'arm', 0, 0, 0, 1, 0, 0),
            (12, 8, 1, 'arm', 0, 1, 0, 1, 0, 0),
            (12, 9, 1, 'arm', 0, 1, 1, 0, 0, 0),
            (12, 9, 4, 'arm', 0, 1, 0, 4, 0, 0),
            (10, 7, 1, 'torso', 0, 1, 0, 1, 0, 0)]:
        s.action(1616, capacity, prior, amount, kind, critical, enabled)
        assert last(s, 'test.last-wound-preview') == [ignored, loss, prior, 0]
        assert last(s, 'test.last-wound') == [
            ignored, loss, prior + loss, 0 if ignored else 1, draws,
            disabled, 1, ignored, 'expanded-wound-retargeted']


def last_wound_state(s):
    s.action(1624)
    return last(s, 'test.last-wound-state')


def test_last_wound_transactions(s):
    initial = limb_state(s)
    for code, expected in [(13, [1, 1, 7, 0, 0, 1]), (14, [0, 0, 8, 1, 0, 1])]:
        s.action(1620, code)
        assert last_wound_state(s) == expected
        s.command('undo')
        assert limb_state(s) == initial
    s.action(1620, 13)
    saved = last_wound_state(s)
    for code in [1, 15]:
        s.action(1620, code)
        assert last_wound_state(s) == saved


def test_last_wound_persistence(Session, bundle, out):
    path = out / 'expanded-last-wound.zsave'
    first = Session(bundle)
    try:
        first.action(1620, 13)
        saved = last_wound_state(first)
        first.command(f':save {path}')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1624')
        assert last_wound_state(second) == saved
        second.action(1620, 1)
        assert last(second, 'test.limb-wound') == ['reused', None]
        assert last_wound_state(second) == saved
    finally:
        second.close()


def recovery_state(s):
    s.action(1641)
    return last(s, 'test.recovery-state')


def test_lasting_recovery(s):
    s.action(1640, 0)
    initial = recovery_state(s)
    assert initial == [0, 1, 0, 6, 4, 0, 1, 3]
    s.action(1640, 4)
    assert last(s, 'test.recovery-preview') == ['recovery-month-not-reached']
    assert recovery_state(s) == initial
    s.action(1640, 5)
    assert last(s, 'test.recovery-month') == ['blocked', 'recovery-month-gap']
    assert recovery_state(s) == initial
    s.action(1640, 7)
    assert recovery_state(s) == initial
    s.action(1640, 1)
    first = recovery_state(s)
    assert first == [1, 1, 0, 6, 4, 0, 1, 3]
    for code in [6, 8, 10]:
        s.action(1640, code)
        assert recovery_state(s) == first
    s.action(1640, 9)
    assert last(s, 'test.recovery-month') == ['reused', None]
    assert recovery_state(s) == first
    s.action(1640, 2)
    second = recovery_state(s)
    assert second == [2, 1, 0, 6, 4, 0, 1, 3]
    s.action(1640, 3)
    assert recovery_state(s) == [3, 0, 1, 6, 4, 0, 0, 3]
    s.command('undo')
    assert recovery_state(s) == second
    s.action(1640, 3)
    s.action(1640, 12)
    later = recovery_state(s)
    assert later == [3, 1, 1, 12, 7, 0, 1, 3]
    s.action(1640, 3)
    assert last(s, 'test.recovery-month') == ['reused', None]
    assert recovery_state(s) == later


def test_lasting_recovery_persistence(Session, bundle, out):
    for months in [1, 3]:
        path = out / f'expanded-lasting-{months}.zsave'
        first = Session(bundle)
        try:
            first.action(1640, 0)
            for month in range(1, months + 1):
                first.action(1640, month)
            saved = recovery_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1641')
            assert recovery_state(second) == saved
            second.action(1640, months)
            assert last(second, 'test.recovery-month') == ['reused', None]
            assert recovery_state(second) == saved
            for month in range(months + 1, 4):
                second.action(1640, month)
            assert recovery_state(second) == [3, 0, 1, 6, 4, 0, 0, 3]
        finally:
            second.close()


def duration_state(s):
    s.action(1631)
    return last(s, 'test.duration-state')


def test_crippling_duration(s):
    initial = duration_state(s)
    assert initial == [0, 0, None, 0, 0, 0, 0, 0, 0, 0, 0]
    s.action(1630, 10)
    assert duration_state(s) == initial
    for code, expected in [
            (1, [6, 1, 'temporary', 0, 0, 11, 11, 6, 0, 1, 1]),
            (2, [6, 1, 'lasting', 1, 1, 10, 11, 7, 0, 1, 1]),
            (3, [6, 1, 'permanent', 0, 0, 10, 17, 3, 0, 1, 1]),
            (4, [6, 1, 'permanent', 0, 0, 0, 0, 3, 0, 1, 1]),
            (5, [0, 0, 'temporary', 0, 0, 11, 11, 6, 1, 1, 0]),
            (13, [6, 1, 'temporary', 0, 0, 15, 11, 6, 0, 1, 1]),
            (14, [6, 1, 'temporary', 0, 0, 15, 11, 6, 0, 1, 1]),
            (15, [6, 1, 'lasting', 1, 1, 10, 11, 7, 0, 1, 1]),
            (16, [0, 1, 'lasting', 1, 1, 10, 11, 7, 0, 1, 1]),
            (17, [0, 1, 'permanent', 0, 0, 10, 17, 3, 0, 1, 1])]:
        s.action(1630, code)
        assert last(s, 'test.duration-outcome') == ['resolved', None]
        assert duration_state(s) == expected
        s.command('undo')
        assert duration_state(s) == initial
    for code, reason in [(11, 'crippling-duration-combat-active'),
                         (12, 'crippling-duration-combat-not-ended')]:
        s.action(1630, code)
        assert last(s, 'test.duration-outcome') == ['blocked', reason]
        assert duration_state(s) == [6, 1, None, 0, 0, 0, 0, 3, 0, 0, 1]
        s.command('undo')
    s.action(1630, 6)
    partial = duration_state(s)
    assert partial == [1, 1, 'temporary', 0, 0, 11, 11, 6, 0, 1, 1]
    for code in [8, 9]:
        s.action(1630, code)
        assert duration_state(s) == partial
    s.action(1630, 7)
    assert duration_state(s) == [0, 0, 'temporary', 0, 0, 11, 11, 6, 1, 1, 0]
    s.command('undo')
    assert duration_state(s) == partial


def test_crippling_duration_persistence(Session, bundle, out):
    for code in [1, 2, 3, 4, 5]:
        path = out / f'expanded-duration-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(1630, code)
            saved = duration_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1631')
            assert duration_state(second) == saved
            second.action(1630, 0)
            assert last(second, 'test.duration-outcome') == ['reused', None]
            assert duration_state(second) == saved
        finally:
            second.close()


def test_crippling_months(s):
    for tl, expected in [(-1, [1,2,3,4,5,6]), (4, [1,2,3,4,5,6]),
                         (5, [1,1,2,3,4,5]), (6, [1,1,1,2,3,4]),
                         (7, [1,1,1,1,2,3]), (12, [1,1,1,1,2,3])]:
        for roll, months in enumerate(expected, 1):
            s.action(1615, roll, tl)
            assert last(s, 'test.crippling-months') == [months]


def limb_retention(s):
    s.action(1623)
    return last(s, 'test.limb-retention')


def test_limb_grip_retention(s):
    initial = limb_state(s)
    s.action(1620, 10)
    assert limb_state(s) == initial
    s.action(1620, 11)
    assert last(s, 'test.limb-wound') == ['blocked', 'limb-retention-score-unavailable']
    assert limb_state(s) == initial
    s.command('undo')
    for code, expected in [
            (7, [1, 11, 11, 1, 0, 1, None, 6, 'hands-unavailable', 4, 6]),
            (8, [1, 11, 10, 0, 1, 2, 'floor', 6, 'weapon-not-ready', 4, 6]),
            (9, [0, 0, 0, 0, 0, 2, 'floor', 3, 'weapon-not-ready', 4, 6]),
            (12, [1, 11, 11, 1, 1, 1, None, 6, 'hands-unavailable', 4, 6])]:
        s.action(1620, code)
        assert last(s, 'test.limb-wound') == ['resolved', None]
        assert limb_retention(s) == expected
        s.command('undo')
        assert limb_state(s) == initial
    s.action(1620, 7)
    saved = limb_retention(s)
    s.action(1620, 1)
    assert last(s, 'test.limb-wound') == ['reused', None]
    assert limb_retention(s) == saved


def test_limb_grip_persistence(Session, bundle, out):
    for code in [7, 8, 9, 12]:
        path = out / f'expanded-limb-grip-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(1620, code)
            saved = limb_retention(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1621')
            assert limb_retention(second) == saved
            second.action(1620, 1)
            assert last(second, 'test.limb-wound') == ['reused', None]
            assert limb_retention(second) == saved
        finally:
            second.close()


def test_unarmed_limb_capacity(s):
    # B147: an unusable hand does not remove its functioning arm's unarmed parry.
    for arms, hand, occupied, cap, expected in [
            (0, 0, 0, 2, [2, 8, 8, 1, 0]),
            (0, 1, 0, 2, [2, 8, 8, 0, 0]),
            (1, 0, 0, 2, [1, 8, None, 0, 0]),
            (2, 0, 0, 2, [0, None, None, 0, 0]),
            (1, 0, 1, 2, [0, None, None, 0, 0]),
            (0, 1, 1, 2, [1, 8, None, 0, 0]),
            (0, 0, 0, 0, [0, None, None, 1, 0]),
            (0, 0, 0, 1, [1, 8, None, 1, 0])]:
        for verb in [1612, 1614]:
            s.action(verb, arms, hand, occupied, cap)
            assert last(s, 'test.unarmed-capacity') == expected
    s.action(1613)
    assert last(s, 'test.unarmed-gates') == [
        'unarmed-grip-map-required', 'unarmed-hand-support-required', 1, 2]


def limb_state(s):
    s.action(1621)
    return last(s, 'test.limb-state')


def test_limb_wound_transactions(s):
    initial = limb_state(s)
    assert initial == [0, 0, 0, 1, None, None, 1, 3, 0, 0, 0, 0, 0, 0]
    s.action(1622)
    assert last(s, 'test.limb-preview') == ['ready', 6, 1, 1]
    assert limb_state(s) == initial
    s.action(1620, 5)
    assert limb_state(s) == initial
    for code, expected in [
            (1, [6, 1, 0, 0, 'floor', None, 1, 2, 1, 3, 6, 1, 0, 0]),
            (2, [6, 1, 1, 0, 'floor', 'floor', 0, 0, 1, 3, 6, 1, 0, 0]),
            (3, [4, 0, 0, 0, 'floor', None, 1, 3, 1, 3, 4, 1, 0, 0]),
            (4, [6, 1, 0, 0, 'floor', None, 1, 2, 1, 3, 6, 1, 0, 1])]:
        s.action(1620, code)
        assert last(s, 'test.limb-wound') == ['resolved', None]
        assert limb_state(s) == expected
        s.command('undo')
        assert limb_state(s) == initial
    s.action(1620, 6)
    assert last(s, 'test.limb-wound') == ['blocked', 'forced-drop-destination-required']
    assert limb_state(s) == initial
    s.command('undo')
    s.action(1620, 1)
    saved = limb_state(s)
    s.action(1620, 1)
    assert last(s, 'test.limb-wound') == ['reused', None]
    assert limb_state(s) == saved


def test_limb_wound_persistence(Session, bundle, out):
    for code in [1, 2, 3, 4]:
        path = out / f'expanded-limb-wound-{code}.zsave'
        first = Session(bundle)
        try:
            first.action(1620, code)
            saved = limb_state(first)
            first.command(f':save {path}')
        finally:
            first.close()
        second = Session(bundle)
        try:
            second.command(f':restore {path}\n@1621')
            assert limb_state(second) == saved
            second.action(1620, 1)
            assert last(second, 'test.limb-wound') == ['reused', None]
            assert limb_state(second) == saved
        finally:
            second.close()


def test_body_supports(s):
    # Full-2008 B421: hand disability permits a shield block, arm disability
    # prevents blocking but retains reduced passive protection unless severed.
    for arm, hand, severed, expected in [
            (0, 0, 0, [1, 1, 1, 1, 3, 0]),
            (0, 1, 0, [0, 0, 0, 1, 3, 0]),
            (1, 0, 0, [0, 0, 0, 0, 2, 0]),
            (1, 1, 0, [0, 0, 0, 0, 2, 0]),
            (1, 0, 1, [0, 0, 0, 0, 0, 0])]:
        s.action(1610, arm, hand, severed)
        assert last(s, 'test.body-supports') == expected
        if arm or hand:
            assert last(s, 'test.disabled-strike') == ['weapon-not-ready', 0]
    s.action(1611)
    assert last(s, 'test.body-support-rejections') == [
        'body-support-hand-required', 'body-part-severed-state',
        'body-support-owner', 'body-support-owner', 'body-part-kind-unavailable']


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


def test_skill_definition_gates(s):
    before = state(s)
    for variant in range(1, 7):
        s.action(1457, variant)
        assert last(s, 'test.skill-definition') == ['accepted' if variant == 3 else 'rejected']
    for variant, expected in [
            (1, ['wildcard-disabled']), (2, ['wildcard-difficulty']),
            (3, ['wildcard-default']), (4, ['wildcard-default']),
            (5, ['accepted', 3, 7])]:
        s.action(1458, variant)
        assert last(s, 'test.wildcard-creation') == expected
    assert state(s) == before


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


def test_technology_learning(s):
    before = state(s)
    s.action(1129)
    assert last(s, 'test.technology-learning') == [
        'technology-starting-access', 'technology-teacher-required',
        'technology-teacher-required', None, 'technology-teacher-subject',
        'technology-personal-level', None, 'technology-learning-cognition', None]
    s.action(1130)
    assert last(s, 'test.technology-learning-gates') == [
        'technology-teacher-required', 'technology-teacher-required', 5, 0,
        'ready', 'ready', 'technology-learning-cognition', 0]
    assert state(s) == before, 'rejected technology learning consumed resources'


def recognition_state(s):
    s.action(1131)
    return last(s, 'test.recognition-state')


def test_recognition(s):
    initial = recognition_state(s)
    assert initial == [None, 0, 0, 0, -2, None, 1]
    s.action(1132)
    assert last(s, 'test.recognition') == ['ready', None]
    s.action(1133)
    assert last(s, 'test.recognition-gates') == [
        'familiarity-recognition-unapproved', 'familiarity-recognition-experience',
        'ready', 'familiarity-recognition-source-unknown', 'familiarity-recognition-source']
    assert recognition_state(s) == initial
    s.action(1100, 9, 12)
    assert recognition_state(s) == initial, 'exception leaked recognition or RNG'
    s.action(1100, 8, 12)
    success = recognition_state(s)
    assert success == [True, 1, 3, 0, 0, 10, 3]
    s.action(1100, 8, 12)
    assert last(s, 'test.recognition') == ['reused', None]
    assert recognition_state(s) == success


def test_recognition_failure(s):
    s.action(1100, 8, 3)
    failed = recognition_state(s)
    assert failed == [True, 0, 3, 0, -2, 10, -8]
    s.action(1100, 8, 3)
    assert last(s, 'test.recognition') == ['reused', None]
    assert recognition_state(s) == failed, 'failed recognition allowed a free retry'


def test_recognition_similarity(s):
    initial = recognition_state(s)
    s.action(1100, 10)
    assert recognition_state(s) == [True, 1, 0, 0, 0, None, 3]
    s.command('undo')
    assert recognition_state(s) == initial


def test_recognition_persistence(Session, bundle, out):
    path = out / 'expanded-recognition.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 8, 3)
        saved = recognition_state(first)
        first.command(f':save {path}\n@1131')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1131')
        assert recognition_state(second) == saved
        second.action(1100, 8, 3)
        assert last(second, 'test.recognition') == ['reused', None]
        assert recognition_state(second) == saved
    finally:
        second.close()


def test_template_composition(s):
    before = state(s)
    # B259: maximum scores, not added adjustments, levels or source point totals.
    for order in [0, 1]:
        s.action(1134, order)
        assert last(s, 'test.template-composition') == [
            12, 12, 12, 12, 14, 13, 22, 5, 8, 2, 137, 8, 2]
    s.action(1135)
    assert last(s, 'test.template-conflicts') == ['exclusive-traits', 'empty-template-composition', 9]
    assert state(s) == before, 'template composition changed live character state'


def test_template_technology(s):
    before = state(s)
    s.action(1136)
    assert last(s, 'test.template-technology') == [
        8, 8, 1, 11, 8, 11, 'template-technology-conflict', 'technology-starting-access']
    assert state(s) == before, 'template technology selection changed live state'


def test_template_choices(s):
    before = state(s)
    s.action(1137)
    assert last(s, 'test.template-choice') == [
        4, 4, 'focus', 'training', 4, 'template-unresolved-choices',
        'template-choice-groups', 'template-choice-points',
        'template-choice-option', 'template-choice-ineligible']
    s.action(1138)
    assert last(s, 'test.template-choice-conflicts') == [
        -5, 1, 'exclusive-traits', 'template-choice-count', 'template-choice-groups']
    assert state(s) == before, 'choice resolution changed live state'


def test_template_score_options(s):
    before = state(s)
    s.action(1139)
    assert last(s, 'test.template-score-options') == [
        17, -10, 11, 12, 9, 10, 10, 21, 7, 10, 10, 'secondary-limit']
    assert state(s) == before, 'score option resolution mutated live state'


def test_extended_measurements(s):
    before = state(s)
    # B15: only complete increments of ten above 100 add a die.
    for strength, expected in [(101, [11, 0, 13, 0]), (109, [11, 0, 13, 0]),
                               (110, [12, 0, 14, 0]), (119, [12, 0, 14, 0]),
                               (120, [13, 0, 15, 0]), (1000, [101, 0, 103, 0])]:
        s.action(1105, strength)
        assert last(s, 'test.damage') == expected
    # B550's fractional-inch through two-yard rows, plus rounding boundaries.
    for ticks, expected in [(6, -15), (7, -14), (10, -14), (15, -13), (20, -12),
                            (30, -11), (45, -10), (60, -9), (90, -8), (150, -7),
                            (240, -6), (360, -5), (540, -4), (720, -3),
                            (1080, -2), (1620, -1), (2160, 0), (2161, 1),
                            (3240, 1), (3241, 2), (4320, 2), (6480, 3),
                            (1080000, 16)]:
        s.action(1140, ticks, 0)
        assert last(s, 'test.size-modifier') == [expected]
    for shape, expected in [(0, 2), (1, 3), (2, 4)]:
        s.action(1140, 4320, shape)
        assert last(s, 'test.size-modifier') == [expected]
    for distance, speed, include, expected in [(40, 30, 1, -9), (5, 1000, 1, -17),
                                              (40, 15, 1, -9), (40, 15, 0, -8)]:
        s.action(1141, distance, speed, include)
        assert last(s, 'test.speed-range') == [expected]
    assert state(s) == before, 'measurement queries mutated state'


def test_equipment_quality(s):
    before = state(s)
    for technology, quality, missing, damage, tl, expected in [
            (0, 'none', 0, 0, 8, -5), (1, 'none', 0, 0, 8, -10),
            (0, 'improvised', 0, 0, 8, -2), (1, 'improvised', 0, 0, 8, -5),
            (1, 'basic', 0, 0, 8, 0), (1, 'good', 0, 0, 8, 1),
            (1, 'fine', 0, 0, 8, 2), (1, 'best', 0, 0, 0, 2),
            (1, 'best', 0, 0, 5, 2), (1, 'best', 0, 0, 8, 4),
            (1, 'best', 0, 0, 11, 5), (1, 'fine', 2, 3, 8, -3)]:
        s.action(1142, quality, technology, missing, damage, tl, 1)
        assert last(s, 'test.equipment-quality') == ['ready', None, expected]
    s.action(1142, 'none', 1, 0, 0, 8, 0)
    assert last(s, 'test.equipment-quality') == ['blocked', 'equipment-required', 0]
    s.action(1143)
    assert last(s, 'test.equipment-context') == [
        5, 'equipment-required', 'equipment-condition-inapplicable']
    assert state(s) == before, 'equipment assessment or blocked check consumed resources'


def acquisition_state(s):
    s.action(1144)
    return last(s, 'test.acquisition-state')


def test_starting_equipment_price(s):
    # Independent B27 examples and boundary values, not a second price algorithm.
    for price, item_tl, campaign_tl, expected in [
            (1500, 8, 3, 48000), (1500, 3, 8, 1500), (1500, 8, 8, 1500),
            (1, 12, 0, 4096), (0, 12, 0, 0), (1073741823, 4, 3, 2147483646)]:
        s.action(1159, price, item_tl, campaign_tl)
        assert last(s, 'test.starting-price') == [expected]
    s.action(1160)
    assert last(s, 'test.starting-price-gates') == [
        48000, 50000, 48000, 'starting-equipment-creation-only', 1500, 1700,
        'starting-equipment-price-source', 'starting-equipment-technology-required',
        48000, 2000, 'reused', 1, 'starting-equipment-price-limit']


def test_acquisition(s):
    initial = acquisition_state(s)
    assert initial == [100, 0, None, 0, 0, 0]
    s.action(1145)
    assert last(s, 'test.acquisition') == ['ready', None, 40]
    assert acquisition_state(s) == initial
    s.action(1100, 12)
    assert acquisition_state(s) == initial, 'failed action leaked money or ownership'
    s.action(1100, 11)
    purchased = acquisition_state(s)
    assert purchased == [60, 1, True, 200, 0, 0]
    s.command('undo')
    assert acquisition_state(s) == initial
    s.action(1100, 11)
    assert acquisition_state(s) == purchased
    s.action(1100, 11)
    assert last(s, 'test.acquisition') == ['reused', None, 0]
    assert acquisition_state(s) == purchased
    s.action(1146)
    assert last(s, 'test.acquisition-gates') == [
        'equipment-unavailable', 'equipment-permission', 'equipment-unaffordable',
        'ready', 0, 'issued-equipment-price', 'equipment-already-owned']
    assert acquisition_state(s) == purchased


def storage_state(s):
    s.action(1147)
    return last(s, 'test.storage-state')


def test_equipment_storage(s):
    s.action(1100, 11)
    s.action(1100, 15)
    carried = storage_state(s)
    assert carried == [None, True, True, 200, 3, 1, 60]
    s.action(1100, 13)
    stored = storage_state(s)
    assert stored == ['workshop', None, None, 0, 0, 1, 60]
    s.command('undo')
    assert storage_state(s) == carried
    s.action(1100, 13)
    s.action(1100, 15)
    assert storage_state(s) == ['workshop', True, True, 0, 0, 1, 60]
    s.action(1148)
    assert last(s, 'test.stored-use') == ['weapon-not-ready', None, 'storage-inaccessible', None, 8, 10, 10]
    s.action(1100, 14)
    assert storage_state(s) == [None, None, None, 200, 0, 1, 60]
    s.action(1100, 11)
    assert acquisition_state(s) == [60, 1, True, 200, 0, 0], 'retrieval enabled a second purchase'


def test_equipment_persistence(Session, bundle, out):
    path = out / 'expanded-equipment.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 11); first.action(1100, 13)
        saved = storage_state(first)
        first.command(f':save {path}\n@1147')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
        first.action(1100, 14)
        continued = storage_state(first)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1147')
        assert storage_state(second) == saved
        second.action(1100, 14)
        assert storage_state(second) == continued
        second.action(1100, 11)
        assert last(second, 'test.acquisition') == ['reused', None, 0]
    finally:
        second.close()


def test_legal_access(s):
    before = state(s)
    for control, legality, role, licensed, expected in [
            (2, 4, 'civilian', 0, ['ready', None, 'none']),
            (3, 3, 'civilian', 0, ['ready', None, 'none']),
            (3, 2, 'civilian', 0, ['blocked', 'license-required', 'license']),
            (3, 2, 'civilian', 1, ['ready', None, 'license']),
            (3, 1, 'civilian', 1, ['blocked', 'special-unit-required', 'special-unit']),
            (3, 1, 'special-police', 0, ['ready', None, 'special-unit']),
            (4, 1, 'intelligence', 0, ['blocked', 'military-or-secret-police-required', 'military-or-secret-police']),
            (4, 1, 'secret-police', 0, ['ready', None, 'military-or-secret-police']),
            (6, 0, 'military', 0, ['ready', None, 'military-or-secret-police'])]:
        s.action(1149, control, legality, role, licensed)
        assert last(s, 'test.legal-table') == expected
    s.action(1150)
    assert last(s, 'test.legal-access') == [
        'registration-required', 'ready', 'legal-exclusion', 'noncitizen-policy-required',
        'ready', 'local-prohibition', True, 'license-required', 'license-required', 100, 0, 'ready']
    assert state(s) == before, 'legal assessment spent time, money or randomness'


def test_campaign_minimal(s):
    s.action(1151)
    assert last(s, 'test.campaign-minimal') == ['license-required', True]


def control_state(s):
    s.action(1153)
    return last(s, 'test.control-state')


def test_control_table(s):
    before = state(s)
    meanings = {'O': 'overlooked', 'I': 'intervention', 'E': 'encounter-required'}
    for rating, row in enumerate(['OOOOOO', 'EOOOOO', 'IEOOOO', 'IIEOOO', 'IIIEOO', 'IIIIEO', 'IIIIIE']):
        for die, symbol in enumerate(row, 1):
            s.action(1152, rating, die, 'enforcement')
            assert last(s, 'test.control-table') == [meanings[symbol]]
    for die, result in [(1, 'prohibited'), (3, 'encounter-required'), (6, 'permitted')]:
        s.action(1152, 3, die, 'legality')
        assert last(s, 'test.control-table') == [result]
    assert state(s) == before


def test_control_question(s):
    initial = control_state(s)
    s.action(1154)
    assert last(s, 'test.control') == ['ready', None, None]
    assert control_state(s) == initial
    s.action(1100, 18)
    assert control_state(s) == initial, 'exception leaked control roll'
    s.action(1100, 16)
    tied = control_state(s)
    assert tied == ['encounter-required', 2, True, None, 1, 0]
    s.action(1100, 16)
    assert last(s, 'test.control') == ['reused', None, 'encounter-required']
    assert control_state(s) == tied
    s.action(1100, 20)
    assert control_state(s) == tied, 'retargeting changed a resolved question'
    s.action(1100, 17)
    completed = control_state(s)
    assert completed == ['overlooked', 2, True, 'checkpoint-dialogue', 1, 0]
    s.command('undo')
    assert control_state(s) == tied
    s.action(1100, 17); s.action(1100, 17)
    assert last(s, 'test.control') == ['reused', None, 'overlooked']
    assert control_state(s) == completed


def test_control_certain(s):
    s.action(1100, 19)
    assert control_state(s) == ['overlooked', None, True, None, 0, 0]


def wealth_state(s):
    s.action(1156)
    return last(s, 'test.wealth-state')


def exchange_state(s):
    s.action(1164)
    return last(s, 'test.exchange-state')


def reaction_state(s):
    s.action(1176)
    return last(s, 'test.reaction-state')


def test_reaction_encounter(s):
    for total, band in [(-10, 0), (0, 0), (1, 1), (3, 1), (4, 2), (6, 2),
                        (7, 3), (9, 3), (10, 4), (12, 4), (13, 5), (15, 5),
                        (16, 6), (18, 6), (19, 7), (30, 7)]:
        s.action(1175, total)
        assert last(s, 'test.reaction-band') == [band]
    initial = reaction_state(s)
    s.action(1177)
    assert last(s, 'test.reaction-preview') == ['ready', None, None, None]
    s.action(1178)
    assert last(s, 'test.reaction-gates') == [
        4, None, 'reaction-predetermined', 'reaction-approach-unchanged', 'reaction-fight-started', 'ready']
    assert reaction_state(s) == initial
    s.action(1100, 31)
    assert reaction_state(s) == initial
    s.action(1100, 30)
    assert last(s, 'test.reaction') == ['resolved', 10, 10, 4]
    s.action(1177)
    assert last(s, 'test.reaction-preview') == ['reused', None, None, None]
    s.command('undo')
    assert reaction_state(s) == initial
    s.action(1100, 30); s.action(1100, 30)
    assert reaction_state(s) == [1, 0, 3, 0]
    s.action(1100, 32)
    result = last(s, 'test.reaction')
    assert result[0] == 'resolved' and result[2] == result[1] - 2
    assert reaction_state(s) == [2, 1, 6, 0]


def test_reputation_failure(s):
    s.action(1100, 29)
    assert last(s, 'test.reputation-recognition') == ['resolved', 10, 0]
    s.action(1100, 29)
    assert last(s, 'test.reputation-recognition') == ['reused', 10, 0]
    assert reputation_state(s) == [1, 3, 0]


def test_reputation_persistence(Session, bundle, out):
    path = out / 'expanded-reputation.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 29)
        saved = reputation_state(first)
        first.command(f':save {path}\n@1172')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1172')
        assert reputation_state(second) == saved
        second.action(1100, 29)
        assert last(second, 'test.reputation-recognition') == ['reused', 10, 0]
        assert reputation_state(second) == saved
    finally:
        second.close()


def reputation_state(s):
    s.action(1172)
    return last(s, 'test.reputation-state')


def test_reputation(s):
    for modifier, breadth, frequency, cost in [
            (2, 'all', 'sometimes', 5), (3, 'most', 'always', 10),
            (-4, 'large', 'always', -10), (1, 'small', 'always', 1),
            (-1, 'small', 'always', -2), (3, 'large', 'sometimes', 3),
            (-3, 'large', 'sometimes', -4), (4, 'negligible', 'always', 0)]:
        s.action(1171, modifier, breadth, frequency)
        assert last(s, 'test.reputation-price') == [cost]
    initial = reputation_state(s)
    s.action(1173)
    assert last(s, 'test.reputation-preview') == ['ready', None, 2]
    assert reputation_state(s) == initial
    s.action(1174)
    assert last(s, 'test.reputation-gates') == [
        0, 'reputation-outside-area', 'reputation-identity-hidden', 3, 3, 'reused',
        'duplicate-reputation-recognition', 'reputation-audience-changed']
    s.action(1100, 28)
    assert reputation_state(s) == initial
    s.action(1100, 27)
    assert last(s, 'test.reputation-recognition') == ['resolved', 10, 2]
    assert reputation_state(s) == [1, 3, 0]
    s.command('undo')
    assert reputation_state(s) == initial
    s.action(1100, 27); s.action(1100, 27)
    assert last(s, 'test.reputation-recognition') == ['reused', 10, 2]
    assert reputation_state(s) == [1, 3, 0]


def test_social_structure(s):
    s.action(1169)
    assert last(s, 'test.social-structure') == [
        5, 15, 6, 6, 3, 'social-purchased-status-limit',
        'rank-replaces-purchased-status', 3, 30, 'rank-status-policy-mismatch']


def information_state(s):
    s.action(1185)
    return last(s, 'test.information-state')


def knowledge_state(s):
    s.action(1190)
    return last(s, 'test.knowledge-state')


def test_uncertain_knowledge(s):
    initial = knowledge_state(s)
    assert initial == [0, 0, 0, 0]
    s.action(1191)
    assert last(s, 'test.knowledge-preview') == ['ready', None, None]
    assert knowledge_state(s) == initial
    s.action(1100, 40)
    assert knowledge_state(s) == initial
    s.action(1100, 39)
    assert last(s, 'test.knowledge-check') == ['resolved', 1, 10]
    assert knowledge_state(s) == [1, 1, 3, 0]
    s.action(1191)
    assert last(s, 'test.knowledge-preview') == ['reused', None, None]
    s.command('undo')
    assert knowledge_state(s) == initial
    s.action(1100, 39); s.action(1100, 39)
    assert last(s, 'test.knowledge-check') == ['reused', 1, 10]
    assert knowledge_state(s) == [1, 1, 3, 0]


def test_unknown_fact(s):
    s.action(1100, 41)
    assert last(s, 'test.knowledge-check') == ['resolved', 0, 10]
    s.action(1100, 39)
    assert last(s, 'test.knowledge-check') == ['reused', 0, 10]
    assert knowledge_state(s) == [0, 1, 3, 0]


def information_money(s):
    s.action(1188)
    return last(s, 'test.information-money')


def test_paid_information(s):
    initial = information_state(s)
    cash = information_money(s)
    assert cash == [0, 0]
    s.action(1189)
    assert last(s, 'test.information-payment-gates') == [
        'information-payment-unapproved', 'information-payment-funds']
    assert information_money(s) == cash
    s.action(1100, 37)
    assert information_money(s) == cash and information_state(s) == initial
    s.action(1100, 36)
    assert last(s, 'test.information-paid') == ['resolved', 40, 1]
    assert information_money(s) == [60, 60]
    assert information_state(s) == [1, 0, 0, 0, 'bridge-open']
    s.command('undo')
    assert information_money(s) == cash and information_state(s) == initial
    s.action(1100, 36); s.action(1100, 38)
    assert last(s, 'test.information-paid') == ['reused', 0, 0]
    assert information_money(s) == [60, 60]


def test_information_delivery(s):
    initial = information_state(s)
    assert initial == [0, 0, 0, 0]
    s.action(1186)
    assert last(s, 'test.information-preview') == ['ready', 0]
    s.action(1187)
    assert last(s, 'test.information-selection') == [
        1, 'information-partial-is-complete', 'information-statement-selection',
        'information-lie-required', 'road-safe', 'information-no-delivery']
    assert information_state(s) == initial
    s.action(1100, 35)
    assert information_state(s) == initial
    s.action(1100, 34)
    assert last(s, 'test.information-delivery') == ['resolved', 3]
    assert information_state(s) == [1, 0, 0, 0, 'bridge-open', 'ferry-closed', 'river-rising']
    s.command('undo')
    assert information_state(s) == initial
    s.action(1100, 34); s.action(1100, 34)
    assert last(s, 'test.information-delivery') == ['reused', 0]
    assert information_state(s) == [1, 0, 0, 0, 'bridge-open', 'ferry-closed', 'river-rising']


def trade_state(s):
    s.action(1194)
    return last(s, 'test.trade-state')


def test_trade_transfer(s):
    initial = trade_state(s)
    assert initial == [100, 20, 0, 1, 0, 'shop', 1, 1, 0, 0]
    s.action(1195)
    assert last(s, 'test.trade-preview') == ['ready', 40]
    s.action(1196)
    assert last(s, 'test.trade-gates') == [
        'trade-agreement', 'trade-item-unavailable', 'trade-permission', 'trade-funds', 'trade-item-ownership', 'local-prohibition']
    assert trade_state(s) == initial
    s.action(1100, 43)
    assert trade_state(s) == initial
    s.action(1100, 42)
    assert trade_state(s) == [60, 60, 1, 0, 1, None, 0, 0, 0, 0]
    s.command('undo')
    assert trade_state(s) == initial
    s.action(1100, 42); s.action(1100, 42)
    assert last(s, 'test.trade-transfer') == ['reused', 0]
    assert trade_state(s) == [60, 60, 1, 0, 1, None, 0, 0, 0, 0]


def loyalty_state(s):
    s.action(1199)
    return last(s, 'test.loyalty-state')


def danger_state(s):
    s.action(1204)
    return last(s, 'test.loyalty-danger-state')


def test_loyalty_danger(s):
    initial = danger_state(s)
    assert initial == [None, 0, 0, 0]
    s.action(1100, 49)
    assert danger_state(s) == initial
    s.action(1100, 48)
    assert last(s, 'test.loyalty-danger') == ['resolved', 0, 8]
    assert danger_state(s) == [8, 1, 0, 3]
    s.command('undo')
    assert danger_state(s) == initial
    s.action(1100, 48); s.action(1100, 48)
    assert last(s, 'test.loyalty-danger') == ['reused', 0, 8]
    assert danger_state(s) == [8, 1, 0, 3]
    s.action(1205)
    assert last(s, 'test.loyalty-danger-preview') == ['blocked', 'loyalty-overlapping-danger-unresolved']
    s.action(1100, 50)
    assert danger_state(s) == [8, 1, 604799, 3]
    s.action(1100, 51)
    assert danger_state(s) == [9, 1, 604800, 3]
    s.action(1205)
    assert last(s, 'test.loyalty-danger-preview') == ['ready', None]
    s.command('undo')
    assert danger_state(s) == [8, 1, 604799, 3]


def loyalty_change_state(s):
    s.action(1206)
    return last(s, 'test.loyalty-change-state')


def test_loyalty_performance(s):
    initial = loyalty_change_state(s)
    s.action(1100, 53)
    assert loyalty_change_state(s) == initial
    s.action(1100, 52)
    assert last(s, 'test.loyalty-change') == ['resolved', 1]
    assert loyalty_change_state(s) == [13, 1, 0, 0]
    s.command('undo')
    assert loyalty_change_state(s) == initial
    s.action(1100, 52); s.action(1100, 54)
    assert last(s, 'test.loyalty-change') == ['reused', 0]
    assert loyalty_change_state(s) == [13, 1, 0, 0]


def test_loyalty_botched(s):
    s.action(1100, 57)
    assert last(s, 'test.loyalty-change') == ['resolved', -1]
    assert loyalty_change_state(s) == [11, 1, 0, 0]


def test_loyalty_forgiveness(s):
    s.action(1100, 55)
    assert last(s, 'test.loyalty-change') == ['resolved', 1]
    assert loyalty_change_state(s) == [18, 1, 3, 0]
    s.action(1100, 55)
    assert last(s, 'test.loyalty-change') == ['reused', 0]
    assert loyalty_change_state(s) == [18, 1, 3, 0]


def test_loyalty_forgiveness_low(s):
    s.action(1100, 56)
    assert last(s, 'test.loyalty-change') == ['resolved', 0]
    assert loyalty_change_state(s) == [15, 1, 3, 0]


def service_state(s):
    s.action(1207)
    return last(s, 'test.service-state')


def test_service_anniversary(s):
    initial = service_state(s)
    s.action(1208)
    assert last(s, 'test.service-gates') == ['service-year-incomplete', 'service-anniversary-not-due', 'service-year-gap']
    assert service_state(s) == initial
    s.action(1100, 59)
    assert service_state(s) == initial
    s.action(1100, 58)
    assert last(s, 'test.service-anniversary') == ['resolved', 12, 10, 1]
    assert service_state(s) == [13, 1, 1, 3, 100]
    s.command('undo')
    assert service_state(s) == initial
    s.action(1100, 58); s.action(1100, 62)
    assert last(s, 'test.service-anniversary') == ['reused', 12, 10, 0]
    assert service_state(s) == [13, 1, 1, 3, 100]


def test_service_failure(s):
    s.action(1100, 60)
    assert last(s, 'test.service-anniversary') == ['resolved', 9, 10, 0]
    assert service_state(s) == [9, 1, 1, 3, 100]


def test_service_automatic(s):
    s.action(1100, 61)
    assert last(s, 'test.service-anniversary') == ['resolved', 20, None, 1]
    assert service_state(s) == [21, 1, 1, 0, 100]


def rescue_state(s):
    s.action(1209)
    return last(s, 'test.rescue-state')


def test_rescue_loyalty(s):
    initial = rescue_state(s)
    s.action(1100, 64)
    assert rescue_state(s) == initial
    s.action(1100, 63)
    assert last(s, 'test.rescue-loyalty') == ['resolved', 10, 13, 13, 4]
    assert rescue_state(s) == [13, 1, 3, 0]
    s.command('undo')
    assert rescue_state(s) == initial
    s.action(1100, 63); s.action(1100, 63)
    assert last(s, 'test.rescue-loyalty') == ['reused', 10, 13, 13, 0]
    assert rescue_state(s) == [13, 1, 3, 0]


def test_rescue_no_decrease(s):
    s.action(1100, 65)
    assert last(s, 'test.rescue-loyalty') == ['resolved', 10, 13, 17, 0]
    assert rescue_state(s) == [17, 1, 3, 0]


def test_rescue_sacrifice(s):
    s.action(1100, 67)
    assert last(s, 'test.rescue-loyalty') == ['resolved', 10, 13, 15, 6]
    assert rescue_state(s) == [15, 1, 3, 0]


def test_rescue_ungrateful(s):
    s.action(1100, 66)
    assert last(s, 'test.rescue-loyalty') == ['resolved', 10, 12, 9, 0]
    assert rescue_state(s) == [9, 1, 3, 0]


def loyalty_pay_state(s):
    s.action(1210)
    return last(s, 'test.loyalty-pay-state')


def test_loyalty_pay(s):
    initial = loyalty_pay_state(s)
    s.action(1100, 69)
    assert loyalty_pay_state(s) == initial
    s.action(1100, 68)
    assert last(s, 'test.loyalty-pay') == ['resolved', 2]
    assert loyalty_pay_state(s) == [14, 12, 2, None, 1, 0, 0]
    s.command('undo')
    assert loyalty_pay_state(s) == initial
    s.action(1100, 68); s.action(1100, 68)
    assert last(s, 'test.loyalty-pay') == ['reused', 0]
    s.action(1100, 70); s.action(1100, 70)
    assert last(s, 'test.loyalty-pay') == ['reused', 0]
    assert loyalty_pay_state(s) == [14, 12, 2, 100, 2, 0, 0]
    s.action(1100, 71)
    assert loyalty_pay_state(s) == [14, 12, 2, 100, 2, 99, 0]
    s.action(1100, 51)
    assert loyalty_pay_state(s) == [12, 12, 2, 100, 2, 100, 0]
    s.command('undo')
    assert loyalty_pay_state(s) == [14, 12, 2, 100, 2, 99, 0]


def job_state(s):
    s.action(1215)
    return last(s, 'test.job-state')


def test_job_month(s):
    initial = job_state(s)
    assert initial == [100, 400, 0, 1, 0, 0]
    s.action(1216)
    assert last(s, 'test.job-month-preview') == ['blocked', 'job-month-not-due', None]
    s.action(1100, 73)
    assert job_state(s) == initial
    s.action(1100, 72)
    assert last(s, 'test.job-month') == ['resolved', 400, 400]
    assert job_state(s) == [500, 400, 1, 1, 3, 100]
    s.command('undo')
    assert job_state(s) == initial
    s.action(1100, 72); s.action(1100, 76)
    assert last(s, 'test.job-month') == ['reused', 0, 0]
    assert job_state(s) == [500, 400, 1, 1, 3, 100]


def test_job_demotion(s):
    s.action(1100, 74)
    assert last(s, 'test.job-month') == ['resolved', 0, 360]
    assert job_state(s) == [80, 360, 1, 1, 3, 100]


def test_job_dismissal(s):
    s.action(1100, 75)
    assert last(s, 'test.job-month') == ['resolved', 0, 400]
    assert job_state(s) == [80, 400, 1, 0, 3, 100]


def test_job_variable_month(s):
    s.action(1100, 77)
    assert last(s, 'test.job-month') == ['resolved', 480, 400]
    assert job_state(s) == [580, 400, 1, 1, 3, 100]


def living_state(s):
    s.action(1219)
    return last(s, 'test.living-state')


def test_household_payment(s):
    initial = living_state(s)
    assert initial == [2000, 0, 0, None, None, 0, 0]
    s.action(1222)
    assert last(s, 'test.living-gates') == [
        'living-payment-unapproved', 'living-payment-not-due', 'living-payment-funds',
        899, 0, 'living-payment-member', 'resolved', 299,
        'living-payment-partial-overlap', 299, 0]
    assert living_state(s) == initial
    s.action(1220)
    assert last(s, 'test.living-preview') == ['ready', 900]
    assert living_state(s) == initial
    s.action(1100, 79)
    assert living_state(s) == initial
    s.action(1100, 78)
    assert last(s, 'test.living-payment') == ['resolved', 900]
    assert living_state(s) == [1100, 1, 1, 0, -1, 0, 0]
    s.command('undo')
    assert living_state(s) == initial
    s.action(1100, 78); s.action(1100, 78)
    assert last(s, 'test.living-payment') == ['reused', 0]
    s.action(1221)
    assert last(s, 'test.living-other-payer') == ['blocked', 'living-period-already-covered', 2000]
    assert living_state(s) == [1100, 1, 1, 0, -1, 0, 0]


def hire_state(s):
    s.action(1239)
    return last(s, 'test.hire-candidate-state')


def test_hire_candidate(s):
    initial = hire_state(s)
    assert initial == [0,1,0,0,2,0,0,0]
    s.action(1240)
    assert last(s, 'test.hire-candidate-preview') == ['blocked','employment-recruiting-interview']
    assert hire_state(s) == initial
    s.action(1100,87)
    presented = hire_state(s)
    assert presented == [0,1,1,0,2,0,0,3]
    s.action(1240)
    assert last(s, 'test.hire-candidate-preview') == ['ready',None]
    assert hire_state(s) == presented
    s.action(1100,95)
    assert hire_state(s) == presented
    s.action(1100,94)
    assert last(s, 'test.hire-candidate') == ['resolved',None]
    assert hire_state(s) == [1,0,0,1,2,0,0,3]
    s.command('undo')
    assert hire_state(s) == presented
    s.action(1100,94); s.action(1100,94)
    assert last(s, 'test.hire-candidate') == ['reused',None]
    s.action(1100,90)
    assert last(s, 'test.recruiting-result')[1] == 'recruiting-unavailable'
    assert hire_state(s) == [1,0,0,1,2,0,0,3]


def payroll_state(s):
    s.action(1241)
    return last(s, 'test.hire-payroll-state')


def test_hire_payroll(s):
    s.action(1100,87); s.action(1100,94)
    initial = payroll_state(s)
    assert initial == [950,0,0,0,3]
    s.action(1100,97)
    assert payroll_state(s) == initial
    s.action(1100,96)
    assert last(s, 'test.hire-payroll') == ['resolved',None,100]
    assert payroll_state(s) == [850,100,1,100,6]
    s.command('undo')
    assert payroll_state(s) == initial
    s.action(1100,96); s.action(1100,96)
    assert last(s, 'test.hire-payroll') == ['reused',None,0]
    assert payroll_state(s) == [850,100,1,100,6]


def test_hire_payroll_unfunded(s):
    s.action(1100,87); s.action(1100,94); s.action(1100,98)
    assert last(s, 'test.hire-payroll') == ['blocked','employment-payroll-funds',0]
    assert payroll_state(s) == [99,0,0,100,3]


def recruiting_state(s):
    s.action(1237)
    return last(s, 'test.recruiting-state')


def test_recruiting_search(s):
    initial = recruiting_state(s)
    assert initial == [1000,1000,0,0,0,0,0,0]
    s.action(1238)
    assert last(s, 'test.recruiting-preview') == ['ready',13,50,None]
    assert recruiting_state(s) == initial
    s.action(1100,88)
    assert recruiting_state(s) == initial
    s.action(1100,87)
    assert last(s, 'test.recruiting-result') == ['resolved',None,50,0,1]
    assert recruiting_state(s) == [950,1000,0,1,0,1,0,3]
    s.command('undo')
    assert recruiting_state(s) == initial
    s.action(1100,87); s.action(1100,87)
    assert last(s, 'test.recruiting-result') == ['reused',None,0,0,0]
    s.action(1100,90)
    assert last(s, 'test.recruiting-result')[1] == 'recruiting-interview-pending'
    s.action(1100,89); s.action(1100,90)
    assert last(s, 'test.recruiting-result')[1] == 'recruiting-week-used'
    s.action(1100,83); s.action(1100,90)
    assert last(s, 'test.recruiting-result')[1] == 'recruiting-week-used'
    assert recruiting_state(s) == [950,1000,0,1,0,0,604799,3]
    s.action(1100,84); s.action(1100,90)
    final = recruiting_state(s)
    assert final[:5] == [950,950,0,2,0]
    assert final[6:] == [604800,6]


def test_recruiting_legal_consequence(s):
    initial = recruiting_state(s)
    s.action(1100,92)
    assert recruiting_state(s) == initial
    s.action(1100,91)
    assert last(s, 'test.recruiting-result') == ['resolved',None,50,200,0]
    assert recruiting_state(s) == [750,1000,200,0,1,0,0,3]
    s.command('undo')
    assert recruiting_state(s) == initial
    s.action(1100,93)
    assert last(s, 'test.recruiting-result') == ['resolved',None,50,200,0]
    assert recruiting_state(s) == [750,1000,200,0,1,0,0,3]


def acceptance_state(s):
    s.action(1233)
    return last(s, 'test.accept-employment-state')


def test_employment_acceptance(s):
    initial = acceptance_state(s)
    assert initial == [0,1,0,100,0,0]
    s.action(1234)
    assert last(s, 'test.accept-employment-preview') == ['blocked','employment-offer-undiscovered']
    s.action(1236)
    assert last(s, 'test.accept-other-worker') == ['employment-offer-undiscovered',0]
    assert acceptance_state(s) == initial
    s.action(1100,80)
    found = acceptance_state(s)
    assert found == [0,1,0,90,0,6]
    s.action(1234)
    assert last(s, 'test.accept-employment-preview') == ['ready',None]
    assert acceptance_state(s) == found
    s.action(1100,86)
    assert acceptance_state(s) == found
    s.action(1100,85)
    assert last(s, 'test.accept-employment') == ['resolved',None]
    assert acceptance_state(s) == [1,0,1,90,0,6]
    s.action(1235)
    assert last(s, 'test.accept-employment-terms') == [100,'archive','archive-contract',0,0,1,'unpaid',1]
    s.command('undo')
    assert acceptance_state(s) == found
    s.action(1100,85); s.action(1100,85)
    assert last(s, 'test.accept-employment') == ['reused',None]
    s.action(1236)
    assert last(s, 'test.accept-other-worker') == ['employment-offer-filled',0]
    assert acceptance_state(s) == [1,0,1,90,0,6]


def job_search_state(s):
    s.action(1229)
    return last(s, 'test.job-search-state')


def test_job_search_batch(s):
    initial = job_search_state(s)
    assert initial == [100,0,None,0,0]
    s.action(1232)
    assert last(s, 'test.job-search-gates') == ['job-search-unapproved','job-search-funds',
        9,0,'job-search-duplicate-job','job-search-opportunity',9,0]
    assert job_search_state(s) == initial
    s.action(1230)
    assert last(s, 'test.job-search-preview') == ['ready',10,12,12,0]
    assert job_search_state(s) == initial
    s.action(1100,81)
    assert job_search_state(s) == initial
    s.action(1100,80)
    assert last(s, 'test.job-search-result') == ['resolved',None,10,2]
    assert job_search_state(s) == [90,1,0,0,6]
    s.action(1231)
    assert last(s, 'test.job-search-receipt') == [12,10,1,10]
    s.command('undo')
    assert job_search_state(s) == initial
    s.action(1100,80); s.action(1100,80)
    assert last(s, 'test.job-search-result') == ['reused',None,0,0]
    s.action(1100,82)
    assert last(s, 'test.job-search-result') == ['blocked','job-search-week-used',0,0]
    assert job_search_state(s) == [90,1,0,0,6]
    s.action(1100,83); s.action(1100,82)
    assert last(s, 'test.job-search-result')[1] == 'job-search-week-used'
    assert job_search_state(s) == [90,1,0,604799,6]
    s.action(1100,84); s.action(1100,82)
    assert job_search_state(s) == [80,2,604800,604800,12]


def test_job_seeking(s):
    initial = job_state(s)
    # Purchased easy skill is 12. Monthly job difficulty does not reduce job-search IQ.
    for minimum, population, status, jobs, budget, lazy, modifier, score in [
            (12,5000,0,1,0,0,0,10),(11,5000,0,1,0,0,1,11),
            (10,5000,0,1,0,0,2,12),(8,5000,0,1,0,0,2,12),
            (12,5000,-1,1,0,0,2,12),(12,5000,2,1,0,0,-4,6),
            (12,5000,0,3,0,0,-2,8),(12,5000,0,1,500,0,2,12),
            (12,100000,0,1,0,1,-2,8),(10,5000,1,2,50,0,0,10),
            (12,5000,4,1,0,0,-8,2)]:
        s.action(1227,minimum,population,status,jobs,budget,lazy)
        expected = ['ready', None] if score >= 3 else ['blocked','job-search-roll-unavailable']
        assert last(s, 'test.job-seeking') == expected + [modifier,score]
    s.action(1227,13,5000,0,1,0,0)
    assert last(s, 'test.job-seeking')[:2] == ['blocked','job-skill-minimum']
    s.action(1228)
    assert last(s, 'test.job-seeking-gates') == [10,'job-search-self-employment',
        'job-search-ability-evidence',12,'job-search-qualification-skill']
    assert job_state(s) == initial


def test_employment_market(s):
    # B517: all job wealth rows at TL8; the worker's wealth is deliberately absent.
    for status, pay in zip(range(-2, 9), [520, 1300, 2600, 5200, 13000, 52000,
                                           260000, 2600000, 26000000, 260000000,
                                           'job-money-limit']):
        s.action(1223, 8, status)
        assert last(s, 'test.job-wealth-pay') == [pay]
    for tl, status, expected in [(0, -2, 125), (0, -1, 'job-fractional-money'),
                                 (7, 1, 4200), (9, 1, 7200), (0, 8, 625000000)]:
        s.action(1223, tl, status)
        assert last(s, 'test.job-wealth-pay') == [expected]
    for population, modifier in [(0,-3),(99,-3),(100,-2),(999,-2),(1000,-1),
                                 (4999,-1),(5000,0),(9999,0),(10000,1),(49999,1),
                                 (50000,2),(99999,2),(100000,3),(2147483647,3)]:
        s.action(1224, population)
        assert last(s, 'test.employment-population') == [modifier]
    for pay, budget, recruiting, bonus in [
            (1000,49,0,0),(1000,50,0,1),(1000,499,0,1),(1000,500,0,2),
            (1000,4999,0,2),(1000,5000,0,3),(1000,499,1,0),(1000,500,1,1),
            (1000,5000,1,2),(1000,50000,1,3),
            (625,31,0,0),(625,32,0,1),(625,312,0,1),(625,313,0,2),
            (625,3124,0,2),(625,3125,0,3),(625,312,1,0),(625,313,1,1),
            (1,0,0,0),(1,1,0,2),(1,2147483647,0,11),
            (2147483647,2147483647,1,1)]:
        s.action(1225, pay, budget, recruiting)
        assert last(s, 'test.employment-advertising') == [bonus]
    for offered, bonus in [(1000,0),(1199,0),(1200,1),(1499,1),(1500,2),(1999,2),(2000,3),(5000,3)]:
        s.action(1226,1000,offered,0,0,0,0,0)
        assert last(s, 'test.recruiting-modifiers') == [bonus]
    for pay, offered, bonus in [(3,3,0),(3,4,1),(3,5,2),(3,6,3),
                                (2147483647,2147483647,0)]:
        s.action(1226,pay,offered,0,0,0,0,0)
        assert last(s, 'test.recruiting-modifiers') == [bonus]
    for risk, combatant, illegal, streetwise, waiver, expected in [
            (1,0,0,0,0,-2),(1,1,0,0,0,0),(0,0,1,0,0,-5),
            (0,0,1,1,0,-5),(0,0,1,1,1,0),(1,0,1,1,1,-2),
            (0,0,1,0,1,'recruiting-illegal-waiver')]:
        s.action(1226,1000,1000,risk,combatant,illegal,streetwise,waiver)
        assert last(s, 'test.recruiting-modifiers') == [expected]


def test_lifestyle_prices(s):
    for status, expected in zip(range(-2, 9), [100, 300, 600, 1200, 3000, 12000, 60000, 600000, 6000000, 60000000, 600000000]):
        s.action(1217, status)
        assert last(s, 'test.living-cost') == [expected]
    cases = [
        ((0, 'monthly', 0, 0), [600, None, 0]),
        ((0, 'travel-month', 0, 0), [3600, None, 0]),
        ((0, 'lodging-day', 0, 0), [120, None, 0]),
        ((0, 'breakfast', 0, 0), [6, None, 0]),
        ((0, 'dinner', 0, 0), [12, None, 0]),
        ((0, 'rations-week', 0, 0), [30, 1400, 0]),
        ((8, 'liquor-bottle', 0, 0), [120, None, 0]),
        ((8, 'wardrobe', 0, 0), [600000000, 2000, 1]),
        ((8, 'ordinary-outfit', 0, 0), [2400, 200, 0]),
        ((8, 'ordinary-outfit', 1, 0), [600, 200, 0]),
        ((8, 'ordinary-outfit', 1, 1), [2400, 200, 0]),
        ((0, 'winter-outfit', 0, 0), [180, 400, 0]),
        ((0, 'formal-outfit', 0, 0), [240, 200, 0]),
        ((0, 'cosmetics-month', 0, 0), [60, 200, 0]),
    ]
    for args, expected in cases:
        s.action(1218, *args)
        assert last(s, 'test.lifestyle-price') == expected


def test_job_earnings(s):
    cases = [
        ((400, 0, 12, 10, 'next-month'), ['ready', None, 400, 400, 0]),
        ((400, 0, 12, 14, 'next-month'), ['ready', None, 400, 400, 0]),
        ((400, 0, 12, 3, 'next-month'), ['ready', None, 400, 440, 0]),
        ((400, 0, 12, 3, 'this-month'), ['ready', None, 440, 440, 0]),
        ((400, 0, 12, 3, 'unspecified'), ['blocked', 'job-raise-timing-required', 0, 400, 0]),
        ((400, 1, 12, 12, 'next-month'), ['ready', None, 400, 400, 0]),
        ((400, 1, 12, 10, 'next-month'), ['ready', None, 480, 400, 0]),
        ((400, 1, 12, 14, 'next-month'), ['ready', None, 320, 400, 0]),
        ((400, 1, 12, 3, 'next-month'), ['ready', None, 1200, 400, 0]),
        ((400, 1, 12, 18, 'next-month'), ['ready', None, 0, 400, 1]),
        ((400, 0, 12, 18, 'next-month'), ['ready', None, 0, 400, 1]),
        ((400, 1, 20, 17, 'next-month'), ['blocked', 'job-automatic-failure-margin-unresolved', 0, 400, 0]),
    ]
    for args, expected in cases:
        s.action(1213, *args)
        assert last(s, 'test.job-earnings') == expected
    s.action(1214)
    assert last(s, 'test.job-money-limits') == ['job-fractional-money', 'job-money-limit', 2000000000]


def test_job_qualifications(s):
    for tl, expected in enumerate([625, 650, 675, 700, 800, 1100, 1600, 2100, 2600, 3600, 5600, 8100, 10600]):
        s.action(1211, tl)
        assert last(s, 'test.typical-job-pay') == [expected]
    s.action(1212)
    assert last(s, 'test.job-qualifications') == [
        'job-other-requirements', 12, 'job-skill-minimum', 'job-purchased-skill-required', 12, 12]


def test_loyalty(s):
    initial = loyalty_state(s)
    s.action(1203)
    assert last(s, 'test.loyalty-preview') == ['blocked', 'loyalty-uninitialized', None, None, None]
    s.action(1100, 45)
    assert loyalty_state(s) == initial
    s.action(1100, 44)
    assert last(s, 'test.loyalty') == ['resolved', 12, 10, 1]
    assert loyalty_state(s) == [1, 1, 3, 0]
    s.action(1203)
    assert last(s, 'test.loyalty-preview') == ['reused', None, None, None, None]
    s.command('undo')
    assert loyalty_state(s) == initial
    s.action(1100, 44); s.action(1100, 44)
    assert last(s, 'test.loyalty') == ['reused', 12, 10, 1]
    assert loyalty_state(s) == [1, 1, 3, 0]


def test_loyalty_automatic(s):
    s.action(1100, 46)
    assert last(s, 'test.loyalty') == ['resolved', 20, None, 1]
    assert loyalty_state(s) == [1, 1, 0, 0]


def test_loyalty_failure(s):
    s.action(1100, 47)
    assert last(s, 'test.loyalty') == ['resolved', 9, 10, 0]
    s.action(1100, 44)
    assert last(s, 'test.loyalty') == ['reused', 9, 10, 0]


def test_trade_modifiers(s):
    for fair, offer, buy_modifier in [
            (100, 100, 0), (100, 109, 0), (100, 110, 1), (100, 91, 0),
            (100, 90, -1), (100, 120, 2), (100, 80, -2), (101, 111, 0),
            (101, 112, 1), (101, 90, -1), (100, 0, -10), (100, 250, 15),
            (2147483647, 0, -10), (2000000000, 2147483647, 0), (1, 101, 1000)]:
        for direction, expected in [('buy', buy_modifier), ('sell', -buy_modifier)]:
            s.action(1197, fair, offer, direction)
            assert last(s, 'test.trade-offer-modifier') == [expected]
    s.action(1198)
    assert last(s, 'test.trade-skill-modifier') == [2, 3, 4, 0]


def test_hire_candidate_persistence(Session, bundle, out):
    path = out / 'expanded-hire-candidate.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 87)
        first.action(1100, 94)
        saved = hire_state(first)
        first.command(f':save {path}\n@1239')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1239')
        assert hire_state(second) == saved
        second.action(1100, 94)
        assert last(second, 'test.hire-candidate') == ['reused', None]
        assert hire_state(second) == saved
    finally:
        second.close()


def test_employment_acceptance_persistence(Session, bundle, out):
    path = out / 'expanded-employment-acceptance.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 80)
        first.action(1100, 85)
        saved = acceptance_state(first)
        first.command(f':save {path}\n@1233')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1233')
        assert acceptance_state(second) == saved
        second.action(1100, 85)
        assert last(second, 'test.accept-employment') == ['reused', None]
        assert acceptance_state(second) == saved
    finally:
        second.close()


def test_job_search_persistence(Session, bundle, out):
    path = out / 'expanded-job-search.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 80)
        saved = job_search_state(first)
        first.command(f':save {path}\n@1229')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1229')
        assert job_search_state(second) == saved
        second.action(1100, 80)
        assert last(second, 'test.job-search-result') == ['reused', None, 0, 0]
        assert job_search_state(second) == saved
    finally:
        second.close()


def test_living_persistence(Session, bundle, out):
    path = out / 'expanded-living.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 78)
        saved = living_state(first)
        first.command(f':save {path}\n@1219')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1219')
        assert living_state(second) == saved
        second.action(1100, 78)
        assert last(second, 'test.living-payment') == ['reused', 0]
        assert living_state(second) == saved
    finally:
        second.close()


def test_trade_persistence(Session, bundle, out):
    path = out / 'expanded-trade.zsave'
    first = Session(bundle)
    try:
        first.action(1100, 42)
        saved = trade_state(first)
        first.command(f':save {path}\n@1194')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1194')
        assert trade_state(second) == saved
        second.action(1100, 42)
        assert last(second, 'test.trade-transfer') == ['reused', 0]
        assert trade_state(second) == saved
    finally:
        second.close()


def test_trade_reactions(s):
    for band, buy, sell in [(1, 900, 100), (2, 600, 150), (3, 360, 225),
                             (4, 300, 300), (5, 300, 300), (6, 300, 300), (7, 300, 300)]:
        for direction, price in [('buy', buy), ('sell', sell)]:
            s.action(1192, band, direction, 300, 300)
            assert last(s, 'test.trade-price') == ['ready', None, price, 0, 0, 1 if band >= 5 else 0]
    for band, direction, offer, price in [(6, 'buy', 200, 240), (6, 'sell', 500, 450),
                                         (7, 'buy', 100, 150), (7, 'sell', 700, 600),
                                         (6, 'buy', 250, 250), (7, 'sell', 400, 400)]:
        s.action(1192, band, direction, 300, offer)
        assert last(s, 'test.trade-price') == ['ready', None, price, 0, 0, 1]
    s.action(1192, 0, 'buy', 300, 200)
    assert last(s, 'test.trade-price') == ['ready', None, 0, 1, -2, 0]
    s.action(1192, 2, 'sell', 300, 360)
    assert last(s, 'test.trade-price') == ['blocked', 'trade-counteroffer-source-conflict', 0, 0, 0, 0]
    s.action(1193)
    assert last(s, 'test.trade-limits') == ['trade-fractional-money', 'trade-price-limit', 1073741820]


def test_information_reactions(s):
    cases = [
        ((0, 0, 'lie', 0, 0), ['ready', None, 'none', 0, 0, 1, -2, 0, 0, 0, 0]),
        ((1, 0, 'lie', 0, 0), ['ready', None, 'malicious-lie', 0, 0, 0, 0, 0, 0, 0, 0]),
        ((2, 0, 'payment', 0, 0), ['ready', None, 'demand-payment', 0, 0, 0, 0, 0, 0, 0, 0]),
        ((2, 0, 'payment', 1, 0), ['ready', None, 'incomplete-belief', 0, 0, 0, 0, 0, 0, 0, 0]),
        ((3, 0, 'unknown', 0, 1), ['ready', None, 'claims-ignorance', 0, 0, 0, 0, 1, 0, 0, 0]),
        ((3, 0, 'partial', 0, 0), ['ready', None, 'incomplete-belief', 0, 0, 0, 0, 0, 0, 0, 0]),
        ((4, 1, 'lie', 0, 0), ['ready', None, 'incomplete-belief', 0, 0, 0, 0, 0, 0, 0, 0]),
        ((4, 0, 'lie', 0, 0), ['ready', None, 'requested-belief', 0, 0, 0, 0, 0, 0, 0, 0]),
        ((5, 2, 'lie', 0, 0), ['ready', None, 'requested-belief', 0, 0, 0, 0, 0, 0, 0, 0]),
        ((6, 2, 'lie', 0, 0), ['ready', None, 'requested-belief', 1, 0, 0, 0, 0, 0, 0, 0]),
        ((7, 2, 'lie', 0, 0), ['ready', None, 'requested-belief', 0, 1, 0, 0, 0, 1, 2, 3]),
    ]
    for args, expected in cases:
        s.action(1183, *args)
        assert last(s, 'test.information-reaction') == expected
    for scale, bonus in [('none', 0), ('day', 1), ('week', 2), ('month', 3), ('year', 4)]:
        s.action(1184, scale)
        assert last(s, 'test.information-modifiers') == [bonus, bonus - 6, None if bonus == 0 else 'information-bribe-inappropriate']


def test_aid_reactions(s):
    # grant, extent, advice, volunteered information, combat roll, modifier, cap, retry, modifier
    cases = [
        ((0, 1, 'reasonable'), [0, 'none', 0, 0, 1, -4, 7, 0, 0]),
        ((1, 1, 'reasonable'), [0, 'none', 0, 0, 1, 0, 4, 0, 0]),
        ((2, 1, 'reasonable'), [0, 'none', 0, 0, 0, 0, 7, 0, 0]),
        ((3, 1, 'reasonable'), [0, 'none', 0, 0, 0, 0, 7, 1, -2]),
        ((4, 1, 'reasonable'), [1, 'requested', 0, 0, 0, 0, 7, 0, 0]),
        ((4, 0, 'reasonable'), [0, 'none', 0, 0, 0, 0, 7, 1, -2]),
        ((5, 0, 'reasonable'), [1, 'requested', 0, 0, 0, 0, 7, 0, 0]),
        ((5, 1, 'silly'), [0, 'none', 1, 0, 0, 0, 7, 0, 0]),
        ((6, 0, 'silly'), [1, 'requested', 0, 1, 0, 0, 7, 0, 0]),
        ((6, 1, 'totally-unreasonable'), [0, 'none', 0, 1, 0, 0, 7, 0, 0]),
        ((7, 0, 'totally-unreasonable'), [1, 'extra-within-capability', 0, 0, 0, 0, 7, 0, 0]),
    ]
    for args, expected in cases:
        s.action(1181, *args)
        assert last(s, 'test.aid-reaction') == expected
    s.action(1182)
    assert last(s, 'test.aid-modifiers') == [0, 1, -7]


def test_combat_reactions(s):
    # (band, fighting, outnumbered, hopeless, escape, remain), expected result.
    cases = [
        ((0, 0, 1, 1, 1, 0), ['attack', 0, 1, 0]),
        ((1, 0, 0, 0, 1, 0), ['attack', 0, 0, 0]),
        ((1, 1, 0, 1, 1, 0), ['flee', 0, 0, 0]),
        ((2, 0, 1, 0, 1, 0), ['flee', 0, 0, 0]),
        ((2, 1, 1, 0, 1, 0), ['continue-fighting', 0, 0, 0]),
        ((3, 0, 0, 0, 1, 0), ['demand-departure', 0, 0, 1]),
        ((3, 0, 0, 0, 1, 1), ['attack', 0, 0, 1]),
        ((3, 0, 1, 0, 1, 1), ['flee', 0, 0, 1]),
        ((3, 1, 1, 0, 1, 1), ['continue-fighting', 0, 0, 0]),
        ((4, 0, 0, 0, 1, 0), ['pass-peacefully', 0, 0, 0]),
        ((4, 1, 0, 0, 1, 0), ['disengage', 0, 0, 0]),
        ((5, 1, 0, 0, 0, 0), ['flee', 0, 0, 0]),
        ((6, 1, 0, 0, 1, 0), ['flee', 0, 0, 0]),
        ((6, 1, 0, 0, 0, 0), ['surrender', 0, 0, 0]),
        ((7, 1, 0, 0, 1, 0), ['surrender', 0, 0, 0]),
        ((5, 0, 0, 0, 1, 0), ['allow-request', 1, 0, 0]),
        ((6, 0, 0, 0, 1, 0), ['allow-request', 3, 0, 0]),
        ((7, 0, 0, 0, 1, 0), ['allow-request', 5, 0, 0]),
    ]
    for args, expected in cases:
        s.action(1179, *args)
        assert last(s, 'test.combat-reaction') == expected
    for strength, language, intruders, expected in [(5, 1, 0, 5), (-5, 0, 1, -9), (0, 0, 0, -2), (0, 1, 1, -2)]:
        s.action(1180, strength, language, intruders)
        assert last(s, 'test.combat-reaction-modifier') == [expected]


def test_social_status(s):
    for level, bonus in [(0, 0), (1, 0), (2, 1), (4, 1), (5, 2), (7, 2), (8, 3), (9, 3)]:
        s.action(1170, level, 0)
        assert last(s, 'test.rank-table') == [level * 5, bonus]
        s.action(1170, level, 1)
        assert last(s, 'test.rank-table') == [level * 10, level]

    for subject, observer, known, friendly, resentment, expected in [
            (3, 1, 1, 0, 0, 2), (3, 0, 1, 0, 0, 3), (3, 0, 0, 0, 0, 0),
            (3, 0, 1, 0, 1, 0), (1, 5, 1, 1, 0, 0), (1, 5, 1, 0, 0, -4),
            (-2, 8, 1, 1, 0, -4), (-2, -1, 1, 0, 0, -1), (2, 2, 1, 0, 0, 0)]:
        s.action(1167, subject, observer, known, friendly, resentment)
        assert last(s, 'test.status-reaction') == [expected]
    s.action(1168)
    assert last(s, 'test.status-context') == [15, 3, 0, 0, -10, -2]


def test_money_exchange(s):
    initial = exchange_state(s)
    assert initial == [0, 5, 0, 0, 0]
    s.action(1165)
    assert last(s, 'test.exchange') == ['ready', 2, 4000]
    assert exchange_state(s) == initial
    s.action(1166)
    assert last(s, 'test.exchange-gates') == [
        'money-exchange-unapproved', 'money-exchange-points', 1000, 10, 10, 0,
        'reused', 1000, 'money-exchange-points', 'money-exchange-money-limit']
    s.action(1100, 26)
    assert exchange_state(s) == initial
    s.action(1100, 25)
    assert exchange_state(s) == [4000, 3, 1, 0, 0]
    s.command('undo')
    assert exchange_state(s) == initial
    s.action(1100, 25); s.action(1100, 25)
    assert last(s, 'test.exchange') == ['reused', 0, 0]
    assert exchange_state(s) == [4000, 3, 1, 0, 0]


def monthly_state(s):
    s.action(1161)
    return last(s, 'test.monthly-state')


def test_monthly_finance(s):
    initial = monthly_state(s)
    assert initial == [0, 0, 0, 0, 0]
    s.action(1162)
    assert last(s, 'test.monthly-preview') == ['ready', 600]
    assert monthly_state(s) == initial
    s.action(1163)
    assert last(s, 'test.monthly-gates') == [
        -2, 400, 'monthly-finance-not-due', 'monthly-debt-unaffordable',
        'monthly-default-consequence-required', 'defaulted', 0, 1, 'reused',
        'monthly-finance-period-gap', -400, 100, 'monthly-debt-without-wealth',
        'monthly-finance-fractional-money']
    s.action(1100, 24)
    assert monthly_state(s) == initial
    s.action(1100, 23)
    assert monthly_state(s) == [600, 1, 1, 0, 0]
    s.action(1100, 23)
    assert last(s, 'test.monthly-payment') == ['reused', 0]
    assert monthly_state(s) == [600, 1, 1, 0, 0]


def test_monthly_undo(s):
    initial = monthly_state(s)
    s.action(1100, 23)
    s.command('undo')
    assert monthly_state(s) == initial


def test_starting_wealth(s):
    for tl, amount in enumerate([250, 500, 750, 1000, 2000, 5000, 10000,
                                 15000, 20000, 30000, 50000, 75000, 100000]):
        s.action(1155, tl, 'average', 0)
        assert last(s, 'test.wealth-table') == [amount, 0]
    for level, extra, amount, cost in [
            ('none', 0, 0, -25), ('poor', 0, 4000, -15), ('struggling', 0, 10000, -10),
            ('comfortable', 0, 40000, 10), ('wealthy', 0, 100000, 20),
            ('very-wealthy', 0, 400000, 30), ('filthy-rich', 0, 2000000, 50),
            ('multimillionaire', 1, 20000000, 75), ('multimillionaire', 3, 2000000000, 125)]:
        s.action(1155, 8, level, extra)
        assert last(s, 'test.wealth-table') == [amount, cost]
    initial = wealth_state(s)
    s.action(1157)
    assert last(s, 'test.wealth-preview') == ['ready', 20000, 4000, 16000]
    assert wealth_state(s) == initial
    s.action(1158)
    assert last(s, 'test.wealth-gates') == [
        'mobile-wealth-unapproved', 200, 'starting-wealth-opening-balance',
        'starting-wealth-creation-only', 'wealth-value-limit']
    s.action(1100, 22)
    assert wealth_state(s) == initial
    s.action(1100, 21)
    funded = wealth_state(s)
    assert funded == [4000, 20000, 4000, 16000, 0, 0]
    s.command('undo')
    assert wealth_state(s) == initial
    s.action(1100, 21); s.action(1100, 21)
    assert last(s, 'test.wealth-allocation') == ['reused', None, 4000]
    assert wealth_state(s) == funded


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
    for check in [test_numbers,test_employment_wealth_payroll,test_employment_wealth_transactions,test_employment_wealth_priority,test_employment_wealth_requirements,test_wealth_advancement,test_wealth_advancement_sequence,test_skill_definition_gates,test_negative_pricing,test_technique_bases,test_learning_requirements,test_familiarity,test_technology_modifiers,test_optional_specialties,test_relative_skill,test_technology_learning,test_recognition,test_recognition_failure,test_recognition_similarity,test_template_composition,test_template_technology,test_template_choices,test_template_score_options,test_extended_measurements,test_equipment_quality,test_starting_equipment_price,test_acquisition,test_equipment_storage,test_legal_access,test_control_table,test_control_question,test_control_certain,test_starting_wealth,test_monthly_finance,test_monthly_undo,test_money_exchange,test_social_structure,test_reputation,test_reputation_failure,test_reaction_encounter,test_information_delivery,test_paid_information,test_uncertain_knowledge,test_unknown_fact,test_trade_transfer,test_loyalty,test_loyalty_automatic,test_loyalty_failure,test_loyalty_danger,test_loyalty_performance,test_loyalty_botched,test_loyalty_forgiveness,test_loyalty_forgiveness_low,test_service_anniversary,test_service_failure,test_service_automatic,test_rescue_loyalty,test_rescue_no_decrease,test_rescue_ungrateful,test_rescue_sacrifice,test_loyalty_pay,test_job_qualifications,test_job_month,test_job_demotion,test_job_dismissal,test_job_variable_month,test_household_payment,test_hire_payroll,test_hire_payroll_unfunded,test_hire_candidate,test_recruiting_search,test_recruiting_legal_consequence,test_employment_acceptance,test_job_search_batch,test_job_seeking,test_study,test_history]:
        fresh(Session,bundle,check)
        print(f'  expanded {check.__name__}: passed',flush=True)
    social = build.build('expanded-social',ROOT / 'tests/fixtures/expanded-social.t')
    fresh(Session,social,test_social_status)
    fresh(Session,social,test_combat_reactions)
    fresh(Session,social,test_aid_reactions)
    fresh(Session,social,test_information_reactions)
    fresh(Session,social,test_trade_reactions)
    fresh(Session,social,test_trade_modifiers)
    exploration = build.build('expanded-exploration',ROOT / 'tests/fixtures/expanded-exploration.t')
    fresh(Session,exploration,test_breath_duration)
    fresh(Session,exploration,test_swimming_assessments)
    fresh(Session,exploration,test_swimming_encounter)
    fresh(Session,exploration,test_swimming_context)
    fresh(Session,exploration,test_swimming_movement_endurance)
    fresh(Session,exploration,test_swimming_owned_endurance)
    swimming_transactions = build.build('expanded-swimming-transactions',ROOT / 'tests/fixtures/expanded-swimming-transactions.t')
    fresh(Session,swimming_transactions,test_swimming_transactions)
    test_swimming_persistence(Session,swimming_transactions,build.out)
    fresh(Session,exploration,test_breath_reserve)
    breath_transactions = build.build('expanded-breath-transactions',ROOT / 'tests/fixtures/expanded-breath-transactions.t')
    fresh(Session,breath_transactions,test_breath_transactions)
    fresh(Session,breath_transactions,test_breath_expired_transactions)
    test_breath_persistence(Session,breath_transactions,build.out)
    combat = build.build('expanded-combat',ROOT / 'tests/fixtures/expanded-combat.t')
    fresh(Session,combat,test_rapid_fire_assessments)
    fresh(Session,combat,test_combat_check_classification)
    fresh(Session,combat,test_critical_hit_assessments)
    fresh(Session,combat,test_weapon_miss_assessments)
    fresh(Session,combat,test_unarmed_miss_assessments)
    purchase = build.build('expanded-software-purchase',ROOT / 'tests/fixtures/expanded-software-purchase.t')
    fresh(Session,purchase,test_software_purchase)
    test_software_purchase_persistence(Session,purchase,build.out)
    software = build.build('expanded-software',ROOT / 'tests/fixtures/expanded-software.t')
    test_software_task_support(Session,software)
    test_software_requirements(Session,software)
    computer = build.build('expanded-computer',ROOT / 'tests/fixtures/expanded-computer.t')
    fresh(Session,computer,test_computer_reservations)
    fresh(Session,computer,test_terminal_switches)
    fresh(Session,computer,test_computer_storage)
    fresh(Session,computer,test_computer_links)
    fresh(Session,computer,test_computer_transfers)
    fresh(Session,computer,test_computer_recording)
    fresh(Session,computer,test_remote_terminal)
    test_remote_terminal_persistence(Session,computer,build.out)
    test_computer_recording_persistence(Session,computer,build.out)
    test_computer_transfer_persistence(Session,computer,build.out)
    test_computer_link_persistence(Session,computer,build.out)
    test_computer_storage_persistence(Session,computer,build.out)
    test_computer_persistence(Session,computer,build.out)
    maintenance_price = build.build('expanded-maintenance-price',ROOT / 'tests/fixtures/expanded-maintenance-price.t')
    fresh(Session,maintenance_price,test_maintenance_prices)
    breakdown = build.build('expanded-breakdown',ROOT / 'tests/fixtures/expanded-breakdown.t')
    fresh(Session,breakdown,test_breakdown_transactions)
    fresh(Session,breakdown,test_repair_prices)
    fresh(Session,breakdown,test_major_repair_parts)
    fresh(Session,breakdown,test_major_parts_preflight)
    test_major_parts_persistence(Session,breakdown,build.out)
    fresh(Session,breakdown,test_breakdown_repair)
    test_breakdown_repair_persistence(Session,breakdown,build.out)
    fresh(Session,breakdown,test_breakdown_days)
    test_breakdown_persistence(Session,breakdown,build.out)
    invention = build.build('expanded-invention',ROOT / 'tests/fixtures/expanded-invention.t')
    test_device_analysis(Session,invention)
    test_rapid_materials(Session,invention)
    test_rapid_starts(Session,invention)
    fresh(Session,invention,test_rapid_salvage)
    fresh(Session,invention,test_rapid_salvage_failed_search)
    fresh(Session,invention,test_rapid_search)
    fresh(Session,invention,test_rapid_search_failure)
    test_rapid_purchases(Session,invention)
    fresh(Session,invention,test_rapid_concepts)
    fresh(Session,invention,test_rapid_concept_retry)
    test_cinematic_tools(Session,invention)
    test_cinematic_prototype_persistence(Session,invention,build.out)
    test_cinematic_prototypes(Session,invention)
    fresh(Session,invention,test_cinematic_concepts)
    fresh(Session,invention,test_cinematic_advanced_concept)
    test_cinematic_concept_persistence(Session,invention,build.out)
    fresh(Session,invention,test_production_order)
    fresh(Session,invention,test_production_order_line)
    test_production_order_persistence(Session,invention,build.out)
    fresh(Session,invention,test_production_line)
    test_production_line_persistence(Session,invention,build.out)
    fresh(Session,invention,test_prototype_testing)
    test_prototype_testing_outcomes(Session,invention)
    test_prototype_testing_persistence(Session,invention,build.out)
    fresh(Session,invention,test_prototype_operation)
    test_prototype_operation_boundaries(Session,invention)
    test_prototype_operation_persistence(Session,invention,build.out)
    fresh(Session,invention,test_prototype_defects)
    test_prototype_defects_persistence(Session,invention,build.out)
    fresh(Session,invention,test_prototype_completion)
    test_prototype_completion_outcomes(Session,invention)
    test_prototype_completion_persistence(Session,invention,build.out)
    fresh(Session,invention,test_prototype_accident)
    fresh(Session,invention,test_prototype_accident_protection)
    test_prototype_accident_persistence(Session,invention,build.out)
    fresh(Session,invention,test_prototype_work)
    test_prototype_work_persistence(Session,invention,build.out)
    fresh(Session,invention,test_prototype_start)
    fresh(Session,invention,test_prototype_start_calendar)
    test_prototype_start_persistence(Session,invention,build.out)
    fresh(Session,invention,test_invention_blueprints)
    test_invention_blueprint_persistence(Session,invention,build.out)
    fresh(Session,invention,test_invention_facilities)
    fresh(Session,invention,test_invention_facilities_reuse)
    test_invention_facilities_persistence(Session,invention,build.out)
    fresh(Session,invention,test_invention_concept)
    test_invention_theories(Session,invention)
    test_invention_concept_persistence(Session,invention,build.out)
    psionics = build.build('expanded-psionics',ROOT / 'tests/fixtures/expanded-psionics.t')
    fresh(Session,psionics,test_psionic_talents)
    test_psionic_warning(Session,psionics)
    test_psionic_advancement(Session,psionics)
    test_psionic_purchase(Session,psionics,build.out)
    test_psionic_history(Session,psionics)
    test_history_purchase(Session,psionics)
    test_psionic_resistance(Session,psionics)
    fresh(Session,psionics,test_psionic_static)
    static_ready = build.build('expanded-static-ready',ROOT / 'tests/fixtures/expanded-static-ready.t')
    fresh(Session,static_ready,test_static_ready)
    test_static_health_defaults(Session,static_ready)
    creatures = build.build('expanded-creatures',ROOT / 'tests/fixtures/expanded-creatures.t')
    swarms = build.build('expanded-swarms',ROOT / 'tests/fixtures/expanded-swarms.t')
    test_swarm_attacks(Session,swarms)
    test_swarm_counterattacks(Session,swarms)
    test_swarm_persistence(Session,swarms,build.out)
    test_swarm_exposure_persistence(Session,creatures,build.out)
    test_swarm_protection(Session,creatures)
    fresh(Session,creatures,test_animal_strength_damage)
    fresh(Session,creatures,test_animal_natural_damage)
    fresh(Session,creatures,test_animal_values)
    test_learned_animal_tasks(Session,creatures)
    test_animal_milestones(Session,creatures)
    fresh(Session,creatures,test_animal_daily)
    test_animal_daily_failure(Session,creatures)
    test_animal_session_persistence(Session,creatures,build.out)
    fresh(Session,creatures,test_animal_sessions)
    test_animal_performance(Session,creatures)
    fresh(Session,creatures,test_animal_handling)
    test_animal_handling_modifiers(Session,creatures)
    fresh(Session,creatures,test_animal_training_tables)
    test_animal_training_plans(Session,creatures)
    technology = build.build('expanded-technology',ROOT / 'tests/fixtures/expanded-technology.t')
    test_inventor_permission(Session,technology)
    fresh(Session,technology,test_cinematic_invention_assessments)
    fresh(Session,technology,test_production_assessments)
    fresh(Session,technology,test_prototype_assessments)
    test_invention_proposals(Session,technology)
    fresh(Session,technology,test_broken_weapons)
    fresh(Session,technology,test_object_capacity)
    fresh(Session,technology,test_object_injury_thresholds)
    shield_ready = build.build('expanded-shield-ready',ROOT / 'tests/fixtures/expanded-shield-ready.t')
    fresh(Session,shield_ready,test_shield_ready)
    fresh(Session,shield_ready,test_shield_ready_health)
    test_shield_ready_routes(Session,shield_ready)
    test_shield_ready_persistence(Session,shield_ready,build.out)
    combat_drop = build.build('expanded-combat-drop',ROOT / 'tests/fixtures/expanded-combat-drop.t')
    fresh(Session,combat_drop,test_critical_drop_transactions)
    fresh(Session,combat_drop,test_weapon_miss_drop)
    test_weapon_miss_drop_persistence(Session,combat_drop,build.out)
    fresh(Session,combat_drop,test_critical_readiness)
    fresh(Session,combat_drop,test_critical_defense_failures)
    test_critical_readiness_persistence(Session,combat_drop,build.out)
    test_critical_drop_persistence(Session,combat_drop,build.out)
    hazards = build.build('expanded-hazards',ROOT / 'tests/fixtures/expanded-hazards.t')
    fresh(Session,hazards,test_infection_assessments)
    fresh(Session,hazards,test_radiation_tables)
    fresh(Session,hazards,test_radiation_shielding)
    radiation = build.build('expanded-radiation', ROOT / 'tests/fixtures/expanded-radiation.t')
    test_radiation_doses(Session, radiation, build.out)
    test_radiation_exposures(Session, radiation)
    test_fractional_radiation(Session, radiation, build.out)
    radiation_traits = build.build('expanded-radiation-traits', ROOT / 'tests/fixtures/expanded-radiation-traits.t')
    test_radiation_traits(Session, radiation_traits)
    radiation_prevention = build.build('expanded-radiation-prevention', ROOT / 'tests/fixtures/expanded-radiation-prevention.t')
    test_radiation_prevention(Session, radiation_prevention, build.out)
    radiation_treatment = build.build('expanded-radiation-treatment', ROOT / 'tests/fixtures/expanded-radiation-treatment.t')
    test_radiation_treatment(Session, radiation_treatment, build.out)
    fallout = build.build('expanded-fallout', ROOT / 'tests/fixtures/expanded-fallout.t')
    test_fallout_treatment(Session, fallout, build.out)
    radiation_check = build.build('expanded-radiation-check', ROOT / 'tests/fixtures/expanded-radiation-check.t')
    test_radiation_checks(Session, radiation_check, build.out)
    pain = build.build('expanded-pain-sensitivity', ROOT / 'tests/fixtures/expanded-pain-sensitivity.t')
    test_pain_sensitivity(Session, pain, build.out)
    radiation_burn = build.build('expanded-radiation-burn', ROOT / 'tests/fixtures/expanded-radiation-burn.t')
    test_radiation_burns(Session, radiation_burn, build.out)
    terminal = build.build('expanded-terminal-condition', ROOT / 'tests/fixtures/expanded-terminal-condition.t')
    test_terminal_condition(Session, terminal, build.out)
    radiation_recovery = build.build('expanded-radiation-recovery', ROOT / 'tests/fixtures/expanded-radiation-recovery.t')
    test_radiation_recovery(Session, radiation_recovery, build.out)
    nausea = build.build('expanded-nausea', ROOT / 'tests/fixtures/expanded-nausea.t')
    test_nausea_episodes(Session, nausea, build.out)
    nausea_trigger = build.build('expanded-nausea-trigger', ROOT / 'tests/fixtures/expanded-nausea-trigger.t')
    test_nausea_triggers(Session, nausea_trigger, build.out)
    nausea_motion = build.build('expanded-nausea-motion', ROOT / 'tests/fixtures/expanded-nausea-motion.t')
    test_nausea_motion(Session, nausea_motion, build.out)
    clotting = build.build('expanded-impaired-clotting', ROOT / 'tests/fixtures/expanded-impaired-clotting.t')
    fresh(Session, clotting, test_impaired_clotting)
    clotting_loss = build.build('expanded-clotting-loss', ROOT / 'tests/fixtures/expanded-clotting-loss.t')
    test_clotting_loss(Session, clotting_loss, build.out)
    clotting_care = build.build('expanded-clotting-care', ROOT / 'tests/fixtures/expanded-clotting-care.t')
    test_clotting_care(Session, clotting_care, build.out)
    surgical_assessment = build.build('expanded-surgical-assessment', ROOT / 'tests/fixtures/expanded-surgical-assessment.t')
    test_surgical_training_assessment(Session, surgical_assessment)
    surgical_operation = build.build('expanded-surgical-operation', ROOT / 'tests/fixtures/expanded-surgical-operation.t')
    test_surgical_operation(Session, surgical_operation, build.out)
    lasting_repair = build.build('expanded-lasting-repair', ROOT / 'tests/fixtures/expanded-lasting-repair.t')
    test_lasting_repair(Session, lasting_repair, build.out)
    surgical_infection = build.build('expanded-surgical-infection', ROOT / 'tests/fixtures/expanded-surgical-infection.t')
    test_surgical_infection(Session, surgical_infection, build.out)
    mortal_stabilization = build.build('expanded-mortal-stabilization', ROOT / 'tests/fixtures/expanded-mortal-stabilization.t')
    test_mortal_stabilization(Session, mortal_stabilization, build.out)
    trauma_maintenance = build.build('expanded-trauma-maintenance', ROOT / 'tests/fixtures/expanded-trauma-maintenance.t')
    test_trauma_maintenance(Session, trauma_maintenance, build.out)
    mortal_suspension = build.build('expanded-mortal-suspension', ROOT / 'tests/fixtures/expanded-mortal-suspension.t')
    test_mortal_suspension(Session, mortal_suspension, build.out)
    mortal_recovery = build.build('expanded-mortal-recovery', ROOT / 'tests/fixtures/expanded-mortal-recovery.t')
    test_mortal_recovery(Session, mortal_recovery)
    recovery_wound = build.build('expanded-recovery-wound', ROOT / 'tests/fixtures/expanded-recovery-wound.t')
    test_recovery_wound(Session, recovery_wound, build.out)
    persistent_dressing = build.build('expanded-persistent-dressing', ROOT / 'tests/fixtures/expanded-persistent-dressing.t')
    test_persistent_dressing(Session, persistent_dressing, build.out)
    poison_entry = build.build('expanded-poison-entry', ROOT / 'tests/fixtures/expanded-poison-entry.t')
    test_poison_entry(Session, poison_entry)
    poison_exposure = build.build('expanded-poison-exposure', ROOT / 'tests/fixtures/expanded-poison-exposure.t')
    test_poison_exposure(Session, poison_exposure, build.out)
    coughing = build.build('expanded-coughing', ROOT / 'tests/fixtures/expanded-coughing.t')
    test_coughing(Session, coughing, build.out)
    temporary_blindness = build.build('expanded-temporary-blindness', ROOT / 'tests/fixtures/expanded-temporary-blindness.t')
    test_temporary_blindness(Session, temporary_blindness, build.out)
    clotting_restoration = build.build('expanded-clotting-restoration', ROOT / 'tests/fixtures/expanded-clotting-restoration.t')
    test_clotting_restoration(Session, clotting_restoration, build.out)
    fresh(Session,hazards,test_airless_seconds)
    fresh(Session,hazards,test_resuscitation_assessment)
    fresh(Session,hazards,test_cardiac_condition)
    fresh(Session,hazards,test_cardiac_resuscitation)
    fresh(Session,hazards,test_exhaustion_assessments)
    fresh(Session,hazards,test_owned_effort)
    fresh(Session,hazards,test_action_gate)
    fresh(Session,hazards,test_health_maneuver)
    fresh(Session,hazards,test_fatigue_strength)
    fresh(Session,hazards,test_collapse_defense)
    maneuver_transactions = build.build('expanded-maneuver-transactions',ROOT / 'tests/fixtures/expanded-maneuver-transactions.t')
    fresh(Session,maneuver_transactions,test_maneuver_transactions)
    test_maneuver_route_parity(Session,maneuver_transactions)
    test_maneuver_persistence(Session,maneuver_transactions,build.out)
    fresh(Session,hazards,test_effort_recovery)
    effort_transactions = build.build('expanded-effort-transactions',ROOT / 'tests/fixtures/expanded-effort-transactions.t')
    fresh(Session,effort_transactions,test_effort_transactions)
    test_effort_persistence(Session,effort_transactions,build.out)
    cardiac_transactions = build.build('expanded-cardiac-transactions',ROOT / 'tests/fixtures/expanded-cardiac-transactions.t')
    fresh(Session,cardiac_transactions,test_cardiac_transactions)
    fresh(Session,cardiac_transactions,test_cardiac_clock)
    fresh(Session,cardiac_transactions,test_cardiac_clock_batch)
    test_cardiac_clock_batch_persistence(Session,cardiac_transactions,build.out)
    fresh(Session,cardiac_transactions,test_cardiac_clock_revival)
    fresh(Session,cardiac_transactions,test_cardiac_clock_immunity)
    test_cardiac_clock_persistence(Session,cardiac_transactions,build.out)
    fresh(Session,cardiac_transactions,test_cardiac_deadline_transactions)
    test_cardiac_persistence(Session,cardiac_transactions,build.out)
    fresh(Session,hazards,test_airless_duration)
    fresh(Session,hazards,test_airless_scheduler_conflict)
    airless_transactions = build.build('expanded-airless-transactions',ROOT / 'tests/fixtures/expanded-airless-transactions.t')
    fresh(Session,airless_transactions,test_airless_transactions)
    fresh(Session,airless_transactions,test_airless_brain_transactions)
    fresh(Session,airless_transactions,test_airless_breath_conflict)
    test_airless_persistence(Session,airless_transactions,build.out)
    test_airless_brain_persistence(Session,airless_transactions,build.out)
    fresh(Session,hazards,test_infection_acquisition)
    fresh(Session,hazards,test_specific_natural_immunity)
    fresh(Session,hazards,test_infection_supervision)
    fresh(Session,hazards,test_aging_assessments)
    fresh(Session,hazards,test_aging_sequence)
    fresh(Session,hazards,test_aging_events)
    fresh(Session,hazards,test_cold_assessments)
    fresh(Session,hazards,test_cold_intervals)
    fresh(Session,hazards,test_cold_overflow)
    fresh(Session,hazards,test_heat_assessments)
    fresh(Session,hazards,test_thermal_shock_assessments)
    fresh(Session,hazards,test_immersion_intervals)
    fresh(Session,hazards,test_immersion_overflow)
    fresh(Session,hazards,test_immersion_scheduler_conflict)
    immersion_transactions = build.build('expanded-immersion-transactions',ROOT / 'tests/fixtures/expanded-immersion-transactions.t')
    fresh(Session,immersion_transactions,test_immersion_transactions)
    test_immersion_persistence(Session,immersion_transactions,build.out)
    cold_transactions = build.build('expanded-cold-transactions',ROOT / 'tests/fixtures/expanded-cold-transactions.t')
    fresh(Session,cold_transactions,test_cold_transactions)
    test_cold_persistence(Session,cold_transactions,build.out)
    fresh(Session,hazards,test_rejuvenation)
    aging_transactions = build.build('expanded-aging-transactions',ROOT / 'tests/fixtures/expanded-aging-transactions.t')
    fresh(Session,aging_transactions,test_rejuvenation_transactions)
    test_rejuvenation_persistence(Session,aging_transactions,build.out)
    fresh(Session,aging_transactions,test_aging_transactions)
    fresh(Session,aging_transactions,test_aging_death_transactions)
    test_aging_persistence(Session,aging_transactions,build.out)
    fresh(Session,hazards,test_infection_progression)
    hazard_transactions = build.build('expanded-hazards-transactions',ROOT / 'tests/fixtures/expanded-hazards-transactions.t')
    fresh(Session,hazard_transactions,test_immunity_transactions)
    test_immunity_persistence(Session,hazard_transactions,build.out)
    fresh(Session,hazard_transactions,test_infection_transactions)
    test_infection_persistence(Session,hazard_transactions,build.out)
    health = build.build('expanded-health',ROOT / 'tests/fixtures/expanded-health.t')
    fear = build.build('expanded-fear',ROOT / 'tests/fixtures/expanded-fear.t')
    fear_quirks = build.build('expanded-fear-quirks',ROOT / 'tests/fixtures/expanded-fear-quirks.t')
    test_fear_quirks(Session,fear_quirks,build.out)
    quirk_stun = build.build('expanded-fear-quirk-stun',ROOT / 'tests/fixtures/expanded-fear-quirk-stun.t')
    test_fear_quirk_stun(Session,quirk_stun,build.out)
    test_fear_stun(Session,fear)
    test_fear_fatigue(Session,fear)
    test_fear_faint(Session,fear,build.out)
    test_fear_faint_injury(Session,fear,build.out)
    test_fear_fatigue_stun(Session,fear,build.out)
    test_fear_stun_modifiers(Session,fear)
    test_fear_stun_persistence(Session,fear,build.out)
    fear_combat = build.build('expanded-fear-combat',ROOT / 'tests/fixtures/expanded-fear-combat.t')
    test_fear_combat(Session,fear_combat)
    fresh(Session,health,test_fear_assessments)
    fresh(Session,health,test_fear_context)
    fresh(Session,health,test_fear_retching)
    retching = build.build('expanded-retching',ROOT / 'tests/fixtures/expanded-retching.t')
    test_owned_retching(Session,retching)
    test_retching_fatigue(Session,retching)
    test_retching_combat(Session,retching)
    test_retching_meals(Session,retching)
    test_retching_remedy(Session,retching)
    test_remedy_persistence(Session,retching,build.out)
    test_retching_persistence(Session,retching,build.out)
    fresh(Session,health,test_scaled_injury_shock)
    fresh(Session,health,test_scaled_shock_turn_boundary)
    fresh(Session,health,test_bleeding_outcomes)
    bleeding = build.build('expanded-bleeding', ROOT / 'tests/fixtures/expanded-bleeding.t')
    test_bleeding_onset(Session, bleeding, build.out)
    test_bleeding_minutes(Session, bleeding, build.out)
    test_bleeding_aid(Session, bleeding, build.out)
    test_bleeding_bandage(Session, bleeding, build.out)
    test_bleeding_care_boundaries(Session, bleeding, build.out)
    fresh(Session,health,test_knockdown_assessment)
    fresh(Session,health,test_expanded_wound_commit)
    fresh(Session,health,test_critical_major_wound)
    fresh(Session,health,test_knockdown_anatomy_exceptions)
    fresh(Session,health,test_crippling_thresholds)
    fresh(Session,health,test_body_supports)
    fresh(Session,health,test_unarmed_limb_capacity)
    fresh(Session,health,test_crippling_months)
    fresh(Session,health,test_last_wounds_option)
    fresh(Session,health,test_expanded_natural_recovery)
    fresh(Session,health,test_medical_schedule)
    fresh(Session,health,test_physician_outcomes)
    fresh(Session,health,test_expanded_first_aid_values)
    fresh(Session,health,test_expanded_bandage)
    fresh(Session,health,test_bandage_rejections)
    fresh(Session,health,test_first_aid_treatment)
    fresh(Session,health,test_surgery_assessments)
    wounds = build.build('expanded-health-transactions',ROOT / 'tests/fixtures/expanded-health-transactions.t')
    fresh(Session,wounds,test_aid_transactions)
    test_aid_persistence(Session,wounds,build.out)
    fresh(Session,wounds,test_bandage_transactions)
    test_bandage_persistence(Session,wounds,build.out)
    fresh(Session,wounds,test_owned_wound_transactions)
    fresh(Session,wounds,test_critical_major_transactions)
    test_critical_major_persistence(Session,wounds,build.out)
    fresh(Session,wounds,test_limb_wound_transactions)
    fresh(Session,wounds,test_last_wound_transactions)
    test_last_wound_persistence(Session,wounds,build.out)
    fresh(Session,wounds,test_crippling_duration)
    fresh(Session,wounds,test_lasting_recovery)
    fresh(Session,wounds,test_later_crippling_care)
    fresh(Session,wounds,test_later_care_calendar)
    fresh(Session,wounds,test_natural_recovery_transactions)
    fresh(Session,wounds,test_medical_supervision_transactions)
    fresh(Session,wounds,test_physician_check_transactions)
    test_physician_check_persistence(Session,wounds,build.out)
    test_medical_supervision_persistence(Session,wounds,build.out)
    test_natural_recovery_persistence(Session,wounds,build.out)
    test_later_care_persistence(Session,wounds,build.out)
    test_lasting_recovery_persistence(Session,wounds,build.out)
    test_crippling_duration_persistence(Session,wounds,build.out)
    fresh(Session,wounds,test_limb_grip_retention)
    test_limb_grip_persistence(Session,wounds,build.out)
    test_limb_wound_persistence(Session,wounds,build.out)
    fresh(Session,wounds,test_knockdown_equipment_drop)
    fresh(Session,wounds,test_knockdown_equipment_retained)
    test_knockdown_drop_persistence(Session,wounds,build.out)
    test_owned_wound_persistence(Session,wounds,build.out)
    minimal = build.build('expanded-campaign',ROOT / 'tests/fixtures/expanded-campaign.t')
    fresh(Session,minimal,test_campaign_minimal)
    fresh(Session,minimal,test_job_earnings)
    fresh(Session,minimal,test_lifestyle_prices)
    fresh(Session,minimal,test_employment_market)
    test_employment_wealth_persistence(Session,bundle,build.out)
    test_wealth_advancement_persistence(Session,bundle,build.out)
    test_hire_candidate_persistence(Session,bundle,build.out)
    test_employment_acceptance_persistence(Session,bundle,build.out)
    test_job_search_persistence(Session,bundle,build.out)
    test_living_persistence(Session,bundle,build.out)
    test_trade_persistence(Session,bundle,build.out)
    test_reputation_persistence(Session,bundle,build.out)
    test_equipment_persistence(Session,bundle,build.out)
    test_recognition_persistence(Session,bundle,build.out)
    test_familiarity_persistence(Session,bundle,build.out)
    test_persistence(Session,bundle,build.out)
    print('  expanded cross-process persistence: passed',flush=True)
    tactical = build.build('expanded-tactical', ROOT / 'tests/fixtures/expanded-tactical.t')
    fresh(Session, tactical, test_tactical_geometry)
    fresh(Session, tactical, test_tactical_movement_values)
    paths = build.build('expanded-tactical-path', ROOT / 'tests/fixtures/expanded-tactical-path.t')
    test_tactical_paths(Session, paths)
    positions = build.build('expanded-tactical-positions', ROOT / 'tests/fixtures/expanded-tactical-positions.t')
    fresh(Session, positions, test_tactical_positions)
    fresh(Session, positions, test_tactical_footprints)
    posture = build.build('expanded-tactical-posture', ROOT / 'tests/fixtures/expanded-tactical-posture.t')
    fresh(Session, posture, test_tactical_posture_maneuvers)
    posture_health = build.build('expanded-tactical-posture-health', ROOT / 'tests/fixtures/expanded-tactical-posture-health.t')
    test_tactical_posture_health(Session, posture_health, build.out)
    test_tactical_footprint_persistence(Session, positions, build.out)
    test_tactical_position_persistence(Session, positions, build.out)
    example = build.build('expanded-example',ROOT / 'examples/expanded/main.t')
    test_example(Session,example)
    print('  expanded example parser/action/dialogue parity: passed',flush=True)


def test_tactical_geometry(s):
    # Explicit clockwise diagram neighbors; rotate facing through all six headings.
    neighbors = [(1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)]
    sides = ['front', 'front', 'right', 'back', 'left', 'front']
    for facing in range(6):
        for heading, (q, r) in enumerate(neighbors):
            side = sides[(heading - facing) % 6]
            for hand in (0, 1):
                s.action(2270, facing, q, r, hand)
                weapon = side == ('right' if hand == 0 else 'left')
                shield = side == ('left' if hand == 0 else 'right')
                assert last(s, 'test.tactical-facing') == [
                    'ready', None, heading, side, weapon or None, shield or None]
    for q, r in [(0, 0), (2, 0), (-2, 1)]:
        s.action(2270, 0, q, r, 0)
        assert last(s, 'test.tactical-facing') == [
            'blocked', 'tactical-adjacent-required', None, None, None, None]
    for coords, distance in [((0, 0, 0, 0), 0), ((0, 0, 3, 0), 3),
                             ((0, 0, 2, 2), 4), ((0, 0, -2, 2), 2),
                             ((-4, 3, 2, -1), 6),
                             ((-1000000, -1000000, 1000000, 1000000), 4000000)]:
        s.action(2271, *coords)
        assert last(s, 'test.tactical-distance') == [distance, 0, 0]
    for barrier, blocked, evidence, status, reason in [
            (0, 0, 0, 'ready', None), (1, 0, 0, 'ready', None),
            (2, 0, 0, 'blocked', 'tactical-solid-barrier'),
            (1, 1, 0, 'error', 'tactical-partial-ruling-evidence'),
            (1, 1, 1, 'blocked', 'tactical-partial-barrier-ruling')]:
        s.action(2272, barrier, blocked, evidence)
        assert last(s, 'test.tactical-terrain') == [status, reason, 0, 0]


def test_tactical_movement_values(s):
    for move, full, half in [(0, 0, 0), (1, 2, 2), (4, 8, 4), (5, 10, 6), (9, 18, 10)]:
        for maneuver in range(1, 5):
            s.action(2274, move, maneuver)
            assert last(s, 'test.tactical-allowance') == [
                full if maneuver < 3 else half, 2 if maneuver == 3 else 0]
    # Forward diagonal rotates; a front sidestep costs twice as much and keeps facing.
    for heading in (0, 1, 5):
        for mode, cost, final in [(0, 2, heading), (1, 4, 0)]:
            for committed in (0, 1):
                s.action(2275, heading, mode, committed, 1, 0)
                assert last(s, 'test.tactical-entry') == ['ready', None, cost, final, None, 0, 0]
    for heading in (2, 3, 4):
        s.action(2275, heading, 1, 0, 1, 0)
        assert last(s, 'test.tactical-entry') == ['ready', None, 4, 0, None, 0, 0]
        s.action(2275, heading, 1, 1, 1, 0)
        assert last(s, 'test.tactical-entry')[:2] == ['blocked', 'tactical-committed-direction']
        s.action(2275, heading, 0, 0, 1, 0)
        assert last(s, 'test.tactical-entry')[:2] == ['blocked', 'tactical-forward-direction']
    for posture, terrain, cost, whole in [(2, 0, 3, None), (3, 0, 6, None),
                                           (4, 0, 6, None), (5, 0, 0, True),
                                           (1, 1, 6, None), (1, 4, 8, None),
                                           (1, 5, 0, True), (2, 4, 9, None)]:
        s.action(2275, 0, 0, 0, posture, terrain)
        assert last(s, 'test.tactical-entry') == ['ready', None, cost, 0, whole, 0, 0]
    for posture, terrain, reason in [(6, 0, 'tactical-sitting'),
                                     (1, 2, 'tactical-jump-required'),
                                     (1, 3, 'tactical-evasion-required'),
                                     (1, 6, 'tactical-solid-barrier')]:
        s.action(2275, 0, 0, 0, posture, terrain)
        assert last(s, 'test.tactical-entry') == ['blocked', reason, 0, None, None, 0, 0]
    for maneuver in (1, 2):
        s.action(2276, 0, 3, maneuver, 10, 5)  # Exactly half: free half-turn.
        assert last(s, 'test.tactical-final') == ['ready', None, 3, 0]
        s.action(2276, 0, 3, maneuver, 10, 6)
        assert last(s, 'test.tactical-final') == ['blocked', 'tactical-final-facing-limit', None, 0]
        s.action(2276, 0, 5, maneuver, 10, 6)
        assert last(s, 'test.tactical-final') == ['ready', None, 5, 0]
    s.action(2276, 0, 3, 4, 6, 6)
    assert last(s, 'test.tactical-final') == ['ready', None, 3, 0]
    s.action(2276, 0, 1, 3, 6, 0)
    assert last(s, 'test.tactical-final') == ['blocked', 'tactical-committed-final-facing', None, 0]
    for heading, cost in [(0, 0), (1, 2), (2, 4), (3, 6), (4, 4), (5, 2)]:
        for maneuver in (1, 2, 4):
            s.action(2277, 0, heading, maneuver)
            assert last(s, 'test.tactical-turn') == ['ready', None, heading, cost]
    s.action(2277, 0, 3, 3)
    assert last(s, 'test.tactical-turn') == ['blocked', 'tactical-committed-turn-procedure', None, 0]


def tactical_position_state(s):
    s.action(2279)
    return last(s, 'test.tactical-position-state')


def test_tactical_positions(s):
    before = tactical_position_state(s)
    assert before == [0, 0, 0, 0, None, None, 0, 'standing', 0, 0]
    s.action(2278, 1)
    assert last(s, 'test.tactical-placement') == ['ready', None]
    assert tactical_position_state(s) == before
    s.action(2278, 2)
    assert tactical_position_state(s) == before
    s.action(2278, 0)
    assert last(s, 'test.tactical-placement') == ['resolved', None]
    placed = tactical_position_state(s)
    assert placed == [1, 1, 1, 1, 0, 0, 2, 'standing', 0, 0]
    s.command('undo')
    assert tactical_position_state(s) == before
    s.action(2278, 0)
    s.action(2278, 0)
    assert last(s, 'test.tactical-placement') == ['reused', None]
    assert tactical_position_state(s) == placed
    s.action(2280)
    assert last(s, 'test.tactical-occupancy') == ['ready', None, 1]
    s.action(2278, 12)  # A retargeted setup receipt must never move the figure.
    s.action(2278, 0)
    assert last(s, 'test.tactical-placement') == ['error', 'tactical-placement-binding']
    assert tactical_position_state(s) == placed


def test_tactical_position_persistence(Session, bundle, out):
    path = out / 'expanded-tactical-position.zsave'
    first = Session(bundle)
    try:
        first.action(2278, 0)
        saved = tactical_position_state(first)
        first.command(f':save {path}\n@2279')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2279')
        assert tactical_position_state(second) == saved
        second.action(2278, 0)
        assert last(second, 'test.tactical-placement') == ['reused', None]
        assert tactical_position_state(second) == saved
        second.action(2278, 6)
        second.action(2278, 20)
        assert last(second, 'test.tactical-placement') == ['blocked', 'tactical-shared-cell-procedure-required']
        second.action(2278, 7)
        second.action(2280)
        assert last(second, 'test.tactical-occupancy') == ['blocked', 'tactical-footprint-transition-required', 0]
    finally:
        second.close()
    for code, status, reason in [
            (3, 'blocked', 'tactical-solid-barrier'),
            (4, 'blocked', 'tactical-unmapped-cell'),
            (7, 'blocked', 'tactical-footprint-transition-required'),
            (9, 'blocked', 'tactical-placement-evidence'),
            (10, 'error', 'tactical-map-duplicate-cell'),
            (13, 'blocked', 'tactical-body-form-unimplemented')]:
        session = Session(bundle)
        try:
            session.action(2278, code)
            session.action(2278, 0)
            assert last(session, 'test.tactical-placement') == [status, reason]
            assert tactical_position_state(session)[:7] == [0, 0, 0, 0, None, None, 0]
        finally:
            session.close()
    session = Session(bundle)
    try:
        session.action(2278, 5)
        session.action(2278, 0)
        assert tactical_position_state(session)[4:6] == [0, -1]
        session.action(2278, 20)
        assert tactical_position_state(session)[:2] == [2, 2]
        session.action(2278, 11)
        session.action(2278, 21)
        assert last(session, 'test.tactical-placement') == ['error', 'tactical-placement-binding']
    finally:
        session.close()


def tactical_footprint_state(s):
    s.action(2281)
    return last(s, 'test.tactical-footprint-state')


def test_tactical_footprints(s):
    s.action(2278, 0)
    upright = tactical_footprint_state(s)
    assert upright == ['standing', 0, 0, None, None, 0, 0, 0]
    s.action(2278, 31)
    assert last(s, 'test.tactical-footprint') == ['blocked', 'tactical-posture-not-committed']
    assert tactical_footprint_state(s) == upright
    s.action(2278, 32)
    assert tactical_footprint_state(s) == upright
    s.action(2278, 30)
    prone = tactical_footprint_state(s)
    assert prone == ['lying', 0, 0, 0, -1, 1, 0, 0]
    s.action(2280)
    assert last(s, 'test.tactical-occupancy') == ['ready', None, 1]
    s.action(2282)
    assert last(s, 'test.tactical-upper-occupancy') == ['ready', None, 1]
    s.command('undo')
    assert tactical_footprint_state(s) == upright
    s.action(2278, 30)
    s.action(2278, 39)  # Replay without changing posture.
    assert last(s, 'test.tactical-footprint') == ['reused', None]
    assert tactical_footprint_state(s) == prone
    s.action(2278, 35)
    assert tactical_footprint_state(s) == prone
    s.action(2278, 33)
    risen = tactical_footprint_state(s)
    assert risen == ['kneeling', 0, -1, None, None, 2, 0, 0]
    s.action(2280)
    assert last(s, 'test.tactical-occupancy') == ['ready', None, 0]
    s.action(2282)
    assert last(s, 'test.tactical-upper-occupancy') == ['ready', None, 1]
    s.action(2278, 39)
    assert last(s, 'test.tactical-footprint') == ['reused', None]
    assert tactical_footprint_state(s) == risen


def test_tactical_footprint_persistence(Session, bundle, out):
    path = out / 'expanded-tactical-footprint.zsave'
    first = Session(bundle)
    try:
        first.action(2278, 0)
        first.action(2278, 30)
        saved = tactical_footprint_state(first)
        first.command(f':save {path}\n@2281')
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@2281')
        assert tactical_footprint_state(second) == saved
        second.action(2278, 39)
        assert tactical_footprint_state(second) == saved
        second.action(2278, 38)
        second.action(2278, 33)
        assert tactical_footprint_state(second) == ['kneeling', 0, 0, None, None, 2, 0, 0]
    finally:
        second.close()
    session = Session(bundle)
    try:
        session.action(2278, 0)
        session.action(2278, 20)
        session.action(2278, 36)
        session.action(2278, 7)
        session.action(2278, 31)
        assert last(session, 'test.tactical-footprint') == ['blocked', 'tactical-shared-cell-procedure-required']
        assert tactical_footprint_state(session) == ['lying', 0, 0, None, None, 0, 0, 0]
    finally:
        session.close()


def test_tactical_posture_maneuvers(s):
    s.action(2278, 50)
    before = tactical_footprint_state(s)
    s.action(2278, 58)
    assert last(s, 'test.posture-preview') == [None]
    assert tactical_footprint_state(s) == before
    s.action(2278, 55)
    assert tactical_footprint_state(s) == before
    s.action(2278, 51)
    assert last(s, 'test.posture-battle') == ['resolved', None]
    assert tactical_footprint_state(s) == ['lying', 0, 0, 0, -1, 1, 0, 0]
    s.command('undo')
    assert tactical_footprint_state(s) == before
    s.action(2278, 51)
    s.action(2278, 52)
    assert tactical_footprint_state(s)[-2:] == [1, 0]
    s.action(2278, 54)
    assert last(s, 'test.posture-battle') == ['blocked', 'invalid-posture-change']
    s.action(2278, 53)
    assert last(s, 'test.posture-battle') == ['resolved', None]
    assert tactical_footprint_state(s) == ['kneeling', 0, -1, None, None, 2, 1, 0]
    s.action(2278, 52)
    s.action(2278, 54)
    assert last(s, 'test.posture-battle') == ['resolved', None]
    assert tactical_footprint_state(s) == ['standing', 0, -1, None, None, 2, 2, 0]


def test_tactical_posture_health(Session, bundle, out):
    def health(s):
        s.action(2283)
        return last(s, 'test.posture-health-state')
    for injured in (False, True):
        s = Session(bundle)
        try:
            s.action(2278, 50)
            s.action(2278, 57)  # FP zero.
            if injured:
                s.action(2278, 60)  # HP zero: Will and HT must each resolve once.
            s.action(2278, 61)
            before = tactical_footprint_state(s), health(s)
            s.action(2278, 65)
            assert last(s, 'test.posture-health-preview') == [None]
            assert (tactical_footprint_state(s), health(s)) == before
            s.action(2278, 55)
            assert (tactical_footprint_state(s), health(s)) == before
            s.action(2278, 51)
            assert last(s, 'test.posture-battle') == ['resolved', None]
            expected_draws = 6 if injured else 3
            assert health(s) == [1, True, 0, 10, 2, 0, 0, expected_draws]
            assert tactical_footprint_state(s)[:6] == ['lying', 0, 0, 0, -1, 1]
            s.command('undo')
            assert (tactical_footprint_state(s), health(s)) == before
            s.action(2278, 51)
            path = out / f'tactical-posture-health-{injured}.zsave'
            saved = tactical_footprint_state(s), health(s)
            s.command(f':save {path}\n@2283')
        finally:
            s.close()
        restored = Session(bundle)
        try:
            restored.command(f':restore {path}\n@2283')
            assert (tactical_footprint_state(restored), health(restored)) == saved
            restored.action(2278, 65)
            assert last(restored, 'test.posture-health-preview') == ['maneuver-health-gate-used']
            assert (tactical_footprint_state(restored), health(restored)) == saved
        finally:
            restored.close()
    s = Session(bundle)
    try:
        s.action(2278, 50)
        s.action(2278, 60)
        s.action(2278, 64)  # HT 3 fails the first roll of ten.
        s.action(2278, 51)
        assert last(s, 'test.posture-battle') == ['resolved', None]
        assert tactical_footprint_state(s)[:6] == ['standing', 0, 0, None, None, 0]
        assert health(s) == [1, None, 1, 0, 2, 0, 0, 3]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2278, 50)
        s.action(2278, 57)
        s.action(2278, 56)  # Occupied upper-body destination blocks before the Will roll.
        before = health(s)
        s.action(2278, 51)
        assert last(s, 'test.posture-battle') == ['blocked', 'tactical-shared-cell-procedure-required']
        assert health(s) == before
    finally:
        s.close()


def test_tactical_paths(Session, bundle):
    cases = [
        ([], [2, 0, 0, 4, 10, 2, None, None]),
        ([77], [1, 1, 1, 4, 10, 2, None, None]),
        ([78], [1, 0, 0, 4, 10, 1, None, None]),
        ([79], [2, 0, 3, 4, 10, 2, None, None]),
        ([80], [2, 0, 0, 6, 6, 2, None, None]),
        ([80, 81], [2, 0, 1, 6, 6, 2, None, None]),
        ([71, 72], [1, 0, 0, 6, 2, 1, True, None]),
        ([73], [2, 0, 0, 6, 10, 2, None, None]),
        ([74, 76], [1, 0, 0, 10, 10, 1, None, True]),
    ]
    for changes, expected in cases:
        s = Session(bundle)
        try:
            s.action(2278, 70)
            initial = tactical_footprint_state(s)
            for code in changes:
                s.action(2278, code)
            s.action(2278, 83)
            assert last(s, 'test.tactical-path') == ['ready', None] + expected + [0, 0]
            # Assessment never installs the assessed destination or changes facing.
            s.action(2279)
            assert last(s, 'test.tactical-position-state')[4:7] == [0, 0, 0]
            assert tactical_footprint_state(s)[1:6] == initial[1:6]
        finally:
            s.close()
    for changes, reason in [([71], 'tactical-path-budget'),
                            ([73, 74], 'tactical-shared-cell-procedure-required'),
                            ([73, 75], 'tactical-evasion-required'),
                            ([76], 'tactical-whole-allowance-path'),
                            ([80, 79], 'tactical-final-facing-limit'),
                            ([82], 'tactical-committed-path-unimplemented')]:
        s = Session(bundle)
        try:
            s.action(2278, 70)
            for code in changes:
                s.action(2278, code)
            assert last(s, 'test.tactical-path')[:2] == ['blocked', reason]
            assert tactical_footprint_state(s)[1:6] == [0, 0, None, None, 0]
        finally:
            s.close()


def test_bleeding_outcomes(s):
    # B420: every full five lost HP adds -1; losses are not rounded up.
    for loss, penalty in [(0, 0), (4, 0), (5, -1), (9, -1), (10, -2), (14, -2), (15, -3)]:
        s.action(2284, 12, loss, 0, 5, 0)
        assert last(s, 'test.bleeding-outcome') == ['ready', None, penalty, 12 + penalty, 0, 1, 0, 0, 0]
    for roll, prior, injury, clear, stop in [(10, 0, 0, 1, 0), (10, 1, 0, 2, 0),
                                           (10, 2, 0, 3, 1), (11, 2, 1, 0, 0),
                                           (18, 2, 3, 0, 0), (3, 0, 0, 1, 1)]:
        s.action(2284, 10, 0, 0, roll, prior)
        assert last(s, 'test.bleeding-outcome') == ['ready', None, 0, 10, injury, clear, stop, 0, 0]
    s.action(2284, 10, 10, 2, 10, 2)
    assert last(s, 'test.bleeding-outcome') == ['ready', None, 0, 10, 0, 3, 1, 0, 0]
    s.action(2284, 3, 5, 0, 3, 0)
    assert last(s, 'test.bleeding-outcome') == ['blocked', 'bleeding-score-unavailable', -1, None, 0, 0, 0, 0, 0]


def test_bleeding_onset(Session, bundle, out):
    def state(s):
        s.action(2286)
        return last(s, 'test.bleeding-state')
    s = Session(bundle)
    path = out / 'expanded-bleeding-onset.zsave'
    try:
        s.action(2285, 0)
        before = state(s)
        assert before == [2, 0, None, None, 0, 0, 0]
        s.action(2285, 2)
        assert last(s, 'test.bleeding-onset') == ['ready', None]
        assert state(s) == before
        s.action(2285, 3)
        assert state(s) == before
        s.action(2285, 1)
        onset = state(s)
        assert onset == [2, 1, 0, 60, 1, 0, 0]
        s.command('undo')
        assert state(s) == before
        s.action(2285, 1)
        s.action(2285, 1)
        assert last(s, 'test.bleeding-onset') == ['reused', None]
        assert state(s) == onset
        s.action(2285, 5)
        assert state(s) == onset
        s.action(2285, 4)
        saved = state(s)
        assert saved == [2, 1, 0, 60, 1, 60, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        assert state(s) == saved
        s.action(2285, 6)
        assert state(s) == saved
        s.action(2285, 1)
        assert last(s, 'test.bleeding-onset') == ['reused', None]
        assert state(s) == saved
    finally:
        s.close()
    for change, reason in [(7, 'bleeding-rule-disabled'), (8, 'bleeding-exception-evidence'),
                           (6, 'bleeding-late-registration')]:
        s = Session(bundle)
        try:
            s.action(2285, 0)
            s.action(2285, change)
            s.action(2285, 1)
            assert last(s, 'test.bleeding-onset') == ['blocked', reason]
            assert state(s)[1] == 0
        finally:
            s.close()


def test_bleeding_minutes(Session, bundle, out):
    def state(s):
        s.action(2287)
        return last(s, 'test.bleeding-minute-state')
    def setup(s):
        for code in (0, 1, 4):
            s.action(2285, code)
    s = Session(bundle)
    path = out / 'expanded-bleeding-minutes.zsave'
    try:
        setup(s)
        before = state(s)
        assert before == [2, 1, 0, 0, None, 60, 60, 0]
        s.action(2285, 21)
        assert last(s, 'test.bleeding-minute')[:2] == ['ready', None]
        assert state(s) == before
        s.action(2285, 22)
        assert state(s) == before
        s.action(2285, 20)
        assert state(s) == [2, 1, 1, 1, None, 120, 60, 3]
        s.command('undo')
        assert state(s) == before
        s.action(2285, 30)
        s.action(2285, 20)
        saved = state(s)
        s.action(2285, 20)
        assert last(s, 'test.bleeding-minute')[:2] == ['reused', None]
        assert state(s) == saved
        s.command(f':save {path}\n@2287')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2287')
        assert state(s) == saved
        s.action(2285, 4)
        s.action(2285, 23)
        assert state(s) == [2, 1, 2, 2, None, 180, 120, 6]
        s.action(2285, 4)
        s.action(2285, 24)
        assert state(s) == [2, 1, 3, 3, 180, 180, 180, 9]
        s.action(2285, 5)
        assert state(s)[6] == 241  # Completed episodes no longer block time.
    finally:
        s.close()
    for change, injury, wounds, streak, stopped in [(26, 5, 2, 0, None),
                                                   (29, 3, 2, 0, None),
                                                   (31, 2, 1, 1, 60)]:
        s = Session(bundle)
        try:
            setup(s)
            s.action(2285, change)
            before = state(s)
            s.action(2285, 22)
            assert state(s) == before
            s.action(2285, 20)
            after = state(s)
            assert after[:5] == [injury, wounds, 1, streak, stopped]
            assert after[-1] == 3
            s.action(2285, 20)
            assert state(s) == after
        finally:
            s.close()
    for change, reason in [(27, 'bleeding-injury-policy-unimplemented'),
                           (28, 'bleeding-loss-basis-required')]:
        s = Session(bundle)
        try:
            setup(s)
            s.action(2285, change)
            before = state(s)
            s.action(2285, 20)
            assert last(s, 'test.bleeding-minute')[:2] == ['blocked', reason]
            assert state(s) == before
        finally:
            s.close()


def test_bleeding_aid(Session, bundle, out):
    def state(s):
        s.action(2287)
        return last(s, 'test.bleeding-minute-state')
    for late in (False, True):
        s = Session(bundle)
        path = out / f'expanded-bleeding-aid-{late}.zsave'
        try:
            s.action(2285, 0)
            s.action(2285, 1)
            if late:
                s.action(2285, 4)
                s.action(2285, 26)  # Critical failed bleeding check: three lost HP.
                s.action(2285, 20)
            s.action(2285, 40)
            assert last(s, 'test.bleeding-aid') == ['resolved', None, 0]
            before = state(s)
            s.action(2285, 42)
            assert last(s, 'test.bleeding-aid')[:2] == ['blocked', 'bleeding-aid-not-due']
            assert state(s) == before
            s.action(2285, 30)  # First Aid 10 succeeds at ten.
            s.action(2285, 4)
            s.command(f':save {path}\n@2287')
            due = state(s)
        finally:
            s.close()
        s = Session(bundle)
        try:
            s.command(f':restore {path}\n@2287')
            assert state(s) == due
            s.action(2285, 41)
            assert last(s, 'test.bleeding-aid') == ['ready', None, 0]
            assert state(s) == due
            s.action(2285, 43)
            assert state(s) == due
            s.action(2285, 42)
            assert last(s, 'test.bleeding-aid') == ['resolved', None, 1]
            stopped = state(s)
            assert stopped[0] == (5 if late else 2)
            assert stopped[4] == (120 if late else 60)
            assert stopped[-1] == due[-1] + 3
            s.command('undo')
            assert state(s) == due
            s.action(2285, 42)
            s.action(2285, 42)
            assert last(s, 'test.bleeding-aid') == ['reused', None, 0]
            assert state(s) == stopped
            s.action(2285, 5)
            assert state(s)[6] == stopped[6] + 61
        finally:
            s.close()

    for interrupted in (False, True):
        s = Session(bundle)
        try:
            for code in (0, 1, 40, 4):
                s.action(2285, code)
            if interrupted:
                s.action(2285, 45)
                s.action(2285, 42)
                assert last(s, 'test.bleeding-aid')[:2] == ['blocked', 'bleeding-aid-interrupted']
                s.action(2285, 46)
                assert last(s, 'test.bleeding-aid') == ['resolved', 'bleeding-aid-interrupted', 0]
                assert state(s)[-1] == 0
            else:
                s.action(2285, 26)
                s.action(2285, 42)
                assert last(s, 'test.bleeding-aid') == ['resolved', None, 0]
                assert state(s)[-1] == 3
            assert state(s)[0] == 2
            assert state(s)[4] is None
            s.action(2285, 30)
            s.action(2285, 20)
            assert state(s)[5] == 120
        finally:
            s.close()


def test_bleeding_bandage(Session, bundle, out):
    def state(s):
        s.action(2288)
        return last(s, 'test.bleeding-bandage-state')
    s = Session(bundle)
    path = out / 'expanded-bleeding-bandage.zsave'
    try:
        for code in (0, 1, 47, 40, 4):
            s.action(2285, code)
        before = state(s)
        s.action(2285, 41)
        assert last(s, 'test.bleeding-aid') == ['ready', None, 0]
        assert state(s) == before
        s.action(2285, 43)
        assert state(s) == before
        s.action(2285, 42)
        assert last(s, 'test.bleeding-aid') == ['resolved', None, 1]
        after = state(s)
        assert after == [1, 1, 1, 1, 1, 1, 60, 3]
        s.command('undo')
        assert state(s) == before
        s.action(2285, 42)
        s.action(2285, 42)
        assert state(s) == after
        s.action(2285, 48)
        assert state(s) == after  # Ordinary bandaging cannot charge or heal twice.
        s.command(f':save {path}\n@2288')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2288')
        assert state(s) == after
        s.action(2285, 48)
        assert state(s) == after
    finally:
        s.close()
    for invalid in (False, True):
        s = Session(bundle)
        try:
            for code in (0, 1, 47, 40, 4):
                s.action(2285, code)
            if invalid:
                s.action(2285, 49)
                before = state(s)
                s.action(2285, 42)
                assert last(s, 'test.bleeding-aid')[:2] == ['blocked', 'bandage-eligible-injury']
                assert state(s) == before
            else:
                s.action(2285, 26)
                s.action(2285, 42)
                assert last(s, 'test.bleeding-aid') == ['resolved', None, 0]
                assert state(s)[0:4] == [2, None, 0, 0]
                assert state(s)[-2:] == [60, 3]
        finally:
            s.close()


def test_bleeding_care_boundaries(Session, bundle, out):
    def state(s):
        s.action(2287)
        return last(s, 'test.bleeding-minute-state')
    path = out / 'expanded-bleeding-offset-care.zsave'
    s = Session(bundle)
    try:
        for code in (0, 1, 11, 40):  # Wound at zero; care begins at ten.
            s.action(2285, code)
        before = state(s)
        assert before[6] == 10
        s.action(2285, 4)  # Cannot skip blood loss due at sixty.
        assert state(s) == before
        s.action(2285, 12)
        s.action(2285, 26)
        s.action(2285, 20)  # Blood loss at sixty, next check at 120.
        due = state(s)
        assert due == [5, 2, 1, 0, None, 120, 60, 3]
        s.action(2285, 4)  # Care completion at seventy must not be skipped.
        assert state(s) == due
        s.command(f':save {path}\n@2287')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2287')
        assert state(s) == due
        s.action(2285, 4)
        assert state(s) == due
        s.action(2285, 11)
        at_completion = state(s)
        assert at_completion[6] == 70
        s.action(2285, 6)
        assert state(s) == at_completion
        s.action(2285, 30)
        s.action(2285, 42)
        assert state(s) == [5, 2, 1, 0, 70, 120, 70, 6]
        s.action(2285, 5)
        assert state(s)[6] == 131
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (0, 1, 11, 40, 12, 30, 20):
            s.action(2285, code)
        before = state(s)
        s.action(2285, 46)
        s.action(2285, 4)  # Cancelled care releases seventy; next bleed remains 120.
        assert state(s)[6] == 120
        assert state(s)[-1] == before[-1]
    finally:
        s.close()


def test_radiation_tables(s):
    # Fixed outcomes at effective score ten: critical success, success, failure, critical failure.
    for dose, penalty, outcomes in [
            (1, 0, ['none', 'none', 'burns', 'blood']),
            (10, 0, ['none', 'none', 'burns', 'blood']),
            (11, 0, ['none', 'burns', 'blood', 'digestive']),
            (20, 0, ['none', 'burns', 'blood', 'digestive']),
            (21, 0, ['burns', 'blood', 'digestive', 'terminal']),
            (40, 0, ['burns', 'blood', 'digestive', 'terminal']),
            (41, -1, ['burns', 'blood', 'digestive', 'terminal']),
            (80, -1, ['burns', 'blood', 'digestive', 'terminal']),
            (81, -3, ['burns', 'blood', 'digestive', 'terminal']),
            (160, -3, ['burns', 'blood', 'digestive', 'terminal']),
            (161, -4, ['burns', 'blood', 'digestive', 'terminal']),
            (799, -4, ['burns', 'blood', 'digestive', 'terminal']),
            (801, -5, ['digestive', 'terminal', 'acute-brain', 'acute-brain']),
            (4000, -5, ['digestive', 'terminal', 'acute-brain', 'acute-brain']),
            (4001, -5, ['terminal', 'acute-brain', 'acute-brain', 'acute-brain'])]:
        for roll, outcome in zip([3, 10, 11, 18], outcomes):
            s.action(2289, 10 - penalty, dose, 0, roll)
            assert last(s, 'test.radiation-table') == ['ready', None, penalty, outcome, 0, 0]
    s.action(2289, 10, 800, 0, 10)
    assert last(s, 'test.radiation-table')[:2] == ['blocked', 'radiation-eight-hundred-overlap']
    s.action(2289, 3, 81, 0, 3)
    assert last(s, 'test.radiation-table')[:2] == ['blocked', 'radiation-score-unavailable']
    for dose, day, tenths in [(200, 0, 2000), (200, 30, 2000), (200, 31, 1900),
                               (200, 47, 300), (200, 48, 200), (200, 100, 200),
                               (1, 31, 1), (15, 31, 50), (15, 32, 15)]:
        s.action(2290, dose, day)
        assert last(s, 'test.radiation-decay') == [tenths, 0, 0]


def test_radiation_doses(Session, bundle, out):
    def state(s):
        s.action(2292)
        return last(s, 'test.radiation-state')
    s = Session(bundle)
    path = out / 'expanded-radiation-doses.zsave'
    try:
        before = state(s)
        s.action(2291, 1, 0)
        assert last(s, 'test.radiation-dose') == ['ready', None]
        assert state(s) == before
        s.action(2291, 2, 0)
        assert state(s) == before
        s.action(2291, 0, 0)
        assert state(s) == [1, 2000, 0, None, 0, 0]
        s.command('undo')
        assert state(s) == before
        s.action(2291, 0, 0)
        s.action(2291, 3, 30)
        s.action(2291, 4, 0)
        assert state(s) == [2, 3000, 0, 2592000, 2592000, 0]
        s.action(2291, 3, 1)
        saved = state(s)
        assert saved == [2, 2900, 0, 2592000, 2678400, 0]
        s.action(2291, 0, 0)
        assert last(s, 'test.radiation-dose') == ['reused', None]
        assert state(s) == saved
        s.command(f':save {path}\n@2292')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2292')
        assert state(s) == saved
        for days, total in [(17, 1200), (13, 1100), (8, 300)]:
            s.action(2291, 3, days)
            assert state(s)[1] == total
            assert state(s)[-1] == 0
    finally:
        s.close()


def test_radiation_shielding(s):
    for numerator, denominator, days, expected in [
            (1, 2, 30, [1, 2, 5]), (1, 2, 31, [1, 20, 'radiation-finer-than-tenth']),
            (1, 3, 31, [1, 30, 'radiation-finer-than-tenth']),
            (200, 1, 48, [20, 1, 200]), (15, 2, 31, [3, 4, 'radiation-finer-than-tenth']),
            (100000000, 20000000, 1000000, [1, 2, 5])]:
        s.action(2296, numerator, denominator, days)
        assert last(s, 'test.radiation-fraction') == expected
    s.action(2294)
    assert last(s, 'test.radiation-materials') == [2, 2, 2, 8, 27, 64]
    for incident, protection, spectrum, ratio in [
            (200, 2, 1, [200, 2, 100, 0]), (200, 2, 2, [200, 40, 5, 0]),
            (200, 200, 3, [20000, 200, 100, 0]), (1, 2, 1, [1, 2, 0, 1]),
            (100, 27, 1, [100, 27, 3, 1])]:
        s.action(2293, incident, protection, spectrum)
        assert last(s, 'test.radiation-shield') == ['ready', None] + ratio
    s.action(2293, 200, 2, 3)
    assert last(s, 'test.radiation-shield')[:2] == ['blocked', 'radiation-subunit-protection-unresolved']


def test_radiation_exposures(Session, bundle):
    def state(s):
        s.action(2292)
        return last(s, 'test.radiation-state')
    s = Session(bundle)
    try:
        before = state(s)
        s.action(2291, 11, 0)
        assert last(s, 'test.radiation-exposure') == ['ready', None]
        assert state(s) == before
        s.action(2291, 12, 0)
        assert state(s) == before
        s.action(2291, 10, 0)
        assert state(s) == [1, 1000, None, None, 0, 0]
        s.command('undo')
        assert state(s) == before
        s.action(2291, 10, 0)
        after = state(s)
        s.action(2291, 10, 0)
        assert last(s, 'test.radiation-exposure') == ['reused', None]
        assert state(s) == after
    finally:
        s.close()
    for change, reason in [(15, 'radiation-subunit-protection-unresolved')]:
        s = Session(bundle)
        try:
            s.action(2291, change, 0)
            before = state(s)
            s.action(2291, 10, 0)
            assert last(s, 'test.radiation-exposure') == ['blocked', reason]
            assert state(s) == before
        finally:
            s.close()


def test_fractional_radiation(Session, bundle, out):
    def ratio(s):
        s.action(2295)
        return last(s, 'test.radiation-ratio')
    path = out / 'expanded-radiation-fractional.zsave'
    s = Session(bundle)
    try:
        s.action(2291, 13, 0)
        before = ratio(s)
        s.action(2291, 11, 0)
        assert last(s, 'test.radiation-exposure') == ['ready', None]
        assert ratio(s) == before
        s.action(2291, 12, 0)
        assert ratio(s) == before
        s.action(2291, 10, 0)
        assert ratio(s) == [1, 2, 1, 0, 0]
        s.action(2291, 17, 0)
        assert ratio(s) == [5, 6, 2, 0, 0]
        s.command('undo')
        assert ratio(s) == [1, 2, 1, 0, 0]
        s.action(2291, 17, 0)
        s.action(2291, 3, 31)
        saved = ratio(s)
        assert saved == [1, 12, 2, 2678400, 0]
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        assert ratio(s) == saved
        s.action(2291, 10, 0)
        s.action(2291, 17, 0)
        assert ratio(s) == saved
        s.action(2291, 3, 50)
        assert ratio(s) == [1, 12, 2, 6998400, 0]
    finally:
        s.close()


def test_radiation_traits(Session, bundle):
    for level, divisor, numerator, denominator in [
            (1, 2, 50, 1), (2, 5, 20, 1), (3, 10, 10, 1),
            (4, 20, 5, 1), (5, 50, 2, 1), (6, 100, 1, 1),
            (7, 200, 1, 2), (8, 500, 1, 5), (9, 1000, 1, 10)]:
        s = Session(bundle)
        try:
            s.action(2291, 20, level)
            s.action(2291, 24, 0)
            assert last(s, 'test.radiation-trait') == [level * 5, divisor, level * 5]
            s.action(2291, 10, 0)
            s.action(2295)
            assert last(s, 'test.radiation-ratio') == [numerator, denominator, 1, 0, 0]
            s.action(2291, 21, 0)  # Changing a current trait cannot rewrite the received dose.
            s.action(2291, 10, 0)
            s.action(2295)
            assert last(s, 'test.radiation-ratio') == [numerator, denominator, 1, 0, 0]
        finally:
            s.close()
    for change in (21, 22):
        s = Session(bundle)
        try:
            s.action(2291, change, 0)
            s.action(2291, 10, 0)
            s.action(2295)
            assert last(s, 'test.radiation-ratio') == [100, 1, 1, 0, 0]
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.action(2291, 23, 0)
        s.action(2291, 10, 0)
        s.action(2295)
        assert last(s, 'test.radiation-ratio') == [0, 1, 0, 0, 0]
    finally:
        s.close()


def test_radiation_prevention(Session, bundle, out):
    # B436: inclusive one-to-three-hour preventive window, no retroactive erasure.
    for elapsed, expected in [(0, 100), (3599, 100), (3600, 50),
                              (7200, 50), (10800, 50), (10801, 100)]:
        s = Session(bundle)
        try:
            s.action(2291, 20, 0)
            s.action(2291, 30, elapsed)
            s.action(2291, 10, 0)
            s.action(2295)
            assert last(s, 'test.radiation-ratio') == [expected, 1, 1, elapsed, 0]
            s.action(2291, 20, 0)  # Reusing administration never consumes a second dose.
            s.action(2291, 31, 0)
            assert last(s, 'test.radiation-prevention') == [1, 1, 2 if 3600 <= elapsed <= 10800 else 1, 1, elapsed, 0]
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.action(2291, 21, 0)
        s.action(2291, 22, 0)
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-prevention') == [2, 0, 1, 1, 0, 0]
        s.action(2291, 20, 0)
        s.command('undo')
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-prevention') == [2, 0, 1, 1, 0, 0]
        s.action(2291, 10, 0)  # Dose before administration remains unchanged.
        s.action(2291, 20, 0)
        s.action(2291, 24, 0)
        assert last(s, 'test.radiation-prevention-result') == ['blocked', 'radiation-prevention-overlap']
        s.action(2291, 30, 10801)
        s.action(2291, 24, 0)
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-prevention') == [0, 2, 1, 0, 10801, 0]
        s.action(2291, 30, 3600)
        s.action(2291, 10, 0)
        s.action(2295)
        assert last(s, 'test.radiation-ratio') == [100, 1, 1, 14401, 0]
    finally:
        s.close()

    path = out / 'expanded-radiation-prevention.zsave'
    s = Session(bundle)
    try:
        s.action(2291, 20, 0)
        s.action(2291, 30, 3599)
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 20, 0)
        s.action(2291, 30, 1)
        s.action(2291, 10, 0)
        s.action(2295)
        assert last(s, 'test.radiation-ratio') == [50, 1, 1, 3600, 0]
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-prevention') == [1, 1, 2, 1, 3600, 0]
    finally:
        s.close()


def test_radiation_treatment(Session, bundle, out):
    s = Session(bundle)
    path = out / 'expanded-radiation-treatment.zsave'
    try:
        s.action(2291, 21, 0)
        s.action(2291, 22, 0)
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-treatment') == [2, 0, 10, 10, 0, 0]
        s.action(2291, 20, 0)
        s.command('undo')
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-treatment') == [2, 0, 10, 10, 0, 0]
        s.action(2291, 20, 0)
        s.action(2291, 20, 0)
        s.action(2291, 24, 0)
        assert last(s, 'test.radiation-treatment-result') == ['blocked', 'radiation-prevention-overlap']
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-treatment') == [1, 1, 13, 10, 0, 0]
        s.action(2291, 10, 0)
        s.action(2295)
        assert last(s, 'test.radiation-ratio') == [100, 1, 1, 0, 0]
        s.action(2291, 3, 13)
        s.action(2291, 30, 86399)
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-treatment') == [1, 1, 13, 10, 1209599, 0]
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 20, 0)
        s.action(2291, 30, 1)
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-treatment') == [1, 1, 10, 10, 1209600, 0]
        s.action(2291, 24, 0)
        s.action(2291, 31, 0)
        assert last(s, 'test.radiation-treatment') == [0, 2, 13, 10, 1209600, 0]
    finally:
        s.close()
    for invalid in (32, 33):
        s = Session(bundle)
        try:
            s.action(2291, invalid, 0)
            s.action(2291, 20, 0)
            s.action(2291, 31, 0)
            assert last(s, 'test.radiation-treatment') == [2, 0, 10, 10, 0, 0]
        finally:
            s.close()


def test_fallout_treatment(Session, bundle, out):
    for advanced, elapsed, fraction, total in [
            (False, 259199, [1, 1], 20), (False, 259200, [1, 2], 15),
            (False, 604799, [1, 2], 15), (False, 604800, [0, 1], 10),
            (True, 43199, [1, 1], 20), (True, 43200, [0, 1], 10)]:
        s = Session(bundle)
        try:
            s.action(2291, 20, 0)
            s.action(2291, 23, 0)
            if advanced:
                s.action(2291, 22, 0)
            s.action(2291, 21, 0)
            days, seconds = divmod(elapsed, 86400)
            s.action(2291, 3, days)
            s.action(2291, 30, seconds)
            s.action(2291, 24, 0)
            s.action(2291, 21, 0)  # Replayed treatment retains its original epoch.
            s.action(2291, 24, 0)  # Release replay neither redoses nor erases.
            s.action(2291, 31, 0)
            assert last(s, 'test.fallout') == fraction + [total, 1, int(advanced), int(not advanced), 1, 2, elapsed, 0]
        finally:
            s.close()
    path = out / 'expanded-fallout.zsave'
    s = Session(bundle)
    try:
        s.action(2291, 20, 0)
        s.action(2291, 25, 0)
        s.action(2291, 26, 0)
        s.action(2291, 31, 0)
        assert last(s, 'test.fallout') == [1, 1, 0, 1, 1, 1, 0, 0, 0, 0]
        s.action(2291, 21, 0)
        s.command('undo')
        s.action(2291, 31, 0)
        assert last(s, 'test.fallout') == [1, 1, 0, 1, 1, 1, 0, 0, 0, 0]
        s.action(2291, 21, 0)
        s.action(2291, 23, 0)
        s.action(2291, 3, 3)
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 24, 0)
        s.action(2291, 31, 0)
        assert last(s, 'test.fallout') == [1, 2, 15, 1, 0, 1, 1, 2, 259200, 0]
        s.action(2291, 3, 4)
        s.action(2291, 21, 0)
        s.action(2291, 24, 0)
        s.action(2291, 31, 0)
        assert last(s, 'test.fallout') == [0, 1, 15, 1, 0, 1, 1, 2, 604800, 0]
    finally:
        s.close()


def test_radiation_checks(Session, bundle, out):
    path = out / 'expanded-radiation-check.zsave'
    s = Session(bundle)
    try:
        s.action(2291, 0, 0)
        s.action(2291, 51, 0)
        s.action(2291, 52, 0)
        s.action(2291, 55, 0)
        assert last(s, 'test.radiation-check-state') == [0, 0, 0, None, None]
        s.action(2291, 50, 0)
        assert last(s, 'test.radiation-check-result') == ['resolved', None, 'none', None]
        s.command('undo')
        s.action(2291, 55, 0)
        assert last(s, 'test.radiation-check-state') == [0, 0, 0, None, None]
        s.action(2291, 50, 0)
        s.action(2291, 50, 0)
        s.action(2291, 54, 0)
        assert last(s, 'test.radiation-check-result')[:2] == ['blocked', 'radiation-check-source-day-used']
        s.action(2291, 30, 86399)
        s.action(2291, 54, 0)
        assert last(s, 'test.radiation-check-result')[:2] == ['blocked', 'radiation-check-source-day-used']
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 30, 1)
        s.action(2291, 54, 0)
        assert last(s, 'test.radiation-check-result') == ['awaiting-consequences', None, 'burns', True]
        s.action(2291, 54, 0)
        s.action(2291, 55, 0)
        assert last(s, 'test.radiation-check-state') == [2, 6, 86400, 0, 86400]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2291, 20, 0)  # Advanced treatment makes the second roll of 11 a success.
        s.action(2291, 0, 0)
        s.action(2291, 50, 0)
        s.action(2291, 3, 1)
        s.action(2291, 54, 0)
        assert last(s, 'test.radiation-check-result') == ['resolved', None, 'none', None]
    finally:
        s.close()
    for setup, reason in [(40, 'radiation-eight-hundred-overlap'),
                          (41, 'radiation-check-below-threshold'),
                          (42, 'radiation-check-fractional-band-unresolved')]:
        s = Session(bundle)
        try:
            s.action(2291, setup, 0)
            s.action(2291, 0, 0)
            s.action(2291, 50, 0)
            assert last(s, 'test.radiation-check-result')[:2] == ['blocked', reason]
            s.action(2291, 55, 0)
            assert last(s, 'test.radiation-check-state') == [0, 0, 0, None, None]
        finally:
            s.close()


def test_pain_sensitivity(Session, bundle, out):
    def state(s):
        s.action(2399)
        return last(s, 'test.pain-state')
    initial = [0, 0, 0, None, 6, 10, -10, 8]
    path = out / 'expanded-pain-sensitivity.zsave'
    s = Session(bundle)
    try:
        assert state(s) == initial
        s.action(2398, 1)
        assert state(s) == initial
        s.action(2398, 5)
        assert state(s) == initial
        s.action(2398, 0)
        assert state(s) == [2, 4, 3, True, 6, 10, -10, 8]
        s.command('undo')
        assert state(s) == initial
        s.action(2398, 0)
        s.command(f':save {path}\n@2399')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2399')
        s.action(2398, 0)
        assert state(s) == [2, 4, 3, True, 6, 10, -10, 8]
    finally:
        s.close()
    for setup, expected in [(2, [1, 2, 0, None, 6, 10, -10, 8]),
                            (3, [4, 8, 3, True, 6, 10, -10, 8]),
                            (4, initial)]:
        s = Session(bundle)
        try:
            s.action(2398, setup)
            s.action(2398, 0)
            assert state(s) == expected
        finally:
            s.close()


def test_radiation_burns(Session, bundle, out):
    def state(s):
        s.action(2291, 68, 0)
        return last(s, 'test.radiation-burn')
    path = out / 'expanded-radiation-burn.zsave'
    s = Session(bundle)
    try:
        s.action(2291, 0, 0)
        s.action(2291, 50, 0)
        s.action(2291, 61, 0)
        assert state(s) == [0, 0, 0, 0, 0, None, None, 3, 0]
        s.action(2291, 60, 0)
        s.action(2291, 30, 36001)  # Cannot skip the onset deadline.
        assert state(s) == [0, 0, 0, 0, 1, None, 36000, 3, 0]
        s.action(2291, 30, 36000)
        s.action(2291, 63, 0)
        s.action(2291, 64, 0)
        assert state(s) == [0, 0, 0, 0, 1, None, 36000, 3, 36000]
        s.action(2291, 62, 0)
        s.command('undo')
        assert state(s) == [0, 0, 0, 0, 1, None, 36000, 3, 36000]
        s.action(2291, 62, 0)
        assert state(s) == [2, 2, 1, 0, 1, 36000, 36000, 4, 36000]
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 62, 0)
        assert state(s) == [2, 2, 1, 0, 1, 36000, 36000, 4, 36000]
        s.action(2291, 67, 0)
        assert state(s)[:4] == [4, 6, 1, 0]
        s.action(2291, 3, 7)
        assert state(s)[2:4] == [0, 0]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2291, 65, 0)
        s.action(2291, 0, 0)
        s.action(2291, 50, 0)
        s.action(2291, 60, 0)
        s.action(2291, 30, 36000)
        s.action(2291, 62, 0)
        assert state(s) == [2, 0, 0, 0, 1, 36000, 36000, 4, 36000]
        s.action(2291, 3, 7)
        assert state(s)[2:4] == [0, 1]
    finally:
        s.close()


def test_terminal_condition(Session, bundle, out):
    def state(s):
        s.action(2291, 31, 0)
        return last(s, 'test.terminal')
    path = out / 'expanded-terminal-condition.zsave'
    s = Session(bundle)
    try:
        initial = [0, 0, 0, 0, None, 0, 0, 0]
        s.action(2291, 21, 0)
        s.action(2291, 22, 0)
        assert state(s) == initial
        s.action(2291, 20, 0)
        s.command('undo')
        assert state(s) == initial
        s.action(2291, 20, 0)
        s.action(2291, 20, 0)
        assert state(s) == [-75, 0, 1, 75, 31536000, 0, 0, 0]
        for days in (100, 100, 100, 64):
            s.action(2291, 3, days)
        s.action(2291, 30, 86399)
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 30, 2)
        assert state(s)[5:] == [0, 31535999, 0]
        s.action(2291, 23, 0)
        assert state(s)[5:] == [0, 31535999, 0]
        s.action(2291, 30, 1)
        s.action(2291, 24, 0)
        assert state(s)[5:] == [0, 31536000, 0]
        s.action(2291, 23, 0)
        s.command('undo')
        assert state(s)[5:] == [0, 31536000, 0]
        s.action(2291, 23, 0)
        s.action(2291, 23, 0)
        assert state(s) == [-75, 0, 1, 75, 31536000, 1, 31536000, 0]
    finally:
        s.close()


def test_radiation_recovery(Session, bundle, out):
    def setup(s, pair):
        for code, argument in [(0, 0), (50, 0), (60, 0), (30, 36000), (62, 0), (70, pair)]:
            s.action(2291, code, argument)
    def state(s):
        s.action(2291, 84, 0)
        return last(s, 'test.radiation-recovery')
    for pair, sterile, terminal in [(1, 0, 0), (2, 1, 0), (3, 0, 1), (4, 1, 1), (5, 0, 0)]:
        s = Session(bundle)
        try:
            setup(s, pair)
            s.action(2291, 82, 0)
            assert state(s) == [0, 0, 0, 4, 1, None, 2, 0]
            s.action(2291, 80, 0)
            s.action(2291, 81, 0)
            s.action(2291, 83, 0)
            assert state(s) == [0, 0, 0, 4, 1, None, 0, 0]
            s.action(2291, 82, 0)
            s.command('undo')
            assert state(s) == [0, 0, 0, 4, 1, None, 0, 0]
            s.action(2291, 82, 0)
            s.action(2291, 82, 0)
            expected = [sterile, -75 * terminal, sterile + terminal, 10, 0,
                        31572000 if terminal else None, 0, 0]
            assert state(s) == expected
            if pair == 4:
                path = out / 'expanded-radiation-recovery.zsave'
                s.command(f':save {path}\n@2295')
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 82, 0)
        assert state(s) == [1, -75, 2, 10, 0, 31572000, 0, 0]
    finally:
        s.close()


def test_nausea_episodes(Session, bundle, out):
    def state(s):
        s.action(2291, 31, 0)
        return last(s, 'test.nausea')
    path = out / 'expanded-nausea.zsave'
    s = Session(bundle)
    try:
        s.action(2291, 21, 0)
        s.action(2291, 22, 0)
        assert state(s) == [10] * 6 + [0, 0, 0, 0]
        s.action(2291, 20, 0)
        s.command('undo')
        assert state(s) == [10] * 6 + [0, 0, 0, 0]
        s.action(2291, 20, 0)
        s.action(2291, 20, 0)
        assert state(s) == [8] * 6 + [1, 1, 0, 0]
        s.action(2291, 32, 0)
        assert last(s, 'test.nausea-contexts') == [8, 10, 10]
        s.action(2291, 24, 0)
        s.action(2291, 30, 60)
        assert state(s) == [8] * 6 + [1, 2, 60, 0]
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 20, 0)
        s.action(2291, 30, 59)
        assert state(s) == [8] * 6 + [1, 2, 119, 0]
        s.action(2291, 30, 1)
        assert state(s) == [10] * 6 + [0, 2, 120, 0]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2291, 20, 0)
        s.action(2291, 24, 0)
        s.action(2291, 25, 0)
        assert state(s) == [8] * 6 + [1, 2, 0, 0]
        s.action(2291, 30, 60)
        assert state(s) == [10] * 6 + [0, 2, 60, 0]
    finally:
        s.close()


def test_nausea_triggers(Session, bundle, out):
    def state(s):
        s.action(2291, 54, 0)
        return last(s, 'test.nausea-trigger')
    path = out / 'expanded-nausea-trigger.zsave'
    s = Session(bundle)
    try:
        s.action(2291, 20, 0)
        s.action(2291, 51, 0)
        s.action(2291, 52, 0)
        assert state(s) == [0, 0, 0, None, 0, 0]
        s.action(2291, 50, 0)  # Seed 1 rolls 10 against nausea-adjusted HT 8.
        s.command('undo')
        assert state(s) == [0, 0, 0, None, 0, 0]
        s.action(2291, 50, 0)
        s.action(2291, 50, 0)
        assert state(s) == [1, 1, 0, 15, 3, 0]
        s.action(2291, 30, 16)
        assert state(s) == [1, 1, 0, 15, 3, 0]
        s.action(2291, 30, 14)
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 53, 0)
        assert state(s) == [1, 1, 0, 15, 3, 14]
        s.action(2291, 30, 1)
        s.action(2291, 53, 0)
        s.action(2291, 53, 0)
        assert state(s) == [1, 0, 1, 15, 3, 15]
    finally:
        s.close()
    for setup, expected in [(40, [1, 0, 0, None, 3, 0]), (41, [0, 0, 0, None, 0, 0])]:
        s = Session(bundle)
        try:
            s.action(2291, 20, 0)
            s.action(2291, setup, 0)
            s.action(2291, 50, 0)
            assert state(s) == expected
        finally:
            s.close()


def test_nausea_motion(Session, bundle, out):
    def state(s):
        s.action(2291, 64, 0)
        return last(s, 'test.nausea-motion')
    path = out / 'expanded-nausea-motion.zsave'
    s = Session(bundle)
    try:
        s.action(2291, 20, 0)
        s.action(2291, 40, 0)
        s.action(2291, 61, 0)
        assert state(s) == [0, None, 0, 0, 0, 0, 0]
        s.action(2291, 60, 0)
        s.action(2291, 30, 3601)
        assert state(s) == [0, 3600, 0, 0, 0, 0, 0]
        s.action(2291, 30, 3599)
        s.command(f':save {path}\n@2295')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2295')
        s.action(2291, 30, 1)
        s.action(2291, 65, 0)  # A due hour cannot be bypassed by stopping.
        s.action(2291, 68, 0)
        assert state(s) == [0, 3600, 0, 3600, 0, 0, 0]
        s.action(2291, 62, 0)
        s.command('undo')
        assert state(s) == [0, 3600, 0, 3600, 0, 0, 0]
        s.action(2291, 62, 0)
        s.action(2291, 62, 0)
        assert state(s) == [1, 7200, 3, 3600, 0, 0, 0]
        s.action(2291, 66, 0)
        s.action(2291, 30, 3600)
        s.action(2291, 63, 0)
        s.action(2291, 63, 0)
        assert state(s) == [2, 10800, 3, 7200, 0, 0, 0]
        s.action(2291, 65, 0)
        s.action(2291, 30, 4000)
        assert state(s) == [2, 10800, 3, 11200, 0, 0, 1]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2291, 20, 0)
        s.action(2291, 60, 0)
        s.action(2291, 30, 3600)
        s.action(2291, 62, 0)
        assert state(s) == [1, 7200, 3, 3600, 1, 0, 0]
        s.action(2291, 30, 16)
        assert state(s) == [1, 7200, 3, 3600, 1, 0, 0]
        s.action(2291, 30, 15)
        s.action(2291, 53, 0)
        assert state(s) == [1, 7200, 3, 3615, 0, 1, 0]
    finally:
        s.close()


def test_impaired_clotting(s):
    for internal, care, expected in [
            (0, 1, [60, 3, 0, 0]), (0, 2, [None, 0, 1, 0]), (0, 3, [None, 0, 1, 0]),
            (1, 1, [60, 3, 0, 1]), (1, 2, [86400, 3, 0, 1]), (1, 3, [None, 0, 0, 0])]:
        s.action(2379, 3, internal, care)
        assert last(s, 'test.clotting') == expected + [0, 0]
    s.action(2380, 10)
    assert last(s, 'test.clotting-profile') == [-30, 'ready']
    s.action(2380, 11)
    assert last(s, 'test.clotting-profile') == [-30, 'impaired-clotting-health-limit']
    s.action(2381)
    assert last(s, 'test.clotting-dispatch') == ['blocked', 'bleeding-impaired-clotting-procedure-required', 0, 0]


def test_clotting_loss(Session, bundle, out):
    def state(s):
        s.action(2285, 66)
        return last(s, 'test.clotting-loss')
    path = out / 'expanded-clotting-loss.zsave'
    s = Session(bundle)
    try:
        s.action(2285, 0)
        s.action(2285, 67)
        s.action(2285, 60)
        s.action(2285, 65)
        s.action(2285, 5)
        assert state(s) == [2, 2, 0, 0, 60, 0, 0, 0]
        s.action(2285, 4)
        s.action(2285, 64)
        s.action(2285, 63)
        assert state(s) == [2, 2, 0, 0, 60, 60, 0, 0]
        s.action(2285, 61)
        s.command('undo')
        assert state(s) == [2, 2, 0, 0, 60, 60, 0, 0]
        s.action(2285, 61)
        s.action(2285, 61)
        assert state(s) == [4, 2, 1, 2, 120, 60, 0, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 4)
        s.action(2285, 62)
        assert state(s) == [6, 2, 2, 4, 180, 120, 0, 0]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2285, 0)
        s.action(2285, 60)
        s.action(2285, 68)
        s.action(2285, 4)
        s.action(2285, 61)
        s.action(2285, 6)  # The other wound still owns a due loss at this instant.
        assert state(s) == [5, 2, 1, 0, 120, 60, 0, 0]
        s.action(2285, 69)
        assert state(s) == [6, 2, 1, 0, 120, 60, 0, 0]
    finally:
        s.close()


def test_clotting_care(Session, bundle, out):
    def state(s):
        s.action(2285, 75)
        return last(s, 'test.clotting-care')
    s = Session(bundle)
    try:
        s.action(2285, 0)
        s.action(2285, 60)
        s.action(2285, 71)
        s.action(2285, 72)
        assert state(s) == [2, 'untreated', 0, 60, None, 2, 0, 0]
        s.action(2285, 70)
        s.command('undo')
        assert state(s) == [2, 'untreated', 0, 60, None, 2, 0, 0]
        s.action(2285, 70)
        s.action(2285, 70)
        assert state(s) == [1, 'first-aid', 0, None, 1, 0, 60, 0]
        s.action(2285, 73)
        s.action(2285, 65)
        assert state(s) == [0, 'first-aid', 0, None, 1, 0, 86460, 0]
    finally:
        s.close()
    path = out / 'expanded-clotting-care.zsave'
    s = Session(bundle)
    try:
        s.action(2285, 0)
        s.action(2285, 67)
        s.action(2285, 60)
        s.action(2285, 4)
        s.action(2285, 61)
        s.action(2285, 70)
        assert state(s) == [3, 'first-aid', 2, 86520, 1, 2, 120, 0]
        s.action(2285, 65)
        s.action(2285, 65)
        assert state(s) == [2, 'first-aid', 2, 86520, 1, 2, 120, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 70)
        s.action(2285, 73)
        s.action(2285, 74)
        s.action(2285, 74)
        assert state(s) == [4, 'first-aid', 4, 172920, 1, 4, 86520, 0]
    finally:
        s.close()


def test_clotting_restoration(Session, bundle, out):
    def setup(s, bandage=True):
        for code in (0, 67, 60, 4, 61):
            s.action(2285, code)
        if bandage:
            s.action(2285, 70)
    def state(s):
        s.action(2285, 86)
        return last(s, 'test.clotting-restoration')
    path = out / 'expanded-clotting-restoration.zsave'
    s = Session(bundle)
    try:
        setup(s)
        s.action(2285, 81)
        s.action(2285, 82)
        initial = [3, 2, 0, 'first-aid', 86520, 2, 0, 120, 0]
        assert state(s) == initial
        s.action(2285, 80)
        s.command('undo')
        assert state(s) == initial
        s.action(2285, 80)
        s.action(2285, 80)
        assert state(s) == [1, 0, 2, 'definitive', None, 0, 1, 120, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 80)
        s.action(2285, 73)
        s.action(2285, 65)
        assert state(s) == [0, 0, 2, 'definitive', None, 0, 1, 86520, 0]
    finally:
        s.close()
    for mode, expected in [
            (83, [2, 1, 1, 'first-aid', 86520, 1, 1, 120, 0]),
            (84, [3, 2, 0, 'definitive', None, 2, 1, 120, 0]),
            (85, [3, 2, 0, 'first-aid', 86520, 2, 0, 120, 0])]:
        s = Session(bundle)
        try:
            setup(s)
            s.action(2285, mode)
            s.action(2285, 80)
            assert state(s) == expected
        finally:
            s.close()
    s = Session(bundle)
    try:
        setup(s, False)
        s.action(2285, 83)
        s.action(2285, 88)
        s.action(2285, 80)
        assert state(s) == [3, 1, 1, 'untreated', 120, 3, 1, 60, 0]
        s.action(2285, 4)
        s.action(2285, 62)
        assert state(s) == [5, 3, 1, 'untreated', 180, 5, 1, 120, 0]
    finally:
        s.close()


def test_surgical_training_assessment(Session, bundle):
    # B170: four points in a Very Hard skill gives IQ-1; B424: TL8 adds 2.
    # B223: non-field surgery without Physician subtracts a further 5.
    cases = [
        ([], ['ready', None, 10, -5, 1, 0, 0]),
        ([91], ['ready', None, 15, 0, 1, 0, 0]),
        ([93], ['ready', None, 15, 0, 1, 0, 0]),
        ([91, 97], ['ready', None, 12, 0, 1, 0, 0]),
        ([92], ['blocked', 'surgical-assessment-prerequisite', None, 0, 1, 0, 0]),
        ([94], ['ready', None, 8, -5, 1, 0, 0]),
        ([91, 94], ['ready', None, 13, 0, 1, 0, 0]),
        ([91, 107], ['ready', None, 11, 0, 1, 0, 0]),
        ([91, 108], ['ready', None, 7, 0, 1, 0, 0]),
        ([91, 109], ['ready', None, 3, 0, 1, 0, 0]),
        ([91, 110], ['blocked', 'surgical-assessment-technology-too-advanced', None, 0, 1, 0, 0]),
        ([91, 111], ['ready', None, 10, 0, 1, 0, 0]),
        ([91, 112], ['ready', None, 6, 0, 1, 0, 0]),
        ([91, 113], ['blocked', 'surgical-assessment-score-unavailable', 2, 0, 1, 0, 0]),
        ([91, 107, 114], ['ready', None, 9, 0, 1, 0, 0]),
        ([101, 107], ['ready', None, 5, 0, 1, 0, 0]),
        ([95], ['blocked', 'surgical-assessment-score-unavailable', -1, -5, 1, 0, 0]),
        ([95, 93], ['ready', None, 4, 0, 1, 0, 0]),
        ([101], ['ready', None, 9, 0, 1, 0, 0]),
        ([98], ['ready', None, 6, -5, 1, 0, 0]),
        ([100], ['ready', None, 6, -5, 1, 0, 0]),
        ([100, 102], ['blocked', 'surgical-assessment-score-unavailable', None, -5, 1, 0, 0]),
        ([101, 103], ['blocked', 'surgical-assessment-score-unavailable', None, -5, 1, 0, 0]),
        ([101, 104], ['blocked', 'surgical-assessment-score-unavailable', None, 0, 1, 0, 0]),
        ([105], ['ready', None, 19, 0, 1, 0, 0]),
        ([105, 106], ['ready', None, 20, 0, 1, 0, 0]),
        ([96], ['blocked', 'surgical-assessment-incapacity', None, 0, 1, 0, 0]),
    ]
    for preparation, expected in cases:
        s = Session(bundle)
        try:
            for code in preparation:
                s.action(2285, code)
            for _ in range(2):
                s.action(2285, 90)
                assert last(s, 'test.surgical-assessment') == expected
        finally:
            s.close()

    # B169 prerequisites constrain purchase, not use through a B173 default.
    for code, expected in [(98, 'skill-prerequisite'), (100, 'skill-prerequisite'), (101, None)]:
        s = Session(bundle)
        try:
            s.action(2285, code)
            s.action(2285, 99)
            assert last(s, 'test.surgical-learning') == [expected]
        finally:
            s.close()
    # The B168 equipment mismatch is applied once, separately from B424's
    # equipment/anesthetic modifiers; infection eligibility follows care TL.
    for codes, expected in [([91, 107], [-2, -5, 3, 0, 0]),
                            ([91, 107, 114], [-4, -5, 3, -2, 0]),
                            ([91, 113], [-11, -7, -4, 0, 1])]:
        s = Session(bundle)
        try:
            for code in codes:
                s.action(2285, code)
            s.action(2285, 115)
            assert last(s, 'test.surgical-technology') == expected
        finally:
            s.close()


def test_surgical_operation(Session, bundle, out):
    def state(s):
        s.action(2285, 125)
        return last(s, 'test.surgical-operation')
    initial = [None, None, 0, 0, 0, 0, None, None]
    active = [0, None, 1, 0, 60, 0, None, None]
    path = out / 'expanded-surgical-operation.zsave'
    for codes in ([91, 112, 131], [132]):
        s = Session(bundle)
        try:
            for code in codes:
                s.action(2285, code)
            s.action(2285, 120)
            assert state(s) == initial
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.action(2285, 120)
        s.action(2285, 130)
        s.action(2285, 122)
        assert state(s) == [0, None, 1, 0, 0, 0, None, None]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2285, 129)
        s.action(2285, 122)  # completion without start
        assert state(s) == initial
        s.action(2285, 120)
        s.action(2285, 122)  # completion before the authored duration
        s.action(2285, 127)  # overlapping operation
        s.action(2285, 5)    # cannot cross completion boundary
        assert state(s) == [0, None, 1, 0, 0, 0, None, None]
        s.action(2285, 4)
        s.action(2285, 121)
        s.action(2285, 123)  # rollback completion and RNG
        assert state(s) == active
        s.action(2285, 122)
        s.command('undo')
        assert state(s) == active
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 122)
        s.action(2285, 122)
        assert state(s) == [0, 60, 1, 0, 60, 3, None, True]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2285, 126)
        s.action(2285, 120)
        s.action(2285, 4)
        s.action(2285, 123)
        assert state(s) == active
        s.action(2285, 122)
        s.action(2285, 122)
        # Failed general operation: three independently rolled 4s, applied once.
        assert state(s) == [0, 60, 1, 12, 60, 6, None, None]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2285, 120)
        s.action(2285, 124)
        s.action(2285, 5)
        s.action(2285, 122)
        assert state(s) == [0, 0, 1, 0, 61, 0, 'surgical-operation-interrupted', None]
    finally:
        s.close()


def test_lasting_repair(Session, bundle, out):
    def state(s):
        s.action(2285, 150)
        return last(s, 'test.lasting-repair')
    path = out / 'expanded-lasting-repair.zsave'
    s = Session(bundle)
    try:
        s.action(2285, 140)
        s.action(2285, 154)  # cannot claim 4.5 months remain on a four-month injury
        s.action(2285, 141)
        s.action(2285, 143)
        assert state(s) == ['lasting', 1, None, None, 21, 0, 7]
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.action(2285, 140)
        s.action(2285, 151)
        assert state(s) == ['lasting', 1, None, None, 21, 0, 7]
        s.action(2285, 141)
        s.action(2285, 142)
        s.action(2285, 144)
        assert state(s) == ['lasting', 1, None, None, 21, 7200, 7]
        s.action(2285, 143)
        s.command('undo')
        assert state(s) == ['lasting', 1, None, None, 21, 7200, 7]
        s.action(2285, 143)
        s.action(2285, 143)
        s.action(2285, 153)
        s.action(2285, 146)
        s.action(2285, 152)
        assert state(s) == ['lasting', 1, 7410, None, 21, 7200, 10]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 145)
        s.action(2285, 147)
        assert state(s) == ['lasting', 1, 7410, None, 21, 7410, 10]
        s.action(2285, 146)
        s.command('undo')
        assert state(s) == ['lasting', 1, 7410, None, 21, 7410, 10]
        s.action(2285, 146)
        s.action(2285, 146)
        assert state(s) == ['lasting', 0, 7410, 7410, 21, 7410, 10]
    finally:
        s.close()
    for mode, duration in [(148, 'permanent'), (149, 'lasting')]:
        s = Session(bundle)
        try:
            for code in (140, 141, 142, mode, 143, 143):
                s.action(2285, code)
            assert state(s) == [duration, 1, None, None, 33, 7200, 13]
        finally:
            s.close()


def test_surgical_infection(Session, bundle, out):
    def state(s):
        s.action(2285, 164)
        return last(s, 'test.surgical-infection')
    path = out / 'expanded-surgical-infection.zsave'
    s = Session(bundle)
    try:
        for code in (160, 129, 120, 4, 123):
            s.action(2285, code)
        assert state(s) == [None, 0, None, 0, 0, 0, 60, 0]
        s.action(2285, 122)
        s.command('undo')
        assert state(s) == [None, 0, None, 0, 0, 0, 60, 0]
        s.action(2285, 122)
        s.action(2285, 122)
        s.action(2285, 165)  # both advances roll back on crossing the daily boundary
        assert state(s) == [True, 0, None, 0, 0, 0, 60, 6]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 161)
        s.action(2285, 162)
        s.command('undo')
        assert state(s) == [True, 0, None, 0, 0, 0, 86460, 6]
        s.action(2285, 162)
        s.action(2285, 162)
        assert state(s) == [True, 1, None, 1, 1, 1, 86460, 9]
        s.action(2285, 161)
        s.action(2285, 163)
        assert state(s) == [True, 2, True, 1, 1, 0, 172860, 12]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (160, 166, 120, 4, 122):
            s.action(2285, code)
        # First disease resistance roll of 3 gives natural immunity; no wound.
        assert state(s) == [None, 0, None, 0, 0, 0, 60, 6]
    finally:
        s.close()


def test_mortal_stabilization(Session, bundle, out):
    def state(s):
        s.action(2285, 175)
        return last(s, 'test.mortal-stabilization')
    path = out / 'expanded-mortal-stabilization.zsave'
    s = Session(bundle)
    try:
        for code in (170, 171, 172, 182, 174):
            s.action(2285, code)
        assert state(s) == [1, 10, 80, 0, None, 3600, 6]
        s.action(2285, 173)
        s.command('undo')
        assert state(s) == [1, 10, 80, 0, None, 3600, 6]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 173)
        s.action(2285, 173)
        assert state(s) == [0, 9, 80, 0, 3600, 3600, 12]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (170, 176, 171, 172, 173):
            s.action(2285, code)
        assert state(s) == [1, 10, 92, 1, None, 3600, 12]
        s.action(2285, 179)
        assert last(s, 'test.mortal-score') == [8]
        for code in (177, 172, 178, 178):
            s.action(2285, code)
        assert state(s) == [0, 10, 92, 1, 7200, 7200, 24]
    finally:
        s.close()
    for code, score in [(180, 8), (181, 6)]:
        s = Session(bundle)
        try:
            s.action(2285, 170)
            s.action(2285, code)
            s.action(2285, 179)
            assert last(s, 'test.mortal-score') == [score]
        finally:
            s.close()
    s = Session(bundle)
    try:
        for code in (170, 183, 171, 172, 173, 184):
            s.action(2285, code)
        assert last(s, 'test.mortal-complication') == [1, 1]
    finally:
        s.close()


def test_trauma_maintenance(Session, bundle, out):
    def state(s):
        s.action(2285, 195)
        return last(s, 'test.trauma-maintenance')
    path = out / 'expanded-trauma-maintenance.zsave'
    s = Session(bundle)
    try:
        for code in (170, 190, 196, 197):
            s.action(2285, code)
        assert state(s) == [0, 1, 0, 0, 0, 0, None]
        s.action(2285, 172)
        s.command('undo')
        assert state(s) == [0, 1, 0, 0, 0, 0, None]
        s.action(2285, 192)
        s.action(2285, 194)  # cannot discard a partial supported interval
        assert state(s) == [0, 1, 1800, 0, 1800, 0, None]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 192)
        # HT10 would fail roll 11; caregiver Physician12 keeps the patient alive.
        assert state(s) == [0, 1, 0, 1, 3600, 3, None]
        s.action(2285, 194)
        s.action(2285, 194)
        s.action(2285, 192)
        assert state(s) == [0, 1, 0, 1, 5400, 6, 3600]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (170, 191, 190, 193):
            s.action(2285, code)
        assert state(s) == [0, 1, 0, 1, 86400, 3, None]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (170, 190, 171, 172, 173):
            s.action(2285, code)
        assert state(s) == [0, 0, 0, 1, 3600, 9, None]
        s.action(2285, 194)
        assert state(s) == [0, 0, 0, 1, 3600, 9, 3600]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (170, 190, 199):
            s.action(2285, code)
        assert state(s) == [0, 1, 0, 1, 3600, 3, None]
    finally:
        s.close()


def test_mortal_suspension(Session, bundle, out):
    def state(s):
        s.action(2285, 206)
        return last(s, 'test.mortal-suspension')
    path = out / 'expanded-mortal-suspension.zsave'
    s = Session(bundle)
    try:
        for code in (170, 200, 201, 203):
            s.action(2285, code)
        assert state(s) == [None, None, 600, 0, 1, 1, 600, 0]
        s.action(2285, 202)
        s.command('undo')
        assert state(s) == [None, None, 600, 0, 1, 1, 600, 0]
        s.action(2285, 202)
        s.action(2285, 202)
        s.action(2285, 171)  # surgery cannot bypass established suspension
        s.action(2285, 193)
        assert state(s) == [600, None, 600, 1, 1, 1, 87000, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 204)
        s.action(2285, 204)
        s.action(2285, 205)
        assert state(s) == [600, 87000, 0, 1, 1, 1, 88200, 3]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (170, 200, 202, 208, 199):
            s.action(2285, code)
        # Healing can end mortality, but does not terminate suspension or wake.
        assert state(s) == [600, None, 600, 1, 0, 1, 4200, 6]
    finally:
        s.close()


def test_mortal_recovery(Session, bundle):
    for codes, cause, at in [([210], 'healing', 0), ([211], 'survival', 1800),
                             ([171,172,173,173], 'surgery', 3600)]:
        s = Session(bundle)
        try:
            s.action(2285, 170)
            for code in codes:
                s.action(2285, code)
            s.action(2285, 212)
            assert last(s, 'test.mortal-recovery') == [1, cause, at, 10, 9, 9, 1, 0, 0, None]
            if cause == 'healing':
                s.action(2285, 213)
                s.command('undo')
                s.action(2285, 212)
                assert last(s, 'test.mortal-recovery')[-1] is None
                s.action(2285, 213)
                s.action(2285, 213)
                s.action(2285, 212)
                assert last(s, 'test.mortal-recovery') == [1, cause, at, 10, 9, 9, 1, 0, 0, 'none']
        finally:
            s.close()


def test_recovery_wound(Session, bundle, out):
    def state(s):
        s.action(2285, 224)
        return last(s, 'test.recovery-wound')
    path = out / 'expanded-recovery-wound.zsave'
    s = Session(bundle)
    try:
        for code in (170, 210, 220, 221, 223):
            s.action(2285, code)
        initial = [0, 79, 9, 1, 0, 0, 0, 0]
        assert state(s) == initial
        s.action(2285, 222)
        s.command('undo')
        assert state(s) == initial
        s.action(2285, 222)
        s.action(2285, 222)
        assert state(s) == [1, 79, 9, 2, 5, 0, 0, 1]
        s.action(2285, 225)
        assert last(s, 'test.persistent-wound') == [-5, -7, 3, 2, 1, -3]
        s.action(2285, 213)  # cannot replace the committed consequence with none
        assert state(s) == [1, 79, 9, 2, 5, 0, 0, 1]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 222)
        assert state(s) == [1, 79, 9, 2, 5, 0, 0, 1]
    finally:
        s.close()
    for code in (226, 227):
        s = Session(bundle)
        try:
            for setup in (170, 210, 220, code, 222):
                s.action(2285, setup)
            assert state(s) == [0, 79, 9, 1, 0, 0, 0, 0]
        finally:
            s.close()


def test_persistent_dressing(Session, bundle, out):
    def state(s):
        s.action(2285, 235)
        return last(s, 'test.persistent-dressing')
    path = out / 'expanded-persistent-dressing.zsave'
    s = Session(bundle)
    try:
        for code in (0, 230, 232):
            s.action(2285, code)
        assert state(s) == [0, -3, 0, 2, 0, 0, 0]
        s.action(2285, 236)
        assert last(s, 'test.dressing-infection') == ['ready', 10]
        s.action(2285, 231)
        s.command('undo')
        assert state(s) == [0, -3, 0, 2, 0, 0, 0]
        s.action(2285, 231)
        s.action(2285, 231)
        s.action(2285, 234)
        assert state(s) == [1, 0, 0, 2, 1, 60, 3]
        s.action(2285, 236)
        assert last(s, 'test.dressing-infection') == ['ready', 13]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 233)
        assert state(s) == [0, -3, 0, 2, 1, 86400, 3]
        s.action(2285, 234)
        assert state(s) == [1, 0, 0, 2, 2, 86460, 6]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (0, 237, 231, 234):
            s.action(2285, code)
        assert state(s) == [0, -3, 0, 2, 1, 60, 3]
    finally:
        s.close()


def test_poison_entry(Session, bundle):
    # Source B437 route boundaries and B162's existing open-wound entry.
    cases = [(240, 0, 0, 0), (241, 1, 1, 0), (242, 0, 0, 0), (243, 1, 1, 0),
             (244, 0, 0, 0), (245, 1, 0, 0), (246, 0, 0, 0),
             (247, 0, 0, 0), (248, 1, 0, 0), (249, 0, 0, 0), (250, 1, 0, 0),
             (251, 0, 0, 0), (252, 1, 0, 1), (253, 0, 0, 0),
             (254, 0, 0, 0), (255, 0, 0, 0), (256, 1, 0, 0), (257, 1, 0, 0), (258, 1, 0, 0)]
    for code, exposed, persistent, modifier in cases:
        s = Session(bundle)
        try:
            s.action(2285, 0)
            for _ in range(2):
                s.action(2285, code)
                assert last(s, 'test.poison-entry') == ['ready', exposed, persistent, modifier, 2, 0, 0]
        finally:
            s.close()


def test_poison_exposure(Session, bundle, out):
    def state(s):
        s.action(2285, 264)
        return last(s, 'test.poison-exposure')
    path = out / 'expanded-poison-exposure.zsave'
    s = Session(bundle)
    try:
        for code in (265, 261, 260, 260, 262, 5):
            s.action(2285, code)
        assert state(s) == [0, 60, None, 1, 0, 0, 0]
        s.action(2285, 4)
        s.action(2285, 263)
        assert state(s) == [0, 60, None, 1, 0, 60, 0]
        s.action(2285, 262)
        s.command('undo')
        assert state(s) == [0, 60, None, 1, 0, 60, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        s.action(2285, 262)
        s.action(2285, 262)
        assert state(s) == [0, 60, 60, 1, 4, 60, 4]
    finally:
        s.close()
    for preparation, injury, draws in [([266], 0, 3), ([270], 4, 1)]:
        s = Session(bundle)
        try:
            for code in preparation + [267, 260, 268, 262]:
                s.action(2285, code)
            assert state(s) == [0, 30, 30, 1, injury, 30, draws]
        finally:
            s.close()
    for code in (271,):
        s = Session(bundle)
        try:
            s.action(2285, code)
            s.action(2285, 260)
            assert state(s) == [None, None, None, 0, 0, 0, 0]
        finally:
            s.close()

    # B438: two failed cycles unlock only on completion; resistance ends early.
    for resisted in (False, True):
        s = Session(bundle)
        try:
            for code in (269, 265, 260, 4, 262, 262, 274, 275):
                s.action(2285, code)
            assert last(s, 'test.poison-cycle') == [1, 1, 4, 4, 60, 4]
            s.action(2285, 4)
            if resisted:
                s.action(2285, 266)
            s.action(2285, 273)
            s.action(2285, 275)
            assert last(s, 'test.poison-cycle') == [1, 1, 4, 4, 120, 4]
            s.action(2285, 272)
            s.command('undo')
            s.action(2285, 275)
            assert last(s, 'test.poison-cycle') == [1, 1, 4, 4, 120, 4]
            s.command(f':save {path}\n@2286')
        finally:
            s.close()
        s = Session(bundle)
        try:
            s.command(f':restore {path}\n@2286')
            for code in (272, 272, 262, 275):
                s.action(2285, code)
            assert last(s, 'test.poison-cycle') == [2, 0, 0, 4 if resisted else 8, 120, 7 if resisted else 8]
            s.action(2285, 274)
            s.action(2285, 275)
            assert last(s, 'test.poison-cycle')[3] == (3 if resisted else 7)
        finally:
            s.close()

    # B439: doubled swallowed dose uses half timing and twice rolled damage.
    s = Session(bundle)
    try:
        for code in (269, 276, 265, 278):
            s.action(2285, code)
        assert last(s, 'test.poison-dose') == ['ready', 2, 2, 2, 30, 30, -2, 2]
        for code in (260, 268, 262, 275):
            s.action(2285, code)
        assert last(s, 'test.poison-cycle') == [1, 1, 8, 8, 30, 4]
        s.action(2285, 279)  # changing admitted dose invalidates the receipt
        s.action(2285, 268)
        s.action(2285, 264)
        assert last(s, 'test.poison-exposure') == [0, 60, None, 1, 8, 30, 4]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (277, 260, 264):
            s.action(2285, code)
        assert last(s, 'test.poison-exposure') == [None, None, None, 0, 0, 0, 0]
        for code in (276, 269, 279, 278):
            s.action(2285, code)
        assert last(s, 'test.poison-dose') == ['ready', 4, 4, 4, 15, 15, -4, 4]
    finally:
        s.close()

    # B439: one owned remedy changes future resistance or ends the sequence,
    # without refunding the four injury already suffered.
    for terminates in (False, True):
        s = Session(bundle)
        try:
            for code in (269, 265, 260, 4, 262, 280):
                s.action(2285, code)
            if terminates:
                s.action(2285, 284)
            for code in (281, 283, 286):
                s.action(2285, code)
            assert last(s, 'test.poison-antidote') == [1, 0, 0, 0, 4, 60, 4]
            s.action(2285, 282)
            s.command('undo')
            s.action(2285, 286)
            assert last(s, 'test.poison-antidote') == [1, 0, 0, 0, 4, 60, 4]
            for code in (282, 282, 288, 286):
                s.action(2285, code)
            assert last(s, 'test.poison-antidote') == [0, 1, 0 if terminates else 3, int(terminates), 4, 60, 4]
            s.command(f':save {path}\n@2286')
        finally:
            s.close()
        s = Session(bundle)
        try:
            s.command(f':restore {path}\n@2286')
            for code in (282, 287, 4, 272, 286):
                s.action(2285, code)
            assert last(s, 'test.poison-antidote') == [0, 1, 0 if terminates else 3, 1, 4, 120, 4 if terminates else 7]
            s.action(2285, 274)
            s.action(2285, 286)
            assert last(s, 'test.poison-antidote')[4] == 3
        finally:
            s.close()
    s = Session(bundle)
    try:
        for code in (260, 280, 285, 282, 286):
            s.action(2285, code)
        assert last(s, 'test.poison-antidote') == [1, 0, 0, 0, 0, 0, 0]
    finally:
        s.close()

    # B439 treatment times, bonuses and technology cap, with transaction replay.
    for setup, duration, bonus, advance in [(None, 60, 2, None), (293, 10, 2, 298), (294, 20, 4, 300)]:
        s = Session(bundle)
        try:
            if setup is not None:
                s.action(2285, setup)
            for code in (287, 260, 290, 292, 296):
                s.action(2285, code)
            assert last(s, 'test.poison-treatment') == [0, 0, 0, 0, 0]
            s.action(2285, 291)
            s.command('undo')
            s.action(2285, 296)
            assert last(s, 'test.poison-treatment') == [0, 0, 0, 0, 0]
            for code in (291, 291, 296):
                s.action(2285, code)
            assert last(s, 'test.poison-treatment') == [1, bonus, 0, duration, 3]
            s.command(f':save {path}\n@2286')
        finally:
            s.close()
        s = Session(bundle)
        try:
            s.command(f':restore {path}\n@2286')
            s.action(2285, 291)
            if advance is not None:
                s.action(2285, advance)
            for code in (262, 296):
                s.action(2285, code)
            assert last(s, 'test.poison-treatment') == [1, bonus, 0, 60, 6]
        finally:
            s.close()
    for setup in [(295,), (294, 297), (267,)]:
        s = Session(bundle)
        try:
            for code in setup + (260, 291, 296):
                s.action(2285, code)
            assert last(s, 'test.poison-treatment') == [0, 0, 0, 0, 0]
        finally:
            s.close()
    s = Session(bundle)
    try:
        for code in (265, 260, 291, 291, 296):
            s.action(2285, code)
        assert last(s, 'test.poison-treatment') == [1, 0, 0, 60, 3]
    finally:
        s.close()

    # B439 coating: inventory cost and depletion; real miss/dodge/hit dispatch.
    s = Session(bundle)
    try:
        for code in (310, 311, 313, 317):
            s.action(2285, code)
        assert last(s, 'test.poison-coating') == [6, 0, 0, 0]
        s.action(2285, 312)
        s.command('undo')
        s.action(2285, 317)
        assert last(s, 'test.poison-coating') == [6, 0, 0, 0]
        for code in (312, 312, 265, 314, 287, 314, 317):
            s.action(2285, code)
        assert last(s, 'test.poison-coating') == [5, 2, 0, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        for code in (315, 314, 317):
            s.action(2285, code)
        assert last(s, 'test.poison-coating') == [5, 3, 0, 1]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (310, 316, 312):
            s.action(2285, code)
        for count in range(1, 4):
            s.action(2285, 318)
            s.action(2285, 317)
            assert last(s, 'test.poison-coating') == [0, count, count, int(count == 3)]
    finally:
        s.close()

    # Independent B439 catalogue values, not derived from the runtime helper.
    for setup, expected in [(320, [1, 1, 1, 3600, 3600, 8, 1, 1, -2]),
                            (321, [4, 2, 1, 0, 1, 1, 4, 0, 0]),
                            (322, [4, 2, 1, 900, 1, 1, 4, 0, 0])]:
        s = Session(bundle)
        try:
            for code in (setup, 324, 265, 260):
                s.action(2285, code)
            assert last(s, 'test.poison-catalogue') == expected
            if setup != 321:
                s.action(2285, 325 if setup == 320 else 326)
            s.action(2285, 262)
            s.action(2285, 275)
            if setup == 320:
                assert last(s, 'test.poison-cycle') == [1, 7, 4, 4, 3600, 4]
                for _ in range(7):
                    s.action(2285, 328)
                s.action(2285, 275)
                assert last(s, 'test.poison-cycle') == [8, 0, 0, 32, 28800, 32]
            else:
                assert last(s, 'test.poison-cycle') == [1, 0, 0, 16, 0 if setup == 321 else 900, 4]
        finally:
            s.close()
    s = Session(bundle)
    try:
        for code in (323, 320, 327, 260, 264):
            s.action(2285, code)
        assert last(s, 'test.poison-stock') == [3, 6, 4, 1]
        assert last(s, 'test.poison-exposure') == [None, None, None, 0, 0, 0, 0]
    finally:
        s.close()

    # B439 dual-route catalogue: fixed contact injury draws no damage dice.
    for setup, expected, count, injury, end_time, draws in [
        (330, [6, 10, 0, 0, 28800, 24, 0, 1, -4], 24, 24, 662400, 72),
        (331, [6, 10, 0, 7200, 3600, 6, 1, 1, -1], 6, 24, 25200, 24),
    ]:
        s = Session(bundle)
        try:
            for code in (setup, 324, 265, 260):
                s.action(2285, code)
            assert last(s, 'test.poison-catalogue') == expected
            if setup == 331:
                s.action(2285, 332)
            s.action(2285, 262)
            s.action(2285, 275)
            assert last(s, 'test.poison-cycle') == ([1, 23, 1, 1, 0, 3] if setup == 330 else [1, 5, 4, 4, 7200, 4])
            for _ in range(count - 1):
                s.action(2285, 333)
            s.action(2285, 275)
            assert last(s, 'test.poison-cycle') == [count, 0, 0, injury, end_time, draws]
        finally:
            s.close()
    for setup in [(330, 334), (330, 335), (336,)]:
        s = Session(bundle)
        try:
            for code in setup + (260, 264):
                s.action(2285, code)
            assert last(s, 'test.poison-exposure') == [None, None, None, 0, 0, 0, 0]
        finally:
            s.close()

    # B438/B439 thresholds and B421 temporary-DX defense/secondary exceptions.
    s = Session(bundle)
    try:
        for code in (347, 0, 340, 265, 260, 4, 262, 341):
            s.action(2285, code)
        assert last(s, 'test.poison-thresholds') == [0, -2, -4, -4, -6]
        assert last(s, 'test.poison-symptom') == [8, 0, 0, 0, 20, 10]
        for index, penalty in [(2, -2), (3, -4), (4, -6)]:
            s.action(2285, 333)
            s.action(2285, 341)
            assert last(s, 'test.poison-symptom') == [index * 8, penalty, penalty, 0, 20, index * 8 + 2]
        for code in (280, 284, 342, 282):
            s.action(2285, code)
        s.action(2285, 343)
        s.command('undo')
        s.action(2285, 341)
        assert last(s, 'test.poison-symptom') == [32, -6, -6, 0, 20, 34]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        for code, injury, penalty in [(343, 26, -4), (344, 19, -2), (345, 13, 0)]:
            s.action(2285, code)
            s.action(2285, 341)
            assert last(s, 'test.poison-symptom') == [injury, penalty, penalty, 0, 20, injury]
        s.action(2285, 346)
        s.action(2285, 341)
        assert last(s, 'test.poison-symptom') == [13, 0, 0, 0, 20, 19]
    finally:
        s.close()

    # B438 cyclic fatigue protection; ordinary FP arithmetic and overflow share
    # the existing health ledger. Fixed four-point effects draw only resistance.
    for overflow in (False, True):
        s = Session(bundle)
        try:
            if overflow:
                s.action(2285, 353)
            for code in (350, 265, 260, 263, 352):
                s.action(2285, code)
            assert last(s, 'test.poison-fatigue') == [9 if overflow else 0, 0, 0, 0, 0, 0, 0]
            s.action(2285, 262)
            s.command('undo')
            s.action(2285, 352)
            assert last(s, 'test.poison-fatigue') == [9 if overflow else 0, 0, 0, 0, 0, 0, 0]
            for code in (262, 262, 352):
                s.action(2285, code)
            assert last(s, 'test.poison-fatigue') == [13 if overflow else 4, 3 if overflow else 0, 4, 3 if overflow else 0, 1, 0, 3]
            s.command(f':save {path}\n@2286')
        finally:
            s.close()
        s = Session(bundle)
        try:
            s.command(f':restore {path}\n@2286')
            for code in (351, 352):
                s.action(2285, code)
            assert last(s, 'test.poison-fatigue') == [12 if overflow else 4, 3 if overflow else 0, 4, 3 if overflow else 0, 1, 600, 3]
            for code in (354, 272, 272, 352):
                s.action(2285, code)
            assert last(s, 'test.poison-fatigue') == [16 if overflow else 8, 7 if overflow else 0, 0, 0, 2, 1200, 6]
            for code in (351, 352):
                s.action(2285, code)
            assert last(s, 'test.poison-fatigue') == [15 if overflow else 7, 7 if overflow else 0, 0, 0, 2, 1800, 6]
        finally:
            s.close()

    # B439 clue identification can authorize later care for the same examiner.
    s = Session(bundle)
    try:
        for code in (360, 293, 287, 260, 361, 363, 364):
            s.action(2285, code)
        assert last(s, 'test.poison-identification') == [0, 0, 0, 0, None]
        s.action(2285, 362)
        s.command('undo')
        s.action(2285, 364)
        assert last(s, 'test.poison-identification') == [0, 0, 0, 0, None]
        for code in (362, 362, 364):
            s.action(2285, code)
        assert last(s, 'test.poison-identification') == [1, 1, 5, 3, 14]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        for code in (367, 291, 296):
            s.action(2285, code)
        assert last(s, 'test.poison-treatment') == [1, 2, 0, 15, 6]
        for code in (368, 262, 264):
            s.action(2285, code)
        assert last(s, 'test.poison-exposure') == [0, 60, 60, 1, 0, 60, 9]
    finally:
        s.close()
    for setup, expected in [((366,), [1, 1, 5, 3, 14]), ((276,), [1, 1, 5, 3, 16]),
                            ((365,), [0, 0, 0, 0, None])]:
        s = Session(bundle)
        try:
            for code in (360, 287) + setup + (260, 362, 364):
                s.action(2285, code)
            assert last(s, 'test.poison-identification') == expected
        finally:
            s.close()
    s = Session(bundle)
    try:
        for code in (360, 293, 265, 260, 362, 367, 291, 364):
            s.action(2285, code)
        assert last(s, 'test.poison-identification') == [1, 0, 5, 3, 14]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (360, 269, 265, 260, 4, 262, 365, 287, 362, 364):
            s.action(2285, code)
        assert last(s, 'test.poison-identification') == [1, 1, 65, 7, 14]
    finally:
        s.close()

    # Antidote knowledge uses the same exposure and actual identifying examiner.
    s = Session(bundle)
    try:
        for code in (360, 287, 260, 362, 280, 370, 281, 283, 375):
            s.action(2285, code)
        assert last(s, 'test.antidote-stock') == [1, 0]
        s.action(2285, 282)
        s.command('undo')
        s.action(2285, 375)
        assert last(s, 'test.antidote-stock') == [1, 0]
        for code in (282, 282, 286):
            s.action(2285, code)
        assert last(s, 'test.poison-antidote') == [0, 1, 3, 0, 0, 5, 3]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        for code in (282, 371, 262, 286):
            s.action(2285, code)
        assert last(s, 'test.poison-antidote') == [0, 1, 3, 1, 0, 60, 6]
    finally:
        s.close()
    for invalid in (265, 372, 373, 374):
        s = Session(bundle)
        try:
            for code in (360, 287, 260):
                s.action(2285, code)
            if invalid == 265:
                s.action(2285, invalid)
            for code in (362, 280, 370):
                s.action(2285, code)
            if invalid != 265:
                s.action(2285, invalid)
            for code in (282, 375):
                s.action(2285, code)
            assert last(s, 'test.antidote-stock') == [1, 0]
        finally:
            s.close()

    # B438: environmental retries use the delay, or one second when immediate.
    s = Session(bundle)
    try:
        for code in (380, 266, 383, 384, 384, 391, 385, 387):
            s.action(2285, code)
        assert last(s, 'test.poison-environment') == [1, 0, 0, None, 1, 1, 0, 0, 3]
        s.action(2285, 388)
        s.command('undo')
        s.action(2285, 387)
        assert last(s, 'test.poison-environment') == [1, 0, 0, None, 1, 1, 0, 0, 3]
        for code in (382, 265, 389, 387):
            s.action(2285, code)
        assert last(s, 'test.poison-environment') == [1, 0, 0, None, 1, 1, 0, 1, 3]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        for code in (385, 385, 387):
            s.action(2285, code)
        assert last(s, 'test.poison-environment') == [1, 1, 1, None, 2, 0, 4, 1, 7]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (381, 266, 383, 390, 384, 387):
            s.action(2285, code)
        assert last(s, 'test.poison-environment') == [120, 0, 0, None, 1, 2, 0, 60, 3]
        for code in (390, 265, 385, 388, 387):
            s.action(2285, code)
        assert last(s, 'test.poison-environment') == [180, 0, 1, 120, 2, 1, 4, 120, 7]
        for code in (390, 266, 386, 387):
            s.action(2285, code)
        assert last(s, 'test.poison-environment') == [180, 1, 1, 120, 3, 0, 4, 180, 10]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (380, 266, 383, 384, 388, 388, 390, 385, 387):
            s.action(2285, code)
        assert last(s, 'test.poison-environment') == [1, 1, 0, 0, 1, 0, 0, 60, 3]
    finally:
        s.close()

    # B438 physiology-specific policy: explicit target, no inferred ancestry immunity.
    s = Session(bundle)
    try:
        for code in (400, 261, 260, 260, 262, 404):
            s.action(2285, code)
        assert last(s, 'test.poison-susceptibility') == [1, 1, 1, 0, 0, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        for code in (4, 262, 404):
            s.action(2285, code)
        assert last(s, 'test.poison-susceptibility') == [1, 1, 1, 0, 60, 0]
    finally:
        s.close()
    for setup, expected in [((400, 401, 287), [1, 0, 1, 0, 60, 3]),
                            ((400, 270), [1, 1, 1, 0, 60, 0]),
                            ((400, 402), [0, 0, 0, 0, 60, 0]),
                            ((400, 401, 270), [0, 0, 0, 0, 60, 0])]:
        s = Session(bundle)
        try:
            for code in setup + (260, 4, 262, 404):
                s.action(2285, code)
            assert last(s, 'test.poison-susceptibility') == expected
        finally:
            s.close()
    s = Session(bundle)
    try:
        for code in (400, 401, 260, 403, 4, 262, 404):
            s.action(2285, code)
        assert last(s, 'test.poison-susceptibility') == [1, 0, 0, 0, 0, 0]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (380, 406, 383, 384, 390, 387):
            s.action(2285, code)
        assert last(s, 'test.poison-environment') == [0, 1, 0, None, 0, 0, 0, 60, 0]
    finally:
        s.close()

    # B439 smoke: no damage, continuous coughing, then failure-margin minutes.
    s = Session(bundle)
    try:
        for code in (420, 266, 383, 421, 384, 422):
            s.action(2285, code)
        assert last(s, 'test.poison-smoke') == [0, None, None, 0, 0, 10, 3, 0]
        for code in (421, 265, 389, 422):
            s.action(2285, code)
        assert last(s, 'test.poison-smoke') == [0, None, None, 0, 0, 20, 3, 0]
        s.action(2285, 385)
        s.command('undo')
        s.action(2285, 422)
        assert last(s, 'test.poison-smoke') == [0, None, None, 0, 0, 20, 3, 0]
        for code in (385, 385, 423, 422):
            s.action(2285, code)
        assert last(s, 'test.poison-smoke') == [1, 420, None, 0, 0, 120, 6, 1]
        s.action(2285, 388)
        s.command('undo')
        s.action(2285, 422)
        assert last(s, 'test.poison-smoke') == [1, 420, None, 0, 0, 120, 6, 1]
        for code in (388, 388, 422):
            s.action(2285, code)
        assert last(s, 'test.poison-smoke') == [1, 420, 540, 0, 0, 120, 6, 1]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        for code in (424, 422):
            s.action(2285, code)
        assert last(s, 'test.poison-smoke') == [1, 420, 540, 0, 0, 539, 6, 1]
        for code in (382, 422):
            s.action(2285, code)
        assert last(s, 'test.poison-smoke') == [0, 420, 540, 0, 0, 540, 6, 1]
    finally:
        s.close()
    s = Session(bundle)
    try:
        for code in (420, 425, 383, 422):
            s.action(2285, code)
        assert last(s, 'test.poison-smoke') == [0, None, None, 0, 0, 0, 0, 0]
    finally:
        s.close()

    # B439 respiratory/vision irritant routes have distinct owned conditions.
    for setup in (440, 441):
        coughing, blind, vision = (1, 0, 9) if setup == 440 else (0, 1, None)
        s = Session(bundle)
        try:
            for code in (setup, 265, 383, 384, 384, 423, 442):
                s.action(2285, code)
            assert last(s, 'test.poison-irritant') == [coughing, blind, None, 0, 0, 100, 3, vision]
            s.action(2285, 388)
            s.command('undo')
            s.action(2285, 442)
            assert last(s, 'test.poison-irritant') == [coughing, blind, None, 0, 0, 100, 3, vision]
            for code in (388, 442):
                s.action(2285, code)
            assert last(s, 'test.poison-irritant') == [coughing, blind, 640, 0, 0, 100, 3, vision]
            s.command(f':save {path}\n@2286')
        finally:
            s.close()
        s = Session(bundle)
        try:
            s.command(f':restore {path}\n@2286')
            for code in (443, 442):
                s.action(2285, code)
            assert last(s, 'test.poison-irritant') == [coughing, blind, 640, 0, 0, 639, 3, vision]
            for code in (382, 442):
                s.action(2285, code)
            assert last(s, 'test.poison-irritant') == [0, 0, 640, 0, 0, 640, 3, 10]
        finally:
            s.close()
    for invalid in (444, 445, 447):
        s = Session(bundle)
        try:
            for code in (441, invalid, 383, 384, 442):
                s.action(2285, code)
            assert last(s, 'test.poison-irritant') == [0, 0, None, 0, 0, 0, 0, 10]
        finally:
            s.close()
    s = Session(bundle)
    try:
        s.action(2285, 446)
        assert last(s, 'test.cloud-opacity') == [-2, -4, -6, 4]
    finally:
        s.close()


def test_coughing(Session, bundle, out):
    def state(s):
        s.action(2285, 413)
        return last(s, 'test.coughing')
    clear = [0, 10, 10, 10, 10, 10, 10, 10, 20, 0, 0]
    active = [1, 7, 9, 9, 9, None, 7, 10, 20, 0, 0]
    path = out / 'expanded-coughing.zsave'
    s = Session(bundle)
    try:
        for code in (410, 412):
            s.action(2285, code)
        assert state(s) == clear
        s.action(2285, 411)
        s.command('undo')
        assert state(s) == clear
        for code in (411, 411, 416):
            s.action(2285, code)
        assert state(s) == active
        s.action(2285, 414)
        assert state(s) == active[:-2] + [59, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        assert state(s) == active[:-2] + [59, 0]
        s.action(2285, 415)
        assert state(s) == clear[:-2] + [60, 0]
        s.action(2285, 411)  # expired receipt must not restart its duration
        assert state(s) == clear[:-2] + [60, 0]
        s.action(2285, 416)
        assert state(s) == active[:-2] + [60, 0]
    finally:
        s.close()


def test_temporary_blindness(Session, bundle, out):
    def state(s):
        s.action(2285, 433)
        return last(s, 'test.temporary-blindness')
    clear = [0, 10, 10, 10, 10, 0, 0, 0]
    blind = [1, None, 10, None, 10, 0, 0, 0]
    path = out / 'expanded-temporary-blindness.zsave'
    s = Session(bundle)
    try:
        for code in (430, 432):
            s.action(2285, code)
        assert state(s) == clear
        s.action(2285, 431)
        s.command('undo')
        assert state(s) == clear
        for code in (431, 431, 435, 436):
            s.action(2285, code)
        assert state(s) == blind
        s.action(2285, 414)
        assert state(s) == blind[:-2] + [59, 0]
        s.command(f':save {path}\n@2286')
    finally:
        s.close()
    s = Session(bundle)
    try:
        s.command(f':restore {path}\n@2286')
        assert state(s) == blind[:-2] + [59, 0]
        s.action(2285, 415)
        s.action(2285, 431)
        assert state(s) == clear[:-2] + [60, 0]
    finally:
        s.close()
