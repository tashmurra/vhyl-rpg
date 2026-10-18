# Unreleased expanded preview

This branch implements an incomplete experimental suite. It is not a stable
release and does not claim full-reference coverage. VERSION follows the merged
main prerelease; no new tag or release publication is part of this work.

Exploration now exposes a pure climbing assessment for all nine printed surfaces,
with exact rates, explicit feet/rung units, encumbrance, check boundaries and
combat fatigue. Owned climbing and falling integration remain pending. The new
table and boundary assertions are authored but unrun while checks are paused.

Shared-load lowering now rejects unresolved support loss detected during its time
interval, including a carrier who recovers before the interval ends. An authored
fixture covers rollback of the clock, support event and inventory transfer. Checks
remain paused, so this behavior has not yet been validated by execution.

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


Added owned finite seizures with standing falls, physical and mental action
restrictions, and an explicit end operation that rolls and charges fatigue once.
The shared clock prevents skipping an unresolved end. Added authored, unrun
fixtures for boundaries, replay, rollback, undo and saved continuation. Cause
integrations and broader validation remain incomplete.


Added the neutral neurological-agent catalogue and explicit authored contracts
for accompanying paralysis or seizure on the first failed cycle. The contract
binds condition duration and evidence, preflights before randomness and prevents
later toxic cycles from refreshing the condition. Added authored, unrun coverage
for six cycles, resistance, recovery boundaries and transactional continuation.
Other afflictions, onset policies and unprepared fear remain incomplete.


Added owned agony episodes, begun-minute fatigue payments, low/high pain-threshold
handling and an explicit credible-recurrence bonus interface. Shared-clock guards
prevent unpaid minutes from being skipped. Added authored, unrun fixtures for
boundary costs, trait effects, transactional behavior and saved continuation.
Cause and social adapters remain incomplete.


Neurological agents now accept owned agony as their authored accompanying
condition. Toxic cycles and begun-minute fatigue retain independent receipts and
shared-clock deadlines. Involuntary pain-cry checks remain available during agony
and seizures. Added authored, unrun assertions for coincident deadlines, rejected
time advancement and independent resource spending.


Added a health/social threat context that applies recovered-agony bonuses once
through shared skill scoring. Intimidation validates the actual target before
rolling through a default no-op base hook. Added authored, unrun fixtures for
ordinary/low-threshold bonuses, repeated previews and wrong-target rejection.
The full owned interrogation procedure remains incomplete.


Added owned continuous interrogation sessions and five-minute question receipts.
The operation distinguishes truth, silence, falsehood and convincing falsehood,
applies source-defined circumstances and trait modifiers, and owns the two-hour
boundary. Responses are authored and previews disclose no answer. Added authored,
unrun fixtures for outcomes, modifier values, timing, rollback, undo and saved
continuation. Interrupted/repeated questioning and other integrations remain open.


Interrogation answers can now be delivered once to the existing received-claims
ledger without extra time or randomness. Truthful and false answers retain
private outcome classifications; hearing either does not automatically establish
a belief. Silence and duplicate delivery produce no new claim. Added authored,
unrun fixtures for preview privacy and transactional/save continuation behavior.
Witnesses, sharing and belief adoption remain separate unfinished integrations.


Added owned moderate/severe/terrible pain with high/low threshold modifiers,
affected skill and attribute checks, and a default-zero self-control health hook.
Pain penalties do not double-count through skill attributes or change secondary
statistics. Added authored, unrun fixtures for the penalty matrix, self-control
admission, defensive exceptions and transactional/save continuation behavior.
Cause adapters and overlapping pain composition remain incomplete.


Expanded self-control rolls now use their purchased 6/9/12/15 rating rather than
always using the Lite default twelve. Added owned occurrences that prevent replay
or renamed requests from rerolling the same trigger, while preserving voluntary
acceptance and the existing authored obligation interface. Added authored, unrun
fixtures for rating/modifier combinations, invalid inputs, rollback and undo.
Trait-specific behavior and optional point-funded resistance remain incomplete.


Added opt-in point-funded self-control before trigger resolution. It consumes one
point from the shared progression ledger, honors mandatory spending gates and
records automatic success without randomness. Replay never charges again or
refunds a completed purchase. Authored, unrun fixtures cover policy/funds checks,
conflicting choices, rollback, undo and saved continuation. Retroactive purchases
and campaign reward adjudication remain separate.


