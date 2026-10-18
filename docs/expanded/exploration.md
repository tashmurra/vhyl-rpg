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
