# Expanded templates

**Status: partial.** Character and ancestry packages. Neutral source: `full-2008`, B258-B263; B445-B454.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `RpgExpandedTemplate` — B258-B259; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.

`RpgExpandedTemplate.create(rules)` creates a new profile with fresh training and
trait instances. Skill definitions may be shared as immutable definitions. This
factory currently handles basic/secondary scores, skill investments and traits
from the existing Lite catalogue. It validates the resulting character costs.
Ancestry exceptions, nested packages, choice groups and the full trait catalogue
are not implemented. It does not mutate or upgrade an existing character.
