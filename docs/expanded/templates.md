# Expanded templates

**Status: partial.** Character and ancestry packages. Neutral source: `full-2008`, B258-B263; B445-B454.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `RpgExpandedTemplate` — B258-B259; tested in `tests/expanded.py::test_numbers`.

The fresh-profile factory and occupational composition interface below are available. The full catalogue and remaining chapter procedures are not implemented. New composition checks are authored but unrun.

`RpgExpandedTemplate.create(rules)` creates a new profile with fresh training and
trait instances. Skill definitions may be shared as immutable definitions. This
factory currently handles basic/secondary scores, skill investments and traits
from the existing Lite catalogue. It validates the resulting character costs.
The ancestry score factory below supplies separate score accounting; ancestry trait exceptions and the full trait catalogue are not implemented. Explicit skill/trait choice groups are described below. It does not mutate or upgrade an existing character.

## Remaining source obligations

The [detailed template inventory](inventory/templates.json) covers the first text
pass over B258–B263 and B445–B454. Its entries are pending, including the supplied
sample packages. Printed totals are acceptance targets, not executable package
definitions. Their individual components, choices and cross-module effects still
need implementation and independent validation.

The expanded implementation must distinguish these composition rules:

- Occupational packages merge overlapping requirements at the highest required
  level and reject incompatible traits. Their suggestions remain customizable.
- Ancestry packages add their level modifiers, derive secondary scores in the
  prescribed order, and retain mandatory components. Conflicts require an
  explicit authored resolution and a recalculated price.
- Lenses declare compatible bases, mutually exclusive alternatives and component
  replacements. Choice groups must resolve both eligibility and cost before any
  investment is committed.

Ancestry skill bonuses, innate training and personal training must remain
separately identifiable while contributing to one final skill score. Ancestry
negative traits and personal replacement traits have different accounting rules.
Zero-cost features and prohibited traits still affect validation and play.

The composition function below handles the current factory’s occupational scores,
skills and Lite traits. Other operations in this list remain requirements. Template design recommendations, such as leaving some starting
points unspent, will remain guidance rather than mandatory character limits.


[Transformation requirements](inventory/traits-catalogue-k.json) replace native
ancestry contributions while retaining personal purchases. Conflicting physical
forms can suspend personal benefits without deleting them. Injury, fatigue,
crippling and conditions persist, with proportionally scaled health/fatigue losses.
The current fresh-profile factory cannot implement these transitions.

Adaptive forms require existing authored templates, purchased value capacity and
memorized identities. Omitting allowed mental disadvantages or ancestry intelligence
adjustments changes template value and must be checked against capacity. Ancestry
costs exclude the transformation ability itself when calculating its allowance,
preventing circular pricing. Every transition needs rollback and save coverage
before it can be considered implemented.

## Combining occupational templates

`rpgExpandedCombineTemplates(templates, rules, pointBudget, disadvantageLimit)`
creates a fresh profile from a nonempty list of `RpgExpandedTemplate` definitions
(B259). Each source template must be valid under its own declared budget. The
combined character uses the supplied final budget and limit; template point totals
are not added together or separately charged.

The highest basic attributes and actual secondary scores are retained. Secondary
adjustments are then recalculated against the merged attributes. For example,
combining DX 10/HT 12 and DX 12/HT 10 retains Basic Speed 5.5, although the final
DX and HT are both 12: its speed adjustment becomes −0.5. Adding the two original
speed adjustments would produce the wrong requirement and price.

For each shared skill definition, composition retains the highest purchased skill
rating implied by its source template's points and attribute. It calculates the
points needed at the merged attribute, with at least one purchased point (three
for a wildcard definition). A general skill that happens to have a higher default
is not treated as a second paid requirement. Matching Lite trait IDs and scopes
retain the higher required level, and incompatible catalogue choices are rejected.
Traits and training are freshly owned for every composition. Input templates and
other previously created characters are not changed.

Current composition supports the fields of the basic factory only. Definitions
with additional contributions, languages or equipment are explicitly rejected.
Technology settings must agree across the selected templates. Ancestry, lenses, composition without explicit resolution of required choices,
modifier-bearing trait definitions and rich conflict diagnostics remain pending.
Template authors must share the same immutable skill definition for requirements
that denote the same skill and specialty; distinct definition objects are distinct
investments under the existing skill identity contract.

