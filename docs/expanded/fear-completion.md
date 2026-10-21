# Fear and mental-state completion checklist

**Not complete. Checks are paused during implementation. No passing validation is claimed.**

This is the authoritative checklist for the approved fear milestone, frozen at
`c2ba9d0`. The wider expansion conversion remains separate and PR #4 remains draft.
The previous chronological log is replaced by requirements and evidence below.
Historical implementation details remain available in Git history and module guides.

## Scope and focus gate

Before each increment, name one requirement ID below and its missing acceptance
scenario. Record the resulting implementation/fixture evidence against that ID.
Do not start another subsystem to close a dependency: make the minimum direct
integration or provide a concrete, tested author contract. A callback alone is
not an implemented effect. No additional mental catalogue entries enter this
milestone beyond the frozen roster, short attention and frenzy.

Deferred: remaining mental catalogue entries, full combat/critical tables,
general invention/production, vehicles, medicine and the wider conversion.
Existing peripheral adapters remain supported; their entire subsystems are not
completion dependencies. No merge, tag or release is authorized.

## Requirements and current evidence

All test names refer to `tests/expanded.py` unless stated otherwise. “Authored”
means the fixture/assertion exists, not that it compiles or passes. Source review
is not runtime evidence. Rows stay open until their acceptance scope has passed.

| ID | Source / approved rule | Implementation and acceptance scenario | Tests / missing evidence | Observed validation |
| --- | --- | --- | --- | --- |
| F01 | full-2008 B360; B345 ruling | Owned initial fear: modifiers, immunity, cap, outcome selection, no invented below-three dice/margin | `test_fear_event`, `test_fear_context`, `test_fear_low_score`, `test_low_control_fear`; full modifier audit required | Unrun; open |
| F02 | full-2008 B360–B361 | Every outcome has matching owned dispatch and concrete effects; see row matrix | Row fixtures below; verify source expectations and dispatch | Unrun; open |
| F03 | full-2008 B361 | Compound health + trait + IQ effects preflight atomically, reject either invalid component without side effects | `test_fear_compound`, `test_fear_compound_preflight`, `test_fear_mental_compound`; pure preview, rejected/preused acquisition and episode cases authored | Unrun; open |
| F04 | full-2008 B148–B150 | Phobia exposures, awareness, repetition, overlap, activity/learning restrictions and worsening | `test_phobia`, `test_phobia_awareness`, `test_phobia_overlap`, `test_phobia_activity`, `test_phobia_learning`, acquisition/worsening fixtures | Unrun; open |
| F05 | full-2008 B93 | Source/victim aura ownership, perception, one-hour protection and prior exposure boundary | `test_fear_aura`; recheck exact boundary and reused context cases | Unrun; open |
| F06 | full-2008 B136, B148, B156 | Postbattle, voices and intrusive replay preserve trigger distinctions and coexist with original consequences | Fear stress, postbattle, replay-fear and replay-self-control fixtures | Unrun; open |
| F07 | full-2008 B361, B428 | Owned recovery and incapacity: correct deadlines, overlap, rest/care, no clearing independent conditions | Faint, coma, catatonia, seizure, panic, recovery-ruling and overlap fixtures | Unrun; open |
| F08 | full-2008 B361, B444 | Exact acquisition/worsening costs; no spendable point award; aging and minimum-attribute rulings | `test_fear_mental`, `test_fear_aging`, `test_fear_adjudication`, physical and hearing-loss fixtures | Unrun; open |
| F09 | Frozen trait source entries | Actual actor/observer reactions, mitigation and incapacity boundaries for each eligible selection | Per-trait social fixtures; roster audit required | Unrun; open |
| F10 | full-2008 B361 rows 21/33 | Expression, room flight, tactical path, fall, attack and destruction produce actual effects with one time/resource charge | Timed-path, expression, flight, fall, path, attack, defense, object, computer and interruption fixtures | Unrun; open |
| F11 | Baseline whitelist + approved scope | Each frozen selection has acquisition, effects, mitigation, worsening where applicable and replay | Per-trait fixtures; exact roster below | Unrun; open |
| F12 | full-2008 B153 | Short attention fails a concrete owned task; terminal prototype failure retains charges and blocks continuation/delivery; enable acquisition/worsening | Existing attention task/study/repair/concept fixtures. Owned multi-step contract, terminal prototype and acquisition fixtures still missing | Implementation incomplete |
| F13 | full-2008 B124 plus approved knockdown ruling | Complete frenzy entry, legal action/defense policy, injury effects, target changes and exit | Injury-window and action assessments exist. Owned active episode and complete lifecycle fixtures missing | Implementation incomplete |
| S01 | Original campaign stress rules below | Optional policy/state and explicit unique gains; cap, immutable policy and episode reset | New stress module and fixtures required | Not implemented |
| S02 | Original campaign stress rules below | Ascending owned threshold decisions, persistence and voluntary-action gate | New stress decision/gating fixtures required | Not implemented |
| S03 | Original campaign stress rules below | Timed nonstacking strain, ordinary owned fear or recorded coping; no recursive gains | New stress consequence fixtures required | Not implemented |
| S04 | Original campaign stress rules below | Safe-hour recovery, daily cap, interruption, interval ownership and independent aftermath | New stress recovery fixtures required | Not implemented |
| D01 | Approved delivery plan | Neutral docs, catalogue/provenance/API navigation and connected playable fear/stress sequence | Documentation updates and example/interface parity required | Not implemented fully |
| V01 | Approved delivery plan | Pure preview, rejection before costs/dice, replay, rollback, undo, separate-process saves for every requirement | Lifecycle fixtures plus coverage audit | Unrun; open |
| V02 | Approved delivery plan | Minimal/all-module builds, unchanged absent-feature behavior, source/native/docs/packaging checks | Commands and result record below | Paused |

