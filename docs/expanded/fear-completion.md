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
| F01 | full-2008 B360; B345 ruling | Owned initial fear: modifiers, immunity, cap, outcome selection, no invented below-three dice/margin | `test_fear_event`, `test_fear_context`, `test_fear_low_score`, `test_low_control_fear`; full modifier audit required | Unrun; open |
| F02 | full-2008 B360–B361 | Every outcome has matching owned dispatch and concrete effects; see row matrix | Row fixtures below; verify source expectations and dispatch | Unrun; open |
| F03 | full-2008 B361 | Compound health + trait + IQ effects preflight atomically, reject either invalid component without side effects | `test_fear_compound`, `test_fear_compound_preflight`, `test_fear_mental_compound`, `test_fear_compound_context`; pure preview, rejected/preused acquisition and episode cases authored | Unrun; open |
| F04 | full-2008 B148–B150 | Phobia exposures, awareness, repetition, overlap, activity/learning restrictions and worsening | `test_phobia`, `test_phobia_awareness`, `test_phobia_overlap`, `test_phobia_activity`, `test_phobia_learning`, acquisition/worsening fixtures | Unrun; open |
| F05 | full-2008 B93 | Source/victim aura ownership, perception, one-hour protection and prior exposure boundary | `test_fear_aura`; recheck exact boundary and reused context cases | Unrun; open |
| F06 | full-2008 B136, B148, B156 | Postbattle, voices and intrusive replay preserve trigger distinctions and coexist with original consequences | Fear stress, postbattle, replay-fear and replay-self-control fixtures | Unrun; open |
| F07 | full-2008 B361, B428 | Owned recovery and incapacity: correct deadlines, overlap, rest/care, no clearing independent conditions | Faint, coma, catatonia, seizure, panic, recovery-ruling and overlap fixtures | Unrun; open |
| F08 | full-2008 B361, B444 | Exact acquisition/worsening costs; no spendable point award; aging and minimum-attribute rulings | `test_fear_mental`, `test_fear_aging`, `test_fear_adjudication`, physical and hearing-loss fixtures | Unrun; open |
| F09 | Frozen trait source entries | Actual actor/observer reactions, mitigation and incapacity boundaries for each eligible selection | Per-trait social fixtures; roster audit required | Unrun; open |
| F10 | full-2008 B361 rows 21/33 | Expression, room flight, tactical path, fall, attack and destruction produce actual effects with one time/resource charge | Timed-path, expression, flight, fall, path, attack, defense, object, computer and interruption fixtures | Unrun; open |
| F11 | Baseline whitelist + approved scope | Each frozen selection has acquisition, effects, mitigation, worsening where applicable and replay | Per-trait fixtures; exact roster below | Unrun; open |
| F12 | full-2008 B153 | Short attention fails a concrete owned task; terminal prototype failure retains charges and blocks continuation/delivery; enable acquisition/worsening | Owned task lifecycle, prototype terminal gate and fear whitelist implemented. `test_attention_work`, `test_attention_prototype`, `test_attention_acquisition` and `test_attention_rapid_prototype` authored; awaiting execution | Implemented; unrun |
| F13 | full-2008 B124 plus approved knockdown ruling | Complete frenzy entry, legal action/defense policy, injury effects, target changes and exit | Owned injury entry, effective shock/stun/movement and survival hooks, and wound-bound knockdown rulings authored in `test_frenzy_entry`, `test_frenzy_knockdown` , `test_frenzy_temper` and `test_frenzy_voluntary`. Temper reuses its check; voluntary entry commits Concentrate and Will. Optional battle entry and rating prices authored in `test_frenzy_battle`. Owned recorded turns, ranged reloads, tactical paths, target changes, exit health and acquisition now have `test_frenzy_turn`, `test_frenzy_boundaries` and `test_frenzy_acquisition` fixtures | Implemented; unrun |
| S01 | Original campaign stress rules below | Optional policy/state and explicit unique gains; cap, immutable policy and episode reset | `RpgExpandedStressPolicy`, state/gain receipts; `test_stress` | Implemented; unrun |
| S02 | Original campaign stress rules below | Ascending owned threshold decisions, persistence and voluntary-action gate | Owned ordered decisions and shared action/check gates; `test_stress`, `test_stress_fear` | Implemented; unrun |
| S03 | Original campaign stress rules below | Timed nonstacking strain, ordinary owned fear or recorded coping; no recursive gains | Owned strain/coping/fear resolutions; `test_stress`, `test_stress_fear` | Implemented; unrun |
| S04 | Original campaign stress rules below | Safe-hour recovery, daily cap, interruption, interval ownership and independent aftermath | Owned safe-hour intervals, shared-clock settlement and daily ledger; `test_stress` | Implemented; unrun |
| D01 | Approved delivery plan | Neutral docs, catalogue/provenance/API navigation and connected playable fear/stress sequence | Stress guide, catalogue, API inputs and connected Echo Vault scene; `test_echo_aftermath` | Authored; unrun |
| V01 | Approved delivery plan | Pure preview, rejection before costs/dice, replay, rollback, undo, separate-process saves for every requirement | Lifecycle fixtures plus coverage audit | Unrun; open |
| V02 | Approved delivery plan | Minimal/all-module builds, unchanged absent-feature behavior, source/native/docs/packaging checks | Commands and result record below | Running |

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
the owned wound ruling and exit contracts are implemented, awaiting validation.

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
| `python3 tools/test.py --vhyl <pinned-vhyl>` | Passed: 48 tool tests and 537 source programs; final-head rerun required after validation fixes |
| `python3 tools/test.py --native --vhyl <pinned-vhyl>` | Running: core, reporting, resilience and Lite passed; expanded suite running |
| `.tools/docs/bin/python tools/build_docs.py --check` | Passed: strict build, local links and 1,515 declarations |
| Packaging unit tests; `.tools/docs/bin/python tools/build_release.py --out <fresh-local-directory>`; checksum verification | Unit tests passed; clean snapshot `de1ef98` built and all manifest/archive checksums verified; final-head repeat required; no publishing |
| Minimal/all-module and absent-feature regression coverage | 537 source programs passed; core/resilience/Lite native regressions passed |
| Parser/structured/dialogue connected example | Passed `test_echo_aftermath`: parser, structured actions, dialogue and cross-process continuation |