The native cases in `tests/expanded.py::test_template_composition` cover order
independence, recalculated secondary costs, overlapping skills and traits, fresh
ownership, conflicting status choices, empty input, and below-average requirements.
These checks have not run while validation is paused.

## Technology settings

Set `campaignTL` on each template to the campaign's technology level. Its default
is 3 for compatibility. A `nil` `techLevel` inherits that campaign setting; an
explicit personal level instead contributes the normal five points per level of
difference to the shared character cost calculation. It is not a separate package
fee. Starting skill access is checked against the resulting personal level.

Composition requires all templates to agree on both campaign and personal levels.
It charges that difference once on the final profile. Mismatches return
`template-technology-conflict`; authors must resolve the definitions before
composition. The library does not silently combine a low-technology disadvantage
and a high-technology advantage. An authored exception to ordinary starting skill
access remains outside this interface.

`tests/expanded.py::test_template_technology` covers campaign inheritance, explicit
personal pricing, single charging during composition, mismatched settings and
rejection of an inaccessible starting skill. These cases are authored but unrun.

## Explicit choice groups

Add `RpgExpandedTemplateChoice` objects to `template.choiceGroups`. Each group has
an `id`, concrete `options`, `minimumChoices` and `maximumChoices` (both default
to one), and optional signed `minimumPoints`/`maximumPoints` bounds. Each
`RpgExpandedTemplateOption` has an `id`, an authored `eligible` flag, and the same
`skillRows` and `traitRows` formats as the basic factory. This currently supports
skill investments, Lite catalogue traits and score changes as described below;
extended trait specifications remain pending.

Call `template.createSelected(rules, selections)` with one row per group:
`[['focus', ['training']], ['background', ['limitation']]]`. Every group must be
present, including an explicit empty selection for an optional group whose minimum
is zero. Unknown or repeated groups/options, wrong counts, ineligible choices and
out-of-range point totals are rejected. Setting both point bounds to 15 expresses
an exact 15-point selection; setting both to −30 expresses a negative 30-point
selection. A selection's price is the sum of its components, without an extra
package charge or discount.

Only after resolving the choices does the factory construct and validate a fresh
profile. It stores `[group ID, option ID]` pairs in `profile.templateChoices` for
presentation and saved character provenance. Choice receipts grant no extra
abilities or restrictions on later advancement. Creating another character from
the same selections creates new investments and traits. Calling ordinary
`create(rules)` on a template with choice groups returns
`template-unresolved-choices` rather than silently omitting them.

Selected rows cannot duplicate a mandatory skill investment, and conflicting traits
are rejected by the normal template validation. More elaborate exchange options,
partial improvements to a mandatory skill/trait purchase and composing unresolved
choice-bearing templates still need explicit implementations. The
current author interface offers concrete alternatives; it does not infer option
eligibility from narrative labels.

`tests/expanded.py::test_template_choices` covers signed prices, exact point limits,
selection receipts, fresh ownership, unresolved and missing groups, duplicate and
ineligible options, wrong counts and selected trait conflicts. The cases remain
unrun while validation is paused.

## Attribute options

An option can specify `stChange`, `dxChange`, `iqChange`, `htChange`, `hpChange`,
`fpChange`, `willChange`, `perceptionChange`, `speedQuarterChange` and `moveChange`.
These are signed increments, defaulting to zero. The secondary fields change the
purchased adjustment, not an absolute final score. Thus +1 Strength raises its
derived health by one, while an additional `hpChange = 1` buys one further health
point. `speedQuarterChange = 1` buys +0.25 Basic Speed.

Option pricing uses the normal component prices and includes these increments in
the group's signed point total. For example, +1 Strength, +1 purchased health and
+0.25 Basic Speed cost 17 points. −1 IQ with +1 Will and +1 Perception costs −10,
keeping those two secondary scores unchanged. Selecting both costs seven points;
there is no extra charge for either option label. Final character validation still
checks secondary limits, prerequisites, total budget and the disadvantage limit.

`tests/expanded.py::test_template_score_options` covers these independent cost
examples, derived scores, source-template preservation and an invalid health
adjustment. The cases remain unrun while checks are paused.


## Character/social subset authoring

