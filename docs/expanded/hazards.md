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
prevention, daily treatment, unsupported cases and preview purity. validation is in progress, so these fixtures are unrun.


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
these authored cases remain unrun pending recorded validation.


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
is authored but unrun pending recorded validation.


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
These fixtures also remain unrun pending recorded validation.


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
The fixture remains unrun pending recorded validation.


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
preview purity. These fixtures remain unrun pending recorded validation.


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
All fixtures remain unrun pending recorded validation.


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
time. These fixtures use the exact compiled game and remain unrun pending recorded validation; they are not a verified compatibility claim.


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
The fixture is authored but unrun pending recorded validation.


`test_rejuvenation_transactions` exercises exception rollback, undo and replay of
restoration after an actual paid attribute improvement. It rejects changed bound
evidence and duplicate request identities, then repeats aging and restoration in
a new era to ensure old losses cannot be restored twice. Character-cost queries
also validate the history and retained advancement spending.

`test_rejuvenation_persistence` restores separate-process saves before restoration,
after restoration and after the next aging event. All routes reach the same base
score, character value, advancement balances and restoration links without extra
randomness or time. The fixture uses the existing exact-game save policy. These
expectations remain unrun pending recorded validation.


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
whose perception exceeds HT. Fixtures remain unrun pending recorded validation.


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
The fixture remains unrun pending recorded validation.


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
These fixtures are authored but unrun pending recorded validation; the exact compiled
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
outcomes. All fixtures remain unrun pending recorded validation.


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
dry-suit routing and purity; it remains unrun pending recorded validation.


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
fixtures are authored but unrun pending recorded validation. Existing Lite regressions
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
operations. All fixtures are authored but unrun pending recorded validation. The dedicated
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

### Owned toxic exposure cycles

`RpgExpandedPoisonExposure` reuses `RpgLiteHazard` parameters and the Lite exposure
base, but owns its admitted delivery and absolute onset deadline. Supply a unique
`id`, expanded `profile`, `hazard`, approved `RpgExpandedPoisonEntry`, factual
`sizeModifier`, `approved` and `effectEvidence` identifying the poison's supported
effects. The hazard supports single or repeated cycles of toxic HP injury or fatigue loss,
with zero to one hundred dice and nonnegative additions. Zero dice requires a
positive fixed addition; it applies that fixed damage without drawing damage dice.
Other symptoms/conditions and negative additions remain unsupported.
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
After a single cycle, normal healing remains available. For cyclic toxic injury,
set `hazard.cycles` and the whole-second `hazard.interval` (1–86400 seconds).
Size adjusts onset only. Each later deadline needs a new `RpgExpandedPoisonCycle`
with a unique `id` and the owned `exposure`; call `assess()` then `apply()`.
`exposure.resolve()` always replays the onset receipt after the first resolution,
so retrying it cannot accidentally commit another cycle.

Each cycle makes a fresh resistance check. Success ends the sequence immediately;
failure applies another wound, up to the specified cycle count. Active cyclic
losses remain protected from healing. Ending the sequence releases only that
exposure's restriction and does not heal any injury. Natural recovery is limited
to unprotected injury; other disease, temperature and clotting restrictions remain
in force. Dead patients incur no later cycle. Fatigue poison, symptom thresholds,
general medical treatments and continuing environmental exposure remain unfinished.

`expanded-poison-exposure.t` and `test_poison_exposure` specify success/failure,
unresistible injury, size-adjusted timing, premature resolution, exact deadlines,
unsupported forms, preview, replay, rollback, undo and saved continuation. They
are authored and unrun.


### Increased abstract poison dose

For digestive or hypodermic follow-up delivery, set an exposure's `doseDoublings`
before admission. It defaults to zero. `doseAssessment()` returns a pure
`RpgExpandedPoisonDoseResult`: abstract dose count, cost and damage multipliers,
size-adjusted onset, interval, resistance modifier and detection modifier.
Each doubling doubles the abstract dose, cost and rolled damage, halves onset
and cycle interval, subtracts two from resistance and adds two to detection
(full-2008 B439). Size changes onset only. Every derived time must remain an
exact whole second; fractional timing is rejected before admission.

Exposure resolution uses this same assessment for every cycle. The admitted
setting is immutable; changing it prevents further execution. The delivering
system must consume the returned dose count once, and purchasing and detection
authors must use its cost multiplier and detection modifier. Automatic inventory
consumption, price settlement and identification actions remain unfinished; this
interface does not claim those integrations. Increased dose on other routes is
rejected. Fractional doses and their author-selected efficacy remain unsupported.
The fixture includes twofold and fourfold arithmetic, doubled injury, shortened
cycle deadlines, route rejection and mutation rejection. validation is in progress.


### Agent-specific antidotes

`RpgExpandedAntidote` is an inventory item with an exact `targetHazard`, original
`effectEvidence`, and either a positive `resistanceBonus` or `endsExposure = true`
with zero bonus. These values are authored facts about that particular remedy;
the interface does not assume that every poison has an antidote. A resistance
remedy requires a resistible agent.

Create `RpgExpandedAntidoteAdministration` with a unique `id`, the active owned
`exposure`, `medicine`, `approved`, `identificationEvidence` and
`administrationEvidence`. Identification must already be established by the
story's actual identification procedure. Administration must already be resolved
by its action, including any action time. `assess()` is pure; `apply()` consumes
one available, uniquely owned inventory unit and stores a receipt in the patient's
`poisonAntidotes`. Removing the final unit removes the item from inventory.
Replaying the receipt consumes nothing and does not charge time again.

A bonus changes subsequent resistance checks, including those during cyclic
poisoning. Termination cancels remaining cycles and releases that exposure's
healing restriction without healing any lost HP. Neither variant rewrites earlier
checks or affects another exposure. The receipt binds the agent and remedy
properties; later editing them invalidates execution. Combined/repeated remedies
on one exposure are rejected pending an explicit interaction procedure.

This implements the remedy-effect contract in full-2008 B439. Discovering a
remedy and administration action durations remain separate unfinished
integrations. Owned identification and timed medical care are described below. Fixture scenarios
cover inventory consumption, mismatched agents, future resistance, termination,
replay, rollback, undo and saved continuation. They are authored and unrun.


### Timed poison treatment

`RpgExpandedPoisonTreatment` owns one attempt against an admitted exposure
(full-2008 B439). Supply `id`, `exposure`, `healer`, a technology-qualified
first-aid or physician `skill`, `approved`, `suitable`, `identificationEvidence`
and `suitabilityEvidence`. These facts must identify the actual agent and explain
why this procedure is appropriate. Harmful vomiting exceptions are not silently
accepted as safe treatment: their effects still require a separate implementation.

Choose `kind = 'wound'` for the one-minute procedure at skill −2, or `digestive`
for the ten-second procedure at unmodified skill. Success grants +2 to subsequent
resistance against that exposure. Wound treatment requires blood/follow-up entry;
digestive treatment requires swallowed entry. `kind = 'medical'` requires
physician, authored `medicalSeconds`, `medicalTechnology` and `medicalBonus`.
The positive bonus cannot exceed half the medical technology rounded up, with a
minimum cap of one. A difference between skill and medical technology uses the
shared cognitive-skill technology modifier.

`assess()` checks suitability, skill, duplicate attempts and whether the duration
can fit before the next poison deadline. `apply()` spends that time once,
rechecks conditions, makes one skill roll and records the attempt in the patient's
`poisonTreatments`. Success changes future poison checks; failure grants no bonus.
It does not heal injury or retroactively change a resolved cycle. Replaying the
receipt spends no additional time or randomness. A later retry or combination
with an antidote is explicitly unsupported until its interaction is defined.

The fixture specifies all three procedures, the medical bonus cap, unsuitable
care, a deadline too soon to finish, failed care, preview purity, replay, rollback,
undo and cross-process continuation. validation is in progress; these scenarios have
not run. Automatic identification actions, harmful exceptions and combinations
remain unfinished.


### Ordinary weapon coatings

`RpgExpandedPoisonStock` holds abstract doses in the existing inventory ledger.
Supply its `hazard`, quantity, authored price and weight. To coat a weapon,
create `RpgExpandedWeaponCoating` with an `id`, owner `profile`, `weapon`,
`stock`, one supported melee `mode`, `reachYards`, `approved` and `evidence`
establishing that this agent follows ordinary coating behavior (full-2008 B439).
A point uses one dose; a cutting edge uses three doses per whole yard of reach.
`assess()` verifies unique inventory ownership and supply. `apply()` consumes
the doses once, records the coating and removes exhausted stock from inventory.
The authoring action supplies any application time; no unsupported duration is
invented. Hypodermic filling, fractional reach and ranged payloads remain separate.

The Lite strike path now calls default no-op weapon `validateStrike` and
`afterStrike` hooks. Expanded coatings use these to validate the admitted mode
before rolling and record each resolved strike. `RpgLiteCombatResult` retains
`attackMode` and `successfulDefense` for this purpose. Misses and dodges do not
rub off the coating. One hit, including a hit stopped by armor, depletes it;
three blocked or parried attacks also deplete it. Individual strike objects are
recorded once, including separate strikes in a double attack. A live coating
rejects a different owner or mode rather than guessing which surface was used.
An exhausted coating may be replaced by a new uniquely identified application.

This integration accounts for coating supply and wear. It does not yet admit
poison exposure automatically after penetration, attach a poison definition to
an expanded wound, or cover unusual persistent coatings. Those delivery paths
remain explicit unfinished work. Fixtures specify inventory, miss/dodge/hit
hooks, repeated parries, receipt reuse, rollback, undo and saved continuation;
they remain unrun pending recorded validation.


### Executable poison catalogue entries

`rpgExpandedPoisonCatalogue(id, route)` returns a fresh definition for the
following neutral entries from full-2008 B439:

| Identifier | Route | Onset | Resistance | Toxic damage | Cycles | Technology | Price/dose | Legality |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `delayed-ingested-agent` | digestive | 3600 seconds | HT−2 | 1d | Eight, 3600-second intervals | 1 | 1 | 1 |
| `injected-venom` | follow-up | 60 seconds | HT−3 | 2d | Six, 3600-second intervals | 0 | 10 | 1 |
| `rapid-systemic-agent` | follow-up or respiratory | Immediate | None | 4d | One | 4 | 2 | 1 |
| `rapid-systemic-agent` | contact or digestive | 900 seconds | None | 4d | One | 4 | 2 | 1 |
| `dual-route-agent` | area contact | Immediate | HT−4 | 1 HP | Twenty-four, 28800-second intervals | 6 | 10 | 0 |
| `dual-route-agent` | area respiratory | 7200 seconds | HT−1 | 1d | Six, 3600-second intervals | 6 | 10 | 0 |

