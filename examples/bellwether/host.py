#!/usr/bin/env python3
"""Play the original town-registry integration vignette."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'hybrid'))
from host import main

if __name__ == '__main__':
    main(title='Town Registry', plan='registry-plan', assessment_verb=1300)
