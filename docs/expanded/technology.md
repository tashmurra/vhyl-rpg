# Expanded technology

**Status: partial.** Electronics, inventions, artifact investigation, object damage,
maintenance and repair. Neutral source: `full-2008`, B471–B479; B483–B485; B529–B533; B546.

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json) · [Procedure inventory](inventory/technology.json) ·
[Outcome tables](inventory/technology-outcomes.json)

Include `vhyl-rpg-expanded-technology.t` after the expanded foundation and equipment. The current
runtime provides pure object-capacity, injury-threshold and disabled-weapon assessments, plus owned environmental breakdown checks. Other inventoried
procedures remain pending, including object damage, actual piece creation,
maintenance, repair and invention projects.

## Object capacity and injury thresholds

`rpgExpandedObjectCapacity(weightHundredths, construction)` implements the detailed
B483 capacity formula for `unliving` and `homogenous` objects, using multipliers
four and eight respectively and rounding up. Integer cubic comparisons avoid
floating-point errors at exact cube boundaries. Weight ranges from one hundredth
of a pound to 10,000 pounds; other constructions and values outside that numeric
range reject explicitly. Author adjustments for unusually fragile or robust
objects remain separate from this baseline.

`rpgExpandedObjectInjury(capacity, priorInjury, injury)` takes final injury after
protection and material-specific injury effects. It returns remaining HP, newly
crossed destruction-check multiples one through four, the automatic destruction
boundary at negative five times capacity, the need for stress checks at nonpositive
HP, eligibility for author-selected reduced effectiveness below one third, and
whether this single injury exceeds half capacity. Equality at one third or one
half does not trigger those strict thresholds.

These are assessments, not committed object damage. A threshold list identifies
possible checks; it does not authorize rolling for an object already destroyed
or continuing to roll after destruction. Under-stress checks occur once per second
of actual use, not once per damage call. Reduced effectiveness and major-damage
subsystem failures require concrete authored consequences. Sentient-machine health,
material injury tolerance, shock, persistent disablement and destruction remain
unfinished. No generic callback is counted as implementing those decisions.

`test_object_capacity` records exact cube and adjacent-weight expectations.
`test_object_injury_thresholds` records strict boundaries, multiple crossings and
non-repetition of an already crossed threshold. Both fixtures also assert zero
random draws and elapsed time. They are authored and unrun.

## Disabled and destroyed weapons

`rpgExpandedBrokenWeapon(state, weightHundredths, missile, family, die, reach)`
assesses the B485 broken-weapon procedure without changing inventory or consuming
dice or time. `state` is `disabled` or `destroyed`; weight uses hundredths of a
pound. Destroyed weapons, disabled missile weapons and disabled weapons weighing
at most one pound are unusable without a die roll. Supply `nil` for `die` in those
cases; an unused die is rejected.

Other disabled weapons require a supplied die from one through six. A missing die
returns `needs-roll`. Supported families are `axe-mace`, `polearm`, `rapier`,
`smallsword`, `spear`, `sword`, `saber` and `two-handed-axe-mace`. Unlisted forms
return `broken-weapon-analogy-required`; the author must establish the closest
listed form before assessment. The caller establishes whether the weapon was
actually disabled or destroyed; a critical-miss label alone is not that evidence.

The result distinguishes unusable outcomes from surviving pieces. Each
`RpgExpandedBrokenPiece` names its new `form`, held/ground `placement`, and any
attack, reach or damage overrides. New forms use their own skill and catalogue
statistics. `nil` means the procedure does not override that statistic, not zero.
Sword/saber remnants instead retain the original form: cutting damage loses two,
thrust becomes ordinary thrust crushing, and reach two becomes one. These overrides
must replace incompatible old modes rather than leaving an impaling attack usable.

This assessment does not create pieces, rebind hands, divide weight, alter money,
apply object injury or repair anything. Those owned transformations remain pending.
There is no generic callback counted as implementing them. The minimal
[technology fixture](../../tests/fixtures/expanded-technology.t) and
`test_broken_weapons` record all six die faces for each family, light/missile and
destroyed exceptions, missing dice, unknown forms, piece modifiers and preview
purity. Fixtures are authored and unrun while checks are paused.

## Equipment operation

Communicators need a medium, format, range and operating skill. Sensors need an
actual sensory effect, operating position, hands and action requirements. A sight,
handheld instrument and hands-free display cannot share an unrestricted passive
bonus. New senses use sensor-operation skill, while improvements to an existing
sense normally use its ordinary check. Active scanning also exposes the emitter
to detection.

