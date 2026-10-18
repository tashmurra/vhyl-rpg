# Expanded traits

## Pricing interfaces

**Status: partial; new native cases have not been run while checks are paused.**

| Interface | Purpose | Source |
| --- | --- | --- |
| `rpgExpandedModifiedCost(base, percentages)` | Existing positive-cost pricing, preserving its positive-only contract | B101 |
| `rpgExpandedSignedModifiedCost(base, percentages)` | Positive, negative or zero arithmetic with the net −80% modifier floor and rounding toward positive infinity | B101; B110 |
| `rpgExpandedSelfControlCost(base, rating)` | Negative base priced at rating 6, 9, 12 or 15, discarding fractional magnitude | B121 |
| `RpgExpandedDisadvantage` | Approved negative price specification integrated through `creationCost()` into character accounting | B110; B120–B121 |

For a negative specification, set `points` to a negative integer, `level` to its
purchased count, and `approved = true` after author review. Use either
`percentages` or `selfControlRating`. Combining a self-control rating with a
nonempty modifier list is currently rejected as
`self-control-modifier-combination`; the composed rounding order has not been
resolved. Invalid ratings are rejected as `self-control-rating`.

A −25 base with a −10% limitation costs −22. A −5 base at self-control 9 costs
−7. Both calculations are pure: they consume no time, points or random rolls.
Negative contributions count toward the existing disadvantage limit and never
credit the unspent-point ledger merely by being assessed. Approval of a price
does not implement that trait's behavior, trigger, compatibility or modifier
effects. These interfaces do not yet constitute a playable full trait catalogue.

The [trait inventory](inventory/traits-foundation.json) begins the detailed
catalogue pass at B32–B37. It records categories, origins, activation, potential
purchases and the initial ability definitions. The existing pricing helper does
not implement these effects; their coverage remains pending.

Abilities need explicit permanent, switchable or attack behavior. A switchable
ability ordinarily changes immediately through a ready action and defaults on
during unconsciousness; an attack ability only acts through its attack procedure.
Mental and physical traits also follow different owners during body transfer,
while social identity requires a concrete campaign policy.

Potential purchases reserve character value without creating a freely spendable
point balance. Revelation, fulfillment and remaining payment have different rules
for inheritance, emergent abilities and secret traits. Hidden abilities must not
leak through preview or public accounting reports.

Condition attacks require actual resistance, effect phases, recovery and expiry.
Temporary attribute penalties have specific derived-stat exceptions. Repeated
effects normally use the worst severity; only eligible enhanced definitions can
stack. Suppression must restore the affected contribution without undoing unrelated
advancement or injuries that occurred during the effect.

Companion pricing is separate from companion agency and appearance. Adventure-level
appearance checks, invested replacement value, betrayal consequences and growth
need owned relationship records. The following catalogue pages and special
modifiers still need review before the companion definition is complete.

The [second catalogue segment](inventory/traits-catalogue-b.json) adds companion
modifiers and abilities through B42. Summoning reuses an existing companion and
retains failed-attempt deadlines. Shared-fate effects need propagation identities
to prevent cycles. Companion-granted powers retain their purchases while the link
is unavailable, rather than being deleted and repurchased.

Arm-specific attributes affect only eligible tasks and use different combination
rules for multiple hands. Accelerated subjective time adds maneuvers without
changing initiative and still respects actions that depend on another actor's
reaction. Neither feature can be represented by a blanket attribute or speed bonus.

Restraint powers own their strength, layers, damage, escape progress and retry
restrictions. Remote perception owns a viewpoint and displaced senses, while
ordinary ability ranges still originate at the body. Hidden impressions and
failed viewpoint placement require specific author contracts without revealing
private world facts through assessment. These effects remain unimplemented.

The [third catalogue segment](inventory/traits-catalogue-c.json) adds mental
compartments, contacts and protection modifiers. Mental compartments can act and
receive influence independently, but share one body and its physical limits.
Vehicle control stations likewise grant operator access without creating extra
weapons or movement capacity.

Contact availability belongs to the contact, including when several characters
share that person. Question penalties, research delays, reliability and private
information need persistent records. An abstract information score must not
silently replace the contact's actual character skills.

Protection layers retain fixed order, coverage, attack restrictions, depletion
and recovery. Absorbed damage creates temporary capability investment rather
than advancement points. Reflection applies to eligible direct hits only and
must not combine with absorption. These effects need integrated damage tests;
the existing trait-cost helper supplies none of this runtime behavior.

