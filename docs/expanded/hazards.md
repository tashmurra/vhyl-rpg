# Expanded hazards

**Status: partial.** Exposure, poison, disease and aging. Neutral source: `full-2008`, B428-B444; B540.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-hazards.t` after the expanded foundation, expanded skills and expanded health. The current
implementation supplies partial infection, aging, rejuvenation, cold, immersion
and airless-exposure procedures, plus heat assessments. The all-module umbrella includes these capabilities
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


## Heat outcome and exertion assessments

`rpgExpandedHeatExertion(effectiveF, upperComfortF)` returns the B434 extra fatigue
for exertion or dehydration: zero at or below the upper comfort limit, one up to
thirty degrees above it, and two up to sixty degrees above it. Whole-degree
Fahrenheit inputs preserve the printed human boundary examples while allowing
an authored comfort range. Beyond the highest supplied band, the assessment
blocks with `heat-exertion-band-unavailable`; it does not extrapolate a surcharge.
This helper does not write `profile.heatExtra` or charge an exertion action.

`rpgExpandedHeatOutcome(score, roll, strokeDie)` returns the fatigue cost of a
supplied heat-resistance check. Success loses none, ordinary failure one, and
critical failure the supplied one-die result. `heatStroke` identifies the latter.
The die is required only on critical failure. A raw seventeen at a high enough
score remains an ordinary failure, following the shared check classification.
The helper does not spend fatigue, apply overflow injury or draw randomness.

Owned heat intervals, HT-based desert survival, encumbrance, shade/activity,
cooling-dependent recovery, intense heat and extra exertion spending remain
incomplete. B434 states a penalty for each additional ten degrees of heat without
an explicit reference temperature in that sentence. The implementation has not
selected an anchor for this modifier; source clarification or an explicit authored
rule selection is required before that assessment can claim coverage.
`test_heat_assessments` covers the supplied surcharge bands, shifted comfort
limits, unsupported high temperatures, ordinary and critical failures and pure
outcomes. All fixtures remain unrun while checks are paused.


## Icy immersion assessment

After the author establishes sudden icy immersion, call
`rpgExpandedThermalShock(drySuit, score, roll)`. A fully waterproof dry suit
returns `ordinaryCold = true`: assess ordinary cold with the actual conditions
instead. This branch needs no supplied resistance roll. Without that protection,
the interval is sixty seconds and the supplied HT check receives no clothing
modifier. Success costs one fatigue; failure costs its positive failure margin,
including critical failure. Drowning requires its own assessment.

Automatic failure on seventeen or eighteen can occur without a positive failure
margin at high scores. The supplied passage does not specify the fatigue cost in
that case; the helper returns `thermal-shock-forced-failure-margin` rather than
inventing a minimum or granting fatigue. This remains an unresolved inventory
case. The assessment neither charges fatigue nor starts an exposure. The owned
procedure below supports owned fatigue loss and overflow injury; drowning
integration remains incomplete. `test_thermal_shock_assessments` records the expected outcomes,
dry-suit routing and purity; it remains unrun while checks are paused.


## Owned immersion and rescue

Create `RpgExpandedImmersion` with a unique `id`, an expanded `profile` and
`evidence` establishing icy immersion without a waterproof dry suit. Breathing
must be handled separately by the author. Call `start()` once; repeated calls
reuse the same start time. A character cannot start ordinary cold exposure while
immersed, or start immersion during an active ordinary cold exposure. This
prevents two schedulers charging the same exposure.

Create a distinct `RpgExpandedImmersionInterval` for each minute, with a unique
`id` and the `exposure`. Call `assess()` or `apply()` at exactly the next sixty-second
boundary on the shared clock. Assessment spends no time, resources or randomness.
Execution checks HT with the shared temperature context, charges the outcome's
fatigue once, and records the interval. It adds the same amount to the exposure's
owned recovery restriction and the character's existing `temperatureFatigue`.
Replaying an interval returns its receipt, including after rescue.

Before randomness, assessment prepares one-point owned wounds for every possible
overflow point. The maximum loss is eighteen minus the effective resistance score.
Each possible wound must be supported by the health module; set `dropDestination`
on the interval if its consequences require an equipment drop. Execution applies
only the needed wounds, before each corresponding fatigue increment, and preserves
the shared fatigue floor and collapse behavior. The result distinguishes
`requestedFatigue`, charged `fatigue`, actual `injury` and committed `wounds`.
Unused prepared wounds are discarded. Death prevents subsequent injury, following
the shared fatigue procedure; the remaining fatigue increments still respect the
existing floor.

The exposure owns both `lockedFatigue` and `lockedInjury`; warming releases its
contribution to `temperatureFatigue` and `temperatureInjury` without healing either.
A check still rejects scores of seventeen or more because an automatic failure
can have no positive failure margin. This remains an explicit incomplete source
case. No automatic catch-up is available for missed minutes.

`leave(evidence)` ends immersion without restoring fatigue or releasing its recovery
restriction. Resolve any due minute before leaving. The author may then begin an
ordinary cold exposure using the actual air, clothing and wind conditions.
`warm(shelter, heatSource, evidence)` requires the character to have left the
water and have both shelter and heat. It releases only that immersion's recovery
restriction. It neither heals the character nor clears restrictions from another
exposure. Multiple exited episodes retain separate restrictions until warmed.

`RpgLiteClimate.advance()` now calls `profile.validateClimateAdvance()` before any
mutation. Its default is inert. With the hazards module installed, it rejects an
active expanded cold or immersion exposure, or an unwarmed immersion restriction,
because the Lite climate procedure resets global temperature restrictions. Use
one scheduler for the character. The guard does not add random draws or time.

`test_immersion_intervals` covers success, failure margins, repeat protection,
exit and warmth. `test_immersion_overflow` covers crossing zero fatigue, the
fatigue floor, successful resistance that still loses fatigue, death during an
overflow sequence and unsupported wound preflight. `test_immersion_scheduler_conflict`
covers duplicate climate ownership. The dedicated
[`expanded-immersion-transactions.t`](../../tests/fixtures/expanded-immersion-transactions.t)
adds preview, exception rollback, undo, replay and cross-process save continuation
fixtures for exposure, its due boundary, multi-point fatigue and overflow injury,
exit and warming. All these
fixtures are authored but unrun while checks are paused. Existing Lite regressions
must verify the default dispatch hook when checks resume.


## Complete air deprivation

`RpgExpandedAirlessExposure` supports an ordinary respiratory system completely
deprived of air, starting with no remaining breath reserve. Supply a unique `id`,
an expanded `profile` and `evidence` establishing those facts. It does not infer
air deprivation merely from being underwater. Partial-air drowning, breathing
exemptions, altered physiology and the handoff from an earlier held breath remain
incomplete; do not use this procedure as an approximation for them.

`start()` records the shared-clock boundary. For each following second, create a
`RpgExpandedAirlessSecond` with a unique `id` and its `exposure`. Advance the
shared clock once in the enclosing action, then call `apply()` at that boundary.
Assessment rejects early or missed boundaries and prepares any possible owned
overflow wound before drawing randomness. Set the second's `dropDestination`
when the health procedure requires it. Execution charges one fatigue, respecting
the shared floor, and applies one-point overflow injury before that increment.
At zero fatigue or less, a conscious survivor checks Will each second; failure
sets the existing unconsciousness and fatigue-collapse flags. At 240 accounted
seconds the character dies irrespective of remaining fatigue or health.

`profile.airClock` is the existing air ledger. The exposure's receipts establish
which seconds it contains; there is no second independent air balance. Repeating
a second reuses its receipt. The result records charged `fatigue`, actual
`injury`, the owned `wound` and any `consciousness` check. Exposure ownership blocks
Lite suffocation, rest recovery and starting another breath reserve, including
at the initial boundary before the first second has elapsed.

`assessAir(evidence)` previews rescue; `resumeAir(evidence)` commits restored clean
air after every due second has been resolved. Rescue at the same boundary as the
last accounted second is allowed, but a dead character cannot be rescued by this
operation. More than 120 accounted seconds requires one HT check; failure reduces
base intelligence by one. Existing secondary offsets remain intact and earned
or unspent advancement points are unchanged. Cases that could take intelligence,
will or perception below one are explicitly unsupported before the check. A
repeated rescue cannot repeat the loss or reset another exposure's air clock.

Successful rescue resets `airClock` and releases exposure ownership. It restores
no fatigue or health. Existing rest recovery and fatigue-collapse awakening then
apply; this does not substitute for drowning resuscitation. Unsupported reserve
handoffs must not reset the deprivation history. The no-reserve restriction is
part of this implementation's scope, not a rule removing the ability to hold
one's breath.

`test_airless_seconds` covers reaching zero fatigue, successful and failed
consciousness rolls, overflow injury, the fatigue floor and repeated operations.
`test_airless_duration` records the 120/121-second brain-injury boundary and the
239/240-second death boundary, using an enlarged fatigue capacity to isolate the
time rule. `test_airless_scheduler_conflict` covers competing suffocation and rest
operations. All fixtures are authored but unrun while checks are paused. The dedicated
[`expanded-airless-transactions.t`](../../tests/fixtures/expanded-airless-transactions.t)
adds rollback after exposure start, consciousness loss and rescue, plus undo and
replay. It checks preview purity, changed bound evidence, rest rejection without
air, normal fatigue recovery after rescue and breath ownership in both directions.
Historical rescue calls must not clear a newly started breath reserve.

`test_airless_persistence` saves at exposure start, a due second, after consciousness
loss and after rescue. `test_airless_brain_persistence` saves before and after the
permanent intelligence-loss check. Each route must preserve the original receipt,
shared clock and random-draw count; resuming a completed rescue cannot repeat its
IQ loss. These fixtures remain unrun. Drowning, breath-reserve handoff, exceptional
physiology and broad cross-module verification remain outstanding; the partial
mappings do not claim full suffocation coverage.


## Radiation dose history and table assessments

`RpgExpandedRadiationDose` records one received dose from `full-2008`
B435. Supply `id`, expanded `profile`, concrete `source` identity, `rads`,
`approved` and evidence for the received amount. `radDenominator` defaults to one;
set it explicitly when `rads` is the numerator of a fractional received dose. `apply()` records `receivedAt`
on the common clock and installs the dose in `profile.radiationDoses`. It does
not charge exposure time, perform a resistance check or apply symptoms. The
source dose must already account for shielding and tolerance; those calculations
are not implemented by this recording interface. Replay preserves the original
dose and date, and changed definitions are rejected.

`remainingQuantity()` and `rpgExpandedRadiationTotal(profile)` assess the
remaining dose as exact fractions without consuming history. The older
`remainingTenths()` and `rpgExpandedRadiationTotalTenths(profile)` conversions
reject values that cannot be represented exactly in tenths. Every dose has its own recovery epoch.
After thirty elapsed days, each further whole day removes ten rads until ten
percent of that dose remains. Exact fractions preserve the permanent residue even below one tenth of a rad. This daily boundary policy does not interpolate
partial days. `rpgExpandedRadiationRemainingTenths(originalRads, elapsedDays)`
exposes the arithmetic; the printed 200-rad example reaches twenty rads after
48 days. Dose reduction does not heal injury or reverse symptoms.

`rpgExpandedRadiationBand(rads)` returns the B436 HT modifier and four outcomes
in critical-success, success, failure, critical-failure order. The neutral outcome
identifiers are `none`, `burns`, `blood`, `digestive`, `terminal` and `acute-brain`.
`rpgExpandedRadiationOutcome(health, rads, modifier, roll)` selects one using a
supplied roll. It consumes no randomness and executes no syndrome. `none` means
no obvious effect, not erasure of the dose history.

The supplied printing assigns 800 rads to two overlapping bands. Exactly 800
returns `radiation-eight-hundred-overlap`; no later-printing correction is
silently applied. Other printed whole-rad boundaries are implemented. Fractional
accumulated totals cannot be passed into this whole-rad lookup by silently
rounding: their band-selection policy remains unresolved.

The [dose fixture](../../tests/fixtures/expanded-radiation.t),
`test_radiation_doses` and `test_radiation_tables` specify row boundaries, all four
outcome columns, the printed recovery example, permanent residue, independently
aged doses, preview, rollback, undo, replay and cross-process continuation.
They are authored and unrun. Exposure scheduling,
living/machine resistance cadence, all syndrome execution, treatment, reproductive
consequences and protection still prevent complete radiation support.


### Shielding and received exposure

`rpgExpandedRadiationProtection(sample)` implements only the B436 reference
samples: half-inch lead, one-and-a-half-inch steel and 750 yards of air each have
PF 2; one yard of water has PF 8, earth PF 27 and concrete PF 64. Identifiers are
`lead-half-inch`, `steel-one-and-half-inches`, `air-750-yards`, `water-one-yard`,
`earth-one-yard` and `concrete-one-yard`. Unlisted thicknesses are not interpolated.

`rpgExpandedShieldedRadiation(incidentRads, protection, spectrum)` returns an
exact `numerator`/`denominator` ratio, `wholeRads` and `fractional`. Spectra are
`ordinary`, `solar-belt` (PF multiplied by twenty), and `cosmic` (PF divided by
one hundred). No fractional dose is rounded to zero or silently rounded upward.
The source does not specify how a resulting PF below one should behave; cosmic
protection below 100 returns `radiation-subunit-protection-unresolved` rather than
inventing amplification or a minimum-protection rule.

`RpgExpandedRadiationExposure` links a shielding result to the existing
dose ledger. Supply `id`, `profile`, `source`, `incidentRads`, `protection`,
`spectrum`, `approved` and evidence for the source/path shielding. `assess()` is
pure; `apply()` creates exactly one received dose and retains its exposure receipt
in `profile.radiationExposures`. It spends no exposure time again. IDs share the
dose namespace, so a separate manually recorded dose cannot duplicate that ID.
Replay changes neither dose nor recovery epoch.

The recorder retains whole and fractional results as reduced exact ratios.
Overlapping shielding materials, treatment effects, syndrome checks and
source-specific exposure cadence remain pending; this interface does
not imply they were applied. `test_radiation_shielding` and
`test_radiation_exposures` specify reference factors, spectra, exact ratios,
blocked cases, preview, rollback, undo and replay. They are authored and unrun.


### Exact fractional radiation quantities

`RpgExpandedRadQuantity` has integer `numerator` and `denominator` fields.
`rpgExpandedRadQuantity(numerator, denominator)` constructs a reduced,
nonnegative ratio. Its `tenths()` method returns an integer only when conversion
is exact; otherwise it raises `radiation-finer-than-tenth`. Never discard the
remainder to force a dose into the current whole-rad effects table.

`RpgExpandedRadiationDose.rads` is the numerator and `radDenominator` defaults to
one, preserving existing whole-rad declarations. The supported numerator range
is one through 100 million and denominator range one through 20 million.
`rpgExpandedRadiationRemainingQuantity(numerator, denominator, elapsedDays)`
implements the same daily recovery and exact ten-percent floor for these ratios.
Its arithmetic checks the recovery floor before multiplying by elapsed days.

`rpgExpandedAddRadiation(left, right)` and `rpgExpandedRadiationTotal(profile)`
reduce fractions and check arithmetic capacity. An unsupported numerator or
common denominator raises `radiation-quantity-capacity` rather than wrapping or
rounding. This is an implementation bound, not a new exposure rule. Shielded
exposure recording normalizes the received ratio into one owned dose.

`test_fractional_radiation` specifies half- and third-rad exposures, their
five-sixths total, the permanent one-twelfth residue, and rollback, undo, replay
and cross-process continuation. Pure cases also cover fractional residues,
large elapsed periods and refused lossy conversion. They remain unrun. The
fractional-dose storage gap is now addressed; fractional effects-table selection,
exposure checks and symptom execution remain pending.


### Trait resistance after shielding

The foundation's `profile.radiationDivisor()` returns one. Including the traits
module enables `RpgExpandedRadiationResistance`: exposure assessment applies its
active divisor after artificial shielding and spectrum adjustments (`full-2008`,
B79; B436). `rpgExpandedDivideRadiation(quantity, divisor)` cancels common factors
before multiplication and rejects quantities outside the dose ledger's capacity.

The result's `numerator` and `denominator` describe shielding alone;
`resistanceDivisor` records the trait factor, and `dose.rads` with
`dose.radDenominator` records the final received quantity. Direct dose declarations
already represent received radiation and are not divided again. Replaying a
committed exposure retains the original dose even if the trait later changes.
`test_radiation_traits` covers the nine factors and costs, inactive and mitigated
traits, exact fractions, replay and modifier rejection. It remains unrun.


### Preventive medication

`RpgExpandedRadiationPreventive` is an inventory item with technology level seven
and a reference price of 500 per dose (`full-2008`, B436). Set an item ID, quantity
and authored weight. Use the equipment acquisition interface when purchasing it;
administering an already-owned dose does not charge money again.

`RpgExpandedRadiationPrevention` records an administration. Supply a unique `id`,
`profile`, owned `medicine`, `approved` and concrete `administrationEvidence`.
The evidence confirms that administration is possible and has occurred at the
current shared clock; the source specifies no administration action duration.
The operation consumes exactly one dose, removes an empty stack from inventory,
and retains the receipt in `profile.radiationPreventions`. Preview spends nothing.
Apply inside an engine action transaction. Duplicate ownership, altered receipt
bindings, unavailable supplies and a dead patient are rejected or blocked.

New shielded exposures receive a further divisor of two from 3,600 through
10,800 elapsed seconds, inclusive. The exposure result records this factor as
`preventiveDivisor`; the final dose also incorporates shielding and trait
resistance. Direct received-dose records are not reduced again. Existing doses
and their recovery dates remain unchanged. Expiry is derived from the clock,
so no timer callback or second resource ledger is required.

An administration while an earlier administration is at most three hours old is
blocked as an unsupported overlap, even during its first hour. This is an explicit
implementation restriction, not a claimed reference prohibition. Replay retains
the original timestamp and never consumes additional stock. Procurement and
administration of a new dose must be separate from replaying an old receipt.

`tests/fixtures/expanded-radiation-prevention.t` is the minimal integration fixture.
`test_radiation_prevention` specifies both timing edges, exact single-dose use,
preview, rollback, undo, nonretroactivity and cross-process saved continuation.
These cases are authored and unrun. Chelation, advanced resistance treatment,
syndrome execution and broader radiation treatment remain incomplete.


### Advanced radiation resistance treatment

`RpgExpandedRadiationRepairMedicine` represents the technology-nine medication
or cell-repair dose in `full-2008`, B436. Its reference unit price is 1,000;
authors supply its inventory ID and weight. Purchase uses ordinary acquisition.
`RpgExpandedRadiationResistanceTreatment` accepts this medicine and the same
administration fields as preventive treatment. It consumes one owned dose through
the shared administration path, retaining its receipt in
`profile.radiationResistanceTreatments`. The inherited failure reasons use the
`radiation-prevention-` prefix. Preventive and advanced medicines have distinct
classes and cannot substitute for each other.

Use `RpgExpandedRadiationContext` with `rpgLiteScore` or `rpgLiteCheck` for a
radiation HT check. Its `attribute` is `rpgHT`, `kind` is `radiation`, and `skill`
must remain nil. Set `modifier` to the applicable table or circumstance modifier;
do not add the treatment bonus manually. The context adds the active treatment's
+3 once through normal score calculation, alongside existing health effects.
Ordinary HT contexts receive no bonus. The pure supplied-number
`rpgExpandedRadiationOutcome` helper does not inspect profiles or treatments.

The bonus begins at administration and expires at 1,209,600 elapsed seconds
(fourteen days); the exact expiry instant is outside the course. An earlier
course must expire before a new course can be administered. Overlapping courses
are explicitly unsupported rather than stacked. Replaying a receipt neither
extends its duration nor consumes stock. This treatment changes neither received
doses nor their recovery dates, and does not execute radiation symptoms itself.

`tests/fixtures/expanded-radiation-treatment.t` and `test_radiation_treatment`
specify the +3 scope, both sides of expiry, repeat administration, insufficient
technology, missing evidence, preview, rollback, undo and saved continuation.
They are authored and unrun. The underlying preventive-treatment fixtures remain
part of the required regression coverage after the shared-path refactor.


### Removing internal fallout

`RpgExpandedInternalFallout` records an internal source separately from absorbed
radiation. Supply a unique `id`, `profile`, `approved` and evidence of the
contamination, then apply inside a transaction. Its receipt is owned by
`profile.internalFallout`. Recording contamination does not invent a dose rate or
retroactively add received radiation. Further ingestion while a burden remains
active is explicitly unsupported; a new burden can be recorded after removal.

`RpgExpandedFalloutMedicine` costs 500 per dose at technology seven;
`RpgExpandedAdvancedFalloutMedicine` costs 500 at technology eight. Use ordinary
inventory acquisition and authored package weights. `RpgExpandedFalloutTreatment`
uses the shared administration fields, plus `contamination` and `advanced`.
The selected medicine class must match the requested treatment. Applying consumes
one owned dose and records it in `profile.falloutTreatments`. A burden supports
one treatment; repeated or replacement courses are explicitly unsupported.

The source fraction follows `full-2008`, B436:

| Treatment | Elapsed time | Remaining exposure fraction |
| --- | --- | --- |
| Basic | Less than three days | 1 |
| Basic | Three days through just before seven days | 1/2 |
| Basic | Seven days onward | 0 |
| Advanced | Less than twelve hours | 1 |
| Advanced | Twelve hours onward | 0 |

`rpgExpandedFalloutFraction(advanced, elapsedSeconds)` is the pure schedule helper.
`contamination.fraction()` derives the current fraction from its owned treatment
receipt. Expiry requires no timer callback. Earlier received doses continue their
independent recovery and permanent residue; removal never deletes them.

`RpgExpandedFalloutRelease` records an authored instantaneous release from that
source. Supply `id`, `contamination`, baseline dose `numerator` and `denominator`,
`approved` and evidence. The baseline is before source removal and personal
protection. Assessment applies the source fraction, radiation-resistance trait
and preventive-medication factor using exact arithmetic. Outer shielding is not
applied to an internal source. Applying commits one shared received dose, or a
zero-release receipt after removal, in `profile.falloutReleases`. Replay retains
the original outcome even after treatment progresses. Preview spends nothing;
all mutations belong in an engine transaction.

This release interface is for an exposure at the current clock. Do not use an
endpoint fraction to reduce a dose accumulated across a treatment boundary.
Continuous source-rate integration and automatic exposure scheduling remain
pending. The source's rate and world facts must be supplied explicitly, and no
source-check cadence or syndrome execution is implied by a received-dose record.

`tests/fixtures/expanded-fallout.t` and `test_fallout_treatment` specify both sides
of each treatment boundary, retained absorbed radiation, single-dose consumption,
preview, rollback, undo, replay and saved continuation. They are authored and unrun.


### Owned living-subject radiation checks

`RpgExpandedRadiationCheck` records a source-specific check from `full-2008`, B436.
Supply a unique `id`, committed `triggerDose`, `approved` and `exposureEvidence`
confirming a currently exposed living subject to whom the living-subject table
applies. This contract does not select machine or other nonhuman effects. The
trigger dose supplies the profile and source identity; the check reads the
profile's total current accumulated dose, including other sources.

For an initial acute exposure, apply at the same ledger instant as the dose.
Set `continued = true` for author-confirmed continued exposure. That evidence is
required even if the trigger dose is older: the record alone does not establish
that a source is still irradiating the character. Each source can use at most one
check per ledger day. Days are fixed 86,400-second buckets from ledger epoch zero;
this is the engine's day-boundary convention for the printed daily restriction.
Separate repeated acute exposures from the same source and delayed initial
checks remain explicitly unsupported. Source identities must represent the same
physical source consistently across dose records.

`assess()` is pure. Below-one-rad totals, fractional effects-table bands, the
800-rad overlap and unavailable scores block before randomness. Otherwise the
check uses `RpgExpandedRadiationContext`, including active advanced treatment,
and the accumulated-dose table modifier. Applying rolls once, stores the selected
outcome and adds the receipt to `profile.radiationChecks`. Replay returns the saved
roll and pending-consequence flag without rerolling or spending time. Definitions
are bound to their receipt, and duplicate IDs are rejected.

A no-effect outcome is `resolved` and retains every dose. Other outcomes return
`awaiting-consequences`, with `consequencesPending = true` and an `effect`
descriptor. This is deliberately an incomplete medical procedure: it records the
mandatory roll, but does not yet apply the syndrome's delayed injuries, symptoms,
trait changes or recovery. Authors must not treat that status as completed care.
Automatic exposure scheduling and the syndrome executor remain pending.

`tests/fixtures/expanded-radiation-check.t` and `test_radiation_checks` specify
preview purity, exception rollback, undo, source/day throttling, treatment
integration, pending syndrome status, replay, saved continuation and blocked
fractional/overlapping bands. The cases are authored and unrun.


### Delayed radiation burns

`RpgExpandedRadiationBurn` implements the initial category-A onset in `full-2008`,
B436. Supply a unique `id`, the committed `radiationCheck` whose `effect` is
`burns`, and any `dropDestination` required by the shared wound pipeline. Call
`schedule()` at the same clock instant as that initial acute exposure and its
check. The episode snapshots HT and schedules onset that many hours later;
`assessSchedule()` is pure. The profile owns it in `radiationBurns`.

The shared clock rejects advancement past a pending onset for a living patient.
At exactly `onsetDue`, `assess()` preflights every possible injury from one through
six against the current wound rules, including knockdown and equipment drops.
`apply()` rolls one die and commits the resulting `RpgExpandedWound`. Use an
engine action transaction so injury, random draws, equipment changes and the
symptom receipt roll back together on an exception. Replay retains the wound.

The onset operation follows the printed order: apply the injury with the existing
pain traits, then gain the temporary pain effect. If pain resistance was active
at onset, suppress its effective level for one week. Otherwise supply an effective
pain-sensitivity level of one for that week. Purchased trait objects and costs do
not change. The effect begins at `onsetAt` and expires at 604,800 elapsed seconds;
normal trait lookup resumes at the expiry instant. Subsequent injuries use the
health module's pain-sensitive pipeline where applicable.

The result is `awaiting-recovery`, with `recoveryChecksPending = true`. The parent
radiation check still has pending consequences: the recovery operation below resolves the
two specified HT checks and their lasting conditions. This onset implementation
does not mark the whole syndrome complete. Continued-exposure onset epochs,
higher syndromes that inherit these symptoms, and overlapping burn episodes
remain explicitly unsupported. A dead patient does not hold the shared clock at
the onset boundary and cannot receive this living-patient onset operation.

`tests/fixtures/expanded-radiation-burn.t` and `test_radiation_burns` specify
scheduling preview, deadline protection, preflight, exception rollback, undo,
shared injury, temporary trait behavior, replay and cross-process continuation.
The fixtures are authored and unrun.


### Radiation-burn recovery consequences

`RpgExpandedRadiationBurnRecovery` implements the two independent recovery checks
in `full-2008`, B436. Supply the `episode`, `approved`, concrete `recoveryEvidence`
and a prepared `terminalCondition` owned by the same profile. The terminal object
must include an approved, meaningful one-year calendar definition; it is only
acquired if its check critically fails. All possible outcomes are preflighted
before dice, including character creation completion and terminal eligibility.

The onset must have committed and the patient must be alive with zero current
injury. Recovery evidence confirms recovery from this episode, not merely an
elapsed duration. Requiring zero total injury is an explicit implementation
restriction until wound-specific healing allocation can distinguish unrelated
remaining injuries. The operation does not itself heal or charge treatment time.

Apply inside an engine action transaction. It rolls twice, first for sterility,
then for the terminal condition. Each check uses the original radiation table
modifier and the current radiation HT context, including advanced treatment.
Only that check's critical failure grants its corresponding condition. Ordinary
failure grants neither. Existing active sterility does not duplicate its feature.
The result exposes both checks, their independent outcome flags and the net
character-point change. Spendable points remain unchanged.

Simple sterility is `RpgExpandedSterility`, a zero-point feature (`full-2008`, B165).
`profile.fertilityBlocked()` exposes this impediment for authored reproductive
procedures; false does not establish fertility in the presence of other world
facts. This feature does not apply the broader source's sexual-trait effects.
The one-year condition uses the health module's owned terminal deadline.

The episode owns one recovery receipt. Completing both checks clears its pending
recovery flag and the parent check's pending consequences. Its temporary pain
effect continues until the original one-week expiry. Replay retains both rolls
and does not duplicate traits, extend a deadline or grant points. Overlapping
burn episodes remain blocked until both recovery checks and the pain effect have
finished. Cures and terminal-condition buy-off remain unsupported.

`tests/fixtures/expanded-radiation-recovery.t` and `test_radiation_recovery` specify
all combinations of the two critical-failure outcomes, ordinary failure, healing
preconditions, preview, rollback, undo, replay, accounting and saved continuation.
These cases are authored and unrun.

### Infection after surgery

`RpgExpandedSurgicalInfectionExposure` attaches to one owned surgical operation,
including successful operations that cause no HP injury. Assign it to the
operation's `infectionExposure`; set its `operation`, `diseaseId`, `evidence` and
`RpgExpandedSurgicalInfectionContext`. The context records the actual care
`medicalTL`, infected matter and special locale. B424's mandatory check does not
require inventing an untreated dirty wound: the surgical context directly supplies
the B444 acquisition modifier of +3 plus contamination modifiers.

When the hazards library is included, infection-requiring surgery must have this
exposure prepared before starting. The operation binds the exposure and its facts,
preflights resistance, and commits the acquisition after either surgical success
or failure. A patient killed by the failure injury receives no postmortem infection
roll. Replay does not roll again. The receipt is private medical state; authors
must not reveal an infection before it is discovered in play.

Natural immunity and `RpgExpandedInfectionDay` use the same mechanisms as wound
infections. The daily record's exposure can now obtain its patient and source ID
from a surgical operation. Daily failure creates a genuine one-HP disease wound;
ending infection unlocks its disease injury without healing that HP automatically.
The clock cannot skip a pending surgical infection's daily boundary. No second
injury or time ledger is created.

Antibiotic acquisition combinations and critical treatment exceptions remain
explicitly unsupported by this surgical adapter; the existing daily treatment
interface still supports its documented antibiotics rules. Optional bleeding and
impaired clotting during surgery remain unfinished. The surgical infection fixture
and `test_surgical_infection` cover acquisition without a wound, daily injury and
resolution, immunity, replay, rollback, undo and cross-process continuation. They
are authored and unrun.

Persistent-wound infection resistance now uses the current daily dressing receipt.
Set `plagueRidden` on an acquisition's infection context and independently on each
`RpgExpandedInfectionDay` to establish the actual surroundings for that roll. This
fact is bound in the resulting receipt. It is distinct from `specialLocale`:
that existing modifier describes a special pathogen, whereas plague-ridden
surroundings activate the persistent wound's separate -3 when it is not dressed.
Both apply when both facts are established. A successful dressing removes only
the persistent-wound penalty, not the pathogen modifier. Acquisition and daily
progression still share the original resistance and disease-injury pipelines.

### Poison entry assessment

`RpgExpandedPoisonEntry` assesses the delivery boundary in `full-2008`, B437–B438.
Supply `patient`, `route`, `method`, `approved` and evidence establishing actual
contact, exposure and protection. The result distinguishes a valid assessment
(`status == 'ready'`) from actual entry (`exposed`). It consumes no dose, time or
randomness and applies no poison injury. Poison definition, delay, resistance,
cycles and treatment remain unfinished runtime work.

The routes use these explicit facts:

- `blood`: direct contact requires `mucousContact`, `openWoundContact` or
  `persistentWoundReached`. The latter requires the active persistent-wound trait
  and exposes `viaPersistentWound`; it does not create another injury. A `spray`
  also requires `vulnerableAreaHit`. For `area`, establish `inArea`; `sealed`
  protection blocks entry, as does the combination of `noBreathing` or
  `filteredLungs` with `eyeMembrane` or `protectedVision`.
- `contact`: direct contact requires `skinContact` or actual `inhaled` exposure.
  A `weapon` additionally requires `unarmored` and `unclad`; an `area` requires
  `inArea` and no sealing.
- `digestive`: direct delivery requires `swallowed`. For `forcedSwallow`, the
  author must also establish at least ten `headOrNeckHeldSeconds`. This checks
  resolved grapple facts; it does not execute or prolong a grapple.
- `follow-up`: a `weapon` needs a committed, patient-owned `wound` with positive
  injury and an eligible `penetrationKind` (`piercing`, `impaling` or `hypodermic`).
  Payload ownership/consumption and the separately specified cutting-edge coating
  procedure remain unfinished; they cannot be inferred from this assessment.
- `respiratory`: actual inhalation is required, with `holdingBreath` preventing
  entry. Stunned or unconscious patients inhale automatically. `noBreathing` or
  `filteredLungs` prevents entry; an `improvisedMask` instead grants the returned
  +1 `resistanceModifier`. Area delivery also requires presence in the area.
- `sense`: `sensePresent` and no `senseProtected` protection are required. Those
  fields refer specifically to the poison's targeted sense; no protection carries
  over to another route. Area delivery requires `inArea`.

Protection fields represent verified innate or equipment capabilities; this
adapter does not claim to implement the corresponding trait/equipment catalogues.
For direct delivery, evidence must establish that the substance reaches the target;
an unobserved attack or speculative presence is insufficient. Breath-holding and
sense-detection procedures remain the responsibility of their actual systems.
Unsupported delivery combinations return explicit reasons.

`expanded-poison-entry.t` and `test_poison_entry` specify all six routes, the
persistent-wound entry, paired area protections, exposed/clothed skin, nine/ten
second forced swallowing, unconscious/stunned respiration, mask benefit and an
owned follow-up wound. They are authored and unrun.

### Owned single-cycle toxic exposure

`RpgExpandedPoisonExposure` reuses `RpgLiteHazard` parameters and the Lite exposure
base, but owns its admitted delivery and absolute onset deadline. Supply a unique
`id`, expanded `profile`, `hazard`, approved `RpgExpandedPoisonEntry`, factual
`sizeModifier`, `approved` and `effectEvidence` identifying the poison's supported
effects. Currently the hazard must describe exactly one cycle of toxic HP injury,
with one to one hundred dice and nonnegative additions. Fatigue, cyclic poison,
other symptoms/conditions, variable dose and negative additions remain unsupported.
The original fictional fixture agent is not a claim of source-catalogue coverage.

`assess()` verifies entry, resistance availability and every possible failure
injury before mutation. `start()` records the exposure in `poisonExposures`, binds
its definition/contact facts and captures the entry resistance modifier. It spends
no additional time or dose. The delivering system must account for the actual
payload once; coating and ammunition payload integration remain unfinished.

B438's size adjustment doubles the onset delay for each positive size step and
halves it for each negative step. `rpgExpandedPoisonDelay` uses exact whole seconds;
sub-second outcomes and overflow are rejected rather than rounded. An immediate
poison is due at its starting instant. Advance the shared ledger to the exact
`dueAt`; the clock cannot skip a live pending exposure. Do not use the inherited
relative `advance` API, which explicitly rejects calls on this expanded type.

`assessResolution()` is pure. `resolve()` rolls resistance at onset using the
current patient and shared poison resistance modifiers, then rolls damage only
when resistance fails or the poison is unresistible. It commits one expanded wound
without subtracting armor again. Replay returns the saved result; the start and
resolution do not reevaluate contact after it has already occurred. Death before
onset releases the clock boundary and prevents further poisoning of that patient.
After a single cycle, normal healing remains available. This is not an
implementation of cyclic-poison recovery restrictions or continuing environmental
exposure.

`expanded-poison-exposure.t` and `test_poison_exposure` specify success/failure,
unresistible injury, size-adjusted timing, premature resolution, exact deadlines,
unsupported forms, preview, replay, rollback, undo and saved continuation. They
are authored and unrun.
