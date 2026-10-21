# Fear and mental-state completion audit

**Not complete. Build checks are paused; the current fixtures are unrun.**
This page separates the fear subsystem's acceptance criteria from the wider
expanded-library conversion. It does not waive either set of requirements or
turn unsupported combinations into completed features.

## Responsibilities and evidence

| Requirement | Current implementation evidence | Outstanding acceptance work |
|---|---|---|
| Initial fear checks and consequence selection | `RpgExpandedFearEvent`; `test_fear_event`, `test_fear_low_score` | Run source-value, replay and lifecycle cases; audit all context modifiers. Below-three scores use a recorded author-selected outcome. |
| Every consequence row and compound outcome | Owned health handlers and typed acquisitions; individual `fear-outcome-*` entries in the source inventory | Audit each row's dispatch and component preflight. Minimum-attribute boundaries use explicit replacement contracts; unsupported acquisitions remain visible blockers. |
| Phobias | Owned exposures, repeated checks, awareness pauses, overlap policy, learning/activity restrictions and worsening | Validate deadlines, simultaneous exposures, restriction removal and compound outcomes. |
| Fear auras | Victim/source/purchase histories; `test_fear_aura` | Validate both time boundaries, sensory eligibility and reused scene contexts. Context-object identity must not reset prior exposure or successful-check protection. |
| Stress follow-ups | Postbattle events and owned phantom-voice occurrences | Validate failed/exact-success trigger distinctions, prohibited-roll rulings and absence of duplicate follow-ups. |
| Recovery and incapacity | Owned faint, coma, catatonia, seizure and recovery requests | Validate independent causes, concurrent aftereffects, care policies and low-score recovery decisions. |
| Lasting changes and aging | Typed mental/physical acquisitions, compounds and `RpgExpandedFearAgingRuling` | Validate exact costs, immutable receipts, advancement accounting and each supported effect. Remaining requested trait selections still require concrete behavior or specific author contracts. |
| Social effects | Existing typed reaction contexts for acquired traits | Audit each eligible mental selection against its reaction adapter and ordinary social entry points. |
| Panic actions | Owned reaction loop, world movement, falls, tactical paths, attacks and artifact operations | Validate actual world/resource effects, interrupted routes, independent incapacity, survivor checks and one time ledger. Unsupported action combinations must reject before spending. |
| Player interfaces | Shared fear action and Echo Vault example; `test_fear_actions` | Run parser, structured-action and dialogue parity and playable continuation. |
| Persistence and compatibility | Authored rollback, undo and separate-process save cases | Execute the relevant source/native/dependency/documentation/package checks after implementation is complete; verify unchanged abridged behavior. |

The detailed [fear inventory](inventory/senses-influence-fear.json) remains the
row-level source checklist. Tests named here are specifications until executed,
not evidence of passing behavior. An implemented class or a registered fixture
alone does not establish completion.

## Combat boundary

Fear selects and owns a panic reaction. If that reaction performs an attack,
the combat adapter owns legality, attack resolution and equipment consequences;
health owns the resulting injury. All share the existing action transaction and
time ledger. A rejected attack must leave the fear reaction, resources and
randomness unchanged so the author can supply a supported concrete reaction.

Recorded attack adapters already accept explicit external scores, dice and injury
with retained evidence. They are author-adjudication contracts, not a claim of
complete automatic combat. Existing supported critical and tactical integrations
remain part of the repository and require validation.

Completing every general critical-hit table, every creature/vehicle attack and
every artifact rule is part of the wider conversion. Those tasks must not replace
the direct fear audit above. Conversely, a missing combat effect that prevents a
required panic scenario from resolving remains an integration gap and must be
fixed or covered by a specific, tested author contract. A generic callback or a
silent abridged approximation is insufficient.

## Focus check

Before each implementation increment, identify the fear/mental-state requirement
it closes and the scenario or source entry that demonstrates the gap. After the
increment, record what changed and what evidence is still missing. General combat
work without a demonstrated fear-integration need stays on the wider conversion
backlog. Repeat this check when new dependencies or scope questions arise.

