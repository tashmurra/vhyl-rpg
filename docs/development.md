# Development and release publication

This is the **Lite conversion release, v1.0.0**. Development is
integrated through pull requests into `main`; version tags identify packaged
snapshots. API names, event contracts and save compatibility may change before a
stable release. Injury, recovery, bounded conflicts and advancement are optional
modules. Supernatural abilities remain a future module.

## Pinned dependencies

[dependencies.json](../dependencies.json) records immutable revisions and their
release labels. These are the latest published releases verified on 17 October
2026:

| Dependency | Release | Revision |
| --- | --- | --- |
| vhyl | [v0.2.1](https://github.com/tashmurra/vhyl/releases/tag/v0.2.1) | `53dbf3b94bb12f269fc447c414bff09fc0b7e46d` |
| Zebulon | [v0.1.2](https://github.com/tashmurra/zebulon-lang/releases/tag/v0.1.2) | `089a6f1d2a55014d0e89bb78d35f82647fdcea61` |

Use the released compiler from that Zebulon release and check out the vhyl
revision above. The lock file is explicit documentation of the tested dependency
pair; the test runner does not fetch dependencies or enforce a Git checkout's
revision. Pass the intended installations using `--vhyl` and `--zebc`.

For example, to prepare the vhyl source dependency in an ignored directory:

```sh
git clone https://github.com/tashmurra/vhyl.git .tools/vhyl
git -C .tools/vhyl checkout --detach 53dbf3b94bb12f269fc447c414bff09fc0b7e46d
export VHYL_ROOT="$PWD/.tools/vhyl"
```

Set `ZEBC` to the matching released compiler executable. Native builds also need
the toolchain described in
[vhyl's development guide](https://tashmurra.github.io/vhyl/development/).
Run the [source and native validation commands](../README.md) before changing
mechanics, persistence or event contracts. Native checks cover the current host;
the release workflow also validates Linux, Windows and macOS. The separate Pages
workflow builds documentation.

## Build the documentation

The site uses the same MkDocs approach as vhyl, including a source-derived
reference, source anchors, alphabetical indexes and search. Python 3.10+ is
required. Its declaration scanner is independent of compiler internals and is
not a semantic checker.

```sh
python3 -m venv .tools/docs
.tools/docs/bin/python -m pip install -r requirements-docs.txt
.tools/docs/bin/python -m unittest discover -s tests -p test_docs.py
.tools/docs/bin/python tools/build_docs.py
python3 -m http.server 8000 --directory build/site
```

Open `http://localhost:8000/`. Generated Markdown and HTML stay under `build/`;
edit the guides or library comments rather than generated pages. `--check` builds
in a temporary directory. `--revision REV` selects the Git revision used for
source links; the default is the checked-out commit. The Pages workflow passes
the commit it is publishing, so source links remain tied to that build.

The build validates local documentation links and source/member anchors, then
runs MkDocs in strict mode. The tests check extraction, extension merging,
inheritance, source escaping and broken-link detection. The supported API index
is curated in `tools/build_docs.py`; internal helpers are also indexed, with an
explicit internal label.

## GitHub Pages

The published reference is at
[tashmurra.github.io/vhyl-rpg](https://tashmurra.github.io/vhyl-rpg/).
Repository Pages must use **GitHub Actions** as its build source.
`.github/workflows/pages.yml` builds and deploys documentation when relevant
files change on `main`, with manual dispatch also available from that branch.
The online reference follows the latest successful deployment from `main`;
offline references attached to pre-releases retain their validated build's source links.

The workflow tests and builds before deploying the generated artifact using the
`github-pages` environment. The Pages workflow publishes documentation separately
from versioned library releases.

## Build a release

`VERSION` is the package version, without the leading `v` used for Git tags.
The current release is [v1.0.0](releases/v1.0.0.md). This is a
source library included in a game at compile time, so it has no standalone library
executable. Release assets contain the library sources, examples, tests, guides
and dependency pins, plus a separate browsable offline documentation archive.
Obtain the pinned vhyl sources and compiler separately.

With a clean committed checkout and documentation dependencies installed:

```sh
.tools/docs/bin/python tools/build_release.py --out build/release
```

The output directory must be new. The builder archives the exact Git commit,
builds the reference against that commit and writes a release manifest and
`SHA256SUMS`. It excludes ignored local tools and native build outputs. Extract
the documentation archive and serve its directory with `python3 -m http.server`
to use search offline. The Markdown guides are also in the source package.

`.github/workflows/release.yml` validates PR source snapshots against the pinned
compiler and native toolchains on Linux x86-64, Windows x86-64 and Apple Silicon
macOS. It builds source and documentation archives once on Linux. macOS output
is universal; CI executes the Apple Silicon slice. Intel macOS is also tested
locally. Native example bundles are validation output rather than release assets.

## Promote an existing build instead of rebuilding

A merge commit and a PR head can have different commit IDs while their **Git
trees** are identical. Trees identify all tracked file contents, paths and modes,
including dependency pins, tests, build scripts and workflows. An unchanged tree
does not need another native build or another set of archives when tagged.

PR jobs check out the PR's actual head commit and always run full validation.
On a merge to `main` or a tag, `tools/promote_release.py` searches recent successful
runs of this repository's release workflow. Reuse requires:

- The same Git tree as the merge/tag target, not just the same version label.
- Successful native jobs on all three platforms and a successful package job.
- A merged PR targeting this repository's `main`, or a directly validated `main`
  run. Fork runs and main runs that merely skipped their native jobs are not fresh
  validation evidence.
- An available, unexpired `release-packages` artifact.
- A matching version, dependency lock, build revision and tree in the manifest.
- Valid checksums, exact source archive contents compared with Git, and offline
  documentation identifying the validated source commit.

The workflow downloads and verifies those packages, skips duplicate compiler and
native work, and promotes the **same source and HTML archive bytes**. The manifest
and original `SHA256SUMS` are also unchanged. A new `release-provenance.json`
records the published merge/tag commit, validated build commit, shared tree,
validation run URL and hashes of all four original assets. The original manifest
and HTML source links continue to identify the commit that was actually built.
This metadata is a provenance record, not a cryptographic signature.

The original checksum file covers the two archives and build manifest; provenance
contains hashes of those assets and the checksum file itself. GitHub supplies an
asset digest for the additional provenance file. There is no second native build
or documentation build just to change the embedded commit label.

If the merge changes tracked files, required checks are missing or artifacts have
expired, the workflow builds and validates a fresh snapshot. API or integrity
failures stop promotion. It never treats missing evidence as a successful check.
The search considers the most recent 100 successful workflow runs; older evidence
can be refreshed with a new validation run.

A tag must match `v` followed by `VERSION` and identify a commit reachable from
`main`. Versions may be stable `X.Y.Z`, or use an `alpha.N`, `beta.N` or `rc.N`
suffix. After fresh validation or verified reuse succeeds, the workflow creates
a draft GitHub release, uploads packages and provenance, and publishes it.
Stable versions become the latest release; suffixed versions retain the
pre-release flag and are not latest. PRs and branch builds do not publish.

Run `python tools/promote_release.py verify --directory PATH` to check a downloaded
build against the current checkout. Promotion tests cover changed source, skipped
or missing jobs, unmerged PRs, foreign repositories/workflows, expired artifacts,
corrupt or rehashed archives and unsafe archive paths.
