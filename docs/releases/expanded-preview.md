# Unreleased expanded preview

This branch implements an incomplete experimental suite. It is not a stable
release and does not claim full-reference coverage. VERSION follows the merged
main prerelease; no new tag or release publication is part of this work.

The expanded foundation and convenience umbrella currently include sixteen partial
feature modules: campaign, characters, combat, creatures, development, equipment,
exploration, hazards, health, psionics, skills, social, tactical, technology, templates
and traits. Magic and vehicles remain proposed modules without standalone runtime
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
author identifies expelled meal credits for revocation through the daily needs
ledger. Owned oral nausea remedies also support expiry and revocation; other
medicines remain unsupported. Other unsupported recovery combinations
remain explicitly unavailable. New persistence and transaction fixtures are unrun.

The retching combat adapter uses the existing turn clock, preventing duplicate
recovery attempts in the same second. Its transaction and clock fixtures are unrun.


Fatigue-plus-stun fear outcomes now share owned one-point fatigue injuries,
collapse handling and timed recovery. Their maximum possible cost is assessed
before rolling. New boundary and continuation fixtures remain unrun.


Behavioral mental quirks can be acquired from an authored fear event without
awarding advancement points. Owned receipts permit the source's creation-limit
exception and preserve concrete scene portrayal decisions. The health module
can commit a combined stun-and-quirk outcome atomically. Broader trait outcomes
remain unfinished; new fixtures are unrun.


Standalone fear fainting now owns its unconsciousness and minute recovery
boundaries. Ordinary waking cannot bypass the episode, and time advancement
cannot skip its due checks. The conditional- and unconditional-injury faint
outcomes use owned wounds with preflight before randomness. Broader overlap
timing remains incomplete; new fixtures are unrun.


The branch now includes the main character/social prerelease, its Town Registry
example and regression fixtures. Original prerelease evidence is retained in its
own release note; it does not validate the merged expanded suite. Build checks
remain paused.

Sixteen feature modules now have partial implementations. Tactical adds pure hex
distance, adjacent facing and barrier assessments, with a minimal fixture covering
rotations and handedness. It does not yet supply persistent figures or movement.
Magic and vehicles still have no standalone runtime module. All newly authored
fixtures remain unrun, and the full suite remains incomplete.

Tactical movement assessments now retain fractional costs, distinguish forward
turns from fixed-facing sidesteps, and apply the final-facing restrictions.
Whole-allowance entries, jumping and evasion have explicit result contracts;
complete path execution and its transactional integration remain pending. The
associated movement-value fixtures are authored and unrun.

Tactical maps now own initial single-hex figure placements and retained receipts.
Finite-cell occupancy checks reject unknown terrain and unresolved footprint
changes. Replay cannot reset a position or install a second figure for a character.
Position transaction and save fixtures are authored but unrun; movement, larger
footprints, close combat and encounter transfer remain incomplete.

Owned tactical footprint changes now reconcile a separately resolved lying
posture with two occupied cells and recovery into either cell. They preserve
shared posture and charge no duplicate time. Transaction/save fixtures are
authored and unrun. Automatic composition with maneuvers, knockdown and forced
overlap remains incomplete.

An explicit tactical posture maneuver now previews geometry before action
permission and commits posture plus footprint in one battle transaction, using
the existing round clock. Direct standing from lying is rejected. Expanded
exhaustion permission and forced knockdown composition remain pending; the
new battle fixture is authored but unrun.

Posture maneuvers can now delegate to a fresh expanded health action gate.
Exhaustion and injury consciousness resolve once, after geometry preflight;
failed permission leaves the footprint unchanged. Combined rollback, undo and
save-continuation fixtures are authored and unrun.

Ordered tactical path assessment now composes entry costs, paid turns, final
facing, ally traversal, occupied endpoints, one-hex minimum progress and
whole-allowance terrain. It does not yet execute movement or interrupts.
The path fixtures are authored and unrun.

The active completion scope now targets health/hazards, character construction,
traits/skills/templates, social play, equipment and exploration. Other unfinished
areas will be listed at delivery. The B420 supplied-roll bleeding outcome and
clear-minute streak are now assessed explicitly; owned bleeding execution remains
pending. New fixtures are authored and unrun.

Optional bleeding now has concrete wound classifications, owned onset receipts
and a protected first-minute boundary. Minute execution and first-aid termination
are still pending, so active bleeding is not yet suitable for playable integration.
Onset transaction and save fixtures are authored and unrun.

Owned bleeding minutes now resolve exact due checks, record shared injury and
stop naturally on a critical success or three clear minutes. Time and randomness
are not charged again on replay. First-aid termination and aggregation remain
pending; small-body and last-wounds combinations are explicitly blocked. New
transaction and persistence fixtures are authored and unrun.

Owned one-minute First Aid care now stops future bleeding on success, preserves
earlier blood loss, and records failures/cancellation without duplicate rolls.
Bandage healing-credit composition remains pending. The new treatment timing,
transaction and save fixtures are authored and unrun.
