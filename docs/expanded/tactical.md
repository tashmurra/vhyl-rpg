# Expanded tactical

**Status: pending.** Hex movement, facing and close combat. Neutral source: `full-2008`, B384-B392.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename is reserved in the catalogue only; do not include it in a game.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

The [maneuver and posture inventory](inventory/maneuvers-postures.json) records
the B551 summary. Posture changes attack and defense modifiers, legal reach,
movement allowance and occupied hexes. Ranged target modifiers apply only to the
listed body regions; they are not blanket concealment bonuses. Low attackers also
have restricted access to parts of a standing target.

Assessment must resolve posture, facing, footprint and maneuver permissions
before spending movement. The detailed B384–B392 transition rules still need
review. Summary rows alone do not establish legal paths, rounding or interruption
behavior. Critical mishaps that move a combatant past an opponent need explicit
handling of blocked destinations and changes of facing.

The [basic combat movement inventory](inventory/combat-turns.json) now records
B367–B368. Step distance rounds upward; a multi-yard step may surround an action,
but a kneel/stand transition consumes the entire allowance. Evasion requires
enough movement to pass the opponent, a physically possible route and no grapple
restraint. An opponent who permits passage requires no contest. These rules still
need reconciliation with the detailed hex movement chapter.

The [tactical chapter inventory](inventory/tactical.json) now covers the first
text pass through B384–B392. Facing, reach and large-body diagrams have also been
inspected. This remains a requirements inventory: coordinate fixtures and
executable paths have not yet been implemented or validated.

Movement assessment needs an ordered path containing position, heading, posture,
terrain costs and occupied cells. Forward diagonal movement changes facing,
while a sidestep preserves it at a different cost. Free final facing depends on
the maneuver and spent budget. A step follows different cost rules from a full
movement maneuver, so one generic path budget would produce incorrect results.

Close combat retains each participant's entry side within a shared hex. Near-side
exits, crossing an opponent, grapple restrictions and available weapon reach all
depend on that state. Failed close-combat readying also differs from failed
readying while grappled; the combined case needs explicit precedence.

Ranged paths retain the chosen line, intervening occupants and their order.
Stray shots continue after a miss or dodge but stop after a hit, block or parry.
Opportunity fire can interrupt movement, and multiple triggered attacks can be
simultaneous. A pop-up attack must expose the actor to those reactions before
returning to cover. Preview must not reveal private watched areas or commit a
target-discrimination roll.

Large bodies require complete footprint and swept-path checks. Their head or
front controls movement and vision, but body sections can travel farther and
strike smaller figures. Body clearance, collision consequences and remaining
movement must be preserved together across rollback, undo and saved games.

Independent validation must cover all six rotations, the depicted reach rings,
partial barriers, fractional movement costs, interrupted paths, occupied exits,
simultaneous reactions and each opportunity-fire band. No checks have been run
while the requested pause remains in effect.

The [special-mobility inventory](inventory/special-mobility.json) adds high-speed
and aerial requirements. Velocity persists separately from movement capacity.
Turning depends on distance traveled since the preceding turn of direction, and
terrain costs can also force deceleration. An invalid high-speed maneuver can
cause loss of control even without a failed roll.

Ground, water and air use different control-loss consequences. Flying paths need
altitude, clearance and nonhovering stall limits; a dive can temporarily change
acceleration and maximum speed. The optional realistic turning formula and
encumbrance-based posture duration require explicit campaign selection. Neither
may silently replace the default procedure.
