# Expanded technology

**Status: partial.** Electronics, inventions, artifact investigation, object damage,
maintenance and repair. Neutral source: `full-2008`, B471–B479; B483–B485; B529–B533; B546.

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json) · [Procedure inventory](inventory/technology.json) ·
[Outcome tables](inventory/technology-outcomes.json)

Include `vhyl-rpg-expanded-technology.t` after the expanded foundation and equipment. The current
runtime provides pure object assessments, owned environmental faults and their
repairs, computer processing, storage, links, terminals, transfers, recordings and
task-scoped software equipment contributions. Owned invention stages now cover
proposals, concepts, blueprint entry, funding, work, secret completion, concrete
fault effects, whole-week testing and supported one-copy production. Object damage,
actual weapon-piece creation, maintenance scheduling, structural repair and broader
invention options remain incomplete. All recent fixtures are authored and unrun.

For invention projects, use the stages below rather than charging the proposal's
assessment values yourself. Every mutation belongs in an engine action transaction.

| Stage | Interface | Committed ledger effects | Important current limit |
| --- | --- | --- | --- |
| Proposal | `RpgExpandedInventionProposal.assess()` | None | Ordinary invention; historical software unresolved |
| Theory | `RpgExpandedInventionConcept.apply()` or `RpgExpandedInventionBlueprint.apply()` | Concept randomness and daily receipt, or blueprint receipt | Secret result; cinematic procedures pending |
| Facilities | `RpgExpandedInventionFacilities.fund()` | Shared money, owned facilities receipt | Alternate funding pending |
| Attempt | `RpgExpandedPrototypeStart.begin()` | Per-attempt money and duration dice | Explicit month intervals; fixed team |
| Work | `RpgExpandedPrototypeWork.apply()` | Shared clock and work credit | Whole approved intervals; no partial interruption credit |
| Completion | `RpgExpandedPrototypeCompletion.apply()` | Secret roll, conditional bug dice, injury/facilities or inventory | Physical prototypes; concrete accident contract required |
| Defect assignment | `RpgExpandedPrototypeDefectSet.apply()` | Pending inventory delivery | Penalty/block effects only |
| Operation | `RpgExpandedPrototypeOperation.apply()` | Time, check, qualifying fault activation | Explicit item/skill context |
| Testing | `RpgExpandedPrototypeTest.apply()` | One week, check, discovery/activation/belief receipt | Whole week; false-confidence critical policy |
| Production line | `RpgExpandedProductionLine.establish()` | Capital cost once | Recorded working prototype required |
| Production copy | `RpgExpandedProductionOrder.begin()` then `finish()` | Per-copy money, later time and inventory | Bug-free physical design; whole ledger units |

Technology's basic dependency remains foundation plus equipment. Software effective
technology contexts additionally use skills. Accident execution and prototype
completion require health's concrete wound adapter and its supported rules; merely
including technology does not activate expanded health. The pure assessments and
computer interfaces remain available without health.

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

## Owned fictional computer links

`RpgExpandedComputerLink` represents a connection inside the authored game world.
It does not open a socket or inspect real credentials. Declare a unique `id`,
distinct `first` and `second` computers, `evidence`, and four concrete world facts:
`compatible`, `mediumAvailable`, `addressKnown` and `credentialsSatisfied`.
These implement the B472 connection requirements. There is no generic success
callback counted as resolving compatibility or access.

`assess()` checks both hosts and these facts without changing anything.
`connect()` records one shared link in both computers' `links`, with a timestamp.
It does not invent a skill roll, connection duration or fee; the authored action
owns such setting-specific costs. It also does not install software, select a
terminal or transfer any data.

`usable()` checks current power, equipment failure and access facts. Revoking
credentials or losing the communication medium makes a connected record unusable
without deleting its history. Restoring those facts can restore usability while
the connection remains established. Explicit `disconnect()` ends it once, even if
the medium or credentials are already unavailable. Historical `connect()` replay
never reconnects a disconnected record; a new connection needs a new ID.

The endpoints and event evidence are bound. Access conditions are intentionally
live world facts and may change, while retargeting the connection is rejected.
Mutations belong in the existing action transaction. Suitable sharing software,
copy permission and destination storage are separately assessed by the owned data
transfer below; an established link alone grants none of those capabilities.

`test_computer_links` and `test_computer_link_persistence` cover every prerequisite,
preview purity, reciprocal registration, rollback, undo, credential revocation,
restoration, disconnect replay and separate-process continuation. Fixtures are
authored and unrun. Connection establishment remains partial until integrated with
transfers, terminal-link roles and the relevant software capabilities.


## Owned data transfer over a link

`RpgExpandedDataTransfer` copies a present `RpgExpandedStoredData` record through
an established usable `link` to its opposite endpoint. Supply a unique transfer
`id`, unique destination `dataId`, `source`, `target`, active `senderProgram` and
`receiverProgram`, `copyApproved`, `uninterrupted`, `durationSeconds` and `evidence`.
Both programs must use approved installed copies with `dataSharing = true` and
must already hold their normal processing reservations. A link alone does not
supply software, permission to copy the data or room at the destination.

`assess()` checks those conditions and destination capacity without mutation.
`apply()` spends the declared duration once, rechecks conditions after clock events,
and stores a new destination record through the existing storage API. It retains
the source and creates no additional program instance. Completion and its delivery
remain in `link.transfers`. A removed delivery is not recreated by replay, and a
completed transfer does not charge again. Request identity, endpoints, programs,
author evidence and duration are bound to the receipt.

B472 permits data sharing but supplies no universal transfer rate. The duration is
therefore an explicit author timing decision from zero through 86,400 seconds;
there is no invented bandwidth derived from computer complexity. `uninterrupted`
asserts that the authored transfer can proceed for that interval. Changed link or
storage conditions detected at completion raise an error so the enclosing action
transaction rolls back its time and other changes. Incremental interrupted
transfers and resumable partial data remain unsupported.

This operation copies an in-game content reference and its declared size. It does
not perform real networking or file I/O. Software effects beyond sharing, terminal
access through a remote host and physical recording remain separate integrations.

