# Expanded skills

**Status: partial.** Skill catalogues, defaults, prerequisites and techniques. Neutral source: `full-2008`, B167-B233.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedSkillLevel` — B170; B175; tested in `tests/expanded.py::test_numbers`.
- `rpgExpandedSkillScore` — B173; tested in `tests/expanded.py::test_numbers`.
- `RpgExpandedTechnique` — B230; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

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
