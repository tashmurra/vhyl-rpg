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
licenses or legality from that level. The campaign module supplies legal-access checks and starting-wealth allocation.
Agreed merchant transfers use the interface below; contextual sale/resale pricing
remains partly implemented in the social module. Carried versus stored equipment uses the interface below. Existing `rpgLiteBuy`
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


## Starting equipment and technology

Set `startingPurchase = true` on an acquisition during character creation to use
full-2008 B27 prices. Supply the item's `techLevel` and its unadjusted `cost`.
Generic items default to an unknown technology level (`nil`); weapons retain their
existing declared level. A starting purchase without a known level is rejected.
Each level above `profile.campaignTL` doubles the base price; a lower level never
reduces it. Personal technology affects access through authored world facts, not
the multiplier. The pure helper `rpgExpandedStartingEquipmentPrice(basePrice,
itemTL, campaignTL)` exposes the same calculation with overflow rejection.

Starting purchases require purchase mode, no separate `quote`, and an unfinished
creation profile. This prevents multiplying an already adjusted market quote.
After creation, use an ordinary acquisition with an authored price and explicit
availability/permission. A previously completed receipt remains reusable without
another charge even after creation ends. All purchases use the existing money and
inventory ledgers; the price calculation spends no time or randomness.

`tests/expanded.py::test_starting_equipment_price` covers the printed five-level
price example, equal/lower technology, bounded arithmetic, pure assessment,
creation restrictions, quote ambiguity, personal-level independence and repeated
acquisition. These cases are authored and unrun while checks are paused.


## Transfer an agreed trade

`RpgExpandedTradeTransfer` commits a sale of an existing physical item or bundle.
Set its unique `id`, `buyer`, `seller`, `item`, agreed `price`, `buyerAgrees`,
`sellerAgrees`, `available` and `permitted`. The price is for the whole item/bundle,
not per quantity. It may come from a ready, non-refused social trade assessment;
the author freezes the agreed quote here rather than rerolling during purchase.

`assess()` verifies exactly one inventory occurrence, owned by the seller, as well
as consent, availability, permission, bounded weight and both money balances.
`transfer()` moves the same object to the buyer, transfers the price once, clears
storage/worn/ready state and any aim using the item, and saves a buyer receipt.
The buyer now carries the item. No time or randomness is consumed; transport and
handling time remain part of the encompassing authored operation. Partial bundle
sales and nested containers are not represented by this operation.

Receipts are `[id, seller, item, price]` in `buyer.tradeReceipts`. A new transfer
object with the same buyer and ID cannot repeat the payment or movement. IDs
cannot be reused for different sellers/items. Claimed transfer objects cannot be
retargeted. The campaign module optionally adds `legalAccess`, bound to the buyer
and item, using the same legality policy as acquisition. The permission fact must
also cover any seller-side restrictions in the authored jurisdiction.

`tests/expanded.py::test_trade_transfer` covers pure preview, consent/access/funds,
sole ownership, local prohibition, movement and payment, rollback, undo and repeat
execution. These authored checks remain unrun while checks are paused.


## Forced drops from injury

The health module can request a concrete `RpgExpandedKnockdownDrop` plan through
`profile.prepareKnockdownDrop(destination)`. It captures carried, ready, non-worn
items without moving them. Wound resolution commits the prepared plan only on a
failed knockdown check, using the same storage-location and inventory fields as
ordinary transfers. Unlike voluntary storage movement, a forced drop remains
valid when the injury leaves its owner unconscious. The plan clears affected aim
state and is retained by the wound receipt. Authors provide the actual receiving
location; inclusion does not guess one. See the [health integration](health.md).

The shared `rpgExpandedDamageDice` lookup is defined in the expanded foundation.
Equipment includes and callers retain their existing API; creature assessments
can reuse the identical table without including the equipment library.


## Digging-tool catalogue and work integration

`rpgExpandedDiggingTool(id, kind)` creates one unowned `RpgExpandedDiggingTool`
from full-2008 B289. Supported kinds are `pickaxe` (TL2, cost 15, weight 8 pounds)
and `shovel` (TL1, cost 12, weight 6 pounds), both legality class 4. Internal weights
use hundredths of a pound. The factory supplies no inventory ownership or free
money. Use `RpgExpandedAcquisition` with the same item, availability and permission
facts to buy or issue it through the existing ledger. Starting-purchase technology
adjustments and authored quotes remain the acquisition operation's responsibility.

