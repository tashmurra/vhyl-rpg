# Detailed source inventory

This inventory is unfinished. The [coverage ledger](../coverage.json) lists
module ownership and existing experimental features. Detailed files record the
smaller obligations that must be resolved before those modules can be complete.
They contain neutral identifiers and acceptance criteria, not source prose or
copies of the reference books.

| Reference | Printed pages | Detailed ledger | Review state |
| --- | --- | --- | --- |
| `full-2008` | B10–B31 | [Character creation](creation.json) | Text reviewed; table verification and complete enumeration still open |
| `full-2008` | B167–B173; B229–B233 | [Skill and technique procedures](skills-procedures.json) | Text reviewed; main skill catalogue and table verification still open |
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

The implementation remains incomplete and the PR remains draft. Build checks are
currently suspended at the user's request. Newly authored inventory checks have
not been run; they must be included when final validation resumes.
