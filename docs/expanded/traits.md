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

**Status: partial.** Trait catalogues, modifiers, benefits and restrictions. Neutral source: `full-2008`, B32-B166.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedModifiedCost` — B101; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.
