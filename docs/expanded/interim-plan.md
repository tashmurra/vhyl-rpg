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
6. Finalize PR #5, complete release validation, merge and publish v1.1.0-alpha.1
   for Bellwether. Full-suite development remains separate in PR #4.

The release request supersedes the earlier draft-only delivery and validation
pause. See the [release notes](../releases/v1.1.0-alpha.1.md) for the final
validation record and integration instructions.

## Implementation observations

The initial extraction contains six expansion modules plus the shared skill-context
and trait-cost hooks. It excludes campaign economics, expanded equipment, expanded
exploration and the unfinished full-suite inventory. Character validation now also
checks the existing trait exclusions and language/native-language invariants.
The playable example, focused fixtures and per-module guides are present.
Inspection of the recorded startup failure found that core validation still
rejected difficulty 3 before expanded skills could participate. Core startup now
uses the skill’s difficulty-limit hook, retaining a limit of 2 for ordinary skills
and accepting 3 for expanded skills. Dynamically created expanded skills also
validate difficulty, attribute and default penalty before use. The release suite exercises these fixes alongside the existing core/Lite checks.
