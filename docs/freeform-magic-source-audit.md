# Freeform magic: direct source audit

Status: researched specification input, 26 October 2026. Required companion to
the [extension plan](freeform-magic-plan.md) and
[permission matrix](freeform-magic-permissions.md). This document adds mechanics
located in the owned PDF; it does not implement them. The private reference
library was separately expanded from this audit. Public terminology follows the
plan.

The targeted M20 resource/casting comparison is settled through M20-32 and its
subdecisions. This document preserves dated research stages. Current executable
coverage and conversion decisions are recorded in the [implementation guide](magic.md)
and [coverage ledger](magic/coverage.json), which supersede earlier implementation
gap inventories below. Spirit-vessel construction remains deferred. This audit
does not claim that every published example has been converted into game content.

Source `freeform-1994` is the 1994 third-generation adaptation, printing
unverified. All locators below are printed pages; PDF viewer pages are one higher.
The PDF matches SHA-256
`9052542535e6ee826fa7f12abf1b46ab13a332b3d38788524ba8347c0863b6d0`.
The separate correction layer is `freeform-errata-1999`, revised 2 September 1999.
Source prose, illustrations, named examples and private service links are not
included. Numeric rules are summarized in original language.

The reference service searches curated records, not the book's text. Comparison
with its full records confirms that several records summarize tables without
including their values. Its processing notes explicitly leave detailed domain
levels and optional rules in the linked book. An omission from a record is not
evidence that the book lacks a rule.

This pass read pp. 44, 46-50, 78-95, 131-137 and 144-151 using local OCR, with
key numeric tables and ambiguous passages checked in page images. It also
revisited relevant domain examples on pp. 97-128. This is a targeted audit of
the plan's gaps, not a claim that every example or paragraph has been converted.

## Casting procedure recovered

Pages 83-89 establish the following sequence:

1. Declare a specific effect, its domains, appearance, targets, delivery type
   and instantaneous or sustained result. The caster must sense the target.
2. Check domain ranks and the plausibility of any subtle explanation.
3. Compute the lowest relevant trained domain skill, subtract one per additional
   domain, and apply permitted modifiers. Spending reserve is optional for an
   ordinary cast; there is no universal fatigue cost (p. 80).
4. Roll, then check whether its margin meets the declared effect's requirements.
   An insufficient result produces no effect and loses spent reserve. Surplus
   success does not automatically enlarge the declared effect.
5. Assess strain from the casting roll and appearance/witness state. An overt
   critical failure triggers backlash with the newly gained strain included.
6. For a successfully created effect, resolve countering and then applicable
   resistance/delivery defenses before applying or reporting the result.

The exact host transaction timing for interrupted casts, multiple defenders and
automatic failures remains an adaptation. It must preserve this source ordering
and distinguish casting success from delivery success.

### Timing, distraction and repeat attempts

| Rule | Recovered mechanics | Pages |
| --- | --- | --- |
| Normal casting | One second; a required practice may lengthen it. | 84 |
| Extra time | Doubling normal time gives +1, with no larger extra-time bonus. | 84 |
| Haste | Shortening a lengthy practice gives -1 or worse; instantaneous casting gives -3 or worse. The referee sets the additional penalty. | 84 |
| Distraction | Roll Will minus the number of distractions. On failure, casting takes that number as a penalty, capped at -5. This is not the Will failure margin. Enhanced mental processing or a successful mind-1 multitasking effect exempts ordinary distractions, not overwhelming input. | 84-85 |
| Formula time | Fixed per formula, normally one second. Neither haste/extra-time modifiers nor high skill change it. Other casting modifiers still apply. | 89 |
| Failed effect | The same effect cannot simply be retried. Attempt a different effect next turn or wait for a significant change of circumstances. | 88 |
| Repeated coincidence | A cumulative penalty is optional referee policy; neither its increment nor a reset interval is specified. A materially better explanation may justify relaxing it. | 87 |

Practices are not all held objects: preparations, movement, speech and equipment
can impose distinct timing and availability checks (pp. 92-95). Examples include
two-to-three-second procedures, preparations lasting minutes, and a prepared
boundary requiring at least two hours. Define original practices with explicit
timing rather than importing the faction-specific catalogue.

A personally bound implement has an additional rule (p. 93): losing it prevents
use of the associated domains until recovered, replaced through relearning, or
made unnecessary by mastery. Relearning to the old rank costs half the usual
character points, then normal costs resume. Whether previously purchased skill
investment is retained, frozen or repurchased is unspecified in the source.
M20-27a below adopts retention as a host ruling. Make this an explicit optional
practice type with an audited cost policy, not a property of all equipment.

## Scaling tables and exceptions

### Reach and area

The two columns on p. 85 have different jobs. Space determines remote reach;
the general column still determines area (p. 86).

| Casting margin | General reach/selection | Space reach |
| --- | --- | --- |
| 0-1 | Touch | Visible destination |
| 2 | One nearby target | Very familiar destination |
| 3 | Entire immediate vicinity | Familiar destination |
| 4 | Selected targets in the vicinity, or one visible target | Destination known through description or an image |
| 5+ or critical | Any selection within sensory reach | Anywhere on the source world's planet |

Immediate vicinity is limited to 15 hexes or line of sight, whichever is less.
The source does not give a numerical distance for "nearby" in this table.
Mapping hexes to host distance, selecting that nearby distance, and replacing the
source planet with an authored world boundary are conversion decisions.

Combined effects use the best applicable chart results among their participating
domains, including reach and damage (p. 85). Permission and a domain's actual
participation still matter; this is not permission to attach an irrelevant domain
just to borrow its numbers.

Duration uses the corrected bands already in the plan: 0-1 = 30 seconds,
2-3 = 30 minutes, 4-5 = one day, 6-7 = one week, 8+ or critical = permanent.
The last two bands come from the official correction, not the uncorrected scan.

### Damage

Page 86 gives these multipliers. Multiply the successful casting margin by the
applicable multiplier to get damage dice; treat zero margin as one for this
calculation. The rank is the caster's rank in the domain causing harm.

| Rank | Chance and decay | Energy | Life | Other domains |
| --- | --- | --- | --- | --- |
| 1 | 0 | 0 | 0 | 0 |
| 2 | 0 | 1 | 3 | 0 |
| 3 | 0 | 2 | 3 | 1 |
| 4 | 4 | 3 | 3 | 2 |
| 5 | 5 | 4 | 3 | 3 |

These numbers do not grant a damaging operation at that rank. The permission
matrix must independently allow the effect. Default damage behaves as crushing;
the effect can justify a different type. Page 89 generally reduces burning,
cutting or impaling damage by one or two per die, with the choice left to the
referee. Critical success does not have a universal damage multiplier in these
charts, even though range and duration have explicit critical rows.

**Specific exceptions must survive conversion.** The life-2 direct injury example
on p. 110 specifies `1d-2` per success and bypasses all protection, including the
source's innate toughness, while allowing Will resistance. The life-4 example
refers back to it. This differs from the generic life multiplier. Record an
effect-specific override and its provenance; do not silently multiply it by
three or treat the differing specific formula as an absent rule. The energy-2 electrical example (p. 106) adds
a health check against stunning and distinguishes nonmetallic armor.

### Other quantities

Page 89 supplies guidelines rather than a complete physics model:

| Quantity | Recovered guideline |
| --- | --- |
| Traits | One success per ten character points of benefit or disadvantage; round absolute cost upward to the next ten. |
| Attributes | Self: one attribute point per success. Another creature: one per two successes. Creating living attributes: one per success. |
| Protection | One success buys five damage resistance or one legacy passive defense, not both. Passive defense caps at six; neither value becomes negative. |
| Existing mass | Raw margin 0 affects 1 pound, 1 affects 10 pounds, 2 affects 100 pounds, continuing by factors of ten. Normally the whole target must fit. |
| Created matter | One tenth of the general mass allowance, unless an effect specifies otherwise. |
| Temperature change | Raw margin 0 allows five Fahrenheit degrees of change; each additional success doubles the change. |

Changes can increase or decrease quantities. The page also says to count an
exact success as one, but its mass and temperature entries explicitly distinguish
raw margin zero. Preserve raw margin and quantity-specific interpretation; do
not globally replace all zero margins with one. A proposed implementation should
give the explicit quantity rules precedence and label that reconciliation.

Legacy passive defense has no direct host equivalent. Translate or omit that
option explicitly; do not quietly turn it into extra armor or an active-defense
bonus. Trait costs and damage/health units also require host conversion.

Selected domain exceptions reinforce the need for separate evaluators:

- Healing restores two legacy health points per success (p. 110), with shared
  treatment restrictions across healers. Regrowing parts and other qualitative
  repairs have referee-set requirements.
- The matter-2 plus power-2 creation formula uses 2 successes for 2 pounds,
  3 for 10, 4 for 20, and 5 for 100 (p. 114). It differs from generic creation
  mass, which p. 89 explicitly makes subordinate to specific mass guidelines.
  Matter 4 later permits mixed materials in this formula; this is not a universal
  composite-creation table. Do not infer all later thresholds from its open-ended
  continuation. The earlier audit misidentified the base rank and scope.
- Mind-1 enhancement divides success between benefit and duration and requires
  at least one for duration (pp. 115-116). The life-3 bodily enhancement is
  nonpermanent and can cause continuing injury (p. 110).
- Time-3 acceleration/slowing has a -2 casting penalty; each full pair of
  successes adds one to the speed/divisor factor, within at most a small room
  (p. 126). Thus 2 successes gives double/half speed, 4 gives triple/one-third.
  A speed factor must be distinguished from extra actions when adapting the
  source's turn wording to the host scheduler.
- Time-4 suspension uses the normal duration chart, also with a small-room
  limit; interference can end it, and very long suspension may fail early by
  referee decision (p. 126). Future travel gives illustrative endpoints rather
  than an exhaustive seconds-to-margin table (p. 127).

## Defenses, ordinary skills and combat

Countering requires at least rank 1 in every incoming domain, then rolls at
`10 + mastery` through mastery 9, or 20 at mastery 10 (p. 87). Successful
defensive margin subtracts from casting margin. More defensive success cancels
the effect; falling below any declared requirement also cancels it. A tie is
not stated to cancel automatically: a remaining zero must still be evaluated.
The worked example misstates mastery 7's ceiling as 16; the main character
table gives 17. Use the main rule and preserve an audit note about the example.

The ordinary resistance-to-magic advantage is explicitly ineffective against
this system (p. 41). Direct effects use Will resistance; indirect effects instead interact with
appropriate protection and may allow Dodge (pp. 86-87). The source refers to
its contemporary core book's p. 150 for the complete resistance procedure.
That procedure is not reproduced here. Critical precedence and the host's
opposed-roll semantics therefore remain explicit conversion decisions.

**Fourth-generation follow-up:** the owned `full-2008` core reference does cover
resistance, at B348-B349 and B241-B242 (combined PDF viewer pages 352-353 and
243-244). These complete pages were extracted and visually checked on 26 October
2026. The original third-generation p. 150 remains unverified, but resistance is
not missing from the available host-generation sources.

For a resistance contest, the attacker must succeed and win; failure ends the
attempt without a defender roll, and ties protect the defender. For supernatural
attacks against living or sapient subjects, the attack target is capped at the
higher of 16 and the defender's resistance, without raising a lower target.
The standard spell system separately says a critical casting success works
automatically. Ordinary successes oppose the effect's specified resistance trait,
usually health or willpower; unconsciousness does not eliminate resistance.
That system also supplies single-target and area resistance-trait adjustments,
full spell-energy costs when resisted, and resistance against existing spells.

These are verified alternative-system rules, not recovered earlier-edition text.
The remaining decision is which parts to adapt: especially critical bypass,
other explicitly mapped defensive traits, multi-target margins after the attack cap, costs,
and interaction with countering. The generic contest and standard spell rules
must not be treated as one universal procedure. Adapting their resistance model
does not require importing the standard spell system's fatigue costs or spell list.

Several casters can counter together. Cooperative casting requires sufficient
ranks for every participant, simultaneous work, communication, and mutual
normal or magical sight. Sum successful contributions; each participant gains
the total strain generated by the group, and any participant's critical failure
makes the group effect critically fail (pp. 87-88). Ordinary failures most directly contribute zero successes; individual strain
gains are summed from actual rolls. Aggregate critical-success scale, exact-zero
aggregation and backlash propagation still need explicit edge-case interpretation.

Pages 131-132 add procedures absent from the earlier plan:

| Use | Source procedure |
| --- | --- |
| Aid an ordinary skill/attribute/contest roll | Declare a valid subtle effect immediately before the named roll. Success grants `max(1, floor(margin / 2))` to that next roll only. No banking or moving the bonus to a different task. |
| Aid attack damage | Choose before the attack roll. Add casting margin to damage; if the attack misses, the aid is lost even on a magical critical success. Opposing attacks/damage can be hindered similarly. |
| Immediate magical defense | Roll the unmodified skill of a suitable domain instead of an ordinary defense, without prior concentration; describe a valid coincidence if successful. Repeated-coincidence penalties can still apply. This is separate from countering an incoming spell. |
| Overtly augment an attack | Make both the magic and attack rolls. A failed augmentation normally leaves the mundane attack possible; a remote melee attack requiring space fails if its enabling magic fails. Multiple blows have separate attack rolls; one critical failure makes all those blows miss. Add magical and mundane melee damage before protection. |

The source frames the last procedure as unwitnessed combat between casters.
Removing those setting restrictions, allowing immediate magical defense in the
host, and deciding its interaction with normal defense limits are adaptations.
These procedures require dedicated combat adapters; do not conflate them with
the ordinary casting action or a generic skill modifier.

General cancellation of every ongoing effect was not established by this pass.
There are specific reversals: memory changes can be undone by winning a contest
against the original roll (p. 118), and an item's enchantment can be destroyed
through power-4-level interference (p. 91). Do not extrapolate a universal dispel.

## Supply, transfer and recovery

| Procedure | Recovered mechanics | Pages |
| --- | --- | --- |
| Ordinary innate recovery | When reserve is below channel, meditate at an eligible source for at least an hour and succeed at the meditation skill. Recover one per two successes, minimum one; the recovery amount is limited by channel and source rating. | 44, 47-48 |
| Source ownership | Ten character points per unit of monthly output; contributions pool, with at most five units purchased by one character. Monthly physical output is separate from innate recovery. | 46 |
| Starting stored supply | Two character points per unit, requires power 1, consumable rather than regenerating advantage. | 46-47 |
| Consume stored supply | Power 1 permits use. The physical portion is entirely consumed in one turn; no partial reuse of the same portion. | 80 |
| Receive reserve | Power 1; one per success; one attempt per source. Receiving does not itself extract or channel supply. | 119 |
| Transfer reserve | Power 3; up to five per success, exact success counts as one; limited by available supply. Taking from another caster cannot reduce that caster below their channel rating. | 120 |
| Magical innate recovery | Power 5; one per success, replenishing up to channel. It is distinct from source meditation. | 121 |