`test_computer_transfers` covers preview purity, missing software/permission/link,
missing source, full destination, rollback, undo, completion-time loss of access,
historical replay and deletion of the delivered record. The clock-failure fixture
changes access during elapsed time to exercise rollback rather than merely
rejecting the initial request. `test_computer_transfer_persistence` resumes before
transfer, after completion and after delivery removal in separate processes.
All fixtures are authored and unrun while checks remain paused.

## Owned computer recording

A computer's `microphone` and `camera` are explicit installed capabilities; neither
is inferred from the computer itself. `RpgExpandedRecording` requires an item
technology level of at least eight, as specified by B472. Its `media` is `audio`,
`video` or `audio-video`, requiring the corresponding sensor or both sensors.

Supply a unique recording `id`, unique `dataId`, `host`, authored content
`reference`, whole `sizeMB`, `durationSeconds` from one through 86,400,
`approved`, `uninterrupted` and evidence of the scene and recording parameters.
The source does not define a universal data rate: duration and size are separate
explicit author facts, not a guessed compression or camera-quality formula.
The reference remains fictional game content; no microphone, camera or real file
is accessed by this library.

`assess()` validates sensors, technology, availability and capacity without time or
randomness. `apply()` advances the shared clock once, rechecks the conditions and
stores the data through the existing storage ledger. Changed conditions raise an
error within the enclosing transaction, rolling back the operation. Records live
in `host.recordings`; replay cannot recreate deleted data or charge another duration.
Running software reservations remain unchanged.

This supports complete uninterrupted recordings that fit. An oversized request
rejects before work instead of silently truncating content. Streaming until full,
partial recordings, interruptions, remote sensor links and per-frame data rates
remain pending. Narrative evidence must establish what the sensors can actually
capture; the presence of a camera is not permission to observe hidden scenes.

`test_computer_recording` covers technology/sensor requirements, exact and exceeded
capacity, previews, rollback, undo, loss of a sensor during clock advancement,
media choices, historical replay and deletion. `test_computer_recording_persistence`
continues before recording, after completion and after data removal in separate
processes. These fixtures are authored and unrun while checks remain paused.


## A computer acting as a remote terminal

`RpgExpandedRemoteTerminal` extends the ordinary terminal with a `localHost` and
explicit `connections`. Each `RpgExpandedTerminalConnection` binds a live link to
an active `clientProgram` on the local computer and active `serverProgram` on the
remote computer. Their approved installed copies must declare `terminalClient`
and `terminalServer` respectively; data-sharing capability alone grants neither.

The supported B472 case requires the remote computer to have greater complexity
than the local one. Equal-complexity and reverse arrangements explicitly return
`terminal-remote-complexity-unavailable`; special configurations require further
source-grounded support. Both programs retain their ordinary processing costs.
The local host must remain powered and operational even when the remote target
is healthy.

The standard switch request calls `accessReason(target)` before spending its
second and again after clock events. A connection or service loss during switching
raises an error for transaction rollback. For an already selected remote host,
authored operations must call `accessReason(current)` before using that service;
selection is not a permanent authorization. Revoked credentials or a stopped
program make the service unavailable without deleting historical selection.
Returning to a healthy local host does not require a live remote connection.

This implements the declared remote-terminal role, not the actual game effects of
every program run remotely. Controller handoff, special multi-host terminals and
broader software task integration remain pending.

`test_remote_terminal` and `test_remote_terminal_persistence` cover missing client
or server capability, unavailable links/local hosts, unsupported complexity,
previews, rollback, undo, access loss during clock advancement, revocation while
selected, local return and separate-process continuation. Fixtures are authored
and unrun while checks remain paused.


## Software supporting a skill task

`RpgExpandedSoftwareCapability` declares an exact `taskId`, `skill`, approved
`equipment` assessment and supporting `evidence`. Install it in the host-bound
software copy's `taskCapabilities`. The author must establish why this program
supports this particular task and choose its equipment quality from B345;
software complexity alone does not determine the bonus.

Set `RpgLiteContext.softwareUse` to a `RpgExpandedSoftwareUse` selecting the
`program`, `terminal`, `taskId` and `capability`. Assessment requires a running,
authorized copy, an operational host, the profile controlling a terminal currently
selecting that host, and matching task and skill. Remote terminals recheck their
live link and client/server programs. An incapacitated operator cannot use this
interface. A second running instance does not add another bonus.

The selected capability contributes through the existing equipment modifier hook.
It changes neither learned skill nor character points, and preview consumes no
time or randomness. The task's existing execution owns its roll and duration;
software selection itself adds no action cost. Contexts without `softwareUse`
retain their existing equipment behavior. Simultaneous `equipmentAssessment` and
`softwareUse` explicitly reject with `task-software-equipment-combination` until a
combined physical/software tool policy is implemented.

`rpgExpandedRequiredSoftwareComplexity(techLevel)` returns the B472 usual baseline
for levels seven through twelve. This is an assessment helper, not automatic
permission to execute a technical task. Superior-software time reductions,
robot personality/skill installations and general utilities remain pending.
The current processing reservation range also limits which complexities can run;
returning a baseline does not bypass host limits. Required-software use is described below.

[Minimal fixture](../../tests/fixtures/expanded-software.t) demonstrates accounting
support with an explicitly approved good-quality program. `test_software_task_support`
authors expected values for ordinary and fine equipment, duplicate instances,
stopped programs, task mismatch, revoked approval, unavailable terminals and
operators, unchanged learned skill and pure previews. These fixtures are unrun
while checks remain paused.


## Required software and effective technology

Use `RpgExpandedSoftwareRequirement` for a technical task whose permitted methods
depend on software. Declare the exact `skill` and `taskId`, approval and evidence,
an optional `minimumComplexity` overriding the usual baseline, and the selected
software `use`. The evidence must justify the minimum and the alternative method.
`fallbackTL` is an explicit lower technology level at which the skill can function
without suitable software; omit it when there is no approved fallback.

`assess(profile, skill)` returns `effectiveTL`, `softwareAvailable` and
`softwareReason` as well as status and reason. Insufficient complexity, a stopped
program or lost access can select the declared fallback. Missing author approval
blocks instead. No fallback is inferred merely by subtracting one from a level.

Set `RpgExpandedSkillContext.softwareRequirement` and its task `equipmentTL` to
apply that effective skill technology through the B168 technology-difference
arithmetic. Include the skills module before technology for this integration.
The context requires an explicit task technology; it never changes the learned
skill object, points, or personal technology. Existing contexts without a
requirement retain their original technology modifier, including authored overrides.
`technologyModifierFor(profile)` performs the contextual calculation; the original
parameterless `technologyModifier()` remains the unmodified-skill calculation.

