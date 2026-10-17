#!/usr/bin/env python3
"""Play the Lite training yard with the existing parser transport and reporting."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'hybrid'))
from host import main

if __name__ == '__main__':
    main(title='Lite Training Yard', plan='yard', assessment_verb=700)
