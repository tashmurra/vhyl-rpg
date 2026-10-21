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