A requirement grants no equipment bonus automatically. To request a separate
bonus, select the same requirement use in `softwareUse`; a different program
selection rejects explicitly. A selected bonus whose software is unavailable
still blocks that bonus-bearing context; omit the bonus selection when intentionally
using the lower-technology method. Task execution continues to own time and rolls.

`test_software_requirements` authors cases for insufficient and sufficient
complexity, a task-specific minimum, absent and stopped software, forbidden
fallback, missing author approval, the lower-technology task itself, and an
explicit bonus. It also records unchanged skill technology, learned score, time
and randomness. These fixtures remain unrun. Automatic selection among several
alternative programs, superior-software time savings and interrupted task execution
remain incomplete.


## Buying a host-bound software copy

`RpgExpandedSoftwarePurchase` extends `RpgExpandedAcquisition`. Supply the paying
`profile`, an `item` representing the supplied documentation/license package,
the approved `copy` with its designated `host`, and `evidence` of the sale and
host delivery. The existing acquisition fields supply price or quote,
`available` and `permitted`. A digital documentation package may have zero weight;
physical media must use its authored weight. Its inventory location does not
control the already installed program's execution permission.

`assess()` checks the copy identity, author facts, existing installations and
ordinary money/ownership constraints without spending resources. `acquire()`
uses the shared acquisition ledger to charge the payer and grant the package,
then adds the copy to its designated host. Invoke it inside an action transaction.
Starting additional program instances consumes processing capacity but no purchase
price. A second copy for a different host is a separate authored sale.

Replaying the receipt charges nothing. It does not reinstall a copy removed from
the host later, and retargeting the copy, host, identifier, complexity, quote or
sale evidence rejects. Runtime revocation of copy approval is separate from the
historical purchase. A duplicate installed identifier blocks before payment.
The sale can grant software that exceeds the host's processing capacity; the
existing run assessment still rejects execution there.

This operation models a sale with authorized delivery, with no implied download
or installation duration. Use a separate authored installation procedure when
that time matters. Starting-wealth pricing, license transfer, copied/pirated
software, refunds and media-driven installations remain incomplete.

[Purchase fixture](../../tests/fixtures/expanded-software-purchase.t) authors
preview, insufficient funds, denied permission, duplicate copy, exception rollback,
undo, replay, two instances for one price, removal and three cross-process save
stages. `test_software_purchase` and `test_software_purchase_persistence` are
unrun while checks remain paused.


## Realistic invention proposals

`RpgExpandedInventionProposal` records an `inventor`, primary `skill`, optional
`relatedSkills`, `description`, proposed `mechanism`, approval and supporting
`evidence`. Set the invention `techLevel`, `retailPrice`, and either an authored
`category` (simple, average, complex or amazing) or `softwareComplexity`.
The price and skill category helpers expose B473 guidance; they never override
the author's classification or create skill prerequisites.

`assess()` requires purchased training in each required subject and uses the
lowest skill score. Realistic inventions more than one technology level above
the inventor block. Lower-technology physical inventions reduce category one
step per level, with a simple minimum. The interaction between historical
software and numerical complexity remains explicitly unsupported.

The result contains the category, controlling skill, base concept modifier,
facilities cost and per-attempt retail cost. An authored `descriptionBonus` of
zero, one or two and the advanced-technology penalty are included. The
`relatedFacilities` decision asserts suitable facilities from an equal-or-higher
complexity project and divides facilities cost by ten. Prices use B474 fixed
currency amounts rather than automatic technology/wealth scaling.

This assessment consumes no money, time or randomness. It is not a completed
invention project or a complete roll context. The owned stages below add model
access, novelty, variant modifiers, historical research, attempts and consequences.
Do not charge the returned costs merely for submitting a proposal.

`test_invention_proposals` authors category boundaries, related-skill selection,
technology limits, historical reduction, facilities reuse, software complexity,
approval, training and description-bonus cases in the technology fixture. The
fixtures are unrun while checks remain paused. Neutral source: `full-2008`, B473–B474.


## Owned secret concept attempts

Create a `RpgExpandedInventionProject` with its approved `proposal`, then a
`RpgExpandedInventionConcept` with a unique inventor-wide `id`, that `project`,
and evidence for the current attempt. `knowledge` selects exactly one of `new`,
`exists` or `model`, so the existing-design and working-model bonuses cannot both
apply. `variantBonus` is an authored zero through five, and `campaignNew` applies
the source penalty for technology new to the campaign.

For a lower-technology invention, `historicalSources` asserts that suitable
references are accessible. Supply a `researchSkill` whose neutral identifier is
`research`; the assessment uses the higher research/invention score, still capped
by required related subjects. Neither the presence of a library nor a high
research score automatically establishes suitable historical sources.

`assess()` returns a score and day without rolling. `apply()` makes one secret
check, records the receipt in the project and in the inventor's
`inventionConceptAttempts`, and stores a `testable` or `flawed` theory where
appropriate. Ordinary failure leaves theory empty and permits another day.
Both kinds of theory prevent further concept attempts on that project until a
later supported project stage resolves them. Flaw discovery is not implemented.

The shared clock defines days as consecutive 86,400-second intervals from game
time zero. One inventor can spend only one concept opportunity in each interval,
even on different projects. This is an eligibility limit, not an automatic charge
of a full day's time: the source specifies attempt frequency without a mandatory
work duration. Authored scheduling advances the shared clock. No money is spent.

Keep the result private: the operation emits no player-facing event and never
announces whether a theory is flawed. Narrative feedback belongs to the author.
The original proposal is bound on first execution; editing its substantive fields
later rejects. New evidence for another attempt uses a new request. Replay returns
the original outcome without consuming randomness or another daily opportunity.
Use the existing action transaction for rollback, undo and saves.

`test_invention_concept`, `test_invention_theories` and
`test_invention_concept_persistence` author ordinary failure, testable and flawed
theories, previews, rollback, replay, proposal retargeting, global daily limits,
clock boundaries, undo and cross-process continuation. These fixtures are unrun.
Blueprint entry, physical prototype construction and flaw discovery have separate
interfaces below. Calendar variants and cinematic invention remain incomplete.