Computers need separate processing and storage capacities. Concurrent programs
consume weighted processing capacity: a host that can run two programs at its own
complexity can instead run one at that level and ten at the level below. Software
availability, licenses, required task support and equipment bonuses are separate
properties. A terminal does not grant access to another host without a valid
connection, compatibility and the required credentials.

## Invention projects

An author must approve a proposed function, mechanism, technology level, difficulty,
required skills, facilities and retail value before the project can spend resources.
The proposal is a concrete design contract; an arbitrary result callback is not a
substitute for it. Ordinary, cinematic and rapid invention have different eligibility,
modifiers, durations and cost procedures. Cinematic options require both campaign
permission and the relevant purchased capability.

A project must retain participants, concept state, facilities, prototype attempts,
bugs, testing history and production work. Flawed theories and undiscovered bugs
are private world state; preview must not reveal them. Each prototype attempt spends
its own time and materials, while suitable facilities can be reused. For cinematic
invention, advanced prototype prices accumulate doubled terms: a native price of
4,000 at three levels above the campaign becomes 4,000 + 8,000 + 16,000 + 32,000 =
60,000. Charging only the final term would underprice both prototypes and production.

Funding can create patron obligations, work without income or investor ownership.
Those consequences belong in campaign accounting. They must not become anonymous
currency grants that disappear on save or rollback.

## Investigation and unusual effects

Unknown-device investigation tracks attempts and discovered controls separately for
each experimenter. A suitable analogous skill can help without being the device's
actual operating skill. The result table can reveal a control, teach a function at
a penalty, create a false theory or trigger a real effect. Revealing a control must
not automatically reveal its purpose or every hidden function.

Each defect and side-effect row needs an executable effect or a specific tested
author contract. Such contracts must identify targets, damage treatment, phenomena,
destinations, timing and recovery where applicable. Persistent effects include
resource consumption, cooling, preparation, repair requirements, temporary penalties,
transformations and accumulated disadvantage points. Random encounters and
inter-world gates require campaign integration; swarms require creature integration.

The inventory leaves unresolved details explicit, including fractional bug counts,
exhausted investigation outcomes, repeated random-effect expansion and recovery from
some electronic disruptions. These are not implemented by accepting an unrestricted
narrative string or silently omitting the effect.

## Damage, maintenance and repair

Objects distinguish damage capacity, reliability, injury treatment and component
function. A disabled object may be partly usable; a destroyed one is ordinarily
irreparable. At zero capacity, reliability checks occur during actual stress, not
while the object is idle. Sentient machines and ordinary inanimate objects also
have different stun and defense behavior.

Repairing damage, restoring maintenance-related reliability loss and clearing a
malfunction are separate operations. They share the object's state, technician time,
parts and currency accounts. Restoring damage capacity must not erase unrelated
maintenance penalties or repair every disabled component. Each lost reliability
point requires its own major repair under the reference procedure.

The optional shield-damage rule needs the actual defense calculation: it triggers
when the shield's bonus changed failure to success, including defenses other than
blocking. Disabled shields still weigh something. Broken weapons can produce held
and dropped pieces with new attack profiles, so breakage must update inventory and
world position atomically.

## Transit hardware

The [world-transit inventory](inventory/world-transit.json) assigns generators,
controls, pulse banks, projectors, detectors and technical search procedures to this
module. Campaign owns routes, windows, arrivals and world consequences. Vehicle
integration owns the mobile hull where present; a stationary capsule does not need
invented driving statistics.

A generator's rated mass includes its supporting systems and cargo. At two tons,
the listed pulse requirement is 400 kilojoules; its listed storage system weighs
2,000 pounds and costs 20,000 before adding the hull, generator or other equipment.
This is a capacity calculation, not a complete vehicle design. Fixed controls also
cannot become programmable merely because the operator knows another destination.

Detectors distinguish bearing, triangulation, source type and source-world analysis.
They need actual range, recording and analysis time. Knowledge of the arrival's band
does not supply its precise world coordinates. Penetrating damage can disable transit
hardware without destroying the hull; restoring the hull alone must not clear that
separate fault.

## Required validation

Independent examples must cover processing-capacity mixtures, sensor action limits,
all invention cost/time categories, secret flawed theories, testing outcomes,
production, each result-table row, repair price bands and every broken-weapon branch.
Object cases must include stress-only checks, subsystem failures, collapse, shield
penetration, reliability loss and repair eligibility.