| Monthly source output | Source rating | Associated barrier rating |
| --- | --- | --- |
| 1-5 | 1 | 8 |
| 6-10 | 2 | 7 |
| 11-20 | 3 | 6 |
| 21-40 | 4 | 5 |
| 41+ | 5 | 4 |

The source table also has environmental ratings for other magic systems, which
are outside this extension. Source rating supplies the casting bonus; monthly
output is not that rating. Calendar collection needs ownership and receipt rules.

The shared 20-space capacity and precedence of strain are confirmed on p. 50.
It does not order displacement between innate and transferable reserve. Nor do
the inspected passages fully reconcile consuming a large physical portion,
channel-limited roll bonuses, transfer throughput and receiving limits. Keep
these as separate operations and decisions. Do not infer an unlimited casting
bonus from the size of a consumable supply item.

## Backlash, complications and injury

The source does provide a numeric **damage branch** for backlash (pp. 134-135).
Roll three dice against current strain, including the triggering gain. Positive
success discharges that much strain. If the referee selects injury, inflict
one die per point discharged. It bypasses protection except the source's innate
toughness and cannot be healed magically. Translate the exception to an explicit
host protection category rather than importing the legacy trait unchanged.
Other branches involve authored confinement or hostile entities; damage is not
mandatory for every backlash.

Complication severity is not wholly unspecified (pp. 133-134):

| Strain spent | Source guidance |
| --- | --- |
| 1 | Usually a brief, local disturbance. |
| 2 | More marked interference, potentially lasting hours. |
| 3 | Significant impairment, potentially days or weeks; can instead make a minor disturbance permanent. Suggested permanent disadvantage value: -5 to -10. |
| 4 | Hazardous impairment lasting hours to weeks depending on severity. |
| 5 | Major temporary or lesser permanent impairment; can make a severity-2 complication permanent. Suggested permanent value: -10 to -30 or more. |

Exact penalties and durations are expressly assigned by the referee. Selection
must spend at least half current strain rounded up; above eight strain, only
severity-5 choices are offered. How multiple choices satisfy the half-spend rule
at higher totals needs a documented policy. Permanent penalties do not
automatically credit the advancement bank.

Not all unusually severe injury is unhealable. Page 137 allows overt healing
with one reserve per three legacy health points restored, rounding the required
reserve upward. Pages 110 and 135 separately prohibit magical healing of backlash
and unstable-transformation injury. Keep those narrower prohibitions. Bodily
self-enhancement normally causes one health point of leakage per day, potentially
much faster with exertion; it must end before that injury can heal naturally
(p. 110). Host injury records need source and healing eligibility, not just a
single aggregate pool.

## Enchanted items

Pages 48 and 90-93 recover substantially more than activation:

- Each programmed effect has its own rating and domain requirements. Activation
  uses that rating, not the user's personal domain skill. It requires physical
  contact, one concentration turn, and any configured command or gesture. The
  source restricts eligible users; a neutral eligibility trait is a conversion.
- Each activation uses one stored reserve, optionally supplied by the user.
  Strain goes to the user. The effect's subtle/overt mode is fixed during
  construction, but a subtle explanation is chosen when used.
- Capacity is twice the lowest effect rating. Power 3 recharges an empty item;
  depletion does not remove its enchantment. Destruction or interference
  equivalent to power 4 can remove it.
- Creation requires power 3, all ranks needed for the effect, and a very-hard
  crafting skill that defaults to power skill minus three and is not mastery
  capped. Collaborators all need the domains, but not all need the crafting skill.
- Roll crafting, the intended effect, and power. Ordinary failure destroys the
  prospective item; critical failure produces an authored flawed result. The
  effect rating is the lower of power and effect skill, excluding reserve-spend
  bonuses. How simultaneous mixed critical/ordinary results combine must be
  specified before automating the rolls.
- Enchanting time per rating point is half an hour for the first effect, one
  hour for the second, two for the third, three for the fourth, and so on. All
  collaborators remain throughout that effect's work. Interruption spoils it
  and advances the time tier for the retry as if it had succeeded. Rest between
  completed effects is unrestricted. A command/gesture adds one hour per ability.
- Final activation requires another power-3-or-higher roll and ten minutes per
  reserve transferred. Attempt a full initial charge without interruption;
  interruption or insufficient supply permanently reduces capacity to the
  amount transferred. Final charging seals the item against adding more effects.
- Starting purchase price is 1,000 currency units per effect-rating point, plus
  domain costs of 2,000/4,000/8,000/16,000/32,000 for ranks 1/2/3/4/5 in each
  effect. These are selected-rank prices, not cumulative steps, as confirmed by
  the worked example. Starting purchases are fully charged. These are source
  economy prices requiring conversion, not a host resale/crafting-profit rule.

Construction locations and exemptions are tied to the original setting. Replace
them with an authored workshop/environment eligibility policy and mark the
change as adapted. The ten-minute transfer rate is specifically the initial
charging procedure; do not silently impose it on every later recharge.

## Optional perception and world rules

Pages 136-137 provide both procedures and a severity progression. Increasing
strain moves from intermittent false objects (1), through environmental changes
(2), responsive elements (3-4), demands for attention (5), missing/changed real
elements (6), hazards (7-8), pervasive extraordinary events (9), to a wholly
altered experience (10+). Episode onset and end remain referee decisions.

Scrutinizing an element uses IQ-3, or IQ without that penalty for the source's
intuition trait; each element can be tested only once. Failure gives ambiguity,
critical failure gives a wrong conviction. A referee may make a failed illusion
physically real; a critical failure is the suggested narrower trigger. Once real,
it cannot be removed merely by disbelief or internal mental confrontation.

Entering an internal confrontation is automatic; a Will roll selects its time
unit: margin 0 years, 1 months, 2 weeks, 3-5 days, 6 hours, 7 minutes, 8+ seconds.
The text does not supply exact counts or a failed-roll row. For durations over
one day, communication may be attempted once per selected time unit: a Will
success permits communication, margin 3+ makes it clear, and its maximum length
is `floor(IQ / 4)` minutes. Internal magical confrontations do not affect the
ordinary world or add strain. This remains an optional authored subsystem.

The relevant local-magic rules are on **pp. 90-92**, not just the travel chapter:

- A parallel spirit environment uses overt casting but subtle strain gains,
  including when the caster affects it from outside.
- An unconstrained outer environment permits known effects without casting
  rolls or strain. It does not grant unknown domain ranks.
- Other worlds have per-domain ratings. Effects within local laws can succeed
  without casting rolls; an appropriate attribute roll may supply magnitude.
  The prose says "lower" than local rank, while examples include equality.
  A `required rank <= local rank` policy is a documented reconciliation, not an
  unnoticed wording change. Above local ratings, ordinary casting rules apply.
- Negative world ratings can make ordinary actions require magic. Authored
  dream environments may change their ratings dynamically.

Page 146 supplies a typical crossing barrier range of 4-18, used in a quick
contest against the effect roll. Source-associated values appear above. Detailed
crossing permissions and hazards remain in the spirits matrix. The travel
chapter's named worlds and creature hierarchies are setting content, not required
mechanics. A general numerical recipe for constructing an entire world was not
established by this audit.

## Specification gaps identified before follow-up decisions

The generic scaling tables, default timing, distraction procedure, failed-effect
retry restriction, ordinary assistance, source output, transfer throughput,
backlash injury and item construction are now located. Do not list them as
missing source data again.

