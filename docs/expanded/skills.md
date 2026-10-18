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

The [technique-summary ledger](inventory/technique-summary.json) compares all 27
summary rows with the detailed definitions. The catalogue has 29 technique
definitions because the detailed text also describes rope descent and unarmed
sweeping. Structured metadata records attribute-based defaults, parent technique
chains, separate specialties, caps and cinematic exceptions. The camera technique
is explicitly uncapped; ranged weapon retention has a Dexterity-based variant.
Rope descent does not restate its difficulty, so that interpretation remains
explicitly unresolved. These records do not expand the current runtime interface.

The [first skill-summary segment](inventory/skill-summary-a.json) maps 44 rows.
It exposed missing Dexterity defaults for aerial and aquatic acrobatics and missing
melee group defaults; these are now recorded alongside the detailed skill edges.
The summary omits other valid defaults, so it cannot replace the detailed catalogue.
Reciprocal default edges do not permit chains through untrained skills. Full field
reconciliation and executable coverage are still pending.

The detailed aiming-skill groups now record their cross-specialty default edges:
beam weapons and mounted direct fire at −4, built-in ranged attacks at −2,
and liquid projectors at −4. Projectile small arms use −2 except that an edge
involving a grenade launcher, miniature rocket or light antitank weapon uses −4.
Matching beam/projectile pistol and rifle defaults require a campaign containing
both weapon technologies. Familiarity penalties remain separate from defaults.
These are source definitions awaiting runtime integration; the abbreviated summary
table does not list every edge.

The [second skill-summary segment](inventory/skill-summary-b.json) maps 103
rows, including group headings and concrete skills. Group headings resolve to
their detailed specializations; they must not create duplicate purchasable skills.
The summary field comparison remains pending.
