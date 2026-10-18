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

Training slots must be exclusive to one profile. Character validation now uses
`trainingPurchaseReason(skill, training)` to reject shared objects and duplicate
slots for the same skill. The same gate runs during development offers and direct
skill purchases, so runtime changes cannot bypass creation-time ownership checks.
A nil training argument represents a genuinely new skill slot. The default hook
on ordinary profiles leaves existing behavior unchanged.

### Finalizing a starting character

Use `RpgExpandedCharacterFinalization` after applying starting purchases and
packages. Supply its id, profile, approval and evidence, then call `assess()` or
`apply()`. Assessment performs the expanded character and budget validation.
Application marks creation complete and captures each negative trait's actual
creation cost in an owned `RpgExpandedBuyoffBasis`, linked to the finalization
receipt. It does not award advancement points or change the starting budget.

Captured bases initially lack buyoff approval: creation approval does not grant
permission to remove a disadvantage later. For an approved later buyoff, add
world justification and approval to the captured basis. Its original bonus and
trait binding remain checked against the historical receipt, even if the current
trait rating changes. Replaying finalization returns the original result and does
not recreate records or revalidate the character's later advancement as creation.

Already-complete profiles and profiles with existing buyoff history reject new
finalization. Existing integrations can keep their manual completion flow, but
must supply their historical bases explicitly. No old-save migration is implied.
The fixture covers pure assessment, one-time capture, separate buyoff approval,
historical-price protection, rollback, undo and save continuation; it is unrun.

Ancestry score composition uses `creationScoreAmounts()` to keep personal and
ancestry investments separate. `creationDisadvantageExemption()` excludes only
ancestry negative components from the personal cap; the ordinary negative-cost
query still reports both sources. Profiles without ancestry retain their
existing accounting. See [ancestry score composition](templates.md#ancestry-score-composition)
for current limits and the unrun validation cases.

`physicalCharacteristicLimitsExempt()` distinguishes the printed nonhuman
exemptions for HP, FP, Basic Speed and Basic Move from the separate permissions
for Will and Perception. The ancestry module supplies this hook from an approved,
owned nonhuman classification. Ordinary profiles retain all previous limits;
`exceptionalCharacteristics` retains its explicit campaign-wide override.
