# Expanded exploration

**Status: partial.** Tasks, physical feats, senses and travel. Neutral source: `full-2008`, B343-B361; B427.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `RpgExpandedTaskTime` — B346; tested in `tests/expanded.py::test_numbers`.

The module also provides the breath interfaces below. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

## Remaining source obligations

The first source pass is recorded in the [task-resolution inventory](inventory/task-resolution.json),
[physical-activity inventory](inventory/physical-activities.json) and
[sense, influence and fear inventory](inventory/senses-influence-fear.json).
These include pending requirements and partial mappings for task timing and
breath reserves. Numeric rows have not yet received independent validation.

`RpgExpandedTaskTime` assesses a duration and modifier. It does not execute a
task, record the single cinematic instant attempt, resolve skill-specific timing
exceptions or manage a long project. Its applicability flag remains a caller
input rather than a complete author contract.

Long projects need owned labor records, separate work categories, supervisor
effects, long-shift fatigue and lost work on critical failure. Travel, swimming,
climbing and effort likewise need interval state so interrupted actions, undo and
save continuation cannot skip or repeat a boundary cost.

Gravity changes must distinguish weight from mass. Jumping, encumbrance and
throwing range respond differently, and zero gravity needs its own movement
procedure. Source tables alone do not supply those interactions.

Some chapter procedures belong elsewhere: equipment quality to equipment,
influence to social, fear consequences to health, combat effort to combat and
optional point-funded outcome changes to campaign. Their dependencies must share
one action result and resource ledger.

Foraging requirements are recorded in the [health-chapter inventory](inventory/health.json)
because that is where the source presents them, but exploration owns their
execution. Daily attempt allowances differ between travel and a dedicated
foraging day. Gathered meals, poisoned food and preserved rations must update the
same inventory consumed by health's food and water procedures.


[Flight and growth traits](inventory/traits-catalogue-f.json) add movement
requirements beyond the chapter procedures. Gliding retains fractional velocity,
altitude and level-flight deceleration; updraft searches have a one-minute retry
boundary. Winged movement checks clearance and individual wing injury. Space
travel can consume a velocity-change reserve while continuing to coast. These
requirements remain pending, and the task-time helper does not implement them.


## Breath duration and owned reserves

`rpgExpandedBreathDuration(health, activity, prepared, ventilation,
controlSucceeded, reserveLevels)` assesses the B351–B352 duration. Activity is
`none`, `mild` or `heavy`; ventilation is `none`, `air` or `oxygen`. Unprepared
breath halves the base duration and cannot claim prior hyperventilation. A
successful breathing-control check multiplies duration by one and a half, and
each eligible reserve level doubles it. All factors combine before final
rounding down to whole seconds under B9. This helper draws no dice and spends
nothing. It does not perform the breathing-control check or grant a trait.

`RpgExpandedBreathReserve` owns one fixed-activity interval. Supply a unique `id`,
`profile`, the assessment inputs and `evidence` recording the actual preparation,
oxygen source, control-check outcome and eligible reserve levels. Prepared breath
requires a previously completed one-second action; in combat that action must
be concentration. The reserve does not charge that action again. Without an owned preparation
receipt, it accepts these facts from the author. The owned preparation interface
below supplies a noncombat action and skill check; catalogue trait eligibility
remains authored. Record the source of each applicable fact in the evidence.

`start()` snapshots health and duration at the current shared time. Repeating it
returns the original receipt. A second active reserve, or an existing nonzero
`airClock`, blocks a new one. `assess()` returns elapsed and remaining seconds
without advancing time. The author must keep activity and preparation conditions
fixed; changing exertion, interruption, unconscious inhalation and exceptional
physiology remain unsupported and need explicit scenario handling. Changing
bound request fields is rejected rather than silently replenishing air.