`RpgExpandedTemplate.create(rules)` produces a fresh profile, owned training and
owned traits. A template supplies primary/secondary scores, technology, budgets,
`skillRows` as `[definition, points]`, and `traitRows` as `[Lite ID, level, scope]`.
Unresolved `choiceGroups` are rejected by direct creation.

`rpgExpandedCombineTemplates` combines occupational packages using the supported
maximum-score procedure rather than charging duplicate purchases. It preserves
paid skill levels and computes the resulting secondary adjustments. Technology
levels must agree. Selection groups and signed score options are explicit authored
choices; use the source-derived interfaces to resolve them before creating a
profile. Apply social contributions to the resulting character and run full
creation validation again, as the Town Registry example does.

The trait factory currently supports existing Lite definitions. Broader authored
trait effects are not silently synthesized from template rows. Ancestry packages,
alternate body forms and the full reference's catalogue of templates are not
provided by this interim milestone.

Source mapping: `full-2008` B258-B259. Template composition, ownership and invalid
choice cases are included in the native validation suite.

The prerelease record applies to the original subset. Checks for this merged
expanded suite remain paused.

## Purchased self-control in template rows

With the traits module installed, `traitRows` also accepts
`['truthfulness', 1, scope, rating]` , `['curious', 1, scope, rating]` or `['cowardice', 1, scope, rating]`,
where `rating` is 6, 9, 12 or 15.
`rpgExpandedTemplateTrait(row)` resolves both the original three-field form and
this explicit four-field purchase. The latter creates a fresh
`RpgExpandedTruthfulness`, `RpgExpandedCuriosity` or `RpgExpandedDangerAvoidance`,
preserving its concrete trigger interface and the
selected rating. The existing three-field form retains shared catalogue behavior.
Other four-field trait IDs currently reject as `template-rated-trait-unavailable`;
the same rejection occurs when the traits module is absent.

For example:

```text
candidInvestigator: RpgExpandedTemplate
    traitRows = [['truthfulness',1,nil,9]]
;
```

The purchased disadvantage contributes −7 points to character accounting and the
negative-point limit. Choice options accept the same row and use that price for
their signed point bounds. No additional package cost is charged. Separate calls
create separate trait objects, so changing one character's rating cannot change
another character or its source template.

Composition deduplicates matching purchases once. Different ratings, or a mix of
shared and explicit rated purchases for the same trait and scope, reject with
`template-trait-purchase-conflict`. Resolve those requirements in the authored
templates before combining them; automatic selection between those conflicting
purchases is not implemented. These guards do not complete the broader modifier,
ancestry or full catalogue composition requirements.

Sources: full-2008, B121, B159 and B259. `test_template_composition` specifies the
four prices, fresh ownership, choice accounting, duplicate purchase handling,
conflicting definitions, unsupported IDs and disadvantage-limit rejection.
Assertions are authored and unrun while checks remain paused.

Four-field trait rows now support `compelled-aid` and `low-motivation`:
`[id, 1, scope, selfControlRating]`, with ratings 6, 9, 12 or 15. The factory
creates the concrete behavior class and retains the purchased rating. Composition
rejects conflicting ratings for the same trait instead of silently choosing a
price. Each creation produces fresh trait instances.

Templates create new, unfinished profiles. Finalize the assembled profile with
`RpgExpandedCharacterFinalization` to validate the complete character and record
its actual original disadvantage costs. The integration fixture covers concrete
types, independent instances, conflicting purchases and final cost capture; it
remains unrun while checks are paused.

Composition now reconstructs each supported trait purchase before adding it to
the output profile. Raising a duplicate trait to a later package's level no
longer mutates the intermediate profile that supplied it. Concrete rated behavior
classes and their costs are checked during reconstruction; unknown purchase
kinds require a supported factory rather than silently becoming plain traits.
The isolation fixture retains the intermediate profile and checks independent
levels and costs before and after a save; it remains unrun.

Every trait is reconstructed and its purchase checked, including duplicates that
will merge with an earlier package. Composition rejects differing active,
mitigated or skill-scope state with `template-trait-state-conflict`, and any
pending trait check (`nextCheck != 0`) with `template-trait-runtime-state`.
Resolve these states in the template definitions before composing a new
character. This avoids package-order-dependent behavior or silently dropping a
customized purchase. The isolation fixture specifies both package orders for
these cases; execution remains paused. Arbitrary custom trait methods are not a
supported template purchase interface.

