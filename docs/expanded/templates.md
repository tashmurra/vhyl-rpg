# Expanded templates

**Status: partial.** Character and ancestry packages. Neutral source: `full-2008`, B258-B263; B445-B454.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `RpgExpandedTemplate` — B258-B259; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

`RpgExpandedTemplate.create(rules)` creates a new profile with fresh training and
trait instances. Skill definitions may be shared as immutable definitions. This
factory currently handles basic/secondary scores, skill investments and traits
from the existing Lite catalogue. It validates the resulting character costs.
Ancestry exceptions, nested packages, choice groups and the full trait catalogue
are not implemented. It does not mutate or upgrade an existing character.

## Remaining source obligations

The [detailed template inventory](inventory/templates.json) covers the first text
pass over B258–B263 and B445–B454. Its entries are pending, including the supplied
sample packages. Printed totals are acceptance targets, not executable package
definitions. Their individual components, choices and cross-module effects still
need implementation and independent validation.

The expanded implementation must distinguish these composition rules:

- Occupational packages merge overlapping requirements at the highest required
  level and reject incompatible traits. Their suggestions remain customizable.
- Ancestry packages add their level modifiers, derive secondary scores in the
  prescribed order, and retain mandatory components. Conflicts require an
  explicit authored resolution and a recalculated price.
- Lenses declare compatible bases, mutually exclusive alternatives and component
  replacements. Choice groups must resolve both eligibility and cost before any
  investment is committed.

Ancestry skill bonuses, innate training and personal training must remain
separately identifiable while contributing to one final skill score. Ancestry
negative traits and personal replacement traits have different accounting rules.
Zero-cost features and prohibited traits still affect validation and play.

These are implementation requirements; the existing factory does not yet provide
these operations. Template design recommendations, such as leaving some starting
points unspent, will remain guidance rather than mandatory character limits.


[Transformation requirements](inventory/traits-catalogue-k.json) replace native
ancestry contributions while retaining personal purchases. Conflicting physical
forms can suspend personal benefits without deleting them. Injury, fatigue,
crippling and conditions persist, with proportionally scaled health/fatigue losses.
The current fresh-profile factory cannot implement these transitions.

Adaptive forms require existing authored templates, purchased value capacity and
memorized identities. Omitting allowed mental disadvantages or ancestry intelligence
adjustments changes template value and must be checked against capacity. Ancestry
costs exclude the transformation ability itself when calculating its allowance,
preventing circular pricing. Every transition needs rollback and save coverage
before it can be considered implemented.