Added executable truthfulness with owned omission/falsehood occurrences and
explicit authored communication outcomes. Existing Fast-Talk and deceptive-Acting
penalties are reused; successful self-control does not remove them or guarantee
that a lie convinces anyone. Authored, unrun fixtures cover outcomes, replay,
rollback, undo and saved continuation. Communication delivery remains incomplete.


Added exact rational digging-rate and duration assessments for all eight source
stages, wooden/improvised tools and unusually hard rock. Breaking and removal
remain distinct work outputs. Authored, unrun matrix fixtures preserve fractional
lifting capacity and volume. Owned work intervals, tool possession and fatigue
execution remain incomplete; the assessments alone grant no excavation credit.


Added owned full-hour digging for loose/ordinary soil and alternating hard-soil
work. Actual tool ownership, site capacity and worker conditions are checked;
clock time, fatigue and exact excavation credit commit once. Authored, unrun
fixtures cover rates, limits, rollback, undo and saved continuation. Partial hours,
separate-stage material stocks and exhausted/heat-adjusted work remain incomplete.


Digging now separates preparation from removal for ordinary soil, hard soil and
rock. Owned stock prevents removal before breaking or double-crediting material.
Changing tool rates rescales persistent volumes exactly from original receipts.
Added authored, unrun stock, rescaling and transactional/save continuation fixtures.
Concurrent teams, partial hours and advanced fatigue remain incomplete.


Added concurrent digging teams with one shared hour, independent worker fatigue,
exact material-flow preflight and atomic member receipts. Duplicate workers,
shared tools and insufficient prepared material reject before execution. Added
authored, unrun fixtures for the source's one-pick/two-shovel arrangement and
transactional/save continuation. Partial intervals and advanced fatigue remain open.


Added fixed pickaxe/shovel catalogue instances using existing acquisition, money,
weight and storage state. Digging validates tool roles and authored material facts;
source entries do not imply a material from technology alone. Added authored,
unrun purchase-to-work fixtures with transactional/save continuation. Wear,
repairs and other tool uses remain incomplete.

- Confirmed the expansion branch includes main's character/social merge
  `5935592` through `84c3e5a`. Self-control trait pricing now rejects a rating on
  an uncontrolled disadvantage, including through character accounting. Added
  regression assertions; checks remain paused and the PR remains draft.

- Templates and choice options now accept explicit truthfulness self-control
  purchases. Fresh instances preserve the rating and concrete effect type;
  matching requirements charge once, while differing or unsupported purchases
  reject. Added price, ownership, composition and budget assertions, still unrun.

- Added evidenced delivery of resolved truthfulness statements to the shared
  received-information ledger. Withheld information cannot be delivered; each
  recipient receives an utterance once, without automatic belief or additional
  rolls. Added rollback, undo and saved-continuation fixtures, still unrun.

- Added rated curiosity occurrences with concrete investigative action choices,
  one-time self-control and owned completion. Added a cabinet-action fixture
  covering normal time charging, rollback, undo and saved pending obligations.
  Explicit template purchases retain the concrete trait. Checks remain paused.

- Added purchased physical-danger avoidance, death-risk self-control and explicit
  greater-threat permissions. Fear contexts derive the rating penalty once and
  reject inconsistent overrides. Template purchases and persistence fixtures are
  included; checks remain paused and occupational reaction integration is pending.

- Added informed occupational reactions to purchased danger avoidance. Explicit
  observer and setting facts control applicability; Diplomacy uses the shared
  reaction path, and invalid participants reject before dice. Rating and integration
  assertions are authored but remain unrun while checks are paused.

- Added exact lifting and dragging assessments from full-2008 B353, including
  device weight, surface divisors, combat pickup duration and capacity boundaries.
  Dragging and existing carried loads share encumbrance arithmetic. Owned execution
  and overload handling remain pending; boundary fixtures are authored and unrun.

- Added owned noncombat equipment lifts using exact capacity and the shared time
  ledger. Stored items become carried after revalidation; anatomy checks available
  hands when installed. Added rollback, undo and save-continuation fixtures, unrun.

