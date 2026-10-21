# Expanded tactical

**Status: partial; fixtures unrun.** Hex movement, facing and close combat. Neutral source: `full-2008`, B384-B392.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-tactical.t` after the expanded foundation, or use the
all-module umbrella. It supplies geometry, movement-value assessments and owned encounter placement.
Including it does not activate tactical movement or replace existing combat.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

The [maneuver and posture inventory](inventory/maneuvers-postures.json) records
the B551 summary. Posture changes attack and defense modifiers, legal reach,
movement allowance and occupied hexes. Ranged target modifiers apply only to the
listed body regions; they are not blanket concealment bonuses. Low attackers also
have restricted access to parts of a standing target.

Assessment must resolve posture, facing, footprint and maneuver permissions
before spending movement. The detailed B384–B392 transition rules still need
review. Summary rows alone do not establish legal paths, rounding or interruption
behavior. Critical mishaps that move a combatant past an opponent need explicit
handling of blocked destinations and changes of facing.

The [basic combat movement inventory](inventory/combat-turns.json) now records
B367–B368. Step distance rounds upward; a multi-yard step may surround an action,
but a kneel/stand transition consumes the entire allowance. Evasion requires
enough movement to pass the opponent, a physically possible route and no grapple
restraint. An opponent who permits passage requires no contest. These rules still
need reconciliation with the detailed hex movement chapter.

The [tactical chapter inventory](inventory/tactical.json) now covers the first
text pass through B384–B392. Facing, reach and large-body diagrams have also been
inspected. This remains a requirements inventory: coordinate fixtures cover adjacent facing, and owned Move paths now execute through the battle scheduler. General maneuver and interruption coverage remains incomplete.
Neither these fixtures nor the merged suite have been validated.

Movement assessment needs an ordered path containing position, heading, posture,
terrain costs and occupied cells. Forward diagonal movement changes facing,
while a sidestep preserves it at a different cost. Free final facing depends on
the maneuver and spent budget. A step follows different cost rules from a full
movement maneuver, so one generic path budget would produce incorrect results.

Close combat retains each participant's entry side within a shared hex. Near-side
exits, crossing an opponent, grapple restrictions and available weapon reach all
depend on that state. Failed close-combat readying also differs from failed
readying while grappled; the combined case needs explicit precedence.

Ranged paths retain the chosen line, intervening occupants and their order.
Stray shots continue after a miss or dodge but stop after a hit, block or parry.
Opportunity fire can interrupt movement, and multiple triggered attacks can be
simultaneous. A pop-up attack must expose the actor to those reactions before
returning to cover. Preview must not reveal private watched areas or commit a
target-discrimination roll.

Large bodies require complete footprint and swept-path checks. Their head or
front controls movement and vision, but body sections can travel farther and
strike smaller figures. Body clearance, collision consequences and remaining
movement must be preserved together across rollback, undo and saved games.

Independent validation must cover all six rotations, the depicted reach rings,
partial barriers, fractional movement costs, interrupted paths, occupied exits,
simultaneous reactions and each opportunity-fire band. No checks have been run
while the requested pause remains in effect.

The [special-mobility inventory](inventory/special-mobility.json) adds high-speed
and aerial requirements. Velocity persists separately from movement capacity.
Turning depends on distance traveled since the preceding turn of direction, and
terrain costs can also force deceleration. An invalid high-speed maneuver can
cause loss of control even without a failed roll.

Ground, water and air use different control-loss consequences. Flying paths need
altitude, clearance and nonhovering stall limits; a dive can temporarily change
acceleration and maximum speed. The optional realistic turning formula and
encumbrance-based posture duration require explicit campaign selection. Neither
may silently replace the default procedure.

The [targeting and elevation inventory](inventory/targeting-elevation.json)
records vertical-distance bands and size-based reach. Extra reach reduces the
effective vertical separation for its user only. Each actor can therefore have
different legal locations and modifiers in the same exchange. Above the normal
vertical limit, unusual postures require concrete authored geometry and exposed
locations before assessment can accept an attack.


## Coordinates, facing and barriers

`RpgExpandedHex` stores integer axial coordinates `q` and `r`, each bounded to
plus or minus one million. `rpgExpandedHex(q, r)` constructs a coordinate.
Coordinates are a library convention: each neighboring cell is one yard away.
With north at the top, headings 0 through 5 run clockwise: east, southeast,
southwest, west, northwest and northeast. Their axial offsets are respectively
`[1,0]`, `[0,1]`, `[-1,1]`, `[-1,0]`, `[0,-1]` and `[1,-1]`.
`rpgExpandedHexNeighbor(origin, heading)` constructs an adjacent coordinate;
a neighbor beyond the supported coordinate bounds is rejected.

`rpgExpandedHexDistance(from, to)` returns geometric grid distance in yards.
It does not calculate a legal route, movement points, sight lines or weapon reach.
Equal coordinates have distance zero without implying permission to share a hex.

`rpgExpandedFacingSide(facing, heading)` returns `front`, `right`, `back` or
`left`. The facing direction and its two neighbors are front. For a concrete
adjacent target, use `RpgExpandedFacingAssessment` with `origin`, `target`,
`facing` and `handedness` (`right` or `left`). Its result supplies `heading`,
`side`, `weaponSide` and `shieldSide`; the last two identify lateral sides only.
Same-hex and nonadjacent targets return `tactical-adjacent-required`. This is
explicitly not a vision cone or a defense modifier for distant targets.

`RpgExpandedHexTerrain` requires a coordinate and a `barrier` of `none`,
`partial` or `solid`. `assess()` accepts partial hexes by default and blocks
solid ones. To disallow a partially obstructed hex, set `partialAllowed = nil`
and provide nonempty `rulingEvidence` describing the concrete obstruction.
The resulting reason distinguishes that author ruling from a solid barrier.
This assessment addresses barriers only: `ready` does not certify occupancy,
posture, terrain cost, clearance or a complete movement path.

These geometry interfaces spend neither time nor randomness and install no persistent
figure state. Owned placement is described below. The minimal
[fixture](../../tests/fixtures/expanded-tactical.t) and `test_tactical_geometry`
specify all six rotations, both handedness choices, adjacency rejection,
distance examples and barrier decisions. They are authored but unrun. Posture transitions and path execution still need their own transaction/save
fixtures before tactical encounters are playable.


## Movement costs and heading changes

The following pure assessments implement parts of `full-2008` B385–B387. They
are inputs to the future path executor, not permission to move a figure directly.
Their [minimal fixture](../../tests/fixtures/expanded-tactical.t) is wired into
`test_tactical_movement_values`; no checks have been run.

`rpgExpandedMovementAllowance(move, maneuver)` accepts `move`, `move-attack`,
`committed-attack` or `increased-dodge`. Its `halfPoints` represents twice the
movement-point allowance, preserving half-point costs exactly. Ordinary movement
uses the supplied Move; committed attack and increased dodge use half Move rounded
up. Committed attack separately reports `alternativeHexes = 2`. Do not add this
hex allowance to the point budget or silently treat two hexes as two points.
Its interaction with difficult terrain still needs path-level reconciliation.

`RpgExpandedHexEntry` takes adjacent `origin` and `target` coordinates, `facing`,
`maneuver`, `travel`, `posture` and a concrete `terrain` record whose coordinate
must match the target. `travel = 'forward'` requires a front hex, costs one point
and changes heading to the entered direction. `travel = 'sidestep'` preserves
heading at two points; this identifier also covers backward movement. A committed
attack allows a front sidestep, but never a side or rear entry.

Postures are `standing`, `crouching`, `kneeling`, `crawling`, `lying` and `sitting`.
Crouching adds half a point; kneeling and crawling add two points. Set
`minorObstructions` to the number of actual minor obstacles. Each adds a point.
`treacherous` adds `footingExtra` points, default one; a larger author-assigned
cost requires nonempty `footingEvidence`. `stairs` and `water = 'shallow'` each
add one point. The author must establish the shallow-water depth relative to the
figure; the library does not infer it from a world label.

Lying or deep water returns `wholeAllowance = true` and zero numeric
`halfPoints`. Zero is a sentinel in this case, **not free movement**: entry consumes
the whole allowance. The future path executor must reconcile this with other
costs and the one-hex minimum-progress rule before accepting a complete path.
Sitting blocks movement. Solid barriers remain blocked. `severeObstruction`
returns `tactical-jump-required`, and `enemyPresent` returns
`tactical-evasion-required`; neither procedure is automatically executed.

`rpgExpandedMovementTurn(facing, targetFacing, maneuver)` prices a before/during
turn at one point per hex-side, choosing the shorter rotation. Committed attack
returns a separate-procedure requirement; its stationary turn must not borrow
the ordinary paid moving-turn rule. `rpgExpandedFacingDistance` exposes the
underlying zero-to-three-side distance.

`rpgExpandedFinalFacing(facing, targetFacing, maneuver, allowanceHalfPoints,
spentHalfPoints)` assesses the free final facing change. Move and move-and-attack
permit any direction after spending at most half the allowance, otherwise only
one hex-side. Increased dodge permits any final direction. Committed attack
forbids a changed final heading. These supplied totals must come from the eventual
validated path; this helper does not independently establish a legal budget or
minimum-progress exception.

A step is a separate procedure. Do not apply these movement-point costs to its
hex allowance. Owned initial positions and occupancy queries are available below. Footprint
transitions, minimum progress, step execution, interrupted movement and
battle-clock integration remain pending.


## Owned encounter placement

`RpgExpandedTacticalMap` is a finite encounter map with an `id` and an authored
`cells` list of `RpgExpandedHexTerrain` objects. Repeated coordinates are invalid.
A missing cell is unknown, not passable ground. Its `figures` and `placements`
are persistent owned records populated by successful placement operations.

Create one `RpgExpandedTacticalFigure` per character with a unique map-local `id`
and `profile`. The supported initial `bodyForm` is `upright-human`, with the
profile standing, crouching, kneeling or sitting. This describes an authored
ordinary one-hex body; it does not automatically infer anatomy from purchased
traits. Initial placement while lying, crawling, horizontal bodies, larger figures and
swarms still require further procedures. A placed upright figure can reconcile
a subsequent lying/recovery transition through the interface below.

`RpgExpandedTacticalPlacement` supplies `id`, `map`, `figure`, `coordinate`,
`facing`, `approved` and nonempty `evidence` establishing the initial encounter
position. Call `assess()` for a pure preview, then `apply()` inside an engine
transaction. Placement copies the input coordinate and installs the figure in
both the map roster and `profile.tacticalFigure`. It changes no posture, health,
time, inventory or advancement balance. A character already assigned to any map
cannot acquire a second figure through another placement.

This is encounter setup, not teleportation or a movement action. A receipt binds
its original character, figure identity, body form, coordinates, heading and
author evidence. Replay returns `reused` without resetting position. Mutating the
request cannot move the figure. Map ownership and receipt bindings are checked
when occupancy is queried. Encounter exit and transfer need explicit future
operations; do not clear ownership fields manually during play.

`map.occupancy(coordinate)` returns a structured result with `occupants` for a
known passable cell. It neither grants traversal nor authorizes sharing a hex.
Placement rejects an occupied destination with
`tactical-shared-cell-procedure-required`; close combat and friendly noncombat
crowding remain separate pending procedures. Allies can eventually be crossed at
an increased movement cost, but initial placement does not implement traversal.

The character's existing `posture` remains authoritative. If any installed figure
changes into an unsupported footprint, occupancy queries return
`tactical-footprint-transition-required`, even for another cell: an unresolved
second occupied hex cannot safely be assumed empty. Resolve supported lying/recovery transitions with `RpgExpandedFootprintChange`
before continuing map actions.
The current implementation does not intercept every existing combat posture change.

The [position fixture](../../tests/fixtures/expanded-tactical-positions.t),
`test_tactical_positions` and `test_tactical_position_persistence` specify preview,
replay, exception rollback, undo, cross-process saves, ownership, occupied cells,
barriers, missing cells, duplicate map cells and unresolved footprints. All are
unrun while checks remain paused. Saves still require the exact compiled game;
there is no migration or separate tactical save format.


## Lying and recovery footprints

`RpgExpandedFootprintChange` reconciles the geometry of an already placed
ordinary upright human after another operation changes the character's posture.
It implements the two-hex placement and choice of recovery hex from `full-2008`
B385. It does not itself grant a posture action, resolve a knockdown, change
posture, charge another second, or decide the legality of standing directly from
lying. The caller must resolve that procedure and compose both operations in the
same engine transaction. If footprint assessment is blocked, abort the enclosing
transaction or explicitly resolve the unavailable space; do not silently accept
a partially completed voluntary posture action.

Supply a unique `id`, the owned `figure`, desired `posture`, `selected` coordinate,
`approved` and concrete `evidence` for the already resolved posture change.
For `posture = 'lying'`, the current origin remains the lower-body hex and
`selected` becomes the adjacent upper-body hex. Both must be mapped, passable and
unoccupied by another figure. The operation copies the selected coordinate into
`figure.upperCoordinate`. Occupancy then reports this figure in both cells.
A previously unresolved footprint on another figure blocks the assessment.

For recovery to `standing`, `crouching`, `kneeling` or `sitting`, the selected
coordinate must be either former occupied hex. The result makes that the origin
and clears `upperCoordinate`. The profile must already have the requested posture;
this geometry interface cannot bypass the source's intermediate posture actions.
Facing is retained. Crawling and horizontal-body transitions remain unsupported.

`assess()` does not alter the figure or profile. `apply()` records the change in
`figure.footprintChanges` once. A receipt binds its request and returns `reused`
on replay without restoring an earlier footprint, including after recovery.
Changed IDs, characters, maps or selected coordinates are rejected. This is
persistent encounter state under the normal transaction/save policy, not a second
health or movement balance.

`test_tactical_footprints` and `test_tactical_footprint_persistence` specify both
occupied cells, recovery into either cell, retained posture authority, replay
after recovery, occupied-destination rejection, rollback, undo and continuation
from a saved prone figure. The fixtures are authored and unrun. Automatic
composition with every attack, fall, maneuver and death remains outstanding, as
do forced overlap, close combat and crowded-map resolution.


## Posture maneuvers in battle

`RpgExpandedPostureManeuver` composes supported posture changes with the existing
`RpgLiteBattle` scheduler. Set its `battle`, owned `figure`, destination `posture`
and, when entering or leaving lying, a fresh matching `footprint` operation.
Use zero `movement`: selecting either former occupied hex on recovery is part of
the posture transition, not additional walking. Run `battle.step(fighter, request)`
inside the usual engine action transaction.

`available(fighter)` previews destination terrain and occupancy before action
permission can consume randomness. The footprint's `assessTransition()` previews
the requested future posture without temporarily writing to the character.
Ordinary `assess()` still requires the profile's actual posture, and `apply()`
never accepts the preview as a substitute for that committed change.

After the battle resolves the posture maneuver, the adapter commits its footprint
before the scheduler advances. It spends no separate seconds. A failed footprint
commit raises an error so the enclosing transaction rolls back the posture as
well. A used maneuver or footprint cannot be reused for a later turn. Entering
lying and recovering to kneeling or sitting are supported; directly standing
from lying is rejected, following `full-2008` B364. A later kneeling/sitting-to-
standing maneuver retains the chosen recovery hex and needs no footprint object.

Crawling, free crouching, posture changes in place of a step, forced knockdown and
large-body transitions still need dedicated integration. Characters at zero or
negative HP/FP require the explicit health permission adapter described below.
Without one they return `tactical-posture-health-permission-required`, rather
than silently substituting the abridged permission procedure.
Existing unconsciousness and stun restrictions remain enforced by the battle.

The [battle fixture](../../tests/fixtures/expanded-tactical-posture.t) and
`test_tactical_posture_maneuvers` specify pure previews, atomic rollback, undo,
lying-to-kneeling-to-standing transitions, rejection of a direct rise and one
shared second per completed combat round. They remain unrun while checks are
paused. This adapter covers posture only, not a complete tactical combat engine.


### Expanded posture action permission

With the health module installed, give the posture maneuver a `healthPermission`
that is an `RpgExpandedHealthManeuver` with `kind = 'posture'` and a fresh owned
`RpgExpandedActionGate` for this character, with `purpose = 'action'` and concrete
evidence. The tactical module references the common maneuver contract, so its
minimal geometry/placement builds do not require the health module.

The outer battle executes only the tactical posture maneuver. Its
`healthAvailable(fighter)` delegates pure permission assessment, and `canAct`
delegates the single committed gate. Do not separately execute the health
maneuver or apply its gate before calling the battle. Invalid actor/purpose,
used gates and unsupported adapter kinds are rejected. Geometry availability is
resolved before either a Will or consciousness roll can occur.

The existing action gate combines exhaustion and low-HP consciousness. If it
denies permission, the battle advances the turn without changing posture or
footprint. A successful check permits the atomic posture operation. Neither the
health adapter nor footprint operation charges an extra second. With no explicit
health adapter, only positive-HP/positive-FP permission uses the inherited path.

`test_tactical_posture_health` and its
[fixture](../../tests/fixtures/expanded-tactical-posture-health.t) specify one
Will roll at zero FP, an additional HT roll at zero HP, no draws during preview
or blocked geometry, atomic rollback/undo, failed-consciousness immobility and
cross-process continuation with a used permission receipt. They remain unrun.
Forced falls from failed permission, expanded combat injuries and other footprint
changes still need their own integration; this composes voluntary posture only.


## Ordered path assessment

`RpgExpandedMovementPath` assesses an ordered `legs` list for an owned `figure`.
Each `RpgExpandedPathLeg` has `kind = 'entry'`, an adjacent `destination` and
`travel` (`forward` or `sidestep`), or `kind = 'turn'` with its target `heading`.
An optional `finalFacing` applies the free end-of-movement facing rule. The
supported maneuver choices are `move`, `move-attack` and `increased-dodge`.
Committed attack remains explicitly blocked until its alternative two-hex
allowance is reconciled with terrain and action ordering.

Supply verified `move` before posture reductions: this is the available movement
score after applicable load and health effects, not the abridged profile's
`move()` result, which already reduces movement for posture. Path assessment
adds posture costs once through the tactical table. Deriving the score from all
traits, sprinting and other movement modes remains an integration obligation.

Terrain records now expose `minorObstructions`, `severeObstruction`,
`treacherous`, `footingExtra`, `footingEvidence`, `stairs` and `water`, using the
entry-assessment contracts above. The path reads these from each actual map cell.
Its explicit `allies` list identifies figures whose cells may be crossed. Each
such occupant adds one obstruction point; do not also count that figure in the
terrain's static obstruction count. An unlisted occupant requires evasion. Ending
in an occupied cell requires the separate sharing procedure and is blocked.

The result reports copied `destination`, final `heading`, `halfPoints`,
`allowanceHalfPoints`, `enteredHexes` and ordered `stages` of
`[q, r, heading, cumulativeHalfPoints]`. Forward diagonals change the heading used
for the next leg. A path exceeding its budget is rejected unless it contains
exactly one entry and no paid turn: that one-hex minimum-progress exception is
reported as `minimumProgress`. It does not bypass barriers, sitting, evasion or
adjacency. Whole-allowance terrain accepts one entry and no paid turn, reports
`wholeAllowance`, and cannot be followed by another entry.

Only supported one-hex footprints are accepted. Lying paths require swept
footprint handling; steps, jumps, close combat, high-speed movement, opportunity
interruptions and full maneuver execution remain pending. Path assessment does
not spend time, move a figure, change its facing, authorize a world action or
consume randomness. It must be re-assessed at the eventual commit boundary.

The [path fixture](../../tests/fixtures/expanded-tactical-path.t) and
`test_tactical_paths` specify ordered headings, paid/free turns, fractional costs,
budget rejection, minimum progress, deep water, allied traversal, occupied
endpoints and required evasion. These fixtures remain unrun.

## Horizontal jump placement

`RpgExpandedJumpPlacement` implements the foundation's jump-position plan.
Supply the existing `figure`, `origin`, successful `destination`, prone `failure`
cell and adjacent `failureUpper` cell. `clearanceApproved` and `evidence` describe
an authored clear flight path and the possible landing surfaces. Intermediate
vertical clearance is an author fact; the map does not infer an arc from ground
terrain. Facing is retained.

Assign the plan to a jump launch's `positionPlan`. Horizontal hex distance must
match the launch distance exactly. Both possible endpoints and the entire prone
failure footprint must be mapped, permitted by terrain and free of other figures.
This validation runs before accuracy dice. Commit updates the same tactical
figure once, including its upper-body cell on failure; it adds no movement clock
or extra time charge. Recorded placement replays validate history without moving
a figure again.

A mapped profile must supply a position plan. The current plan supports ordinary
upright-human figures and horizontal placement only. Vertical placement requires
an elevation-aware adapter. Enhanced jumps requiring more than one second are
rejected rather than instantly placed; multi-turn travel remains pending.
`expanded-jump-placement.t` covers success, prone and critical failure, blocked
terrain, occupied cells, missing plans, rollback, undo and saved replay. Assertions
are authored, unrun while checks are paused.

## Small-obstacle jumps in a path

Set a `RpgExpandedPathLeg` to `kind = 'small-jump'` for the B352 automatic
small-obstacle procedure. Supply `actorSize`, `obstacleSize`, `jumpApproved` and
`jumpEvidence`; set `significant` when the obstacle is a deliberate hazard.
The author must establish the current character's size and that the described
small obstacle is the obstruction being crossed. The obstacle must be at least
three size steps smaller. Significant or larger obstacles require the full jump
procedure. This entry is permitted only during Move, from standing or crouching,
and currently excludes deep-water jumping.

`RpgExpandedSmallJumpEntry` adds two half-points (one movement point) to the
ordinary adjacent-entry cost. Other terrain, crouching and ally costs remain
additive. Do not also count this same obstacle in `minorObstructions`; that field
represents additional obstructions. A terrain `severeObstruction` flag can be
satisfied by this explicitly approved small jump, but solid barriers and unknown
cells remain blocked. The ordinary path allowance and final-facing rules still
apply. No accuracy roll or separate concentration/launch action is charged.

This extends pure path assessment; committing the complete path remains separate.
`test_tactical_small_jumps` covers the exact size boundary, smaller obstacles,
actor-relative size, significant hazards, Move restriction, approval, crouching,
deep water and preview purity. Assertions are authored, unrun while checks remain
paused.

## Committing an uninterrupted Move path

`RpgExpandedPathMove` binds an `id`, `fighter`, `battle` and assessed `path`.
The path must belong to that fighter's existing figure and use `maneuver = 'move'`.
Set its allowance from `profile.moveBeforePosture()`. This shares the existing
load, injury, fatigue and base-movement arithmetic while leaving posture costs
to the path, avoiding a second crouching reduction. Lite `move()` still applies
its existing posture reductions after this shared calculation.

Set `uninterrupted` and `evidence` only for an authored route with no pending
reaction, interrupt or additional hazard check. For known injury interruptions,
use the staged subtype described below. Movement attacks and other maneuvers
are not implemented by this adapter. The existing
path validation still rejects unknown terrain, unsupported footprints, unresolved
evasion and illegal destinations.

Use `RpgExpandedPathMoveManeuver` from health, with `operation` set to this object
and a fresh movement-aware `healthGate` (`requiresMovement = true`,
`mentalAbility = nil`). Pass it to the existing battle's `step`.
Leave the maneuver's separate `movement` value at zero: the path accounts for
movement points. After health permission, it captures the path and revalidates
its definition, origin, allowance, cost, destination and facing at commit. It then
updates the existing figure once. The battle charges time once at the round
boundary; neither the operation nor small-obstacle entries charge extra seconds.

A committed operation returns `reused` from assessment; replay cannot move the
figure or spend another turn. Use a fresh operation and health gate for another
turn. Exceptions and undo cover the move, permission, battle state and clock.
The `expanded-path-move.t` fixture includes small-obstacle movement, crouching,
preview, invalid inputs, rollback, undo, save continuation and Lite movement
expected values. Assertions remain unrun while checks are paused.

## Clambering onto an adjacent surface

`RpgExpandedClamber` implements the B352 two-Move alternative to a risky jump.
Bind its `id`, `fighter`, `battle`, existing `figure`, `origin` and adjacent
`destination`. Set `reachable`, `stableSurface` and `evidence` only when the
authored upper surface has suitable reachable support and no additional hazard
procedure is needed. These are world facts: a two-dimensional map does not
establish vertical reach or elevation by itself.

For each turn create `RpgExpandedClamberManeuver` with `operation` set to this
object and a fresh physical `healthGate`. Call the normal battle `step`. The first
successful turn records progress without relocating the figure. The second
consecutive successful turn moves it to the destination automatically, preserving
facing. No accuracy roll is made. The battle charges both turns normally; the
clamber operation charges neither additional time nor movement points.

A skipped turn or unrelated ledger advance restarts the sequence. Origin changes,
unsupported body support, blocked terrain and occupied destinations reject the
attempt. The destination is checked again before the second turn commits.
Completion is replay-safe; it cannot move the figure a second time. Existing
health permission handles exhaustion or incapacity independently of the automatic
clamber success rule.

This adapter supports an ordinary upright figure and an adjacent authored upper
surface. General three-dimensional movement, changing supports during a maneuver
and interrupt resolution remain pending. The clamber fixture covers completion,
skipped turns, invalid reach, occupancy, rollback, undo and saved continuation.
Assertions remain unrun while checks are paused.


## Extreme-panic escape turns

`RpgExpandedPanicPathOperation` connects an owned extreme-panic reaction to the
existing `RpgExpandedPathMove` and battle scheduler. It commits actual coordinates,
facing and path costs, uses a fresh physical health permission and retains the
turn receipt. See [panic maneuvers](health.md#panic-maneuvers-and-permission-dispatch)
for wiring, clock ownership and custom permission hooks. Movement remains subject
to the path engine's occupancy, posture, terrain, footprint and interruption limits.
The panic adapter does not substitute a narrative room move for a tactical route.
The integration and persistence fixture is authored but unrun.

## Injury interruptions during panic movement

Use `RpgExpandedInterruptedPathMove` when a route has known injury triggers rather
than declaring it uninterrupted. It uses the same `fighter`, `battle`, `path` and
Move maneuver interface. `RpgExpandedPanicPathOperation` accepts this subtype and
retains the existing one-turn permission and battle-clock handling.

Supply an ordered `interruptions` list of `RpgExpandedPathInjuryInterruption`
objects. Each declares its owning `move`, a distinct increasing `afterLeg` index,
one fresh `RpgExpandedWound` for that moving character, and an adjacent `fallUpper`
hex. Approval, `triggerEvidence` and `injuryEvidence` record why the trigger occurs
at that leg and how its final injury was adjudicated. This is a concrete injury
contract, not an implicit attack roll or a generic callback. A trap or comparable
authored event must have its damage and protection resolved separately. Body-part
injuries currently require a further adapter and reject explicitly.

Assessment verifies the complete planned route, every interruption, each wound,
and clear standing/prone stopping spaces without changing position or rolling.
Execution enters each leg in order and applies its declared injury exactly once.
A surviving, conscious, unstunned actor with unchanged posture and allowance
continues along the remaining planned legs, preserving cumulative movement cost.
An actor who dies, becomes incapacitated or changes posture stops at the trigger.
Unreached interruptions remain unspent. A prone actor's lower body remains in the
trigger hex and the upper body occupies the authored adjacent `fallUpper` hex,
as specified by full-2008 B385. Ending in a shared occupied hex is unsupported and
is rejected during assessment.

Set `reducedMovePolicy = 'stop'` and record that choice in the move's `evidence`.
This is an **author-selected stop policy**, not a claimed printed formula for
recalculating a partly completed turn. Full-2008 B419 reduces Move after injury,
but does not specify the remaining-budget treatment used here. If the allowance
falls mid-route, this policy ends movement at that trigger. Other policies are
unsupported rather than silently inferred.

The retained result separates the planned `pathResult` from actual execution:
`completedLegs`, `spentHalfPoints`, `stoppedReason`, `finalQ`, `finalR` and
`finalFacing`. Free final-facing choice is applied only when the route completes.
Neither a trigger nor resumption spends another second; the battle owns the
round clock. Definition and outcome bindings retain the actual path and wound
history across duplicate calls, rollback, undo and saved continuation.

The [interrupted panic fixture](../../tests/fixtures/expanded-panic-interrupted-path.t)
and `test_panic_interrupted_path` specify two-trigger continuation, collapse at the
first trigger, an unspent later injury, reduced-allowance stopping, preview purity,
mutation rejection and persistence. Assertions are authored and unrun.
A stationary declared Wait attack is connected by the adapter below. General
opportunity fire, nested interrupts and automatic attack resolution remain
outstanding. B366 permits a mover to resume after a Wait interrupt; the staged
executor retains the remaining path for the supported response.

### A declared stationary Wait attack

Place `RpgExpandedPathWaitInterruption` in the staged move's `interruptions` list.
It inherits `move`, `afterLeg`, `fallUpper`, approval and trigger evidence. Supply
`declaration` (an already committed `RpgExpandedWaitDeclaration`) and `strike`
(a fresh `RpgExpandedAdjudicatedStrike`). Leave the inherited `wound` field empty:
the strike owns its optional hit wound, so misses and successful defenses do not
create injury. Attacker, defender, battle, weapon, mode and the reached trigger
hex must match the declaration exactly.

The waiting fighter spends a turn when declaring, not when the route triggers
it. The interrupt commits the recorded attack at the reached hex without another
clock tick. A surviving mover continues; a knocked-down mover retains the actual
prone footprint and an unreached later trigger remains unspent. One declaration
cannot trigger twice or remain live into its fighter's next turn.

The [Wait fixture](../../tests/fixtures/expanded-panic-wait.t) and
`test_panic_wait` specify hit/miss, expiry, rollback, undo, save continuation and
one start-of-turn permission check. Assertions remain unrun. See the
[health guide](health.md#declared-wait-responses) for the explicit stationary,
ordinary-attack subset and remaining unsupported conversions.

## Critical defensive falls

`RpgExpandedDefenseFallPosition` connects a critical Dodge failure to the
existing owned footprint transition. Attach it to the recorded strike's
`RpgExpandedStrikeDefenseFailure.position`. The combat library supplies the
consequence; the tactical library supplies this concrete geometry adapter.

Provide the matching `owner`, defender `figure`, approval and evidence. For a
standing or other single-hex upright-human figure, provide a fresh `footprint`
whose posture is `lying` and whose selected adjacent hex is clear. Assessment
checks the map, figure ownership, terrain and all occupied cells before the
strike spends ammunition or commits injury. The critical failure changes posture;
the position adapter then commits the footprint in the same action transaction.
It spends neither movement allowance nor another turn. Invalid geometry rejects.

An already-prone defender requires no new footprint: leave `footprint` nil and
retain its two occupied hexes. Replays validate the recorded transition without
reapplying it. Calling the position adapter outside its owning consequence is
rejected. Other body forms, airborne falls and shared-cell falling procedures
remain unsupported.

`expanded-panic-defense-position.t` and `test_panic_defense_position` specify
preview purity, normal/already-prone resolution, occupied and invalid landing
hexes, direct-call rejection, rollback, undo and cross-process continuation.
These fixtures are authored and unrun while build checks remain paused.
