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
weapon-specific defense penalties remain executable requirements. The
[second segment](inventory/melee-catalogue-b.json) adds the remaining melee rows
and shared physical-item keys across skill uses. These uses must refer to one
owned item, not duplicate purchases or mass; runtime identity integration remains
pending.


Shield-spike values add to the host shield, and electric-prodding modes have a
linked affliction rather than a second independently fired attack. Staff and sword
skills can produce different reach, damage, parry and minimum-strength values for
the same item. Mode selection must retain ownership, damage and readiness state.
The melee tables now have a first enumeration pass, with independent fixtures and
runtime integration still pending.


The [muscle-powered ranged inventory](inventory/muscle-ranged-catalogue.json)
records rated-strength bows, launchers, thrown modes, ammunition and entangling
implements. A launcher and its projectile remain separate possessions; a thrown
weapon remains the same item used in melee. Readying and attacking can have
different hand requirements.

Material rules change quality effects, breakage, penetration and sometimes lasting
sharpness. Silver coating changes a target's matching vulnerability multiplier,
not universal damage. All listed rows have been visually compared with the source;
that does not establish runtime correctness or catalogue acceptance.

The [grenade and ammunition inventory](inventory/grenades-and-ammunition.json)
records visually reviewed thrown-device profiles, fuse preparation, cloud effects,
electronic access restrictions and optional malfunction thresholds. Fuse expiry
belongs to the armed item even after it changes hands; chemical exposure belongs
to each affected actor and the continuing cloud.

Ammunition variants alter armor penetration and wound category separately. Launcher
quality changes range while projectile quality follows its own rules. Integrated
weapon modes must share host price and mass but retain separate ammunition state.
Firearm profiles are indexed below; executable integration remains pending.

The [pistol and compact automatic catalogue](inventory/firearms-catalogue-a.json)
separates base accuracy from sight bonuses, listed weapon mass from reload mass, and
magazine capacity from chamber capacity. Automatic-only weapons and individual
loading require different action validation. Civilian variants apply only to rows
that explicitly allow them; electronics and short-range rocket adjustments bind
to the corresponding table notes. These 22 profiles remain inventory data pending
executable integration and independent fixtures.

The [long-gun catalogue](inventory/firearms-catalogue-b.json) adds 20 profiles,
including integrated launchers and shotgun pellets. A rest or deployed bipod
changes legal bracing and, for a bipod, the strength requirement. Shell expenditure
and pellet hits are separate quantities. Single-shot weapons list unloaded mass;
repeating weapons list loaded mass. Inventory changes must respect that distinction
when tracking ammunition carried, chambered and spent.

The [beam and heavy weapon catalogue](inventory/firearms-catalogue-c.json) records
21 profiles and their page-specific notes. Guided missile speed is separate from
half-damage range; some explosive launchers lose penetration rather than damage
at range. Electrical beams combine damage and resistance within one attack.
Backpack supplies, detachable mounts and host-mounted launchers need explicit
ownership and mass accounting. Missing fuel-replenishment detail and backblast
geometry remain documented author-contract requirements, not invented rules.

The [early armour catalogue](inventory/armor-catalogue-a.json) records 53 profiles
and the shared wearing procedures. Protection depends on location, facing and
damage type. Included clothing and padding are already reflected in each item;
adding them again would double-count both protection and encumbrance. Layering
requires a flexible, concealable inner piece. Worn helmets can restrict vision,
and noncombat reactions depend on whether the observer accepts the need for armour.
Equip and quick-release actions require their own persisted progress and timing.

The [advanced armour catalogue](inventory/armor-catalogue-b.json) records 28
profiles, including separately purchased inserts, visors and helmets. Active suit
power and breathing supply use separate clocks. Helmet-dependent sealing and
sensory benefits must end when the configuration changes, while passive protection
remains. Equipment-granted strength and senses are temporary contributions, not
permanent character purchases. Technology scaling applies only to marked pieces.

The [mount armour catalogue](inventory/armor-catalogue-c.json) adds 15 horse
profiles. Coverage, facing, restricted vision and movement penalties belong to
the mount. Leg armour is purchased and weighed per protected pair, with a movement
penalty for each pair. Fitting these pieces to other anatomy requires an explicit
author contract; the listed profiles do not imply universal creature sizing.

The [shield inventory](inventory/shields-and-carrying.json) separates defense
bonuses from the shield's own resistance and durability. Shield-side coverage,
attack type and the optional damage-to-shields procedure govern protection.
Holding an item is distinct from wielding it, and bucklers have different handling
from strapped shields. Offensive and defensive modes share one inventory item.

The [camping equipment inventory](inventory/general-equipment-a.json) records
47 distinct profiles and one alias. Containers have separate empty mass and
capacity; consumable quantities and operating time persist with the item. Skill
gear, tent poles, satellite signals and deployment height are prerequisites for
specific uses. Qualitative warmth or tool functions require documented author
contracts where the source does not specify a numeric effect.

The [remaining general equipment inventory](inventory/general-equipment-b.json)
records 79 profiles, including separate portable tool-kit specialties. Mount
control aids cancel penalties rather than granting unrestricted riding bonuses.
Medical kits bind to treatment and wound records; optics, communications and weapon
accessories require active use and compatible targets. Missing capacities, service
conditions and operating details remain explicit author-contract requirements.
