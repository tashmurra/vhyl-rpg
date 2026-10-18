# Expanded social

**Status: partial.** Reactions, influence and social permissions. Neutral source: `full-2008`, B359; B494-B495; B559-B562.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-social.t` after the expanded foundation. Purchased
standing and a pure relative-standing modifier are available; full reactions,
influence and permissions remain pending.

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


## Purchased standing

`RpgExpandedStatus` is an owned point contribution with `id`, `owner`, `culture`
and `level`. Each level costs five points; negative levels contribute negative
points. The default allowed interval is -2 through 8. An authored culture can set
`minimum` and `maximum` explicitly, within the implementation's -100 through 100
numeric bounds. Duplicate standing for one culture and mixing expanded standing
with Lite standing traits are rejected.

`rpgExpandedStatusReaction(subjectStatus, observerStatus, recognized, friendly,
resents)` implements the relative-standing guidelines from full-2008 B29. Hidden
standing has no effect. Higher standing normally gives the difference as a bonus;
resentment suppresses that guideline bonus without inventing a new penalty.
Lower positive standing has no penalty with a friendly observer. Negative standing
has a penalty against higher standing, capped at -4.

`RpgExpandedStatusEncounter` gathers these explicit facts for `subject`, `observer`
and `culture`. Its pure `assess()` returns a modifier only. Absent purchased
standing in that culture means zero. Without a `structure`, this interface considers purchased standing only and
rejects profiles with organizational rank in the encounter culture. Supply the
structure described below to incorporate wealth and rank. Courtesy/temporary
titles, culture-specific privileges and upkeep remain pending. It performs no rolls and grants no social permissions.

The [minimal fixture](../../tests/fixtures/expanded-social.t) and
`tests/expanded.py::test_social_status` cover prices, relative differences,
recognition, friendly and resentful attitudes, negative-standing limits and foreign
cultures. These cases are authored and remain unrun while checks are paused.


## Rank and the social structure

`RpgExpandedRank` contributes five points per level, or ten when `replacesStatus`
is enabled (full-2008 B29–B30). Set `culture`, `institution`, `level`, the authored
`maximum` (default 8), and `admitted`. Membership at level zero is distinct from
having no membership. Duplicate ranks in the same institution are rejected.
Admission is an explicit world fact: prerequisites, duties, enforcement powers
and other privileges must be supplied separately. Courtesy and temporary rank are
not yet represented by this class.

A `RpgExpandedSocialStructure` identifies a `culture`. With ordinary standing,
each rank contributes +1 at levels 2–4, +2 at 5–7 and +3 at 8 or higher. Multiple
institutional ranks contribute separately. Set `wealthLinked` only when wealth
confers standing in that culture. The campaign wealth contribution supplies +1
from the wealthy tier, +2 at the first multimillionaire level, and +3 from the
second level onward. The social module does not depend on the campaign module;
without a wealth contribution there is no wealth-derived bonus.

Set `purchasedMaximum = 2` for the optional two-level ceiling on directly purchased
standing. Free bonuses remain additional. To replace standing entirely, set
`replacingInstitution` and mark that institution's rank `replacesStatus = true`.
The total is then that rank level; purchased standing is rejected and wealth and
other ranks supply no standing bonus. Inconsistent replacement flags are rejected.
Attach this structure to `RpgExpandedStatusEncounter.structure`, matching its
culture. `standing(profile)` and encounter assessment are pure.

The authored `test_social_structure` case checks combined standing, the wealth
bonus ceiling, purchased limits and replacement rejection. The minimal social
fixture checks rank price and standing-bonus boundaries without the campaign
module. All cases remain unrun while checks are paused. Full reactions, social
permissions and institutional prerequisite execution remain incomplete.