## Prototype duration and secret outcomes

`rpgExpandedPrototypeDuration(category, dice, workers)` accepts exactly the
source-prescribed number of supplied dice. It returns a rational duration through
`numerator`, `denominator` and `unit`, plus `minimumDays = 1`. Day-based results
already enforce that minimum; month-based results retain calendar units, with the
minimum to be applied when an authored calendar resolves the duration. A month is
not silently treated as thirty days. The worker count must represent the skilled
people actually assigned; this helper does not reserve their schedules.

`rpgExpandedPrototypeTeamModifier(proposal, assistants, toolsPenalty)` counts each
unique assistant once when they have a trained required skill of at least twenty,
caps the assistant bonus at four, and subtracts an authored tools penalty from
zero through ten. The inventor cannot be included as their own assistant. This
is qualification arithmetic, not proof of availability for the whole project.

`rpgExpandedPrototypeOutcome(score, roll, flawed, bugDice)` assesses a supplied
secret roll. A flawed theory cannot yield a working prototype; critical success
reveals its flaw. Critical failure marks facilities destroyed and an accident
requiring at least two damage dice for each participant. It does not apply injury
or invent the accident's damage type, protection interaction or extra severity.

Working critical success needs no bug dice. Other success needs one die for a
margin of at least three, otherwise two dice (major count first, minor count
second). Half-die bug counts round down under the general character-result
rounding convention in B9. Irrelevant or missing dice reject. The result carries
counts only; concrete defect descriptions, discovery and consequences remain to
be authored in the owned prototype stage.

All three helpers are pure assessments. Use the owned funding, work, completion
and accident interfaces below for mutations. Future work reservations, broader
accident effects and the remaining defect lifecycle remain incomplete.
`test_prototype_assessments` authors duration boundaries, team qualification,
margin boundaries, odd half-dice, flawed theories and accidents; it is unrun while
checks remain paused. Neutral source: `full-2008`, B9 and B474.


## Owned facilities funding

`RpgExpandedInventionFacilities` binds a `project`, paying expanded `payer`,
explicit approval and evidence that the payment establishes the inventor's
facilities. The project must hold a theory. The payer may be a sponsor, but this
interface does not roll for a patron, negotiate shares or create a loan.

`assess()` checks the proposal, available funds and existing facilities without
spending anything. `fund()` debits the existing money balance and records the
receipt in `project.facilityFunding`, with the active installation in
`project.facilities`. Invoke it inside the usual action transaction. This is a
facilities payment, not the separate retail-price cost of a prototype attempt.

The receipt preserves `fullCost` before any related-facilities discount. A new
funding request after destruction pays that original full cost; it cannot reuse
the destroyed facilities for a discount. Replay of the old payment does not
restore a destroyed installation or charge again. A second request against an
intact installation blocks. Project, payer and funding-evidence retargeting also
rejects after payment.

The owned prototype accident interface marks these facilities `destroyed` after
applying its supported wounds. The funding receipt does not claim that a laboratory
has been built in elapsed game time or supplied with every special material.
Future scheduling, gradual professional funding and external investors remain
pending; attempt funding and work intervals have separate interfaces below.

`test_invention_facilities` and `test_invention_facilities_persistence` author
previews, funds and approval gates, rollback, undo, replay, intact-installation
rejection, destruction/rebuilding and save continuation. They remain unrun while
checks are paused. Neutral source: `full-2008`, B474.


## Starting from actual blueprints

`RpgExpandedInventionBlueprint` binds a project to an in-game design `reference`.
The author must establish that it was `acquired`, is an `actualDesign`, and is
approved, with explicit supporting evidence. A rumor that a device exists or
access to a working model is insufficient; those use the concept modifiers.

`assess()` retains the approved proposal's skill and technology gates. `apply()`
records `project.blueprintEntry` and establishes a testable theory, binding the
proposal and design reference. It does not roll, spend time or money, or append a
daily concept receipt. The inventor can therefore still make their ordinary
concept attempt on another project that day. Facilities and attempt costs remain
separate obligations.

Replay does not grant a new theory or consume another resource. The entry rejects
an already established theory, including a flawed one: replacing an ongoing
project's theory and reconciling its existing prototype work remain unsupported.
The reference names fictional design data; this interface performs no file I/O
and does not determine whether a discovered document is genuine. That fact must
come from the authored world.

`test_invention_blueprints` and `test_invention_blueprint_persistence` author
approval/acquisition gates, preview purity, rollback, undo, replay, reference
binding, preserved daily opportunity, subsequent facilities funding and
cross-process continuation. They remain unrun while checks are paused. Source:
`full-2008`, B473.


## Funding and sizing a prototype attempt

`RpgExpandedPrototypeStart` binds a unique `id`, project, expanded payer,
`assistants`, tools penalty, approval and evidence. It requires a held theory and
funded, intact facilities. Every participant must be available and trained in at
least one required subject. Qualification for the assistant bonus still uses the
higher twenty-skill threshold. One active attempt per project is supported.

`assess()` validates all facts and sufficient money before randomness or spending.
`begin()` charges the separate per-attempt retail cost once, rolls the source's
duration dice once, and records the resulting `seconds`, dice and rational duration.
It sets `project.activePrototype` and appends the request to `project.prototypes`.
The facilities payment is not charged again. `workedSeconds` initially remains
zero and the shared clock does not advance merely for funding the attempt.

For complex or amazing projects, provide `monthDays` covering respectively six or
eighteen successive month intervals from the authored work origin and
`calendarEvidence`. Each interval is one through forty whole days; different
calendars outside that range reject. The entire array is validated before rolling,
then only the rolled number of months is used. Divide by skilled worker count,
apply the one-day minimum, and add any authored `extraSeconds` for an unusually
large project. That extension is a scheduling decision, not an automatic size rule.

Replay preserves the original duration without another cost or random draw.
Changing the bound project, payer, participants, calendar or evidence rejects.
Use an action transaction so failed execution restores money, random state and
project state together. Funding does not reserve participants against other
activities: shared work scheduling, interruption, completion rolls, accidents,
defect creation and cancellation/refunds remain incomplete. Use the separate secret completion interface after recording all required work.

