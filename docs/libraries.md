# Library selection

Essential means required by the selected integration, not enabled in every game.
Include the engine once. For Lite, include progression followed by the Lite umbrella; do not also include its components separately. Expanded integrations add the expanded foundation after this sequence.

**The expanded conversion is incomplete.** Ten feature modules currently provide the scoped mechanics described below. Remaining modules are a roadmap, not includeable libraries. The [coverage ledger](expanded/coverage.json) is a chapter-level inventory; detailed catalogue enumeration remains unfinished.

## Core / essential

| Library | Include | Dependencies | Compatibility | Status | Guide / example |
| --- | --- | --- | --- | --- | --- |
| Core engine | `vhyl-rpg.t` | vhyl | Core | Available | [Guide](authoring.md) / [example](../examples/hybrid/main.t) |
| Expanded foundation | `vhyl-rpg-expanded.t` | Core + progression + Lite | Expanded profiles | Experimental | [Guide](expanded/index.md) / [example](../examples/expanded/main.t) |
| Lite catalogue | `vhyl-rpg-lite-catalogue.t` | Lite umbrella order | Lite component | Available | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite characters | `vhyl-rpg-lite-characters.t` | Lite umbrella order | Lite component | Available | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite combat | `vhyl-rpg-lite-combat.t` | Lite umbrella order | Lite component | Available | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite equipment | `vhyl-rpg-lite-equipment.t` | Lite umbrella order | Lite component | Available | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite exploration | `vhyl-rpg-lite-exploration.t` | Lite umbrella order | Lite component | Available | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite health | `vhyl-rpg-lite-health.t` | Lite umbrella order | Lite component | Available | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite traits | `vhyl-rpg-lite-traits.t` | Lite umbrella order | Lite component | Available | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite umbrella | `vhyl-rpg-lite.t` | Core + progression | Lite | Available | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Progression | `vhyl-rpg-progression.t` | Core | Core or Lite | Available | [Guide](progression.md) / [example](../examples/resilience/main.t) |

## Optional

| Library | Include | Dependencies | Compatibility | Status | Guide / example |
| --- | --- | --- | --- | --- | --- |
| Conflict | `vhyl-rpg-conflict.t` | Core + resilience | Simplified profiles | Available | [Guide](resilience.md) / [example](../examples/resilience/main.t) |
| Expanded all | `vhyl-rpg-expanded-all.t` | Core + progression + Lite | Expanded profiles | Experimental; available modules only | [Guide](expanded/index.md) / [example](../examples/expanded/main.t) |
| Expanded campaign | `vhyl-rpg-expanded-campaign.t` | Expanded foundation + equipment | Expanded profiles | Partial: legal access, employment, wealth and recurring finances | [Guide](expanded/campaign.md) / [minimal fixture](../tests/fixtures/expanded-campaign.t) |
| Expanded characters | `vhyl-rpg-expanded-characters.t` | Expanded foundation | Expanded profiles | Partial | [Guide](expanded/characters.md) / [example](../examples/expanded/main.t) |
| Expanded combat | `vhyl-rpg-expanded-combat.t` (proposed) | Expanded foundation | Expanded profiles | Not implemented | [Guide](expanded/combat.md) / no example yet |
| Expanded creatures | `vhyl-rpg-expanded-creatures.t` (proposed) | Expanded foundation | Expanded profiles | Not implemented | [Guide](expanded/creatures.md) / no example yet |
| Expanded development | `vhyl-rpg-expanded-development.t` | Expanded foundation + skills | Expanded profiles | Partial | [Guide](expanded/development.md) / [example](../examples/expanded/main.t) |
| Expanded equipment | `vhyl-rpg-expanded-equipment.t` | Expanded foundation | Expanded profiles | Partial | [Guide](expanded/equipment.md) / [example](../examples/expanded/main.t) |
| Expanded exploration | `vhyl-rpg-expanded-exploration.t` | Expanded foundation | Expanded profiles | Partial | [Guide](expanded/exploration.md) / [example](../examples/expanded/main.t) |
| Expanded hazards | `vhyl-rpg-expanded-hazards.t` (proposed) | Expanded foundation | Expanded profiles | Not implemented | [Guide](expanded/hazards.md) / no example yet |
| Expanded health | `vhyl-rpg-expanded-health.t` | Expanded foundation | Expanded profiles | Partial: supported wounds, upper-limb effects and recovery | [Guide](expanded/health.md) / [minimal fixture](../tests/fixtures/expanded-health.t) |
| Expanded magic | `vhyl-rpg-expanded-magic.t` (proposed) | Expanded foundation | Expanded profiles | Not implemented | [Guide](expanded/magic.md) / no example yet |
| Expanded psionics | `vhyl-rpg-expanded-psionics.t` (proposed) | Expanded foundation | Expanded profiles | Not implemented | [Guide](expanded/psionics.md) / no example yet |
| Expanded skills | `vhyl-rpg-expanded-skills.t` | Expanded foundation | Expanded profiles | Partial | [Guide](expanded/skills.md) / [example](../examples/expanded/main.t) |
| Expanded social | `vhyl-rpg-expanded-social.t` | Expanded foundation | Expanded profiles | Partial: standing, reactions, trade, information and loyalty | [Guide](expanded/social.md) / [minimal fixture](../tests/fixtures/expanded-social.t) |
| Expanded tactical | `vhyl-rpg-expanded-tactical.t` (proposed) | Expanded foundation | Expanded profiles | Not implemented | [Guide](expanded/tactical.md) / no example yet |
| Expanded technology | `vhyl-rpg-expanded-technology.t` (proposed) | Expanded foundation | Expanded profiles | Not implemented | [Guide](expanded/technology.md) / no example yet |
| Expanded templates | `vhyl-rpg-expanded-templates.t` | Expanded foundation + characters + skills | Expanded profiles | Partial | [Guide](expanded/templates.md) / [example](../examples/expanded/main.t) |
| Expanded traits | `vhyl-rpg-expanded-traits.t` | Expanded foundation | Expanded profiles | Partial | [Guide](expanded/traits.md) / [example](../examples/expanded/main.t) |
| Expanded vehicles | `vhyl-rpg-expanded-vehicles.t` (proposed) | Expanded foundation | Expanded profiles | Not implemented | [Guide](expanded/vehicles.md) / no example yet |
| Reporting | `vhyl-rpg-report.t` | Core | Core assessments | Available | [Guide](reporting.md) / [example](../examples/hybrid/main.t) |
| Resilience | `vhyl-rpg-resilience.t` | Core | Simplified profiles | Available | [Guide](resilience.md) / [example](../examples/resilience/main.t) |

Do not apply simplified resilience/conflict pools to a Lite or expanded activity. The full umbrella does not enable wildcard skills, exceptional character limits or instant tasks.