Catalogue statistics are validated before acquisition and digging use. Quantity
is one physical tool; create separate instances for separate workers. Put a local
price adjustment in the acquisition quote rather than changing the baseline cost.
The base item's new `validateAcquisition()` hook does nothing for existing generic
items, preserving their existing behavior.

The printed entry does not establish a tool's material. Before using it in digging,
set `diggingMaterial` (`metal`, `wood` or `improvised`) and `materialEvidence` from
an authored inspection or world fact. These facts must match the digging-hour
request. `diggingUseReason(role, material)` rejects a pick used as a shovel or an
unsupported material claim. Existing generic items retain their authored role
contract through a default no-op hook. Stored or otherwise unusable tools still
fail the normal inventory availability check.

`expanded-digging-equipment.t` specifies both catalogue profiles, shared money and
carried weight, purchase/work replay, rollback, undo, saved continuation, missing
material evidence, wrong roles, storage and changed catalogue statistics. Assertions
remain unrun. Wear, breakage, repairs, weapon use and altered item variants remain
separate unfinished integrations; these tools do not supply a universal skill bonus.

## Owned equipment pickup

`RpgExpandedEquipmentLift` picks up one already owned, stored item outside combat,
using the exploration module's B353 lifting assessment. Both modules depend on the
foundation, whose `rpgExpandedLiftingRules` hook blocks with
`lifting-exploration-required` if exploration is absent. No circular include or
second inventory is introduced.

Supply a stable `id`, expanded `profile`, owned `item`, non-nil `sourceLocation`,
`mode` (`one-hand` or `two-hands`), `accessible`, `freeHands`, `approved`, and
nonempty `evidence`. Establish that the object can be gripped and lifted normally;
unwilling creatures, anchored objects and combat pickup require other procedures.
The requested bundle's actual weight must fit the mode, and the combined carried
load must remain within ten times basic lift. Overload execution is still pending.

If anatomy is installed and defined, set `hands` to the actual one or two hand
objects. The health hook validates ownership, functional arms/hands, distinct
bindings and occupation by carried ready/worn gear. With no defined anatomy,
`freeHands` and the authored evidence establish hand availability. Physical
incapacity and exhausted actors block before time is spent.

`assess()` is pure. `apply()` spends one, two or four seconds according to the load, then rechecks the request,
ownership, location, health, hands, weight and lifting capacity. A changed condition
throws so the surrounding transaction rolls back the elapsed time. Success clears
`storageLocation`, leaves the item unready and unworn, and records the lift in
`profile.liftingReceipts`. Ownership and quantity remain unchanged. The normal
inventory weight calculation now includes the item. This is pickup into carried
inventory, not sustained gripping, weapon readiness or a movement operation.

Replaying the same operation reuses its receipt without spending more time or
picking up an item again after a later storage action. A new physical pickup
requires a new operation ID. Do not also call the low-level storage operation or
charge another pickup duration for this action.

