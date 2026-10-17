# Authoring mundane challenges

The rules layer computes outcomes. The game authors what those outcomes mean,
which information players receive and which alternatives remain available.
Mechanics and examples use original wording and content.

## Character profiles

`RpgProfile` is an authored record shared by PCs and NPCs. Its optional `actor`
identifies the associated world entity. A `Thing` can refer to the record through
`rpgProfile`; binding that property is explicit.

| Property | Default | Meaning |
| --- | --- | --- |
| `st`, `dx`, `iq`, `ht` | 10 | Strength, coordination, mental ability and physical resilience |
| `will`, `perception` | `iq` | Mental resistance and noticing ability; independently overridable |
| `maxHP` | `st` | Capacity reserved for future injury rules; no injury tracking yet |
| `maxEnergy`, `energy` | `ht`, `maxEnergy` | Capacity and available effort; expenditure does not implement fatigue thresholds |
| `skills` | `[]` | Authored `RpgTraining` records |
| `traits` | `[]` | Authored `RpgTrait` records |

`attributeScore(enum)` accepts `rpgST`, `rpgDX`, `rpgIQ`, `rpgHT`, `rpgWill` and
`rpgPerception`. `skillScore(skill)` returns a numeric rating or nil when training
is required. These queries do not roll, emit output or change game state.

A `RpgSkill` declares its attribute, difficulty (0, 1 or 2) and `defaultPenalty`.
Defaults are opt-in: nil means training is required, even for an easy skill.
The game decides cultural familiarity and access when defining its skill roster
and approach prerequisites. The attribute used for an untrained default is capped
at 20 before adding the declared penalty.

`RpgTraining` associates `skill` and positive `points`. The following offsets
apply to the current governing attribute:

| Points invested | Difficulty 0 | Difficulty 1 | Difficulty 2 |
| --- | --- | --- | --- |
| 1 | +0 | −1 | −2 |
| 2–3 | +1 | +0 | −1 |
| 4–7 | +2 | +1 | +0 |
| 8–11 | +3 | +2 | +1 |
| Each further four points | Another +1 | Another +1 | Another +1 |

Training never silently falls back to a better untrained rating. Duplicate
training for a skill is a configuration error. Point investments are authored
starting data; this module does not award or spend advancement points.

`RpgTrait.modifierFor(context)` returns a small numeric modifier. Keep the hook
observational and narrowly conditioned on its intended activity. A trait can
grant a benefit or impose a limitation; its name alone has no effect. Traits do
not supply automatic compulsions, real-time recharge rules or universal bonuses.

## Goals, approaches and retry slots

`RpgChallenge` has a stable, unique `id`, maintained `completed` flag and
maintained `revision` counter. Different approaches and characters can pursue
the same goal. Completing it closes the entire goal.

An `RpgApproach` defines one method:

| Setting/hook | Contract |
| --- | --- |
| `id`, `challenge` | Nonempty stable ID, unique within the goal; owning goal |
| `skill` / `attribute` | Skill to check, or an attribute when skill is nil |
| `modifier`, `modifierFor(c)` | Fixed and contextual adjustments |
| `automatic` | Resolve a valid attempt without a roll or skill prerequisite |
| `timeCost`, `energyCost` | Nonnegative seconds and energy charged on a fresh resolution |
| `costlyMargin` | Maximum ordinary failure margin promoted to costly success; zero disables |
| `completesChallenge` | Whether achieving this approach completes the shared goal; default true |
| `blockedReason(c)` | Player-safe reason ID, or nil to permit the attempt |
| `opponent` | Optional opposing `RpgProfile` |
| `oppositionSkill` / `oppositionAttribute` | Opponent's skill or attribute |
| `oppositionModifier`, `oppositionModifierFor(c)` | Opponent's adjustments |
| `apply(c, result)` | Execute authored consequences exactly once per fresh resolution |

The resolver charges every freshly resolved attempt, including failure and a
tie. Automatic solutions can also have costs. Blocked, reused and already
completed attempts incur no RPG costs and consume no dice.

Declare a `RpgAttempt` with `profile` and `approach` for every permitted pair.
These slots are the authority for retries across input paths. Missing or
duplicate slots are errors rather than a reason to invent an untracked attempt.
The explicit slots avoid allocating persistent source entities during play.
Dice and explanations use lists of scalar snapshot data, supported by the
journal and logical saves. An NPC needs only the slots and
statistics for activities the adventure actually supports.

The current slot stores the most recent revision's outcome. Call
`challenge.advance()` during a committed action after a material change, such
as learning a relevant technique, acquiring suitable equipment, or changing the
opposition. This permits fresh attempts for all profiles/approaches on that goal.
Use separate goals if changes should affect only one obstacle. Revisions must
only increase; never advance them for a retry, wording change, menu refresh,
unrelated command or passage of a parser turn alone. A new approach has its own
slot and can be attempted without advancing another approach's revision.

Prerequisites are checked before recalling a slot. A result cannot be replayed
through a currently forbidden approach. Blocked attempts are not recorded, so a
missing key can be acquired and used without a revision change.

## Numerical resolution

`rpgCheck(score, roll)` is a pure helper for a supplied three-die total. An
effective score below three returns blocked. Otherwise the result succeeds when
the total is at most the score, subject to these exceptions:

- 3 or 4 always succeeds critically.
- 5 is critical success at score 15+, and 6 at score 16+.
- 17 always fails and is critical failure at score 15 or lower.
- 18 always fails critically.
- A result ten or more above the score fails critically.