## Combining packages with selected options

Pass an `RpgExpandedTemplateSelection` alongside ordinary templates to
`rpgExpandedCombineTemplates`. Set its `template` to the source package and
`selections` to the same `[group ID, [option IDs]]` rows accepted by
`createSelected`. Every selected package is fully validated, including option
eligibility, count and its own point bounds, before the combined profile is
returned. Passing a choice-bearing template directly still rejects unresolved
choices.

```text
selectedProfession: RpgExpandedTemplateSelection
    template = professionPackage
    selections = [['training', ['fieldwork']]]
;
// Compose [backgroundPackage, selectedProfession] using the ordinary function.
```

Selected traits and skills participate in the same highest-requirement merge as
mandatory components. They are not charged again as a package fee. Unselected
options grant no purchases; they remain in the original package definition for
author-directed later customization. This does not implement a later advancement
purchase or automatic application of unused options.

The result's `templateSelections` stores one `[source template, choice receipts]`
row per input, in input order. Choice receipts are the resolved `[group ID,
option ID]` pairs, so equal group IDs in different packages retain their origin.
`templateChoices` remains the receipt for a single factory selection. Changing a
selection input later does not rewrite the combined character's choices or
investments. Source definitions remain shared author definitions, not copies of
all available options.

Source: `full-2008`, B259. `test_selected_template_composition` specifies choice
pricing, duplicate merging, invalid selections, preserved prior results, undo and
cross-process save continuation. These assertions are authored and unrun.

## Personal occupational changes

`RpgExpandedTemplateCustomization.create(rules)` constructs a fresh character
from `template` and its `selections`, then applies approved personal changes.
Set `approved` and a nonempty `evidence` description for the author's permission.
This interface applies to occupational suggestions, not mandatory ancestry
components or an existing character's advancement.

- `removeTraits` contains `[trait ID, scope]` rows. Each must identify exactly one
  purchase; unknown, repeated or ambiguous removals reject.
- `removeSkills` contains the shared skill definitions to remove. Each must be
  present exactly once.
- `additions` is an eligible `RpgExpandedTemplateOption`. Its score changes are
  added to the fresh profile. Its skill rows add purchased points to an existing
  training slot or create a fresh slot. Repeated skill rows reject. Its trait
  rows create fresh supported purchases.

Remove an existing trait before supplying its replacement; adding a duplicate
is not an implicit upgrade. Skill points are additive here, unlike occupational
composition's highest-requirement merge. Removing and then reintroducing a skill
uses only the new investment. Existing skill learning and prerequisite gates
still apply to the completed profile.

The ordinary character validator checks the result's total cost, all personal
and occupational negatives together, trait compatibility and the five-personal-
quirk limit. Unused quirk slots remain empty. A package label adds no extra cost.
The source template and previously created characters are unchanged. The
interface neither spends advancement points nor advances time or randomness;
finalize the returned character separately. Language, equipment, contribution
and mandatory ancestry customization are outside this interface.

Source: `full-2008`, B258-B259. `test_template_customization` specifies additive
skill investment, replacement and removal, combined negative limits, excessive
quirks, permission and invalid-removal rejection, fresh ownership, undo and save
continuation. Assertions are authored but unrun while checks remain paused.

## Zero-cost prohibited purchases

`RpgExpandedTabooTraits` is an owned `RpgExpandedContribution` for an authored
ancestry prohibition (full-2008, B261 and B452). Give it a unique `id`, its
character `owner`, `approved = true`, and a nonempty explanatory `evidence`.
Install it in that character's `contributions`.

- `traitIds` prohibits possession of those trait IDs, even when inactive or
  mitigated. It does not grant a negative point allowance.
- `skills` prohibits purchased training in the specified shared skill
  definitions. An untrained default is not a purchased skill.
- `attributeRanges` holds `[attribute, minimum, maximum]` rows. Both endpoints
  are forbidden, with supported attributes ST, DX, IQ, HT, Will and Perception.
  Other secondary characteristics need separate interfaces.

Character validation rejects existing prohibited investments. Shared skill
learning gates reject new training before spending points or study time. Ordinary
trait and attribute development offers reject forbidden target purchases before
commit. These constraints contribute no points and do not automatically infer
prohibitions from anatomy or other traits. An author must supply the concrete
restrictions and their rationale.

