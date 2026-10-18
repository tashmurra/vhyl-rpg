# Expanded creatures

**Status: pending.** Animals, body forms, mounts and swarms. Neutral source: `full-2008`, B455-B461.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename is reserved in the catalogue only; do not include it in a game.

Implementation must verify each applicable source procedure and catalogue entry, add module-specific APIs and independent expected-value tests, and exercise persistence and interaction with other modules. A generic callback is not evidence of completed mechanics.

## Source inventory

The [creature inventory](inventory/creatures.json) records the first text pass
through B455–B461. It includes each printed encounter profile, the training-time
table, mount pricing, natural attacks and swarm examples. Every entry remains
pending implementation and independent validation.

Printed encounter statistics are abbreviated. They preserve explicit secondary
score overrides, but omit traits needed for full character-point accounting.
Player-controlled creatures require complete definitions; importing a short
encounter record must not imply that requirement has been met. Inherited trait
lists and domestic/wild choices also need resolution before execution.

## Integration requirements

Creatures use the shared character and health model. Their body form determines
occupied spaces, legal movement, manipulation, attacks and crippling effects.
The module must preserve explicit changes such as a bear's smaller upright
footprint and a rider's position within a multi-hex mount.

Natural damage depends on attack type, strength, anatomy and trained brawling.
The printed dodge score already includes applicable reflexes; importing it and
then adding reflexes again would overstate the defense. The same care is needed
for precomputed natural damage and enhanced movement.

Animal training needs an owned course with intelligence eligibility, handling
specialty, daily trainer/animal time and completed milestones. General training,
one new trick and war training are different procedures. Printed war-mount
prices already include basic war training. Ordinary pets use currency and
authored behavior; unique companions use their complete character value and the
ally rules.

Swarms occupy a shared space and use automatic attacks and different defenses
against incoming damage. Tiny-creature ingress, sealed protection, dispersal,
target changes and compatible shield or stomping attacks need explicit state.
Treating a swarm as one ordinary animal would give the wrong rolls and timing.
