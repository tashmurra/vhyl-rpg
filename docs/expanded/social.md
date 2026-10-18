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


## Reputation and recognition

`RpgExpandedReputation` is an owned contribution with a unique `id`, concrete
`details`, `facets` and a recognition `frequency`. A facet is
`[audienceId, reactionModifier, breadth]`. Modifiers range from -4 to +4. Breadth
is `all`, `most`, `large`, `small` or `negligible`, corresponding to factors 1,
2/3, 1/2, 1/3 or zero on the five-point-per-modifier cost. Multiple facets require
an explicit `disjoint` assertion: these are mutually exclusive audience categories
within a single reputation. Overlapping reputations use separate contributions.

Facet costs are rounded down, then summed. Frequency is `always`, `sometimes`
(10 or less), or `occasionally` (7 or less); apply factors 1, 1/2 or 1/3 to that
sum and round down again. These are the explicit exceptions in full-2008 B27–B28,
including downward rounding for negative values. A zero-net reputation remains
recorded. Mixing this representation with Lite reputation traits is rejected.

Use `RpgExpandedReputationRecognition` with the owned reputation, a stable person
or small-group `audience` identity and its applicable `facet`. Supply `inArea` and
`identityExposed` (a name or face is sufficient) from world facts. Pure `assess()`
returns readiness without a recognition result or random draw. `resolve()` rolls
3d for the two limited frequencies; automatic recognition rolls nothing. Success
or failure is retained in `reputation.recognitions`. A new recognition object for
the same audience reuses that result. Changing its audience facet is rejected.
For a large crowd, explicitly identify distinct groups when the author chooses
multiple recognition rolls; changing IDs merely to retry is outside the contract.

`rpgExpandedReputationModifier(recognitions)` combines resolved reputations for
one subject and audience, limiting the total to -4 through +4. Unresolved entries,
duplicated reputations and mixed audiences are rejected. This is a modifier
assessment, not a full reaction-table resolver. Geographic loss of reputation,
buyoff, changed reputation over time and resulting world consequences remain
pending. Stored results are historical snapshots, not automatic recalculations.

`tests/expanded.py::test_reputation` contains expected price checks, a multifaceted
zero cost, geographic/identity gates, duplicate audiences, pure previews,
deterministic recognition, rollback and undo. These authored cases remain unrun;
`test_reputation_failure` and `test_reputation_persistence` additionally cover
failed recognition and cross-process reuse; they too remain unrun.


## Private reaction encounters

Register a `RpgExpandedReactionEncounter` in `subject.reactionEncounters`, with
unique `id` and a stable `audience`. The encounter owns its history across requests.
`RpgExpandedReactionAttempt` identifies an authored `approach` and its numeric
`modifier`. This low-level modifier must already incorporate applicable traits,
standing, recognized reputations and world conditions exactly once; automatic
catalogue-wide modifier collection remains pending.

`assess()` checks readiness but never exposes the saved attitude, total or dice.
`resolve()` returns private author data and records it. Do not send that data to
player-facing events: portray what the NPC says and does instead. Reaction totals
use 3d plus modifiers, with higher totals favorable; they are not success rolls.
Bands are 0 through 7, with upper boundaries 0, 3, 6, 9, 12, 15, 18, then unbounded
above (full-2008 B560–B561). `worstBand` and `bestBand` clamp the resulting band.
A `predeterminedBand` supplies the attitude without consuming randomness.

Repeating an approach reuses its record. A new approach requires `approvedChange`
after the first request; the author must actually change the offer, speaker,
information or other relevant approach. Set encounter `fighting` when a previous
request starts a fight; further request rolls are blocked. A predetermined attitude
also blocks retries until the author explicitly changes that policy.

When the NPC considers further requests a nuisance, set attempt `nuisance`.
The encounter accumulates a -2 penalty per such retry. An authored
`waitedReasonably` decision resets that accumulation; it does not itself advance
time. Any actual waiting must use the shared time ledger once. Set this only when
the elapsed time satisfies the NPC's circumstances. Attempt history, penalties
and random state remain within normal transactions and saves.

