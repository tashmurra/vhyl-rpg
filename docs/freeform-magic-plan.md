# Freeform magic extension plan

Implementation status: see the [implementation guide](magic.md),
[author guide](magic.md) and [coverage ledger](magic/coverage.json). The earlier
open checklists below preserve the research history; they are superseded by that checkpoint.

Status: approved design with first executable casting milestone, 26 October 2026. Repository baseline: `2162b49`.
This document specifies a separate opt-in extension. The implementation checkpoint
at the end identifies the executable subset; remaining API names are proposals.
Updated after three parallel source audits and the direct core-reference checks. The outstanding-work
checklist below separates verified rules, open conversion choices, source
dependencies and implementation deliverables; unchecked items remain open.

The [domain permission matrix](freeform-magic-permissions.md) is a required part
of this plan, not an optional appendix. Its 45 rank entries, qualifications,
cross-domain requirements and effect-specific exceptions are inputs to phase 1
and the implementation acceptance checks. Research coverage does not imply that
all those effects are executable yet.

The [direct PDF source audit](freeform-magic-source-audit.md) is also required.
It supplies the recovered scale tables, casting/retry procedures, ordinary skill
and combat assistance, resources, backlash injury, item construction and optional
world rules. Its source exceptions and unresolved interpretations are part of
phase 1, not details to replace with guessed defaults.

Build `vhyl-rpg-magic.t`: characters combine knowledge of different domains to
describe effects, cast them using the existing three-die engine, and balance a
reserve against accumulating strain. Keep setting, organizations, named powers,
cosmology and character archetypes out of the library. Use ordinary language in
rules, identifiers, examples and player commands.

## Evidence and conversion boundary

Use neutral source ID `freeform-1994`: the owned third-generation adaptation,
1994 publication, printing unverified; corrections are `freeform-errata-1999`,
revised 2 September 1999. Printed page numbers below refer to that book, not
viewer pages; viewer page = printed page + 1. The reference service supplied
curated summaries for character costs, casting, resources, defenses,
formulas, items, consequences and advancement. These were complete record
responses, not complete coverage of the source rules. It supplied a domain directory;
follow-up inspection of the owned PDF located all 45 rank descriptions. See the
[domain permission matrix](freeform-magic-permissions.md) for neutral summaries,
page references, conjunctions and exceptions. The service's search itself does
not search the PDF or OCR.

The scan has damaged lower portions of printed pages 1 and 3. Navigation was
reconstructed; missing text and the printing remain unresolved. The curated
records apply the separate correction layer. Neither reconstructed navigation
nor a setting summary is authority for an unrecorded mechanical rule.

Follow the repository's [provenance convention](provenance.md): distribute
original code, original explanations, neutral source IDs and printed page
references. Keep source-title mappings, private service URLs, scans, extracted
text and campaign records outside the distributed extension. This plan's source
map is a research index, not a claim of complete implementation or validation.

**Accepted conversion direction — 26 October 2026:** use the available
`full-2008` core mechanics and adapt the older magic procedures in the spirit of
their intended behavior. Preserve explicit magic-specific permissions and
exceptions, and document interactions with the newer core. Exact reconstruction
of the earlier core edition is not a prerequisite or a research blocker. This
settles the edition direction; the detailed resistance, timing and accounting
adapters below still need specification.

Three labels must accompany the future coverage ledger:

- **Retained:** supported source procedure, rewritten in original language.
- **Adapted:** deliberate vhyl-rpg conversion or house rule, with its reason.
- **Unverified:** needed detail not established by the retrieved records.

The host uses the existing later-generation attribute, skill, injury and fatigue
rules. Preserve the distinctive magic procedures, explicitly adapt their host
interfaces, and do not import legacy character sheets or legacy combat rules.
The source's own conversion chapter, pp. 178–187, converts into its contemporary
rules generation; it is not authority for this conversion.

## Accepted adjudication direction — 26 October 2026

- Add a virtual referee for inventing effects and judging plausible coincidence.
  The referee supplies a structured ruling; the engine validates and executes it.
- Adapt spirit calling difficulty to relationships using the existing social
  libraries. Calling, arrival and cooperation remain distinct outcomes.
- For initial item construction, critical failure has the same item outcome as
  ordinary failure: destroy the prospective item and create no flawed item.
  A concrete defect system is deferred for later review. Preserve the original
  dice result for any separately applicable casting consequences; this decision
  does not globally turn critical casting failures into ordinary failures.
- Use the recovered local-barrier table as defaults with explicit location
  overrides. Do not describe the whole table as unspecified referee content.
- Distorted perception is authored content. The virtual referee does not invent
  episodes, rewrite world truth, or manufacture their resolution dynamically.
- In discussions and private comparison notes, include original terminology in
  parentheses where useful. Keep distributed runtime identifiers and game-facing
  vocabulary neutral; the explanatory crosswalk is not an in-world dependency.

### Virtual referee contract

The following is the proposed implementation design for the accepted direction,
not a claim that a virtual referee already exists in the libraries.

1. Receive an intended outcome and proposed method, typed targets and supported
   operations, the caster's actual domain knowledge, relevant observed facts,
   local world rules, and the history of similar coincidences. Separate proposed
   narrative from established world facts.
2. Reuse a versioned ruling for the same method and relevant circumstances where
   possible. For a new combination, return required domains/ranks, delivery,
   applicable scale rules, required circumstances, appearance classification,
   bounded discretionary modifiers, a rationale and evidence identifiers.
3. Validate the ruling against the permission matrix, supported operations and
   character capability. Ruling an effect permissible cannot create an operation
   handler that the engine lacks. Return unsupported or unresolved when needed.
4. Determine actual operations and domain permissions before judging apparent
   coincidence. Use a hypothetical ordinary observer with available information,
   not knowledge of hidden world state; a plausible explanation cannot waive
   creation, movement or influence requirements. Evaluate the apparent causal
   chain, local conditions and relevant observers. An absent observer does not automatically make an overt
   effect subtle. Track repeated noticeable coincidences by scene and method;
   use a declared repetition policy, not a new arbitrary penalty each turn. Store
   visible plausibility separately from physically present witnesses, audience
   familiarity and location policy. The anniversary pp. 531-534 provides this
   design refinement; M20-20 supplies neutral witness eligibility and M20-07
   retains the witness-dependent strain schedule.
5. Freeze the ruling and world-state revision before dice or reserve spending.
   Calculate skill, costs, success thresholds, defense and strain through the
   existing rules. Save the ruling, policy version and result so replay/undo do
   not re-adjudicate the same attempt. Materially changed facts can reopen review.
6. Keep author overrides explicit and logged, and publish only the explanation
   that the player's knowledge permits. The provider may be rule-based or use
   a language model behind this interface; no hosted provider is selected here.

Validation cases must include equivalent requests with different wording,
unsupported creative proposals, different methods for the same outcome, claimed
facts contradicted by the world, changes in observer/location state, repeated
coincidences, and stable replay of an existing ruling.

### Spirit relationship adapter

Reuse `RpgDisposition`/`RpgSocialApproach` for attitudes and request boundaries,
and `RpgExpandedReactionEncounter`/`RpgExpandedReactionAttempt` for encounter
history and changed approaches. `RpgExpandedLoyalty` supplies patterns for durable
relationships and incident accounting, but its employer/pay semantics are not a
universal model of spirits. Add a spirit relationship adapter with identity,
familiarity, attitude, promises, fulfilled/broken obligations and relevant history.

Map spirit strength and relationship into a documented calling requirement.
Keep success at making contact separate from willingness to appear or perform a
service; a favorable attitude cannot waive domain requirements or explicit
refusal. Define the numeric mapping and tests before implementation. This is an
accepted adaptation of the source's power-and-relationship judgment, not a
published universal social-to-calling formula.

### Supplementary comparison source

The supplied anniversary rulebook is a separate comparison source,
`anniversary-2015` (private reference source ID `mage-20th-anniversary`). Use its explanations of effect construction, coincidence and
relationships as design evidence. Preserve the primary three-die rules and label
any imported concept as adapted. Its dice-pool successes, resource costs,
critical-failure rules and domain prerequisites are not interchangeable with
`freeform-1994`. The initial targeted comparison is recorded in the source audit;
this is not a complete import or audit of the new book.

### M20 decision register — 26 October 2026

The user has completed the decision batches for the targeted M20 resource and
casting comparison, through M20-32 and its subdecisions. These are adopted
extension policies, not amendments to either published source or a full audit
of every M20 rule. No question from those batches remains unanswered. Separate
host-adapter, transaction and implementation work remains listed below.