Combined fixtures must cover vehicle damage, creature or machine characters,
magical side effects, resource consumption over time and private knowledge.
Preview purity, deterministic replay, rollback, undo and save continuation need
ongoing projects and damaged objects, not only isolated arithmetic. Checks remain
suspended while implementation continues; none of this new inventory is claimed
as tested runtime behavior.

The [durability inventory](inventory/object-durability.json) adds the B557–B559
object, structure and cover tables. Weight lookup and the optional cube-root
formula are separate selection policies. Door and wall values apply to a section,
while building values describe the whole structure. An object’s own armor is
also distinct from the protection its thickness provides as cover.

Repeated attacks can erode armor at a specific small spot. That damage must keep
its position, material floor and damage-type history instead of reducing every
surface of the object. Some source details remain unresolved, including the
wallboard erosion floor and rounding for calculated building capacity. The table
values have been visually compared with the supplied printing; this does not
establish runtime implementation or test coverage.


## Owned environmental breakdowns

`RpgExpandedBreakdown` implements the B485 environmental-failure check for an
item explicitly marked `requiresMaintenance = true`. Set a unique `id`, `item`,
`trigger` (`careless-exposure` or `extreme-day`), and `evidence` identifying the
world event. `artifactHT = nil` uses ten; otherwise supply the item's reliability.
`maintenanceHTLoss` reduces that value. Maintenance schedules and accumulated loss
are not generated by this operation and remain an unfinished subsystem.

The check uses current reliability plus four, optional `dailyCleaning` (+1), and
`brutality` (zero, minus one or minus two). Cleaning qualification and environmental
severity are explicit author facts. Scores outside the supported 3–1000 range
block before drawing dice. `assess()` is pure; `apply()` draws one three-dice check
and stores it in the item's `environmentFailures`. Success leaves operation intact;
failure sets `environmentFailure` to the receipt, requiring minor repair, or major
repair on a critical failure. It does not spend time: the exposure or world clock
has already established the event. Repair attempts use the owned repair request and major-repair parts record below.

While a failure is active, `usableBy()` returns false and existing attack, parry,
block and equipment-operation hooks retain that restriction. The inherited storage
restriction still applies. Neither price nor weight changes. This API does not
clear readiness, erase contents, destroy the object or apply personal injury.
An already failed item rejects further exposure checks until its fault is repaired;
it does not silently upgrade an existing fault.

An extreme-day receipt prevents another such check for that item on the same
`floor(rpgLedger.seconds / 86400)` day. Careless exposure is a separate event and
can require an additional check that day. Authors must use one stable event ID per
actual exposure; changing IDs is not permission to reroll the same incident.
Automatic world scheduling and other calendar origins remain pending.

Run commits in the enclosing action transaction. Request bindings and historical
results survive save/restore. Replays do not draw again or reapply failure. The
library emits no player-facing notification; authors can keep the malfunction
private until operation reveals it, as the source permits. Concrete diagnosis and
structural repair interfaces remain outstanding.

The [breakdown fixture](../../tests/fixtures/expanded-breakdown.t) supplies
`test_breakdown_transactions`, `test_breakdown_days` and
`test_breakdown_persistence`: ordinary success, minor/major failures, reliability
loss, severe conditions, invalid applicability, preview purity, rollback, undo,
daily deduplication, distinct exposure checks, storage coexistence and separate
process continuation. These fixtures are authored and unrun.


## Environmental-fault repair

`RpgExpandedBreakdownRepair` repairs one active environmental `failure`. Supply a unique
attempt `id`, `repairer`, a suitable `skill`, `approvedSkill = true`, `evidence`
identifying why that skill and the available tools apply, and
`uninterrupted = true`. Skill suitability is an explicit author decision for this
specific item and fault, not permission to repair every device with one skill.
`equipmentModifier` records the established tool adjustment. Nonpositive repairer
HP or fatigue and incapacitation reject; interrupted work and accelerated attempts
remain unsupported.

`assess()` checks eligibility without time or dice. `apply()` spends 1,800 seconds
on the shared ledger and makes one contextual skill check, including the B484
original-price modifier. Success clears this item's active environmental fault and
records `failure.repairedBy`; failure leaves it active. Each attempt remains in
`failure.repairs`. A failed attempt can be followed by a new ID, but replaying an
old attempt never spends time or rolls again. Replaying the original breakdown
after successful repair does not disable the item again. Run the operation inside
the existing action transaction, including its time advancement.

This repair targets a malfunction, not structural HP, maintenance-related HT loss,
a severed part or another subsystem. Those require separate repair records. It
does not restore the item's readiness or move it out of storage. `item.cost` must
represent original price for this procedure, rather than a resale valuation.

