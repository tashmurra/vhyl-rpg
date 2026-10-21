#!/usr/bin/env python3
"""Play the signal workshop through the existing public host transport."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'hybrid'))
from host import main

if __name__ == '__main__':
    main(title='Signal Workshop', plan='workshop-plan', assessment_verb=1200)