Use the returned definition as an owned exposure's `hazard`, with an approved
entry of the same route. The common exposure implementation handles size, dose,
resistance, cyclic protection, treatment and exact deadlines. Catalogue values
are validated against the supplied printing before admission and continuation.
Changing a catalogue definition is rejected; use an ordinary authored hazard for
an original variant. Other catalogue identifiers are explicitly unsupported until
their symptom, fatigue or condition procedures have executable support.

`rpgExpandedPoisonCatalogueStock(stockId, catalogueId, route, doses)` creates an
unowned inventory lot with the definition, quantity, technology and legality.
Its `cost` is the total price of that lot, matching the acquisition API's price
contract. World authors must still supply sale availability, legal permission
and any price override through normal acquisition. Weight is unspecified by this
catalogue; supply it before acquisition when the game accounts for it. The helper
does not itself buy, issue, administer or consume the stock.

The fixture's expected values are literal source values. It specifies all eight
failed cycles of the delayed agent, immediate and delayed unresisted injury,
lot pricing and rejection of modified catalogue statistics. Tests remain unrun;
catalogue coverage remains partial pending validation and delivery integration.


The `dual-route-agent` entry enforces `method = 'area'` in addition to the chosen
route. Its contact variant uses fixed one-point toxic injury and therefore draws
only resistance dice each cycle. The respiratory variant uses one damage die on
failed resistance. Each route has its own admitted exposure; the interface does
not collapse simultaneous contact and inhalation into one arbitrary effect.

For this catalogue entry, set `preparedForAgent = true` and nonempty
`preparationEvidence` on the exposure only when that preparation is established
in the authored encounter. The source permits fear checks for unprepared people;
unprepared admission is explicitly blocked pending integration with the owned
fear procedure. This is a supported prepared-victim path, not complete fear or
persistent-environment coverage. The preparation facts are bound at admission.
Fixtures cover the full twenty-four contact cycles and six respiratory cycles,
their final injuries and random-draw counts, wrong delivery methods, unprepared
admission and invalid zero-damage definitions. They remain unrun.


### Venom injury symptoms

The `injected-venom` catalogue entry (full-2008 B439) applies temporary DX
penalties of −2, −4 and −6 when its attributed injury reaches one third, one half
and two thirds of full HP. `rpgExpandedVenomDexterityPenalty(capacity, injury)`
compares exact integer fractions; it does not round a threshold downward. Owned
exposures retain `symptomInjury`, incremented only by their committed toxic injury.
Unrelated wounds cannot start or escalate these symptoms.

`poisonDexterityPenalty()` feeds the shared health modifier for DX actions and
DX-based skills. Under the temporary-attribute rule (B421), Basic Speed, Move and
active defenses remain unchanged. A custom DX-based defensive reaction must mark
its check context `defensiveReaction = true`; ordinary defense contexts are
already exempt. This changes a temporary check modifier, not purchased DX.

Healing caps each exposure's remaining symptom injury at current total injury,
so crossing back above a symptom threshold removes that severity. Later unrelated
injury does not restore the cleared severity. Ending the poison stops future
cycles and releases its healing lock but does not itself clear symptoms or heal
HP. Simultaneous symptom-bearing exposures are rejected pending an explicit
combined-attribution procedure. Other symptom forms remain unfinished.

Fixtures specify nonintegral threshold boundaries, staged DX loss, unchanged
secondary/defense values, antidote termination followed by healing, later
unrelated injury, undo and saved continuation. They remain unrun.


### Fatigue-damage poison

Set an authored hazard's `fatigueDamage = true` to apply its fixed or rolled
amount to FP instead of direct toxic HP. `RpgExpandedPoisonFatigueLoss` reuses
the existing owned point-by-point fatigue procedure, including overflow HP loss,
FP floor and unconscious collapse. It records receipts in `poisonFatigueLosses`
and creates uniquely identified expanded wounds for overflow injury. The existing
fear fatigue API retains its six-point limit and history; poison loss supports
up to 10000 points in one assessed effect.

`RpgExpandedPoisonResult.fatigue` reports actual added fatigue;
`fatigueLoss` links its owned receipt, and `injury` reports overflow HP loss.
Each cycle preflights before its resistance or damage draws. Resistance success
skips both FP and HP loss. Fixed effects draw no damage dice.

Active cyclic exposures retain `lockedFatigue` and any overflow `lockedInjury`.
The default-zero `additionalRecoveryLockedFatigue()` profile hook extends the
existing rest protection without charging another clock or maintaining another
FP total. Rest can recover unrelated fatigue, but cannot recover the exposure's
protected loss. A final cycle, successful resistance or terminating antidote
releases both restrictions without granting any recovery. Other hunger, thirst,
sleep and temperature restrictions remain separate.

The fixture uses an original fixed four-point agent to specify ordinary fatigue,
overflow injury, recovery of unrelated FP, protected rest, final release, replay,
rollback, undo and saved continuation. These fixtures are unrun. The remaining
condition-based catalogue agents and persistent environmental repetition are
still incomplete.


### Owned poison identification

`RpgExpandedPoisonIdentification` implements clue-based and symptom-based
identification from full-2008 B439. Supply a unique `id`, admitted `exposure`,
`examiner`, `skill`, `approved`, concrete `evidence`, authored `durationSeconds`
and any `conditionsModifier`. The source gives no universal examination time,
so the duration is an explicit encounter fact. Use `clue = 'residue'` with
poisons, `animal` with naturalist, or `symptoms` with diagnosis or poisons.
Symptom identification additionally requires `observedSymptoms = true` and an
owned cycle that actually caused HP or FP loss. A claim of symptoms before any
effect is rejected. The clue must be available to that examiner.

`assess()` checks the examiner, clue and clock boundary without rolling.
`apply()` spends the authored duration once, rechecks facts and makes one skill
roll. The exposure's dose detection modifier applies to this check. Success and
failure are both recorded in the patient's `poisonIdentifications`; replay spends
nothing. Further attempts by the same examiner on the same exposure are rejected
until a retry procedure is supplied. Identification does not treat the patient,
reveal unrelated agents or clear an exposure.

Timed care can set `identification` to a successful receipt instead of supplying
`identificationEvidence`. The receipt must identify the same exposure and belong
to the treating healer. Failed identification cannot authorize care. Explicit
prior knowledge remains available through `identificationEvidence` when the
story has established it independently. Suitability evidence is still required:
knowing the agent does not make every proposed treatment safe.

Interrogation remains a social procedure rather than an unconditional
intimidation roll in this interface. Recognition before an exposure is admitted,
sharing knowledge between characters and retries remain unfinished. Fixtures specify residue and animal clues, observed symptoms,
dose bonuses, failed identification, treatment linkage, replay, rollback, undo
and saved continuation. They are authored and unrun.


An antidote administration may also set `identification` and `administrator` in
place of `identificationEvidence`. The receipt must be successful, identify the
same exposure and belong to that administrator. The administrator must currently
be able to act. These conditions and receipt integrity are checked before the
inventory unit is consumed. The administration receipt binds both objects and
continues to validate the original identification on replay and later resistance
queries. Previously established knowledge can still use explicit evidence.

This path does not share an examiner's knowledge with another character
implicitly. A different administrator needs independently established knowledge
until an explicit knowledge-sharing interface is available. Fixtures cover
failed identification, an incapacitated or different administrator, altered clue
evidence, stock preservation on rejection, replay, rollback, undo and saved
continuation; all remain unrun.


### Continued poisonous environments

`RpgExpandedEnvironmentalPoisonExposure` owns a continuing area exposure
(full-2008 B438). Supply the ordinary exposure fields plus concrete
`environmentEvidence`; its entry must describe actual area contact through blood,
contact, respiration or a sense. Start it once, then resolve onset normally.
Every later check uses a uniquely identified `RpgExpandedEnvironmentalPoisonCycle`
bound to that exposure. An ordinary cycle receipt is rejected for this subtype.

Until the first failed resistance, each success schedules another check after the
size-adjusted delay, or after one second for an immediate agent. It restores the
full damaging cycle count because successful environmental checks have not yet
started the poison's damage sequence. Exact deadlines remain enforced by the
shared ledger. Replay the original cycle object to retrieve its result without
rolling again; `exposure.resolve()` always refers to onset.

The first failed resistance sets `environmentAffected` and starts the ordinary
damage sequence. Subsequent cycles use the agent's damage interval and normal
termination rules. Further successful resistance ends that acquired poison; it
does not restart environmental retries after the victim has already been affected.
No additional inventory dose, action time or damage roll is charged for a
successful environmental resistance check.

Call `leave(evidence)` when the patient actually leaves. Before the first failed
resistance, this cancels the pending exposure and releases its clock boundary.
After poison has been acquired, leaving records the departure while retaining
remaining poison cycles and healing restrictions. Repeated departure calls must
reuse the same evidence and do not spend anything. Changed protection, re-entry,
cloud dispersal and residual-surface behavior need explicit encounter integration;
they are not inferred by this persistent-contact interface.

Fixtures specify immediate and delayed retries, retry receipt reuse, first
failure, acquired cycles after departure, cancellation before acquisition,
rejection of a wrong cycle type, rollback, undo and saved continuation. They are
authored and unrun.


### Physiology-specific susceptibility

The source leaves species-specific immunity and resistance differences to the
author (full-2008 B438). `RpgExpandedPoisonSusceptibility` makes that decision
explicit for a `profile` and exact `hazard`: supply `physiology`, `approved`,
`evidence`, and either `immune = true` or a signed `resistanceModifier`.
Set the exposure's `susceptibility` to that decision before admission. No ancestry
name, creature label or free-text physiology string grants immunity by itself.

The assessment validates the target and evidence. Combining immunity with a
nonzero modifier is rejected, as is modifying resistance for an unresistible
agent. Valid immunity records the admitted exposure as finished at the current
instant, without spending time, rolling resistance, taking damage or scheduling
environmental retries. It does not consume or refund a delivering system's
payload. Ordinary dose, route and catalogue constraints still apply.

A nonimmune modifier applies to every actual poison resistance check alongside
the entry, dose and treatment modifiers. The complete decision is bound into the
exposure receipt. Altering its target, rationale or effect after admission
invalidates continuation; it does not retroactively rewrite an acquired poison.
Transformations that change physiology during exposure need a separate explicit
procedure and remain unsupported.

Fixtures specify immune replay and saved continuation, ordinary resistance
adjustment, immunity to an unresistible agent, wrong targets, invalid combinations,
post-admission mutation and immune environmental contact. They remain unrun.


### Ordinary smoke and environmental coughing

