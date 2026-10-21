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

## Additional catalogue talents

Use `rpgExpandedMakeCatalogueTalent(id, level, approved)` to create a fresh
purchase, then install it in the character's owned `traits` list. Approval records
the campaign's permission; levels are 1–4. Prices are per level (full-2008,
B89–B91). Skill memberships are fixed in `catalogueTalentSkills(id)`.

| ID | Points per level | Eligible reaction audience, subject to demonstrated and appreciated aptitude |
|---|---:|---|
| `animal-aptitude` | 5 | Animals |
| `artistic-aptitude` | 5 | Buyers or critics of the subject's artwork |
| `commercial-aptitude` | 10 | Business counterparts |
| `medical-aptitude` | 10 | Current or former patients |
| `musical-aptitude` | 5 | Listeners or critics of the subject's music |
| `numerical-aptitude` | 10 | Engineers or scientists |
| `plant-aptitude` | 5 | Gardeners or sentient plants |

The existing three talent IDs remain supported. Musical aptitude includes only
the conducting specialty of group performance; other included skills receive
their usual specialty coverage. `catalogueTalentApplies(id, skill)` is the shared
predicate for skill, study and reaction eligibility. Optional specialties retain
the parent's required specialty through `studySpecialty()`.

Overlapping catalogue talents add skill bonuses, including totals above four.
Study uses the greatest applicable level, so reductions do not stack. Reaction
contexts still select one demonstrated talent and require authored audience facts;
combining several talent reaction claims remains unsupported. The seven additional IDs support ordinary template rows and fresh reconstruction.
Source-skill default transfers remain pending. Fixtures are authored but unrun.

## Custom talent groups

`rpgExpandedMakeCustomTalent(profile, id, skillIds, level, approved, evidence)`
creates a fresh `RpgExpandedCustomTalent`; install it in that profile's `traits`
list. The author must approve the group's related, believable innate aptitude
and record the rationale in `evidence` (full-2008, B90–B91). This interface does
not infer relatedness or authorize an arbitrary all-purpose weapon group.

List distinct base skill IDs; specialties count once. One through six skills cost
5 points per level, seven through twelve cost 10, and thirteen or more cost 15.
Levels range from one to four. The implementation accepts up to 1,000 listed IDs.
Exceptional author pricing is unsupported and rejected. The purchased skill list,
ID, owner and approval rationale are bound; changing them requires a separately
authored replacement procedure rather than mutating this purchase. Levels may
change through the usual advancement accounting; no factory spends points.

Raw and contextual skill benefits, prerequisites, study reductions and optional
specialties use the existing talent paths. Overlapping skills add bonuses while
study uses the strongest talent. `RpgExpandedTalentReactionContext` also accepts
this purchase: the author supplies the appreciative audience and demonstrated
skill. It still resolves only one talent reaction claim.

A custom purchase cannot be shared by profiles or reconstructed by template
composition. Template cloning, custom specialty-only groups, group amendments
and exceptional prices remain unsupported. Price-boundary, ownership, binding,
reaction, mitigation, undo and save-continuation fixtures are authored but unrun.

## Pressure support

`RpgExpandedPressureSupport` implements the three standard ambient-pressure tiers
(full-2008, B77–B78): set `level` to 1, 2 or 3 and `approved = true`, then install
the purchase in the character's traits. Costs are 5, 10 and 15 points. Template
rows `['pressure-support', level, nil]` create fresh approved purchases, and
composition reconstructs them without sharing objects.

`profile.pressureSupportLevel()` returns active, unmitigated protection and
validates the purchase. The hazard module uses it for constant-pressure exposure
thresholds and decompression risk. It does not grant armor against localized
crushing, explosions, vacuum protection, sealing or breathable air. Nonstandard
`profile.nativePressureHundredths` is a zero-point authored feature (default 100).
Character templates preserve this feature and reject conflicting compositions.
Ancestry packages also support a mandatory bound native-pressure feature;
changing-pressure procedures remain pending. Tier, mitigation, purchase-copy and exposure-binding fixtures are
authored but unrun.


## Free-fall susceptibility

`RpgExpandedFreeFallSusceptibility` costs -10 points, with `level = 1`,
`approved = true` and `scope = 'regular-space-travel'`. The scope is the author's
explicit declaration that the campaign features regular space travel; omitting it
rejects the purchase (`full-2008`, B156). The fixed trait rejects alternative cost,
levels, self-control or custom skill lists. Template plain/copy operations preserve
the declaration and create independent purchases.

An active, unmitigated purchase supplies susceptibility to free-fall entry: health
-4 and no eight-hour adaptation after failure. Character validation and the shared
learning gate reject paid free-fall training, including optional specialties by
study identity. Defaults remain usable. The paid-skill resolver also rejects an
invalid injected purchase. Temporarily mitigating the hazard effect does not
remove the prohibition on buying the skill; removing the trait is a separate
character-development decision.

An unresolved free-fall exposure binds the effective susceptibility at entry.
Changing protection or trait activation during that episode rejects instead of
rewriting its recovery rules. Return to normal gravity before starting an exposure
with changed physiology. General free-fall task caps, ancestry composition and
mid-exposure trait transformation remain pending. The integration fixture is
[`expanded-free-fall-trait.t`](../../tests/fixtures/expanded-free-fall-trait.t);
its cost, campaign, learning and hazard cases are authored but unrun.


## Orientation sense

`RpgExpandedOrientationSense` has two fixed levels costing 5 and 10 points
(`full-2008`, B34). Set `approved = true`; the trait rejects custom costs, scopes,
self-control and skill lists. The template factory copies each purchase independently.

World authors must set `profile.orientationEnvironment` to `local`, `deep-space`
or `cross-dimensional` before requesting skill scores from a character with the
active trait. The local category includes ordinary planetary, underground and
underwater settings where directional orientation applies. The lower level gives
no bonus in deep space; neither level supplies a bonus across dimensions. Missing
world facts reject instead of inferring that the ability functions.

Both levels give +3 to `body-sense` and `navigation` specialties `air`, `land` and
`sea` where the ability functions. Level two also gives +1 to `piloting` and +2
to `aerobatics`, `free-fall`, and navigation specialties `space`/`hyperspace`.
Bonuses enter the shared skill score once, including its legal defaults and
prerequisite level comparisons, and therefore also affect free-fall task caps.
They do not change purchased points or training costs. The check-only path also
supports characters using the foundation without the expanded skill resolver.

North answers and whole-route retracing now have explicit world-fact interfaces
in the [exploration guide](exploration.md). Automatic world/calendar feeds,
partial routes, automatic network coverage, ancestry composition and world-transition
automation remain pending. Those interfaces preserve the original journey ledger and require authored world facts.
See [`expanded-orientation-sense.t`](../../tests/fixtures/expanded-orientation-sense.t)
for the minimal fixture and independent bonus/default/cap expectations; unrun.


## Signal-dependent orientation

Set `RpgExpandedOrientationSense.signalDependent = true` for the printed -20%
limitation (`full-2008`, B35). Total cost is 4 points at level one or 8 at level
two. Template copying preserves this flag. The reduction does not itself declare
that a network exists or works in the character's location.

The world author sets `profile.orientationFrame` to an identity for the current
location/context and records a `RpgExpandedOrientationSignalReport` with matching
`frame`, a unique `id`, `profile`, `approved = true` and original `evidence`.
`available`, `compatible` and `jammed` describe the actual signal; an available
signal also requires a `network` identity. `assess()` previews these facts and
`record()` stores an immutable observation at the shared clock time, making it
the character's current report. Reports consume no randomness or elapsed time.