## Frozen mental-selection roster

The following is the exact `rpgExpandedFearMentalFacts` whitelist at `c2ba9d0`.
Add only short attention and frenzy in this milestone. Quirks, fixed beliefs,
phobias and their existing consequence interfaces remain included separately.

| Trait ID | Public type |
| --- | --- |
| `truthfulness` | `RpgExpandedTruthfulness` |
| `curious` | `RpgExpandedCuriosity` |
| `cowardice` | `RpgExpandedDangerAvoidance` |
| `compelled-aid` | `RpgExpandedCompelledAid` |
| `low-motivation` | `RpgExpandedLowMotivation` |
| `postbattle-stress` | `RpgExpandedPostbattleStress` |
| `pleasure-loss` | `RpgExpandedPleasureLoss` |
| `phantom-voices` | `RpgExpandedPhantomVoices` |
| `humorlessness` | `RpgExpandedHumorlessness` |
| `pervasive-distrust` | `RpgExpandedPervasiveDistrust` |
| `social-inhibition` | `RpgExpandedSocialInhibition` |
| `companionship` | `RpgExpandedCompanionship` |
| `overstimulation` | `RpgExpandedOverstimulation` |
| `goal-fixation` | `RpgExpandedGoalFixation` |
| `impulsive-action` | `RpgExpandedImpulsiveAction` |
| `bad-temper` | `RpgExpandedVolatileTemper` |
| `nightmares` | `RpgExpandedNightmares` |
| `overconfidence` | `RpgExpandedOverconfidence` |
| `solitude` | `RpgExpandedSolitude` |
| `status-sensitivity` | `RpgExpandedStatusSensitivity` |
| `self-sacrifice` | `RpgExpandedSelfSacrifice` |
| `intrusive-replay` | `RpgExpandedIntrusiveReplay` |
| `low-confidence` | `RpgExpandedLowConfidence` |
| `incuriosity` | `RpgExpandedIncuriosity` |
| `indecision` | `RpgExpandedIndecision` |
| `credulity` | `RpgExpandedCredulity` |


Frenzy's combined knockdown/consciousness ambiguity now has an approved policy:
require a recorded author-selected ruling, retain actual injury and stun immunity,
and invent no unstated modifier. The previous unanswered-policy blocker is closed;
the implementation is still required.

