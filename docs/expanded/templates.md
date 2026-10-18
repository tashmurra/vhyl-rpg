# Expanded templates

**Status: partial.** Character and ancestry packages. Neutral source: `full-2008`, B258-B263; B445-B454.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `RpgExpandedTemplate` — B258-B259; tested in `tests/expanded.py::test_numbers`.

The fresh-profile factory and occupational composition interface below are available. The full catalogue and remaining chapter procedures are not implemented. New composition checks are authored but unrun.

`RpgExpandedTemplate.create(rules)` creates a new profile with fresh training and
trait instances. Skill definitions may be shared as immutable definitions. This
factory currently handles basic/secondary scores, skill investments and traits
from the existing Lite catalogue. It validates the resulting character costs.
Ancestry exceptions, choice groups and the full trait catalogue are not implemented. It does not mutate or upgrade an existing character.

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

The composition function below handles the current factory’s occupational scores,
skills and Lite traits. Other operations in this list remain requirements. Template design recommendations, such as leaving some starting
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

## Combining occupational templates

`rpgExpandedCombineTemplates(templates, rules, pointBudget, disadvantageLimit)`
creates a fresh profile from a nonempty list of `RpgExpandedTemplate` definitions
(B259). Each source template must be valid under its own declared budget. The
combined character uses the supplied final budget and limit; template point totals
are not added together or separately charged.

The highest basic attributes and actual secondary scores are retained. Secondary
adjustments are then recalculated against the merged attributes. For example,
combining DX 10/HT 12 and DX 12/HT 10 retains Basic Speed 5.5, although the final
DX and HT are both 12: its speed adjustment becomes −0.5. Adding the two original
speed adjustments would produce the wrong requirement and price.

For each shared skill definition, composition retains the highest purchased skill
rating implied by its source template's points and attribute. It calculates the
points needed at the merged attribute, with at least one purchased point (three
for a wildcard definition). A general skill that happens to have a higher default
is not treated as a second paid requirement. Matching Lite trait IDs and scopes
retain the higher required level, and incompatible catalogue choices are rejected.
Traits and training are freshly owned for every composition. Input templates and
other previously created characters are not changed.

Current composition supports the fields of the basic factory only. Definitions
with additional contributions, languages, equipment or a different personal
technology level are explicitly rejected. Ancestry, lenses, selectable options,
modifier-bearing trait definitions and rich conflict diagnostics remain pending.
Template authors must share the same immutable skill definition for requirements
that denote the same skill and specialty; distinct definition objects are distinct
investments under the existing skill identity contract.

The native cases in `tests/expanded.py::test_template_composition` cover order
independence, recalculated secondary costs, overlapping skills and traits, fresh
ownership, conflicting status choices, empty input, and below-average requirements.
These checks have not run while validation is paused.