| ID | Adopted ruling | Scope |
| --- | --- | --- |
| M20-01 | Retain separate domain skills and the host's 3d6 roll. | Use the lowest involved domain skill and the existing additional-domain penalty. Do not replace these with one general casting skill. |
| M20-02 | Require power rank 3 to absorb portable stored reserve. | Adopts the anniversary prerequisite in place of the earlier rank-1 consumption permission. Storage, throughput and whole-portion consumption rules otherwise remain unchanged; this does not raise ordinary receiving/storage or source meditation prerequisites. |
| M20-03 | Omit spendable determination initially. | Do not add a temporary determination pool or treat Will/fatigue as its equivalent. Later ritual or backlash options requiring such expenditure need a separately approved replacement or omission. |
| M20-04 | Retain +2 effective casting skill per reserve point spent. | Retain the channel-based per-turn expenditure limit. Do not adopt the proposed +1-per-point, maximum-+3 reserve bonus. M20-22 separately retains individual limits without an aggregate cap. |
| M20-05 | Permit power 5 to remove the caster's accumulated strain at one reserve per strain point. | Requires a successful working and actual reserve expenditure. This deliberately adds an internal-removal permission beyond the earlier external-manifestation example; it grants neither automatic casting success nor an exemption from applicable casting costs/consequences. |
| M20-06 | Permit weekly natural recovery only below five strain. | Remove one point per completed week while strain remains below five and the caster uses no magic except personal rank-1 perception. Disallowed casting or reaching five resets the recovery interval. Do not enable the optional monthly recovery for totals of 5–9. |
| M20-07 | Retain the GURPS strain-gain schedule. | Preserve the table below, including witness-dependent gains and failed-roll margins. Do not substitute M20's default or optional Revised schedule. |
| M20-08 | Adapt M20's backlash consequence bands. | Injury scaling, lasting strain, outward blasts and the complete blast adapter are adopted through M20-08a–d. Preserve the already-adopted group checks and voluntary complication batches. |
| M20-08a | Use scaled host injury. | Bruising causes `ceil(D/2)` HP, injury D HP and severe injury `2*D` HP, where D is backlash strength. Preserve the current protection and magical-healing restrictions. These are adopted conversion coefficients requiring playtesting, not published equivalences. |
| M20-08b | Include lasting strain. | It occupies reserve capacity and contributes to backlash rolls, but ordinary discharge, weekly recovery and the ordinary power-5 removal working cannot clear it. Removal requires a separately authored resolution. |
| M20-08c | Include outward blasts for physical backlash of strength 10+. | Only a selected physical-injury branch produces a blast. Use the adopted M20-08d distance, cover and defense procedure below. |
| M20-08d | Adopt the full blast adapter, including reactive diving. | Fixed collateral damage falls with distance; authored cover and torso armor protect bystanders. Eligible targets may dive at Dodge +3 to change exposure. Apply internal injury to the caster once; no automatic fragmentation or ignition. Details below. |
| M20-09 | Omit voluntary backlash postponement initially. | Neither temporary determination nor the proposed fatigue substitute may be spent to delay an impending backlash. |
| M20-10 | Limit initiated effect casting to one roll per normal world combat turn. | Extra actions from accelerated time do not grant extra castings. The reserve-assistance channel limit uses the same world-turn clock. Countering is a separate defensive procedure. |
| M20-11 | Penalize casting for ongoing effects requiring active concentration only. | Apply `-floor(N/2)` for N already-running effects requiring active attention. Mere duration, waiting triggers and anchored effects do not count; active duration extension does. Keep existing distraction rules as a separate procedure. |
| M20-12 | Permit declared partial results on eligible operations. | A successful casting roll with insufficient declared scale may produce the smaller result specified before rolling. Binary/indivisible effects stay all-or-nothing; failed rolls produce no partial effect. Permissions and defenses still apply. |
| M20-13 | Permit a bounded ordinary retry sequence. | At most three attempts at the same goal: initial, then additional -1 and -2 skill. Each incurs usual time, spending and strain; margins do not accumulate. Critical failure ends the sequence. A material change is required to reopen it; specific domain retry locks still override. |
| M20-14 | Include optional bounded extended rituals in the initial extension. | Accumulate progress toward one declared effect with finite attempts, interruptions, endurance and provisional strain. M20-14a–j settles roll limits, timing, casting failure, progress, provisional pressure, endurance, interruptions, pauses, restarting and simultaneous effects. Specified ledger interactions remain pending. No determination resource is added. |
| M20-14a | Limit a ritual to `3 + lead mastery` rolls. | Count failed rolls. Helpers and pauses do not refresh the limit. This is a chosen host bound, not the source's differently scaled Willpower-plus-Arete calculation. |
| M20-14b | Use three ritual timing categories. | Each roll takes five minutes for a brief working, one hour for a ceremony or five hours for a major working. The operation or virtual referee fixes the category from declared scope/method before starting; the player cannot simply select the fastest interval. |
| M20-14c | End the ritual immediately on a critical casting failure. | An ordinary failure contributes no progress, uses an attempt and adds a cumulative -1 to later casting rolls. There is no critical-failure recovery through fatigue, determination or banked progress. |
| M20-14d | Accumulate successful margins as ritual progress. | Count an exact successful roll as one. For cooperation, aggregate raw successful margins first and apply the minimum once per group roll; an all-failure group adds zero. Failed rolls add nothing. Declare thresholds and permitted partial outcomes first; apply the resulting effect once at successful termination, never on a critical failure. |
| M20-14e | Apply provisional ritual strain immediately, without reserve refunds. | Normal strain gains apply on each casting roll. Before each roll after the first, add one provisional point; it occupies reserve capacity and contributes to backlash immediately. Successful full or permitted partial completion clears only remaining provisional points; all other endings convert the remainder into ordinary temporary strain. Clearing provisional points never restores displaced reserve. |
| M20-14f | Use HT-based ritual endurance checks. | Permit `max(1, floor(HT/3))` hours of uninterrupted work, then check HT to undertake each further hour at cumulative modifiers 0, -1, -2, etc. Any failed endurance check ends the ritual from exhaustion, not as a critical casting failure. No separate flat ritual fatigue-per-hour charge is added. |
| M20-14g | Allow a Will-3 check for forced ritual interruptions. | Injury, active defense, knockdown or comparable disruption requires the check. Success continues; failure ends the ritual without becoming a critical casting failure. Stun, unconsciousness or destruction of indispensable setup ends it automatically. This adapts the host concentration procedure. |
| M20-14h | Allow controlled pauses in major workings. | Pause only between completed rolls, for at most 48 hours, with setup undisturbed. Resume using the lowest required domain skill without casting bonuses, at -1 per earlier pause (first resumption 0, second -1). Failure ends the ritual. Progress, remaining rolls, casting-failure penalties and provisional strain persist. Only full normal sleep resets endurance; no currency payment is required. Brief workings and ceremonies remain uninterrupted. |
| M20-14i | Count each whole ritual as one ordinary goal attempt. | After an ordinary unsuccessful ending, a fresh ritual may use the next slot in the three-attempt sequence. Its -1 or -2 applies to every casting roll. Restart with zero progress and a fresh ritual roll allowance, retaining incurred costs and strain. A critical casting failure ends the whole sequence. |
| M20-14j | Allow one additional active effect during a ritual. | Apply -1 to ritual casting while maintaining it. Personal rank-1 perception is exempt from this extra restriction; mere duration, anchors and waiting triggers do not count. Exclude the additional effect from the ordinary concentration count to avoid duplicate penalties. Required ritual activity must remain feasible, and the normal world-turn casting limit still applies. |
| M20-15 | Require relevant mundane training for skill-dependent practices. | A practice dependent on an ordinary skill requires training in it. Any higher minimum must be explicitly authored for that practice. Practices without a meaningful mundane skill require none. This does not equate source ability dots with host skill scores. |
| M20-16 | Include one bounded mundane preparation check per cast or whole ritual. | Success gives +1 to the next casting roll, critical success +2, failure 0, critical failure -1. For rituals, apply it only to the first casting roll. Preparation takes authored time of at least one normal turn, cannot be rerolled within that casting attempt, and cannot benefit from magic or preparation bonuses. These coefficients are host conversion choices. |
| M20-17 | Use a bounded shared scene counter for conspicuous coincidences. | Count successful conspicuous coincidences across casters. First three: no repetition penalty; fourth/fifth: -1; sixth/seventh: -2; eighth onward: -3. Exclude hidden personal effects and unobtrusive perception. Reset only on a material scene change recorded by the virtual referee. Replace the older repetition modifier rather than stacking it. |
| M20-18 | Use authored local practice profiles with +1/0/-1 casting modifiers. | Accepted practices give +1, neutral 0, rejected -1. Overlapping profiles resolve to one local modifier. Profiles inform coincidence assessment but do not automatically make matching effects subtle or waive permissions, barriers or world domain ratings. |
| M20-19 | Keep casting rolls initially, including routine magic. | Do not import the optional automatic-success shortcut for familiar minor coincidences. Preparation, margins and critical results continue through the ordinary casting procedure. |
| M20-20 | Require physical presence for heightened-risk witnesses. | The observer must be present, able to perceive the working, and have authored familiarity/beliefs that do not accommodate that kind of magic. Cameras, livestream viewers and later recordings do not increase casting strain. Friendship alone grants no exemption; use individual traits rather than setting categories. Discovery can still have story consequences. |
| M20-21 | Retain optional paid formula improvements. | A known formula costs no points at +0; +1/+2/+3 improvements cost 1/2/4 points. Retain its special skill ceiling and fixed casting time. There is no numerical limit on known formulas. Learning/access conditions remain separate from buying improvement. |
| M20-22 | Keep individual modifier limits without an aggregate cap. | Preserve per-rule spending, bonus and penalty limits, including channel throughput, preparation/local bounds and cumulative ritual penalties. Existing learned-skill ceilings still apply where specified. Do not import the anniversary net three-step limit. |
| M20-23 | Retain doubling time for +1 on ordinary improvised casting only. | Double the required casting time for +1 skill; further time gives no larger bonus. Formulas keep fixed times, and extended rituals retain their agreed intervals without an automatic extra-time bonus. Do not adopt the proposed +1/+2/+3 time ladder. |
| M20-24 | Use staged familiarity penalties of -2/-1/0. | An unfamiliar but compatible practice or tool imposes -2; an authored familiarization milestone reduces it to -1, and full familiarization removes it. Apply one familiarity penalty per cast, not per component. Milestones are authored or recorded virtual-referee rulings, not an automatic attempt count. Missing required equipment, training or permissions still blocks casting. |
| M20-25 | Use authored formula-learning conditions. | Record knowledge when a teacher, source or demonstrated practice satisfies an authored learning condition. Require compatible available methods and permissions, applying M20-24 familiarity where relevant. No universal additional learning/research roll is required; purchased improvement remains separate. |
| M20-26 | Include one personal tool bonus, increased for an explicitly bound tool. | Each caster may designate one personal tool for one chosen domain through an authored training/story milestone. Compatible workings involving that domain gain +1; if the tool is explicitly bound and cannot be replaced by ordinary shopping, gain +2 total instead. Multiple tool bonuses do not stack. |
| M20-27 | Retain half-cost rank relearning after losing a bound tool. | Dependent domain use is blocked until recovery, sufficient mastery exemption, or replacement through relearning. Relearn up to the previous rank at half the normal character-point cost; subsequent advancement returns to normal cost. Do not adopt free authored rebinding or M20's permanent destruction consequences. M20-27a–b settles investment retention and replacement bonus eligibility; cumulative half-cost accounting is specified below. |
| M20-27a | Preserve existing domain-skill and formula investment during rank restoration. | Only restored ranks determine which effects a replacement can support. Use retained trained skill with its normal mastery ceiling for eligible workings. Charge additional points for rank restoration only, not skill or formula repurchase. |
| M20-27b | Allow a properly rebound replacement to regain +2. | Require the authored binding milestone and the relevant restored ranks. The caster need not restore every former rank before receiving the bonus on an eligible working. Ordinary purchase alone grants no designation or bonus. |
| M20-28 | Omit emergency casting without required practice/tools. | Use another valid method where permitted, or earn the existing mastery exemption. Neither determination nor the proposed fatigue substitute can bypass missing requirements or bound-tool loss. |
| M20-29 | Retain fully qualified group casting initially. | Every participating caster must possess all domain ranks needed for the effect. Roll participants individually and combine successful margins under the settled group critical/strain rules. Do not add broader rank-one participation or a separate lesser-assistant contribution mode. Ordinary preparation and practical help remain available. |
| M20-30 | Retain declared scope despite surplus success. | Extra margin does not automatically add damage, targets or duration beyond the declaration. Preserve the already-retained critical-result rules. Do not introduce the proposed authored surplus-result tiers or post-roll rewards. |
| M20-31 | Handle symbolism through existing practice, local and plausibility rules. | Do not add a separate generic significant-symbol casting bonus. Meaningful symbols can inform the existing adjudication but cannot waive domain permissions or make an implausible effect subtle merely by being named. |
| M20-32 | Keep all strain above twenty without a new threshold trigger. | Reserve capacity remains zero at totals of twenty or more. Preserve existing critical-failure and authored discretionary backlash triggers; crossing twenty alone requires no extra check or automatic explosion. Never clamp away earned strain. |

### M20-08 adopted consequence mapping

Evidence: anniversary pp. 548-549 and 551-552. Retain the current three-die
discharge procedure and call its positive release result D (backlash strength).
With ordinary strain this is the discharged amount. With lasting strain,
the roll uses total strain and D still selects severity, but removal is
capped at the temporary points available; permanent points remain. A zero
release result means no band consequence, distinct from having no removable
temporary points. The source's separate dice-pool botch
result (harmless total discharge) is not imported by this adaptation. Critical
handling remains part of the host discharge specification.

| D | Adopted consequence structure, preserving the M20 combinations |
| --- | --- |
| 1–5 | Bruising plus a trivial complication. |
| 6–10 | Bruising or a minor complication. |
| 11–15 | Injury, a significant complication, an entity encounter, or mild authored distorted perception. |
| 16–20 | Injury plus one lasting strain point, or two authored outcomes chosen from a severe complication, entity encounter, moderate distorted perception and confinement. |
| 21+ | Severe injury plus one outcome: two lasting strain points, a drastic complication, an entity encounter, severe distorted perception, or confinement. |

The author selects an eligible outcome or supplies a versioned selection policy;
this is not permission to generate distorted perception or a prison world at
runtime. Configured tables must have supported authored outcomes. Voluntary
complication purchases remain a separate procedure with their accepted batch
rules; a mandatory band consequence does not spend strain a second time.

The adopted host injury conversion is `ceil(D/2)` HP for bruising, D HP for
injury and `2*D` HP for severe injury. These are deliberate starting coefficients
for playtesting, not an asserted equivalence between Storyteller and GURPS dice.
This replaces the earlier one-d6-per-discharged-point branch. Retain the
existing backlash protection and magical-healing restrictions. Integrate through the host health
pipeline; do not directly overwrite HP or bypass wound/death checks.

Track ordinary temporary strain T and lasting strain L separately. With no
active provisional ritual strain, total P = T + L; during a ritual, include its
live provisional component R as well (M20-14e), so P = T + L + R. P occupies the
shared reserve track and is used for the backlash roll. Its release result D
sets severity. Release cannot remove L; absent R it removes `min(D,T)` from T.
With R present, debit allocation between releasable T and R must be defined in
the transaction specification so later cleanup cannot remove the same point
twice. Newly awarded lasting points are added after release in the same
consequence transaction. Ordinary strain gains add to T.