## Next completion work

1. Audit the retained fear row inventory against actual dispatch, including
   author decisions, compound effects and minimum-attribute boundaries.
2. Close remaining mental-selection, reaction and incapacity integration gaps.
3. Exercise the required panic scenarios through their concrete action adapters;
   keep broader combat catalogue work separately identified.
4. Once implementation is complete, resume validation, repair failures, update
   this audit with observed results and push the final state to the existing PR.

No completion claim or release follows from this audit alone.

## Recovery ownership audit

Source inspection found that fear-stun completion releases its owned mental-stun
flag and episode pointer, leaving physical stun and unconsciousness unchanged.
The ordinary stun-recovery entry point defers to an active owned fear episode.
Checked recovery rejects an unconscious patient before time or dice are spent;
fixed-duration rows still expire without curing the independent incapacity.

`test_fear_quirk_stun` now specifies those overlapping conditions, recovery
rollback, undo and timed expiry. These cases are **unrun**, and this source audit
is not runtime verification. No additional independent mental-stun producer was
found in the current libraries; authors directly overwriting the shared flag do
not create a separately owned condition.

The timed panic executor has a different recovery contract from fear stun:
its scheduled checks continue during independent unconsciousness, resolving only
the panic episode. `test_fear_panic` now specifies failed-check scheduling,
success without waking or clearing physical stun, replay, undo and continuation
in a new process. The health guide's obsolete claim that this combination blocks
recovery has been removed. These additional cases remain unrun.

## Timed-panic movement increment

Row 21 now has a concrete world movement activity and an owned active-action
health gate. It relocates the actor, retains failed health attempts, checks Move
and the recovery deadline, and rejects active-combat/tactical routes. The existing
crying fixture now specifies its lifecycle. Tactical row-21 routing now uses `RpgExpandedTimedPanicPath`, with an owned
Move maneuver and health gate. Its registered fixture specifies actual hex
movement, shared-round timing and failed exertion. Stationary pointless
expression now has a mode-specific author contract with physical/speech gates,
observable portrayal events and no task benefits; row-33 tactical routes remain
separate. These implementations still require validation.
No builds or tests have run for this increment.

## Stress terminology

There is no implemented general accumulating stress/sanity track: no persistent
stress balance, accumulation schedule, threshold progression or stress-recovery
ledger. References to stress in the current fear implementation mean specific
postbattle or phantom-voice triggers and their owned follow-up events. They must
not be presented as evidence that a general track exists. Such a track needs an
identified source procedure or an explicitly selected campaign design; no point
values, thresholds or recovery rates are invented by this conversion.

## Acquired speech-loss integration

The stationary panic-expression adapter now distinguishes vocal sound from
articulated speech, matching full-2008 B125. Its new communication fixture starts
with a row-24 physical acquisition: loss of articulated speech still permits
noncommunicative vocal panic, while total muteness rejects it without a time or
randomness charge. Nonvocal gestures remain available subject to other health
restrictions. This closes an integration gap in an already supported physical
selection; it does not complete the remaining trait catalogue. Fixtures are unrun.

## Fixed mental-trait fallback increment

Row 25 now recognizes four additional already-implemented fixed mental traits
as the related prior condition: emotional-understanding deficit, emotional
obliviousness, callousness and learning bar. Their specific existing behavior
remains active while the author-selected ten-point fallback is acquired once.
The selection fixture includes their costs, skill/learning effects and accounting
across replay, rollback, undo and save continuation. These cases remain unrun;
this is not a claim that the entire mental-trait catalogue is implemented.

## Susceptibility selections

Physical fear selections now accept motion and free-fall susceptibility, reusing
the existing trait and hazard mechanics. Acquisition preflights incompatible
prior training and retains the free-fall campaign restriction; it cannot erase
training or grant point refunds. The selection fixture specifies both new
purchases and their learning effects. Lifecycle and composed hazard validation
remain unrun, and other catalogue selections remain outstanding.

## Activity-history integrity