- Added owned lifting-skill rolls with exact margin-based capacity ratios and
  duplicate-lift rejection. Carrying and encumbrance remain unchanged. Pickup
  consumption is pending; rollback/undo/save fixtures are authored and unrun.

- Connected owned lifting-skill results to physical pickups, preserving baseline
  carrying limits and exact capacity comparisons. Request and weight binding prevents
  bonus reuse for a changed lift. Added joint rollback and between-stage save
  fixtures; checks remain paused and failed physical-attempt timing remains pending.

- Added a combined lifting attempt that records successful pickup or failed
  capacity once. Unsuccessful duration requires explicit author evidence because
  the supplied reference does not specify it. Joint rollback and saved failure
  continuation fixtures are authored; checks remain paused.

- Corrected B15 pickup timing: a load within Basic Lift takes one second outside
  combat as well. Added strength-rounding and skill-adjusted duration assertions;
  corrected the strength-11 digging expectation to the existing rounded base.
  No Lite rounding change was needed. Checks remain paused.

- Added authored cooperative-load assessment by summing individual Basic Lift,
  with duplicate-helper and incapacity rejection. It reuses exact lift/dragging
  arithmetic. Joint execution and load distribution remain pending; fixtures unrun.

- Added pure shared-load allocation assessment with exact weight conservation,
  existing inventory load and per-helper encumbrance. Shares require an evidenced
  author decision. Committed shared carrying remains pending; fixtures unrun.

- Added owned shared carrying and authored lowering, preserving a single item
  owner and per-helper load shares. Storage, trade and individual pickup reject an
  actively shared item. Added rollback, undo and saved-carrying fixtures, unrun.
  Coordinated movement, emergency drops and reallocation remain pending.

- Added explicit emergency release for shared loads after verified support loss.
  Whole-load dropping and impact consequences require authored evidence; the
  release adds no voluntary lowering time. Added rollback/undo/save fixtures,
  unrun. Automatic health-event dispatch and load redistribution remain pending.

- Connected shared carrying to unconsciousness, knockdown and committed limb
  disablement hooks. Pending support loss blocks further time until adjudication,
  survives recovery and save continuation, and clears on emergency release.
  Notification/rollback fixtures are authored; checks remain paused.

- Added shared-carry integration fixtures using real limb-wound operations, covering
  bound hands, parent arms, unbound-hand exclusion, combined incapacitation events,
  rollback, undo and saved injury continuation. All assertions remain unrun.

- Reserved shared-carry supports now reject conflicting weapon, parry, active
  shield and new lifting use while preserving an explicitly free hand. Lowering
  releases reservations. Added capability and pre-RNG strike fixtures, unrun.

- Connected shared-carry reservations to unarmed parry capacity, including mapped
  free arms and conservative handling of unmapped supports. Added direct defense
  query assertions; checks remain paused.

Climbing failure assessment now distinguishes rope-limited falls, critical
failures that bypass rope protection and earlier obstacles. Exploration also
supplies the full printed falling-velocity table for whole-yard distances through
112 yards. These pure calculations do not commit movement or injuries; owned
falling, fractional distances and environmental velocity rules remain incomplete.
Table and geometry fixtures are authored and unrun.

Hazards now supplies a pure full-profile collision damage expression, including
reduced-die bands, half-up rounding and hard-surface capacity doubling. It leaves
existing abridged calculations unchanged. Boundary and printed-example fixtures
are authored but unrun; collision injury execution remains incomplete.

Fall protection assessment now distinguishes worn armor (all treated as flexible
for falls) from innate resistance and separates penetrating damage from blunt
trauma injury. It covers a single homogeneous layer; layered protection and wound
commitment remain incomplete. Boundary fixtures are authored and unrun.

An owned torso fall-injury operation now connects already resolved crushing damage
and homogeneous protection to the existing wound ledger. Reapplication uses its
bound receipt. Preview, transaction, undo and cross-process save fixtures are
provided but unrun. Location rules and the rest of fall execution remain partial.

Owned torso falls now apply an optional breakable-obstacle cap before protection
and blunt trauma. The cap and its source facts are bound to the receipt. Obstacle
damage and subsequent impacts remain unfinished; new fixtures are unrun.

Owned torso falls now support evidenced elastic landing protection before armor,
including its effect on blunt trauma. Fixtures cover partial/complete cushioning,
cap ordering, replay and rollback, but remain unrun while checks are paused.

