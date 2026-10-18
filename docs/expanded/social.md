# Expanded social

**Status: pending.** Reactions, influence and social permissions. Neutral source: `full-2008`, B359; B494-B495; B559-B562.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename is reserved in the catalogue only; do not include it in a game.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

The [reaction inventory](inventory/reactions.json) records B559–B562 by both
reaction band and context. General attitude, possible combat, trade, assistance,
information and loyalty have different consequences. A favorable morale result
can mean flight or surrender during a fight; it does not create friendship.

Authors need specific inputs for perceived relative strength, escape routes,
reasonable requests, information known, motives and risks. Information can be
accurate according to a speaker's beliefs while factually wrong. Hidden loyalty
must remain separate from competence and must not leak through preview results.
Predetermined attitudes also need an explicit path that consumes no reaction roll.

Trade uses the local fair price, the actual offer and the context-specific price
limits. Offers, bribes, permitted retries and follow-up modifiers need persistent
identities so a preview or repeated command cannot spend money or roll twice.
The B562 counteroffer example contains a visually confirmed arithmetic
inconsistency: half of an offer at 120% is described as 50%. A documented selection
policy and independent tests are required before that procedure can be complete.

These entries remain pending. No reaction subsystem or validating runtime tests
are claimed by the inventory, and build checks remain paused.

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
