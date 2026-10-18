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
    for check in [test_numbers,test_negative_pricing,test_technique_bases,test_learning_requirements,test_familiarity,test_technology_modifiers,test_optional_specialties,test_relative_skill,test_technology_learning,test_recognition,test_recognition_failure,test_recognition_similarity,test_template_composition,test_template_technology,test_template_choices,test_template_score_options,test_extended_measurements,test_equipment_quality,test_starting_equipment_price,test_acquisition,test_equipment_storage,test_legal_access,test_control_table,test_control_question,test_control_certain,test_starting_wealth,test_monthly_finance,test_monthly_undo,test_money_exchange,test_social_structure,test_reputation,test_reputation_failure,test_reaction_encounter,test_information_delivery,test_paid_information,test_uncertain_knowledge,test_unknown_fact,test_trade_transfer,test_loyalty,test_loyalty_automatic,test_loyalty_failure,test_loyalty_danger,test_study,test_history]:
        fresh(Session,bundle,check)
        print(f'  expanded {check.__name__}: passed',flush=True)
    social = build.build('expanded-social',ROOT / 'tests/fixtures/expanded-social.t')
    fresh(Session,social,test_social_status)
    fresh(Session,social,test_combat_reactions)
    fresh(Session,social,test_aid_reactions)
    fresh(Session,social,test_information_reactions)
    fresh(Session,social,test_trade_reactions)
    fresh(Session,social,test_trade_modifiers)
    minimal = build.build('expanded-campaign',ROOT / 'tests/fixtures/expanded-campaign.t')
    fresh(Session,minimal,test_campaign_minimal)
    test_trade_persistence(Session,bundle,build.out)
    test_reputation_persistence(Session,bundle,build.out)
    test_equipment_persistence(Session,bundle,build.out)
    test_recognition_persistence(Session,bundle,build.out)
    test_familiarity_persistence(Session,bundle,build.out)
    test_persistence(Session,bundle,build.out)
    print('  expanded cross-process persistence: passed',flush=True)
    example = build.build('expanded-example',ROOT / 'examples/expanded/main.t')
    test_example(Session,example)
    print('  expanded example parser/action/dialogue parity: passed',flush=True)
