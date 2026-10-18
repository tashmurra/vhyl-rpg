# Detailed source inventory

This inventory is unfinished. The [coverage ledger](../coverage.json) lists
module ownership and existing experimental features. Detailed files record the
smaller obligations that must be resolved before those modules can be complete.
They contain neutral identifiers and acceptance criteria, not source prose or
copies of the reference books.

| Reference | Printed pages | Detailed ledger | Review state |
| --- | --- | --- | --- |
| `full-2008` | B10–B31 | [Character creation](creation.json) | Text reviewed; table verification and complete enumeration still open |
| `full-2008` | B167–B173; B229–B233 | [Skill and technique procedures](skills-procedures.json) | Text reviewed; table verification and cross-reference resolution still open |
| `full-2008` | B174–B185 | [Skill catalogue, first segment](skills-catalogue-a.json) | Text and definition metadata transcribed; procedures and cross-references pending |
| `full-2008` | B186–B197 | [Skill catalogue, second segment](skills-catalogue-b.json) | Definition metadata, timed procedures and specialty requirements transcribed |
| `full-2008` | B198–B209 | [Skill catalogue, third segment](skills-catalogue-c.json) | Includes weapon groups and their separate integration obligations |
| `full-2008` | B210–B228 | [Skill catalogue, final segment](skills-catalogue-d.json) | First text pass complete through the catalogue end; enumeration audit still open |
| `full-2008` | B254–B257 | [Psionic powers](psionics.json) | Family memberships, advancement, interference and information contracts enumerated; underlying traits pending |
| `full-2008` | B258–B263; B445–B454 | [Templates and combined packages](templates.json) | Composition, ancestry accounting, sample packages and design permissions enumerated; component definitions pending |
| `full-2008` | B290–B296 | [Development and transformations](development.json) | Advancement, study, maintenance and transformation procedures enumerated; existing study mappings remain partial |
| `full-2008` | B343–B349 | [Task resolution](task-resolution.json) | Roll procedures, equipment modifiers, timing, projects and contests enumerated |
| `full-2008` | B349–B357 | [Physical activities](physical-activities.json) | Activity procedures, gravity, numeric tables and effort options enumerated |
| `full-2008` | B358–B361 | [Senses, influence and fear](senses-influence-fear.json) | Hearing and fear tables enumerated by row; full fear dispatch remains pending |
| `full-2008` | B418–B427 | [Injury, recovery and fatigue](health.json) | Anatomy, wound options, treatment, drug design, resource recovery and foraging enumerated |
| `full-2008` | B428–B437, excluding poison and radiation | [Conditions and environmental hazards](environmental-hazards.json) | Conditions, exposure, collisions, fire, electricity and pressure enumerated; falling formula conflict open |
| `full-2008` | B435–B436 | [Radiation](radiation.json) | Dose histories, effects, shielding and treatment enumerated; overlapping printed boundary confirmed visually and unresolved |
| `full-2008` | B437–B444 | [Poison, illness and aging](poison-illness-aging.json) | Delivery, catalogue entries, intoxication, withdrawal, contagion, infection and aging enumerated; cross-reference audit open |
| `full-2008` | B455–B461 | [Creatures, training and swarms](creatures.json) | Encounter values, training table, natural damage and swarm procedures transcribed; full trait and ancestry resolution pending |
| `full-2008` | Remaining mechanically applicable pages | Pending | Chapter-level ownership only |
| `abridged-2004` | Existing foundation | Pending | Regression coverage exists; detailed rule-by-rule comparison still open |

A page range identifies where evidence is found. It does not certify that every
rule on those pages has been enumerated. In particular, cross-references can
introduce requirements from later chapters. `enumeration_complete` stays false
until a second pass accounts for section headings, sidebars, tables, catalogue
entries and cross-references. Table rows are separate obligations where their
values can fail independently.

## Entry contract

Each entry records a stable neutral `id`, `source`, printed `pages`, owning
`module`, `kind`, implementation `status`, an original `acceptance` criterion and
`tests`. Multiple modules may use a rule, but one module owns its implementation.
Cross-module coverage must verify the consuming operation, not just a helper.

- `pending`: no complete implementation and validating test are identified.
- `partial`: a related implementation exists, but the acceptance criterion is
  not yet satisfied. `existing_feature` points to the experimental feature in
  the parent ledger; it does not establish correctness or completeness.
- `implemented`: executable behavior and independent source-based validation
  satisfy the criterion, including relevant integration and state transitions.
- `adjudicated`: a documented, specific author interface and tests establish
  inputs, permitted choices, consequences, invalid decisions and persistence.
  A generic callback is insufficient.

An empty `tests` list means there is no validating test mapped to that entry yet.
Existing chapter-level or helper tests must not be assigned to every row simply
because they invoke the same function. Tests must check the individual expected
value or procedure, including failures and boundary cases where applicable.
Structural inventory tests detect broken references; they do not verify rules.

