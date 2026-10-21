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

The [optional accumulating stress library](expanded/stress.md) implements original campaign
rules: a 0–12 pool, explicit gains, ordered decisions and safe-hour recovery.
It is inactive until configured and separate from reference-derived fear.
The focused fear milestone and its validation status are tracked in the
completion checklist; the wider rules conversion remains incomplete.