Short attention must finish via a concrete owned task lifecycle and the minimum
prototype terminal transition. No further general invention/production work is
required. Unsupported authored tasks must use that lifecycle contract or reject
before spending; silently bypassing the trait is not supported integration.

## Fear outcome coverage matrix

References below are existing inventory mappings, retained for verification.
They are not proof of full dispatch, lifecycle or independent-value coverage.
Every row requires assessment, execution, replay and recovery/consequence checks
where applicable; compound rows also require both component rejection paths.

| Table row | Inventory entry | Registered acceptance mappings | Result |
| --- | --- | --- | --- |
| 4-5 | `fear-outcome-4-5` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Unrun; audit open |
| 6-7 | `fear-outcome-6-7` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Unrun; audit open |
| 8-9 | `fear-outcome-8-9` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Unrun; audit open |
| 10 | `fear-outcome-10` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Unrun; audit open |
| 11 | `fear-outcome-11` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Unrun; audit open |
| 12 | `fear-outcome-12` | `test_fear_assessments`, `test_fear_retching`, `test_owned_retching`, `test_retching_persistence`, `test_retching_fatigue`, `test_retching_combat`, `test_retching_meals`, `test_retching_remedy`, `test_remedy_persistence` | Unrun; audit open |
| 13 | `fear-outcome-13` | `test_fear_assessments`, `test_fear_quirks` | Unrun; audit open |
| 14-15 | `fear-outcome-14-15` | `test_fear_assessments`, `test_fear_fatigue`, `test_fear_fatigue_stun`, `test_fear_stun` | Unrun; audit open |
| 16 | `fear-outcome-16` | `test_fear_assessments`, `test_fear_quirk_stun` | Unrun; audit open |
| 17 | `fear-outcome-17` | `test_fear_assessments`, `test_fear_faint` | Unrun; audit open |
| 18 | `fear-outcome-18` | `test_fear_assessments`, `test_fear_faint_injury` | Unrun; audit open |
| 19 | `fear-outcome-19` | `test_fear_assessments`, `test_fear_faint_injury` | Unrun; audit open |
| 20 | `fear-outcome-20` | `test_fear_assessments`, `test_fear_shock_faint` | Unrun; audit open |
| 21 | `fear-outcome-21` | `test_fear_assessments`, `test_fear_panic`, `test_panic_crying`, `test_panic_history`, `test_timed_panic_path`, `test_panic_expression_communication` | Unrun; audit open |
| 22 | `fear-outcome-22` | `test_fear_assessments`, `test_fixed_beliefs` | Unrun; audit open |
| 23 | `fear-outcome-23` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound`, `test_fear_selection`, `test_status_sensitivity`, `test_status_outburst`, `test_self_sacrifice`, `test_acquired_replay_event` | Unrun; audit open |
| 24 | `fear-outcome-24` | `test_fear_assessments`, `test_fear_physical`, `test_fear_aging`, `test_fear_selection` | Unrun; audit open |
| 25 | `fear-outcome-25` | `test_fear_assessments`, `test_fear_phobia_worsening`, `test_fear_mental`, `test_fear_selection` | Unrun; audit open |
| 26 | `fear-outcome-26` | `test_fear_assessments`, `test_fear_compound`, `test_fear_compound_preflight` | Unrun; audit open |
| 27 | `fear-outcome-27` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound`, `test_nightmare_compound`, `test_fear_selection`, `test_fear_compound_preflight` | Unrun; audit open |
| 28 | `fear-outcome-28` | `test_fear_assessments`, `test_fear_coma` | Unrun; audit open |
| 29 | `fear-outcome-29` | `test_fear_assessments`, `test_fear_coma` | Unrun; audit open |
| 30 | `fear-outcome-30` | `test_fear_assessments`, `test_catatonia` | Unrun; audit open |
| 31 | `fear-outcome-31` | `test_fear_assessments`, `test_fear_seizure`, `test_fear_adjudication` | Unrun; audit open |
| 32 | `fear-outcome-32` | `test_fear_assessments`, `test_fear_acute` | Unrun; audit open |
| 33 | `fear-outcome-33` | `test_fear_assessments`, `test_extreme_panic`, `test_panic_flight`, `test_panic_fall`, `test_fear_recovery_ruling`, `test_panic_path`, `test_panic_object`, `test_panic_attack`, `test_panic_interrupted_path`, `test_panic_wait`, `test_panic_computer` | Unrun; audit open |
| 34 | `fear-outcome-34` | `test_fear_assessments`, `test_fixed_beliefs` | Unrun; audit open |
| 35 | `fear-outcome-35` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound` | Unrun; audit open |
| 36 | `fear-outcome-36` | `test_fear_assessments`, `test_fear_physical`, `test_fear_aging`, `test_fear_selection`, `test_fear_hearing_loss` | Unrun; audit open |
| 37 | `fear-outcome-37` | `test_fear_assessments`, `test_fear_physical`, `test_fear_aging`, `test_fear_selection`, `test_fear_hearing_loss` | Unrun; audit open |
| 38 | `fear-outcome-38` | `test_fear_assessments`, `test_fear_compound`, `test_fear_compound_preflight` | Unrun; audit open |
| 39 | `fear-outcome-39` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound`, `test_fear_compound_preflight` | Unrun; audit open |
| 40-plus | `fear-outcome-40-plus` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound`, `test_fear_adjudication` | Unrun; audit open |

## Original optional stress policy

This is an explicitly approved campaign design, not a procedure from full-2008.
Create `vhyl-rpg-expanded-stress.t`; inclusion alone does not activate it.

- One owned stress balance, range 0–12. Explicit evidenced mild/moderate/severe
  causes add 1/2/3. Unique causes cannot add stress twice. Retain requested and applied
  amounts; clamp at the cap and explicitly discard overflow.
- Thresholds 4/8/12 each queue one decision per episode in ascending order.
  Returning to zero rearms thresholds. Existing unresolved decisions survive.
- Choose strain (-1 skill/attribute checks for 600 seconds, refresh without
  stacking), an ordinary owned fear event, or evidenced narrative coping.
  Strain does not alter self-control, damage or derived characteristics.
- Pending decisions block the next voluntary non-recovery action before costs
  or dice, without blocking incoming harm, passive defense, involuntary effects,
  rest/care or narrowly authorized decision resolution.
- Each uninterrupted safe hour recovers one point, maximum four per campaign
  day, credited to the day in which the hour ends. Intervals cannot overlap or be
  reused. Interrupted hours grant no credit. Use the shared clock.
- Recovery does not cure independent strain/fear/traits or erase decisions.
  Gains are never automatic after fear, attacks or critical hits.
- Configure policy before first use, then retain it immutably with owned state.
  Use existing transaction/undo/save machinery and exact-game save compatibility.

## Implementation and validation gates

1. Close F01–F10 by tracing source rows and actual implementations; correct stale
   inventory notes and author any missing acceptance scenarios.
2. Close F11–F13 without enlarging the roster or peripheral subsystems.
3. Implement S01–S04 with owned lifecycle fixtures and default-value assertions.
4. Finish D01 and audit that every requirement has executable implementation or
   a specific tested author contract and authored acceptance fixtures.
5. Only then resume checks. Repair failures within this frozen scope. No passing
   claim is permitted from source inspection or fixture registration alone.

| Required command / evidence | Environment / observed result |
| --- | --- |
| `python tools/test.py` | Not run; paused |
| `python tools/test.py --native` | Not run; paused |
| `python tools/build_docs.py --check` | Not run; paused |
| Packaging unit tests; `python tools/build_release.py --out <fresh-local-directory>`; checksum verification | Not run; paused; no publishing |
| Minimal/all-module and absent-feature regression coverage | Audit required before execution |
| Parser/structured/dialogue connected example | Implementation and validation required |

Push reviewable commits to PR #4; retain draft status for the wider conversion.
Complete this milestone only when every requirement above has observed passing
acceptance evidence and no unresolved in-scope implementation remains.
