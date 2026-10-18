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
The catalogue inventory currently covers [B174–B185](inventory/skills-catalogue-a.json),
[B186–B197](inventory/skills-catalogue-b.json),
[B198–B209](inventory/skills-catalogue-c.json) and
[B210–B228](inventory/skills-catalogue-d.json). This completes the first text pass
through the main catalogue, but not its enumeration audit, cross-reference
resolution or implementation. Definition metadata is not an executable catalogue
and does not imply completed skill effects.

The recorded procedures include persistent code-breaking attempts, combined
impersonation checks, audience-specific storytelling effects, timed induction and
suggestions, vehicle/equipment skill caps, and weapon-specific attack and defense
rules. These need owning state and integration tests in addition to catalogue
score definitions. Source text that leaves a boundary or consequence unspecified
requires an explicit author contract; it must not acquire an invented numeric rule.


[Skill aptitude requirements](inventory/traits-catalogue-l.json) include the ten
printed skill groups, reaction audiences, default-use bonuses and reduced learning
time. Specialties count once for pricing, but a specific specialty restriction still
limits the actual bonus. Overlapping groups may exceed four for skill bonuses only;
reaction and study overlap must not silently inherit that exception. These effects
and their catalogue identifier mappings remain pending.