The neutral `combustion-smoke` catalogue entry implements ordinary smoke from
full-2008 B439: area respiratory delivery, ten-second onset, unmodified HT
resistance, and coughing on failure. Use it with
`RpgExpandedEnvironmentalPoisonExposure`. Success schedules another environmental
resistance attempt; failure records an owned `RpgExpandedEnvironmentalCoughing`
condition in both the cycle result and exposure. It causes no HP/FP loss and draws
no damage dice. Dense damaging smoke requires a separate authored definition.

The condition remains active while the patient stays in the environment. Its
`durationSeconds` is the resistance failure margin times sixty: the recovery tail
after departure. Until departure, `expiresAt` is nil. The exposure's owned
`leave(evidence)` sets expiry to departure time plus that tail, validates clock
capacity, and preserves receipt replay. The coughing modifiers and Stealth block
come from the health library; crossing expiry removes them without a recovery
roll. Symptom-based identification recognizes this actual condition even though
it caused no injury.

The source gives legality four but no dose price or technology for ordinary
smoke. These fields remain unspecified, and the catalogue stock factory rejects
commercial stock creation for this entry. It does not invent a purchase price.
The source's default failure-margin duration is ambiguous for an automatic failed
roll with a nonpositive numerical failure margin; admission currently rejects
resistance scores above sixteen for this condition until that case is resolved.
Overlapping coughing causes remain unsupported.

Fixtures specify successful retry, failed onset without damage, continuous
symptoms, departure and exact tail expiry, rollback, undo and cross-process
continuation. They are authored and unrun. Dense-smoke injury, changed protection,
re-entry and broader cloud lifecycle integration remain incomplete.


### Respiratory and visual irritant cloud

`rpgExpandedPoisonCatalogue('dual-irritant', route)` implements the respiratory
and visual routes of full-2008 B439's irritant-cloud entry. Both are area effects
with immediate onset, HT−2 resistance, technology six, price ten per dose and
legality two. Choose `respiratory` for coughing or `sense` for blindness. The
visual route additionally requires `entry.senseKind = 'vision'`; another sense
cannot substitute for eyesight. Missing or protected senses prevent admission.

Use `RpgExpandedEnvironmentalPoisonExposure` and explicit preparation evidence,
as with the other catalogue agents that may require a fear decision. A failed
check creates an owned condition that persists in the cloud, then for the failure
margin in minutes after departure. Respiratory and visual effects use separate
condition histories. `RpgExpandedEnvironmentalBlindness` uses the temporary
blindness visual gates; its unseen-target combat adapter is still incomplete,
so the existing explicit combat rejection remains in force.

Opacity applies independently of the poison's resistance outcome. For a vision
check, set `irritantCloudYards` to the actual whole yards of cloud crossed and
`irritantCloudPenaltyPerYard` to the authored density from one through three.
The shared modifier subtracts their product, matching
`rpgExpandedIrritantCloudVision(yards, density)`. This is a vision-check modifier,
not an automatic attack penalty. Fractional geometry, attack visibility and cloud
movement remain separate unfinished integrations.

Fixtures cover both route effects and expiry after departure, protected vision,
wrong senses, missing preparation, density arithmetic, undo and saved continuation.
They are authored and unrun. Unprepared fear resolution, overlapping conditions,
changed protection and the remaining combat integration are still incomplete.


### Neurological agents and associated conditions

The neutral `neurological-agent` catalogue entry (full-2008 B439) accepts area
contact delivery. Its fixed values are TL6, cost 20 per dose, legality 0, immediate
onset, HT−6 resistance, two dice of toxic injury and six cycles one minute apart.
Use the existing environmental exposure type for continuing presence in a cloud;
a regular exposure represents a single admitted contact. Prepared-patient evidence
is still required until unprepared fear admission is integrated.

This entry also requires an executable authored affliction contract on the
exposure: `associatedCondition`, `associatedPolicy`, and `associationEvidence`.
The supported policy is `first-failed-cycle`. Supply an approved
`RpgExpandedParalysis`, `RpgExpandedSeizure` or `RpgExpandedAgony` for the same patient, with its own
unique ID, duration and evidence. Paralysis also requires its balance assessment.
The book lists possible accompanying conditions but does not supply their duration
or precise onset/refresh procedure here. Selecting this policy and duration is an
explicit author adjudication, not a fixed catalogue rule.

Admission preflights the selected condition. The first failed resistance applies
it alongside injury; successful resistance does not apply it. Later cycles never
restart or extend it. Its definition is bound into the exposure receipt and cannot
be changed after admission. Its own recovery remains independent of poison-cycle
termination: an antidote that ends toxic cycles does not silently cure paralysis
or settle a seizure's pending fatigue. A seizure end must be resolved at its exact
shared-clock boundary. Agony independently charges each begun minute; when its
payment and a toxic cycle are both due, resolve both before advancing beyond that
second. Toxic injury never settles an agony payment. Retching, combined irritant effects and alternative
onset policies reject as unsupported rather than being approximated.

`expanded-neurological-agent.t` specifies fixed catalogue values, six injury
cycles, absence of condition refresh, successful resistance, missing-contract
rejection, seizure-end integration, coincident agony/toxic deadlines, preview, replay, rollback, undo and saved
continuation. These assertions are authored and unrun.

### Collision damage assessment

`rpgExpandedAssessCollision(capacity, velocity, hard)` returns crushing damage
`damageDice` and `damageAdds` without rolling, injuring anyone or spending time.
Pass full HP capacity, not HP remaining after injury, and velocity in whole yards
per second. Set `hard` only for collision with an immovable hard surface; it doubles
the moving object's capacity before calculating dice. A soft surface uses ordinary
capacity. Zero velocity returns zero dice and zero adds.

Positive results below one die use the three printed reduced-die bands; larger
results round half a die upward. The result also exposes the effective `capacity`
and supplied `velocity`. It does not use the abridged collision helper's rounding.
For example, 10 HP striking a hard surface at 19 yards per second gives 4d crushing.

This is a damage-expression assessment, not an injury commitment. Sharp-object
conversion, breakable-obstacle caps, elastic cushioning, armor/blunt trauma,
locations, moving-object interactions and owned collision execution remain pending.
Do not roll twice when the same collision later supplies damage to both objects.
`test_collision_assessment` specifies the fractional thresholds, rounding, zero
motion and the printed hard-surface example; assertions remain unrun.
Source: `full-2008`, B430-B431.

### Fall protection and blunt trauma

`rpgExpandedAssessFallProtection(damage, resistance, kind)` assesses one homogeneous
protection layer. Use `armor` for worn armor (including rigid armor) or `innate`
for innate resistance. It returns `penetratingDamage`, `stoppedDamage` and
`bluntInjury`. If armor stops the entire fall damage, each full five damage points
causes one point of blunt-trauma injury. Any penetration suppresses blunt trauma.
Innate resistance never creates blunt trauma through this rule.

Keep the outputs distinct: penetrating damage still needs the applicable location
and injury rules; blunt injury is already injury and receives no wounding
multiplier. This function neither rolls nor commits a wound. Do not combine mixed
innate and worn layers into a single resistance value: their ordering is not
represented by this interface, and layered fall protection remains pending.
The authored fixture covers zero damage, zero resistance, five-point boundaries,
exactly stopped damage, penetration and the innate exception. validation is in progress.
Source: `full-2008`, B379 and B431.

### Owned torso fall injury

`RpgExpandedFallInjury` commits an already resolved crushing fall damage value to
an expanded profile. Set `id`, `profile`, `damage`, `resistance`, `protectionKind`,
`approved` and `evidence`; supply `dropDestination` where a knockdown could drop
held gear. Evidence must establish the resolved damage, torso treatment without
location rules, and one homogeneous protection layer. This operation does not roll
damage or repeat a landing check and adds no second time charge.

`assess()` preflights protection and the standard wound procedure without committing
injury. `apply()` creates one wound in `expandedWounds` and records the operation in
`fallInjuries`. Run it within the engine action transaction. Repeated application
returns the recorded result; changing the bound request or reusing its identifier
is rejected. The result exposes the protection assessment and owned wound. Even a
fully protected zero-injury fall retains its receipt so it cannot later be rerolled
through this operation. Normal wound consequences use the existing injury ledger.

The default location is `torso`; the explicit hand adapter is described below. Random hit locations, uncapped limb
injury, multiple crippled limbs, mixed protection, special anatomy, obstacle damage,
landing maneuvers and automatic linkage from an owned climb remain incomplete.
This bridge must not be used as a fallback for those rules. The authored fixture
covers preview, replay, changed-request rejection, rollback, undo, cross-process
save continuation, armor blunt injury, penetration and innate protection. Validation is in progress; none of these new assertions has run.


### Breakable landing obstacles

`rpgExpandedCollisionCap(damage, obstacleHP, obstacleDR)` caps basic impact damage
at the breakable immovable obstacle's HP plus DR (source `full-2008`, B431).
Pass `nil` for both obstacle values when this rule does not apply. A partly
specified obstacle is rejected. This calculation is pure and does not apply
armor or damage either participant.

`RpgExpandedFallInjury` accepts the same optional `obstacleHP` and `obstacleDR`
fields. Its evidence must establish that the obstacle is breakable and immovable.
It records `impactDamage` after the cap, then assesses protection and the wound.
The cap therefore also limits damage used to calculate blunt trauma. Both obstacle
values become part of the receipt's binding. The obstacle's own damage and any
subsequent fall remain unimplemented; authors must not treat the receipt as a
complete resolution of an obstacle breaking. The new fixtures cover exact and
exceeded caps, absent and incomplete facts, ordering before armor, replay and
rollback. They remain unrun pending recorded validation.

### Elastic landing protection

Owned torso falls accept `cushionDR` (zero by default, or 2 through 10) with
`cushionEvidence` describing the elastic landing surface and its applicability.
The printed examples give DR 2 for a feather bed and DR 10 for a safety net,
trampoline or airbag; intermediate ratings require an authored assessment.
These values are collision protection, not general armor for the character.

The operation applies the obstacle cap, subtracts cushioning, then assesses the
remaining impact against worn or innate protection. `impactDamage` is the capped
impact and `cushionedDamage` is the amount reaching the character's protection.
Cushioning is external to worn armor: only damage reaching that armor can cause
its blunt trauma (B379). Cushioning itself does not create an armor blunt-trauma
wound. Both rating and evidence are bound to the receipt. Missing evidence or a
nonzero rating below the printed range blocks the operation before commitment.

This does not determine whether a net breaks, infer a cushion from room scenery,
or implement landing in water. The fixture covers partial and complete cushioning,
obstacle-cap ordering, armor blunt trauma, preview, replay, rollback and missing
facts. Assertions remain unrun. Source: `full-2008`, B379 and B431.


### Linking the landing receipt