`rpgExpandedRepairPriceModifier(price)` covers the price bands.
`rpgExpandedRepairPartsPrice(price, die)` quotes one through six tenths of original
price, rounding up to the inventory's whole monetary unit. The latter is pure: it
neither purchases nor consumes parts. The owned package below performs those steps.
Major faults without a quoted parts record return `breakdown-major-parts-unavailable` before time or randomness.

`test_repair_prices`, `test_breakdown_repair` and
`test_breakdown_repair_persistence` cover price boundaries, partial-unit rounding,
preview purity, rollback, undo, failed attempts, retry costs, replay and separate
process continuation. They are authored and unrun while checks remain paused.


## Major-repair parts acquisition and installation

`RpgExpandedRepairParts` binds one parts quote to a major environmental fault.
Supply `failure`, an expanded-profile `payer`, `evidence` describing the suitable
parts, their authored `weight` in hundredths of a pound, and explicit `available`
and `permitted` supply facts. `assess()` is pure. `quote()` rolls one die once,
records the original device price and creates a single physical package. The fault
accepts only one quote, preventing another request from rerolling its price.

`purchase()` uses `RpgExpandedAcquisition` and the payer's existing money and
inventory. Insufficient funds block without another die roll. Availability and
permission are rechecked before acquisition; replay of a paid purchase never
charges again or recreates inventory. The quote can be obtained before the payer
has sufficient funds. Quoting and purchasing spend no implied travel or shopping
time; the encompassing world action owns those costs.

The first major-repair attempt preflights the purchased package's presence and
accessibility, then installs it within the same action transaction. Installation
removes its carried inventory entry once. It remains linked to this fault and is
reused after a failed attempt, rather than charging new parts on each retry. A
major attempt uses the ordinary half-hour procedure with an additional minus two
skill modifier. Success clears the fault; it does not restore unrelated structural
HP, maintenance loss or disabled systems.

The package, quote die, cost, payer, acquisition receipt and installation state
persist with the fault. Changed supply evidence, item identity or pricing mode is
rejected. Parts for a different fault cannot satisfy this one. Repairs still need
an approved skill, suitable equipment and uninterrupted work; source rules for
ordinary structural damage and multiple distinct faults remain unfinished.

`test_major_repair_parts` covers quote rollback and replay, affordability, purchase
rollback and replay, package weight in inventory, installation rollback, failed
repair followed by success, and no repeated payment or installation. It is authored
and unrun. `test_major_parts_preflight` additionally covers a competing quote,
unpurchased or stored parts and duplicated inventory entries; those reject before
repair time or dice. `test_major_parts_persistence` saves at five stages (before
quote, quoted, purchased, installed after failure, repaired) and continues in a
new process. Historical replay must retain money, inventory, repair state, dice
and time. These additional fixtures are also authored and unrun.