The ability works only with available, compatible, unjammed coverage. A known
unavailable/incompatible/jammed signal suppresses both skill bonuses and the
north/retracing interfaces. Missing reports, reports from another character, a
changed frame or elapsed time reject the query until a fresh report is recorded.
This deliberately requires current author facts instead of silently extending
coverage. Replaying an old report does not refresh its timestamp or replace a
newer report. Historical reports remain available for save, undo and audit.

Character cost validation does not require a current signal; the observation is
required when using the limited ability. Automatic coverage sensors, jamming
contests, combinations with other trait modifiers and ancestry composition remain
pending. The fixture
[`expanded-orientation-signal.t`](../../tests/fixtures/expanded-orientation-signal.t)
covers costs, copying, eligibility, time/frame staleness, preview, replay,
rollback, undo and save continuation. It remains unrun while checks are paused.


## Humorlessness

`RpgExpandedHumorlessness` is a fixed -10-point purchase with `level = 1` and
`approved = true` (`full-2008`, B146). It rejects custom cost, scope, self-control
and skill lists. Template plain/copy operations create independent purchases.
Character validation rejects duplicates. Its reaction penalty requires a recorded
observer-specific indication that the behavior was evident; see
[observed behavior](social.md#observed-behavior-in-reactions). No universal
reaction penalty or compulsory player dialogue is added.


## Pervasive distrust

`RpgExpandedPervasiveDistrust` costs -10 points with `level = 1` and
`approved = true` (`full-2008`, B148). Custom costs, scopes, self-control
and skill lists are rejected. Character validation rejects duplicate purchases;
template plain/copy operations produce independent purchases. Active, unmitigated
traits enable the [observer-specific effects](social.md#pervasive-distrust).
Trust decisions and character dialogue remain authored/player choices.


## Phantom voices

`RpgExpandedPhantomVoices` implements the three purchase severities from
`full-2008`, B148: `level` 1/2/3 with `points` -5/-10/-15. Set
`approved = true`; custom scopes, self-control and skill lists are rejected.
Template plain/copy operations preserve severity in independent purchases.
Duplicate purchases reject during character validation.

`RpgExpandedPhantomVoiceOccurrence` implements an optional author-selected stress
check. Set a unique `id`, owning expanded `profile`, a unique `stressor` object,
`approved = true` and original `evidence` describing the stressful occurrence.
`assess()` is pure. `resolve()` rolls three dice once; six or less starts an
episode. It records the severity, roll and onset on the character's shared time
ledger without charging time or fatigue. Another object for the same stressor
is rejected; repeating the original returns its stored result.

`active()` reports whether that occurrence produced an episode which has not
ended. The source specifies no fixed duration: call `end(true, evidence)` when
the author confirms cessation. Ending is recorded and repeatable without extra
charges. Different stressors can have separate occurrences; ending one does not
end another. Existing fear, injury and other consequences are not replaced.
These records contain private author information, not automatically player-visible
explanations of the character's experiences.

Owned full fear events now execute the mandatory check after failure or exact
success, as documented below. Direct rolled
self-control and abridged fear calls reject active phantom-voice combinations
before randomness; owned self-control triggers integrate as described below.
Episode-induced fear and broader treatment procedures remain incomplete.
Command resistance, sound masking and a funded origin-aware cure path use the
concrete interfaces below. This interface must not be presented
as the complete disadvantage.

[`expanded-phantom-voices.t`](../../tests/fixtures/expanded-phantom-voices.t)
specifies costs, copies, the six/seven trigger boundary, preview, duplicate
occurrences, replay, explicit ending, rollback, undo and save continuation.
The fixture and `test_phantom_voices` remain unrun while checks are paused.


### Stress-related self-control integration

For an owned `RpgExpandedSelfControlTrigger` on a character with active phantom
voices, set `stressRelation` to `stress-related` or `unrelated` before a rolled
attempt. Missing classification blocks assessment before randomness or spending.
The author uses the trigger's existing `evidence` to explain the relationship.
Characters without the active trait keep their existing behavior and draw count.

A failed stress-related roll automatically resolves one additional voice check
and stores it in `phantomVoiceOccurrence`. The original self-control obligation
remains active regardless of whether voices occur. Exact self-control success,
unrelated rolls, voluntary surrender and purchased success do not trigger the
extra check. The latter two are choices without a failed die roll. Trait
mitigation suppresses the extra check.

The generated occurrence uses `self-control:` followed by the trigger ID, and
the trigger object as its stressor. These identities are preflighted before the
original roll. Reserve that ID prefix for this integration. Replay validates the
linked occurrence and returns both saved results without rolling. Engine
transactions restore both histories and randomness together on exception or undo.

Use the owned trigger interface for this combination. Direct low-level
`rpgLiteSelfControl` calls reject rolled attempts with active phantom voices using
`phantom-voices-owned-self-control-required`; voluntary surrender remains
available without a roll. `rpgLiteFright` rejects the active-trait combination
with `phantom-voices-full-fear-integration-required`, because abridged fear cannot
supply the required full procedure. Mitigated or absent phantom voices preserve
existing behavior. Full fear events use their own preflighted stress follow-up;
the direct abridged call remains guarded.

The shared `rpgLiteSelfControlCore` function is internal arithmetic used after
owned-trigger preflight. Author integrations must use the public direct function
or the owned trigger, rather than calling the core and bypassing policy.
[`expanded-voice-self-control.t`](../../tests/fixtures/expanded-voice-self-control.t)
specifies classification, success/failure boundaries, unrelated rolls, mitigation,
surrender, purchased success, preview, replay, rollback, undo and save continuation.
Its assertions remain unrun while checks are paused.


`test_voice_direct_guards` adds unrun fixtures for rejection before randomness,
voluntary surrender, mitigation and unchanged direct behavior without the trait.
Both guards throw a structured expanded error so callers cannot mistake an
unsupported request for a failed resistance roll.


### Command resistance

`RpgExpandedVoiceCommand` implements the author-selected Will roll for commanding
severity (`full-2008`, B148). Supply a unique `id`, an owned active `occurrence`
at severity three, a distinct `command` token, original `instruction` text,
`approved = true` and `evidence`. At least one of `underStress` or `intoxicated`
must describe the current authored situation. Approval explicitly selects the
source's discretionary resistance check; the module does not roll for every
spoken command. Current mitigation, unconsciousness or death prevents a new check.

`assess()` is pure. `resolve()` uses the shared Will resistance check, including
applicable health effects, and stores its result in the occurrence's `commands`
history. It returns `resisted`, `check`, `instruction` and the assessed `score`.
There is no additional time, fatigue, point or inventory charge. A successful
check resists this command. On failure, the author/player flow must adjudicate
the named action, including its legality, targets, costs and ordinary success
checks. The resistance result never makes the commanded action succeed or directly
changes another character, item or injury ledger. This is an explicit narrative
decision point tied to the recorded instruction and check.

The same command token or ID cannot be rolled again within the occurrence.
Repeating the original request validates its bound instruction, qualifying facts
and result, then returns `reused`. Historical results remain readable after the
episode ends; new checks require an active episode. Distinct commands use new
tokens and author approval. Command content and episode origins remain private
author data unless deliberately revealed by the game.

[`expanded-voice-command.t`](../../tests/fixtures/expanded-voice-command.t)
and `test_voice_command` specify stress and intoxication eligibility, exact Will
success and failure, duplicate rejection, inactive episodes, mitigation, preview,
replay, rollback, undo and cross-process save continuation. Assertions remain
unrun while checks are paused. Automatic command/action routing remains pending.


### Sound masking

For disruptive severity, `RpgExpandedVoiceSoundMask` records an author-confirmed
interval in which the episode drowns out ordinary sound (`full-2008`, B148).
Supply a unique `id`, the active severity-two `occurrence`, `approved = true`
and original `evidence`. The current trait must still be active at severity two.
`assess()` is pure; `begin()` records the shared clock without rolling or charging
time, fatigue or points. Repeating the same interval reuses its receipt. Another
interval within the same episode must wait until the earlier interval ends.

The shared scoring path returns unavailable with
`phantom-voices-sound-masked` for hearing and spoken-input tasks while a mask is
active. The corresponding check returns a blocked result without random draws.
`RpgLiteContext.auditoryInput` defaults to `auto`: hearing checks and
`understandsSpeech` tasks require sound unless marked `written`. Set `required`
for other tasks dependent on ordinary sound, or `none` when the authored task
uses a non-auditory channel, such as reading visible signs. These fields describe
the actual task channel; they do not confer alternative senses. Invalid channel
values reject while masking applies. This does not remove the character's ability
to speak or impose a general mental penalty.

Call `end(true, evidence)` when the author confirms ordinary sound is audible
again. No fixed duration is invented. Ending the episode also deactivates all of
its masks; mitigation suppresses their effects while it applies. Histories remain
available for replay and saves. Separate episodes can mask simultaneously, and
ending one mask does not end another episode's effect. Commanding severity does
not automatically inherit masking because that inheritance is not explicit in
the supplied entry.

[`expanded-voice-mask.t`](../../tests/fixtures/expanded-voice-mask.t) and
`test_voice_mask` specify hearing, speech, writing, alternate channels, absence of
extra dice/time, preview, replay, overlapping episodes, mitigation, rollback, undo
and cross-process save continuation. These assertions remain unrun. Startling
voices use the owned fear-cue interface below.


### Private origins and funded exorcism buyoff

`RpgExpandedVoiceOrigin` records author-known cause (`full-2008`, B148). Set the
expanded `profile`, owned `RpgExpandedPhantomVoices` purchase in `trait`,
`origin = 'psychological'` or `'possession'`, `approved = true` and original
`evidence`. `assess()` is pure; `record()` stores the immutable origin without
rolling or charging time. One origin record is allowed per purchase. This is
private author state, not a diagnosis or knowledge automatically available to
the character.

`assessPsychotherapy()` explicitly blocks discovering or curing a possession
cause with `voice-origin-psychotherapy-cannot-discover-or-cure`. For psychological
origin it returns `voice-origin-psychotherapy-procedure-required`: knowing the
category does not itself perform diagnosis, treatment or recovery.

`RpgExpandedVoiceExorcism` supports a funded cure after author-confirmed successful
exorcism. Set the recorded `origin`, `successful = true`, `approved = true` and
`evidence` describing the externally resolved exorcism. It requires possession,
an approved historical `RpgExpandedBuyoffBasis`, open development time, sufficient
unspent points and no spending restriction. Assessment returns the exact original
award as `points`; it does not guess the cost from the current severity.

`apply()` delegates to `rpgLiteBuyOff`, removing the purchase and spending that
amount once. It then closes active voice episodes and records the cure on the
origin. Commands, masks and historical checks remain as receipts; no check is
rerolled and no extra time is charged. Repeating the cure returns `reused` and
the original charge without spending again. The existing engine transaction
restores the purchase, points and episodes together on failure or undo.

This path does not roll the exorcism itself. A cure without sufficient funds or
outside the existing buyoff downtime gate is explicitly blocked pending a
source-grounded deferred-payment procedure. The game must not present such a
blocked transaction as a completed cure. Psychotherapy and automatic origin
discovery remain unfinished.

[`expanded-voice-origin.t`](../../tests/fixtures/expanded-voice-origin.t) and
`test_voice_origin` specify origin exclusions, historical cost, affordability,
downtime and approval gates, preview, single charging, episode closure, replay,
rollback, undo and cross-process save continuation. Assertions remain unrun.


## Fixed beliefs and fear acquisition

`RpgExpandedFixedBelief` represents the three severity tiers in `full-2008`,
B130: `level` 1/2/3 costs -5/-10/-15. Supply a distinct nonempty `scope`,
original `beliefText`, `behaviorText` describing its actual behavioral impact,
and `approved = true`. Approval includes campaign suitability, particularly for
the most disruptive tier. Severity follows behavior, not the unusual wording of
the belief alone. The one-point harmless form remains a separate quirk.

Expanded character validation permits distinct scoped purchases of this type
under the common neutral ID. It rejects repeated scopes, invalid definitions and
combined credit over forty points. `traitMayRepeat(trait)` defaults to the
existing quirk-only exception for ordinary profiles. Mixing these purchases with
the older `delusions` identifier rejects until composition is implemented.
For ownership above forty nominal points, set `creditedPoints` explicitly on
one or more purchases. Each allocation is between zero and its nominal severity
cost. Before creation closes, allocations must total the smaller of forty and
the nominal total. Leaving the field unset uses full severity credit; there is
no implicit list-order allocation. This is an author-selected accounting
allocation, not an additional source rule about which belief receives credit.

Severity, reactions and behavior remain unchanged by reduced credit. Character
costs, negative-component limits and template copying use the allocated credit.
Creation finalization records original buyoff bases even for zero-credit negative
purchases. After creation, historical allocations are retained rather than
redistributed when a purchase is removed. Buyoff still requires explicit approval
of that historical basis. Fear acquisition checks nominal severity separately
from its credited value and never creates spendable points.

Template copying creates a fresh purchase with the same severity, scope and
author text. Plain shorthand rejects with
`fixed-belief-authored-definition-required`, because a name and severity alone
cannot supply the belief and behavior. Historical acquisition receipts are not
copied to the new purchase.

`RpgExpandedFixedBeliefAcquisition` executes the accounting part of fear rows
twenty-two and thirty-four (B361). Set unique `id` and `eventId`, `profile`, an
unowned authored `trait`, `tableTotal = 22` or `34`, `approved = true` and
`evidence` connecting the purchase to that selected outcome. It requires a
completed creation profile and exactly the row's nominal -10 or -15 severity.

`assess()` is pure. `apply()` installs the purchase once, records the event and
increments the development revision. It does not award earned or unspent points.
The post-creation disadvantage allowance keeps this involuntary acquisition from
retroactively violating the creation disadvantage limit. Repeated application
returns its receipt without another purchase or revision.

`RpgExpandedFixedBeliefPortrayal` records concrete author adjudication. Supply
`id`, `profile`, the owned `belief`, a `situation` identity, `decision` (`followed`
or `departed`), actual `observedBehavior`, and `approved = true`. Pure `assess()`
checks these facts; `apply()` records them once without time, points or randomness.
Each belief has at most one portrayal per situation. Replay binds the original
behavior, severity and decision. A departure is recorded, not automatically
permitted or penalized. Authors still route actions and dialogue explicitly.

Use the social module's `RpgExpandedFixedBeliefObservation` for witnessed
reactions. Multi-belief reaction stacking, automatic action/dialogue routing,
unfunded or outside-downtime revelation buyoff and compound fear outcomes remain
pending. These entries remain partial. Beliefs are character fiction, not
automatically established world facts or additional abilities.

[`expanded-fixed-beliefs.t`](../../tests/fixtures/expanded-fixed-beliefs.t) and
`test_fixed_beliefs` specify both fear prices, unchanged earned/unspent points,
creation-limit allowance, multiple scopes, the forty-point boundary, duplicate
scopes, preview, replay, rollback, undo and save continuation. They remain unrun.

## Belief truth, knowledge and revelation

`RpgExpandedFixedBeliefKnowledge` records private authored facts separately:
`truthConfirmed`, `characterAware` and `playersRecognize`. Supply a unique `id`,
`profile`, owned `belief`, approval and evidence. Subsequent records name the
latest receipt for that belief as `previous`; they do not rewrite history.
`record()` binds the facts without publishing them, changing points, or rolling.
False or unknown truth and mistaken recognition can be represented independently.
Authors must not expose these objects or private evidence in player views.

`RpgExpandedFixedBeliefRevelationBuyoff` uses the latest `knowledge` receipt,
approval and evidence. Both confirmed truth and player recognition are necessary
for this route (`full-2008`, B130); character awareness alone is insufficient.
Unavailable disclosure states share one reason and return no private facts.
The operation requires an approved historical buyoff basis, open advancement and
sufficient unspent points, then delegates to the shared buyoff ledger once.
Replaying a completed operation does not charge again. It does not force a reveal,
grant an ability, or automatically remove the purchase when truth is recorded.
Unfunded mandatory buyoff and outside-downtime resolution remain pending.

[`expanded-belief-revelation.t`](../../tests/fixtures/expanded-belief-revelation.t)
and `test_belief_revelation` specify private-state result parity, recognition,
affordability, replay, rollback, undo and save continuation. They remain unrun.


[`expanded-belief-credit.t`](../../tests/fixtures/expanded-belief-credit.t) and
`test_belief_credit` specify forty-five nominal points with forty credited,
unchanged severity, template copying, zero-credit original bases, allocation
rejection, replay, rollback, undo and save continuation. Fixtures remain unrun.


## Life-sustaining requirements

`RpgExpandedSustenanceRequirement` defines an authored substance, object or
environment needed for life support (`full-2008`, B130). Supply distinct `scope`,
`requirementKind`, original `requirementText`, `rarity`, `frequency`, approval and
evidence. `illegal` adds the source surcharge before frequency scaling. Rarity is
`rare`, `occasional`, `common` or `very-common`; frequency is `continuous`,
`hourly`, `daily`, `weekly`, `monthly`, `seasonal` or `yearly`.

`rpgExpandedSustenanceCost` applies the four rarity prices and seven frequency
multipliers, discarding fractional magnitude. Character accounting uses that
cost, and template copies preserve the complete authored definition. Multiple
requirements need distinct scopes; shorthand without the definition rejects.
This purchase does not represent skilled maintenance or slow dietary starvation.

`rpgExpandedSustenanceSchedule` returns the multiplier numerator, denominator,
injury interval in seconds, fixed dose period in seconds and calendar period in
months. Monthly, seasonal and yearly periods deliberately have no fixed-seconds
substitute. `requiredContactSeconds()` returns the required residence/contact
duration for periodic objects and environments; it rejects continuous access
and substance doses, whose satisfaction cannot be inferred from that duration.

This is definition, pricing and schedule metadata coverage. Owned access,
consumption, calendar deadlines, missed-access injury and accelerated aging are
still pending; including the trait does not yet execute those effects. No generic
author callback is counted as their implementation.
[`expanded-sustenance.t`](../../tests/fixtures/expanded-sustenance.t) and
`test_sustenance` tabulate all 56 ordinary/legal-price combinations, seven
schedules, contact durations and template copying. Fixtures remain unrun.


Sustenance purchases also accept `acceleratedAging = true` (+30%, B130).
The hazards module requires an owned aging advance on every associated injury
and executes supported crossed boundaries through the shared aging history.
See [deprivation-related aging](hazards.md#applying-deprivation-related-aging)
for age evidence, calendar requirements and explicit unsupported combinations.


## Motion susceptibility

`RpgExpandedMotionSusceptibility` is an approved −10-point purchase (full-2008,
B144), with no levels, scope or self-control multiplier. The template trait
factory supports independent copies under `motion-susceptibility`.
`profile.motionSusceptible(activeOnly)` distinguishes the purchased restriction
from currently active symptoms. Mitigation suppresses active susceptibility; it
does not grant permission to learn prohibited skills.

For characters with this purchase, classify each skill's `vehicleOperationClass`
as 1 for vehicle operation or 0 for other skills. For authored skills outside the existing catalogue, nil is explicitly
unclassified and rejects learning. This author classification must follow the
actual task; it is not inferred from arbitrary skill IDs. Learning hooks and
character validation reject paid vehicle-operation training, while unrelated
classified skills remain available. Full catalogue classification remains
pending. `expanded-motion-trait.t` / `test_motion_trait` specify cost, independent
template copying, mitigation, classification and existing-training rejection.
Fixtures remain unrun; persistent journey symptoms are still outstanding.


The existing Lite catalogue now supplies operation classification through
`vehicleOperationClassification()`: bicycling, boating, driving, piloting and
submarine are operation skills (full-2008 B180, B188, B214 and B223). Other
existing catalogue entries default to non-operation. This does not install the
full expanded skill catalogue or change Lite behavior when the expansion is
absent. An explicit contradictory classification on a known operation skill
rejects. Optional expanded specialties inherit classification from their parent
and reject conflicting overrides. Remaining authored skills still require an
explicit classification when the susceptibility restriction applies.

`expanded-motion-catalogue.t` / `test_motion_catalogue` specify the five operation
identities, navigation exclusion, optional specialty inheritance and conflicting
overrides. Fixtures remain unrun. Expanded crew, command and custom operation
skills still need their source-specific catalogue definitions.


## Exceptional breath reserve

`RpgExpandedBreathReserveTrait` uses neutral ID `breath-reserve` and costs two
points per level (full-2008 B41). Set `approved`, `eligibility` (`nonhuman` or
`super`) and evidence for that eligibility. Ordinary humans reject. The current
integer implementation supports levels 1–10 and explicitly rejects higher
levels; this is an implementation bound, not a source maximum.

`profile.purchasedBreathReserveLevels()` validates the purchase and returns its
active, unmitigated levels. Duplicate purchases reject. Template copying makes a
fresh trait and preserves eligibility and evidence; these are purchase options
for composition comparisons. Existing character accounting uses `creationCost()`.

Set a `RpgExpandedBreathReserve`'s `usePurchasedReserve = true` to derive and
snapshot its levels from the profile. Each level doubles duration, including a
successful breathing-skill bonus. Later mitigation affects future reserves;
changing physiology during an existing reserve requires a separate transition.
The `test_breath_reserve_trait` fixture covers cost, combined duration, mitigation,
eligibility, duplication and independent template copies. Fixtures remain unrun.

### Sympathy

`RpgExpandedSympathy` implements the ordinary five-point trait from full-2008
B22. Set `approved = true` and install it in the profile's `traits`. The fixed
identity, price and single level are validated; percentage variants are rejected.
`profile.sympathyActive()` honors activation and mitigation and rejects duplicate
instances. Character accounting uses its normal `creationCost()`.

The begging skill context adds the purchased trait's +3 automatically. Existing
`RpgExpandedSocialInhibition` applies its −1/−2/−4 tiers because begging is marked
as requiring social interaction; the strongest tier also prohibits learning it.
Do not repeat those purchased effects through the context's authored `pitiable`
or `shynessPenalty` fields: simultaneous active sources are rejected.

`RpgExpandedSympathyReactionContext` in the social library requires the actual
`subject`, `observer`, approval and evidence for `perceivedNeed`. It grants +3
only when the subject's trait is active and the observer perceives that need.
Callous observers receive no bonus. The context verifies the reaction's observer
identity. `test_begging_traits` specifies costs, tiers, learning restrictions,
mitigation, observer exclusions and duplicate modifier rejection. Fixtures remain
unrun; modified trait variants and appearance interpretation remain unsupported.

### Expanded appearance

`RpgExpandedAppearance` implements the fixed tiers from full-2008 B21. Install
one approved trait with `tier` from −5 through 4. In ascending order the point
costs are −24, −20, −16, −8, −4, 0, 4, 12, 16 and 20. Tier zero is ordinary
appearance. Duplicate expanded appearances and simultaneous legacy appearance
traits are rejected, including when temporarily mitigated.

The corresponding reaction modifiers through tier 1 are −6, −5, −4, −2, −1, 0
and +1. Tiers 2–4 give +4/+6/+8 to attracted observers and +2 otherwise.
For ordinary presentation at tiers 3–4, a same-sex observer with other reaction
penalties totaling below −4 instead gives −2. Supply the negative penalties
before offsetting bonuses; −4 exactly does not trigger resentment.

`presentation = 'androgynous'` is available at tiers 2–4; `'impressive'` is
available from tier 1. At tiers 2–4 these use flat +3/+4/+5 modifiers. Visibility,
compatibility, activation and mitigation still apply. The named universal and standardized options below are supported; arbitrary
percentage lists remain rejected.

Use `RpgExpandedAppearanceReactionContext` with subject, observer, approval and
evidence. Its `compatibleAppearance`, inherited `sees` and `attracted`, `sameSex`
and `otherReactionPenalties` fields describe the specific observer. It validates
the observer identity and contributes the appearance modifier to the ordinary
reaction calculation. This does not automatically simulate social exclusion or
attention from strangers associated with extreme tiers; those incidents remain
an author integration gap. `test_expanded_appearance` specifies the fixed table,
flat options, visibility, compatibility, mitigation and resentment threshold.
Fixtures remain unrun.


Set `universal = true` to apply the appearance modifier to every observer who can
see the subject, regardless of compatibility. Tiers 2–4 use the flat +3/+4/+5
bonuses. Universal applicability adds 25% to the trait price, including negative
appearance prices as specified by the signed rounding rule.

Set `standardized = true` only above tier 1. This reduces cost by 50% and halves
positive appearance bonuses for same-culture observers. Fractions round down
under the ordinary result rounding convention (full-2008 B9); flat +3 becomes +1
and flat +5 becomes +2. Other cultures receive the usual modifier. Resentment is
a penalty, so this limitation does not halve it. Combine the two price modifiers
before rounding the point cost upward (B9/B101): tier 2 with both costs 9 points.

The appearance reaction context uses its inherited `sameCulture` fact. Begging
inverts the resulting appearance modifier and binds that audience fact in its
hourly record. `test_appearance_modifiers` covers signed prices, combined pricing,
visibility, compatibility, culture, odd bonuses, resentment and ineligible tiers.
Fixtures remain unrun. Narrative consequences of extreme appearance still need
explicit authored incident integration.

### Styling expertise

`RpgExpandedStyling` is an approved, fixed five-point trait (full-2008 B21).
Activation and mitigation determine whether the designer can prepare an outfit.
Templates support `['styling', 1, nil]` and preserve typed copies. Duplicate owned
instances and unsupported price modifiers are rejected.

The social library's `RpgExpandedStylingPreparation` records concrete advance
preparation: give it an ID, designer, wearer, occasion, outfit identity, outfit
description, approval and evidence, with `plannedInAdvance = true`. Designer and
wearer may be the same person. `prepare()` records the authored preparation once;
it does not invent a duration or consume materials. The wearer owns the receipt.
Later loss of the designer's trait does not undo the already prepared outfit.

### Distinctive features

`RpgExpandedDistinctiveFeatures` implements full-2008 B22's unusual cosmetic
features at −1 point per level, with levels 1–5. Supply a species identity, concrete
`description`, `origin`, and approval that these features are unnatural for that
species. This is independent of attractiveness and may coexist with appearance.
Activation and mitigation control the effect; duplicate instances are rejected.

Use `RpgExpandedDistinctiveContext` for the affected task. Set `subject` to the
person with the features and give approved evidence describing the task and crowd.
For `purpose = 'disguise'` or `'shadowing'`, the acting profile must be that subject
and the context's skill must match the purpose; each level subtracts one. For
`'identify'` or `'follow'`, the acting profile must be someone else, and each level
adds one to that attempt. This permits observation or other authored appropriate
checks rather than imposing a new universal identification skill.

Set `sharedByCrowd = true` only when almost everyone in the crowd shares those
features; both modifiers then become zero. Author evidence determines whether
the features are usable in the task. The context does not reveal an identity,
create a pursuit or resolve detection automatically; it modifies the actual check.

A configured template row is
`['distinctive-features', levels, nil, nil, [species, description, origin]]`.
Copies preserve those facts and the executable trait class. The plain row is
rejected because it lacks the required origin and description.
`test_distinctive_features` specifies price, both modifier directions, the crowd
exception, mitigation, typed copying and missing-origin rejection. Fixtures remain
unrun; concrete pursuit and disguise scenario integration remains pending.

## Broad cultural adaptation

`RpgExpandedCulturalAdaptation` implements the two full-2008 B46 coverage prices:
`coverage = 'own-species'` costs ten points; `coverage = 'world'` costs twenty.
Supply `approved` and concrete `evidence`. The campaign must explicitly enable
`rules.cinematicCulturalAdaptation`; it defaults off. Duplicate purchases are
rejected, including inactive duplicates. Percentage modifications are unsupported.

For own-species coverage, set `profile.culturalSpecies` to an authored species
identity and populate each relevant `RpgExpandedCulture.species` list. For world
coverage, set the purchase's `world` and each culture's `world` identity. Missing
scope facts reject assessment rather than assuming broad coverage. Cultural
membership is authored independently of appearance, nationality and language.
An active, unmitigated purchase removes the unfamiliarity penalty only within
its scope; native and separately purchased familiarity continue to work normally.
No language, reaction bonus, status or permission is granted.

Templates accept a configured row:
`['cultural-adaptation',1,nil,nil,[coverage,world,evidence]]`.
Set the template's `culturalSpecies` for own-species coverage; use nil for that
purchase's world option. Ordinary and selected creation preserve the species
identity, and occupational composition rejects conflicting species identities.
Trait copies remain independent. `test_cultural_adaptation` specifies costs,
scope, campaign rejection, suppression, template isolation, undo and save replay.
Fixtures remain unrun. Ancestry transformations and automatic cultural-context
selection across all skills remain pending.


## Fine sensory purchases and detection bonuses

`RpgExpandedSensoryRecognition` represents the unmodified purchases in
full-2008 B49. Set `approved = true`, level one, and matching `id`/`sense`:
`fine-hearing`/`hearing` costs 15, `fine-smell`/`smell` costs 15, and
`fine-taste`/`taste` costs 10. Each sense may be purchased once. Inactive or
mitigated purchases give no bonus. Unsupported percentages, scopes and levels
are rejected. Plain template rows use those IDs; copying creates an independent
purchase in the existing character cost ledger.

The shared scoring hook adds four once to hearing contexts and to the matching
mode of `RpgExpandedChemicalContext`, in addition to its acute-sense bonus.
It does not bypass missing capacity or stimulus. The default hook returns zero
when the expansion is absent. Other authored skill contexts can override
`sensoryRecognitionMode()` to name a justified sensory channel, but this does
not supply missing prerequisites or special task procedures.

Purchase accounting and scoring are implemented here. Sound and scent
memorization is documented in the traits guide. Individual recognition, taste
sampling/analysis, tracking and noisy-target following integration, and special
modifiers remain pending. Purchasing the trait alone must not be presented as
implementing those procedures. `test_sensory_recognition` specifies prices,
stacking, suppression, invalid modifiers, duplicate rejection, template copying,
undo and saved continuation. Fixtures remain unrun.


## Sound and scent memory

`RpgExpandedSensoryMemoryAttempt` implements the B49 memorization procedure for
`hearing` or `smell`. Supply `id`, `profile`, an authoritative `signature` object,
`sourceAvailable`, `approved` and concrete `evidence` that exposure lasts for the
whole interval. `seconds` defaults to 60 and cannot be less. Use the same
signature object for later attempts at the same sound or odor; a display name
or a newly allocated request must not bypass the retry restriction.

An active matching fine-sense purchase is required. `assess()` previews the
shared health permission, schedule, clock capacity and Intelligence score.
`resolve()` spends the exposure interval once, then makes the Intelligence
check. The learning check is distinct from detecting the stimulus and does not
add the detection bonus. Invalid requests spend nothing. Health denial records
an outcome with no exposure time or memory roll and imposes no retry delay.

Success retains the signature. Failure sets `retryAt` to completion plus 86,400
seconds; another attempt is blocked until that exact boundary, including after
save continuation. Repeating the same request returns its original result.
`profile.knowsSensorySignature(sense, signature)` queries the retained knowledge
without performing a detection or recognition check. Bound request and outcome
fields prevent rewriting a completed attempt or its deadline.

Author evidence is required for uninterrupted exposure; automated moving-source
availability and interruption events remain pending. Taste sampling remains unfinished. Matching successful observations against
known signatures is documented in the exploration guide. The shared player action interface is described below. `test_sensory_memory` specifies both senses,
minimum duration, trait suppression, health denial, replay, rollback, undo,
failed-attempt tampering and saved retry-boundary continuation. Fixtures are
unrun while checks are paused.


## Shared sensory memory actions

Bind `RpgExpandedSensoryMemoryAction.attempt` to a
`RpgExpandedSensoryMemoryAttempt`, and set `operation` to `preview` or `resolve`.
Parser and structured commands call `exec(context)`; dialogue choices call
`perform(context.asker)`. The actor must own the attempt's profile. Ownership is
checked before assessment, preventing another character from probing remembered
signatures or retry deadlines through this action.

The action delegates to the same attempt for time, health permission, learning
and replay. Its `rpg.expanded.sensory-memory` event contains operation, status
and reason only; signature identity, die rolls and retry timestamps are not
broadcast. Authors may use the returned outcome for recipient-specific feedback.
Switching to another request for the same signature still respects the owned
history and retry deadline.

`test_sensory_memory_actions` specifies parser, structured and dialogue routes
for hearing and smell, ownership denial, preview purity, rollback, undo, repeated
execution and saved continuation of a failed-attempt retry barrier. These
fixtures are unrun while validation remains paused.


### Full fear and phantom-voice follow-ups

`RpgExpandedFearEvent` preflights an owned voice occurrence before rolling when
this trait is active (full-2008 B148). On failure, it first retains the separate
consequence-table roll, then resolves one voice check. An exact success also
resolves one voice check; success by a positive margin and immunity do not.
The occurrence is stored in `result.stressFollowup`, with the fear event as its
stressor and `fear:` plus the event ID as its ID. Reserve this prefix.

Both the selected fear consequence and any voice episode persist. Replaying the
event validates the linked receipt without another check. The original event,
its table selection and the voice receipt share the engine transaction for
rollback, undo and saved continuation. `test_fear_stress` specifies these cases;
assertions remain unrun while build checks are paused.

## Fear auras

`RpgExpandedFearAura` supplies the B93 purchase and source-specific fear effect.
Choose `sense = 'sight'` or `'hearing'`, `penalty` (additional negative points on
the fear check), `alwaysOn`, `touchOnly`, and `approved = true`. Base cost is 30
plus 10 per penalty point. Always-on applies -20%; close-contact-only applies
B112's -30% reach-C limitation. The shared positive-cost rounding and limitation
floor apply. Custom extra modifiers and alternative melee reaches are not part
of this interface. Template copying preserves these choices in a fresh purchase.

Install the trait on the source profile. For each affected perceiver, author a
`RpgExpandedFearAuraContext` with `auraOwner`, `aura`, `perceived`, `activated`,
and the ordinary approved scene evidence. `perceived` means the chosen sense
actually received the stimulus; it does not grant sight or hearing. Voluntary
activation requires an available conscious source; always-on ignores the
activation choice. Contact-only requires `contactEstablished` and the ordinary
`touching` modifier, preventing omission of the contact fear penalty.

Resolve that context through an owned fear event. History belongs to each
victim/source/purchase combination. Every earlier actual check within the last
86,400 seconds grants +1; immune observations do not count as checks. Success
protects that victim from the same source for 3,600 seconds. Both boundaries are
exclusive at expiry. History is derived from retained events, so authored
`priorExposures24h` must remain zero. Existing ordinary scene modifiers still
apply. Authors enumerate the affected observers and identify each activation;
this interface does not discover world visibility or broadcast hidden results.

`test_fear_aura` specifies costs, contact and activation eligibility, exact
one-hour immunity and 24-hour exposure boundaries, immune-event replay and saved
continuation. Fixtures are authored but unrun. Other aura modifier combinations,
automatic perception routing and the remaining full fear outcomes remain open.


## Postbattle stress

`RpgExpandedPostbattleStress` implements the B150 -5 base purchase with the
standard independent self-control rating. Template copying preserves the rating.
Use `RpgExpandedPostbattleFearContext` with the owning profile, purchase as
`trait`, approved ending evidence and a nonpositive authored `dangerPenalty`.
Use that context in `RpgExpandedPostbattleFearEvent`, with the same trait and
penalty, `battleEnded = true`, unique event ID and the battle as `occurrence`.

The initial check uses the purchased self-control number, sleep effects and
existing health self-control modifiers. It does not use Will or the initial fear
cap. Failure adds its margin to a separate three-die consequence roll and enters
the same owned consequence workflow. The specialized context retains the
original modifiers for those consequences that later use modified Will. Ending
the same battle again cannot produce another check. Author approval establishes
that the battle really ended and explains any danger/gruesomeness penalty.

A failed check also performs the existing mandatory phantom-voice stress
follow-up when applicable. Exact self-control success does not trigger it.
`test_postbattle_fear` specifies independence from Will, exact success versus
failure, ending eligibility, replay, exception rollback, undo and consequence
commitment. Assertions remain unrun. Scores outside the supported range and
unsupported selected consequences remain explicit limitations of the shared flow.

## Phobia purchases and exposures

`RpgExpandedPhobia` prices the B149–B150 catalogue through a neutral `scope`:
`isolation`, `blood`, `cats`, `crowds`, `darkness`, `dead`, `dirt`, `canines`,
`enclosure`, `fire`, `heights`, `insects`, `loud-noise`, `machinery`, `magic`,
`monsters`, `number-thirteen`, `large-water`, `open-space`, `psi`, `reptiles`,
`sexual-contact`, `sharp`, `spiders`, `unfamiliar`, `sunlight` or `weapons`.
Set `points` to the matching base price, `approved = true`, and the independent
`selfControlRating`. Machinery/sharp-object prices use the authored `technology`;
magic/psionic prices use `prevalence` (`common`, `uncommon`, `unknown`).
`rpgExpandedPhobiaBase` supplies those prices before self-control adjustment.
Template copying preserves the settings and rating.

Start a `RpgExpandedPhobiaExposure` with a unique `id`, owning `profile`, purchased
`trait`, `cause` identity, approval and evidence explaining the perceived stimulus.
The initial check is due immediately. Create a `RpgExpandedPhobiaContext` with
that exposure, the same profile and approved stimulus evidence, then resolve a
`RpgExpandedPhobiaCheck` with its own unique ID and occurrence. Success applies
-4/-3/-2/-1 to DX, IQ and all skill checks at ratings 6/9/12/15 respectively,
while that cause persists. The initial roll uses self-control, not Will, and
is not capped at thirteen. Failure selects the full fear table and uses the
same committed consequence interfaces and failed-stress follow-ups.

With `threatOnly = true`, the check gets +4 and no actual-stimulus condition or
crowd count may be supplied. Otherwise `condition = 'ordinary'` selects no extra
modifier. Named conditions implement known/animated bodies, unfamiliar food,
fall risk, large/poisonous/numerous creatures, robots and hostile machines,
friendly/hostile magic targeting, Friday, weapon use/threat and unfamiliar
nonhuman company. Monster severity is selected explicitly from `severity-one`
through `severity-four`. Crowds require `crowdCount` and apply the printed
25/100/1,000-and-later boundaries. Approval establishes that the situation
actually triggers this character's purchased fear; imagined supernatural causes
are not treated as proof of real supernatural activity.

Every check schedules the next one 600 seconds later. The shared clock cannot
skip that boundary. Use a fresh context/check and occurrence at the boundary;
repeating an old check returns its old result. `exposure.end(true, evidence)`
records that the perceived cause has ceased, removes the ongoing penalty and
cancels future checks. It cannot skip the initial check or cancel an unresolved
fear consequence. Histories bind purchases, checks, start and ending records.
Use the engine transaction boundary for starting, checking and ending exposure.

`test_phobia` specifies initial and repeat timing, threat-only success above the
ordinary fear cap, DX penalties, failure-to-consequence execution, stress
follow-ups, replay, rollback, undo and saved continuation. Fixtures remain unrun.

The learning, voluntary activity, overlap and unconscious-perception adapters
below supply explicit interfaces for these interactions. They require authored
world facts; they do not infer every catalogue trigger from room descriptions.
Prohibited initial rolls below score 3 require the recorded author ruling
documented in the health guide. Unsupported consequence choices remain explicit.


### Fear-induced phobia acquisition

`RpgExpandedFearPhobiaAcquisition` implements a specific phobia choice for B361
rows 23 and 35. Supply a new unowned `RpgExpandedPhobia`, completed-creation
`profile`, unique `id`, source `eventId`, `tableTotal`, approval and evidence
connecting this new fear to that event. The fully adjusted purchase must cost
exactly -10 or -15 respectively. An already-owned phobia of the same scope is
rejected; worsening an existing purchase uses the separate owned procedure below.

`assess()` is pure; `apply()` installs the purchase once, records ownership and
increments the existing development revision. Earned and unspent points remain
unchanged. The purchase receives a post-creation disadvantage allowance, without
changing the ordinary creation limit. The owned fear event accepts the matching
acquisition for a direct result, or the health module can combine it with the
specified faint/coma and permanent IQ consequence. Non-phobia mental traits are
not accepted as substitutes by this specific interface.


## Worsening an existing phobia

`RpgExpandedFearPhobiaWorsening` implements the phobia branch of full-2008 B361
row 25. Author `id`, `eventId`, `profile`, the `previous` owned purchase,
`related`, approval and evidence connecting the incident to the existing fear.
When related and above self-control 6, supply a fresh `replacement` with the same
scope, base price, technology and prevalence, and a self-control rating exactly
one step lower. The replacement takes the old purchase's place; existing
exposures retain their original facts and follow the owned transition for future
checks and shaken penalties. Historical check results are never rewritten.

If no related purchase exists, or its rating is already 6, supply `fallback`
as a fresh `RpgExpandedFearPhobiaAcquisition` for row 23 and the same profile
and event ID. It must introduce a distinct phobia worth exactly ten points.
A transition or fallback increments development revision once and never grants
earned or unspent points. The additional disadvantage allowance follows owned
receipts, including later transitions from fear-acquired purchases.
The typed mental-purchase transition adapter below covers additional controlled
traits. Other catalogue entries still need specific transition adapters.
`test_fear_phobia_worsening` specifies current-exposure continuity, exact step
validation, fallback, rollback, undo and save continuation. It is unrun.

## Phobia perception during unconsciousness

`RpgExpandedPhobiaAwarenessPause` provides an explicit author contract for a
faint or coma that interrupts perception of a persistent stimulus. Set a unique
`id`, the `exposure`, approval and evidence, then call `begin()` while the
profile is actually unconscious. This suspends that exposure's ten-minute check
boundary and shaken penalty; it neither ends the stimulus nor skips health
recovery checks. A conscious profile cannot begin this pause.

After waking, call `resume(true,evidence)` when the stimulus is perceived again.
The next phobia check is due immediately; subsequent checks resume the ten-minute
schedule. Time cannot advance past waking until the author resumes perception or
ends the exposure with evidence that the stimulus is no longer perceived.
This is an explicit perception decision, not an automatic source rule for
unconsciousness. `test_phobia_awareness` specifies a twelve-minute faint,
recovery, resumption, replay, rollback, undo and saved continuation; it is unrun.


## Physical effects acquired from fear

`RpgExpandedFearPhysicalAcquisition` implements concrete choices for full-2008
B361 rows 24, 36 and 37. Supply `id`, `eventId`, `profile`, `tableTotal`, approval,
evidence describing the actual change, and fresh `purchases`. Supported purchase
types are `RpgExpandedPainSensitivity`, `RpgExpandedPersistentWound` and
`RpgExpandedSpeechLimitation`. Their combined cost must be exactly -15, -20 or
-30 respectively. Include the health library for their health effects.

The acquisition adds the actual traits, preserving their existing speech, pain
and wound effects. A persistent wound purchase does not subtract HP at acquisition.
Duplicate effects, already-owned purchases, unsupported types and speech
conflicts are rejected before committing. Development revision increments once;
there is no earned-point or spendable-point reward. Forced aging is available
through the hazards adapter below. Appearance changes and other physical
transformations still need specific adapters. Approval of a price
alone cannot satisfy this interface. `test_fear_physical` specifies all three
required totals, speech blocking, accounting, rollback, undo and saved replay;
fixtures are unrun.

`RpgExpandedFixedBeliefAcquisition` also accepts rows 23 and 35 as an authored
choice of another mental disadvantage. Those rows require the exact actual cost,
not a reduced credit allocation. They compose with faint row 27 and coma rows
39/40 through `RpgExpandedFearTraitCompound`, using acquisition rows 23/35.
The distinct mandated-belief rows 22/34 and compounds 26/38 retain their behavior.
The compound fixture includes both alternatives; it remains unrun.

## Phobia learning restrictions

Machinery and magic phobias participate in the skills library's shared
`skillLearningReason` gate (full-2008 B149), including study paths that use that
gate. While either phobia is active, skill definitions require an explicit
`phobiaLearningKinds` list and `phobiaLearningEvidence`. Supported classifications
are `machine-repair`, `complex-machine-use`, `simple-machine-use`, `magic` and
`other`; use multiple classifications when appropriate. No classification is
inferred from a skill's name.

Machinery phobia blocks repair learning and complex-machine operation learning,
while permitting explicitly classified simple-machine use. Magic phobia blocks
learning magic. Missing classification blocks learning before time, points or
dice are spent. These gates do not erase previously acquired training.
`test_phobia_learning` specifies the shared gate and no-randomness behavior; it
is unrun. Broader voluntary-activity permissions remain pending.

Direct low-level self-control and generic self-control triggers reject typed
phobias and postbattle stress before spending resources. Their owned exposure or
battle event is required so table consequences and stress follow-ups cannot be
bypassed. `RpgLiteTrait.validateDirectControl()` is a no-op for existing traits;
its expanded overrides supply these guards without changing ordinary Lite dice
consumption. The phobia fixture includes a direct-call rejection assertion,
unrun with the rest of the paused suite.


## Concurrent phobia exposures

Declare `phobiaOverlapPolicy` and `phobiaOverlapEvidence` on the profile before
starting its first exposure if concurrent phobias are possible. `sum` combines
shaken penalties; `worst` applies the greatest penalty. These are explicit
campaign rulings: the supplied B149 passage does not specify aggregation of
several simultaneous phobias. With no declared ruling, a second active exposure
is rejected. The policy is bound into each exposure's history.

Distinct purchases may respond to the same scene, but the same current purchase
and cause cannot create duplicate active exposure records. Each exposure retains
its own check schedule, outcomes and perception pauses. Resolve each due check
and its consequence before advancing time. Ending one exposure does not cancel
another. `test_phobia_overlap` specifies both rulings, missing-policy rejection,
independent penalties, rollback, undo and save continuation; fixtures are unrun.

## Voluntary activity permissions

Attach `RpgExpandedPhobiaActivity` to the `phobiaActivity` property of an
`RpgExpandedEffort` or `RpgExpandedActionGate`. The activity must name the same
profile, approval and evidence describing the world facts. This supplements
ordinary health permission; it does not spend a second action or time cost.

For `kind = 'height'`, supply `heightFeet`, `insideBuilding` and
`awayFromWindows`. An active heights phobia blocks voluntary movement above
15 feet unless both building and window conditions hold (full-2008 B149).
For `kind = 'power-consent'`, an active psi phobia blocks voluntary consent to
receiving that power (B150). Forced exposure uses the exposure/check interface
instead; passing an action permission cannot replace that check.

The gate binds the actual activity facts into its receipt. Replaying a granted
permission does not spend again or reassess it against a different place.
Actions involving these situations must attach this contract; geometry and
consent are authored facts. `test_phobia_activity` specifies the height boundary,
exception, consent restriction, rollback, undo and saved replay; it is unrun.


## Frightening cues from disturbing voices

`RpgExpandedVoiceFearContext` connects an active, owned severity-two
`RpgExpandedPhantomVoiceOccurrence` to a specific authored frightening cue.
Supply `profile`, `voiceOccurrence`, a stable `cue` identity, approval and
evidence. Create an ordinary owned fear event using that context. An ended,
non-occurring or differently severe voice episode cannot start this cue.
Once recorded, the fear event remains replayable after the voices end.

The context supplies evidence for ordinary fear selection; it does not make
every voice episode frightening. A failed or exactly successful resulting fear
check still creates the separate mandatory voice follow-up. No new fear event
is recursively invented from that follow-up: another frightening cue requires
another explicit author decision. The `expanded-voice-fear.t` fixture and
`test_voice_fear` cover the retained link, expiry, follow-up, rollback, undo and
cross-process continuation; assertions remain unrun.

## Other lasting mental outcomes and worsening

`RpgExpandedFearMentalAcquisition` uses the same retained acquisition and
character-accounting path as phobias for B361 rows 23 and 35. It accepts concrete
purchases whose existing effects and author interfaces are implemented:
truthfulness, curiosity, danger avoidance, compelled aid, low motivation,
postbattle stress, pleasure loss and phantom voices. Select an actual typed
purchase with exact adjusted cost -10 or -15, respectively. Generic price-only
traits are rejected, as are inactive, mitigated, already-owned or duplicate
purchases. No spendable points are awarded.

The same acquisition fits `RpgExpandedFearTraitCompound` for rows 27, 39 and 40.
It supplies the lasting trait while the existing faint/coma episode supplies
unconsciousness, and row 40 owns the permanent IQ reduction. Acquiring phantom
voices does not retroactively add a stress check to the already-resolved initial
fear event; subsequent qualifying occurrences use the new trait normally.

`RpgExpandedFearMentalWorsening` supports row 25 for the controlled purchases in
that list and for phobias. Supply logically related `previous` and fresh
`replacement` purchases of the same kind with self-control exactly one step
worse. Historical receipts keep the old purchase; subsequent new triggers use
the replacement. Continuous phobia exposures follow the existing successor
lookup. Uncontrolled purchases cannot be worsened through a self-control
interface. At the minimum rating, or without a related purchase, select a fresh
ten-point phobia, supported mental purchase or fixed belief through `fallback`.

The existing `RpgExpandedFearPhobiaAcquisition` and
`RpgExpandedFearPhobiaWorsening` interfaces remain available. All these paths
share their existing receipt lists, point allowance and development revision.
Fixtures `expanded-fear-mental.t` and `expanded-fear-mental-compound.t` cover
prices, actual trait effects, worsening, compound outcomes, preview, duplicate
prevention, rollback, undo and saved continuation. Assertions are unrun. Other
catalogue traits still require concrete acquisition adapters; this is not a
claim that every mental trait or treatment procedure is complete.


## Forced aging selected by fear

An optional `aging` on `RpgExpandedFearPhysicalAcquisition` accepts
`RpgExpandedFearAging` from hazards. Set its matching `profile`, `years` (1–10),
`calendarId`, `oldAgeMonths`, `medicalTL`, approval and age evidence. The selection
budget counts each added year as -3; this is only a selection value. It does not
award character points or add a trait priced at that amount. Combine it with
actual purchases to meet the selected row's exact total, or use five years alone
for row 24. Attribute losses retain ordinary aging accounting.

The advance evaluates every crossed aging boundary through the existing loss
ledger, including lifespan bands, fitness, longevity and natural death. Unaging
rejects this outcome. No elapsed gameplay time is charged. The last age reached
constrains later ordinary and deprivation-related aging, and rejuvenation restores
the existing recorded losses. Use `RpgExpandedFearAgingCalendar` where an exact
campaign day map is required; its span must match the selected years.

When a crossed boundary can have an effective score below 3, provide a contingent
`RpgExpandedFearAgingRuling` as `lowScoreRuling`: matching `owner`, four `losses`
in ST/DX/IQ/HT order (each 0–2), approval and evidence. It is used only at an
unrollable boundary. That boundary retains `author-selected-aging-losses` with an
empty rolls list. No failure margin is invented. The ruling is bound before the
advance begins so a later random loss cannot leave a partly paid advance awaiting
an undefined decision. Ordinary rollable boundaries keep their four existing rolls.

`expanded-fear-aging.t` / `test_fear_aging` specify selection accounting, crossed
boundaries, ordinary losses, no-dice author losses, rejuvenation, receipt mutation,
rollback, undo and saved continuation. These assertions are authored and unrun.
