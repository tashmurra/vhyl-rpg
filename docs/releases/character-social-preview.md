# Character and social interim milestone

Unreleased and awaiting validation. Adds six optional character/social modules,
a focused umbrella and the original Town Registry integration example. Existing
core/Lite include paths and event contracts are retained. New context and cost
hooks default to existing behavior when expansions are absent.

The milestone supplies authored character accounting, skill mechanisms, trait
price specifications, occupational templates, standing, reputation, reactions,
information delivery, trade terms and loyalty records. It does not claim complete
reference coverage or provide the full trait/skill catalogues. Influence/contact
procedures, ancestry and unrelated expansion systems remain ongoing work.

## Validation record

The earlier local run passed source checks, strict documentation, packaging,
existing core/Lite native regressions, the Town Registry example's parser/action/
dialogue parity and cross-process saves, and the social decision-table cases.
It then failed while starting the combined character/social fixture: core startup
validation rejected the expanded difficulty-3 skill.

The startup fix, stricter wildcard and dynamic skill validation, trait-pricing
fixture, and additional prerequisite/template cases have not been run. Build
checks are paused at the user's request. Earlier results do not validate the
current commit, and the interim PR remains draft until the remaining checks pass.

No release, tag or merge is performed by this interim PR. Saves remain bound to
the exact compiled game.
