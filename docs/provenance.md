# Provenance

The mechanics implementation, adventure scene, host presentation and guides use
original wording and examples. Source and documentation are distributed under
the [MIT licence](../LICENSE).

The optional Lite implementation was checked against John's owned reference
`gurps-lite-4e`: **GURPS Lite, Fourth Edition, August 2004, Rev. 07/12/04**,
printed pp. 2–32. Numeric mechanics and tables are implemented in original code;
the rulebook PDF, its extracted prose, and private campaign records are not
distributed. GURPS is a trademark of Steve Jackson Games. This project is not
affiliated with or endorsed by Steve Jackson Games. The MIT license covers this
project's original code, not the rulebook or its artwork. Consult the original
publication for complete rules, examples and GM guidance.

See the [Lite coverage and authoring guide](lite.md) for source-page mappings,
GM decision hooks and table boundaries. No Third Edition material is blended
into the Fourth Edition mechanics.

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
