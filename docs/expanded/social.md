# Reputation and social interactions

## Standing and reputation

`RpgExpandedStatus` is a culture-specific contribution. `RpgExpandedRank` adds an
authored institution, admission and whether rank replaces status.
`RpgExpandedSocialStructure` defines how purchased status, rank and installed
wealth contributions interact. No campaign wealth module is included here;
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