Set `RpgExpandedFallInjury.landing` to the resolved owned landing attempt and
`fall` to that same occurrence. The operation validates the receipt on assessment
and replay. An unresolved attempt, another profile's result, changed request or
wrong occurrence is rejected. A successful dive suppresses impact damage before
protection; an acrobatic reduction to zero velocity likewise suppresses it.

For a result that does not negate damage, set `damageVelocity` to the velocity
used for the supplied damage roll. It must match the receipt, so a successful
acrobatic landing cannot accidentally reuse the original fall velocity. The damage
roll itself is still supplied by the author: this link does not roll collision dice
or verify their provenance. Use `RpgExpandedFallImpact` below when the engine should own that roll.
The operation makes no additional landing roll or time charge.

When `fall` is set, only one injury receipt per profile may use that occurrence,
even with a different identifier or without a landing link. Create a distinct
occurrence for a genuinely subsequent impact. All linkage fields bind on commit.
Fixtures cover successful/failed dives, reduced velocity, unresolved/mismatched
receipts, duplicate injury, rollback, undo and cross-process continuation. These
assertions remain unrun pending recorded validation.


### Owned fall impact roll

`RpgExpandedFallImpact` accepts an `injury` template (`RpgExpandedFallInjury`) and
an authored `hard` surface classification. The template must be uncommitted with
`damage = 0`, a distinct `fall` occurrence and `damageVelocity`; its existing
landing, protection, cushion, obstacle, evidence and drop fields apply. Full HP
capacity supplies collision dice. Resolve any owned landing attempt first.

`assess()` computes the damage expression and preflights injury at the minimum,
maximum and armor-stopping boundary, where applicable. This checks both the peak
penetration and peak blunt trauma before consuming randomness. `apply()` rolls
the damage dice once, records each die and the total, then commits a copied injury
operation in the same action transaction. A negated dive rolls zero damage dice.
The result exposes `expression`, `dice`, `damage` and the committed `injury`.
The profile's `fallImpacts` list owns the impact receipt; the original template
stays uncommitted. Do not separately apply that template.

Replay validates the template binding and child injury receipt without rerolling.
The occurrence guard prevents a second wound through a different impact or direct
injury operation. No additional time is charged. Run inside an engine action so
exceptions roll back dice, wounds and receipt histories together. The deterministic
fixture specifies preview, rollback, undo, replay, save continuation, changed
surface rejection, pre-roll location rejection and no damage RNG after a dive.
Assertions remain unrun. This completes only the supported torso/homogeneous-
protection impact path; random locations, layered protection, obstacle damage,
subsequent falls and automatic world movement remain incomplete.

### Hand impacts

`RpgExpandedFallInjury` also accepts `location = 'hand'` with an owned hand
`bodyPart` and nonempty `locationEvidence` identifying the already resolved random
fall-location result. It selects `RpgExpandedFallExtremityWound` so excess HP injury
is preserved rather than capped at the hand's crippling threshold. Normal owned
anatomy, drop and support-loss hooks apply. The location fields bind to the receipt
and are copied by the owned impact-roll operation.

The engine does not yet roll a fall location here; authors must not select the
least harmful hand instead of supplying the actual resolved result. Unsupported
locations remain rejected. Mixed protection, other limbs/extremities and the
extra-limb disability roll remain incomplete. Hand-impact rollback, undo, replay
and save assertions are authored and unrun.

Arm impacts now use `RpgExpandedFallLimbWound` when `location = 'arm'`, with an owned
arm `bodyPart` and evidence of the resolved random location. This preserves full
HP loss and owns the additional-limb die. Other arms disabled by that die receive
zero-injury disability receipts, not repeated impact damage. The same fields bind
through direct injury and owned impact rolling. Lower-limb and automatic location
support remain unfinished; see the health guide for the current arm procedure.

Owned leg and foot fall locations are now accepted with matching body parts and
resolved-location evidence. They preserve full injury and force lying when crippled.
Extra leg crippling affects other legs only. Supported locomotion remains blocked
pending its aid/movement adapter; new fixtures remain unrun.


## Critical jump falls