The following was the pre-decision inventory. Later entries and the current
plan resolve group results, reserve displacement/overflow, complication batching,
construction failure, relearning investment and casting action limits:

1. **Source dependencies:** the original legacy core resistance and spirit
   direction-finding references are from an uncatalogued edition. Spirit-vessel
   construction explicitly refers to an uncatalogued supplement (p. 123).
   Available host analogues do not verify those original procedures.
   Host-generation resistance is now verified in `full-2008`; choosing and
   integrating it is conversion work, not an absent-rule blocker.
2. **Source interpretation:** raw-zero precedence; critical group outcomes;
   reserve-origin displacement and strain above twenty; transfer/receipt
   composition; high-strain
   complication batches; mixed item failure precedence; skill treatment during
   rank relearning; local-rating equality; and
   missing failed-roll/time-count rules in optional internal confrontations.
3. **Authored choices:** novel effects, qualitative difficulty, coincidence,
   exact complications, confined-world escape, special practices and local laws.
   The source deliberately delegates these; further OCR cannot turn them into
   fixed published formulas.
4. **Conversion:** host costs, damage/health/protection, units, default reach,
   critical outcomes, action limits, interrupted-cast charges and persistence.
5. **Coverage:** every implemented operation needs its own prerequisites, scale,
   delivery, exceptions and tests. Rank summaries and these general rules do not
   replace an audit of the particular domain examples used by implementation.

The initial reference library update expanded ten records and added four, including its
own editorial permission matrix and separate combat, exception and construction
records. It retains the source's terminology and edition; the neutral extension
vocabulary and host conversion choices stay here. The API remains read-only;
updates are made to source records and deployed as a new service release.

## Parallel source audit, 26 October 2026

Three independent audits revisited resistance, resources/cooperation, and
items/mental effects/other worlds; a fourth pass checked host lifecycle, time
rate, units and rounding. This follow-up supersedes broader missing-rule claims
above where specified. `freeform-1994` pages refer to the original magic system;
`full-2008` B-prefixed pages are host-generation evidence, not automatic imports.
Numbers and difficult passages were checked against rendered page images.

### Recovered or clarified rules

| Topic | Finding | Source |
| --- | --- | --- |
| Direct resistance | Direct effects use Will. Ordinary resistance-to-magic advantage has no effect against this magic system. Possession always attempts resistance. Importing the standard spell system's trait bonuses would contradict the retained source baseline. | 41, 86, 117 |
| Countering | A counter reduces actual effect magnitude. One target's counter can cancel an entire area effect if the remaining margin cannot support the declared area. Concerted counters explicitly use cooperation rules. | 87-88 |
| Casting costs and disclosure | Failed or inadequate casts lose spent reserve; strain is assessed before defenses; the result is reported after defenses. The source does not prescribe refunding or recomputing these costs on resistance. | 86-87 |
| Specific quantities | Specific mass guidelines expressly override the generic allowance. Preserve the particular creation formula's rank-2 prerequisites and later rank-4 mixed-material extension. Life's specific direct injury formula is also an operation override. | 89, 110, 114 |
| Capacity | Reserve that would overlap strain cannot be held. This already resolves ordinary incoming reserve overflow. It does not specify which origin of reserve is displaced or cap strain at twenty. | 44, 50 |
| Taking reserve | Power 3 explicitly permits taking another caster's reserve above the protected channel floor; willing donation is not a prerequisite. Treat an unwilling direct target under applicable resistance. | 86, 120 |
| Remote supply | The power-3 plus space-4 delivery formula moves one reserve per success, unlike the generic five-per-success transfer operation. | 120-121 |
| Cooperation | Sum actual individual strain gains once and apply that sum to each participant. Ordinary failures most directly contribute zero successes, not a negative success amount; the source does not direct rewriting everyone's dice after one critical failure. | 86, 88 |
| Standard spell lifecycle | Host-generation rules cover interrupted concentration, voluntary abort, strongest-instance stacking, maintenance, active manipulation and cancellation. These have their own costs and must not overwrite the original system's specific rules implicitly. | full-2008 B236-B238 |
| Time-rate model | Each level of the host time-rate trait adds one maneuver on the existing turn; it does not move initiative earlier. This supplies a model for scheduling, not a ruling on reserve spending per subjective turn. | full-2008 B38 |
| Units and rounding | Point costs round toward positive infinity, feats/combat results downward, except specific rules. The source supplies both convenient game-metric and more exact conversion columns, plus temperature-change conversion. | full-2008 B9 |

### Cancellation, mental effects and spirits

The following are source procedures, not missing mechanics awaiting invention:

- Memory alteration can be reversed by a contest against the original roll
  (p. 118). A caster affected by the sustaining-flow disruption can spend one
  reserve to end it (p. 120). A boundary breach's creator can close it at any
  time (p. 123). Physical destruction or power-4-equivalent interference removes
  item enchantment, but depletion alone does not (p. 91).
- Certain ongoing manifestations of strain explicitly admit countering,
  including an energy-5 manifestation for which it is the only banishment route
  (p. 169). These are exceptions to the usual incoming-effect procedure, not a
  universal persistent-effect cancellation algorithm.
- `full-2008` B250 supplies both targeted cancellation and nonselective area
  dispelling, including skill requirements, contests, time and cost. Neither
  reverses completed permanent changes or strips permanent item enchantment.
  Mapping spell prerequisites/costs to domains/reserve is a conversion decision.
- Thought probing has a specific duration in minutes equal to success margin,
  and cannot repeat until the subject sleeps. Established links survive travel.
  Possession occupies the caster's attention and distinguishes full from partial
  control. Memory alteration uses the duration chart for the amount of memory
  affected (pp. 117-118). These require effect-specific evaluators.
- Mental projection has its own movement, perception and combat rules: IQ
  replaces physical strength/dexterity, Will replaces health, astral injury
  reduces Will, zero severs the bodily link, and lost Will returns at one per
  hour (p. 118). The stated speed exceeds 500 mph; it is not an exact speed cap.
- Spirit sight has a numerical barrier/success table, distinct from crossing
  contests. Rank-4 boundary work changes barrier strength by two per success;
  trapping, rescue and voluntary closing have explicit procedures (pp. 122-124).
- Spirit rules distinguish flexible casters from beings with one fixed effect
  per purchased domain level. The latter take one die of severe injury per
  strain gained instead of storing strain. Materialization has explicit barrier
  limits: 8 or less, 12 or less, and below 18 for the three strength categories
  (p. 167). Manifestations of strain have skill `10 + 2 * rank`, no reserve and
  no further strain from their effects (p. 169).
- `full-2008` B296 supplies body/mind ownership of traits and skill recalculation;
  B193 supplies a distinct exorcism procedure. Its possession and mental-control
  alternatives must not erase the original sleep-based retry exceptions.

### What the checked books still do not settle

