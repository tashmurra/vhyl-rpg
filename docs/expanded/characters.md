# Expanded characters

**Status: partial.** Character accounting and secondary characteristics. Neutral source: `full-2008`, B10-B31.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedValidateCharacter` — B16-B17; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

The [character-creation inventory](inventory/creation.json) separates individual
procedures, modifiers, table rows and author decisions. Its pending entries are
not covered by the secondary-characteristic validation above.


Fear-induced quirks installed by the traits module reduce current character
value without granting advancement points. Their owned receipts supply a
post-creation negative-point allowance and a specific exception to the normal
five-quirk creation cap. Ordinary sixth quirks remain invalid. See the
[behavioral quirk contract](traits.md#fear-induced-behavioral-quirks) for authored
outcomes, portrayal records and limitations. The corresponding fixture is unrun.


## Character/social subset authoring

`RpgExpandedProfile` adds independent `hpAdjustment`, `fpAdjustment`,
`willAdjustment`, `perceptionAdjustment`, `speedQuarterAdjustment` and
`moveAdjustment` to the existing Lite profile. Speed uses quarter-point increments.
The normal source bounds apply unless `rules.exceptionalCharacteristics` is set
by the author. That option permits exceptional construction; it does not grant
unimplemented anatomy, scale or combat rules.

`rpgExpandedCharacterAmounts(profile)` returns signed cost components.
`rpgExpandedCharacterCost(profile, negativeOnly)` returns total cost or the sum of
negative components. `rpgExpandedValidateCharacter(profile)` checks secondary
bounds, budgets, unique training, prerequisites, existing trait exclusions,
language identities and the single native-language allowance. It rejects invalid
characters rather than silently reducing purchased scores.

Set `pointBudget` and `disadvantageLimit` explicitly. The native-language allowance
is applied by `RpgLiteLanguage.cost()`, not by adding spendable points. This is a
creation validator; it must not be used as a blanket post-advancement budget check.
The milestone does not yet supply an expanded advancement validator for every
possible contribution.

Feature modules add owned `RpgExpandedContribution` instances to `contributions`.
Each has a unique `id`, an `owner` matching the profile, `amounts(profile)` and
`validate(profile)`. Status, rank and reputation participate in this accounting.
Implement a concrete effect separately when adding an authored feature: a point
contribution alone does not grant an executable advantage.

The Town Registry example creates a 34-point investigator: IQ 11 costs 20,
Will +1 costs 5, two skill investments cost 4, and reputation costs 5. Its budget
is 40. Source mapping: `full-2008` B14-B17, B23-B30 and B170.

The prerelease record applies to the original subset. Checks for this merged
expanded suite remain paused.