`resumeAir(evidence)` ends the reserve when breathable air is restored before or
at expiry. It never restores fatigue. After expiry it blocks with
`breath-suffocation-unresolved`, because downstream fatigue and brain-injury
procedures must first account for the elapsed time. The active reserve prevents
calling `rpgLiteSuffocate` through a default-inert `validateSuffocation()` hook,
so the two procedures cannot consume or reset the same exposure independently.
The hazards library supplies an explicit `RpgExpandedBreathExhaustion` handoff
at the expiry boundary; see [Exhausted breath reserves](hazards.md#exhausted-breath-reserves).
An expired assessment alone does not transfer ownership. Underwater inhalation,
vacuum adjustments and loss of reserve before expiry remain incomplete.

The minimal [`expanded-exploration.t`](../../tests/fixtures/expanded-exploration.t)
fixture covers independent duration expectations, combined-factor rounding,
preparation rejection, exact expiry boundaries, duplicate reserves and shared-ledger
ownership. `test_breath_duration` and `test_breath_reserve` are authored but unrun
while checks are paused. The dedicated
[`expanded-breath-transactions.t`](../../tests/fixtures/expanded-breath-transactions.t)
adds authored transaction fixtures for exceptions after start and air restoration,
undo and replay, preview purity, rejected bound-field mutation and duplicate
reserves. Historical calls against an ended reserve must leave a newer active
reserve intact. Separate-process saves cover the start, the second before expiry,
exact expiry, restored air and unresolved post-expiry exposure. Restoring an
expired reserve must not reset its clock or permit a new breath to erase the
unresolved suffocation interval. These transaction and persistence fixtures also
remain unrun; they do not establish passing validation or complete suffocation
coverage.


## Swimming and lifesaving assessments

`rpgExpandedSwimmingModifier(intentionalEntry, encumbrance, build)` returns the
B354 balance-check modifier. Supply encumbrance level zero through four and build
`ordinary`, `overweight`, `fat` or `very-fat`. Intentional entry adds three; each
encumbrance level subtracts two. The build additions are zero, one, three and five.
The caller owns entry facts and must obtain encumbrance from the same equipment
ledger used by other actions. This helper does not charge exertion fatigue.

`rpgExpandedSwimmingOutcome(stage, score, roll)` accepts an effective target and
supplied roll. Stages are `entry`, `stable`, `struggling` and `recovering`. Every
failure inhales water, costs one fatigue and selects another check in five
seconds. Successful recovery from `struggling` selects a one-minute check; success
at that check returns to the normal five-minute cadence. Critical failure adds no
extra fatigue to this particular procedure. `seconds` is the next-check interval,
not time spent by this assessment. At zero fatigue, intervening one-second
consciousness checks still require their own owned scheduler; this helper does
not perform them or permit their costs to be skipped.

`rpgExpandedLifesavingModifier(rescuerStrength, victimStrength, techniqueBonus)`
provides the B355 rescue modifier. The author supplies any nonnegative bonus for
an actual rescue technique. `rpgExpandedLifesavingOutcome(score, roll)` returns
`rescued` on success. Ordinary failure costs one fatigue, inhales water and permits
a retry after sixty seconds. Critical failure costs six fatigue and sets
`mustBreakOff`; it does not schedule a retry. These are rescue checks, distinct
from ordinary swimming balance checks.

The assessments are pure. The owned encounter below implements a subset of
swimming balance checks. Complete water inhalation, consciousness, shedding
equipment, rescue movement and resuscitation remain incomplete. A `rescued` assessment does not clear lungs,
restore fatigue or teleport either character. `test_swimming_assessments` records
modifier, cadence, failure and rescue expectations; the fixture remains unrun.


## Owned swimming balance checks

Create `RpgExpandedSwimmingEncounter` with a unique `id`, `profile`, optional
Swimming `skill`, `intentionalEntry`, `build` and entry `evidence`. The current
procedure is for a conscious ordinary swimmer in deep water; amphibious and aquatic
exemptions, active diving and unusual physiology require separate support. With
no skill definition supplied, explicitly set `defaultAvailable` after establishing
that the character may use the ordinary default under B173. Its HT input is capped
at twenty before subtracting four. With a skill supplied, the shared character
skill scorer resolves training or defaults. The definition must identify HT/Easy
Swimming; its catalogue and availability remain the author's responsibility.

`start()` schedules an immediate entry check. Create `RpgExpandedSwimCheck` with
a unique `id` and the `encounter`, then call `assess()` or `apply()` at each exact
scheduled boundary. The shared clock is advanced by the enclosing activity, not
by the balance check. Every committed check owns its previous stage, result and
next due time. A repeat returns the receipt without another roll or fatigue charge.
Current carried load is read for each assessment. Trained skill contexts receive
encumbrance through the shared scorer; the untrained attribute context applies it
explicitly, so neither path doubles the penalty.

A failed check charges one fatigue through the shared increment helper and moves
to five-second checks. A successful recovery selects sixty seconds, then an
ordinary success selects three hundred. `leave(evidence)` requires an established
exit, no unresolved due check and a swimmer who is not struggling. It does not
clear lungs or perform lifesaving. Changing bound entry circumstances is rejected.
The encounter blocks competing breath reserves, airless exposure and quiet-rest
recovery until the author ends the supported swimming interval.

This stage rejects a swimmer with one or fewer fatigue remaining before rolling:
a possible failure requires the unfinished zero-fatigue consciousness/drowning
scheduler. Overloaded characters and unavailable effective scores also block.
Exertion fatigue, active rescue, equipment shedding and unexpected changes of
physiology remain incomplete; the balance-check cadence must not stand in for
them. `test_swimming_encounter` records failure, recovery, normal cadence, repeat
protection and leaving. `test_swimming_context` covers untrained caps, trained and
untrained encumbrance, default availability and explicit unsupported states. These
fixtures remain unrun while checks are paused; the combined-schedule transaction and continuation fixtures are described below.


## Water movement and endurance assessment

`rpgExpandedSwimmingMovement(basicMove, adapted, encumbrance)` supplies the B354
ordinary movement calculation. A land-dweller's water Move is one fifth of positive
Basic Move, rounded down with a minimum of one. An aquatic or amphibious actor
uses full Basic Move. The `adapted` input must reflect an established capability;
it does not grant that capability or breathing independence. The helper returns
`waterMove` and `yardsPerTenSeconds`, using encumbrance factors without prematurely
rounding away fractional per-second movement. For water Move one and heavy
encumbrance, the ten-second distance is four yards.

This helper is before injury, exhaustion, purchased water movement, current,
terrain or maneuver effects. It must not substitute for those adjustments. In
particular, B355/B426 requires reduced movement below one-third remaining fatigue;
that interaction is not yet integrated here. No movement or elapsed time is
committed by assessing a distance.

`rpgExpandedSwimmingEndurance(profile, skill, pace)` compares HT with the supplied
Swimming skill through the shared scorer and selects the higher target. Ties use
HT. No skill is required to use HT. Pace is `top-speed`, `slow` or `floating`:
the first checks every sixty seconds, the others every eighteen hundred seconds.
Failure costs one fatigue. The assessment supplies `context`, `score`, `seconds`
and `failureFatigue` without rolling or spending. It excludes the intentional-entry
and build bonuses of the separate balance-check procedure. A skill context still
receives its ordinary encumbrance modifier once through the shared scorer.

The owned endurance procedure below handles fixed-pace intervals and balance
check ordering. Heat surcharges, extra effort and movement changes at fatigue
thresholds remain incomplete.
`test_swimming_movement_endurance` records movement boundaries, the printed
heavy-encumbrance example, adapted movement, HT/skill selection and pace intervals.
These fixtures remain unrun while checks are paused.


## Owned endurance intervals

Set the encounter's `pace` before starting: `top-speed` checks each sixty seconds;
`slow` and the default `floating` check each eighteen hundred seconds. Pace is bound
to that encounter and cannot change silently. The start schedules both the
immediate balance check and the first endurance interval. Each uses the same
shared clock with its own owned receipts.

`RpgExpandedSwimEndurance` requires a unique `id` and `encounter`. Assess or apply
it exactly at `nextEnduranceAt`; it does not advance time. It selects the HT or
Swimming context through `rpgExpandedSwimmingEndurance`, rolls once and charges
one fatigue only on failure. A repeat reuses the result, including after leaving
the water. Balance and endurance are distinct source costs, so both may apply at
one boundary; neither includes the other's charge.

If both checks are due, resolve balance first. Endurance rejects until that check
is resolved, and a balance check rejects if an earlier endurance boundary was
skipped. `leave()` also rejects unresolved endurance. These ordering rules do not
permit catch-up, pace changes or skipping intervening checks. The encounter's
history validator checks both schedules independently.

The current executor rejects positive heat surcharges, overload, incapacitation
and one or fewer remaining fatigue before rolling. These cases need additional
procedures; they do not silently receive the ordinary one-point approximation.
`test_swimming_owned_endurance` covers failed checks, duplicate calls, leaving,
and simultaneous balance/endurance boundaries with unchanged randomness on a
blocked request. Fixtures remain unrun; the combined-schedule transaction and continuation fixtures below are also unrun.


The dedicated
[`expanded-swimming-transactions.t`](../../tests/fixtures/expanded-swimming-transactions.t)
uses one continuous random stream for the entry balance check and first endurance
check. `test_swimming_transactions` exercises exceptions after each commit, undo
and deterministic replay, changed pace rejection, duplicate encounters, preview
purity, competing rest/diving operations and unresolved checks before exit.
`test_swimming_persistence` restores separate-process saves at encounter start,
after entry, at an endurance boundary, after its fatigue cost and after exit.
Historical requests must remain reusable without resetting either schedule or
charging fatigue again. All these fixtures are authored but unrun; they do not
establish passing native or persistence validation.


## Exact digging assessments

`rpgExpandedDiggingRate(liftHundredths, stage, toolMaterial, improvisedDivisor,
rockDivisor)` implements full-2008 B350–B351 without rounding away fractional
lifting capacity. Stages are `loose`, `ordinary`, `ordinary-pick`, `hard-pick`,
`hard-shovel`, `hard-solo`, `rock-pick` and `rock-shovel`. Supply Basic Lift in
hundredths of a pound. `toolMaterial` is `metal`, `wood` or `improvised`; wooden
tools halve the rate, while improvised tools use an authored divisor of at least
four. Supply `rockDivisor = 1` normally; a greater divisor explicitly represents
unusually hard rock in the `rock-pick` stage only.

The result's `rateNumerator / rateDenominator` is cubic feet per hour.
`fatiguePerHour` records the source's one/two/three/four fatigue cost for loose,
ordinary, hard soil or rock. `workKind` distinguishes `loosened`, `broken` and
`removed`: breaking material does not count as removing it. Ordinary pick work
produces loose soil for a separate removal stage. The hard-solo rate includes
switching between pick and shovel; do not also credit separate pick/shovel work.

`rpgExpandedDiggingVolume(length, width, depth)` multiplies whole-foot dimensions.
For fractional volume, supply an exact numerator/denominator directly to
`rpgExpandedDiggingDuration(rate, volumeNumerator, volumeDenominator)`. Its
`durationNumerator / durationDenominator` is hours, not seconds. Ratios remain
exact and need not be reduced. Bounds reject arithmetic overflow rather than
silently rounding. A three-halves-cubic-foot volume and nonintegral Basic Lift
therefore retain their fractional work requirement.

These functions are pure assessments. They do not establish possession of tools,
advance time, charge fatigue, reserve a work site or credit excavation. The owned-hour, material-stock and team adapters below supply execution.
Exhaustion and fractional-hour fatigue remain unfinished. `expanded-digging.t` specifies every source rate with
metal, wooden and improvised tools, harder rock, fractional lifting capacity and
volume, and absence of time/randomness changes. Assertions are authored and unrun.


## Owned digging hours

`RpgExpandedDiggingSite` owns excavation and prepared-material credit for
`loose`, `ordinary`, `hard-solo` or `rock` sites. Set its unique `id`, `stage` and whole-cubic-foot
`capacityCubicFeet`. Completed work is exact: `removedNumerator / rateDenominator`
is the removed volume, backed by the site's `hours` receipts.

`RpgExpandedDiggingHour` supplies `id`, expanded `profile`, `site`, actual owned
`shovel`, and a distinct owned `pick` for hard-solo work. Supply `toolMaterial`,
`improvisedDivisor`, `approved` and evidence establishing material, tool roles,
site access and uninterrupted working conditions. Tool ownership, positive quantity
and `usableBy(profile)` are checked. Assessment also verifies remaining capacity,
worker eligibility, fatigue margin, clock bounds and pending shared-clock events.

`apply()` advances exactly one hour, rechecks conditions and rate, charges the
source hourly fatigue and credits the site once. Replay returns the original
receipt. Any change that invalidates the hour after time advances rejects the
transaction; normal undo and save continuation include tools, fatigue, time and
work receipts. Breaking and removal are not double-credited.

Partial hours, heat-adjusted work, critical-health
workers and fatigue reaching zero remain unsupported and reject explicitly. Each supported hour must
fit the remaining site volume and leave positive fatigue. Those limits describe
unfinished adapters, not changes to the source rules. `expanded-digging-work.t`
specifies three work stages, wood tools, fractional lifting capacity, missing
equipment, exhaustion rejection, site capacity, preview, replay, rollback, undo
and saved continuation. Assertions remain unrun.


## Separate breaking and removal stages

An hour may set `stage` independently of its site's material. Ordinary sites allow
`ordinary` direct removal, `ordinary-pick` preparation, and `loose` removal of
prepared stock. Hard-soil sites (`site.stage = 'hard-solo'`) allow `hard-solo`
direct removal, `hard-pick` preparation and `hard-shovel` removal. Rock sites allow
`rock-pick` and `rock-shovel`. Pick-only work requires the owned pick; removal
requires the owned shovel. Alternating hard-solo work still requires both.

The site stores `preparedNumerator` alongside `removedNumerator`, using the same
`rateDenominator`. Preparing material consumes remaining unworked capacity;
removing prepared material consumes that stock. Neither operation can credit more
than the remaining source volume. Preparation produces no excavation credit by
itself, and direct removal cannot consume prepared stock a second time.

Rates with different denominators, such as a switch to wooden tools, use an exact
common denominator. Existing work receipts retain their original rates; the site
validates both current totals by reconstructing them from those receipts. Bounds
reject unrepresentable scales before time or fatigue is spent. `rockDivisor` on
a rock-pick hour supplies the authored reduction for unusually hard material.

`test_digging_material` specifies preparation/removal pairs for all three materials,
insufficient-stock rejection, exact rescaling, replay, rollback, undo and saved
continuation. Assertions remain unrun. Individual hours can run sequentially or in the shared team operation below.
Partial hours and advanced fatigue remain unfinished.


## Concurrent digging teams

`RpgExpandedDiggingTeamHour` takes a unique `id`, one `site` and a `members` list of
fresh digging-hour objects. Each member must represent a different worker with
separate usable tools. The team's pure assessment combines exact preparation,
consumption and direct-removal rates, rejecting insufficient raw or prepared
material before time or fatigue is spent. Member order does not determine whether
preparation can supply removal during the hour.

`apply()` spends one shared hour, then commits the individual receipts atomically.
The site records preparation before consumption for validation, but every member
has the same start and completion times. A worker cannot appear twice, and one
physical tool cannot be assigned to two workers. Each worker pays their own stage's
fatigue cost. Replaying the team or an individual member never pays again.

The source's ordinary-soil arrangement—one pick worker and two shovel workers of
equal lifting capacity—therefore completes one hour of combined work, rather than
three elapsed hours. `expanded-digging-team.t` specifies that case with reordered
members, insufficient preparation, shared tools, duplicate workers, unavailable
workers, preview, replay, rollback, undo and saved continuation. Assertions remain
unrun. Partial intervals, fatigue reaching zero and environmental work modifiers
remain incomplete.


With the optional equipment library, `rpgExpandedDiggingTool` creates catalogue
pickaxes and shovels for the existing purchase/issue ledger. Digging checks their
role and explicitly established material as well as ownership and usability.
See the [equipment guide](equipment.md) for catalogue fields and the material
contract. Generic authored tools remain supported through the base item hook.

## Lifting and dragging assessments

`rpgExpandedAssessLift(lift, weight, mode, combat, runningStart, braced)` implements
full-2008 B353 capacity arithmetic. `lift` is the profile's
`basicLiftHundredths()` and `weight` is hundredths of a pound. Modes are
`one-hand`, `two-hands`, `shove`, `back` and `shift`, with limits of 2, 8, 12,
15 and 50 times basic lift. A running shove doubles its limit. The caller must
establish adequate running space (full Move in combat); shifting requires authored
footing and bracing. These facts do not grant permission to move an unwilling
character or bypass grappling.

The result reports capacity, readiness, duration when specified, and combat
maneuver. Loads at or below basic lift take one second (B15). Heavier one- and
two-hand lifts take two and four seconds respectively. Combat pickup uses Ready. Combat shoves use
Attack, or Move with a running start. Back carrying reports one fatigue per second
strictly above ten times basic lift. A nil duration means the source has not
specified a duration for this assessment; do not interpret it as free execution.

`rpgExpandedAssessDragging(lift, load, deviceWeight, device, smoothLevel)` preserves
an exact effective-weight numerator and denominator. Devices are `none`,
`snow-sledge` (sledge over snow/ice), `cart` (two wheels) or `wagon` (four wheels),
with divisors 1, 2, 10 and 20. Add the device weight before dividing. Smooth,
relatively level terrain doubles the divisor. Arbitrary sledges or surfaces do
not qualify without the stated physical conditions. `none` requires zero device
weight. The result uses the shared encumbrance bands, comparing rational weights
without rounding them to whole pounds or hundredths.

Above fifteen times basic lift, dragging rejects for capacity. Between ten and
fifteen times basic lift it exposes the overloaded band but remains blocked with
`dragging-overload-execution-required`; do not pass it through the ordinary
immobile-load result as if that completed the expanded procedure.

These are pure assessments: they do not transfer inventory, change map positions,
spend time/fatigue, roll Lifting, or create an ongoing carrying operation. Combined
workers, carried equipment during dragging, lifting-skill bonuses, consecutive
Ready maneuvers, unwilling targets and overload execution remain separate pending
work. `expanded-loads.t` specifies exact limits, immediate boundary values,
fractional loads, device weight, surface stacking, bracing and zero time/RNG.
Its assertions remain unrun while checks are paused.

The equipment module now commits noncombat stored-item pickups through
[`RpgExpandedEquipmentLift`](equipment.md#owned-equipment-pickup), sharing these
assessments and the existing inventory/time ledgers. Other load execution remains
pending; new owned-pickup assertions are authored and unrun.

## One lifting-skill roll per lift

`RpgExpandedLiftingSkillAttempt` implements the full-2008 B205/B353 skill roll.
Supply a stable `id`, expanded `profile`, an owned purchased HT/Average skill
whose ID is `lifting` and which has no attribute default, the concrete `lift`
operation identity, `approved`, and nonempty `evidence`. `modifier` is an explicit
authored skill-check modifier. Untrained use and physical incapacity block before
rolling. The operation does not use an attribute default for this skill.

`assess()` is pure. `resolve()` rolls once, retaining the check and the capacity
ratio in `RpgExpandedLiftingSkillResult.liftNumerator / liftDenominator`, measured
in hundredths of a pound. Success multiplies the initial Basic Lift by
`(100 + 5 * margin) / 100`; a failed roll retains baseline capacity. No intermediate
rounding is applied. Replay returns the original result; a second attempt object
for the same lift identity rejects even if given another request ID. The profile's
`liftingSkillAttempts` owns these receipts through undo and save continuation.

This result applies to that pickup only. It never changes the profile's Basic
Lift, encumbrance thresholds, carrying limit or inventory. Assessment and skill
resolution do not charge additional action time. The actual lift must charge its
ordinary action duration once. Set the equipment lift's `skillAttempt` before resolving the skill. The operation
now validates physical eligibility before the roll and consumes its resolved
capacity assessment when picking up the item. Resolving the skill alone still
does not complete the pickup. The request must implement the foundation's
`RpgExpandedLiftIdentity` contract; equipment lifts supply that implementation.

The fixture specifies margin-four success, critical success using its actual
margin, failure, no-default rejection, duplicate-lift rejection, preview purity,
rollback, undo and cross-process continuation. Carrying state remains unchanged
in every case. Assertions remain unrun while checks are paused.

### Applying trained capacity to a pickup

Set `pickup.skillAttempt = attempt` and `attempt.lift = pickup` before calling
`attempt.resolve()`. Both must use the same profile. The attempt binds the physical
request, item weight and ordinary Basic Lift. A changed request cannot reuse the
bonus. Pure pickup assessment reports `lifting-skill-unresolved` before the roll;
it never rolls implicitly. Physical ownership, reach, hands and carrying-limit
failures block the skill roll as well.

After resolution, `pickup.apply()` compares the weight with the exact multiplied
capacity and charges one, two or four seconds on success, according to the load and hands. The character's
carrying limit still uses ordinary Basic Lift. The result reports
`capacityNumerator / capacityDenominator`; `capacityHundredths` is nil if that
capacity cannot be represented as a whole hundredth. No rounding can make an
otherwise excessive load pass.

The roll and pickup may be committed in one surrounding action transaction, or
saved between resolution and pickup. Replay never grants a second roll or repeats
the pickup. The fixture covers both transaction rollback and saved continuation,
including a 180-pound load above baseline two-hand capacity that a margin-four
bonus can lift. These assertions remain unrun. The equipment module now offers a [combined attempt](equipment.md#committing-a-complete-skill-assisted-attempt)
with explicit authored failure timing. Combat sequences, cooperation and broader
action routing remain incomplete; a blocked capacity assessment alone must not
be reported as a completed physical attempt.

Basic Lift derived from character strength follows B15: retain the fractional pound
below ten pounds, but round values of ten pounds or more to the nearest whole
pound. For example, strength 7 gives 9.8 pounds, strength 8 gives 13 pounds and
strength 11 gives 24 pounds. The existing profile method already implements this;
no change to its rounding or Lite behavior is required. Exact dragging ratios and
skill bonuses are applied after that base calculation. Synthetic fractional inputs
in the arithmetic fixtures test the helpers independently, not a different rule
for deriving a character's Basic Lift.

New assertions cover this rounding boundary, one-second pickups outside combat,
and the one-second threshold with a skill-adjusted lifting capacity. The owned
digging fixture now expects 48 cubic feet per hour at strength 11, using the
rounded 24-pound base. These corrections come from source/code inspection; all
assertions remain unrun while checks are paused.

## Cooperative load assessment

`RpgExpandedCooperativeLoad` implements full-2008 B353's permission to combine
Basic Lift when the arrangement allows cooperation. Provide at least two distinct
expanded `participants`, `approved = true`, and nonempty `evidence` explaining the
physical arrangement: access, grips, positioning and how each helper contributes.
This approval is an authored world fact. It does not automatically make an awkward
object shareable or grant another hand to a character.

For `operation = 'lift'`, supply `weight`, `mode` and the relevant lift facts.
For `operation = 'drag'`, supply the load `weight`, `deviceWeight`, `device` and
`smoothLevel` facts used by the existing dragging assessment. Inapplicable device
fields on lifts, or combat/running/bracing flags on dragging, reject rather than
silently changing the operation. All weights are hundredths of a pound.

`assess()` sums each participant's existing `basicLiftHundredths()` after that
profile's rounding. It never adds ST and squares the result. For example, strength
8 and 11 contribute 13 and 24 pounds, for 37 pounds combined. The returned load
assessment adds `combinedLift` and `participantCount` and otherwise uses the same
capacity, duration and exact effective-weight calculations as individual loads.
Duplicate participants and actors unable to perform voluntary physical work are
rejected or blocked before any time or randomness is spent.

This is a pure cooperative-capacity assessment, not a joint pickup or travel
operation. Returned encumbrance is the combined-load calculation, not an automatic
replacement for each participant's inventory, movement or fatigue state. Individual
load distribution, each helper's available hands, coordinated execution, ongoing
team movement and fatigue still require implementation. Do not execute several
individual pickups for one shared object or multiply its weight into every
inventory as a substitute.

`test_cooperative_loads` specifies separately rounded strength values, exact
capacity and immediate-over-limit cases, wagon/surface modifiers, duplicate
helpers, missing authorization and an incapacitated helper. Assertions are authored
and unrun while checks remain paused.

### Assessing individual shares

`rpgExpandedAssessLoadDistribution(rows, weight, approved, evidence)` assesses an
authored distribution for a shared object, using B353 cooperation and the existing
encumbrance bands. Rows are `[expandedProfile, shareHundredths]`; at least two
unique participants must each have a positive share. Their shares must sum exactly
to the object's `weight`. Approval and evidence explain the actual load-bearing
arrangement. Equal division is not inferred or presented as a published rule.

A ready `RpgExpandedLoadDistributionResult` contains `allocations` rows of
`[profile, shareHundredths, totalCarriedHundredths, encumbranceLevel]`. The total
adds that participant's current inventory load. Existing possessions remain in
one inventory; the assessed object's weight must not already be included in any
participant's carried load. This helper accepts numeric weight and cannot establish
that physical fact itself; the future shared-object execution must validate it.

The assessment blocks if shares omit or duplicate weight, a participant is
repeated, or a helper would exceed the supported ten-times-Basic-Lift carried load.
It changes no profile, inventory, time or randomness. It does not establish lifting
capacity, health, access or hand availability by itself; use it with the cooperative
capacity assessment and the physical arrangement contract.

The fixture includes unequal shares, existing carried equipment, exact total
conservation, missing/excess weight, duplicate helpers, missing approval and
individual overload. Assertions are authored and unrun. Committed shared-object
ownership, ongoing movement, fatigue and release remain pending.

The equipment module now provides [owned shared carrying](equipment.md#owned-shared-carrying)
for these capacity and distribution assessments. One inventory owns the item;
participant load calculations add only their assigned shares. Coordinated movement,
emergency drops and reallocation remain incomplete; integration fixtures are unrun.

### Climbing assessment

`rpgExpandedAssessClimb(surface, distance, encumbrance, combat, ordinaryFatigue)`
implements the printed B349 rate table through the existing shared table. Pass
whole feet for walls, trees, mountains and ropes, or whole rungs for ladders.
The result exposes `unit`, an exact `rateNumerator / rateDenominator` in units per
second, and a duration rounded up once to whole ledger seconds. It does not convert
feet to truncated hundredths of yards. Supported surface identifiers are
`ladder-up`, `ladder-down`, `tree`, `mountain`, `stone-wall`, `building`, `rope-up`,
`rope-down` and `rappel` (equipped rope descent).

For non-ladders, `modifier` includes the printed surface adjustment minus the
encumbrance level, and `checkCount` gives the entry check plus five-minute checks
through the assessed interval. Ladders return no modifier and zero checks.
`ordinaryFatigue` is the author's ordinary cost for this climb; the combat result
replaces it with twice that cost, with a minimum of one, and specifies `move`.
Do not add the ordinary cost again. Overloaded climbing is rejected rather than
assigned an unsupported fifth encumbrance penalty.

This assessment spends no time, fatigue or randomness. It is not an executable
climbing encounter: skill rolls, interruption, secured-rope fall distances,
falling damage and owned progress still require implementation. The existing
profile's activity behavior is unchanged. `test_climb_assessment` specifies all
nine rows at both speeds, encumbrance, fractional rates, whole-second rounding,
five-minute boundaries and combat fatigue. These assertions remain unrun while
checks are paused. Source: `full-2008`, B349.

### Failed climbs and falling velocity

`rpgExpandedAssessClimbFall(score, roll, heightFeet, secured, ropeFallFeet)`
classifies a supplied check without rolling again. Pass the effective score and
actual roll, the distance to the first lower obstacle in feet, and (when secured)
the distance before the rope arrests the fall. An ordinary failed check still
means a fall: the rope limits its distance when it catches sooner than the obstacle.
Critical failure ignores that limit. An earlier obstacle takes precedence over a
longer rope. Success returns no fall. An unsecured request must pass `nil` for
`ropeFallFeet`.

A failed check returns `impactRequired` even when rope slack is zero. This means
consequences remain to be adjudicated, not that damage is automatically inflicted.
The assessment does not invent rope strength, anchor integrity, arrest injuries,
landing surface or collision damage. Those facts must be resolved before treating
a failed climb as a completed movement. Source: `full-2008`, B349.

`rpgExpandedFallVelocity(yards)` supplies the full printed B431 velocity table for
whole-yard falls from zero through 112 yards at ordinary gravity and atmosphere.
Results are yards per second. Do not silently convert fractional feet to whole
yards or extrapolate long falls using this function. Fractional distances,
terminal velocity, altered gravity/pressure and fall damage remain pending; the
abridged helper is unchanged and is not the full profile's fallback.

`test_climb_fall_assessment` specifies success, ordinary and critical failure,
secured and unsecured falls, obstacle precedence and zero slack, plus every
whole-yard value in the full table. All assertions remain unrun.

### Controlled landing assessment

`rpgExpandedAssessLanding(distance, method, fluid, freeToMove, score, roll)`
assesses a single chosen `acrobatics` landing or `dive` into water/a similar fluid.
Distance is whole yards from 1 through 112. Supply the applicable skill score with
ordinary modifiers, but without a dive speed penalty; the function adds that
penalty using the full speed/range table. It consumes no randomness or time.

A successful acrobatic landing subtracts five yards (minimum zero) before looking
up impact velocity. A successful dive sets `negatesDamage`; failed checks leave
distance and velocity unchanged. One call accepts one method, never both. Missing
movement freedom, a dive without fluid, or an effective score below three blocks
the assessment. The method must be chosen before the roll.

The caller must own the attempt and its roll: this pure helper does not prevent
rerolls or commit a landing, damage or world position. Skill selection, owned
attempts and connection to fall injury remain pending. The fixture includes the
seven-yards-per-second penalty row, success/failure, eligibility and short falls.
Assertions remain unrun. Source: `full-2008`, B431 and B550.

The existing `rpgExpandedRangeModifier` is now defined in the expanded foundation
so equipment and exploration share the full table without a circular dependency.
Its signature and equipment behavior are unchanged.

### Owned landing attempt

`RpgExpandedLandingAttempt` owns the single maneuver choice and roll for a fall.
Set `id`, `profile`, a distinct authored `fall` occurrence object, `distance`,
`method`, `fluid`, `freeToMove`, `skill`, `approved` and `evidence`. A fall occurrence
is an event identity, not a reusable room or terrain object. The evidence establishes
this occurrence and the applicable landing conditions. Use the ordinary acrobatics
skill definition (DX/Hard, DX-6 default) or swimming (HT/Easy, HT-4 default).
`modifier` supplies ordinary authored circumstances; omit the dive speed penalty,
which is applied once by the landing procedure.

`assess()` checks eligibility and the effective skill without rolling or committing.
`resolve()` rolls once and stores the result in the profile's `landingAttempts`.
The request binds on resolution. Replaying it returns the stored outcome; changing
the request or creating a different attempt for the same profile and occurrence
is rejected before RNG. Use the existing action transaction for rollback and undo.
No extra time or injury is charged here. Stored results retain the original score
and velocity even if the character later changes.

This implements the B431 landing check, not general sporting high dives or vehicle
control. Alternative skill-default chains, automatic fall-event creation, impact
resolution and position changes remain pending. Authors must carry the result
forward to the same fall, using reduced velocity or damage negation as appropriate;
the hazards module accepts an explicit landing receipt as described below. The new fixture covers preview,
rollback, undo, replay, duplicate-occurrence rejection, changed-choice rejection,
successful and failed dives, and cross-process continuation. Assertions remain
unrun while checks are paused. Source: `full-2008`, B174, B224, B431 and B550.


The hazards module's `RpgExpandedFallInjury` can link to this receipt through its
`landing` and matching `fall` fields. `impactFor(profile, fall)` validates committed
ownership and binding before exposing the result. This interface lives in the
foundation as `RpgExpandedLandingReceipt`, keeping exploration independent of the
hazards include. The concrete attempt implements it; the base rejects use.

## Daily hiking conditions and mileage

`RpgExpandedHikingConditions` assesses one homogeneous route segment using
`full-2008` B351. Set `terrain` to `very-bad`, `bad`, `average` or `good`;
`weather` to `dry`, `rain`, `shallow-snow`, `deep-snow`, `ice-coating` or
`solid-ice`; and `road` to `none`, `poor`, `ordinary` or `best`.
Road quality replaces surrounding terrain. Rain on a poor road uses the
very-bad factor; other wet roads use average terrain without another rain
penalty. Snowy or ice-coated roads use average terrain and the applicable
weather divisor, unless `roadCleared` is true.

`equipment = 'skis'` replaces snow terrain with average terrain and removes
its speed divisor, selecting `skiing` as the travel skill. Skates require
solid ice, select `skating`, and use good terrain. Without skates, solid ice
uses bad terrain. These are explicit equipment facts, not inventory grants.
Deeper-than-ankle snow defaults to division by four; a larger
`deepSnowDivisor` requires `deepSnowEvidence`. Conflicting equipment or
cleared-road facts return a blocked outcome. Mixed weather and ice roads
need further adjudication and are not silently converted to a supported case.

Call `rpgExpandedAssessHiking(move, enhancedPercent, succeeded, conditions)`
with current ground movement after encumbrance, injury and fatigue,
an authorized ground-movement multiplier in hundredths (`100` is ordinary,
`200` is double), and the result of the day's skill check. It returns
`milesHundredths`, effective terrain, weather divisor and the applicable
travel skill. The single success bonus is twenty percent. Intermediate
fractions are retained; the final distance is truncated to hundredths of a
mile. Inputs that exceed safe integer arithmetic are explicitly rejected.

This assessment consumes no time or randomness and does not authorize a
completed journey. The caller must still own the daily skill attempt,
validate equipment and trait applicability, and occupy the full travel day
including preparation and rest. Daily attempt receipts and shared-roll group pace are described below.
Interruptions, fatigue, mixed routes and world movement remain incomplete.
The minimal fixture is `tests/fixtures/expanded-hiking-assessment.t`;
its expected-value and purity assertions have been authored but not run.

## Owned daily hiking attempts

`RpgExpandedHikingAttempt` resolves the ordinary daily bonus from `full-2008`
B200 and B351. Give it a unique `id`, `approved = true`, route/preparation
`evidence`, and `members` rows of `[profile, skill, modifier, modifierEvidence]`.
A solo attempt has one member and no leader. Skills must be the source-defined
HT-based `hiking` (Average, HT-5), `skiing` or `skating` (Hard, HT-6; B220-B221).
Each nonzero modifier requires an author explanation; B200 permits appropriate
maps or footwear bonuses, but terrain affects distance, not this skill roll.
Authors must establish actual equipment and movement eligibility before rolling.

For a shared group roll, include every participant in `members`, set `leader`
to one of them and supply the IQ/Average `leadershipSkill` (IQ-5 default, B204).
The leader needs skill 12 or better. The assessment averages the members'
effective travel skills, including defaults, rounding down. Resolution uses one
3d6 roll for the whole group, and each participant owns the same receipt.
Success grants the shared twenty-percent bonus; failure grants none.

`assess()` is pure. `resolve()` validates before randomness, records the result
and returns that result on replay. A second attempt with any ID or travel skill
is rejected for a participant who already has a receipt that day. Calendar days
are the shared ledger's 86400-second intervals starting at zero; integrations
using another day boundary need an explicit calendar adapter. Changing members,
leader, skill definitions or declared modifiers after resolution is rejected.
Replaying a historical result remains possible without consuming time or dice.

`assessPace(conditions, enhancedPercents)` evaluates current member movement
with one authorized ground multiplier per member, then returns the lowest daily
mileage. The conditions' travel skill must match each member's selected skill.
Shared-roll groups commit to staying together; this interface provides no
split-group bonus. Expired daily receipts cannot assess a later day's pace.
The method remains a distance assessment, not a movement or time commit.

Ordinary daily rolls do not spend travel time, fatigue or advancement points.
Full-day occupation, interruptions, extra effort and movement execution remain
incomplete. Independent-roll parties are described below. They must not be inferred from a saved
bonus receipt. `tests/fixtures/expanded-hiking-attempt.t` contains solo/group
integration fixtures for previews, success, failure, duplicate requests, leadership,
rollback, undo, saved replay and next-day availability. Assertions remain unrun.

## Parties using individual daily rolls

`RpgExpandedHikingParty` implements the B200 ordinary party procedure alongside
B351 shared pace. Set `attempts` to two or more resolved **solo**
`RpgExpandedHikingAttempt` receipts, give the decision a unique `id`, and provide
`evidence` that those travelers choose to stay together. Every receipt must be
from the current ledger day and belong to a different traveler. Unresolved,
expired or shared leadership-roll receipts cannot stand in for independent rolls.

`assess()` inspects those existing rolls. `resolve()` records the party decision
in every member's `hikingParties` history; it consumes no dice, time or resources.
`result.bonusAchieved` is true only when every traveler succeeded. The party's
`assessPace(conditions, enhancedPercents)` applies this common bonus and selects
the slowest member, rather than applying each member's bonus independently.
The multiplier order follows `attempts`; skills must match the route conditions.

Independent-roll travelers may split and regroup. A new party decision uses
existing receipts and recomputes the all-members-success condition; it never
permits another daily skill attempt. Replaying the same decision preserves the
stored outcome, while changing its membership or evidence is rejected. Historical
results remain readable, but expired receipts cannot assess current travel pace.
These records do not themselves move characters or reserve travel time.

The fixture `tests/fixtures/expanded-hiking-party.t` covers a mixed-result party,
an all-success party, regrouping, invalid receipts, exception rollback, undo and
save continuation. These assertions are authored and unrun. Travel execution,
fatigue, interruptions and full-day time occupation remain incomplete.

The health module's `RpgExpandedMarchHourCost` now provides the B426 fatigue
settlement for a completed marching hour or the assumed hour at a combat stop.
Its owned interval prevents duplicate charging between those pathways and feeds
the existing fatigue/injury ledger. See [marching-hour fatigue](health.md#marching-hour-fatigue).
A travel controller must supply the interval and own its time; automatic travel
scheduling and actual-event interruption exceptions are still incomplete.

For a continuous hour under unchanged conditions, health now also supplies
`RpgExpandedMarchHour`, which owns the action gate, one ledger hour and the
marching cost together. Failed permission is retained without charging an hour.
See [continuous marching hours](health.md#continuous-marching-hours). This does
not complete the full-day itinerary, rest or interruption procedures.

## Ordinary-object throwing assessments

`rpgExpandedThrowDistanceFactor(weight, lift)` contains every printed ratio row
from `full-2008` B355, including rows above the ordinary eight-times-lift weight
limit. Both inputs are hundredths of a pound; the returned distance factor is in
hundredths. It compares exact integer cross-products rather than rounding a
weight ratio before choosing the next higher row. Table access alone grants no
permission to lift or throw an object.

`rpgExpandedAssessThrow(strength, lift, weight, skillAssessment)` rejects weights
above eight times Basic Lift, selects one hand up to twice lift and two above,
and returns distance in hundredths of a yard plus an unrolled thrust damage
expression. `skillAssessment` can be nil for unskilled throwing. The result also
identifies the attack maneuver and base accuracy adjustments: DX-3 for a specific
target, DX for a general area, or the selected throwing skill without that DX
penalty. Actual size, speed, range and other target modifiers remain separate.

`rpgExpandedAssessThrowSkill(mode, relativeLevel, palmSized, cinematicAllowed)`
implements B356 with modes `unskilled`, `throwing` and `throwing-art`.
`relativeLevel` is **trained** skill relative to DX; a default does not establish
training. Ordinary throwing requires a palm-sized object and grants +1 or +2
range strength at DX+1 or DX+2. The explicitly authorized cinematic skill can
handle any ordinary object and grants +1 or +2 range strength and damage per
die at DX or DX+1. These bonuses do not change lifting eligibility, weight bands
or the strength used to select base thrust damage.

Damage defaults to crushing. Sharp-object damage types need authored shape
adjudication. For the two-to-four-times-lift damage band, the negative half-point
per die rounds downward (B9/B355): three dice take a -2 adjustment. This corrects
the earlier inventory wording, which described subtracting a rounded-down
positive quantity. Existing Lite formulas remain unchanged.

These functions assess capability without time, RNG or inventory changes. They
do not replace purpose-built thrown-weapon statistics, confirm ready equipment,
execute an attack, damage either participant, or catch an object. Fragile objects
and thrown characters require their own independent damage roll on impact.
Those owned operations and skill eligibility integrations remain incomplete.
The minimal fixture is `tests/fixtures/expanded-throw-assessment.t`; full-table,
weight-band, skill-bonus and source-example assertions are authored and unrun.

## Assessing a held throw from character state

`RpgExpandedHeldThrow` connects ordinary-object assessments to a `profile`,
owned `item`, and optional ordinary `skill`. Supply `approved`, explanatory
`evidence`, `palmSized`, target kind `specific` or `area`, any authored attack
`modifier`, and whether the selected action uses the `offHand`.
The skill must have the B226 DX/Average throwing definition with DX-3 default.
A paid training entry establishes skill-based range bonuses; without one, an
area throw uses DX while a specific target uses the available skill default.
A character trained below DX still uses the selected skill for an area throw.

The result includes `score` alongside range, hands and damage expression.
Range bonuses use the trained rating relative to DX, independently of temporary
attack penalties. The actual attack score passes through the common context
modifiers, including shock and off-hand penalties. Expanded skill definitions
can supply their existing richer default chains; this request does not create
default edges or silently add catalogue entries.

The item must be a single, ready, unworn, accessible object owned by the profile.
Purpose-built weapon objects require their weapon procedure. The health module
supplies `throwingHandsReason(profile, required)` using owned hand bindings;
missing anatomy support is explicitly rejected. Disabled or reserved hands,
conflicting held gear and unmapped competing grips prevent the assessment.
Two hands are required above twice Basic Lift. One or two bound hands may be
used for a lighter object; additional-hand throwing needs its own procedure.

This is a pure assessment: it neither readies nor releases the object, draws a
roll, spends maneuver time nor grants permission at zero HP. Cinematic skill
prerequisites, exhausted-strength throwing, the attack/defense exchange, impact
and catching remain incomplete. `tests/fixtures/expanded-held-throw.t` contains
unrun assertions for training/defaults, range bonuses, injury and hand legality,
readiness, shock, off-hand penalties and repeated preview purity.

## Deliberate-pass catching assessment

`rpgExpandedAssessCatch(score, waiting, throwScore, throwRoll, deliberate)`
implements the B355 catch calculation for an object intentionally lobbed to the
catcher. Supply DX or an authored suitable sports score before the waiting and
throw-margin adjustments. The prior throw must actually succeed. Not taking a
Wait maneuver applies -4; each two full positive points of thrower success
margin grants +1. An automatic successful low roll with a negative margin grants
no bonus. The result exposes `throwCheck`, `throwBonus`, `waitPenalty`, adjusted
`score`, and `countsAsParry` for the catching hand.

`rpgExpandedResolveCatch(...)` accepts one additional `catchRoll` and returns
its separate `check` and `caught` result. Both functions are pure: neither rolls
dice, spends time, consumes a parry nor transfers equipment. A successful lob
does not guarantee a catch. Failed lobs and non-deliberate throws return blocked
outcomes before interpreting a catcher roll. Hostile throws require an active
defense; intercepting a pass intended for someone else requires the distinct
thrown-weapon parry procedure.

An owned catch action must still validate the prior lob receipt, the selected
hand, any sports specialization, available parries and ownership transfer. It
must also settle critical consequences. These integrations remain incomplete;
`countsAsParry` is an execution obligation, not an already consumed defense.
`tests/fixtures/expanded-catch-assessment.t` supplies unrun boundary, independent
outcome, critical-result and preview-purity assertions.

## Owned throw-roll stage

`RpgExpandedThrowAttempt` records the roll stage for one distinct authored
`occurrence`. Supply an `id` and a `request` of type `RpgExpandedHeldThrow`.
For a deliberate pass, set `recipient` to the intended expanded profile and use
an area target. A specific-target attack cannot be declared a pass. The request
retains the authored targeting and equipment facts.

`assess()` preflights the held-object request and the health permission gate.
`resolve()` applies that gate and, if permitted, records one throw roll. Failed
permission is retained without a throw roll; neither kind of result can reroll
on replay. Another ID for the same occurrence and thrower is rejected. The
profile owns the record in `throwAttempts`. The result exposes `assessment`,
`gate`, `allowed` and `check`, and the attempt stores `committedAt`.

Declared request fields and skill definitions are bound on resolution. Historical
replay uses the recorded result even after readiness changes, but cannot retarget
the request. `assessCatch(recipient, score, waiting)` validates the intended
recipient and feeds the **recorded** throw score and roll into the pure catch
assessment. Denied permission or an unsuccessful lob cannot qualify as a pass.
This method does not roll the catcher or transfer the object.

The foundation's `prepareThrowGate` hook rejects unavailable permission support;
the health module supplies the concrete action/consciousness gate. This owned
stage does not release the object, charge maneuver time, resolve defenses or
critical consequences, or apply impact injury. A future complete throw action
must compose those stages in the same engine transaction. Do not treat this
record alone as an object in flight or a completed attack.

`tests/fixtures/expanded-throw-attempt.t` contains unrun assertions for pure
preview, rollback, undo, duplicate occurrences, saved replay after readiness
changes, declared-field retargeting and a denied consciousness check.

## Owned ordinary-hit damage rolls

`RpgExpandedThrownDamage` implements the B355 damage-roll stage after an ordinary
specific-target throw. The held request must name `targetEntity` before its
attempt resolves; this identity is included in the bound request definition.
Supply `id`, the resolved `attempt`, `approved`, `defensesResolved`, `hitConfirmed`
and `evidence` establishing the hit. The attempt itself must have a successful,
noncritical throw check. Critical outcomes require their separate procedure.

`objectKind` is `durable`, `fragile` or `character`. All three roll target damage.
The latter two also roll **independent** damage for the thrown object or
character, using the same damage expression. A durable object has no self-damage
roll, represented by `objectDamage = nil`, not a zero result from a discarded
roll. `damageType` defaults to `cr`; `cut`, `pi` or `imp` require authored
`shapeEvidence`. The usual crushing/non-crushing minimum applies to each total.

`assess()` validates those facts before RNG. `resolve()` stores `targetDice`,
`objectDice`, `targetDamage`, `objectDamage`, `dice` and `adds` in a result owned
by the thrower's `thrownDamageRolls` history. Replaying it returns the same dice;
a second ID for the same throw cannot reroll damage. Neither later training nor
item-readiness changes recompute the throw's recorded damage expression.

This stage does not establish physical release, apply armour, deal injury,
transfer an item or resolve critical-hit effects. The thrown-character option
only records the additional damage roll; it does not replace creature carrying
and injury integration. Compose these records with owned impact operations once
those paths are implemented. The fixture `tests/fixtures/expanded-thrown-damage.t`
contains unrun assertions for independent dice, crushing/non-crushing minima,
invalid hit facts, duplicate rolls, rollback, undo and saved continuation before
and after damage resolution.

The equipment module now consumes throw-attempt receipts through
`RpgExpandedThrownRelease` and `RpgExpandedThrowLanding`. These stages own
in-flight inventory state and an authored resting location, respectively; see
[thrown release and landing](equipment.md#thrown-release-and-landing). They add
no include cycle: the receipt interface lives in the expanded foundation.
The complete timed action, catching, impact application and critical-failure
release remain incomplete.

Recorded thrown damage now implements the foundation's
`RpgExpandedThrownDamageReceipt` interface for health integration. A target
profile comes from the bound `targetEntity`; a represented thrown character
uses `objectProfile`, declared before damage resolution. Health's
`RpgExpandedThrownInjury` consumes either side once with ordinary torso
protection. See [applying thrown injury](health.md#applying-ordinary-thrown-torso-injury).
This does not complete material-object damage or full throw action composition.

## Selecting a limb before throwing

A specific-target `RpgExpandedHeldThrow` may select `hitLocation = 'arm'`,
`'hand'`, `'leg'` or `'foot'`. Supply the corresponding owned `locationPart`,
`targetEntity` and `locationEvidence`. These become part of the bound attempt
definition. Area lobs cannot select a limb, and an injury consumer cannot change
the selected location after the roll.

The B399 location penalty is added automatically: -2 for an arm or leg and -4
for a hand or foot. The authored `shieldAtLocation` fact selects the special -4
penalty for a shield-bearing arm or -8 for a shield-holding hand; it is invalid
for other locations. Other supplied attack modifiers must exclude this location
penalty to avoid charging it twice. The health hook validates anatomy and rejects
unsupported or already disabled parts before randomness.

The damage receipt carries the selected part into the owned wound pipeline.
See [selected thrown limb injuries](health.md#selected-thrown-limb-injuries).
This does not implement other hit locations or random location selection.

Throw attempts use the full ranged check classification from B382. A failure by
ten alone is an ordinary ranged miss, not a critical failure; 17/18 retain their
source-defined treatment. Catch rolls count as active defenses and use B374's
successful 3/4 exception even at effective scores below three, while failures by
ten can be critical. The prior lob and catcher keep their distinct check kinds.
`rpgExpandedCombatCheck` now lives in the expanded foundation so exploration
shares these rules without depending on the optional combat module. Lite roll
classification is unchanged. The new regression assertions remain unrun.

## Recording a deliberate-pass catch

`RpgExpandedCatchAttempt` consumes a released `RpgExpandedThrowFlightReceipt`
(the equipment module supplies `RpgExpandedThrownRelease`). Set `id`, `flight`,
`fighter`, the recipient's owned `hand`, `aware`, `approved` and `evidence`.
The fighter must represent the recorded recipient. `otherHand` identifies its
secondary-hand parry counter; the author must map the selected anatomical hand
consistently to that counter. `waiting` asserts an actual authored Wait; this
interface does not create or schedule that maneuver. An optional DX-based
`sports` skill requires a specialty and `sportEvidence` explaining suitability.

`assess()` spends no resources or randomness. `resolve()` records one defense
roll and consumes the selected hand's parry even on failure. Replaying the same
attempt returns its recorded result; another attempt for that flight is rejected.
The catch uses the recorded lob margin, ordinary defense modifiers and the
recipient's health restrictions. The hand must be functional, empty and free of
support reservations. This initial adapter requires ordinary two-hand anatomy
and an object within the one-hand lifting limit. Repeated catches use the same hand counter as other parries: each prior parry
subtracts four, or two with active approved advanced martial training (B376).
The other hand has its own counter; the normal turn reset clears both.

This is a roll-and-parry stage. Use equipment’s `RpgExpandedCatchCapture` with
`receipt` set to the successful attempt to transfer the item and settle the
flight. Neither stage spends maneuver time, resolves critical consequences or
implements interceptions. An unsettled flight blocks positive time advancement.
The integration fixture `expanded-catch-attempt.t` covers success, failure,
preview purity, duplicates, rollback, undo and saved replay. Assertions remain
unrun while checks are paused; the inventory entry remains partial.

### Concentration during a catch

If the recipient fighter has accumulated concentration, catch assessment also
prepares a contextual Will-3 distraction score (B366). A committed catch records
its defense roll first, followed by the concentration check. The result exposes
`concentrationScore`, `concentrationCheck` and `concentrationLost`. Failure clears
the fighter's accumulated concentration; success preserves it. An effective
score below three fails without a concentration random draw. Invalid requests
remain free of rolls and counter changes. Replaying the same catch reuses both
outcomes, including after a save/restore.

This integrates the existing fighter concentration counter. Spell-specific
interruption consequences and other owned activities are not supplied by this
adapter. The associated preview, success/failure, rollback, undo and saved-replay
assertions in `test_catch_concentration` remain unrun while checks are paused.

## Assessing ordinary jump distance

`rpgExpandedAssessJump(basicMove, runYards, jumpingSkill, prepared, encumbrance)`
provides a pure B352 distance assessment. Pass `nil` for `jumpingSkill` to use
Basic Move; supplying a skill selects half that score, rounded down, even when
it is worse than Basic Move. The caller must establish actual skill eligibility.
`runYards` is the available running start. Each resulting distance is capped
independently at twice its standing value.

`prepared` means the required preparation has occurred; a false value halves
both distances. In combat, preparation requires two consecutive concentration
maneuvers. This assessment does not establish or spend those maneuvers. Pass
`encumbrance = -1` to disable the optional load reduction, or a load category
from zero through four to apply it explicitly. Results expose `basis`,
`highInchTenths` and `broadInchTenths`, both distances in tenths of an inch, so
half-distance and fifth-based load factors do not lose fractional inches.

For Basic Move six, standing results are 260 and 1080 tenths of an inch:
26 inches high and nine feet broad. A five-yard run reaches the respective
running caps of 52 inches and eighteen feet. Preview consumes no time or dice.
Effective movement below two returns an explicit unsupported reason because the
printed linear formulas give nonpositive heights in that range. Enhanced movement,
enhanced jumping, the optional strength basis, owned preparation, difficult-jump
rolls, landing consequences and actual movement remain pending.

The `expanded-jump-assessment.t` fixture covers the printed examples, run-up
boundaries, deliberate skill substitution, preparation and all optional load
factors. Its assertions are authored, unrun while checks are paused.

The held-throw low-fatigue guard remains in place. B426 halves current strength
but preserves strength-derived quantities, explicitly including damage. The
throwing adapter does not yet resolve the interaction with every range and
lifting formula; it rejects that case instead of halving all derived quantities.

### Profile-backed jump distances

`RpgExpandedJumpDistance` supplies the pure formulas with current profile data.
Set `profile`, `runYards` and `prepared`; select `skill` only when deliberately
using a paid DX/Easy Jumping skill with no default. The request rejects an
untrained skill rather than silently using DX. With `encumbranceOption` enabled,
it reads the profile's current load category; otherwise no load reduction applies.

`strengthOption` enables the B352 optional strength basis. Supply measured
`bodyWeightHundredths` and `bodyWeightEvidence`. Both body weight and Basic Lift
use hundredths of a pound. Only Basic Lift strictly greater than body weight
permits the higher of floor(ST/4) and Basic Move. Equality grants no benefit.
An explicitly selected Jumping skill replaces that basis with half its score.
The independent pure helper is `rpgExpandedJumpStrengthBasis`.

An installed, approved, active `RpgExpandedEnhancedJump` multiplies the final
height and distance by two per level. This also multiplies prepared/unprepared
and running results. Calculations that exceed the integer representation return
`jump-distance-numeric-limit` before overflow. The request is an assessment:
it neither grants permission to act nor records preparation, moves a character,
spends time, rolls dice or resolves a landing. Trait-specific travel speed,
jump attacks and fall protection remain pending.

### Enhanced-jump fall protection

`RpgExpandedJumpDistance.maximumAssessment()` computes prepared running maxima
under its strength and encumbrance options. It compares the ordinary basis with
every paid Jumping skill on the profile and retains the greatest height; the
request's current run-up and preparation fields do not reduce this maximum.
Enhanced ground-movement integration remains unsupported.

`RpgExpandedJumpFallProtection` implements `RpgExpandedLandingReceipt`. Set
`id`, `profile`, the distinct `fall` occurrence, original `distance` in yards and
`jumping` to that profile's distance request. `assess()` previews the active
trait's protection; `resolve()` owns the result once for the fall. Distance is
currently limited to the existing ordinary-gravity fall table's 1–112 yards.
The comparison retains fractional inches rather than rounding protection up.

Optionally supply `acrobatics`, an already resolved `RpgExpandedLandingAttempt`
for the same profile, occurrence and original distance using the Acrobatics
method. Its successful five-yard reduction also extends the safe-fall threshold
by five yards. Reusing that roll avoids charging a second landing check. Dive
receipts are rejected. Outside the safe threshold, its ordinary effective fall
distance and velocity continue to apply.

Pass the resolved protection as `RpgExpandedFallInjury.landing`, with the same
fall occurrence and the resulting velocity, then use `RpgExpandedFallImpact` as
usual. Protected impacts spend no damage dice and resolve a zero-injury receipt.
Replay retains the recorded protection and does not reevaluate a later trait
change. Duplicate protection records for one fall are rejected. The fixture
`expanded-jump-fall.t` covers threshold boundaries, Acrobatics composition,
inactive traits, rollback, undo and cross-process save continuation. Assertions
remain unrun while checks are paused.


### Enhanced-jump speed and elapsed time

`rpgExpandedAssessJumpTravel(groundMove, maximumInchTenths, distanceInchTenths)`
implements the B89 speed rule. It returns `speedNumerator / speedDenominator`
in yards per second: the greater of ground Move and one fifth of maximum broad
jump distance. Distances use tenths of an inch. The denominator is 1800, retaining
fractional speeds without rounding the maximum-distance jump beyond five seconds.
`seconds` is elapsed time rounded up to the engine's whole-second clock; a zero
distance requires zero seconds. Requests exceeding maximum distance are blocked.

For example, a hundred-yard maximum and ground Move five give a jump speed of
twenty yards per second and a five-second maximum jump. Ground Move twenty-five
gives a four-second maximum jump. Integer-limit distances are assessed without
multiplying them into an overflowing intermediate result.

`RpgExpandedJumpDistance.travelAssessment(distanceInchTenths)` supplies current
ground Move and the computed maximum. It additionally requires active enhanced
jumping and checks the actual launch's prepared/unprepared and running/standing
range. Maximum-distance speed does not let an unprepared standing jump exceed
its own distance limit. These are pure assessments; time commitment, travel
interruption, position changes and jump attacks remain pending. The speed table
and profile-boundary fixtures in `test_jump_travel` are authored, unrun.

### Recording combat jump preparation

`RpgExpandedJumpPreparation` binds a `fighter` and its active `battle`. Use
health's `RpgExpandedJumpPrepareManeuver` for each preparation turn, with this
object as `preparation` and a fresh `RpgExpandedActionGate` as `healthGate`,
with `requiresMovement = true` and `mentalAbility = nil`.
Call the existing battle's `step` method. The battle spends its normal time;
the preparation object charges no additional time or randomness.

Two consecutive successful concentration turns establish readiness. Turn stamps,
the shared ledger and increasing concentration counters must agree. A lost
concentration counter invalidates readiness; unrelated concentration or skipped
turns restart the sequence. Changing the fighter/battle after recording is
rejected. Readiness lasts through the interval before the next action and cannot
be recovered merely by setting the distance request's `prepared` flag.

Set `RpgExpandedJumpDistance.preparation` and call `combatAssessment()` to derive
full or half distance from this receipt. This method ignores the request's
manually supplied `prepared` value. It does not perform or consume the subsequent
jump; launch, travel interruption and position changes remain pending. Existing
manual assessment remains available for authored situations outside this adapter.
The `expanded-jump-preparation.t` fixture covers consecutive turns, interruption,
unrelated concentration, rollback, undo and saved continuation. Assertions remain
unrun while checks are paused.

### Recording the jump launch

`RpgExpandedJumpLaunch` binds `id`, a distinct `occurrence`, `fighter`, `battle`
and its `jumping` distance request. Supply `direction` (`horizontal` or
`vertical`), `requiredInchTenths`, `approved` and `evidence` describing the route.
Set `difficult` for a horizontal jump requiring an accuracy check; the author
must identify long or deliberately hazardous jumps here. Vertical jumps always
require a check. `penalty` permits the B352 difficulty range -5 through zero,
and a nonzero penalty requires `difficult`.

Health's `RpgExpandedJumpLaunchManeuver` takes the launch and a fresh `healthGate`
with `requiresMovement = true` and `mentalAbility = nil`.
Use the existing battle's `step`. It consumes a whole Move turn; leave its
ordinary `movement` field at zero to avoid charging separate walking movement.
After health permission, it captures combat distance while concentration is still
available. The scheduler then clears concentration as usual. Commit consumes that
snapshot, so a prepared jump keeps its range without retaining preparation for
another launch. The battle remains the sole owner of time advancement.

An accuracy check uses contextual DX or the selected paid Jumping skill, whichever
is higher. Ordinary failed checks leave the profile lying down. Critical failure
also sets `fallRequired` and applies the preflighted fall plan; `fallOutcome`
contains the owned impact result. The launch records a roll outcome, not a
position change or complete travel/landing operation. `assess()` on a committed
launch returns `reused`; a new occurrence is required for another jump. The
health maneuver refuses to execute an already committed launch.

The launch fixture covers range rejection before permission or randomness,
prepared success, ordinary and critical failure, single consumption, exception
rollback, undo and save continuation. All assertions remain unrun while checks
are paused. Destination placement and travel interruption remain explicit implementation gaps.

### Critical-jump falling damage

Every launch that requires an accuracy roll must supply `fallYards` and a
`fallPlan` implementing `RpgExpandedJumpFallPlan`. Height is the authored fall
to the actual lower surface, independent of jump distance, within the current
ordinary-gravity table's zero-to-112-yard range. Missing plans are rejected before
health permission or accuracy dice.

Hazards supplies `RpgExpandedJumpFallImpact`. Its `impact` is an uncommitted
`RpgExpandedFallImpact` whose injury template names the launch profile and
occurrence and whose `damageVelocity` matches the height table. The existing
impact preview checks the full possible damage range, protection and anatomy.
Thus a critical failure cannot first discover an unsupported injury location
after rolling. A plan already used elsewhere is rejected.

On critical failure only, launch commit consumes this impact once. Its damage
dice, protection and owned wound are part of the same transaction as the launch
roll and health permission. Ordinary failure still leaves the actor prone without
using the impact. Historical launch assessment validates the committed child
impact instead of rolling or injuring again. Authoring must currently supply any
landing-protection receipt in the template with compatible velocity; creating a
new reactive landing maneuver during the critical-fall transaction is pending.

`test_jump_launch_fall` covers critical damage, armor, missing-plan rejection,
rollback, undo and cross-process continuation. These assertions are authored,
unrun while checks remain paused.

### Placing a jump on a tactical map

A launch can now take a `positionPlan`, and requires one when the profile already
has a tactical figure. The tactical module supplies
[`RpgExpandedJumpPlacement`](tactical.md#horizontal-jump-placement), with authored
successful and prone-failure destinations. Launch preflights both outcomes and
commits the selected location in the same transaction as its roll and any fall
injury. Horizontal placement retains the existing figure and facing. Vertical
placement, enhanced multi-second travel and interruption remain unsupported.

### Ordinary small obstacles

`rpgExpandedCanJumpAutomatically(actorSize, obstacleSize, significant)` evaluates
the B352 automatic-jump threshold. It returns true only for an ordinary obstacle
at least three size steps smaller than the character. Supply current size facts
and mark deliberate hazards significant; this helper does not move the actor.
During combat, use the tactical
[small-obstacle path entry](tactical.md#small-obstacle-jumps-in-a-path), which
requires Move and adds one movement point within the existing allowance.

### Clambering instead of a risky jump

For the two-consecutive-Move alternative in B352, use the tactical
[clamber operation](tactical.md#clambering-onto-an-adjacent-surface). It owns the
progress and places an existing figure on an authored reachable adjacent upper
surface after the second turn, without a jump accuracy roll. Both turns still
require normal physical health permission.

## Assessing foraging outcomes

`rpgExpandedAssessForage(method, score, roll)` implements the B427 results for
`plants`, `hunting` and `fishing` using supplied dice. A plant success provides
one meal; hunting or fishing success provides two. Hunting applies its -4
penalty internally, so the supplied score must exclude that penalty. Plants
share one attempt category; hunting and fishing share the other.

Plant rolls of natural 17 and 18 return `poisonScope = 'forager'` and `'party'`
respectively, including at high skill. They provide no successful meal yield.
The same rolls for hunting/fishing do not invoke the plant-poisoning rule.
`RpgExpandedForageSite` adds explicit resource availability and authored scarcity
and repeated-use penalties. Supply its ID and concrete evidence. The printed
scarcity examples are -3 for snow and -6 for desert; these are authored choices,
not automatically imposed climate labels. Local depletion likewise requires an
authored penalty, not an invented universal depletion rate.

These pure assessments do not create food, consume ammunition, spend time,
reserve daily attempts or injure anyone. Health supplies the matching pure
[plant-poison assessment](health.md#foraged-plant-poisoning). Daily scheduling, weapon eligibility, food inventory and preservation remain
pending; the owned plant-roll adapter below supplies a limited travel-day path. `test_foraging_assessment` covers yields, natural-roll complications,
scarcity, unavailable resources, hunting penalties and supplied poison dice;
assertions are authored, unrun while checks remain paused.

Health now provides [owned plant-poisoning resolution](health.md#committing-foraged-plant-poisoning)
for an already recorded natural-17/18 plant check. It commits separate checks and
wounds per exposed character without repeating the forage roll. Plant attempt ownership is described below; consumed-food inventory remains pending.

## Owned travel-day plant attempts

`RpgExpandedPlantForageAttempt` requires an ID, expanded profile, forage site,
paid skill, approval and evidence describing the travel-day search and applicable
specialty. Include health for its physical action gate. Use a Perception/Average
Survival definition with default -5, or IQ/Hard Naturalist with default -6; each
requires a specialty. Existing abridged skill definitions remain unchanged.
Alternate defaults are explicitly blocked in this adapter.

Call `assess()` for a pure preview and `resolve()` to commit. The profile owns
`plantForageAttempts`; a completed plant roll reserves that character's one
attempt for `rpgLedger.seconds / 86400`. Switching skills, sites or request IDs
does not reset the allowance. Permission denial records its health outcome but
does not consume the plant roll. Replay returns the original result without
another health check or forage roll, including after save continuation.

The result exposes `day`, `allowed` and `forage`, whose fields include the recorded
check, meal count and poison scope. An authored poisoning operation can consume
the recorded check through the health module. The author must establish who ate
the plants; this adapter does not infer consumers or create inventory items.

No extra time is charged because this roll accompanies an authored travel day.
The ledger-day boundary is explicit; a broader travel schedule, dedicated
foraging days, hunting ownership and food preservation remain pending; fishing ownership is described below.
See `tests/fixtures/expanded-plant-forage.t` for integration and
`test_plant_forage` for authored, unrun assertions.

## Owned travel-day fishing attempts

`RpgExpandedFishingForageAttempt` uses the same assessment and commit sequence
as plant foraging. Supply an ID, profile, site with water available, approval,
evidence and a Fishing definition (Perception/Easy, default -4, no technology
level). Paid training and the printed Perception default are both supported.
Water availability means suitable water with fish to catch, as established by
the site evidence; a water hex alone does not establish that fact.

Include equipment and supply `tools = RpgExpandedFishingTools`, with an
`RpgExpandedEquipmentAssessment`, approval and evidence identifying the available
fishing method and equipment. The equipment assessment applies its modifier
through the existing skill context exactly once. Missing required equipment
blocks the attempt; improvised tools use the ordinary equipment modifier.

The profile owns `animalFoodForageAttempts`. One resolved fishing roll reserves
that travel day's animal-food allowance, independently of plant attempts. The
same request ID may occur once in each category; the health-gate IDs include the
method. New request IDs do not grant additional fishing rolls. A successful
roll records two meals, while failure records zero and still uses the allowance.
Natural 17/18 fishing rolls do not invoke plant poisoning.

Tool definitions are bound to the recorded attempt. Replay after changing its
tools is rejected; create a fresh request for a later day's changed equipment.
Site conditions may change after completion without altering the stored result.
Shared roll ownership lives in `RpgExpandedTravelForageAttempt`; plant callers
retain their original class and result interface.

The fixture `tests/fixtures/expanded-fishing-forage.t` combines plant and fishing
attempts, default use, equipment modifiers, unavailable resources, exact daily
boundaries, rollback, undo and saved continuation. Its assertions are authored,
unrun. Hunting ammunition and attempt integration, food inventory, preservation
and dedicated foraging days remain pending.

## Owned hunting attempts

`RpgExpandedHuntingForageAttempt` shares `animalFoodForageAttempts` with fishing.
Supply a carried, ready `RpgLiteWeapon`, one of its ranged attack modes, its
matching DX skill, available hands, site, approval and evidence. Mode specialty
and applicable technology level must match the skill. The selected hands must
meet the mode's normal requirement; special reduced-hand operation is not
implemented here. The ordinary minimum-strength shortfall modifies the skill,
and the B427 hunting penalty of -4 is then applied once by the forage assessment.

Set `ordinaryHunt` and `ammunitionEvidence` to establish an ordinary hunt without
special projectile effects, and explicitly provide `ammunitionUsed`. B427 does
not specify a shot count for its abstract hunt: this quantity is an author fact,
not a published fixed expenditure. The request requires that quantity already
loaded in `weapon.ammunition` and deducts it once on either success or failure.
It neither performs a second combat attack nor reloads automatically. Replay
returns the stored result even though the weapon now has less ammunition.

Pure assessment rejects unavailable weapons, insufficient ammunition, missing
facts and thrown modes before spending resources or rolling. Thrown hunting,
retrieval, special projectile effects, and detailed target damage need their own
integration and remain unsupported. The author establishes suitable ordinary
small game; the request records two meals on success and zero on failure. It
does not create a creature target or food inventory.

`tests/fixtures/expanded-hunting-forage.t` demonstrates an authored two-bolt hunt,
shared fishing/hunting limits in both orders, explicit ammunition debit, failure,
rollback, undo and saved replay. Assertions in `test_hunting_forage` are authored,
unrun. Dedicated-day scheduling, actual food stock and preservation remain
pending alongside the unsupported weapon cases above.

## Claiming gathered food

The equipment module's `RpgExpandedForageHarvest` converts a positive recorded
yield into one new `RpgExpandedFoodStock` in the recipient's existing equipment
list. Supply the forage attempt as `source`, a fresh zero-quantity stock, the
recipient, approval and evidence establishing collection or transfer. The stock
uses one ordinary meal per quantity; its per-meal weight and value are authored
facts because B427 does not specify them.

The source records its single credited harvest. Replaying the claim returns the
recorded result; another claim with a different ID or stock cannot credit that
source again. A failed roll or plant-poisoning outcome has no positive yield to
claim. Collection adds no time or randomness and does not reroll the forage check.

Claiming food does not cook or preserve it. Set readiness only from actual
authored preparation, then use the health module's
[inventory-backed meal](health.md#consuming-food-inventory) to debit stock and
credit the existing needs ledger. `tests/fixtures/expanded-forage-food.t` covers
collection, duplicate rejection and consumption with rollback, undo and saved
continuation; its assertions are authored, unrun. Cooking procedures, spoilage,
preservation and poisoned-food consumption tracking remain pending.

Gathered fish and meat now support an owned
[smoking batch](equipment.md#smoking-gathered-meat-and-fish). The operation uses an
authored fire interval and duration, keeps the same meal stock, and marks it
preserved only after uninterrupted coverage. It does not create extra rations or
supply a shelf-life model. The earlier preservation gap is partially addressed;
authored fixtures remain unrun.

## Dedicated foraging days

Reserve `RpgExpandedForagingDay` for each participating character before that
ledger day starts its activities. Supply an ID, profile, approval and evidence
that the party has chosen gathering instead of travel. `assess()` is pure;
`reserve()` persists the commitment. The current adapter accepts reservations
only at an exact 86400-second day boundary and before recorded forage or hiking
activity. It does not reinterpret a partly traveled day as a full foraging day.

A reservation raises that character's allowance to five plant rolls and five
animal-food rolls for the day. Hunting and fishing still share the animal-food
count. Every resolved roll, successful or failed, uses its category allowance;
a denied physical permission uses no roll. Request IDs and sites do not reset
these counts, and replay uses the recorded results.

The reservation blocks the owned hiking attempt and marching-hour integrations
for any overlapping day. `profile.travelScheduleReason(start, seconds)` exposes
the same restriction for authored travel adapters; custom travel must consult
it before committing travel. Imported travel must be recorded through the shared
integrations or excluded by the author's day-choice contract. Broader vehicle,
flight and world-travel integration is not implied by this adapter.

Reservation and forage rolls do not advance the clock a second time. Advance the
world's existing schedule normally through the day; the commitment remains in
history and cannot be cancelled to reclaim travel after using extra rolls. On
the next day, the ordinary one-per-category allowance resumes unless another day
is reserved. Past reservations survive saves without extending their allowance.

`tests/fixtures/expanded-foraging-day.t` covers both five-roll limits, rejection
of sixth attempts, hiking/marching exclusion, next-day reset, late reservations,
prior activity, rollback, undo and saved continuation. Assertions are authored,
unrun. Partial-day scheduling and arbitrary external travel adapters remain
explicit integration limits.

Plant foraging now accepts unpaid targets defined with
[`RpgExpandedNaturalistSkill` or `RpgExpandedSurvivalSkill`](skills.md#nature-and-survival-defaults).
The skills module supplies attribute and eligible purchased-skill defaults,
including terrain and world relationships, through the shared resolver. Plain
abridged skill instances still require paid training in this adapter. This replaces
the earlier blanket default restriction for the two expanded definition types;
no additional forage allowance is granted.


## Orientation answers and remembered routes

`RpgExpandedNorthAssessment` supplies a pure world-fact interface for the
orientation trait (`full-2008`, B34). Bind `profile`, the world's actual
`northDirection`, `approved = true` and original `evidence`. Assessment first
checks the trait's environment eligibility; it never invents a direction, changes
position, rolls or spends time.

`RpgExpandedOrientationRoute` records an ordered `waypoints` list against a
character's `RpgLiteJourney`. Give it a unique `id`, `approved = true` and
`evidence` identifying the actual route. `begin()` captures the shared clock and
journey elapsed time. After traversal, `complete(true, evidence)` requires positive
elapsed travel from that journey, consistent shared time, no recorded fall, and
an explicit arrival declaration covering the listed waypoints. World connectivity
and the route actually taken remain authored facts; a journey's elapsed time alone
does not prove them. Neither operation advances time a second time.

`retrace(profile, monthCutoffAt, calendarEvidence, currentWaypoint, positionConfirmed)`
returns the reversed waypoint list. It requires the same traveler, a completed
route, the confirmed final waypoint, an active eligible orientation trait and an
explicit cutoff from the campaign calendar. The complete recorded route must
fall within the supplied month window. No thirty-day approximation is built in.
The result is remembered navigation information: normal movement still pays its
own time, fatigue and hazard consequences. Age is reassessed on each query.

`abandon(evidence)` closes an interrupted trace without allowing it to be
retraced as complete. Retried completion and abandonment reuse their state, and
an abandoned trace permits a later independent route. The fixture
[`expanded-orientation-route.t`](../../tests/fixtures/expanded-orientation-route.t)
covers travel evidence, exact cutoff, endpoint rejection, cancellation, replay,
rollback, undo and persistence; it is authored but unrun.

Partial-route retracing, multi-journey traces, route recording from parser movement
and automatic calendar/position feeds remain pending. The current interface is an
explicit author contract with owned records, not an automatic world-map solver.


## Owned tools in wilderness operations

Fishing and wilderness survival preflight call `assessForProfile(profile,skill)`
on the tool adapter. Owned assessments must match the acting character, and
shared tools retain their permission, availability and site checks before any
roll. Legacy authored tool adapters retain their existing behavior.

Equipment definitions bind owned item identities, task, approval and evidence;
shared assessments additionally bind grant definitions, and purchased kits bind
quality, technology and supported skills. Completed forage receipts reject
retargeting these definitions. Later inventory movement alone does not rerun a
completed attempt or spend resources again.

`expanded-owned-fishing.t` / `test_owned_fishing` cover owner mismatch, inaccessible
tools, preview purity, item retargeting, replay, rollback, undo and save continuation.
These fixtures are authored but unrun while checks are paused.


## Defaulted small-boat entry

`RpgExpandedBoatEntry` connects B180–B181 boarding to the B354 swimming state.
Supply `id`, `profile`, an `enter` Boating `context`, `approved` and `evidence`.
For an untrained entry, also supply a fresh `RpgExpandedSwimmingEncounter` owned
by the same profile with `intentionalEntry` unset. `assess()` preflights both
possible outcomes without rolling. Swimming now exposes `assessStart()` for this
pure preparation; its existing `start()` uses the same checks.

`apply()` rolls only when the target boating skill is defaulted. Failure starts
the involuntary water encounter with its immediate entry check due; the ordinary
swimming procedure then handles that separate check. Success reports `boarded`.
Trained entry reports boarding without randomness. The owned attempt preserves
its result across replay, undo and save. It does not move native room objects,
spend invented action time or bypass subsequent water checks. The game must bind
the result to its actual boarding/location action.

`expanded-boat-entry.t` / `test_boat_entry` specify pure preview, failed and
successful defaulted entry, trained entry, rollback, undo and saved replay.
Fixtures remain unrun. Docking, underway checks and their movement consequences
remain outstanding.


## Exhausted swimming consciousness

A swimming balance or endurance check may now consume the last positive fatigue
point. The encounter records that exhaustion boundary.
`RpgExpandedSwimConsciousness` takes an `id` and the owned `encounter`; its
`apply()` checks Will at exactly the next elapsed second, once per receipt.
Failure causes unconsciousness with fatigue-collapse provenance. The clock
cannot skip a required consciousness boundary. These checks do not spend
additional fatigue: partial-air drowning does not use complete-airlessness
fatigue costs (full-2008, B354 and B436–B437).

Swimming checks at zero or negative fatigue require the health adapter described
below. Unconscious submersion, air-loss timing and rescue/resuscitation
transitions remain incomplete; this is not a complete
drowning implementation. `expanded-swim-exhaustion.t` / `test_swim_exhaustion`
specify the zero boundary, successful/failed Will checks, no duplicate fatigue,
rollback, undo and saved replay. Fixtures remain unrun.


### Further fatigue loss while swimming

With the health library installed, balance and endurance checks at zero or
negative fatigue preflight a one-point `RpgExpandedWound` through
`prepareSwimmingWound`. Set the check's `dropDestination` when incapacitation
may drop held equipment. The wound applies only if the check actually loses
fatigue, and uses the existing injury, shock and survival procedures. Without
the adapter, exhausted checks reject explicitly.

The current second's `RpgExpandedSwimConsciousness` must resolve first. This
ordering preserves independent one-second consciousness and five-second
struggling schedules. No fatigue or injury is charged merely for the Will check.
At negative full fatigue capacity, the swimmer becomes unconscious.
`expanded-swim-negative-fatigue.t` / `test_swim_negative_fatigue` specify five
Will checks followed by one fatigue point and one injury, including rollback,
undo and saved replay. Fixtures remain unrun; unconscious drowning transitions
are still outstanding.


### Entering water already exhausted

Starting a swimming encounter at zero or negative fatigue schedules an immediate
consciousness check at the entry instant. Resolve `RpgExpandedSwimConsciousness`
before the first balance check; later checks retain one-second spacing. A
swimmer who becomes exhausted during an existing check instead starts that
sequence at the next second. No elapsed time or extra fatigue is invented at
entry.

Encounter validation now checks the complete consciousness sequence: owned
receipts, distinct IDs, consecutive timestamps, bound outcomes and the retained
last-check boundary. A failed check cannot have later consciousness checks in
the same sequence. `expanded-swim-zero-entry.t` / `test_swim_zero_entry` specify
immediate entry, precondition rejection, single injury, rollback, undo, save
continuation and altered-history rejection. Fixtures remain unrun. Recovery
and renewed exhaustion within one uninterrupted encounter still need an explicit
transition; unconscious drowning and rescue work remains outstanding.


## Owned breath preparation

`RpgExpandedBreathPreparation` records `id`, `profile`, `approved` and evidence
of safe breathing access. Outside combat, `apply()` charges the shared clock
one second (full-2008 B351–B352). Repeated application reuses that receipt.
`assess()` spends neither time nor randomness. An optional `controlSkill` must
be a purchased `RpgExpandedBreathControlSkill` from the skills module: HT/Hard,
without defaults (B182). The committed skill roll supplies the 50% duration
bonus on success; failure leaves the ordinary prepared duration.

Set a reserve's `preparation` to that receipt. Start the reserve at the same
shared-clock time as preparation completion, with `prepared = true` and
`ventilation = 'none'`. Starting consumes the receipt once and derives
`controlSucceeded` from its check, without another time charge or roll. A stale,
foreign or previously consumed receipt rejects. Existing author-supplied
preparation flags remain available when no receipt is selected.

Combat preparation currently rejects with
`breath-preparation-combat-adapter-required`; it requires integration with the
concentration maneuver. Hyperventilation and oxygen supply remain outside this preparation operation.
The separate fatigue-recovery operation is described below.
`expanded-breath-preparation.t` / `test_breath_preparation` specify successful,
failed and absent skill checks, unpaid-skill rejection, replay, rollback, undo
and separate-process continuation. Fixtures remain unrun.


## Quiet breathing recovery

`RpgExpandedBreathingRecovery` takes `id`, `profile`, a purchased breathing
control `skill`, `approved` and evidence for two minutes of quiet rest without
restorative magic (full-2008 B182, B427). `restorativeMagic = true` blocks the
operation. The author must establish that fact; this interface does not inspect
unimplemented spell systems. Rest restrictions and protected fatigue use the
existing profile hooks.

`assess()` spends nothing. `apply()` rolls the skill and calls ordinary rest for
120 seconds, preserving shared condition clocks. On success it restores one
eligible FP unless ordinary recovery already restored it during those seconds,
and clears the rest credit consumed by accelerated recovery. On failure the
quiet rest still earns ordinary rest credit. No fatigue caused by hunger,
thirst, missed sleep or another protected cause is converted into ordinary FP.

The owned result contains `check`, `rest` and `recovered`; repeated application
returns `reused`. The `test_breathing_recovery` fixture covers success, failure,
ordinary-recovery overlap, incompatible magic, no recoverable fatigue, rollback,
undo and saved replay. Fixtures are unrun. Interruptible sessions and automatic
integration with future restorative spell effects remain incomplete.


Breathing recovery rejects an active breath reserve, nonzero air-loss clock or
an owned airless exposure even if the author has approved quiet rest. Assessment
also preflights shared-clock boundaries before the check. Profile validation
binds recovery completion times and outcomes and rejects duplicate or
overlapping history records. `test_breathing_restrictions` covers these air and
protected-fatigue gates plus altered history rejection; fixtures remain unrun.


For purchased exceptional physiology, enable `usePurchasedReserve` on the breath
reserve. The traits module then supplies active levels and validates eligibility;
the reserve snapshots them when starting. Without the traits module this option
rejects explicitly. The original author-supplied `reserveLevels` mode remains
available when the option is absent. See [Exceptional breath reserve](traits.md#exceptional-breath-reserve).


## Practical nature observations

`RpgExpandedNatureObservation` resolves the naturalist information tasks in
full-2008 B211. Supply a unique `id`, expanded `profile`, typed naturalist `skill`,
`occurrence` object, `planet`, `planetType`, and `purpose`: `plant-safety`,
`animal-safety`, `shelter` or `weather`. The skill's planet must match; its normal
purchased/default score applies, including biology defaults.

The author supplies the exact supportable `finding`, `approved`, and concrete
`evidence` describing what can be learned from the available signs. Set
`accessible` only when the observer has the required access and senses; use
`modifier` for applicable authored conditions. Preview is pure. `resolve()` rolls
once, returns the finding on success and no conclusion on failure, then retains
the result in `profile.natureObservations`. Replay binds the request and finding.
A new record cannot reroll the same occurrence and purpose for the same observer;
a genuinely changed situation requires a new authored occurrence.

The observation neither produces food nor changes shelter, exposure or poison
state. Those actions use their existing ledgers after a player decision. No fixed
duration is specified for these knowledge checks; authors account for travel,
search and inspection separately. The result is not automatically broadcast to
other characters or turned into their beliefs. Task access and the truth of the
finding are explicit author responsibilities, not inferred from a generic hook.

`test_nature_observation` covers success/failure, biology defaults, pure preview,
inaccessible evidence, replay, rollback and undo without resource or time changes.
Fixtures remain unrun while checks are paused.


## Receiving a nature finding

With social included, `RpgExpandedNatureDisclosure` delivers a resolved
observation's finding to its observer. Supply `id`, `assessment` (the observation)
and `recipient` (its profile), whose `knowledge` must be an owned
`RpgExpandedKnowledge`. `assess()` does not reveal a statement. `deliver()` records
one received statement and returns it; replay returns the same statement without
an additional entry, roll or time charge. An unresolved or failed observation
cannot disclose a finding. Other recipients need a separate communication action.

This delivery does not add beliefs or fabrications. It records what the observer
learned without forcing later choices. Observation history validation checks
ownership, unique IDs and occurrence/purpose pairs, bound facts, and the original
check outcome and finding. `test_nature_disclosure` specifies missing and failed
findings, rollback, undo, replay, cross-process saves and outcome-tampering
rejection. Fixtures remain unrun while checks are paused.


## Nature observations through native actions

`RpgExpandedNatureObservationAction` binds one `observation`. Authors attach it
to a `Verb`, parser grammar, or a dialogue choice that calls
`perform(context.asker)`. Normal action execution delegates through
`perform(context.actor)`. The actor's `rpgProfile` must own the observation;
a mismatched actor is blocked before rolling or changing history.

All routes use the same owned result, so repeated commands cannot reroll it.
The `rpg.expanded.nature-observation` event carries status and reason only.
Use the separate disclosure operation to present a finding to its observer.
No vocabulary or conversation choice is installed merely by including exploration.
`test_nature_actions` specifies parser, structured-action and dialogue parity,
wrong-actor rejection, rollback, undo and replay. Fixtures remain unrun.


## Fossil study findings

With skills installed, `RpgExpandedPaleontologyAssessment` resolves one approved
finding from a specimen (full-2008 B212). Supply a stable `id`, observing `profile`,
`RpgExpandedPaleontologyContext`, stable `specimen` identity, `accessible = true`,
and the authored `finding`, `approved` and `evidence`. The context selects
recognition, habitat, structure or age; authors must ground the conclusion in the
specimen and provide any applicable equipment modifier. An age finding should
state the supported approximate age, not an invented precision.

`assess()` returns eligibility and score without exposing the finding, rolling,
spending time or recording history. `resolve()` performs one check and returns the
finding only on success. Both successful and failed checks enter the observer's
`paleontologyAssessments`; repeating the same object reuses its outcome. A second
object with the same id, or the same specimen and task, rejects. The supplied
printing specifies no fixed study duration here, so this operation adds none.

The receipt binds the specimen, conclusion, approvals, task, specialty, technology,
laboratory flag and scoring inputs. Changing those facts after resolution rejects
rather than rerolling. Profile validation checks owned history. Familiarity records bind their owner, skill, equipment type and configured
penalty; the result retains the modifier used for its original roll. Later practice
or recognition can improve new studies without rewriting previous findings. Laboratory access may use an authored fact or the live equipment interface below.
Include social for the disclosure and action interfaces below.

`test_paleontology_assessment` specifies preview purity, successful and failed
findings, duplicate rejection, exception rollback, undo, replay, cross-process save
continuation, changed-context rejection and blocked access. These fixtures are
unrun while checks are paused.


### Receiving fossil findings through native actions

`RpgExpandedPaleontologyDisclosure` in social accepts an `id`, resolved
`assessment` and `recipient`. The recipient must be the observer and own their
`RpgExpandedKnowledge`. `assess()` previews eligibility without returning the
statement. `deliver()` records exactly the successful finding in `received` once;
failed assessments cannot disclose a finding. It does not change beliefs, spend
time or roll again. The receipt binds its timestamp, knowledge owner and exact
statement, including across save continuation.

`RpgExpandedPaleontologyAction` takes `assessment`, optional `disclosure`, and
`operation` (`assess` or `receive`). `exec(context)` uses the command actor;
dialogue choices call `perform(context.asker)`. Both require the actor's
`rpgProfile` to be the observer. The `rpg.expanded.paleontology` event carries
operation, status and reason; authored presentation uses the returned result.

The minimal disclosure and action fixtures demonstrate parser commands, structured
verbs and dialogue choices sharing these objects. Their unrun tests cover missing
or failed findings, owner mismatch, preview purity, repeat delivery, rollback,
undo, save continuation, timestamp tampering and route parity.


### Live laboratory equipment

Set the study context's `laboratoryEquipment` to an
`RpgExpandedLaboratoryAssessment` from equipment. This is a toolkit assessment:
provide the laboratory `toolkit`, its matching `items`, `quality` and `techLevel`,
the observer `profile`, the fossil `skill`, and approved evidence that the facility
is a laboratory adequate for this specimen. Owned tools must be accessible;
borrowed facilities use recorded `accessGrants` with the existing site, expiry and
revocation checks. A valid assessment supplies the mandatory microscopic laboratory.

The quality modifier applies to `age` tasks. Other tasks still check access and
tool technology but receive no dating-quality bonus. Leave `equipmentModifier`,
`equipmentTL` and the generic `equipmentAssessment` unset when using this interface;
combining them rejects rather than counting equipment twice. No additional inventory
or time ledger is created.

Committed findings bind the equipment definition. Later loss or revocation of
access does not erase an existing result or trigger another roll; a new study
checks current access. Changing the bound adequacy, tool quality or technology
rejects reuse. `test_paleontology_equipment` specifies owned and borrowed access,
revocation, quality, technology differences, rollback, undo, save continuation and
replay after losing access. Fixtures remain unrun.


### Familiarity and retained findings

Attach an owned `RpgExpandedFamiliarity` to the fossil context's `familiarity`
field when that equipment type requires it. The normal familiarity penalty applies
once alongside laboratory quality and technology. Assessment results expose the
`familiarityModifier` used, and replay returns the original score and modifier.
Practice uses the existing familiarity time ledger. A new specimen study sees the
improved familiarity; an already resolved study retains its original outcome.
Changing the bound familiarity identity or penalty rejects reuse.

`test_paleontology_familiarity` specifies preview purity, the initial penalty,
practice removing the penalty for a new study, old-result replay, rollback, undo,
save continuation and receipt tampering. It remains unrun while checks are paused.
