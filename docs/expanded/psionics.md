# Expanded psionics

**Status: partial; fixtures unrun.** Power definitions, talent pricing and latent eligibility. Ability effects and interference remain pending. Neutral source: `full-2008`, B254-B257.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-psionics.t` after the expanded foundation. The convenience umbrella includes it without activating any powers.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

The [detailed power inventory](inventory/psionics.json) records the chapter's
sample families, each eligible ability membership, talent and advancement rules,
countermeasures, and numerical examples. Most entries remain pending; partial talent work is identified individually. References
to underlying trait pages are dependencies to resolve, not proof that those
abilities work.

Each power must retain its abilities' own activation, resistance, duration and
resource procedures. Talent modifies eligible use rolls; it does not supply an
ability or automatically increase effect strength. The counterpower family has
no talent or source discount. Latent talent permits later investment in its
family, while acquiring an unrelated family requires a campaign decision.

Information abilities require a documented author contract for world facts,
information quality and misleading outcomes. Hidden rolls must stay hidden from
player-facing outcomes. Only the two specified perception abilities use the
severe-failure misinformation rule; it cannot become a generic rule for all
mental powers.

Magic and mental powers retain distinct origins, even when their physical or
mental effects interact. The shared injury, time and resource ledgers must apply
those interactions without charging an action or maintaining an effect twice.

## Power and talent authoring

Define `RpgExpandedPsionicPower` with a unique `id`, explicit `abilityIds`,
`powerModifier`, `approved` and `evidence` explaining campaign permission.
Membership identifiers refer to underlying traits; listing them does not
implement those traits. Duplicate or empty membership is rejected. Ordinary
families use a source modifier of -10 and five-point talents; the modifier must
be set explicitly. A counterpower definition uses zero, `allowsTalent = nil`
and `talentPoints = 0`. An unusually broad family requires
`customTalentPriceApproved` and an authored `talentPoints`, even if the author
chooses five. This object validates a definition; it does not apply modifiers
to ability prices or enforce countermeasures yet.

`RpgExpandedPsionicTalent` is an owned trait in the character's existing
`traits` list. Set its `id`, `power`, `level`, `approved` and `evidence`.
`creationCost()` contributes the level times the power's talent price through
the existing expanded trait accounting hook. More than four levels requires
`aboveFourApproved`; no talent may be installed in a family that forbids it.

`rpgExpandedPsionicTalentBonus(profile, power)` returns that family's active
talent level or zero. Conflicting definitions with the same family ID and
duplicate talents are rejected. Ability implementations must add this bonus
exactly once to their activation or use roll, including applicable physical
control rolls. The helper does not increase damage or effect strength, grant an
ability, roll dice or alter any ledger. Automatic roll integration is pending.

`rpgExpandedPsionicLatentEligibility(profile, power, abilityId)` checks whether
an owned talent permits an eligible first-ability purchase. Temporarily inactive
talent remains owned potential, although its use bonus is zero. A ready result
is permission only: purchase, point spending, current ability membership,
new-family permissions and executable ability effects remain pending.

The [minimal fixture](../../tests/fixtures/expanded-psionics.t) and
`test_psionic_talents` specify five-point costs, the four-level limit, explicit
higher-level permission, inactive talent, broad-family pricing and unrelated
ability rejection. They remain unrun while checks are paused.