Controlled-landing assessment now distinguishes acrobatic distance reduction from
successful fluid dives that negate damage. Dive speed penalties reuse the full
range helper, moved unchanged into the expanded foundation. Owned landing attempts
and injury linkage remain pending; new assessment fixtures are authored and unrun.

Owned landing attempts now bind one acrobatic landing or fluid-dive choice and roll
to a profile and distinct fall occurrence. Repeat calls reuse the result; alternate
attempts for that occurrence are rejected. Transaction, undo and save fixtures are
provided but unrun. Automatic impact and injury linkage remain incomplete.

Torso fall injuries can now consume owned landing receipts, enforcing occurrence
and owner binding, matching non-negated impact velocity, dive damage negation and
one injury receipt per fall. Integration/persistence fixtures remain unrun. The
impact damage roll is still author-supplied; automatic roll ownership is pending.

Owned torso impacts now roll and record collision dice and commit the linked
injury in one transaction, after checking penetration and blunt-trauma extrema.
Negated dives consume no damage dice. Deterministic, rollback, undo and save
fixtures remain unrun; broader fall execution is still incomplete.

Health now assesses fall-specific limb/extremity injury without the ordinary
crippling cap and classifies the additional-limb die without adding HP loss.
Owned anatomy changes and fall-location integration remain pending. Threshold and
all-die-result fixtures are authored and unrun.

Owned fall hand injuries now preserve full HP loss while using the existing
anatomy, knockdown and drop machinery. Explicit evidence of a resolved location
is required; automatic location rolls and additional-limb disability remain
unfinished. Transaction and persistence fixtures are authored and unrun.

Owned arm falls now roll once for additional arm crippling and record secondary
disabilities with zero extra HP loss. Existing anatomy/drop hooks are reused.
Both branches and transaction/save fixtures are authored and unrun; automatic
locations, lower limbs and broader equipment combinations remain incomplete.

Combined fall-arm equipment fixtures now cover shared-weapon retention, secondary
arm drops, knockdown precedence, missing destinations and transaction/persistence
behavior. They remain unrun; no equipment integration pass is claimed.

Health now exposes lower-limb consequence assessments for a biped's crippled foot
or leg, including skill penalties, movement limits and support/posture requirements.
Owned lower-limb anatomy and movement enforcement remain pending; boundary fixtures
are authored and unrun.

Owned legs and feet now support ordinary and uncapped fall injuries, forced lying
and same-kind extra crippling. Unsupported movement/posture changes reject pending
aid integration. Transaction/save fixtures are authored and unrun.

Lower-limb penalties now apply once to declared leg-dependent skills and melee
attacks/parries, with ranged attacks exempt. Context overrides and skill metadata
support authored tasks; complete classification remains pending. Score fixtures
are authored and unrun.

A fitted peg support can now permit standing and capped walking for a biped with
one impaired leg. Existing inventory, encumbrance, injury and fatigue calculations
apply; aid/terrain availability is rechecked. Transaction/save fixtures remain
unrun. Crutches, crawling and support-loss falls remain incomplete.

Crutch mobility support now validates owned aid and hand bindings, reserves its
supporting hands and applies distinct leg/foot movement limits. Availability,
transaction and save fixtures are authored and unrun. Support-loss falls and
broader mobility cases remain incomplete.

Mobility support settlement now records resolved physical consequences, releases
the aid and sets lying posture without duplicate injury/time. Unsafe deactivation
and elapsed time with unavailable standing support are guarded. Fixtures remain
unrun; automatic loss notifications and broader integration remain unfinished.

Forced aid drops and supporting-hand injuries now record persistent mobility-loss
events. Restoring readiness does not bypass settlement. Rollback, undo, saved
pending history and real hand-wound fixtures are authored and unrun; other loss
causes still require integration.

Active mobility aid storage and sales now preserve support-loss occurrences. Authored regression fixtures cover repeated operations, exception rollback, undo and settlement before time advancement. These fixtures have not been run: all requested checks remain paused, and the expanded suite remains incomplete.

Daily hiking now has a pure full-reference terrain and weather assessment,
including roads, clearance, deep snow, skis and skates. Distance arithmetic
retains fractions until final rounding. Table and boundary fixtures are
unrun; daily travel execution and group procedures remain incomplete.

