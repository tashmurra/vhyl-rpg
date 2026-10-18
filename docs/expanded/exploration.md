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
while checks are paused. Transaction, undo and save-continuation coverage for
these new interfaces remains to be added.