**Status: partial.** Trait catalogues, modifiers, benefits and restrictions. Neutral source: `full-2008`, B32-B166.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedModifiedCost` — B101; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.


The [fourth catalogue segment](inventory/traits-catalogue-d.json) records detection,
respiration and nutrition exceptions, controlled infection, duplication, memory,
empathic impressions and cinematic defense purchases. These remain pending effects.
Detection and empathic impressions need separate private evidence and public output:
a pure assessment must not reveal that a hidden target exists or whether an
impression is truthful. Retry deadlines belong to the character's observation
history, so constructing a fresh action cannot reset a failed memorization attempt.

Duplication requires separately owned bodies connected to one character origin.
Ordinary merging averages current health and fatigue; shared reserves instead
conserve allocations and add them on reunion. Copied signature equipment needs
origin records even after transfer or dropping, because merging removes those
copies. Copy deaths, replacement purchases and optional extra lives must use one
advancement ledger. Rounding, absent participants and secondary death propagation
remain explicit source decisions, not implemented behavior.

Respiration exceptions are specific: independence from oxygen does not protect
against contact toxins, pressure or vacuum. Reduced respiration variants can
still require environmental oxygen or a finite reserve. Nutrition and sleep
independence do not grant arbitrary recovery. Infectious control likewise separates
infection, delayed transformation, purchased companion control and later release;
insufficient advancement points cannot prevent an otherwise valid infection.


The [fifth catalogue segment](inventory/traits-catalogue-e.json) distinguishes top
speed from basic movement, and faster perception from extra actions. Additional
arms, heads and mouths have separate occupancy and injury consequences. They do
not automatically grant attacks, spell actions or mental compartments. All-out
attack and rapid-strike allocations must share the existing turn ledger.

Replacement lives need a durable consumption record even when restoring an older
character snapshot. Backup location, preparation duration, permitted tampering and
body acquisition require explicit authored decisions. Favors likewise retain
adventure-level retry restrictions and can be consumed only once per successful
call, subject to their specified exceptional roll.

Fitness changes recovery according to fatigue cause. Exertion and supernatural
power costs must retain their provenance within one fatigue ledger, including
when both occur between rest periods. Fractional loss rates cannot be rounded
independently for every newly constructed action. These capabilities remain
inventory requirements and are not provided by the current trait pricing helper.


The [sixth catalogue segment](inventory/traits-catalogue-f.json) records flexibility,
flight variants, contingency equipment, growth, restorative touch and scoped
bonuses. Flight mode is part of the capability definition: powered flight,
gliding and reaction-mass space travel use different movement and reserve rules.
Neither flight nor greater size automatically supplies environmental protection,
strength or resized equipment. These definitions remain pending implementation.

Contingency equipment requires a session allowance and explicit item eligibility.
An existing owned item must retain its identity when revealed. Improvised devices
also need materials, skill resolution and a committed failed-use cost. Growth
requires separate supporting strength and checks against actual surrounding
space, with timed barrier penetration when eligible.


The [seventh catalogue segment](inventory/traits-catalogue-g.json) covers sensory
bands, injury anatomy, damaging powers, alternate attacks, phasing and invisibility.
Anatomical protections compose through explicit included traits and incompatible
body forms. A purchased attack retains damage type, delivery and exact fractional
dice pricing; an alternate family also owns shared failure and suppression state.

Phasing needs region-level material state, barrier eligibility, respiration and
carried-object transitions. Invisibility needs observer and sensing-domain checks,
with separate evidence for sound, tracks, shadows and reflection. Neither is a
single universal immunity flag. Intuitive guidance also retains a question identity
and bounded authored outputs so repeated previews cannot reveal hidden answers.
All of these effects remain pending implementation and validation.


The [eighth catalogue segment](inventory/traits-catalogue-h.json) records innate
travel, legal permissions, real-play rerolls, magical aptitude and mental effects.
Real-play cooldowns need an explicit clock policy and roll-event window; advancing
the fictional clock cannot refresh them. A reroll must replace the selected result
before its consequences are committed, including when the roll remains private.

Mental command, conditioning, probing and thought reading have different subject
histories, expiry rules and output contracts. A question identity must survive
rephrasing; a new action object cannot bypass a subject cooldown. A mental shield
also retains its voluntary state while unconscious. These effects are pending,
and the rapport continuation is now recorded in the ninth segment.


The [ninth catalogue segment](inventory/traits-catalogue-i.json) completes the
rapport text and adds temporary ability pools, patrons, payload and consciousness
transfer. Pool assignments own temporary contributions; reallocating capacity
must not refund permanent advancement or retain removed capabilities. Borrowed
powers similarly retain their source, modifiers and expiry.

Body transfer separates the acting mind, physical host, suppressed occupant and
original body. Host attributes and relative physical skills change while mental
traits persist. Failed transfers can create permanent subject immunity. Memory
attempts, purchased return access and remote-control termination need persistent
records. The module remains incomplete; these are implementation obligations.


The [tenth catalogue segment](inventory/traits-catalogue-j.json) adds foresight,
ancestral and object histories, recovery, active sensors and shadow form. Sensors
retain their own range, emission visibility, environmental limits and detail
outputs. A targeting lock is distinct from discovery, and switching sensor modes
must not accumulate bonuses from incompatible modes. These effects remain pending.


The [eleventh catalogue segment](inventory/traits-catalogue-k.json) records fixed
and adaptive transformations, shrinking, protected equipment, parallel item
acquisition and natural appendages. Shrinking scales different quantities from
stretching, and each full-value exception applies only to its selected quantity.
Acquired items retain origin, expiry and retry-family records; transferred or
consumed items must not evade their return rule. These effects remain pending.


The [twelfth catalogue segment](inventory/traits-catalogue-l.json) records skill
aptitude groups, communication channels, remote manipulation and environmental
control. Remote hands perform one maneuver under concentration and retain grip,
position and aim state. Throwing releases the object and uses different distances
for physical range and accuracy. Communication likewise retains contacts, channel
compatibility and interference rather than treating transmission as public speech.


The [thirteenth catalogue segment](inventory/traits-catalogue-m.json) completes
the main advantage catalogue through B100, before perks. This is a first inventory
pass, not complete implementation. Teleportation keeps preparation and distance
rules separate, owns failure cooldowns and limits defensive use to once per turn.
Spontaneous skill retention also owns its point reservation, learning restrictions
and month-long provisional state.


The [first modifier segment](inventory/traits-modifiers-a.json) records perks,
percentage arithmetic, compatibility and initial attack enhancements. Perks cannot
receive modifiers. Most enhancements cannot be switched off individually without
an explicit permission. Default range, area and duration apply only where a
modifier requires an otherwise unspecified dimension.

Repeating damage owns recovery restrictions and termination actions. Delayed
attacks retain their selected trigger or deadline and neutralization method.
Follow-up attacks depend on a carrier's hit and penetration result and inherit
only the specified modifier subset for pricing. These behaviors are pending;
the existing positive-price helper does not validate or execute them.


The [second modifier segment](inventory/traits-modifiers-b.json) records guidance,
linked actions, persistent areas, sensory delivery, symptoms and walls. Linked
attacks share one hit roll only when their listed combat statistics match; they
retain separate damage and protection resolution. Mobile areas and projectiles
also need persistent identities, positions and control dependencies.

Symptoms follow damage caused by their particular attack and end through healing
that damage. Side effects instead use resistance, duration and sometimes sequential
phases. Ranged conversion bars reuse while any prior effect remains, except where
a specific trait overrides that rule. These lifecycle requirements remain pending
and are not implemented by the existing modifier arithmetic.


The [third modifier segment](inventory/traits-modifiers-c.json) covers limitations
and gadget rules. Signed disadvantage pricing rounds toward positive infinity.
Temporary disadvantages also cap absolute point savings, so a percentage-only
price helper is insufficient. Optional limited enhancements require an explicit
campaign choice and apply restrictions to their selected enhancement alone.

Preparation is character-owned: only one prepared ability can be retained at a
time. Limited uses, ammunition reloads, recharge deadlines and unreliable-activation
rest locks are separate constraints. Every use must validate them before spending
resources, while failed attempts still commit their specified costs. Gadget damage,
theft, repair and unique loss also need identity-based lifecycle records. These
behaviors remain unimplemented.


The [initial disadvantage inventory](inventory/disadvantages-a.json) covers
custom-trait design, self-control and the catalogue through impaired sight.
Self-control has a purchased rating independent of Will, with an optional paid
success rule requiring explicit campaign selection. Acquired injuries reduce
character value without granting spendable points; buying them off uses earned
points and any required recovery conditions.

Hidden disadvantages and memory loss need private definitions plus controlled
public disclosure. Repeated withdrawal, focus, injury-trigger and recovery checks
need dated episode histories. Reconstructing an action must not reset those
histories, while narrative uncertainty must not overwrite already committed facts.
All new entries remain pending implementation and validation.


The [second disadvantage segment](inventory/disadvantages-b.json) distinguishes
rage, combat freezing and stimulus confusion. Each constrains different actions
and has different defenses or recovery checks; none can be implemented as a
generic stun flag. Pain episodes and temperature-dependent attribute losses need
independent clocks and source-tagged recovery. The pain-frequency table and prose
also differ at the activation boundary, which remains an explicit source decision.

Compulsions carry real time, expenditure, living-cost and reaction consequences.
Hidden truthfulness rolls and sensory restrictions need controlled information
outputs. Existing character accounting does not execute these new effects.


The [third disadvantage segment](inventory/disadvantages-c.json) separates
missed-sustenance injury from daily depletion that ordinary healing cannot restore.
Both need owned clocks and source-tagged injury in the shared health ledger.
Calendar boundaries, qualifying contact durations and the depletion recovery amount
need explicit source decisions before those procedures can be completed.

Dependents, external duties and adverse fate also affect advancement and character
accounting. Their author interfaces must record appearances, assignments, losses
and settlement decisions; a general narrative callback cannot establish coverage.
Reduced personal time changes action scheduling, while outside events retain their
world-time schedule. These entries remain pending executable implementation.


The [fourth disadvantage segment](inventory/disadvantages-d.json) covers personal
opponents, stress episodes and catastrophic anatomy. Opponent appearances need
persistent adventure/session identities, while permanent removal creates a
character-accounting settlement. Appearance checks alone do not implement the
authored encounter obligations.

Brittle, combustible, explosive and externally animated bodies change injury
outcomes rather than simply increasing damage. Persistent bleeding also needs
per-wound original injury and separate external/internal recovery stages. Added
sleep, food and life-support requirements use the existing time, inventory and
health ledgers. All these integrations remain pending.


The [fifth disadvantage segment](inventory/disadvantages-e.json) distinguishes
missed-maintenance attribute loss from injury and records its staffing, frequency
and restoration requirements. Sleep interruptions, nightmares, indecision and
cycling moods each need owned clocks with different retry and recovery rules.

Mobility traits also alter valid hit locations, manipulator access, armor coverage
and point accounting. Acquired leg loss, naturally legless movement and anchored
bodies must remain distinct. The inventory records these integration requirements;
it does not yet provide their runtime behavior.


The [sixth disadvantage segment](inventory/disadvantages-f.json) records each
stimulus-specific fear, including technology-dependent prices and exposure
modifiers. Successful resistance still imposes penalties, failed resistance uses
the full fear table, and continuing exposure has its own retry clock. Believed
threats must not disclose whether hidden supernatural effects are real.

Violence constraints depend on authored intent, perceived targets and consequences.
Limb and sensory restrictions require task-specific permissions and information
filtering. These are pending integration requirements, including the unresolved
relationship between single-eye ranged and general coordination penalties.


The [seventh disadvantage segment](inventory/disadvantages-g.json) includes
visually reviewed lifespan and sleep-fraction tables. Calendar units and legal age
remain distinct: biological maturity does not automatically grant adult social
permissions. Recovery and meal-time restrictions use the shared clocks rather
than separate deductions for the same elapsed time.

Secrets require a transactional replacement when disclosed, while social stigmas
need concrete, campaign-specific restrictions and observer knowledge. Merely
storing their names or reaction penalties would leave their applicable procedures
unimplemented. These entries and their validating fixtures remain pending.


The [eighth disadvantage segment](inventory/disadvantages-h.json) separates
resistance susceptibility, post-armor injury multiplication and timed exposure
loss. Their affected rolls, order of operations and clocks differ. The vulnerability
price table has been visually reviewed; executable behavior and expected-value
fixtures remain pending.

Alternate personality packages must share the actor's physical state and ledgers.
Conditional healing, session misfortune and supernatural event traits also need
specific authored contracts, not unrestricted callbacks or duplicate actors.


The [quirk and custom-disadvantage inventory](inventory/disadvantages-i.json)
records the five-slot limit, each listed mental and physical minor trait, and
custom pricing requirements. Mental traits need concrete behavior or narrow
penalties; physical quirks need defined effects at creation. Open mental slots do
not permit later acquisition of arbitrary physical restrictions.

Composite restrictions can contain benefits, and their signed prices need separate
component accounting without duplicate credit. The first source-enumeration pass
now reaches the end of this trait chapter; that does not establish catalogue
completeness, executable effect coverage or passing validation.

## General modifier summary

The [modifier summary](inventory/modifier-summary.json) maps 49 enhancement rows
and 38 limitation rows to the detailed inventory. Fixed and per-unit summary
prices have been compared with those detailed entries. Full eligibility, effect
resolution, trait-specific modifiers and independent execution fixtures remain
pending; the current price helper does not implement this catalogue.

Summary headings do not remove detailed caps or exceptions. Explosion enhancement
has at most three levels. Additional recoil requires rapid fire and gives no more
than a 40% discount. Accuracy cannot fall below zero. Fragmentation has both a
twelve-die ceiling and a main-attack damage limit. The interpretation of mixed dice
and damage additions in that second limit remains unresolved.

Delivery modifiers also have mutually exclusive price forms. Blood exposure costs
−40% ordinarily but +100% with area or cone; skin exposure changes from −30% to
+150%. Sensory delivery becomes a limitation when the underlying ability already
bypasses armor or uses the specified remote-resistance procedure. A builder must
select the applicable form after checking the complete ability, then price it
once. Group summary rows are navigation to actual modifiers, not extra purchases.

## Trait summary reconciliation

The [first trait-summary segment](inventory/trait-summary-a.json) maps 112 rows
to the detailed character and trait ledgers. These include named tiers, sensory
variants, relationship groups, perks and skill aptitudes. The full field comparison and executable catalogue remain pending.

Orientation, internal timekeeping and bodily flexibility have alternative tiers.
Their listed prices are totals for the selected tier; an upgrade replaces the
lower tier's contribution rather than adding a second purchase and stacking both
sets of bonuses. Thermal-only sight is a zero-point feature, while switching
between ordinary and thermal sight costs ten points. The inventory records that
distinction so a zero price cannot accidentally grant both senses.

Arm-specific attribute purchases also have bounded scope: dexterity pricing covers
one or two arms, and strength pricing covers one through three. Broader purchases
use the overall attribute. Alternate identities have separate legal/illegal costs
and eligibility, but never create funds. These records await executable character
accounting, application and advancement fixtures.

The [second trait-summary segment](inventory/trait-summary-b.json) maps another
148 rows, completing the positive-trait summary mapping. It records further tier
families and bundled senses. Exclusive low-frequency hearing, ultrasonic hearing
and ultraviolet sight have zero-point forms; retaining ordinary senses costs
extra. The corresponding speech traits include their special hearing capability.
A summary range must not become an arbitrary price slider: detailed ultrasonic
speech has zero- and ten-point variants.

Base-plus-level prices also need a defined level origin. The life-draining bite's
base price includes one health point per second; its increments buy additional
drain. Tunneling increments instead price each movement point, and fear increments
price each added penalty point. The summary ledger stores these distinctions for
future accounting tests. The detailed higher recovery tier still has its recorded
source-wording discrepancy; mapping its summary does not resolve that behavior.

The [first negative-trait summary segment](inventory/trait-summary-c.json) maps
128 rows. Starred entries use the listed cost at self-control 12; ratings 6, 9
and 15 apply multipliers of 2, 1.5 and 0.5 respectively. Discard fractional point
magnitudes, so a −5 base at rating 9 is −7, not −8. These ratings are independent
of Will. The ledger keeps this pricing separate from the eventual trigger and
consequence contracts.

One-point minor variants need their own concrete behavior and share the character's
five-quirk credit allowance, including contributions from templates. They do not
automatically inherit the full trait's penalties. The skill-incompetence variant
is an explicit exception with specified mechanics: prohibit learning the selected
skill and apply −4 to its defaults across all specialties. It must be relevant to
the campaign. Companionship traits modify the owner's reactions toward others;
those modifiers must not be applied in the opposite direction.

The [final negative-trait summary segment](inventory/trait-summary-d.json) maps
99 rows. All 487 trait-summary rows now have detailed targets: 260 positive and
227 negative entries. This is a completed row mapping, not completed source or
runtime coverage. Classification, pricing, modifiers, effects and the remaining
source ambiguities still need reconciliation.

The final segment distinguishes mutually exclusive speech, manipulation, fitness
and coordination variants. Two labels for the same reproductive-anatomy quirk
share a single purchase and credit. The minor goal costs one negative point without
a self-control multiplier; the full short- and long-term goals use that multiplier.
The permanently active shadow form uses its complete negative-cost version rather
than adding that credit to the positive-cost switchable version.

Absent natural healing blocks ordinary recovery and medical health restoration,
while first aid can still stop bleeding. Its partial and total variants differ in
conditional recovery and health theft; neither automatically forbids every form of
body-compatible surgery, repair or exotic restoration. These distinctions must
reach the shared health ledger before the corresponding traits can be complete.

## Maintenance staffing and frequency prices

`rpgExpandedMaintenanceBase(people)` implements the B143 staffing table and its
full-doubling extension above one hundred people. The base is minus seventy for
51–199 people, minus eighty for 200–399, and continues by full doublings. The
printed ten-thousand-person example therefore has a base of minus 130.

`rpgExpandedMaintenanceCost(people, frequency)` applies `monthly`, `fortnightly`,
`weekly`, `alternate-days`, `daily`, `twice-daily`, `three-to-five-daily` or
`constant`. Final negative fractional point costs round toward zero; one person's
fortnightly requirement costs minus three, and alternate-day service costs minus
seven. These helpers accept one through one million people and reject other
frequency identifiers. They neither grant points nor spend staff time.

Pricing does not implement a maintenance obligation. An executable requirement
still needs eligible staff or qualifying traits, appropriate facilities, one-hour
installments, concrete due times and any explicitly approved substitution of
additional person-hours for simultaneous workers. Monthly timing is a calendar
choice; three-to-five-daily and constant service need explicit coverage policies.
No consumed supplies are implied by maintenance itself.

A missed installment reduces HT and requires the source's further HT check.
Ordinary failure needs an authored additional incapacity, and critical failure
requires a potentially fatal consequence appropriate to the maintained subject.
The current price helpers do not resolve those outcomes or restore lost HT.
Technology's environmental-fault repair is a separate procedure and must not be
counted as maintenance-loss recovery. Each lost HT point requires its own major
repair where that technology procedure applies.

The [minimal price fixture](../../tests/fixtures/expanded-maintenance-price.t) and
`test_maintenance_prices` record staffing boundaries, full doublings, every
frequency, fractional negative costs and zero time/randomness. They are authored
and unrun while checks are paused. Maintenance remains partial in the inventory.


## Purchased invention capability

`RpgExpandedInventor` uses the neutral identifier `inventive-capability` and a
`tier` of `cinematic` (25 points) or `rapid` (50 points). These are alternative
purchases, not cumulative levels. Approval is required; repeated instances,
nonunit levels and percentage modifiers are currently rejected. The existing
character trait-cost interface includes the selected cost. The trait grants no
scientific or technical training.

`RpgExpandedProfile.inventionCapabilityTier()` returns the active, unmitigated
capability, or nil. Without this traits module the foundation returns nil. The
technology permission interface adds campaign and world gates. Owned cinematic
execution and advancement between these tiers remain incomplete; pricing and
permission are not a complete implementation of the trait. The permission fixtures
are authored and unrun. Source: `full-2008`, B56–B57 and B475.


## Fear-induced behavioral quirks

`RpgExpandedMentalQuirk` represents the recurring-action branch of the mental
quirk contract in `full-2008`, B162–B163. Set `approved`, `triggerText` and
`responseText` to a concrete situation and behavior the player can portray.
Empty descriptions are invalid. The trait retains the shared `quirk` identity,
one level and minus-one character value. Passive labels and unspecified
callbacks do not satisfy this interface. Narrow numeric-penalty quirks require
separate effect implementations.

`RpgExpandedFearQuirkAcquisition` records an authored fear consequence. Supply
an `id`, unique `eventId`, expanded `profile`, a new `quirk`, `approved` and
`relationEvidence` explaining how it relates to the frightening event and the
character. This is an explicit author-selected outcome interface, not a full
fear-table roll. It requires completed character creation. Apply it inside an
engine action transaction.

The acquisition installs the trait, reduces character value by one and advances
`developmentRevision`. It changes neither `earnedPoints` nor `unspentPoints`.
Its receipt permits this fear-induced quirk beyond the normal five-quirk creation
limit and excludes its acquired negative point from that creation limit's
negative-point budget. Ordinary quirks still use the five-quirk limit. Removing
an acquired trait removes its allowance; replaying the old acquisition does not
reinstall it or grant points. Event and behavior bindings prevent retargeting an
existing receipt. Quirk changes and buy-off still need their own procedures.

`RpgExpandedQuirkPortrayal` makes the author contract explicit for a scene. Supply
an `id`, owning `profile`, `quirk`, `triggerPresent`, `decision`, `observedBehavior`
and `approved`. When triggered, the decision is `followed` or `departed`; otherwise
it must be `inapplicable`. The record retains the observed behavior and decision
once, under normal transaction and save handling. It does not force the player's
choice, invent an advancement penalty, or pretend the character followed the
quirk. Any authored advancement sanction requires its own supported ledger
operation; automatic sanction handling is not implemented here.

`test_fear_quirks` specifies sixth-quirk acquisition, unchanged spendable points,
creation-budget validation, ordinary-sixth-quirk rejection, portrayal decisions,
preview, rollback, undo, replay and cross-process continuation. The fixture is
unrun. The health module can combine this acquisition with row-sixteen stun
atomically; see its authoring guide. Broader fear trait outcomes remain incomplete.


## Character/social subset authoring

`rpgExpandedModifiedCost` prices a positive cost with percentage modifiers.
`rpgExpandedSignedModifiedCost` also handles negative costs, using the source's
signed rounding rule and modification floor. `rpgExpandedSelfControlCost` applies
the supported self-control frequency multipliers independently of Will.

`RpgExpandedTrait` and `RpgExpandedDisadvantage` are approved price specifications
on the existing trait interface. Set `id`, signed `points`, `level`, `percentages`
and `approved`; disadvantages may set `selfControlRating`. The combination of
self-control repricing and percentage modifiers is explicitly rejected until its
composition rules are implemented. `approved` means the author approved that
price specification, not that the library implemented all described effects.

Existing Lite traits remain usable and retain their executable behavior.
Additional authored effects must be implemented in concrete mechanics and tested.
The character/social umbrella does not supply a full advantage/disadvantage catalogue,
generic power effects or an automatic self-control trigger procedure. Do not give
a character an advertised capability based only on the calculated point cost.

Source mapping: `full-2008` B101-B121. Full trait catalogues and their effects remain
part of the broader expansion project. See the [prerelease validation record](../releases/v1.1.0-alpha.1.md).

The prerelease record applies to the original subset. Checks for this merged
expanded suite remain paused.


## Radiation resistance

`RpgExpandedRadiationResistance` implements the nine purchased dose divisors in
`full-2008`, B79. Set `approved = true`, retain its `radiation-resistance` identity,
and choose a level:

| Level | Divisor | Character points |
| --- | --- | --- |
| 1 | 2 | 5 |
| 2 | 5 | 10 |
| 3 | 10 | 15 |
| 4 | 20 | 20 |
| 5 | 50 | 25 |
| 6 | 100 | 30 |
| 7 | 200 | 35 |
| 8 | 500 | 40 |
| 9 | 1000 | 45 |

Install one instance in `profile.traits`; character accounting includes its cost.
The hazards exposure recorder divides after shielding, keeping exact fractional
doses. Inactive or mitigated traits retain their purchased cost but supply no
protection. Duplicate instances and generic traits using this identity are
rejected during exposure assessment. Percentage modifiers are unsupported and
rejected; purchasing or changing this trait during advancement still requires a
supported advancement procedure. Do not directly change its level to spend points.

The minimal integration fixture is `tests/fixtures/expanded-radiation-traits.t`.
Its expected-value cases in `test_radiation_traits` are authored and unrun. This
addition does not complete the traits catalogue or radiation syndrome procedures.


## Pain sensitivity

`RpgExpandedPainSensitivity` is the fixed -10-point trait from `full-2008`, B142.
Set `approved = true` and install one instance in `profile.traits`. The health
module, with scaled injury shock selected, supplies doubled shock, physical
resistance penalties and the Will check to avoid crying out after injury above
one HP. Its shared health result exposes the cry-out outcome. Modifier pricing,
observer-dependent discovery and optional reaction consequences remain incomplete.
See the [health guide](health.md#pain-sensitivity-in-the-injury-pipeline) and
`tests/fixtures/expanded-pain-sensitivity.t`; the fixture is authored and unrun.


The health module also supplies `RpgExpandedTerminalCondition` for an acquired
one-year deadline with -75 character value. See its [authoring contract](health.md#acquired-one-year-terminal-condition).
It participates in shared character accounting without awarding spendable points.
Other duration tiers, creation purchases and cure/buy-off are still pending.


## Impaired clotting

`RpgExpandedImpairedClotting` supplies the fixed -30-point purchase and HT-ten cap
from `full-2008`, B138. Set `approved = true`. Its special bleeding procedure is
still partial: the health module has a pure care-stage assessment and prevents
ordinary bleeding from silently approximating it. See the
[health contract](health.md#impaired-clotting-assessment) for the unresolved owned
loss and treatment work. The fixture is authored and unrun.

### Persistent open wound

`RpgExpandedPersistentWound` is the fixed -5-point disadvantage from `full-2008`,
B162. It requires approval, one level and no percentage or self-control modifiers.
Acquiring it does not remove HP. The health module provides an explicit
`RpgExpandedRecoveryWoundAcquisition` for a critical mortal-recovery consequence;
ordinary creation can use the trait's normal character-cost contribution.

`rpgExpandedAssessPersistentWound` exposes B162's source values from explicit
facts: an informed attacker can target the opening at -7 with a 3/2 wounding
multiplier; a blood agent that actually reaches it has a broken-skin entry route;
an undressed wound in plague-ridden surroundings gives -3 infection resistance.
These are assessments, not automatic attack, poison or treatment execution.
Damage-type/location composition and blood-agent entry remain unfinished. Daily
dressing now has an owned health operation, and infection resistance uses its
current-day result in the hazard module. Do not apply the assessed multiplier twice or treat it as a
new HP loss merely for having the trait.


### Executable self-control ratings and owned triggers

`RpgExpandedDisadvantage.selfControlNumber()` now supplies the approved rating
6, 9, 12 or 15 to the shared `rpgLiteSelfControl` operation (full-2008 B121).
Omitting the rating selects twelve. This is independent of Will. Authored stimulus
modifiers, sleep penalties and the health self-control hook apply afterward.
Invalid ratings or unapproved expanded traits reject before rolling. Expanded
scores below three block without randomness; voluntary acceptance remains
available without a roll. Ordinary Lite traits retain their fixed rating twelve
and prior random-number behavior.

For a persistent occurrence, use `RpgExpandedSelfControlTrigger` with unique `id`,
`profile`, owned controlled `trait`, stable `trigger` identifier, `modifier`,
`giveIn` and `evidence` describing the actual triggering circumstance. `assess()`
is pure; `resolve()` commits one check and its obligation. Replays return the same
check. A new request ID cannot reroll the same trait/trigger pair. Use a new trigger
identifier only for a genuinely new occurrence established by the author.

The operation inherits the obligation interface: `active` is true after failed
resistance or voluntary acceptance, and `permits(action)` uses the authored
action's `satisfies(obligation)` decision. Before resolution, it grants no action
permission. This contract requires concrete authored behavior for each trait; it
does not implement an entire behavioral catalogue through a generic callback.
`begin(modifier,giveIn)` is a compatibility entry into the same owned resolution.
Trait-specific trigger/counter rules remain incomplete. The explicit point-funded
option is described below. `expanded-self-control.t` specifies all four ratings, Will independence,
pain modifiers, invalid inputs, voluntary acceptance and once-only triggers with
preview, rollback and undo. These assertions are authored and unrun.


### Optional point-funded self-control

The full-2008 B121 option is disabled by default. Enable
`rules.pointFundedSelfControl` for a campaign that permits it, then set
`buySuccess = true` on a fresh `RpgExpandedSelfControlTrigger`. This is a choice
before resolving the occurrence. It cannot be combined with `giveIn` or retrofitted
onto a failed check; retroactive purchases remain unsupported.

Assessment checks campaign permission, trait approval, the existing
`developmentSpendingReason()` gate and one available `unspentPoints`. Resolution
consumes one point permanently in the ordinary progression ledger and increments
`developmentRevision`. It records an automatic successful check and no active
obligation, without rolling or spending time. Earned-point history is unchanged.
No separate point bank, reservation or automatic refund is created. Replay,
including after a policy change or save restoration, uses the original receipt.
Normal transaction rollback and undo still restore the entire action.

`test_self_control_points` specifies disabled policy, insufficient funds,
conflicting choices, mandatory-development spending protection, a modified score
below three, preview, replay, rollback, undo and cross-process continuation.
These assertions are authored and unrun. Campaign reward judgments about repeated
resistance remain authored rather than automatic point penalties.


### Truthfulness

`RpgExpandedTruthfulness` implements the full-2008 B159 base −5 controlled trait.
Set `approved = true` and an optional `selfControlRating` (default twelve).
Its fixed identity, level and base price are validated; percentage modifications
are not yet supported. Shared scoring already supplies −5 to Fast-Talk and −5 to
Acting when `context.deceptive` is true. Nondeceptive Acting retains its normal
score. The penalty remains even after successful self-control for an occurrence.

Use `RpgExpandedTruthfulnessTrigger` for a concrete communication opportunity.
Supply the inherited ID, profile, trait, stable trigger and evidence, plus `mode`
(`omission` or `falsehood`), the relevant authored `truth`, and a proposed
`falsehood` when applicable. Omission uses the selected self-control rating;
speaking a falsehood adds −5 to the effective modifier. `failureChoice` is `truth`
or, for falsehood attempts, `obvious-lie`. This is an authored choice between the
two source-described consequences, not automatic disclosure of arbitrary secrets.

On success, the receipt reports `withheld` with no statement or `falsehood` with
the proposed statement. On failure or voluntary acceptance, it reports
`disclosed-truth` or `obvious-falsehood` and the corresponding authored statement.
Successful self-control does not make a lie convincing; any later Acting or
Fast-Talk procedure still applies its penalty. Render the receipt through the
story's communication action; it does not send messages or alter knowledge by
itself. Replays reuse the original outcome, and altered requests reject. The
inherited obligation interface remains available for authored action permission.

`expanded-truthfulness.t` specifies skill penalties, omission, falsehood, both
failure choices, voluntary acceptance, preview, replay, rollback, undo and saved
continuation. Assertions remain unrun. The social module now provides evidenced
statement delivery through `RpgExpandedStatementDelivery`, using the resolved
trigger’s `communication` receipt. Parser/dialogue routing and integrations with
broader social contests remain incomplete.

Self-control pricing requires `controlled = true` on the disadvantage. A rating
on an uncontrolled disadvantage rejects with `self-control-ineligible-trait`
both when priced directly and through character accounting. Runtime rating
lookup uses the same eligibility gate. This explicit declaration identifies an
authored resistance procedure; it does not establish catalogue eligibility or
implement that procedure's consequences. Pure numeric pricing remains available
for assessment. Regression assertions cover all three rejection paths and remain
unrun while checks are paused. Source: full-2008, B121.

The template adapter accepts an explicit truthfulness rating in a fourth trait-row
field, retaining `RpgExpandedTruthfulness` behavior and fresh ownership. See
[purchased template traits](templates.md#purchased-self-control-in-template-rows)
for supported rows, composition guards and choice accounting.

## Curiosity occurrences

`RpgExpandedCuriosity` implements the base −5 rated investigative compulsion
(full-2008, B129). Set `approved = true` and an optional `selfControlRating`;
its price and runtime rating use the shared B121 procedure. Warning or judgment
traits do not bypass this trigger. An explicit template row
`['curious',1,scope,rating]` creates this concrete trait.

For each interesting situation create an owned `RpgExpandedCuriosityTrigger`.
Set the inherited profile, trait, stable ID, trigger and evidence, plus a
`subject`, `interesting = true`, and a nonempty, unique `investigationActions`
list. Entries are stable authored action identities for concrete ways to
investigate that subject. They may share one parser/structured/dialogue operation.
`assess()` rejects incomplete definitions before rolling. `resolve()` performs
self-control once, or accepts voluntary surrender, retaining the resulting
obligation. Merely resolving it spends no action time and reveals no hidden facts.

Before the ordinary story action executes, call `permits(actionIdentity)`.
Unresolved occurrences permit nothing. After a failed check only the listed
investigative actions are permitted through this contract; after success or
completion the occurrence imposes no restriction. The author must install this
gate in each applicable entry path. It is not an automatic global parser filter,
and unrelated emergency or forced-action exceptions are not inferred.

Execute the permitted action through its normal mechanics, charging its normal
time/resources and applying its actual consequences. At the end of that same
transaction, call `complete(actionIdentity,evidence)` with a nonempty account of
the completed investigation. Do not call it for an assessment or failed attempt
that did not investigate the subject. Completion clears the obligation and binds
the action, evidence and game time. Identical completion calls reuse that record;
a different action or explanation rejects. A transaction failure rolls back both
the action and the completion. An investigation need not discover a secret to
satisfy the compulsion.

The `expanded-curiosity.t` integration opens an authored cabinet in five seconds,
then records completion, with no automatic secret reveal. Its assertions cover
failed and successful resistance, voluntary acceptance, action gating, missing
definitions, repeat resolution, completion replay, rollback, undo, saved pending
obligations and rated purchases. All are unrun. Broader story-action integration,
parser/dialogue parity and general investigation mechanics remain incomplete;
this entry remains partial rather than treating the author interface as complete
catalogue coverage.

## Physical-danger avoidance

`RpgExpandedDangerAvoidance` is the full-2008 B129 base −10 self-control trait.
It uses the shared `cowardice` catalogue key for compatibility. Set `approved`
and the purchased rating; explicit template rows accept
`['cowardice',1,scope,rating]`. The four ratings cost −20/−15/−10/−5 and supply
physical-danger fear penalties of 4/3/2/1 respectively. Its definition requires
one level and no unimplemented percentage modifiers.

Use `RpgExpandedDangerAvoidanceTrigger` for one proposed physical risk, with the
inherited owned occurrence fields, `physicalDanger = true`, and a nonempty unique
`riskyActions` list of authored action identities. Set `risksDeath` when appropriate;
it adds −5 to this self-control check. `resolve()` rolls once and retains the
refusal obligation on failure. It does not execute an action or charge its costs.

Gate the proposed actions with `permits(identity)`: an unresolved occurrence
permits nothing, a successful check permits the risk, and a failed check rejects
listed risky actions while allowing other actions such as retreat. Set
`greaterDanger` and nonempty `greaterDangerEvidence` before resolving when another
physical threat compels the risk. That explicit exception permits the risky action
even after failed resistance. These facts are bound to the occurrence; changing
them afterward rejects rather than allowing a reroll. Dynamic changes of threat
require a separate authored occurrence and remain an integration responsibility.

The health module derives the fear penalty through
`profile.physicalDangerFearPenalty()`. It applies only when a fear context declares
physical risk. A matching explicit penalty is not added again; a conflicting
nonzero override rejects. Contexts using older authored trait records retain their
existing explicit-classification path. Including traits alone does not install the
health module or enable fear encounters.

The fixture specifies all four prices and fear penalties, ordinary versus mortal
risk, refusal versus retreat, the evidenced greater-threat exception, malformed
facts, replay, rollback, undo and saved continuation. Assertions remain unrun.
Social reactions from informed occupational observers are available through
`RpgExpandedDangerReactionContext`. Dynamic threat transitions and parser/dialogue
action gates remain incomplete; this catalogue entry remains
partial. The author determines actual physical danger and greater threats, and
must route all relevant action entry points through the permission contract.


## Advanced martial training

`RpgExpandedMartialTraining` represents the thirty-point cinematic permission
from `full-2008`, B93. Set `approved` and `prerequisiteEvidence` to record the
campaign's availability decision and its additional prerequisites (or their
absence). The fixed single-level form currently rejects percentage modifiers.
An active, unmitigated instance halves the repeated bare-hand parry penalty in
owned catch attempts. Duplicate instances are rejected before a catch roll.

The trait grants no skills automatically. Rapid-strike integration, cinematic
skill prerequisite integration and other melee-parry adapters remain pending;
this catalogue entry is partial. `test_catch_repeat_parry` contains expected
scores for ordinary and trained repeated parries, inactive benefits and independent
hand counters. These assertions are authored, unrun while checks are paused.

## Enhanced jumping

`RpgExpandedEnhancedJump` costs ten points per level (`full-2008`, B89).
Set `approved`; the current definition supports the unmodified trait and rejects
percentage modifiers. `RpgExpandedJumpDistance` consumes active, unmitigated
levels and doubles final distance per level. Duplicate trait instances are
rejected when querying that benefit. The trait does not grant Jumping skill.

Jump movement speed, jump attacks and the trait's fall-protection procedure
remain pending, so the catalogue entry remains partial. Pure profile fixtures
cover pricing, disabled benefits, running/preparation multipliers, optional
strength boundaries and paid skill selection. Assertions are authored, unrun.

Enhanced-jump fall protection now uses an owned exploration landing receipt:
see [enhanced-jump fall protection](exploration.md#enhanced-jump-fall-protection).
It compares the full prepared running high-jump maximum with the fall and can
reuse one successful Acrobatics landing for the five-yard extension. Jump
movement speed and jump attacks remain pending; the trait is still partial.

The enhanced-jump speed rule is now available through exploration's pure
`travelAssessment`: current ground Move or one fifth of maximum broad-jump
range, whichever is greater. It retains fractional speed and calculates elapsed
whole seconds. Committed travel, interruption and jump attacks remain pending.

## Social inhibition

`RpgExpandedSocialInhibition` implements the ordinary three-tier trait from
full-2008 B154 with neutral public identifiers. Set `approved = true` and `level`
1, 2 or 3. Fixed costs are -5, -10 and -20; contextual interpersonal-skill
penalties are -1, -2 and -4 respectively. Percentage modifiers, self-control
variants and duplicate instances are rejected.

The shared contextual score hook applies the penalty once to the printed list
of interpersonal skills, including Carousing, Diplomacy, Fast-Talk and Teaching.
An authored additional skill can set `requiresSocialInteraction` to establish
that the broader printed interpersonal-skill condition applies. Administrative
checks are not automatically penalized. Inactive or mitigated traits retain their
point cost but contribute no current penalty.

Tier 3 blocks learning affected skills through expanded profile learning
permission, including when the optional skills module is absent. It permits
penalized default use. An already-paid affected skill at this tier is explicitly
rejected as requiring an acquisition/retention adapter; the reference's learning
prohibition is not silently interpreted as deleting the character's investment.
The same permission participates in character training validation.

The base Lite context hook returns zero when this expansion effect is absent and
adds no randomness. The social-inhibition fixture covers price tiers, contextual
penalties, default use, learning rejection, mitigation, duplicate definitions and
an actual Carousing preparation. Assertions are authored, unrun. Roleplay remains
authored; later acquisition with existing skills and modified variants remain
pending.

## Emotional-understanding deficit

`RpgExpandedEmotionalUnderstandingDeficit` implements the ordinary B142 trait
under a neutral identifier. It costs -20 points, requires approval, and rejects
levels, self-control and percentage-modifier variants. It applies -3 to the
printed emotion-dependent skills, including Acting, Carousing, Criminology,
Detect Lies, Diplomacy, the audience-influence skills, Fast-Talk, Interrogation,
Leadership, Merchant, Politics, Psychology, Savoir-Faire, Sex Appeal, Sociology
and Streetwise. These skills remain learnable.

An additional authored skill can set `requiresEmotionalUnderstanding` when it
relies on emotional motivation. The flag and the printed list identify one
applicability condition; appearing in both does not apply the penalty twice.
The shared context hook adds this penalty to other distinct effects such as
social inhibition. It contributes zero when inactive or mitigated, with its
purchased point cost unchanged. It does not remove the character's own emotions.

Profile validation rejects duplicate instances and incompatible traits with IDs
`empathy`, `callous`/`callousness`, or `oblivious`/`emotional-obliviousness`.
The last pair identifies the B146 emotional-motivation disadvantage, not every
other form of social awkwardness. Custom trait definitions must preserve those
semantic identities for the compatibility check.

The emotional-understanding fixture covers pricing, penalties, stacking,
mitigation, learning permission, explicit additional-skill applicability,
incompatible traits and a Carousing preparation. Assertions are authored, unrun.
Modified variants, complete catalogue mapping and any setting-specific emotional
reasoning contracts remain pending.

## Loss of pleasure

`RpgExpandedPleasureLoss` implements the ordinary B140-B141 trait at -15 points.
It applies -3 through the shared context hook to Carousing, Connoisseur, Erotic
Art and Gambling. It rejects duplicate instances and modified/self-control
variants. Inactive or mitigated instances contribute no current penalty; their
purchased cost is unchanged.

The social module provides an explicit observation context for the separate
reaction effect. The trait does not automatically penalize every observer or
invent an influence immunity. Narrative appreciation, motivation and setting
consequences remain authored; modified variants and those broader authoring
contracts remain pending. The pleasure-loss fixture covers all four skill
categories, an unaffected skill and scoped reaction behavior; assertions are
unrun.

## Emotional obliviousness

`RpgExpandedEmotionalObliviousness` implements B146 at -5 points. It applies -1
to use and resist Diplomacy, Fast-Talk, Intimidation, Savoir-Faire, Sex Appeal and
Streetwise. The public identifier `emotional-obliviousness` distinguishes this
motivation-understanding trait from other social-awkwardness entries.

The shared skill hook handles the acting character. A separate influence
resistance hook handles the target and composes with the existing intimidation
resistance modifier. With no active expansion effect, that hook returns zero and
the existing Lite calculation and dice consumption are unchanged. Inactive or
mitigated instances contribute neither penalty. Duplicate definitions and
modified/self-control variants are rejected; the emotional-understanding deficit
also rejects this trait as incompatible.

Effective resistance below three is explicitly rejected before any influence
dice are spent because the existing contest adapter does not resolve that case.
This integration does not claim to complete all expanded influence exceptions or
other traits' resistance rules. The fixture covers actor and target penalties
separately and together, mitigation, the absent-effect path, low-resistance
rejection, rollback, undo and cross-process continuation. Assertions are authored,
unrun.

### Callousness (full-2008, B125)

`RpgExpandedCallousness` costs -5 and applies -3 to Teaching through the
shared score path. `RpgExpandedCallousnessContext` names the subject, target,
skill, approval and evidence. Set `helpfulPsychology` for assistance rather than
research, `pastVictim` for an interaction with someone previously harmed by the
subject's conduct, and `coercive` for threats or torture using Interrogation or
Intimidation. The first two conditions impose -3; coercion grants +1. Overlapping
penalty descriptions apply once. Ordinary research receives no penalty.

Supply these facts for the particular interaction; the engine cannot infer a
history of mistreatment from dialogue. Pass this context to the shared skill or
influence operation. The existing interrogation question procedure recognizes
the new trait for its threat/torture bonus. Set the question's `pastVictim` fact
when the prisoner previously suffered from the interrogator's conduct; the
question then applies -3 as well. Do not repeat either effect in its modifier. Inactive or mitigated traits retain their cost but suspend their
effects. The emotional-understanding deficit remains incompatible.

`RpgExpandedCallousnessReactionContext` in the social library names an observer
and accepts `pastVictim` and `empathicObserver` facts with approval and evidence.
Either condition gives -1; both together still give -1. Attach it to a reaction
attempt's `socialContext`. This does not infer observer abilities or histories.
The minimal fixture covers these contextual calculations and invalid facts;
checks remain paused, so this entry remains partial and unverified.

### Learning bar (full-2008, B125)

`RpgExpandedLearningBar` costs -30. It leaves starting skills valid and usable,
but blocks new skill investment through development offers, direct skill
purchases and study. It also blocks familiarity practice and recognition before
time or randomness is spent. Existing familiarities remain usable. Active,
unmitigated instances block DX and IQ advancement; ST and HT offers can proceed
through their ordinary approval and point gates.

A trait purchase must supply `expandedTraitNature` (`mental` or `physical`) and
`expandedTraitEvidence` on its `RpgDevelopment` offer. Mental purchases are
blocked; approved physical purchases remain possible. Unclassified traits and
secondary-characteristic advancement return explicit unresolved reasons rather
than guessing. Buying off the disadvantage uses the existing removal path.

`learningAcquisitionReason(kind)` distinguishes acquisition from creation
validation. Custom technique acquisition must consult it with `technique` before
spending resources. `RpgExpandedTechniquePurchase` now enforces this gate for
shared point purchases. Temporary modular ability integration remains pending;
a callback alone does not complete it.
Direct assignments to character fields are author operations and must not be
used to bypass advancement assessment. The fixture covers rejection without
spending, allowed purchases, mitigation, replay, rollback, undo and save
continuation; it has not been run while checks are paused.

### Speech limitation (full-2008, B125)

`RpgExpandedSpeechLimitation` costs -15 for inability to articulate speech, or
-25 with `total = true` and `points = -25` for inability to vocalize at all.
The first form permits nonlinguistic sounds and compatible voice traits. Both
reject stuttering; the total form also rejects voice, mimicry, disturbing voice,
and custom traits marked `voiceRelated`. Compatibility is checked independently
of mitigation; mitigation suspends the action restriction, not the point cost.

Set `requiresSpeech` on a context for articulated words, or
`requiresVocalization` for a nonlinguistic sound. The shared score/check path
rejects unavailable communication before randomness. Existing effort checks
using `talk` or a speech requirement also respect the limitation. Contexts for
writing, shared signing and other nonvocal channels remain available; authors
must describe the actual channel rather than infer it from a skill name.

Nonshared signing between player characters uses `RpgExpandedGestureExchange`
in the social library. Its sender can receive full-rate credit through
`RpgExpandedCommunicationStudy` in development; other channels remain pending. The fixture covers costs, channel distinctions, compatibility
and rejection without random draws; checks remain paused.

### Compelled assistance (full-2008, B125)

`RpgExpandedCompelledAid` has a -15 base price and uses the shared self-control
ratings. Create one `RpgExpandedAidTrigger` per occurrence, identifying the
recipient, available `assistance`, why the character `shouldResist`, approval and
evidence. The author must establish actual means to help; the trait creates no
items, money or abilities. Hostility, orders and possible traps do not exempt an
otherwise eligible opportunity. `assess()` is pure; `resolve()` uses the existing
self-control machinery, including voluntary surrender and the explicit campaign
policy for point-funded resistance. Repeated resolution does not reroll.

Bind an `RpgExpandedAidDecision` to the resolved trigger with `choice = 'offer'`
or `'decline'`. A failed check requires the offer. Recording it satisfies this
obligation without performing or paying for the promised assistance; use the
relevant action and resource rules for subsequent help. The recorded choice
cannot be changed on replay. Authors must route this scene decision through the
interface; automatic parser/dialogue discovery of aid opportunities is pending.

The fixture covers resistance, surrender, invalid opportunities, required offers,
replay, rollback, undo and save continuation. It remains unrun while checks are
paused, so the inventory entry remains partial.

### Low motivation (full-2008, B126)

`RpgExpandedLowMotivation` has a -15 base cost and shared self-control pricing.
`RpgExpandedMotivationTrigger` supplies a unique occurrence, distinct string
`choices`, an authored `leastEffort` choice, approval and evidence. Describe the
actual available courses of action, including a companion's demand when that is
the easier course. Failed resistance constrains the decision to that choice;
success permits any listed choice. This implements a fictional behavior rule,
not a clinical model or an inference about a person's intentions.

With `minimumNecessitiesOnly` and exactly one choice, assessment returns
`motivation-no-trigger` without a roll; perform that ordinary action through its
normal interface. Multiple choices still call for resistance. Mitigation also
returns no trigger. `RpgExpandedMotivationDecision` records a resolved choice
once and clears its obligation; the subsequent action retains its ordinary time
and resource costs. Authors must route the scene choice through this interface.

The self-control receipt binds the full choice list and prevents rerolls of the
same occurrence. Fixtures cover least-effort choices, resistance, minimum needs,
replay, rollback, undo and saved obligations, but remain unrun. Trait replacement
and transition accounting, plus automatic parser/dialogue discovery, are pending.

### Recurrent pain definition (full-2008, B126)

`RpgExpandedRecurrentPain` defines severity 1, 2 or 3; `intervalHours` of 1, 2,
4 or 8; and appearance `frequency` of 6, 9, 12 or 15. Approval is required.
`creationCost()` multiplies the severity's base price by both interval and
frequency factors before dropping fractions. Do not round each factor's result
separately. Its fixed definition rejects self-control ratings and additional
percentage modifiers.

`awakePenalty()` returns -2, -4 or -6, and `intervalSeconds()` exposes the
recovery interval. `appears(roll)` is a pure threshold assessment using the
frequency table's explicit “or less” boundaries. It does not roll, schedule or
apply an episode. The paragraph's informal “below” wording is interpreted using
those explicit table boundaries.

The health library now supplies `RpgExpandedRecurrentPainDay` and
`RpgExpandedRecurrentPainRecovery` for daily waking episodes and interval checks.
Sleep episodes use the health library’s sleepless-rest adapter; overlapping-day
handling remains pending. These definition
methods alone do not modify character scores. The fixture independently lists all 48 prices and appearance boundaries;
it remains unrun and all corresponding inventory entries remain partial.

### Companionship preference (full-2008, B126)

`RpgExpandedCompanionship` costs -5 at level 1 or -10 at level 2. For IQ-based
skill checks, attach an approved `RpgExpandedCompany` to the context's `company`.
Its distinct `members` include the subject: one member means alone; four means
the subject and three companions. This is the interface's explicit convention
for the printed group-size threshold. Evidence establishes who actually provides
company, rather than counting all characters in a room automatically.

Level 1 applies -1 while alone. Level 2 applies -2 alone, -1 in groups of two
through four, and zero with five or more. IQ-based skill checks without company
facts reject while the trait is active; attribute-only checks are unaffected.
Inactive or mitigated traits retain their price but suspend their effects.

`RpgExpandedCompanionshipReactionContext` in the social library names the subject
and the reacting `observer`. With approved evidence and `usualReaction`, it adds
+2 or +4 for the observer's trait. It never adds this bonus merely because the
subject has the trait. Unusual reactions are explicitly authored with that flag
unset. Attach the context to the reaction attempt's `socialContext`.

The fixture covers both levels, group-size boundaries, reaction ownership,
exceptions and missing facts before randomness. It remains unrun. Automatic
scene membership and integration with every specialized skill operation remain
pending, so the inventory entry remains partial.
