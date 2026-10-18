# Occupational templates

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