This implements the roll and retry machinery, not the table's context-specific
world consequences. Combat/morale, trade, aid, information and loyalty outcomes
remain pending. A favorable combat reaction must not be interpreted as friendship.
`tests/expanded.py::test_reaction_encounter` covers band boundaries, private previews,
predetermined attitudes, retry gates, nuisance accumulation, rollback and undo.
All authored cases are unrun while checks are paused.


## Potential combat and morale

`RpgExpandedCombatReaction` interprets a known private reaction `band` using
`inCombat`, `outnumbered`, `hopeless`, `escapePossible` and `visitorsRemain`.
These are explicit encounter facts, including what the NPCs perceive; they are
not inferred from hidden character statistics. `assess()` is pure and returns
an `intent`, `noQuarter`, `leaveDemand` and `aidModifier`.

Low bands can call for attack or continued fighting; the poor band demands that
visitors leave before its out-of-combat attack/flight decision. Neutral standing
means peaceful passage or an attempt to disengage from an existing fight.
During combat the good band calls for flight, the next band for flight if possible
and surrender otherwise, and the highest band for surrender. Flight is an intent:
the tactical system must still determine and execute legal movement. It is not a
teleport or a successful escape guarantee. Outside combat the top three bands
permit aid/information follow-up rolls at +1, +3 and +5 respectively.

`rpgExpandedCombatReactionModifier(perceivedStrength, commonLanguage, intruders)`
combines the authored -5 through +5 relative-strength assessment with the -2
language and -2 home-territory modifiers (full-2008 B561). Add this once when
preparing the associated reaction attempt. Resolve an encounter result first,
then pass its private band to this assessment. Do not expose hidden attitude
through player-facing events.

Combat AI execution, surrender acceptance, possible later ambushes and voluntary
party membership remain pending. The current interface specifies the table's
immediate decision, not its complete world consequences. The minimal social
fixture and `tests/expanded.py::test_combat_reactions` cover the contextual branches
and modifiers. These cases remain unrun while checks are paused.


## Requests for aid

`RpgExpandedAidReaction` takes the resolved private `band`, whether the request is
`simple`, and an authored `reasonableness`: `reasonable`, `silly` or
`totally-unreasonable`. Pure `assess()` reports willingness and follow-up mechanics
from full-2008 B560–B562. Bands 0–3 deny help; the first two require a potential-combat
reaction (at -4 for band 0, or capped at neutral for band 1). Band 3 permits a retry
at -2. At neutral, simple requests are granted and complex requests may be retried
at -2. Good reactions grant reasonable requests and offer advice when denying
unreasonable ones. Very good reactions grant anything short of totally unreasonable
requests and volunteer useful information. The highest band offers additional help
within the provider's capability.

The result distinguishes `granted`, `extent`, `advice`, `volunteerInformation`,
`combatFollowup`, `followupModifier`, `followupBestBand`, `retry` and `retryModifier`.
Do not treat `granted` as completed assistance. A provider still needs the time,
resources and abilities for the requested task. Follow-up combat rolls and changed
approaches must use persistent encounter/attempt records; they are not performed
by this pure assessment. If a hostile follow-up cannot produce combat, its other
hostile world consequences remain an authored requirement.

`RpgExpandedAidModifiers` supplies the context-specific total: +1 for `verySimple`,
an authored nonpositive `complexity`, -1 for `inconvenience`, optional `standingRisk`
of -2 or worse, and optional `physicalRisk` of -1 or worse. Nil risk means absent.
Risk magnitude and courage are world judgments; the implementation does not guess
them from unrelated traits. Add this total once to the reaction attempt.

`tests/expanded.py::test_aid_reactions` covers each band, complexity/reasonableness
branches, escalation caps and modifiers. Cases remain unrun. Provider task execution,
resource transfer, advice content and follow-up encounter orchestration are still
pending, so these entries remain partial in the coverage ledger.


## Information requests

