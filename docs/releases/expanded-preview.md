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

Successful bleeding-control care can now commit a linked bandage credit in the
same minute and transaction. Existing wound/serial markers prevent duplicate
healing. Earlier-wound allocation after further blood loss remains restricted;
combined healing, rollback and save fixtures are authored and unrun.

Bleeding care now protects its own completion deadline independently of the
next blood-loss check. Offset care, cancellation and saved continuation retain
both event times; new fixtures are authored and unrun.

Radiation now has owned whole-rad dose histories, independent daily decay and
permanent tenth-rad residue, plus pure syndrome-table selection. The supplied
800-rad overlap is explicitly blocked. Syndrome execution, exposure integration
and treatment remain pending; new fixtures are authored and unrun.

Radiation shielding now exposes the printed PF samples and exact received-dose
ratios, with an owned whole-rad exposure adapter. Fractional received-dose
integration and cosmic PF below one remain explicit unresolved cases.
New fixtures are authored and unrun.

Radiation doses now retain exact fractions through shielding, independent
recovery, permanent residue and summation. Lossy tenth-rad conversions are
rejected, with bounded integer arithmetic. Effects-table selection for fractional
totals remains unresolved; fractional persistence fixtures are authored and unrun.


Radiation resistance now prices all nine reference tiers and applies their dose
divisors after shielding. Received doses retain exact fractions and their original
receipt when traits change later. Modifier combinations and advancement remain
unsupported; the new integration fixture is authored and unrun.


Preventive radiation medication now uses the shared inventory and clock: one
owned dose grants the reference reduction during its one-to-three-hour window.
Receipts prevent duplicate consumption and preserve already-recorded exposure.
Overlapping administrations are explicitly unsupported. Boundary and persistence
fixtures are authored and unrun; other radiation treatments remain pending.


Advanced radiation treatment now consumes one technology-nine inventory dose and
grants +3 through a dedicated radiation HT context for fourteen days. It shares
administration and receipt handling with preventive medication; overlapping
courses are blocked and absorbed dose is unchanged. New expiry and persistence
fixtures are authored and unrun. Automatic radiation syndrome procedures remain
pending.


Internal fallout now has owned contamination and treatment records. Basic and
advanced medication consume existing inventory doses and reduce future authored
instantaneous releases on their reference schedules, preserving absorbed dose.
Continuous source-rate integration, repeated ingestion and repeated treatment
remain unsupported. New boundary and persistence fixtures are authored and unrun.


Living-subject radiation checks now retain source/day receipts, use active
advanced treatment and preserve their rolled outcome across replay and saves.
Nonzero syndromes are explicitly awaiting consequences; their medical effects
are still pending. Unsupported table bands block before randomness. New fixtures
are authored and unrun.


Pain sensitivity now connects its fixed purchase to shared injury handling:
doubled shock, physical resistance penalties and recorded Will checks to avoid
crying out. Default injury hooks preserve the absent-trait path. New and updated
fixtures are authored and unrun; observer consequences and radiation symptom
timing remain pending.


Initial radiation burns now have an owned onset deadline, one shared wound and
a one-week effective pain-trait change that preserves purchased traits. The clock
protects pending onset, and receipts prevent repeated injury. Recovery checks,
higher syndromes and overlapping episodes remain pending. New fixtures are
authored and unrun.


An acquired one-year terminal condition now has shared trait accounting and an
owned, calendar-defined death deadline. It does not award spendable points or
permit time to skip its pending resolution. Other tiers, cures and radiation
recovery integration remain pending; new fixtures are authored and unrun.


Radiation-burn recovery now records its two independent health checks and acquires
sterility or a one-year terminal condition only on the corresponding critical
failure. Outcomes share character accounting and existing condition deadlines.
Whole-profile healing is required pending wound-specific recovery allocation;
new outcome and persistence fixtures are authored and unrun.


