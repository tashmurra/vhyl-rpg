# Lite rules layer

This optional layer implements the mechanics supplied by **GURPS Lite Fourth
Edition, August 2004, Rev. 07/12/04** (`gurps-lite-4e`, printed pp. 2–32).
It is a rules library, not a GM: it resolves declared circumstances but does not
invent an NPC's motives, map geometry, legal system, disease or alternate world.
The original rulebook is not included in the release.

## Integration and compatibility

```text
#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
```

The umbrella includes characters, catalogues, equipment, health, combat,
exploration and traits in dependency order. Do not include a component twice.
Use `RpgLiteProfile` for both PCs and NPCs. Existing core-only games and the
simplified resilience/conflict modules are unchanged. Do not also apply their
`RpgBody` injury or `energy` spending to the same Lite activity: Lite keeps
`injury` and `fatigue` deficits, exposes `hp()` and `fp()`, and permits negative
HP/FP. The legacy `energy` property is not the Lite fatigue pool.

All changes belong inside an executing vhyl `Action` or committed dialogue
selection. vhyl then journals objects, lists, dice state, inventory, clocks,
conditions and point spending together. Exceptions roll back the action; undo
restores it. Ordinary blocked combat actions do not consume a turn, randomness,
aim or defenses. Persist activity objects on a game-owned object rather than
recreating them between commands. Logical saves belong to their exact compiled
game identity; this release does not migrate older game saves.

`rpgLiteScore`, cost/wealth calculations, derived statistics, damage-dice lookup,
range/posture lookup and defense-score queries do not draw dice or mutate a
character. Factories return new objects; keep the returned owned instance.
`rpgLiteCheck`, treatments, journeys, exposure and battle operations **do** mutate
state. Host UI previews must not call them. Numeric helpers throw `RpgError` for
unsupported inputs. Character validation adds a readable `reason` through
`RpgLiteCharacterError`.

## Units and ownership

- All clocks use whole seconds. Basic Speed uses quarters (`DX + HT`), avoiding
  floating-point truncation before deriving Move and initiative.
- Inventory weights, Basic Lift and lifting capacities use hundredths of a pound.
  Throw distance and daily hiking distance use hundredths of yards and miles.
- High jumps return inches; broad jumps return feet. Combat distance/speed are
  whole yards/yards per second. Fractional host coordinates need an explicit
  rounding policy before calling the rules.
- Damage tables return `[dice, adds]`. Damage, injury, FP, prices and points are
  integers. `rpgLitePenetration` applies half-range damage before armor and wounds.
- Profile, trait, language, training, weapon and activity instances are owned
  state. Do not share mutable ammunition, traits or training between characters.
- `rpgSpendTime` updates the game ledger. Battles, journeys, skill tasks, treatment,
  rest and Jumper charge their own elapsed time. `rpgLiteHealthTime`, needs,
  climate, fire and exposure advance only their own clocks: call those from the
  same activity's elapsed-time adapter, without charging game time again.

## Character creation and development (pp. 4–18)

Set `st`, `dx`, `iq`, `ht`, `campaignTL`, `techLevel`, `pointBudget` and the
campaign's `disadvantageLimit`. Create catalogue traits with
`rpgLiteMakeTrait(id, level, scope)`, skills with
`rpgLiteMakeSkill(id, techLevel, specialty)`, and assign `RpgTraining` investments.
`rpgLiteTraining` retrieves an existing matching skill or a default-only instance.
Training identity includes the skill ID, TL and specialty. Technological skills
require an integer TL; non-technological skills require `nil`.

`rpgLiteCatalogue.traits` and `.skills` are the complete ID inventories. Traits
have signed per-level costs, allowed levels and self-control flags. Separate IDs
represent priced alternatives, such as `luck`, `extraordinary-luck` and
`ridiculous-luck`; `flexibility` and `double-jointed`; and different wealth,
appearance and resistance levels. `scope` supplies such things as an enhanced
parry weapon skill, a vow's subject or a quirk's description. Five quirks may be
taken. Cultural and fictional permission remain authored, not inferred from IDs.

Languages have independent spoken/written levels 0–3 and an optional native
allowance. Language Talent changes effective comprehension, not purchased points.
`rpgLiteRead` rejects illiterate reading, checks IQ for semi-literacy, and allows
fluent comprehension automatically without dice.
Use `rpgLiteCharacterCost(profile,nil)` for total points and `true` for negative
components. Call `rpgLiteValidateCharacter` after assembling the sheet; it checks
budgets, incompatible variants, duplicate traits/languages and technological
learning restrictions. Generic custom traits remain possible with authored costs.

`rpgLiteStartingWealth(profile,mobile)` calculates the full or settled allowance.
Assign the result to `money` once; `rpgLiteBuy` deducts affordable purchases.
The campaign decides which items actually exist and can be bought.