This interface does not implement ancestry package costs, mandatory-component
composition, or arbitrary author-written purchase paths. Occupational composition
continues to reject profiles with contributions; it cannot silently discard these
constraints. Each character needs its own contribution instance.

`test_template_taboo` specifies zero cost, creation rejection, learning and
advancement gates, unchanged resources on rejection, undo, and save continuation.
Assertions remain unrun while checks are paused.

Will and Perception prohibitions also apply to the derived increases caused by
an IQ development offer. Assessment projects both scores with their existing
purchased offsets before any points are spent. Direct Will/Perception offers use
their explicit target. Ranges forbid their endpoints; targets outside the range
remain eligible under the other purchase rules. The prohibition is on possession
of a level, not on crossing intermediate levels during a single purchase.
The taboo fixture specifies both endpoints, direct and derived purchases, and
invalid existing secondary scores; these additions remain unrun.

## Ancestry score composition

`rpgExpandedCreateAncestryCharacter(personal, ancestries, rules)` creates a new
profile from an occupational template, explicit template selection or personal
customization. Each ancestry is an approved `RpgExpandedAncestryScoreTemplate`
with a unique `id`, explanatory `evidence`, and the ten score-change fields used
by template options. Empty ancestry input represents the zero-cost baseline.
Repeated ancestry IDs reject. The score-only class rejects trait and skill rows. Use `RpgExpandedAncestryTemplate`
for supported mandatory trait rows, as described below. Ancestry skills remain
unsupported.

Ancestry deltas add together. The factory adds the basic-attribute deltas first;
secondary scores derive from those totals, with personal and ancestry secondary
adjustments each applied once. For example, personal ST 11 and HP adjustment +2,
combined with ancestry ST +6 and HP +4, produce ST 17 and HP 23. Personal DX 12,
HT 12 and speed +1, combined with ancestry DX +2, HT +1 and speed −0.75, produce
Basic Speed 7.00. The package label has no additional price.

The owned `profile.ancestryScores` records source IDs and the combined deltas.
Character accounting separates personal and ancestry score components rather
than netting them before computing negative totals. Ancestry negative score
components are exempt from the personal disadvantage cap. Personal negative
purchases remain counted even when an ancestry bonus hides them in the final
score. Later personal advancement changes the final score and its personal cost
while retaining the original ancestry deltas. Changing the owned origins or
deltas causes a binding rejection; changing ancestry requires a future explicit
transformation interface.

An ancestry score template can explicitly declare `nonhuman = true`. An approved
nonhuman package exempts the completed character from the ordinary HP/FP, Basic
Speed and Basic Move adjustment limits (B16-B17). It does not exempt Will or
Perception from their limits. Those still require the campaign's explicit
`exceptionalCharacteristics` permission. Human packages and the empty baseline
retain ordinary limits. The owned ancestry receipt binds this classification
alongside its score origins.

The ancestry factory resolves personal options and changes, applies ancestry,
and validates the complete character once. Personal physical purchases that
need the approved nonhuman exemption are therefore allowed. A negative ancestry
cost can also bring the completed character within its point budget. The final
personal disadvantage cap, prerequisites, compatibility and characteristic
limits still apply. Public `create` and `createSelected` calls without ancestry
continue to validate the characters they return. The full trait catalogue, ancestry skills, size-based pricing modifiers,
omissions and transformations remain unfinished. Occupational composition rejects ancestry-bearing profiles
rather than losing their origin accounting.

Sources: `full-2008`, B261 and B451-B452. `test_ancestry_scores` specifies the two
printed secondary-score examples, separate personal/ancestry negative costs,
additive packages, zero baseline, a negative package with zero personal negative
allowance, personal advancement, binding rejection, undo and save continuation.
These assertions remain unrun while checks are paused.

The ancestry fixture additionally specifies nonhuman physical exemptions under
ordinary campaign rules, rejection of the same human package, retained Will and
Perception limits, and rejection of edited receipt classification. Assertions
remain unrun. This is a character-rule distinction, not an automatic inference
from size, appearance or a package's name.

Internal `assembleProfile` and `assembleSelectedProfile` methods construct
unvalidated intermediate profiles. They are implementation stages for the
validated factories, not ready-to-play creation APIs. Custom template subclasses
that participate in ancestry creation must put their construction changes in
these stages; overriding only `create` does not customize ancestry assembly.
The ancestry fixture covers ordinary, selected and customized personal purchases
that require nonhuman classification, a final-budget boundary, and rejection of
an invalid completed character without changing a previously returned profile.
These assertions remain unrun.

