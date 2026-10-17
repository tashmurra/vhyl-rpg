# vhyl-rpg

**Pre-release:** the mundane prototype is on
[`pre-release/mundane-rpg`](https://github.com/tashmurra/vhyl-rpg/tree/pre-release/mundane-rpg).
It has not been merged to `main`; API and save contracts may change.
Browse the [searchable documentation and library reference](https://tashmurra.github.io/vhyl-rpg/).

Mundane character and challenge mechanics for hybrid vhyl adventures, written
in Zebulon. Parser commands, structured actions and dialogue choices can all
commit the same attempt through one resolver.

The prototype includes character attributes, trained and default skills, narrow
trait modifiers, three-die checks, opposed checks, automatic solutions, authored
consequences, energy/time costs and persistent retry records. Injury, recovery,
advancement and supernatural abilities are later modules.

The optional [reporting extension](docs/reporting.md) adds exact success odds,
ability/modifier explanations and recorded individual dice. Author disclosure
settings and player preferences control which details a CRPG host receives.

## Dependencies

Use the vhyl sources and compiler revision recorded in
[dependencies.json](dependencies.json). Dependencies are external; no compiler
internals, copied adventure library or network reference service is required.
Python 3.10+ runs the checks and example host. Native prerequisites are described
in vhyl's development guide.

The tested pair is **vhyl v0.2.1** (`53dbf3b`) and **Zebulon v0.1.2**
(`089a6f1`), the latest published releases verified on 17 October 2026.
See [development and documentation builds](docs/development.md) for setup and
the GitHub Pages publication workflow.

Set `VHYL_ROOT` to your vhyl source directory and `ZEBC` to the matching compiler
executable, or supply `--vhyl` and `--zebc` to the test runner. An invalid explicit
setting fails without falling back to a different installation.

## Try the hybrid example

From this repository's root, with the dependency settings above:

```sh
mkdir -p build
"$ZEBC" build examples/hybrid/main.t --include-dir lib \
  --include-dir "$VHYL_ROOT/lib" --emit shared --opt O2 \
  --out-dir build/survey-office --runtime-cache build/runtime-cache
python3 examples/hybrid/host.py build/survey-office --vhyl "$VHYL_ROOT"
```

The output directory must be new. The example host uses vhyl's example transport
client and the generated consumer's public interface.

Try `inspect panel`, `pick hatch`, `force hatch` or `persuade keeper`. Use `:plan`
to open numbered choices, then `:1`, `:2`, etc. Parser and menu attempts share
their results. `take key` followed by `use key` is a reliable route to the goal.
`examine panel` supplies basic information without a check. The optional
inspection can improve preparation. `undo` restores attempts and costs together.
`:save PATH` and `:restore PATH` manage a logical save; `:quit` exits the host.
`:odds` shows permitted assessments without taking a turn. Add `--details` to
the host command to show dice and calculations after attempts, and assessments
alongside `:plan`. The keeper's resistance remains undisclosed.

The generated consumer also runs directly. Structured verbs 100–104 map to
the five example approaches; target arguments use inspected runtime handles.
The library itself reserves no verb codes.

## Add it to a game

```text
#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
```

Add `lib` and the dependency's `lib` as compiler include directories. Language,
preview and dialogue modules remain optional. Author a profile, goal, approaches
and one `RpgAttempt` slot for each allowed profile/approach pair. Call
`rpgResolve(profile, approach)` only from committed gameplay execution. Use its
result in an authored consequence hook and presentation code. See the complete
[example](examples/hybrid/main.t) and [authoring guide](docs/authoring.md).

Include `<vhyl-rpg-report.t>` after the core to use `rpgAssess`,
`rpgPublishAssessment`, `rpgPublishRoll` and `rpgRecordedResult`. Reporting is
opt-in per approach; it does not change the existing `rpg.result` event.

## Validation

```sh
python3 tools/test.py --vhyl "$VHYL_ROOT" --zebc "$ZEBC"
python3 tools/test.py --vhyl "$VHYL_ROOT" --zebc "$ZEBC" --native
```

The first command checks every complete source program and tests dependency
selection. The second additionally builds and executes native programs, checking
numeric boundaries, skill defaults, deterministic dice, opposed outcomes, retry
costs, consequences, NPC profiles, all three input paths, preview purity, undo,
exception rollback and save/restore into a new process. Missing native tools fail
the native run. Successful native execution covers the current host only.
Reporting checks independently enumerate die faces, verify hidden and reduced
disclosures, and confirm saved reports preserve the original calculation after
attributes, training, labels or costs change. Presentation tests cover the
example's detailed and minimal views.

Use `--out NEW_DIRECTORY` to retain bundles and saves. Failed runs always retain
their output and print its location. `--runtime-cache DIRECTORY` reuses native
runtime builds across runs. Generated files are ignored by Git.

Original source and examples are distributed under the [MIT licence](LICENSE).
