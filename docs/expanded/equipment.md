# Expanded equipment

**Status: partial.** Weapons, armour, equipment and extended numeric tables. Neutral source: `full-2008`, B16; B264-B289; B345; B550.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedRangeModifier` — B550; tested in `tests/expanded.py::test_numbers`.
- `rpgExpandedDamageDice` — B16; tested in `tests/expanded.py::test_numbers`.

The numeric interfaces below also cover size and combined speed/range. The full catalogue and remaining chapter procedures are not implemented. New boundary checks are authored but unrun.

The [task-resolution inventory](inventory/task-resolution.json) records equipment
quality, missing-item and damage modifiers separately. These depend on actual
tools and task eligibility: some tasks cannot be attempted without equipment at
all. The task-specific equipment assessment below now handles those numeric
conditions; inventory-backed availability and item-quality purchasing remain pending.


The [detailed size/range inventory](inventory/size-speed-range.json) now records all
printed B550 rows, including fractional dimensions and shape rules. The rows have
been visually compared with the reference page; this is source verification, not
a runtime test. `rpgExpandedRangeModifier` handles whole-yard lookup; the size and
combined speed/range helpers below add explicit measurement interfaces. Combat and
sensing integration remains pending, and the new boundary checks have not run.


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

## Extended measurements

`rpgExpandedDamageDice(strength, swing)` now applies B15's progression above 100:
each complete ten additional Strength adds one die to the Strength-100 result.
Thus 101–109 retain 11d thrust/13d swing, and 110 gives 12d/14d. The helper accepts
Strength through 1,000. Omitted intermediate rows between 40 and 100 still return
`unsupported-strength-row`; the inspected reference pages do not supply their
interpolation rule. This numeric helper does not bypass the existing damage
roller's 100-die limit or integrate expanded damage into every combat action.

`rpgExpandedSizeModifier(dimensionTicks, shape)` uses thirtieths of an inch, so the
printed 1/5-, 1/3-, 1/2- and 2/3-inch rows have exact integer boundaries. One yard
is 1,080 ticks. Inputs round upward to the next printed size row. Pass shape 0 for
ordinary geometry, 1 for an elongated box, or 2 for a box, sphere or blob. For
example, a four-yard dimension gives +2, +3 or +4 respectively. The author selects
the relevant dimension: normally the longest, but the shortest for an object much
thinner in two dimensions. A preassigned creature or vehicle size modifier should
be used directly rather than recalculated from descriptive measurements.

The size helper accepts 6 through 1,000,000,000 ticks. Dimensions below the first
printed row remain unsupported rather than receiving an invented extrapolation.
`rpgExpandedSpeedRangeModifier(yards, yardsPerSecond, includeSpeed)` adds speed only
when the author selects its relevance; otherwise it uses range alone. Combined
values above the existing 100-million-yard numeric bound are rejected. It consumes
no randomness and does not move the target or spend time.

`tests/expanded.py::test_extended_measurements` contains the printed size boundaries,
shape examples, speed/range examples and full-ten-point damage progression cases.
These are authored but unrun while validation is paused.

## Task equipment quality

Attach an `RpgExpandedEquipmentAssessment` to a skill context's
`equipmentAssessment` field. It describes the tools available for that operation.
Its pure `assess(skill)` returns a structured ready/blocked result and modifier.
No assessment on a context retains the previous zero equipment modifier.

Set `quality` to `none`, `improvised`, `basic`, `good`, `fine` or `best` (B345).
A missing set blocks the task unless `allowWithoutEquipment` is explicitly true;
then it gives −10 for a technology-qualified skill or −5 otherwise. Improvised
sets give −5 or −2 respectively. Basic, good and fine sets give 0, +1 and +2.
Best equipment requires an explicit `techLevel` and gives half that level rounded
down, with a minimum +2. Use the actual equipment level, consistently with any
cross-technology context modifier.

For basic-or-better sets, `missingItems` subtracts one per important missing item
and `damagePenalty` subtracts an authored value from zero through three. Applying
these condition modifiers to absent or improvised equipment is rejected, since the
source only specifies them for basic-or-better sets. The author decides which
items matter and how damage affects this particular task; item labels alone do
not determine those judgments.

`rpgLiteScore` and `rpgLiteCheck` combine this assessment with skill-use modifiers
once. An impossible missing-equipment task returns `equipment-required` before
rolling. The assessment neither spends consumables nor grants ownership of tools.
Actual inventory availability, ongoing damage state, quality purchase prices and
specific catalogue exceptions still need their owning equipment procedures.

Authored cases in `tests/expanded.py::test_equipment_quality` cover each quality,
technological versus other skills, rounding and minimum best-quality bonuses,
missing/damaged items, combined contextual modifiers, blocked checks and purity.
They have not run while validation is paused.

## Acquiring an item

Use an owned `RpgExpandedAcquisition` with `profile`, an existing physical `item`,
`available` and `permitted`. `assess()` is pure and returns an
`RpgExpandedAcquisitionResult`; `acquire()` rechecks the conditions and commits
inside the normal action transaction. The result's `money` is the amount charged,
separate from character points. The default `mode = 'purchase'` uses `item.cost`,
or an explicit `quote` for the offered price. As in the existing item contract,
this is the total price for that item instance/bundle, not a second multiplication
by its quantity. `mode = 'issue'` costs zero and rejects a nonzero quote.

A successful acquisition appends the same item instance to `profile.equipment` and
deducts money once. The receipt then returns `reused` with no charge. It cannot be
retargeted to another item or profile after commitment. Items already in any Lite
or expanded profile's inventory are rejected, preventing duplicate ownership
through another acquisition offer. The operation also validates nonnegative funds,
price, quantity and bounded total item weight before changing state.

Availability and permission are explicit authored world facts. The reference's
item technology indicates earliest availability, not a universal prohibition on
buying above one's personal level. This interface does not infer market supply,
licenses or legality from that level. Detailed legality/control interactions,
merchant-to-buyer transfers, starting-wealth allocation and sale/resale procedures
remain pending. Carried versus stored equipment uses the interface below. Existing `rpgLiteBuy`
retains its original contract; use this acquisition object for the expanded path.

`tests/expanded.py::test_acquisition` covers pure previews, affordability and
permission gates, issue pricing, inventory ownership, one-time charging, undo and
exception rollback. These authored cases remain unrun while checks are paused.

## Carried and stored possessions

An item's `storageLocation = nil` means it is carried. A non-nil authored location
means it is stored off-character. Both states retain the same item in the owner's
`equipment` inventory, so storage cannot create a second ownership or money ledger.
The default preserves existing carried-item behavior.

Use `RpgExpandedEquipmentStorage` with `profile`, `item`, `destination` and an
explicit `accessible` world fact. A `nil` destination retrieves the item. `assess()`
is pure; `move()` performs the transfer within the action transaction. It requires
ownership and access, clears worn/ready state and cancels aim associated with the
moved item. Moving to the current location is a no-op. The transfer does not specify
a universal elapsed time; an operation that includes travel or handling must
account for that time once through the shared ledger.

Stored items contribute no carried weight or worn armour protection. Combat checks
also exclude them from strikes, weapon parries, shield blocks, shield defense
bonuses and reloading, even if a stale ready/worn flag is present. Retrieval does
not automatically ready or wear equipment. Tool assessments still require their
authored availability facts; they are not yet bound to particular inventory items.
Container nesting, storage capacity and other owners' custody remain pending.

Authored cases cover ownership-preserving storage, retrieval, weight/protection,
stale equipment flags, attack/reload/shield exclusion, access rejection, undo and
cross-process save continuation. The restored acquisition receipt also prevents a
second charge. See `test_equipment_storage` and `test_equipment_persistence` in
`tests/expanded.py`; these checks remain unrun.