M20-08b qualifies M20-05/M20-06: power-5 removal and weekly recovery cannot
reduce L. Absent an active ritual, they reduce only T; interactions with live R
require the ritual ledger specification. Weekly eligibility uses total P below five. Voluntary complication spending
also cannot debit L: retain the accepted snapshot thresholds based on P, but
validate expenditure against available T. If the required batch cannot be paid,
it is unavailable; do not erase protected points or silently relax its minimum.
A named authored resolution is required to remove L.

Physical backlash with D at least ten also causes an outward blast. The caster
receives the adopted internal injury once; the blast is not a second hit on the
same caster. Use the adopted host blast adapter below. No runtime blast
handler has been implemented by this planning work.

### M20-08d adopted blast adapter

Evidence: anniversary p. 552 requires the outward blast; `full-2008` B414
supplies inverse-distance collateral damage and torso armor, and B377 supplies
diving for cover. The following is a host conversion, not a direct transcription
of either complete explosion system:

- Let B be the adopted internal injury amount before the caster's protection.
  For another target at distance r yards, use
  `floor(B / (3 * max(1, r)))` basic collateral damage. Use actual distance with
  a one-yard minimum for this calculation. Do not guess distances from room
  membership. Normal-air falloff is the initial authored default; different
  media require an explicit location policy.
- Subtract authored intervening cover DR and the target's applicable torso DR,
  never below zero. Apply the result as crushing injury with a one-times wound
  multiplier through the host health pipeline. This explicit cover-DR adapter
  is a project choice; the source's ranged-cover rules alone are not a universal
  blast simulation. Cover is not automatically indestructible or total immunity.
- An aware, eligible target may attempt Dodge +3 to dive one legal step to cover
  or away. On success, use the new position/cover for blast exposure; on failure,
  resolve exposure before that step. A successful dodge in open ground does not
  erase the blast. The caster cannot dodge the internal injury.
- The fallout is calculated from fixed B rather than new damage dice. Stop
  injury where the rounded damage is zero. Do not infer a separate radius from
  an invented damage-dice count. No additional internal-explosion vitals
  multiplier applies; no automatic fragmentation or ignition is introduced.
  Those require separately authored material/secondary-effect support.
- Preserve the adopted backlash healing restriction for its injury. Do not
  copy the caster's internal armor bypass to bystanders: theirs is an external
  blast. Snapshot positions and barriers for each blast, apply each target once,
  and retain receipt/undo data. Objects require their own supported damage rules.

Example: strength D=12 on the injury branch gives B=12: an unprotected bystander
one yard away takes 4 HP, two yards away takes 2 HP, and four yards away takes
1 HP. A one-yard bystander with 3 torso DR takes 1 HP. The caster's pre-protection
internal injury remains 12 HP. These are adopted host conversion values, not
a claim of probability equivalence with either source.

### M20-12/M20-13 partial outcomes and ordinary retry state

Store the full requested outcome and any allowed partial outcome before rolling.
An operation must explicitly support the partial form, with valid targets,
permissions, scale and delivery. The virtual referee cannot improvise a benefit
from a failed roll or waive a binary requirement. A partial result remains
subject to its own duration, defenses and reversal rules.

Record an attempt sequence by substantive goal and relevant circumstances, with
an ordinal of one through three and modifiers 0, -1 and -2. A partial result is
not automatically a material change that grants unlimited attempts at the same
goal. Ordinary retries do not bank or add casting margins. Any already-delivered
world change must be accounted for without applying its benefit twice. A new
materially changed approach may reopen assessment through the virtual referee's
versioned ruling procedure; changing only the description cannot reset the count.

The general retry rule cannot bypass thought-probing/possession sleep locks,
healing opportunity limits, or other operation-specific restrictions. Extended
rituals use the approved progress policy below. Each whole ritual consumes one
ordinary goal-attempt slot under M20-14i; its internal casting checks do not
consume extra goal slots. An exhausted sequence still requires a material change.

### M20-14 adopted ritual framework — remaining details pending

Store the declared effect, ruling version, lead caster, fixed mastery-based
attempt allowance and assigned timing category at the start. Maximum rolls are
`3 + lead mastery`; helpers, elapsed time and pauses cannot refill that allowance.
The assigned intervals are five minutes, one hour and five hours per roll for
brief, ceremonial and major workings respectively. These are host choices
inspired by the anniversary procedure, not its exact optional timing wording.
Practices must remain feasible for the assigned interval; this does not erase
separately declared physical preparation requirements.

An ordinary casting failure consumes its attempt, adds no progress and imposes
an additional cumulative -1 on subsequent ritual casting rolls. Normal casting
eligibility checks still apply; an unusable effective score cannot be rolled
without a permitted change to modifiers. A critical casting failure immediately
ends the ritual. No recovery payment or extra rescue roll is enabled. Preserve
normal critical-failure consequences and the agreed group failure precedence.
Under M20-14f, a failed endurance check ends work from exhaustion rather than
becoming a casting critical failure. M20-14g likewise treats an interruption
check as a concentration check, not a casting roll.

Each successful casting check adds its raw margin to ritual progress, with a
minimum of one for an exact success. A cooperative step first sums actually
successful raw margins; then apply the minimum once to the combined successful
result, not once per participant. Require at least one successful contributor;
ordinary failures add zero and any critical failure terminates the ritual under
the agreed group rule. The effect's full threshold and any permitted partial
threshold/outcome must be validated and frozen before the first check. Apply
one effect at successful termination, never intermediate copies after every
roll. A critical failure never delivers a partial effect. Do not manufacture
permissions, unsupported operations or free changes to declared scope from a
large accumulated total.

Normal casting strain applies to every ritual casting roll. Before committing
each roll after the first, add one provisional strain point. Keep this tagged
as R for the active ritual: it immediately contributes to total P for both
capacity and backlash. On full or permitted partial success, clear only the
remaining R tagged to that ritual; preserve ordinary gains and lasting strain.
On every other ending, convert the remaining R to ordinary T without adding it
twice or re-displacing reserve. Removing R after success does not refund reserve
already overwritten. A backlash that already consumed provisional points must
not cause them to be subtracted again at completion.

Use `max(1, floor(HT/3))` hours as the uninterrupted endurance allowance. Before
undertaking each additional hour, check HT with penalties 0, -1, -2, and so on.
Failure ends the ritual from exhaustion; it does not itself count as a critical
casting failure. Resolve the unfinished ritual's remaining provisional strain
under M20-14e. No flat ritual fatigue-per-hour cost is added by this rule; ordinary
host injury, fatigue, sleep and environmental rules remain relevant. Endurance
checks use elapsed work time, not the number of casting rolls: a five-hour roll
can require checks before its casting roll is reached.

When injury, an active defense, knockdown or comparable disruption threatens
an active ritual, check Will-3. Success preserves the ritual; failure ends it
without becoming a critical casting failure. Stun, unconsciousness or destruction
of an indispensable part of the setup ends it automatically. This is the chosen
adaptation of Basic's concentration procedure, rather than M20's interruption
and recovery sequence. Failed termination still resolves provisional strain.

Only major workings permit planned pauses, between completed casting rolls.
Each pause may last at most 48 hours and requires undisturbed setup. Resume with
the lowest required domain skill, without casting bonuses, at -1 per earlier
pause: first resumption 0, second -1, and so on. Failed resumption ends the
ritual. Preserve progress, remaining casting rolls, accumulated casting-failure
penalties and provisional strain. A pause does not replenish attempts or erase
risk; only a full normal sleep resets endurance. No currency payment is required.
Brief workings and ceremonies cannot use this planned-pause procedure.

A whole ritual consumes one slot in M20-13's three-attempt sequence for the same
goal. Its internal casting rolls consume only its own finite ritual allowance.
Following an ordinary unsuccessful ending, a new ritual may use the next goal
slot; apply that slot's -1 or -2 to every casting roll, in addition to any
within-ritual failure penalties. Restart with zero progress and a fresh
`3 + lead mastery` allowance, retaining incurred costs and strain. A critical
casting failure ends the whole goal sequence. Pausing and resuming the same
ritual is not a restart and grants no fresh allowance.

One additional effect requiring active attention may accompany a ritual. While
it is maintained, apply -1 to ritual casting. Personal rank-1 perception is
exempt from this extra restriction. Mere lasting duration, anchored effects and
waiting triggers do not count. Remove the one additionally maintained effect
from M20-11's ordinary concentration count when applying the ritual-specific
penalty; do not charge twice for the same effect. This does not exempt other
qualifying effects from M20-11. The world-turn casting limit still applies,
and the caster must remain able to perform the required ritual activity.

The transaction specification must also fix group allocation of provisional
strain, release/voluntary-removal bucket order, declaration of full/partial
thresholds and critical range/duration handling during accumulation. These
integration details are not resolved merely by declaring a ritual clock.

### M20-15/M20-16 mundane practice and preparation

A practice that depends on an ordinary skill requires training in that skill;
merely having a default score does not establish training. Any higher minimum
must be explicitly authored for the practice, rather than inferred by converting
source ability dots into host scores. A practice with no meaningful mundane
skill has no invented skill prerequisite. The implementation must identify the
host's training evidence separately from temporary bonuses to effective skill.

Permit one relevant mundane preparation check before each cast or whole ritual.
Use the host's ordinary success categories: success +1, critical success +2,
failure no bonus, critical failure -1 to the next casting roll. For a ritual,
consume the result on its first casting roll only, not every accumulated-progress
roll. A preparation critical failure is not itself a critical casting failure.
The chosen coefficients and one-roll duration are explicit conversion rules.

Preparation takes an authored amount of time, at least one normal world turn.
It cannot be repeated within the same casting attempt to seek a better result.
Magic cannot enhance the preparation check, and preparation bonuses cannot
assist other preparation checks. Keep this check separate from the original
extra-time casting modifier; M20-22 retains individual limits without a global
modifier cap. Preparation grants no missing domain permission or practice training.

### M20-17–19 scene repetition, local conditions and routine casting

Track successful, conspicuous coincidences in a shared scene ledger, regardless
of caster. Before an eligible cast, use its prospective position among such
successes: positions 1–3 incur no repetition penalty, 4–5 incur -1, 6–7 incur
-2, and 8 onward incur -3. Increment only when a successful conspicuous
coincidence actually occurs. Failed attempts do not advance the counter, though
their ordinary retry penalties and consequences still apply. Hidden personal
effects and unobtrusive perception neither increment the counter nor receive
this penalty. Record a reset only when the virtual referee identifies a material
scene change; renaming the scene or changing casters is insufficient. This
replaces the older repetition modifier. The schedule and cap are chosen host
values, not a claim of direct probability equivalence.

Locations may have authored profiles of accepted, neutral and rejected practices,
contributing one local casting modifier of +1, 0 or -1. Resolve overlapping
profiles to one modifier rather than adding each profile's value. The evaluator
must record the applicable profile and resolution in its ruling; profile
precedence/conflict handling still needs deterministic implementation. Local
acceptance informs apparent plausibility but does not automatically classify
an effect as subtle. Domain permissions, barriers and otherworld domain ratings
remain independent checks. Profiles do not grant characters an unapproved way
to rewrite local conditions merely by declaring that a practice is accepted.

Routine familiar magic still uses casting rolls. Do not import M20's optional
automatic-success shortcut or use mundane automatic-success procedures to bypass
the magic roll. Existing practice requirements, preparation, margins and critical
outcomes continue to apply.

### M20-20–22 witnesses, formulas and modifier limits

A heightened-risk witness must be physically present, able to perceive the
working, and have authored familiarity or beliefs that do not accommodate that
kind of magic. Evaluate individual traits rather than named factions, species
or supernatural categories. Friendship alone is not an exemption. Cameras,
livestream audiences and people viewing later recordings do not increase the
casting strain; recorded exposure may still produce ordinary story consequences.
Keep this eligibility separate from whether the effect is subtle or overt, and
use the retained M20-07 strain table once eligibility is known. Record the
relevant observer state in the casting assessment for stable replay.