`test_prototype_start`, `test_prototype_start_calendar` and
`test_prototype_start_persistence` author preflight rejection, rollback, undo,
replay, exact seeded duration, explicit month conversion and save continuation.
They remain unrun while checks are paused. Source: `full-2008`, B474.


## Committed prototype work intervals

`RpgExpandedPrototypeWork` records an interval with a unique attempt-local `id`,
the begun `attempt`, one through 86,400 `seconds`, approval, `uninterrupted` and
evidence of the whole team's availability and access to the bound facilities.
The author must establish that participants are not assigned incompatible work
elsewhere; this is not a future calendar reservation service.

`assess()` checks the active attempt, current facilities, available trained
participants and remaining work. `apply()` advances the shared clock once for
the team, then checks those conditions again before increasing `workedSeconds`.
A clock event that incapacitates a participant, destroys the facilities, changes
work credit or advances additional time raises an error; the enclosing action
transaction rolls back the entire interval. No work is credited automatically
for unrelated time passing.

Receipts in `attempt.workIntervals` retain actual start/end times. Replaying one
adds no time or work, even after later progress. A new interval cannot exceed the
remaining duration. No extra currency or random draw is involved. Prototype
completion remains a separate secret operation: reaching the required duration
does not itself roll or create a working object; call the separate completion interface.

The original team and time basis stay bound. Participant substitution, partial
credit for an interrupted interval, simultaneous unrelated projects, automatic
work/rest scheduling and completion consequences remain incomplete. Day/month
project durations are elapsed project intervals; this interface does not declare
that every elapsed second is strenuous labor or award study credit for it.

`test_prototype_work` and `test_prototype_work_persistence` author preview purity,
rollback, clock-triggered interruption, facility loss, undo, replay, exact remaining
work, and cross-process continuation. These fixtures remain unrun while checks
are paused. Source: `full-2008`, B474.


## Owned prototype accident consequences

`RpgExpandedPrototypeAccident` accepts a completed-work attempt, its assessed
critical-failure `outcome`, explicit approval, evidence and exactly one target for
every inventor/assistant. `RpgExpandedPrototypeAccidentTarget` specifies an owned
wound `id`, expanded `profile`, two through ten damage `dice`, a supported physical
`damageType`, assessed `protection`, armor `divisor` and equipment-drop
`destination`. The author must establish the accident mechanism and applicable
protection; neither an explosion nor a default protection value is inferred from
the source's minimum damage statement.

Include the health module to supply `prepareTechnologyWound`. The foundation's
fallback returns no adapter, causing `prototype-accident-health-required` rather
than applying simplified injury. The concrete adapter creates the existing owned
torso wound, retaining scaled shock, major wounds, drops and the shared injury
ledger. Its anatomy, trait and campaign-rule restrictions still apply.

Assessment preflights every possible raw damage total for every target before
randomness. Execution rolls each target's damage in declared order, applies its
wound and records both in the accident receipt, then marks the original facilities
destroyed. Enclose this in an action transaction so any exception restores all
participants, randomness and facilities. There is no additional cost or elapsed
time. Replay returns the historical receipt without another injury or destruction.

This is a concrete consequence contract for supplied critical-failure outcomes;
the completion interface below makes the secret roll and closes the active
attempt. It supports standard torso wounds and the listed physical damage types,
not arbitrary multi-location explosions, secondary fires or unsupported anatomy.
Those combinations must await explicit support. Actual rebuilding still uses a
new facilities funding request and the recorded full cost.

`test_prototype_accident`, `test_prototype_accident_protection` and
`test_prototype_accident_persistence` author preflight, rollback, undo, replay,
protection, funding preservation and cross-process wound continuation. These
fixtures remain unrun. Source: `full-2008`, B474, with existing injury procedures.


## Secret prototype completion

`RpgExpandedPrototypeCompletion` connects a fully worked attempt to its secret
roll. Supply the recipient and authored physical prototype `item`, a fresh
`accident` contract covering the whole team, approval and evidence. Select the
current `knowledge`, `variantBonus` and `campaignNew` facts as for concepts.
Prototype checks use the lowest current contextual required skill, proposal
modifiers, qualified assistants and the bound tools penalty; historical research
does not replace the invention skill for this stage.

`assess()` verifies both delivery and every possible accident wound before any
roll. `apply()` rolls once, draws only the bug dice required by the actual outcome,
applies accidents through the wound contract and closes the active attempt.
Ordinary failure preserves the theory for a newly funded retry. A critical
success on a flawed theory discovers the flaw and clears that theory, allowing
a new concept attempt; it never creates a working object.

A working prototype with no bugs is issued through the existing inventory
acquisition ledger without charging its retail cost again. A prototype with bugs
is retained in the completion receipt with `pendingDefects`; it is **not delivered**
as usable equipment until the supported executable defect set is assigned.
`project.workingPrototype` retains either successful result and blocks treating a
second attempt as ordinary prototype construction. Later bug-free physical copies
use the production-order interface below; defect propagation remains incomplete.

The result stays private and emits no player-facing event. Narrative disclosure
must not reveal secret bug counts or flawed-theory state merely because an author
can inspect the receipt. Replay returns the historical outcome without another
roll, injury, item or charge. Use the usual action transaction to keep all these
consequences atomic. Software prototypes and unsupported accident configurations
reject before rolling rather than silently using physical-item delivery.

`test_prototype_completion`, `test_prototype_completion_outcomes` and
`test_prototype_completion_persistence` author preview, missing accident approval,
rollback, undo, ordinary failure, unresolved defects, bug-free delivery, flawed
theory discovery, accident dispatch, replay and cross-process continuation.
Fixtures remain unrun. Source: `full-2008`, B473–B474.


## Executable defect assignment and operation context

A `RpgExpandedPrototypeDefectSet` supplies the exact major/minor counts recorded
by a pending completion. Each `RpgExpandedPrototypeDefect` needs a unique id,
severity, effect and evidence. Supported minor effects are `operation-penalty`
with an explicitly authored penalty of one through ten. Supported major effects
are `operation-block`, with no numeric penalty. These effect magnitudes are world
design decisions, not a new source table. Other behaviors reject explicitly.

`assess()` verifies every definition, count and delivery condition. `apply()`
binds the definitions, issues the held prototype through its existing acquisition
receipt and clears pending delivery. Initial faults must be inactive and
undiscovered. Replaying installation never grants another item or resets a fault.
The shared inventory continues to account for the item's ordinary weight even
when a fault makes its operation impossible.

