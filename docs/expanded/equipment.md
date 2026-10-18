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