| Remaining issue | Why it remains |
| --- | --- |
| Original core resistance and spirit-vessel construction | The matching earlier core edition is not catalogued. Spirit-vessel construction explicitly points to another supernatural supplement on p. 123; the owned books do not contain that procedure. Host resistance is available separately. |
| Some conjunction ranks | Pages 100, 104, 120-121 and 123 require additional knowledge without universal numeric ranks. Page 97 expressly delegates novel combinations to the referee. |
| Typed reserve displacement and strain above twenty | The shared capacity does not define reserve-origin ordering, saturation or a mandatory automatic discharge threshold. |
| Transfer/receipt composition | The separate receiving and transfer descriptions do not say that a second receiving roll is always required. Single-turn allocation of a large consumed portion needs a transaction policy. |
| High-strain complication batches | Values and minimum expenditure are known. Snapshotting eligibility for a whole batch versus recalculating after each choice is unspecified. |
| Group critical and exact-zero edges | Critical-failure propagation is explicit; aggregate critical-success scale, zero-margin aggregation and who makes backlash rolls after a group critical failure are not fully specified. |
| Crafting and relearning | The three construction rolls lack mixed-failure precedence. Half-price rank restoration is given, but treatment of previously purchased skill investment is not explicit. |
| Local equality and internal episodes | Local-world examples support equality despite stricter prose. Internal-confrontation durations give units, not counts or a failed-roll row; episode onset/end are referee-controlled. |
| World construction | Ingredients and continued source support are described, but no complete rank/size/supply/time formula is supplied. Boundary-prison rescue is covered; authored backlash-world escape is a different issue. |
| Engine implementation | Transactions, persistent IDs, undo, exact scheduler integration and coverage of implemented operations belong to the host specification, not a missing rulebook chapter. |

The earlier checklist mixed these categories. Most recovered rules should now
move to implementation and validation; the remaining table is the narrower
research/interpretation boundary. A deliberate host adaptation can resolve an
edge without pretending that the source printed that decision.

## Accepted edition direction — 26 October 2026

The user accepts adapting the original magic system to the available newer core
in the spirit of its intended behavior. Older core wording remains historically
unverified, but recovering it is not required for this project. Use `full-2008`
for core procedures, retain explicit magic-specific exceptions, and label the
resulting adapters. This changes the classification of older core references
from retrieval dependencies to conversion work; it does not resolve the distinct
external spirit-vessel source or the listed accounting edge cases.

## Deferred spirit-vessel construction — 26 October 2026

The user does not own the supplement referenced under the spirit-vessel example
on printed p. 123 (viewer p. 124), and requests review later. Construction is
therefore deferred, not an active acquisition task or a blocker for the core
extension. Keep the rank permission visible and the procedure unsupported until
a future review supplies source evidence or approves an explicit adaptation.
See the plan's [referee-judgment table](freeform-magic-plan.md#referee-judgments-to-preserve)
for the separate gameplay decisions intentionally left to the referee.

## Local defaults, adjudication and accounting follow-up — 26 October 2026

### Local barriers already have a table

The complete printed p. 146 (viewer p. 147) was rechecked visually. These are
suggested local barrier values in `freeform-1994`, not invented conversion
numbers. The source allows exceptions and says most sites stay within one point
of the usual value; unusual deviations can be deliberate world content.

| Location or source strength | Barrier |
| --- | --- |
| Laboratory | 18 |
| Inner city | 16 |
| Ordinary location | 14 |
| Rural countryside | 12 |
| Deep wilderness | 10 |
| Active source, strength 1 | 8 |
| Source strength 2 | 7 |
| Source strength 3 | 6 |
| Source strength 4 | 5 |
| Source strength 5 | 4 |

Use these as configurable setting defaults, not a compulsory claim about all
fictional technology or geography. The table's other-magic environmental column
is not automatically an additional modifier to this magic system. Crossing
uses the barrier contest; sight uses its own p. 122 success table. Local world
casting laws on pp. 90-92 are a third, distinct mechanism. These tables and rules
are recovered; which location has an exceptional rating remains authored.

### Accounting issues illustrated

The following examples expose policy choices; they do not add new printed rules.

- **Group critical and zero results (p. 88):** a success margin of three plus an
  exact success gives raw aggregate three, but four if each exact success counts
  as one before aggregation. Quantity-specific zero rules need an explicit
  aggregation order. Ordinary failures contribute no successes. One person's
  critical failure makes the whole effect fail; whether everybody or only the
  actual critical-failing caster must check backlash remains unspecified. One
  critical success likewise does not explicitly give the entire group critical
  range/duration benefits. Sum actual individual strain gains once and apply
  that sum to each participant; do not reroll or rewrite the other contributions.
- **Reserve displacement (pp. 44, 50, 119-120):** eight reserve plus twelve strain
  fill the track. Three more strain remove three reserve, leaving five reserve
  and fifteen strain. That arithmetic is settled. If four of the original eight
  reserve came from innate recovery and four from outside, an origin-tagged
  model must decide which three were lost. Alternatively, a single pool with a
  protected channel-rating floor needs a clear rule reconciling origin wording
  and transfer restrictions. The book does not mandate two separately tagged
  pools. Rejecting incoming excess reserve is settled; strain beyond twenty
  and origin bookkeeping remain separate decisions.
- **Complication batches (pp. 133-134):** with twelve strain, at least six must
  be spent, and the above-eight rule permits only severity-five choices. Under
  a start-of-batch interpretation, two severity-five choices cost ten and leave
  two. Under a sequential interpretation, the first costs five, leaves seven,
  and changes eligibility before the next choice. Fixed eligibility and a fixed
  minimum-spend total for the whole transaction would prevent order-dependent
  pricing; this is a proposed policy, not an adopted or printed algorithm.
- **Construction outcomes (p. 91):** one of three required rolls could fail
  ordinarily while another critically fails. The source's destruction versus
  defect outcomes need precedence. The user's accepted initial adaptation now
  resolves this: both outcomes become ordinary construction failure, destroying
  the prospective item. Defect generation is deferred. Preserve actual dice
  flags for independently applicable magical consequences and define debit/time
  handling in the implementation; do not erase critical results globally.

### Accepted authoring decisions

Invented effects and coincidence will use a virtual referee with validated,
versioned rulings; spirit calling will adapt existing social relationships;
item defects are deferred under the ordinary-failure adaptation; distorted
perception is explicitly authored. Detailed interfaces and remaining work are
in the plan. These are conversion decisions, not corrections to source records.

### Anniversary comparison: targeted inspection only

The new supplied PDF has 698 viewer pages and a 2015 copyright page. The checked
body pages map printed page to viewer page plus one. Use provisional neutral
source ID `anniversary-2015`. Original file unchanged; this is not a complete
catalogue/import or a claim that its rules replace `freeform-1994`.

- Pages 528-530 distinguish the intended effect, capability and method, and
  explain appearance in local circumstances. They are useful conceptual input
  for adjudication; setting-specific belief requirements are not mandatory host
  features merely because this source uses them.
- Page 539 gives an optional scene-based repeated-coincidence rule, focused on
  noticeable events and excluding private minor effects. Its difficulty numbers
  belong to its own dice system; consider its structure as a candidate policy,
  not a direct numerical patch to the three-die rules.
- Pages 331-332 retain overlapping reserve/strain and protected personal reserve,
  but do not explicitly settle the origin-ordering question above. Page 332
  notably requires power rank 3 for absorption of portable supply, unlike the
  earlier adaptation's rank 1 permission. Keep that difference visible.
- Pages 540-541 describe extended ritual failures and their own recovery costs.
  These are not the same procedure as the earlier adaptation's simultaneous
  cooperative casting; they do not settle group critical propagation by fiat.
- Page 652 ties use of a spirit-bearing item to the relationship with its spirit.
  This supports the relationship design concept, not adoption of its activation
  dice or release of the deferred construction feature. Construction remains
  scheduled for later review by the user's decision.

Numerical statements on p. 332 and the extended-ritual procedure on p. 540 were
visually checked. Page 539's optional-rule layout was also inspected. No new
source facts were inferred from the PDF filename or creation metadata alone.

