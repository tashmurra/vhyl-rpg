# Running and fatigue

The optional expanded running module implements ordinary ground sprinting and
paced running from `full-2008`, B218 and B354, using the shared health and rest
mechanics corresponding to B426–B427. It does not replace Lite journeys.

## Include and author

Include the core, progression and Lite umbrella, then the expanded foundation,
expanded skills and `vhyl-rpg-expanded-running.t`, each once. It is not part of
the character/social umbrella. Including it alone changes no existing activity.

```text
trackRules: RpgExpandedRules;
runner: RpgExpandedProfile rules = trackRules skills = [runnerTraining];
runnerTraining: RpgExpandedTraining skill = rpgExpandedRunningSkill points = 4;
run: RpgExpandedRunning profile = runner;
```

`rpgExpandedRunningSkill` is a shared, immutable HT/Average definition with HT−5
default. Training and point accounting use the existing expanded skill system.
Keep one activity owned by each character and reuse it across commands; do not
recreate it to reset fatigue counters. A custom `skill` must be an expanded
HT/Average skill with the `running` ID, not a wildcard. Do not change the profile
bound to an activity during play.

Call mutations inside an `Action.exec` or committed dialogue transaction:

- `advance(seconds)` runs up to 86,400 seconds, stopping if movement or action
  becomes impossible. Zero seconds is a validated no-op.
- `speedHundredths()` previews the **next second's** speed in hundredths of a
  yard per second, without spending time or drawing dice.
- `setPace('sprint')` or `setPace('paced')` changes pace and resets acceleration.
  Selecting the current pace changes nothing.
- `interrupt()` resets acceleration without spending time. Call it when stopping,
  turning, or starting rest. Fatigue interval progress is retained.

Set `sprintEligible` from authored terrain and direction facts. While false,
sprinting uses ordinary Move and still checks fatigue every 15 seconds. Each
ineligible running second resets acceleration. For an instantaneous turn or
stop between calls, use `interrupt()` even if eligibility is true again by the
next call. Sprint acceleration also requires standing posture.

## Checks, movement and elapsed time

Sprinting checks every 15 completed seconds; paced running checks every 60.
Choose the higher effective HT or Running score, after contextual modifiers;
HT wins ties. Resolve exactly one check. A failure applies one FP of exertion
through the existing health helper; its environmental surcharge, if any, still
applies. Success costs no FP. Encumbrance affects Move, not this roll.

The observational `fatigueContext(which)` hook supplies a fresh `RpgLiteContext`
for each candidate: `nil` means HT, otherwise `which` is the Running skill.
Override it to provide authored situational modifiers, retaining the supplied
attribute/skill identity. Preview and validation call this hook too, so it must
not mutate state or draw randomness. The selected context uses the existing
check machinery, including its reroll hook.

Speed starts from the profile's adjusted Move. Sprinting uses normal Move for
one second, then gains 20%, with at least +1 Move. Fractional speeds are kept;
Move 7 becomes 8.4 yards/second. Paced speed is half the calculated sprint
speed, or 4.2 in that example. The general fatigue penalty applies strictly
**below** one-third of maximum FP. The Lite journey's additional penalty at
exactly one-third does not apply here. Immobile or incapacitated profiles have
zero speed.

Separate sprint and paced counters preserve partial intervals across pace
changes, interruptions and rest. For example, sprinting for 14 seconds, then
pacing for 59, leaves both checks one second away. **This mixed-pace accounting
is an extension policy**, not a procedure specified by the reference. Rest does
not erase these counters; it restores eligible FP through the existing rules.

Each simulated second checks ability to act before movement. At zero FP or less,
this includes a Will roll; reaching zero during a batch cannot bypass the next
second's check. The completed second then updates fatigue and health-condition
clocks. The global time ledger is charged once for the completed total. A failed
pre-second check does not consume that second, but its collapse and dice remain
part of the action. These rules give the same state and random draws for a long
advance and equivalent one-second calls.

The returned `RpgExpandedRunningResult` contains:

| Field | Meaning |
| --- | --- |
| `status` | `resolved`, `blocked` before any elapsed time, or `stopped` after some elapsed time |
| `reason` | `nil`, `incapacitated`, `cannot-move`, or `cannot-act` |
| `seconds` | Actual completed running seconds |
| `fatigue`, `injury` | Actual losses caused by running's exertion checks, including environmental surcharge and overflow injury |
| `check` | Last running fatigue check, or `nil` if none occurred |
| `checks` | Ordered effort, consciousness, running, and overflow-injury checks |

Passive condition hooks retain their own effects and receipts; they are not
reported as running injury. Configuration errors throw before activity changes.
Undo, exception rollback and saves use existing vhyl journalling. Saves remain
specific to the exact compiled game; no migration is supplied.

## Integration and limits

The activity does not choose routes, move world actors, or integrate distance.
For precise travel, sample `speedHundredths()`, advance one second, and apply
that distance only if the result completed a second. Longer advances are useful
when exact distance is irrelevant. Do not also charge command time, advance
health clocks, invoke a Lite journey, or spend the legacy energy pool for the
same running time. Battle fatigue remains a separate end-of-battle rule.

Running clears the quiet-rest counter on each completed second. Interrupt the
activity before calling `rpgLiteRest`; ordinary eligible FP recover at one per
600 seconds. Food, water, sleep and temperature recovery restrictions remain.

This module deliberately reuses the host's Lite health approximation: failed
zero-FP effort checks cause unconscious collapse rather than separate conscious
incapacitation. Critical-failure heart attacks and resuscitation are not
implemented. Existing overflow injury, automatic collapse at negative maximum
FP, low-FP movement/defense penalties, and rest behavior are inherited; this is
not a complete expanded health conversion.

Enhanced Move, Fit/Very Fit, fatigue immunity, extra effort, racing contests,
other exertion activities and automatic combat-movement integration are outside
this module. Authored trait pricing alone does not implement those effects.
