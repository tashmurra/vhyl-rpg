# Expanded social

**Status: partial.** Reactions, influence and social permissions. Neutral source: `full-2008`, B359; B494-B495; B559-B562.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-social.t` after the expanded foundation. Available procedures include standing and rank accounting, contextual reactions,
information exchanges, trade and loyalty. The guide below defines each supported
subset; full catalogue effects, influence and permissions remain incomplete.

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

The subsystem is partially implemented as described below. Individual inventory
entries retain their remaining gaps; authored fixtures are unrun while build
checks remain paused.

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

Several context-specific outcomes and owned reaction procedures are implemented
below. Complete outcome and trait integration remain pending; the inventory alone
does not establish runtime correctness.


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
statements to the author and records `[id, provider, statements, moneyPaid]` in the recipient's
knowledge `received` list. It does not add them to the recipient's beliefs. Only
render those statements through authored dialogue; do not expose the provider's
private belief/fabrication classifications. `selectedStatements()` is an author-only
query and must not be used for player previews.

The recipient's receipt prevents duplicate deliveries even through another object
with the same response ID. Claimed delivery objects cannot be retargeted. No time or randomness is charged by delivery. The optional payment contract below
transfers money atomically; associated speaking time must be committed once by
the enclosing operation. An unanswered demand, refusal
or claim of ignorance cannot be delivered as factual content. Research obligations
and follow-up rolls remain separate requirements. Broader bribery integration, uncertain-knowledge checks and belief revision remain
pending.

`tests/expanded.py::test_information_delivery` covers bounded knowledge, incomplete
selection, explicit lies, private previews, receipt reuse, exception rollback and
undo. These authored cases remain unrun while checks are paused.


## Paid information delivery

For a band-2 respondent choosing payment, set the delivery's positive `price` and
explicit `paymentApproved`. The recipient is the payer and the provider is the
payee. The operation validates both balances, affordability, overflow and the answer
selection before changing either balance. It then transfers the price and records
the incomplete answer in one transaction. No secondary money account is created.

The reaction is assessed against the proposed payment without setting its shared
`paymentReceived` flag. A pre-paid reaction cannot also use a positive delivery
price: that combination is rejected to avoid double payment. A zero-price delivery
retains the existing externally-paid/free contract. Positive prices for other
reaction outcomes, self-payment and professional information sales are rejected
rather than inferred as equivalent transactions. This is payment for an answer,
not the separate bribe that modifies a new reaction roll.

The receipt stores the amount paid. Repeated delivery, including another object
with the same recipient/provider/ID, returns `reused` without charging. It does
not return the earlier answer as new content. `assess()` can report the price but
still omits all answer statements. `tests/expanded.py::test_paid_information`
contains approval/funds rejection, payment/answer accounting, rollback, undo and
repeat-payment cases. These authored checks remain unrun.


## Uncertain prior knowledge

`RpgExpandedKnowledgeCheck` takes an owned `knowledge` record, an authored
`statement`, `context` and explicit `plausible` world fact. Use a `RpgLiteContext`
(or compatible expanded context) with `kind = 'knowledge'`, checking intelligence
or a skill appropriate to the fact (full-2008 B562). A statement cannot also be a
known fabrication. Dead or unconscious characters cannot perform this check.
The context determines legitimate skill defaults and shared situational modifiers;
unavailable training is rejected before randomness is consumed.

`assess()` returns readiness without a score, result or known/unknown answer.
`resolve()` uses the shared check procedure once, stores the result in
`knowledge.checks`, and adds the statement to beliefs on success. Failure does not
invent a lie. Another object or context for the same statement reuses the recorded
result rather than rolling again. Existing beliefs need no roll. Later learning
can add a belief through a distinct authored acquisition process; it does not
rewrite the historical check.

This procedure determines prior knowledge, not research progress or objective truth.
The author must supply a plausible, specific statement and a relevant skill.
Player dialogue should reveal only the character's resulting recollection, not
private dice or the whole knowledge record. Standard transaction history includes
the random state, last check, stored result and any new belief together.

`tests/expanded.py::test_uncertain_knowledge` and `test_unknown_fact` cover private
preview, deterministic success/failure, no reroll, rollback and undo. These cases
remain unrun; cross-process knowledge continuation and research procedures still
need implementation/validation coverage.


## Trade reaction prices

`RpgExpandedTradeReaction` takes the private `band`, `direction` (`buy` or `sell`
from the player party's perspective), local `fairPrice`, and optional
`offeredPrice` (defaults to fair price). Pure assessment returns a price or refusal.
The fair price is the current local value, not necessarily the catalogue cost.
A lowest-band refusal requires a potential-combat follow-up at -2; it does not
transfer goods or money. Favorable bands also indicate an offer of advice/help.

At bands 1–3 the buy/sell factors are respectively 3 and 1/3, 2 and 1/2, and
6/5 and 3/4. Neutral and good reactions use fair price. The next band accepts offers
subject to a purchase minimum of 4/5 fair price and a sale maximum of 3/2; the
highest band uses 1/2 and 2. These limits do not imply automatic availability,
affordability or transfer of title. They are quoted prices, not committed trades.

The B562 altered-counteroffer example is internally inconsistent. For bands 1–5,
an offer differing from fair price returns `trade-counteroffer-source-conflict`.
No silently chosen interpretation is applied. Exact whole-unit arithmetic uses
`rpgExpandedTradeFraction`; fractional prices and overflow are explicitly rejected
pending a currency-precision policy. Exceptional discounts motivated by hidden
world circumstances remain separate, unimplemented author contracts.

`tests/expanded.py::test_trade_reactions` contains independent expected values for
all bands, both transaction directions, favorable offer limits, refusal, the source
conflict and arithmetic boundaries. These cases remain unrun. Bargaining modifiers,
merchant transfers, employment and professional-information trade integration
remain pending.


## Bargaining modifiers

`rpgExpandedTradeOfferModifier(fairPrice, offeredPrice, direction)` counts complete
ten-percent steps relative to the local fair price (full-2008 B562). A higher buy
offer favors the merchant and gives a bonus; a higher requested sale price favors
the player party and gives a penalty. The reverse applies below fair price.
Prices need not divide evenly into ten-percent units: the calculation compares
exact integer thresholds and never rounds an incomplete step into a full bonus.
It avoids multiplying large prices directly and explicitly rejects modifiers
outside the supported -1000 through +1000 range.

`RpgExpandedTradeModifiers` combines this result with an authored applicable
`merchantLevel`: nil gives no skill bonus, a qualifying rating below 20 gives +1,
and 20 or higher gives +2. Set the rating from the actual character and applicable
skill; this low-level context does not discover or validate catalogue membership.
Do not add the general high-skill reaction bonus again for the same commerce skill.
The assessment itself neither rolls nor commits an offer or money transfer.

`tests/expanded.py::test_trade_modifiers` covers both directions, exact and partial
ten-percent boundaries, fractional thresholds, large prices and skill boundaries.
`test_trade_persistence` adds a cross-process saved-trade continuation case. Both
are authored and unrun while checks are paused. Altered counteroffer pricing remains
blocked as documented above, even when its reaction modifier is calculable.


## Private loyalty records

Register `RpgExpandedLoyalty` in the subject's `loyalties`, with a unique `id`,
`subject` and `employer`. Only one relationship per employer is accepted. Loyalty
is separate from skill, competence and the accuracy of claims made at hiring.
Use `preset` for a predetermined rating, or `initialModifier` for a random initial
rating. `initialize()` records preset loyalty without dice, or rolls 3d once and
adds the modifier (full-2008 B518/B562). Repeated initialization reuses the rating.

`RpgExpandedLoyaltyCheck` references that record and a stable `incident`. The author
sets `necessary` when the actual situation calls for a check: ordinary combat is
not automatically mortal peril for an experienced fighter. Supply any circumstantial
`modifier` explicitly. `assess()` returns readiness without the private rating,
dice or result. `resolve()` compares 3d directly with effective loyalty; this is
not an ordinary skill roll with automatic failure on 17/18. An effective rating
of at least 20 resolves automatically without dice. Success and failure are saved
per incident, including the rating used, so a second request cannot reroll it.

Failure means the hireling acts in their own interests in that incident; it does
not automatically enact total betrayal. What action is taken remains specific to
the situation and must be authored. Do not emit private ratings or checks through
player-visible events. Preset/random initialization and incident records use the
normal transaction/save state; no extra elapsed time is charged.

`test_loyalty`, `test_loyalty_automatic` and `test_loyalty_failure` in
`tests/expanded.py` cover private previews, deterministic outcomes, automatic checks,
repeat incidents, rollback and undo. All cases remain unrun. Pay changes, rescue,
forgiveness, employer performance, service anniversaries and timed loyalty effects
remain pending. This is not yet complete employment or loyalty behavior.


## Noncombatant exposure and temporary loyalty

Use `RpgExpandedLoyaltyDanger`, a specialized loyalty check, when an actual
noncombatant is exposed to combat (full-2008 B519). Set `noncombatant` and
`necessary` explicitly and identify the incident. A failed check records a -1
penalty lasting 604800 seconds on the existing shared clock. A successful check
adds no penalty. Replaying the incident cannot extend its expiry or add another
penalty. The receipt also records its check kind; an ordinary loyalty incident
cannot be reused as a danger incident or vice versa.

`loyalty.rating()` calculates current effective loyalty without deleting expired
history. The penalty applies before, but not at, the expiry time. The check and
penalty add no elapsed time themselves. Clock advancement belongs to the actual
encounter and subsequent activities, so undo across an expiry restores the earlier
effective rating automatically.

The source notes that repeated exposures may have permanent effects, but does not
specify temporary stacking. A second danger check while the first penalty remains
active returns `loyalty-overlapping-danger-unresolved`; no roll is consumed. A
permanent change also requires a separately specified author decision. Do not
silently replace, refresh or stack the penalty. These combinations remain unresolved
coverage requirements.

`tests/expanded.py::test_loyalty_danger` contains failed exposure, repeat protection,
rollback, undo, overlap rejection and exact expiry-boundary cases. The cases remain
unrun while checks are paused.


## Permanent loyalty changes

`RpgExpandedLoyaltyChange` records specific completed events from full-2008 B519.
Supply the `loyalty`, event `id` and a concrete authored `evidence` reference.
For `kind = 'performance'`, set `continuing` and `adventureComplete`, then choose
`performance = 'great-success'`, `'botched'` or `'ordinary'`. The permanent change
is respectively +1, -1 or zero. The ID identifies the adventure, so another change
object cannot reclassify or reapply that adventure's result.

For `kind = 'forgiveness'`, the ID must identify an existing failed loyalty incident.
Set `forgiven` only after the employer has actually forgiven the hireling, with or
without punishment. On commitment, current effective loyalty of 16 or higher gives
+1 to base loyalty; below that threshold the event is recorded with zero change.
Recording the zero change prevents later attempts to collect a bonus for the same
forgiveness after loyalty rises. These operations add no time, randomness, money
or character points.

`assess()` checks authored event prerequisites without returning the private rating
or prospective change. `apply()` changes the base and records
`[kind, id, change, evidence]` in the relationship's `changes`. These are private
author interfaces. They do not create the adventure outcome, forgiveness dialogue,
or a character's decision to forgive.

Authored cases `test_loyalty_performance`, `test_loyalty_botched`,
`test_loyalty_forgiveness` and `test_loyalty_forgiveness_low` in `tests/expanded.py`
cover signed changes, duplicate events, the eligibility threshold, zero-change
receipts, rollback and undo. Checks remain paused and unrun. Rescue, pay and
service-anniversary changes remain pending.


## Service anniversaries

`RpgExpandedServiceAnniversary` implements the annual check from full-2008 B519.
Supply the owned `loyalty`, sequential `year` starting at 1, `anniversaryAt` on the
shared clock, and the authored `completedService` fact. The campaign calendar must
calculate the real service anniversary; the runtime does not impose a 365-day year.
Due dates must increase, years cannot be skipped, and a check cannot run before its
date. This operation does not itself advance time.

`assess()` reveals no rating or check result. `resolve()` checks current loyalty,
gives a permanent +1 on success, and records the year even on failure. Effective
loyalty of 20 or higher succeeds without dice. Results are stored in `serviceYears`,
with `lastServiceYear` and `lastAnniversaryAt` enforcing chronological processing.
A repeated year, including a new operation object, reuses the prior result with
zero additional change. Catch-up must process outstanding years in order; author
simulation must supply the loyalty state appropriate to each past anniversary,
rather than silently applying today's state to an earlier year.

Authored cases `test_service_anniversary`, `test_service_failure` and
`test_service_automatic` in `tests/expanded.py` cover prerequisites, early dates,
skipped years, success/failure, automatic outcomes, duplicate years, rollback and
undo. The fixture uses a deliberately short authored calendar interval to exercise
date behavior without assuming a world calendar. Checks remain paused and unrun.
Calendar scheduling and rescue/pay integration are still incomplete.


## Rescue gratitude

`RpgExpandedRescueLoyalty` represents one completed rescue from full-2008 B519.
Provide the owned relationship, unique rescue `id`, concrete `evidence`, `rescued`
and `riskedLifeOrMission`. `rescueBonus` is at least +3; the author may choose more
for the nature of the rescue. Other applicable reaction adjustments belong in
`otherModifier`. The assessment validates these facts before any roll.

`resolve()` rolls 3d plus those modifiers. At a total of 13 or higher, base loyalty
becomes the greater of its previous value and the reaction total. A lower reaction
leaves it unchanged. A serious injury or death among the rescuers may justify an
optional additional permanent bonus: set `seriousSacrifice` and an explicit
`sacrificeBonus`. The source leaves that amount to the author; zero is the default.
This authored extra bonus is applied in addition to the ordinary gratitude result.

The relationship's `rescues` history stores the roll, total, resulting rating,
evidence and extra bonus. Reusing the rescue ID returns the saved result without
rerolling or applying a bonus again. A private preview contains no loyalty or dice.
No rescue time or injury is charged here: those must already be represented by the
actual rescue operation. Rescue itself is not simulated by setting these facts.

Interactions between temporary loyalty modifiers and the source's “original
loyalty” comparison remain unresolved. When current effective loyalty differs from
base, this operation returns `rescue-temporary-loyalty-unresolved` before rolling.
The independent cases `test_rescue_loyalty`, `test_rescue_no_decrease`,
`test_rescue_ungrateful` and `test_rescue_sacrifice` cover gratitude thresholds,
retained higher loyalty, optional sacrifice, replay, rollback and undo. Checks
remain paused and unrun.


## Higher pay and its lingering bonus

`RpgExpandedLoyaltyPayChange` implements full-2008 B519. Set `mode = 'start'`,
owned `loyalty`, unique event `id`, `normalPay`, `actualPay` and concrete `evidence`
of the compensation arrangement. Both amounts cover the same period or loot share.
Each complete ten-percent increase gives +1 loyalty. Below-normal pay and increases
smaller than a full step do not create this bonus. This operation records the loyalty
effect; salary or loot payment must use its own single money transfer.

The relationship keeps `payBonus` separate from `base`. Consequently, exclude this
same higher-pay factor from `initialModifier` and from any later check's manual
modifier. Effective `rating()` adds it once. The pay arrangement can be established
before initial loyalty is determined; initialization returns the resulting effective
rating without embedding the bonus in the permanent base.

When extra pay actually ends, use a new event with `mode = 'stop'` and `expiresAt`
set to one calendar month after cessation. The authored calendar must supply that
absolute shared-clock date; no fixed thirty-day month is assumed. The bonus remains
active before that date and expires exactly at it. Neither start nor stop advances
time, and repeated event IDs cannot reapply or extend the effect.

Changing an active bonus, or starting another while its old bonus lingers, returns
`loyalty-pay-overlap-unresolved`. The supplied rule does not specify overlapping
rate changes; the engine does not silently stack or refresh them. After expiry a
new arrangement with a new event ID can start normally. Underpayment, ongoing
salary processing and employment consequences remain separate requirements.

`tests/expanded.py::test_loyalty_pay` covers bonus/base separation, repeated events,
rollback, undo and exact expiry. Its short fixture date stands in for an authored
calendar month. All cases remain unrun while checks are paused.


## Character/social subset authoring

## Standing and reputation

`RpgExpandedStatus` is a culture-specific contribution. `RpgExpandedRank` adds an
authored institution, admission and whether rank replaces status.
`RpgExpandedSocialStructure` defines how purchased status, rank and installed
wealth contributions interact. The character/social umbrella does not include the campaign wealth module;
wealth-linked behavior requires an explicit compatible contribution.
`RpgExpandedStatusEncounter` needs recognition, culture and relevant disposition
facts. A score does not automatically confer access or legal authority.

`RpgExpandedReputation` owns facets `[audienceID, modifier, breadth]`, a `details`
reference and recognition frequency. Multiple facets must be explicitly disjoint.
Use `RpgExpandedReputationRecognition` with the concrete audience, applicable
facet, geographic applicability and exposed identity. Resolution is retained for
that audience, including failed recognition. `rpgExpandedReputationModifier`
combines resolved reputations for one subject/audience and enforces the modifier
cap. Price and recognition are separate operations.

## Private reactions and authored consequences

Register `RpgExpandedReactionEncounter` in the subject's `reactionEncounters`.
Its unique ID identifies the ongoing encounter. Authored bounds or a predetermined
band are supported. `RpgExpandedReactionAttempt` supplies a distinct approach,
modifier and any explicit retry/nuisance facts. Assessment does not expose saved
attitudes or dice. Resolution is private author data; a repeated approach does not
reroll. A new approach needs approval, and fights/predetermined reactions restrict
retries. Waiting reasonably is an authored fact, not a universal timer.

`RpgExpandedAidReaction`, `RpgExpandedInformationReaction`,
`RpgExpandedTradeReaction` and `RpgExpandedCombatReaction` translate a band and
context facts into structured decisions. Read their consequence fields. They do
not themselves grant aid, research unknown answers, transfer goods or start combat.
Trade uses whole currency units; unsupported fractional prices and ambiguous
counteroffer combinations are rejected. Combat reactions describe decisions only;
this milestone does not include expanded combat execution.

## Information delivery

An owned `RpgExpandedKnowledge` separates beliefs, fabrications and received
statements. `RpgExpandedInformationDelivery` selects requested, partial, related or
fabricated information from the provider's actual records. It has a unique ID,
provider, recipient, response decision and availability. Optional payment requires
an explicit payment contract and commits once with the receipt. Receiving a
statement does not automatically make it true or make the recipient believe it.
`RpgExpandedKnowledgeCheck` retains an authored plausible-knowledge check and its
result without manufacturing facts on failure.

## Loyalty

Register an owned `RpgExpandedLoyalty` for each relevant employer relationship.
Initialization accepts a preset or rolls the initial reaction once.
`RpgExpandedLoyaltyCheck` uses the separate direct-roll loyalty procedure;
`RpgExpandedLoyaltyDanger` tracks its timed noncombatant danger penalty.
Performance/forgiveness changes, service anniversaries, rescue gratitude and pay
changes use their distinct persistent records. Supply concrete authored evidence
for these events. Assessments keep private results private. Money transfers and
work schedules are not part of the social module.

The source-derived API reference documents fields and methods. Full influence
contests, contacts, complete social permissions and some reaction follow-up
procedures remain outside this milestone. Source mapping: `full-2008` B27-B30,
B44-B45, B494-B495, B518-B519 and B560-B562. See the [prerelease validation record](../releases/v1.1.0-alpha.1.md).

The prerelease record applies to the original subset. Checks for this merged
expanded suite remain paused.


### Threatening recurrence of a resolved condition

When the optional health library is included, `RpgExpandedAgonyThreatContext`
connects a recovered agony episode to interrogation or intimidation scoring.
Supply the actual target, owned episode, credibility decision and supporting
threat evidence. It contributes the B428 bonus once through the normal skill
modifier interface. Use it with the shared score/check functions or, for
intimidation, `rpgLiteInfluence`; the latter rejects a mismatched target before
rolling. Keep unrelated adjustments in `modifier`, without adding the recurrence
bonus a second time. See the [health guide](health.md) for fields and limits.
This adapter does not supply the full interrogation procedure or automatically
transfer knowledge. Its fixture is authored and unrun while checks are paused.


### Owned interrogation questions

`RpgExpandedInterrogation` supplies the full-2008 B202 procedure for an authored,
continuous questioning session. Set its `id`, expanded-profile `interrogator`,
`prisoner` and IQ/Average `interrogation` skill. Each
`RpgExpandedInterrogationQuestion` supplies a unique `id`, `session`, question
identifier, `truthfulAnswer`, `falseAnswer`, `approved` and `evidence`. Responses
are original authored identifiers or objects; the engine does not manufacture
facts. Supply both possible answers even when ordinary failure uses silence.

`assess()` is pure and reveals no selected statement. `apply()` spends five
minutes and resolves a Quick Contest against Will. Victory selects the truthful
answer; a tie or ordinary defeat selects `failureResponse` (`silence` or `lie`).
Defeat by more than five selects `believable-lie`. The result records the contest,
margin, response kind and statement. Keep these results and dice private to the
author/GM; deliberately decide what narration the player receives. A returned lie
does not automatically become a belief or an entry in the knowledge ledger.
Replaying a committed question returns its stored result without time or rolls.

Set `loyaltyResists` for the source's Very Good/Excellent loyalty condition.
`means` is `ordinary`, `severe-threat` or `torture`; it describes established
fiction, not an action that inflicts damage. The operation applies the source's
−5 loyalty modifier, −3 low-empathy modifier, +3 severe-threat or +6 torture bonus,
and +1 callousness bonus to either of the latter. After the session passes two
hours, questions receive +2. These adjustments are applied once; put only other
modifiers in `modifier`. Evidence must establish the declared circumstances.

Questions own their five-minute intervals and receipts. Both participants must
remain available, and their effective scores must be unchanged at completion.
Shared-clock deadlines may reject an interval before time is spent. A subsequent
question must start at the previous question's completion; interrupted sessions,
repeat questions, exhausted/critical-health participants and institutional teaching
access remain explicit unfinished integrations. Answer delivery is an explicit
operation described below.
The separate recovered-agony threat context is not yet wired into this owned
question operation; an author can assess its contribution and supply it once as
an additional modifier. `expanded-interrogation.t` specifies outcomes, modifiers,
preview purity, replay, rollback, undo, saved continuation and the two-hour
boundary. Assertions remain unrun.


### Delivering an interrogation answer

After a question resolves, `RpgExpandedInterrogationDelivery` records its spoken
answer in the interrogator's existing `RpgExpandedKnowledge.received` ledger.
Supply a unique delivery `id`, the completed `question`, and its interrogator as
`recipient`. The recipient must own a valid knowledge object. `assess()` reveals
no statements; `deliver()` returns the committed statement and stores its source
as the prisoner. The five-minute question already paid for the conversation, so
delivery spends no additional time, money or randomness.

A question can be delivered once, even through differently named delivery
objects. Replaying the same delivery validates its target, question and knowledge
receipt, then returns the same statement. Silence creates no delivery. Truthful
and false answers both enter the received-claims ledger: neither automatically
changes the recipient's beliefs or fabrications. The private question result
retains its truth/lie classification; do not expose that classification as player
knowledge. Witnesses, sharing claims, belief adoption and using a received answer
to authorize another subsystem still require separate authored operations.

The interrogation fixture specifies unanswered-question rejection, preview
privacy, truthful and false claims, silence, duplicate prevention, rollback, undo
and saved continuation. These assertions are authored and unrun.

## Delivering a resolved statement

`RpgExpandedStatementDelivery` connects a concrete resolved communication to a
recipient's existing `RpgExpandedKnowledge.received` ledger. Currently the
truthfulness trigger supplies this receipt through its `communication` property.
The foundation's `RpgExpandedStatementReceipt` keeps the source, speaker,
statement, private outcome classification and delivery ownership together. Its
source validates it against the original resolved procedure before delivery.

Set a stable delivery `id`, the `communication`, and an expanded `recipient`
with owned knowledge. The author must set `heard = true` and nonempty `evidence`
establishing that this recipient heard and understood this particular utterance.
This is a story fact, not a substitute for unresolved language, range or perception
checks: resolve any such uncertainty first. The speaker cannot be its own
recipient. Separate witnessed recipients require separate evidenced deliveries.

`assess()` returns readiness without revealing the statement. `deliver()` records
`[id, speaker, [statement], 0]` and returns the statement, without adding time,
randomness, payment or a second self-control roll. A withheld statement blocks.
One utterance reaches each recipient at most once, even under another delivery
ID. Replaying a completed request returns its bound statement; changing its
fields, source content or received ledger rejects.

Truth, convincing falsehood and obvious falsehood all enter the received ledger
as heard statements. They do not automatically become beliefs or fabrications,
and the receipt's private classification is not copied to the recipient. The
authored conversation may portray an obvious lie according to the resolved
outcome. Belief adoption, deception contests, parser/dialogue routing and automatic
witness discovery remain separate integration obligations.

The delivery is an engine integration contract for the full-2008 B159 outcome,
not an additional published influence mechanic. `expanded-statement-delivery.t`
and `test_statement_delivery` specify hearing evidence, withheld information,
truth/lie delivery, ownership, preview purity, replay, duplicate prevention,
rollback, undo, altered-receipt rejection and cross-process continuation.
These assertions remain unrun while checks are paused.

## Occupational reactions to danger avoidance

`RpgExpandedDangerReactionContext` extends the shared social context for the
full-2008 B129 setting-dependent reaction. Supply an expanded `subject`, an
`observer`, `approved = true` and nonempty `evidence`. Set `avoidanceKnown` when
this observer knows about the trait, and `occupationalExpectation` when the
authored setting and role apply the penalty. Neither fact is inferred from a job
title or a failed fear check. Both must be true for a penalty.

The context obtains the concrete purchased trait's 4/3/2/1 penalty for ratings
6/9/12/15. `rpgLiteReactionModifier(subject,context)` applies it once alongside
other reaction modifiers. The context's ordinary `modifier` remains available
for unrelated circumstances; do not repeat this trait penalty there. An observer unaware
of the trait or an inapplicable occupational expectation contributes zero. If applicable
facts are asserted without a concrete purchased trait, the request rejects.

Pass the same context to `rpgLiteInfluence`. Its observer must match the actual
target. Participant and authored-fact validation occur before any influence dice;
Diplomacy's ordinary-reaction result uses the penalty through the shared modifier
path. This does not turn the reaction penalty into a skill penalty or override
another influence skill's specific outcome procedure.

The shared context's new hooks return zero/no-op by default. Existing Lite calls
retain their arithmetic and dice consumption. The fixture covers all four ratings,
unknown/inapplicable cases, unrelated modifiers, Diplomacy and invalid requests
before RNG. These assertions remain unrun. General multi-trait reaction composition
and parser/dialogue routing remain broader integration obligations.

## Automatic social-skill reaction bonus

Attach `RpgExpandedReactionMastery` to a reaction attempt's `mastery` field.
Supply the same encounter, one selected Diplomacy or Fast-Talk skill, approval
and concrete context evidence. The assessment uses the subject's skill rating,
not a fresh skill roll or a temporary skill-check modifier. Diplomacy at level
20 or higher gives +2 (full-2008, B187). Fast-Talk at that level gives +2 only
when `canSpeak` establishes that the character is allowed to talk (B195).
Level 19 gives no bonus. The ordinary definitions are checked against their
printed attributes, difficulties and attribute defaults.

The reaction attempt adds this bonus once to its existing modifier. Do not also
include the same bonus manually in `modifier`. The encounter stores the selected
skill, assessed level, modifier and evidence in `masteryHistory`, alongside its
existing private reaction history. Preview adds no history or randomness, and
replay retains the original total after skill changes. Predetermined reactions
bypass the mastery assessment and consume no dice.

This adapter selects one qualifying skill. Combining multiple mastery sources
and the separate successful-skill-roll bonus are not implemented by this field.
It does not replace influence procedures or expose secret attitudes to players.
`tests/fixtures/expanded-reaction-mastery.t` covers the 19/20 boundary, speaking
eligibility, predetermined outcomes, replay, rollback, undo and saved
continuation; assertions are authored, unrun.

## Contextual skill preparation

`RpgExpandedReactionPreparation` owns one Administration or Carousing check for
an encounter before its reaction history begins. Supply the encounter, skill,
reaction kind, contextual modifier, approval and evidence. Administration requires
`reactionKind = 'bureaucracy'` and gives +2 on success (B174). Carousing supports
`general`, `aid` or `information`, gives +2 on success, and gives -2 on failure
(B183). The evidence must establish the actual audience and appropriate setting.

Include health for action permission. `requiresMovement` describes the authored
task. `seconds` is its authored duration, charged through the existing ledger
once; zero is available for a check whose activity time was already accounted
for, which must be explained in the evidence. The reference gives no universal
duration for these contextual tasks. Skill modifiers must likewise have a
concrete rationale; this request does not automatically purchase entertainment.

Call `assess()` for a pure preview and `resolve()` before the reaction attempt.
The encounter records the check and automatically includes its modifier in later
reaction attempts, including approved changed approaches. A failed Carousing
check therefore continues to penalize that audience. A second preparation cannot
replace the recorded check, and replay neither spends time nor rolls again.
Health permission denial is recorded without setting a reaction modifier.
Predetermined reactions need no preparation and bypass any modifier.

Do not manually add the same modifier to the reaction attempt. Other contextual
skills, entertainment purchasing, special failure dangers and broader carry-over
between separately authored encounters remain pending. The preparation fixture
covers success, distinct failure effects, persistent modifiers, time charged
once, rollback, undo and saved continuation; assertions are authored, unrun.

## Paid Carousing entertainment

Attach `RpgExpandedCarousingEntertainment` to a contextual preparation's
`entertainment` field. Set its reciprocal `preparation`, payer, provider, price,
bonus, availability, approval and evidence. The payer must be the encounter's
subject; the provider is a distinct profile with an existing money balance.
The author sets the local price and an appropriate skill bonus of +1 through +3
(full-2008, B183). There is no invented fixed conversion from money to bonus.

Preparation preview verifies affordability, service facts and the bonus before
health permission, time or dice. On commitment, the existing money balances
transfer the price once before the Carousing roll. The receipt is bound to this
preparation; another preparation cannot borrow it. Replay and saved continuation
retain the payment. Failure still pays for entertainment already provided and
retains Carousing's -2 reaction consequence.

The bonus applies to the Carousing skill check, not directly to the reaction
roll. Do not add it again to `skillModifier`. Health permission denial makes no
purchase. Entertainment inventory, individual drink consumption, intoxication
and special venue dangers remain separate pending integrations. The fixture
`tests/fixtures/expanded-carousing-entertainment.t` covers affordability, service
availability, +1/+3 score effects, money conservation, replay, rollback, undo and
saved continuation; assertions are authored, unrun.

### Changes during preparation

Preparation rechecks its bound definition and encounter after health permission,
after elapsed time, and before recording the result. A changed audience, changed
price or removed payment object invalidates the operation. A reaction that runs
during the preparation interval also invalidates it; the earlier preflight is
not sufficient to attach a later bonus to an already-resolved encounter.

These failures propagate to the enclosing action transaction so time, payment,
random draws, encounter changes and receipts roll back together. Do not catch
and suppress the failure inside an action that then commits partial changes.
The `expanded-social-interruption.t` fixture injects audience, encounter, price,
definition-length and provider-capacity changes during time advancement, then
checks rollback and successful retry after cross-process restore. Assertions are
authored, unrun while checks remain paused.

Carousing preparation now also consumes the traits module's
[social-inhibition penalty](traits.md#social-inhibition) through the shared score
hook. Its -1/-2/-4 is separate from entertainment's +1 to +3 and is applied once.
Other emotional-motivation and pleasure-related trait penalties remain pending.

The traits module now supplies the
[emotional-understanding deficit](traits.md#emotional-understanding-deficit)
through the same context hook as social inhibition. Carousing and other listed
emotion-dependent checks take -3; the skills remain learnable. This replaces the
earlier missing emotional-motivation penalty for this concrete trait definition.
Pleasure-related effects and other trait integrations remain pending.

## Observed lack of appreciation

Set a reaction attempt's `socialContext` to
`RpgExpandedPleasureReactionContext` for the B141 reaction effect. Identify the
subject and observer matching the encounter, set `noticeable`, choose a penalty
from 1 to 3, and provide approval and evidence describing what the observer
noticed. The penalty applies only while the subject's pleasure-loss trait is
active and unmitigated. The context also uses the ordinary visible/heard reaction
modifiers; do not add those or this penalty manually to the attempt's modifier.
A nil `socialContext` preserves the previous reaction calculation.

Use `consequence(band)` for this context's adverse response. It accepts only
`adverseResponse = 'ridicule'` or `'rejection'`; violent choices are rejected before
the reaction roll. An unfavorable band returns that authored social consequence
when the trait is noticeable. Otherwise it returns `ordinary-social-response`.
Do not feed this trait's adverse reaction into the potential-combat interpreter:
the source explicitly makes this ridicule or rejection rather than violence.

The fixture covers notice, mitigation, penalty endpoints, private reaction
replay and nonviolent response validation. Assertions are authored, unrun.
Cross-context narrative consequences and modified trait variants remain pending.

The traits module's [emotional obliviousness](traits.md#emotional-obliviousness)
now modifies both acting skill and target resistance for the six ordinary
influence skills. The new resistance hook defaults to zero, preserving existing
behavior without the trait. Unsupported effective resistance below three is
rejected before rolling rather than returned as a misleading ordinary outcome.
