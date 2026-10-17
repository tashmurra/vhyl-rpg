# Playable resilience and short conflicts

These optional modules turn injury, fatigue and opposition into authored play.
They use bounded adventure policies rather than a per-parser-turn medical or
tactical simulation. PCs and NPCs use the same profile and body types.

```text
#include <vhyl-rpg.t>
#include <vhyl-rpg-resilience.t>
#include <vhyl-rpg-conflict.t>
```

The reporting module remains independently optional. See the complete
[gatehouse scene](../examples/resilience/main.t) and
[play instructions](../README.md).

## Body state and condition effects

Bind an authored `RpgBody` to exactly one `RpgProfile` in both directions:

```text
traveller: RpgProfile actor = player resilience = travellerBody;
travellerBody: RpgBody profile = traveller injury = 3 aidRemaining = 3;
```

`body.hp()` is `profile.maxHP - body.injury`. Injury is a stored deficit, so a
capacity increase preserves existing wounds. The stored fields also include
shock, stun, unconsciousness, death, untreated injury and recovery clocks. All
are journalled and included in logical saves.

| Condition | Mechanical consequence |
| --- | --- |
| Injury | The next committed check using coordination or intelligence, including associated skills, takes accumulated shock, capped at −4 |
| Major wound: one injury greater than half capacity | One health check; failure stuns, and failure by five or critical failure causes unconsciousness |
| HP strictly below one third of capacity | `mobilityDivisor()` returns two; the short conflict halves defense, rounding up |
| Energy strictly below one third of capacity | Strength checks use half strength, rounding up; mobility/defense are also reduced |
| Zero energy | Approaches requiring exertion are blocked; an authored non-exerting approach can still permit talking |
| Zero HP or lower | Deterministic incapacitation; recovery or an authored rescue is required |
| Lethal body at −5 times capacity | Death; ordinary rest and treatment cannot revive it |

The one-third boundary is consistently **strictly below**, checked with integer
arithmetic. Injury and exhaustion share one mobility divisor rather than stacking
multiple halvings. Maximum HP and authored weapon damage are not recalculated
from temporarily reduced strength. A zero-capacity energy pool opts out of effort
exhaustion. The default `lethal = nil` makes defeat survivable; death requires an
explicit author setting. There are no repeated consciousness/death rolls on
ordinary parser commands, automatic bleeding timers or mortal-wound subsystem.
The library also does not drop inventory or force posture changes on a failed
major-wound check; add those consequences explicitly if the scene supports them.

`condition()` gives a summary: well, wounded, badly-hurt, exhausted, stunned,
unconscious or dead. It prioritises more serious states; it does not replace the
individual flags or numerical values. `rpgPublishBody(profile)` explicitly emits
the player's condition and capacities. Publishing NPC health is a separate
author decision.

The default `RpgApproach.requiresExertion` is true when this module is included.
Set it to nil for an appropriate low-effort or social method. Condition checks
and modifiers feed the same preparation/calculation used by `rpgAssess` and
`rpgResolve`; previews never draw recovery dice. `afterAttempt` clears shock
only after a fresh check has used it. A blocked or cached check does not clear it.

For non-RPG movement, inventory actions and bespoke adapters, enforce applicable
body flags in their execution checks and call `body.endAction()` after committed
activity. It expires shock and interrupts quiet rest. The core does not globally
prevent all standard adventure verbs while unconscious. The gatehouse adapter
demonstrates an explicit help route and conditions on its gameplay actions.

## Applying injury

`rpgInjuryFor(damage, armor, numerator, denominator)` is pure arithmetic:
subtract armor, multiply positive penetration by the explicit ratio, round down,
and retain at least one HP when penetration is positive. Armor can stop an attack
completely. Damage and armor are nonnegative integers up to 10000; ratio parts
are 1–10. Weapon ranges, armor divisors and damage categories are authored outside
this helper.

`rpgWound(profile, damage, armor, numerator, denominator)` commits that injury,
updates shock, adds only fresh injury to the treatment budget, and makes a major
wound check when needed. Injury saturates at six times maximum HP. Its temporary
`RpgCareResult` reports actual injury and the private health check. It emits no
player prose or automatic medical report.

Invoke mutation helpers only during committed actions or consequences. Exceptions
roll back the enclosing gameplay transaction, including dice and condition state.

## Treatment, rest and rescue

An authored `RpgTreatment` declares its skill, modifier, supply charges, duration,
healing bonus and observational `available(healer, patient)` gate. The default
duration is 660 seconds. `rpgTreat(healer, patient, treatment)` checks the healer,
skill, patient and supplies before charging anything. Self-treatment is allowed
when the healer can act. Healer condition modifiers apply to the skill check.

One fresh attempt consumes one supply charge and its declared time:

- Success restores one die plus the declared bonus, with a minimum of one HP.
- Critical success uses six instead of drawing the healing die.
- Ordinary failure provides one HP of bandaging.
- Critical failure instead inflicts two HP of injury.