Ordinary daily hiking attempts now retain solo or shared-group rolls in every
participant's history. Duplicate attempts cannot reroll by changing IDs or
travel skills. Group assessment applies the leadership threshold, average skill
and slowest-member pace. Replay and next-day handling have authored, unrun
fixtures; a roll receipt still does not complete a journey or spend travel time.

Independent-roll hiking parties now retain a shared decision over existing solo
receipts. Their bonus requires every traveler to succeed, and their pace uses
the slowest member. Splitting or regrouping cannot create new daily rolls;
shared leadership receipts cannot be reused as independent rolls. Fixtures are
authored but unrun, and full travel execution remains incomplete.

Marching-hour fatigue now has an owned cost record, including hot-weather,
heavy-clothing and cooling adjustments, overflow injury and duplicate interval
protection. Time remains the travel controller's responsibility. Cost-table and
persistence fixtures are authored but unrun; automatic scheduling remains partial.

Continuous marching hours now own both action permission and elapsed time with
their fatigue cost. Failed effort attempts persist without rerolling; completed
hours replay without another time or fatigue charge. Fixed-condition changes
reject the transaction. Authored fixtures remain unrun; interrupted travel,
recurring consciousness checks and full-day scheduling are still incomplete.

Ordinary-object throwing now has pure full-table range and damage assessments,
including lift limits, hand requirements and ordinary/cinematic skill bonuses.
The inventory's negative half-point-per-die rounding description was corrected
against the source. Source-table and example fixtures remain unrun; pickup,
attack, catching and impact execution are still incomplete.

Held-object throwing now derives ordinary skill bonuses and attack scores from
character training, and validates readiness and owned hand bindings. Temporary
attack penalties do not incorrectly reduce training-based range bonuses.
Fixtures are authored but unrun; attack commitment and cinematic prerequisite
integration remain incomplete.

Deliberate-pass catching now has a pure source-grounded assessment for successful
lobs, Wait penalties and throw-margin bonuses, with independent catcher results.
Unsuccessful lobs and thrown attacks cannot use this procedure. Fixtures are
unrun; owned hand/parry consumption, catches and interception remain incomplete.

Throw attempts now retain the owned permission gate and one throw roll per
occurrence. Recorded deliberate passes can feed catch assessments without
rerolling; denied permission remains denied on replay. Persistence fixtures
are authored but unrun. Inventory release, maneuver time and impact remain
unfinished parts of the complete throw action.

Confirmed ordinary thrown hits now have owned damage-roll records. Fragile
objects and thrown characters use independent self-damage dice, preserved across
replay. Unresolved defenses and critical outcomes are rejected before damage RNG.
Fixtures are authored but unrun; release, protection and injury integration
remain unfinished.

Thrown release now has owned in-flight inventory state with storage, sale and
lifting exclusions. Landing settlement clears that state without duplicating
ownership or moving a retrieved item on replay. Unresolved flight blocks positive
time advancement. Fixtures remain unrun; complete action timing, catches and
impact consequences still require integration.

Recorded thrown damage can now feed owned ordinary torso wounds for the target
and a represented thrown character. Supported protection applies outer DR before
flexible armour, separates blunt injury from penetration and prevents duplicate
receipt-side injury. Fixtures remain unrun; other locations, anatomy, material
objects and complete action composition remain unfinished.

Thrown limb selection now binds arms, hands, legs or feet before the attack roll
and applies their location penalties. Recorded injury uses the same part,
including living-limb impaling adjustments, caps, severance, equipment drops and
lower-limb knockdown. Fixtures are authored but unrun; other locations, anatomy
and complete timed attack composition remain unfinished.

Throw attempts now use the full ranged critical-miss rule: a failure by ten
alone no longer blocks ordinary release as a critical failure. Catch assessments
use active-defense low-score success and critical-failure rules. The shared check
helper moved to the foundation to avoid a new module dependency. Regression
fixtures are authored but unrun; checks remain paused.

Deliberate passes now have an owned catch-roll stage connected to released
inventory and a recipient fighter's hand-parry counter. The stage applies repeated bare-hand parry penalties and checks supported
anatomy before spending randomness.
Successful catches now support an owned inventory transfer and flight settlement;
critical consequences remain pending. Regression and
persistence fixtures are authored, unrun under the check pause.