Known formulas have no numerical count limit. Default use at +0 costs no points;
optional +1/+2/+3 improvements cost 1/2/4 points. They retain their fixed casting
time and special ceiling: the purchased improvement may exceed the ordinary
mastery-based skill cap, but remains at most default +3. Acquiring knowledge of
a formula and purchasing a numerical improvement are distinct actions. The
learning/access procedure uses authored conditions under M20-25.

Apply each casting modifier under its own eligibility, limit and stacking rules;
do not clamp their combined adjustment to a global range. In particular, reserve
assistance remains +2 per point within channel throughput, preparation and local
modifiers keep their adopted bounds, and ritual failure penalties may continue
to accumulate. Existing ceilings on learned domain skills still apply before
casting modifiers where specified. This does not import M20's difficulty floor,
ceiling or conversion of excess difficulty into extra required successes.

### M20-23–25 time, familiarity and learning

Ordinary improvised casting may double its required time for +1 effective skill,
with no additional bonus for waiting longer. This is separate from the mundane
preparation check and does not waive the required practice's minimum time.
Formulas retain their fixed casting times, without haste or extra-time changes.
Extended rituals use the already-adopted intervals; those intervals do not
supply an automatic extra-time casting bonus. Do not import the proposed
multiplicative time ladder or M20's larger extra-preparation benefit.

A compatible but unfamiliar practice or tool imposes -2 on casting. An authored
familiarization milestone reduces this to -1; full familiarization removes it.
Apply one familiarity penalty per cast, not one for every unfamiliar component.
The implementation must define how multiple components' familiarity states
resolve to that one penalty, and persist the supporting milestones and ruling
versions. Familiarization requires authored conditions or a recorded virtual
referee ruling, not merely a fixed number of attempts. Missing required equipment,
training or domain permissions still prevents the cast; a familiarity penalty
cannot buy eligibility or erase a required dependency.

Record formula knowledge when an authored learning condition is met through a
teacher, a source, or demonstrated practice. Learning requires compatible
available methods and permissions; apply relevant familiarity penalties when
using the formula. There is no universal extra learning/research check. An
authored learning condition can involve a task with its own ordinary checks,
but those do not create an implicit general formula-learning minigame. Record
the knowledge separately from optional paid improvement and preserve the
unlimited-count policy for known formulas.

### M20-26–28 personal tools, bound-tool loss and missing requirements

Each caster may designate one personal tool tied to one chosen domain through
an authored training or story milestone. A compatible working involving that
domain gains +1 casting skill when using the tool. If the tool is explicitly
bound and cannot be replaced by ordinary shopping, the total is +2 instead.
Multiple tools do not stack these bonuses; mere possession or purchase does
not establish designation. These are chosen host coefficients inspired by the
anniversary instrument categories, without requiring a faction-linked domain.

A lost bound tool blocks use of its dependent domains until it is recovered,
made unnecessary by the existing mastery exemption, or replaced through
relearning. Retain the GURPS procedure: relearning to the former rank costs
half the usual character points, then normal advancement prices resume.
An authored story milestone alone does not waive that payment. Do not import
M20's permanent destruction penalty or substitute the proposed free rebinding
procedure. Investment retention, cumulative cost accounting and replacement
bonus eligibility follow the policies below; they are not new ad hoc referee
rulings per loss.

Accounting defaults selected after the source/host follow-up (conversion rulings,
not a claim that the old book specifies every detail): retain the former rank as
a restoration ceiling and track restored access separately. If C(r) is the
ordinary cumulative rank price under the character's existing price policy,
cumulative restoration cost is `ceil(C(r)/2)`; charge the difference between
restored levels. For practice-dependent totals 5/25/45/65/90, restoration totals
are 3/13/23/33/45, not 46 from rounding every increment separately. Advancement
above the former maximum uses normal incremental rank prices. Recovering the
original tool or earning the applicable mastery exemption restores former access
without refunding replacement training already paid for. Preserve replacement
training records separately from which tool currently supplies access.

Under M20-27a, preserve existing domain-skill and formula investment. Restored
ranks gate the operations available through a replacement; eligible workings use
the retained skill with its normal mastery ceiling. Additional expenditure pays
for rank restoration only. Under M20-27b, a replacement that satisfies the
authored binding milestone can regain the +2 bonus for workings supported by
its restored ranks. It need not await restoration of every formerly known rank.
Ordinary shopping alone grants neither designation nor bonus. Apply the same
single-tool, chosen-domain and compatibility limits as M20-26.

There is no emergency resource payment to bypass a required practice or tool.
Where permitted, a caster may use another valid method or an earned mastery
exemption; ordinary missing-equipment/training/permission checks still apply.
Do not add a determination pool, spend fatigue as its substitute, or use
unfamiliarity penalties to circumvent an unmet requirement. A bound-tool
restriction uses its specific recovery procedure, not ordinary substitution.

### M20-29 group qualifications

Every participating caster must have all domain ranks required by the declared
effect, including currently usable access where a tool dependency applies.
Roll each participant individually and combine actual successful margins under
the previously adopted group rules. Preserve group critical-failure precedence,
quantity-specific minimums, shared strain and per-participant backlash checks.
Do not import M20's broader rank-one participation or a separate lesser-assistant
mode with automatic contributions. Mundane preparation and practical assistance
remain available under their own rules; they do not turn an unqualified helper
into a contributing group caster or generate free group margin.

### M20-30–32 declared results, symbols and strain overflow

Retain the declared effect when the roll exceeds its required scale. Surplus
margin cannot automatically add targets, damage or duration beyond the
validated declaration. The adopted critical-result rules remain exceptions
within their stated scope; this does not introduce general exceptional-result
rewards. Declared partial results under M20-12 remain available, but no new
authored surplus-result tier system is enabled.

Symbolic significance is evaluated through the existing practice requirements,
local profiles and virtual-referee plausibility procedure. It grants no separate
generic numerical bonus. It cannot substitute for domain permissions or make
an implausible effect subtle merely through description. Existing personal/bound
tool bonuses continue under their own eligibility and non-stacking rules.

Record all earned strain, including totals above twenty. With total strain P,
reserve capacity remains `max(0, 20-P)`, so it is zero at twenty and beyond.
The total continues to include ordinary temporary, lasting and live provisional
strain for the already-adopted procedures. Do not discard overflow, wrap the
track, or invent a second overflow pool. Crossing twenty does not itself trigger
a mandatory backlash check or explosion. Existing critical-failure triggers
and authored discretionary triggers remain, as do the adopted severity bands
and physical-branch blast conditions when a backlash actually occurs.

### Comparison decisions complete; integration still outstanding

The targeted resource/casting comparison's user choices are now recorded through
M20-32. The source audit retains their provenance and the alternatives that were
not selected. This closes that decision round, not the full extension design or
implementation. Remaining work includes:

- The host resistance/countering adapter (R1–R4/R6): awareness and waiver,
  capped contest margins, critical results, counter timing and resource receipts.
- Ritual transactions: allocation of provisional strain in groups, debit order
  between temporary/provisional buckets, removal during a ritual, and critical
  range/duration handling during accumulated progress.
- Composition of reserve consumption, receiving and transfer; declaration and
  validation of scale thresholds; deterministic handling of overlapping local
  profiles and multiple unfamiliar components.
- Operation-specific permissions, delivery, cancellation and supported coverage;
  item access/economy; optional world-rating and internal-confrontation gaps.
- Authored consequences, spirit relationship integration, validation and runtime
  implementation. Spirit-vessel construction remains expressly deferred.

Resource accounting must continue to distinguish reserve balance, capacity,
throughput, mandatory fuel and optional assistance. Do not reopen settled
choices merely because their persistence or transaction code is still unwritten.

## Language and setting removal

Use lowercase common nouns. A noun already in ordinary use need not receive an
invented replacement. Prefer “cast an effect” to a new name for casting, and
“a caster” to a named category of people. Capitalization in class names remains
the repository's programming convention, not an in-world title.

| Mechanical role | Public term | Meaning and boundary |
| --- | --- | --- |
| Overall magical development | mastery | Limits domain ranks and ordinary casting skill; not social rank. |
| Innate supply and spending rate | channel | Determines innate reserve and per-turn spending limit; no personified guide. |
| Area of knowledge | domain | Has a rank and separately purchased skill. |
| Spendable magical resource | reserve | Separate from the host's energy/fatigue pool. |
| Accumulated magical instability | strain | Displaces reserve and can cause consequences. |
| Plausibly ordinary appearance | subtle | An authored judgment of the effect in its circumstances. |
| Obviously impossible appearance | overt | Independent of whether anyone observes it. |
| Relevant observer | witness | An authored observer eligibility rule, not a supernatural caste. |
| Casting implement or activity | practice | A tool, gesture, song, preparation or exercise; not necessarily an object. |
| Learned, repeatable effect | formula | A fixed effect specification with separately purchased improvement. |
| Continuing supply location | source | Produces reserve according to explicit world time and ownership rules. |
| Portable supply | stored reserve | A consumable resource in an item. |
| Item with programmed effects | enchanted item | Each effect has its own casting rating. |
| Defensive cancellation | counter / dispel | Counter an incoming effect; dispel an existing effect where permitted. |
| Uncontrolled release of strain | backlash | A mechanical release plus authored consequences. |
| Chosen persistent consequence | complication | Has explicit duration and penalties; does not mint development points. |
| Advancement prerequisite | breakthrough | A completed authored milestone, without prescribed spiritual narrative. |
| Optional other-world travel | crossing / barrier / other world | Author-defined topology; no supplied map or cosmology. |
| Optional unreliable experience | distorted perception | Separate beliefs and observations from world truth. |

Remove faction memberships, compulsory enemies and secrets, supernatural social
titles, personality classifications, named beings, locations, sample characters
and setting history. Do not rename these into mechanically mandatory substitutes.
An author can supply schools, organizations and beliefs through ordinary game
data, but none is required for a character to cast.

Retain nine knowledge areas initially to avoid redesigning their interactions:

| Domain ID / label | Scope | Source description begins |
| --- | --- | --- |
| `space` / space | Position, distance and spatial connections | 97 |
| `chance-decay` / chance and decay | Probability, disorder and deterioration | 102 |
| `energy` / energy | Physical forces, heat, light and related phenomena | 105 |
| `life` / life | Living organisms | 109 |
| `matter` / matter | Nonliving substances | 112 |
| `mind` / mind | Thought, perception and mental activity | 115 |
| `power` / power | Raw magical supply and the basis of magical effects | 119 |
| `spirits` / spirits | Nonphysical beings and interactions across a barrier | 122 |
| `time` / time | Temporal perception and change | 125 |

“Chance and decay” deliberately preserves both halves of the source domain.
“Power” is knowledge; “reserve” is a spendable quantity. “Energy” concerns physical
phenomena and does not refer to the profile's fatigue field. Explain these three
distinctions once in the guide. Spirits and other worlds are optional author
content, without assumptions about religion or a universal afterlife.

Player-facing verbs can include **sense, reveal, hide, move, change, create,
destroy, heal, protect, bind, counter** and **dispel**. They describe intent, not
a universal rank ladder. “Create” does not mean rank 3 in every domain. A domain's
verified permissions and conjunction requirements determine legality.

## Mechanics to retain and adapt

### Character investment

Keep domain rank separate from trained skill. A character might know a difficult
operation but perform it unreliably. A formula improves a particular effect; it
never supplies missing knowledge.

1. **Retained:** mastery 1–10, domain ranks 1–5, and rank no greater than mastery.
   Ordinary domain skill is capped at `10 + mastery` through mastery 9; mastery
   10 removes that cap. Keep uncapped investment so advancement releases previously
   purchased ability. Source: pp. 44, 50.
2. **Adapted:** use an IQ-based `RpgExpandedSkill`, difficulty 3, no attribute or
   skill defaults, no wildcard and at least one invested point. Use the host's
   skill cost curve rather than a legacy Mental/Very Hard cost table. Apply the
   mastery cap before casting modifiers; do not cap the final modified roll.
