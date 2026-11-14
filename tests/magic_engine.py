"""Mechanical extension tests through the public transaction and save transport."""
from native import fresh, last, load_host
from support import ROOT


def case(s, number, *args):
    start = len(s.log)
    s.action(720, number, *args)
    values = [e['values'] for e in s.log[start:] if e['id'] == 'test.engine']
    assert len(values) == 1, (number, args, [e['id'] for e in s.log[start:]])
    return values[0]


EXPECTED = {
    1: [30,30,1800,1800,86400,86400,604800,604800,-1,100,10,1000,3,3,12],
    2: [15,13,5,10,10,None,None],
    3: [2,2,0,2,0],
    4: [6,6,4,6,0,14,'reused',12,0,3,6],
    7: [2,23,True,1,1,0,'resolved','full','full',1],
    8: [1,'resolved','full',1,1,'full',1],
    9: ['ready',17,491400,'resolved',1,'ready',2,2,True,19000],
    10: ['resolved',5,1,'reused',5],
    11: [2,True,2,None,None,True],
    12: ['false','real','real',True,13,None],
    13: ['resolved','full',12,1],
    14: [3,5,0],
    15: [0,1,10],
    16: ['resolved','full',1,1,1,0,0,1],
    17: [38,2,True,13,13,'resolved','full',1,1,1,0,0,600],
    18: [True,0,True,1],
    19: ['resolved',4,True,'reused'],
    20: [True,4,10,0,0],
    21: [True,0,14400,14400,10],
    22: [0,3,0,6,0],
    23: ['resolved',True,17,10,-1,'reused',3],
    24: [10,15,15,4500,10,10],
    25: ['resolved',True,True,True],
    26: [0,0,'miss',2],
    27: ['magic-reprepare-declaration',None],
    28: ['magic-memory-content','needs-ruling',0],
    29: [50,'reused',50,12,'magic-source-share-limit',4,10,46,4,54],
    30: [12,1,True,13,13,'resolved','insufficient',0,1,1,0,0,300,1,None,None],
    31: ['resolved',True,True,1,True],
    32: ['blocked','magic-ritual-concentration',0,True],
    33: [25,3],
    34: ['insufficient',0,20],
    35: ['insufficient',None,19,20],
    36: ['magic-source-attempt',10,8],
    38: ['magic-life-property-class'],
    39: ['magic-reprepare-declaration',3],
}

# One permission derivation per rank, independent of caster training data.
MATRIX = {
    'space': [('observe','matter'),('remote-sense','matter'),('relocate','self'),('passage','matter'),('dimensions','matter')],
    'chance-decay': [('observe','matter'),('chance','matter'),('decay','matter'),('decay','simple'),('erode-belief','other')],
    'energy': [('observe','matter'),('redirect','matter'),('generate','matter'),('redirect','motion'),('generate','motion')],
    'life': [('observe','other'),('reshape-life','simple'),('reshape-life','self'),('reshape-life','other'),('transform-life','other')],
    'matter': [('observe','matter'),('create','matter'),('reshape','matter'),('transmute','matter'),('extraordinary','matter')],
    'mind': [('enhance-mind','self'),('suggest','other'),('link','other'),('memory','other'),('project','self')],
    'power': [('receive','other'),('disturb','other'),('transfer','other'),('unmake','matter'),('replenish','self')],
    'spirits': [('observe','other'),('contact','other'),('cross','self'),('boundary','other'),('mark','other')],
    'time': [('time-sense','self'),('past','other'),('accelerate','other'),('suspend','other'),('forward','self')],
}


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build('magic-engine', ROOT / 'tests/fixtures/magic-engine.t')
    for number, expected in EXPECTED.items():
        def check(s, n=number, want=expected):
            got = case(s,n)
            assert got == want, (n,got,want)
        fresh(Session,bundle,check)
    for dice, expected in [(16,[True,0,3,None,3]), (17,[True,10,0,None,0])]:
        fresh(Session,bundle,lambda s: _equal(case(s,6,dice),expected))
    for domain, operations in MATRIX.items():
        for rank,(operation,target) in enumerate(operations,1):
            def check(s, d=domain, r=rank, op=operation, t=target):
                data=case(s,5,op,'density' if op=='enhance-mind' else 'none',t,d)
                assert data[:2] == [d,r], (d,r,data)
                if op=='create' or d=='energy' and r in (3,5):
                    assert data[2:4] == ['power',2],data
            fresh(Session,bundle,check)
    # M20 Life permissions: healing versus alteration, simple versus complex,
    # and explicitly authored cosmetic / similarly sized body forms.
    for op, target, kind, rank in [
        ('heal','self','ordinary',2), ('heal','other','ordinary',3),
        ('heal','simple','ordinary',2), ('injure','self','ordinary',3),
        ('injure','other','ordinary',3), ('injure','simple','ordinary',2),
        ('reshape-life','self','cosmetic',2), ('reshape-life','other','cosmetic',4),
        ('reshape-life','self','ordinary',3),
        ('transform-life','simple','ordinary',3),
        ('transform-life','simple','complex-form',5),
        ('transform-life','self','similar-form',4),
        ('transform-life','self','ordinary',5),
        ('transform-life','other','similar-form',5),
        ('create','simple','ordinary',3), ('create','other','ordinary',5),
    ]:
        def check(s, op=op, target=target, kind=kind, rank=rank):
            data = case(s,5,op,'density',target,'life',kind)
            assert data[:2] == ['life',rank], (op,target,kind,data)
            if op == 'create':
                assert data[2:4] == ['power',2], data
        fresh(Session,bundle,check)
    for target, rank, expected in [
        ('self',1,['magic-permission',None,4,None]),
        ('self',2,[None,True,0,True]),
        ('other',2,['magic-permission',None,4,None]),
        ('other',3,[None,True,0,True]),
    ]:
        fresh(Session,bundle,lambda s, t=target, r=rank, e=expected:
              _equal(case(s,37,t,r),e))
    # Persistent layers and recovery clocks survive a fresh process and undo.
    save = build.out / 'magic-engine.zsave'
    s=Session(bundle)
    try:
        case(s,13)
        s.action(721); before=last(s,'test.engine-saved')
        s.command(f':save {save}\n@721')
    finally: s.close()
    s=Session(bundle)
    try:
        s.command(f':restore {save}\n@721')
        assert last(s,'test.engine-saved') == before
    finally: s.close()
    print('  magic engine: workflows, resistance boundaries, 45 ranks, M20 Life thresholds and persistence passed',flush=True)


def _equal(got, expected):
    assert got == expected,(got,expected)
