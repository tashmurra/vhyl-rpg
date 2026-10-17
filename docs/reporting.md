# Assessments and roll explanations

Include `<vhyl-rpg-report.t>` after `<vhyl-rpg.t>` for optional CRPG-facing
assessments and reports. Language, dialogue and action-preview modules are not
dependencies of the reporting extension. It reserves no transport verb codes.

## Authoring an explanation

Give skills and traits a `labelId` for the host's translations. Attribute checks
use built-in labels: `rpg.strength`, `rpg.coordination`, `rpg.intelligence`,
`rpg.health`, `rpg.will` and `rpg.perception`.

The core computes a temporary `RpgCalculation` containing:

| Field | Meaning |
| --- | --- |
| `abilityLabelId` | Authored skill label, or the attribute label |
| `attributeId` | Governing attribute label |
| `training` | `attribute`, `trained`, `default`, or `unavailable` |
| `attributeScore` | Governing rating used; capped at 20 for a default |
| `defaultPenalty` | Explicit default adjustment, or nil |
| `baseScore` | Skill/default/attribute rating before situational adjustments |
| `effectiveScore` | Final rating used by the check |
| `modifiers` | Flat triples of category, label ID and signed amount |

Categories are `situation`, `context`, `trait` and `other`. Zero adjustments are
omitted. The first 31 nonzero components remain separate; any remaining total
is grouped under `rpg.modifier.other`, keeping the published explanation bounded
without changing its arithmetic. No trait or modifier is discarded from the
effective rating.

`modifierLabelId` and `contextLabelId` label an approach's fixed and contextual
adjustments. `oppositionModifierLabelId` and `oppositionContextLabelId` do the
same for resistance. Their defaults are generic message IDs. Each trait's
`labelId` describes its own adjustment. For example, a host can render:

```text
Lockwork 11 -2 difficulty +3 preparation = 12
74.1% chance of achieving the goal
```

Calculation and outcome code is shared with execution. Context and trait hooks
must remain observational, including when used by the resolver. Assessment
never calls `apply`, rolls dice, records an attempt, charges costs, teaches facts,
or creates a history interval.

Publish assessment events from a query entry point, outside ranking, affordance,
or choice-availability hooks: vhyl requires those hooks to emit no output.

## Assess a possible attempt

```text
local assessment = rpgAssess(surveyor, pickHatch);
rpgPublishAssessment(assessment, nil);
```

`rpgAssess(profile, approach)` is a trusted query. It requires the same declared
attempt slot as execution, and observes the same completion, prerequisite,
retry, resource and ability rules. Its return value must not be exposed directly
to players: it can contain secret difficulty and opposition details.

| Status | Meaning |
| --- | --- |
| `ready` | A fresh attempt is available; odds and applicable costs are supplied |
| `blocked` | A prerequisite, resource or usable rating is missing |
| `settled` | This revision was attempted already; `recorded` contains that result |
| `complete` | The shared goal is already complete |

Blocked, settled and complete assessments have no fresh-roll odds. Settled
assessments retain the previous calculation, not a recalculation with newly
changed attributes. Their immediate costs are zero. The next committed action
always evaluates the current situation again; an assessment is not permission
to bypass action scope or prerequisites.

For a ready assessment, `odds` is a temporary `RpgOdds` with exact counts:

| Count | Meaning |
| --- | --- |
| `total` | 216 ordinary outcomes, 46656 opposed outcomes, or 1 automatic outcome |
| `achieved` | Goal achieved, including costly success |
| `success` | Successful outcome, including critical rolls that win |
| `costlySuccess` | Successful outcome with an authored cost |
| `setback`, `complication`, `tie` | Other mutually exclusive outcome categories |
| `rollSuccess` | Acting character's individual roll succeeds |
| `criticalSuccess`, `criticalFailure` | Acting character's individual critical flags |

`success + costlySuccess + setback + complication + tie` equals `total`.
`achieved` equals `success + costlySuccess`. The individual-roll counters overlap
the outcome categories. In a contest, a successful roll can lose to a better
successful roll, and critical flags do not override contest ranking. Automatic
outcomes have nil individual-roll counters because no roll occurs.

`odds.chanceBasisPoints()` returns the goal probability rounded to hundredths of
a percent (7407 for 74.07%). Hosts can use the original numerator and denominator
for their own rounding. The model is independent fair dice; it never inspects
the generator's next result. Implementation enumerates weighted totals rather
than sampling or consuming randomness.

## Record and report an actual attempt

```text
local result = rpgResolve(surveyor, pickHatch);
rpgPublish(result);
rpgPublishRoll(result, nil);
```

Core results now carry `dice`, `oppositionDice`, `kind`, `calculation` and
`oppositionCalculation`. Attempt slots preserve the faces, labels, training
state, modifier breakdown, ratings and original expenditure as scalar snapshot
data. Subsequent stat, label, skill or cost changes do not rewrite the report.
Dice are drawn once; reporting and reusing an attempt never draws again.

