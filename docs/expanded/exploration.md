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
fixtures remain unrun while checks are paused; dedicated transaction and
cross-process continuation fixtures are still outstanding.
