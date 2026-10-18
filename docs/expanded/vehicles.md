# Expanded vehicles

**Status: pending.** Vehicle operation, travel and combat. Neutral source:
`full-2008`, B462–B470, with integration references to B394–B396, B430–B431,
B483–B485, B548 and B554–B555.

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json) · [Detailed inventory](inventory/vehicles.json)

This module has not been implemented. Its proposed filename,
`vhyl-rpg-expanded-vehicles.t`, is reserved in the catalogue; do not include it
in a game yet. The first source pass records vehicle statistics, catalogue rows,
location codes, terrain multipliers, mount categories, travel and combat
procedures. Those records are acceptance requirements, not executable definitions.
Visual table verification, cross-reference review and validating tests remain open.

## State and integration requirements

A vehicle needs persistent physical state: components and their exposure,
location-specific protection, damage, velocity, facing, altitude or depth,
propulsion resources, cargo, occupants, controls and weapon stations. Powered
and unpowered bodies use different injury treatments. A draft creature remains
a creature with its own fatigue, injuries and training; it is not folded into
chassis health. An occupant remains the same character when embarking or leaving.

The operator controls vehicle movement on their own turn. Other occupants act on
their turns and must reach the relevant controls before using them. Movement,
weapon fire, treatment and fatigue must use the existing shared ledgers. A travel
operation must not also spend the same interval through an occupant activity or
an encounter update. Likewise, the same hit must not trigger duplicate control
checks through both damage and tactical integration.

Assessment must identify the required control skill, installed systems, route,
resource costs and possible consequences without consuming randomness or changing
state. Commit only after validating capacity, access, drive limits and the whole
requested operation. Ongoing trips, loss of control, leaks and weapon aiming need
owned records that participate in transaction rollback, undo and exact-game saves.

## Travel and control

Acceleration, maximum velocity and range describe different constraints. Road
travel depends on terrain and propulsion; rail vehicles cannot simply move off
rails at reduced speed. Sailing needs wind facts, water travel needs current and
depth, and aircraft need stall, altitude and landing constraints. Convoy leadership
can change the group's daily speed without rewriting individual vehicle profiles.
Provisions, crew fatigue and fuel must remain separate resource accounts.

Reaction-drive spacecraft spend a velocity-change budget on acceleration and
deceleration, including departure and arrival. For example, a budget of 200,000
with planned changes of 3,600, 90,000 and 88,500 leaves 17,900. An assessment that
checks only departure would incorrectly accept a trip without arrival fuel.
Constant-thrust and campaign-defined exotic travel are different drive procedures.

Control checks combine operator skill and vehicle handling. Stability determines
failure severity; it is not a general skill bonus. In combat, loss of control has
different outcomes for ground, air, surface-water and space/underwater vehicles.
A failed check also clears aim and temporarily penalizes attacks from the vehicle.
These effects require explicit expiry and recovery state.

## Combat and author decisions

Weapon mounts constrain arcs, protection, attack skill and stabilization. A moving
platform can cap accumulated aiming bonuses, while a fixed mount can cap gunner
skill by control skill. Handheld fire by the operator has its own divided-attention
penalty. Occupant defenses and cover depend on actual restraint, exposure and the
attack's target; a vehicle dodge cannot replace every occupant defense rule.

Authors must supply world facts such as obstacles, winds, water depth, recovery
opportunities, unusual drive limits and station access. The eventual interfaces
must distinguish these inputs from computed results, record the selected decision
and reject missing required input before a roll. A generic callback accepting an
arbitrary result would not satisfy these contracts.

The inventory preserves unresolved source details rather than normalizing them
silently. These include the sports-car location-code order, fractional outcomes
when combining captain and crew checks, and signed underwater depth changes.
General cruising guidance also needs explicit precedence relative to the specific
terrain and aircraft procedures. No later-printing corrections are assumed.

## Required validation

Independent cases must cover every catalogue row, terrain multiplier and mount,
plus mixed passengers and cargo, fuel exhaustion, stalled flight, rail legality,
convoy days, each control-failure category and access to controls after operator
incapacity. Combat cases must include location-specific damage, exposed occupants,
leaks, ramming, stabilization, aim expiry and optional damage scaling.

Combined fixtures must exercise creatures pulling vehicles, mounted weapons,
pressure loss, tactical footprints and sustained journeys. Preview purity,
rejected operations, deterministic replay, rollback, undo and save continuation
must cover these ongoing states. No vehicle-specific tests have been run; build
checks remain suspended while implementation continues.
