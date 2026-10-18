# Expanded characters

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