Advanced martial training now has fixed thirty-point accounting and an active
repeated-catch-parry benefit. Ordinary hand penalties accumulate by four and the
training benefit reduces that increment to two. Rapid-strike and cinematic skill
permissions remain incomplete. Added hand-counter assertions are unrun.

Catching while concentrating now records a separate contextual Will-3 check,
preserves accumulated concentration on success and clears it on failure. Catch
replay does not repeat either roll. Spell-specific interruption consequences
remain pending. New concentration and persistence assertions are authored, unrun.

Exploration now provides ordinary jump-distance assessment from B352: standing
and running formulas, independent running caps, half-skill substitution,
preparation and optional encumbrance. Distances retain tenths of an inch.
Owned preparation, movement and landing consequences remain pending. Printed
example and boundary assertions are authored, unrun while checks are paused.

Profile-backed jump assessment now validates paid skill selection, reads optional
encumbrance, supports the explicit strength/body-weight option and consumes
active enhanced-jump levels. Enhanced jumping has ten-point-per-level accounting.
Movement, jump attacks and fall protection remain pending. New expected-value
and boundary fixtures are authored, unrun while checks are paused.

Enhanced jumping now supplies an owned safe-fall receipt connected to collision
and injury resolution. Prepared maxima consider paid Jumping skill; optional
Acrobatics reuses the prior landing roll. Protected impacts use no damage dice.
Threshold, rollback, undo and saved-continuation fixtures are authored, unrun.

Enhanced-jump travel assessment now calculates speed from current ground Move
and maximum broad-jump range, retains fractional speeds and gives bounded
whole-second travel time. Actual launch distance is checked independently.
Time commitment and position changes remain pending; new assertions are unrun.

Combat jump preparation now records consecutive concentration turns through the
existing battle scheduler and health gates. Combat distance assessment derives
preparation from that record. Interruption, unrelated concentration, ledger
drift, rollback and saved continuation have authored coverage; checks remain paused.

Whole-turn jump launches now preserve prepared distance across the Move
maneuver's concentration reset and record required DX/Jumping accuracy once.
Failed accuracy leaves the actor prone; critical failure marks pending fall
consequences. Position changes and falling-damage settlement remain incomplete.
Range, outcome, rollback, undo and saved-replay fixtures are authored, unrun.

Critical jump failures now consume an authored, preflighted fall-impact plan
inside the launch transaction. Success and ordinary failure do not use it;
recorded critical outcomes validate the existing child injury on replay. Missing
plans fail before rolls. Armor, rollback, undo and saved-replay assertions are
authored, unrun. Position changes and reactive landing maneuvers remain pending.

Horizontal jump launches can now place the existing tactical figure at authored
success/failure endpoints, including the prone failure footprint. Both outcomes
are checked before dice; mapped profiles require a placement plan. Vertical and
multi-second enhanced-jump placement remain unsupported. Terrain, occupancy,
rollback, undo and saved-replay fixtures are authored, unrun.

Small ordinary obstacles now have a pure automatic-jump size test and a tactical
path entry costing one extra movement point. The entry requires Move and rejects
significant hazards, missing approval and unsupported posture/water combinations.
Boundary, additive-cost and purity assertions are authored, unrun.

Uninterrupted tactical Move paths now commit through health-aware battle turns,
including automatic small-obstacle jumps. Shared pre-posture movement arithmetic
avoids double crouching costs while retaining Lite's final movement calculation.
Replay, rollback, undo, save continuation and Lite expected-value fixtures are
authored, unrun. Reactions, interrupts and movement attacks remain pending.

Jump preparation, launch and path movement now require explicitly physical
health gates. Missing movement requirements and mental-only gates are rejected
before rolls. Exhausted permission denial has authored rollback, undo and saved
continuation coverage; assertions remain unrun while checks are paused.

The two-Move clamber alternative now records consecutive progress and places the
existing figure on an authored reachable adjacent upper surface without an
accuracy roll. Health permission remains per-turn. Occupancy, skipped turns,
rollback, undo and saved-continuation assertions are authored, unrun.

