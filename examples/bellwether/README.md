# Town Registry: character and social integration

This original vignette demonstrates a Bellwether-oriented integration. Its clerk,
ledger and local facts are examples, not additions to an existing campaign's canon.
Use the tagged v1.2.0-alpha.1 prerelease for a reproducible integration snapshot.

Include core, progression and the Lite umbrella, followed by
`vhyl-rpg-expanded-character-social.t`. Do not also include the six expansion
components separately. The umbrella enables no optional campaign rules.

The `investigatorTemplate` creates an owned profile and two owned skill investments.
Creation adds a separately owned reputation and validates the combined 34-point
character against a 40-point budget. The actor and knowledge objects are then
bound to that profile. Change the template and audience definition for your game;
these two authored skills do not constitute a supplied skill catalogue.

The clerk's reaction is private. Recognition and reaction results remain in owned
records; public output contains only dialogue, information actually delivered and
the player's own sheet. The clerk's authored minimum reaction is civil, so this
scene cannot turn a poor roll into an unimplemented combat encounter. Information
comes from the clerk's recorded beliefs, which are distinct from world truth.

A repeated approach reuses the conversation state and spends no additional time.
A different question needs an authored approach and permission under the reaction
rules; the example does not grant unlimited retries or substitute an interview
skill check for a missing influence procedure.

## Build and play

After selecting the pinned dependencies described in the repository development
guide, compile the example with the same include paths as the existing examples:

```sh
zebc build examples/bellwether/main.t --include-dir lib \
  --include-dir "$VHYL_ROOT/lib" --emit shared --opt O2 \
  --out-dir build/bellwether
python examples/bellwether/host.py build/bellwether --vhyl "$VHYL_ROOT"
```

Use `create investigator`, `ask ledger` and `status`, or `:plan` to select dialogue
choices. Structured action codes are 1301 (create), 1302 (ask) and 1300 (sheet).
All three mutation entry points call the same implementation inside the existing
action transaction. `undo`, `:save PATH` and `:restore PATH` use the host's standard
facilities. Saves require the exact compiled game; there is no save migration.

The authored native test covers the three entry points, the independent expected
character cost, repeat protection, undo/replay and continuation in new processes.
See the [prerelease notes](../../docs/releases/v1.1.0-alpha.1.md) for validation
and the supported integration boundaries.
