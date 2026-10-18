# Expanded health

**Status: partial.** Injury, treatment, recovery, fear consequences and fatigue. Neutral source: `full-2008`, B360-B361; B418-B429; B552-B553.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-health.t` after the expanded foundation. The current
implementation supplies only the B419 high-capacity shock calculation and its
integration with the existing wound ledger. Set `rules.scaledInjuryShock = true`
to select that difference; inclusion alone preserves the existing calculation.
`rpgExpandedInjuryShock(capacity, injury)` is a pure calculation for one wound:
capacity below 20 uses each injury point, while larger capacities use complete
increments of capacity/10 as the divisor. Drop fractional penalties and cap at 4.

The existing wound path adds the resulting penalty to the same `profile.shock`,
retains high-pain resistance and charges injury once. Unsupported low-pain
modification rejects before injury is committed. The hook defaults to the existing
Lite calculation when the option is disabled. No new injury or fatigue pool is
introduced. `test_scaled_injury_shock` provides independent threshold expectations
and integrated repeated-wound/resistance cases, but has not run while checks are
paused.

Detailed injury, knockdown/location effects, medical care, recovery and fear
remain pending. This option does not enable a complete expanded injury profile;
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