## Mandatory ancestry traits

`RpgExpandedAncestryTemplate` extends the ancestry score definition with
`traitRows` using the existing three-field catalogue rows or supported four-field
rated purchases. The factory creates fresh concrete traits, installs them on the
character, and records each purchase and its ancestry ID in the owned receipt.
Their ordinary executable effects remain available; there is no separate ancestry
trait balance or package fee.

Ancestry disadvantages contribute to the character's total value but are exempt
from the personal disadvantage cap. Ancestry quirks are likewise exempt from the
five-personal-quirk limit. Personal negatives and quirks still count normally.
These exemptions depend on receipt ownership and the exact mandatory purchases,
not on a freely assigned flag on an arbitrary trait.

Validation rejects missing mandatory purchases or edits to their cost, level,
rating, scope, identity or skill list. Activation and mitigation may still change
through normal play. Ordinary disadvantage buyoff and removal offers cannot
remove mandatory ancestry purchases, even with a separate buyoff approval.
Permitted complete ancestry omissions use the explicit replacement accounting
interface below. Partial and modifier-bearing replacements remain pending.

Overlapping personal and ancestry traits currently reject under ordinary trait
validation. Supported ancestry-to-ancestry stacking is described below. Personal
improvements still need further origin-aware composition; they are not silently
merged or repriced. Only the trait row factories already
supported by the installed modules are available. Ancestry skills, modifiers,
full catalogue packages and transformations remain incomplete.

Sources: `full-2008`, B261-B262 and B452. `test_ancestry_traits` specifies rated
concrete behavior, costs and exemptions, five personal quirks plus an ancestry
quirk, excessive personal quirks, mandatory-component binding, blocked ordinary
buyoff, fresh ownership, undo and cross-process save continuation. These fixtures
are authored but unrun while checks are paused.

## Stacking supported ancestry traits

When distinct ancestry packages require the same trait ID and scope, composition
adds levels for verified shared-catalogue per-level traits: the four acute senses,
charisma, fearlessness, hard-to-kill and night vision. Night vision retains its
nine-level maximum; the other supported entries retain the current catalogue's
implementation bounds. Trait levels are combined on the fresh character, leaving
source definitions unchanged.

Identical fixed purchases are retained once, with all contributing ancestry IDs
recorded in the receipt's corresponding `traitOrigins` list. This also applies to
identical concrete rated purchases. Different ratings, purchase forms, scopes or
incompatible tier choices are not resolved by adding their prices. Conflicting
matching purchases reject with `ancestry-trait-conflict`; ordinary trait
compatibility checks reject incompatible distinct IDs. An author must resolve
these definitions before composition or supply a supported explicit conflict
resolution as described below.

Two occurrences of the same trait ID and scope inside one ancestry reject as
`duplicate-ancestry-trait-row`. A package cannot create extra levels by listing
the same purchase twice. Other per-level traits require verified composition
support; differing levels reject rather than silently applying an unsupported
addition rule. Personal/ancestry overlap remains unsupported.

Sources: `full-2008`, B35, B41, B55, B58, B71 and B261.
`test_ancestry_stacking` specifies additive levels and prices, the night-vision
cap, fixed and rated deduplication, conflicting tiers/ratings, package-order
independence, rejected duplicate rows, immutable prior characters, undo and save
continuation. These assertions remain unrun.

## Explicit conflicts between ancestries

Use `rpgExpandedCreateResolvedAncestryCharacter(personal, ancestries,
resolutions, rules)` for an approved decision about conflicting ancestry traits
(B261). The ordinary ancestry factory supplies an empty resolution list and
continues to reject unresolved conflicts.

Each `RpgExpandedAncestryConflict` has a unique `id`, `approved`, nonempty
`evidence`, and two selectors: `retainedAncestry`/`retainedTrait`/`retainedScope`
and `discardedAncestry`/`discardedTrait`/`discardedScope`. Ancestry selectors use
package IDs; trait selectors use trait IDs. Both purchases must exist exactly
once, in different input ancestries. The interface currently recognizes the
shared catalogue's mutually exclusive fortune, appearance, wealth, flexibility,
sight, status and disease-resistance choices, acute hearing versus impaired
hearing, and conflicting purchase forms, ratings or tiers for a matching trait.
Other conflicts need explicit implementation rather than an unverified callback.

