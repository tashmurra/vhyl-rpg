# Fear and mental-state completion checklist

**Implementation and acceptance fixtures are authored; validation is now in progress.
No passing validation is claimed until recorded below.**

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
| F01 | full-2008 B360; B345 ruling | Owned initial fear: modifiers, immunity, cap, outcome selection, no invented below-three dice/margin | `test_fear_event`, `test_fear_context`, `test_fear_low_score`, `test_low_control_fear`; full modifier audit required | Passed focused native acceptance, including initial modifiers, source cap, route parity and prohibited-roll rulings |
| F02 | full-2008 B360–B361 | Every outcome has matching owned dispatch and concrete effects; see row matrix | Row fixtures below; verify source expectations and dispatch | Row-by-row native evidence is recorded below; remaining panic/trait cases running |
| F03 | full-2008 B361 | Compound health + trait + IQ effects preflight atomically, reject either invalid component without side effects | `test_fear_compound`, `test_fear_compound_preflight`, `test_fear_mental_compound`, `test_fear_compound_context`; pure preview, rejected/preused acquisition and episode cases authored | Compound, preflight, context-changing acquisition and mental-compound acceptance passed; final-suite gate pending |
| F04 | full-2008 B148–B150 | Phobia exposures, awareness, repetition, overlap, activity/learning restrictions and worsening | `test_phobia`, `test_phobia_awareness`, `test_phobia_overlap`, `test_phobia_activity`, `test_phobia_learning`, acquisition/worsening fixtures | Passed acquisition/worsening, activity and learning restrictions, awareness, overlap, repetition and prohibited-roll acceptance |
| F05 | full-2008 B93 | Source/victim aura ownership, perception, one-hour protection and prior exposure boundary | `test_fear_aura`: exact boundary, reused context, undo and fresh-process restore | Passed focused native acceptance |
| F06 | full-2008 B136, B148, B156 | Postbattle, voices and intrusive replay preserve trigger distinctions and coexist with original consequences | Fear stress, postbattle, replay-fear and replay-self-control fixtures | Voice occurrence/clock, commands, masking, origins, fear and self-control follow-ups passed; postbattle/replay coverage running |
| F07 | full-2008 B361, B428 | Owned recovery and incapacity: correct deadlines, overlap, rest/care, no clearing independent conditions | Faint, coma, catatonia, seizure, panic, recovery-ruling and overlap fixtures | Faint, coma, catatonia, seizure, acute injury, recovery rulings and independent incapacity acceptance passed |
| F08 | full-2008 B361, B444 | Exact acquisition/worsening costs; no spendable point award; aging and minimum-attribute rulings | `test_fear_mental`, `test_fear_aging`, `test_fear_adjudication`, physical and hearing-loss fixtures | Mental and physical accounting, aging, minimum-attribute adjudication, hearing loss and fallback worsening passed |
| F09 | Frozen trait source entries | Actual actor/observer reactions, mitigation and incapacity boundaries for each eligible selection | Per-trait social fixtures; roster audit required | Unrun; open |
| F10 | full-2008 B361 rows 21/33 | Expression, room flight, tactical path, fall, attack and destruction produce actual effects with one time/resource charge | Timed-path, expression, flight, fall, path, attack, defense, object, computer and interruption fixtures | Passed focused native acceptance: expression, crying, room flight, falls, tactical and interrupted paths, Wait, recorded attacks, defense consequences, object destruction and computer damage |
| F11 | Baseline whitelist + approved scope | Each frozen selection has acquisition, effects, mitigation, worsening where applicable and replay | Per-trait fixtures; exact roster below | Unrun; open |
| F12 | full-2008 B153 | Short attention fails a concrete owned task; terminal prototype failure retains charges and blocks continuation/delivery; enable acquisition/worsening | Owned task lifecycle, prototype terminal gate and fear whitelist implemented. `test_attention_work`, `test_attention_prototype`, `test_attention_acquisition`, `test_attention_rapid_prototype`, `test_attention_concept`, `test_attention_repair`, `test_attention_task` and `test_attention_study` | Passed focused native acceptance; final-source suite pending |
| F13 | full-2008 B124 plus approved knockdown ruling | Complete frenzy entry, legal action/defense policy, injury effects, target changes and exit | Owned injury entry, effective shock/stun/movement and survival hooks, and wound-bound knockdown rulings authored in `test_frenzy_entry`, `test_frenzy_knockdown` , `test_frenzy_temper` and `test_frenzy_voluntary`. Temper reuses its check; voluntary entry commits Concentrate and Will. Optional battle entry and rating prices authored in `test_frenzy_battle`. Owned recorded turns, ranged reloads, tactical paths, target changes, exit health and acquisition now have `test_frenzy_turn`, `test_frenzy_boundaries` and `test_frenzy_acquisition` fixtures | All eight frenzy entry, injury, battle, turn, acquisition and exit fixture groups passed focused native acceptance |
| S01 | Original campaign stress rules below | Optional policy/state and explicit unique gains; cap, immutable policy and episode reset | `RpgExpandedStressPolicy`, state/gain receipts; `test_stress` | Passed policy, gains, severity, saturation, deduplication and episode-reset acceptance |
| S02 | Original campaign stress rules below | Ascending owned threshold decisions, persistence and voluntary-action gate | Owned ordered decisions and shared action/check gates; `test_stress`, `test_stress_fear` | Passed ascending decisions, saved pending state and pre-cost action gating |
| S03 | Original campaign stress rules below | Timed nonstacking strain, ordinary owned fear or recorded coping; no recursive gains | Owned strain/coping/fear resolutions; `test_stress`, `test_stress_fear` | Passed coping, ordinary fear, panic coexistence, nonstacking strain and exact expiry |
| S04 | Original campaign stress rules below | Safe-hour recovery, daily cap, interruption, interval ownership and independent aftermath | Owned safe-hour intervals, shared-clock settlement and daily ledger; `test_stress` | Passed owned safe hours, interrupted intervals, daily cap, midnight credit and retained independent consequences |
| D01 | Approved delivery plan | Neutral docs, catalogue/provenance/API navigation and connected playable fear/stress sequence | Stress guide, catalogue, API inputs and connected Echo Vault scene; `test_echo_aftermath` | Three interface routes and cross-process continuation passed; final-source rerun pending |
| V01 | Approved delivery plan | Pure preview, rejection before costs/dice, replay, rollback, undo, separate-process saves for every requirement | Lifecycle fixtures and explicit mapping below | Passed focused lifecycle scenarios; full-suite gate remains V02 |
| V02 | Approved delivery plan | Minimal/all-module builds, unchanged absent-feature behavior, source/native/docs/packaging checks | Commands and result record below | Running |