The fixture specifies preview, one-/two-hand limits, disabled-hand rejection,
post-time interruption rollback, undo, replay and separate-process save
continuation. Assertions remain unrun. A resolved lifting-skill attempt can now be attached through `skillAttempt`; see
[trained capacity](exploration.md#applying-trained-capacity-to-a-pickup). Combat Ready
sequences, failed-attempt timing, cooperative lifts, overload, sustained gripping and parser/dialogue routing remain
incomplete. Source: full-2008, B353.

### Committing a complete skill-assisted attempt

Use `assessAttempt()` and `attempt()` when the action includes the lifting roll
and its physical outcome. Before resolving the roll, supply `failedAttemptSeconds`
and nonempty `failureTimingEvidence`. The supplied reference gives two-/four-second
successful lifts but does not explicitly specify unsuccessful strain duration.
Failure timing is therefore a required author adjudication, not a new fixed source
rule. The cabinet/crate fixture uses an authored four-second failed attempt.

Assessment checks physical eligibility, skill eligibility and both possible clock
advances without rolling. Missing failure timing blocks with
`lifting-failure-timing-required`. Execution resolves the owned skill once. If its
capacity suffices, the ordinary pickup path spends the successful duration and
transfers the item. Otherwise it spends the declared failure duration, leaves the
item stored, and records a resolved result with `pickedUp = nil` and
`reason = 'lifting-capacity'`. Success records `pickedUp = true`.

Both outcomes own one lifting receipt. Calling either `attempt()` or `apply()`
again reuses the recorded result; a failed attempt does not become a free retry.
A genuinely new physical attempt requires a new lift and skill-attempt identity.
A changed condition during the elapsed interval throws, rolling back time, the
skill roll and all receipts when executed in the same transaction. Authors should
use this combined operation for parser, structured and dialogue action paths.

Fixtures cover missing timing before RNG, success, failure, joint rollback, undo,
replay, an interruption during failure and saved failed-attempt continuation.
Assertions remain unrun. Combat lifting, cooperative lifts, sustained gripping,
overload and game-specific action routing remain incomplete.

## Owned shared carrying

`RpgExpandedSharedCarry` lifts one stored, already owned item using the exploration
module's cooperative capacity and load-distribution assessments. Supply `id`,
`owner`, `item`, non-nil `sourceLocation`, `mode` (`one-hand` or `two-hands`),
`approved` and evidence of access, grips and physical cooperation. `members` rows
are `[expandedProfile, shareHundredths, freeHands, handObjects]`. Shares must account
for the entire item exactly; the existing anatomy hook validates supplied hands
when anatomy is defined. The allocation is authored, not automatically equal.

`assess()` is pure. `lift()` advances one shared lifting interval, rechecks the
arrangement, and commits one receipt. The item remains in its owner's equipment
list; no copy is added to helpers' inventories. Its `storageLocation` and
`sharedCarry` point to the carrying operation. Each participant's `sharedCarries`
ledger references that same object, and `loadHundredths()` adds only their share.
Consequently existing encumbrance calculations see each person's actual assigned
load alongside their own gear. Post-time assessment does not reserve another
lifting interval.

Ordinary storage, trade and single-person lifting reject the item while it is in
shared carrying. Movement-requiring effort hooks reject unsupported actions while
a participant is carrying; coordinated travel and combat hand occupation are not
yet integrated. Authors must not move the object or participants through unrelated
low-level operations as a substitute for a shared movement procedure.

`lower(destination, seconds, evidence)` ends the arrangement after an explicitly
authored lowering action. The destination must be non-nil and the duration positive;
the source does not provide a universal lowering duration. The method checks
participants' ability to act and hand functionality before and after elapsed time.
It stores the destination, duration and evidence for replay, clears the active item
association, and removes every active share while retaining historical receipts.
A changed condition throws so the surrounding transaction rolls back. Emergency
drops, loss of a helper, reallocation, overloaded carrying and coordinated movement
remain pending and must be handled as explicit unsupported combinations.

Replaying `lift()` after lowering does not lift the item again. A new lift requires
a new operation ID. Altering an active allocation or item weight invalidates its
receipt rather than silently changing carried weight. The fixture specifies unequal
shares, a single owner, one time charge, transfer guards, rollback, undo, saved
active carrying and replayed lowering. Assertions remain unrun. Source: full-2008,
B353; shares and lowering duration are explicit author adjudications.

### Emergency loss of a shared load

`RpgExpandedSharedCarryRelease` records an immediate drop after an actual loss of
support. Set `carry`, affected `member`, `cause`, and a non-nil `destination`.
Supported causes are `unconscious`, `dead`, `knockdown` (lying and stunned), or
`disabled-support` (a bound hand/arm has become nonfunctional). The affected profile
must be a participant and satisfy the stated condition at first execution.

The B420 knockdown rule drops held objects, but does not determine whether the
other helpers retain a shared object or what its impact does. Consequently the
author must set `wholeLoadDrops = true` and nonempty `evidence` describing this
arrangement, plus `impactResolved = true` and `impactEvidence` describing the
settled consequences. Resolve any falling-object damage, broken contents, or
injuries through their normal procedures in the same surrounding transaction.
A harmless drop may instead have explicit authored evidence. These fields are an
adjudication contract, not an automatic damage or balance simulation. Do not mark
impact resolved merely to bypass missing consequences.

`assess()` is pure. `release()` closes the shared carry at the current event time,
clears each active weight share, and places the single owned item at the destination.
It adds no voluntary lowering time, fatigue or roll. Replays reuse the outcome,
even if the member later recovers; changing the release request rejects. The
history remains after the item is subsequently moved. This closes the otherwise
blocked lowering case when a helper is incapacitated.

The fixture covers a healthy member's rejected release, an unconscious member,
death, knockdown, missing arrangement/impact evidence, rollback, undo, saved
release continuation and recovery after release. Assertions remain unrun. Bound
support injury integration, automatic dispatch from every health event, remaining
helpers retaining/reallocating the load, and general impact damage remain pending.

### Pending support-loss events

Active shared carries now receive health notifications. `becomeUnconscious()`
records unconsciousness (or death when already declared), the shared knockdown
procedure invokes `onKnockdown()`, and a committed disabling limb wound invokes
`onBodySupportLost(part)`. Bound hands and their supporting arms are matched to the
carry's member rows. Default hooks preserve behavior when shared carrying is absent.

`supportLosses` stores `[profile, cause, eventSeconds]` once for each member/cause.
`pendingSupportLoss()` reports an unresolved recorded event, or a currently visible
loss of support. The game-time ledger rejects positive advancement with
`shared-support-loss-unresolved` while any active carry has such a loss. The health
event itself remains committed; resolve the physical load before advancing time.
No drop destination, distribution change or impact outcome is invented by a hook.

Emergency release accepts a matching recorded event even if the member has since
recovered. Recovery does not erase the need to resolve the load's fate. Release
closes the carry and clears the clock gate; the event remains in history. Use the
public health procedures when authoring incapacitation so these events participate
in the same transaction. Direct field edits are not a substitute for event dispatch.

Lowering also checks pending support loss after its time interval. Even if a
participant recovers during that interval, an unresolved event interrupts lowering
and rolls back that action's time, events and inventory changes. The support-loss
fixture includes this transient incapacitation case; its assertions remain unrun.

The new fixture covers notification, duplicate notification, rollback and undo of
the health change, blocked time before and after recovery, saved pending state,
and release allowing time to advance. Assertions remain unrun. Dedicated limb-wound fixtures now cover bound hands, parent arms, unbound hands
and combined knockdown/unconsciousness; they remain unrun. Remaining support-loss
causes, retention/reallocation and coordinated movement remain incomplete.

### Reserved hands during shared carrying

The profile's `supportReserved(part)` hook reports hands/arms used by an active
shared carry. `reservedLiftingHandsReason(hands)` prevents a new pickup or shared
lift from claiming them. Both default to no restriction without an active carry.
Health-aware equipment checks now exclude reserved supports from attacks, parries,
active shield blocks and available attack-hand counts. A different, explicitly
bound free hand remains available. With no hand mapping, active hand use is blocked
rather than silently assuming a spare hand. Passive shield defense is unchanged;
this hook controls active use, not the physical presence of the shield.

Normal lowering and support-loss detection deliberately check the support's
functionality without rejecting the carry's own reservation. Closing the carry
releases its reservation. The fixture specifies both-hand and one-hand carrying,
free-hand use, active versus passive shield behavior, a rejected strike before RNG,
and restored availability after lowering. These assertions remain unrun; broader
combat movement and automatic readiness changes remain pending. Unarmed defense
capacity now excludes reserved supporting arms, as described below.

Unarmed parry capacity now uses the same support reservations. With defined
anatomy it counts only functioning, unoccupied, unreserved arms and still respects
the fighter's authored `freeHands` limit. One mapped free arm permits the ordinary
unarmed parry but does not satisfy the two-arm requirement for the other-hand
parry. If a shared carry has no anatomical mapping, it does not assume a free
unarmed defense limb. Lowering or emergency release restores availability through
the same reservation query; no second mutable hand-count ledger is introduced.

`test_shared_hands` now specifies actual defense-score queries for these cases,
including unchanged scores before and after carrying and zero RNG consumption.
Assertions remain unrun while checks are paused.

Storage changes and committed trades call the profile's `onEquipmentUnavailable(item, cause)` hook, with `storage-change` and `transferred` respectively. The default hook does nothing. Health integration records active mobility support loss through this hook; storing or selling an aid does not itself adjudicate a fall. A storage move clears readiness even when retrieving an item, so integrations should settle pending support loss before reactivating an aid.

## Thrown release and landing

`RpgExpandedThrownRelease` owns the inventory stage of a throw. Supply an `id`
and a resolved `receipt` implementing `RpgExpandedThrowReceipt`; exploration's
`RpgExpandedThrowAttempt` supplies the concrete implementation. Its release
assessment requires permission and a throw roll. Critical failures require their
separate outcome procedure before a release can be inferred.

`assess()` verifies that the bound item still has its recorded weight, one owner,
one quantity and a ready carried state. `apply()` sets `storageLocation` and
`thrownFlight` to the release record and clears readiness. The item stays in the
thrower's inventory but no longer contributes to carried load. Aim is cleared,
and `onEquipmentUnavailable(item, 'thrown')` informs support-loss integrations.
The record is retained in `profile.thrownReleases`. Replay cannot release it twice.

While `thrownFlight` is active, storage, trade, individual lifting and shared
carrying reject the item. Positive ledger advances reject any unresolved release;
the containing action must settle flight before continuing game time. These
stages themselves spend no time or randomness. The complete throw action's
maneuver/time integration is still pending.

`RpgExpandedThrowLanding` supplies an authored resting location after the
mechanical consequences have been resolved. Set `release`, a non-nil
`destination`, `consequencesResolved = true` and explanatory `evidence`.
`apply()` clears flight state and stores the item there; it does not adjudicate
a hit, damage, a catch or ownership transfer. Replaying a landing does not move
an item that has subsequently been retrieved. The same release cannot acquire
a second landing settlement. Direct edits to flight state bypass this contract
and must not be used as a substitute for settlement.

The minimal combined fixture is `tests/fixtures/expanded-throw-release.t`.
Its rollback, undo, pending-save continuation, storage/trade exclusion,
critical-failure and replay assertions are authored but unrun.


## Capturing a successful pass

`RpgExpandedCatchCapture` takes a `receipt` implementing the foundation's
`RpgExpandedCatchReceipt`; exploration supplies `RpgExpandedCatchAttempt`.
Call `assess()` to preview and `apply()` to commit. A successful recorded catch
and an unsettled released flight are required. The recipient must still be
available, the selected hand free and functional, the item unchanged in quantity
and weight, and the thrower its sole inventory owner.

The commit removes the item from the thrower's inventory, adds it once to the
recipient's inventory, clears its flight/storage state, marks it ready and assigns
its body support to the catching hand. The capture becomes the flight settlement,
allowing time advancement. It spends no time or randomness. Replaying the same
capture returns the prior result without moving an item again; another capture
for an already settled flight is blocked. Failed catches require a separate
landing or consequence procedure. Critical consequences and interceptions remain
outside this adapter. Exception rollback, undo, duplicate rejection and save
continuation assertions are authored in `test_catch_capture` and remain unrun.

## Fishing tools for daily foraging

`RpgExpandedFishingTools` adapts an existing `RpgExpandedEquipmentAssessment` for
an exploration fishing attempt (full-2008, B195 and B345). Set `approved` and
`evidence` to identify the actual available method and tools, and assign the
assessment to `equipmentAssessment`. Its quality, missing-item and damage
modifiers are applied through the skill context. The adapter records these facts
in the attempt binding; it does not create tools or infer inventory ownership.
See [owned fishing attempts](exploration.md#owned-travel-day-fishing-attempts)
for the complete integration and authored, unrun fixture.

## Food from recorded forage yields

`RpgExpandedFoodStock` is an ordinary inventory item whose quantity counts meals.
`RpgExpandedForageHarvest` claims one positive owned forage yield into a fresh
stock, preserving single ownership and binding the source to that claim. Supply
an ID, recipient profile, source attempt, empty stock, approval and concrete
collection/transfer evidence. Per-meal weight and price remain authored facts.

Use `assess()` before `apply()`. Neither call rolls dice or spends time; only a
successful commit adds stock to inventory. Replay cannot duplicate the yield,
including after some or all of the food has been consumed. Readiness for eating
is separate from collection. See [claiming gathered food](exploration.md#claiming-gathered-food)
and [consumption](health.md#consuming-food-inventory) for integration.

## Smoking gathered meat and fish

`RpgExpandedSmokingBatch` implements the B427 preservation path for a whole
`RpgExpandedFoodStock` whose `foodKind` is `meat` or `fish`. Harvest assigns this
kind from the recorded forage method. Supply the owner, stock, a concrete
`RpgExpandedSmokingFire`, duration in seconds, approval and evidence establishing
preparation conditions and enough fire capacity for the batch. B427 specifies
neither duration nor a drying-weight conversion: duration is authored and the
operation preserves the stock's quantity and weight.

The fire records its ID, lighting time, fuel coverage deadline and supporting
evidence. Its `extinguish()` method records the current shared-ledger time once;
relighting requires a new fire record. These fields describe an actual authored
fire, not an automatic fuel purchase or fire-lighting procedure.

Call `assess()` and then `start()`. The operation owns its start and completion
times, binds the request and locks the stack against ordinary use. Advance the
existing world clock normally; `assessCompletion()` remains blocked until the
configured interval has elapsed. `complete()` requires fire coverage throughout
that interval and unchanged quantity and ownership. It marks the same food
preserved and ready to eat, releasing the lock without adding meals or charging
time again. A fire extinguished before completion prevents success; cancellation
releases the stock without granting preservation or undoing elapsed time.

Replay does not repeat processing, even after some preserved meals are eaten.
The fixture `tests/fixtures/expanded-food-smoking.t` uses an explicitly synthetic
60-second author duration to exercise boundaries, interruption, cancellation,
quantity conservation, rollback, undo and saved continuation. Assertions are
unrun. Fuel inventory, lighting, automatic cooking times, drying weight and
spoilage/shelf-life rules remain outside this operation; no values are invented
for them.

## Wilderness equipment and weather

`RpgExpandedWildernessTools` combines an existing equipment assessment with
explicit `planet`, `terrain`, `weatherPenalty`, approval and evidence. The weather
penalty is limited to 0 through -5 (full-2008, B224). It rejects a Survival
specialty that does not match the actual planet and terrain, then supplies both
weather and equipment modifiers through the shared skill context. Use it with
[daily wilderness survival](health.md#daily-wilderness-survival); this condition
record does not itself resolve care or create equipment.


## Authored local market offers

`RpgExpandedMarketOffer` separates the listed baseline from a merchant's actual
price (`full-2008`, B264). Supply `id`, the physical `item`, `market` identity,
`currency`, `baselinePrice`, `price`, approval and evidence explaining local
conditions. Before purchase, the baseline must match `item.cost`. Price adjustment
is an authored world fact; no universal shortage or negotiation multiplier is
invented. `profile.moneyUnit` identifies the existing purse's unit, defaulting to
`campaign-unit`; mismatched offers block instead of performing implicit exchange.

Assign the offer to `RpgExpandedAcquisition.marketOffer`. Availability, permission,
ownership and affordability still use the existing acquisition path. Market offers
cannot combine with raw `quote`, starting-equipment pricing or issued items.
Commit subtracts the actual offer price from the same `profile.money` and transfers
the same physical item. It leaves the listed item cost unchanged. Replay binds the
accepted offer's identity, currency, baseline, price and author facts, so later
edits cannot turn an accepted sale into a different transaction. Later changes to
the item's current baseline do not rewrite the accepted baseline or charge again.

Ordinary acquisitions without a market offer retain their existing behavior.
Currency conversion, physical coin inventories and automated negotiation remain
pending. `expanded-market-offers.t` and `test_market_offers` specify independent
baseline/offer values, currency and evidence rejection, conflicting price sources,
preview, rollback, undo, replay and saved continuation. Fixtures remain unrun.


## Optional physical silver and gold

`RpgExpandedCoinage` adopts the optional B264 convention with explicit approval,
evidence and `currency`: silver coins are worth four units, with 250 coins per
pound. The equal-weight gold coin uses an authored `goldRatio`, default twenty.
The reference describes that ratio as approximate; setting it is a campaign
choice. Copper weight is unspecified; copper requires the explicit author convention
described below.

`RpgExpandedCoinStock` is an ordinary physical inventory stack whose `quantity`
counts coins. `faceValue()` returns the stack's currency value and
`weightHundredths()` rounds its exact mass upward to the engine's hundredth-pound
unit. This last rounding is a representation policy, not a new source rule; keep
coins in one stack where possible to avoid repeated sub-unit rounding. Carried
coin mass participates in the normal inventory calculation. Ordinary acquisition
rejects coin stacks so that acquiring money requires an explicit exchange.

`RpgExpandedCoinExchange` takes `id`, `profile`, `stock`, `quantity`, `direction`
(`withdraw` or `deposit`), approval and concrete world evidence of an available,
accepting issuer/recipient. A withdrawal requires an empty unowned stack and
moves value from `profile.money` into that stack. A deposit requires uniquely
owned accessible coins, credits the same purse and removes the stack when empty.
Partial deposits preserve remaining quantity and mass. Currency mismatches,
insufficient funds, shared ownership, unavailable stock and overflow reject or
block before mutation. Approval does not invent a bank or exchange service.

Accepted exchange facts are bound to persistent receipts. Replay after partial or
complete deposit cannot mint coins again. No time, points or randomness is spent;
any travel/service procedure is authored separately. Physical value is excluded
from the abstract balance until deposited, preventing duplicate purchasing power.
Direct coin tender, change-making, copper weight and currency conversion remain
pending. `expanded-coins.t` / `test_coins` specify silver/gold value and mass,
conservation, partial/full deposits, bound convention, rollback, undo and saved
continuation. Fixtures remain unrun while checks are paused.


## Paying for equipment with coins

Set `RpgExpandedAcquisition.coinTender` to an `RpgExpandedCoinTender` naming that
same `acquisition`. Supply `coins` rows `[ownedStack, coinCount]`, optional
nonnegative `cash` from the existing abstract purse, approval and evidence that
the merchant accepts this payment. All stacks must use the purse's currency,
be uniquely owned and accessible, and appear only once in the tender. Total face
value plus abstract cash must exactly match the assessed purchase price.

The ordinary acquisition assessment still validates the item, availability,
permission, ownership and price, then assesses payment without mutation. Commit
deducts only the specified abstract cash and physical coins, removes empty stacks
and adds the purchased item in the same gameplay transaction. It never deposits
the coins into the purse first. Partial stacks retain their remaining value and
mass. Replay binds the accepted tender and cannot spend it twice, including after
an emptied stack has left inventory. Cash-only purchases keep their previous path.

This interface supports explicit exact payment for the existing merchant
acquisition model. It does not invent merchant change, exchange rates or a second
seller cash ledger. Overpayment, underpayment and issued-item tender reject;
authored merchant acceptance is required even when the denominations are valid.
`expanded-coin-purchases.t` / `test_coin_purchases` cover partial/exhausted stacks,
mixed payment, acceptance and exact-price gates, unchanged resources on failure,
rollback, undo, replay and saved continuation. Fixtures remain unrun.


### Copper with authored mass

The optional B264 copper denomination is one currency unit per coin. To use
`metal = 'copper'`, the campaign must supply `copperWeightThousandths` (positive
thousandths of a pound per coin) and nonempty `copperWeightEvidence` on its
`RpgExpandedCoinage`. There is no default copper weight: the source does not give
one. Missing weight rejects even for an empty copper stack before withdrawal.
The mass setting is an explicit campaign fact and becomes part of exchange and
payment receipt bindings.

Copper uses the same owned withdrawal, deposit and exact-tender paths as silver
and gold. One-unit coins permit wholly physical payment of odd prices without
changing the abstract purse. Stack mass rounds upward only after multiplication;
value and mass overflow checks occur before funds or inventory change. Silver
and gold retain their exact four-thousandths-pound coin weight.
`expanded-copper.t` / `test_copper` use a clearly synthetic five-thousandths-pound
copper weight to specify rounding, missing-detail rejection, physical purchase,
rollback, undo, receipt binding and saved continuation. That fixture weight is
not a reference-table value. Fixtures remain unrun.


## Starting allocation and equipment integration

Use the campaign library's `RpgExpandedWealthAllocation` before starting purchases
(`full-2008`, B25-B27/B264). It computes campaign-TL wealth and the purchased wealth
multiplier, credits only the spendable share to `profile.money`, and records
settled assets separately as nonspendable property value. Subsequent acquisitions
spend that same balance. Starting higher-TL purchases retain their existing price
adjustment; issued equipment adds its item without charging its listed price.

Allocation receipts bind the original mobile/settled choice, its approval and
recorded total/cash/assets. Replaying after purchases never replenishes cash.
Changing the wealth purchase later does not recalculate the original allocation;
changing the allocation's recorded choice or amounts rejects. No optional
starting-purchase wrapper or second purse is required: perform allocation and
purchases in the normal engine transaction when they must succeed together.
`expanded-starting-purchases.t` / `test_starting_purchases` specify the shared
balance, higher-TL charge, unaffordable purchase, issued gear, unchanged allocation
after wealth changes, rollback, undo and saved replay. Fixtures remain unrun.


## Inventory-backed task equipment

`RpgExpandedOwnedEquipmentAssessment` extends the B345 quality assessment with
`profile`, exact `skill`, `items`, approval and evidence explaining why that set
is adequate for the task. The author still classifies quality, missing components
and damage: ownership alone does not establish that a toolkit can perform surgery,
repair a vehicle or support a different specialty.

The assessment requires unique, owned, nonempty item stacks accessible to that
profile. Stored, thrown and jointly carried items block. Duplicate item references
and shared ownership reject. No-equipment assessments require an empty item list;
other quality classes require at least one actual item. The inherited no-equipment
and improvised restrictions, quality bonuses and condition penalties still apply.

Shared skill contexts call `assessFor(profile,skill)`, preventing an assessment for
one character from supplying another character's bonus. Ordinary authored
assessments delegate to their existing `assess(skill)` implementation, preserving
prior behavior. Availability is reassessed at use time and consumes no items,
time or randomness. Consumable supplies, borrowed/workshop access and purchasing
quality-specific kits remain pending.
`expanded-owned-tools.t` / `test_owned_tools` specify quality/condition arithmetic,
storage and ownership rejection before rolls, wrong-character rejection, undo and
saved continuation. Fixtures remain unrun while checks are paused.


## Permitted shared tools and fixed facilities

`RpgExpandedEquipmentAccess` owns a permission grant for one `profile`, `owner`,
`item` and `skill`, with unique `id`, approval and evidence. Both profiles are
expanded profiles. `grant()` records the permission once; optional `expiresAt`
uses the existing world clock and expires at that exact second. `revoke()` ends
permission immediately and idempotently. Permission transfers neither ownership,
weight nor money.

World integration must maintain each profile's `equipmentSite` using the game's
actual location facts. For a carried borrowed tool, recipient and owner must have
the same non-null site and the item must be usable. For a fixed facility, set the
grant's `site`: recipient must be there and the item must be stored at precisely
that site. This explicit grant permits use of the stored workshop without putting
it into the recipient's carried inventory. Thrown/jointly carried items still
block; changed ownership or duplicate inventory ownership cannot preserve access.
These site tokens are authored world facts, not automatic native movement hooks.

Use `RpgExpandedAccessibleEquipmentAssessment` with `accessGrants`. It applies
the ordinary owned checks to the user's own items and resolves exactly one grant
for each other item. The same B345 adequacy evidence and numeric quality/condition
rules apply. Every use reassesses permission, expiry, ownership and physical
access before rolling. Consumption, capacity scheduling and automatic native
movement wiring remain pending. `expanded-equipment-access.t` /
`test_equipment_access` specify carried and workshop access, expiry, revocation,
movement/ownership changes, no transfer, rollback, undo and saved continuation.
Fixtures remain unrun while checks are paused.


## Purchasing quality-specific kits

`rpgExpandedToolkitBaseline(baseCost,quality)` implements the B345 typical price
relationships: basic ×1, good ×5 and fine ×20, with overflow rejection. The source
says approximately; these become a campaign baseline only when the author adopts
them. `RpgExpandedToolkit` records `baseCost`, `quality`, `techLevel`, a nonempty
list of exact `supportedSkills`, approval and evidence. One kit is one inventory
item (`quantity = 1`), with its authored physical weight.

A `best` kit requires `exceptionalPrice`; no universal price or automatic market
availability is inferred. Other quality classes reject that extra price field.
Ordinary acquisition still checks permissions, availability and affordability;
local market offers may adjust the adopted baseline. The kit's actual cost is
charged through the same purse and its weight stays in the existing inventory.

`RpgExpandedToolkitAssessment` takes the purchased `toolkit` as its sole `items`
entry. Its quality and technology must match the item, and the task skill must
appear in the kit's supported scope. This prevents claiming a better bonus than
the purchased kit provides. Existing owned/shared-access checks, task adequacy,
missing components and damage penalties still apply. Tool-specific consumables,
physical upgrades and detailed kit catalogues remain pending.
`expanded-toolkit-purchase.t` / `test_toolkit_purchase` specify baseline prices,
purchase-to-modifier integration, unavailable/unowned use, quality mismatch,
missing exceptional price, rollback, undo and saved replay. Fixtures remain unrun.
