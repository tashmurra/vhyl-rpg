# Expanded technology

**Status: partial.** Electronics, inventions, artifact investigation, object damage,
maintenance and repair. Neutral source: `full-2008`, B471–B479; B483–B485; B529–B533; B546.

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json) · [Procedure inventory](inventory/technology.json) ·
[Outcome tables](inventory/technology-outcomes.json)

Include `vhyl-rpg-expanded-technology.t` after the expanded foundation. The current
runtime provides a pure disabled-weapon assessment only. Other inventoried
procedures remain pending, including object damage, actual piece creation,
maintenance, repair and invention projects.

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
