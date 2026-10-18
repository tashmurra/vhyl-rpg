# Expanded hazards

**Status: pending.** Exposure, poison, disease and aging. Neutral source: `full-2008`, B428-B444.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename is reserved in the catalogue only; do not include it in a game.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

## Source inventory

The [environmental inventory](inventory/environmental-hazards.json) covers the
first text pass through B428–B437, excluding poison and the separately recorded
[radiation procedures](inventory/radiation.json). The
[poison, illness and aging inventory](inventory/poison-illness-aging.json) extends
the first pass through B444, including infection and dependency. Enumeration
audits, cross-references and independent numeric validation remain open. None of
these inventories is evidence of implemented hazard behavior.

Exposure records must identify the source, route, protection, elapsed intervals
and resulting conditions. Air composition and pressure are independent; a sealed
suit does not automatically supply oxygen, cooling or resistance to every gas.
Cold and heat also restrict recovery of their own injury and fatigue.

Collisions require both participants' structural capacities, relative velocity,
angle and surface properties. Falls have distinct armor and location rules, and
occupants may suffer a separate sudden-stop injury. Those calculations must feed
the shared health state while preserving the identities of individual impacts.

Radiation needs dated doses rather than one resettable exposure counter. Each
dose has its own delayed reduction and permanent residue; symptom sequences and
treatments have separate schedules. Removing an internal source does not remove
already absorbed radiation. Machines use their own susceptibility and failure
rules.

Poison definitions need delivery-specific effects and protection. A multi-route
agent can affect a protected respiratory system differently from exposed eyes or
skin. Delay, repeated exposure and cyclic damage are separate clocks. Treatments
must match the identified agent and change only its eligible future effects.
The mechanical catalogue uses neutral identities and abstract game doses.

Illness adds hidden acquisition and immunity, contagious periods, contact history
and restricted natural healing. Infection of a wound uses its own contamination
modifiers and surgical eligibility. These procedures must share the wound and
treatment records managed by health rather than creating parallel injury totals.

Intoxication and withdrawal require stage, consumption and daily-progress records.
Their low-target resistance rolls are explicit exceptions to the usual rejection
of impossible ordinary skill attempts. Temporary drug effects must preserve the
traits they suppress so expiry does not delete the character's original abilities.

Aging schedules depend on lifespan traits and the campaign calendar. Each event
has four ordered checks with special critical and longevity rules. Store the date
and origin of losses: rejuvenation restores age-related losses within the reversed
years, while ordinary advancement purchases and unrelated injuries remain
separately accounted.

## Unresolved supplied-source decisions

- B350 and B431 state different gravity scaling for terminal velocity. The
  selected procedure must be explicit and tested; no later revision is implied.
- B436 includes 800 rads in two adjacent effect bands. The overlap was confirmed
  in the rendered source page. Runtime range generation must wait for an explicit
  boundary policy rather than quietly choosing one row.
- Some tables give rounded measurement bands or example limits rather than a
  complete continuous formula. Supported precision and interpolation decisions
  must be documented, with unsupported combinations rejected explicitly.

These issues do not prevent inventorying other sections. They do prevent a
complete-coverage claim for the affected procedures.
