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

Include `vhyl-rpg-expanded-creatures.t` after the expanded foundation. It provides training assessments and owned task/calming checks; it does not yet execute training days or creature combat. The convenience umbrella includes it without activating any rules.

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
behavior or changes character points. Owned attendance and daily checks are described below. Attack execution and
learned milestones remain pending. A plan
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
simulate success: use the owned daily check below. Bad-failure attacks and learned
milestones remain unimplemented. Attendance alone is not a training course.

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
still-unimplemented learned-milestone procedure; points and behavior are not
awarded by this counter.

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
