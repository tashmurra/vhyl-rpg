# Expanded rules: experimental implementation

This is an incremental implementation, **not a complete full-reference conversion**.
The [library catalogue](../libraries.md) separates available modules from proposed
ones. The [coverage ledger](coverage.json) records implemented features, pending
modules and the unfinished detailed source inventory. The [detailed source inventory](inventory/index.md) records individual obligations
and the evidence still needed. The full conversion cannot be accepted while those
entries remain unresolved.

## Integration

```text
#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded-all.t>
```

Alternatively, include `vhyl-rpg-expanded.t` and individual available modules
once, in dependency order. Development additionally requires expanded skills;
hazards requires expanded health and skills. Character-cost queries additionally require
expanded characters.
The all umbrella includes only available modules; it is not a promise of complete
coverage. Existing Lite APIs retain their abridged behavior.

Create an owned `RpgExpandedRules` and `RpgExpandedProfile`, assigning `rules`.
Use `rpgExpandedValidateCharacter` when the characters module is installed.
Validation covers secondary limits, training-slot duplication and point budgets;
it does not yet validate the full trait/skill catalogues, social backgrounds,
ancestry exceptions or all language combinations. Never treat a successful check
as certification of a complete full-reference character.

`hpAdjustment`, `fpAdjustment`, `willAdjustment`, `perceptionAdjustment`,
`speedQuarterAdjustment` and `moveAdjustment` represent purchased changes.
Derived values remain tied to the underlying attributes. One speed unit is one
quarter point. The character cost includes each signed component separately, so
negative adjustments cannot disappear when mixed with positive adjustments.
The default limits describe ordinary characters; `exceptionalCharacteristics`
permits the wider authored range. Size-based price reductions are not implemented.
Inherited core initialization still limits declared basic attributes to 100.

Optional modules can add owned `RpgExpandedContribution` objects. A contribution
has a unique ID, an owner, a pure list of signed `amounts(profile)`, and a pure
`validate(profile)` method. Do not count skill/trait investment in a contribution
if it is already included in `skills` or `traits`.

## Skills, techniques and trait pricing

`RpgExpandedSkill` accepts difficulty 0–3. `rpgExpandedSkillLevel` and
`rpgExpandedSkillCost` implement the four difficulty columns. A wildcard uses
Very Hard difficulty, triples point prices, and requires `rules.wildcardSkills`.
A partially funded wildcard below three points has no purchased level.

`defaults` contains explicit `[skill, penalty]` pairs. Only invested source skills
supply skill defaults: a chain of untrained defaults supplies no level.
`RpgExpandedTraining.defaultFrom` explicitly selects a listed paid-up default
basis. Its current equivalent point credit combines with invested points; raising
the source skill therefore need not immediately raise the purchased destination.
Cyclic paid defaults throw an error. Automatic redistribution of investment when
switching the direction of a default is not implemented.

Skills are authored definitions, not a full catalogue. Prerequisites, familiarity,
optional specialties and technological cross-level penalties are not yet supplied.
The inherited Lite score pipeline applies its existing situational adjustments.

`RpgExpandedTechnique` is an owned contribution with a trained parent skill,
default penalty, maximum above that skill, difficulty and invested points. Add it
to `profile.contributions` to include its cost. `score()` follows the current parent
skill and rejects investment above its cap. Technique-specific maneuvers and
prerequisites beyond the invested parent are not implemented.

`rpgExpandedModifiedCost` prices positive-cost traits using a summed percentage,
a minimum 20% multiplier and upward integer rounding. `RpgExpandedTrait` requires
explicit author approval. This is **pricing only**: it neither implements the
modifiers' effects nor certifies their compatibility. Negative-cost modifiers,
the trait catalogue and special pricing exceptions remain pending.

## Numeric expansion helpers