Nausea now has owned cause records, attribute/skill and defense penalties, and
independent expiry or cause-ending receipts. Multiple causes do not multiply the
nausea penalty. Vomiting-trigger integration remains pending; new duration and
persistence fixtures are authored and unrun.


Nausea events now compose their health checks with shared retching and reviewed
oral-benefit loss. Fixed-duration vomiting ends without the extra recovery roll
used by the preserved fear-table entry point. Hourly motion scheduling and
automatic event adapters remain pending; new fixtures are authored and unrun.


Hourly nausea checks now have owned free-fall/motion exposure records. The clock
protects each hour, healthy hours consume no dice, and replay cannot advance a
deadline twice. Vomiting endpoints share the same clock without duplicate time.
Automatic event adapters remain pending; new fixtures are authored and unrun.


Impaired clotting now has its fixed purchase, HT cap and distinct care-stage
assessment. Ordinary bleeding rejects the trait rather than applying its different
random loss procedure. Owned mandatory bleeding and definitive treatment remain
pending; new fixtures are authored and unrun.


Impaired-clotting wounds now own independent untreated minute-loss records with
fixed original amounts, protected deadlines and shared injury accounting.
Ordinary healing is gated for registered untreated/protected losses. Treatment
transitions and automatic enrollment remain pending; new fixtures are authored
and unrun.


Impaired-clotting first aid now shares the one-minute bandaging operation and its
single healing credit. External bleeding stops; torso impalements retain daily
loss, while prior internal loss stays protected from ordinary healing. Unrelated
injury can recover. Definitive treatment remains pending; fixtures are unrun.


Internal bleeding now accepts a concrete authored supernatural-restoration event:
protected HP restoration and stopping the source are independent effects, with
shared healing and replay-safe receipts. Surgical execution remains pending;
new partial-restoration and persistence fixtures are authored and unrun.

Surgical assessment now derives prerequisite and Physician training from owned
skill investments and returns the shared current skill score. The medical
skill supplies all four published default paths and distinguishes learning
prerequisites from default use. Surgical equipment from a different technology
level now uses the shared B168 penalties, including impossible advanced tools,
without doubling the B424 equipment or anesthetic modifiers. Timed surgery
and its consequences remain incomplete; the new fixture is authored and unrun.

The common surgical operation now owns its elapsed-time boundary and completion
receipt, with one skill roll and a shared 3d failure wound. It supports interruption
and replay, with rollback/undo/save fixtures authored but unrun. Specific treatment
effects and infection/bleeding combinations remain incomplete and are not claimed
as covered by this common lifecycle.

Lasting crippling injuries now have a two-hour surgical repair adapter: success
converts the remaining authored month fraction to campaign weeks, while critical
failure makes the disability permanent in addition to the general failure injury.
An owned deadline restores function without healing HP. Integration and persistence
fixtures are authored and unrun; the documented medical combination gaps remain.

Post-surgical infection now uses an operation-owned exposure with shared disease
resistance, daily progression and protected disease injury. Successful surgery
does not create a fictitious wound. Required exposures are preflighted before
starting and committed once after the operation; integration/persistence fixtures
remain authored and unrun. Antibiotic acquisition exceptions remain incomplete.

Mortal stabilization now has an owned one-hour operation with per-condition retry
penalties, injury-severity modifiers and the permanent-health recovery check.
Ordinary survival checks continue during care. Discretionary complications are
flagged rather than invented. Fixtures are authored and unrun; trauma maintenance
and the documented surgical combination gaps remain incomplete.

Trauma maintenance now provides owned hourly or daily survival checks using the
higher patient/caregiver score. Ledger dispatch advances owned mortal care during
other activities; resting skips duplicate mortal-clock processing. Default Lite
dispatch remains unchanged. Fixtures are authored and unrun. Mid-interval support
transitions and suspended animation remain incomplete.

An owned suspended-animation receipt now suppresses mortal survival checks while
preserving the partial interval and preventing ordinary awakening. It requires an
already resolved external effect; acquisition and other physiological interactions
remain unfinished. Persistence and healing-interaction fixtures are authored and
unrun.