3. **Retained as provisional prices:** mastery total costs are
   `15, 30, 45, 65, 85, 110, 135, 165, 200, 250`; channel costs 15 per level.
   Advancement pays the difference in total cost. The mastery-8 correction is
   essential. These prices need host-balance testing, not an assertion of parity.
4. **Adapted:** detach domain prices from faction identity. A character whose
   domains initially require practices uses total rank costs `5, 25, 45, 65, 90`;
   a character initially free of that requirement uses `10, 30, 50, 70, 95`.
   Select this policy at creation, not per attempt. Preserve progressive practice
   exemptions from mastery 2 onward; no retroactive refunds. Do not add a school
   discount or mandatory specialty. Source prices and correction: pp. 44, 50, 55.
5. **Retained:** a formula's +0/+1/+2/+3 improvement costs 0/1/2/4 points. Its
   default is the lowest relevant capped domain skill minus conjunction penalties.
   It may exceed the ordinary mastery cap, but cannot exceed default +3. Use a
   dedicated purchase calculation: `RpgExpandedTechnique` has a different curve
   and only one default basis. Source: pp. 88–89.
6. **Adapted:** no default 400-point campaign, mandatory character package, free
   immunity, affiliation disadvantage or automatic social standing. Use the
   author's ordinary creation budget, explicitly counting magic contributions.
   A suggested starting rank cap of 3 is configurable; initial strain is zero.
7. **Adapted:** mastery improvement requires both an authored breakthrough and
   sufficient unspent points. Use existing milestone receipts and the same point
   bank; purchasing never awards the milestone again. Source: pp. 132–133.

Some domain ranks require additional traits in the source. Time 1 requires a
separately purchased accurate-timekeeping trait (p. 125). Mind 1 can temporarily
grant selected mental benefits, but permanent benefits require point payment
(pp. 115–116). Record and convert each dependency before enabling that permission;
a rank purchase alone must not silently grant unpriced host traits.

### Casting and effect size

An effect specification records domains and minimum ranks, operation, targets,
sensing method, direct/indirect delivery, magnitude, range, duration, casting
time, required practice, reserve expenditure, and consequence handler.
Appearance and eligible witnesses come from world-state hooks. Player text may
express an intention but cannot certify its own legality, visibility or subtlety.

**Retained calculation**, pp. 83–89:

```text
base = minimum(capped trained skill in every required domain)
base -= number of additional domains
formula casting: add purchased formula improvement to that default
effective skill = base + applicable casting modifiers
roll = three dice; casting margin = effective skill - roll
```

Preserve the separate casting outcome and delivered effect outcome. Under
M20-12, passing a check with insufficient margin may produce the predeclared
smaller outcome only when that operation supports partial results. Otherwise
it produces no effect, and spent reserve is still lost. A failed casting roll
cannot produce a partial effect. Countering or resistance can also prevent
delivery after the casting check succeeded. None of these cases becomes
ordinary core “costly success.”

Retain the +2 per reserve spent, the channel spending limit per normal world combat turn,
extra-domain penalty, subtle bonus `floor(mastery / 2)`, source rating bonus,
appropriate personal connection bonus, and at most +1 for doubling casting time.
Formulas have fixed casting times and do not receive casting-time adjustments.
Normal casting takes one second, with practices potentially extending it.
Haste gives -1 or worse; instantaneous casting gives -3 or worse, with exact
penalties authored. Distraction first requires Will minus the distraction count;
failure applies that count as a casting penalty, capped at -5. Specific mental
abilities exempt ordinary distractions. Repeated-coincidence penalties remain
authored. M20-13 replaces the general changed-circumstances-only retry gate
(p. 88) with at most three attempts at the same goal: the initial attempt, then
retries at additional -1 and -2 skill. Each attempt incurs its normal time,
spending and strain; critical failure ends the sequence. After the limit or a
critical failure, a material change is required to reopen the attempt sequence.
Specific domain retry restrictions still take precedence. Rewording alone is
not a material change.

**Adopted M20-10/M20-11:** a caster may initiate at most one effect-casting roll
per normal world combat turn, even with accelerated actions. Countering remains
a separate defensive procedure. Optional reserve assistance uses the same
world-turn channel limit; acceleration cannot refresh it. Apply an additional
`-floor(N/2)` skill modifier for N already-running effects requiring active
attention: zero or one gives no penalty, two or three gives -1, four or five
gives -2. Do not count the new effect being attempted, mere remaining duration,
waiting triggers or effects anchored elsewhere. Actively extending an effect
counts. Store attention requirements explicitly; this is distinct from the
existing distraction check and its exemptions. These rules do not reduce a
longer practice's required casting time.

Use corrected duration bands: margin 0–1 gives 30 seconds; 2–3 gives 30 minutes;
4–5 gives one day; 6–7 gives one week; 8+ or a critical gives the permanent band.
This is a capability ceiling for a legal effect, not permission to create any
permanent change on a critical. An effect requesting less can use less. Record
that only range and duration have explicit critical rows; no universal critical
damage multiplier was found in the general tables.

Range, duration and magnitude must all meet the full declared requirements,
or the explicitly predeclared partial outcome under M20-12. Do not
invent a universal pool of successes to divide among them, but preserve explicit
exceptions: the mind 1 enhancement on pp. 115–116 allocates success separately
to its benefit and duration, reserving at least one point for duration. The
life 3 self-enhancement on p. 110 cannot become permanent through its duration
roll. The general range progression and the separate space range column need
distinct evaluators. The [source audit](freeform-magic-source-audit.md) now records
the complete general damage multipliers and mass, temperature, protection and
attribute guidelines from pp. 85-86 and 89. It also identifies effect-specific
damage and creation-mass overrides. Preserve raw margin separately from each
quantity's treatment of exact success. Legacy passive defense needs an explicit
conversion; it is not another name for host armor.

**Adapted:** retain the host's `rpgCheck` critical and automatic-failure behavior
for casting, and document the edition change. Scores below 3 are blocked before
spending. Handle special source procedures, such as rolling against small strain
totals, separately where `rpgCheck`'s minimum score would be inappropriate.

### Reserve, strain and consequences

Keep reserve separate from `profile.energy`, which already represents host
fatigue. Track one reserve total, channel rating, per-turn expenditure, strain
and supply receipts. Strain has ordinary temporary, lasting and live provisional
ritual components; their total
occupies capacity. Ordinary discharge and recovery cannot remove the lasting
component (M20-08b). Derive protected reserve as `min(reserve, channel)` and
transferable excess as `max(0, reserve - channel)`; no separate origin pools are
required. The shared nominal capacity is 20:
`available reserve capacity = max(0, 20 - strain)`. Added strain reduces reserve
to that capacity, first removing the transferable excess and then, if necessary,
the protected portion. Protection is against transfer, not against strain.
Acquiring reserve never erases strain. Preserve strain above 20 instead of
clamping it away; a severe-consequence policy remains to be specified. The
positional pool model is a documented conversion, supported by both sources.

Source pp. 44, 46–50, 78–80 distinguish innate replenishment, transferable supply
and periodic production. Direct PDF inspection of pp. 119–121 additionally
confirms power 1 for receiving/storing extra reserve, power 3 for transferring
existing supply, and power 5 for replenishing innate reserve. Creation does not
produce surplus transferable reserve. Innate reserve cannot be transferred.
Ordinary innate recovery at a supply location requires an eligible source, time
and a check, with channel and source limits. Power 5 provides a distinct magical
replenishment route (p. 121); do not impose the ordinary source-location procedure
on that effect. Resting to regain fatigue is not reserve recovery. The source
audit records recovery amounts, source-output bands, consumable supply and
power-1 receiving/power-3 transfer throughput. Interactions between these
throughput limits still need interpretation; reserve displacement is resolved.

**Adopted override M20-02:** absorbing portable stored reserve requires power 3,
following the anniversary source, rather than the earlier power-1 permission to
consume it. Receiving already extracted reserve and ordinary source meditation
retain their separate requirements. Storage and throughput limits still apply.

**Adopted M20-04:** optional reserve assistance retains +2 effective casting skill
per point spent, with the existing channel-based per-turn limit.

**Adopted additions M20-05/M20-06:** a successful power-5 working may spend one
reserve per point of the caster's temporary strain removed; lasting strain is
excluded by M20-08b. Small strain pools
also recover one point per completed eligible week: strain must remain below
five including lasting strain, and only personal rank-1 perception is permitted
during that interval. Recovery removes temporary points only.
Other casting or reaching five resets the interval. No monthly higher-pool
recovery is enabled. Persist the recovery interval and qualifying events; these
are separate from fatigue recovery and from voluntary complication expenditure.

Retain these strain gains from p. 86, keyed to the **casting roll**, not whether
the final effect reaches its target:

| Appearance / witness state | Successful casting roll | Failed casting roll |
| --- | --- | --- |
| Subtle | 0 | 0 normally; highest domain rank on a critical failure |
| Overt, no eligible witness | 1 | Failure margin |
| Overt, eligible witness | Highest domain rank | Twice the failure margin |

An overt critical failure also triggers the backlash procedure after adding
strain. Other triggers are authored. Verify treatment of forced failures whose
numeric margin is nonnegative under the host's critical rules before coding the
table; do not turn a negative “failure margin” into resource recovery.

**M20-08a–d adopts the replacement consequence structure and blast adapter
above.** The earlier source baseline is as follows:
backlash rolls against accumulated strain, and the discharged amount determines
severity (pp. 133–136). Direct inspection located a specific injury branch:
one damage die per point discharged, bypassing ordinary protection and preventing
magical healing (p. 135). It is one possible consequence, not every backlash.
Convert its innate-protection exception explicitly. Supply original definitions
for the supported consequences: injury, impaired
casting, altered surroundings or a persistent complication. Author choice or a
declared deterministic selection policy decides which applies. Unsupported
consequences block configuration, rather than quietly releasing strain for free.

Voluntary complications require author-approved effects, spending at least half
current strain rounded up, and the source's severity restrictions. Permanent
complications do not award free development points. Distorted perception is an
optional later module with separate truth and belief state, not a compulsory
diagnosis or a replacement for the existing fright system.

The audit also records severity/duration guidance and perception-test procedures.
Severe wounds can generally receive overt healing at one reserve per three
legacy health points, rounded up (p. 137); backlash and unstable-transformation
injury retain their specific natural-healing-only restrictions (pp. 110, 135).

### Defenses, cooperation and items

**Retained:** countering requires knowledge of every domain in the incoming
effect; its rating uses the mastery ceiling rather than the defender's trained
skill, with rating 20 at mastery 10. A successful defense subtracts its margin
from the casting margin; cancellation occurs when remaining margin cannot meet
the declared requirements. Direct resistance is a separate stage (pp. 86–88).

**Retained:** direct effects use Will (p. 86), and the ordinary resistance-to-magic
advantage does not affect this system (p. 41). **Adapted proposal:** resolve that
Will resistance with the host opposed comparison after countering; ties resist. Specify critical
precedence, minimum-score behavior and which margin is used for magnitude in
phase 1. Mark the host comparison and critical policy as adapted; the choice of Will
is already supported by the original source. Indirect physical effects use the host's applicable Dodge, armor,
damage types and injury operations, without a second generic Will defense.
No legacy passive-defense statistic is imported. New protection effects need an
explicit host translation and price review.

**Verified host-generation evidence:** `full-2008` B348-B349 and B241-B242 have
been checked directly in the owned PDF. A resistance contest requires the
attacker to succeed and win; ties favor the defender, and a failed attacker
does not require a defender roll. For eligible supernatural attacks against
living or sapient subjects, the attack target is
`min(attack target, max(16, resistance target))`. The standard spell system
separately supplies critical-casting bypass, resistance traits, conscious waiver,
unconscious resistance, individual/area handling and paid costs on resistance.
The generic contest and standard spell procedures have different scope.

Resistance is therefore available conversion evidence, not a missing-rule
blocker. Only the original earlier-generation core p. 150 remains unverified.
The comparison adapter still requires explicit choices. Preserve the original
Will rule and resistance-advantage exclusion; do not import standard-spell
critical bypass, trait bonuses, area rules or fatigue costs automatically.
Resolve the open parts of R1-R6 before implementing resisted effects.

