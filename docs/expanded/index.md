# Character and social integration

This interim milestone contains the character and social subset of the expanded
rules project. Implementation and documentation are under review; validation is
pending. It is not a complete conversion of the full reference.

## Includes

Include `vhyl-rpg.t`, `vhyl-rpg-progression.t` and `vhyl-rpg-lite.t`, then
`vhyl-rpg-expanded-character-social.t`. This umbrella includes foundation,
characters, skills, traits, templates and social exactly once. For smaller games,
include the foundation and only the components listed in the
[library catalogue](../libraries.md). No cinematic or wildcard option is enabled
merely by including a module.

Create an `RpgExpandedRules` object and give each `RpgExpandedProfile` a `rules`
reference. Keep training, traits, reputation, knowledge and encounter records
owned by their respective characters. Shared skill definitions and templates are
immutable author data; each template creation produces fresh character state.
Use `rpgExpandedValidateCharacter` before admitting a created character to play,
then set `creationComplete = true`.

## Shared state and actions

Expanded profiles inherit the Lite injury, fatigue, inventory and money state and
the progression point bank. There is no second character ledger. Call mutating
operations from an `Action.exec` or the existing dialogue transaction. Preview
methods do not spend resources or draw randomness. An authored operation may
return `blocked`, `ready`, `resolved` or `reused`; inspect its reason instead of
assuming a callback or table assessment performed a world action.

Private reaction, recognition and loyalty results belong to trusted author code.
Publish NPC dialogue and concrete consequences, not private numeric results.
Keep world truth, NPC beliefs, statements heard and the player's beliefs distinct.
The [Town Registry](../../examples/bellwether/README.md) demonstrates these
boundaries with parser, structured-action and dialogue entry points.

Undo, exception rollback and saves use vhyl's existing transaction mechanism.
Saves remain tied to the exact compiled game. This milestone supplies no old-save
migration. Lite behavior should remain unchanged when expansions are absent;
regression validation is still pending.

## Boundaries

Authored definitions are supported; full trait, skill and spell catalogues are
not supplied. Trait price arithmetic does not provide supernatural effects.
Occupational templates do not implement ancestry construction. Influence contests,
contacts, complete social permissions, expanded combat/injury, campaign economics
and other full-suite modules remain outside this interim branch. Trade tables
produce terms; they do not transfer inventory. These exclusions do not remove them
from the ongoing full-suite project.

See [characters](characters.md), [skills](skills.md), [traits](traits.md),
[templates](templates.md) and [social](social.md), with neutral provenance in the
[source guide](../provenance.md).