Healing, spontaneous survival and surgery now share owned mortal-recovery
consequences. A failed permanent-health check changes HT and development revision
once without awarding points. Critical receipts allow an explicit decision to add
no discretionary consequence. Fixtures remain authored and unrun.

Critical mortal recovery can now acquire an approved persistent-wound disadvantage
with a bound location and decision receipt, without additional HP loss or spendable
points. Its source assessment is available; daily dressing and live combat/exposure
integration remain incomplete. Acquisition/persistence fixtures are authored and
unrun.

Persistent wounds now support owned daily dressing through First Aid or Physician,
with authored duration and no HP grant. Successful care suppresses the relevant
-3 modifier in live infection acquisition/progression for that ledger day. Same-day
retries and combat/blood-agent integration remain incomplete. New persistence and
boundary fixtures are authored and unrun.

Poison entry now has source-backed assessments for blood, contact, digestive,
follow-up, respiratory and sense-based delivery, including persistent wounds and
paired area protection. These do not consume payloads or resolve poison effects;
the exposure lifecycle remains incomplete. Route fixtures are authored and unrun.

Owned single-cycle toxic exposures now reuse hazard parameters, size-adjust onset,
protect their ledger deadline and resolve resistance/shared injury once. Cyclic
poison, fatigue, payload accounting and other effects remain incomplete. Timing,
rollback and persistence fixtures are authored and unrun.


Cyclic toxic HP exposure now owns individual cycle receipts, checks resistance at
each exact deadline, ends early on successful resistance and protects outstanding
poison injury from healing until termination. Replaying the onset cannot trigger
a later cycle. Added rollback, undo and cross-process continuation fixtures; all
remain unrun while checks are paused. Fatigue effects, symptoms and treatments
remain incomplete. The expansion branch includes the current main branch.


Increased abstract digestive and hypodermic poison doses now bind timing, damage
and resistance to one immutable exposure setting. The pure assessment also
returns dose count, cost and detection modifiers. Fractional doses, automatic
payload consumption and purchasing/detection integration remain unfinished.
Added authored, unrun fixtures for arithmetic, injury and invalid routes.


Agent-specific antidote receipts now consume one owned inventory unit and either
modify future poison resistance or terminate the admitted exposure without
healing existing injury. Wrong agents and combined remedies are rejected.
Identification and administration require explicit authored evidence; their
action integrations and general treatment remain incomplete. Replay, rollback,
undo and save-continuation fixtures are authored but unrun.


Timed poison care now owns one first-aid/physician attempt, charges the shared
clock once and grants its resistance bonus only after a successful skill roll.
Wound and digestive care use their specified durations/modifiers; general
physician care enforces the medical technology cap. Unsuitable care, skipped
poison deadlines and undefined combinations are rejected. Added authored,
unrun fixtures; identification actions and harmful exceptions remain unfinished.


Ordinary melee poison coatings now consume abstract inventory doses and deplete
from actual strike outcomes: one hit or three blocks/parries, with misses and
dodges preserved. Default no-op weapon hooks retain uncoated attack behavior.
Fixtures are authored and unrun. Automatic penetration-to-exposure delivery,
injectors, unusual coatings and ranged payloads remain incomplete.


Added neutral executable delayed-ingested and rapid-systemic poison catalogue
definitions from full-2008 B439, including fixed route-specific timing and an
inventory lot factory with price, technology and legality. Literal source-value
fixtures cover the eight-cycle sequence and unresisted onset variants; they remain
unrun. Other agents and automatic payload admission remain incomplete.


Added fixed positive toxic damage without damage-die draws, and the neutral
dual-route catalogue agent's distinct area-contact and area-respiratory cycles.
Admission enforces area delivery and documented preparation; unprepared fear
integration remains blocked explicitly. Full-cycle expected-value fixtures are
authored and unrun, and persistent environmental repetition remains incomplete.