The existing progression layer supplies one-time milestone receipts and
earned/unspent points. Use priced `RpgDevelopment` offers for basic attributes
and approved advantages, `rpgLiteLearn` for incremental skill investment, and
`rpgLiteBuyOff` for disadvantage removal. Set `developmentOpen` only when the
fiction permits training or a buy-off. Inborn advantages do not become freely
available merely because the character can afford them.

## Checks, social rules and traits (pp. 2–3, 8–17, 24)

`RpgLiteContext` selects the attribute or skill and facts such as darkness,
off-hand use, close quarters, language, speech comprehension, deception,
unnecessary risk and a nearby phobic stimulus. `rpgLiteScore` applies the relevant
trait, shock, encumbrance and situational modifiers. Existing `rpgCheck` and
`rpgEvaluate` supply success/critical and Quick Contest arithmetic;
`RpgLiteRegularContest` repeats until exactly one side succeeds.

Use `rpgLiteReactionModifier` with `RpgLiteSocialContext`, then roll 3d and pass
the modified total to `rpgLiteReaction`. Predetermined reactions require no dice.
`rpgLiteInfluence` performs the opposed skill/Will contest, Intimidation and Sex
Appeal outcomes, and Diplomacy's better-of-two-reactions rule. Recognition,
attraction, cultural relevance and what a successful request obtains belong to
the scene. `rpgLiteNotice` composes senses, optional comprehension and Danger
Sense; `rpgLiteEmpathy` returns the secret check, leaving truthful versus
misleading impressions to the author. `rpgLiteFright` sets stun/faint durations.

Mental disadvantages are not just price tags: `RpgLiteObligation.begin` resolves
self-control or voluntary surrender; `permits(action)` asks the authored
`action.satisfies(obligation)` predicate. Use it in action availability. The game
must define triggers and consequences for anger, greed, honesty, bloodlust,
jealousy, duties, vows and similar fictional obligations. `RpgLitePhobia` tracks
initial and ten-minute checks; pass its presence into affected check contexts.
Truthfulness, bad sight, hard hearing, reaction penalties and combat pacifism
also have direct numeric/situational hooks. `mitigated` disables a trait's current
effect without refunding its point cost, e.g. corrected vision.

Luck uses **real play time**, not adventure elapsed time. The host supplies the
monotonic `playSeconds` value. Override `context.reroll(profile,result)` or
`maneuver.reroll(profile,kind,roll)` to decide immediately after the initial roll,
before consequences. Combat kinds are `attack`, `enemy-attack`, `defense` and
`damage`; the enemy-attack case chooses the worst of three. The low-level
`rpgLiteReroll` supports raw success, damage, reaction or external-event dice
totals, and enforces the shared cooldown. For damage, reroll the dice **before**
adding constant damage modifiers. `rpgLiteLuck` additionally requires the last
recorded check and unchanged RNG position. Never use it to change a check whose
consequences have already been applied. `rpgLiteUnluckiness` gates an authored
misfortune once per session; the GM decides the misfortune.

`RpgLiteJump` implements separate time/world Jumper abilities, concentration,
the hurry penalty, IQ ceiling, fatigue, unsafe destination refusal and critical
misrouting. Its `available` and `arrived` hooks supply world structure and a
safe corresponding location within the published tolerance. It is not a
general spell or supernatural-power system.

## Equipment and combat (pp. 18–22, 24–30)

Factories supply the printed armor/shields and melee/ranged weapon tables.
Weapons have independent attack modes (one-based `modeIndex`), ammo, reserves,
reload progress, readiness and muscle-powered weapon ST. A new weapon is
unloaded and unready. Inventory includes its listed loaded weight; reserve
ammunition and other carried supplies should be authored `RpgLiteItem`s with
the appropriate weight, rather than counting their integer reserve quantity as
weight. Wear armor with `worn = true`; ready shields separately. Reloading
advances through Ready maneuvers, including individual loading and crossbow
strength/goat's-foot restrictions.

Create one `RpgLiteFighter` per participant and an owned `RpgLiteBattle` containing
them. `begin()` sorts Basic Speed, DX and random ties; `current()` identifies the
next actor. `step(fighter,request)` handles `nothing`, `move`, `posture`, `aim`,
`attack`, `all-out-attack`, `move-attack`, `all-out-defense`, `concentrate` and
`ready`. All-Out Attack options are `determined`, `double`, `strong`; All-Out
Defense options are `dodge`, `block`, `parry`, `double`. Ready option `reload`
advances ammunition; otherwise it readies the selected weapon.

The request supplies target, reach, distance, speed, size, lighting, visibility,
awareness, shield side, available hands, movement, threat and lethal intent.
These are world facts, not discoveries by the library. `available` vetoes an
illegal tactical action before dice; `apply` moves actors or updates other world
state after resolution. Use `offWeapon`/`offModeIndex` for a second weapon.
`parry-other` selects the other hand for a second distinct defense. Aim tracks
target and weapon; changing activities or being distracted loses it.

