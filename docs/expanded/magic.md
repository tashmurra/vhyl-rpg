# Expanded magic

**Status: pending.** Spell procedures, catalogue and enchantment. Neutral source:
`full-2008`, B234–B253; B479–B483.

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json) · [Enchantment inventory](inventory/enchantment.json)

This module has not been implemented. Its proposed filename,
`vhyl-rpg-expanded-magic.t`, is reserved in the catalogue; do not include it in a
game. The general casting chapter and spell catalogue still need their detailed
inventory. The enchantment chapter now has a first text pass covering creation,
level-cost tables, the item catalogue, use and market procedures. Underlying spell
and trait references, numeric audits and validating tests remain pending.

## Casting requirements

The eventual module must implement learning and prerequisites, energy costs,
casting actions, resistance, maintenance, interruption and expiry for every applicable
spell. It must use the character's shared injury, fatigue, advancement and time
accounts. A spell effect cannot be represented solely by a label and a generic
callback; authored choices must have explicit, tested inputs and consequences.

An ongoing spell needs owned state identifying its caster, targets, paid energy,
maintenance schedule and termination conditions. Assessment must reject unsupported
combinations or insufficient resources before consuming time or randomness. Spell
execution, persistence and rollback must work through the existing transaction
mechanisms.

## Enchantment requirements

An enchanted item needs per-spell effective skill, host restrictions, actual effects
and discovered knowledge. Effective magical skill is distinct from the enchantment
that reduces energy consumption. High item skill does not itself reduce activation
time or energy. Low magic can suppress an item without permanently destroying its
enchantments; physical breakage removes magic, and ordinary repair cannot restore it.

Rapid enchantment spends contributed energy at its completion roll, succeeds or
fails under the ceremonial rules, and may create hidden altered effects on ordinary
failure. Slow enchantment instead invests full workdays, with a fixed participant
roster, interruption penalties and make-up days. Its final roll must not charge all
the energy again. A mage cannot contribute two simultaneous shifts by joining two
project objects.

Item use must enforce eligibility and exclusive control. The first eligible toucher
has priority; an ineligible toucher does not reserve the item. A restriction to
magically gifted users on one contained spell applies to all spells on that item.
Continuous items apply their effects only when worn or wielded appropriately, and
do not teach the user an independently castable spell.

The inventory includes each listed item, energy-cost row, material surcharge and
host category. Pricing is campaign-owned: common-trade, mass-production and rare-item
markets are explicit choices, with host and special-material costs added once.
A mass-production cutoff depends on the actual typical enchanting group, not merely
the number of energy points that fit in the generic time formula.

## Required validation

Enchantment cases must independently cover prerequisites, every energy table row,
ammunition and launcher adjustments, mixed spells and restrictions, contributors,
low-magic eligibility, interruptions, lost participants, hidden failures and critical
outcomes. Verify that each method spends its distinct resources once and that an
ordinary failed additional slow enchantment preserves the previously enchanted host.

Full module validation also requires the complete spell catalogue, resistance,
maintenance, interruption and expiry, plus preview purity, replay, rollback, undo
and cross-process save continuation. Checks remain suspended during implementation;
this inventory does not establish executable spell coverage.


[Trait integration at B66–B68](inventory/traits-catalogue-h.json) adds aptitude,
restricted rituals, resistance and local magical-energy changes. Aptitude discounts
exclude the foundation purchase. Energy changes affect carried subjects by default,
with a separate area enhancement beginning at one yard. Overlapping enhancers use
the highest increase; suppression interactions still need the energy chapter.
Item sensing retains separate first-sight and first-touch history. None of these
requirements is implemented by a generic trait-cost calculation.


[Granted-spell aptitude](inventory/traits-catalogue-j.json) uses an authored spell
list, separate learned versions and built-in conduct obligations. It does not share
ordinary spell prerequisites or aptitude bonuses, and its included pact cannot
receive a second discount. Eligibility, suspension and restoration need explicit
records; this source coverage does not yet supply executable casting behavior.
