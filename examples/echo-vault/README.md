# Echo Vault

An original short encounter: face an impossible reflection, recover your attention
if necessary, and discover where the archive key is hidden. Call the guide before
facing the reflection to remove the isolation penalty.

Parser commands, structured actions and dialogue choices call the same operations.
The shared fear action checks actor ownership. An event can resolve only once;
revisiting it cannot reroll the check or repeat a consequence. The inscription is
unavailable while mentally stunned. Breathing advances the shared clock, allowing
short-stun recovery, and reading the inscription spends one second once.

This scene deliberately uses the source's explicit confusion adjudication choice
(full-2008 B360): after a failed check, the author selects row 4 for this harmless
illusion. The original rolled result is retained. This is a scene-specific author
ruling, not a replacement for ordinary horror-table results or a claim that other
outcomes have no consequences. No source prose or setting material is reproduced.

## Build and play

The example and its fixtures are authored but unrun while build checks are paused.
After implementation is complete and checks resume, use the standard dependencies:

```sh
zebc build examples/echo-vault/main.t --include-dir lib \
  --include-dir "$VHYL_ROOT/lib" --emit shared --opt O2 \
  --out-dir build/echo-vault
python examples/echo-vault/host.py build/echo-vault --vhyl "$VHYL_ROOT"
```

Use `call guide`, `face reflection`, `breathe`, `read inscription`, and `status`,
or `:plan` for dialogue choices. Structured codes are 1401, 1402, 1403, 1404 and
1400 respectively. The host supplies undo and exact-compiled-game save/restore.
This example includes foundation and health directly; traits, skills and the
all-module umbrella are unnecessary for its ordinary fear event.

## Connected aftermath scene

After finding the inscription, use `open cabinet`, then `recover` until awake.
Use `hear footsteps` and `wait panic` until composure returns. The cabinet
uses an explicitly recorded below-three ruling for a compound faint and
lasting curiosity; no fabricated initial roll is shown. The footsteps use
the same approved boundary interface for timed panic, with actual crying
intervals and recovery checks.

Later, `remember` records one of four distinct authored reminders. Each explicitly
adds three stress. At a threshold choose `cope`, `accept strain` or `face memory`.
These respectively record coping, timed strain, or a normal owned fear event
with an explicit confusion ruling if a consequence is needed. `rest hour`
records guarded recovery, respecting the daily cap. Stress is an original
optional campaign policy, not a reference-derived sanity rule.

These same operations are available as structured verbs 1420–1428 and dialogue
choices cabinet/recover/footsteps/panic/remember/cope/strain/memory/rest.
Structured operation 1429 reports the aftermath state for host integrations.
The existing reflection scene and its operations remain unchanged.
