# Expanded traits

The [trait inventory](inventory/traits-foundation.json) begins the detailed
catalogue pass at B32–B37. It records categories, origins, activation, potential
purchases and the initial ability definitions. The existing pricing helper does
not implement these effects; their coverage remains pending.

Abilities need explicit permanent, switchable or attack behavior. A switchable
ability ordinarily changes immediately through a ready action and defaults on
during unconsciousness; an attack ability only acts through its attack procedure.
Mental and physical traits also follow different owners during body transfer,
while social identity requires a concrete campaign policy.

Potential purchases reserve character value without creating a freely spendable
point balance. Revelation, fulfillment and remaining payment have different rules
for inheritance, emergent abilities and secret traits. Hidden abilities must not
leak through preview or public accounting reports.

Condition attacks require actual resistance, effect phases, recovery and expiry.
Temporary attribute penalties have specific derived-stat exceptions. Repeated
effects normally use the worst severity; only eligible enhanced definitions can
stack. Suppression must restore the affected contribution without undoing unrelated
advancement or injuries that occurred during the effect.

Companion pricing is separate from companion agency and appearance. Adventure-level
appearance checks, invested replacement value, betrayal consequences and growth
need owned relationship records. The following catalogue pages and special
modifiers still need review before the companion definition is complete.

The [second catalogue segment](inventory/traits-catalogue-b.json) adds companion
modifiers and abilities through B42. Summoning reuses an existing companion and
retains failed-attempt deadlines. Shared-fate effects need propagation identities
to prevent cycles. Companion-granted powers retain their purchases while the link
is unavailable, rather than being deleted and repurchased.

Arm-specific attributes affect only eligible tasks and use different combination
rules for multiple hands. Accelerated subjective time adds maneuvers without
changing initiative and still respects actions that depend on another actor's
reaction. Neither feature can be represented by a blanket attribute or speed bonus.

Restraint powers own their strength, layers, damage, escape progress and retry
restrictions. Remote perception owns a viewpoint and displaced senses, while
ordinary ability ranges still originate at the body. Hidden impressions and
failed viewpoint placement require specific author contracts without revealing
private world facts through assessment. These effects remain unimplemented.

The [third catalogue segment](inventory/traits-catalogue-c.json) adds mental
compartments, contacts and protection modifiers. Mental compartments can act and
receive influence independently, but share one body and its physical limits.
Vehicle control stations likewise grant operator access without creating extra
weapons or movement capacity.

Contact availability belongs to the contact, including when several characters
share that person. Question penalties, research delays, reliability and private
information need persistent records. An abstract information score must not
silently replace the contact's actual character skills.

Protection layers retain fixed order, coverage, attack restrictions, depletion
and recovery. Absorbed damage creates temporary capability investment rather
than advancement points. Reflection applies to eligible direct hits only and
must not combine with absorption. These effects need integrated damage tests;
the existing trait-cost helper supplies none of this runtime behavior.

**Status: partial.** Trait catalogues, modifiers, benefits and restrictions. Neutral source: `full-2008`, B32-B166.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedModifiedCost` — B101; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.
