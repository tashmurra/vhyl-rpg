# Freeform magic

`vhyl-rpg-magic.t` is an opt-in extension built on expanded characters and
skills. It provides deterministic mechanics and typed effect operations. The
[GM interface](gm.md) supplies recorded judgments about declared effects and
coincidence; it does not execute model-generated code. An inference provider is
optional. The Python bridge can call a small local model, an operating-system
service, or a separate process without changing the rules library.

The [coverage ledger](magic/coverage.json) maps all 45 domain/rank entries to
operations, sources, adapters and tests. This is a reusable rules library, not
a physics simulator or a catalogue of every example effect in the source.
Games still author their objects, properties, possible observations, locations,
practices, spirit relationships and narrative consequences. Spirit-vessel
construction remains deferred by the user's decision; defective items and
backlash postponement are deliberately absent from the adopted rules.

## Include and initialize

Include core, progression, Lite, expanded foundation, expanded characters,
expanded skills, `vhyl-rpg-gm.t`, then `vhyl-rpg-magic.t`. The umbrella includes
character investment, scaling, world state, health, casting, resources,
defenses, operations, work/rituals, groups, consequences, items, spirits and mind
adapters. Existing games do not need to include either new umbrella.

Attach an owned `RpgMagicState` contribution to each caster's expanded profile.
Paid domain training remains in the profile's skills; rank prices are separate.
Use `RpgMagicGoal` and owned `RpgMagicOpportunity` objects for stable retries.
Every input route to an attempt must share that opportunity. Only a materially
changed situation may reopen its goal.

For world operations, register `RpgMagicSubject` and `RpgMagicPlace` objects in
one `RpgMagicWorld`. Link the caster's `world` and `subject`, and set each
profile's `magicSubject`. A subject is the adapter for an adventure entity,
not a replacement for that entity. Relocation and existence changes update a linked
entity through ordinary adventure containment; mapped destinations require a room. The game consumes typed properties and
topology through `value`, `rpgMagicDestinations`, `rpgTraverseMagicPassage`,
`rpgMagicActionRate` and `rpgMagicSubjectCanAct`. It must use those adapters in
its movement, environment and scheduling rules; merely including magic cannot
rewrite a game's arbitrary custom movement or physics implementation.

## Declare, adjudicate, execute

Create a `RpgMagicOperation`, populate its declaration, and call
`rpgPrepareMagicOperation(operation, caster)`. Its fields include a registered
target, operation verb, optional destination/property, amount, duration, reach
selection and distance. Derived domain requirements cannot be lowered by a GM
reply. A property ID selects an authored `RpgMagicProperty`; it is never a
language-level object property. Creation uses an authored dormant subject with
`creationTemplate = true`, known composition and viability.

For example, `reshape-life` distinguishes simple life, self and another complex
organism; `generate` distinguishes electromagnetic energy from motion and adds
power 2; `create` derives life/matter rank and power 2. `rpgComposeMagic` merges
up to eight prepared operations, taking the maximum rank in each domain.
Unknown verbs are rejected. Changing declaration parameters requires preparing
the operation again; changing a prepared step requires recomposing its parent. A host accepting an AI proposal constructs these
typed declarations, validates them, then registers the candidates for a ruling.
It must not evaluate provider text as code or manufacture arbitrary properties.

An intent's `magic-1` ruling is `[effect ID, appearance, modifier, rationale]`.
The selected effect, targets, prerequisites and modifier bounds come from game
state. `rpgAssessMagic` is pure; it never calls a provider or rolls dice.
`rpgCastMagic` validates, charges once, rolls, records strain, applies counters,
resolves defenses and delivers only supported scope. Surplus margin does not
expand the declaration. `rpgPublishMagic` exposes only status, delivery and time;
private observations and rationale require a separate authored disclosure rule.

Expert authors can still implement `RpgMagicEffect` directly. Its `available`,
`facts`, `afterRoll`, `defend` and `apply` methods are trusted game code. Sustained
custom effects must explicitly set `lifecycleImplemented`; a flag alone is not
a substitute for implementing their behavior. The original workshop demonstrates
this small custom-handler path. General declarations use the typed operations.

## Casting, defenses and cooperation

