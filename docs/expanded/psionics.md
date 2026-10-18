# Expanded psionics

**Status: partial; fixtures unrun.** Power definitions, talent pricing, latent eligibility and secret danger warnings. Other ability effects and interference remain pending. Neutral source: `full-2008`, B254-B257.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-psionics.t` after the expanded foundation. The convenience umbrella includes it without activating any powers.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

The [detailed power inventory](inventory/psionics.json) records the chapter's
sample families, each eligible ability membership, talent and advancement rules,
countermeasures, and numerical examples. Most entries remain pending; partial talent work is identified individually. References
to underlying trait pages are dependencies to resolve, not proof that those
abilities work.

Each power must retain its abilities' own activation, resistance, duration and
resource procedures. Talent modifies eligible use rolls; it does not supply an
ability or automatically increase effect strength. The counterpower family has
no talent or source discount. Latent talent permits later investment in its
family, while acquiring an unrelated family requires a campaign decision.

Information abilities require a documented author contract for world facts,
information quality and misleading outcomes. Hidden rolls must stay hidden from
player-facing outcomes. Only the two specified perception abilities use the
severe-failure misinformation rule; it cannot become a generic rule for all
mental powers.

Magic and mental powers retain distinct origins, even when their physical or
mental effects interact. The shared injury, time and resource ledgers must apply
those interactions without charging an action or maintaining an effect twice.

## Power and talent authoring

Define `RpgExpandedPsionicPower` with a unique `id`, explicit `abilityIds`,
`powerModifier`, `approved` and `evidence` explaining campaign permission.
Membership identifiers refer to underlying traits; listing them does not
implement those traits. Duplicate or empty membership is rejected. Ordinary
families use a source modifier of -10 and five-point talents; the modifier must
be set explicitly. A counterpower definition uses zero, `allowsTalent = nil`
and `talentPoints = 0`. An unusually broad family requires
`customTalentPriceApproved` and an authored `talentPoints`, even if the author
chooses five. This object validates a definition; it does not apply modifiers
to ability prices or enforce countermeasures yet.

`RpgExpandedPsionicTalent` is an owned trait in the character's existing
`traits` list. Set its `id`, `power`, `level`, `approved` and `evidence`.
`creationCost()` contributes the level times the power's talent price through
the existing expanded trait accounting hook. More than four levels requires
`aboveFourApproved`; no talent may be installed in a family that forbids it.

`rpgExpandedPsionicTalentBonus(profile, power)` returns that family's active
talent level or zero. Conflicting definitions with the same family ID and
duplicate talents are rejected. Ability implementations must add this bonus
exactly once to their activation or use roll, including applicable physical
control rolls. The helper does not increase damage or effect strength, grant an
ability, roll dice or alter any ledger. Automatic roll integration is pending.

`rpgExpandedPsionicLatentEligibility(profile, power, abilityId)` checks whether
an owned talent permits an eligible first-ability purchase. Temporarily inactive
talent remains owned potential, although its use bonus is zero. A ready result
is permission only: the ability purchase itself remains pending. Talent purchases use the owned
advancement interface below.

The [minimal fixture](../../tests/fixtures/expanded-psionics.t) and
`test_psionic_talents` specify five-point costs, the four-level limit, explicit
higher-level permission, inactive talent, broad-family pricing and unrelated
ability rejection. They remain unrun while checks are paused.

## Secret danger warning

`RpgExpandedPsionicDangerSense` implements the B47 warning check with the B257
source discount: its expanded creation cost is fourteen points. Set `power` to
a definition that includes `danger-sense` and has `powerModifier = -10`, with
`approved` and `evidence`. The owned trait has the distinct ID
`psionic-danger-warning`, so the Lite notice fallback cannot roll it again.
This version supports no additional ability modifiers. A second warning trait,
an ordinary danger-sense trait or precognition cannot coexist for execution.

For each impending hazard, create one `RpgExpandedDangerWarning` with a stable
situation `id`, `profile`, owned `ability`, `hazardPresent`, `approved`,
`interferenceKnown` and `evidence`. Supply `warningText` that gives enough notice
to act and `detailText` that adds the nature of the danger. These are authored
world facts, not text generated from the die result. Set `suppressed` only when
an established countermeasure currently blocks the power. Countermeasure
resolution itself is still pending; unknown interference blocks the request.

`assess()` is pure. `apply()` runs inside an action transaction and secretly
rolls Perception plus the matching active talent. Success returns the ordinary
warning; rolls of three or four return the detailed warning. Failure returns no
warning. A successful roll of five does not reveal details merely because it
qualifies as a critical success at a high score. The operation consumes three
dice, no energy and no time, and never overwrites the profile's `lastCheck`.
The author may inspect `secretCheck`, but must not send it to a player-facing
report. The returned result contains only the selected warning text and status,
not the roll or effective score.

The owned situation history prevents repeat rolls, including a second request
object with the same situation ID. Replaying the original receipt returns its
existing warning without randomness. Use this interface directly for a psionic
warning, rather than invoking the Lite danger fallback as well. Other sensory
information abilities and automatic parser integration remain pending.

`test_psionic_warning` covers the source cost, real seeded success and failure,
explicit three/four detail boundaries, ordinary five, suppression, duplicate
situations, replay, hidden-result handling, rollback and undo. Its fixtures are
authored but unrun.

## Mental-power resistance

`RpgExpandedPsionicResistance` is an owned trait with `degree = 3`, `8` or
`'immune'`, plus `approved` and `evidence`. B81 classifies this threat family as
very common: the respective expanded creation costs are ten, fifteen and thirty
points. No power discount applies. Duplicate resistance instances are rejected;
levels of one instance are not used to stack bonuses.

`rpgExpandedAssessPsionicResistance(profile, resistanceAllowed, attribute)`
returns `applicable`, `immune` and `modifier` without rolling. Set
`resistanceAllowed` from the actual ability procedure, whether the character is
a direct target or caught in its area. An unresisted ability remains unresisted,
even for a character with immunity. IQ and Will resistance are supported;
other attributes return `psionic-resistance-attribute-unavailable` until their
specific procedures are resolved. Resistance is always on under B34; voluntary deactivation is rejected.

For a permitted resistance check, use `RpgExpandedPsionicResistanceContext`
with the correct `attribute` and `resistanceAllowed = true`. Its ordinary Lite
score/check path adds the bonus exactly once through the context modifier hook.
Do not also add the trait's bonus to `modifier`. Immunity makes the check
unavailable with reason `psionic-resistance-immune`, consuming no dice; the
ability executor should use the pure assessment to resolve immunity before
attempting its contest. With no resistance allowed the context rejects with
`psionic-no-resistance-roll`, also without randomness.

This context supplies the resistance side, not a universal attack contest or
ability effect. The originating ability retains its own activation, resistance,
resource and duration procedure. `test_psionic_resistance` specifies pricing,
IQ/Will bonuses, immunity, unresisted effects, always-on validation and unsupported
attributes through the real score/check path. Fixtures remain unrun.

## Absolute static protection

`RpgExpandedPsionicStatic` implements the absolute B78 protection definition.
It costs thirty points, plus fifteen per `areaLevels` and thirty for
`switchable`. The first area level covers one yard and subsequent levels double
that radius; this implementation bounds area levels at twenty. Personal static
has radius zero. Set `approved` and `evidence`; a non-switchable field cannot
be inactive. The resistible limitation remains unsupported. The Ready adapter below executes
voluntary switching.

Use `RpgExpandedPsionicStaticContact` to assess one field's effect. Supply its
`owner`, owned `field`, ability `source`, actual `target`, `approved` and
`evidence`. Personal static protects its owner and owned carried or worn items;
for an item target supply `targetCarrier`, whose inventory must contain it.
Area static also blocks operation within its radius and effects targeting that
radius. Supply whole-yard `sourceDistance` and `targetDistance` from the field
owner; boundaries are inclusive. These are explicit world facts, not a tactical
position calculation.

An indirect physical consequence, such as a thrown rock, sets
`indirectPhysical` and bypasses this protection. A verified counterpower effect
sets `counterpower`, since that family cannot itself be blocked by psionic
interference. These facts belong to the ability executor; neither flag grants
a different ability or changes its origin. `assess()` returns `suppressed`,
uses no randomness and does not mutate state.

A danger-warning request accepts `staticContacts` for known fields. Each must
identify the observer as both source and target, with neither bypass flag set.
Every field is assessed before the secret roll; a blocking field prevents the
roll. The warning receipt binds its contact evidence, so replay cannot retarget
it. `interferenceKnown` is still required: a supplied list is not proof that no
other countermeasure exists. Other interference mechanisms remain pending.

`test_psionic_static` specifies personal/item protection, exact radius bounds,
area and switchable pricing, inactive fields and the physical/counterpower
exceptions. `test_psionic_warning` additionally specifies suppression inside an
area, operation outside it, personal suppression and an inactive switchable
field. All fixtures remain unrun.

## Switching static in combat

Use `RpgExpandedStaticReadyManeuver` with an owned `field` and `enable` set to
the desired state. Pass it to `RpgLiteBattle.step` inside the normal action
transaction. It requires the switchable enhancement, a Ready maneuver, and a
state change. The field changes immediately when Ready executes; the battle
advances its shared turn and clock, with no second time charge and no activation
roll. Out-of-turn, stunned and otherwise unavailable actors cannot switch.

An optional `healthAdapter` accepts the existing expanded Ready health adapter
for actors whose injury or fatigue requires permission checks. Without it,
nonpositive HP or FP blocks switching. This is not a concentration activity and
has no separate interruption test. The underlying transaction still rolls back
if an exception occurs.

B34 defaults advantages to on during unconsciousness and sleep. The shared
`RpgLiteProfile.becomeUnconscious()` transition calls an inert-by-default
`onUnconscious` hook; quiet sleeping rest calls `onSleep` before advancing time.
The psionics module restores owned static fields to active in both hooks, with
no random draw or separate time charge. A restored field remains on after waking
until deliberately switched off again.

Lite injury, fatigue, action-consciousness, fear, airless exposure and drowning,
and expanded health/hazard transitions use this shared method. The separate
resilience-body library has its own state model and is not adapted here. Authors
who directly set `unconscious = true` bypass hooks; use `becomeUnconscious()` for
expanded profiles. An inactive field on an unconscious owner still triggers an
explicit guard if an external integration bypasses that transition.

The minimal `expanded-static-ready.t` fixture exercises the actual battle path.
`test_static_ready` specifies immediate changes, shared round timing, ownership
and enhancement guards, actor turn restrictions, exception rollback and undo.
It remains unrun while checks are paused.

`test_static_health_defaults` adds source-derived collapse and sleeping-rest
expectations, default-on persistence after waking, undo and exception rollback.
These new dispatch hooks preserve the old assignments and consume no extra
randomness when psionics is absent. Regression and native fixtures remain unrun;
compatibility is not yet verified at this head.

## Earned-point talent advancement

`RpgExpandedPsionicTalentAdvancement` installs or improves an owned talent using
the existing advancement ledger. Set `id`, expanded `profile`, `talent`,
`targetLevel`, `permitted` and `evidence`. The character must have completed
creation. By default `requiresDowntime` honours `developmentOpen`; the author
can explicitly waive that requirement. Purchases also honour
`developmentSpendingReason`, so mandatory spending cannot be bypassed.

An existing talent establishes access to its own family. The implemented danger
warning ability also establishes membership even without talent. With neither,
`newPowerApproved` is required. Membership from other abilities must be added
alongside their actual implementations; a string in a catalogue does not count
as an owned power. Duplicate talent families and conflicting trait IDs are
rejected. A target above four requires `aboveFourApproved`.

`assess()` returns the positive difference between current and target talent
costs (or the full target cost for a first purchase). `apply()` runs inside an
action transaction, debits `unspentPoints`, increments `developmentRevision`,
updates the existing trait or installs the new one, and records the receipt in
`psionicTalentAdvancements`. It does not award points, add time, roll dice or
create a second point ledger. The retained trait continues to contribute its
full current cost to expanded character accounting. Replaying the purchase
returns zero additional cost and never lowers a later improved talent.

`test_psionic_advancement` specifies delta costs, first talent with an owned
ability, new-family permission, higher-level approval, insufficient funds,
downtime, preview purity, replay, exception rollback and undo. These assertions
are authored but unrun. Ability purchases, modifier buyoffs and advancement
through arbitrary unimplemented abilities remain pending.