The total healing already includes bandaging. It is capped by untreated injury
and actual injury. An attempt consumes the entire current treatment budget even
when it fails. A later wound adds only its own damage to that budget, so a minor
scratch cannot reopen old failed treatments. Starting injuries need an explicit
`aidRemaining` budget if they are eligible for first aid. Successfully restoring
positive HP and usable energy can wake a patient; it does not automatically clear
stun. This is an explicit adventure recovery policy.

`rpgRest(profile, seconds)` models uninterrupted, safe quiet rest supplied by the
game, accepting 1–86400 seconds per call. It charges elapsed RPG time, restores
one energy per full ten minutes, and makes one health check per full day for one
HP. Fractions carry only within uninterrupted rest; exertion, injury and explicit
`endAction()` interrupt the clocks. Rest at full energy cannot bank future energy.
A quarter-hour of rest clears temporary stun/unconsciousness when HP and energy
are positive at the end. Dead bodies do not recover.

The game must author safety, shelter and eligibility before calling rest. There
is no automatic recovery attached to `WAIT`, movement or dialogue refresh, and
the RPG ledger does not run the vhyl scheduler. `rpgRecoverStun(profile)` is a
separate one-second committed recovery maneuver with one health roll.

Author a rescue or alternate route when the story should continue after defeat.
The gatehouse's `accept help` is a specific clinic transition costing a day,
returning an incapacitated protagonist to one HP. It is not a general free-healing
API, does not revive death, and is unavailable during the confrontation.

## Social opposition

`RpgDisposition` binds an NPC profile to an authored attitude from −3 to +3.
Its observational `permits(actor, approach)` hook can refuse requests regardless
of the numeric score. `RpgSocialApproach` uses a skill-versus-Will contest, adjusts
resistance by disposition, and changes attitude after a fresh resolution. Defaults
are +1 for achievement and −1 for any other resolved outcome, clamped to the
range. Authors can set those shifts.

Social attempts retain the core's slots, prerequisite checks, costs and retry
rules. A repeated request neither rolls again nor changes attitude again. New
facts, concessions or an explicitly related development offer can advance the
goal revision. Success changes only the authored consequences; it grants no
general permission to control an NPC or override a forbidden request. Keep
opposition scores and reactions undisclosed unless the story permits them.

## Short physical conflicts

An `RpgConflict` has exactly two authored `RpgCombatant` objects, a stable ID,
availability hook, time per exchange and maximum exchange count. It is a bounded
scene controller. It does not implement a tactical map, initiative system,
ammunition, equipment catalogue or one-second simulation for every world actor.

`rpgBeginConflict(conflict)` begins it once. `rpgConflictStep(conflict, maneuver)`
commits one protagonist maneuver and one eligible opposition reply:

| Maneuver | Effect |
| --- | --- |
| attack | Skill/attribute check, eligible defense, authored damage dice and adds, armor and injury |
| defend | +2 defense against the reply |
| recover | A health check to remove stun before the reply |
| escape | A coordination contest; success ends the scene before a reply |
| surrender | Ends immediately without retaliation or another roll |

Attacks default to one energy; unaffordable or blocked attacks consume no dice,
time or exchange. The default defense is `(coordination + health) / 4 + 3`, rounded
down, then adjusted for condition. Stun adds −4. Critical attack success bypasses
defense; ordinary attack failure misses. Damage dice, bonus, armor and wound ratio
are explicit combatant settings. The default unarmed attack is one die minus two,
with a minimum of zero damage. A stunned opponent recovers instead of attacking.
Unconscious or dead participants do not make attacks.

Resolved exchanges cost the authored duration (two seconds by default). The
default six-exchange limit ends in stalemate. Outcomes are won, defeated, escaped,
surrendered, stalemate, or another explicit authored end such as truce. A finished
conflict cannot restart; use a new authored scene for a later encounter.
`ended(result)` runs after the persistent outcome is set, exactly once. It can
award a milestone, open a route or arrange rescue. Call `rpgFinishConflict` from
committed story code to end a scene when its fiction changes.

`rpgPublishConflict(result)` is opt-in. It emits the encounter outcome and count;
individual strike details appear only when `discloseRolls` is authored true.
Trusted strike results contain attack/defense checks, individual faces, damage
and injury. The gatehouse's `--details` view shows permitted dice. Encounter state,
randomness and consequences survive undo and cross-process restore; the library
does not retain a complete combat log or retrospectively reroll a past strike.

## Event envelopes

All envelopes below begin with version 1 and are emitted only by explicit
publication functions:

```text
rpg.body: actor, condition, currentHP, maxHP, energy, maxEnergy, mobilityDivisor
rpg.conflict: conflictID, status, reason, maneuver, outcome, exchanges, active
rpg.strike: conflictID, side, outcome, score, attackTotal, defenseTotal,
            damage, injury, attackFaceCount, defenseFaceCount, damageFaceCount,
            attackFaces..., defenseFaces..., damageFaces...
```

Strike `side` is acting or reply. No hidden NPC HP is included in the encounter
envelope. Roll publication is an author ceiling; hosts should additionally honour
the player's display preference. Core `rpg.result`, `rpg.assessment`, `rpg.roll`
and `rpg.calculation` schemas are unchanged.