## Post-investigation rulings and anniversary comparison — 26 October 2026

The user requested independent investigation before a best-fit ruling on group
outcomes, a fresh reserve investigation, and adoption of fixed-at-start
complication batching. Three reviewers checked the available sources. The
following supersedes earlier open-status descriptions; published-source records
remain separate from these project decisions.

### Adopted group-result interpretation

- Sum raw margins from actually successful participants. Ordinary failures
  contribute zero and retain their own failure consequences. At least one
  participant must succeed; a group of ordinary failures is not a successful
  zero-margin cast. Critical failure overrides all successful contributions.
- Apply quantity-specific minimum successes once to the aggregate. Margin three
  plus exact success zero is three, not four. Two exact successes are successful
  raw zero: use the normal minimum for damage and the explicit raw-zero entries
  for mass/temperature. Countering subtracts raw margin without a minimum bonus.
- If no one critically fails, a genuine critical success preserves the specific
  critical range/duration chart benefits for the group. It does not multiply
  damage, grant extra domain knowledge, change declared intent or bypass resistance.
- Calculate each caster's strain gain from their actual roll, sum those gains
  once, and add that total to each caster. An overt group critical failure then
  triggers one backlash check per participant against their own resulting strain.
  Several critical failures do not produce duplicate checks per participant.
  A subtle critical failure has no automatic backlash check solely from that flag.

These edges are adopted conversion rulings, not recovered verbatim procedures.
`freeform-1994` pp. 85-89, 134 supplies the underlying charts, actual-gain sharing
and group critical failure. `anniversary-2015` pp. 542-543 confirms shared danger,
but its dice-pool model has neither an exact-success zero margin nor the same
natural critical-success flag. Its general teamwork (pp. 391-395) and the owned
core's other cooperation systems do not settle those three-die details.

The ruling applies minimum scale to one shared effect, preserves a solo caster's
critical chart benefit when helpers join, and preserves individual strain pools
when the entire group is endangered. An alternative zero-normalization order
would also be defensible; it was deliberately rejected to avoid granting a new
minimum-success contribution for every barely successful helper.

### Reserve investigation: one pool is sufficient

`freeform-1994` pp. 44, 50, 119-120 supplies a single shared track, the transfer
floor at channel and strain's precedence. `anniversary-2015` pp. 248, 331-332 adds
clear placement: baseline reserve first, later reserve extending in one direction,
strain coming from the other. There is no prescribed history tag for each point.
Personal reserve's protection from taking is not immunity to strain overwrite.

Adopt the derived positional model: with Q reserve, P strain and A channel,
protected reserve is `min(Q,A)` and transferable excess is `max(0,Q-A)`. Added
strain sets Q to `min(Q,max(0,20-P))`. Ordinary spending uses the same single
Q value. This models excess being used/displaced before the protected base,
without maintaining separate origin pools. It is a labelled reconciliation,
not a newly found sentence expressly mandating historical external-first debits.

Keep all earned strain, including totals above twenty. The anniversary p. 333
explicitly contemplates twenty or more and possible severe consequences, but
neither that warning nor its p. 549 table defines a universal saturation cap or
one mandatory overflow outcome. Consequence selection remains a separate policy.

### Complication batch accepted

Snapshot starting strain P. Require total expenditure of at least `ceil(P/2)`
and at most P. If starting P is above eight, every chosen complication costs
five. Evaluate the entire proposed batch against that snapshot and apply it once.
Do not recalculate eligibility after each selection. For P=12, two five-point
choices spend ten and leave two. This is the accepted deterministic adaptation
of `freeform-1994` pp. 133-134; M20's later consequence system does not replace it.

### Changes beyond dice notation

| Mechanism | Earlier adaptation | Anniversary evidence | Conversion significance |
| --- | --- | --- | --- |
| Casting skill | Lowest trained domain skill, additional-domain penalty, three-die roll; mastery caps skill. | Mastery dice pool against difficulty driven by highest domain and circumstances (501). | A different mathematical model; a one-point difficulty reduction is not a fixed host skill bonus. |
| Reserve assistance | +2 effective skill per point, channel-limited (44, 88). | Difficulty reduction, normally channel-limited with net reduction at most three; extra spending can offset penalties; special other-use spending clause for power 3+ (332, 537). | Preserve separate bonus, channeling and absorption rules; do not import an unlimited bonus. |
| Portable supply | Power 1 permits consumption (80). | Power 3 extracts portable supply (332, 520-521). | A real permission change, not a dice conversion. The user adopted power 3 for absorption on 26 October 2026 (M20-02). Separate receiving/storage prerequisites remain unchanged. |
| Personal strain removal | Power 5 example attacks an external manifestation, not internal accumulated strain (121). | Power 5 can cancel strain with reserve point for point (549). | Adopted for the caster's own strain on 26 October 2026 (M20-05), requiring a successful working and actual expenditure. |
| Natural strain loss | Existing plan uses original consequence procedures. | Small pools can fade under stated restraint; a higher-total abstinence variant is optional (549). | Weekly loss below five adopted on 26 October 2026 (M20-06); no monthly higher-total option. The plan fixes eligible activity and interval reset rules as conversion policy. |
| Strain generation | Source-specific gains based on mode, witnesses, rank and failed-roll margin (86). | Default successful overt casts gain one; botches use rank/witness formulas. A harsher later-edition variant is explicitly optional (502, 547, 550). | Different risk economy; choose a complete policy instead of blending favorable rows. |
| Formulas | Default use costs zero points; paid +1/+2/+3 improvements have special skill/time rules (89). | No point expenditure to know a formula; optional learning/research rolls and unfamiliar-method treatment (529). | Distinguish free default access from the earlier paid specialization, rather than claiming every old formula cost points. |
| Extended rituals | Cooperative casting alone is not a complete extended-success ritual engine (88). | Bounded repeated rolls, fatigue, failure escalation, first-botch recovery, and additional risk for continued rolls (540-543). | Useful optional procedure requiring a deliberate host implementation. |
| Coincidence | Circumstantial plausible appearance and optional repetition penalty (81, 87). | Expanded method/local-context guidance and a scene-based repetition option (530-539). | Useful virtual-referee inputs and policy structure; numerical modifiers still need adaptation. |

M20 preserves a menu of edition choices rather than one uniformly newer rule.
Page 21 dates the first edition to 1993 and the second to 1995, consistent with
the 1994 adaptation's early-era baseline. This is chronology evidence, not proof
that every difference first appeared in a particular subsequent edition.


### Additional casting refinements checked in the anniversary PDF

- **Actual operations and visible plausibility:** pp. 533-534 distinguishes the
  process from its apparent explanation and uses an ordinary hypothetical
  observer without omniscient access to hidden facts. A plausible arrival does
  not create a missing vehicle or driver. This informs the accepted virtual
  referee design: capability first, plausible presentation second.
- **Outcome and retry:** pp. 503, 537-540 permits partial results where meaningful
  and penalized continuation. This differs from the original declared-scope and
  changed-circumstances restriction. Define eligible operations rather than
  universally halving outputs or allowing unlimited retries.
- **Action and attention:** pp. 528-529, 535 explicitly limits casting to one
  effect per turn even under acceleration. Only concentrated ongoing effects
  count toward load; mere duration, triggers and anchors are distinct. These
  are useful candidates for the outstanding scheduler/lifecycle policy.
- **Mundane practice:** pp. 532-533 allows appropriate ability prerequisites and
  a bounded preparation roll, with safeguards against recursive or automatic
  preparation bonuses. This is not implied by the original magic-to-mundane
  assistance rule running in reverse.
