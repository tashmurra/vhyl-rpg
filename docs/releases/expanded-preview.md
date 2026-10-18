# Unreleased expanded preview

This branch implements an incomplete experimental suite. It is not a stable
release and does not claim full-reference coverage. VERSION remains unchanged;
no tag or release publication is part of this work.

The expanded foundation and convenience umbrella currently include ten partial
feature modules: campaign, characters, development, equipment, exploration,
health, skills, social, templates and traits. Combat, creatures, hazards, magic,
psionics, tactical, technology and vehicles remain proposed modules with no
standalone runtime library. Available include paths are distinguished from
proposals in the [library catalogue](../libraries.md).

The implemented subsets include secondary purchases and character accounting,
trait pricing, richer skill/default/technique procedures, template composition,
equipment and legal access, contextual reactions and social exchanges, study,
employment and wealth advancement. Each module guide records its actual scope.
The full skill, trait, equipment and supernatural catalogues remain incomplete.

The health module now includes scaled shock, supported location wounds, owned
arm/hand state, equipment and unarmed-parry restrictions, single- and multiple-grip
drops, disability duration, temporary full-health recovery and lasting recovery
through authored calendar milestones. Later completed physician care can shorten
recovery without stacking discounts. An explicit last-wounds option records
ignored injuries without spending health or randomness. Other anatomy,
accumulated wounds, full medical procedures, surgery and permanent-disability
accounting remain incomplete.

New public expansion APIs use `RpgExpanded` / `rpgExpanded` prefixes. Shared Lite
hooks default to the existing behavior; the latest compatibility and persistence
claims still require validation. Injury, fatigue, inventory and advancement
continue to use their existing balances. Calendar milestones represent authored
world facts and do not introduce a second time-spending ledger. Save support
retains the exact-compiled-game policy; there is no automatic old-save migration.

Public documentation uses neutral reference IDs, edition/printing metadata and
printed page labels. Private source links, source book titles, source prose and
artwork are not repository deliverables. The comparison guide, per-module guides,
source inventories and [coverage ledger](../expanded/coverage.json) describe the
remaining work. Detailed inventory and catalogue enumeration are not complete.

Build checks and CI are paused at the user's request until implementation is
complete. Recent source/native fixtures, transaction and save-continuation cases,
and documentation changes are authored but unrun. Older successful checks do
not validate the current head. Required final checks include existing core/Lite
regressions, independent source-value checks, module dependencies, combined
examples, input parity, rollback/undo/save continuation, strict documentation,
neutral naming, source coverage and packaging. The full PR remains draft until
implementation and those acceptance requirements are satisfied.
