#!/usr/bin/env python3
"""Play the gatehouse using the same parser and choice host as the first scene."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'hybrid'))
from host import main

if __name__ == '__main__':
    main(title='Rain Gatehouse', plan='gate.plan', assessment_verb=405)
