# Expanded skills

**Status: partial.** Skill catalogues, defaults, prerequisites and techniques. Neutral source: `full-2008`, B167-B233.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedSkillLevel` — B170; B175; tested in `tests/expanded.py::test_numbers`.
- `rpgExpandedSkillScore` — B173; tested in `tests/expanded.py::test_numbers`.
- `RpgExpandedTechnique` — B230; tested in `tests/expanded.py::test_numbers`.

Additional interfaces are described below: learning requirements, equipment
familiarity, technology modifiers and optional specialties. Their new native checks
are authored but unrun. The full catalogue and remaining chapter procedures are
not implemented. See the integration guide for restrictions.

The [skill procedure inventory](inventory/skills-procedures.json) records individual
cost-table cells, default rules, familiarity requirements and technique definitions.
Attribute-based defaults, technique default chains and explicit uncapped techniques
now have runtime support; their new native cases are authored but not yet run.
The catalogue inventory currently covers [B174–B185](inventory/skills-catalogue-a.json),
[B186–B197](inventory/skills-catalogue-b.json),
[B198–B209](inventory/skills-catalogue-c.json) and
[B210–B228](inventory/skills-catalogue-d.json). This completes the first text pass
through the main catalogue, but not its enumeration audit, cross-reference
resolution or implementation. Definition metadata is not an executable catalogue
and does not imply completed skill effects.

The recorded procedures include persistent code-breaking attempts, combined
impersonation checks, audience-specific storytelling effects, timed induction and
suggestions, vehicle/equipment skill caps, and weapon-specific attack and defense
rules. These need owning state and integration tests in addition to catalogue
score definitions. Source text that leaves a boundary or consequence unspecified
requires an explicit author contract; it must not acquire an invented numeric rule.


[Skill aptitude requirements](inventory/traits-catalogue-l.json) include the ten
printed skill groups, reaction audiences, default-use bonuses and reduced learning
time. Specialties count once for pricing, but a specific specialty restriction still
limits the actual bonus. Overlapping groups may exceed four for skill bonuses only;
reaction and study overlap must not silently inherit that exception. These effects
and their catalogue identifier mappings remain pending.

The [technique-summary ledger](inventory/technique-summary.json) compares all 27
summary rows with the detailed definitions. The catalogue has 29 technique
definitions because the detailed text also describes rope descent and unarmed
sweeping. Structured metadata records attribute-based defaults, parent technique
chains, separate specialties, caps and cinematic exceptions. The camera technique
is explicitly uncapped; ranged weapon retention has a Dexterity-based variant.
Rope descent does not restate its difficulty, so that interpretation remains
explicitly unresolved. Catalogue definitions and their operational effects remain pending.

The [first skill-summary segment](inventory/skill-summary-a.json) maps 44 rows.
It exposed missing Dexterity defaults for aerial and aquatic acrobatics and missing
melee group defaults; these are now recorded alongside the detailed skill edges.
The summary omits other valid defaults, so it cannot replace the detailed catalogue.
Reciprocal default edges do not permit chains through untrained skills. Full field
reconciliation and executable coverage are still pending.

The detailed aiming-skill groups now record their cross-specialty default edges:
beam weapons and mounted direct fire at −4, built-in ranged attacks at −2,
and liquid projectors at −4. Projectile small arms use −2 except that an edge
involving a grenade launcher, miniature rocket or light antitank weapon uses −4.
Matching beam/projectile pistol and rifle defaults require a campaign containing
both weapon technologies. Familiarity penalties remain separate from defaults.
These are source definitions awaiting runtime integration; the abbreviated summary
table does not list every edge.

The [second skill-summary segment](inventory/skill-summary-b.json) maps 103
rows, including group headings and concrete skills. Group headings resolve to
their detailed specializations; they must not create duplicate purchasable skills.
The summary field comparison remains pending.

The [third skill-summary segment](inventory/skill-summary-c.json) maps 104
rows, including group headings and concrete skills. Group headings resolve to
their detailed specializations; they must not create duplicate purchasable skills.
The summary field comparison remains pending.

The [final skill-summary segment](inventory/skill-summary-d.json) maps 24
rows, including group headings and concrete skills. Group headings resolve to
their detailed specializations; they must not create duplicate purchasable skills.
The summary field comparison remains pending.

All four skill-summary segments now link 275 rows to their detailed definitions.
Attribute, difficulty and technology headings have been compared. The ammunition
quick-draw specialty retains its technology qualification despite the unqualified
group heading in the summary. Low-technology weather prediction is an alias of
meteorology, with a home-area bonus and no planet-type specialty requirement until
technology level five. These exceptions are recorded explicitly. Defaults,
prerequisites, conditional specializations and executable effects still need their
full reconciliation and integration fixtures.

Detailed specialty networks are also recorded for visual art, explosives, geography
and ordinary hazardous materials. Visual art uses its close-family exceptions and
a −6 fallback between other specialties; familiarity remains a separate modifier.
The explosives network has two −2 pairs, with −4 between the other specialties.
Geography specialties default at −5, as do the three ordinary hazardous-material
specialties. Exotic hazardous materials receive no automatic cross-default:
any allowed relationship needs an explicit authored definition. None of these
edges permits chains through untrained skills. Runtime catalogue dispatch and
context-sensitive default eligibility remain pending.

Navigation retains two separate default groups: air/land/sea at −2 and
space/transit-space at −5, with no default between the groups. Sea and air cannot
use their astronomy default when bad weather hides the stars and no technological
aids are available. Survival defaults connect land specialties at −3 and aquatic
specialties at −4, with only coast/lagoon and swamp/river bridging those groups.
A different planet adds −4 only when both planets share a type; it cannot create
a missing terrain edge. Natural-history defaults likewise require the same planet
type. These conditions are recorded separately from familiarity and attribute
defaults, awaiting runtime eligibility and composition fixtures.

Ground-vehicle defaults are directional. Each target specialty uses its own
printed fallback, with the automobile/heavy-wheeled and halftrack/tracked pairs
retaining their better defaults. Motorcycle operation has its cycling default;
other driving specialties do not automatically supply a reverse edge. Boat
defaults now use complete catalogue identifiers, and diving-suit defaults name
each other protective-suit skill explicitly.

A protective suit can cap Dexterity and Dexterity-based checks without changing
the character's purchased attribute. Its own clumsiness penalty can apply in
addition; an authored suit may explicitly omit the cap. Operating a suit does not
grant environmental knowledge, and unpowered, unsealed armor needs no suit skill.
The life, geological, weather and physical-geography skills also retain the
planet-type default network, distinct from the planet-specific survival and
natural-history restrictions. These source definitions still await runtime use.

Electronics operation, electronics repair, engineering and mechanics now carry
their within-family −4 defaults; mathematics specialties carry −5 defaults.
Engineering and electronics-operation defaults retain the campaign's option to
exclude exotic/ordinary crossings. Mechanics defaults retain specific author
adjustments for unusually close or distant specialties. These are separate from
technology-level penalties and equipment familiarity.

The design/repair/operation links remain directional: ordinary electronics
operation defaults to matching repair at −5, while repair defaults to matching
operation at −3. Computer repair instead uses computer operation at −5. Engineering
requires applied mathematics from technology level five onward, plus its specialty
prerequisites. Vehicle-category definitions must bind a concrete category; they
are not wildcard skills covering every vehicle. Source metadata preserves these
conditions, but runtime prerequisite and context resolution are still pending.

Piloting fallback edges are now explicit and directional: an autogyro uses
helicopter experience at −3, while helicopter operation uses autogyro experience
at −2. Specialties with only specific defaults, such as lightsails and
low-gravity wings, do not gain a general fallback. The broader airplane and
spacecraft selectors retain explicitly unresolved category boundaries; expanding
them to every flying vehicle would grant unsupported defaults.

Piloting also records its skill-15 critical-failure confirmation and the distinction
between cockpit-like telepresence and other remote operation. The source recommends
a watchkeeper trained above default while underway. The author must define any
consequences or operating restriction; the recommendation alone does not establish
automatic failure or forbid all emergency operation. These are procedure requirements awaiting
vehicle-state integration, not behavior supplied by catalogue metadata alone.

## Technique default bases

Set exactly one of `skill`, `attribute` or `parentTechnique` on an owned
`RpgExpandedTechnique`. A skill basis requires a purchased point. A technique
basis may itself have zero points: the chain ultimately reaches its selected
skill or attribute. Each technique instance represents one chosen specialty;
raising that basis raises its descendants without another point charge.
`maximumAboveSkill` remains the compatibility name for the cap above the selected
basis, including an attribute or parent technique. Set it to `nil` only for an
explicitly uncapped definition. `hard` selects the B230 pricing column.

Register each purchased instance once in the owner's `contributions`, with its
own identifier. Referencing a parent does not purchase it or charge its points
again. Default-only intermediate instances can have zero points. Cross-owner
references, cycles and multiple selected bases are rejected. These score methods
are pure; they do not spend advancement points, time or randomness.

For example, an attribute-based definition with `attribute = rpgST`,
`penalty = -4`, `hard = true`, and `maximumAboveSkill = 3` costs eight points
to reach Strength +3. This describes its rating only; situational strength bonuses
and the associated combat action still require the combat implementation.
Additional prerequisites, cinematic permissions and catalogue effects are not
inferred from a default graph.

`tests/expanded.py::test_technique_bases` covers zero-point intermediate defaults,
parent advancement, contribution accounting, attribute caps, uncapped ratings,
cycles, ambiguous bases, ownership and preview purity. These new checks have not
run while build validation is paused.

## Learning prerequisites

An expanded skill's `prerequisite` can be an `RpgExpandedPrerequisite` tree.
A `kind = 'skill'` leaf names `skill` and optionally `minimum`: it requires
at least one purchased point and, when specified, that paid level. An untrained
default does not satisfy either requirement. A `kind = 'trait'` leaf names
`traitId` and `traitLevel` (default one); possession is checked independently of
temporary activation or suppression. `kind = 'all'` or `'any'` combines nonempty
`children`. Cycles and malformed requirements are rejected, including malformed
branches of an otherwise satisfied alternative.

`profile.skillLearningReason(skill)` returns `nil` or `'skill-prerequisite'`.
Character validation checks purchased skills. Advancement purchase assessment and
study check eligibility before committing points, time or study credit. The base
progression hook returns `nil`, preserving eligibility for profiles without
expanded rules. Acquisition requirements do not lower a skill's rating or grant
permission to use equipment; familiarity and operational restrictions are separate.
Authors must supply the actual prerequisite definitions: this interface does not
instantiate the catalogue. Conditional campaign requirements and prerequisite
loss after character creation still require their owning procedures.

The native cases in `tests/expanded.py::test_learning_requirements` exercise paid
minimums, trait possession, alternative/conjunctive requirements, cycle rejection,
and blocked purchases/study with unchanged ledgers. They are authored but unrun
while validation is paused.

## Equipment familiarity

Declare one `RpgExpandedFamiliarity` per profile, skill and equipment type, and
register it in `profile.familiarities`. Set `owner`, `skill`, and `equipmentType`;
the last identifies an authored family of equivalent models. Duplicate entries
for the same skill/type and cross-owner entries are rejected. The standard
`requiredSeconds` is 28,800 and `penalty` is −2 (B169). Specify exceptions only
where the selected skill's procedure provides them.

Set `initial = true` for authored starting familiarities. Validation limits these
to twice the purchased points in that skill. These are initial character choices,
not a method for gaining familiarity after play begins. Practice uses
`assess(seconds)` and `advance(seconds)`, with `available` representing access to
usable equipment. Assessment is pure. Commit charges the shared time ledger once,
adds practice seconds, and binds progress to its original owner, skill and type.
Call it within the normal action transaction. The final second removes the
penalty; repeating practice on a known type returns `reused` with zero time.
Requests exceeding the remaining practice are rejected before spending time.
Practice grants neither skill points nor study credit.

Use `RpgExpandedSkillContext` with matching `skill` and `familiarity` in
`rpgLiteScore` or `rpgLiteCheck`. The contextual penalty is added once alongside
other modifiers; it does not change the purchased skill or technique rating.
Ordinary contexts retain a zero-valued hook and consume no additional randomness.
A context without a familiarity record applies no familiarity modifier, so authors
must supply a record whenever the equipment-use procedure calls for one.

The recognition decision interface below handles discretionary rolls and authored
similarity decisions. Do not model technology penalties by changing this penalty
or practice duration. Combined
study/practice sessions also remain unsupported; calling both commits would charge
time twice. The familiarity state currently supports a dedicated practice action.

Authored native coverage includes preview purity, initial allowances, duplicate
rejection, context ownership, the final practice second, refusal of excess time,
repeat prevention, exception rollback, undo and cross-process save continuation
(`test_familiarity` and `test_familiarity_persistence` in `tests/expanded.py`).
These checks have not run while validation is paused.

## Technology-level use modifiers

`rpgExpandedTechnologyModifier(skillTL, equipmentTL, cognitive)` implements the
B168 use table. Set `cognitive` for IQ-based skills. Higher equipment levels give
−5, −10 and −15 at differences of one, two and three; four or more returns `nil`
(impossible). Lower equipment levels give −1, −3, −5, −7 and another −2 per
further level. Other controlling attributes use −1 per level in either direction.
Both technology levels must be in the supported range 0–12.

Set `equipmentTL` on `RpgExpandedSkillContext` to apply this alongside familiarity.
The selected skill must have an explicit `techLevel`. A missing equipment level
leaves the technology modifier zero; authors must supply it for cross-level use.
Familiarity removes only its own penalty. At an impossible technology difference,
`rpgLiteScore` returns `nil` and `rpgLiteCheck` returns a result with reason
`technology-too-advanced`, without consuming randomness. Untouched Lite contexts
retain their existing unavailable reason and zero additional modifier.

Learning access is handled separately below. Programmed capabilities remain
pending. Improved or obsolete equipment uses the recognition interface below. Native
expected-value table checks and combined-context cases are authored in
`tests/expanded.py::test_technology_modifiers` but remain unrun.

## Optional specialties

Create a definition with
`rpgExpandedOptionalSpecialty(generalSkill, id, specialty, approved)` and give it
its own training slot. The parent must be an IQ-based expanded skill of Average,
Hard or Very Hard difficulty. The author approves that the narrower field fits the
skill and technology level. The definition uses one lower difficulty, the same
technology level, and the same prerequisite object. It does not spend points.
The parent may represent a required specialty already; the resulting optional
specialty remains tied to that exact parent definition. Nested optional specialties
and wildcard parents are rejected.

The general skill defaults to a purchased optional specialty at −2. If another
skill explicitly defaults to the general skill, it can instead default to the
purchased optional specialty at that penalty minus another two. These are explicit
B170 edges, not permission for arbitrary double defaults. For example, a skill
with a −5 default from a general field can use its optional specialty at −7.
`defaultFrom` can also select the optional specialty when buying up the general
skill. A profile cannot contain two investments for the same parent and optional
specialty identity, even if the definitions have different IDs.

The factory does not infer unprinted defaults into the optional specialty, or
reciprocal defaults between sibling specialties. Author explicit catalogue edges
only when supported by the selected procedure. Prerequisite exceptions require
separate implementation; the current factory preserves them unchanged. Definition
metadata remains immutable by author convention after character creation.

`tests/expanded.py::test_optional_specialties` contains independent rating,
propagated-default and paid-default cases, invalid-parent and approval cases,
prerequisite preservation, duplicate identity and preview purity checks. They
remain unrun while validation is paused.

## Relative skill checks

`rpgExpandedRelativeSkill(profile, skill)` subtracts the skill's usual controlling
attribute from its base rating (B171–B172). It returns `nil` if the skill is
unavailable. Set `rollAttribute` on `RpgExpandedSkillContext` to add this relative
level to another attribute. Alternatively, set `fixedBase` to a specific number,
usually 10, for a comparison that removes attribute differences. These choices
are mutually exclusive and require a skill. Neither changes the training ledger.

Use the context with `rpgLiteScore` or `rpgLiteCheck`. Situational modifiers still
apply, and attribute-specific modifiers use the roll's selected attribute. A
fixed-base check has no controlling attribute for such modifiers. Technology
classification continues to use the skill definition's original controlling
attribute; replacing an IQ-based repair roll with a DX-based manipulation roll
does not turn the technical knowledge into another kind of skill.

For a procedure that explicitly adds training to physical Strength, call
`rpgExpandedSkillStrength(profile, skill)`: only a positive relative level is
added. This is separate from an ordinary Strength-based skill roll, which uses
`rollAttribute = rpgST` and retains negative relative levels. Neither interface
chooses when a narrative task should use a different attribute; that choice is
authored in the operation's context.

`tests/expanded.py::test_relative_skill` includes the source's alternate-attribute
and fixed-base examples, negative and unavailable training, conflicting choices,
attribute-dependent shock, and preview purity. These new cases remain unrun.

## Learning across technology levels

B168 learning access applies whenever the skill has a `techLevel`, including
technology-qualified Lite definitions used by an expanded profile. Ordinary
learning requires IQ 6 or higher. A starting character cannot buy skills above
personal technology level. During play, IQ-based technological skills still require
raising personal technology level first. Other controlling attributes may learn
above personal level with a teacher. Mark the profile's existing `creationComplete`
state when character creation ends; it distinguishes starting access from learning
in play, not permission to ignore the remaining requirements.

`skillLearningReason(skill)` checks these character eligibility restrictions and
prerequisites. `skillLearningWithTeacherReason(skill, teacher)` additionally checks
the teacher requirement for an above-level skill. The teacher must be another
profile with purchased training in that exact skill definition, including its
technology level and specialty, and an available skill rating.

Point purchases use `RpgDevelopment.teacher`; their normal author availability
hook still controls access to the lesson or opportunity. Study supplies its teacher
only for education or intensive instruction, and continues to check its existing
teaching and subject requirements. A teacher reference on a self-study or work
track does not bypass the requirement. Blocked requests return a specific
`technology-*` reason before charging points, time or study credit. Profiles without
expanded rules retain the default learning hook.

Low-IQ programmed capabilities do not count as ordinary learning and are not
implemented by this gate. Technology-level transformation, training loss and
catalogue-specific exceptions remain pending. The authored checks in
`tests/expanded.py::test_technology_learning` cover starting versus in-play access,
IQ-based restrictions, teacher identity and training, lower cognition, purchase and
study gates, and unchanged ledgers on rejection. They have not run.

## Recognizing familiar equipment

Create an owned target familiarity record and an authored
`RpgExpandedFamiliarityRecognition` decision referencing it. Set `approved` only
when the author elects to use the B169 recognition procedure. `assess()` is pure;
`resolve()` belongs inside the action transaction and spends no practice time or
points. It records the decision on the target so a repeated call, including one
through another decision object, cannot grant a free reroll.

For `mode = 'roll'`, the profile must know at least six distinct equipment types
for the selected skill. Resolution rolls against that skill once. Success removes
the familiarity penalty; failure leaves it in place, and ordinary practice remains
available. The stored `recognitionCheck` preserves the outcome. A blocked assessment
does not count as an attempt or consume randomness.

For `mode = 'similar'`, `'improved'` or `'obsolete'`, set `similarTo` to another
known familiarity of the same owner and skill. This is the author's explicit
judgment about the relationship between the two types; the library validates the
comparison and grants recognition without a roll. It does not infer similarity
from item labels, numeric technology levels or adjacent catalogue entries. All
three modes remove only unfamiliarity. The independent technology modifier still
applies to the actual equipment level.

A target retains one recognition decision, including a failed roll. Authors should
reuse that record for future encounters with the same type. Reopening a failed
decision based on new narrative evidence is not currently an implemented procedure.
Retargeting a record after practice or recognition is rejected. Catalogue-specific
recognition exceptions still need their own integrations.

Authored native cases cover approval and experience gates, known comparison types,
ownership, deterministic success and failure, no repeat rolls, unchanged technology
penalties, exception rollback, undo and cross-process continuation. See
`test_recognition`, `test_recognition_failure`, `test_recognition_similarity` and
`test_recognition_persistence` in `tests/expanded.py`. These checks remain unrun.


## Character/social subset authoring

Create `RpgExpandedSkill` definitions with an `id`, governing `attribute`,
`difficulty` (0 easy, 1 average, 2 hard, 3 very hard), optional `techLevel`,
`specialty`, `defaults` and `prerequisite`. Each default edge is `[skill, penalty]`.
Give the profile one owned `RpgExpandedTraining` per skill, containing `skill` and
`points`. `defaultFrom` explicitly selects a paid-up default basis; the engine
rejects cycles and does not treat an unpaid default chain as training.

`rpgExpandedSkillLevel` and `rpgExpandedSkillCost` expose the point table.
`profile.skillScore(skill)` combines legal trained and default scores. Optional
wildcards require `rules.wildcardSkills`; they use the very-hard difficulty and
triple cost. Character validation and learning reject purchased wildcard skills
when the campaign option is disabled. Definition validation rejects a wildcard
with any other difficulty or with attribute/skill defaults, including before a
score is requested.

`RpgExpandedPrerequisite` supports skill, trait, all and any requirements with
explicit definitions. The learning hooks also reject unsupported technology-level
access. Use `skillLearningWithTeacherReason` for advancement above personal
technology where an appropriate teacher is required; do not bypass it by writing
training points directly during play.

Techniques, optional specialties and relative-skill contexts are exposed in the
source-derived API reference. Their prerequisites and default bases must be
explicitly authored. Optional specialties are not a free extra broad skill.
Owned `RpgExpandedFamiliarity` records track equipment-type practice and recognition;
practice consumes the shared clock and recognition retains failure as well as
success. An authored equipment type is an identity, not a second inventory item.

The module supplies mechanisms for authored definitions, not a full skill catalogue.
The Town Registry's two skills are original integration examples. Source mapping:
`full-2008` B168-B175, B230-B233. See the [prerelease validation record](../releases/v1.1.0-alpha.1.md).

The prerelease record applies to the original subset. Checks for this merged
expanded suite remain paused.

### Surgical training and defaults

`RpgExpandedSurgerySkill` supplies the IQ/Very Hard medical skill from `full-2008`,
B223. Set its `techLevel`. Its generated default edges use same-technology
purchased First Aid (-12), Physician (-5), Physiology (-8) or Veterinary (-5),
identified by the neutral skill IDs. The shared resolver selects the best legal
paid or default level, respects familiarity and personal technology restrictions,
and does not allow an untrained default to become another default's source.
Explicit authored `defaults` remain available in addition to these source edges.

Learning requires a purchased First Aid or Physician skill at the same technology
level. The class supplies this through `learningPrerequisiteReason`, alongside
any authored prerequisite tree. Under B169/B173 this learning requirement does
not prevent using the unpurchased skill through a legal default. The health
library's `RpgExpandedSurgicalAssessment` composes that skill score with surgical
conditions and the Physician-absence penalty. Medical defaults do not themselves
count as Physician training.

`defaultEdges(profile)` is an extension point for generated skill-to-skill edges;
its default implementation returns the existing authored `defaults` unchanged.
`learningPrerequisiteReason(profile)` defaults to no additional constraint. Neither
hook may mutate state or consume randomness. The surgical fixture specifies all
four source defaults, learning versus use, double-default rejection and unfamiliar
skills. It remains unrun. Operation execution remains incomplete, so this catalogue entry is still
partial. Surgical assessment now applies B168 technology mismatch penalties
through `rpgExpandedTechnologyModifier`, which lives in the expanded foundation
so health and skills use one implementation. The public function and its results
are unchanged.

## Nature and survival defaults

`RpgExpandedNaturalistSkill` supplies the B211 IQ/Hard definition and IQ-6
default. Set `planet`, `planetType` and a `specialty` equal to the planet ID.
Purchased Naturalist on another planet of the same type supplies the printed
-4 default. Different planet types supply no cross-planet edge. An applicable
Biology source can be supplied as an explicit `[skill, -3]` default edge through
the existing authored-default interface; automatic Biology catalogue selection
and validation remain pending.

`RpgExpandedSurvivalSkill` supplies the B223-B224 Perception/Average definition
and Perception-5 default. Set its planet, planet type and terrain specialty. Its
resolver discovers purchased Naturalist for the same planet at -3, and purchased
Survival specialties using the printed relationships: -3 between land types,
-4 between aquatic types, and -4 for the coast/lagoon and swamp/river crossings.
The same terrain on another planet of the same type is -4; a terrain change
adds its normal penalty to that -4. No edge crosses different planet types.
Planet type is an author-supplied classification ID, not inferred from a name.

Terrain IDs are `arctic`, `desert`, `island-beach`, `jungle`, `mountain`, `plains`,
`swampland`, `woodlands`, `bank`, `deep-ocean-vent`, `fresh-water-lake`,
`open-ocean`, `reef`, `river-stream`, `salt-water-sea` and `tropical-lagoon`.
Special man-made terrains require a separate adapter and are rejected by this
standard-terrain class. These IDs describe the authored skill instances; existing
catalogue identifiers and abridged definitions are unchanged.

`rpgExpandedSurvivalDefault` exposes the pure terrain/world relationship for
assessment. Both skill classes use the existing paid-source resolver, so an
untrained default cannot become a second default source. Paid improvements,
attribute-default caps and familiarity restrictions remain in that resolver.
Conflicting type labels for the same planet are rejected.

Plant foraging accepts these expanded definitions without requiring a purchase
of the target skill. The same daily attempt category still applies. Other nature
uses, daily wilderness injury, dependent care, terrain/body compatibility,
trapping and complete catalogue integration remain pending.
`tests/fixtures/expanded-nature-defaults.t` covers attribute, terrain, aquatic,
crossing, world and untrained-source cases; assertions are authored, unrun.

The health module now supplies [daily wilderness survival](health.md#daily-wilderness-survival)
using the expanded Survival definition. It enforces the ten-dependent limit and
commits independent failure injuries. This partially addresses the earlier daily
wilderness-procedure gap; trapping, route-finding, full catalogue adaptation and
special body/terrain rules remain pending.

### Buying technique improvements (full-2008, B229-B230)

Set `rules.techniques = true` explicitly before using technique scores or
purchases. Merely including the skills library leaves this option disabled.
Existing integrations that call `RpgExpandedTechnique.score()` must opt in.

An owned `RpgExpandedTechniquePurchase` names a profile, a technique already in
its `contributions`, and the desired total `targetPoints`. Supply a unique id,
`approved`, `evidence`, `practicedAction` and `distinctFromCoreAction`. The author
approves a specific action, its difficulty, default and cap; a technique cannot
replace buying the parent skill's core action. Optional additional requirements
use the technique's `purchasePrerequisite`, a `RpgExpandedPrerequisite` tree.
The existing default-chain validation requires paid parent skills and rejects
cycles and invalid ownership before purchase.

`assess()` is pure. `apply()` spends the difference from the current investment,
increments the shared development revision, and saves one owned receipt in
`profile.techniquePurchases`. It requires downtime by default and respects both
learning restrictions and reserved advancement spending. Average techniques
start improving at one point; Hard techniques require two points for their first
improvement, then one point per further level. A parent skill increase still
raises the technique without a separate charge. Caps are relative to the parent;
`maximumAboveSkill = nil` remains explicitly uncapped.

Replay returns the original receipt without spending again, including after a
later purchase. Changing a completed request's bound definition is rejected.
The fixture covers costs, caps, opt-in, author approval, learning restrictions,
insufficient funds, parent improvement, rollback, undo and save continuation.
These fixtures remain unrun. The broader technique catalogue, special contextual
effects and temporary modular acquisition remain incomplete; this purchase
interface does not supply those procedures.

### Contextual technique checks

Use `RpgExpandedTechniqueContext` with `rpgLiteScore` for preview and
`rpgLiteCheck` for execution. Set `technique` and set `skill` to the root parent
skill, even when the technique defaults to another technique. For an attribute
root, leave `skill` nil and set `attribute` to that root attribute. Mismatched
roots and ownership are rejected before a random draw. Campaign technique
opt-in is still required.

The technique supplies the unmodified base; the shared scoring path then applies
parent-skill equipment, familiarity, technology, language, trait, injury and
other ordinary context modifiers once. Set the context fields for the actual
action rather than copying a previously adjusted score into `modifier`. Parent
improvements and technique investments are reflected at assessment time. The
check uses the existing random stream, immediate luck handling and transaction
state. It does not itself spend action time or apply a skill-specific consequence.

Relative-attribute and fixed-base technique contexts are explicitly unsupported.
Special critical tables, cinematic eligibility and individual technique effects
still need their owning procedure; the standard success check does not implement
those effects. Fixtures exercise stacked modifiers, nested defaults, invalid
contexts and persistence, but remain unrun while checks are paused.

### Cinematic technique permission (full-2008, B230)

Mark cinematic definitions with `cinematic = true`. Choose the campaign's
`cinematicTechniquePolicy` explicitly: `unrestricted` permits their use;
`restricted` requires a specific training or mastery permission. With no policy,
marked techniques reject both purchases and default use. Parent techniques in a
default chain must also qualify.

For restricted use, provide `cinematicRequirement` as a trait prerequisite leaf
for `advanced-martial-training` or `weapon-mastery`, with `cinematicApproved` and
`cinematicEvidence`. The author must establish that the selected permission
covers this technique, including a mastery trait's weapon scope. The engine
checks actual possession; this contract does not implement the still-incomplete
weapon-mastery catalogue or infer its scope from a name. Separate requirements
for purchasing a technique remain in `purchasePrerequisite`.

`ordinaryPistolException` is accepted only for the `paired-weapon-attack`
definition: Hard, parent Guns/pistol with a technology level, default -4 and cap
at the parent skill. It bypasses the cinematic permission requirement, preserving
the printed ordinary-campaign exception. It does not enable other firearm
specialties or implement simultaneous attack resolution.

Fixtures cover missing policy, missing permission, possession, unrestricted
use, default-chain restrictions and the specific pistol exception. They remain
unrun; catalogue and weapon-scope integration remain partial.

Familiarity practice now binds its target and progress across elapsed-time hooks.
A hook that changes the equipment type, recorded progress, eligibility or exact
elapsed interval causes rejection before credit. Let that exception reach the
engine transaction boundary so time and hook effects roll back together. This
also prevents a hook from silently completing the same familiarity twice.

Ancestry single-skill bonuses apply through `ancestrySkillModifier(skill)` after
trained/default resolution. Paid skill calculations stay unmodified for default
chains and advancement prices. See [ancestry bonuses](templates.md#single-skill-ancestry-bonuses)
for ownership, specialty handling and current limitations. New assertions remain
unrun while checks are paused.

Catalogue talent checks now dispatch through
`catalogueTalentCheckModifier(skill)`. With expanded traits installed, the three
existing catalogue talents use their complete printed membership lists, including
optional specialties identified by their parent. Trained and default contextual
checks receive the bonus once. Inactive or mitigated purchases give no bonus.
The Lite profile retains its original membership and contextual arithmetic.

With the skills module installed, `catalogueTalentSkillModifier(skill)` adds the
catalogue bonus to an available raw `skillScore`. The contextual hook then returns
zero, avoiding a second bonus. Relative and fixed-base checks and skill-based
techniques inherit that raw bonus. Skills without a legal purchased/default level
remain unavailable. Without the skills module, expanded traits retain the
contextual bonus path.

`rpgExpandedPaidSkill` remains the investment-only calculation, keeping talent
levels out of point prices. Transfer of source-skill talents through paid default
chains and custom skill groups still needs dedicated
source verification and implementation. The raw, contextual, fixed-base and
technique assertions are authored but unrun.

Minimum-level skill prerequisites use purchased training plus persistent catalogue
talent and ancestry skill modifiers (full-2008, B89, B169, B452). At least one
purchased point is still mandatory. A better default, equipment, reaction or other
situational check modifier cannot qualify the character. Checking the prerequisite
does not spend points or time or roll dice. Boundary and no-training fixtures are
authored but unrun while checks are paused.

Expanded profile validation rejects duplicate catalogue talent purchases even
when the requested skill lies outside the talent's group. Each purchase remains
limited to four levels, including inactive or mitigated purchases. Optional
specialties inherit their parent skill's catalogue membership for both skill
bonuses and study time. The corresponding fixtures are authored but unrun.


## Multiple attribute defaults and free-fall skill

Expanded skills may declare `attributeDefaults` as `[attribute, penalty]` pairs
in addition to the existing single `defaultAttribute`/`defaultPenalty` interface.
The shared resolver considers each legal attribute default, caps the underlying
attribute at 20 before applying its penalty, then selects the best purchased or
default level. No default creates purchased training or satisfies a paid-skill
prerequisite. Wildcards reject attribute defaults just as they reject skill
defaults. Invalid attribute identifiers and positive default adjustments reject.

`RpgExpandedFreeFallSkill` supplies dexterity/average with dexterity -5 and health
-5 (`full-2008`, B197). Its catalogue definition rejects altered attributes,
difficulty, technology qualification, wildcard mode and extra default edges.
Owned free-fall exposures use this class when no skill is supplied. Supply the
same skill object used by a character's training when purchased ability applies.

While an owned free-fall exposure remains open, dexterity-based checks use the
lower of their ordinary base and the character's free-fall skill score. The
shared score path applies this cap before ordinary situational modifiers, keeping
health/shock/equipment adjustments from being charged twice. A character who has
adapted still uses the cap until returning to normal gravity. This does not
rewrite the purchased skill or its point cost. An active exposure, including a
healthy one, must be closed before opening another for the same character.

The existing whole-profile behavior is unchanged when no exposure is open. A
neutral identity hook in the Lite score path permits the optional environment
rule without adding random draws. The orientation-sense trait supplies the printed spatial-awareness bonus through
the shared skill score. Integration with all movement/vehicle subsystems remains pending. The minimal fixture
[`expanded-free-fall-skill.t`](../../tests/fixtures/expanded-free-fall-skill.t)
contains independent default/cap values and saved-game continuation; it is unrun.


## Ground-vehicle operation

`RpgExpandedDrivingSkill` implements the nine B188 specialties using
`specialty`: `automobile`, `construction-equipment`, `halftrack`, `heavy-wheeled`,
`hovercraft`, `locomotive`, `mecha`, `motorcycle` and `tracked`. Supply `techLevel`.
The skill is DX/Average, with DX−5 and IQ−5 attribute defaults. Directed defaults
use actually purchased compatible sources through the existing resolver; this
does not permit chains of unpaid defaults. Automobile/heavy-wheeled and
halftrack/tracked use their paired −2 defaults. The other listed cross-specialty
penalties remain distinct. Motorcycle uses Bicycling−4, while mecha additionally
allows same-technology Battlesuit−3. Mixed legacy Driving sources at the same
technology reject rather than silently assuming expanded specialty semantics.

`RpgExpandedDrivingContext` uses the ordinary shared score/check interface. Its
`task` is `operation`, `map-reading`, `simple-malfunction` or `traffic-rules`; the
latter three use IQ with the existing relative skill level. Specify
`conditionsPenalty`, `repairPenalty`, `unfamiliarControls` and
`unfamiliarTypePenalty` from actual authored conditions. Negative condition and
repair penalties must be at least −2; an unfamiliar type penalty must be at
least −4. Unfamiliar controls impose −2. Nonzero penalties require `evidence`.
This context rejects an additional generic familiarity record to avoid charging
the same unfamiliarity twice.

`expanded-driving.t` / `test_driving` specify selected default boundaries, IQ
task substitution, combined modifiers and invalid penalty rejection. Fixtures
remain unrun. Per-vehicle familiarity acquisition, minimum-strength effects,
control-loss consequences and vehicle movement integration remain outstanding.


The typed Driving definition rejects changes to its prescribed attribute-default
list and additional authored default edges. Use an explicitly authored skill type
for a campaign variant rather than silently changing the published definition.
The Driving fixture now sets the character's technology to match the skill;
untrained access to higher-technology skills still follows the shared restriction.

`expanded-driving-matrix.t` / `test_driving_matrix` enumerate all 81 directed
specialty pairs against an independently specified expected-score matrix. They
also cover Bicycling and Battlesuit sources, technology mismatch, an unpaid
source and altered attribute defaults. These are authored expectations, not
passing validation results: checks remain paused.


## Owned driving familiarity

`RpgExpandedDrivingFamiliarity` specializes the existing owned familiarity
record for `controls` (−2) or `vehicle-type` (−4 or a more severe authored penalty).
Supply the owner, typed Driving skill, authored `equipmentType`, availability and
evidence. These records use the B169 eight-hour practice duration. Control and
type records may share one vehicle identity; duplicate records for the same
aspect reject. Existing generic familiarity duplicate rules remain unchanged.

Set `controlsFamiliarity` and/or `typeFamiliarity` on a Driving context. Matching
manual unfamiliarity penalties reject, preventing a double charge. For practice
on both aspects of the same vehicle, call
`rpgExpandedPracticeDriving(profile,skill,records,seconds)`. It preflights every
record, advances the shared clock once and updates all remaining practice only
after confirming unchanged conditions. Fully known records do not charge time
again. Ordinary rollback, undo and save mechanisms own the state.

`expanded-driving-familiarity.t` / `test_driving_familiarity` specify both initial
penalties, one eight-hour time charge, penalty removal, rollback, undo, saved
continuation and conflicting manual input. Fixtures remain unrun. The author
still establishes vehicle availability; this is not automatic native vehicle
interaction or control-loss resolution.


## Small-watercraft operation

`RpgExpandedBoatingSkill` covers `large-powerboat`, `motorboat`, `sailboat` and
`unpowered` at an explicit `techLevel` (full-2008, B180–B181). It is DX/Average
with DX−5 and IQ−5 defaults. Typed same-technology specialties supply their
directed defaults through purchased source training. Only large powerboat also
receives Seamanship−4. Legacy boating sources are rejected where expanded
specialty semantics are required. Crewed-bridge ships require other skills.

`RpgExpandedBoatingContext.eventKind` is `enter`, `get-underway`, `dock`, `hazard`
or `routine`. `checkRequired(profile)` requires a boarding check when the target
skill is used at default, and checks for getting underway, docking and hazards.
Routine operation does not create an additional check. Calling the shared check
interface for an unneeded check reports `boating-check-not-required`.

Set `conditionsPenalty` to zero or −3 or worse, with evidence for adverse
conditions. The inherited owned familiarity record supplies the separate −2
unfamiliar-boat penalty and existing practice behavior. These are modifiers and
check requirements; falling into water, docking, movement and control-loss
consequences still require integration with their actual world actions.

`expanded-boating.t` / `test_boating` specify the full 16-pair default matrix,
boarding requirements, ordinary hazard modifiers and the restricted Seamanship
default. Fixtures remain unrun while checks are paused.


## Breathing efficiency skill

`RpgExpandedBreathControlSkill` supplies the fixed HT/Hard, no-default definition
from full-2008 B182. Custom defaults, specialties, alternate attributes and
technology levels reject. The exploration library's
`RpgExpandedBreathPreparation` can execute its trained check and apply the
breath-duration bonus through an owned receipt. The separate `RpgExpandedBreathingRecovery` operation implements two-minute
quiet-rest checks through the shared fatigue ledger. The `test_breath_preparation` fixture
covers this integration and remains unrun.


## Physiology catalogue skill

`RpgExpandedPhysiologySkill` implements the IQ/Hard skill at an explicit
`techLevel` and species `specialty` (full-2008 B213). Use a species identifier even
in a single-species setting so medical knowledge receipts identify their subject.
The skill supplies IQ-6 and same-technology defaults from purchased diagnosis,
physician or surgery at -5. The existing resolver rejects chained untrained
defaults and supports purchased improvements through `RpgExpandedTraining`.

Cross-species defaults are author decisions, not a universal table. Add
`RpgExpandedPhysiologyDefault` objects to the target skill's `speciesDefaults`.
Each requires a typed `source` skill with a different specialty at the same
technology, an explicit nonpositive `penalty`, `approved = true`, and concrete
`evidence` explaining the relationship in this world. Duplicate sources reject.
No relationship is assumed merely because another physiology specialty is trained.
A source with no purchased training cannot supply a default.

This typed skill can be used by `RpgExpandedPhysiologyCheck`, including the
body-reading, first-aid, physician-healing and surgery integrations. Existing
explicitly authored skill objects remain supported. `test_physiology_skill`
provides independent expectations for each printed default, mismatched technology,
authored relationships, untrained sources and invalid definitions. These fixtures
and the updated medical integration fixtures remain unrun while checks are paused.


## Physician and first-aid catalogue skills

`RpgExpandedPhysicianSkill` supplies IQ/Hard, IQ-7, same-technology first aid-11
and veterinary-5 defaults (full-2008 B213). Set an explicit `techLevel`.
At level 4 or below, set `earlyMedicineApproved` and provide concrete
`earlyMedicineEvidence` explaining why scientific medicine exists in the setting.
This setting decision does not grant equipment, qualifications or treatment access.

`RpgExpandedFirstAidSkill` supplies IQ/Easy and IQ-4 (full-2008 B195). Purchased
physician training at the same technology defaults without a penalty; veterinary
defaults at -4. Purchased `traditional-treatment` training without a technology
qualification also defaults without a penalty, retaining that source skill's
attribute and rating. This reflects the non-technological skill in B192.
The shared resolver requires purchased sources and prevents untrained default chains.

Use these types with existing physician practice, periodic healing and first-aid
operations. Existing authored skills remain compatible. These definitions do not
provide drug identification or formulation. The owned post-bandaging first-aid
treatment now supports an explicit diagnosis
requirement for unusual problems; other first-aid operations still need that
integration. Drug procedures remain incomplete.
`test_medical_skills` specifies each default, incompatible technology and the
low-technology author contract. Medical integration fixtures also use these types.
All new fixtures remain unrun while checks are paused.


## Biology and native planet types

`RpgExpandedBiologySkill` implements IQ/Very Hard biology at an explicit
`techLevel` (full-2008 B180). Set `specialty` to `habitable`, `gas-giant`,
`hostile-terrestrial`, `icy-small-body`, `ice-covered` or `rocky`. Set the
character's `nativePlanetType` to the type where they grew up. IQ-6 applies only
when that background matches the requested specialty. An unspecified background
grants no IQ default; it does not silently assume familiarity with a world.

Purchased biology at the same technology defaults between planet types at -4.
Purchased `RpgExpandedNaturalistSkill` for a planet of the matching type provides
its printed -6 default. Untrained source skills cannot provide default chains.
The common-animal physiology knowledge check can use this typed biology skill
with its existing -4 modifier and an explicitly matching planet type.

The new `attributeDefaultAllowed(profile)` hook preserves existing defaults by
returning true unless overridden; optional specialties delegate to their parent.
Biology's optional subfields use the explicit approval contract below. `test_biology_skill` specifies native and foreign
attribute defaults, purchased scientific and practical defaults, incompatible
technology, untrained sources and preview purity. The body-physiology fixture
now uses typed biology. All affected fixtures remain unrun.


## Optional biology subfields

Use `rpgExpandedBiologySubfield(parent, id, subfield, approved, evidence)` to
create a `RpgExpandedBiologySubfield` tied to one typed biology parent. It uses
IQ/Hard, the parent's technology and prerequisites, and its own training slot.
Supply approval and concrete evidence that the field is coherent at this
technology (full-2008 B169–B170, B180). Botany, ecology and genetics are examples;
other authored scientific fields are allowed. Level 6 is a common historical
threshold in the source, not a universal prohibition on earlier specialties.

General biology defaults to purchased subfield training at -2. Another planet
type at the same technology defaults to that training at -6: its -4 biology
relationship plus the -2 optional-specialty adjustment. This works even when the
general parent has no purchased training. It does not permit arbitrary untrained
default chains or grant a general biology IQ default on a foreign world.
The factory grants no points and does not decide which subfield applies to a task.
Authors select the skill appropriate to the question, using the general parent
for work outside the subfield. The parent definition is validated whenever the
optional specialty is validated.

`test_biology_subfields` specifies direct, general and cross-planet ratings,
invalid approval/evidence/parent definitions, rollback and undo. Fixtures remain
unrun; catalogue completion still requires the paused validation work.


## Biology defaults for practical nature knowledge

`RpgExpandedNaturalistSkill` now discovers purchased biology training for its
`planetType` and supplies the printed Biology-3 default (full-2008 B211).
Its existing planetary specialization and same-type planet-to-planet defaults
remain in place. Use the same neutral planet-type identifiers as the biology
catalogue. A biology specialty for another planet type does not directly supply
this default, and an untrained biology skill cannot create a default chain.

Purchased optional biology subfields supply the same practical knowledge at -5,
combining the printed -3 with the optional-specialty adjustment of -2. The
scientific parent need not be trained. These scores feed existing naturalist
operations, including plant foraging, without a separate time or food ledger.
Authored site availability, daily attempt limits and poisoning consequences still
apply. `test_biology_foraging` covers scoring, preview, rollback, undo and replay
through the owned forage operation. These fixtures remain unrun.


## Veterinary skill and animal-care context

`RpgExpandedVeterinarySkill` provides IQ/Hard veterinary skill at an explicit
`techLevel`, without an IQ default (full-2008 B228). Purchased animal handling
of any specialty defaults at -6; purchased physician or surgery at the same
technology defaults at -5. Optional animal-type specialties can use
`rpgExpandedOptionalSpecialty` with author approval and separate training.

`RpgExpandedVeterinaryContext` adds the printed +5 when the animal knows and
trusts the caregiver, and `unfamiliarPenalty` of -2 or worse for an unfamiliar
type. Supply the `animal` profile, `animalType`, `approved` and concrete `evidence`
for those facts. Leave the penalty at zero for a familiar type. The context
rejects a -1 unfamiliarity penalty and a second familiarity receipt. An optional
specialty must match the animal type; otherwise use its general veterinary parent
and the normal -2 default. Use through `rpgLiteScore` or `rpgLiteCheck`.

This context assesses and rolls competence; it does not heal, prescribe, operate
or advance care time. Animal treatment must still be connected to owned health
procedures and their shared ledgers before that part of the catalogue is complete.
`test_veterinary_skill` specifies each default, absent IQ default, trust,
unfamiliarity, combined modifiers and optional-specialty scoring. Fixtures remain
unrun while checks are paused.


## Animal-handling catalogue specialties

`RpgExpandedAnimalHandlingSkill` implements IQ/Average, IQ-5 animal handling
with a required animal-category `specialty` (full-2008 B175). It has no technology
level. Authors choose categories appropriate to the animals' intelligence and the
setting; the engine does not assign fictional species to a biological taxonomy.

Populate a target skill's `relationships` with `RpgExpandedAnimalHandlingDefault`
objects. Each names a typed `source` specialty, `relationship` (`same-order`,
`different-order` or `distant`), `approved` and concrete `evidence` for that
classification. The corresponding penalties are -2, -4 and -6. Duplicate sources
reject. Only purchased source training supplies a default; an untrained specialty
cannot pass along its IQ default. Any purchased animal-handling specialty also
supplies the veterinary default at -6.

These skills can be passed to existing animal training, task and calming
operations. Their existing author permissions and animal-state requirements still
apply. This catalogue definition alone grants no training, command compliance or
combat effect. `test_animal_handling_skill` specifies all relationship penalties,
untrained sources, missing approval and the veterinary connection. Fixtures remain
unrun; combined animal-procedure and combat validation remains incomplete.


## Psychology disciplines and species defaults

`RpgExpandedPsychologySkill` implements IQ/Hard psychology with IQ-6 and
sociology-4 defaults (full-2008 B216). Set the species `specialty`.
The default `discipline` is `general`. Campaigns using the optional split select
`applied` or `experimental` and provide `splitApproved` and `splitEvidence`.
Purchased experimental psychology supplies applied psychology at -5; there is no
reverse discipline default. The attribute default remains available.

Cross-species defaults require explicit `RpgExpandedPsychologyDefault` entries
in `speciesDefaults`, with a typed `source`, nonpositive `penalty`, approval and
evidence. Relationships must remain within the same discipline. This prevents a
species relationship from silently bypassing the directional discipline rule.
Experimental training does not directly supply the applied-psychology defaults
used by lie detection and body reading, and an untrained applied intermediary
cannot create a default chain. Existing authored skill definitions retain their
previous behavior.

Individual inference uses the owned assessment documented in the social guide;
situational modifiers use the context below. `test_psychology_skill` specifies the one-way
discipline default, attribute fallback, social-inference default eligibility and
campaign-approval rejection. Fixtures remain unrun while checks are paused.


## Individual psychology contexts

Use `RpgExpandedPsychologyContext` with a typed general or applied psychology
skill, a `subject` profile and matching `subjectSpecies` (full-2008 B216). Set
`purpose` to `prediction`, `diagnosis` or `exploit-weakness`. Supply `approved`
and concrete `evidence` establishing the subject and relevant circumstances.
Experimental psychology cannot directly serve as the skill for this context;
select the applied definition to use its eligible default instead.

`knownWell` and `knownPersonalityType` each add +3. The authored `empathyModifier`
may be -3, 0, +1 or +3; a nonzero value is allowed only for diagnosis with
`subjectPresent`. The author establishes the applicable empathy ability; the
context does not infer or purchase it. Active purchased callousness subtracts 3
except when the purpose is specifically to identify exploitable weaknesses.
Callousness is read from the profile, so authors should not repeat that penalty
in `modifier`. Keep other justified situational adjustments there.

The context computes and rolls competence through existing skill interfaces.
It does not choose a character's behavior, grant knowledge or resolve treatment. The social library supplies the owned assessment operation for authored findings. `test_psychology_context` covers each printed
modifier, combinations, active callousness, its exception and inapplicable empathy
or discipline rejection. Fixtures remain unrun while checks are paused.


## Sociology catalogue skill

`RpgExpandedSociologySkill` supplies IQ/Hard, IQ-6, Anthropology-3 and applied
Psychology-4 defaults (full-2008 B221). It has no technology level or required
species specialty. Only purchased source training provides a default; purchased
optional source specialties incur the additional -2 from B170. Experimental
psychology is not treated as direct applied training.

General sociology can supply psychology's -4 default for an explicitly selected
species. Older authored sociology definitions with a matching species specialty
remain accepted, but a species specialty is no longer required. The resolver
still cannot chain an untrained sociology default into psychology.

This definition supplies skill arithmetic. Large-group cooperation, social
pressures and contact between societies still require owned authored-finding
operations and appropriate access/evidence. `test_sociology_skill` specifies the
printed defaults, the incoming psychology default, optional-source propagation
and prevention of untrained chains. Fixtures remain unrun while checks are paused.


## Anthropology catalogue skill

`RpgExpandedAnthropologySkill` provides IQ/Hard anthropology for an explicit
species `specialty`, with IQ-6, Sociology-3 and Paleontology (human origins)-2
(full-2008 B175, B212). The latter source uses neutral `id = 'paleontology'`,
`specialty = 'human-origins'` and an explicit technology level. Other fossil-study
specialties do not directly supply that default. Only purchased source training
counts; optional source subfields receive the normal additional -2.

Add `RpgExpandedAnthropologyDefault` objects to `speciesDefaults` for related
species. Each requires a typed `source`, `penalty` from -2 through -5, author
approval and concrete relationship evidence. Leave the relationship absent for
unrelated species. The character can still use the printed IQ default; an absent
relationship prevents transfer of another species' purchased skill, not the
attribute fallback. Untrained sources cannot create default chains.

Cultural findings and predictions about rituals still need owned authored-result
operations. The definition alone supplies skill scoring. `test_anthropology_skill`
specifies every printed source default, correct fossil specialty selection,
related/unrelated species and untrained-source rejection. Fixtures remain unrun.


## Paleontology specialties and study conditions

`RpgExpandedPaleontologySkill` implements IQ/Hard fossil study at an explicit
technology level (full-2008 B212). Choose `microscopic`, `human-origins`, `plants`
or `animals`. There is no IQ default. Purchased same-technology biology defaults
at -4; other paleontology specialties at the same technology default at -2.
The human-origins specialty also defaults from purchased anthropology at -2.
Optional source subfields receive the normal additional -2 adjustment.

`RpgExpandedPaleontologyContext` accepts `task` as `recognition`, `habitat`,
`structure` or `age`, plus author approval and evidence that the specimen supports
that task. Microscopic study requires `laboratory = true` before a score is
available. For age estimation, supply the applicable `equipmentModifier` for the
laboratory facilities; this field rejects on other task types. Authors establish
access and facility quality. The expanded context can also apply an explicit
equipment technology level through its existing compatibility rules.

This interface supplies scoring and eligibility, not a generated fossil age or
scientific conclusion. Include exploration for owned specimen findings through
`RpgExpandedPaleontologyAssessment`. The exploration guide also describes
`laboratoryEquipment` for live ownership and access checks. `test_paleontology_skill` specifies printed defaults,
inter-specialty transfer, missing-laboratory rejection and age equipment scoring.
Fixtures remain unrun while checks are paused.


## Packing and caravan expertise

`RpgExpandedPackingSkill` supplies the full-2008 B212 IQ/Average skill with IQ-5
and purchased Animal Handling (`equines`)-5 defaults. Other animal specialties do
not supply that default. The definition has no required specialty or technology
level; ordinary optional-specialty source adjustments use the common resolver.

The exploration library's `RpgExpandedPackTrain` assesses the caravan's expertise.
Its `members` are `[profile, packingSkill]` rows, with `approved` and `evidence`
establishing participation. `assess()` returns `speedPercent` 100 when an available
member has skill 15 or higher, otherwise 80, including an empty packer roster.
`master` identifies the first qualifying participant. Duplicate participants reject;
dead, unconscious or stunned members cannot supply expertise. The pure assessment
spends no time or randomness. Apply its percentage once to the caravan's otherwise
normal travel speed; it does not assign loads or choose a route.

Owned packing rolls and difficult-animal handling prerequisites are documented in
the exploration guide. Hiking pace accepts this percentage through `RpgExpandedHikingConditions.packTrain`;
committed caravan movement remains incomplete. `test_packing_skill` specifies the
attribute and equine defaults, non-equine and untrained rejection, the 14/15 speed
boundary, unavailable packers and duplicate members. Fixtures remain unrun.

### Begging skill and local modifiers

`RpgExpandedBeggingSkill` supplies the IQ/Easy definition and ordinary defaults
from full-2008 B212: IQ at −4, purchased quick persuasion at −2, or purchased
public speaking at −3. The common resolver selects the best eligible default.
The skill has no technology level or specialty.

`RpgExpandedBeggingContext` requires `approved` and concrete `evidence` describing
the local crowd and personal presentation. It adds the profile's charisma level,
3 for an authored `pitiable` fact, `shynessPenalty` from −4 through 0, and an
authored `crowdModifier`. `invertAppearance` optionally subtracts the supplied
normal `appearanceModifier`; `extremeAppearance` prohibits this inversion. These
facts need author adjudication until all corresponding trait adapters exist.
Keep `interaction` false: this is a skill task, not a general reaction roll.

The context only assesses a score. It does not spend an hour, award money, or
resolve critical bonuses and legal or violent consequences. The social library supplies `RpgExpandedBeggingHour` for owned hourly execution;
critical incident settlement still requires author integration. `test_begging_skill` specifies default arithmetic,
modifier composition and forbidden appearance inversion; fixtures are unrun.

With the traits library installed, begging automatically receives active sympathy
and social-inhibition effects. Leave authored `pitiable` and `shynessPenalty`
unset when those purchased traits supply the effect. The context rejects duplicate
sources instead of stacking them. Appearance and crowd facts remain authored.

For purchased expanded appearance, set begging's `appearanceContext` to an
approved `RpgExpandedAppearanceReactionContext` and choose `invertAppearance`.
The subject must be the beggar; the observer and evidence describe the audience
whose appearance response applies. The context computes the B21 modifier and
negates it for B212. It respects visibility, compatibility, attraction and the
flat presentation options. Active tiers −5 and −4 prohibit inversion.

Leave raw `appearanceModifier` and `extremeAppearance` unset with this adapter.
Purchased appearance cannot be bypassed with a raw number. An audience containing
different observer responses still needs an authored selection or ruling; this
interface does not invent an averaging rule. Hourly receipts bind the selected
observer facts. Later character appearance changes do not recalculate completed
earnings, while rewriting the recorded audience facts rejects replay.
`test_begging_appearance` specifies inversion, exclusions and save continuation;
fixtures remain unrun.

### Disguise definitions and assessment

`RpgExpandedDisguiseSkill` implements the IQ/Average, technology-qualified skill
from full-2008 B187. Supply a technology level and species `specialty`. Ordinary
defaults are IQ−5 and purchased same-technology makeup−3. For physically similar
species, provide `similarSpeciesDefaults` rows `[sourceSkill, penalty, evidence]`
with penalties −2 through −4 and concrete physical-similarity evidence. The source
must be a purchased same-technology disguise skill of another species. The reserved
`'animals'` specialty cannot participate in these inter-specialty defaults.

`RpgExpandedDisguiseContext` requires approval and evidence for ordinary disguise
conditions. It applies authored equipment modifiers, a different-appearance
penalty from −1 through −5 (or zero), an explicitly supported `elasticSkin` +4,
and the actor's active distinctive-feature penalty. `sharedByCrowd` selects the
B22 crowd exception. A nonzero `sizeModifierDifference` is blocked until an
explicit exception adapter exists. Animal-specialty assessments require their
own procedure and are rejected by this context.

This is a pure score assessment. A prepared disguise still needs an owned
30–60 minute preparation procedure and separate observer contests; quick costume
changes, acting combinations and animal disguise procedures remain pending.
`test_disguise_skill` specifies printed defaults, similarity restrictions and the
actual score path through distinctive features. Fixtures remain unrun.

### Animal-disguise assessment

`RpgExpandedAnimalHabitsStudy` owns the required Naturalist recall for one
`animalType` and `encounter`. Give it an ID, profile, typed Naturalist skill,
approval and concrete evidence for `successMagnitude` and `failureMagnitude`,
each from 1–3. Resolution rolls once, storing the positive success adjustment or
negative failure adjustment; repeat calls reuse that result. The printed passage
does not set a recall duration, so this operation advances no time. An unavailable
actor is blocked. The health library supplies the shared action gate before the
recall roll, including exhausted effort and consciousness checks.

`RpgExpandedAnimalDisguiseContext` requires an animal-specialty disguise skill and
that profile's resolved study for the same encounter and animal type. It uses
+2 for `downwind`, −1 per additional animal for ordinary groups, or −1 per complete
ten animals for a `herd`, plus `skinConditionPenalty` from −3 through zero.
These replace the ordinary disguise context's modifiers. Author evidence confirms
the group consists of the same animal type and describes the approach and skins.
This assessment does not prepare a costume or settle whether the animals are
fooled. Preparation and observer resolution remain pending.

`test_animal_disguise` specifies signed recall outcomes, wind and skin arithmetic,
group-size boundaries, rollback, undo, reuse and save continuation. Fixtures are
unrun. The curated reference service supplied no in-scope clarification of the
ordinary preparation/observer-roll boundary; later-supplement material was not
used to fill that gap.


Animal-habits recall requires the health adapter at execution. A denied gate is
stored as the encounter's resolved permission outcome, with no Naturalist roll
and no usable disguise adjustment. Recovering later does not turn the same receipt
into a free reroll; a genuinely new authored encounter needs a new study. Replay
validates the owned gate and bound outcome. `test_animal_habits_health` specifies
exhausted denial, no extra skill draw, rollback, undo, save continuation and
rejection of a changed permission flag. Fixtures remain unrun.

### Theatrical makeup

`RpgExpandedMakeupSkill` implements full-2008 B206's technology-qualified IQ/Easy
skill, with IQ−4 and purchased same-technology disguise−2 defaults. The ordinary
resolver prevents chained defaults from supplying unpurchased source skills.
`RpgExpandedMakeupContext` names the subject and a concrete cosmetic
`presentation`, with approval and evidence. `heightChange` must be zero.
`prosthetics` requires effective equipment technology 6 or higher; without an
explicit `equipmentTL`, the skill's technology level is used.

The social library's `RpgExpandedMakeupApplication` owns the work. Supply an ID,
performer's profile, context, an authored `seconds` duration, material availability
and permission. The source gives no fixed makeup duration; the fixture's ten
minutes is an authored scene choice. Assessment validates restrictions and the
health gate before spending time. An allowed application advances the shared
ledger once and rolls once. Success installs the application as the subject's
`makeupPresentation`; failure preserves any prior presentation. A repeat call
returns the stored result without charging time or rolling again.

Cosmetic presentation does not change physical characteristics, purchased
appearance or identity knowledge, and it does not establish that an observer is
fooled. Toolkit access, quality and technology can use the equipment adapter. Consumable
inventory, physical removal operations, observer contests and native
action routes remain pending. The social guide documents recorded removal and
replacement through `end(evidence)` and `presentationReason()`. `test_makeup` specifies the disguise default, height and
technology restrictions, success/failure, rollback, undo and save continuation.
Fixtures remain unrun.
