# Expanded creatures

The [mounted-combat inventory](inventory/special-mobility.json) adds B396–B398
requirements to the creature chapter. Rider and mount retain separate maneuvers,
injury, hands or controls, training, load and position. Bucking tracks consecutive
successes and failures; alternation cannot accumulate toward either threshold.
Control-loss outcomes can release items, alter movement, loosen equipment, cause
falls or require timed recovery and recall attempts.

Mount control must share actual saddle, reins and passenger state with equipment
and tactical modules. A hit to the mount can require a rider check; rider stun or
knockback can cause a fall without injuring the mount. These procedures remain
pending implementation and validation.

**Status: partial; fixtures unrun.** Training assessments, handling modifiers and owned handling checks are available. Animals, body forms, mounts and swarms remain incomplete. Neutral source: `full-2008`, B175 and B455–B461.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-creatures.t` after the expanded foundation. It provides owned training days and milestones, task/calming checks, exact valuation assessments and natural-attack formulas. Creature combat execution remains incomplete. The convenience umbrella includes it without activating any rules.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

## Source inventory

The [creature inventory](inventory/creatures.json) records the first text pass
through B455–B461. It includes each printed encounter profile, the training-time
table, mount pricing, natural attacks and swarm examples. The training table and eligibility entries have partial implementations; independent
validation and the remaining entries are pending.

Printed encounter statistics are abbreviated. They preserve explicit secondary
score overrides, but omit traits needed for full character-point accounting.
Player-controlled creatures require complete definitions; importing a short
encounter record must not imply that requirement has been met. Inherited trait
lists and domestic/wild choices also need resolution before execution.

## Integration requirements

Creatures use the shared character and health model. Their body form determines
occupied spaces, legal movement, manipulation, attacks and crippling effects.
The module must preserve explicit changes such as a bear's smaller upright
footprint and a rider's position within a multi-hex mount.

Natural damage depends on attack type, strength, anatomy and trained brawling.
The printed dodge score already includes applicable reflexes; importing it and
then adding reflexes again would overstate the defense. The same care is needed
for precomputed natural damage and enhanced movement.

Animal training needs an owned course with intelligence eligibility, handling
specialty, daily trainer/animal time and completed milestones. General training,
one new trick and war training are different procedures. Printed war-mount
prices already include basic war training. Ordinary pets use currency and
authored behavior; unique companions use their complete character value and the
ally rules.

Swarms occupy a shared space and use automatic attacks and different defenses
against incoming damage. Tiny-creature ingress, sealed protection, dispersal,
target changes and compatible shield or stomping attacks need explicit state.
Treating a swarm as one ordinary animal would give the wrong rolls and timing.


[Additional anatomy and occupancy requirements](inventory/traits-catalogue-i.json)
include eye membranes, internal cargo/passengers and parasitic or spiritual
occupants. Internal payload is part of the body for movement and limited-capacity
abilities, while exposed payload loses the owner's defensive protection. Passenger
control requires a separate purchase. Body occupation must preserve separate
injury and resource histories for host and occupant. These effects are pending.

## Training assessments

`rpgExpandedAnimalTrainingDays(intelligence, level)` implements all sixteen cells
of the general training table for intelligence and training levels two through
five. Impossible cells return `nil`. `rpgExpandedAnimalTrickDays(intelligence)`
returns the separate single-trick duration; intelligence two returns `nil` because
no single-trick duration is supplied. Values outside the table reject explicitly.

Create `RpgExpandedAnimalTrainingPlan` with separate expanded `animal` and
`trainer` profiles, a purchased `animal-handling` skill, `appropriateSpecialty`,
`approved` and evidence. The author confirms species suitability and specialty
matching. For general training set `kind = 'general'` and `level`; for one trick
set `kind = 'trick'` and a neutral `trick` identifier. Set `wild` to match the
animal's authored mental package; the plan reports its -5 training modifier.

`assess()` returns structured eligibility, days and the source schedule: four
hours daily in two two-hour sessions. It neither rolls nor spends time, awards
behavior or changes character points. Owned attendance and daily checks are described below. Attack execution remains pending; learned metadata milestones are described below. A plan
must not be treated as a completed course.

## Handling modifiers

`rpgExpandedAnimalTaskModifier(familiar, stressful, complexityPenalty)` combines
unfamiliar-handler and stressful-circumstance penalties with an authored complex
task penalty. Use zero for a noncomplex task, or at least three for a complex one.
`rpgExpandedAnimalCalmingModifier(wild, frightened, manKiller)` selects the severe
calming category without counting wild and frightened twice.
`rpgExpandedAnimalCombatPenalty(handlingScore)` returns the animal's attack and
defense penalty at handling scores fifteen and twenty. These helpers do not
perform the task or install combat modifiers automatically.

The [minimal fixture](../../tests/fixtures/expanded-creatures.t) uses only the
foundation and this module. `test_animal_training_tables` authors all table cells,
trick times and modifier boundaries. `test_animal_training_plans` authors training
eligibility, specialty, wild modifier and preview purity. Fixtures are unrun while
checks are paused. Sources: `full-2008`, B175 and B458–B459.

## Owned task and calming checks

Create `RpgExpandedAnimalHandlingAttempt` with an expanded `animal` and `handler`,
the relevant `animal-handling` skill and a unique ID for that animal. Confirm
`appropriateSpecialty`, `approved`, `available` and `uninterrupted`, and explain
the circumstances in `evidence`. `seconds` is an authored scenario duration; the
source does not prescribe a universal time for these tasks.

For `mode = 'task'`, supply a neutral `taskId`, confirm `trainingEstablished`, and
set familiarity, stress and complexity facts. For `mode = 'calm'`, omit task
fields and select the animal's wild, frightened and dangerous-history facts.
`speciesModifier` accepts a separately sourced nonpositive modifier. These facts
are author assertions; this interface does not infer training from intelligence
or replace a creature's mental package. A handling request marked `performance` still rejects: use the separate
performance receipt below after resolving the ordinary task check.

`assess()` is pure. Execute `apply()` within an action transaction: it spends time,
rechecks request identity and participant availability, and resolves the shared
skill check. The receipt records `score`, `check`, `succeeded`, costs and the
animal's `animalHandlingAttempts` history. Replay returns the historical result
without spending time or rolling again. Retargeting a committed receipt rejects.

Every resolved receipt has `authorResolutionRequired = true`. `succeeded` means
the handling check succeeded; it does not teleport an animal, fetch an item,
launch an attack, clear fear or award training. The author uses the check and
margin to resolve the creature's behavior within the game. Executable behavior
responses and daily training consequences remain separate unfinished work; these
check receipts are not counted as complete creature behavior implementation.

`test_animal_handling` and `test_animal_handling_modifiers` author contextual
modifiers, failed checks, preview, interruption rollback, undo, replay, request
binding, participant availability and rejection of unsupported performance.
Fixtures remain unrun. Source: `full-2008`, B175.

## Animal-act performance checks

`RpgExpandedAnimalPerformance` attaches the required entertainment check to a
completed task-mode handling receipt. Set `handling`, the handler's `performance`
skill, approval, availability and evidence. An optional authored `modifier` is
combined with the shared skill context. A calming receipt cannot substitute for a
trained task. The handling check need not have succeeded: both results are kept
separately for the author to interpret.

After `assess()`, execute `apply()` within an action transaction. It rolls the
separate performance check and binds one receipt to `handling.performanceReceipt`.
The act's elapsed time was already accounted by the handling request, so this
check adds no time charge. A second receipt for the same act rejects; replay of
the original receipt returns its recorded result without another roll. Changing
the performer indirectly by retargeting the handling receipt also rejects.

Results expose `handlingCheck` and the distinct performance `check`, with
`succeeded` referring only to performance. `authorResolutionRequired` remains
true. The API does not infer applause, payment, persuasion, animal obedience or
another social consequence. Those outcomes remain authored; no generic callback
is being counted as their implementation.

`test_animal_performance` authors success/failure combinations, preview, rollback,
undo, replay, unavailable acts, duplicate checks, retargeting and unchanged elapsed
time. Fixtures remain unrun. Sources: `full-2008`, B175 and B212–B213.

## Owned training attendance

Create `RpgExpandedAnimalCourse` with an approved training `plan`, then create
separate `RpgExpandedAnimalTrainingSession` receipts for the two daily sessions.
Each session needs an ID unique within its course, approval, uninterrupted access
and evidence. The course binds the plan, participants, specialty, target and
animal intelligence at the first committed session. Retargeting that plan rejects.

A session charges 7,200 seconds through the shared time ledger, rechecks the plan
and both participants, and records attendance on the course and animal. It grants
no learned behavior or successful training day. `successfulDays` remains zero
until a successful daily check awards progress. Sessions do not
roll and therefore preserve random state.

A session may end exactly at midnight but cannot straddle a day boundary. The
animal cannot attend a different course on the same day. One isolated session on
a previous day does not count as the first half of a later training day. This
implementation uses the shared clock's whole-day boundaries to represent the
source's daily schedule. Multiple animals can be trained sequentially; no parallel
time is silently credited to a trainer.

After the second session, `dailyCheckRequired` is true, `course.pendingDay` records
that day, and `animal.pendingAnimalTrainingCourse` identifies the course. Further
sessions reject until the daily check is resolved. Do not clear these fields to
simulate success: use the owned daily check below. Bad-failure attacks remain unimplemented; learned milestones require the verified
completion receipt below. Attendance alone is not a training course.

`test_animal_sessions` and `test_animal_session_persistence` author two-session
accounting, competing-course rejection, midnight rejection, pending-check gating,
preview, interruption rollback, undo, replay, binding and cross-process
continuation. Fixtures remain unrun. Source: `full-2008`, B458–B459; daily check
requirement: B175.

## Daily training checks and failed days

After two sessions, create `RpgExpandedAnimalTrainingCheck` with its `course`,
approval and evidence. The check uses the trainer's shared handling skill context,
the plan's wild-animal penalty and an optional sourced `speciesModifier`. It
requires both attendance receipts and available participants before randomness.
No further time is charged for the already-accounted training day.

A successful check adds exactly one to `successfulDays` and clears the pending
day. A failed check adds none and sets `course.pendingFailure` to its owned
receipt. Replaying the check never awards a second day. Another check cannot
reroll the same day. Reaching `requiredDays` blocks further attendance pending the
learned-milestone receipt below; points and behavior are not awarded by this counter.

B175 says a badly failed training roll provokes an attack but does not give a
numerical threshold here. `RpgExpandedAnimalTrainingFailure` therefore requires
an explicit `classification`, approval and evidence from the author, instead of
inventing a margin cutoff. `ordinary` closes the failed day with no learning.
`attack` currently rejects with `animal-training-attack-execution-unavailable`,
leaving the course unresolved until the required attack can be executed. Do not
classify a bad failure as ordinary merely to bypass that missing procedure.

Failure classification is an explicit adjudication record, not a callback. It
binds the failed check and author evidence, supports undo/replay, and cannot clear
another course's pending day. Historical `failureAdjudicationRequired` describes
the check's original outcome; inspect `failureResolution` and `pendingFailure`
for its current resolution state.

`test_animal_daily` and `test_animal_daily_failure` author required attendance,
preview, rollback, credit-once, no duplicate time charge, unavailable participants,
retargeting, failed-day holds, ordinary classification, unsupported attacks, undo
and replay. Fixtures remain unrun. Sources: `full-2008`, B175 and B458–B459.

## Learned training milestones

After the required successful days, create `RpgExpandedAnimalTrainingMilestone`
with the `course`, approval and evidence. Assessment verifies the bound plan,
exact successful-day total, unique daily-check dates and resolution of failed
days. Pending sessions or failures prevent completion. Changing a counter without
matching check receipts rejects before training metadata changes.

`apply()` records one milestone on both the course and animal. General courses
set `animalTrainingLevel`; single-trick courses append only their neutral trick ID
to `animalKnownTricks`. Learning one trick never grants its corresponding general
level. No skill points, attributes, inventory or additional time are changed.
Training plans reject already-known objectives. Existing trained creatures may
have their initial level/tricks authored separately; this does not fabricate a
course history.

Replay returns the historical milestone without regranting training or restoring
metadata subsequently changed by authored play. Authors can inspect the level and
trick list when confirming a handling task's `trainingEstablished` fact. Actual
recall, tolerance, warning and combat behavior remain authored and are not claimed
as implemented by these metadata fields. Training-attack execution remains pending.

`test_animal_milestones` authors an entire two-day general course and fourteen-day
single-trick course using attendance and daily checks, then verifies distinct
awards, preview, rollback, inflated-counter rejection, approval, binding, undo and
replay. Fixtures remain unrun. Sources: `full-2008`, B175 and B458–B459.

## Requiring learned training for a task

Attach an approved `RpgExpandedAnimalTask` as a handling attempt's
`taskDefinition`; its ID must match `taskId`. For `kind = 'general'`, set
`requiredLevel` from two through five according to the source training level and
species-appropriate behavior. For `kind = 'trick'`, use the learned trick ID and
set `requiredLevel = nil`. The author supplies approval and evidence for why this
task fits that training; the library does not infer a creature's possible behavior
from an arbitrary identifier.

The task definition checks `animalTrainingLevel` or `animalKnownTricks` before
time or randomness. A provided definition takes precedence over the older
`trainingEstablished` author assertion, so that assertion cannot bypass a failed
metadata requirement. Existing authored creatures may continue to use the explicit
assertion when no task definition is supplied. Calming requests reject task
definitions because calming is a separate operation.

The handling receipt binds the task contract as well as its ID. Retargeting its
required level, trick or evidence after a committed attempt rejects; replay does
not perform another task check. Passing eligibility permits the handling roll and
still does not force obedience or execute a behavior.

`test_learned_animal_tasks` authors complete general and trick courses, verifies
that attendance alone cannot enable the task, records the milestone, then checks
eligibility, preview, execution, undo, task-contract binding and replay. Fixtures
remain unrun. Sources: `full-2008`, B175 and B458–B459.

## Animal and mount valuation

These pure assessments return `RpgExpandedAnimalValue` with an exact reduced
`numerator` and `denominator`. `money` is set only for a whole currency value.
They spend no money, transfer no animal and never round a fractional price.
Integer representation overflow rejects explicitly.

- `rpgExpandedDomesticAnimalValue(baseValue, intelligence, trainingLevel)` applies
  the ordinary domestic training categories. Zero denotes untrained. Intelligence
  two gains no premium; higher untrained animals use two-thirds base value;
  level-three training retains base value; full level four uses one-and-a-half
  times base; full level five uses twice base.
- `rpgExpandedEnhancedAnimalValue(baseValue, intelligence, speciesIntelligence,
  trainingLevel)` requires full training and an intelligence increase of one or
  two. It uses four or ten times the species base price directly, consistent with
  the printed example. Do not feed it a price already increased for ordinary full
  training. Other intelligence differences reject as unsupported.
- `rpgExpandedMountMoveValue(baseValue, basicMoveIncrease)` handles the stated
  zero, one or two-point Basic Move increase, with multipliers one, two and four.
  Enhanced Move's speed multiplier is not a Basic Move increase.
- `rpgExpandedWarTrainingValue(baseValue, priceIncludesWarTraining)` applies the
  initial doubling only when absent from the supplied price. A printed war-mount
  price already includes this training and must not be doubled again.

These are separate source adjustments, not a universal market-price calculator.
Wild-animal value, strength-based price adjustments, additional war-training
premiums, combinations requiring an authored baseline, and committed animal
purchases remain pending. The author must identify the correct baseline before
applying any helper.

`test_animal_values` authors training categories, the exceptional-intelligence
multipliers, Move premiums, already-included war training, fractional prices,
zero prices and unsupported qualification cases. Fixtures remain unrun.
Source: `full-2008`, B459.
## Natural attack damage

`rpgExpandedNaturalDamage(thrustDice, thrustAdds, kind, anatomy, weakBite,
horizontal, dexterity, brawlingScore)` assesses the natural-attack formulas in
`full-2008`, B460. Supply **unmodified thrust** for the animal's current strength.
Do not supply an encounter's already adjusted bite or kick: that would count
anatomy and skill twice. A missing brawling score is `nil`.

Supported combinations:

| Kind | Anatomy values |
| --- | --- |
| `bite` | `ordinary`, `sharp-teeth`, `fangs` |
| `claw` | `ordinary`, `blunt-claws`, `sharp-claws` |
| `kick` | `ordinary`, `blunt-claws`, `sharp-claws`, `hooves` |
| `striker` | `cr`, `cut`, `imp`, as established by the actual trait |

Use `weakBite` only for bites and `horizontal` only for kicks. Horizontal
posture reduces kicking damage when the limb lacks claws; it cancels the hoof
bonus. Brawling at dexterity plus two contributes one point per die to every
supported attack. Invalid anatomy combinations are rejected.

The `RpgExpandedNaturalDamage` result contains `dice`, `adds`, `damageType`,
`anatomyBonus` and `skillBonus`. For example, raw thrust `2d-1`, horizontal
hooves and no qualifying brawling produce `2d-1` crushing; qualifying brawling
changes this to `2d+1`. The function makes no rolls and changes no ledger.
Negative adds remain intact until basic damage is rolled and its minimum is
applied by the damage resolver.

This assessment does not establish attack legality, choose a target, roll an
attack or apply an injury. Creature catalogue wiring and combat dispatch remain pending. The authored
`test_animal_natural_damage` fixture covers the formula branches and the skill
threshold; it remains unrun while checks are paused.


### Strength-based natural attacks

`rpgExpandedNaturalDamageForStrength(strength, kind, anatomy, weakBite,
horizontal, dexterity, brawlingScore)` obtains raw thrust from the shared
`rpgExpandedDamageDice` lookup in the expanded foundation, then applies the same
natural-attack assessment. The creature module does not require equipment.
Existing equipment users retain the same function name and results.

The lookup supports strength 1–40, the printed five-point rows through 100,
and the specified full-ten-point progression above 100, bounded at 1000.
Unprinted intermediate rows from 41 through 99 are rejected; no interpolation
is inferred. The natural-attack assessor retains its 100-die bound, so a table
result beyond that limit is rejected before any random roll or ledger change.
A stronger animal does not silently fall back to the Lite table.

For example, strength 45 gives raw thrust `5d`; a crushing striker with no
qualifying brawling produces `5d+5`. Strength 24 gives `2d+1`; horizontal hooves
cancel their per-die anatomy modifiers, and qualifying brawling adds two,
producing `2d+3`. The fixture `test_animal_strength_damage` exercises these and
other printed rows in the minimal creature build. It is authored but unrun.

## Swarm exposure protection

`RpgExpandedSwarmExposure` records a contact interval for one `swarm` identity
and one expanded `victim` profile. Set `tiny` for insect-sized attackers,
`protection` to `none`, `clothing`, `low-tech-armor`, `normal-armor` or `special`,
and supply `approved` and `evidence` describing the actual covering and swarm.
Set `armorDR` only for an armour category. For special protection the author
must establish whether this covering protects against this particular swarm,
then set `specialEffective` accordingly. Special protection is not universal.

Call `assess()` for a pure preview and `begin()` inside an action transaction
when contact starts. The owned record is stored in `victim.swarmExposures`.
`begin()` on an existing record preserves its start; a second record for the
same swarm and victim is blocked. Changing its definition after contact is
rejected. Undo and save use the engine's ordinary object state mechanisms.

Results contain elapsed whole seconds, `immune` and effective `dr`. Tiny
creatures are excluded by ordinary clothing while elapsed time is below two
seconds, and by low-tech armour while it is below five seconds. At the exact
boundary protection expires. Larger creatures use armour's normal DR without
an ingress deadline. Tiny creatures with unclassified normal armour return
`swarm-tiny-armor-classification-required`; identify the actual protection
category instead of treating all armour as sealed.

The record does not advance time or consume randomness. The combat scheduler
owns elapsed time. This record implements the B461 protection interval only. The attack interface
below applies damage separately. It does not reset protection after leaving contact,
change clothing during contact or resolve a new encounter with a reused swarm
identity. Those operations remain pending. `test_swarm_protection` covers the
exact boundaries, repeated start, preview and exception rollback; it is unrun.

## Automatic swarm contact attacks

Include the health module to commit injury. `RpgExpandedSwarm` owns the contact
attack history; its `kind` selects `stinging-insects`, `flying-biters` or
`ground-biters`. These neutral identifiers select the B461 sample damage
procedures. Movement, population and map occupancy are not yet implemented by this class.
The counterattack interface below supplies owned injury and dispersal. An author may mark a swarm `dispersed`; attacks then
block.

Give each `RpgExpandedSwarmAttack` a unique `id`, a started `exposure`,
`inContact`, `approved` and `evidence` establishing actual contact. The exposure
must identify the same typed swarm and an expanded victim. Stinging insects
require a tiny exposure and an authored whole-yard `distanceFromNest`; at 50
yards or more pursuit ends. The two biting kinds require a non-tiny exposure.
Use `dropDestination` when potential knockdown requires dropping held objects.

`assess()` preflights every possible injury through the victim's
`prepareSwarmWound` hook. The health module implements this hook with the shared
owned wound record. Missing health support or unsupported anatomy blocks before
randomness. `apply()` must run inside an action transaction. It makes no attack
or defense check: biting swarms roll one die of cutting damage, subtract the
exposure's DR and apply the cutting wound multiplier; stinging insects inflict
one injury directly. Complete immunity prevents both damage and its roll.
Health checks required by injury still use the ordinary health procedure.

The receipt retains damage, injury and the owned wound. Replaying it never
applies injury again. There is at most one attack per victim per ledger second.
Without `mapped`, a swarm may attack only one victim that second; changing its
victim also requires `victimChangeReason`. With `mapped`, the author must verify
that every victim occupies the swarm's hex. The attack does not spend a second:
the encounter scheduler advances the shared clock once for the combat interval.
No scheduler or tactical occupancy verification is implied by these flags.

The combined fixture `expanded-swarms.t` and `test_swarm_attacks` cover direct
sting injury, cutting damage, immunity, pursuit distance, duplicate intervals,
receipt replay, exception rollback and undo. They remain unrun. Weapon attacks
against the swarm, target relocation, exposure renewal and
cross-process attack continuation remain unfinished.

## Swarm counterattacks and dispersal

`RpgExpandedSwarmCounterattack` executes the B461 supplemental `shield` or
`stomp` action. Set its unique `id`, `swarm`, expanded `actor`, `kind`,
`approved`, `inReach` and `evidence`. A shield attack requires an owned, ready,
usable shield item with a defense bonus and a flying swarm. Stomping requires
a ground swarm, no shield field, and author-confirmed `ableToStomp` based on the
actor's body and posture. Neither action rolls an attack, defense or damage.

A shield strike adds two injury; a stomp adds one. The swarm's owned injury
ledger disperses stinging insects at twelve, flying biters at eight and ground
biters at six. Dispersed swarms cannot make further contact attacks or receive
these counterattacks. Receipts are retained by both swarm and actor. Replaying
a receipt does not add injury; each actor has at most one supplemental
counterattack per ledger second, even when changing swarms. The operation does
not advance time. These special actions leave the ordinary weapon attack slot
available, but integration with the weapon action budget remains pending.

`rpgExpandedDiffuseInjury(normalInjury, damageType, areaEffect)` applies the B380
cap to an already calculated ordinary injury: impaling and all piercing sizes
cap at one, other supported types at two. Set `areaEffect` only for a verified
area, cone or explosion attack, which bypasses this cap. This pure function
does not calculate penetration, consume ammunition or commit a weapon hit.
Direct weapon attacks against swarms still require that integration.

`test_swarm_counterattacks` specifies exact injury thresholds, repeated-receipt
behavior, per-second limits, invalid flying stomps, pure assessment, rollback,
undo and diffuse caps. The fixture is authored and unrun while checks are paused.