Maintenance schedules must incorporate the B143 cross-reference as well as B485:
a missed installment loses one HT and requires a further HT roll, with concrete
additional incapacity or potentially fatal outcomes supplied by the author. The
[trait price helpers](traits.md#maintenance-staffing-and-frequency-prices) cover
staffing/frequency accounting only. The existing `maintenanceHTLoss` input is not
an implementation of that missed-service procedure or its recovery.

## Computer processing reservations

`RpgExpandedComputer` owns installed `copies` and process `runs`. Set its physical
`item`, `complexity` and `powered` state. `RpgExpandedSoftwareCopy` identifies one
host-bound installed copy, its complexity, an explicit `approved` authorization
and evidence. These declarations do not purchase software, grant network access
or create skills. A licensed copy can support multiple simultaneous instances;
no new purchase is charged for each process.

`RpgExpandedProgramRun` has a unique `id`, `host` and installed `copy`. `assess()`
checks power, environmental failure, copy authorization and processing capacity
without mutation. `start()` reserves capacity; `stop()` releases it once. The
host retains the history and timestamps, so replaying a stopped run's start does
not restart it. A new execution needs a new instance ID. Stop remains possible
when the machine is unavailable so reservations can be cleaned up explicitly.

The B472 capacity rule uses exact integer units: each complexity step costs ten
times the previous one, and a host has twice the units of its own complexity.
Complexity two can therefore run one complexity-two program plus ten
complexity-one programs. A program above the host's complexity is rejected even
if its reservation could otherwise be represented. Supported complexity values
are zero through eight; values outside that numerical range reject explicitly.
`rpgExpandedProcessingUnits()` exposes the pure conversion.

The host rejects duplicate instance IDs and invalidated copy bindings. It derives
used capacity from active owned records rather than a separately mutable counter.
The API consumes no dice, money or time; an authored operator action owns its
actual interaction cost. Each mutation belongs in that action's transaction.
Power loss prevents new starts but does not silently erase reservation history.
World simulation of process execution, crash recovery and device destruction
remains to be implemented.

`test_computer_reservations` and the [computer fixture](../../tests/fixtures/expanded-computer.t)
cover preview purity, start/stop rollback, undo, host limits, a mixed workload,
capacity rejection, historical replay and release/reallocation. They are authored
and unrun. Software purchase, equipment bonuses, task
prerequisites and network permissions remain unfinished; processing reservations do not substitute for those systems.

## Ordinary terminal switching

`RpgExpandedTerminal` declares a `controller`, an explicit list of connected
`hosts`, the initially selected `current` host, and its `powered` state. These are
world facts established after connection and authorization; adding a host to the
list is not a substitute for resolving compatibility, addresses or credentials.
The current implementation supports the ordinary one-host-at-a-time terminal.
Special hardware for simultaneous human access remains unsupported.

`RpgExpandedTerminalSwitch` owns one selection request with `id`, `terminal`,
`target` and `evidence`. `assess()` rejects disconnected or unavailable targets,
unpowered terminals and unsupported incapacitated/nonpositive-HP-or-fatigue
controllers before spending time. `apply()` changes the selected host and charges
one second through the existing clock. Selecting the already current host charges
zero seconds. There is no new interaction roll and no effect on either host's
processing reservations.

The request records the previous host, selected host and completion time in
`terminal.switches`. Replay is historical: it does not switch back after a later
selection or charge another second. Mutating a recorded request's controller,
target or evidence rejects. This currently binds a terminal to its authored
controller; handing it to someone else needs a separate lifecycle operation.
Run switches within the enclosing action transaction.

`test_terminal_switches` covers preflight, disconnected and unpowered hosts,
zero-cost repeated selection, rollback, undo, processing-state preservation and
historical replay. `test_computer_persistence` saves mixed workloads before and
after a switch, process stop and return switch, then continues in a separate
process. These fixtures are authored and unrun. Terminal switching does not yet
supply network connection establishment, task-specific software use or data transfer.

## Owned computer data storage

Set a computer's `storageMB` independently of its processing complexity.
`rpgExpandedStorageMB(amount, unit)` converts whole `MB`, `GB` or `TB` using the
B472 decimal convention (1,000 MB per GB and 1,000 GB per TB). The numeric limit
is one billion MB. Sub-megabyte quantities are unsupported rather than silently
rounded; authors must use an explicit aggregate for collections of small files.

`RpgExpandedStoredData` declares a unique `id`, `host`, an authored content
`reference`, `sizeMB`, `approved` permission and evidence that the data is available
with that size. `assess()` is pure; `store()` reserves space only if the host is
powered, operational and has room. The record describes fictional content. It
never opens the reference as a path or URL and does not copy real files.

The host derives used space from present records in `data`. Removal marks the
record absent and releases its capacity, retaining identity and timestamps for
replay. A historical `store()` call cannot recreate removed data; a new allocation
needs a new ID. Repeated removal releases nothing further. Changed reference,
size, host or evidence rejects. Store/remove operations belong in the enclosing
action transaction and consume no implicit bandwidth, elapsed time or randomness.
The author must separately resolve the action that produces, copies or transfers
that content, including permissions and time.

This storage ledger does not use processing capacity. Conversely, running a
program does not invent its storage size. Streaming recorder rates, removable
media, software installation size, network transfer, backup and destruction-driven
data loss remain unfinished integrations. Current removal requires a powered,
operational host; external media operations are not silently approximated.

`test_computer_storage` covers decimal units, exact capacity, unavailable hosts,
rollback, undo, historical replay and independence from running software.
`test_computer_storage_persistence` resumes four allocation/removal stages in a
separate process. Both use the computer fixture and are authored but unrun.


`rpgExpandedReferenceDataMB(category)` supplies the B472 reference-size rows using
neutral category IDs: `long-text`, `national-road-map`, `regional-navigation`,
`vehicle-plans`, `global-navigation`, `small-library`, `city-library`,
`large-library`, `research-library` and `human-mind`. They range from 10 MB to
100 million MB. Vehicle plans represent the source's collection of one hundred
small or ten complex vehicles. These are storage estimates, not generated content,
a navigation capability or a procedure for creating or copying a mind. All rows
have authored expectations in `test_computer_storage`; those checks remain unrun.