`rpgRecordedResult(profile, approach)` retrieves the last result from that slot,
even after the goal is completed or its revision changes. It returns nil if the
slot was never attempted. This trusted query does not evaluate current ability
or prerequisite hooks. It returns status `reused`, zero current charges, and
the original `recordedTimeSpent`/`recordedEnergySpent`. The slot retains only its
latest attempt; it is not a complete journal of every revision.

`rpgPublishRoll` ignores blocked/complete results. It can explain an automatic
success, but never invents dice for it. Roll reports use the recorded expenditure;
the existing `rpg.result` event still reports charges from the current call.

Undo, exception rollback and logical saves cover the snapshot data. Transport
actor handles may change on restore; use fresh handles from the restored world.
The actor handle in a report is current, while its mechanical calculation remains
the original snapshot. Logical saves must match the compiled program; this update
does not add migration for saves from earlier builds.

## Author ceilings and player preferences

Each approach defaults to hidden reporting. Set `assessmentDisclosure` and
`rollDisclosure` explicitly to `RpgDisclosure` records. `rpgFullDisclosure` is
an opt-in preset for public checks:

```text
modify pickHatch
    assessmentDisclosure = rpgFullDisclosure
    rollDisclosure = rpgFullDisclosure
;
```

Every `RpgDisclosure` field defaults to nil:

| Field | Permission |
| --- | --- |
| `visible` | Publish the approach ID and actor at all |
| `showAbility` | Ability label, governing attribute and training state |
| `showCalculation` | Ratings, default penalty and modifier breakdown |
| `showChance` | Exact outcome probabilities |
| `showCosts` | Immediate assessment costs or original roll expenditure |
| `showAvailability` | Ready/blocked/settled/complete status and reason |
| `showOutcome` | Recorded outcome and achievement |
| `showDice` | Recorded totals and individual faces |
| `showOpposition` | Existence and permitted details of the opposing check |
| `estimateLabelId` | Authored qualitative estimate when exact odds are withheld |

The second argument of each publisher is a player's requested `RpgDisclosure`.
Nil uses the author's ceiling. Otherwise each permission is the intersection of
author and player settings. A full player request cannot enable a hidden check,
and a reduced request can suppress details from a public one. Dynamic author
policy can override observational `disclosureFor(context, source)`, where source
is `assessment` or `roll`.

Hidden checks emit no reporting events, including no IDs. Numeric contest odds
require opposition permission from both records; otherwise they are withheld,
and only an explicitly authored qualitative estimate may be shown. Opponent
calculations and faces have their own opposition gate. Margins additionally
require numeric calculation permission because they expose effective ratings.

For secret modifiers, withhold both `showCalculation` and `showChance`; keep
`showAbility` and an authored estimate if those are known. Probability itself
reveals information about difficulty. The layer does not guess which authored
facts the player should know. Keep disclosure hooks observational and validate
world scope before publishing an approach.

The existing `rpgPublish` and `rpg.result` envelope are unchanged. Their disclosure
remains the caller's responsibility; enabling this extension does not publish
additional details automatically.

## Event envelopes (version 1)

All fields below are scalar values. Withheld values are nil. Hosts should key
translations by label ID and refresh transient views after world resynchronization.

`rpg.assessment`:

```text
version, challengeId, approachId, actor, status, reason, kind,
timeCost, energyCost, estimateLabelId,
total, achieved, success, costlySuccess, setback, complication, tie,
rollSuccess, criticalSuccess, criticalFailure
```

`rpg.roll`:

```text
version, challengeId, approachId, actor, status, kind, outcome, achieved,
recordedTimeSpent, recordedEnergySpent,
roll, margin, critical, oppositionRoll, oppositionMargin, oppositionCritical,
ownDiceCount, oppositionDiceCount, ownFaces..., oppositionFaces...
```

Counts are zero for an explicitly disclosed absent roll, and nil when withheld.
A total or margin does not authorize a host to infer or display redacted fields.

`rpg.calculation`, emitted after the assessment/roll header for each permitted side:

```text
version, source, challengeId, approachId, actor, side,
abilityLabelId, attributeId, training, attributeScore, defaultPenalty,
baseScore, effectiveScore, modifierCount,
(category, labelId, signedAmount)...
```

Source is `assessment` or `roll`; side is `acting` or `opposition`. Modifier
count is at most 32. Ability-only reports have nil numbers and zero modifiers.
An automatic attempt has no calculation event. Keep query batches within the
host's normal event transport limits.

## Hybrid example

The example exposes observational code 105 for its five known approaches.
`:odds` requests it without entering the gameplay cycle. The host's `--details`
flag displays permitted roll explanations and requests assessments alongside
`:plan`. Basic play continues to show the original narrative without dice.

The example explicitly opts into publishing roll events. Its host controls their
display, while the general publisher API also supports suppressing fields before
transport via player preferences. The keeper's exact opposition is withheld in
both assessment and roll events.
