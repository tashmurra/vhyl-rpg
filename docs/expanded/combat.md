# Expanded combat

**Status: pending.** Maneuvers, attacks, defenses and special combat. Neutral source: `full-2008`, B357; B362-B383; B393-B417; B547-B558.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename is reserved in the catalogue only; do not include it in a game.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

The [physical-activity inventory](inventory/physical-activities.json) includes the
optional combat-effort procedures. They require declared campaign enablement,
fatigue payment before the combat roll, maneuver restrictions and additional
injury on critical failure. The rapid-attack and strong-attack options are
mutually exclusive. Ordinary will-based physical effort must not be substituted
for these combat procedures.


## Modifier-table requirements

The [combat summary inventory](inventory/combat-modifiers.json) records B547–B549
as individual conditions and table rows. The detailed combat chapters still need
review, so the summary alone is not a complete attack or defense implementation.

Assessment must separate legality, base score, modifiers and final caps. Some
attacks cap final effective skill at nine even after bonuses. Some maneuvers forbid
a defense entirely; a high calculated defense cannot restore it. Visibility has a
combined penalty limit, while other penalties may remain independently applicable.

Dual-weapon penalties already include ordinary off-hand use. Targeting an armor
gap is a distinct target choice, and a partly exposed location incurs its extra
penalty once. These distinctions require modifier provenance so overlapping
integration layers do not charge the same condition twice.

Moving-platform attacks depend on terrain, mount and stability. The summary does
not separately classify an unstabilized enclosed turret for all terrain cases, and
its stabilization wording is narrower than the detailed vehicle text concerning
stabilized sights. Those combinations remain pending reconciliation. A generic
vehicle penalty cannot stand in for the listed matrix.

Aim, evaluation, feints, shock, prior dodges, control failures and repeated parries
need actor-, weapon- or target-specific state and expiry. Preview must not consume
an aim turn, defense opportunity, ammunition or fatigue. A committed attack must
resolve all hits through the shared injury ledger and preserve rollback, undo and
save behavior.

## Size and range integration

The [size/range inventory](inventory/size-speed-range.json) includes every printed
B550 row, visually compared with the source page. Size uses the relevant dimension
and shape adjustment; speed contributes only when the applicable procedure calls
for it. The existing whole-yard range helper supplies only part of this calculation.

Independent tests must cover row boundaries, fractional dimensions, final skill
caps, defense rejection, repeated modifiers, platform categories and multi-hit
resolution. No new tests or builds have been run while checks are suspended.

## Critical outcomes and anatomy

The [critical-outcome inventory](inventory/critical-outcomes.json) records each
row of the ordinary-hit, head-hit, weapon-miss and unarmed-miss tables. Selection
depends on the action and struck location. Critical damage multipliers act on
basic damage; armor and injury conversion remain separate stages. The two hit
tables round reduced armor differently, so they cannot share an unconditional
halving operation.

Weapon construction, quality and attack type determine whether a miss requires
a confirmation or replacement roll. Unarmed outcomes have separate rules for
natural weapons, creatures that cannot fall, and flight or swimming. Temporary
incapacity, dropped equipment, altered facing, lost actions and lasting wounds
must use the same persistent state as ordinary actions.

The [maneuver summary](inventory/maneuvers-postures.json),
[anatomy tables](inventory/anatomy-locations.json) and
[vehicle location tables](inventory/vehicle-locations.json) supply additional
integration requirements. None of these inventories is an executable subsystem
yet. Validation must independently cover every table result, conditional reroll,
rounding direction and expiry boundary before coverage can be marked complete.

The [detailed turn inventory](inventory/combat-turns.json) covers B362–B368.
Encounter time advances once per participant cycle, while maneuver permissions
last until the individual actor's next selection. Initiative ties are resolved at
encounter creation and retained. Re-sorting after every temporary speed change
would contradict the fixed ordering procedure.

Wait actions need a declared trigger, response, expiry and suspended action to
resume. Defending while waiting changes which response remains legal. Aim and
concentration also react differently to defenses and injury; they cannot share
one unconditional interruption flag. Feints retain actor-target ownership and
their own margin calculation, while evaluation survives active defense.

Full-turn maneuvers consume the whole second even for actors with additional
maneuver capabilities. Shared time accounting must distinguish that constraint
from extra attacks, free item release and ongoing ability maintenance.
