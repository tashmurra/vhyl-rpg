# Expanded equipment

**Status: partial.** Weapons, armour, equipment and extended numeric tables. Neutral source: `full-2008`, B16; B264-B289; B345; B550.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedRangeModifier` — B550; tested in `tests/expanded.py::test_numbers`.
- `rpgExpandedDamageDice` — B16; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

The [task-resolution inventory](inventory/task-resolution.json) records equipment
quality, missing-item and damage modifiers separately. These depend on actual
tools and task eligibility: some tasks cannot be attempted without equipment at
all. The existing numeric helpers do not implement this equipment assessment.


The [detailed size/range inventory](inventory/size-speed-range.json) now records all
printed B550 rows, including fractional dimensions and shape rules. The rows have
been visually compared with the reference page; this is source verification, not
a runtime test. `rpgExpandedRangeModifier` still handles only whole-yard lookup,
not size calculation, fractional units, target-speed selection or sensing rules.
Those integrations and independent boundary tests remain pending.
