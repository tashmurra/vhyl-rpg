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
major, while a shock-producing face wound still requires a check. Eye and limb
injuries reject because their crippling procedures are not implemented here.
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

The supported subset requires standard humanoid anatomy, excludes eye/limb
crippling and the listed injury-tolerance/pain-sensitivity traits, and blocks a
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