The timed-panic episode now validates its activity histories, not only recovery
checks. Non-recursive receipt validation covers crying, world movement,
expression and tactical movement. Recorded count, unique ownership and interval
ordering guard the episode history; retained definitions, outcomes and health
permissions are checked before later clock advancement or action permission.
Mutation cases are added to the existing fixtures and remain unrun.

## Overriding-goal selection

A new B146 overriding-goal trait is selectable at exact fear-row costs. Its
specific author interface classifies concrete actions, resolves wise deviation,
retains pursuit obligations and records goal fulfillment through replacement or
funded buyoff. Goal versions prevent old obligations from reactivating through
reused wording. Registered fixtures cover pricing, a denied world action,
replacement, accounting, undo and save continuation; they remain unrun. Configured goal templates now create independent purchases while preserving
authored term, goal and rating. Copy, isolation and actual self-control roll
cases are registered but unrun. The remaining mental catalogue still requires
work. This increment adds actual selection behavior rather than only a price.


## Impulsive-action selection

The B139 impulsive-action trait now has an owned decision interface. Authors
classify concrete immediate and deliberative alternatives; failed self-control
blocks deliberation, and the completed choice is retained without a second time
charge or roll. Exact ten- and fifteen-point fear acquisitions are supported.
The fixture includes actual scene effects, acquisition accounting and lifecycle
cases, but remains unrun. This closes another implementation selection gap;
remaining catalogue work and full validation still prevent a completion claim.


## Extreme-panic receipt boundaries

The row-33 episode and reaction now reject retained definition lists with altered
lengths, and reaction receipts bind the result status as well as the recovery
check and timing. `test_extreme_panic` specifies these mutations during an active
reaction chain and after restored continuation has completed it. Rejection must
roll back the mutation without changing severity, clock or random consumption.
These cases remain unrun; this closes a receipt-integrity gap, not the remaining
catalogue or execution-validation work.


## Room-flight incapacity boundary

Row-33 room flight now consults the shared voluntary-movement restriction before
spending time and again before relocation. A conscious, balanced but paralyzed
character cannot bypass incapacity merely because posture and fatigue permit
movement. The existing flight fixture specifies denied preview/execution with
unchanged position, severity, clock and dice, including saved continuation.
These cases are authored and unrun. Tactical movement continues to use its own
owned maneuver health gate; this change addresses the direct room-route gap.


## Destructive-action health permission

The object-destruction panic adapter now requires an owned physical action gate.
Known incapacity blocks before spending; a failed committed exertion or
consciousness check retains the timed attempt but creates no object wound. The
survivor check still follows. Direct calls cannot bypass the reaction's time
ownership. Existing computer-destruction fixtures inherit the same permission.
The object fixture adds paralysis, direct-call rejection, failed consciousness,
rollback, undo and saved continuation. These cases remain unrun; broader artifact
rules and remaining catalogue selections are still outstanding.


## Tactical panic execution ownership

Panic attack and path operations now require their owning reaction to be settling
before they can execute. The shared panic health gate enforces the same boundary,
including calls through a battle maneuver. Preview remains available outside
execution. Direct gate, operation and battle calls are specified to leave injury,
ammunition, position, turn order, clock, dice and reaction history unchanged.
The attack/path fixtures include these cases and remain unrun; normal reaction
execution retains the existing rollback, undo and continuation specifications.


## Volatile-temper selection

A typed B124 volatile-temper selection now owns the stressful occurrence, specific
stressor, self-control result and completed hostile or restrained scene action.
Exact ten- and fifteen-point fear selections and rated template copies are
supported. Failed stressful checks retain the existing phantom-voice follow-up.
The separate uncontrolled-rage interaction remains explicitly blocked pending
its own behavior; the catalogue is therefore still incomplete. Registered
pricing, action, stress and lifecycle fixtures are unrun.


## Rage-entry injury prerequisite