## Frozen mental-selection roster

The following is the exact `rpgExpandedFearMentalFacts` whitelist at `c2ba9d0`.
Add only short attention and frenzy in this milestone. Quirks, fixed beliefs,
phobias and their existing consequence interfaces remain included separately.

| Trait ID | Public type | Acceptance scenarios | Observed validation |
| --- | --- | --- | --- |
| `truthfulness` | `RpgExpandedTruthfulness` | `test_truthfulness` | Running; awaiting `test_truthfulness` |
| `curious` | `RpgExpandedCuriosity` | `test_curiosity` | Passed focused native acceptance |
| `cowardice` | `RpgExpandedDangerAvoidance` | `test_danger_avoidance`, `test_danger_reaction` | Passed focused native acceptance |
| `compelled-aid` | `RpgExpandedCompelledAid` | `test_compelled_aid` | Passed focused native acceptance |
| `low-motivation` | `RpgExpandedLowMotivation` | `test_low_motivation` | Passed focused native acceptance |
| `postbattle-stress` | `RpgExpandedPostbattleStress` | `test_postbattle_fear` | Passed focused native acceptance |
| `pleasure-loss` | `RpgExpandedPleasureLoss` | `test_pleasure_loss` | Passed focused native acceptance |
| `phantom-voices` | `RpgExpandedPhantomVoices` | `test_phantom_voices`, `test_voice_fear`, `test_voice_self_control` | Passed focused native acceptance |
| `humorlessness` | `RpgExpandedHumorlessness` | `test_observed_reactions` | Passed focused native acceptance |
| `pervasive-distrust` | `RpgExpandedPervasiveDistrust` | `test_distrust_reactions` | Passed focused native acceptance |
| `social-inhibition` | `RpgExpandedSocialInhibition` | `test_social_inhibition`, `test_social_inhibition_minimal` | Passed focused native acceptance |
| `companionship` | `RpgExpandedCompanionship` | `test_companionship`, `test_company_social_operations` | Passed focused native acceptance |
| `overstimulation` | `RpgExpandedOverstimulation` | `test_overstimulation`, `test_overstimulation_strike` | Passed focused native acceptance |
| `goal-fixation` | `RpgExpandedGoalFixation` | `test_goal_fixation`, `test_goal_template` | Passed focused native acceptance |
| `impulsive-action` | `RpgExpandedImpulsiveAction` | `test_impulsive_action` | Passed focused native acceptance |
| `bad-temper` | `RpgExpandedVolatileTemper` | `test_volatile_temper` | Passed focused native acceptance |
| `nightmares` | `RpgExpandedNightmares` | `test_nightmares`, `test_nightmare_compound` | Passed focused native acceptance |
| `overconfidence` | `RpgExpandedOverconfidence` | `test_overconfidence`, `test_overconfidence_social` | Passed focused native acceptance |
| `solitude` | `RpgExpandedSolitude` | `test_solitude`, `test_solitude_social` | Passed focused native acceptance |
| `status-sensitivity` | `RpgExpandedStatusSensitivity` | `test_status_sensitivity`, `test_status_sensitivity_social`, `test_status_outburst` | Running; awaiting `test_status_sensitivity_social`, `test_status_outburst` |
| `self-sacrifice` | `RpgExpandedSelfSacrifice` | `test_self_sacrifice` | Passed focused native acceptance |
| `intrusive-replay` | `RpgExpandedIntrusiveReplay` | `test_intrusive_replay`, `test_replay_self_control`, `test_replay_fear`, `test_replay_senses`, `test_replay_overlap`, `test_acquired_replay_event` | Passed focused native acceptance |
| `low-confidence` | `RpgExpandedLowConfidence` | `test_low_confidence` | Passed focused native acceptance |
| `incuriosity` | `RpgExpandedIncuriosity` | `test_incuriosity`, `test_incuriosity_social` | Passed focused native acceptance |
| `indecision` | `RpgExpandedIndecision` | `test_indecision`, `test_indecision_confusion`, `test_indecision_turns` | Passed focused native acceptance |
| `credulity` | `RpgExpandedCredulity` | `test_credulity`, `test_credulity_learning` | Passed focused native acceptance |


