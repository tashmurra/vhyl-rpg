"""Playable character/social integration: entry-point parity and saved continuations."""
from native import last, load_host
from support import ROOT


def state(session):
    session.action(1300)
    return last(session, 'bellwether.state')


def test(build):
    Session = load_host(build.vhyl)
    bundle = build.build('bellwether', ROOT / 'examples/bellwether/main.t')
    observations = []
    for mode in ('parser', 'action', 'dialogue'):
        session = Session(bundle)
        try:
            if mode == 'parser':
                session.command('create investigator')
            elif mode == 'action':
                session.action(1301)
            else:
                session.action(80, 'registry-plan')
                session.select('create-investigator')
            assert state(session) == [34, 12, 11, 0, 0]
            if mode == 'parser':
                session.command('ask ledger')
            elif mode == 'action':
                session.action(1302)
            else:
                session.action(80, 'registry-plan')
                session.select('ask-ledger')
            after = state(session)
            assert after == [34, 12, 11, 2, 60]
            observations.append(after)
            # A repeated question must not reroll the private reaction or consume time.
            session.action(1302)
            assert state(session) == after
        finally:
            session.close()
    assert observations[0] == observations[1] == observations[2]

    session = Session(bundle)
    try:
        session.action(1301)
        before = state(session)
        session.action(1302)
        after = state(session)
        session.command('undo')
        assert state(session) == before
        session.action(1302)
        assert state(session) == after
    finally:
        session.close()

    path = build.out / 'bellwether-created.zsave'
    first = Session(bundle)
    try:
        first.action(1301)
        first.command(f':save {path}\n@1300')
        assert any('[save ok code=0]' in line for line in first.raw_lines)
    finally:
        first.close()
    second = Session(bundle)
    try:
        second.command(f':restore {path}\n@1300')
        assert state(second) == [34, 12, 11, 0, 0]
        second.action(1302)
        assert state(second) == [34, 12, 11, 2, 60]
        second.command(f':save {path}\n@1300')
        assert any('[save ok code=0]' in line for line in second.raw_lines)
    finally:
        second.close()
    third = Session(bundle)
    try:
        third.command(f':restore {path}\n@1300')
        third.action(1302)
        assert state(third) == [34, 12, 11, 2, 60]
    finally:
        third.close()
    print('  Bellwether character/social parity, undo and cross-process continuation: passed', flush=True)