Cooperative casting retains participant qualification, communication, simultaneous
action, shared visibility, addition of successful margins, whole-group failure
on any critical failure, and the group's total strain gain applied to every
participant. Keep each contribution, expenditure and roll in one transaction.
Determine ordering and edge cases before shipping it; it is not an ordinary
two-character core contest.

Include the separately recovered pp. 131-132 procedures: one-use assistance to
ordinary rolls, attack/damage modification, immediate magical defense without
prior concentration, and magically augmented mundane attacks. The source audit
records their formulas and restrictions. These are distinct delivery types and
need separate host integration and balance checks.

Enchanted items use their programmed effect ratings rather than personal domain
skill. Source pp. 90–95 give a charge ceiling of twice the lowest effect rating,
contact/concentration requirements and continuing strain liability. Preserve the
difference between an item that supplies an effect and a practice that enables
personal casting. The source audit now supplies creation checks, duration tiers,
interruption penalties, initial charging, capacity sealing and starting prices.
Construction-location restrictions, user eligibility and economy conversion
remain explicit adaptation decisions.

## Extension architecture

The first supported integration uses core, progression, Lite, expanded foundation,
expanded characters and expanded skills. This supplies the existing character
budget, IQ-based very-hard skills, Will, injury, fatigue and inventory. It does
not require the character/social umbrella, social, templates, fright, reporting
or the unfinished full expansion suite. A core-only adapter can follow later;
do not claim it works with simplified resilience pools in the first release.

Use composition: an owned `RpgMagicState` references an `RpgExpandedProfile`;
immutable `RpgMagicDomain` and `RpgMagicEffect` definitions are shared. Domain
rank and skill investment, formula purchases, reserve, strain and active effects
belong to individual characters. Use `RpgExpandedContribution` for magic costs,
without charging skill investments twice in the character ledger.

Proposed files under `lib/`:

| File | Responsibility |
| --- | --- |
| `vhyl-rpg-magic.t` | Opt-in umbrella in documented dependency order |
| `vhyl-rpg-magic-characters.t` | Ownership, ranks, capped skills, costs and purchases |
| `vhyl-rpg-magic-effects.t` | Effect specifications, domain permissions and scale tables |
| `vhyl-rpg-magic-casting.t` | Pure assessment, committed casting and receipts |
| `vhyl-rpg-magic-strain.t` | Reserve accounting, strain, backlash and complications |
| `vhyl-rpg-magic-combat.t` | Casting actions, interruption, countering and host defenses |
| `vhyl-rpg-magic-items.t` | Optional enchanted items and supply sources |
| `vhyl-rpg-magic-report.t` | Optional disclosure-safe assessments and recorded rolls |

Keep cooperative casting and other-world/perception features behind explicit
capability boundaries until their later phases. Publishing an umbrella does not
mean every source subsystem is implemented.

### One committed procedure

Provide `rpgAssessMagic` and `rpgCastMagic`. Parser, structured commands and
dialogue choices normalize to the same validated request. Assessment is pure;
only committed gameplay draws dice, spends resources or mutates history.

1. Validate ownership, current permission, sensing, targets, ranks, practices,
   delivery support, resource availability and the selected rules version.
2. Check an immutable request identity and authored opportunity revision against
   a persistent casting receipt. Repeated delivery of the same action reuses the
   original receipt. A genuinely new cast requires an explicit new opportunity;
   neither UI refresh nor alternative wording creates one.
3. Freeze inputs and reserve expenditure, then commit the casting action/time.
   Resolve distractions and concentration at their defined stages. Charge an
   attempted cast even when its roll or its later delivery fails.
4. Resolve casting, scale requirements, strain, countering, resistance and
   backlash in a documented deterministic order. Distinguish roll success,
   adequate scope, defended outcome and final application in the receipt.
5. Record a guard before invoking authored consequences, apply the final effect
   once, and complete any linked challenge only after delivery succeeds.
6. Publish only explicitly permitted observations. Hidden witnesses, targets,
   defenses, strain and beliefs must not leak through previews or reason codes.

Use `rpgRandom` and pure `rpgCheck` where applicable. Reuse profile permission and
modifier hooks through a defined magic context, applying trait, condition and
conjunction modifiers exactly once. Preserve existing `afterAttempt` semantics
for condition expiration through an adapter, with focused regression tests.

Do not wrap an ordinary `rpgResolve` success and try to cancel it afterward:
that function caches the result and can complete the goal before `apply` runs.
It also uses ordinary fatigue costs and lacks multi-domain and multi-stage
receipts. Keep the new orchestration in the extension; extract a small shared
helper only if implementation demonstrates a real need and old behavior passes
unchanged tests. Existing `rpg.result` event contracts stay intact; new magic
events carry their own version and disclosure policy.

`RpgDevelopment.kind` currently has a closed set of purchase operations. Add
magic-owned purchase assessment/commit operations against the existing point
bank, or a narrowly reviewed extension hook. Do not pass an invented kind to
`rpgDevelop`: its fallback currently removes a trait. Receipts and ownership must
prevent repeat purchases, shared character state and unintended refunds.

### Time, combat and persistence

`rpgLedger.seconds` does not drive the adventure scheduler. Introduce an explicit
magic-time adapter supplied by the host. In battle, use the existing concentration
maneuver and battle-turn checks; `RpgLiteBattle.advance` already charges one second
per round. Use that normal world-turn boundary for M20-10 casting eligibility
and reserve assistance; additional personal actions do not reset either. Do not
charge a second again in the casting adapter. Outside battle,
the author supplies the advancing world clock. Calendar production requires an
explicit calendar policy, rather than guessing that every month is 30 days.

Multi-second casts need saved progress, interruption and expiry rules. Effect
instances need stable IDs, source/target references, start/expiry times, strength,
stacking/replacement rules and idempotent removal. A temporary attribute modifier
must not overwrite the base attribute or erase later advancement when it expires.
“Permanent” means no timed expiry, not an irreversible operation immune to undo.

Store scalar snapshots and stable world references in declared persistent state,
not temporary result objects. Save resource debits, request identity, dice,
critical flags, margins, defenses, participant order, derived magnitude,
consequences, duration and reporting permission. Undo, exceptions and cross-process
restore must reproduce the same result. Saves still identify the exact compiled
game; this extension does not promise migration of existing saves.

