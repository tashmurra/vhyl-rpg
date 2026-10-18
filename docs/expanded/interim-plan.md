# Character and social interim milestone

This branch delivers a focused character-creation and social-interaction milestone
for Bellwether. The full modular conversion remains a separate ongoing project.
This document is an implementation checklist, not a claim of runtime validation.

## Scope

- Expanded foundation and shared character ledgers.
- Character costs, secondary characteristics and validation.
- Authored skills, defaults, prerequisites, specialties, techniques and familiarity.
- Trait price specifications with explicit limits on executable effects.
- Occupational template composition and authored choices.
- Status/rank, reputation and recognition, reactions, information and trade terms,
  and loyalty procedures.
- A playable Bellwether-oriented creation and social investigation example using
  original characters and world facts, with parser, action and dialogue parity.
- Include/dependency instructions, complete library catalogue for this branch,
  neutral source references and accurate supported/unsupported boundaries.

Full trait/skill catalogues, ancestry construction, influence/contact procedures,
expanded combat, equipment, campaign economics and other expansion systems are not
implicitly delivered by this milestone. Review the relevant functionality for
actual usability; document remaining boundaries rather than importing unrelated
unfinished modules.

## Delivery gates

1. Isolate the necessary modules and compatibility hooks from the full-suite work.
2. Review and complete character/social integration, ownership and validation.
3. Add the playable example and focused regressions, including private previews,
   deterministic replay, exceptions, undo and cross-process saves.
4. Rewrite guides and source coverage for precisely this deliverable; remove stale
   roadmap claims and public game-brand references while retaining software notices.
5. Once implementation is complete, resume source, native, strict documentation
   and packaging checks for this interim scope and repair failures.
6. Create and attach a focused PR against main, preserving the full-suite draft.
   Do not merge, tag or publish a release. Continue full-suite work after delivery.

Build checks and CI-triggering pushes remain paused during implementation. No
interim validation has run yet.

## Implementation observations

The initial extraction contains six expansion modules plus the shared skill-context
and trait-cost hooks. It excludes campaign economics, expanded equipment, expanded
exploration and the unfinished full-suite inventory. Character validation now also
checks the existing trait exclusions and language/native-language invariants.
The next steps are focused behavioral fixtures, the playable example and usable
per-module documentation. This is not yet the interim delivery.
