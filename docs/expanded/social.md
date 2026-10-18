# Expanded social

**Status: pending.** Reactions, influence and social permissions. Neutral source: `full-2008`, B359; B494-B495; B559-B562.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename is reserved in the catalogue only; do not include it in a game.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

## Reaction requirements now inventoried

The [campaign procedure ledger](inventory/campaign-procedures.json) records the
B494–B495 reaction rules under this module. Reactions use secret three-dice totals
with higher results favorable; they are not ordinary roll-under checks. Context
selects whose traits and skills apply. Predetermined category bounds clamp a result
without rerolling, while a fully determined reaction needs no random roll.

A changed approach may permit a retry. Repeated nuisance requests can accumulate
penalties until an authored sufficient interval passes. Eligibility and attempt
history need persistent encounter state. Influence uses its own procedure and must
not also grant an ordinary reaction roll to select the better outcome.

The detailed reaction outcome table and underlying trait integration remain pending.
This inventory does not establish an implemented social subsystem.