Casting uses the lowest paid required domain skill, mastery ceiling, additional
domain penalty and the accepted modifiers. Haste is an authored penalty, with
at least −3 for instantaneous casting. `rpgCheckMagicDistractions` commits one
ordinary distraction check per opportunity; forced interruptions use Will−3.
Tool dependence, training, preparation, formula investment, scene coincidences,
world-turn frequency, source-rating bonuses and the three-attempt retry sequence are retained.

Direct living or sapient targets use Will. An aware, conscious, willing target
may waive it; possession always resists. The original dice are compared with
casting skill capped at `max(16, target Will)`. Resistance uses the lesser of
that margin and remaining scope. Failed attackers cannot win; failed defenders
lose to a successful attacker; ties defend. Critical casting does not bypass
defenses. Ordinary resistance-to-magic bonuses do not apply. Indirect attacks
use an authored `RpgMagicPhysicalDefense`, cover, armor and host injury handling.

Declare `RpgMagicCounter` objects in initiative order before rolling. Each
participant needs rank 1 in every incoming domain. Successful raw margins reduce
scope; a concerted counter's critical failure defeats that counter group's
contribution. Each defender contributes at most once to an incoming cast.
Countering may interrupt the defender's own work. It spends no normal reserve.

`rpgCastMagicGroup` requires fully qualified, mutually visible, communicating
participants. It combines actual successful raw margins, lets critical failure
dominate, and gives each participant the sum of individual strain gains.
A group critical failure causes one discharge per participant. Cooperative
resistance caps each successful contribution using its own original dice and
bounds their sum by surviving scope. This explicit conversion also applies to
accumulated ritual contributions; no replacement attack roll is invented.

