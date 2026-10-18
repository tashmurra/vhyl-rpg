# Expanded health

**Status: pending.** Injury, treatment, recovery, fear consequences and fatigue. Neutral source: `full-2008`, B360-B361; B418-B427.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename is reserved in the catalogue only; do not include it in a game.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

The [fear inventory](inventory/senses-influence-fear.json) separately records every
full-reference fear-table outcome and its modifiers. Full fear resolution caps
the initial effective score at thirteen and selects a consequence with a new
three-dice roll plus failure margin. It must not replace Lite's existing
stun/faint calculation unless the expanded procedure is explicitly selected.

Recovery checks use different attributes, modifiers and intervals by outcome.
Some outcomes also impose injury, fatigue, temporary penalties, new traits or
permanent attribute loss. An owned episode must retain those details across
time advancement, rollback, undo and save continuation. Lasting traits require a
specific event-related author decision and alter character value without granting
spendable points. None of this expanded fear behavior is implemented yet.
