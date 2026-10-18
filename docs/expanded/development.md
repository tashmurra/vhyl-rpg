# Expanded development

**Status: partial.** Study, teaching and transformations. Neutral source: `full-2008`, B290-B296.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `RpgExpandedStudy` — B292-B293; tested in `tests/expanded.py::test_study`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

## Current limits

`RpgExpandedStudy` accumulates credit for one owned skill-training record using
job learning, self-study, education or intensive training. It advances the shared
time ledger and places earned investment directly in that training record. It
does not award unrestricted adventure points.

This is an experimental subset. It does not yet implement spell, technique or
advantage study targets, tuition, course schedules, immersion, skill maintenance,
modifications or mind transfer. Its `teachingScore` field is supplied by the caller
and is not yet derived from the instructor's actual teaching skill. Its scheduling
limits also need to distinguish source caps from campaign-adjustable guidance.
Do not treat a successful assessment as validation of a complete course.

## Remaining source obligations

The [development inventory](inventory/development.json) records the first text
pass through B290–B296. Entries linked to the existing study feature remain
partial; the other procedures are pending. Independent numeric checks and
cross-reference resolution remain necessary.

The implementation must preserve four different accounting paths:

- Adventure points are spendable awards. Their session and eligibility history
  matters for experience-based improvements and learning under pressure.
- Study creates investment in its approved target. Learning rates, instructor
  qualifications, prerequisites and elapsed-time restrictions determine credit.
- Event-granted traits change character value without granting or consuming an
  equivalent amount of spendable points.
- Modifications use a declared point, currency or involuntary-event policy.
  Point debt absorbs future awards; surgery also creates persistent recovery and
  possible injury consequences.

Ordinary instruction accepts an instructor with sufficient subject skill **or**
sufficient investment. Intensive instruction requires both a higher subject skill
and more investment, along with the teaching qualification, materials and learner
health requirements. Teacher availability and payment terms are separate authored
decisions.

Optional skill maintenance needs use and practice histories, due checks and
investment loss. A practice hour that preserves an extreme skill is not also a
study hour. Foreign-language and cultural immersion have an explicit overlapping
learning exception; it must not become a general exemption for concurrent tracks.

Mind transfer must retain mental traits and skill investments while replacing the
appropriate physical traits, then recalculate derived scores and value. Backups
and active copies require independent persistent state and dated snapshots.
Neither operation may silently share mutable inventory or advancement ledgers.