Foraging now has pure printed-result assessments for plant, hunting and fishing
yields, hunting's penalty, authored scarcity and natural-17/18 plant poisoning.
The companion health assessment distinguishes direct poison injury from damage.
Daily ownership, food inventory and party injury commitment remain pending.
Expected-value assertions are authored, unrun while checks remain paused.

Recorded plant-foraging poison outcomes now have owned self/party resolution,
independent health checks and direct-injury wounds. All possible injuries are
preflighted, duplicate exposure is rejected and replay reuses child wounds.
Special susceptibility remains explicit. Rollback, undo and save fixtures are
authored, unrun while checks are paused.

Travel-day plant rolls now have per-character ownership shared across both
eligible skills and all sites. Physical health permission precedes the roll;
replay preserves the outcome and the daily limit survives save continuation.
Full-profile paid skill definitions are required. Alternate defaults, dedicated
foraging days and food inventory remain pending. Fixtures are authored, unrun.

Travel-day fishing now commits through the shared forage operation, with a
separate animal-food allowance, Perception default and explicit equipment
assessment. Plant and fishing requests can coexist on the same day. Exact daily
boundary, default, equipment, rollback, undo and save-continuation assertions are
authored, unrun. Hunting integration and food inventory remain pending.

Ordinary loaded-weapon hunting now shares the daily animal-food allowance with
fishing. Explicit authored ammunition expenditure uses the existing weapon
ledger once on success or failure; preview and replay do not debit it. Hunting's
printed penalty and ordinary strength shortfall affect the roll. Thrown weapons,
special projectile effects and food inventory remain pending. Shared-limit,
resource, rollback, undo and saved-replay fixtures are authored, unrun.

Positive forage yields can now be claimed once into ordinary food inventory.
Inventory-backed meals debit that stock while crediting the existing daily needs
ledger. Collection does not imply cooking or preservation; edible preparation
requires explicit facts. Duplicate claims, empty stock, rollback, undo and saved
continuation have authored, unrun fixtures. Spoilage, preservation and poisoned
food consumption remain pending.

Meat and fish preservation now owns a smoking interval against a concrete fire
record. Processing locks the stock; completion preserves the same quantity and
marks it edible, while interruption and cancellation grant no preservation.
Duration and fire capacity remain authored facts. Timing, interruption, rollback,
undo and saved-continuation fixtures are authored, unrun; fuel inventory and
spoilage remain pending.

Dedicated foraging-day reservations now enable five plant and five shared
hunting/fishing rolls while blocking owned hiking and marching travel. They must
be committed at a day boundary before activity and cannot be cancelled to gain
travel after extra rolls. Next-day limits reset normally. Boundary, shared-limit,
travel-exclusion, rollback, undo and saved-continuation fixtures are authored,
unrun; external travel adapters must use the exposed scheduling restriction.

Expanded nature and survival definitions now generate terrain/world defaults
from eligible purchased skills. Plant foraging accepts these unpaid targets
through the shared resolver without granting extra attempts. Standard terrain,
planet classification and no-double-default assertions are authored, unrun.
Automatic Biology source selection and the broader wilderness procedures remain
pending.

Daily wilderness survival now records one guide's roll and up to ten dependents,
with matched terrain/world conditions, equipment and weather modifiers. Failure
commits independently rolled direct injuries through existing wounds; duplicate
daily resolution is blocked across recipients. Expected values, zero-injury
floors, rollback, undo and saved continuation fixtures are authored, unrun.

Reaction attempts now accept one explicit social-skill mastery bonus: Diplomacy
20+ supplies +2, and Fast-Talk 20+ does so when speaking is allowed. The private
encounter records its contribution once; predetermined reactions bypass it.
Threshold, eligibility, replay, rollback, undo and saved-continuation fixtures
are authored, unrun. The social guide's obsolete no-implementation statements
have been corrected; the subsystem remains partial.

Owned Administration and Carousing preparation checks now feed encounter
reactions without duplicate rolls or time charges. Carousing failure retains its
-2 modifier across changed approaches to the same audience. Health permission
precedes the check; predetermined reactions bypass preparation. Persistence and
failure-effect fixtures are authored, unrun; other skills and special failure
consequences remain pending.

