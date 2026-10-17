#!/usr/bin/env python3
"""Play the example using parser commands and numbered dialogue choices."""
import argparse
import importlib.util
import os
from pathlib import Path
from presentation import report_lines

DEVELOPMENTS = {'gate.study-aid': 'Study first aid', 'gate.practice': 'Practise brawling',
                'gate.resolve': 'Strengthen resolve', 'gate.learn-poise': 'Learn composure',
                'gate.overcome-nerves': 'Overcome nerves'}


def show_output(session, details=False):
    for line in session.raw_lines:
        if not line.startswith('@'):
            print(line)
    for event in session.log:
        if event['id'] == 'survey.text':
            print(event['values'][0])
        elif event['id'] == 'dialogue.utterance' and event['values'][3] is not None:
            print(event['values'][3])
        elif event['id'] == 'rpg.body':
            _, _, condition, hp, maximum, energy, maximum_energy, _ = event['values']
            print(f'Condition: {condition.replace("-", " ")}. HP {hp}/{maximum}; energy {energy}/{maximum_energy}.')
        elif event['id'] == 'rpg.progress':
            _, _, kind, name, status, reason, points, bank, earned, _ = event['values']
            name = DEVELOPMENTS.get(name, 'Development opportunity')
            if status == 'ready':
                print(f'{name}: available for {points} points; {bank} unspent.')
            elif status == 'resolved':
                print(f'{"Milestone" if kind == "award" else "Development"}: {points} points; {bank} unspent.')
            elif status == 'blocked':
                print(f'{name}: {str(reason or "unavailable").removeprefix("rpg.").replace("-", " ")}; {bank} unspent.')
        elif event['id'] == 'rpg.conflict':
            _, _, status, reason, maneuver, outcome, exchanges, _ = event['values']
            print(f'Confrontation: {outcome or reason or status} (exchange {exchanges}).')
    if details:
        for line in report_lines(session.log):
            print(line)


def main(*, title='Survey Office', plan='survey-plan', assessment_verb=105):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    parser.add_argument('--vhyl', type=Path, default=os.environ.get('VHYL_ROOT'))
    parser.add_argument('--details', action='store_true', help='show permitted ability and dice details')
    args = parser.parse_args()
    if args.vhyl is None:
        parser.error('supply --vhyl or VHYL_ROOT')
    source = args.vhyl.resolve() / 'examples/dialogue/host.py'
    spec = importlib.util.spec_from_file_location('vhyl_dialogue_host', source)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    session = module.Session(args.bundle)
    try:
        print(f'{title}. Type :plan for choices, :odds for assessments, :quit to leave, or a parser command.')
        show_output(session, args.details)
        while True:
            line = input('> ').strip()
            if line == ':quit':
                break
            # raw_lines is bounded; clear this presentation buffer before each
            # request rather than retaining a stale offset into it.
            session.raw_lines.clear()
            session.log.clear()
            if line == ':plan':
                session.action(80, plan)
                if args.details:
                    session.action(assessment_verb)
            elif line == ':odds':
                session.action(assessment_verb)
            elif line.startswith((':save ', ':restore ')):
                # Consumer control commands need a following query to produce
                # a ready boundary. A dialogue refresh does not advance time.
                session.command(line + '\n' + module.action_line(82))
            elif line.startswith(':') and line[1:].isdigit():
                index = int(line[1:]) - 1
                if not 0 <= index < len(session.choices):
                    print('Choose a displayed number.')
                    continue
                session.select(session.choices[index]['id'])
            elif line.startswith(':'):
                print('Use :plan, :odds, :N, :save PATH, :restore PATH or :quit.')
                continue
            elif line:
                session.command(line)
            show_output(session, args.details or line == ':odds')
            for i, choice in enumerate(session.choices, 1):
                print(f':{i} {choice["text"]}')
    except (EOFError, KeyboardInterrupt):
        pass
    finally:
        session.close()


if __name__ == '__main__':
    main()
