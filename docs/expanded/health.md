# Expanded health

**Status: partial.** Injury, treatment, recovery, fear consequences and fatigue. Neutral source: `full-2008`, B360-B361; B418-B429; B552-B553.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-health.t` after the expanded foundation. The current
implementation supplies the B419 high-capacity shock calculation, standard-location
knockdown assessment and a limited committed wound request using the shared ledger. Set `rules.scaledInjuryShock = true`
to select that difference; inclusion alone preserves the existing calculation.
`rpgExpandedInjuryShock(capacity, injury)` is a pure calculation for one wound:
capacity below 20 uses each injury point, while larger capacities use complete
increments of capacity/10 as the divisor. Drop fractional penalties and cap at 4.

The existing wound path adds the resulting penalty to the same `profile.shock`,
retains high-pain resistance and charges injury once. Combat turn cleanup uses
the same scaling hook for counter-injury, and a turn without new injury clears
the prior shock. Unsupported low-pain
modification rejects before injury is committed. The hook defaults to the existing
Lite calculation when the option is disabled. No new injury or fatigue pool is
introduced. `test_scaled_injury_shock` provides independent threshold expectations
and integrated repeated-wound/resistance cases.
`test_scaled_shock_turn_boundary` covers ordinary turn expiration, counter-injury
scaling and rejection before injury or randomness is spent. These cases have not
run while checks are paused.

Critical-hit doubled shock remains assessment-only. The existing battle result
retains aggregate counter-injury, not per-wound critical effects. Committed support
must preserve which wounds survive the actor's turn boundary, apply the critical
cap without letting a later ordinary wound reduce an existing penalty, and retain
high-pain immunity. Merely doubling the stored shock value would also double
unrelated earlier injury and would not satisfy this contract.

Broader detailed injury, anatomy exceptions, medical care, recovery
and fear remain pending. This option does not enable a complete expanded injury profile;
other wound behavior remains the explicitly selected existing foundation behavior.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

The [fear inventory](inventory/senses-influence-fear.json) separately records every
full-reference fear-table outcome and its modifiers. Full fear resolution caps
the initial effective score at thirteen and selects a consequence with a new
three-dice roll plus failure margin. It must not replace Lite's existing
stun/faint calculation unless the expanded procedure is explicitly selected.

Recovery checks use different attributes, modifiers and intervals by outcome.
Some outcomes also impose injury, fatigue, temporary penalties, new traits or
permanent attribute loss. An owned episode must retain those details across
time advancement, rollback, undo and save continuation. Lasting traits require a
specific event-related author decision and alter character value without granting
spendable points. None of this expanded fear behavior is implemented yet.

The [injury and recovery inventory](inventory/health.json) covers the first text
pass through B418–B427. It records location-specific crippling, optional bleeding
and accumulated wounds, survival and waking checks, treatment tables, advanced
drug design, fatigue causes and restricted recovery. All detailed entries remain
pending; shared Lite helpers are integration starting points, not proof of full
coverage.

Expanded health must retain one global injury and fatigue balance while also
recording wound locations, uncapped injury relevant to destruction, disabled body
parts and recovery deadlines. Optional location accumulation and bleeding must
remain disabled unless explicitly selected. Extra limbs and nonhuman anatomy
change both thresholds and consequences.

Temporary attribute penalties generally leave derived capacities unchanged and
exclude defensive reactions. Permanent changes require recalculation. These
paths cannot share an unconditional attribute setter without preserving their
different effects.

Medical procedures need owned sessions and patient-level eligibility. The source
specifies caregiver qualifications, technology-dependent capacity and frequency,
retry penalties, equipment requirements and treatment consequences. Healing must
also scale with unusually high health capacity without being scaled twice by
both the treatment and its caller.

Fatigue recovery remains specific to its cause: quiet rest, adequate meals, water
and uninterrupted sleep have different requirements. Successful recovery of one
cause must not erase another cause's restrictions. Drug effects likewise need
onset, resistance, dose history and expiry, with suppressed traits restored only
when that suppression ends.

The condition catalogue on B428–B429 is recorded in the
[environmental inventory](inventory/environmental-hazards.json), with health as
its owning module. Conditions such as paralysis, retching, daze and cardiac
arrest have different action permissions, resistance and recovery rules. They
cannot all be implemented by setting the existing stun flag. Each cause needs
owned duration and consequence records so resolving one condition does not erase
another.

The [anatomy inventory](inventory/anatomy-locations.json) adds the B552–B553
location tables and damage exceptions. Random targeting must use the actual body
form. A missing random location falls back to the torso; deliberately selecting a
nonexistent or inaccessible part must be rejected. Eyes and vital organs also
restrict eligible damage types and angles.

Location records need separate identities for individual limbs, wings, fins and
tails. Crippling can disable flight or impose specific movement and dexterity
penalties. A single limb-damage counter cannot represent these consequences.
Global injury, local crippling thresholds and excess injury limits must be
resolved together without charging damage twice. Critical temporary incapacity
must expire independently of lasting crippling from the same wound.

The [appendix review](inventory/appendix.json) records a boundary discrepancy:
B420 requires injury strictly greater than half capacity for an ordinary major
wound, while B564 includes equality. Completion requires a documented precedence
policy and an independent exact-half test; the inventory does not silently erase
either wording.

The [damage review](inventory/damage-readiness.json) also records differing
low-health formulas. B380 halves basic speed and movement, while B419 halves
movement and dodge. These are numerically different because dodge includes a
constant bonus and encumbrance. The expanded profile needs a documented
precedence choice and boundary cases; Lite behavior must remain unchanged.


Trait integration requirements at [B58–B59](inventory/traits-catalogue-f.json)
include apparent death when a survival bonus is decisive, scoped knockout/pain
resistance and restorative touch. The latter needs wound-specific crippling
history, one-attempt-per-healer/limb restrictions and dated successful treatments.
Ordinary injury restoration, disease cure and limb repair have different costs
and eligibility. Source ambiguity about repetition across healers and types is
recorded explicitly; no full healing implementation is claimed.


[Recovery and resistance traits](inventory/traits-catalogue-j.json) require
cause-aware healing, scheduled regeneration and missing-part restoration. Daily
draining losses are excluded from regeneration; radiation healing can remove
permanent accumulated dose. The source's faster-healing paragraph names lost HT
before describing restored HP. This was visually confirmed on the printed page;
its interpretation remains explicitly unresolved.
Resistance also depends on effect delivery and cannot become a blanket bonus
against every attack. None of these inventory entries is counted as implemented.


[Deathless variants](inventory/traits-catalogue-m.json) differ from unusual
durability: ordinary pain and crippling remain, while survival, bodily destruction
and reformation use tier-specific rules. Continuous damaging exposure can prevent
remains from healing even when further injury is capped. Embedded obstructions and
post-destruction healing triggers require separate state. These are pending rules,
not extensions already supplied by the Lite injury functions.


Pain sensitivity remains explicitly blocked with scaled shock: B142 doubles shock,
while B419 gives the ordinary cap. The supplied curated records do not resolve
that interaction. Its knockdown/torture modifier, involuntary vocalization check
and observer-dependent reaction consequences also remain pending. No partial
price-only trait is presented as the complete disadvantage.

## Location knockdown assessment

`rpgExpandedAssessKnockdown(capacity, injury, location, maleGroin)` assesses the
standard torso, face, skull, vitals and groin cases from `full-2008` B419-B420.
Pass injury already adjusted for protection and damage type. The result reports
`major`, `required`, the location `modifier` and ordinary `shock`; it consumes no
resources, rolls no dice and applies no injury. Pain traits are not included in
this location modifier. `maleGroin` is an authored anatomical fact and is accepted
only for the groin location.

The assessment gives precedence to B420's strictly-greater-than-half major-wound
threshold over the appendix equality. Thus a half-capacity torso wound is not
major, while a shock-producing face wound still requires a check. This pure helper rejects eye and limb locations. Owned arm/hand wounds use the separate crippling assessment described below.
This helper is restricted to standard anatomy; it cannot represent absent brains
or vitals, diffuse bodies or other injury-tolerance exceptions.

`test_knockdown_assessment` enumerates threshold, location and high-capacity
expectations. It remains unrun. Use the supported committed request below; do not call the
ordinary wound function and then add another knockdown check, which would
double-check major wounds. Modified targets below
three also need explicit resolution before commit integration, since B345 bars
ordinary success attempts below three and the knockdown consequences depend on a
failure margin. This assessment does not invent that margin.


## Committing a supported wound

Create one owned `RpgExpandedWound` with an opportunity `id`, `profile`, final
injury `amount`, supported `location` and the applicable `maleGroin` fact. The
profile must explicitly select `scaledInjuryShock`. `assess()` performs no injury,
roll or time charge; `apply()` uses the shared wound commit and stores the original
health result in both the request and `profile.expandedWounds`. Run `apply()` in
an action transaction. A repeated request returns `reused`; its `health` is the
original receipt, not newly applied damage. A different request with the same ID
rejects, as does retargeting a committed request.

The request supplies one location-specific knockdown trigger and modifier instead
of adding a second major-wound check. Existing pain resistance, stun/prone state,
unconsciousness and mortality processing remain in the shared commit. There is
no second injury ledger. Raw attack damage, armour and damage multipliers must be
resolved before creating this request.

The supported subset requires humanoid locations, permits the absent-brain and
absent-vitals knockdown exceptions below, excludes eye and lower-limb crippling and other
unsupported body/pain traits, and blocks a
required check with an unavailable score. If a knockdown check could require held equipment to be dropped, include the
expanded equipment module and supply `dropDestination`. Without that integration
or destination, the request blocks before injury. These are
explicit limitations, not full health coverage.

`test_expanded_wound_commit` covers exact-half/no-check, minor face injury,
location penalties, failure-by-five unconsciousness, one-time application and
preflight rejection without injury or random draws. It is authored but unrun.
`test_owned_wound_transactions` covers rollback after the roll, undo/replay,
repeat protection and rejected duplicate/retargeted requests.
`test_owned_wound_persistence` restores both unapplied requests and committed
receipts in separate processes. Wound history validates receipt ownership and
identity. These cases are authored but unrun; their presence is not runtime
validation.


## Equipment dropped by knockdown

With `vhyl-rpg-expanded-equipment.t` installed, `dropDestination` identifies the
authored floor or other receiving location. Preflight captures carried, ready,
non-worn items in a concrete `RpgExpandedKnockdownDrop` plan. A failed knockdown
check commits that plan even if the same check leaves the character unconscious.
A successful check moves nothing. Worn and packed items remain carried.

Dropped items retain ownership in the existing equipment list but receive the
storage location, become unusable as carried gear, and no longer contribute to
carried load. Relevant aim state is cleared. `wound.droppedEquipment` retains the
committed plan and its item identities; it is not a second inventory. Repeating a
wound does not drop the objects again. Picking them up uses the existing authored
storage-transfer procedure and its accessibility checks.

`test_knockdown_equipment_drop` covers missing-destination rejection, item/load
changes, aim cleanup, rollback, undo and repeat protection. It remains unrun.


`test_knockdown_equipment_retained` covers a successful check retaining the held
item and rejecting a changed destination on the committed request.
`test_knockdown_drop_persistence` saves and restores both successful and failed
checks, preserves the drop receipt's item identities, and checks that retrieving
a dropped item does not let replay of the old wound drop it again. Its pickup
fixture assumes an authored later recovery; it is not a medical recovery test.
These cases remain unrun under the build-check pause.


## Absent-organ knockdown exceptions

`rpgExpandedAssessAnatomyKnockdown` adds explicit `noBrain` and `noVitals` facts
to the standard location assessment. Under B420, absent brain removes the minor
face/skull trigger and the major-wound location penalty; absent vitals does the
same for vitals/groin. A major wound still requires an unpenalized check. The
unrelated location family is unchanged.

Committed wounds derive these flags from active `no-brain` and `no-vitals` trait
IDs and retain the assessment in `wound.knockdownAssessment`. This integrates the
knockdown effects only; it neither supplies trait prices nor changes final injury,
protects other locations or implements every injury-tolerance effect. Authors
still supply validated trait definitions and final injury. Homogeneous/diffuse
bodies, eyes and lower limbs remain explicitly unsupported by this request.

`test_knockdown_anatomy_exceptions` covers minor/major cases, unchanged unrelated
locations, retained assessment flags and random draw counts. It is authored but
unrun. The broader anatomy/trait inventory remains partial.


## Single-injury crippling assessment

`rpgExpandedAssessCrippling(capacity, injury, kind, count, severing)` returns a
`RpgExpandedCripplingAssessment` without changing a character or drawing random
numbers. `injury` is final injury before the location's health-loss cap; `kind`
is `limb`, `extremity` or `eye`. `count` is the anatomical count of that kind,
including already disabled parts. It must not shrink as parts become unusable.

Under full-2008 B421, the returned `minimumInjury` is the smallest integer above
the applicable threshold. `healthLoss` caps limb and extremity loss at that
minimum; eye injury remains uncapped. `crippled` and `destroyed` use the original
injury, with destruction starting at twice the minimum. `severed` additionally
requires cutting or explosive trauma, supplied through `severing`, and applies
only to limbs and extremities. For example, at capacity 10 an ordinary limb hit
for 12 returns minimum 6, health loss 6, and destruction; an eye hit for 4 returns
minimum 2, health loss 4, and destruction.

This helper assesses one ordinary injury. It does not accumulate location injury,
apply critical-result overrides, determine disability duration, or disable a
body part. The owned wound path below integrates the arm/hand subset; other
locations remain unavailable. Applying only its capped
health loss through a torso wound would omit those consequences and is not a
supported integration.

`test_crippling_thresholds` enumerates exact boundaries, odd capacity, additional
limbs and extremities, uncapped eyes, and severing distinctions. It is authored
but unrun while build checks are paused. The inventory entries remain partial.


## Owned arm and hand state

`RpgExpandedBodyPart` describes an owned arm or hand in `profile.bodyParts`.
Set a unique `id`, `profile`, and `kind` (`arm` or `hand`). A hand's `parent`
references its arm in the same profile. An arm has no parent. Only one hand per
arm is currently supported. Other anatomy rejects explicitly. `disabled` records
loss of function; `severed` requires `disabled`. These fields describe functional
state and do not store or spend health points.

`validateBodyParts()` checks ownership, identities, supported kinds and parent
relationships. `functional()` returns false for a disabled part or a hand on a
disabled arm. Authors can supply existing disabilities with these fields. The owned upper-limb wound path below sets disability and its wound reference.
The duration procedure below can clear temporary disability at full health;
permanent-disability point accounting is not yet supplied.

Bind a weapon's `bodySupports` to the hands holding it; bind an attached shield
to its arm. The shared combat engine now dispatches weapon attacks, weapon
parries, shield blocks and passive shield protection separately:

- `attackUsableBy(profile)` requires all bound parts and, for an arm-mounted
  item, its hand to function. Missing hand anatomy rejects rather than assuming
  an unaffected hand.
- `parryUsableBy(profile)` uses those same functional requirements.
- `blockUsableBy(profile)` requires functioning arm supports. An attached hand's
  disability alone does not prevent a shield block.
- `passiveDefenseBonus(profile)` removes a severed arm's protection and reduces
  an attached disabled arm's bonus by one, to a minimum of zero.

All four methods retain ordinary equipment availability, including storage when
the equipment module is installed. Empty bindings retain existing behavior.
The Lite implementations delegate to `usableBy(profile)` and preserve the
original bonus. These hooks do not roll dice. A disabled bound weapon rejects
in strike preflight before an attack can spend resources or randomness.

The bindings are explicit author facts. They do not infer which hand holds an
unbound item, drop items, change unarmed defenses, prevent reloads or readying,
or supply nonhuman limb effects. Do not use this partial interface to claim full
crippling support. Only the explicit arm/hand wound path below is available.
`test_body_supports` covers functional distinctions, early attack rejection,
ownership errors and unsupported anatomy. It is authored but unrun; transaction,
undo and save continuation of these new fields remain to be covered.


## Committing an upper-limb wound

Set `RpgExpandedWound.bodyPart` to the owned arm or hand and set `location` to
its kind. `amount` remains final injury before the location cap. Set `severing`
for cutting or explosive trauma. The assessment returns `healthLoss` and a
`crippling` assessment separately from the original amount. The shared injury
commit receives the capped loss; every crippling injury still requests one
major-wound check, including hand wounds below half health capacity.

On commitment, the part becomes disabled and retains `disablingWound`. A severed
part is also marked severed; raw destruction facts remain in the wound's
`cripplingAssessment`. Repeat application returns the historical result without
spending health or randomness again. Changing the bound part or damage category
on a committed request rejects.

All carried held items and shields need explicit body supports before a
crippling wound can be assessed. Single-grip affected items drop to
`dropDestination`. A worn shield remains on a disabled arm unless the arm is
severed; severing drops it and clears its worn state. The equipment module's
`prepareForcedDrop` supplies storage and aim cleanup. Knockdown and local drops
share item identities so an item is not dropped twice. Missing integration or
destination blocks before injury or dice are spent.

Unsupported worn bindings, further injury to an already
disabled part, critical-result crippling overrides, duration, recovery, unarmed
combat and full limb-based action restrictions remain incomplete. Already-disabled-part wounds explicitly block. This is a partial upper-limb
integration, not complete crippling coverage. Authors must not assume the new
state covers every action or supplies an automatic recovery schedule.

`test_limb_wound_transactions` covers capped loss, below-half major wounds,
retained/severed shields, overlapping knockdown drops, preview purity, rollback,
undo and repeat protection. `test_limb_wound_persistence` covers the committed
part/wound relationship and repeat protection after cross-process restoration.
Both are authored but unrun while checks remain paused.


## Unarmed parries after upper-limb injury

Full-2008 B147 distinguishes a missing or disabled hand from an unusable arm:
a functioning handless arm can still make an unarmed parry. The combat engine
queries `fighter.unarmedParryCapacity()` and
`fighter.unarmedParryRequirement(otherHand)` before assessing that defense.
With owned anatomy, capacity counts functioning arms, excludes arms occupied by
held items, and remains capped by the author's `freeHands` value for additional
restraints. A disabled hand alone does not reduce this count. A disabled or
severed arm does. Body supports must describe held equipment; an unbound ready
item rejects with `unarmed-grip-map-required` rather than guessing its grip.

A second unarmed parry needs two eligible arms, including when the primary weapon
is the built-in punch or kick representation. Merely retaining such an object
must not make a single arm count twice. Profiles without owned anatomy retain
the existing authored `freeHands` behavior and requirement calculation.

With owned anatomy, punch and hand-mounted striking equipment require explicit
hand supports for attacks. Missing bindings reject with
`unarmed-hand-support-required`; disabling the bound hand or its arm makes the
attack unavailable. This attack restriction does not remove a handless arm's
unarmed parry. Natural attack representations should remain fighter attack
objects rather than carried inventory items.

`test_unarmed_limb_capacity` enumerates healthy, disabled-hand, disabled-arm,
occupied-arm and authored-capacity cases against actual defense assessment. It
also covers the built-in punch representation, invalid grip information, attack
eligibility, no random draws and profiles without anatomy. These fixtures are
unrun. Full grappling, limb-specific maneuver choices and the B147 modifiers to
other tasks remain outstanding; this closes only the unarmed-parry capacity gap.


## Retaining an item held in several hands

When a disabled hand or arm releases an item still held by another functioning
hand, full-2008 B421 provides a DX check to retain it. Preflight now collects
those items and verifies the check is available before committing injury or
randomness. All grips in this case must explicitly name hands. The destination
for a possible drop is still required even if the later check succeeds.

`RpgExpandedLimbDropPlan` records conditional items, `checks`, `retainedItems`,
and actual dropped `items`. The wound commits its knockdown consequences first.
An item already dropped by knockdown needs no retention roll. Incapacitation also
prevents retention. Otherwise, each eligible item gets one immediate DX check.
A success removes the injured support from the item's grips and keeps the item
carried; a failure sends it through the same forced-drop storage operation.
Repeating the wound reuses this record without rerolling.

`RpgExpandedGripContext` treats immediate retention as a defensive reaction under
the temporary-attribute exception in B419/B421. It does not apply the wound's
shock or other temporary attribute reductions. This is the implementation's
application of that general exception to the specified immediate retention roll;
the source does not list retention by name among its examples.

`attackHandCount(profile, requested)` defaults to the existing requested count.
For body-bound equipment it limits that count to the distinct functioning arms
supporting the item. Combat uses the effective count for hand requirements,
two-handed bracing and becoming unready. Retaining an item with one hand therefore
does not make a mandatory two-hand attack available.

`test_limb_grip_retention` and `test_limb_grip_persistence` cover successful and
failed retention, shock exclusion, knockdown superseding the check, retained
weapons with a severed-arm shield drop, invalid low scores, rollback, undo,
remaining-grip attack eligibility and repeat protection after save/restore.
They are authored but unrun. Multiple-grip retention no longer blocks solely
because an unaffected hand remains; duration, repeated-location injury and the
other listed incomplete procedures still remain outstanding.


## Classifying crippling duration

`RpgExpandedCripplingDuration` is owned by an existing committed crippling wound
through `wound.durationRecord`. Set `wound` and the authored `combatEnded` fact,
then call `assess()` or `apply()` inside an action transaction. Assessment checks
ownership and rejects duplicate duration records. It also checks active battle
objects: an authored end-of-combat assertion cannot bypass a still-active battle
containing this patient. For an injury outside combat, the author sets
`combatEnded` to indicate no combat remains to be concluded.

Under full-2008 B422-B423, success on the health check gives `temporary`, ordinary
failure gives `lasting`, and critical failure gives `permanent`. Destruction is
permanent without this check or a month roll; it need not wait for combat to end.
The active `rapid-healing` or `very-rapid-healing` trait supplies the B79 bonus of
five, once. This integrates that effect without supplying the trait catalogue or
its other recovery effects.

The stored `result` contains the classification, check and, for lasting injury,
`monthRoll` and `months`. `rpgExpandedCripplingMonths(roll, medicalTL)` applies the
B422 reductions for physician care, with a one-month minimum. A nil level means
no qualifying treatment. To use this adjustment in the owned request, provide
`physician`, `medicalTL` and nonempty `careEvidence` identifying completed care.
These are authored world facts: the interface records the provider and completed
care, but does not perform treatment, validate a physician's full qualifications,
or charge its resources. Missing or inconsistent care fields reject before the
duration roll. The broader medical subsystem remains incomplete.

Repeated application returns `reused`; the original outcome remains available
as `record.result`. The wound, combat-end fact and care fields are bound at
commit and cannot be changed to reroll or obtain a different discount. Requests
with unavailable health scores reject before consuming randomness.

The shared `afterHealing()` hook has a no-op Lite default. Expanded profiles use
it to clear only a temporary disability from its own still-current wound when
injury reaches zero. Partial healing does not clear it. Full healing does not
clear lasting or permanent disability. The stored result marks `recovered`, and
the historical wound remains available. Classifying a temporary injury when the
patient is already fully healed also clears that disability immediately.

Lasting recovery is recorded in calendar months, not converted to a fixed number
of ledger seconds. The calendar milestone and later-care interfaces below handle lasting expiry and its physician adjustment; surgery and permanent repair
and the character-value consequences of permanent disability remain pending.
This procedure grants no advancement points. It is not complete injury recovery.

`test_crippling_duration`, `test_crippling_duration_persistence` and
`test_crippling_months` cover classifications, destroyed-part roll suppression,
trait bonuses, care reductions, full-health restrictions, active-combat gates,
duplicate/retargeted requests, rollback, undo and cross-process continuation.
They are authored but unrun while build checks remain paused.


## Lasting recovery on the campaign calendar

`RpgExpandedRecoveryMonth` commits one observed monthly anniversary of a lasting
injury. Set `duration` to the wound's committed duration record, `ordinal` to the
anniversary number starting at one, and supply `calendarId`, `boundaryId`,
`evidence` and `reached`. The author or host calendar determines actual dates:
`boundaryId` must identify the corresponding monthly anniversary of the injury,
not simply the next month-end or another unrelated boundary. `evidence` records
that authored calendar fact. This is a concrete integration contract, not a date
parser or a second clock.

`assess()` blocks until the boundary is reached and requires consecutive
ordinals. `apply()` appends the owned milestone to `duration.recoveryMonths`.
Calendar identity must stay consistent, boundary IDs cannot be reused, and a
committed request binds its ordinal and evidence. Reapplying that same request
returns `reused`; changing it or supplying a duplicate boundary rejects. Profile
validation checks the retained history and completion state.

At the required number of months, the operation clears the current wound's
functional disability and marks its duration result recovered. It does not add
health points, consume randomness, grant advancement points, or charge elapsed
time again. Unlike temporary disability, lasting disability does not require
full global health at this boundary. Dead patients cannot recover through this
operation. Temporary and permanent classifications are unavailable here.

For example, a recorded three-month recovery uses three distinct authored
anniversaries. Months one and two retain the disability; month three clears it.
If the character later suffers a new injury to the same part, replaying month
three of the old injury cannot clear the new disability. Ownership is checked
against the specific wound before recovery, and completed requests are historical
receipts thereafter.

An author may commit several separately identified milestones when the story
advances across several months. The host must establish that each anniversary
was reached. The library deliberately does not equate a month with thirty days
or use `rpgLedger.seconds` as a world calendar. Surgery that changes months to
weeks, later physician care and permanent repair still need their own procedures.

`test_lasting_recovery` and `test_lasting_recovery_persistence` cover early/skipped
boundaries, calendar changes, duplicate and retargeted requests, rollback, undo,
partial and completed save continuation, unchanged injury/time/randomness and
replay after a newer wound. These fixtures are authored but unrun.


## Optional last wounds

Set `rules.lastWounds = true` to select the full-2008 B420 last-wounds option.
It is off by default and applies only to the currently supported owned arm/hand
wounds. When current health is strictly below one-third of capacity, the request
ignores a limb wound unless it is critical, cripples the part, or inflicts at
least one-third capacity in a single injury. Comparisons use integer products
rather than rounded third-health thresholds. At exactly one-third current health
the option does not apply.

Set `wound.criticalHit` from the resolved attack outcome. That fact is bound into
the receipt, so it cannot later be changed to reinterpret an applied wound. The
assessment and committed request expose `ignored`; `healthLoss` is zero for an
ignored wound. The operation retains an owned history record for replay, but
leaves health, shock, wound serial and randomness unchanged. It does not suppress
torso wounds or disable crippling consequences for a qualifying hand injury.

`test_last_wounds_option` enumerates the health and injury boundaries, critical
and crippling exceptions, torso exclusion, disabled-option behavior and preview
purity. `test_last_wound_transactions` and `test_last_wound_persistence` cover
undo, retarget rejection, retained ignored outcomes and cross-process replay.
All are authored but unrun.

This option is separate from B420's accumulated-wounds option. The latter needs
an active location-injury ledger and healing allocation, which are not yet
implemented. The source places the rule about ignoring further health loss from
a capped location under that optional procedure; this implementation does not
silently enable it or assume it governs every repeated limb wound. Requests to
already-disabled parts remain explicitly unavailable pending that integration.


## Physician care after classification

`RpgExpandedCripplingCare` applies completed physician care to an existing lasting
disability. Supply a unique `id`, its owned `duration`, the `physician`, the
`medicalTL` used for care and nonempty `evidence` identifying that completed care.
As with care recorded during classification, these are authored world facts.
This operation records the calendar effect; it does not conduct treatment,
certify a provider's qualifications or charge treatment time and supplies.

Assessment computes the B422 reduction from `duration.result.monthRoll`, never
from a previously discounted duration. A treatment that offers no shorter
recovery blocks without appending another effect. Better care may shorten the
period once; repeating the same request returns its saved outcome. Duplicate IDs
and retargeted committed care reject. Temporary, permanent, already recovered or
dead-patient cases do not receive this lasting-recovery adjustment.

`duration.result.months` retains the classification-time value.
`duration.requiredMonths()` gives the effective total calendar duration after
later care. `duration.laterCare` retains the ordered care records; each result
reports `monthsBefore`, `monthsAfter` and whether that care completed recovery.
The history validates against the original die, so neither multiple providers
nor repeated applications stack discounts. The calendar-milestone operation uses
the effective requirement. If the completed milestone count already meets the
shortened requirement, the care operation clears only this wound's disability
immediately, without restoring health points or drawing more random numbers.

For example, an untreated three-month result becomes two months after qualifying
level-five care. Level-seven care reduces the original three-month result to the
one-month minimum. If one monthly anniversary has already passed, that improved
care completes the local recovery. Applying level-five care twice would still
leave a two-month requirement.

`test_later_crippling_care`, `test_later_care_calendar` and
`test_later_care_persistence` cover preview purity, non-stacking reductions,
initial-versus-later care, immediate and future calendar expiry, evidence and
identity rejection, rollback, undo and cross-process replay. These fixtures are
unrun. The full treatment, surgery and permanent-repair procedures remain pending.


## Expanded natural recovery

Set `rules.expandedNaturalRecovery = true` to use the expanded natural-recovery
subset through `rpgLiteRest`. The option is off by default. The existing
`healingClock`, global time-spending ledger and healing operation remain the only
clock and balances involved; there is no parallel recovery counter.

Full-2008 B424 gives a daily health check after eligible rest and food. The
expanded hooks add the B79 rapid-healing bonus of five, once, and double base
healing for the higher level. `rapid-healing` levels one/two or the separate
`very-rapid-healing` ID supply these effects; authors still need valid trait
purchases and prerequisites. B155 slow healing doubles the check interval for
each of its three supported levels: two, four or eight days. These effect hooks
do not supply the trait catalogue or all of those traits' interactions.

`rpgExpandedHealingAmount(capacity, amount)` applies B424's high-capacity healing
multiple. Natural recovery uses it after selecting the one- or two-point base
amount. The committed healing is capped to injury eligible for natural recovery,
so a larger result cannot consume protected disease or temperature injury.
Fully healed patients, and patients with only that protected injury, consume no
natural-recovery roll under this option. Other recovery sources do not yet
receive the new multiple automatically.

`naturalRecoveryConditions` is the author's numeric modifier for the good or bad
conditions allowed by B424. It does not certify medical supervision or replace
its separate qualification rules. The rest call's existing food and eligibility
arguments still describe the authored interval. Physician supervision and scheduled
healing checks are described below. Rest-period interruption and automatic care
scheduling remain incomplete; hosts must not count ineligible activity as recovery rest.

The shared hooks are `naturalRecoveryInterval`, `naturalRecoveryModifier`,
`naturalRecoveryAmount`, `naturalRecoveryNeeded` and `validateNaturalRecovery`.
Their Lite defaults retain the former interval, check, amount and random draw
behavior. Expanded preflight rejects inconsistent protected-injury balances and
unavailable required checks before time or randomness is spent. Active unhealing
with otherwise eligible injury requires an unimplemented exception context and
rejects explicitly. Natural healing alongside a mortal-wound regimen also
rejects pending chronological medical integration.

`test_expanded_natural_recovery` covers source values, interval boundaries,
scaling, conditions, protected injury, option-off behavior and preflight errors.
`test_natural_recovery_transactions` and `test_natural_recovery_persistence`
exercise the last second of a slow-healing interval, rollback, undo/replay and
cross-process continuation. These fixtures are authored but unrun.


## Physician supervision and capacity

`rpgExpandedMedicalSchedule(techLevel)` returns B425's patient limit and base
interval for additional physician healing checks. Level zero has no physician
service. Levels one through three share the weekly row; later rows progress to
five checks per day and 200 patients at level twelve or above. The result is a
table assessment, not an automatic treatment scheduler. The owned check interface below applies patient-specific slow healing and
executes an eligible additional check.

`RpgExpandedMedicalPractice` owns one physician's active patient roster. Supply
an `id`, `physician` and its technology-specific `physician` skill definition.
`assess()` requires a skill rating of at least twelve for this competent-care
interface. At technology six or higher, set `advancedEquipment` when the familiar
gadgetry is available. Without it, clean surroundings permit the B425 level-six
capacity and frequency fallback; otherwise assessment blocks. The actual skill
rating is retained. The `available` fact means the provider is supplying the care
for the authored recovery interval; a dead or unconscious provider is unavailable.

Use `admit(patient)` and `release(patient)` in action transactions. The provider's
`medicalPractice` and patient's `medicalSupervision` point back to the same roster.
A physician cannot acquire a second roster to evade capacity, and a patient
cannot acquire a second supervising practice to stack benefits. Admission checks
capacity before changing either reference. Re-admitting the same patient is
idempotent. Release permits leaving an unavailable practice and frees the
physician's assignment when the roster becomes empty.

With expanded natural recovery enabled, an assigned patient's recovery modifier
includes the B424 bonus of one. Preflight verifies ownership, qualification,
capacity and provider availability before spending recovery time or randomness.
The bonus combines with a healing trait's separate bonus; multiple providers do
not multiply it. Rest that does not attempt natural recovery does not require
this bonus assessment. Authors must keep availability and roster membership
consistent with the whole recovery interval: this interface does not yet track
the physician's work schedule or certify continuous care from world events.

`test_medical_schedule` enumerates every printed row, equipment fallback,
qualification and capacity rejection. `test_medical_supervision_transactions`
and `test_medical_supervision_persistence` cover assignment, release, duplicate
providers, bonus application, unavailability, rollback, undo and cross-process
ownership. These fixtures are authored but unrun. The separately scheduled physician check is described below; full medical
procedures remain incomplete.


## Additional physician healing checks

`RpgExpandedPhysicianCheck` resolves the B424-B425 check in addition to natural
recovery. Supply a unique `id`, the admitted `patient`, its `practice`, the
`continuousCare` fact and nonempty `evidence` describing the completed eligible
care interval. `modifier` represents authored circumstances for this roll. A
physician's base skill must still qualify the supervising practice. The request
requires the expanded wound path to be available for a possible critical failure;
set the patient's `scaledInjuryShock` rule and, where relevant, a
`dropDestination` for that possible injury's knockdown consequences.

Admission records `medicalCareSince` and the applicable `medicalCareInterval` on
the patient. The interval comes from the medical-help table, doubled for each
slow-healing level under B155. The parent activity advances `rpgLedger.seconds`
once; assessment observes this ledger and does not spend time again. Hosts must
use this only for accounted intervals of qualifying care, not infer eligibility
from unrelated activity merely because the ledger advanced. The completed-care
assertion and evidence are required in addition to the timestamp check.

The interval must have elapsed since both the current admission/care baseline
and the last physician check. Only one provider can be assigned; changing doctors
requires a fresh admission and cannot grant an immediate extra check. Changes
to the effective interval during an admission explicitly block until the host
releases and re-admits the patient for a new care interval. A late check resolves
one current opportunity, not a backlog of historical rolls. Missed opportunities
are not automatically performed retroactively.

`rpgExpandedPhysicianOutcome(capacity, score, roll)` exposes the source outcome
assessment: ordinary success restores one base health point, critical success
two, ordinary failure none, and critical failure causes one injury. High-capacity
scaling applies to healing only. Execution uses `rpgLiteHeal` or a prepared owned
torso wound, sharing the existing health balance, recovery hooks and consequences.
Preflight checks the harmful outcome before rolling. Protected disease or
exposure injury, unhealing and mortal-wound regimens remain explicitly unavailable
pending their complete treatment rules.

The patient's `medicalChecks` retain the request, original check, actual healing
or injury, provider and completion time. `medicalLastCheckAt` persists across
provider changes. Repeating a committed request returns its saved result; a new
request at the same time is not due. IDs cannot be reused and committed request
facts cannot be retargeted. The same completed care interval is never charged or
rolled twice.

`test_physician_outcomes`, `test_physician_check_transactions` and
`test_physician_check_persistence` cover source outcomes, capacity scaling,
critical-failure injury, the last second of eligibility, pure preview, rollback,
undo, duplicate requests, provider changes and saved continuation. They are
authored but unrun. Continuous-care activity scheduling and the wider medical
procedures remain incomplete.


## First-aid calculations

`rpgExpandedFirstAidTable(techLevel)` returns a `RpgExpandedFirstAidTable`
with `tableSeconds`, `bandageSeconds` and `healingAdjustment`, following
`full-2008`, B424. Bandaging takes 60 seconds; the table interval is the
additional treatment after bandaging. Technology nine and higher share the
highest row. This query does not advance time.

`rpgExpandedFirstAidOutcome(capacity, techLevel, score, roll, healingRoll,
bandageCredit)` assesses supplied dice without drawing randomness or changing
health. Supply the patient's maximum health capacity, effective first-aid score,
three-die check, and actual health previously restored by this treatment's
bandaging. `healingRoll` is a one-die result for ordinary success; critical
success uses the maximum automatically, and failed checks need no healing die.

The result exposes:

- `bandageAllowance`: one health multiplied by the B424 capacity factor.
- `bandageCredit`: the supplied actual prior recovery, limited to that allowance.
- `healingAllowance`: the successful table result, minimum one, scaled once.
- `additionalHealing`: the successful allowance minus the bandage allowance.
- `injury`: two plus actual prior bandage credit on critical failure; zero otherwise.
- `check`: the assessed success and critical classification.

The allowance and actual recovery differ when bandaging reaches full health.
For capacity 30, technology eight and a healing die of four, the total allowance
is 12 and additional allowance is nine, even if only one of the three potential
bandage points could be restored. Unused bandage allowance is not carried forward
to heal a later wound. An owned session must enforce this eligibility before
committing any recovery.

Reversing actual prior bandage credit on critical failure is the accounting
interpretation used here and in the existing treatment path: the whole treatment
then causes a net loss of two health. The extra injury itself is not multiplied
by the healing factor. This helper does not apply that injury or resolve its
consequences.

These are numerical interfaces, not a complete expanded treatment session.
The owned bandaging and post-bandaging interfaces below provide committed time,
recovery and duplicate-treatment protection for their supported cases. Interrupted
care, bleeding and complete equipment/skill contexts remain incomplete.
Do not call a shared healing function directly with these allowances as a
substitute for those eligibility checks. Existing Lite treatment remains unchanged.
`test_expanded_first_aid_values` contains independent table-row and outcome
expectations, including capped bandage credit and critical outcomes. It is
unrun while checks are paused.


## Owned bandaging

`RpgExpandedBandage` supplies the one-minute bandaging step for the latest
supported committed `RpgExpandedWound`. Set `wound`, `healer`, `evidence` and
`eligibleInjury`. The author must identify why pressure or a tourniquet is
appropriate and how much of the current injury remains eligible. The amount
cannot exceed either current injury or that wound's committed health loss.
This explicit amount does not create another injury ledger.

`assess()` returns the prospective scaled healing and 60-second cost without
changing health, time or randomness. `apply()` spends that time once and heals
through the shared health function. The wound owns the receipt; a repeated
request returns `reused` with no additional time or recovery. A second request
for the wound is blocked. The existing `bandagedSerial` marker also prevents
repeating a bandage already performed through the Lite treatment path.

The request rejects earlier wound serials, mortal patients, protected disease or
temperature injury, and unsupported unhealing exceptions. These restrictions
remain coverage gaps, not alternative rules. Bandaging can invoke the existing
awakening check when healing an unconscious patient. Call the operation within
an engine transaction, as with other committed actions.

This atomic one-minute operation does not yet support interrupted treatment,
or bleeding checks. The subsequent treatment stage uses a separate owned request
described below. Bandaging relies on authored
eligibility evidence; it does not infer injury allocation from a generic callback.
`test_expanded_bandage` covers preview purity, scaled recovery, repeated requests
and shared time accounting. `test_bandage_rejections` asserts no spending for missing evidence, invalid
eligible injury, protected injury, incapacity, earlier wounds and an existing
bandage marker. `test_bandage_transactions` covers preview, exception rollback,
undo, replay, duplicate requests and changed evidence after completion.
`test_bandage_persistence` saves before and after treatment, restores in a separate
process and continues or reuses the same owned request. These are authored
expectations; all new fixtures remain unrun while checks are paused.


## Post-bandaging treatment

`RpgExpandedFirstAid` applies the B424 treatment stage after an owned bandage.
Supply `bandage`, `healer`, a technology-specific `first-aid` `skill`, and the
combined applicable `modifier`. Set `comfortable = true` and `careEvidence` to
establish that the patient stays warm, comfortable, calm and still for this
uninterrupted interval. The current API executes the whole interval atomically;
it does not schedule intervening world events or handle interruptions.

Assessment checks the completed bandage, current wound serial, patient and healer
conditions, usable skill score, care evidence and the possible critical-failure
wound before spending time or randomness. Set `dropDestination` when that failure
could require an equipment drop. A blocked failure path blocks the request before
its skill roll, even if the actual roll might succeed.

Execution charges only the additional table interval: the bandage already charged
its own minute. Ordinary success draws one healing die; critical success uses the
maximum without that die. Additional recovery is capped by the original authored
eligible injury minus actual bandage healing, and by current injury through the
shared healing function. Critical failure uses an owned wound for two points plus
actual prior bandage recovery. It can trigger the usual injury consequences.
The patient's shared `aidUsed` marker and the bandage's `treatment` receipt prevent
another treatment from spending resources again. Reusing the completed request
returns its historical outcome with zero new seconds.

This stage remains partial: earlier-wound allocation, interrupted care, bleeding,
and complete equipment/physiology/diagnosis contexts remain incomplete. Authors supply the applicable contextual modifier;
that input alone does not constitute implementation of every context rule.
`test_first_aid_treatment` provides successful and critical-failure expectations,
preview purity and repeated-request checks. `test_aid_transactions` covers both
outcomes, rollback after mutation, undo, deterministic replay, duplicate requests
and altered receipt evidence. `test_aid_persistence` restores the exact compiled
game in another process before treatment and after success or critical failure;
it checks continuation and historical receipt reuse. These fixtures are authored
but unrun while checks are paused.


## Surgical assessment

`RpgExpandedSurgeryContext.assess()` calculates surgical modifiers from
`full-2008`, B223 and B424 without performing an operation. Its explicit inputs
are `techLevel`, `anesthetic`, `sterile`, `site` (`head`, `chest` or `other`),
`diagnosed`, `physicianTrained` and `fieldExpedient`. These describe established
world facts, not inferred skill ownership. A future committed operation must
verify them against its surgeon, patient, diagnosis and available equipment.

The result separates `equipmentModifier`, `anestheticModifier`,
`cleanlinessModifier`, `siteModifier`, `diagnosisModifier` and `trainingModifier`.
Its total `modifier` also includes authored `equipmentQualityModifier`,
`physiologyModifier` and `otherMissingEquipmentModifier`. The last input must
exclude missing anesthetic: the dedicated penalty replaces that item's ordinary
missing-equipment penalty. Quality and physiology values remain authored inputs;
the context does not implement their full rule families.

`earlyAntisepsis` selects the technology-five poor-antisepsis campaign condition.
`infectionCheckRequired` is true at lower technologies and at technology five
when that choice is selected. This flag does not resolve infection. Technology
zero is explicitly unsupported because the surgical equipment table begins at
one. Higher technologies use the table's continuing formula.

`rpgExpandedSurgeryOutcome(score, roll, simpleAmputation, damageRolls)` assesses
supplied dice for the general B223 result. Failure requires exactly two damage
dice for a simple amputation and three for other operations; each die must be
one through six. Success requires no damage roll. The result reports `check`,
`damageDice` and `damage`. A critical failure still needs its operation-specific
consequences in addition to this general failure result.

These interfaces do not commit damage, time, skill prerequisites, infection,
stabilization or disability repair. Those inventory entries remain partial or
pending. `test_surgery_assessments` records expected technology rows, combined
penalties, field-expedient exceptions, infection triggers and failure damage.
The fixtures remain unrun while checks are paused.


The medical roster also records `medicalAdmittedAt` for the current assignment.
It remains fixed when a scheduled physician check advances `medicalCareSince`;
release clears it and readmission records a new start. The hazards module uses
this timestamp when assessing care over a full infection interval. This preserves
one provider roster and avoids treating a check timestamp as the admission date.


## Resuscitation assessment

`rpgExpandedResuscitationProcedure(skillKind, medicalTL, trained,
modernTechnique, cause)` supplies the B425 attempt duration and skill modifier.
Use `physician` or `first-aid`, and cause `drowning`, `asphyxiation` or
`heart-attack`. The recorded procedure requires technology seven or higher.
Each attempt takes sixty seconds. Physician has no procedure penalty. First aid
normally has minus four; trained modern rescue breathing for drowning or
asphyxiation reduces that penalty to minus two. A default roll or a heart-attack
attempt retains minus four. Equipment and other applicable skill circumstances
must be assessed separately.

This helper performs no skill check and starts no treatment. It does not establish
that a victim is revivable, extend a cause-specific deadline or interrupt ongoing
suffocation. Owned treatment, repeated attempts, lung clearance and deadline
integration remain incomplete. `test_resuscitation_assessment` records the skill,
technology, training and cause distinctions and remains unrun while checks are
paused.


## Cardiac arrest onset and deadline

`RpgExpandedCardiacArrest` owns a confirmed cardiac-arrest trigger. Supply a unique
`id`, `profile` and `evidence` from the actual triggering procedure. `start()` checks
the supported diffuse, homogeneous and no-vitals anatomy immunities first. Immune
onsets are recorded as prevented without fatigue loss, collapse or a deadline.
Other onsets set the existing fatigue deficit to twice fatigue capacity, producing
negative full fatigue and unconsciousness. This is a condition assignment, not
an FP expenditure: it does not inflict fatigue-overflow injury or erase existing
recovery restrictions.

The B429 deadline is twenty seconds per point of HT, captured at onset. Repeating
`start()` cannot refresh it. `assessExpiry()` is pure; `expire()` at or after the
deadline records death and clears active condition ownership. The author must
schedule this deadline on the shared clock. Ordinary rest is rejected while the
condition is active. The cardiac treatment below supports uninterrupted resuscitation. Changing
physiology and interactions with other causes of death remain incomplete. Do not clear the active
condition manually as a substitute for a successful treatment procedure.

`rpgExpandedCardiacHealth(capacity, injury, survived)` supplies the condition's
health floor using the existing injury-deficit representation. Survival requires
at least full capacity in injury, meaning zero current HP; death requires at least
twice capacity, meaning negative full HP. A worse existing injury total is retained.
The helper itself changes nothing. Untreated expiry applies the death consequence
directly without attack damage, shock or survival rolls. A successful cardiac resuscitation applies the survival consequence directly,
without an attack damage roll.

`test_cardiac_condition` records duration, fatigue assignment without overflow,
repeated onset, early expiry, exact expiry, preserved recovery restrictions,
immunities and both health-floor formulas. Fixtures remain unrun while checks are
paused. Interrupted care remains outstanding; opt-in deadline dispatch is described
below. The
transaction and continuation fixtures below are authored but unrun.


## Committed cardiac resuscitation

`RpgExpandedCardiacResuscitation` owns one uninterrupted attempt against an active
`arrest`. Supply a unique `id`, an able `healer`, a technology-specific `skill`,
any assessed contextual `modifier`, and `careEvidence` establishing uninterrupted
access and suitable equipment for the full minute. Skill must be IQ/Easy first aid
or IQ/Hard physician at technology seven or later. The healer's actual training
and defaults are resolved through the shared skill scorer. First aid retains the
minus-four cardiac penalty; the drowning/asphyxiation rescue-breathing reduction
does not apply to cardiac arrest.

`assess()` previews the attempt without spending time or randomness. It rejects
an invalid skill, an incapacitated or exhausted healer, concurrent mortal injury,
a missing care contract, or a completion time at or beyond the arrest deadline.
`apply()` charges sixty seconds once and makes the skill check. Failure leaves the
arrest active; another attempt needs a new ID and enough remaining time. Replaying
an attempt returns its receipt, so neither a success nor a failure can be rerolled
or refunded. The shared action transaction must enclose this operation.

On success, the case records `revivedBy`, releases active arrest ownership and
raises the injury deficit to at least full health capacity. Worse existing injury
is retained. This is the specified post-arrest condition consequence, without
attack shock, knockdown or a new survival roll. Fatigue remains at its negative
capacity limit and ordinary recovery is subsequently allowed. Successful revival
therefore does not immediately awaken or fully heal the patient. The old deadline
cannot kill a successfully revived case.

The operation supports only the uninterrupted minute asserted by the care
contract. It does not schedule other actors' events during that minute; scenarios
with intervening hazards, interrupted treatment, multiple simultaneous providers
or additional revival restrictions require further integration. Drowning and
asphyxiation treatment remain separate incomplete procedures.

`test_cardiac_resuscitation` records physician and first-aid targets, a retained
worse injury total, repeat protection, failed-then-successful treatment, unavailable
technology and a deadline that cannot accommodate an attempt. Fixtures remain
unrun while checks are paused; the dedicated persistence and rollback fixtures below remain unrun.


The dedicated
[`expanded-cardiac-transactions.t`](../../tests/fixtures/expanded-cardiac-transactions.t)
adds exception rollback after onset, failed treatment, revival and untreated
expiry. `test_cardiac_transactions` records undo and replay of onset and treatment,
preview purity, blocked rest, bound-care rejection and stale requests after
revival. `test_cardiac_deadline_transactions` checks rollback and undo at the fatal
boundary. The original expiry request must remain blocked after revival, even
when the old deadline has passed.

`test_cardiac_persistence` restores separate-process saves after onset, after a
failed attempt, after revival and after death. Continuation preserves attempted
care, elapsed time, shared fatigue/injury and random state. Historical successful
and failed treatment requests must not reroll or recharge time. All fixtures are
unrun while checks are paused; no passing persistence claim is made.


## Expanded exhaustion assessments

`rpgExpandedExhaustionOutcome(remaining, capacity, collapsed, purpose,
willScore, willRoll, healthScore, healthRoll)` assesses B426 using supplied rolls.
Purpose is `action`, `talk`, `rest` or `do-nothing`. Positive remaining fatigue
permits the action without this check. At zero or less, a new action needs a Will
check; talking, resting and doing nothing are exempt until an existing collapse
prevents activity. A previously collapsed actor cannot obtain another effort roll
while fatigue remains nonpositive. Resting or doing nothing remains available.

Ordinary failure returns `incapacitated` without declaring unconsciousness.
Critical failure additionally assesses the supplied HT roll; failure returns
`cardiacTrigger`. This flag is a trigger for the owned cardiac condition, whose
immunity check must still run. It does not itself apply cardiac collapse or start
a deadline. At negative full fatigue capacity, the outcome instead identifies
unconsciousness without an effort roll. Scores and rolls are only required for
checks that the selected branch actually uses.

`rpgExpandedLowFatigueValue(value, remaining, capacity)` supplies the B426 halving
arithmetic for Move, Dodge or effective ST: strictly below one-third remaining
fatigue, halve and round up. It must not be used to reduce HP, damage or other
ST-based derived quantities. This numeric helper grants no permission to act;
a deeply exhausted actor can have a computed movement value while unable to use it.

Both helpers are pure. They do not mutate collapse, resolve a cardiac trigger,
spend time or draw randomness. The owned request below commits those outcomes.
Parser/structured/dialogue dispatch integration remains incomplete; these helpers
alone are not a replacement for `rpgLiteCanAct`.

`test_exhaustion_assessments` records positive-fatigue exemptions, ordinary and
critical effort failures, HT resistance, high-score automatic failure, prevention
of repeated efforts during collapse, negative-limit unconsciousness and exact
one-third rounding boundaries. Fixtures remain unrun while checks are paused.


## Owned effort permissions

Create `RpgExpandedEffort` with a unique action `id`, `profile`, `purpose` and
`evidence` identifying the actual attempted action. The four purposes are those
of the pure assessment. Assess the action's own legality and costs before calling
`apply()` within the enclosing action transaction. An allowed result permits that
one action; it does not execute it, advance time or spend its costs. Reusing the
same request returns the historical result without another roll. A different
action requires a new request; a historical permission is not a reusable permit.

`assess()` prepares the Will check and possible HT/cardiac branch without consuming
randomness. Cardiac onset now exposes `assessOnset()` so all possible outcomes can
be checked before the effort roll. Ordinary failure sets `exhaustionCollapsed`
while leaving consciousness unchanged. Critical failure makes the HT check; failure
commits the owned cardiac condition, including its anatomy-immunity decision.
Immunity prevents the cardiac consequences but does not negate the failed effort's
incapacity. Subsequent efforts during that collapse resolve without another roll.

The existing `rpgLiteCanAct` gate now calls the default-inert
`exhaustionBlocksAction()` hook after its existing incapacity and Do Nothing checks.
The expanded implementation prevents the old gate from rerolling a committed
collapse. Otherwise the old gate retains its previous behavior. Authors using an
owned expanded effort must not also invoke the Lite effort check for that action;
automatic replacement across all action adapters remains incomplete.

`afterFatigueRecovery()` is called by the shared health-time procedure and clears
expanded collapse once fatigue becomes positive. External fatigue-restoration
procedures must use that hook after updating the shared balance. Historical failed
requests do not reapply collapse after recovery. Other incapacities remain separate.
`test_owned_effort` covers success, conscious collapse, HT resistance, cardiac
onset, immunity, preview purity and repeat protection. `test_effort_recovery`
covers the legacy guard, no reroll during collapse, ordinary rest recovery and
replaying an old failure. `test_effort_transactions` covers rollback of all four rolled branches, undo,
changed-evidence rejection, recovery rollback and historical replay after recovery.
`test_effort_persistence` saves each branch and continues it in a separate process,
including the link to its owned cardiac condition. Fixtures remain unrun while
checks are paused. Broad action-dispatch integration remains outstanding.

## Owned action health gate

`RpgExpandedActionGate` extends `RpgExpandedEffort` for an active turn. Use purpose
`action` or `do-nothing`. It combines the B426 effort procedure with the B419
injury-consciousness check, so authors using its permission must not call
`rpgLiteCanAct` again for that turn. Other legality, action costs and execution
remain the action's responsibility and must be preflighted before this gate.

Assessment prepares both potential checks without spending randomness. Execution
first resolves exhaustion; only an allowed active action then checks consciousness
if current HP is zero or lower. That HT check has -1 per full HP capacity below
zero. Do Nothing skips both checks, but cannot grant an action to an already
unconscious or mortally wounded character. A consciousness failure sets
unconsciousness without adding exhaustion collapse. The receipt exposes
`consciousnessCheck` separately from its effort `check` and cardiac `healthCheck`.

The result belongs to one authored turn. Repeated calls return the recorded
permission and checks without rerolling, including after consciousness failure.
The gate charges no time or fatigue. Use it inside the enclosing action transaction.
The maneuver adapter below provides an opt-in integration point. Other parser,
structured and dialogue adapters still need explicit integration; merely including
this class does not replace their existing health gate.

`test_action_gate` records the combined-roll order, early stop on exhausted
collapse or cardiac onset, injury-only checks, the full-negative-HP penalty,
Do Nothing exemptions, preview purity and historical replay. It is authored but
unrun while checks are paused.


## Using the health gate for a maneuver

Use `RpgExpandedHealthManeuver` where an existing encounter accepts a
`RpgLiteManeuver`. Set `healthGate` to a fresh `RpgExpandedActionGate` owned by the
fighter's expanded profile. The gate purpose must be `do-nothing` for the `nothing`
maneuver and `action` for all other maneuvers. Give it a unique ID and evidence
identifying that one attempted turn.

The encounter performs its existing maneuver and attack preflight first, then
calls `healthAvailable(fighter)`. Invalid movement or attack requests therefore do
not roll or record the health gate. A ready request calls `canAct(fighter)` once.
The expanded adapter uses the owned gate in place of the ordinary combined health
check. A failed permission consumes the encounter turn as incapacitation; it does
not execute the maneuver or charge its costs. Inspect `healthGate.result` for the
separate effort, cardiac and consciousness results.

A completed gate cannot authorize a later turn, even if the original request is
submitted again: the adapter returns `maneuver-health-gate-used` before rolling or
advancing the encounter. Give each subsequent turn a fresh gate. The two hooks on
`RpgLiteManeuver` default to its existing health behavior, so ordinary maneuvers
retain the existing path and draw order. This compatibility is not yet verified.

This adapter covers maneuver entry only. Defense checks during Do Nothing,
journeys, travel abilities and other action adapters remain to be integrated.
`test_health_maneuver` records successful effort with one roll, failed effort,
combined injury checks, Do Nothing, invalid movement and rejection of a consumed
gate on the next turn. Fixtures remain unrun while checks are paused.


The `expanded-maneuver-transactions.t` fixture exercises the adapter inside a real
engine action transaction and encounter. `test_maneuver_transactions` records
exception rollback and undo of the effort, injury-consciousness and cardiac
branches, including the encounter index and RNG state. It also records rollback
of a later actor's turn and the associated shared second of time, changed-evidence
rejection, and refusal to reuse a gate in the next round.
`test_maneuver_persistence` saves before the first action, after its health outcome,
and after the round boundary, then continues each phase in a separate process.
These checks are authored but unrun. The route-parity fixture below covers this
maneuver entry point; owned defense-turn consciousness checks remain outstanding.

## Low-fatigue strength checks

Set `rules.expandedFatigueStrength = true` to apply the B426 temporary strength
reduction through `rpgLiteScore` and `rpgLiteCheck`. Below one-third FP, direct ST
checks use half ST, rounded up. Trained skills whose controlling attribute is ST
receive the same attribute reduction while retaining their relative training.
This includes a trained `RpgExpandedSkillContext` with `rollAttribute = rpgST`.
Fixed-base checks have no controlling attribute and retain their fixed base.

The adjustment is contextual: purchased `st`, `maxHP`, basic lifting capacity,
strength-based damage and character-point accounting do not change. Existing
Move and Dodge procedures already apply their separate low-health and low-fatigue
halvings. Do not apply the pure low-fatigue helper again to their final values.
The default-inert `healthAttributeModifier(context)` hook preserves the existing
score path when the option is absent or disabled.

An untrained strength-based default at low fatigue is explicitly rejected with
`fatigue-strength-default-unavailable`; the interaction between temporary strength,
attribute-default caps and chained defaults is not implemented here. Callers that
read `attributeScore` directly, other strength-based procedures, and the separate
core resilience system are not automatically redirected to this option.

`test_fatigue_strength` records the strict one-third boundary, odd-strength rounding,
relative training, fixed-base exemption, preserved purchased characteristics and
lifting capacity, combined low-health/low-fatigue Move and Dodge, the disabled
option, and pure assessment. These fixtures are authored but unrun.


The fixture also exposes `first turn`, `second turn`, `first rollback` and
`second rollback` parser commands, corresponding structured verbs, and instructor
dialogue choices. All three routes call the same `maneuverDo` operation inside
their engine transaction. The instructor is an observer of the encounter; issuing
a fixture command is not an in-world action by the incapacitated fighter.

`test_maneuver_route_parity` compares successful effort, injury-consciousness failure, exhausted
collapse and cardiac onset across those routes. For each branch it records
exception rollback, undo and deterministic replay of the first turn, rollback of
the round boundary, and rejection of a consumed gate on the following turn.
The fixture is authored but unrun; it establishes no passing parity claim yet.
Other shared health operations still need equivalent route coverage.


## Defense eligibility during exhausted collapse

The shared defense scorer now consults `healthBlocksDefense()`. Its Lite default
returns false. The expanded health implementation blocks defenses during conscious
exhaustion collapse while FP remains zero or below, and during an active owned
cardiac arrest. This is an eligibility query: it does not roll, spend a defense,
or modify the character. The usual unconsciousness and other existing defense
restrictions still apply.

Ordinary rest clears expanded collapse when FP becomes positive, restoring defense
eligibility subject to the remaining restrictions. Dodge can still be reduced by
low fatigue after eligibility returns. `test_collapse_defense` creates collapse
through a committed failed effort, records the absence of Dodge, Block and Parry,
then records the return of Dodge after recovery, with no extra random draws.
The fixture is authored but unrun. This guard does not yet replace the legacy
consciousness/effort checks for a defense attempted during Do Nothing.


## Cardiac deadlines on the shared clock

Set `rules.automaticCardiacDeadlines = true` before starting an owned cardiac
condition to register it with `rpgExpandedCardiacClock`. This choice is captured
at onset: changing the campaign option later does not cancel a registered case.
Immune onsets are not registered. Existing cases created with the option disabled
continue to require an explicit `expire()` call.

`rpgSpendTime` now calls the default-inert `rpgLedger.validateAdvance(seconds)`
and `afterAdvance(previousSeconds)` hooks. Expanded health preflights registered
case ownership, deadline identity and due injury consequences before the clock
changes. After the single shared time charge, due untreated cases commit their
existing expiry operation. An advance that crosses the deadline records `endedAt`
at the deadline, even when the shared clock ends later. Repeated advances do not
repeat injury; successful resuscitation prevents the scheduled expiry. No random
numbers are consumed by deadline dispatch.

Use these operations inside an engine action transaction. The clock, registration,
condition and receipt then share rollback, undo and the exact-game save policy.
Writing directly to `rpgLedger.seconds` bypasses the hooks and is unsupported for
scheduled cases. Death from another cause while a cardiac case remains active is
explicitly rejected at its due boundary pending a separate termination contract.
This scheduler handles cardiac deadlines only: it does not simulate intervening
care choices, exposure ticks or arbitrary world events during a long time advance.

`test_cardiac_clock` records the exact boundary, crossing it in a larger advance,
exception rollback, undo, changed-case rejection, captured scheduling policy and
repeat protection. `test_cardiac_clock_revival` records cancellation by successful
treatment. `test_cardiac_clock_persistence` continues saves immediately before and
after expiry in a separate process. All fixtures are authored but unrun while
checks remain paused.


`test_cardiac_clock_batch` adds two cases with deadlines at 100 and 200 seconds,
registered in the opposite order. It records onset rollback, one advance crossing
both deadlines, undo of both expiries, and separate advances through each boundary.
Its unsupported-death case catches the rejection inside the fixture operation,
then inspects both patients and the clock. Thus transaction rollback cannot conceal
a partial commit before validation rejected the later registered case.
`test_cardiac_clock_batch_persistence` saves between the deadlines and continues
the remaining case in another process. These batch fixtures remain unrun.


## Critical injuries treated as major wounds

A caller resolving a qualifying critical-hit effect may set both `criticalHit`
and `forceMajorWound` on its owned `RpgExpandedWound`. Supply the actual final
injury in `amount`, and set this flag only after damage penetrates protection.
Zero injury and a missing critical-hit declaration are rejected. This input does
not raise injury to the ordinary major-wound threshold or charge damage again.

The wound preflights the existing knockdown/drop path with a mandatory major-wound
check. `rpgExpandedMajorWoundModifier` supplies the location penalty, including
supported absent-brain/vitals exceptions. Supported body-part wounds use the limb
modifier. Execution keeps the original injury amount, shared health ledger and
one wound receipt. Replaying it does not roll again; changing the major-wound
flag on an existing receipt is rejected.

`test_critical_major_wound` records one-point critical injuries to torso, face,
skull, vitals and groin, anatomy exceptions, blocked low scores, unchanged injury,
repeat protection and immutable declaration. Fixtures remain unrun. This supports
the major-wound consequence, not the complete attack or other critical-hit effects.


`test_critical_major_transactions` exercises the one-point critical wound with
held equipment inside an action transaction. It records rollback of injury,
knockdown, random draws and the forced drop; rejection of a missing critical
qualification or drop destination; undo; and rejection of changed historical
flags or destinations. `test_critical_major_persistence` saves before and after
the wound, then continues in another process without repeating the check or
inventory transfer. These fixtures remain unrun while checks are paused.

## Full-reference fear assessments

`rpgExpandedAssessFear(will, modifier, unfazeable)` applies the B360 initial
check cap after the supplied modifiers: modified Will above thirteen becomes
thirteen. Immunity returns without a score or random draw. Scores below three
are explicitly unavailable in this interface. The cap must not be reused for
ordinary Will checks or later fear recovery. This helper does not assemble
situational modifiers or execute the check.

`rpgExpandedFearTable(total)` records the B360–B361 consequence specification
for every printed result from four through forty, with higher totals selecting
the forty-plus row. The caller must supply the three-die table roll plus failure
magnitude; this helper does not roll, commit consequences or invoke the Lite
fear formula. It returns the selected kind, duration dice/unit, fixed duration,
recovery policy, fatigue and injury dice, conditional injury, trait requirements,
repeat durations and aftereffects. A negative `traitPoints` is a required
character-value change, not an award of spendable points.

Conditional fields matter: the injury on rows eighteen, twenty-six and
twenty-seven requires a failed immediate health check; row thirty-one likewise
conditions injury and separately specifies permanent health loss on a critical
failure. Row twenty-five first attempts a related self-control reduction, with
`fallbackTraitPoints` identifying the alternative. Catatonia records escalating
neglect injury and a recovery penalty lasting as long as the episode. Extreme
panic requires authored consequential reactions, preceded by its specified
reaction dice. No generic callback is treated as implementing these outcomes.

Row twenty's post-duration recovery is marked `source-followup-required` because
the inspected paragraph specifies duration and fatigue without explicitly
repeating a recovery roll. Do not silently select a recovery policy. Several later rows
still need owned execution, exact resource spending, recovery scheduling and
where applicable author-selected trait or behavior consequences. Terrifying
object-history readings therefore remain blocked.

`test_fear_assessments` supplies independent expected initial-score boundaries
and every primary table row. Conditional resource and aftereffect fields still
need independent validation when their executors are added. The fixture is
unrun while checks are paused; this is partial source coverage only.

## Fear scene modifiers

`RpgExpandedFearContext` combines the B360 modifier categories without rolling.
Set an expanded `profile`, `approved` and `evidence` establishing why this event
requires a fear check for this character. The assessment reads owned fearlessness,
fearfulness, combat reflexes, combat paralysis, daring and higher-purpose traits;
conditional fields determine when their effects apply. It adds each once before
calling the initial-check cap helper.

Use `physicalRisk` with an explicit `cowardicePenalty` from one through four
when the character has that trait. Likewise, an owned alien-interest trait
requires its `xenophiliaBonus` when confronting `monsters`. Missing or unused
severity classifications are rejected. `charging` and `purposeThreat` activate
the corresponding owned trait bonuses.

`body` is `none`, `prepared`, `nonviolent`, `violent` or `mutilated`. Mutilated
bodies require a one-to-three `mutilationPenalty`; `dependentVictim` requires a
body. `inCombat` supplies the separate battle bonus. Monster scenes supply
`monsterPenalty` from zero through ten and `hordeBand` from zero through five.
The printed horde anchors are five, ten, twenty, fifty and at least one hundred
creatures for bands one through five. The author classifies unlisted counts;
this interface does not invent interpolation between those anchors.

`touching`, whole-yard `distance` and `remote` describe physical access. Remote
viewing uses its own bonus instead of stacking the distant-viewing bonus; a
touching event cannot also be remote or have nonzero distance. `isolated`,
`adverseLighting` and `believesAlone` apply the remaining circumstance penalties.
For night-dwellers the author sets adverse lighting according to that reversal.

Preparation uses `priorExperience`, `priorExposures24h` and `briefingBonus`
(zero through three). The exposure count is an explicit author fact for now;
automatic twenty-four-hour encounter history is still pending. The result
reports the complete `modifier`, capped `score` and immunity. It does not
execute a fear event or recovery check. `test_fear_context` specifies the printed
categories, trait contributions, distance boundary, exclusive remote bonus and
combined modifiers. All new fixtures remain unrun.


## Owned short fear-stun episodes

`RpgExpandedFearStun` executes an authored outcome from `full-2008`, B360,
rows four through eleven and fourteen through sixteen. Supply a unique `id`, a ready `RpgExpandedFearContext`,
`tableTotal`, `approved` and `evidence` recording the selected outcome. This is
an explicit outcome interface; it does not yet roll the initial fear check or
select an outcome from the whole table. Unsupported rows are rejected before
randomness or state changes. Apply it inside an engine action transaction.

The episode owns the profile's mental-stun condition and records its start,
initial deadline and original scene modifier. Rows four and five clear that
condition automatically when shared time reaches the one-second deadline.
Rows six through nine have a one-second initial duration; ten and eleven roll
one or two duration dice. Starting an episode does not advance time. Existing
stun, another fear episode, unconsciousness or death prevents starting it.

After the initial duration, create a distinct `RpgExpandedFearStunRecovery`
with an `id` and `episode` for each recovery attempt. `assess()` is pure;
`apply()` spends one shared second and then rolls. Rows six and seven use
unmodified Will. Later supported rows retain the original fear modifier even
when the scene changes. Recovery does not apply the initial-check cap of
thirteen. A failed attempt leaves the episode active. Replaying a committed
attempt returns its receipt without another time charge or roll.

The Lite recovery hook defers while an expanded fear episode owns recovery.
Completion clears mental stun without clearing an independently acquired
physical stun. Use the combat adapter below inside battle turns instead of
calling the standalone timed route. Episodes and
receipts use ordinary persistent game objects and the engine's transaction,
undo and exact-compiled-game save mechanisms.

`test_fear_stun`, `test_fear_stun_modifiers` and `test_fear_stun_persistence`
specify duration boundaries, automatic recovery, pure previews, exception
rollback, original modifier retention, uncapped recovery, undo, failed-attempt
receipts and cross-process continuation. These fixtures remain unrun while
checks are paused. Full-table execution, encounter history and fear-triggered
supernatural reading integration remain incomplete.


### Combat recovery

Use `RpgExpandedFearRecoveryManeuver` for a Do Nothing turn after the initial
stun duration. Bind its `battle`, a fresh `recovery` request for the actor's
owned episode, and a fresh `RpgExpandedActionGate` as `healthGate`. The gate's
purpose must be `do-nothing`. Keep movement zero. The battle must have this
fighter as its current participant; mismatched ownership and reused requests
are rejected before spending resources.

The maneuver performs the recovery check at the end of that actor's turn.
`applyInTurn` is the adapter's internal execution route: its receipt has zero
additional seconds because the battle scheduler advances the shared clock.
The standalone `apply()` still spends its own second. Both routes record the
attempt's starting time and prevent another attempt within that same second.
A fresh request is needed after a failed roll; reusing the old maneuver cannot
obtain another recovery check or another free turn. During the initial stun
period use an ordinary Do Nothing maneuver; no recovery roll is yet eligible.

`test_fear_combat` specifies initial-duration rejection, health-gate integration,
no duplicate time charge, successful and failed recovery, same-second rejection,
preview purity, exception rollback, undo and replay rejection. It remains unrun.


### Fear-induced retching assessment

`rpgExpandedAssessFearRetching(health, attribute, requiresConcentration)`
assesses the row-twelve duration and B428–B429 condition effects without
changing state. For health below twenty-five, `initialSeconds` is twenty-five
minus health; subsequent recovery uses `recoveryScore` with a one-second
interval. The inspected source does not specify a minimum for exceptional
health values at or above twenty-five, so those requests return
`retching-duration-source-required` instead of inventing a duration.

The result applies a minus-five `modifier` to dexterity, intelligence and
perception, with zero for the other base attributes. `automaticFailure` and
`actionAllowed` identify concentration's special restriction. This condition
permits attempted actions despite the general incapacitating-condition rule;
do not implement it by setting mental stun. Its effective-stun defense penalty
is minus four. `finishingFatigue` records one fatigue point due at the end, and
`oralBenefitsLost` records the need to revoke affected meals and oral medication.
These fields describe required consequences; this helper does not charge or
revoke them, change defense scores, or create a recovery episode.

`test_fear_retching` contains independent duration, attribute, concentration and
resource expectations. The fixture remains unrun. Owned execution is described below. Broader oral-medicine effects
remain pending; row twelve remains partial.


### Owned retching episodes

`RpgExpandedFearRetching` owns one active condition on an expanded profile.
Provide a unique `id`, an approved fear `context`, outcome `approved` and
`evidence`, and `oralEffectsReviewed`. The latter is an explicit author finding
about recent meals and oral medicine. `affectedOralBenefits` accepts the owned meal credits and oral nausea remedies
described below. Other benefit types remain explicitly unavailable. The selected
list is bound when the episode starts; changing it prevents recovery until
the original reviewed list is restored. New meals cannot be credited while
retching remains active.

Starting the episode records the initial deadline without spending time or
randomness. It applies the attribute penalties through ordinary contextual
checks and the effective-stun defense penalty through the existing defense
calculation. Physical or mental stun does not double that defense penalty.
The actor is not marked mentally stunned and can attempt other actions.
`RpgLiteContext.requiresConcentration`, a `concentrate` check kind, and the
combat Concentrate maneuver all identify the unavailable operation. Authors
must mark concentration-dependent checks explicitly; the engine cannot infer
that requirement from descriptive text.

After the deadline, a fresh `RpgExpandedRetchingRecovery` with an `id` and
`episode` spends one shared second and checks health. Successful recovery ends
the condition and charges one fatigue point through the shared increment
function. If remaining fatigue is zero or negative, successful recovery also
commits one point of injury through `RpgExpandedWound`. This requires the scaled
injury rule and supported wound anatomy and traits; missing wound support blocks
before the recovery attempt spends time or dice. Supply `dropDestination` when
the wound procedure could require dropping equipment. Reaching negative maximum
fatigue invokes the shared unconsciousness hook and records fatigue collapse.
A changed oral review or affected benefit also blocks before time or dice.
Replaying a committed request does not charge fatigue, time or dice again.
Use this standalone recovery outside an already charged combat turn. Within
a battle use the adapter below.

`test_owned_retching` and `test_retching_persistence` specify contextual penalties,
concentration rejection, duration boundaries, final fatigue, pure preview,
rollback, undo, replay, unsupported combinations and continuation in a new
process. They are authored and unrun while checks remain paused.


Recovery receipts use `RpgExpandedRetchingRecoveryResult`: `fatigueAdded` and
`injuryAdded` report committed costs, and `wound` retains the owned injury record.
A failed health roll commits neither fatigue nor injury. Recovery reassesses the
cost after spending its second so intervening time effects cannot leave a stale
injury plan. Exception rollback restores the condition, wound history, resource
ledgers, elapsed time and random stream together.

`test_retching_fatigue` specifies positive, zero and near-collapse fatigue;
success and failure; preflight rejection without the required wound rule;
preview, rollback, undo and replay. It remains unrun with the other new fixtures.


### Retching recovery in combat

`RpgExpandedRetchingRecoveryManeuver` binds a `battle`, a fresh `recovery` and a
fresh `healthGate` whose purpose is `do-nothing`. The request's kind must remain
`nothing` and movement must be zero. The actor must be the battle's current
participant and own the recovery episode. Initial-duration and oral-review
requirements are checked before the health gate or any random roll.

The adapter calls the recovery's `applyInTurn` route. It uses the same injury
preflight and final fatigue charge as standalone recovery, but reports zero
additional seconds: the battle scheduler owns elapsed time. Both recovery routes
record their starting time and reject a new attempt in that same second. A
completed request cannot be reused as a fresh combat maneuver; after a failed
check, author a new recovery and health gate for the next eligible turn.

`test_retching_combat` specifies positive and zero fatigue, failed and successful
checks, concentration rejection before turn consumption, pure preview, exception
rollback, undo, same-second rejection, no duplicate resource spending and the
single battle-clock advance. These fixtures remain unrun.


### Meal credits and expelled food

`RpgExpandedMealCredit` records an eaten meal in the existing `RpgLiteNeeds`
ledger. Set `id`, the expanded `profile`, its `needs` object, `meals` (one through
three), `approved` and `evidence`. This credits food already obtained and eaten;
it neither buys inventory nor charges time for eating. Start the needs ledger
with only its otherwise supplied meals, leaving capacity for these credits.
Do not separately count the same meal in `needs.meals`.

Applying a credit adds its meals once and records the needs cycle. Replaying it
never adds food again, including after revocation. The daily needs settlement
uses credited meals for that day and then removes those credits from the next
cycle's count. The original Lite daily plan remains unchanged when there are no
owned credits. No second food or fatigue ledger is introduced.

The retching author identifies which recent meal credits were expelled and
places those objects in `affectedOralBenefits`. The source supplies no universal
elapsed-time cutoff for “recent”; that classification remains an explicit world
fact in the reviewed outcome evidence. Starting the episode revokes the listed
credits atomically with its condition. Duplicate references, another actor's
credits, unrecorded food and already settled cycles reject before mutation.
Multiple credits on one needs ledger are assessed together before any removal.
A meal's receipt retains `revokedBy`, and replay cannot restore expelled food.

`test_retching_meals` specifies credit replay, revocation, pure previews,
rollback, undo, changed-review rejection, duplicate references and the daily
settlement boundary. These fixtures remain unrun. Retroactive reversal of a
settled day's fatigue and broader oral-medicine effects remain unsupported.


### Oral nausea remedies

`RpgExpandedOralNauseaRemedy` records an already administered oral treatment
whose supported effect is the B428 nausea-trigger bonus. Set its unique `id`,
`profile`, `approved`, `evidence`, `effectStartsAt` and `effectEndsAt`. The source
specifies the bonus but no universal onset or duration for medicines; those
times must be explicit authored facts for the selected treatment. Missing timing
blocks registration. This record does not purchase, consume or administer an
inventory item and does not add a separate time charge.

`rpgExpandedNauseaTriggerModifier(profile, richMealWithinHour)` returns the
source's plus-two remedy adjustment and minus-two recent-rich-meal adjustment.
The modifier applies only to the vomiting-trigger health check. It does not
remove nausea's general penalties or improve retching recovery. Multiple active
remedies still contribute a single plus two. Effects begin at `effectStartsAt`
and cease at `effectEndsAt` on the shared clock; queries never roll or mutate.
Global nausea state, trigger scheduling and its retching-on-failure procedure
remain to be implemented.

Include an expelled remedy record in the retching episode's reviewed
`affectedOralBenefits`, alongside any meal credits. The start transaction removes
both benefits atomically and binds each `revokedBy` receipt. Replaying remedy
registration cannot restore an expelled effect. New oral remedies cannot be
registered during active retching. Unrecorded, foreign, expired or previously
revoked remedies reject; other medicines require their own concrete effect
implementations and are not represented by this class.

`test_retching_remedy` and `test_remedy_persistence` specify the numeric bonus,
non-stacking behavior, onset and expiry boundaries, combined meal/medicine
revocation, preview, rollback, undo, replay and cross-process continuation.
They remain unrun while checks are paused.


### Fatigue-plus-stun outcomes

Rows fourteen and fifteen use `RpgExpandedFearStun` with the same original
modifier and recovery policy as row ten. The operation preflights the maximum
six-point fatigue cost before randomness, rolls one die for fatigue and one for
stun duration, then commits the owned cost and episode in the same action.
Supply `dropDestination` if possible fatigue injury needs a forced-drop plan.
An unsupported possible consequence rejects before either die is drawn.

`RpgExpandedFearFatigueLoss` handles the prescribed one-through-six-point fear
cost with a unique `id`, expanded `profile` and `amount`. It introduces no time
charge. Points lost at nonpositive fatigue each create a separate one-point
owned wound; they are not combined into a larger wound with different major-wound
behavior. The fatigue ledger clamps at negative maximum while further costs
still cause injury. Reaching that limit invokes the shared unconsciousness hook
before further injury is resolved. Death terminates further expenditure.

Assessment prepares all potential wounds, equipment drops and crossed survival
thresholds. The resulting `RpgExpandedFearFatigueResult` reports actual
`fatigueAdded`, `injuryAdded` and committed `wounds`. Replaying the loss returns
zero new costs. The stun episode retains its `fatigueLoss` receipt, so repeated
calls and saved-game continuation cannot spend the cost again. A fatal cost
records the episode as completed instead of creating an active stun on a corpse.

`test_fear_fatigue`, `test_fear_fatigue_stun` and the extended `test_fear_stun`
specify positive, zero and negative fatigue, clamping, separate wounds, both
randomized outcomes, preflight rejection, preview, rollback, undo, replay and
cross-process recovery. They remain unrun.


### Combined stun and mental quirk

For row sixteen, set `RpgExpandedFearStun.quirkAcquisition` to a fresh
`RpgExpandedFearQuirkAcquisition` from the traits module. Its `profile` must
match the fear context and its `eventId` must equal the episode's `id`. The
acquisition must have the explicit behavior and event-relation evidence described
in the [traits guide](traits.md#fear-induced-behavioral-quirks).

Both consequences are assessed before the one-die stun duration is rolled.
The same engine action commits the new quirk and owned stun. This row does not
charge fatigue. Recovery follows the modified-Will procedure of row ten, while
the quirk persists after stun ends. An already used acquisition, missing approval
or missing trait implementation blocks before randomness. A quirk acquisition
supplied for another stun row is rejected rather than silently ignored.

`RpgExpandedFearQuirkContract` lives in the foundation solely to avoid circular
or mandatory catalogue dependencies. Its default implementation is unavailable;
it does not count as implemented author adjudication. The traits module supplies
the concrete acquisition. Health-only integrations retain their existing include
set and can continue using other supported outcomes.

`test_fear_quirk_stun` specifies compound preview and rollback, unchanged
spendable points, no fatigue cost, missing-contract rejection, replay and recovery
after cross-process restoration. The fixture remains unrun.


### Owned fainting

`RpgExpandedFearFaint` implements rows seventeen through nineteen of
`full-2008`, B361; `tableTotal` defaults to seventeen. Supply an `id`, approved fear `context`, outcome `approved`
and `evidence`. A held-item drop requires the equipment module and an authored
`dropDestination`; missing drop support blocks before randomness. The operation
requires a conscious actor with positive health and fatigue and no conflicting
unconsciousness owner. It rolls one die of minutes, records `nextCheckAt`, puts
the actor lying down and invokes the shared unconsciousness hook.

The initial recovery check becomes due when that duration ends. A fresh
`RpgExpandedFearFaintRecovery` owns each health check, with its own `id` and
`episode`. The request charges no additional time: the shared clock has already
reached the boundary. Failure schedules the next check sixty seconds later;
success ends the faint. Replaying an attempt neither rerolls nor reschedules.
This uses a dedicated health-check context, without borrowing the ordinary
wake context's trait adjustments.

Time advancement stops at pending faint recovery boundaries. Attempts to jump
past a boundary reject before time changes; advance to it, resolve the due check,
and then continue. This prevents long rests or travel from silently skipping
required checks. Ordinary unconsciousness timers, healing and fatigue recovery
cannot wake an actor while the faint owns recovery. The base hooks preserve
ordinary behavior when no expansion owns the condition.

Ending the faint clears only its ownership. It does not wake an actor whose
health, fatigue, mortality, other unconsciousness owner or other recorded
medical condition still prevents waking. Those conditions keep their existing
recovery procedures. Full overlapping-cause timing and later compound faint outcomes remain
incomplete; this interface does not implement those later rows.

`test_fear_faint` specifies initial duration, suppression of early ordinary wake
and healing checks, exact deadlines, failure/retry timing, boundary rejection,
preview, rollback, undo, replay, save continuation and retained unconsciousness
from another cause. The fixture is authored and unrun.


For `tableTotal = 18`, the faint keeps the one-die-minute duration and makes its
separate immediate health check. Failure commits one point of injury through an
owned wound; success does not create a wound. For `tableTotal = 19`, duration is
two dice of minutes and one point of injury is unconditional, without an extra
health check at onset. Both retain the same minute recovery schedule.

The possible wound and forced drop are assessed before duration dice or the
immediate check. Missing wound-rule or anatomy support blocks the entire event.
Unconsciousness and the fall are established before the collapse injury, so the
injury cannot cause a second knockdown of an already unconscious actor. `onset`
retains the immediate `check` when present and the committed `wound` when injury
occurs. Replay never rolls or injures again.

`test_fear_faint_injury` specifies conditional and unconditional injury, both
durations, successful immediate resistance, zero-cost rejection, preview,
rollback, undo, replay and saved-game continuation. These fixtures remain unrun.


## Optional bleeding: minute outcome

`rpgExpandedBleedingOutcome(health, lossBasis, modifier, roll, clearMinutes)`
implements the supplied-roll minute outcome from `full-2008` B420. It subtracts
one from the HT score per full five HP in `lossBasis`, then adds the explicitly
supplied contextual `modifier`. It returns the ordinary check plus `injury`,
`clearMinutes` and `stopped`. Ordinary failure loses one HP, critical failure
three; either resets the clear-minute streak. Ordinary success increments the
streak, stopping at three; critical success stops immediately.

The prior streak must be zero, one or two. A completed bleeding episode must not
be assessed as another active minute. A score below three returns an explicit
unavailable result. The helper consumes no randomness or time and commits no
injury. Its `ready` result is an assessment, not a resolved bleeding episode.

The caller must supply a verified loss basis; this helper does not decide whether
partially healed injuries, multiple wound times or subsequent blood loss alter
that basis. Those policies need reconciliation in the owned episode implementation.
Bleeding eligibility remains a concrete author decision tied to actual wounds.
Campaign selection, persistent episodes, minute scheduling, injury execution and
successful first-aid termination are still pending. Merely including health does
not activate bleeding.

`test_bleeding_outcomes` specifies five-HP boundaries, ordinary and critical
results, three consecutive clear minutes, failure resetting the streak, modifiers
and blocked scores. The fixture is authored and unrun while checks are paused.


### Owned bleeding onset and eligibility

`RpgExpandedRules.bleeding` defaults to nil. With it explicitly enabled,
`RpgExpandedBleedingWound` classifies a committed `RpgExpandedWound` using
`damageKind`, `bleeds`, `approved` and concrete `evidence`. Supported categories
are cutting, impaling, piercing, crushing, burning, corrosion and other. Ordinary
cutting/impaling/piercing wounds bleed; ordinary crushing wounds do not. Burns
and corrosion use the wound's actual major-wound assessment. Departures from
these defaults, and the `other` category, require `exceptionEvidence`. This records
an explicit author decision rather than inferring unseen injury anatomy.

`RpgExpandedBleedingEpisode` takes a unique `id` and this `classification`.
`apply()` must occur at the wound's recorded `committedAt` time, normally in the
same engine transaction. It installs `profile.bleedingEpisode`, adds an owned
history entry and sets `nextCheckAt` sixty seconds after onset. It neither causes
another wound nor spends time. Replaying its bound receipt does not reset that
deadline. Late registration and overlapping active episodes return explicit
requirements for the pending aggregation procedure.

The shared ledger may advance exactly to a pending check, but rejects crossing
it. Binding changes are rejected before clock advance. Dead characters no longer
block the clock. Episode scheduling and wound timestamps follow the exact-game
save policy; no old-save migration is supplied.

**This lifecycle is incomplete.** Automatic wound enrollment,
subsequent-wound aggregation, the loss-basis policy and first-aid termination are
not yet supplied. Do not enable bleeding in a playable integration until those
operations are available for the intended scenario. An active episode stops time
at each required check until it is resolved below. This boundary must not be bypassed by manually
changing the deadline or clearing ownership fields.

`test_bleeding_onset` and the
[fixture](../../tests/fixtures/expanded-bleeding.t) specify opt-in, wound ownership,
eligibility evidence, registration timing, preview, rollback, undo, replay and
cross-process preservation of the exact minute boundary. They remain unrun.


### Executing a bleeding minute

`RpgExpandedBleedingMinute` requires a unique `id`, owned `episode`, explicit
`lossBasis`, `basisEvidence` and `approved`. At exactly `episode.nextCheckAt`,
`assess()` prepares the HT context and all possible injury before any die roll.
`apply()` rolls once, commits any blood-loss injury through an owned expanded
wound, records the result, and either schedules the next minute or stops the
episode. It does not spend the elapsed minute again. Advance the shared ledger
to the deadline, then resolve the check inside an action transaction.

The episode retains the clear-minute streak. Ordinary or critical failure resets
it; critical success or three successive clear minutes sets `stoppedAt` and clears
`profile.bleedingEpisode`. Death also releases the pending clock boundary. Minute
receipts retain their committed injury, check and timestamp. Replay reports
`reused` without another roll, wound or deadline change. Distinct attempts cannot
resolve the same minute twice.

The loss basis remains an explicit, approved source interpretation; this does not
claim automatic aggregation of healing, later injuries or preceding blood loss.
The standard wound adapter is supported only at maximum HP six or greater and
without `rules.lastWounds`. Smaller bodies would introduce an unresolved
blood-loss/major-wound interaction; the optional injury-ignoring rule also needs
explicit reconciliation. Both are rejected before randomness. Other unsupported
wound configurations propagate their normal preflight blocker.

`test_bleeding_minutes` specifies exact due times, retained failed/successful
minutes, injury amounts, reset/termination of the streak, replay, preview,
rollback, undo, saved continuation and release of the clock after termination.
These fixtures remain unrun. First-aid termination, automatic wound enrollment,
multiple-wound aggregation and a fully reconciled loss basis still prevent a
complete bleeding-system claim.


### First Aid to stop bleeding

`RpgExpandedBleedingAid` owns the B424 pressure/tourniquet interval and its First
Aid check. Supply `id`, active `episode`, `healer`, a technology-specific
`first-aid` skill, applicable `modifier`, `approved` and concrete `careEvidence`.
`start()` retains the request and sets `completesAt` one minute later. Advance the
shared clock normally; neither starting nor completing this operation charges
the interval again. Any intervening bleeding deadlines must still be resolved.

At exactly `completesAt`, set `uninterrupted` only if the full care interval was
actually maintained. `assessCompletion()` is pure. `complete()` checks the
healer's current condition and skill, then rolls once. Success sets the episode's
`stoppedAt` and clears its active ownership; failure leaves the due bleeding check
pending. Even critical failure here does not borrow the two-HP consequence from
the separate shock-treatment procedure. A completed or cancelled receipt cannot
be rolled again. `cancel()` records interrupted care without a roll or benefit,
allowing another owned attempt to begin.

When a full care interval ends at the first bleeding deadline, successful care
can be resolved before that check, preventing initial blood loss. Later success
stops future loss without undoing prior wounds. It also leaves the normal wound
healing accounting intact. Earlier loss does not disappear from injury history.

Without a `bandage` this operation implements bleeding control only. Supply the
linked bandage described below to apply the healing credit in the same interval;
do not separately execute another timed bandage operation for that benefit. Concurrent aid attempts, changing healers, lost supplies and
multi-wound care also need explicit integration. Failed-care retries use a fresh
owned attempt and a new full minute; broader attempt modifiers remain authored.

`test_bleeding_aid` specifies early and late successful control, retained prior
loss, exact due times, failed/interrupted care, cancellation, no duplicate clock
charge, preview, rollback, undo, replay and saved continuation. These fixtures
are authored and unrun while checks remain paused.


### Bandage credit in the same care interval

Optionally set `RpgExpandedBleedingAid.bandage` to an owned
`RpgExpandedBandage` for the classified wound and the same healer. Supply its
normal `eligibleInjury` and evidence. Both starting care and completing it preflight
that credit, including protected injury and once-only restrictions, before rolling.
If First Aid succeeds, the aid operation stops bleeding and calls
`bandage.applyAfterBleedingCare(care)` within the same transaction. This commits
the ordinary scaled, capped healing credit with zero additional seconds.

The linked bandage retains its normal wound pointer, result and character serial
marker. Its receipt is also usable by the existing subsequent shock-treatment
interface, subject to that interface's limits. The care result reports `healed`.
Replaying either treatment or ordinary bandaging cannot grant a second credit.
Failed or cancelled bleeding care leaves the linked credit uncommitted.

The specialized commit requires a retained successful care receipt, matching
wound/healer, completed full interval and the current completion time. It cannot
be used to manufacture untimed treatment. The ordinary `bandage.apply()` still
charges its existing minute. Shared healing/marker mutation is factored into the
internal `commitHealing` method; integrations should use the assessed public
operations rather than call that internal commit directly.

Earlier-wound allocation remains restricted. If subsequent blood-loss injury
has changed the patient's latest-wound serial, the original wound's linked
bandage is rejected before the care roll. Bleeding-control-only care can still
stop further loss. Broader wound-specific healing allocation needs its own
reconciliation rather than bypassing the existing serial protection.

`test_bleeding_bandage` specifies one total care minute, one healing credit,
preview purity, failure without healing, invalid-eligibility rejection, rollback,
undo, replay and cross-process preservation of treatment markers. All fixtures
remain unrun while checks are paused.


### Offset care deadlines

Bleeding-minute checks and care completion use separate deadlines. If an injury
occurs at time zero and care begins at ten seconds, the next events are the
bleeding check at sixty and care completion at seventy. Resolving the first event
does not authorize an advance straight to the following bleeding check at 120.
The ledger rejects crossing the outstanding care deadline with
`bleeding-care-boundary`. It consumes no time or randomness on rejection.

At the care deadline, complete or cancel the owned attempt before advancing.
Interrupted or newly ineligible care still requires an explicit cancellation;
otherwise the scheduler would silently discard a pending player decision.
Cancellation releases only that care boundary, preserving the next bleeding
check. Natural cessation or death removes the episode's clock restrictions;
retained historical care may be cancelled without inventing a treatment effect.
The scheduler does not automatically resolve private rolls or heal on clock ticks.

`test_bleeding_care_boundaries` specifies offset event ordering, rejection at both
boundaries, cancellation and cross-process continuation with pending care.
It is authored and unrun, alongside the other paused validation fixtures.