`margin` is score minus roll, including on exceptional results. `critical` is
`success`, `failure`, or nil. Ordinary failed checks are setbacks; critical
failures are complications. The game supplies specific consequences.

Opposed attempts roll once for each side. A success beats a failure. When both
succeed, the larger margin wins; when both fail, the smaller failure margin wins.
Equal margins with matching success states tie. Critical flags do not replace
this comparison. A tied attempt is recorded, costs resources, and requires a new
approach or material change rather than an automatic reroll. The opponent must
have a usable rating; missing training or a rating below three blocks the attempt
without rolling either side.

`costlyMargin` applies only to an ordinary failed, unopposed check. It never
promotes critical failures, defeats or ties in a contest. Costly success counts
as achieving the goal; `apply` must supply the meaningful extra consequence.

`rpgRandom` uses a deterministic integer generator. `seed(n)` accepts
1–2147483646 and resets its draw counter; call it during initialization, not on
each attempt. Each ordinary check consumes three draws, an opposed check six.
The documented default seed is 1; games can initialize a different seed. All
generator state is journalled with attempt state. Undo/replay of the same action
therefore reproduces the roll. This is reproducibility, not protection against a
player deliberately exploring different histories.

## Results and consequences

`rpgResolve(profile, approach)` returns a temporary `RpgResult`:

- `status`: `resolved`, `reused`, `blocked`, or `complete`.
- `outcome`: `success`, `costly-success`, `setback`, `complication`, or `tie`;
  nil for blocked/complete results.
- `achieved`: true for success or costly success; otherwise nil.
- `reason`: a player-safe authored ID or a built-in blocked reason.
- `score`, `roll`, `margin`, `critical`, and their `opposition*` counterparts:
  private mechanical details; nil where no roll was made.
- `timeSpent`, `energySpent`: costs charged by this call, zero when reused.
- `recordedTimeSpent`, `recordedEnergySpent`: original costs of the recorded
  attempt, preserved when it is reused or later reported.
- `dice`, `oppositionDice`: individual faces, or empty lists without a roll.
- `kind`: `automatic`, `check` or `contest` for a resolved attempt.
- `calculation`, `oppositionCalculation`: temporary explanations of the abilities
  and modifiers actually used. Their scalar snapshots are retained by the slot.

The built-in reasons are `training-required`, `too-difficult`,
`insufficient-energy` and `opposition-unavailable`. The library emits no prose
for them. Supply original game messages or a host translation as needed.

The slot is recorded and any goal completion set before `apply` runs, preventing
recursive resolution from applying the same consequences twice. A source
exception rolls back the enclosing turn, including dice, costs, records and
consequence mutations supported by the runtime. Use normal blocked results for
expected impossibility. `RpgError` indicates a bad configuration or API argument.

Do not retain temporary contexts/results in World properties. Copy only needed
scalar values, or use the authored attempt slots. Hooks must not perform external
I/O or effects that the runtime cannot undo. Consequences should mutate declared
world state, relations and knowledge.

## Hybrid actions, queries and time

Invoke the resolver only from `Action.exec`, a committed dialogue selection, or
an NPC's committed action. Keep prerequisites and target validation in the shared
action path. Dialogue adapters must enforce equivalent scope/target requirements
in their approach hooks; selecting a menu must not grant additional permission.
The example's choices call the same gameplay adapter as parser actions.

Never roll in ranking, verification, affordances, choice labels/availability or
menu refresh. vhyl requires those hooks to remain observational; this language
version does not enforce their purity. A preview can disclose an authored option
without disclosing its hidden rating or whether it will succeed.

`rpgLedger.seconds` accounts only for challenge durations. It does not drive
vhyl events, replace world time, charge travel or convert every command into
seconds. vhyl retains its existing turn policy: a parser/structured attempt
reaching the normal cycle may advance a turn even when blocked or reused, while
previews and dialogue refresh do not. Later scheduling integration needs an
explicit game-wide time policy.

`rpgPublish(result)` is an optional disclosure step. It emits `rpg.result` with
these scalar values, in order:

```text
version (1), challenge ID, approach ID, actor,
status, outcome, reason, achieved, timeSpent, energySpent
```

The envelope omits scores, dice, margins, critical flags and opponent identity.
Only publish it for a player-visible attempt: even an ID or failed attempt can
be secret. NPC checks and hidden checks can use the resolver without publishing.
Presentation belongs to the game; the example maps results to original messages.
Its `SurveyMessage` also emits `survey.text` with one original prose string so
the event-only terminal host can display the same narrative as a direct console.
Those presentation events are example-specific and are never emitted by queries.

The prototype adds no generic action verbs and changes no vhyl message IDs or
verb codes. The example uses 100–104 and fixtures use additional local codes.
The optional [reporting extension](reporting.md) adds assessment and roll events.
Its example query uses code 105 and does not enter the gameplay action cycle.

## Authoring safeguards

Validation during `vhylStart()` rejects invalid skill definitions, duplicate
training, invalid profile values, malformed costs, invalid opposing profiles,
duplicate goal/approach IDs and duplicate attempt slots. Skill ratings change
with their governing attributes. Author settings should remain within documented
integer ranges: attributes 1–100, training 1–10000, costs 0–86400 seconds and
0–1000 energy, modifiers −500–500, effective scores −1000–1000. Maintained
counters are checked signed 32-bit integers; overflow fails the turn.

Give required progress a reliable route or a consequence that preserves another
route. A failed expertise check can lose an advantage without hiding the only
required clue. Keep fictional prerequisites separate from ability: the correct
key works without a roll, and skill cannot make an inapplicable object into one.
