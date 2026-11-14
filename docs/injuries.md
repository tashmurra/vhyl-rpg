# Authored injuries

Include `vhyl-rpg-injuries.t` **after the Lite umbrella**. It also works with
expanded profiles. Include `vhyl-rpg-injuries-magic.t` after both injuries and the
magic umbrella when Life repair is needed. Neither file belongs to an umbrella;
existing games without them retain Lite behavior.

## Authoring consequences

```text
local result = rpgInflictInjury(profile, 'leg', 'right', 6, 'lasting', 2);
local fracture = result.record;
```

This applies six HP of injury through the existing health pipeline **once**, then
records loss of right-leg function for two months. Do not also apply the same HP
through a combat callback. No location is rolled or inferred from damage.

Parts are `arm`, `hand`, `leg`, `foot`, and `internal`. Limb injuries require
`left` or `right`; internal injuries require `nil`. Severity is `temporary`,
`lasting`, `permanent`, or `mortal` (internal only). Lasting injuries require an
authored duration of 1–6 months; all other severities require zero months.
This API deliberately permits scripted injuries without damage thresholds or
limb damage caps. It is not the full hit-location damage procedure.

Records belong to `profile.injuries`; `result.record` is the durable handle.
Repeated injuries create independent records. Restrictions remain until **all**
applicable records have recovered. Read `active`, `severity`, and
`remainingSeconds` for presentation; no player prose or automatic disclosure is
provided. Calls belong in a vhyl action transaction. Existing saves are tied to
the compiled game; no old-save migration is supplied.

For a consequence whose duration should be rolled, create it as temporary and
call `rpgAssessInjury(record)` once, normally at combat end. HT success leaves it
temporary; failure makes it lasting for 1d months; critical failure makes it
permanent. Explicit lasting/permanent classifications cannot be reassessed.
Damage still uses Lite's existing major-wound threshold; this API does not add a
second automatic knockdown roll for small authored injuries.

## Functional effects

- An arm or hand injury disables that side for attacks, readiness, aiming and
  parrying. A shield cannot block with the affected side. Fighters default to
  `weaponHand = 'right'`, `shieldHand = 'left'`; authors may change them. Declare
  `request.hands = 1` for a one-handed attack when only one hand is available.
  Item transfer/drop narration and handed inventory placement remain host work.
- A leg or foot injury causes a fall and prevents standing, kneeling, ordinary
  walking, kicking, running, jumping, and journeys. Lying/crawling movement is
  capped at one yard per second. Crutches and braced standing are deferred.
- Active internal injuries prevent exertion activities and attacks, including
  running, jumping, lifting and journeys. They permit ordinary walking and
  defenses if the existing health rules allow them. This broad rest requirement
  is an **authored adaptation**, not a printed organ-specific penalty.
- Mortal internal injuries additionally use the existing mortal flag,
  incapacitation, half-hour survival checks and stabilization/recovery rules.
  A new injury does not reset an existing mortal survival clock.

These are broad humanoid categories. There is no automatic targeting, location
armor, bleeding, organ simulation, dismemberment, prosthesis, or new trait-cost
accounting. Shield handling deliberately uses a broad disabled-side rule rather
than the full reference's distinction between an injured hand and injured arm.
Host actions outside library combat/exploration must consult `injuryHandUsable`,
`injuryHands`, `injuryLegsUsable`, and `injuryExertionAllowed` themselves.

## Recovery and treatment

HP loss and loss of function are separate. Ordinary HP healing does not erase a
lasting or permanent injury. `rpgLiteHealthTime` advances the injury clock through
a dedicated `injuryTime` hook, including rest, combat and expanded running.
The host must advance it for other elapsed intervals, exactly once per patient.
One month is **30 days**, a host calendar policy. Temporary injuries clear on the
next health-time update at full HP (a zero-second update is sufficient). Lasting
injuries clear when their countdown expires. Permanent injuries do not expire.
Mortal injury records clear after the underlying mortal condition resolves.

```text
rpgTreatInjury(fracture, healer, physicianScore, modifier, techLevel, nil);
rpgTreatInjury(fracture, surgeon, surgeryScore, modifier, techLevel, true);
```

Physician care requires score 12+, can be used once per record before surgery,
and subtracts 1/2/3 months at TL5/6/7+, with a one-month minimum. It does not roll
or spend game time. Surgery can be attempted once per record, costs two hours,
and rolls the supplied skill plus modifier. Success converts remaining months
to weeks (remaining seconds × 7/30, rounded upward); critical failure makes the
injury permanent. A failed ordinary operation retains the current recovery time.
Permanent, temporary and healed injuries are ineligible. A surgical attempt on
an active mortal internal injury instead takes one hour: success clears the
patient's mortal condition and leaves a one-month lasting internal injury.
Failure leaves the mortal condition unchanged. It does not automatically wake
the patient. The procedure advances patient and healer health clocks before completion,
including mortal survival checks. Death or healer incapacitation interrupts it;
time already spent is retained. The host supplies surgery modifiers. One attempt is allowed per record, as for other surgery.

The once-per-record surgical limit and extending these recovery rules to broad
internal injuries are explicit adaptation policies. Equipment, medical access,
supplies, valid skill and TL modifiers are supplied by trusted host code. This
module does not purchase or consume medical inventory. Surgery charges the
activity ledger and advances patient/healer health time itself. Advance other
world clocks for that interval separately, without advancing these two health
clocks or charging the ledger again.

## Life healing

Author an `RpgInjuryLifeEffect`, set `target` and `injuryRecord`, and prepare it
with `rpgPrepareMagicOperation`. Use normal GM ruling, permission, casting,
delivery and opportunity settlement. This is a `heal` operation: Life 2 for self
or simple life, Life 3 for another complex organism. It repairs one active,
nonpermanent authored injury as well as performing ordinary HP healing.

Its `amount` must cover the original injury at two HP per unit, even if HP has
already recovered. For six original injury, set `amount = 3` or greater. This
full-scope requirement is a host adaptation; partial tissue-repair accumulation
is not implemented. HP healing retains shared treatment, provenance and severe
injury reserve restrictions. Functional repair can still occur after HP has
recovered, with a fresh legal casting opportunity. A repaired record cannot be
reused. Mortal repair only completes if the existing mortal condition resolves.
Permanent loss of function requires a separately authored restoration effect.
Ordinary generic `heal` restores HP; use this bridge to explicitly repair a
lasting functional injury. Neither inclusion nor the Life bridge restores
backlash or unstable transformation HP.

## Source and verification boundary

Recovery concepts derive from neutral reference `full-2008`, B421–B424; Life
permissions follow the project's adopted `anniversary-2015`, pp. 516–517.
Simplifications and host policies above are deliberate, not claims of full
reference coverage. No source-book material is distributed.

Broad-category native tests cover arms/hands, legs/feet, internal injury, timed
recovery, physician/surgical treatment, Life repair, persistence and transaction
rollback. Existing Lite, running and magic regressions verify default behavior.
