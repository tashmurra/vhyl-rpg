# Index reconciliation

Source: `full-2008`, B329–B334 and B570–B575. The index is a navigation aid,
not an additional rules catalogue. Both occurrences were read and their extracted
text compared. The differences are page headers, page numbers and line wrapping;
no different mechanical reference was found in the repeated index.

| First occurrence | Repeated occurrence | Treatment |
| --- | --- | --- |
| B329 | B570 | Same references; use the detailed rule destinations |
| B330 | B571 | Same references; one contest entry wraps differently |
| B331 | B572 | Same references; use the detailed rule destinations |
| B332 | B573 | Same references; use the detailed rule destinations |
| B333 | B574 | Same references; use the detailed rule destinations |
| B334 | B575 | Same references; use the detailed rule destinations |

The index intentionally omits most individual traits, skills and spells. Their
separate summary tables are mapped in the trait, modifier, skill, technique and
spell ledgers. An index search alone therefore cannot establish catalogue
completeness.

## References traced during this pass

These checks locate existing inventory entries. They do not establish that their
runtime implementation or validation is complete.

| Indexed subject, expressed neutrally | Detailed destination | Inventory evidence |
| --- | --- | --- |
| Campaign encounter scheduling and sample outcomes | B502–B504 | [Campaign procedures](campaign-procedures.json): `campaign-encounter-schedule` and all six `campaign-example-encounter-*` rows |
| Cinematic combat choices | B417 | [Guidance, area effects and cinematic procedures](guidance-area-cinematic.json): explicit selection, attire, minor opponents, blast, knockback, point mitigation, ammunition, melee order, fatigue defense and paired-weapon entries |
| Invention defects, artifact investigation and unusual side effects | B476–B479 | [Technology outcomes](technology-outcomes.json): defect rolls 3–18, investigation totals 0–20 and side-effect rolls 3–18 |
| Learnable traits and maintenance | B294 | [Development](development.json): nine learnable-trait subjects and separate opt-in maintenance intervals, modifiers, point loss and practice rules |
| Transformation and continuity of a character's identity | B294–B296 | [Development](development.json): purchase/debt, procedures, mind transfer, copies, backups, death and replacement contracts |
| Character and ancestry constructions | B258–B263; B445–B454 | [Templates](templates.json): role templates, lenses, ancestry templates, bundles, composition, taboo traits and innate learning entries |
| Recovery after injury-related unconsciousness | B423 | [Health](health.json): `health-unconscious-positive`, `health-unconscious-zero-band` and `health-unconscious-negative-band` |
| Repeated form calculations and glossary definitions | B563–B569 | [Appendix](appendix.json): recovery terminology, prerequisite investment, weekly time, work/study conversion, campaign fields and reporting state |

## Destination corrections and exclusions

The unconsciousness entry at B334/B575 points to B329 for recovery. B329 is an
index page. The actual procedure is at B423, confirmed by reading that page:
positive remaining health uses a fifteen-minute recovery, the intermediate band
uses hourly checks, and the lowest band begins with a single check after twelve
hours. The existing health entries use the rule page; do not derive recovery
behavior from the erroneous index pointer.

The index also points to named fictional people, organizations, setting locations,
illustrations, publication credits, commercial references and narrative examples.
Those references do not create repository deliverables. Mechanically relevant
constructions embedded in examples remain in [example compositions](example-compositions.json)
and setting-specific mechanics remain in their neutral campaign inventories.
Neither an excluded fictional label nor an index alias is a separately purchasable
trait, spell or equipment item.

This pass closes the comparison of the repeated indexes and traces the subjects
above. It does not claim a complete reference-by-reference audit of every index
destination. Detailed field reconciliation, unresolved source conditions,
executable behavior and independent tests remain tracked by the individual
ledgers and [scope policy](scope.md).
