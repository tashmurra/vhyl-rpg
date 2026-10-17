# Provenance

The mechanics implementation, adventure scene, host presentation and guides use
original wording and examples. Source and documentation are distributed under
the [MIT licence](../LICENSE).

The declaration scanner in `tools/docscan.py` is adapted from
[vhyl's documentation builder at v0.2.1](https://github.com/tashmurra/vhyl/blob/53dbf3b94bb12f269fc447c414bff09fc0b7e46d/tools/build_docs.py),
copyright 2026 John Cunningham, under the MIT licence. The original notice is
retained in [third-party notices](../THIRD_PARTY_NOTICES.md). The reference
renderer uses that scanner to index this repository's two library modules;
neither the documentation builder nor mechanics import compiler internals.

vhyl and Zebulon remain external dependencies pinned in
[dependencies.json](../dependencies.json). The example host loads vhyl's
example transport from the supplied dependency checkout. MkDocs and its installed
dependencies are documentation build tools governed by their own licences.
