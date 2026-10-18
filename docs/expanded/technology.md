# Expanded technology

**Status: pending.** Electronics, inventions, artifact investigation, object damage,
maintenance and repair. Neutral source: `full-2008`, B471–B479; B483–B485.

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json) · [Procedure inventory](inventory/technology.json) ·
[Outcome tables](inventory/technology-outcomes.json)

This module has not been implemented. Its proposed filename,
`vhyl-rpg-expanded-technology.t`, remains reserved in the catalogue; do not include
it in a game. The first text pass covers these sections and records their tables
as pending requirements. Underlying traits, equipment definitions, cross-references,
visual table checks and executable tests still need completion.

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
