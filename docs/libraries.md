# Library catalogue

Essential means a dependency of the selected integration, not an instruction to enable every module. Include each umbrella or its ordered components once. Do not mix simplified resilience pools with Lite/expanded injury state. Expanded modules are experimental; see the [prerelease notes](releases/v1.2.0-alpha.1.md).

## Core / essential

| Library / purpose | Include | Dependencies | Compatibility | Status | Guide / example |
| --- | --- | --- | --- | --- | --- |
| Core engine | `vhyl-rpg.t` | vhyl | Core | Existing | [Guide](authoring.md) / [example](../examples/hybrid/main.t) |
| Expanded foundation | `vhyl-rpg-expanded.t` | Core + progression + Lite | Expanded | Experimental prerelease | [Guide](expanded/index.md) / [example](../examples/bellwether/main.t) |
| Lite catalogue | `vhyl-rpg-lite-catalogue.t` | Lite umbrella order | Lite component | Existing | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite characters | `vhyl-rpg-lite-characters.t` | Lite umbrella order | Lite component | Existing | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite combat | `vhyl-rpg-lite-combat.t` | Lite umbrella order | Lite component | Existing | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite equipment | `vhyl-rpg-lite-equipment.t` | Lite umbrella order | Lite component | Existing | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite exploration | `vhyl-rpg-lite-exploration.t` | Lite umbrella order | Lite component | Existing | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite health | `vhyl-rpg-lite-health.t` | Lite umbrella order | Lite component | Existing | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite traits | `vhyl-rpg-lite-traits.t` | Lite umbrella order | Lite component | Existing | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Lite umbrella | `vhyl-rpg-lite.t` | Core + progression | Lite | Existing | [Guide](lite.md) / [example](../examples/lite/main.t) |
| Progression | `vhyl-rpg-progression.t` | Core | Core/Lite | Existing | [Guide](progression.md) / [example](../examples/resilience/main.t) |

## Optional

| Library / purpose | Include | Dependencies | Compatibility | Status | Guide / example |
| --- | --- | --- | --- | --- | --- |
| Character/social umbrella | `vhyl-rpg-expanded-character-social.t` | Expanded foundation + five modules | Expanded | Experimental prerelease | [Guide](expanded/index.md) / [example](../examples/bellwether/main.t) |
| Conflict | `vhyl-rpg-conflict.t` | Core + resilience | Simplified | Existing | [Guide](resilience.md) / [example](../examples/resilience/main.t) |
| Expanded characters | `vhyl-rpg-expanded-characters.t` | Expanded foundation | Expanded | Experimental prerelease | [Guide](expanded/characters.md) / [example](../examples/bellwether/main.t) |
| Expanded skills | `vhyl-rpg-expanded-skills.t` | Expanded foundation | Expanded | Experimental prerelease | [Guide](expanded/skills.md) / [example](../examples/bellwether/main.t) |
| Expanded fright | `vhyl-rpg-expanded-fright.t` | Expanded foundation + traits | Expanded | Experimental | [Guide](expanded/fright.md) |
| Expanded social | `vhyl-rpg-expanded-social.t` | Expanded foundation | Expanded | Experimental prerelease | [Guide](expanded/social.md) / [example](../examples/bellwether/main.t) |
| Expanded templates | `vhyl-rpg-expanded-templates.t` | Expanded foundation + characters + skills | Expanded | Experimental prerelease | [Guide](expanded/templates.md) / [example](../examples/bellwether/main.t) |
| Expanded traits | `vhyl-rpg-expanded-traits.t` | Expanded foundation | Expanded | Experimental prerelease | [Guide](expanded/traits.md) / [example](../examples/bellwether/main.t) |
| Reporting | `vhyl-rpg-report.t` | Core | Core | Existing | [Guide](reporting.md) / [example](../examples/hybrid/main.t) |
| Resilience | `vhyl-rpg-resilience.t` | Core | Simplified | Existing | [Guide](resilience.md) / [example](../examples/resilience/main.t) |

## Optional adjudication and magic

The [GM boundary](gm.md) is independent of magic and inference providers.
The [magic extension](magic.md) adds typed domain operations, casting and defenses,
rituals, cooperation, resources, items and world adapters on expanded characters
and skills. Its coverage ledger distinguishes executable mechanics from the
content and environment integration a game must author.
