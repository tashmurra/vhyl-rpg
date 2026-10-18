# Trait price specifications

`rpgExpandedModifiedCost` prices a positive cost with percentage modifiers.
`rpgExpandedSignedModifiedCost` also handles negative costs, using the source's
signed rounding rule and modification floor. `rpgExpandedSelfControlCost` applies
the supported self-control frequency multipliers independently of Will.

`RpgExpandedTrait` and `RpgExpandedDisadvantage` are approved price specifications
on the existing trait interface. Set `id`, signed `points`, `level`, `percentages`
and `approved`; disadvantages may set `selfControlRating`. The combination of
self-control repricing and percentage modifiers is explicitly rejected until its
composition rules are implemented. `approved` means the author approved that
price specification, not that the library implemented all described effects.

Existing Lite traits remain usable and retain their executable behavior.
Additional authored effects must be implemented in concrete mechanics and tested.
This interim branch does not supply a full advantage/disadvantage catalogue,
generic power effects or an automatic self-control trigger procedure. Do not give
a character an advertised capability based only on the calculated point cost.

Source mapping: `full-2008` B101-B121. Full trait catalogues and their effects remain
part of the broader expansion project. Validation is pending.
