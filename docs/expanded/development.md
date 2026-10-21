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

The [campaign procedure ledger](inventory/campaign-procedures.json) also records
session and story awards, dependent restrictions, direct ability awards and the
outside-rescue exception under this module. These need unique award events and the
shared advancement account. Work-based study must share the employment time record;
a job's eight-hour workday contributes two hours of study credit without reserving
another study interval. These integrations are not yet implemented.

Study sessions now retain their original learner, subject, mode, progress and
daily usage across elapsed-time hooks. Before awarding credit they recheck those
values and continued eligibility, including learning restrictions and teacher
requirements. Changed conditions reject the session; propagate the exception to
the engine transaction boundary to roll back time and hook effects together.
Sessions ending at midnight retain credit against the day on which they began.
The interruption fixture covers retargeting, eligibility changes, clock changes,
rollback, undo and save continuation. It remains unrun while checks are paused.

### Credit for nonvocal communication (full-2008, B125, B292)

`RpgExpandedCommunicationStudy` credits a completed communication receipt to an
owned `RpgExpandedStudy` track. Supply `source`, `study`, approval and evidence
that its skill covers the actual communication. Gesture exchanges are the first
concrete adapter: they record the sender's total speech limitation during the
exchange and expose only time already charged. Mitigating the limitation later
does not erase that historical eligibility.

`assess()` previews; `apply()` adds four quarter-learning-seconds per elapsed
second, sharing the study track's existing 200-hour point threshold. It never
advances time or awards spendable adventure points. Each exchange can credit
only one track, even through another request object. Replay, rollback and save
continuation retain that restriction. Skill-learning restrictions still apply;
initial ownership and related-skill approval are required.

Only the sending participant of the implemented gesture adapter is supported.
Writing, shared languages, language-proficiency study and other channels require
concrete adapters and remain pending. Zero-duration exchanges grant no credit.
The fixtures cover full-rate accumulation, threshold crossing, duplicate claims,
historical eligibility, rollback, undo and saves; they remain unrun.

Both ordinary and communication study require an exclusive training slot:
the same `RpgTraining` object cannot appear twice or belong to another profile.
This is checked at assessment and again after ordinary study advances time, so
an elapsed-time hook cannot transfer or share the slot before credit is awarded.
The ownership fixtures exercise both entry points and interruption rollback;
they remain unrun while checks are paused.

Direct `rpgLiteLearn` purchases now consult the same training-ownership and
`developmentSpendingReason` gates used by advancement offers before changing
points. For expanded profiles, a shared training object or duplicate skill slot
blocks the purchase; the direct API retains its nil result for blocked requests.
The owned-offer API returns a structured reason. Reservation hooks also apply to
direct purchases. The authored fixture compares both paths and checks that
blocked requests leave points untouched; it remains unrun.

### Historical disadvantage buyoff cost (full-2008, B291)

Expanded direct buyoffs require a `RpgExpandedBuyoffBasis` in the profile's
`buyoffBases`. Bind its owner and trait, the `originalBonus` awarded for that
trait, approval and evidence covering the original cost and world justification.
The cost is historical: changing a current self-control rating does not rewrite
the original award. Creation modifiers and self-control pricing can make this
amount differ from the trait's base price. No cost is guessed when the basis is
missing. Ordinary Lite profiles retain their existing base-price calculation.

`rpgLiteBuyOff` now consults reserved-point rules before spending. It removes the
owned trait and debits its recorded cost once; repeat calls return nil. Its
existing downtime gate remains. The fixture covers missing evidence records,
reservations, affordability, historical cost, rollback, undo and save replay;
it remains unrun. Automated capture of original awards during all creation and
transformation paths remains pending.

Expanded `RpgDevelopment` offers with `kind = 'remove-trait'` now require the
same historical basis for a disadvantage. Their explicit `cost` must equal the
recorded original bonus; both undercharging and overcharging return a structured
mismatch reason before spending. An absent or unapproved basis blocks the offer.
Direct and owned buyoffs therefore use the same cost and reservation rules.
The offer fixture covers both mismatch directions, cross-path replay, rollback,
undo and saves; it remains unrun.

## Talent study time

The three shared catalogue talents now reduce the study time for their full
printed skill lists by ten percent per active level (full-2008, B89-B91).
Mechanical aptitude includes the nine printed trades; wilderness aptitude
includes fishing and mimicry; social aptitude includes the full thirteen-skill
list. Required specialties use their skill ID and optional specialties use their
parent identity. Inactive or mitigated talents grant no reduction.

`RpgExpandedStudy.learningThreshold()` keeps credit in quarter learning-seconds
and changes the exact threshold for a point. Levels one through four use
2,592,000, 2,304,000, 2,016,000 and 1,728,000 credit units respectively. The
ordinary threshold remains 2,880,000. Daily limits and clock spending still use
actual elapsed seconds, and skill point prices do not change. The same threshold
applies to communication-study credit without charging its elapsed time again.

A study track binds its current threshold. If the applicable rate changes while
partial credit remains, assessment rejects with `study-rate-change-unresolved`;
conversion of partial progress is not implemented. At zero credit, a new point
may start under the new rate. Changes during a committed time interval trigger
the existing transaction rollback checks. Custom group talents and overlapping
study benefits remain unfinished; this adapter covers the three existing,
disjoint catalogue groups.

`test_talent_study` and `test_talent_communication_study` specify exact boundaries,
preview purity, the full group memberships, ordinary rates, rate changes,
communication credit, undo and save continuation. Assertions remain unrun.


## Full-day travel conflicts

Study checks the learner's reserved travel days before spending time or awarding
credit. Education and intensive study also check an expanded teacher's travel
schedule. This implements the no-study constraint of full-2008 B351 when the game
uses [`RpgExpandedTravelDay`](exploration.md#reserving-a-full-travel-day). Ordinary
pace previews do not automatically reserve a day.

## Communication credit per participant

A completed communication receipt exposes `studySeconds(profile)` and
`studyCredit(profile)`. `RpgExpandedCommunicationStudy` grants full-value credit
only for that participant's retained eligible interval and blocks a second award
for the same participant. Two eligible participants may each study the skills
they used without advancing the shared clock again. The relevant-skill approval
and ordinary learning restrictions still apply.

`creditedStudies` retains `[profile, credit]` pairs. The existing `creditedStudy`
field remains a compatibility view of the first award. Applications should use
`studyCredit(profile)` to find a participant's award; changing the compatibility
field or retargeting a retained credit invalidates the history.

Gesture receipts retain independent sender and recipient eligibility. Total
speech limitation enables the existing sender credit; complete hearing loss can
enable either participant's credit (full-2008 B125, B129). Eligibility is bound at
the time of communication and does not change when a condition is later mitigated.
`test_hearing_loss` specifies independent awards, duplicate rejection, point
boundaries, no extra elapsed time, rollback, undo and saved continuation. The
assertions are authored and unrun.

A learner with complete hearing loss must supply accessible communication for
`education` or `intensive` sessions: `communicationMode`,
`communicationEvidence`, and a shared `communicationLanguage` for `written` or
`signed` modes. These facts are part of the session binding. The `visual` mode
requires an authored viable demonstration and does not grant language knowledge.
Self-study and job-learning keep their existing permission requirements.
