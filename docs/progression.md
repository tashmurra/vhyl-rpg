# Milestones and constrained progression

Include `<vhyl-rpg-progression.t>` after the core. It works without condition,
conflict, language, dialogue or reporting modules. PCs and NPCs use the same
point and development model; publication remains an explicit author decision.

Progression is driven by authored objectives and learning opportunities. It
does not reward repeated rolls, command counts, failed-treatment grinding or
unbounded encounter loops.

## Milestone awards

`RpgProfile` gains `earnedPoints`, `unspentPoints`, `developmentOpen` and
`developmentRevision`. Points are nonnegative integers. Earned points are a
lifetime total capped at one million; unspent points cannot exceed that total.
An authored starting bank must initialise both counters consistently.

An `RpgMilestone` has a stable unique ID, 1–10000 points and an observational
`available(profile)` gate returning a reason ID or nil. Predeclare one `RpgAward`
receipt for each allowed profile/milestone pair. Missing or duplicate receipts
are configuration errors.

```text
safePassage: RpgMilestone id = 'chapter.safe-passage' points = 6;
passageReceipt: RpgAward profile = protagonist milestone = safePassage;
```

Call `rpgAwardMilestone(profile, milestone)` from an authored committed objective
consequence. A fresh eligible award claims the receipt and increases both point
counters before `milestone.apply(profile)` runs. That hook may unlock learning
opportunities. A repeated award returns reused, adds nothing and does not invoke
the hook. Exceptions roll back the receipt, counters and consequences together.
Undoing the original objective also undoes its award, so redoing it reproduces
one consistent history rather than generating extra points.

## Authored development offers

An `RpgDevelopment` belongs to one profile and has a unique ID. Set `unlocked`
when the fiction supplies a mentor, relevant discovery, practice or meaningful
experience. By default it also requires `profile.developmentOpen`, which the
game sets at a suitable pause. Its independent `available(profile)` gate can
enforce further story requirements. Unlocking does not itself spend points.

| kind | Target | Price |
| --- | --- | --- |
| skill | An owned `RpgTraining` slot and target point investment | Target investment minus existing investment |
| attribute | One attribute identifier and target score | Score difference × per-level price |
| trait | An authored `RpgTrait` and positive `cost` | Explicit authored cost |
| remove-trait | A currently owned limitation trait and positive `cost` | Explicit authored buy-off cost |

Attribute prices are 10 for strength/health, 20 for coordination/intelligence,
and 5 for Will/Perception per point. Attribute targets are 1–100. Skill targets
are 1–10000 invested points, not desired effective skill scores. Trait prices
are 1–10000. The library does not infer trait prices or refund removed limitations.
Authors must price a buy-off consistently with the game's starting budget.

Reserve a new skill using an owned `RpgTraining` with zero points in the profile's
skills list. It remains untrained, using only an explicitly permitted default,
until purchased. Mutable training slots cannot be shared between profiles when
targeted by offers; validation rejects that configuration. No persistent runtime
skill entities are allocated during play.

```text
fieldMedicine: RpgTraining skill = firstAid points = 0;
lesson: RpgDevelopment id = 'learn.field-medicine' profile = protagonist
    training = fieldMedicine target = 2;
```

`rpgAssessDevelopment(offer)` is observational. It returns ready, reused or
blocked, the current price and a reason where applicable. Queries consume no
points, time, randomness, receipts or history. Check affordability after the
current price is computed, so competing offers cannot spend a stale preview.

`rpgDevelop(offer)` commits a currently ready offer. It marks it purchased,
deducts the current price, changes the owned value and increments the development
revision before its `apply(profile)` consequence. An already purchased or
already attained target returns reused without charging. A blocked, locked,
unaffordable or out-of-downtime offer changes nothing. An exception rolls back
the entire purchase and any game consequences.

Ordinary purchase gates return `rpg.development-locked`, `rpg.downtime-required`,
`rpg.insufficient-points` or an authored reason. A dependent attribute exceeding
the score ceiling returns `rpg.attribute-limit`. Invalid declarations throw a
configuration error at startup.

## Dependent attributes and existing attempts

Intelligence purchases raise Will and Perception by the same difference,
preserving independently purchased or authored offsets. Health purchases preserve
the missing-energy deficit when the default maximum energy rises. Strength
purchases increase default HP capacity while leaving stored injury intact.
Explicitly overridden `maxHP` or `maxEnergy` properties retain their authored
capacity rules; the library does not replace them. A higher capacity does not
resurrect a dead body or clear an unconscious flag automatically.

A purchase does not globally reset challenge attempts. An offer may declare a
`reopens` list of related `RpgChallenge` objects. Only those revisions advance,
once on a fresh purchase. A completed goal remains completed. This keeps unrelated
failed checks settled and prevents free rerolls from buying an irrelevant skill.
Previously recorded scores, modifiers, costs and faces remain historical snapshots;
improvements affect fresh calculations, not old reports.

Progression does not implement training-hour accounting, free-form respecs,
automatic advantages, attribute decreases for refunds or supernatural permission.
The game authors which opportunities exist and when their development window is
open. Close that window during a confrontation or other unsuitable activity.

## Publication and persistence

`rpgPublishProgress(value)` explicitly emits `rpg.progress`:

```text
version (1), actor, kind, ID, status, reason, points,
unspentPoints, earnedPoints, developmentRevision
```

Kind is award or purchase. Award points are gained; purchase points are spent or
required by a ready/blocked assessment. Reused results have zero points. A
purchase assessment and its committed result use the same shape. NPC banks and
locked story opportunities must only be published when the author intends them
to be visible.

Receipts, banks, unlocks, purchased flags, training, attributes, trait lists,
related challenge revisions and consequence state all participate in undo and
logical saves. Do not store temporary `RpgProgressResult` instances in persistent
properties. The [gatehouse example](../examples/resilience/main.t) demonstrates
objective awards, constrained purchases, new assessments and a safe downtime flow.