Frenzy's combined knockdown/consciousness ambiguity now has an approved policy:
require a recorded author-selected ruling, retain actual injury and stun immunity,
and invent no unstated modifier. The previous unanswered-policy blocker is closed;
the owned wound ruling and exit contracts passed focused native acceptance.

Short attention uses a concrete owned task lifecycle and the minimum
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
| 4-5 | `fear-outcome-4-5` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Passed focused native acceptance |
| 6-7 | `fear-outcome-6-7` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Passed focused native acceptance |
| 8-9 | `fear-outcome-8-9` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Passed focused native acceptance |
| 10 | `fear-outcome-10` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Passed focused native acceptance |
| 11 | `fear-outcome-11` | `test_fear_assessments`, `test_fear_stun`, `test_fear_stun_modifiers`, `test_fear_stun_persistence`, `test_fear_combat` | Passed focused native acceptance |
| 12 | `fear-outcome-12` | `test_fear_assessments`, `test_fear_retching`, `test_owned_retching`, `test_retching_persistence`, `test_retching_fatigue`, `test_retching_combat`, `test_retching_meals`, `test_retching_remedy`, `test_remedy_persistence` | Passed focused native acceptance |
| 13 | `fear-outcome-13` | `test_fear_assessments`, `test_fear_quirks` | Passed focused native acceptance |
| 14-15 | `fear-outcome-14-15` | `test_fear_assessments`, `test_fear_fatigue`, `test_fear_fatigue_stun`, `test_fear_stun` | Passed focused native acceptance |
| 16 | `fear-outcome-16` | `test_fear_assessments`, `test_fear_quirk_stun` | Passed focused native acceptance |
| 17 | `fear-outcome-17` | `test_fear_assessments`, `test_fear_faint` | Passed focused native acceptance |
| 18 | `fear-outcome-18` | `test_fear_assessments`, `test_fear_faint_injury` | Passed focused native acceptance |
| 19 | `fear-outcome-19` | `test_fear_assessments`, `test_fear_faint_injury` | Passed focused native acceptance |
| 20 | `fear-outcome-20` | `test_fear_assessments`, `test_fear_shock_faint` | Passed focused native acceptance |
| 21 | `fear-outcome-21` | `test_fear_assessments`, `test_fear_panic`, `test_panic_crying`, `test_panic_history`, `test_timed_panic_path`, `test_panic_expression_communication` | Passed focused native acceptance |
| 22 | `fear-outcome-22` | `test_fear_assessments`, `test_fixed_beliefs` | Passed focused native acceptance |
| 23 | `fear-outcome-23` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound`, `test_fear_selection`, `test_status_sensitivity`, `test_status_outburst`, `test_self_sacrifice`, `test_acquired_replay_event` | Awaiting `test_status_outburst` |
| 24 | `fear-outcome-24` | `test_fear_assessments`, `test_fear_physical`, `test_fear_aging`, `test_fear_selection` | Passed focused native acceptance |
| 25 | `fear-outcome-25` | `test_fear_assessments`, `test_fear_phobia_worsening`, `test_fear_mental`, `test_fear_selection` | Passed focused native acceptance |
| 26 | `fear-outcome-26` | `test_fear_assessments`, `test_fear_compound`, `test_fear_compound_preflight` | Passed focused native acceptance |
| 27 | `fear-outcome-27` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound`, `test_nightmare_compound`, `test_fear_selection`, `test_fear_compound_preflight` | Passed focused native acceptance |
| 28 | `fear-outcome-28` | `test_fear_assessments`, `test_fear_coma` | Passed focused native acceptance |
| 29 | `fear-outcome-29` | `test_fear_assessments`, `test_fear_coma` | Passed focused native acceptance |
| 30 | `fear-outcome-30` | `test_fear_assessments`, `test_catatonia` | Passed focused native acceptance |
| 31 | `fear-outcome-31` | `test_fear_assessments`, `test_fear_seizure`, `test_fear_adjudication` | Passed focused native acceptance |
| 32 | `fear-outcome-32` | `test_fear_assessments`, `test_fear_acute` | Passed focused native acceptance |
| 33 | `fear-outcome-33` | `test_fear_assessments`, `test_extreme_panic`, `test_panic_flight`, `test_panic_fall`, `test_fear_recovery_ruling`, `test_panic_path`, `test_panic_object`, `test_panic_attack`, `test_panic_interrupted_path`, `test_panic_wait`, `test_panic_computer` | Passed focused native acceptance |
| 34 | `fear-outcome-34` | `test_fear_assessments`, `test_fixed_beliefs` | Passed focused native acceptance |
| 35 | `fear-outcome-35` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound` | Passed focused native acceptance |
| 36 | `fear-outcome-36` | `test_fear_assessments`, `test_fear_physical`, `test_fear_aging`, `test_fear_selection`, `test_fear_hearing_loss` | Passed focused native acceptance |
| 37 | `fear-outcome-37` | `test_fear_assessments`, `test_fear_physical`, `test_fear_aging`, `test_fear_selection`, `test_fear_hearing_loss` | Passed focused native acceptance |
| 38 | `fear-outcome-38` | `test_fear_assessments`, `test_fear_compound`, `test_fear_compound_preflight` | Passed focused native acceptance |
| 39 | `fear-outcome-39` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound`, `test_fear_compound_preflight` | Passed focused native acceptance |
| 40-plus | `fear-outcome-40-plus` | `test_fear_assessments`, `test_fear_phobia_acquisition`, `test_fear_mental`, `test_fear_mental_compound`, `test_fear_adjudication` | Passed focused native acceptance |

