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
