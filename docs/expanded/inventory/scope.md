# Reference scope and reconciliation

The inventory uses `full-2008` and printed page labels. Its neutral identifiers
are independent of the private reference service. Source books, page images,
biographies and copied form layouts are not repository deliverables.

| Pages or material | Treatment | Remaining work |
| --- | --- | --- |
| Covers, title and credit pages; B3–B6 | Publication context and navigation; no reproduced artwork, prose or branding | Preserve edition metadata in provenance |
| B7–B9 | Introductory conventions, arithmetic and unit conversions are in [reference overview](reference-overview.json) | Independent arithmetic fixtures and explicit unit-display policy |
| B10–B296 | Detailed character, ability, equipment and development ledgers | Catalogue reconciliation, source ambiguities, execution and fixtures |
| B297–B306 | Summary trait, skill, technique and spell tables are secondary cross-checks | Trait, skill, technique, spell and general-modifier rows mapped to detail. Complete value/condition comparisons and resolve recorded disagreements |
| B307–B323 | Fiction and named characters excluded; reusable mechanics retained in [example compositions](example-compositions.json) | Neutral component links and original integration fixtures |
| B324–B328 | [Condensed combat](condensed-combat.json) is a distinct source section | Explicit precedence for differences from detailed combat and profile-specific fixtures |
| B329–B334 | Index used as a coverage aid; not a new rule catalogue | Complete index-to-ledger reconciliation |
| B335–B336 | Original reporting requirements and repeated numeric summaries retained in [reference overview](reference-overview.json) | Derived views over shared state and reconciliation with detailed tables |
| B337–B342 | Second-volume publication context, contents and introduction | Contents-to-ledger reconciliation; no copied prose or layout |
| B343–B562 | Detailed procedures, catalogue entries and outcome tables indexed by chapter | Numeric/visual review where still pending, cross-module implementation and fixtures |
| B563–B576 | [Glossary and appendices](appendix.json) retain mechanical requirements; duplicate navigation and blank forms are not new catalogues | Resolve glossary discrepancies and complete repeated-index reconciliation |

A summary table cannot be marked covered merely because its chapter has a ledger.
Each row must map to the actual neutral definition, including aliases, conditional
defaults, specialties, prerequisites and modifiers. A disagreement needs a recorded
selection policy and tests at the affected boundary. Neither a printed example
total nor a generated manifest is sufficient evidence of correctness.

The short combat appendix inside `full-2008` is not the `abridged-2004` source.
Where it simplifies a detailed procedure, the implementation must keep its choice
explicit. Installing an expansion must not silently change existing Lite behavior.

The first-pass ledgers remain incomplete inventories. They deliberately retain
pending status for unimplemented behavior, missing source details and unresolved
cross-references. Narrative adjudication requires a documented, tested interface
for the particular decision; a generic callback does not close an inventory entry.