A resolution cannot discard a compatible additive purchase, bypass a summed-level
cap, discard the same component twice, or retain a component another resolution
discards. Missing, ambiguous, unapproved and contradictory decisions reject.
After applying the decisions, normal ancestry stacking and final character
validation still apply. Remaining unresolved conflicts therefore still reject.

The combined price is recomputed from retained components; a discarded component
contributes neither cost nor disadvantage exemption. Decision snapshots are stored
in the owned ancestry receipt and survive later changes to author definitions.
This is conflict resolution between ancestries, not a personal omission of a
mandatory ancestry trait. Personal omissions use the separate B262 replacement accounting below.

`test_ancestry_conflicts` specifies retaining either side of a positive/negative
conflict, retaining one rated purchase, invalid and contradictory decisions,
unchanged prior characters, receipt binding, undo and save continuation. These
assertions remain unrun while checks are paused.

## Package prohibitions and cosmetic notes

An ancestry definition can supply `tabooTraitIds`, `tabooSkills` and
`tabooAttributeRanges` using the `RpgExpandedTabooTraits` formats above. The
factory creates a separate owned constraint contribution for each package with
prohibitions, carrying its approval and explanatory evidence. Final validation
checks the combined character against every installed constraint, including a
package that contradicts its own mandatory traits.

The ancestry receipt binds these contributions and their definitions. Removing a
required contribution or changing its prohibited purchases rejects before shared
learning or ordinary advancement. Two characters created from one definition
receive different owned contributions. Editing the source package later does not
rewrite an existing character's constraints. Conflict decisions about trait rows
do not remove ancestry prohibitions.

`cosmeticFeatures` stores nonempty cosmetic descriptions at zero point cost.
The owned receipt's `features` list contains `[ancestry ID, description]` pairs.
These notes grant no movement, resistance, sensing, injury, or environmental
benefit. Native environmental conditions and physiological features with
mechanical consequences still require their specific implementations; they
must not be represented as cosmetic notes to claim support.

Sources: `full-2008`, B261 and B452. `test_ancestry_features` specifies zero cost,
mandatory constraint ownership, prohibited initial purchases, direct learning,
rejected edits and removals, source-definition isolation, undo and save
continuation. Assertions are authored but unrun.

## Approved personal omissions

`rpgExpandedCreateCustomizedAncestryCharacter(personal, ancestries, resolutions,
omissions, rules)` adds approved complete omissions after ancestry conflicts and
stacking have been resolved. Each `RpgExpandedAncestryOmission` specifies a unique
`id`, the combined ancestry `traitId` and `scope`, `approved`, and nonempty
`evidence`. Missing or ambiguous targets reject. The target must be an ancestry
purchase; the interface cannot remove unrelated personal investments.

The omitted trait is absent from the character's active trait list. Its original
purchase remains in the ancestry receipt, and an owned accounting contribution
records the original ancestry cost plus an equal, opposite personal adjustment.
For example, omitting a 15-point ancestry benefit gives entries +15 and −15:
the net cost is zero, but the personal −15 counts against the disadvantage cap.
Omitting a −10 ancestry disadvantage gives entries −10 and +10: the net cost is
zero and the ancestry −10 remains exempt from the personal cap. This is different
from discarding a conflicting ancestry component before composition.

The accounting contribution and original purchase are bound to the character.
Removing that contribution, editing the recorded purchase, or directly restoring
the omitted trait rejects. Ordinary trait development offers cannot restore it
and leave the personal adjustment in place. A dedicated restoration/advancement
procedure is still needed. Changing the author request after creation does not
rewrite an existing character.

Only complete, unmodified omissions of currently supported ancestry trait
purchases are implemented. Partial omissions, enhancements/limitations on the
replacement, zero-cost feature omissions, and restoration remain unfinished.
Other ancestry obligations and final character constraints remain in force.

Source: `full-2008`, B262. `test_ancestry_omissions` specifies both price signs,
the personal negative-cap boundary, required approval and target identity,
accounting ownership, unchanged prior characters, restoration rejection before
spending, undo and save continuation. These assertions are authored but unrun.