`RpgExpandedJumpFallImpact` adapts a preflighted `RpgExpandedFallImpact` to a
jump launch. The impact must belong to the launch profile and occurrence, and
its velocity must match the authored fall height. The adapter rejects reuse
before a new launch and validates recorded child outcomes during replay.
See [critical-jump falling damage](exploration.md#critical-jump-falling-damage).
This adapter adds no separate time charge or duplicate injury ledger.

## Crushing pressure

`rpgExpandedAssessPressure(pressure, nativePressure, support, sizeModifier)` uses
hundredths of an atmosphere and full-2008 B435. Crushing checks start strictly
above ten times native pressure, or one hundred times with support level two.
Support level three prevents crushing checks. The assessment returns the health
modifier, failure-injury multiplier and whether return to normal pressure can
pose decompression risk. Size modifiers of +2 or greater multiply failure injury.
The risk flag does not resolve decompression or supply a safe schedule.

`RpgExpandedPressureExposure` binds a constant-pressure interval to a profile.
Supply a unique `id`, the four assessment inputs, `approved` and evidence for
pressure, native environment, support and size. `begin()` records entry without
rolling or advancing time. Resolve a fresh `RpgExpandedPressureCheck` at entry
and at each `dueAt` while crushing checks are required. Checks use the shared
resistance and injury procedures; a failure's margin determines injury before
size scaling. Retain each check object for repeat-safe execution.

The enclosing action advances the shared clock. Early checks block; missed
checks also block, requiring the caller to schedule exposure checks at their
actual deadlines rather than silently skip them. `end()` refuses to discard a
currently due check. Pressure/protection changes require ending the interval and
starting a new one; overlapping intervals are rejected. The shared clock refuses to advance past an unresolved entry or minute check.
It can reach a future deadline exactly, but the author must resolve the check
before advancing further; the clock does not automatically roll. Immune and ended
intervals do not impose pressure deadlines.

Unrestricted changing-pressure travel and inferred safe decompression schedules remain pending.
See the authored-stage and illness procedures below for the supported subset. Threshold, size, duplicate,
missed-deadline, rollback, undo and save-continuation fixtures are authored but
unrun pending recorded validation.

Pressure exposures now default native pressure from
`profile.nativePressureHundredths`; an explicit `nativePressure` overrides it.
`resolvedSupport()` uses the greater of authored external support and the profile's
active pressure-support purchase. Neither adds to the other. Effective protection
and native pressure are bound when the interval begins. A changed feature,
mitigated purchase or different effective tier rejects before the next check;
finish/reassess exposure through an authored transition instead of silently
changing an active interval. Purchase support is supplied by the traits module;
the hazards module remains usable without it.

Pressure deadlines are validated against entry time and the owned ordered check
history. Editing a deadline or end marker rejects rather than allowing an action
to bypass exposure. Clock-boundary, immunity, ended-exposure and schedule-mutation
fixtures are authored but unrun.

## Decompression examples

`rpgExpandedAssessDecompression(pressure, nativePressure, support, seconds,
humanExamples)` assesses return to native pressure using only full-2008 B435's
printed boundaries. Pressure inputs use hundredths of an atmosphere. The general
risk thresholds and support immunity apply first. Set `humanExamples` only when
the author confirms the reference's baseline-human examples are appropriate;
those examples require native pressure 100.

At up to two atmospheres the baseline return is safe regardless of duration. Up
to 2.5 atmospheres the listed safe duration is 4,800 seconds; beyond that, slow
decompression is required. At 5.5 atmospheres or above there is no listed safe
period. Exactly four atmospheres returns the approximate reference value 1,320
seconds with `approximate = true` and blocked status requiring author judgment.
No interpolation is made for other pressures or native environments.

A ready result sets either `safeReturn` or `slowRequired`. A blocked result means
the reference has not supplied a sufficiently exact limit; neither false flag
establishes safety. `referenceSafeSeconds` is informational. No result simulates
a decompression schedule, rolls for illness or moves the character.

`exposure.assessReturnToNative(humanExamples)` uses the bound constant exposure's
elapsed duration, or its recorded end time after closure. It is a pure assessment
and does not end an interval or clear a due crushing check. Boundary, support,
unknown-environment and recorded-duration fixtures are authored but unrun.

Exposure records snapshot `entryNativePressure` and `entrySupport` at entry.
Active intervals compare these with the live character and external protection;
completed intervals retain the historical values without consulting later trait
changes. Consequently, subsequent mitigation or native-pressure changes do not
block time because of an old exposure. Historical return assessment uses that
completed interval's end time and protection, not eligibility for a later new
return. Editing the stored entry facts still rejects. Closed-history and saved
continuation fixtures are authored but unrun.

## Authored decompression schedules

`RpgExpandedDecompressionPlan` executes an author-approved schedule (full-2008,
B435). Supply `id`, the completed source `RpgExpandedPressureExposure`, `stages`
as `[pressureHundredths, durationSeconds]` rows, `approved` and `evidence` explaining
why that exact schedule is accepted for the exposure. Pressures must strictly descend from the source pressure, never below native
pressure, and the last stage must be at native pressure. Combine equal-pressure
holds into one row; hold time at the original pressure belongs to the source
exposure before it is closed. Every stage has positive duration. No duration is generated from the
sparse printed examples, and approval is not inferred from the list's shape.

Begin immediately when the source interval ends. `begin()` creates the first
owned pressure exposure. Use `RpgExpandedDecompressionProgress` with `plan`, the
one-based `stage` and `seconds` to advance the shared clock and record credit once.
Retain each progress object for replay. Split progress at any crushing-pressure
deadline and resolve an ordinary `RpgExpandedPressureCheck` against the current
entry in `plan.exposures`. After all stage seconds have been recorded and any due
check resolved, `finishStage()` closes the interval and opens the next one, or
records `completedAt` at the final stage.

Unrelated time advances are blocked during the schedule; elapsed counters must
match owned progress records. Use engine action transactions and allow exceptions
to roll back the whole action, including the in-flight progress marker. A failed
or interrupted schedule does not count as completed. Concurrent schedules for
multiple characters, changes to protection/native pressure, abandonment, emergency
ascent remain explicitly unsupported. Illness following a separately completed unsafe
exposure has the limited procedure below.

A completed plan proves execution of the authored schedule, not independently
verified safety. Shared-clock exclusion, repeat-safe credit, multi-stage execution,
rollback, undo and cross-process continuation fixtures are authored but unrun.

Crushing checks remain mandatory inside a decompression stage: the entry check
must resolve before time advances, and a check due exactly when a stage's hold
ends must resolve before `finishStage()`. A rejected progress action must unwind
through the engine transaction so its in-flight marker rolls back. Integration
fixtures cover these boundaries and reject repeated-pressure rows without time
or randomness; they remain unrun.


## Unsafe-return illness and hourly recovery

`RpgExpandedDecompressionIllness` implements the unsafe-return outcomes
of `full-2008`, B435. Supply an owned, completed pressure `source`, a unique `id`,
`unsafeReturn = true`, `approved = true` and original `evidence` explaining why
the return was too rapid. Set `humanExamples` only when the printed human examples
apply. The record must start at the exposure's end time; a known safe return,
an active decompression plan or another active illness prevents onset. Unknown
safe limits require the author's explicit unsafe-return judgment; the procedure
does not infer a decompression schedule.

`assess()` previews eligibility. `apply()` commits one health check: critical
success ends without symptoms, ordinary success starts agony, ordinary failure
causes unconsciousness, and critical failure causes death. The default
`failureMode = 'unconscious'` selects the unconsciousness branch. Alternatively,
set `failureMode = 'paralysis'`, `positionAssessed = true` and `balanced` to the
authored onset position. This keeps the patient conscious but applies the shared
paralysis restrictions, including loss of active defenses and speech or movement.
An unbalanced patient falls prone. Missing position assessment blocks before a roll. Repeating `apply()` returns its stored result.

Create a fresh `RpgExpandedDecompressionRecovery` with `episode` pointing to the
illness for each hourly check. It must execute exactly at `episode.dueAt`.
Successful recovery from agony ends the illness. Success from unconsciousness
starts agony; the paralysis alternative follows the same hourly progression.
Failure in either initial failure branch applies one die of injury through the
shared wound procedure. Other causes of unconsciousness still prevent waking.
A failed agony recovery continues the pain for the next hour.

Each hour of pain owns a standard `RpgExpandedAgony` record, accessible as
`episode.agony`. Pay its ordinary minute fatigue receipts through `pay(id)` as
time advances. Hourly recovery does not replace those payments. The clock refuses
to skip either an agony payment or an illness recovery boundary. No separate
injury, fatigue or time balance is introduced. Run commits inside normal engine
actions and let exceptions propagate so transaction rollback restores all effects.

Recompression symptom treatment is described below. Emergency ascent from an
active plan and simultaneous explosive decompression remain pending. This procedure does not
claim those combinations. The minimal integration fixture is
[`expanded-decompression-illness.t`](../../tests/fixtures/expanded-decompression-illness.t).
Its onset, recovery, preview, replay, rollback, undo and cross-process continuation
fixtures are authored but unrun pending recorded validation.


Illness-owned paralysis persists through the exact hourly boundary until recovery
changes its phase. Illness-owned agony also remains active at that boundary until
the hourly check commits; a zero-time action cannot exploit expired pain before
that check. Continuing agony installs a fresh minute-payment record without a
second payment for a repeated recovery request. The ordinary finite-duration
paralysis and agony records retain their existing behavior.

[`expanded-decompression-paralysis.t`](../../tests/fixtures/expanded-decompression-paralysis.t)
covers missing position evidence, conscious immobility, failed hourly recovery,
transition to agony, rollback, undo and save continuation. These fixtures are unrun.


## Recompression symptom treatment

`RpgExpandedRecompression` binds an illness `episode` to an active pressure
`exposure` for the same patient. The maintained pressure must equal the original
illness exposure. Supply `highestConfirmed = true`, `approved = true`, a unique
`id`, and `evidence` confirming that this is the highest relevant pressure
experienced. A more complex pressure history needs explicit author review; the
library does not infer the highest pressure from unrelated historical episodes.

`assess()` is a preview; `begin()` records the start time without advancing time
or rolling. Create a fresh `RpgExpandedRecompressionCheck` pointing to `treatment`
for each check, exactly every 300 seconds after treatment begins. Each check uses
health +4 (`full-2008`, B435). Failure leaves symptoms in place. Success clears
this illness's agony, paralysis or owned unconsciousness. It does not revive a
dead patient or clear another cause of unconsciousness. Repeated requests return
the recorded outcome without rerolling or charging resources.

Continue existing agony minute payments and pressure entry/minute checks while
treatment is active. The five-minute deadline cannot be skipped. Ordinary hourly
illness recovery remains available until symptom relief; when deadlines coincide,
the author chooses which check to resolve first. Successful treatment can prevent
an outstanding illness check, but never erases already committed consequences.
At a minute boundary, resolve treatment before charging the next minute if it
succeeds; prior fatigue remains spent. Standard timed agony retains its prior
payment behavior.

Call `cancel()` before ending or changing the maintained pressure. Cancellation
ends treatment eligibility without curing symptoms or resetting ordinary illness
recovery. A later approved treatment has its own five-minute start time. Pressure
exposure remains active after symptom relief until the author ends it, so its own
crushing checks and safe-return requirements still apply.

This currently implements symptom relief. The source's phrase about recovery
from all effects does not explicitly specify how to reconcile previously applied
injury with the shared wound ledger; injury restoration remains unresolved and is
not counted as implemented. Emergency ascent and multi-stage treatment changes
also remain pending. See
[`expanded-recompression.t`](../../tests/fixtures/expanded-recompression.t) for
minimal integration and authored rollback, undo, replay and persistence fixtures.
All new fixtures remain unrun pending recorded validation.


## Sudden acceleration

`rpgExpandedAssessAcceleration(acceleration, homeGravity, orientation)` is a pure
assessment using thousandths of standard gravity. Supported orientations are
`upright`, `seated`, `prone` and `inverted`. The trigger treats home gravity below
100 as 100, requires a check from 2.5 times that home value, and applies -2 for
each complete doubling above the trigger. Seated or prone adds +2; inverted adds
-2. The printed five-times-home and ten-times-home cases therefore give -2 and -4
before position modifiers (`full-2008`, B434).

For execution, create `RpgExpandedAcceleration` with a unique `id`, `profile`,
the same three physical facts, `approved = true` and original `evidence` that
this was a sudden acceleration. Supply `dropDestination` where needed for the
shared injury procedure. `assess()` checks all possible fatigue consequences
before rolling. `apply()` records the onset and consumes no randomness below the
trigger. Failed resistance spends fatigue equal to the failure margin through
`RpgExpandedAccelerationFatigueLoss`; exhaustion injury uses the existing wound
ledger. A critical failure also records ten seconds of blackout per failure point.

`recover()` is available once that blackout duration has elapsed, without another
roll or time charge. The clock stops at its expiry until recovery is committed.
The episode owns unconscious recovery during the blackout; exhaustion, mortal
injury and other independent causes can still prevent waking afterward. Repeated
onset and recovery requests are idempotent. Run commits inside normal engine
actions so exceptions restore the complete transaction.

Current execution supports effective resistance scores 3 through 16. Higher
scores can critically fail without a positive mathematical failure margin; the
supplied procedure does not resolve the resulting fatigue/blackout boundary.
Those cases reject before randomness rather than inventing a minimum duration.
Already unconscious patients are also explicitly unsupported. Collision injury from being thrown against a surface is a separate receipt,
described below; the health check must not be used in its place. The minimal fixture is
[`expanded-acceleration.t`](../../tests/fixtures/expanded-acceleration.t).
Expected-value, preview, replay, rollback, undo and persistence fixtures are
written but unrun pending recorded validation.


## Acceleration against a surface

`RpgExpandedAccelerationImpact` binds one physical impact to an already committed
`accelerationEvent`. Its `injury` is an uncommitted `RpgExpandedFallInjury`
template for that event's profile, with `fall = accelerationEvent`, approved
impact evidence, actual protection and location facts. Set `hard` for an
immovable hard surface. The adapter supports the existing torso/limb injury
subset; it does not assert a collision merely because acceleration occurred.

The source velocity is ten times acceleration in standard gravities (B434).
The adapter uses `velocityScale = 100` for hundredths of yards per second, so
`injury.damageVelocity` equals the event's acceleration in thousandths of standard
gravity. For example, acceleration 250 becomes 2.5 yards per second. Binding the
physical event prevents substituting another velocity or using its receipt for a
different character. An optional landing receipt is inapplicable and rejected.

Call `assess()` and `apply()` at the recorded event time. Damage is rolled once,
then committed through the shared collision protection and wound procedures.
The existing impact history prevents another impact receipt from charging the
same event again. The acceleration health check, its fatigue and this physical
impact remain separate consequences; either can apply without the other. The
adapter adds no elapsed time. To commit both consequences atomically, call them
inside one engine action and reject blocked outcomes so the action rolls back.

`rpgExpandedAssessScaledCollision(capacity, velocity, scale, hard)` supports
velocity scales 1, 10, 100 and 1000. It retains fractional velocity through the
collision calculation and rounds only the resulting damage expression. Existing
`rpgExpandedAssessCollision` calls still use scale 1. General `RpgExpandedFallImpact`
records may declare a scale, but existing landing receipts require scale 1.

See [`expanded-acceleration-impact.t`](../../tests/fixtures/expanded-acceleration-impact.t)
for a minimal integration fixture. Fractional thresholds, equivalence to whole
speeds, duplicate prevention, preview, rollback, undo and save continuation
fixtures are authored but unrun. Multiple successive impacts from a single event,
unsupported hit locations and special anatomy remain outside this adapter.


## Free-fall entry and adaptation

`RpgExpandedFreeFallExposure` implements entry and adaptation from `full-2008`,
B434, using the skill/default comparison described on B197. Supply a unique `id`,
`profile`, `approved = true` and original `evidence` establishing first entry,
physiology and continuing free fall. `native = true` avoids an entry check.
`susceptible = true` selects the B156 susceptibility procedure: health -4 at
entry and no subsequent adaptation checks. These physiological flags are explicit author facts. When the traits module is
installed, an active `RpgExpandedFreeFallSusceptibility` purchase automatically
supplies susceptibility; the trait also supplies purchase and learning restrictions. Contradictory native/susceptible facts reject.

An optional expanded `skill` must be the dexterity/average `free-fall` skill.
Ordinary resistance selects the better of health and the supplied skill score.
Without a supplied skill, `RpgExpandedFreeFallSkill` supplies both printed
attribute defaults. Health -5 cannot exceed the health alternative for entry. Susceptibility uses health
with its printed penalty. `assess()` previews; `apply()` commits once. Failed
entry creates both a persistent nausea cause and a `RpgExpandedNauseaMotion` in
`exposure.motion`. No duration is guessed for the nausea.

Use the existing `RpgExpandedNauseaMotionHour` interface every completed hour,
including explicit retching/oral-effect preparation. Create a fresh
`RpgExpandedFreeFallAdaptation` pointing to `exposure` for each eight-hour check.
Resolve the completed eighth motion hour before attempting adaptation. Successful
adaptation ends this exposure's nausea and motion triggers; an independent nausea
cause or retching episode remains intact. Failed adaptation schedules another
check eight hours later. The shared clock prevents either deadline being skipped.

`leave(true, evidence)` records an authored return to normal gravity and ends
only this exposure's causes, including for susceptible characters. Resolve a
completed motion hour before leaving at its exact boundary. Repeated entry,
adaptation and exit operations do not duplicate costs or rolls.

Sealed-suit choking/drowning, mid-exposure trait changes, ancestry composition
complete movement integration remain outstanding. The orientation-sense trait
now supplies the spatial-awareness skill bonus. The fixture
[`expanded-free-fall.t`](../../tests/fixtures/expanded-free-fall.t) covers entry,
health/default choice, hourly integration, adaptation, return to gravity,
independent nausea, rollback, undo, replay and save continuation. It is unrun
pending recorded validation.


## Sustenance deprivation

`RpgExpandedSustenanceDeprivation` starts an owned uninterrupted deprivation
schedule (`full-2008`, B130). Supply `id`, `profile`, an owned active `requirement`,
approval, evidence that required access has just been missed, and a drop destination
when equipment could be dropped by an injury consequence. Include the traits
module to validate the purchase. `begin()` records the current shared time once;
the first injury falls one injury interval later. Monthly and longer dose deadlines
must already have been established by the author; this operation does not invent
a calendar or infer satisfaction from elapsed time.

Create `RpgExpandedSustenanceInjury` receipts with unique IDs and the episode.
Pure `assess()` preflights the shared wound path. `apply()` at the exact due time
adds one point of injury through that path, preserving its survival and equipment
consequences. Replay does not add another wound, spend time or roll again. The
clock cannot cross an unsettled injury boundary. Episode history binds its original
requirement, interval and tick sequence. Death ends the need to settle later ticks.

Periodic object/environment contact can restore access as described below.
Mitigation/removal during an episode, resource consumption,
calendar ownership and accelerated aging remain pending. Do not begin an episode
that needs those unsupported transitions; no automatic cure or silent clock
cancellation is supplied. Contact-duration metadata alone is not an access receipt.

[`expanded-sustenance-injury.t`](../../tests/fixtures/expanded-sustenance-injury.t)
and `test_sustenance_injury` specify exact boundaries, one-point ticks, replay,
preview purity, exception rollback, undo and cross-process save continuation.
These fixtures remain unrun pending recorded validation.


### Restoring periodic contact

`RpgExpandedSustenanceContact` owns one uninterrupted object/environment contact
interval for an `episode`. Set approval and evidence of actual qualifying access,
set `contactPolicy = 'uninterrupted'`, and explicitly choose `boundaryOrder = 'access-first'` or `'injury-first'`.
This tie ordering is an authored ruling: B130 specifies duration but does not
settle simultaneous completion and injury. `begin()` records the shared clock;
it does not spend time, assume a dose was consumed, or cancel deprivation.

Advance time through ordinary operations, settling any due injury ticks.
`assessCompletion()` requires the full source contact duration. With injury-first,
an injury due at that instant must be settled first. `finish(true, evidence)`
requires author confirmation that qualifying contact remained uninterrupted;
it records restoration once and releases the deprivation clock guard. Existing
injury remains. Repeated completion returns the receipt without spending time.

The restored episode remains historical. A new episode with a distinct ID may
start after a later author-confirmed missed deadline. Automatic recurrence and
calendar tracking remain pending. Continuous requirements, substances, accumulated contact and mitigation/removal
transitions are not supported by
this contact operation. A generic elapsed-time interval alone does not establish
qualifying access; the author must connect the receipt to actual world events.

[`expanded-sustenance-contact.t`](../../tests/fixtures/expanded-sustenance-contact.t)
and `test_sustenance_contact` cover both authored boundary choices, short contact,
clock release, replay, rollback, undo and save continuation. Fixtures are unrun.


### Interrupting and restarting contact

The source does not define accumulation across interruptions. The explicit
`contactPolicy = 'uninterrupted'` selects a campaign ruling: each successful
contact must supply the entire duration in one interval. Other values reject
before commitment; this is not presented as the only published interpretation.

Call `interrupt(true, evidence)` when qualifying contact ceases. It records the
shared timestamp without ending deprivation or changing existing injury. The
interrupted receipt can no longer complete. Begin a fresh contact object to
restart; the earlier elapsed time is not credited under this policy. The episode
keeps each interval, verifies chronological non-overlap and retains the latest
contact identity. Repeated interruption or completion reuses the stored result.
World movement adapters must record interruptions when access actually ends.

[`expanded-sustenance-interruption.t`](../../tests/fixtures/expanded-sustenance-interruption.t)
and `test_sustenance_interruption` specify partial-duration rejection after a
restart, continued injury, replay, rollback, undo and save continuation. These
fixtures remain unrun. Accumulated-contact policies remain unimplemented.


### Restoring access with a substance dose

`RpgExpandedSustenanceStock` uses the ordinary item inventory and quantity ledger.
Its `requirementScope` identifies the authored requirement; each unit is one
sufficient dose. The author defines dose size and suitability in the world.
`RpgExpandedSustenanceDose` supplies a unique `id`, `episode`, owned `stock`,
approval, ingestion evidence and the same explicit `boundaryOrder` ruling used
for contact. It requires a periodic substance requirement, a living conscious
subject who is not retching, and an accessible uniquely owned stock unit.

`assess()` is pure. `apply()` consumes one unit, removes an exhausted stack from
inventory, and records restoration once. It does not heal injury, add another
time charge or consume again on replay. Injury due at the same instant follows
the authored boundary choice. The clock guard releases after restoration, and a
later missed deadline can start a distinct episode. Purchase and action duration
remain with their existing author operations; this receipt records ingestion at
the shared clock rather than inventing a universal ingestion duration.

Continuous supplies, assisted ingestion, later regurgitation, automatic dose
scheduling and calendar recurrence remain pending. A stock match alone does not
establish ingestion; the author must provide that fact from the actual action.
[`expanded-sustenance-dose.t`](../../tests/fixtures/expanded-sustenance-dose.t)
and `test_sustenance_dose` specify both boundary choices, absent stock, one-time
consumption, clock release, rollback, undo and save continuation. Fixtures are unrun.


### Owning a later missed deadline

`RpgExpandedSustenanceDeadline` registers the next period after an episode's
recorded restoration. Supply unique `id`, the restored `source` episode, approval
and evidence. Register at the same shared time as restoration, before advancing
time. Hourly, daily and weekly requirements calculate their fixed due time.
For monthly, seasonal or yearly requirements, supply `calendarId`, `boundaryId`
and `calendarDueAt`, with evidence identifying the actual one-, three- or
twelve-month campaign boundary. These dates are authored calendar facts, not a
fixed-seconds conversion. Duplicate source registrations and calendar boundary
identities for the same requirement reject.

Pure `assess()` reports the interval; `register()` binds the deadline once.
The clock cannot cross it unsettled. At exactly `dueAt`, supply a fresh matching
`RpgExpandedSustenanceDeprivation` with evidence of missed access to
`assessMissed(episode)` and `miss(episode)`. The latter starts that episode once;
its first injury is one injury interval later, not at the missed deadline.
Replay retains both receipts without another episode or time charge.

The missed-deadline path, timely substance doses and full uninterrupted contact
ending at the deadline are supported. Early access and automatic recurrence remain pending; initial access uses the
explicit campaign-start receipt described below. Do not register a cycle that needs
those unsupported paths. Continuous requirements use a separate access model and reject
this periodic API.

[`expanded-sustenance-deadline.t`](../../tests/fixtures/expanded-sustenance-deadline.t)
and `test_sustenance_deadline` specify a fixed day, an authored 28-day calendar
month, boundary guards, replay, rollback, undo and save continuation. Fixtures
remain unrun; the calendar example is not a universal month-length rule.


### Timely substance doses

`RpgExpandedSustenanceDueDose` supplies a registered `deadline`, matching owned
`stock`, approval and evidence of actual ingestion. It is available exactly at the
owned due time, before the deadline is declared missed. Assessment is pure and
performs the same stock availability, unique ownership and ingestion eligibility
checks as deprivation-restoring doses. `apply()` consumes one ordinary inventory
unit and records the deadline's `fulfillment` once. An exhausted stack leaves the
inventory. It adds no injury, deprivation episode, randomness or time charge.

A deadline cannot be both fulfilled and missed. Repeated application reuses its
receipt after the stock is exhausted, and time can advance beyond the settled
boundary. Early dosing and automatic next-period registration remain pending;
this operation does not silently choose a rolling or fixed schedule for early
access. Timely contact requirements use the duration-aware settlement below.

[`expanded-sustenance-timely-dose.t`](../../tests/fixtures/expanded-sustenance-timely-dose.t)
and `test_sustenance_timely_dose` specify fixed and calendar deadlines, premature
requests, mutually exclusive outcomes, one-time consumption, rollback, undo and
cross-process save continuation. Fixtures remain unrun.


### Timely object and environmental contact

`RpgExpandedSustenanceDueContact` supplies the registered `deadline`, approval,
evidence of actual access and `contactPolicy = 'uninterrupted'`. This explicitly
selects the same no-accumulation campaign ruling as restoration contact. `begin()`
records the shared time and requires enough time remaining to supply the full
contact duration within the registered period. It does not charge time or mark
the requirement satisfied merely because contact started.

At the deadline, `assessCompletion()` requires that full elapsed interval.
`finish(true, evidence)` records author-confirmed uninterrupted qualifying contact
as fulfillment. It creates no deprivation or injury and releases the boundary
once. Missed and fulfilled outcomes remain exclusive. Contact spanning outside
the registered period cannot receive credit from this operation.

This path covers uninterrupted contact ending at the deadline. Early completed
contact, interruption/restart within a timely period, accumulated contact and
automatic recurrence remain pending. Authors must not confirm continuity when
world movement or changed conditions interrupted access.
[`expanded-sustenance-timely-contact.t`](../../tests/fixtures/expanded-sustenance-timely-contact.t)
and `test_sustenance_timely_contact` specify the full duration, premature
completion, replay, clock release, rollback, undo and save continuation. Fixtures
remain unrun.


### Successive fulfilled periods

To continue after timely fulfillment, create another
`RpgExpandedSustenanceDeadline` with the same restored `source` episode and set
`previous` to the latest fulfilled deadline in that chain. Register it at the
shared time of fulfillment. Fixed periods calculate the next due time from that
instant; calendar periods retain `calendarId` and require a new `boundaryId` and
an explicitly authored `calendarDueAt`. Both timely doses and timely contact can
anchor the successor through their bound fulfillment receipts.

Only the latest fulfilled period can be extended. Unfulfilled predecessors,
branching from older periods, duplicate identities, changed calendars and delayed
registration reject. A missed period instead leads to a fresh deprivation episode;
after restoration, that episode starts its own deadline chain. Replays and saved
successors preserve the original due time and do not consume more stock.

Registration remains an explicit author action, normally in the same transaction
as fulfillment. There is no automatic calendar generator or catch-up loop. Early access and automatic setup remain pending. Initial access without a prior
deprivation uses the receipt below. [`expanded-sustenance-recurrence.t`](../../tests/fixtures/expanded-sustenance-recurrence.t)
and `test_sustenance_recurrence` specify successive daily periods, the unfulfilled
predecessor gate, replay, rollback, undo and save continuation. Fixtures are unrun.


### Starting from satisfied access

`RpgExpandedSustenanceInitialAccess` records an initial campaign fact. Supply
unique `id`, `profile`, owned periodic `requirement`, approval and evidence that
sufficient access has just occurred and its resources are already reflected in
the starting state. `record()` binds the current shared time and definition once;
it creates no deprivation, injury, time charge or inventory change. It is an
initialization interface, not an alternative live consumption action.

Use this receipt as a deadline's `source` and register at the same clock time.
Subsequent deadlines, timely doses, contact and missed-period transitions use the
ordinary owned procedures. The receipt rejects another initial record for the
requirement, or an initial record after existing deprivation/deadline history,
so it cannot reset an active obligation. Continuous access remains a separate
unsupported initialization case.

[`expanded-sustenance-initial.t`](../../tests/fixtures/expanded-sustenance-initial.t)
and `test_sustenance_initial` specify no initial resource charge or fictional
injury, duplicate rejection, rollback, undo, save continuation and later inventory
consumption. Fixtures remain unrun.


### Continuous object and environmental access

`RpgExpandedContinuousSustenanceAccess` records actual continuous access with
unique `id`, `profile`, owned `requirement`, approval and world-fact evidence.
The requirement must be continuous and use an object or environment. Select
`boundaryOrder` explicitly for restoration coinciding with a due injury, as with
other access operations. `begin()` records initial access without a periodic
contact duration; periodic deadline APIs continue to reject this frequency.

When access ends, pass a fresh matching deprivation episode with loss evidence
to pure `assessLoss(episode)` and then `lose(episode)`. Loss records the current
clock and starts the existing one-injury-per-minute schedule once. Beginning a matching deprivation also closes its active continuous-access
receipt through the same loss binding, so direct episode integration cannot leave
an overlapping satisfied state. At actual restoration, create a fresh continuous-access
receipt naming that `episode`; `begin()` stops future deprivation ticks while
retaining existing injury. Simultaneous tick ordering follows the selected ruling.

Access and loss receipts retain identity and timestamps. Concurrent active access
for the same requirement rejects; replay does not restart the injury clock.
These are concrete author-confirmed world transitions. Automatic location changes,
continuous substance ingestion, finite supply-device consumption and aging remain
pending; this interface does not manufacture or consume an environmental supply.

[`expanded-sustenance-continuous.t`](../../tests/fixtures/expanded-sustenance-continuous.t)
and `test_sustenance_continuous` specify minute injury, loss/restoration replay,
rollback, undo and cross-process save continuation. Fixtures remain unrun.


### Assessing deprivation-related aging

`rpgExpandedSustenanceAgingPlan(profile, oldAgeMonths)` is a pure assessment of
the two years added by one qualifying injury point (`full-2008`, B130). It uses
the existing aging schedule (B444, B53, B154) and returns `oldAgeMonths`,
`newAgeMonths`, `addedYears = 2` and `boundaryAgeMonths`. The starting age must
be an authored exact month boundary; the function does not infer a birthday or
round an age measured in days. Boundaries after the old age and through the new
age are included, including transitions to more frequent aging checks.

Ordinary aging immunity does not remove these boundaries: B130 explicitly makes
this effect apply to otherwise ageless characters. Extended lifespan and
month-based shortened-lifespan bands use the shared schedule. Crossing a day-based
band returns `sustenance-aging-day-calendar-required` and no partial boundary
list, because exact campaign day/month relationships are needed.

The helper is assessment coverage; owned execution is described below. The helper does not change age, attributes, time or randomness and does
not by itself execute the modifier. It will support preflight of the owned
aging operation rather than introduce a second age ledger.

[`expanded-sustenance-aging-plan.t`](../../tests/fixtures/expanded-sustenance-aging-plan.t)
and `test_sustenance_aging_plan` specify young ages, the three ordinary frequency
bands, ageless characters, extended and shortened lifespan, and explicit rejection
of unresolved day calendars. Fixtures remain unrun.


### Applying deprivation-related aging

Set `acceleratedAging = true` on a sustenance purchase to apply its +30% modifier
through the shared signed-price arithmetic (`full-2008`, B130). Template copies
preserve it. Each deprivation injury then requires its own
`RpgExpandedSustenanceAgingAdvance` in `tick.agingAdvance`. Supply a unique `id`,
that `tick`, exact `oldAgeMonths`, `calendarId`, approval, age evidence and
`medicalTL`. A missing or mismatched advance rejects before injury or randomness.

The injury transaction records one two-year increment and its bound boundary
plan. Replaying the injury neither adds years nor duplicates its wound. The
receipt is causal age history, not an independent ticking age counter. Successive
increments in the same rejuvenation era must not overlap, and their calendar
must agree with ordinary aging history. Authors account for natural elapsed age
when supplying the next exact age.

Call `applyNextBoundary()` until complete. Each required boundary executes the
existing four-roll aging procedure and records its losses in `agingHistory`,
including for otherwise ageless characters. Rejuvenation can therefore use the
same loss records. Ordinary aging retains its normal exemption. Completed checks
are not rerolled; time cannot advance with unsettled checks while the character
is alive. Death ends further checks. No extra adventure time is charged.

Day-based shortened-lifespan intervals require the explicit calendar mapping
below. Sequences that could enter an unsupported derived-stat or low-score state
reject before injury. Negative
secondary adjustments are permitted when the full sequence remains supported. Day-level age inputs remain unsupported.
These limits keep the modifier partial; they are not substitute rules. The
existing optional equivalent-trait-loss adjudication is also outside this path.

[`expanded-sustenance-aging.t`](../../tests/fixtures/expanded-sustenance-aging.t)
and `test_sustenance_aging` specify modifier pricing/copying, one injury's two-year
increment, checks despite ordinary immunity, pending-check time guards, replay,
rollback, undo and save continuation. Fixtures remain unrun.


`rpgExpandedSustenanceAgingPreflight(profile, count, medicalTL)` evaluates each
planned boundary with the lowest still-living attribute scores reachable under
its maximum loss, applying the existing longevity and medical/fitness rules.
Temporary scores are separate from the live character. This permits supported
negative secondary purchases without changing ordinary aging results; unsafe
combinations return the shared procedure's reason before injury or random draws.
It does not infer that the character will actually suffer those worst losses.

[`expanded-sustenance-aging-adjustments.t`](../../tests/fixtures/expanded-sustenance-aging-adjustments.t)
and `test_sustenance_aging_adjustments` specify a supported reduced-health purchase
through two failing aging boundaries, unchanged preview scores/randomness, and
rejection of a sequence whose later derived state is unsupported. Fixtures are unrun.


### Exact calendar days for accelerated aging

For day-based lifespan bands, provide `RpgExpandedSustenanceAgingCalendar` in the
advance's `calendar`. Supply the matching `calendarId`, approval, evidence,
`months` and `dayBandOrigins`. `months` contains exactly 25 ordered
`[ageInMonths, absoluteCalendarDay]` rows, from the exact starting month through
the end of the two-year increment. Day values must strictly increase. Each
applicable day-based band needs `[startingAgeInYears, absoluteCalendarDay]` in
`dayBandOrigins`. An origin within the mapped span must agree with its month-start
date. The supplied span is limited to 10,000 calendar days.

`rpgExpandedSustenanceCalendarAgingPlan` combines month-based checks at actual
month boundaries with day-based checks at exact intervals from the authored band
origin. It returns both `boundaryAgeMonths` and `boundaryCalendarDays`; multiple
checks within one month retain distinct days. The owned advance binds that map,
executes every planned boundary in order, and stores each loss in the existing
aging history. Owned boundary identities avoid collisions between same-month
checks. No day/month ratio is inferred. The shared aging history still records
whole-year age labels; exact offsets remain in the causal advance.

Starting ages between month boundaries use the explicit endpoint extension
below. Day-precise rejuvenation uses the shared-history operation below. Missing or inconsistent calendar facts reject before injury rather than
using a partial plan. Ordinary month-based advances can still omit the calendar.
[`expanded-sustenance-aging-calendar.t`](../../tests/fixtures/expanded-sustenance-aging-calendar.t)
and `test_sustenance_aging_calendar` specify a calendar-specific transition to
45-day checks, all crossed boundaries, inconsistent-origin rejection and save
continuation. Fixtures remain unrun; the example's month lengths are authored
world facts, not source rules.


### Two-year increments starting within a month

Set both `startDay` and `endDay` on the aging calendar to author exact endpoints.
In this form, supply 26 ordered month-start rows: the first 25 cover the starting
month through the month two years later, and the final row bounds that ending
month. `startDay` must lie within the first month and `endDay` within the
corresponding month two years later. Approval and evidence establish that these
are the actual two-year anniversary dates, including the campaign's handling of
unequal months and leap dates. The engine does not invent that calendar policy.

The planner excludes the starting day and includes the ending day. It records
`oldAgeCalendarDay` and `newAgeCalendarDay` alongside month labels and exact check
dates. The causal receipt binds these endpoints. Successive increments in the
same rejuvenation era cannot move backward within the ending month; a later
month-only assertion cannot erase already-known day precision. Whole-month plans
retain their existing 25-row form when both endpoint fields are omitted.

[`expanded-sustenance-aging-dates.t`](../../tests/fixtures/expanded-sustenance-aging-dates.t)
and `test_sustenance_aging_dates` specify a between-month anniversary, the checks
it crosses, owned execution, replay and cross-process save continuation. Fixtures
remain unrun. Sub-day age precision remains pending; dated rejuvenation is described below.


### Rejuvenation to an exact age date

`RpgExpandedDatedRejuvenation` extends the existing rejuvenation operation
(`full-2008`, B444). Supply its usual ID, profile, calendar, effect evidence and
year labels, plus `oldAgeCalendarDay` and `newAgeCalendarDay` in that same authored
age calendar. The new date must precede the old date; both can lie within the same
year. Evidence establishes the effect and the correspondence between dates and
year labels. This does not cast a spell or manufacture a rejuvenating treatment.

The operation restores recorded losses strictly after the target date through
the former date. A loss at the target date remains. Exact dates come from the
owned sustenance-aging boundary plan. Ordinary aging entries without exact dates
can be classified only when their year lies wholly inside or outside the range;
ambiguous endpoint-year records reject. No dates are guessed for them.

Application uses the existing restoration ledger, marks each restored aging event,
and restores its characteristic losses once. It adds character value without
awarding earned or spendable points. The recorded new rejuvenation era permits
later aging from the younger age. Pending sustenance aging checks must be settled
before rejuvenation; otherwise their ownership would straddle the age change.
Replay binds the exact target dates and cannot restore the same losses twice.

[`expanded-sustenance-rejuvenation.t`](../../tests/fixtures/expanded-sustenance-rejuvenation.t)
and `test_sustenance_rejuvenation` specify selective same-year losses, unchanged
point balances and randomness, rollback, undo and cross-process save continuation.
Fixtures remain unrun. Sub-day age precision remains unsupported.


### Exact dates on ordinary aging records

`RpgExpandedAgingEvent` optionally accepts `calendarDay`, an absolute age-calendar
day in its `calendarId`. Existing `evidence` must establish that date and the
reached aging boundary. The event binds the day when applied. Known exact dates
must strictly increase within the same rejuvenation era; events after a youth
restoration may begin a younger era. Omitting the date preserves the existing
whole-year authoring contract and roll behavior.

Dated rejuvenation can use these ordinary event dates alongside exact causal
aging dates. The original year-based rejuvenation operation keeps its conservative
partial-year handling. Both rejuvenation paths now validate the source aging
receipts before restoring their losses, so a changed date cannot redirect an
already recorded loss to a different target range.

[`expanded-dated-aging.t`](../../tests/fixtures/expanded-dated-aging.t) and
`test_dated_aging` specify two ordinary six-month checks within one year, selective
restoration of the later loss, changed-date rejection, replay, rollback, undo and
save continuation. Fixtures remain unrun.


## Seasickness assessment

`rpgExpandedSeasickness(health,susceptible,movingVehicle,seagoing,stabilized,day,roll)`
implements the supplied-roll outcome distinction in full-2008 B144/B436. The
author supplies actual vehicle facts and one-based journey day. Ordinary
passengers check on the first day aboard a qualifying seagoing vessel at health
+5. Stabilized modern vessels are excluded for ordinary passengers. Trait
susceptibility instead applies daily on any moving vehicle.

The result reports `checkRequired`, `score`, `check`, `penalty` and `vomits`.
Ordinary passengers avoid all effects with a critical success or success by at
least five; lesser success gives −2, and failure gives −5 with vomiting.
Susceptible passengers remain at −2 even on a critical success. An inapplicable
check requires no roll and consumes no randomness.

This is a pure assessment, not an executed journey condition. Trait ownership,
vehicle-skill learning restrictions, daily scheduling, persistent penalties and
actual vomiting remain outstanding. `expanded-seasickness.t` / `test_seasickness`
specify expected values and applicability boundaries; fixtures remain unrun.


## Owned motion journeys

`RpgExpandedMotionJourney` owns a continuous authored trip: set `id`, `profile`,
`movingVehicle`, `seagoing`, `stabilized`, `approved` and `evidence`.
`RpgExpandedMotionDay` supplies that `journey`, a one-based `day` and an unused
ordinary `RpgExpandedRetching` episode for a possible failure. Its episode must
review affected oral benefits before any randomness. Susceptibility comes from
the character's active purchase.

`apply()` records each day once, rolls through the shared check interface and
executes retching on failure. Daily penalties replace the previous value in
`journey.currentPenalty`; days with no new required check preserve the prior
journey penalty. Checks use elapsed 24-hour boundaries, and the clock cannot
skip the next boundary. Set `endEvidence` and call `end()` when the trip ends.
Ending clears the journey penalty; an already-started retching episode retains
its own recovery procedure. Replaying a recorded day spends no randomness.

Journey penalties apply through the shared score interface. Live boarding and
disembarking hooks and partial-day travel interruption remain outstanding. `expanded-motion-journey.t` / `test_motion_journey` specify
pure assessment, daily replacement, actual vomiting, rollback, undo and saved
continuation. Fixtures remain unrun.


### Motion penalties in checks

Active journeys now contribute `currentPenalty` to DX, IQ and all skill checks,
including skills based on other attributes. Unrelated raw attribute checks and
active-defense contexts do not acquire this skill/attribute modifier. Existing
retching still supplies its own concentration and defense restrictions. When
the active retching episode belongs to this journey, its existing −5 attribute
modifier also satisfies the journey's −5 for that same check; it is not charged
twice. Other independent conditions retain their existing effects.

Ending a journey removes its continuing penalty. Retching that has not finished
continues under its ordinary recovery procedure. Journey receipts validate the
current penalty against the latest owned daily result, rejecting edited penalty
state. `expanded-motion-scores.t` / `test_motion_scores` specify affected and
unaffected scores, same-cause overlap, journey-end behavior, saved continuation
and changed-penalty rejection. Fixtures remain unrun pending recorded validation.


## Unconscious swimmer submersion

`RpgExpandedDrowningExposure` extends the existing complete-air-loss procedure
(full-2008, B436–B437). Supply its `id`, `profile`, the active `swimming` encounter,
`approved` and `evidence` that the unconscious swimmer is fully submerged without
air. `assessSubmersion()` is pure. Unconsciousness alone does not establish that
world fact, and a conscious swimmer cannot use this handoff.

`start()` closes the swimming encounter with a bound submersion receipt and starts
the shared airless exposure at the same instant. It charges no time, fatigue or
injury. Subsequent `RpgExpandedAirlessSecond` operations own air deprivation and
its existing fatigue/injury/death boundaries. The swimming ledger retains its
history without continuing swimming checks. Replay cannot duplicate the handoff.

This subtype rejects ordinary `resumeAir()` with
`drowning-resuscitation-required`: clean air alone cannot bypass the required
water-clearing treatment. The staged treatment transition is described below.
`expanded-swim-submersion.t` / `test_swim_submersion` specify conscious rejection,
atomic handoff, one-second air costs, rollback, undo and save continuation.
Fixtures remain unrun.


## Staged drowning resuscitation

`RpgExpandedDrowningResuscitation` supplies `id`, `exposure`, `healer`, a
First Aid or Physician `skill`, `modernTechnique`, optional `modifier`,
`approved` and `evidence` of actual rescue access. It uses the B425 technology
and skill modifiers. `start()` records treatment without charging time. Advance
the existing `RpgExpandedAirlessSecond` operations during the one-minute
treatment; `finish()` requires exactly sixty elapsed seconds and no unresolved
air-deprivation seconds. The minute is not charged a second time.

Successful treatment authorizes the exposure's existing clean-air recovery,
including its brain-injury check when applicable. It does not restore spent
fatigue or injury or immediately awaken a still-exhausted patient. Failure leaves
the exposure active and permits a distinct later attempt if time remains.
Concurrent attempts, inaccessible healers, insufficient time, early completion
and clean-air recovery without successful water clearing reject.

`expanded-drowning-care.t` / `test_drowning_care` specify minute timing, ongoing
air costs, successful recovery, rollback, undo and saved replay. The synthetic
patient has unusually high health capacity to isolate the full minute from death
thresholds; this does not imply ordinary drowning victims survive that delay.
Call `cancel(evidence)` when care is interrupted or abandoned. Cancellation
retains elapsed time, exposure and injury, releases the attempt for a distinct
retry, and prevents the cancelled attempt from finishing. Repeated cancellation
is harmless. The shared clock rejects advancing beyond an unfinished minute;
finish or cancel that attempt before advancing further. A dead patient no longer
holds this clock boundary.

`expanded-drowning-interruption.t` / `test_drowning_interruption` specify
cancellation, retry, completion boundaries, rollback, undo and saved replay.
Fixtures remain unrun. The native rescue-action adapter is described below; patient retrieval and changing world access remain authored responsibilities.


### Rescuer ownership and treatment history

One rescuer can own only one unfinished drowning treatment at a time, even
when patients have different exposures. `assess()` and `start()` return
`drowning-care-healer-busy` before spending time or randomness. Cancel the
previous attempt to release the rescuer; cancellation remains explicit if a
patient dies. Completed and cancelled records do not reserve the rescuer.
This is an execution constraint for the staged treatment interface.

Profile validation checks treatment membership, duplicate identifiers, active
patient ownership, bound completion and cancellation state. Removing a receipt
from the patient's exposure does not make its committed object reusable.
`expanded-drowning-ownership.t` / `test_drowning_ownership` cover cross-patient
contention, release, saved replay and altered histories. These fixtures are unrun.


### Native rescue actions

`RpgExpandedDrowningCareAction` extends the engine's `Action`. Bind `attempt`
to an owned `RpgExpandedDrowningResuscitation` and choose `operation` as `start`,
`finish` or `cancel`. Cancellation also requires `cancellationEvidence`. Bind
the rescuer's world actor through `rpgProfile` to the attempt's `healer`; a
mismatched actor is blocked before the treatment is changed.

Attach the action to authored grammar and a `Verb` for parser and structured
requests. A dialogue choice calls `action.perform(context.asker)`. Both entry
points delegate to the same treatment methods and emit
`rpg.expanded.drowning-care` with `[operation, status, reason]`. Reporting and
player-facing labels remain authored. The adapter does not advance time or
resolve airless seconds; the existing scheduler must do that exactly once.

The concrete three-route integration is in
`tests/fixtures/expanded-drowning-actions.t`. Its `test_drowning_actions`
fixture specifies early completion, successful finish, replay, cancellation,
incorrect actor binding, exception rollback and undo. Fixtures remain unrun.
World movement, patient retrieval and dynamic access changes still require
an authored integration; this adapter does not infer those world facts.


## Exhausted breath reserves

`RpgExpandedBreathExhaustion` extends `RpgExpandedAirlessExposure`. Set `id`,
`profile`, `reserve` and evidence that ordinary air deprivation continues.
`assessStart()` is pure. At exactly `reserve.startedAt + reserve.durationSeconds`,
`start()` closes the reserve and transfers ownership to the airless exposure
without advancing time, rolling or charging fatigue. The first
`RpgExpandedAirlessSecond` is due one second later (full-2008 B352, B436–B437).

The reserve records `airlessHandoff` and an expiry time, not a claim that clean air
was restored. Its `resumeAir()` then rejects with `breath-airless-recovery-owned`;
call the exposure's recovery method instead. Both histories remain available
for profile validation, undo and exact-game save continuation. Repeated starts
reuse the original exposure without replenishing breath.

The caller must schedule the boundary. Early or late requests reject; missed
seconds are not retroactively charged. This handoff covers ordinary deprivation
after fixed-activity breath holding. It does not establish underwater inhalation,
vacuum exposure, changing exertion or loss of reserve before expiry.
`expanded-breath-handoff.t` / `test_breath_handoff` specify timing, replay,
rollback, undo, separate-process continuation and preservation of injury and
fatigue. Fixtures remain unrun.