`RpgExpandedInformationReaction` uses a resolved private `band` and `complexity`
(0 simple, 1 complex, 2 very complex). Ordinary enquiries use `mode = 'enquiry'`.
Professional information sales return `information-use-trade`; interrogation
returns `information-use-interrogation`, preventing silent use of the wrong
procedure. Both corresponding procedures remain separate implementation work.

At bad reactions, authors select `adverseChoice = 'lie'` or `'payment'`. The latter
returns a demand until `paymentReceived` is true, then an incomplete answer. Poor
reactions require `'unknown'` or `'partial'`; an offered bribe permits another
reaction attempt. The lowest band calls for a combat reaction at -2; the next band
calls for a malicious lie. Neutral replies are complete only for simple questions.
Good replies answer the question, very good replies add related knowledge, and
excellent replies add a research obligation when `knowledgeIncomplete`. If an
excellent respondent `offersHelp`, a subsequent aid roll receives +2 and cannot be
worse than band 3. These follow-ups are returned requirements, not extra hidden rolls.

The result's answer modes distinguish `malicious-lie`, `claims-ignorance`,
`demand-payment`, `incomplete-belief` and `requested-belief`. Belief is what the
respondent thinks true, which can differ from the world. This assessment does not
supply text or knowledge: authoring and delivery must constrain answers to the
respondent's known facts, and deliberate lies require explicit false claims.
Knowledge storage, research execution, paid delivery and follow-up orchestration
remain pending. Do not count a response mode as completed information transfer.

`RpgExpandedInformationModifiers` combines -1/-2 complexity, -3 for `intrusive`,
an optional `danger` penalty of -3 or worse, and an authored
`knowledgeProfessionBonus` of 2–4 (zero if absent). `bribeScale` is `none`, `day`,
`week`, `month` or `year`, referring to the respondent's income-equivalent value;
the resulting bonus is 0–4 (full-2008 B44–B45 and B562). Nonzero bribes require
`discreet` and `appropriate`. This only assesses the bonus: it neither deducts
money nor executes a promised favor. Those must be committed once through the
relevant world operation. Calendar and income equivalence remain authored facts.

`tests/expanded.py::test_information_reactions` covers response modes, partial
answers, follow-up requirements and modifier scales. All cases remain unrun while
checks are paused; the module remains partial.


## Knowledge-constrained delivery

Assign each participating profile one `RpgExpandedKnowledge` through `knowledge`,
with the matching `owner`. `beliefs` contains authored statement identifiers or
objects the character believes; `fabrications` contains deliberate claims they
know they are making up. The same statement cannot occupy both lists. World truth
is separate and is never queried automatically by this module.

`RpgExpandedInformationDelivery` identifies a response by `id`, `provider`,
`recipient` and its `reaction`. Select `requested` statements from the provider's
beliefs, a strict `partial` subset for incomplete answers, optional `related`
beliefs and `lies` from fabrications. The authored selection must represent the
question's known answer; a complete answer here means all selected known statements,
not omniscient knowledge. An incomplete answer cannot select the entire nonempty
requested list. Deliberate lying requires at least one authored fabrication.

Set `available` only when the participants can communicate. `assess()` checks
readiness and selection but returns no statements. `deliver()` returns the selected
statements to the author and records `[id, provider, statements]` in the recipient's
knowledge `received` list. It does not add them to the recipient's beliefs. Only
render those statements through authored dialogue; do not expose the provider's
private belief/fabrication classifications. `selectedStatements()` is an author-only
query and must not be used for player previews.

The recipient's receipt prevents duplicate deliveries even through another object
with the same response ID. Claimed delivery objects cannot be retargeted. No time,
money or randomness is charged by delivery; associated payment or speaking time
must be committed once by the enclosing operation. An unanswered demand, refusal
or claim of ignorance cannot be delivered as factual content. Research obligations
and follow-up rolls remain separate requirements. Automatic payment integration,
uncertain-knowledge checks and belief revision remain pending.

`tests/expanded.py::test_information_delivery` covers bounded knowledge, incomplete
selection, explicit lies, private previews, receipt reuse, exception rollback and
undo. These authored cases remain unrun while checks are paused.