`RpgMagicAugmentation` and `RpgMagicManeuver` bridge declared assistance to
`RpgLiteBattle`: a miss spends the assistance, and matching-type magical/mundane
damage combines before armor. Injury from multiple blows is deferred until their
rolls are known; one critical failure makes all those blows miss. A failed augmentation leaves the mundane attack
available unless the maneuver explicitly requires enabling magic. An assistance
receipt is tied to one ordinary task. `rpgImmediateMagicDefense` uses the suitable
unmodified domain skill and a recorded subtle ruling for an explicitly
`defensive` effect (`intent.purpose = 'defense') instead of an ordinary
defense; it has a separate attack-bound receipt.

## Work, rituals and clocks

`rpgBeginMagicWork` and `rpgAdvanceMagicWork` support interruptible ordinary
casting. Elapsed work is spent; reserve is debited only at the final roll.
`rpgInterruptMagic` checks Will−3, except stun, unconsciousness or destroyed
setup automatically ends the work.

`rpgBeginMagicRitual`, `rpgRollMagicRitual` and `rpgEndMagicRitual` implement the
agreed 3 + mastery roll limit, authored timing categories, accumulated progress,
ordinary-failure penalties, critical termination and one final delivery. Each
later roll adds provisional strain. Capacity pressure is immediate. Discharge
removes temporary strain first, then the active ritual's provisional points.
Success clears surviving provisional points without refunding displaced reserve;
other endings convert them to ordinary strain. Endurance checks occur as each
additional hour begins, preserving time already worked on exhaustion.

Major workings can pause between completed rolls. The 48-hour limit, setup
integrity, resumption skill, cumulative pause penalty and sleep/endurance reset
are explicit. A ritual freezes its adjudicated external facts; a relevant
external change ends it so a fresh declaration can be judged. Its own reserve
and strain changes do not invalidate its ruling. `RpgMagicGroupRitual` uses one
progress pool and the lead's allowance. One additional active effect is recorded
from actual concentration state, with the adopted −1 ritual penalty.
`rpgCastDuringMagicRitual` allows a separate, feasible working while enforcing
the one-extra-active-effect limit and the normal world-turn casting limit.

`rpgLedger` records accounted activity, while `RpgMagicWorld` schedules actual
world time. The host calls `world.advance(uniqueIntervalId, elapsedSeconds)` once
for each real interval, including concurrent group work only once. Advance IDs
are idempotent and conflicting reuse is rejected. Extra actions never advance
this clock by themselves. Advance world time **before resolving the final roll
or applying its effects**, so an effect starts at completion rather than at the
beginning of its casting interval. The work/ritual APIs let the host interleave
that clock advancement with activity; revalidate when an expiry changes relevant
facts. `rpgLedger` does not advance the world implicitly. Time acceleration returns activity opportunities;
suspension delays only explicitly `subjective` effect timers. Forward travel
advances the scheduler and processes deadlines; it never restores saves or
predicts random draws. Long downtime is split into legal host ledger chunks.

Timed effects have persistent IDs, expiry, concentration and separate base values.
The strongest positive and negative equivalent layers combine; weaker layers
resume when stronger ones expire. Only expressly reversible owned effects can
be canceled generically. Memory reversal, passage closure and item disenchantment
have separate procedures. There is no universal dispel or invented upkeep cost.

## Resources, injury and consequences

Reserve storage, protected innate reserve and transferable excess are distinct.
`rpgMoveMagicReserve(actor, donor, recipient, ...)` settles a successful delivered transfer atomically,
with a stable source receipt; `rpgTransferMagicReserve` is the recipient-as-caster pull convenience. Portable portions require power 3 and predeclared
allocations; the whole portion is consumed, including unused excess. Source
collection has period receipts; meditation replenishes innate reserve separately.
`rpgBuyMagicSupply` records ten-point source shares (at most five units per
character) and two-point-per-unit starting portable supply. Purchases need an
authored opportunity, unspent points and stable receipts; owning a source does
not increase its output. The game supplies calendar period IDs and access milestones. Weekly recovery,
power-5 temporary-strain removal and lasting strain use separate accounting.

Injury passes through the host health pipeline with provenance. Backlash injury
cannot be magically healed; unstable transformation injury also blocks natural
healing while its layer remains active. Treatment opportunities are shared
across healers. Severe healing requires overt delivery and reserve at one point
per three HP, rounded up. Body alteration leakage is scheduled by world time.
Temporary attribute and armor layers preserve purchased base values. Selected
permanent mental benefits require an authored eligible property and point payment.

Use `RpgMagicConsequenceBatch` for the adopted backlash bands. It validates
required authored consequences, applies internal injury once, lasting strain,
and strength-10+ outward blasts. Bystander exposure records specify legal dive
steps, cover and torso protection. A successful Dodge+3 changes exposure rather
than canceling the blast. `rpgAcceptMagicComplications` validates the entire
voluntary batch against starting strain and spends it once. Narrative content
must be provided; no missing consequence is silently discarded.

## Items, minds and other worlds

`RpgMagicCraft` freezes full-rank participants, effect rating and construction
time. Craft/effect/power checks run in that order; any failure destroys the
prospective item. Interrupted work loses the current ability and advances its
tier. Final charging costs ten minutes per point and seals capacity at the amount
delivered; failed final activation remains retryable. Later recharge uses ordinary
transfer throughput. Activation validates contact, commands/gestures, user
eligibility, a fixed appearance ruling, charge and a stable opportunity. The user
receives casting strain. Item prices use an authored currency factor.

Mental links have explicit membership and disclosure categories. Memory overlays
retain underlying memories. Probing and failed possession remain locked until
the subject sleeps. Projection has its own health, body link, mental attributes,
hourly recovery and temporary visibility. The game supplies travel routes and
body compatibility; projection alone grants neither physical senses nor another
world's geography.

Spirit contact uses a bounded relationship score and an optional existing social
`disposition.permits` adapter. Contact grants no service or obedience. Suggested
barriers, sight thresholds, crossing contests, boundary layers, rescue,
materialization thresholds and fixed-power injury costs are provided. Places,
regions, destinations and protection content remain authored. Distorted perception
uses authored false elements with one recognition check each; it does not create
objective world facts. Internal-encounter duration has an explicit converted table.

## Example and checks

The original workshop supports parser, dialogue and structured input with shared
receipts. Build it in a new output directory:

```sh
"$ZEBC" build examples/magic/main.t --include-dir lib \
  --include-dir "$VHYL_ROOT/lib" --emit shared --opt O2 \
  --out-dir build/magic-workshop --runtime-cache build/runtime-cache
python3 examples/magic/host.py build/magic-workshop --vhyl "$VHYL_ROOT"
```

Use `preview inspect`, `rule inspect`, then `cast inspect`. The external Python
adapter round-trips the same versioned protocol a later model adapter would use.
`tests/magic.py` covers the original transaction/GM integration;
`tests/magic_engine.py` covers the engine workflows and all 45 rank derivations.
Run `python3 tools/test.py --vhyl "$VHYL_ROOT" --native` for the full suite.
