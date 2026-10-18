# Expanded combat

**Status: partial; fixtures unrun.** Maneuvers, attacks, defenses and special combat. Neutral source: `full-2008`, B357; B362-B383; B393-B417; B547-B558.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-combat.t` after the expanded foundation, or use the
expanded-all umbrella. This first implementation supplies pure ordinary rapid-fire
assessments from `full-2008`, B373–B375. It does not yet execute a complete expanded
attack. Existing Lite attacks retain their current path.

## Ordinary rapid-fire assessments

`rpgExpandedRapidFireBonus(shots)` returns the attack bonus for the actual number
of shots, including the above-99 doubling bands. One shot has no burst bonus.
`rpgExpandedAssessBurst(shots, rate, loaded, recoil)` checks a positive declared
shot count against firing rate and loaded ammunition. A ready receipt contains
`shots` and `modifier`; a blocked receipt explains the insufficient ammunition or
exceeded rate. This assessment never spends ammunition or advances time.

After a successful attack, call `rpgExpandedRapidFireHits(shots, recoil,
successMargin)` to obtain potential hits: one initial hit plus complete recoil
multiples, capped at the shots fired. Do not call it for a failed attack. The -1
margin allowed by automatic success at skill three on a four still gives the
initial hit. Critical-hit consequences and defense denial belong to the attack
resolver, which is not implemented here.

For one already-eligible Dodge, `rpgExpandedRapidFireDodge(hits, score, roll)` uses
supplied dice and returns `avoided`, `remaining` and the check. Ordinary success
avoids one plus margin; critical success avoids every hit. For example, four hits
against Dodge 10 with a roll of eight leave one hit. Automatic success on three or
four remains possible at low defense scores. These functions draw no randomness.

All counts are bounded integers. A burst can contain at most 1,000,000 shots and
recoil is limited to 1–1,000; defense scores accept -1,000–1,000. These are runtime
bounds, not additional source restrictions. The helpers model one ordinary
projectile per shot against one target. Multiple-projectile rounds, special
close-range behavior, spraying, suppression and malfunctions require their own
procedures. Do not silently route those attacks through this assessment.

`test_rapid_fire_assessments` records every printed bonus band's endpoints,
several doubling boundaries, declaration limits, recoil margins, shot-count caps,
the printed Dodge example, critical and automatic defenses, and preview purity.
The [minimal integration fixture](../../tests/fixtures/expanded-combat.t) includes
only the foundation and this module above the common dependencies. These cases
are authored but unrun while checks are paused.

Owned attack execution, ammunition commitment, independently rolled damage for
each remaining hit, injury transactions and playable encounters remain incomplete.
The inventory below is still a list of requirements, not a claim of full coverage.

The [physical-activity inventory](inventory/physical-activities.json) includes the
optional combat-effort procedures. They require declared campaign enablement,
fatigue payment before the combat roll, maneuver restrictions and additional
injury on critical failure. The rapid-attack and strong-attack options are
mutually exclusive. Ordinary will-based physical effort must not be substituted
for these combat procedures.


## Combat check classification

`rpgExpandedCombatCheck(kind, score, roll)` accepts `melee`, `ranged` or
`defense` and supplied three-die totals. It returns the shared check structure.
Under B381–B382, failure by ten is critical for melee attacks and defenses, but
not ranged attacks. Natural eighteen critically fails; seventeen critically fails
below effective skill sixteen and ordinarily fails at sixteen or higher. Critical
success thresholds use effective skill, including bonuses and penalties.

Attacks below score three remain blocked. Defenses can succeed on three or four
even at lower scores; otherwise their critical-failure margin uses the actual
score. The rapid-fire Dodge helper uses this classifier, so a low defense failing
by ten carries the appropriate critical-failure indication. No prone posture,
shield readiness or critical-table effects are applied by the classifier.

`rpgExpandedRangedOutcome(score, roll, malfunctionThreshold)` selects the next
ordinary ranged-attack branch. A nil threshold disables the optional malfunction
procedure. An authored threshold from 3 through 19 is compared with the unmodified
attack dice; nineteen cannot trigger on three dice. If a malfunction qualifies,
the result has `outcome = 'malfunction'`, and no critical table is selected even
when the underlying check critically failed. Otherwise `criticalTable` is `hit`,
`miss` or nil. Ordinary successful attacks permit defense; critical hits do not.

This is branch assessment, not execution of the selected consequences. It does
not establish that a malfunction fires zero projectiles: stoppages, for example,
have their own one-shot rule. Malfunction-number derivation, weapon eligibility,
malfunction effects, critical tables and attack/defense state transitions remain
unimplemented. The supplied dice are never rerolled and no resources are spent.

`test_combat_check_classification` records the ranged/melee distinction, low
Dodge margins, skill-sixteen and natural-roll boundaries, below-three attack
rejection, defense denial and malfunction precedence. These cases remain unrun.

## Critical-hit effect assessments

`rpgExpandedCriticalHit(roll, location, damageType, eyePossible)` assesses the
B556 general or head critical-hit table using a supplied table roll. Face, skull
and eye select the head table. The supported ordinary locations are torso,
vitals, groin, neck, arm, hand, leg and foot. `eyePossible` is an authored fact
about the shot line and anatomy. An unavailable eye converts the head-table eye
redirect to that table's half-armor/major-wound effect. Directly declaring an
unavailable eye target is rejected.

The result separates numeric effects from consequences that still need owned
execution. `rpgExpandedCriticalDamage(effect, rolledBasic, maximumBasic)` applies
maximum damage or the basic-damage multiplier before armor and injury factors.
`rpgExpandedCriticalArmor(effect, dividedArmor)` receives DR after ordinary armor
divisors: general-table halving rounds down; head-table halving rounds up; the
armor-ignoring head result returns zero. These helpers do not roll damage.

Major-wound, double-shock, temporary-crippling, deafness and appearance-loss fields
are explicitly conditional on penetration. `rpgExpandedCriticalShock` doubles
normal shock only when required and caps that critical effect at eight. Apply
ordinary trait exemptions when obtaining normal shock. For a limb/extremity that
was not already crippled by its injury, `rpgExpandedCriticalCrippleSeconds(HT)`
gives the temporary duration with its two-second minimum.

`dropHeld` applies even without penetration. The head table's `dropWeapon` effect
instead requires selecting the actual weapon, randomly if two are held.
`forcedDoNothing` requires that maneuver on the next turn but does not itself
remove active defenses. Crushing head effects can require deafness recovery;
other penetrating head effects can require one appearance-level loss, or two for
burning/corrosion. Those equipment, condition, disability and appearance commits
are not implemented by this assessment. Do not treat the flags as completed
persistent consequences or grant normal defenses against a critical hit.

`test_critical_hit_assessments` records every general and head table roll,
eye-redirection fallback, damage-type scarring, armor rounding, maximum and
multiplied basic damage, penetration-dependent shock, and duration boundaries.
All cases are authored but unrun. Critical-miss tables, multi-hit critical routing
and owned injury/equipment/condition integration remain incomplete.

## Modifier-table requirements

The [combat summary inventory](inventory/combat-modifiers.json) records B547–B549
as individual conditions and table rows. The detailed combat chapters still need
review, so the summary alone is not a complete attack or defense implementation.

Assessment must separate legality, base score, modifiers and final caps. Some
attacks cap final effective skill at nine even after bonuses. Some maneuvers forbid
a defense entirely; a high calculated defense cannot restore it. Visibility has a
combined penalty limit, while other penalties may remain independently applicable.

Dual-weapon penalties already include ordinary off-hand use. Targeting an armor
gap is a distinct target choice, and a partly exposed location incurs its extra
penalty once. These distinctions require modifier provenance so overlapping
integration layers do not charge the same condition twice.

Moving-platform attacks depend on terrain, mount and stability. The summary does
not separately classify an unstabilized enclosed turret for all terrain cases, and
its stabilization wording is narrower than the detailed vehicle text concerning
stabilized sights. Those combinations remain pending reconciliation. A generic
vehicle penalty cannot stand in for the listed matrix.

Aim, evaluation, feints, shock, prior dodges, control failures and repeated parries
need actor-, weapon- or target-specific state and expiry. Preview must not consume
an aim turn, defense opportunity, ammunition or fatigue. A committed attack must
resolve all hits through the shared injury ledger and preserve rollback, undo and
save behavior.

## Size and range integration

The [size/range inventory](inventory/size-speed-range.json) includes every printed
B550 row, visually compared with the source page. Size uses the relevant dimension
and shape adjustment; speed contributes only when the applicable procedure calls
for it. The existing whole-yard range helper supplies only part of this calculation.

Independent tests must cover row boundaries, fractional dimensions, final skill
caps, defense rejection, repeated modifiers, platform categories and multi-hit
resolution. No new tests or builds have been run while checks are suspended.

## Critical outcomes and anatomy

The [critical-outcome inventory](inventory/critical-outcomes.json) records each
row of the ordinary-hit, head-hit, weapon-miss and unarmed-miss tables. Selection
depends on the action and struck location. Critical damage multipliers act on
basic damage; armor and injury conversion remain separate stages. The two hit
tables round reduced armor differently, so they cannot share an unconditional
halving operation.

Weapon construction, quality and attack type determine whether a miss requires
a confirmation or replacement roll. Unarmed outcomes have separate rules for
natural weapons, creatures that cannot fall, and flight or swimming. Temporary
incapacity, dropped equipment, altered facing, lost actions and lasting wounds
must use the same persistent state as ordinary actions.

The [maneuver summary](inventory/maneuvers-postures.json),
[anatomy tables](inventory/anatomy-locations.json) and
[vehicle location tables](inventory/vehicle-locations.json) supply additional
integration requirements. None of these inventories is an executable subsystem
yet. Validation must independently cover every table result, conditional reroll,
rounding direction and expiry boundary before coverage can be marked complete.

The [detailed turn inventory](inventory/combat-turns.json) covers B362–B368.
Encounter time advances once per participant cycle, while maneuver permissions
last until the individual actor's next selection. Initiative ties are resolved at
encounter creation and retained. Re-sorting after every temporary speed change
would contradict the fixed ordering procedure.

Wait actions need a declared trigger, response, expiry and suspended action to
resume. Defending while waiting changes which response remains legal. Aim and
concentration also react differently to defenses and injury; they cannot share
one unconditional interruption flag. Feints retain actor-target ownership and
their own margin calculation, while evaluation survives active defense.

Full-turn maneuvers consume the whole second even for actors with additional
maneuver capabilities. Shared time accounting must distinguish that constraint
from extra attacks, free item release and ongoing ability maintenance.

## Attack and defense state

The [attack and defense inventory](inventory/attacks-defenses.json) covers
B369–B377. A burst has one declared ammunition expenditure and attack roll, but
can produce several hits. A successful dodge removes only the permitted number;
a critical dodge removes all. Remaining hits must pass individually through the
shared damage path. Sequential melee attacks likewise see equipment, posture and
injury changes caused by earlier attacks.

Defense legality precedes the roll. Ordinary blocking has a per-turn attempt
limit, while repeated parries count separately for each hand or weapon. Retreat
belongs to one opponent and persists against that opponent's remaining attacks;
it does not retroactively put those attacks out of reach. Protective dodges can
transfer a hit to another actor and consume later retreat eligibility even when
the interception fails.

Grapples need owned relationships between actors and body parts, with occupied
hands, posture, pin state and escape deadlines. A single `grappled` flag cannot
represent holding an item, restraining one limb, pinning a torso and strangling.
The supplied text differs at the exact twice-strength movement boundary between
B370 and B371. That case remains unresolved until a precedence policy is
documented and independently tested.

Collision attacks use each participant's health capacity and relative movement
to determine damage. Mounts and vehicles substitute their own capacity and the
appropriate control skill. Shield collisions redirect incoming damage to the
shield without removing the actor's fall risk. These integrations remain pending;
the inventory does not establish an executable combat module.

## Damage ordering and equipment actions

The [damage and readiness inventory](inventory/damage-readiness.json) records
B378–B383. Basic damage, range reduction, protection, penetration, wound factors
and final injury are distinct stages. Flexible armor trauma bypasses wound
multipliers, corrosion weakens protection for later hits, and internal follow-up
effects bypass protection without creating knockback or blunt trauma. Linked
effects instead share an attack roll while retaining separate resistance and
damage resolution.

Critical-failure dispatch has explicit combat exceptions. Failure by ten applies
to melee attacks and defenses, but not ranged attacks. Firearm malfunction takes
priority over a simultaneous critical miss, so the implementation must select
the consequence before consuming randomness for a critical-outcome table.

Readying, finding, transferring, dropping and stowing an item have different
requirements. A combat handoff needs both participants' actions; shield release
can require an action even when ordinary item release is free. Long actions need
owned progress, interruption policy and resource reservations. Completing a
reload must not also grant a free attack or duplicate ammunition.

The [special-mobility inventory](inventory/special-mobility.json) records
surprise, visibility and mounted/aerial combat. Surprise initiative is a group
procedure distinct from individual turn ordering. Total surprise has a shared
freeze interval followed by individual recovery; partial surprise adds increasing
recovery bonuses. Reflex capabilities create exceptions that must also work in
groups containing both protected and unprotected actors.

Visibility distinguishes inability to see anything, an invisible opponent and a
known but unseen location. Attack and defense permissions differ among them.
Hearing or another actual sense can locate an attacker without revealing hidden
information through preview. A visible weapon emerging from concealment is also
different from a wholly invisible attack.

Mounted attacks use rider skill limits, mount motion and control history. Near
misses can transfer between rider and mount; special hanging postures change both
exposed locations and transfer thresholds. Resolve one attack identity through
these branches so it cannot strike both participants accidentally.

The [targeting inventory](inventory/targeting-elevation.json) adds the detailed
B398–B403 procedures. Random hit location is rolled after a successful attack
and failed defense. Large-area injury instead derives protection from torso armor
and the least-protected exposed location, accounting for direction, immersion and
cover. It must not use a random location or a permanent whole-body average.

Attacks on weapons declare disarming or destruction before resolution. Their
defense choices exclude blocking, another weapon's parry and shield bonuses.
Disarming then has its own contest, readiness consequences and item displacement;
destruction uses actual object durability. These paths must share inventory state
without treating a successful attack as automatic item removal.

Armor-gap targeting replaces the ordinary location penalty and restricts eligible
damage types. Reduced-force and blunt-mode attacks likewise need declared attack
profiles before rolling. They do not change the character's purchased strength or
permanently rewrite the weapon's normal damage definition.

The [special-weapon inventory](inventory/special-weapons.json) records advanced
unarmed techniques and weapon-specific behavior. Joint locks, neck holds and
ordinary grapples have different entry conditions, escape modifiers, resource
timing and armor treatment. Some ongoing contests do not consume attacks, but
still require the original hold to remain valid and the relevant hands occupied.

Embedded weapons and entangled equipment need persistent relationships among
items, holders and targets. Extraction can cause additional injury based on the
original wound; failed extraction cannot repeatedly deal that injury. Releasing
an embedded item transfers grip without necessarily detaching it from the target.
Weapon-specific critical outcomes also override parts of the general tables.

Optional malfunctions use unmodified attack dice and actual device categories.
A stoppage fires one shot before failing, while other outcomes can prevent all
shots, delay an explosive or create a dud. Diagnosis, clearing and repair have
different checks, durations and hand requirements. These states must integrate
with ammunition, ongoing work and technology repair without duplicating costs.

The [special ranged inventory](inventory/ranged-special.json) distinguishes
shots spent, projectiles produced and hits resolved. Multiple-projectile rounds
can use different close-range behavior, while spraying allocates one burst among
targets and traversal gaps. Suppression persists until the next turn and can
affect later entrants without charging another burst for each one. Its remaining
hit capacity must be shared across all entrants.

Cover interception, firing through cover and overpenetration are separate paths.
They retain actual protected locations, selected shot line and entry/exit armor.
A downstream target must not receive a fresh full-damage attack after protection
has already absorbed part of the same projectile.

The supplied spray-fire text has overlapping bands at firing rate sixteen and a
gap-cost example that differs from a literal reading of the procedure. Both are
visible in B409. These remain explicit policy decisions requiring independent
boundary cases; no silent correction or later-printing substitution is assumed.

Ranged restraints also need distinct state: taut versus slack rope, escape
progress, consecutive failures, tether length and weapon attachment. Grenade
countdowns and prepared-projectile expiry follow the item across ownership
changes. Shared time and inventory integration remains pending.

The [guidance and area inventory](inventory/guidance-area-cinematic.json) reaches
the end of the detailed combat chapter. This completes its first text pass, not
its implementation or completeness audit. Trait definitions, equipment entries,
geometric fixtures and independent tests still need reconciliation.

Guided and autonomous projectiles need owned flight records with target, speed,
remaining travel, seeker senses and any required operator or designator activity.
The hit roll occurs on arrival. Reloading or launching another item must not erase
an in-flight projectile or reset its range budget.

Area, cone, blast and fragment effects share an impact event but resolve different
exposure and damage rules. Scatter is determined once. Fragment hits have their
own locations and protection, while internal and contact detonations use separate
branches. The source's torso-armor instruction for blasts differs from its general
large-area armor procedure; that precedence remains explicit and unresolved.

Cinematic procedures are separate campaign choices, defaulting off. Point-funded
injury reduction and fatigue-funded defense conversion require atomic accounting
across damage, advancement and skipped turns. Minor-opponent behavior, unlimited
ammunition and altered knockback likewise need executable permissions and state;
descriptive callbacks alone do not complete these options.


[Additional trait interactions](inventory/traits-catalogue-l.json) include remote
manipulation maneuvers, selected-result fortune, unusual survival thresholds and
advanced martial training. Remote actions share the actor's concentration turn;
physical injury still accumulates under unusual durability, with cause-specific
fatal thresholds. Training reduces specified penalties but does not grant skills.
These inventory requirements are not yet executable combat behavior.
