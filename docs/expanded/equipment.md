# Expanded equipment

**Status: partial.** Weapons, armour, equipment and extended numeric tables. Neutral source: `full-2008`, B16; B264-B289; B345; B550.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedRangeModifier` — B550; tested in `tests/expanded.py::test_numbers`.
- `rpgExpandedDamageDice` — B16; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

The [task-resolution inventory](inventory/task-resolution.json) records equipment
quality, missing-item and damage modifiers separately. These depend on actual
tools and task eligibility: some tasks cannot be attempted without equipment at
all. The existing numeric helpers do not implement this equipment assessment.


The [detailed size/range inventory](inventory/size-speed-range.json) now records all
printed B550 rows, including fractional dimensions and shape rules. The rows have
been visually compared with the reference page; this is source verification, not
a runtime test. `rpgExpandedRangeModifier` still handles only whole-yard lookup,
not size calculation, fractional units, target-speed selection or sensing rules.
Those integrations and independent boundary tests remain pending.


[Signature and transformed equipment](inventory/traits-catalogue-k.json) needs
identity-based ownership and disposition. Voluntary disposal of signature equipment
removes its invested value; blameless permanent loss permits either replacement or
point return, with an authored recovery opportunity first. Shrinking equipment
returns to normal size when put down, potentially changing occupied space. The
existing numeric equipment helpers do not provide these lifecycle rules.


## Purchasing and weapon data

The [equipment procedure inventory](inventory/equipment-procedures.json) records
living and wardrobe costs, legality, technology eligibility and weapon-field
semantics. Starting funds, issued possessions and household assets must share the
existing ownership and money model. Travel lodging and included clothing must not
be charged twice through overlapping living and item expenses.

Weapon definitions need separate physical items and attack modes. Loaded mass,
reload mass, individual loading, rated strength, hand requirements, reach changes,
parry restrictions and mounted use all have distinct meanings. A missing field is
not zero. Existing numeric helpers do not implement these rules or the item tables;
source review, catalogue definitions and executable integration remain pending.


The [first melee catalogue segment](inventory/melee-catalogue-a.json) records the
visually reviewed B271–B272 rows, with individual attack modes and the shared B274
notes. Blade quality, readiness, electrical contact duration, thrown modes and
weapon-specific defense penalties remain executable requirements. Multiple skill
uses must refer to one owned item, not duplicate purchases or mass. Later melee
rows and cross-skill identity reconciliation remain pending.