Carousing preparation can now purchase authored entertainment through existing
payer/provider money balances. Its +1 to +3 bonus modifies the skill check once;
payment persists on failure and is not repeated on replay. Affordability,
conservation, rollback, undo and saved-continuation fixtures are authored, unrun.
Intoxication and venue-specific dangers remain pending.

Social preparation now rejects changed encounter state and definitions after
time advancement before it pays or rolls. This closes an intervening-reaction
gap and handles changed definition lengths explicitly. Audience, price, payment
capacity and intervening-reaction rollback/retry fixtures are authored, unrun.

Social inhibition now has fixed tier pricing, shared interpersonal-skill penalties
and the strongest tier's learning prohibition. Default use, mitigation and absent
expansion behavior retain explicit paths; already-paid affected skills at the
strongest tier are rejected pending acquisition rules. Price, score, duplicate
and Carousing integration fixtures are authored, unrun.

The emotional-understanding deficit now has fixed pricing, -3 contextual skill
penalties and incompatible-trait validation. It stacks with distinct social
inhibition penalties without duplicate application and does not prohibit skill
learning. Cost, applicability, mitigation, compatibility and Carousing fixtures
are authored, unrun.

Loss of pleasure now has fixed pricing and its four contextual skill penalties.
An explicit observer context applies the authored -1 to -3 reaction penalty when
noticeable and exposes only nonviolent adverse responses. Reaction attempts can
now consume an optional social context directly. Scope, replay and response
fixtures are authored, unrun.

Emotional obliviousness now applies its -1 to both use and resistance of the six
ordinary influence skills. The resistance hook defaults to zero and composes
with existing intimidation resistance. Actor/target, mitigation, low-score,
rollback, undo and saved-continuation fixtures are authored, unrun; the broader
expanded influence procedure remains partial.

- Added the fixed-cost callousness trait, shared Teaching penalty, authored
  helpful-psychology/victim/coercion contexts, observer-specific reactions and
  recognition by existing interrogation questions (full-2008 B125). Added
  unrun fixtures; broader trait and social coverage remains incomplete.

- Added the learning-bar disadvantage and acquisition gates for development,
  direct skill purchases, study and familiarity. Starting skills remain usable;
  approved physical advancement remains available. Technique purchases and
  modular ability integration remain pending. Added unrun persistence and
  resource-accounting fixtures (full-2008 B125).

- Added owned incremental technique purchases using the shared advancement bank,
  learning restrictions, authored approval and prerequisite trees. Technique
  scores and purchases now require explicit campaign opt-in. Authored cost,
  rollback, undo and save fixtures remain unrun (full-2008 B229-B230).

- Added contextual technique checks through the shared skill scoring and random
  stream, preserving root-skill modifiers and nested technique investments.
  Unsupported relative contexts reject explicitly. Special outcomes and the full
  technique catalogue remain incomplete; the new fixtures are unrun (B230).

- Cinematic techniques now require an explicit campaign policy for purchases
  and default use, with authored training/mastery scope and the specific ordinary
  pistol exception. Added unrun eligibility fixtures; full weapon-mastery
  integration remains pending (full-2008 B230).

- Study and familiarity practice now revalidate their targets and eligibility
  after time hooks, preventing credit after interruption or retargeting. Added
  unrun rollback, midnight-boundary and save-continuation fixtures.

- Added two speech-limitation tiers, voice-trait compatibility and pre-roll
  articulated-speech/vocalization gates. Nonverbal contexts remain available;
  authored gestures and communication study are still pending. Fixtures are
  unrun (full-2008 B125).

- Added owned player-authored gesture exchanges without skill rolls, recording
  intent and interpretation separately and charging elapsed time once. Added
  unrun interruption, undo and save fixtures. Communication-study integration
  remains pending (full-2008 B125).

- Added full-rate communication-study credit from completed gesture exchanges,
  using recorded eligibility and elapsed time without a second time charge.
  Credit shares the existing study track and rejects duplicate claims. Other
  communication channels remain pending; new fixtures are unrun.

- Study now rejects shared or duplicated training objects before awarding credit,
  including communication credit and ownership changes during elapsed-time hooks.
  Added unrun ownership fixtures and an interruption regression case.

- Interrogation questions now apply callousness's past-victim penalty from an
  explicit bound fact, alongside the existing coercion bonus. Added unrun
  integration, interruption, undo and save fixtures (full-2008 B125).