Catalogue entries may include `reference_data`: the controlling score, difficulty,
technology qualification, default candidates and prerequisites transcribed from
the supplied printing. These are implementation inputs, not runtime definitions.
Conditional defaults and references to whole skill groups must be resolved before
code generation or execution. An empty default list records no ordinary default;
any campaign-dependent exception remains in the entry acceptance criterion.
Shared procedure families and exact-equivalence skills must retain one investment
identity where the source requires it. Merely generating skill objects from this
metadata would leave their procedures, effects and author contracts unfinished.

Template catalogue entries may record a `printed_cost` as an independent target
for component accounting. It is not permission to charge that number without
resolving the package's components and choices. Power membership entries record
`trait_pages` for their underlying abilities: enumerating membership does not
implement activation, resistance, ongoing effects or the referenced trait.

Creature entries may include `encounter_data` with printed attributes, secondary
scores, skills, traits, movement modes, occupied hexes and prices. Inherited trait
references and choices are unresolved implementation inputs. Minimum-price and
minimum-weight qualifiers preserve the source's lower bounds. These abbreviated
records are not fully priced ancestry templates and cannot serve as complete
player-character definitions without resolving the omitted traits and accounting.

Entries of kind `author-decision` remain pending until a concrete contract exists.
For example, permission to grant a character-creation reward needs the award
amount, eligibility, unique award identity and an execution path that cannot pay
twice. An untyped function accepting arbitrary changes does not fulfill it.

## Exclusions

Detailed files record excluded narrative material and the reason for exclusion.
Setting fiction, named example characters, artwork and source wording are outside
this conversion. Examples that illustrate a general mechanic are excluded only
as fictional content: the underlying mechanic still needs its own entry.

Public references identify the supplied printings through the neutral IDs in
[provenance](../../provenance.md). Private book-title mappings and source locations
stay outside the repository. Do not substitute later revisions or supplements.

## Current findings

The character-creation pass identifies obligations absent from the experimental
implementation: exemptions from negative-cost caps, body-dependent attribute
pricing, low-strength fractional lifting capacity, movement in different media,
language modes and learning, social standing, reputation and temporary identities.
The presence of a basic point-cost helper does not fulfill those requirements.

Template composition needs separate operations for occupational requirements and
ancestry deltas. Occupational overlap takes the highest required level; ancestry
levels add. Both require conflict handling and repricing. Negative ancestry
components are exempt from personal disadvantage limits, but personally omitting
a positive ancestry trait creates a negative replacement that counts toward them.

Mental powers inherit their underlying trait procedures. The source adds power
membership, talent bonuses and interference; it does not prescribe one universal
activation roll or ongoing cost. The counterpower family has neither talent nor
a source discount. Information powers also need a specific hidden-information
contract, including the severe-failure exception for two abilities.

Development has several distinct accounting paths. Spending earned points,
earning restricted study investment, receiving an event-imposed trait and buying
a body modification must not all use the same point-bank operation. The source
also distinguishes ordinary teaching qualifications from intensive instruction,
and has specific exceptions to the usual prohibition on overlapping study.
The existing study helper covers only part of these requirements.

The resolution chapter contains requirements owned by several modules: equipment
quality, optional campaign outcome purchases, combat effort, social influence and
health-managed fear effects. The detailed entries identify those owners rather
than placing every operation in exploration. In particular, full fear resolution
cannot reuse the Lite duration formula: it needs a separate table, recovery
checks and lasting consequences, while preserving Lite's existing execution path.

The injury pass distinguishes temporary penalties from permanent score changes,
and global injury from body-part damage. Treatment needs records for individual
wounds, recovery restrictions, caregiver capacity and retry history. A new
treatment object must not reset a patient's eligibility or grant another healing
allowance. The same applies to foraging attempts, meals and sleep recovery.

Two source decisions remain explicit in the environmental ledgers. B350 describes
linear gravity scaling of terminal velocity, while B431 uses square-root scaling
with gravity and pressure. B436 prints adjacent radiation bands that both include
800 rads; this overlap is visible in the rendered page, not merely extracted text.
These entries cannot be called complete until the implementation documents and
tests its specific selection policy. Later-printing corrections are outside scope.

The first text pass now reaches the end of the injury and hazard chapter. Poison
and disease records need distinct delivery, incubation, resistance, symptom and
recovery state. Hidden immunity, treatment suitability and infection surgery
cannot be represented by a single generic damage callback. Aging also needs
dated losses so a later age reversal restores the correct attributes without
undoing unrelated injuries or purchases.

The implementation remains incomplete and the PR remains draft. Build checks are
currently suspended at the user's request. Newly authored inventory checks have
not been run; they must be included when final validation resumes.