The next missing anger interaction requires whole-second injury aggregation.
`RpgExpandedRageInjuryWindow` now assesses actual recorded health loss in the
current second, using a strict greater-than-quarter-capacity threshold. Missing
injury ledger coverage blocks rather than silently losing hits. Registered
boundary and lifecycle fixtures remain unrun. This assessment does not activate
rage: entry and observation ownership, voluntary entry, combat restrictions,
injury overrides and exit checks remain the next implementation obligations.


The rage injury prerequisite now includes a retained qualifying snapshot, unique
per profile/second. Later hits cannot produce a second receipt for that second,
and replay retains the original contributing wounds after time advances.
Mutation, rollback, undo and save cases are registered but unrun. No immunity
switches or incomplete rage activation were introduced; entry must still consume
the receipt atomically with a complete episode, combat policy and exit procedure.


The ranged-choice prerequisite now assesses actual owned weapon ammunition and
rate of fire, the strict beyond-twenty-yards exception, the aim prohibition and
recorded quick-draw reload eligibility. Its boundary fixtures are unrun. It does
not execute a combat turn or activate rage; melee/closing choices, injury rules
and exit procedures remain outstanding. This assessment alone is not evidence
of completed frenzy behavior.


The hand-weapon/approach assessment now requires an all-out attack in reach and
an explicitly feasible closest approach otherwise, preferring a moving attack
or slam when possible. Actual weapon ownership/readiness and current Move bound
the choice. Boundary fixtures are registered and unrun. These assessments still
need the owned rage episode and actual turn adapter; they do not themselves
apply attacks, defense restrictions, injury immunity or recovery checks.


## Combined knockdown policy boundary

Source review of B124 and B420 found an unresolved interaction between frenzy
stun immunity, the bonus for remaining conscious and the combined
knockdown/stun/unconsciousness roll. A recorded-author-policy versus explicit
blocking decision has been requested; no answer is assumed. Independent work
extracted the existing combined procedure into default-preserving profile hooks
so an eventual policy can share the wound ledger. No frenzy benefit is enabled.
Default success/failure and persistence fixtures are registered but unrun.


## Nightmare waking selection

Nightmares now have a typed rated purchase and concrete morning-waking event.
Failure charges one sleep-restricted fatigue point through the common ledger;
raw 17/18 also applies the day-long skill/Perception penalty. Authored day
boundaries, duplicate checks, overflow injury and immutable receipts are handled
explicitly. The ten-point rated purchase is selectable by fear. Registered
recovery, expiry and lifecycle cases remain unrun. The separate playable-dream
campaign procedure is still pending, as are the other remaining trait and frenzy
obligations. The frenzy knockdown-policy question is still unanswered.


Nightmare compound coverage now includes row-27 acquisition during fainting,
blocked waking while unconscious, recovery without an automatic nightmare check,
and the later explicitly recorded morning after sleep. The fixture retains
character accounting and tests repeated compound/waking execution, rollback,
undo and saved continuation. These are authored expectations, not observed passes.


## Overconfidence selection and reactions

The B148 overconfidence selection now retains self-control and explicit confident
versus cautious scene actions. Its exact ten-point rated purchase is eligible
for fear acquisition. Participant-specific social records apply +2 for a
classified young/naive observer or -2 for an experienced observer through the
ordinary owned reaction procedure, with duplicate-effect prevention. No actual
skill or attribute increase is granted. Action and social lifecycle fixtures are
registered but unrun. This adds a concrete selection and reaction adapter; the
other catalogue and frenzy obligations remain incomplete.


## Choice restrictions and mitigation

Impulsive-action, volatile-temper and overconfidence now release unfinished
choice restrictions while the current purchase is inactive, mitigated or absent.
Reactivation without completion restores the retained restriction without a new
roll. Completed choices remain immutable receipts. Shared regression cases cover
all three fixtures, including actual scene execution and undo; they remain unrun.


## Solitude selection and reaction direction