Push reviewable commits to PR #4; retain draft status for the wider conversion.
Complete this milestone only when every requirement above has observed passing
acceptance evidence and no unresolved in-scope implementation remains.

## Current validation gate

Implementation includes the frozen roster and owned author contracts, the optional
stress module and connected Echo Vault acceptance sequence. Checks resume to
execute the authored scenarios and repair failures within this scope. Wider
conversion work remains deferred.

### Observed validation, current working tree

- `.tools/docs/bin/python tools/build_docs.py --check`: passed; 1,512 public/internal declarations indexed, strict site build and local links checked.
- `python3 -m unittest discover -s tests -p test_docs.py`: 8 passed.
- `python3 -m unittest discover -s tests -p test_expanded_inventory.py`: 16 passed.
- Source suite: 48 tool tests and 537 source programs passed with the verified pinned compiler; rerunning after the host-boundary integration.
- Native execution remains in progress. `test_frenzy_turn` passed actual injury/time, rejection, exception rollback, undo, deterministic replay and cross-process save continuation. The larger focused and full suites are running. The first optimized build exceeded the compiler tool deadline; validation uses unoptimized games and an explicit 64 MiB macOS test-host worker stack. Numeric fixture parameters now stay outside the object-subject transport. Recoverable mechanics errors use the exported RPG dispatch boundary to release exception ownership before journal rollback.
- Environment: macOS Intel; Python 3.13.14; pinned vhyl revision `53dbf3b94bb12f269fc447c414bff09fc0b7e46d`; verified official `zebc` v0.1.2 archive (SHA-256 `85a8b0e8112fc744937d89729d488a19f15d07fe70b27e48ae596a9907f12c95`); LLVM 22.1.8 and Rust 1.98.1 selected explicitly. The older compiler on PATH is not used for this evidence.


Focused native results observed during the current validation run:

- `test_frenzy_turn`, `test_frenzy_boundaries`, `test_frenzy_acquisition`: passed.
- `test_stress`, `test_stress_fear`, `test_stress_pending`, `test_stress_panic`: passed.
- `test_stress_refresh`: passed nonstacking refresh through the exact expiry boundary and cross-process restore.
- `test_stress_midnight`: passed recovery credit against the day in which the interval ends, preserving a pending decision.
- Core, reporting, resilience and Lite native regressions, including saved continuation: passed in the full runner. Expanded execution remains in progress.
- Echo Vault structured sequence reaches compound faint/recovery, lasting curiosity, panic/recovery, all three stress choices and safe rest. `test_echo_aftermath` now passes all three routes and cross-process saved continuation.

- `test_fear_compound_context`: failed before the commit-order fix and passed afterward, including rollback and fresh-process replay. Physical consequences use the original event context before acquiring a trait that changes later fear scores.
