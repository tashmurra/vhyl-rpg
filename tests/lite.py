"""Independent Lite table, boundary, gameplay, and persistence expectations."""
from pathlib import Path
import sys

from native import fresh, last, load_host
from support import ROOT, run

FIELDS = '''hp fp shock stunned unconscious dead mortal posture rng draws seconds rest luck
traits turn seconds_combat enemy_injury ammo reload exposure_clock exposure_cycles exposure_done last_roll
hunger thirst sleep_debt temperature_fatigue climate_clock maneuver aim ready burning points skills'''.split()


def state(session):
    session.action(990)
    return dict(zip(FIELDS, last(session, 'test.lite'), strict=True))


def action(session, code, *args):
    session.action(600, code, *args)


def test_tables(session):
    initial = state(session)
    for strength, dexterity, health, weight, expected in (
        (10, 10, 10, 0, [2000, 20, 5, 0, 5]),
        (11, 11, 10, 2400, [2400, 21, 5, 0, 5]),
        (10, 10, 10, 2001, [2000, 20, 5, 1, 4]),
        (10, 10, 10, 4001, [2000, 20, 5, 2, 3]),
        (10, 10, 10, 6001, [2000, 20, 5, 3, 2]),
        (10, 10, 10, 12001, [2000, 20, 5, 4, 1]),
        (10, 10, 10, 20001, [2000, 20, 5, 5, 0]),
    ):
        session.action(991, strength, dexterity, health, weight)
        assert last(session, 'test.derived')[:5] == expected
    for damage in range(0, 13):
        for armor in (0, 1, 4, 20):
            for divisor in (1, 2):
                for damage_type, numerator, denominator in [('cr', 1, 1), ('cut', 3, 2), ('imp', 2, 1), ('pi-', 1, 2)]:
                    for half in (0, 1):
                        penetration = max(0, damage // (2 if half else 1) - armor // divisor)
                        expected = max(1, penetration * numerator // denominator) if penetration else 0
                        session.action(992, damage, armor, divisor, damage_type, half)
                        assert last(session, 'test.penetration') == [expected]
    session.action(993)
    traits = [entry['values'] for entry in session.log if entry['id'] == 'test.trait']
    skills = [entry['values'] for entry in session.log if entry['id'] == 'test.skill']
    weapons = [entry['values'] for entry in session.log if entry['id'] == 'test.weapon']
    assert len(traits) >= 80 and len(skills) >= 85 and len(weapons) >= 26
    assert dict(traits)['combat-reflexes'] == 15
    assert dict(traits)['bad-temper'] == -10
    assert all(modes >= 1 for _, modes in weapons)
    thrust = [(1,-6),(1,-6),(1,-5),(1,-5),(1,-4),(1,-4),(1,-3),(1,-3),(1,-2),(1,-2),
              (1,-1),(1,-1),(1,0),(1,0),(1,1),(1,1),(1,2),(1,2),(2,-1),(2,-1)]
    swing = [(1,-5),(1,-5),(1,-4),(1,-4),(1,-3),(1,-3),(1,-2),(1,-2),(1,-1),(1,0),
             (1,1),(1,2),(2,-1),(2,0),(2,1),(2,2),(3,-1),(3,0),(3,1),(3,2)]
    for strength in range(1,21):
        session.action(991, strength, 10, 10, 0)
        assert last(session, 'test.derived')[5:] == list(thrust[strength-1] + swing[strength-1])
    assert state(session) == initial


def test_equipment_and_defenses(session):
    for name, expected in (
        ('broadsword', [500,300,'swing',0,1,'cut',0,0,0,0,10,0]),
        ('longbow', [200,300,'thrust',0,2,'imp',3,150,200,1,11,2]),
        ('crossbow', [150,600,'thrust',0,4,'imp',4,200,250,1,7,4]),
        ('auto-pistol-9mm', [350,240,'fixed',2,2,'pi',2,150,1850,9,9,3]),
        ('sniper-rifle', [5600,1750,'fixed',9,1,'pi',6,1500,5500,5,11,3]),
    ):
        session.action(998,name)
        assert last(session,'test.weapon-data') == expected
    for posture, maneuver, expected in (
        ('standing','nothing',[11,9,8]), ('lying','nothing',[8,6,5]),
        ('standing','all-out-attack',[None,None,None]),
        ('standing','move-attack',[11,9,None]), ('standing','all-out-defense',[13,9,8]),
    ):
        session.action(999,posture,maneuver)
        assert last(session,'test.defenses') == expected
    for total, expected in ((-1,'disastrous'),(0,'disastrous'),(1,'very-bad'),(3,'very-bad'),
                            (4,'bad'),(6,'bad'),(7,'poor'),(9,'poor'),(10,'neutral'),
                            (12,'neutral'),(13,'good'),(15,'good'),(16,'very-good'),
                            (18,'very-good'),(19,'excellent')):
        session.action(1000,total)
        assert last(session,'test.reaction') == [expected]


def test_health(session):
    action(session, 6, 20, 10)
    action(session, 1, 10)
    current = state(session)
    assert current['hp'] == 0 and not current['unconscious'] and not current['dead'], current
    action(session, 1, 10)
    assert not state(session)['dead'], 'successful HT death check killed character'
    action(session, 1, 40)
    assert state(session)['dead'], 'minus five HP did not kill'
    before = state(session)
    action(session, 3, 86400)
    assert state(session) == before, 'rest changed a dead character'


def test_fatigue(session):
    action(session, 2, 10)
    assert state(session)['fp'] == 0 and state(session)['hp'] == 10
    action(session, 2, 1)
    assert state(session)['fp'] == -1 and state(session)['hp'] == 9
    action(session, 3, 599)
    assert state(session)['fp'] == -1
    action(session, 3, 1)
    assert state(session)['fp'] == 0 and state(session)['rest'] == 0
    action(session, 3, 600)
    assert state(session)['fp'] == 1


def test_traits(session):
    action(session, 5, 'acute-vision', 3)
    session.action(994, 'vision')
    assert last(session, 'test.score') == [13]
    action(session, 5, 'high-pain-threshold', 1)
    action(session, 1, 3)
    assert state(session)['shock'] == 0
    action(session, 5, 'luck', 1)
    action(session, 14)
    original, selected = last(session, 'test.luck')
    assert selected <= original and state(session)['luck'] == 3600


def test_reload(session):
    action(session, 12, 'auto-pistol-9mm', 0)
    for expected in (1, 2):
        action(session, 13)
        assert state(session)['ammo'] == 0 and state(session)['reload'] == expected
    action(session, 13)
    assert state(session)['ammo'] == 9 and state(session)['reload'] == 0


def test_exposure(session):
    action(session, 10, 9)
    assert state(session)['exposure_cycles'] == 3
    action(session, 10, 1)
    assert state(session)['exposure_cycles'] == 2
    action(session, 10, 19)
    assert state(session)['exposure_cycles'] == 2
    action(session, 10, 1)
    assert state(session)['exposure_cycles'] == 1
    action(session, 10, 20)
    assert state(session)['exposure_done'] is True


def test_travel(session):
    session.action(995, 0, 100)
    assert last(session, 'test.travel') == [20, 7, 3500, 7500]
    session.action(995, 20, 16001)
    assert last(session, 'test.travel') == [40, 14, 0, 7500]


def test_character(session):
    session.action(996)
    assert not any(event['id'] == 'test.character-error' for event in session.log), session.log
    assert last(session, 'test.character') == [92, -13, 1000, 0]
    for skill, points, expected in [('karate', 0, None), ('karate', 1, 8), ('karate', 2, 9),
                                    ('karate', 4, 10), ('karate', 8, 11), ('karate', 12, 12),
                                    ('climbing', 0, 5), ('climbing', 1, 9), ('brawling', 1, 10)]:
        session.action(997, skill, points)
        assert last(session, 'test.training') == [expected]
    action(session, 23)
    current = state(session)
    assert current['points'] == 6 and current['traits'] == 0 and current['skills'] == 1
    before = state(session)['draws']
    action(session,24,0)
    assert last(session,'test.reading')[2] == 'illiterate'
    action(session,24,3)
    assert last(session,'test.reading') == ['resolved','automatic',None]
    assert state(session)['draws'] == before
    action(session,24,1)
    assert state(session)['draws'] == before + 3
    action(session,25)
    assert last(session,'test.default-skill') == ['climbing',5]
    action(session,26)
    assert last(session,'test.default-aid') == [16]


def test_blocked_combat(session):
    action(session, 6, 20, 10)
    action(session, 8)
    before = state(session)
    action(session, 9, 'aim', '')
    assert last(session, 'test.combat')[:2] == ['blocked', 'cannot-aim']
    assert state(session) == before
    action(session, 9, 'ready', 'reload')
    assert state(session) == before
    action(session, 12, 'auto-pistol-9mm', 0)
    before = state(session)
    action(session, 9, 'attack', '')
    assert last(session, 'test.combat')[:2] == ['blocked', 'empty']
    assert state(session) == before


def test_care(session):
    action(session, 1, 3)
    action(session, 17)
    assert state(session)['hp'] == 8
    action(session, 17)
    assert state(session)['hp'] == 8, 'fresh treatment farmed bandaging'
    action(session, 27)
    action(session, 3, 60)
    current = state(session)
    assert current['shock'] == 0 and not current['stunned'], 'quiet recovery retained combat penalties'


def test_needs(session):
    action(session, 16, 2, 1, 86400)
    current = state(session)
    assert (current['hunger'], current['thirst'], current['sleep_debt']) == (1, 3, 3), current
    action(session, 3, 600)
    assert state(session)['thirst'] == 3, 'single drink cleared dehydration'
    action(session, 20, 28800)
    assert state(session)['sleep_debt'] == 2
    action(session, 20, 7200)
    assert state(session)['sleep_debt'] == 0
    action(session, 3, 86400)
    assert state(session)['thirst'] == 0


def test_climate(session):
    action(session, 19, 10, 1799)
    assert state(session)['temperature_fatigue'] == 0
    action(session, 19, 10, 1)
    assert state(session)['temperature_fatigue'] == 1
    action(session, 3, 600)
    assert state(session)['fp'] == 9, 'rest in cold recovered exposure fatigue'
    action(session, 19, 70, 0)
    action(session, 3, 600)
    assert state(session)['fp'] == 10
    action(session, 21, 10)
    assert state(session)['burning'] == 3
    action(session, 22)
    assert state(session)['burning'] == 0


def test_transactions(session):
    before = state(session)
    action(session, 1, 3)
    after = state(session)
    assert after['hp'] == 7
    session.action(3)
    assert state(session) == before
    action(session, 11)
    assert state(session) == before, 'exception retained injury'
    action(session, 8)
    started = state(session)
    action(session, 9, 'attack', '')
    combat = state(session)
    session.action(3)
    assert state(session) == started
    action(session, 9, 'attack', '')
    assert state(session) == combat, 'replayed attack diverged'


def test_restore(Session, bundle, out):
    save = out / 'lite.zsave'
    first = Session(bundle)
    try:
        action(first, 5, 'acute-vision', 3)
        action(first, 8)
        action(first, 9, 'all-out-defense', 'dodge')
        saved = state(first)
        first.command(f':save {save}\n@990')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
        action(first, 9, 'attack', '')
        future = state(first)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {save}\n@990')
        assert any('[restore ok code=0]' in line for line in second.raw_lines)
        assert state(second) == saved
        action(second, 9, 'attack', '')
        assert state(second) == future
    finally:
        second.close()


def test(build, bundle=None):
    standalone = bundle is not None
    Session = load_host(build.vhyl)
    bundle = bundle or build.build('lite', ROOT / 'tests/fixtures/lite.t')
    for check in (test_tables, test_equipment_and_defenses, test_health, test_fatigue, test_traits, test_reload,
                  test_exposure, test_travel, test_character, test_blocked_combat, test_care,
                  test_needs, test_climate, test_transactions):
        fresh(Session, bundle, check)
        print(f'  {check.__name__}: passed', flush=True)
    test_restore(Session, bundle, build.out)
    print('  Lite cross-process continuation: passed', flush=True)
    if not standalone:
        example = build.build('lite-yard', ROOT / 'examples/lite/main.t')
        output = run([sys.executable, ROOT / 'examples/lite/host.py', example,
                      '--vhyl', build.vhyl], timeout=60,
                     input='hike\nrest\nspar\ndefend\nattack\nstop\nstatus\n:quit\n')
        assert 'You hike for an hour.' in output and 'HP 10/10; energy 11/12' in output, output
        assert 'The bout begins.' in output and 'The trainer stops the bout.' in output, output
        assert 'turn.failed' not in output and 'Milestone: 2 points' in output, output
        print('  Lite training-yard integration: passed', flush=True)


if __name__ == '__main__':
    from support import Build
    test(Build('', ROOT / '.tools/vhyl', ROOT / 'build'), Path(sys.argv[1]))
