"""Broad authored injury categories; no automatic locations or organ simulation."""
from native import fresh, last, load_host
from support import ROOT
from fright import find_seed

FIELDS = 'injury hands legs exertion move posture mortal active severity remaining draws seconds count jump lift run_reason'.split()
def do(s, code, *args): s.action(770, code, *('none' if a is None else a for a in args))
def state(s):
    s.action(990)
    return dict(zip(FIELDS,last(s,'test.injuries'),strict=True))
def inflict(s, part='arm', side='right', severity='lasting', months=2):
    do(s,1,part,side,2,severity,months)

def categories(s):
    inflict(s)
    assert state(s)['hands'] == 1
    do(s,11)
    assert last(s,'test.attack') == ['injury-limb-unavailable']
    do(s,2)
    assert state(s)['injury'] == 0 and state(s)['active']
    do(s,3,5184000)
    assert state(s)['hands'] == 2 and not state(s)['active']
    inflict(s,'hand','left')
    assert state(s)['hands'] == 1 and state(s)['lift'] == 0
    inflict(s,'leg','right')
    assert not state(s)['legs'] and state(s)['jump'] == 0
    assert state(s)['run_reason'] == 'injury-exertion'
    do(s,8,'standing')
    assert state(s)['move'] == 0
    do(s,8,'crawling')
    assert state(s)['move'] == 1
    inflict(s,'foot','left')
    assert not state(s)['legs']

def internal(s):
    inflict(s,'internal',None)
    assert not state(s)['exertion'] and state(s)['jump'] == 0
    do(s,2)
    assert state(s)['active']
    do(s,3,5184000)
    assert state(s)['exertion']
    inflict(s,'internal',None,'mortal',0)
    assert state(s)['mortal']
    do(s,5,find_seed(lambda d: 4 < d.roll() <= 10 and 4 < d.roll() <= 10 and d.roll() < 17))
    do(s,4,7,1)
    assert not state(s)['mortal'] and state(s)['severity'] == 'lasting'
    assert state(s)['remaining'] == 2592000

def treatment(s):
    inflict(s,months=6)
    do(s,4,7,0)
    assert state(s)['remaining'] == 7776000
    before = state(s)
    do(s,4,7,0)
    assert state(s) == before
    do(s,5,1)
    do(s,4,7,1)
    assert state(s)['remaining'] == 1812720
    do(s,3,1812719)
    assert state(s)['active'] and state(s)['remaining'] == 1
    do(s,3,1)
    assert not state(s)['active']

def life(s):
    inflict(s)
    do(s,7)
    assert last(s,'test.life') == [2,None]
    assert not state(s)['active'] and state(s)['injury'] == 0
    inflict(s,'internal',None)
    do(s,2)  # functional repair is still available when HP has already recovered
    do(s,7)
    assert not state(s)['active']
    inflict(s,'hand','left','permanent',0)
    do(s,7)
    assert last(s,'test.life')[1] == 'injury-life-unavailable'
    assert state(s)['active']

def severity(s):
    inflict(s,severity='temporary',months=0)
    do(s,5,find_seed(lambda d: 10 < d.roll() < 17))
    do(s,6)
    assert state(s)['severity'] == 'lasting' and state(s)['remaining'] > 0
    before=state(s)
    do(s,6)
    assert state(s)==before
    inflict(s,'hand','left','temporary',0)
    do(s,5,find_seed(lambda d: d.roll() == 18))
    do(s,6)
    assert state(s)['severity'] == 'permanent'
    do(s,2); do(s,3,20000000)
    assert state(s)['active']

def surgery_failure(s):
    inflict(s)
    do(s,5,find_seed(lambda d: d.roll() == 18))
    do(s,4,7,1)
    assert state(s)['severity'] == 'permanent'
    before=state(s)
    do(s,4,7,1)
    assert state(s)==before

def casting(s):
    inflict(s)
    do(s,12,2,1)
    assert last(s,'test.cast') == [None,True], last(s,'test.cast')
    assert not state(s)['active']

def permission(s):
    inflict(s)
    before=state(s)
    do(s,12,1,1)
    assert last(s,'test.cast') == ['magic-permission',None]
    assert state(s)['active'] and state(s)['injury'] == before['injury']

def temporary(s):
    inflict(s,severity='temporary',months=0)
    do(s,2)
    do(s,3,1)
    assert not state(s)['active']

def transactions(s):
    before=state(s)
    do(s,9,'arm','right',2,'lasting',2)
    assert state(s)==before
    inflict(s)
    after=state(s)
    do(s,10)
    assert state(s)==after
    s.action(3)
    assert state(s)==before

def test(build):
    Session=load_host(build.vhyl)
    bundle=build.build('injuries',ROOT/'tests/fixtures/injuries.t')
    for check in (categories,internal,treatment,life,severity,surgery_failure,casting,permission,temporary,transactions):
        fresh(Session,bundle,check)
        print(f'  injuries {check.__name__}: passed',flush=True)
    path=build.out/'injuries.zsave'
    s=Session(bundle)
    try:
        inflict(s); do(s,3,100)
        saved=state(s)
        s.command(f':save {path}\n@990')
    finally: s.close()
    s=Session(bundle)
    try:
        s.command(f':restore {path}\n@990')
        assert state(s)==saved
        do(s,3,5183900)
        assert not state(s)['active']
    finally: s.close()
    print('  injuries cross-process persistence: passed',flush=True)
