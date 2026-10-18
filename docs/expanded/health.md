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
arguments still describe the authored interval. Rest-period interruption rules,
physician supervision and medical treatment schedules remain incomplete; hosts
must not count ineligible activity as recovery rest.

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
Wound ownership, duplicate-treatment prevention, interrupted care, bleeding,
equipment and skill contexts, and committed time/resource use remain incomplete.
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
bleeding checks, or the subsequent shock-treatment session. It relies on authored
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
complete equipment/physiology/diagnosis contexts and treatment transaction/save
fixtures remain incomplete. Authors supply the applicable contextual modifier;
that input alone does not constitute implementation of every context rule.
`test_first_aid_treatment` provides successful and critical-failure expectations,
preview purity and repeated-request checks. It is authored but unrun.
