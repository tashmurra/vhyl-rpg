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
