# Expanded characters

**Status: partial.** Character accounting and secondary characteristics. Neutral source: `full-2008`, B10-B31.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedValidateCharacter` — B16-B17; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

The [character-creation inventory](inventory/creation.json) separates individual
procedures, modifiers, table rows and author decisions. Its pending entries are
not covered by the secondary-characteristic validation above.


Fear-induced quirks installed by the traits module reduce current character
value without granting advancement points. Their owned receipts supply a
post-creation negative-point allowance and a specific exception to the normal
five-quirk creation cap. Ordinary sixth quirks remain invalid. See the
[behavioral quirk contract](traits.md#fear-induced-behavioral-quirks) for authored
outcomes, portrayal records and limitations. The corresponding fixture is unrun.