- **Determination:** pp. 536-537 spends temporary Willpower for an automatic
  success before the roll, at most once per turn. This would be a new currency;
  the host's Will score or fatigue is not already the same mechanic.
- **Witness and local policy:** pp. 531-532 limits the relevant witnesses to
  physically present observers; familiarity affects their eligibility. The
  scene repetition rule (539) and local-practice rules (611-613) are optional.
  Recording/camera exposure can matter narratively without being a present
  witness. Local belief does not waive required domain permissions.
- **Practice/tool dependency:** pp. 566-567, 587-588 offers a broader method model
  and different unique-tool loss/advancement rules. This does not resolve the
  original half-price relearning accounting by itself.

These additions are indexed as separate M20 source facts in the private
reference. The plan's M20 decision register records subsequent user selections;
unselected alternatives remain candidates. No wholesale M20 resource or
dice-pool system has been adopted. Published evidence remains separate from the
extension's chosen procedures and interval/accounting interpretations.

### Backlash conversion decisions and blast evidence — 26 October 2026

The user adopted the anniversary consequence combinations with a host injury
scale of half backlash strength rounded up for bruising, full strength for
injury, and twice strength for severe injury. Lasting strain is enabled: it
occupies reserve capacity and affects backlash rolls but is excluded from
ordinary discharge, weekly recovery and ordinary power-5 removal. These are
project decisions, including the explicit removal exceptions, not claims about
equivalent dice probabilities. See M20-08a–c in the plan for the complete policy.

Outward blasts on a physical branch of strength ten or more are also adopted.
The reference previously indexed the relevant Basic Set chapter without its
procedure. Direct inspection of `full-2008` B377 and B413–B415, with B407–B408
for the scope of cover rules, supplied the following adaptation evidence:

- B414 divides collateral blast damage by three times distance in yards,
  rounding down, and uses torso armor. Its dice-based radius is distinct from
  that falloff and cannot simply be applied to our fixed injury values.
- B377 permits a defensive dive to nearby cover or farther from the blast.
  Success changes position/exposure; it does not simply negate an area effect.
- The ranged-cover rules do not supply a complete blast-obstacle simulation.
  Authored cover DR in the adopted adapter is explicitly a host choice.
- Fragmentation, ignition and alternative media/contact rules have additional
  procedures. They are not automatically imported into the magic extension.

B377 and B414 were also visually checked in the PDF (viewer 381 and 418).
The private reference now has a focused `basic-explosions` record. The plan's
M20-08d decision adopts distance, cover, armor and reactive diving as the host
conversion. No explosion runtime has been implemented. The subsequent M20-10
and M20-11 decisions adopt one initiated casting per normal world combat turn
and a -1 modifier per pair of already-running effects requiring attention;
these are labelled host policies, not direct probability conversions.


### Outcome and ritual selections — 26 October 2026

M20-12 adopts partial results only for successful casting rolls and operations
whose smaller outcome was specified before rolling. M20-13 adopts three ordinary
attempts at a goal with retry penalties of -1 and -2, normal attempt costs/risk,
no accumulated margins, and termination on critical failure. Specific domain
retry locks remain. These are chosen host interpretations of the anniversary
partial-outcome/continuation options, not the original GURPS retry rule.

M20-14 includes extended rituals as an optional initial-release procedure. Its
numerical details were settled in the subsequent M20-14a–j choices below;
transaction integration still remains. The plan distinguishes accepted scope
from a completed ritual implementation.


M20-14a–c subsequently adopts a maximum of three plus lead mastery rolls,
five-minute/hour/five-hour roll intervals assigned by scope and method, and
ordinary-failure escalation of -1 per failure. Critical casting failure ends
the ritual immediately, with no recovery payment. These are explicit host
conversion values; they do not claim that M20 uses GURPS Will, the same brief
ritual timing, or the same critical-failure procedure. Remaining ritual decisions
are enumerated in the plan's framework section.


M20-14d–f adopts successful-margin progress with one minimum point per successful
solo/group check, immediate provisional pressure on reserve capacity and backlash,
no refund of displaced reserve, and HT-based endurance. The host endurance
allowance is floor(HT/3) hours with a minimum of one; subsequent hourly checks
escalate by -1. Failed endurance ends the working without becoming a critical
casting failure. Subsequent decisions below settle interruptions, pauses and
restarts; ledger integration remains explicitly outstanding.


M20-14g–i adopts Will-3 for forced interruptions, controlled major-working pauses
of at most 48 hours, and ritual restarts within the ordinary three-attempt goal
sequence. The interruption check adapts GURPS Basic B236 (viewer 238); automatic
termination cases and its ritual application are chosen host policy. It does
not import M20's disruption-as-botch recovery sequence.

The pause procedure draws on M20 pp. 541–542 (viewer 542–543), but substitutes
the lowest required domain skill without casting bonuses, penalized by earlier
pauses, and omits the determination payment. Progress, remaining attempts,
casting-failure penalties and provisional strain persist; only full normal
sleep resets endurance. Each whole ritual uses one goal-attempt slot, with
sequence penalties applying to every casting roll. Ordinary unsuccessful
endings permit the next slot; critical casting failure ends the sequence.
These are accepted conversion rulings, not additions to published-source MCP
records. M20-14j below subsequently settles simultaneous effects; transaction integration remains outstanding.


### Practice and simultaneous-effect selections — 26 October 2026

M20-14j allows one additional effect requiring active attention during a ritual,
with -1 to ritual casting while maintained. Personal rank-1 perception is exempt
from this extra restriction; mere duration, anchors and waiting triggers do not
count. Do not count the additional effect again under the ordinary concentration
penalty. Ritual feasibility and the world-turn casting limit remain in force.
This adapts M20 p. 540 (viewer 541); its host modifier and interaction with the
concentration policy are adopted rulings, not a literal source formula.

M20-15 requires training where a practice depends on an ordinary skill; higher
minimums are authored per practice. M20-16 permits one relevant preparation
check per cast or whole ritual, with +1/+2/0/-1 for success/critical success/
failure/critical failure, applying only to the next casting roll (the first
ritual roll). It takes authored time of at least one normal turn, cannot be
repeated within the attempt, and cannot be enhanced by magic or other preparation
bonuses. M20 pp. 532–533 (viewer 533–534) supplies optional ability prerequisites
and bounded mundane assistance; the adopted host coefficients, training test
and bonus duration are separate conversion decisions.

The next selections below address optional scene repetition (p. 539), local
practice acceptance/rejection (pp. 611–613), and automatic success for trivial
familiar coincidences (p. 539). The source automatic-success option uses mastery
at least required rank plus three and excludes combat and consequential/complex
effects; M20-19 omits that shortcut from the initial host extension.


### Scene and routine-casting selections — 26 October 2026

M20-17 adopts a shared counter of successful conspicuous coincidences in a scene:
first three unpenalized, fourth/fifth -1, sixth/seventh -2, eighth onward -3.
Hidden personal effects and unobtrusive perception are excluded. Only a material
scene change recorded by the virtual referee resets it; it replaces rather than
stacks with the earlier repetition modifier. The explicit schedule and cap are
host choices inspired by the optional M20 p. 539 procedure (viewer 540).

M20-18 adopts authored local practice profiles: accepted +1, neutral 0, rejected
-1, with overlapping profiles resolved to one modifier. They also inform
coincidence adjudication without automatically making accepted practices subtle
or waiving domain permissions, barriers or world domain ratings. M20 pp. 611–613
(viewer 612–614) provides the optional acceptance/rejection concept; deterministic
profile precedence remains implementation work.

