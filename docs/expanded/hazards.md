# Expanded hazards

**Status: partial.** Exposure, poison, disease and aging. Neutral source: `full-2008`, B428-B444; B540.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-hazards.t` after the expanded foundation, expanded skills and expanded health. The current
implementation supplies infection assessments and owned acquisition receipts;
it supports a limited daily progression path. The all-module umbrella includes these capabilities
without activating any hazard.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

## Source inventory

The [environmental inventory](inventory/environmental-hazards.json) covers the
first text pass through B428–B437, excluding poison and the separately recorded
[radiation procedures](inventory/radiation.json). The
[poison, illness and aging inventory](inventory/poison-illness-aging.json) extends
the first pass through B444, including infection and dependency. Enumeration
audits, cross-references and independent numeric validation remain open. Only the explicitly linked partial entries below have runtime assessments;
the inventories do not imply complete hazard behavior.

Exposure records must identify the source, route, protection, elapsed intervals
and resulting conditions. Air composition and pressure are independent; a sealed
suit does not automatically supply oxygen, cooling or resistance to every gas.
Cold and heat also restrict recovery of their own injury and fatigue.

Collisions require both participants' structural capacities, relative velocity,
angle and surface properties. Falls have distinct armor and location rules, and
occupants may suffer a separate sudden-stop injury. Those calculations must feed
the shared health state while preserving the identities of individual impacts.

Radiation needs dated doses rather than one resettable exposure counter. Each
dose has its own delayed reduction and permanent residue; symptom sequences and
treatments have separate schedules. Removing an internal source does not remove
already absorbed radiation. Machines use their own susceptibility and failure
rules.

Poison definitions need delivery-specific effects and protection. A multi-route
agent can affect a protected respiratory system differently from exposed eyes or
skin. Delay, repeated exposure and cyclic damage are separate clocks. Treatments
must match the identified agent and change only its eligible future effects.
The mechanical catalogue uses neutral identities and abstract game doses.

Illness adds hidden acquisition and immunity, contagious periods, contact history
and restricted natural healing. Infection of a wound uses its own contamination
modifiers and surgical eligibility. These procedures must share the wound and
treatment records managed by health rather than creating parallel injury totals.

Intoxication and withdrawal require stage, consumption and daily-progress records.
Their low-target resistance rolls are explicit exceptions to the usual rejection
of impossible ordinary skill attempts. Temporary drug effects must preserve the
traits they suppress so expiry does not delete the character's original abilities.

Aging schedules depend on lifespan traits and the campaign calendar. Each event
has four ordered checks with special critical and longevity rules. Store the date
and origin of losses: rejuvenation restores age-related losses within the reversed
years, while ordinary advancement purchases and unrelated injuries remain
separately accounted.

## Unresolved supplied-source decisions

- B350 and B431 state different gravity scaling for terminal velocity. The
  selected procedure must be explicit and tested; no later revision is implied.
- B436 includes 800 rads in two adjacent effect bands. The overlap was confirmed
  in the rendered source page. Runtime range generation must wait for an explicit
  boundary policy rather than quietly choosing one row.
- Some tables give rounded measurement bands or example limits rather than a
  complete continuous formula. Supported precision and interpolation decisions
  must be documented, with unsupported combinations rejected explicitly.

These issues do not prevent inventorying other sections. They do prevent a
complete-coverage claim for the affected procedures.


## Fictional memory effects

The [setting-content inventory](inventory/setting-mechanics.json) includes a
fictional agent with resistance, unconsciousness and recent-memory effects. Its
source name and associated setting are excluded. The printed description does not
fully specify onset, unconscious duration or the anchor for its lost-memory window;
those details require a documented author contract before the effect is supported.

A memory effect must change what the affected character can recall while preserving
what actually happened in the world. It must not undo purchases, wounds, movement or
other committed events. Delivery, dose inventory, permissions and repeated exposure
also need their own validation. This entry remains pending; it is not an implemented
hazard or a real chemical specification.


## Infection assessment

`RpgExpandedInfectionContext` records the B444 contamination and treatment facts:
`infectedMatter`, `specialLocale`, `antibiotics`, `medicalTL`,
`criticalTreatmentFailure` and `untreatedDirtyWound`. The author establishes wound
exposure; the context does not infer contamination from a room name or injury.

`assessAcquisition()` returns `checkRequired` and an HT modifier of +3 plus
contamination penalties for an established untreated dirty wound. Infected matter
contributes -2 and a special-infection locale -3; ordinary dirt contributes zero.
These replace general contagion modifiers. Qualifying antibacterial care at
technology six or higher returns `prevented` without requiring a check.

A critical treatment failure blocks with
`infection-critical-treatment-adjudication`: the prevention exception needs an
explicit treatment-outcome contract before committed exposure is supported.
Lower-technology antibacterial care blocks. Unestablished exposure also blocks;
this does not assert immunity or absence of infection.

`assessTypicalProgression()` describes a typical existing infection: a daily
86400-second interval, one injury on failed HT, and an end to infection on success.
Its HT modifier includes contamination and +3 for qualifying antibiotic treatment.
The acquisition check's initial +3 is not added to the daily HT check. Special
infections may specify different procedures and are not represented by this
method. The reported injury is not capacity-scaled healing.

Both methods return `RpgExpandedInfectionAssessment` and consume no time or
randomness. They do not establish infection, secretly roll acquisition, maintain
an owned disease history, restrict recovery or apply injury. Those mechanisms
remain incomplete. The minimal fixture
[`expanded-hazards.t`](../../tests/fixtures/expanded-hazards.t) exercises the
library independently; `test_infection_assessments` covers combined modifiers,
prevention, daily treatment, unsupported cases and preview purity. Checks remain
paused, so these fixtures are unrun.


## Owned wound exposure

`RpgExpandedInfectionExposure` takes a committed expanded `wound`, a stable neutral `diseaseId`, an
`RpgExpandedInfectionContext` as `conditions`, and authored `evidence` identifying
its open-wound exposure. `assess()` performs eligibility checks without consuming
randomness. `apply()` resolves the acquisition check once through the shared HT
and disease-resistance context, or records prevention without rolling. It does
not spend additional time for discovering an exposure that already occurred.

The wound's `infectionExposure` owns the receipt. Its `acquiredAt` captures the
shared time ledger. Repeated calls return the original result; another object
for that wound is blocked. Conditions and evidence bind on commit and cannot be
changed to obtain another roll. New contamination of the same wound is currently
unsupported rather than silently treated as a fresh exposure.

The result's `infected`, `prevented` and `check` fields are private author state.
The library emits no event announcing infection; hosts must preserve hidden
acquisition until an appropriate discovery or symptom procedure permits it.
This receipt is not a symptom, diagnosis, or disease-damage record.

The module now depends on expanded health for authoritative wound ownership.
Existing disease-resistance bonuses are reused. Complete immunity, unusually low
resistance scores, critical-treatment exceptions, progression, recovery locks,
reinfection and discovery contracts remain incomplete. Acquisition rollback,
undo and save expectations are recorded in the transaction fixture below. `test_infection_acquisition`
covers resistance, infection, prevention, preview purity and repeat protection;
these authored cases remain unrun while checks are paused.


## Typical daily progression

`RpgExpandedInfectionDay` owns one daily check for an acquired infection. Supply
an episode-local unique `id`, `exposure`, `antibiotics`, `medicalTL` and
`careEvidence` describing treatment during the interval. Acquisition contamination
stays fixed; antibiotic care can change on subsequent days. Set `dropDestination`
if the possible injury requires an equipment drop.

The host advances the shared clock to each exact daily boundary measured from
`exposure.acquiredAt`. The request checks that boundary and spends no additional
time. Early requests block; missed boundaries block with
`infection-missed-boundary` rather than applying current conditions retroactively.
Automatic scheduling and historical catch-up remain incomplete.

A failed check commits one owned wound and increments the shared `diseaseInjury`
restriction. `exposure.lockedInjury` identifies this episode's contribution to that
restriction; it is not another health balance. A successful check ends the episode
and releases only that contribution. It does not heal any injury or release another
illness's restriction. Day receipts retain their outcome for idempotent replay,
and profile validation checks order, timestamps and injury contributions.

Qualified physician supervision can provide the B443/B424 bonus as described
below. Exceptional infection types, complete immunity, discovery, interruption,
other disease procedures and verified transaction/save behavior remain incomplete.
`test_infection_progression` covers an early request, failed daily check, reuse,
recovery and preservation of a separate disease-injury restriction. The fixture
is authored but unrun while checks are paused.


## Transaction and continuation fixtures

[`expanded-hazards-transactions.t`](../../tests/fixtures/expanded-hazards-transactions.t)
uses engine actions around acquisition and progression. Its inspection events
are test-only access to private state, not a player-facing discovery interface.
`test_infection_transactions` checks exceptions after each mutation, undo and
replay, changed acquisition evidence, pure assessment, and reuse after recovery.
It also calls profile history validation on the acquired, progressing and ended
episodes. The patient's separate disease restriction must survive throughout.

`test_infection_persistence` restores saves in a separate process after acquisition,
a failed day, and recovery. Each route continues to the same final balance and
reuses old receipts without spending more time or randomness. Save files retain
the exact-compiled-game policy. These fixtures are authored but unrun; they do not
establish verified persistence until checks resume and pass.


## Specific natural immunity

B443's first-attempt immunity uses `profile.diseaseResistances`, with one
`RpgExpandedDiseaseResistance` record per authored disease identifier. Use the
same `diseaseId` for exposures to the same agent, regardless of wound or location;
use a different identifier for a genuinely different disease. The host defines
these identities from its disease catalogue, not from presentation names.

The first rolled acquisition attempt records its exposure and raw roll. A natural
three or four grants specific hidden immunity. Later resistance rolls cannot
retroactively grant it. Prevention without a roll does not create a first-attempt
record. An immune patient resolves later exposure without a resistance roll;
`result.immune` distinguishes this from antibiotic prevention. Historical receipts
retain their original result even if later state changes.

The library does not announce these records. Broad immunity traits, acquired
immunity after recovery and authored physiology exceptions remain incomplete.
`test_specific_natural_immunity` covers both qualifying raw rolls, an ordinary
first success followed by a later natural three, different disease identities,
no extra randomness for immunity, and profile history validation. The fixture
is authored but unrun. `test_immunity_transactions` covers rollback and undo of
both the first-attempt record and later immune exposure, then repeats each
operation to check that it consumes no additional randomness.
`test_immunity_persistence` restores separate-process saves for natural three and
four, before and after a later exposure. It checks the original roll, immunity,
injury and random draw count, including history validation after restoration.
These fixtures also remain unrun while checks are paused.


## Physician-supported infection recovery

For a daily infection check under medical supervision, set `practice` to the
patient's existing `RpgExpandedMedicalPractice` and `continuousCare = true`.
`careEvidence` must establish qualified care for the whole daily interval. The
practice must be the patient's single assigned provider, meet its skill and
equipment requirements, remain available, and have admitted the patient no later
than the interval's start. Late admission cannot supply a retrospective bonus.

The result reports `physicianBonus = 1`, added to the recovery check together with
qualifying antibiotic and contamination modifiers (`full-2008`, B443; B424).
This bonus does not heal injury or grant another daily infection roll. The
request spends no extra time and does not advance the separate physician-check
schedule. Changing doctors or care conditions after completion does not change
the historical result; changing the request's bound inputs is rejected.

Medical rosters now retain `medicalAdmittedAt` separately from
`medicalCareSince`, which advances after scheduled physician checks. Release
clears admission; readmission starts a new care interval. This timestamp does not
certify continuous care by itself: the author must still supply the interval fact.
Automatic care scheduling and interruption remain incomplete.
`test_infection_supervision` records the combined bonus and no-spending rejection
expectations for absent continuous care, late admission and an unavailable doctor.
The fixture remains unrun while checks are paused.


## Aging calculations

`rpgExpandedAgingSchedule(shortLevels, extendedLevels)` returns maturity in years
and three `bands`, each `[startingAgeYears, intervalUnit, intervalCount]`.
The shortened-lifespan levels zero through four use the exact B154 table;
extended lifespan multiplies the normal schedule from B53/B444. Conflicting
shortened and extended inputs block. The current numeric interface supports
extended levels through ten; larger values are outside this bounded interface.

Preserve the returned `year`, `month` and `day` units in the campaign calendar.
The B154 table rounds onset ages and includes specific day intervals; repeated
fractional halving of the normal schedule is not equivalent. These calculations
do not decide birthdays, whether an anniversary has occurred, or agelessness.
An owned event must establish those facts before applying any aging rolls.

`rpgExpandedAgingModifier(medicalTL, fitness)` uses the world's medical technology
minus three and one fitness adjustment from -2 through +2. It does not infer
world medicine from carried equipment or combine mutually exclusive fitness traits.
`rpgExpandedAgingLoss(score, roll, longevity)` assesses one attribute's prospective
loss from supplied dice. Ordinary failure loses one; critical failure and raw
seventeen or eighteen lose two. Longevity uses its own raw-roll exception and
limits loss to one, including the modified-health seventeen boundary.
Ordinary scores below three remain explicitly unsupported; the longevity rule
can be assessed directly even at those scores.

The functions do not roll dice, mutate attributes, alter derived scores or
account for character points. Ordered four-attribute events, the prohibition on
luck, natural death, alternative equal-value losses and rejuvenation history
remain incomplete. `test_aging_assessments` provides source-row, rounding,
modifier and roll-boundary expectations. These fixtures remain unrun.


`rpgExpandedAgingSequence(profile, medicalTL, fitness, longevity, rolls)` assesses
four supplied rolls in strength, dexterity, intelligence and health order. It
returns `scoresBefore`, `scoresAfter`, `losses`, `rolls`, `pointLoss` and
`naturalDeath`. All four checks use the pre-event health score plus the aging
modifier: health is the final attribute in the ordered sequence. Loss is capped
at the attribute's current value, so a terminal result reaches zero rather than
creating a negative base score.

The result also exposes projected `healthCapacity`, `fatigueCapacity`, `will`,
`perception`, `speedQuarters` and `move`, preserving independently purchased
secondary adjustments. `pointLoss` uses the standard base-attribute prices;
it is a change in character value, not a charge against earned or unspent
advancement points. Skill training points remain unchanged while attribute-based
skill values will follow the base changes when an owned event is committed.

This interface is a projection. It does not change the profile, apply natural
death, enforce birthdays, replace losses with traits, or restore youth. A future
committed event must also handle invalid derived states and validate interactions
with capacity-limited traits. No luck or random helper is called by this
supplied-roll interface. `test_aging_sequence` records independent expected
losses, point values, derived characteristics, the zero-attribute boundary and
preview purity. These fixtures remain unrun while checks are paused.


## Owned aging events

`RpgExpandedAgingEvent` takes `profile`, `calendarId`, unique `boundaryId`,
`ageYears` (completed years), consecutive `ordinal`, `reached`, `evidence` and
world `medicalTL`. The author must establish that this is the next actual aging
anniversary under the selected schedule, including subannual intervals. The
engine verifies onset age, sequence, stable calendar, nondecreasing age and
unique boundaries; it does not infer elapsed calendar months from seconds.
A true `reached` flag without valid calendar evidence is not sufficient authoring.

The event reads the profile's neutral `short-lifespan`, `extended-lifespan`,
`unaging`, `longevity` and mutually exclusive fitness trait levels. Trait catalogue
and purchase validation remain separate. An ageless profile is exempt. Assessment
rejects unsupported low scores and potential invalid derived values before any
random draw. It does not apply the prospective worst-case losses.

`apply()` draws four three-die rolls directly in source order without a luck
interface. It commits the resulting base scores, marks `dead` for natural death,
and stores the full `RpgExpandedAgingSequence` in `result`. Dynamic secondary
values and attribute-based skill scores follow those base changes; independent
secondary purchases and skill points are retained. Character accounting sees the
new bases, while earned and unspent advancement balances remain unchanged.

`profile.agingHistory` owns each event and its `completedAt` timestamp. Reusing an
event returns `reused` without another roll, mutation or time charge; its original
sequence remains accessible through `event.result`. Changed bound inputs and
reused boundary identities are rejected. The event observes an already reached
calendar boundary and does not spend calendar time again.

Automatic calendar scheduling, trait substitutions, rejuvenation, capacity-limited
trait interactions and verified aging transaction/save behavior remain incomplete.
`test_aging_events` covers a normal event, a terminal low attribute, unchanged
advancement balances, pure preview, repeated execution and rejected calendar facts.
All fixtures remain unrun while checks are paused.


The dedicated
[`expanded-aging-transactions.t`](../../tests/fixtures/expanded-aging-transactions.t)
includes character accounting to check the effect on total point value.
`test_aging_transactions` exercises preview, exception rollback, undo, deterministic
replay, duplicate calendar boundaries, changed bound facts and history validation.
`test_aging_death_transactions` checks that rollback and undo also restore a living
profile after a terminal result. The tests assert that earned and unspent points
are unchanged throughout.

`test_aging_persistence` restores saves made before and after both ordinary aging
and natural death in a separate process. It continues or reuses the same event and
checks attributes, character cost, death state, history, randomness and shared
time. These fixtures use the exact compiled game and remain unrun while checks
are paused; they are not a verified compatibility claim.


## Restoring recorded youth

`RpgExpandedRejuvenation` applies the attribute-restoration consequence of an
already established youth-restoring effect (`full-2008`, B444). Supply unique `id`,
`profile`, `calendarId`, `oldAgeYears`, `newAgeYears` and `effectEvidence`. The
source of the effect, its costs and the character's actual calendar age remain
world facts managed by the host. This request neither casts a spell nor operates
a device, and does not charge their resources again.

Assessment selects all unrestored aging events strictly between the new whole-year
age and the supplied old age. A same-year boundary blocks with
`rejuvenation-partial-year-unavailable`: current records do not distinguish the
within-year timing needed for a partial restoration. An unexplained earlier age,
calendar mismatch, missing effect evidence, duplicate identity or dead patient
also rejects or blocks. Resurrection is not implied by age restoration.

Execution adds each selected event's actual recorded losses to the current base
attributes. It therefore preserves later purchased improvements instead of
resetting scores to an old snapshot. Each event records `restoredBy`; a later
request cannot restore it again. The receipt reports `gains`, `pointGain` and
`restoredEvents`. Character value rises through the changed bases, with no refund
or charge to earned or unspent points and no random roll or time expenditure.

`profile.rejuvenations` owns the receipts. Subsequent aging events record a new
`era` and may begin again at a lower age; calendar boundary identities and global
aging ordinals still cannot be reused. Old aging results stay immutable. Their
restoration links preserve the distinction between historical loss and current
character state.

This whole-year implementation does not restore trait substitutions or support
partial-year cutoffs or automatic age tracking. Transaction and save
fixtures are authored but still require execution. `test_rejuvenation` covers a real attribute advancement
purchase between aging and rejuvenation, retained point spending, preview purity,
repeated requests, a second aging/restoration cycle and the ambiguous-year gate.
The fixture is authored but unrun while checks are paused.


`test_rejuvenation_transactions` exercises exception rollback, undo and replay of
restoration after an actual paid attribute improvement. It rejects changed bound
evidence and duplicate request identities, then repeats aging and restoration in
a new era to ensure old losses cannot be restored twice. Character-cost queries
also validate the history and retained advancement spending.

`test_rejuvenation_persistence` restores separate-process saves before restoration,
after restoration and after the next aging event. All routes reach the same base
score, character value, advancement balances and restoration links without extra
randomness or time. The fixture uses the existing exact-game save policy. These
expectations remain unrun while checks are paused.


## Ambient cold assessment

`rpgExpandedColdWeather(effectiveF, windMph, clothing, wet, lowerComfortF)` returns
whether a check is needed, the interval, modifier and one-fatigue failure cost
from B430. Clothing is `light`, `winter`, `arctic` or `heated`; a heated suit must
actually function. Wind thresholds are inclusive at ten and thirty miles per
hour. Temperature penalties use complete ten-degree increments below zero.
Inputs are whole degrees Fahrenheit and whole miles per hour. Ordinary armor
protection is not a substitute for insulating or heated clothing.

`RpgExpandedColdContext` adds `profile`, `temperatureEvidence` and optional
`survival`. The author supplies effective wind-chill temperature and the actor's
lower comfort threshold; 35 degrees is the default. The source provides no
wind-chill conversion formula. Temperature tolerance, unusual physiology and
protective equipment must be established separately by the author.

For cold that requires a roll, `assess()` chooses the better effective score from
HT and HT-based arctic survival. The skill must be an expanded average,
perception-based `survival` definition with `specialty = 'arctic'`. The expanded
skill context rebases its relative level onto HT and retains contextual modifiers.
This is why hazards now requires expanded skills. An equal score selects HT;
a missing legal skill score leaves the HT option available. Unsupported low
scores reject before rolling.

These are pure assessments. Owned exposure intervals, changing weather, fatigue
and injury commits, shelter-dependent recovery and thermal shock remain pending.
They do not clear another climate episode's recovery restriction. The source and
integration expectations in `test_cold_assessments` include wind boundaries,
clothing combinations, subzero increments, comfort thresholds and a character
whose perception exceeds HT. Fixtures remain unrun while checks are paused.


## Owned cold intervals

`RpgExpandedColdExposure` extends the cold context with a unique `id` and owned
history. `start()` records the current shared time and binds unchanged conditions;
one active cold exposure is permitted per character. Repeated starts do not reset
the clock. Changing bound weather, clothing or survival inputs is rejected.
Weather transitions and partial-interval carryover remain unsupported.

For each due boundary create `RpgExpandedColdInterval` with unique episode-local
`id` and `exposure`. The host advances time once; `apply()` checks the exact
boundary without charging it again. Failure uses the shared fatigue function and
adds the loss to `temperatureFatigue`. The episode's `lockedFatigue` records its
contribution to that restriction, not another fatigue balance. Repeated interval
requests return their receipt. Early or missed boundaries block, and finishing
an episode cannot skip an already due interval.

`finish(shelter, heatSource, evidence)` requires both adequate shelter and a heat
source. It releases only this episode's temperature recovery restriction and
ends the exposure; it does not restore fatigue or remove another source's lock.
Normal recovery can then restore eligible fatigue. Historical receipts remain
available after the episode ends.

Overflow injury now uses the owned wound path described below. Thermal shock,
changing conditions, automatic scheduling,
and verified cold transaction/save behavior remain incomplete.
`test_cold_intervals` records expected timing, failure cost, repeated use, history
validation, missing-heat rejection and preservation of another temperature lock.
The fixture remains unrun while checks are paused.


At zero fatigue or below, cold-interval assessment prepares a one-point owned
wound. Set the interval's `dropDestination` if its possible consequences require
an equipment drop. Any unsupported wound consequence blocks before the cold roll.
Failure applies the wound and the shared single-point fatigue increment; fatigue
stops at the existing negative-capacity limit while further failed cold checks
can still cause injury. Collapse uses the existing fatigue-collapse flags.

`temperatureInjury` and `temperatureFatigue` receive the committed amounts.
The exposure records its own contribution to each restriction; shelter and heat
release both contributions without healing injury, restoring fatigue or clearing
another episode's locks. A successful cold check discards the prepared wound.
The Lite fatigue function retains its original injury-before-increment order and
end-of-call collapse logic; only the single-point increment arithmetic is shared.
This intended compatibility still requires the paused regression suite to run.

`test_cold_overflow` records expected behavior at zero fatigue, just above the
negative-capacity limit and at that limit, plus successful resistance, repeat
protection and recovery restriction ownership. These fixtures remain unrun.


The dedicated
[`expanded-cold-transactions.t`](../../tests/fixtures/expanded-cold-transactions.t)
exercises engine transactions around fixed-condition exposure, overflow injury and
shelter release. `test_cold_transactions` covers duplicate active exposure,
changed bound weather, early and due boundaries, preview purity, an unresolved
check before shelter, exception rollback, undo, deterministic replay and history
validation. It preserves separately authored temperature fatigue and injury
restrictions while releasing only the tested episode's contributions.

`test_cold_persistence` restores separate-process saves immediately after exposure
starts, at the first due boundary, after overflow and after shelter release. Each
route reaches the same fatigue, injury, restrictions, receipt history, random draw
count and shared time. Historical interval receipts remain reusable after shelter.
These fixtures are authored but unrun while checks are paused; the exact compiled
game is required for continuation.
