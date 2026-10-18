# Expanded hazards

**Status: partial.** Exposure, poison, disease and aging. Neutral source: `full-2008`, B428-B444; B540.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-hazards.t` after the expanded foundation and expanded health. The current
implementation supplies infection assessments and owned acquisition receipts;
it does not yet commit daily progression. The all-module umbrella includes these capabilities
without activating any hazard.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

## Source inventory

The [environmental inventory](inventory/environmental-hazards.json) covers the
first text pass through B428–B437, excluding poison and the separately recorded
[radiation procedures](inventory/radiation.json). The
[poison, illness and aging inventory](inventory/poison-illness-aging.json) extends
the first pass through B444, including infection and dependency. Enumeration
audits, cross-references and independent numeric validation remain open. Only the explicitly linked partial entries below have runtime assessments;
the inventories do not imply complete hazard behavior.

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


## Fictional memory effects

The [setting-content inventory](inventory/setting-mechanics.json) includes a
fictional agent with resistance, unconsciousness and recent-memory effects. Its
source name and associated setting are excluded. The printed description does not
fully specify onset, unconscious duration or the anchor for its lost-memory window;
those details require a documented author contract before the effect is supported.

A memory effect must change what the affected character can recall while preserving
what actually happened in the world. It must not undo purchases, wounds, movement or
other committed events. Delivery, dose inventory, permissions and repeated exposure
also need their own validation. This entry remains pending; it is not an implemented
hazard or a real chemical specification.


## Infection assessment

`RpgExpandedInfectionContext` records the B444 contamination and treatment facts:
`infectedMatter`, `specialLocale`, `antibiotics`, `medicalTL`,
`criticalTreatmentFailure` and `untreatedDirtyWound`. The author establishes wound
exposure; the context does not infer contamination from a room name or injury.

`assessAcquisition()` returns `checkRequired` and an HT modifier of +3 plus
contamination penalties for an established untreated dirty wound. Infected matter
contributes -2 and a special-infection locale -3; ordinary dirt contributes zero.
These replace general contagion modifiers. Qualifying antibacterial care at
technology six or higher returns `prevented` without requiring a check.

A critical treatment failure blocks with
`infection-critical-treatment-adjudication`: the prevention exception needs an
explicit treatment-outcome contract before committed exposure is supported.
Lower-technology antibacterial care blocks. Unestablished exposure also blocks;
this does not assert immunity or absence of infection.

`assessTypicalProgression()` describes a typical existing infection: a daily
86400-second interval, one injury on failed HT, and an end to infection on success.
Its HT modifier includes contamination and +3 for qualifying antibiotic treatment.
The acquisition check's initial +3 is not added to the daily HT check. Special
infections may specify different procedures and are not represented by this
method. The reported injury is not capacity-scaled healing.

Both methods return `RpgExpandedInfectionAssessment` and consume no time or
randomness. They do not establish infection, secretly roll acquisition, maintain
an owned disease history, restrict recovery or apply injury. Those mechanisms
remain incomplete. The minimal fixture
[`expanded-hazards.t`](../../tests/fixtures/expanded-hazards.t) exercises the
library independently; `test_infection_assessments` covers combined modifiers,
prevention, daily treatment, unsupported cases and preview purity. Checks remain
paused, so these fixtures are unrun.


## Owned wound exposure

`RpgExpandedInfectionExposure` takes a committed expanded `wound`, an
`RpgExpandedInfectionContext` as `conditions`, and authored `evidence` identifying
its open-wound exposure. `assess()` performs eligibility checks without consuming
randomness. `apply()` resolves the acquisition check once through the shared HT
and disease-resistance context, or records prevention without rolling. It does
not spend additional time for discovering an exposure that already occurred.

The wound's `infectionExposure` owns the receipt. Its `acquiredAt` captures the
shared time ledger. Repeated calls return the original result; another object
for that wound is blocked. Conditions and evidence bind on commit and cannot be
changed to obtain another roll. New contamination of the same wound is currently
unsupported rather than silently treated as a fresh exposure.

The result's `infected`, `prevented` and `check` fields are private author state.
The library emits no event announcing infection; hosts must preserve hidden
acquisition until an appropriate discovery or symptom procedure permits it.
This receipt is not a symptom, diagnosis, or disease-damage record.

The module now depends on expanded health for authoritative wound ownership.
Existing disease-resistance bonuses are reused. Complete immunity, unusually low
resistance scores, critical-treatment exceptions, progression, recovery locks,
reinfection and discovery contracts remain incomplete. Acquisition rollback,
undo and save fixtures also remain to be added. `test_infection_acquisition`
covers resistance, infection, prevention, preview purity and repeat protection;
these authored cases remain unrun while checks are paused.