## Lifecycle evidence (V01)

These registered native scenarios assert state, resource balances and random draw
counts, including after restoration in a newly started game process:

| Boundary | Passing acceptance evidence |
| --- | --- |
| Pure preview and either compound component rejected/preused | `test_fear_compound_preflight`, `test_fear_compound_context` |
| Failed owned task cannot resume; completed charges survive | `test_attention_task`, `test_attention_work`, `test_attention_prototype` |
| Action legality, interruption, undo and duplicate spending | `test_frenzy_boundaries`, `test_panic_interrupted_path`, `test_timed_panic_path` |
| Transaction exception and undo restore gains/decisions | `test_stress` (gain and resolution exceptions; gain and strain undo) |
| Duplicate causes, saturation, policy mutation and ordered decisions | `test_stress`, `test_stress_severity` |
| Pending decision survives recovery and a fresh process | `test_stress_pending` |
| Refresh without stacking and exact saved expiry | `test_stress_refresh` |
| Recovery day boundary and interrupted-hour exclusion | `test_stress_midnight`, `test_stress` |
| Ordinary fear resolution replays without duplicate dice or stress | `test_stress_fear` |
| Independent panic can proceed with a saved pending decision | `test_stress_panic` |
| Parser, structured action and dialogue reach the same aftermath | `test_echo_aftermath` |

