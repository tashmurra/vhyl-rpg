# Expanded skills

**Status: partial.** Skill catalogues, defaults, prerequisites and techniques. Neutral source: `full-2008`, B167-B233.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedSkillLevel` — B170; B175; tested in `tests/expanded.py::test_numbers`.
- `rpgExpandedSkillScore` — B173; tested in `tests/expanded.py::test_numbers`.
- `RpgExpandedTechnique` — B230; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

The [skill procedure inventory](inventory/skills-procedures.json) records individual
cost-table cells, default rules, familiarity requirements and technique definitions.
Attribute-based techniques and technique-to-technique defaults remain unsupported.
The complete skill catalogue still needs a separate inventory.
