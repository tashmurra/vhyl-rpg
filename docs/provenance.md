# Provenance

The mechanics implementation, adventure scene, host presentation and guides use
original wording and examples. Source and documentation are distributed under
the [MIT licence](../LICENSE).

The optional Lite implementation was checked against John's owned reference
`abridged-2004`: **abridged fourth-generation rules, August 2004, Rev. 07/12/04**,
printed pp. 2–32. Numeric mechanics and tables are implemented in original code;
the rulebook PDF, its extracted prose, and private campaign records are not
distributed. The MIT license covers this
project's original code, not the rulebook or its artwork. Consult the original
publication for complete rules, examples and GM guidance.

See the [Lite coverage and authoring guide](lite.md) for source-page mappings,
GM decision hooks and table boundaries. No earlier-generation material is blended
into this rules generation.

The declaration scanner in `tools/docscan.py` is adapted from
[vhyl's documentation builder at v0.2.1](https://github.com/tashmurra/vhyl/blob/53dbf3b94bb12f269fc447c414bff09fc0b7e46d/tools/build_docs.py),
copyright 2026 John Cunningham, under the MIT licence. The original notice is
retained in [third-party notices](../THIRD_PARTY_NOTICES.md). The reference
renderer uses that scanner to index this repository's library modules;
neither the documentation builder nor mechanics import compiler internals.

vhyl and Zebulon remain external dependencies pinned in
[dependencies.json](../dependencies.json). The example host loads vhyl's
example transport from the supplied dependency checkout. MkDocs and its installed
dependencies are documentation build tools governed by their own licences.

## Expanded reference

The experimental expanded modules use neutral reference `full-2008`, with the
character volume identified by its February 2008 third printing and the campaign
volume by its April 2008 fourth printing. Printed page labels use a B prefix.
No later corrections are implied. The private reference service, PDFs, extracted
text, images and title mappings are not distributed. Original implementation code
and guides remain under this project's licence; that licence grants no rights to
the source publications. See the [comparison](rules-comparison.md) and
[coverage ledger](expanded/coverage.json) for the partial implementation boundary.

## Optional magic conversion

The experimental magic extension follows the separately documented conversion
from `freeform-1994`, with the identified `freeform-errata-1999`, selected
`anniversary-2015` refinements and explicit host rules. It does not change the
Lite rules generation. The [conversion plan](freeform-magic-plan.md) and
[source audit](freeform-magic-source-audit.md) distinguish source mechanics,
selected adaptations and deferred work. The [implementation guide](magic.md)
and [coverage manifest](magic/coverage.json) distinguish executable rules from
game-authored world content and the deferred spirit-vessel procedure. Original code,
neutral terminology and workshop examples are included; source PDFs, extracted
prose, illustrations and source-setting characters are not.
