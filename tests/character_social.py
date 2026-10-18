"""Independent source expectations for the focused social decision tables."""
from native import fresh, last, load_host
from support import ROOT


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


def state(s):
    s.action(1450)
    return last(s, 'test.character-social-state')


def test_character_contracts(s):
    initial = state(s)
    s.action(1452)
    assert last(s, 'test.character-cost') == [53,12,11]
    for difficulty in range(4):
        for points, offset in [(1,0),(2,1),(4,2),(8,3),(12,4)]:
            s.action(1453,difficulty,points,0)
            assert last(s, 'test.skill-table') == [12 + offset - difficulty]
    for points, expected in [(2,None),(3,9),(6,10),(12,11),(24,12)]:
        s.action(1453,3,points,1)
        assert last(s, 'test.skill-table') == [expected]
    s.action(1454)
    assert last(s, 'test.skill-defaults') == [14,12,None,13]
    for variant, reason in [(1,'secondary-limit'),(2,'duplicate-language'),(3,'native-language'),
                            (4,'incompatible-traits'),(5,'point-budget')]:
        s.action(1455,variant)
        assert last(s, 'test.invalid-character') == [reason]
    s.action(1456)
    assert last(s, 'test.template-ownership') == [8,4,1]
    # Expanded difficulty does not widen the accepted core/Lite declarations.
    for variant in range(1, 7):
        s.action(1457, variant)
        assert last(s, 'test.skill-definition') == ['accepted' if variant == 3 else 'rejected']
    for variant, expected in [
            (1, ['wildcard-disabled']), (2, ['wildcard-difficulty']),
            (3, ['wildcard-default']), (4, ['wildcard-default']),
            (5, ['accepted', 3, 7])]:
        s.action(1458, variant)
        assert last(s, 'test.wildcard-creation') == expected
    assert state(s) == initial


def test_social_transactions(s):
    initial = state(s)
    assert initial == [0,0,10,0,0,0,0,0]
    s.action(1451)
    assert last(s, 'test.private-preview') == ['ready',None,None,None]
    s.action(1400,2)
    assert state(s) == initial
    s.action(1400,1)
    assert last(s, 'test.private-reaction') == ['resolved',5]
    after = state(s)
    assert after == [1,1,10,0,0,0,6,0]
    s.command('undo')
    assert state(s) == initial
    s.action(1400,1); s.action(1400,1)
    assert last(s, 'test.private-reaction') == ['reused',5]
    assert state(s) == after
    s.action(1451)
    assert last(s, 'test.private-preview') == ['reused',None,None,None]
    s.action(1400,5)
    assert state(s) == after
    s.action(1400,4)
    assert last(s, 'test.paid-answer') == ['resolved',5]
    paid = state(s)
    assert paid == [1,1,5,5,1,0,6,0]
    s.command('undo')
    assert state(s) == after
    s.action(1400,4); s.action(1400,4)
    assert last(s, 'test.paid-answer') == ['reused',0]
    assert state(s) == paid
    s.action(1400,7)
    assert state(s) == paid
    s.action(1400,6)
    loyal = state(s)
    assert loyal == [1,1,5,5,1,1,9,0]
    s.action(1400,6)
    assert state(s) == loyal


def test_failed_recognition(s):
    s.action(1400,3)
    assert last(s, 'test.private-reaction') == ['resolved',4]
    before = state(s)
    s.action(1400,3)
    assert last(s, 'test.private-reaction') == ['reused',4]
    assert state(s) == before == [1,1,10,0,0,0,6,0]


def test_social_save(Session,bundle,out):
    path = out / 'character-social.zsave'
    first = Session(bundle)
    try:
        first.action(1400,3); first.action(1400,4); first.action(1400,6)
        saved = state(first)
        first.command(f':save {path}\n@1450')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1450')
        assert state(second) == saved
        second.action(1400,3); second.action(1400,4); second.action(1400,6)
        assert state(second) == saved
    finally:
        second.close()


def test_trait_prices(s):
    for base, first, second, expected in [(10,50,-75,8),(-25,-10,0,-22),
                                         (-15,0,-90,-3),(-1,-80,0,0),(1,-80,0,1),
                                         (-100,-65,10,-45),(15,20,0,18)]:
        s.action(1500,base,first,second)
        assert last(s, 'test.modified-price') == [expected]
    for rating, expected in [(6,-10),(9,-7),(12,-5),(15,-2)]:
        s.action(1501,-5,rating)
        assert last(s, 'test.self-control-price') == [expected]
    s.action(1502)
    assert last(s, 'test.trait-price-contract') == ['unapproved-trait',15,-7,'self-control-modifier-combination']


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build("expanded-social", ROOT / "tests/fixtures/expanded-social.t")
    fresh(Session, bundle, test_social_status)
    fresh(Session, bundle, test_combat_reactions)
    fresh(Session, bundle, test_aid_reactions)
    fresh(Session, bundle, test_information_reactions)
    fresh(Session, bundle, test_trade_reactions)
    fresh(Session, bundle, test_trade_modifiers)
    print("  expanded social source tables: passed", flush=True)
    combined = build.build('character-social', ROOT / 'tests/fixtures/character-social.t')
    for case in [test_character_contracts, test_social_transactions, test_failed_recognition]:
        fresh(Session, combined, case)
    test_social_save(Session, combined, build.out)
    print('  character/social validation, transactions and persistence: passed', flush=True)
    pricing = build.build('expanded-pricing', ROOT / 'tests/fixtures/expanded-pricing.t')
    fresh(Session, pricing, test_trait_prices)
    print('  expanded trait price contracts: passed', flush=True)