The neutral injected-venom catalogue entry now executes cyclic toxic damage and
its exact injury-based DX symptom thresholds. Temporary penalties affect DX
checks and skills while preserving secondary characteristics and defensive
reactions. Healing clears severity without later unrelated wounds restoring it.
Fixtures are authored and unrun; other symptom forms and combined symptomatic
exposures remain incomplete.


Fatigue-damage poison now uses owned FP-loss receipts and expanded overflow
wounds. Active cyclic FP and HP losses remain protected from rest/healing until
termination, while unrelated fatigue may recover. A default-zero Lite recovery
hook preserves the existing behavior when no expansion lock is present. Added
authored, unrun overflow and persistence fixtures; validation remains paused.


Poison identification now owns clue/symptom examination time, skill checks and
results, including increased-dose detection modifiers. Successful receipts can
authorize timed treatment for the same examiner and exposure. Failed or
unsupported identification does not grant care permission. Added authored, unrun
transaction/persistence fixtures; knowledge sharing and other recognition paths
remain incomplete.


Antidote administration now accepts owned identification receipts, requiring a
successful result for the same exposure and actual administrator before any
stock is consumed. Failed knowledge, mismatched or incapacitated administrators
and altered receipts are rejected. Added authored, unrun persistence and
transaction fixtures. Knowledge sharing and combined remedies remain incomplete.


Continued area poison exposure now owns resistance retry deadlines and departure.
Success retries after the scaled delay or one second for immediate agents; first
failure starts ordinary damaging cycles. Leaving before acquisition cancels the
pending effect, while leaving afterward preserves acquired poison. Added authored,
unrun transaction and persistence fixtures. Cloud lifecycle and re-entry remain
incomplete.


Poison susceptibility now has a concrete author contract for a specific
physiology, character and agent. Explicit immunity resolves without effects or
environmental retries; an authored modifier changes resistance. The decision is
bound at admission and never inferred from ancestry labels. Fixtures are authored
and unrun; changing physiology during exposure remains unsupported.


Owned coughing/sneezing episodes now apply timed attribute/skill penalties and
block Stealth, while preserving temporary-attribute defensive and secondary
exceptions. Expiry follows the shared clock without extra rolls. Added a minimal
health-only fixture, authored and unrun. Poison/environment cause integration and
overlapping durations remain incomplete.


Ordinary smoke now uses the owned environmental poison path to apply coughing
without injury. Symptoms persist in the area and expire after departure plus the
resistance failure margin in minutes. No price or technology is invented for
smoke. Authored fixtures cover retry, continuous symptoms, exact expiry, undo and
saved continuation; they remain unrun. Dense smoke and ambiguous nonpositive
failure-margin durations remain incomplete.


Temporary blindness now owns its finite duration and blocks explicitly visual
checks while preserving nonvisual senses. Strikes involving the condition reject
before rolling until the unseen-target combat adapter is implemented. Added a
minimal fixture for expiry, replay, rollback, undo and saved continuation; it is
authored and unrun. Environmental blindness integration remains incomplete.


The neutral dual-irritant catalogue now applies respiratory coughing or
vision-based blindness through owned environmental conditions and departure
tails. Authored cloud density also modifies vision per whole yard independently
of resistance. Fixtures are authored and unrun. Unprepared fear resolution,
overlapping effects and unseen-target combat remain incomplete.


Owned paralysis now preserves consciousness, handles balanced-position onset and
restricts voluntary movement and speech. Explicit mental abilities requiring
neither can use the existing owned action gate, with receipt-bound permissions.
Added a minimal authored, unrun fixture for expiry, rollback, undo and saved
continuation. Poison causes and specialized combat adapters remain incomplete.


Physical medical procedures now consult the practitioner's movement availability
before starting care. This closes a conscious-paralysis bypass in bandaging,
first aid, surgery, resuscitation, bleeding/clotting care, trauma maintenance,
dressing and poison treatment. Identified-antidote administration also checks
movement. Added authored, unrun bandaging boundary assertions; checks remain
paused during implementation.
