# Unreleased expanded preview

This branch implements an incomplete experimental suite. It is not a stable
release and does not claim full-reference coverage. VERSION remains unchanged;
no tag or release publication is part of this work.

The expanded foundation and convenience umbrella currently include fifteen partial
feature modules: campaign, characters, combat, creatures, development, equipment,
exploration, hazards, health, psionics, skills, social, technology, templates and
traits. Magic, tactical and vehicles remain proposed modules without standalone runtime
libraries. Available include paths are distinguished from proposals in the
[library catalogue](../libraries.md). Technology currently supplies pure object-capacity,
injury-threshold and disabled-weapon assessments, owned environmental faults and
repairs, computer processing, storage, links, terminals, transfers and recordings.
Task-scoped software can contribute an equipment modifier through a running copy
and live terminal. Required software can select an explicitly approved lower
technology for the task without changing learned skill. Host-bound software sales
share the acquisition ledger, with no repeated charge for program instances. Object damage, inventory transformation, maintenance scheduling,
structural repair and broader invention options remain unfinished. Supported owned
invention stages cover theories, facilities, funded work, secret physical-prototype
completion, concrete defects, whole-week testing and bug-free one-copy production.
Cinematic invention, software prototypes, partial testing and defect propagation
remain incomplete. New fixtures are authored and unrun while checks are paused.

The implemented subsets include secondary purchases and character accounting,
trait pricing, richer skill/default/technique procedures, template composition,
equipment and legal access, contextual reactions and social exchanges, study,
employment and wealth advancement. Each module guide records its actual scope.
The full skill, trait, equipment and supernatural catalogues remain incomplete.

The health module now includes scaled shock, supported location wounds, owned
arm/hand state, equipment and unarmed-parry restrictions, single- and multiple-grip
drops, disability duration, temporary full-health recovery and lasting recovery
through authored calendar milestones. Later completed physician care can shorten
recovery without stacking discounts. An explicit last-wounds option records
ignored injuries without spending health or randomness. Optional expanded natural
recovery adds healing traits and capacity scaling through the shared rest clock.
Qualified medical rosters and scheduled physician checks share the same patient
state. Owned bandaging and post-bandaging treatment record time, recovery and
critical-failure injury. Surgical modifiers and general failure outcomes have pure
assessment interfaces; committed operations remain incomplete. Other anatomy,
accumulated wounds, interrupted care and permanent-disability accounting also
remain incomplete.

The hazards module includes private owned wound-infection acquisition, specific
first-attempt immunity, daily progression and qualified physician-care modifiers.
Recovery releases only the episode's contribution to the shared disease-injury
restriction. Exact aging schedules and ordered aging events preserve independent
secondary purchases and advancement balances. Calendar timing is authored;
automatic scheduling, rejuvenation, broader diseases and environmental hazards
remain incomplete. Minimal and transaction/save fixtures are authored but unrun.

New public expansion APIs use `RpgExpanded` / `rpgExpanded` prefixes. Shared Lite
hooks default to the existing behavior; the latest compatibility and persistence
claims still require validation. Injury, fatigue, inventory and advancement
continue to use their existing balances. Calendar milestones represent authored
world facts and do not introduce a second time-spending ledger. Save support
retains the exact-compiled-game policy; there is no automatic old-save migration.

Public documentation uses neutral reference IDs, edition/printing metadata and
printed page labels. Private source links, source book titles, source prose and
artwork are not repository deliverables. The comparison guide, per-module guides,
source inventories and [coverage ledger](../expanded/coverage.json) describe the
remaining work. Detailed inventory and catalogue enumeration are not complete.

Build checks and CI are paused at the user's request until implementation is
complete. Recent source/native fixtures, transaction and save-continuation cases,
and documentation changes are authored but unrun. Older successful checks do
not validate the current head. Required final checks include existing core/Lite
regressions, independent source-value checks, module dependencies, combined
examples, input parity, rollback/undo/save continuation, strict documentation,
neutral naming, source coverage and packaging. The full PR remains draft until
implementation and those acceptance requirements are satisfied.


The partial expanded combat library now exposes ordinary rapid-fire assessments
from `full-2008` B373–B375: burst limits, attack bonuses, recoil hit counts and
Dodge hit reduction. It is listed in the library catalogue and available through
the umbrella. Minimal dependency and expected-value fixtures are authored but
unrun. Complete attack execution, ammunition expenditure and per-hit injury remain
unimplemented. This preview is not a release or a complete conversion claim.


The technology preview now includes owned invention concept attempts, blueprint
entry, facilities and attempt funding, work intervals, secret completion and
accident consequences through the shared health ledger. Supported executable
prototype defects can be assigned, surfaced by operation failures and discovered
through complete-week testing. Exact production fractions and line capital funding
are available. Supported whole-unit production orders fund and deliver bug-free
physical copies. Fractional ledger amounts, broader defect effects and interrupted
testing remain incomplete. All newly authored fixtures remain unrun while checks are paused.

The creature library now provides pure general-training and single-trick durations,
training-plan eligibility and handling modifiers (`full-2008`, B175 and B458–B459).
Its minimal dependency fixture is authored but unrun. Daily courses, creature
profiles, mounts and swarms remain incomplete.


Fear support includes pure full-table consequence specifications and scene
modifiers, plus owned execution of the short-stun outcomes on B360. Automatic
recovery and subsequent Will attempts share the time ledger; replay does not
charge twice. A Do Nothing combat adapter uses the existing battle clock and
shared health gate. Complete fear-event execution remains unfinished. Persistence,
rollback and recovery fixtures are authored and unrun.


Owned fear-induced retching supplies contextual penalties, concentration
restrictions and shared defense effects. Standalone and combat health recovery charge their
final fatigue once and uses owned wounds for injury at nonpositive fatigue. The
author must establish that no oral benefits need revocation. Unsupported recovery combinations
remain explicitly unavailable. New persistence and transaction fixtures are unrun.

The retching combat adapter uses the existing turn clock, preventing duplicate
recovery attempts in the same second. Its transaction and clock fixtures are unrun.
