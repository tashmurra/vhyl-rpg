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
