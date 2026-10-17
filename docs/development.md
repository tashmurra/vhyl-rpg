# Development and pre-release publication

This is the **mundane prototype pre-release**, developed on
[`pre-release/mundane-rpg`](https://github.com/tashmurra/vhyl-rpg/tree/pre-release/mundane-rpg).
It has not been merged to `main`. API names, event contracts and save compatibility
may change before a stable release. Injury, recovery, advancement and supernatural
abilities remain future modules.

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
files change on `pre-release/mundane-rpg` or `main`. A push to the pre-release
branch can publish without adding a workflow to `main`. Manual dispatch is also
declared; GitHub makes it available once the workflow exists on the default
branch. Both allowed branches publish to the same site; its latest deployment
is authoritative.

The workflow tests and builds before deploying the generated artifact using the
`github-pages` environment. Deploying documentation does not merge branches,
create a package release, or upload native bundles. The mechanics remain a
pre-release until a separate release decision.