The [accounting examples](freeform-magic-source-audit.md#accounting-issues-illustrated)
explain group critical outcomes, reserve displacement, complication batching and
the now-resolved initial construction-failure policy. The same follow-up records
the local-barrier defaults and the separate anniversary comparison.

## Current gaps and completion criteria

The nine-domain permission research is complete at the rank-summary level.
The [direct PDF audit](freeform-magic-source-audit.md) has now located the general
scaling tables, casting/retry rules, resource throughput, backlash injury, item
construction and optional-world procedures. Host-generation resistance has also
been verified in `full-2008`. The gaps below have been narrowed accordingly.
Source interpretation, external-book dependencies and deliberate host adaptations
are different kinds of work. Unqualified page references use `freeform-1994`;
B-prefixed resistance references use `full-2008`.

| Priority / area | Gap type | Work needed to close it |
| --- | --- | --- |
| 1. Effect strength and reach | Recovered; interpretation and conversion remain | Implement the audited tables with quantity-specific zero handling, units and rounding. Preserve specific life damage and the specific creation-formula mass override. Audit any further domain example before enabling its operation. Define nearby reach, host trait prices and a replacement/omission policy for legacy passive defense. |
| 2. Casting and defenses | Both source sequence and host-generation resistance recovered; conversion remains | Keep cast, scope, strain, countering and resistance distinct. Resolve R1-R6 below, forced-failure margins, interruption costs and multiple defenders. Exact earlier-generation resistance remains unverified but does not block an explicitly adapted host rule. Include pp. 131-132 assistance and immediate defense, and do not invent a universal ongoing dispel. |
| 3. Resources and consequences | Recovered numeric rules; interpretation and author policy remain | Apply the accepted single-pool displacement and fixed-at-start complication policy; define composition of the known consumption/receiving/transfer operations and implement M20-32 overflow without a new threshold trigger. Implement the adopted backlash bands and injury scale, implement the blast adapter and convert the severe-wound healing cost. Exact complication penalties/durations and non-injury backlash remain authored as the source directs. |
| 4. Executable effects | Conversion and implementation | Turn permission descriptions into composable operation rules with typed targets, domain prerequisites and delivery handlers. Cover self/other, living/nonliving, existing/created energy or matter, temporary/permanent effects and explicit exceptions. Keep unknown operations distinct from insufficient character rank. The goal is reusable operations, not a fixed spell list. |
| 5. Host character and world behavior | Conversion decision | Translate legacy damage, healing, fatigue, attributes, traits and protection into the existing host models. Define injury-origin restrictions, healing opportunities shared across healers, body transformation, mental control and truth-versus-belief state. Record which effects require additional host systems and remain unsupported until those systems exist. |
| 6. Time and persistent effects | Conversion and implementation | Define cast interruption, stacking, expiry, cancellation and retry reopening. Integrate acceleration, suspension and forward travel with the world scheduler. Enforce the accepted world-turn casting and reserve-assistance limits under acceleration; bound long durations and time jumps without overflowing the current seconds ledger. |
| 7. Groups, items and optional worlds | Recovered procedures; interpretation and conversion remain | Implement the adopted group critical/zero-margin policy, full-rank group qualifications, and half-price rank relearning with retained skill/formula investment and replacement bonus eligibility. Apply the accepted ordinary-failure outcome to all failed construction; defer defects. Convert item economy, eligible users and construction locations. Reconcile world-rating equality and incomplete internal-confrontation time rules. Supply host topology and authored consequences; mark unsupported external-book procedures and deferred features. |
| 8. Costs, balance and delivery | Validation and implementation | Test retained magic prices with host skill/trait costs, reserve bonuses, cooperation, high-margin damage and permanent changes. Implement the extension, examples, coverage ledger, persistence, disclosure controls and regression checks. No runtime magic code or mechanical tests have been delivered by this planning work. |

Every implemented operation needs a traceable permission entry, scale rule,
delivery rule and validation case. Each of the 45 rank entries must be marked
supported, partially supported or deferred in the future coverage ledger; no
rank may be advertised as fully supported merely because its basic skill exists.
Source examples that differ from apparent general rules retain an explicit
exception or a documented conversion decision.

The next priority is **turning recovered scaling and casting rules into an
explicit host specification**, resolving the listed interpretations and external
dependencies. Then settle resource/consequence accounting and implement a small
end-to-end slice. Optional world features and a large formula catalogue can
follow without blocking a clearly scoped first release.

### Parallel-audit outcome

The [follow-up audit](freeform-magic-source-audit.md#parallel-source-audit-26-october-2026)
records three independent source investigations plus host-rule checks. It found
that the earlier checklist overstated several research gaps. In particular:

- Direct resistance is Will, and the ordinary resistance-to-magic trait is
  expressly ineffective against this system.
- Countering order, magnitude reduction, concerted counters and area cancellation
  are published rules. Remaining timing/cap integration is software conversion.
- Reserve overflow rejection and taking another caster's reserve are explicit.
- The exceptional creation-mass table belongs to a particular rank-2 formula;
  it was previously mislabelled as a general rank-4 composite rule.
- Cancellation, mental projection/combat, spirit powers, boundary rescue and host
  spell lifecycle have substantially more published coverage than the initial
  reference summaries exposed.

The checked items below close source questions only. They do not claim code has
been implemented. Most remaining unchecked items are explicit conversion,
automation or authored-content work; genuine source limitations are narrowed in
the unchecked parts of S2-S7 and H7. Spirit-vessel construction is deferred for later review because
the referenced supplement is not owned; it is not a first-release blocker.
Earlier core references will be adapted using the available newer core under the
accepted conversion direction; retrieving that earlier edition is not required.
Rules explicitly left to a referee still require authored choices.

### Outstanding resistance decisions

The following are conversion decisions, not requests to rediscover the verified
core rules. Close each with a written policy, provenance label and validation
case. The current Will/tie proposal is a starting point, not a completed adapter.

- [ ] **R1 - Eligibility and awareness adapter.** Direct effects use Will and
  indirect effects use their delivery defenses (p. 86); these are settled.
  Classify implemented operations accordingly and expose the source's dodge
  eligibility judgment. Decide whether to adopt the host conscious-waiver and
  unconscious-resistance policy while preserving possession's always-resist
  exception (p. 117).
- [ ] **R2 - Attack cap and margin accounting.** Decide how the verified cap
  applies to the casting result. Preserve separate casting, scope and resistance
  margins; decide whether the capped margin changes magnitude or only resistance.
  Define how to reuse a casting roll when area targets have different resistance.
- [ ] **R3 - Critical outcomes.** Decide whether the standard spell system's
  critical-casting bypass applies to this extension. Specify whether it also
  bypasses countering, how defender critical results behave, and how automatic
  failures with nonnegative arithmetic margins are represented. Do not generalize
  the spell-specific exception to every opposed roll.
- [ ] **R4 - Independent counter timing.** The source already orders countering
  before resistance, reduces actual magnitude, cancels an entire declared area
  when the reduced margin cannot support it, and permits concerted counters
  (pp. 86-88). Specify reaction limits, independent-counter ordering, interruption
  of a counterer's own cast and the adapter to the host resistance cap.
- [x] **R5 - Preserve the published resistance-advantage exclusion.** Page 41
  expressly makes the ordinary resistance-to-magic advantage ineffective here.
  Apply none of its standard single-target or area bonuses to this extension.
  Other host traits, such as a mental shield, need operation-specific mapping
  if supported; they are separate features, not a missing default resistance rule.
- [ ] **R6 - Transaction timing and disclosure adapter.** Spent reserve is lost
  on failure/inadequate scope, strain is assessed before defenses, and final
  reporting follows defenses (pp. 86-87). Preserve that sequence. Specify exact
  debit/reservation behavior for interrupted or aborted casts, item receipts and
  hidden-data disclosure; do not add standard spell fatigue costs.

### Outstanding source interpretations and accounting

- [ ] **S1 - Record exact-success precedence.** General numbers and specific
  mass-override priority are recovered. Preserve the particular matter-2 plus
  power-2 creation formula's table (matter 4 permits mixed materials), rather
  than applying it to all composite creation. Document explicit raw-zero tables
  taking precedence over generic minimum-one wording. Additional operation audits
  belong to D1; life's specific injury formula is already known.
- [x] **S2 - Reserve displacement and excess strain policy resolved.** Use one
  reserve total Q, with `min(Q, channel)` protected from transfer and
  `max(0, Q - channel)` transferable. When strain P rises, reserve becomes
  `min(Q, max(0, 20 - P))`; excess reserve disappears first and protection
  from transfer does not confer immunity to strain. No origin-tagged reserve
  ledger is required. This is the derived wheel-position interpretation supported
  by `freeform-1994` pp. 44, 50, 120 and `anniversary-2015` pp. 248, 331-332;
  label it adapted. M20-32 retains all strain above twenty, with zero reserve
  capacity and no new mandatory threshold-crossing backlash trigger. Existing
  triggers still apply. Implementation and transaction checks remain D2/D6.
- [ ] **S3 - Receiving/transfer composition.** Whole-portion consumption, transfer
  throughput, protected channel floor and storage limits are known. Taking another
  caster's reserve is permitted (p. 120), with applicable direct resistance;
  consent-only transfer would be a departure. Specify whether receiving and
  transfer compose into one transaction and how a large consumed portion is
  allocated. Preserve the remote-delivery formula's one-per-success exception.
- [x] **S4 - Complication batch policy accepted, 26 October 2026.** Snapshot
  starting strain, eligible severities and minimum expenditure for the entire
  transaction. Spend at least half the starting strain, rounded up; above eight
  starting strain, every selected complication costs five. Validate total cost
  against starting strain, then apply the batch once. Do not change eligibility
  between selections. Exact penalties/durations remain authored. Implementation
  and boundary/atomicity checks remain D2/D4/D6.
- [x] **S5 - Group-result policy adopted after source investigation.** Sum
  raw margins from genuinely successful contributors; ordinary failures add zero.
  Require at least one successful contributor. Apply quantity-specific exact-zero
  minima once to the aggregate, preserving explicit raw-zero mass/temperature
  entries; raw counter reduction has no minimum-one bonus. Any critical failure
  dominates the group. Otherwise any critical success supplies only the source's
  critical range/duration eligibility, not extra damage or resistance bypass.
  Sum strain from actual individual rolls once and give that sum to each caster.
  An overt group critical failure triggers one backlash check per participant
  against their own post-sharing strain; multiple critical failures do not repeat
  those checks. A subtle critical failure has no automatic backlash trigger.
  These group edge rules are explicit conversion rulings, supported but not
  uniquely determined by the investigated sources. Implementation/tests remain D3/D6.
- [x] **S6 - Relearning accounting and construction outcome policies resolved.** Initial
  construction treats critical failure as ordinary failure for the item outcome;
  any failed required check destroys the prospective item. No flawed item is
  produced. A defect system is deferred for later review. Choose evaluation order
  and debit timing during implementation without changing this outcome policy.
  M20-27a–b preserves skill/formula investment and permits +2 after proper
  replacement binding within restored ranks. Cumulative restoration costs are
  rounded up once, with no refunds on original-tool recovery. Implement these
  adopted policies and their receipts under D2/D4/D6.
- [ ] **S7 - Enumerated prerequisites and external sources.** Assign authored
  operation requirements for unspecified added ranks in spatial mass/momentum
  changes (p. 100), selective biological control (p. 104), property removal
  (pp. 120-121), and world creation (p. 123). Page 97 delegates novel combinations
  to the referee. **Spirit-vessel construction: deferred for later review by
  user decision, 26 October 2026.** The referenced supplement is not owned
  (p. 123). Keep the permission visible but mark construction unsupported; do
  not block the core extension on obtaining it. Exact
  earlier core resistance and spirit direction-finding will be adapted using
  available newer-core procedures; no older-edition lookup is required.
- [x] **S8 - Principal cancellation procedures located.** Preserve specific
  reversals, target-paid release, boundary closing, item disenchantment and
  manifestation banishment from pp. 91, 118, 120-123 and 169. Countering has
  explicit ongoing-manifestation exceptions. `full-2008` B250 supplies targeted
  cancellation and area dispelling as alternative evidence. A universal domain
  dispel remains an optional conversion, not an absent core procedure that must
  be invented. Implementation and supported-operation coverage remain D1-D3.

### Referee judgments to preserve

These are the principal gameplay judgments left open by the source, rather than
missing arithmetic rules. Page references use `freeform-1994`. In a programmed
game, the author supplies policies or authored content for these judgments; the
engine should apply them consistently and should not accept player descriptions
as proof of eligibility.

| Judgment | Specific decision | Source pages |
| --- | --- | --- |
| Novel effects | Decide whether the proposed method fits the domain descriptions and which domains/ranks an unlisted combination needs. Qualitative results such as regrowing body parts or complex illusions can need a success requirement beyond ordinary damage/mass/duration tables. | 97, 100, 104, 110, 117, 120-123 |
| Plausible appearance | Decide whether the described occurrence could pass as an ordinary coincidence in its actual circumstances or is overtly impossible. The original optional repeated-coincidence penalty has no fixed increment or reset interval; adopted M20-17 supplies the host schedule and material-scene reset. M20-18 supplies local practice profiles. M20-20 supplies neutral witness eligibility replacing source setting categories. | 81, 83, 87 |
| Haste, distraction and retry | Set haste beyond the stated minimum penalties, judge what constitutes a distraction or overwhelming input, and decide whether circumstances have changed enough to reopen a failed attempt. Timing/distraction formulas remain; the general retry gate is replaced by M20-13 while specific domain locks remain. | 84-85, 88 |
| Physical delivery and unusual injury | Decide whether a particular indirect attack permits Dodge. For applicable generic damage, choose the stated one- or two-point-per-die reduction for non-crushing types; a host damage conversion must document its replacement. Decide qualitative healing requirements and when exertion worsens unstable bodily changes. | 86, 89, 110 |
| Backlash and complications | Decide whether to invoke backlash outside the mandatory trigger, select its kind, approve/design complications, and assign exact penalties/durations within the published severity guidance. Injury has a formula; non-injury consequences and escape trials require content. | 133-137 |
| Flawed items | Source offers a referee-selected defect. Accepted initial adaptation: treat critical failure as ordinary construction failure and defer the defect system. This resolves mixed-failure item outcomes. | 91 |
| Spirits and local worlds | Adapt calling requirements through the social relationship system. Use the p. 146 barrier table and explicit location exceptions; local world laws and entities' responses remain authored. World creation has unquantified ingredients, so either author an explicit optional procedure or defer it. Spirit-vessel construction is separately deferred. | 122-124, 146-147 |
| Distorted perception | Accepted as authored content: explicit episode triggers, duration, false elements, permitted manifestations and resolution. Source scrutiny rules may be retained; missing duration counts/failure cases must be declared by the episode policy. | 136-137 |

Do not leave source ambiguities to improvised runtime decisions merely because a
referee could adjudicate them. Excess strain and transfer/receipt composition
still need explicit extension policies (S1-S6). Group critical/zero aggregation
has a documented adopted policy after investigation. Reserve
displacement now uses the derived single-pool model, complication batches use
fixed starting eligibility, and mixed crafting item outcomes use ordinary failure.
Resistance caps, critical precedence and scheduler behavior likewise belong to
the accepted newer-core conversion (R1-R6 and H3), not unrestricted referee fiat.

### Outstanding host specification and authored policies

- [ ] **H1 - Scale, units and traits.** Convert damage/healing, attributes,
  trait prices, weight, temperature and distance; use the verified B9 rounding
  rules and choose its game-metric or precise conversion convention. Define nearby
  reach and large-value bounds and omission/replacement of legacy passive defense.
- [ ] **H2 - Injury and transformation.** Track injury origin and healing
  eligibility, shared treatment opportunities across healers, bodily leakage,
  and temporary versus permanent modifications without overwriting base traits.
- [ ] **H3 - Time and effect lifecycle.** Specify casting progress, interruption,
  expiry, stacking/replacement, cancellation and retry reopening. Define scheduler
  behavior for acceleration, suspension and forward travel, enforcing M20-10
  casting/spending limits, M20-11 attention accounting and bounded long time jumps. Host evidence now includes B236-B238
  interruption, stacking and maintenance, and B38 additional maneuvers on the
  existing turn. Choose adapters without overwriting source-specific rules.
- [ ] **H4 - Virtual referee and world judgments.** Implement the accepted
  adjudication contract for invented effects and coincidence, including versioned
  rulings, validation, stable replay and a concrete repetition policy. Use the
  barrier table as location defaults with authored overrides. Keep practices,
  exact complications and non-injury backlash as explicit content/policies.
- [ ] **H5 - Items and production.** Convert item prices, eligible users and
  construction-location requirements. Define ownership, calendar output,
  collection receipts, recovery and recharging without duplicate collection.
- [ ] **H6 - Implement recovered mental/spirit procedures.** Use the detailed
  links, control, projection and astral combat rules (pp. 117-118), sight/crossing/
  boundary rules (pp. 122-124), and common spirit/manifestation rules (pp. 167, 169).
  Implement the accepted social relationship adapter for spirit calling and
  cooperation, with a tested numeric mapping. Model controllers, perception
  channels, spiritual health and topology, or defer
  affected operations. B296 body/mind transfer and B193 exorcism are available
  host alternatives; these systems are not broadly missing from the books.
- [ ] **H7 - Optional world/perception rules.** Decide whether equality satisfies
  local domain ratings; supply missing failed-roll and exact-duration rules for
  internal confrontations through explicitly authored episode policies. Distorted
  perception remains authored rather than generated by the virtual referee.
  Boundary-prison rescue is recovered (pp. 122-123). Define authored
  backlash-world escape and unquantified world construction scope. These features may be explicitly deferred from the first release.

### Outstanding implementation and delivery

- [ ] **D1 - Coverage ledger.** Create `docs/magic/coverage.json`, accounting for
  all 45 rank entries as supported, partially supported or deferred, with source
  pages, prerequisites, scale/delivery rules, exceptions, decisions and fixtures.
- [ ] **D2 - Casting foundation.** Implement the separate opt-in module, character
  purchases, capped skills, formulas, pure assessment, resource accounting and
  single-caster execution with the three proposed noncombat example operations.
- [ ] **D3 - Combat and cooperation.** Implement the approved resistance/counter
  policies, indirect delivery, assistance, immediate defense, augmented attacks
  and cooperative casts. Add only operations whose prerequisites and handlers
  are explicitly covered.
- [ ] **D4 - Persistent state.** Implement stable effect IDs, scheduler adapters,
  atomic receipts, action deduplication, expiry/removal, undo and cross-process
  restoration. Preserve unrelated character changes and disclosure boundaries.
- [ ] **D5 - Items and optional modules.** Implement or explicitly defer crafting,
  charging, supply production, other worlds and distorted perception. A rank
  purchase must not imply support for a deferred operation.
- [ ] **D6 - Balance and regression evidence.** Exercise price curves, reserve
  bonuses, group scaling, high-margin damage and permanent benefits with original
  fixtures. Run the focused verification matrix below and existing compatibility
  checks; documentation validation alone is not mechanical validation.
- [ ] **D7 - Distribution.** Deliver examples, author/API guides, unsupported
  coverage, neutral provenance, library/build registration and release packaging.
  Audit public text and identifiers for excluded setting terms and private data.

Research-only closures R5 and S8 and policy closures S4 and S5 are supported by
the companion audit. They do not imply implementation is complete. Close
remaining specification or implementation items only when their decisions and
validation evidence are linked from the future ledger. Explicit deferral must name the affected operations
and release scope; it does not count as full conversion coverage. A noncombat
prototype can precede R1-R6, but must not claim resisted or countered combat
support. No runtime implementation or mechanical test suite exists for this
extension yet.

## Delivery sequence and acceptance gates

### 1. Complete the mechanical specification

Create `docs/magic/coverage.json` with neutral source ID, printed pages,
correction references, evidence kind, retained/adapted/unverified status,
implementation symbol and validation fixture for each procedure. Turn the
[researched permission matrix](freeform-magic-permissions.md) into explicit
operation rules, preserving its exceptions and unresolved additional ranks.
Include the matrix's healing/retry restrictions, extra trait purchases,
creation dependencies, forward-only time travel and special margin allocation
in the specification and fixtures. Work through the gap register above in order.
The book provides guidelines, not an exhaustive decision table: author rulings
for unlisted combinations must be labeled as such. Keep other missing details
unverified; do not reconstruct them from another edition or remembered rules.

Use the audited scaling tables, base times, distraction procedure, supply rules
and item construction rather than researching their existence again. Resolve
required traits, resistance ordering/criticals, reserve overflow and the audit's
remaining interpretations. Implement the now-adopted reserve displacement,
complication batch and cooperative edge policies. Write the
explicit host conversion decisions alongside those entries. This phase is the
gate for claiming a complete mechanical conversion; missing peripheral tables
need not prevent an honestly limited prototype.

### 2. Build the casting foundation

Implement character contributions, capped skills, reserve/strain state, pure
assessments, a dedicated receipt and a single-character casting pipeline. Add
only verified permissions and original authored example effects. Start with a
small noncombat example: inspect concealed material (matter 1), redirect existing
light (energy 2), and relocate a small object (space 4). Define target and scale
limits explicitly. A generic “move” command is insufficient: redirecting an
already moving object uses energy 4, while generating motion uses energy 5 plus
power 2. These source distinctions are now verified in the permission matrix.

Acceptance: all three input paths produce identical requests and results; blocked
and preview operations spend nothing; an insufficient margin loses committed
reserve but changes no target; duplicate submissions do not roll or spend twice.

### 3. Add progression and sustained consequences

Implement formula pricing, practice exemptions, breakthroughs, source recovery,
verified scale tables, duration management, complications and backlash. Give the
example a reliable mundane route so failed magic cannot erase required progress.

Acceptance: total-versus-incremental costs are correct; learning releases capped
investment; formulas keep their special ceiling and fixed time; strain displaces
reserve; expiry, stacking, undo and restoration preserve unrelated changes.

### 4. Integrate defenses and cooperation

Implement casting in combat, direct resistance, indirect attack delivery,
countering, interruption, one-use skill assistance, immediate magical defense,
augmented mundane attacks and cooperative casts. Test the boundary between a
successful cast and an unsuccessful delivered effect. Make high-margin damage,
permanent alteration, reserve bonuses and group scaling explicit balance targets.

Acceptance: no premature goal completion, duplicate injury or duplicate clock
advance; canceled effects retain appropriate costs and strain; each participant
pays once and receives the source-defined shared consequence.

### 5. Add items and optional world features

Implement verified item creation/activation/recharging and periodic supply.
Other worlds use author-defined locations, barriers and local casting policies;
distorted perception uses authored beliefs and limited inspection receipts.
These can be separate follow-on packages without delaying the base extension.
Do not advertise a full conversion while any promised subsystem remains deferred.

### 6. Document and release

Write the authoring guide, include examples, API reference, edition-conversion
notes and accurate unsupported list. Add the implemented extension to the
[library catalogue](libraries.md), README and neutral provenance. Add standalone
include fixtures and build/test registration. Audit prose, identifiers, events,
labels and examples for excluded setting terms; retain existing software names
and required software notices. No source prose, named spells or private URLs enter
the package.

Run existing source/native checks with the pinned dependencies, strict docs and
release packaging checks. Release notes must identify exactly which ranks,
operations, delivery types and optional subsystems are supported. Review balance
with original fixtures rather than legacy named characters. Keep altered prices
or optional limits clearly marked as adaptations.

## Focused verification matrix

- Ownership and costs: duplicate training, shared mutable state, rank above
  mastery, missing investment, corrected mastery/rank prices, formula +3 cost,
  progression locks and repeated purchases.
- Casting: minimum required domain skill, one penalty per extra domain, modifier
  order, capped base versus final skill, no-default failure, exact-margin and
  insufficient-margin effects, all host critical boundaries.
- Resources: zero reserve, spend above channel, several casts in one turn,
  innate transfer rejection, strain at/above 20, displacement, failed-cast costs,
  and no unearned recovery from negative failure margins or absent consequences.
- Scale: every verified range/duration/damage boundary, including corrected
  duration transitions 5→6 and 7→8; critical success cannot bypass rank permission.
- Audited exceptions: raw zero margin for mass/temperature; life damage and
  specific creation-formula overrides; general area versus remote space reach; no
  automatic critical-damage multiplier; strain based on casting rather than delivery.
- Permission matrix: all 45 entries accounted for as supported, partial or
  deferred; creation conjunctions, existing-energy limits, self/other differences,
  separately paid traits and explicit combination exceptions enforced.
- Effect exceptions: mind enhancement allocates margin to benefit and duration;
  bodily self-enhancement cannot become permanent through a duration roll;
  restricted injuries resist magical healing; changing healers cannot reopen the
  same treatment opportunity; mental retries honor their operation-specific gates.
- Defense: all-domain counter eligibility, mastery-10 defense rating, remaining
  margin below effect requirements, direct-resistance ties, and correct indirect
  armor/Dodge/injury handling.
- Groups/items: participant qualification, one critical failure, summed strain
  per participant, atomic expenditure, item-specific ratings and charge ceilings.
- Item construction: half-hour first tier, interrupted-work tier advance,
  initial-charge capacity reduction and sealing, and selected-rank purchase prices.
- Assistance: next-roll-only bonuses, lost aid on a missed attack, immediate
  defense eligibility, and an enabling spell's failure on a remote melee attack.
- Lifecycle: action deduplication, interruption, replacement/expiry, no repeated
  breakthrough awards or supply collection, deterministic participant/dice order,
  exception rollback, undo/replay and restore into a fresh process.
- Privacy and compatibility: hidden observer/defender data, immutable recorded
  calculations, pure previews, parser/action/dialogue parity, unchanged core/Lite
  behavior when omitted and no mixed simplified/expanded health ledgers.

## Source-page research map

All entries below refer to `freeform-1994`, third generation, 1994, printing
unverified, with `freeform-errata-1999` applied where identified.

| Subject | Printed pages | Evidence boundary |
| --- | --- | --- |
| Character creation | 39–40, 50 | Budget and package are source recommendations, not adopted settings. |
| Mastery, channel and practices | 44, 50, 89 | Corrected mastery 8 and rank 1–2 costs; skill pricing is adapted. |
| Supply and shared track | 44, 46–50, 78–80, 83, 119–121 | Recovery, output, receipt and transfer amounts audited; displacement/overflow policies adopted, while transfer composition remains open. |
| Appearance and casting | 81, 83–89 | Timing, distractions, sequence and general retry gate audited; referee choices need host policy. |
| Range, damage and duration | 85–86, 89 | General tables inspected directly, with official duration correction and specific domain overrides. |
| Countering and cooperation | 86–88 | Procedures inspected; exact legacy resistance is external, while verified host-generation resistance is available for an explicit adaptation. Group edge policies were adopted after the follow-up investigation; implementation remains open. |
| Ordinary assistance and combat | 131–132 | One-use aid, immediate defense and augmented attacks now included. |
| Formulas | 88–89 | Price curve, default, cap and timing exception retrieved. |
| Enchanted items and practices | 48, 90–95 | Construction, time, interruption, charging and prices audited; access, economy and practice policy need conversion. |
| Nine domain descriptions | 97–128 | All 45 rank descriptions located and inspected in the PDF; neutral matrix records permissions and exceptions. |
| Breakthroughs | 132–133 | Milestone structure retained; prescribed narrative removed. |
| Strain consequences and injury | 110, 133–137 | Specific backlash damage, complication guidance and restricted healing audited; non-injury outcomes authored. |
| Distorted perception | 136–137 | Severity, scrutiny and internal-confrontation table audited; exact durations and failure gaps remain authored. |
| Crossings and local conditions | 90–92, 122–127, 144–151 | Local casting policies and barrier ratings inspected; world construction and external spirit procedures remain outside verified coverage. |
| Source conversion chapter | 178–187 | Different conversion direction; not a host conversion recipe. |

Additional host source: `full-2008`, character volume third printing (February
2008), B241-B242; campaign volume fourth printing (April 2008), B348-B349.
These pages verify standard resisted spells, generic resistance contests and the
supernatural attack cap. They resolve the host-source lookup, while R1-R6 track
the remaining extension-specific decisions. No later corrections are implied.

The first implementation milestone should be a small, fully tested casting
extension with explicit coverage, followed by the remaining verified mechanics
in the sequence above. Its public vocabulary and data model should already be
free of setting dependencies, so later coverage does not require another rename.

## Implementation checkpoint — 26 October 2026

The mechanical library and typed world adapters are implemented. The earlier
research checklists above are historical: their resolved policy choices are
recorded in [implementation decisions](magic/decisions.md), and their delivery
mapping is in [the coverage ledger](magic/coverage.json). The [author guide](magic.md)
is the current integration contract. Spirit-vessel construction remains the
explicit user-authorized deferral. Authored world content and a concrete AI
provider are game integration choices, not additional missing source research.

The library includes casting, scaled declarations, direct/indirect defenses,
countering, fully qualified cooperation, ordinary work and extended rituals,
resource supply/recovery, backlash consequences, injury restrictions, item
workflows, timed overlays, mental information and spirit/world adapters.
Tests exercise deterministic public transactions and cross-process persistence;
the existing workshop remains the small end-to-end GM protocol example.

No source examples or setting lore are shipped as an executable spell catalogue.
The coverage ledger names the actual operations for each rank and the game-owned
adapters they require. Registering a rank does not enable arbitrary unimplemented
physics, properties or unknown operations. Neither an LLM nor the OS AI service
is required by the library; a separate provider can implement the GM protocol.

No release has been published or tagged by this implementation task.