Set `RpgLiteContext.prototypeItem` for an operation using the prototype. The item
must belong to the profile and be accessible. Active penalty faults contribute
through the normal contextual modifier path; a blocking fault returns
`prototype-defect-blocked` without a roll. These are operation-only effects and do
not reduce learned skill. Contexts without the selected item remain unchanged.
Do not assume this opt-in context automatically intercepts every weapon attack,
vehicle maneuver or electronics operation; those dispatch integrations remain
incomplete.

The operation and testing interfaces below manage `active` and `discovered`
separately; installation alone does not activate faults. Repairs, additional
fault effects and cross-module dispatch remain pending. The concrete penalty and
blocking contracts are implemented; arbitrary narrative callbacks are not counted
as executable defects.

`test_prototype_defects` and `test_prototype_defects_persistence` author count
validation, preview, rollback, undo, inventory delivery, replay, bound definitions,
active penalty/block effects, item accessibility and cross-process continuation.
They remain unrun. Source: `full-2008`, B474; concrete fault effects are authored.


## Operation failures that surface faults

`RpgExpandedPrototypeOperation` owns one explicitly authored operation check.
Supply an operation `id`, profile, item, skill, bounded contextual modifier,
zero through 86,400 seconds, approval, uninterrupted availability and evidence.
The item must have an installed executable defect set. Ordinary items without
defects continue to use existing check interfaces.

Choose `marginDefect` from the currently undiscovered faults and `criticalDefect`
from existing major faults. Omit a choice only when its eligible set is empty.
These are authored choices rather than invented random selection rules; explain
them in the operation evidence. A critical failure selects the major fault when
one exists, even with a failure margin smaller than five. Otherwise, failure by
five or more surfaces the selected undiscovered fault. The selected fault becomes
active and discovered; operation failure does not silently repair an old fault.

Assessment checks choices and current operation legality before time or randomness.
Execution advances the shared clock once, rechecks conditions, makes the normal
contextual skill check and records the activation. If clock events invalidate the
operation, the enclosing transaction restores the interval. The operation emits
no narrative event; the author describes the attempted task and manifested fault
from the structured check. A failed check already has its ordinary failure result;
the new fault affects subsequent operations through the item context.

Receipts live in `defects.operations`. Replay returns the original check and fault
without another roll, time charge or activation. Different operations require
new ids and currently valid choices. This interface supports one skill check and
its concrete penalty/block faults. Vehicle/weapon dispatch, specialized technology
and familiarity contexts, physical consequences beyond those faults, and weekly
testing remain incomplete.

`test_prototype_operation`, `test_prototype_operation_boundaries` and
`test_prototype_operation_persistence` author the margin-five boundary, a major
fault at critical failure with a small margin, preflight choices, clock interruption,
rollback, undo, replay and separate-process continuation. Fixtures remain unrun.
Source: `full-2008`, B474.


## A complete week of prototype testing

`RpgExpandedPrototypeTest` owns one complete uninterrupted testing week. Supply a
unique test `id`, tester profile, item, operation skill, approval, uninterrupted
availability and evidence. Select `discoveryDefect` from undiscovered faults and
`failureDefect` from existing major faults, omitting a selection only when its
eligible set is empty. Choices are authored before rolling.

The check uses the operation skill at minus three, retaining current contextual
conditions and active faults. The interface advances seven successive 86,400-second
intervals through the shared clock and revalidates availability after each. Any
invalidating event raises an error for rollback of the entire week. It supports
complete weeks only; partial testing, tester substitution and interruption credit
remain pending. Approval must establish the tester's availability across the week;
no automatic employment or study credit is awarded.

Ordinary success discovers the selected fault without activating it. Critical
success discovers every remaining unknown fault. Ordinary failure activates an
existing major fault if present. The supported explicit `criticalPolicy` is
`false-confidence`: critical failure records the tester's mistaken belief that no
bugs remain, without discovering or activating any real fault. The alternative
major-like incident policy rejects until a concrete consequence contract is
implemented. Actual discovery state and false confidence remain separate.

The request records its check, discoveries, activated fault, belief and start/end
times in `defects.tests`. Replay charges no additional week and changes no fault
state. Finding a fault is not repairing it. Active blocking faults can prevent
further operation-based testing; repairs and broader diagnostic procedures remain
separate incomplete work. Keep the structured result private until the authored
narrative chooses what the tester understands.

`test_prototype_testing`, `test_prototype_testing_outcomes` and
`test_prototype_testing_persistence` author all supported result branches, previews,
clock-event rollback, undo, replay, policy rejection and separate-process
continuation. Fixtures remain unrun. Source: `full-2008`, B474.


## Production arithmetic and line funding

`rpgExpandedAssessProduction(retailPrice, prototypeSeconds, line, paidLabor)`
returns exact reduced fractions for per-copy money and seconds, plus the line's
setup cost. Individual copies cost one fifth of retail for parts alone or full
retail including labor, and take half the supplied prototype duration. A line
costs twenty times retail; each copy costs one fifth for parts or one half with
labor. Its time is the lesser of one seventh of prototype duration and retail
price divided by one hundred hours. No extra one-day minimum is applied to
production copies.

The caller must state the basis of `prototypeSeconds`, such as the actual recorded
prototype duration; the helper does not roll a replacement duration or silently
choose between alternatives. Fractions remain explicit: a price of 101 yields
101/5 for parts, not a rounded charge. Future committed production must resolve
unsupported fractional ledger amounts explicitly. Prices through 100 million and
prototype durations through one billion seconds are supported; comparisons avoid
multiplication overflow at the upper bounds.

`RpgExpandedProductionLine` records a unique line id, project, expanded payer,
approval, availability, permission and evidence. The current implementation
requires a working prototype on that project. `assess()` checks the capital
payment before mutation; `establish()` charges twenty times the bound retail
price once and records the line in `project.productionLines`. This payment is
separate from prototype facilities and per-copy production. Replay does not charge
again. It does not yet manufacture items or schedule setup work: evidence must
establish the available installation rather than implying a universal setup time.

