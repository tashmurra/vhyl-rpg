# Expanded health

**Status: pending.** Injury, treatment, recovery, fear consequences and fatigue. Neutral source: `full-2008`, B360-B361; B418-B429; B552-B553.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename is reserved in the catalogue only; do not include it in a game.

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
