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
be concentration. The library does not charge that action again. It currently
accepts these facts from the author and does not implement the action or catalogue
eligibility checks. Record the source of each applicable fact in the evidence.

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
Owned suffocation handoff, drowning, resuscitation and vacuum adjustments remain
incomplete. An expired assessment alone does not count as implementing them.

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