M20-19 retains casting rolls for routine magic and omits M20 p. 539's optional
automatic-success rule initially. No separate eligibility thresholds or guaranteed
margins are required for that omitted option. These selections are project
rulings, separate from published-source reference records.


### Witness, formula and modifier selections — 26 October 2026

M20-20 requires a physically present observer able to perceive the working,
whose authored familiarity/beliefs do not accommodate the relevant magic, for
heightened witness strain. Cameras, streams and later recordings do not count;
friendship is not itself an exemption. This neutral adaptation of M20 pp. 531–532
(viewer 532–533) replaces source setting categories with individual traits and
retains ordinary consequences of discovery. It does not replace the separately
adopted GURPS strain schedule or make an unobserved overt effect subtle.

M20-21 retains GURPS Mage pp. 88–89 formula improvement pricing: +0/+1/+2/+3
costs 0/1/2/4 points, with fixed casting time and the special skill ceiling.
Known formulas have no numerical count limit. M20 p. 529 (viewer 530) instead
has no separate experience purchase for rote improvement; that alternative was
not selected. M20-24–25 subsequently settles familiarity and authored learning/access.

M20-22 retains individual modifier limits without an aggregate casting cap.
M20 pp. 503, 536–537 supplies a net three-step difficulty bound, but that is
not adopted into the host three-die system. The approved reserve coefficient,
channel throughput, bounded bonuses and cumulative ritual penalties remain;
learned-skill ceilings still apply where specified. Published source rules and
these accepted conversion decisions remain distinct.


### Time, familiarity and learning selections — 26 October 2026

M20-23 retains GURPS Mage p. 84's +1 for doubling ordinary improvised casting
time, with no further bonus for more time. Formulas retain fixed times under
p. 89, and the chosen extended ritual intervals grant no automatic extra-time
bonus. The larger M20 preparation benefit and the proposed host time ladder
were not adopted. This is separate from the mundane preparation check.

M20-24 adapts the unfamiliar-method/tool progression on M20 pp. 529 and 567
(viewer 530 and 568) as -2/-1/0 host casting skill. Authored milestones or
recorded virtual-referee rulings establish familiarization. Apply one penalty
per cast, not per unfamiliar component; missing required equipment, training
or domain permissions remains an eligibility failure. The host coefficient
and milestone procedure are explicit conversion decisions.

M20-25 uses authored learning conditions for formula knowledge, through teachers,
sources or demonstrated practice, without the universal learning/research check
option described on M20 p. 529. Available methods, permissions and familiarity
remain relevant. Recording knowledge and purchasing a numerical improvement
are distinct operations. M20-26–28 subsequently settles tool benefits,
dependency/loss and omission of an emergency practice bypass.


### Tool and dependency selections — 26 October 2026

M20-26 adopts a designated personal tool tied to one chosen domain for +1 host
casting skill, or +2 total when it is explicitly bound and irreplaceable by
ordinary purchase. An authored training/story milestone establishes designation;
multiple tool bonuses do not stack. M20 pp. 587–588 (viewer 588–589) supplies
personal/unique instrument benefits; the host coefficients, one-tool limit and
neutral domain designation are chosen conversion rules.

M20-27 explicitly retains GURPS Mage p. 93 (viewer 94) half-cost rank relearning
after bound-tool loss. Recovery, sufficient mastery exemption, or replacement
through relearning restores access. The proposed free authored rebinding option
was not selected, nor were M20 p. 588's permanent destruction consequences.
The old text does not settle already-purchased domain skill, exact fractional
price accounting or restoration of the original during partial relearning;
these remain conversion details for a consistent policy. Replacement bonus
eligibility also needs reconciliation with the adopted personal-tool rule.

M20-28 omits emergency casting without required practice/tools. M20 pp. 566–567
(viewer 567–568) offers a determination-funded bypass with restrictions; neither
that resource nor a fatigue substitute is adopted. Another valid method or an
earned mastery exemption can still satisfy ordinary eligibility where permitted.


A follow-up agent checked the full reference, Mage p. 93 visually, Mage p. 50's
separate rank/skill purchases, Basic B9's upward point-cost rounding (viewer 11),
M20 p. 588, and the host's integer progression accounting. No source supplied
an instruction to repurchase domain skill. The subsequent M20-27a–b choices adopt skill/formula retention and replacement
bonus restoration as host rulings, not published facts.

The conversion's accounting defaults use cumulative `ceil(C(rank)/2)` costs,
charging differences rather than rounding each separate increment. This yields
3/13/23/33/45 for the default practice-dependent rank schedule and avoids a
purchase-path-dependent total. The placement of rounding is a host ruling;
Basic B9 supports upward point-cost rounding but does not define this Mage
restoration procedure. Recovery of the original tool or mastery exemption
restores former access without refunding paid replacement training; new ranks
beyond the former maximum cost ordinary incremental prices. These defaults
retain the user's half-cost choice rather than replacing it with free recovery.


### Relearning and cooperation selections — 26 October 2026

M20-27a adopts retention of purchased domain-skill and formula investment during
half-cost rank restoration. Relearned ranks gate the replacement's supported
operations; eligible rolls use retained skill with the ordinary mastery ceiling.
Additional points pay for rank restoration only. This resolves the p. 93
accounting gap using the separately purchased ranks/skills distinction on p. 50;
it is a host ruling rather than a newly recovered explicit retention sentence.

M20-27b permits a replacement to regain the +2 bonus after an authored binding
milestone, for workings within ranks already restored through that replacement.
Completing restoration of every former rank is unnecessary. Ordinary shopping
does not establish binding. This deliberately combines the retained GURPS
replacement procedure with the adopted host personal/bound-tool bonus; it does
not import M20's permanent loss of a destroyed unique instrument's benefit.

M20-29 retains the GURPS Mage p. 88 full-rank qualification for every group
participant and the settled margin/critical/shared-risk policy. The broader
participation and separate lesser-assistant mode in M20 pp. 542–543 (viewer
543–544) are not adopted initially. Ordinary preparation and practical help
remain available, without creating automatic helper contributions to group
casting margins.


### Final targeted comparison selections — 26 October 2026

M20-30 retains declared effect scope when casting earns surplus margin. Extra
damage, targets or duration are not automatic rewards; the already-retained
critical-result rules remain. This preserves the GURPS Mage pp. 85, 88 approach
instead of importing the exceptional-result reward approach discussed in M20
pp. 503, 537–540. The proposed authored surplus tiers were not selected.

M20-31 uses existing practice requirements, local profiles and plausibility
adjudication for symbolic significance. The optional significant-instrument
bonus in M20 p. 588 (viewer 589) is not added. Symbols cannot waive domain
permissions or certify their own plausibility; the separately adopted personal
and bound-tool benefits remain subject to their own rules.

M20-32 records the full strain total beyond twenty, with zero reserve capacity
and no new threshold-crossing backlash trigger. M20 p. 333 (viewer 334) explicitly
contemplates such totals and discretionary severe consequences, rather than
specifying a saturation cap or one mandatory overflow outcome. Existing
critical-failure and authored discretionary triggers remain, along with the
selected backlash bands and physical-branch blast rules. This resolves the
previously outstanding overflow choice.

The targeted M20 decision round is complete. This does not complete the host
resistance adapter, ritual/resource transactions, operation-by-operation coverage,
content authoring or implementation. Those remain on the plan's current
checklist; settled choices should not be presented as new missing-source gaps.
