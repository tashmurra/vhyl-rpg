# vhyl-rpg

**Release: v1.0.0.** Development follows `main`, with tagged snapshots
for releases. Saves identify the exact compiled game; upgrades require a new game
unless the game author supplies a migration.
See the [release notes](docs/releases/v1.0.0.md) and
[release builds](docs/development.md) for packages and validation.
Browse the [searchable documentation and library reference](https://tashmurra.github.io/vhyl-rpg/).

Mundane character and challenge mechanics for hybrid vhyl adventures, written
in Zebulon. Parser commands, structured actions and dialogue choices can all
commit the same attempt through one resolver.

The core includes character attributes, trained and default skills, narrow
trait modifiers, three-die checks, opposed checks, automatic solutions, authored
consequences, energy/time costs and persistent retry records. Optional modules
add [injury, treatment and bounded conflicts](docs/resilience.md), plus
[milestone progression](docs/progression.md).

The opt-in [Lite rules layer](docs/lite.md) implements character creation,
the advantage/disadvantage and skill catalogues, equipment, second-by-second
combat, social checks, travel, injury, fatigue, recovery and hazards from
**abridged fourth-generation rules (August 2004, Rev. 07/12/04)**. Jumper is included;
magic systems from other books are not. The guide distinguishes executable
mechanics from GM-authored setting and narrative decisions.

The optional [reporting extension](docs/reporting.md) adds exact success odds,
ability/modifier explanations and recorded individual dice. Author disclosure
settings and player preferences control which details a CRPG host receives.

## Choose libraries

The [complete library catalogue](docs/libraries.md) groups core/essential and
optional libraries, with dependencies and availability for each. The
[abridged/full comparison](docs/rules-comparison.md) explains why expanded rules
need separate opt-in behavior.

An [experimental expanded layer](docs/expanded/index.md) adds purchased secondary
characteristics, authored skill defaults and techniques, trait pricing, extended
numeric tables, task timing, character packages and study. This is an **incomplete
conversion**: most planned systems and the full catalogues remain unimplemented.
The [coverage ledger](docs/expanded/coverage.json) records these gaps explicitly.
The partial [campaign module](docs/expanded/campaign.md) adds authored equipment
legal-access policies; its new validation cases remain unrun.
Try the [signal workshop](examples/expanded/main.t) with the corresponding
[host](examples/expanded/host.py); it accepts `study`, `decode`, `rest day`,
`status`, `undo` and `:plan` choices. Build it like the other examples, selecting
`examples/expanded/main.t` and a new output directory.

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

The other modules are opt-in too: `<vhyl-rpg-resilience.t>` adds injuries and
recovery; `<vhyl-rpg-conflict.t>` follows resilience and adds short physical
conflicts and social disposition; `<vhyl-rpg-progression.t>` needs only the core.
The original core-only and reporting integrations continue to work.

For Lite, include `<vhyl-rpg-progression.t>` and then `<vhyl-rpg-lite.t>` after
the core. Use `RpgLiteProfile`, not the simplified resilience/conflict pools,
for Lite characters. See [the Lite guide](docs/lite.md) and
[the training-yard example](examples/lite/main.t).

## Play resilience and progression

Build `examples/resilience/main.t` using the same include directories and native
options as above, with a new output directory such as `build/gatehouse`. Then run:

```sh
python3 examples/resilience/host.py build/gatehouse --vhyl "$VHYL_ROOT" --details
```

You arrive wounded and tired. `treat wounds`, `rest`, `find permit` and `show
permit` provide a peaceful route. Completing the objective awards points once;
`train aid`, `train resolve`, `learn poise` and `overcome nerves` spend them at a
quiet pause. `:plan` offers numbered choices and `:odds` shows current permitted
assessments and development costs without taking a turn.

In a fresh run, `confront guard` starts a short encounter. Choose `attack`,
`defend`, `recover`, `escape` or `surrender`. A stalemate ends it after six
exchanges. Incapacitation has an authored `accept help` route; combat is optional.
Undo and logical saves preserve conditions, supplies, points and conflict state.

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
Additional native checks cover treatment budgets, rest boundaries, incapacitation
and rescue, social permission, conflict replay and restore, one-time milestones,
owned training, attribute dependencies, purchase rollback and hybrid parity.

Use `--out NEW_DIRECTORY` to retain bundles and saves. Failed runs always retain
their output and print its location. `--runtime-cache DIRECTORY` reuses native
runtime builds across runs. Generated files are ignored by Git.

Original source and examples are distributed under the [MIT licence](LICENSE).

Tags reuse successful PR validation and packages when the complete Git tree
matches. Source and HTML archives remain byte-for-byte identical; publication
adds a small provenance file tying the validated build to the release commit.
A changed tree or unavailable build evidence requires fresh validation.