The B142 solitude selection now reuses the owned hostile-response procedure for
explicit unwanted proximity. Its separate NPC reaction context applies the
rating-dependent penalty from the reacting observer, even when both participants
own the trait; it does not penalize others' reactions to the subject. Exact
fear-cost acquisition, action, mitigation, invalid facts and social lifecycle
fixtures are registered but unrun. Frenzy and other catalogue entries remain
unfinished; the status-sensitivity increment is described below.


## Status sensitivity and completed outbursts

The full-2008 B153 selection now has a typed rated purchase and an owned
clear-slight response trigger. The NPC-side reaction context applies the owner's
rating penalty and composes the independent solitude modifier. The opposite
reaction direction uses a recorded observation of an actual completed hostile
response after failed control; its conditional -3 requires author confirmation.
Registered fixtures cover those directions, composition, action execution,
mitigation, pricing, rollback, undo and saved continuation. They remain unrun.
This increment does not complete frenzy, the full remaining trait catalogue or
a general accumulating stress/sanity track.


## Self-sacrifice selection

The full-2008 B153 self-sacrifice purchase now supports rated templates and exact
fear acquisition. Its owned conflict trigger binds the other person, competing
needs and classified scene actions. Failed control restricts the choice to
other-first actions; successful control also permits self-first actions.
Completion records actual authored execution in the same transaction, with no
implicit resource transfer. Lifecycle and mitigation fixtures are registered
but unrun. Remaining traits and frenzy still prevent an overall completion claim.


## Replacement execution at minimum attributes

The consequence boundary audit confirmed that row 31 at minimum HT or a
prohibited HT-check score, and row 40 at minimum IQ, expose explicit replacement
reasons. The existing adjudication fixture previously stopped after replacing
the selected row. It now also specifies committing a fixed-duration stun,
retaining the original event, expiring the replacement, preserving the original
attributes, avoiding invented rolls, rollback, undo and cross-process save
continuation. The inventory now links this contract and no longer describes the
minimum-HT case as having no replacement route. These cases remain unrun; direct
zero-attribute transitions are still outside the implemented procedure.


## Intrusive replay episode implementation

The B136 stress-triggered replay gap now has a typed purchase, retained onset
roll and source durations, immutable authored content, timed skill penalties and
the severe skill-use prohibition. Its direct occurrence fixtures specify onset,
expiry, rollback, undo and save continuation but remain unrun. Automatic fear dispatch, overlapping episodes and complete sensory blocking still
require implementation. Owned self-control dispatch is described below; the
unintegrated fear and direct-control routes still reject explicitly. The purchase is deliberately not yet accepted as a fear
selection. This is an implementation increment, not completion of this trait.


## Intrusive replay after failed self-control

Owned self-control now preflights authored episode content and resolves a replay
check after an actual failed stress-related roll. It preserves the independent
phantom-voice follow-up, ordered before replay, and retains both receipts.
Exact success, unrelated checks, giving in and funded success do not fabricate
failed-roll triggers. New fixtures specify roll counts, atomic rollback, undo,
missing-content rejection and saved replay. They remain unrun. Automatic fear
dispatch, episode overlap and full sensory incapacity are the next integration
gaps for this trait.


## Intrusive replay after fear

Owned fear events now retain a replay follow-up independently of phantom voices.
The context binds authored episode content before the initial roll; ordinary
failure or exact success resolves the follow-up once. Below score three an
explicit `replayStress` ruling chooses `check` or `none`, separately from the
voice ruling. Fixtures specify roll order/counts, omitted-content rejection,
rollback, undo and save continuation, but remain unrun. Concurrent episodes and
complete sensory incapacity remain outstanding before this trait can become an
accepted fear acquisition.


## Intrusive replay sensory boundary

Severe replay episodes now gate shared sensory and Perception checks, explicitly
external custom checks, fear-aura perception and new external fear events.
`externalInputReason()` gives authors a concrete disclosure gate for narration
outside checks; internal recollection remains distinct from new sensory input.
Committed fear consequences remain valid when their follow-up creates sensory
incapacity. Registered cases specify no-dice denial, classification bypass
rejection, expiry and persistence, but are unrun. Episode overlap remains the
next unresolved integration before enabling fear acquisition.