The per-outcome and roster tables retain the remaining episode-specific tests.
All-module and absent-feature regressions remain the separate V02 gate.

## Original optional stress policy

This is an explicitly approved campaign design, not a procedure from full-2008.
`vhyl-rpg-expanded-stress.t` supplies the policy; inclusion alone does not activate it.

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
| `python3 tools/test.py --vhyl <pinned-vhyl>` | Passed: 50 tool tests and all 538 source programs with the validation fixes; additional fixture transport repairs passed focused native compilation/execution |
| `python3 tools/test.py --native --vhyl <pinned-vhyl>` | Core, reporting, resilience and Lite passed. All-module host compilation exceeded the fixed tool deadline; retrying with fewer concurrent builds |
| `.tools/docs/bin/python tools/build_docs.py --check` | Passed: strict build, local links and 1,515 declarations |
| Packaging unit tests; `.tools/docs/bin/python tools/build_release.py --out <fresh-local-directory>`; checksum verification | Unit tests passed; clean snapshot `de1ef98` built and all manifest/archive checksums verified; final-head repeat required; no publishing |
| Minimal/all-module and absent-feature regression coverage | 538 source programs passed; core/resilience/Lite native regressions passed |
| Parser/structured/dialogue connected example | Passed `test_echo_aftermath`: parser, structured actions, dialogue and cross-process continuation |

Push reviewable commits to PR #4; retain draft status for the wider conversion.
Complete this milestone only when every requirement above has observed passing
acceptance evidence and no unresolved in-scope implementation remains.

## Validation environment and execution

Implementation and acceptance fixtures are authored; checks have resumed. The
requirement and outcome tables above are the authoritative acceptance record.
An observed focused pass does not substitute for the final suite gate.

Validation uses Intel macOS, Python 3.13.14, pinned vhyl revision
`53dbf3b94bb12f269fc447c414bff09fc0b7e46d`, official `zebc` v0.1.2
(archive SHA-256 `85a8b0e8112fc744937d89729d488a19f15d07fe70b27e48ae596a9907f12c95`),
LLVM 22.1.8 and Rust 1.98.1. The older compiler on PATH is not used.
`python3` is the available Python command; documentation uses `.tools/docs/bin/python`.

Native acceptance uses unoptimized games and an explicit 64 MiB macOS test-host
worker stack. The compiler's fixed 120-second external-tool deadline prevents
some universal builds from completing. Completed host slices are retained in
separate validation bundles. The largest combined fixture also required linking
its unchanged compiler-emitted LLVM with the same LLVM flags and a 900-second
outer deadline. Failed universal output is retained separately. These results
establish host-native behavior, not ARM or universal-build validation.

Build reuse compares the complete compiler-preprocessed source before executing
the registered acceptance functions. Focused retries execute the same assertions
as the repository suite; a failed assertion remains open until its corrected
scenario passes. No rule outcome is marked complete from compilation alone.

The final gate includes source, native behavior, strict documentation, packaging
and archive checksums. PR #4 remains draft for the separate wider conversion.