The engine resolves critical hits, defenses, DR, wound type, major wounds and
death checks, including armed parries against unarmed attacks. Requested defense
can be `dodge`, `block`, `parry` or `parry-other`; the second defense is attempted
only when legal. Initiative and maneuver state remain stable across undo/save.
`finish()` applies end-of-battle fatigue after a fight longer than ten seconds.
Victory, surrender, retreat, rescue and when combat ends are game decisions.

## Travel, recovery and hazards (pp. 22–24, 29–32)

`RpgLiteJourney` persists exertion and interval checks for hiking, sprinting,
paced running, swimming, climbing and overloaded movement. Climb surface IDs
and exact feet/rungs-per-minute rates come from `rpgLiteClimbData`; its rounded
`speedHundredths` convenience value is not a substitute for exact long-distance
integration. Distance, terrain, available routes and a secured rope's actual
fall distance are authored facts. Independent helpers calculate jumping, lift,
throwing, hiking mileage, collisions and Catfall-adjusted falls.

`RpgLiteSkillTask` supports timed/repeated tasks, opposed concealment/search and
other skill contests, escape retries, lockpicking time, forgery inspection and
survival injury. Select the opponent score, context and authored interval where
the book delegates those decisions to the GM. Scene-specific effects such as
discovering clues, commanding animals or piloting a particular vehicle remain
consequence hooks, not generic world simulation.

Health distinguishes injury, shock, stun, fainting, mortal wounds, death and
fatigue collapse. `rpgLiteWound` applies threshold checks; `rpgLiteCanAct` handles
negative-HP/FP effort. `RpgLiteTreatment` persists bandaging and treatment,
prevents repeated bandage healing on unchanged wounds, and consumes supplies.
`rpgLiteRest` recovers only eligible fatigue and daily natural healing; food,
water, sleep, illness and temperature impose their respective restrictions.

Use one `RpgLiteNeeds` per character with meals supplied per day, water quarts,
climate-required quarts and active/inactive status. It tracks missing meals,
eight-hour dehydration, daily severe dehydration and missed sleep. Sleep debt
requires uninterrupted sleep; dehydration requires a day of rest with water.
`RpgLiteClimate` preserves partial cold/heat intervals and environmental recovery
locks; set `sheltered` only for genuinely protective conditions. `RpgLiteFire`
tracks burning clothes, distraction and extinguishing. Direct exposure to flames
uses the ordinary burning-damage helpers with the GM-selected intensity.

`RpgLiteHazard` defines a poison/disease; `RpgLiteExposure` keeps incubation and
cyclic resistance/damage state. Disease injury cannot heal naturally until
recovery. Remedies adjust the disease's recovery modifier. A continuing poison
environment is represented by repeated exposures at the authored interval.
Suffocation tracks lack of air, fatigue, unconsciousness, four-minute death and
possible lasting IQ loss; a drowning scene must also require the rescuer's
First Aid check before restoring clean air.

## Source boundaries and GM rulings

- The supplied damage table covers ST 1–20; its lookup rejects values beyond
  that range rather than inventing Basic Set extensions. Restrict development
  offers accordingly, or author a separate higher-ST table.
- The printed speed/range table omits some intermediate rows and ends at 100
  yards. Lookup uses the next supplied row; notably it does **not** silently add
  a seven-yard row. Supply `rangeModifier` explicitly beyond that table.
- Falling heights between printed rows use the next supplied height; fractional
  collision dice use the integer part, with the published below-one-die minimum.
  These are explicit library rounding policies, not additional printed rules.
- Lite lists RoF and shotgun pellet statistics but does not supply the Basic
  Set rapid-fire/recoil hit procedure. A strike resolves one projectile; a host
  choosing a multi-projectile policy must label that as its own ruling. No
  unsupported recoil or hit-location system is smuggled into this layer.
- The running/swimming rule's one-third-FP boundary is retained for those
  activities; the general fatigue penalty uses strictly less than one third.
- Narrative obligations, NPC reactions to conduct, talent-related professional
  respect, permissions to acquire advantages, destination safety and campaign
  creation are deliberate GM interfaces, not random automatic behavior.

## Play and validate

```sh
"$ZEBC" build examples/lite/main.t --include-dir lib \
  --include-dir "$VHYL_ROOT/lib" --emit shared --opt O2 \
  --out-dir build/training-yard --runtime-cache build/runtime-cache
python3 examples/lite/host.py build/training-yard --vhyl "$VHYL_ROOT"
```

Try `hike`, `rest`, `spar`, `attack`, `defend`, `recover`, `stop`, `treat wounds`,
`rest day`, `status` and `undo`. `:odds` displays the current sheet; the example
is parser/structured-action driven, not a dialogue-menu showcase.

`python tools/test.py --native` runs the existing regressions plus independent
Lite table/boundary checks, character investment, combat rejection, recovery,
needs, exposure, deterministic undo, exception rollback and cross-process
continuation. See the generated library reference for source-linked signatures.