`rpgExpandedRangeModifier` uses the full progression, including the seven-yard
row. It accepts whole yards through 100 million and rounds up to the next row.
Supply the applicable sum of range and speed; deciding whether speed matters is
a world-context decision. Existing Lite attacks do not automatically call this
helper: pass its result through the existing maneuver `rangeModifier` field.

`rpgExpandedDamageDice` supplies printed rows at ST 1–40, then 45, 50, …, 100.
Unsupported intermediate scores above 40 throw; no interpolation is invented.
It is a lookup helper, not an expanded combat integration. Existing Lite combat
continues to use its own damage table and rejects higher ST.

`RpgExpandedTaskTime.assess(rules)` returns `status`, `reason`, `modifier` and
`seconds`. Positive steps 1–5 select 2, 4, 8, 15 or 30 times normal duration.
Negative steps reduce duration by 10% each. Fractional seconds round upward,
an explicit library policy. The author must set `applicable`; combat is excluded.
Instant tasks additionally require `cinematicInstantTasks`. Skill-specific timing
rules take precedence; this helper must not be applied to spell casting.
Assessment never charges time or draws dice. A game commits the selected check
and its time once, inside an executing action.

## Study and persistence

An owned `RpgExpandedStudy` refers to a training slot already owned by its profile.
Set the mode to `job`, `self`, `education` or `intensive`, and explicitly permit
study only after the scene has checked subject prerequisites, access and materials.
`employment` is `none`, `part` or `full`. Education requires a qualified teacher;
intensive training additionally checks superior skill/investment, suitable health
and `lavishMaterials`. The supplied `teachingScore` is the author's verified
teacher qualification, not a free player input.

`assess(seconds)` is pure. `advance(seconds)` charges the common time ledger and
credits only its training subject. A started track rejects retargeting to another
profile, training slot or subject. It never grants spendable adventure points.
Credit is stored in quarter learning-seconds, preserving fractional rates and
partial intervals. Daily mode budgets are shared across the profile's study
tracks. A call crossing midnight is rejected; split it at the boundary. These
calendar days are measured from the adventure ledger's epoch. Simultaneous group
study and other overlapping elapsed-time accounting are not supported.

All mutation belongs in a vhyl Action or committed dialogue choice. Undo,
exceptions and logical saves preserve clocks and investment together. Save files
still require the exact compiled game. No old-save migration is provided.

## Outstanding conversion

Complete the detailed inventory of sections, tables and catalogue entries first.
Then finish the character/skill/trait modules, templates, social and exploration
procedures, the remaining detailed health and hazard procedures, combat/tactical
integration, supernatural systems,
creatures, technology, vehicles and campaign procedures. Each pending module has
its own guide and status in the catalogue. The planned multi-scenario examples and
complete cross-module validation are also outstanding.


### High-capacity shock

The [health module](health.md) now exposes the B419 shock divisor through an
explicit `scaledInjuryShock` rule choice. It reuses the existing injury and shock
fields; full detailed injury and treatment remain pending. The all-module umbrella
includes this capability without enabling the choice. Authored cases are unrun.


### Treatment and hazards

The health module also supplies owned supported wounds, upper-limb restrictions,
disability recovery, physician rosters and checks, bandaging and post-bandaging
care. Surgery currently has assessment helpers. These interfaces share injury,
recovery restrictions and time rather than creating another character balance.

The [hazards module](hazards.md) uses those wound records for private infection
acquisition and daily progression. It adds disease-specific first-attempt immunity
and calendar-authored aging events. Broader diseases, environmental hazards,
automatic scheduling and rejuvenation remain incomplete. Their guides and source
entries identify unsupported cases and authored test coverage; checks are paused.


The [combat module](combat.md) now supplies pure ordinary burst declaration,
rate-of-fire bonus, recoil hit-count and supplied-roll Dodge assessments. The
umbrella includes it without replacing existing attacks. Owned attack execution
and per-hit injury remain incomplete; new fixtures are authored but unrun.
