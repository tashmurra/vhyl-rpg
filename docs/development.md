# Development and pre-release publication

This is the **mundane prototype pre-release, v0.1.0-alpha.1**. Development is
integrated through pull requests into `main`; prerelease tags identify packaged
snapshots. API names, event contracts and save compatibility may change before a
stable release. Injury, recovery, advancement and supernatural abilities remain
future modules.

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
the documentation workflow does not run the compiler or native suite.

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
offline references attached to pre-releases retain their tagged source links.

The workflow tests and builds before deploying the generated artifact using the
`github-pages` environment. The Pages workflow publishes documentation separately
from versioned library releases.

## Build a pre-release

`VERSION` is the package version, without the leading `v` used for Git tags.
The first pre-release is [v0.1.0-alpha.1](releases/v0.1.0-alpha.1.md). This is a
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

`.github/workflows/release.yml` checks pull requests to `main`, updates to `main`
and pre-release tags. It builds the pinned compiler and validates source, protocol
and native behavior on Linux x86-64, Windows x86-64 and Apple Silicon macOS.
The macOS compiler emits universal output; CI executes the Apple Silicon slice.
Intel macOS execution was also verified locally for the initial prototype.
The workflow builds release archives and documentation on Linux. A tag must
match `v` followed by `VERSION`, and use an `alpha.N`, `beta.N` or `rc.N` suffix.
The tag must identify a commit reachable from `main`.

After all jobs pass on a tag, the workflow creates a draft GitHub pre-release,
uploads the verified packages, manifest and checksums, then publishes it with
the pre-release flag and without marking it as the latest stable release.
Branch and PR builds upload check artifacts without publishing a release.
Native example bundles are validation output rather than release assets.
