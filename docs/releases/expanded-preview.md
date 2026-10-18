# Unreleased expanded preview

This branch starts the optional expanded rules conversion. It is not a stable
release and does not claim full-reference coverage. VERSION remains the current
published release until a separately reviewed release is prepared.

Available experimental mechanics include secondary purchases, four-column skill
pricing, explicit paid defaults, technique investment, positive-trait percentage
pricing, extended range and damage rows, task timing, character package factories
and study tracks. The signal-workshop example uses common parser, structured-action
and dialogue operations.

Existing core and Lite APIs retain their behavior. New APIs use the
`RpgExpanded` / `rpgExpanded` prefixes. Public guides use neutral reference IDs and
page labels; private reference files and branded source identifiers are excluded.

The [library catalogue](../libraries.md) lists all current modules and the full
proposed suite, sorted by required dependencies and optional libraries. The
[coverage ledger](../expanded/coverage.json) records implemented features and
remaining work. Eleven proposed modules have no runtime implementation, the
available modules are partial, and detailed catalogue-entry enumeration remains
unfinished. Full combat, tactical, health/hazard, supernatural, creature,
technology, vehicle and campaign integration must be completed before claiming
the planned conversion is delivered.

Validation for this preview must include the existing regressions, independent
expanded arithmetic checks, study history/persistence, example input parity,
strict documentation generation and package construction. Passing those checks
validates the implemented subset; it does not certify pending mechanics.