`test_production_assessments`, `test_production_line` and
`test_production_line_persistence` author price/time fractions, branch boundaries,
large values, working-prototype and funds gates, previews, rollback, undo, replay
and save continuation. Fixtures remain unrun. The one-copy interface below executes
supported whole-unit orders. Fractional currency, production without a locally built
prototype, defect propagation and partial production scheduling remain incomplete. Source: `full-2008`, B474.


## Funded one-copy production orders

`RpgExpandedProductionOrder` binds a unique project-local id, project, payer,
recipient, responsible worker and authored copy item. Supply the parts/labor
choice, optional funded `line`, approval, availability, permission, uninterrupted
work and evidence that the item matches the design. The current path requires a
delivered bug-free physical prototype and uses its recorded duration. Defective
design propagation and newly rolled production-duration bases remain unsupported.

`assess()` validates the exact cost/time fractions, funds, worker availability,
line availability, item ownership and pending item reservations. Fractional money
or seconds reject before spending; there is no silently rounded quote. `begin()`
charges the per-copy cost once and preserves the assessed duration. A line accepts
one pending order at a time. Another order cannot reserve the same undelivered
item, and another completed item must use a distinct item object.

`finish()` performs the whole uninterrupted production interval through the shared
clock in at-most-one-day steps, rechecking the worker and line after each. It then
issues the copy through the shared inventory ledger and releases the line. Any
invalidating clock event or delivery error rolls back that finishing action; the
previously funded order remains available for later work. Replay of either phase
never charges money or time again. Funded and delivered states support saves.

The worker represents the responsible available labor; evidence must establish
any paid workforce and the required facilities. No universal manufacturing skill
roll or extra setup duration is invented. Partial work credit, simultaneous line
output, cancellation/refunds, changed crews, nonphysical products, fractional
ledger support and copies carrying defects remain incomplete.

`test_production_order`, `test_production_order_line` and
`test_production_order_persistence` author preview, funds, rollback, clock-driven
interruption, undo, retarget rejection, separate manual/line timing, replay and
continuation before and after delivery. Fixtures remain unrun. Source:
`full-2008`, B474.


## Cinematic invention assessments

`rpgExpandedCinematicInventionCosts(category, retailPrice, campaignTL, deviceTL,
reusedFacilities)` implements B475's base facilities costs and per-technology
increments. The adjusted retail cost accumulates the original amount and every
successive doubling; it is not merely the final doubled amount. Appropriate
reused facilities divide their cost by ten. The author must establish their
required similarity, complexity and technology. Integer overflow rejects explicitly.

`rpgExpandedCinematicInventionModifier(category, softwareComplexity, personalTL,
deviceTL)` uses the milder category penalty, or numerical software complexity,
and minus five for each level above the inventor. Category and software complexity
are mutually exclusive inputs. This assessment does not add a campaign-new
technology penalty. Other situational modifiers remain separate. Campaign and
personal technology are separate inputs because the cost and skill rules compare
to different levels.

`rpgExpandedRapidConceptSeconds(die)` and
`rpgExpandedRapidPrototypeSeconds(category, dice)` preserve the rapid variant's
specific dice and units. In particular, average construction on a roll of one or
two takes thirty minutes, and the ordinary one-day minimum does not apply.
Supplied dice keep these helpers pure.

These are assessment helpers only. They neither enable cinematic rules nor grant
the required purchased capabilities. Ordinary proposal, concept and prototype
execution continues using its existing formulas. Trait eligibility, explicit
campaign/world permissions, rapid resource acquisition, advanced-device defect
tables and owned cinematic execution remain pending; callers must not substitute
these assessments into an ordinary project's mutable receipts.

`test_cinematic_invention_assessments` authors the published cost example,
accumulated-price progression, campaign/personal technology distinctions, category
penalties, rapid timing boundaries and preview purity. Fixtures remain unrun.
Source: `full-2008`, B475–B476.


## Cinematic invention permission

`RpgExpandedInventionPermission` checks an expanded inventor, `mode` (cinematic or
rapid), design approval and evidence. Enable `rules.cinematicInvention` explicitly;
rapid mode additionally requires `rules.rapidInvention`. Both default to nil.
The traits module must supply an active purchased `RpgExpandedInventor`; an
ordinary tier cannot authorize rapid work. The rapid tier also qualifies for the
ordinary cinematic mode.

Set `violatesOrdinaryPhysics` when the proposed design needs speculative physics.
Such a request additionally requires `rules.speculativePhysics`, plus the same
explicit design approval. Neither a purchased trait nor broad world permission
makes every design feasible. The author evidence must explain the proposed design.

This pure gate grants no skill, points, material, time discount or project outcome.
Ordinary invention execution remains unchanged. Owned cinematic dispatch will
need to invoke this gate and the appropriate formulas at each committing stage;
it remains incomplete. Calling `assess()` alone does not authorize editing an
ordinary request's stored costs or duration.

`test_inventor_permission` authors disabled campaign settings, missing/inactive
capability, both tier costs, rapid restrictions, speculative physics and design
approval. Fixtures remain unrun. Source: `full-2008`, B56–B57 and B475–B476.


## Owned cinematic concepts

`RpgExpandedCinematicProposal` extends the ordinary proposal with a matching
`RpgExpandedInventionPermission`. Its permission mode must currently be
`cinematic`; rapid execution rejects explicitly. The proposal retains the same
trained primary/related skill requirements, approved mechanism and complexity
classification. It substitutes cinematic base modifiers and campaign-relative
cost assessments, without the ordinary one-level technology ceiling.

Use it in `RpgExpandedInventionProject` and the existing
`RpgExpandedInventionConcept`. The owned daily attempt, secret outcome, replay,
undo and save behavior is shared. `campaignNew` contributes no penalty on this
path; personal technology still determines the advanced-design skill penalty.
Permission is checked before a new attempt; old receipts remain historical.
The bound proposal also retains the permission's design and mode fields so those
cannot be retargeted after execution.

Ordinary proposals retain their existing outcome formulas and random draw counts.
Cinematic physical prototypes at or below the inventor's personal technology
level now share the owned funding, work, accident and delivery pipeline. A success
margin of at least three needs no defect dice; a lesser success rolls one die and
halves it, rounding down, for minor defects only. Critical successes remain free
of defects. Permission is rechecked before work and completion, while completed
receipts remain historical.

Completion records `productionPrice`. Production-line setup and one-copy orders
use that recorded price, including the accumulated campaign-relative adjustment.
This keeps subsequent production from reverting to the native retail price.

