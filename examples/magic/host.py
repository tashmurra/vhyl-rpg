#!/usr/bin/env python3
"""Play the workshop through the provider-neutral host boundary; no model required."""
import argparse
import importlib.util
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'hosts'))
from vhyl_gm import AuthoredAdjudicator, Exchange, decode_request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    parser.add_argument('--vhyl', type=Path, default=os.environ.get('VHYL_ROOT'))
    args = parser.parse_args()
    if args.vhyl is None:
        parser.error('supply --vhyl or VHYL_ROOT')
    source = args.vhyl.resolve() / 'examples/dialogue/host.py'
    spec = importlib.util.spec_from_file_location('vhyl_dialogue_host', source)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    session = module.Session(args.bundle)
    exchange = Exchange()
    provider = AuthoredAdjudicator({
        'inspect': ['inspect-material', 'subtle', 0, 'An authored workshop observation.'],
        'redirect': ['redirect-light', 'subtle', 0, 'An authored optical adjustment.'],
        'relocate': ['relocate-token', 'subtle', 0, 'An authored unnoticed movement.'],
    })
    effects = {'inspect': 1, 'light': 2, 'move': 3}
    print('Optical workshop. Use preview, rule or cast followed by inspect, light or move. Use quit to leave.')
    try:
        while True:
            try: words = input('> ').strip().split()
            except EOFError: break
            if words == ['quit']: break
            if len(words) != 2 or words[0] not in ('preview', 'rule', 'cast') or words[1] not in effects:
                print('Example: rule inspect, then cast inspect.'); continue
            operation, name = words
            which = effects[name]
            session.log.clear()
            if operation == 'rule':
                session.action(700, which, 3)
                request = exchange.register(decode_request(session.log))
                # Replace this adapter with a local service later. For a slow adapter,
                # run it on a worker, then submit its reply on the session owner thread.
                reply = exchange.validate(provider.adjudicate(request))
                session.action(700, which, 4, reply['serial'], reply['status'], *reply['ruling'])
                print('Ruling submitted; preview checks it against the current world.')
            else:
                session.action(700, which, 0 if operation == 'preview' else 2)
                for event in session.log:
                    if event['id'] == 'rpg.magic.result':
                        _, _, status, delivered, seconds = event['values']
                        print(f'{name}: {status}; effect delivered: {bool(delivered)}; time used: {seconds}s.')
    finally:
        exchange.reset()
        session.close()


if __name__ == '__main__': main()