Funding and start reject `cinematic-advanced-defects-unavailable` when the design
exceeds personal technology. The special defect table, extended shifts, software
prototype delivery and rapid execution remain pending. Passing this gate does not
make those other procedures available.

`test_cinematic_prototypes` authors margin-three and lesser-success outcomes,
preview purity, rollback, permission withdrawal, replay and adjusted line costs.
These fixtures remain unrun. Source: `full-2008`, B475–B476.

`test_cinematic_concepts`, `test_cinematic_advanced_concept` and
`test_cinematic_concept_persistence` author campaign/capability/physics gates,
novelty behavior, beyond-one-level attempts, unsupported-stage rejection, preview,
rollback, undo, replay and cross-process continuation. Fixtures remain unrun.
Source: `full-2008`, B475.

### Cinematic workshop decisions

Set `RpgExpandedCinematicProposal.waiveToolsPenalty = true` only when the author
approves ignoring the questionable-equipment penalty for this design. Supply
`toolsWaiverEvidence` describing that decision. The default preserves the
prototype's `toolsPenalty`; owning the capability alone never waives it.
The waiver changes only that penalty, leaving assistant qualifications and all
other modifiers intact. Both fields are part of the bound project definition;
changing either after execution rejects the request before further work or rolls.
Missing evidence rejects an attempted waiver.

`test_cinematic_tools` authors explicit waiver, default penalty, missing evidence
and post-start retargeting cases. `test_cinematic_prototype_persistence` authors
cross-process continuation before and after completion, historical adjusted-price
reuse for production, and undo of a paid production order. Fixtures remain unrun
while checks are paused. Source: `full-2008`, B475–B476.

## Rapid concept sessions

Use `RpgExpandedRapidProposal` with permission mode `rapid`, the purchased rapid
capability tier, and both campaign invention options enabled. Submit concepts
through `RpgExpandedRapidConcept`; a generic concept request rejects this proposal
instead of skipping its time charge. Each request needs a unique ID, project,
evidence, `approved` and `uninterrupted` author facts.

Assessment is pure. Execution preflights all six possible elapsed durations, rolls
one die for minutes, spends that time once, and rechecks the request, bound design,
inventor and permission before rolling the secret concept check. An interrupted
session raises an error so the enclosing action transaction restores time, random
state and other changes. Always execute `apply()` inside an engine action.

Rapid attempts have no daily quota. Their receipts share the inventor's concept
history and unique-ID enforcement, but do not consume an ordinary daily attempt.
Failed attempts may be followed by another owned session. Replay returns the
recorded duration and result without another time charge or roll. Ordinary and
non-rapid cinematic requests preserve their daily limit and existing draw counts.

Rapid prototype funding still rejects `rapid-prototype-components-unavailable`:
component discovery, resource consumption and construction remain pending. The
rapid concept path does not enable ordinary prototype construction as a fallback.

`test_rapid_concepts` and `test_rapid_concept_retry` author permission gates,
request-type rejection, preview, transaction rollback, interruption, replay,
unsupported construction, elapsed time and same-day retry. Fixtures remain unrun.
Source: `full-2008`, B476.

## Purchasing rapid-construction components

`RpgExpandedRapidPurchase` acquires an authored component bundle into the payer's
ordinary inventory. Supply a unique `id`, rapid invention `project`, `payer`,
`item`, and approved availability, permission and evidence. A held theory and the
current rapid capability/campaign permission are required. Assessment computes
prices without spending currency or consuming randomness.

The first receipt charges cinematic facilities and prototype costs divided by
100. Subsequent receipts for the same project charge only the divided prototype
cost; the project's `rapidFacilityPurchase` retains the original setup receipt.
Both parts and setup must be exact whole currency units. Fractional amounts reject
with `rapid-purchase-fractional-ledger-unavailable`, without rounding or payment.
Designs requiring the unimplemented advanced defect table also reject.

Call `acquire()` inside an engine action. It uses `RpgExpandedAcquisition` for a
single shared currency deduction and inventory grant. Replaying a receipt neither
charges again nor restores components removed later. The receipt binds its
project, payer, item and evidence, and each project enforces unique purchase IDs.
Results expose `money`, `facilitiesMoney`, `partsMoney` and the owned `acquisition`.
For replay, `money` is zero while the historical price components remain visible.

These receipts currently acquire resources only. Prototype reservation,
consumption, critical-failure destruction and scrounged alternatives still need
integration; rapid construction remains blocked. No separate inventory is added.
`test_rapid_purchases` authors ordinary and campaign-advanced prices, setup paid
once, spare parts, preview, rollback, replay, undo, duplicate IDs, retargeting,
availability, insufficient funds and fractional rejection. Fixtures remain unrun.
Source: `full-2008`, B477.

## Finding rapid-construction components

`RpgExpandedRapidSearch` resolves a search against an actual authored source.
Supply the rapid invention `project`, unique `id`, `source` reference, `skill`,
`sourceKind`, `seconds` and evidence. The author must affirm `approved`,
`available`, `permitted` and `uninterrupted`. For `plentiful` sources the skill's
neutral ID must be `scrounging`; for `limited` sources the author chooses and
justifies the relevant technical skill in `evidence`. The reference does not
specify search duration here, so `seconds` is an explicit scenario decision.

The request applies the category penalty (0, -2, -6 or -10), resolves the current
contextual skill score, and on success rolls `(one die - 1) * 100` as
`projectCost`. Failure leaves `projectCost` unset and consumes no cost die.
A zero cost is a successful discovery. Campaign and purchased-tier permission
are still required. The search uses ordinary skill availability and modifiers;
it grants no skill training.

`assess()` is pure. Execute `apply()` within an action transaction: it spends the
specified time, rechecks definition, source permissions and inventor state, then
records the check and cost. Interrupted execution raises an error for transaction
rollback. Replay and project history retain the original result without another
roll or time charge. Searching does not itself charge currency, transfer inventory
or consume the source. Applying the receipt to acquired components and prototype
construction remains pending.

`test_rapid_search` and `test_rapid_search_failure` author preview, rollback,
interruption, skill-source mismatch, unavailable sources, capability gating,
retargeting rejection, replay, elapsed time and success/failure cost-die behavior.
Fixtures remain unrun. Source: `full-2008`, B476–B477.
