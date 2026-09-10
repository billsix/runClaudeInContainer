# The lean-image-when-nested standard — what "minimal" means per project

**Reference document** — the convention that every containerized project builds a *lean* image when
built nested inside a sandbox and its *full* image on a host, with no flag to remember; the idiom; the
rules for what may and may not be trimmed; and the 2026-09-10 survey of every project under the
sandbox's `/foo/opt` mount with a `CLAUDE.md`. Work: `tasks/minimal-image-for-nested-podman-standard.md`
(umbrella) + one `tasks/minimal-nested-image.md` per project. Sibling of `nested-podman-design.md`
("The `PODMAN_RUN_FLAGS` convention"), which it does not repeat. Written 2026-09-10 (William Emerison
Six <billsix@gmail.com> asked for the standard).

## 1. Why

The nested podman store is RAM (`NESTED_PODMAN_TMPFS_SIZE`, 8–16 GB). A batteries-included project
image (runCrushInContainer's client: 22 GB; this sandbox's own image; anything with a TeX distribution
plus Emacs plus Jupyter) cannot be built there, so image-level verification of build-file changes needed
a real-machine visit every time. runCrushInContainer solved it twice over: first a `FULL_TOOLCHAIN` flag
(2026-08-29), then — the decisive step (2026-09-10) — defaulting that flag from the `NESTED_PODMAN=1`
signal every sandbox already exports, so the lean image is what a nested `make image` *just builds*.

## 2. The standard

**Rule.** Every optional-feature build flag in a project Makefile defaults to its lean value when
`NESTED_PODMAN=1` and to its full value otherwise:

```make
# Full on a real host; lean when built NESTED inside a sandbox (which exports NESTED_PODMAN=1):
# the full image does not fit the nested RAM store. Same idiom as PODMAN_RUN_FLAGS. Override
# either way on the command line (FLAG=1 nested needs a store that can take the full image).
USE_EMACS  ?= $(if $(filter 1,$(NESTED_PODMAN)),0,1)
BUILD_DOCS ?= $(if $(filter 1,$(NESTED_PODMAN)),0,1)
```

The Dockerfile side is unchanged: `ARG FLAG=0` + the `if [ "$FLAG" = "1" ]` dispatch the template
already uses; `--build-arg FLAG=$(FLAG)` on `image`. A bare `podman build` stays lean (ARG default 0),
a host `make image` stays byte-identical (no `NESTED_PODMAN` in the environment → the full value).

**What flips (lean = off):** editors and their configs (`USE_EMACS`, Spyder), documentation toolchains
(`BUILD_DOCS`: TeX, sphinx, inkscape, ImageMagick, pandoc), notebooks (`USE_JUPYTER`), GUI/display
extras (`USE_GRAPHICS`, `USE_X_WINDOWS` — *unless* the project's headless verification runs on the
image's own Mesa, as modelviewprojection's does), any "full toolchain" superset (`FULL_TOOLCHAIN`).

**What never flips:** the project's **gates** — tests, sanitizer suites, tree-sitter grammar builds,
a docs build when `make html` *is* the gate (spimulator's `BUILD_TREE_SITTER`/`RUN_SANITIZERS`,
modelviewprojection's `BUILD_DOCS`) — and the **product's own build dependencies** (musl for apue, TeX
for texExpToPng and the osbooks, gst's GUI-package libs for smalltalk). A lean image that cannot run the
gate verifies nothing; the flag-coverage rule (cross-project `CLAUDE.md`, "Verification gates in nested
containers", the 2026-07-07 spimulator lesson) is the reason.

**Other rules carried from the reference implementation:** same image tag for both variants (a lean
host build replaces the full image until the next full rebuild — accepted); no language servers in a
lean image (maintainer, 2026-09-10 — a declared-but-absent server fails to start harmlessly, and
Crush's "no LSP client handles file" is expected there); measure both sizes and record them in the
project's `CLAUDE.md`; a project with nothing optional (pyNuklear) adopts the standard by stating so.

**For new projects:** the template's Makefile flag block starts with the nested-aware form for every
optional flag. The template spec lives in the maintainer's personal overlay
(`~/.ai-coding-conventions.personal.md`, host-side); the line to add there is the `make` block above.
The tracked cross-project `CLAUDE.md` gets a one-paragraph point 3 under "Running projects in a nested
container" (drafted in the umbrella task).

## 3. The survey (2026-09-10) — every `/foo/opt` project with a `CLAUDE.md`

Read from each Dockerfile, Makefile and `entrypoint/*install*.sh` in the sandbox; sizes are to be
measured at implementation (none of these images were built for the survey). Per-project detail and
plan: that project's `tasks/minimal-nested-image.md`.

| Project | Today's flags (host default) | Unconditional heavyweights | Lean variant | Notes |
|---|---|---|---|---|
| runCrushInContainer | `FULL_TOOLCHAIN` (1) | — | **done**: 1.65 GB vendored / 3.16 GB online vs 22 GB | the reference implementation |
| apue | none | emacs; musl from source (product) | new `USE_EMACS` | man pages stay |
| epix-mirror | none | six texlive collections, ghostscript, ImageMagick, jupyterlab (pip) | new `BUILD_DOCS` + `USE_JUPYTER` | biggest saving in the fleet; lib/py-ext/ASan need none of it |
| geometricalgebra | `USE_SPYDER` 0, `USE_EMACS` 0 (**dead ARG**), `BUILD_DOCS` 1 | emacs in `01-install-base.sh`; `03-install-notebook-tex.sh` unconditional | `BUILD_DOCS` flips; make `USE_EMACS` live; gate notebook-tex | `make test` is the gate |
| gltron | `USE_GRAPHICS` 1 | emacs, ffmpeg in base | `USE_GRAPHICS` flips; new `USE_EMACS` | confirm image-time `ctest` needs no X |
| hanoi | `BUILD_DOCS` 1 | — | `BUILD_DOCS` flips | trivial |
| programmingFromTheGroundUp | `BUILD_DOCS` 1, `USE_GRAPHICS` 1 | emacs; i686 glibc (product) | both flip; new `USE_EMACS` | check `gtk4` |
| pyNuklear | none | — | **none needed** (already lean) | add `PODMAN_RUN_FLAGS` auto-default (missing) |
| smalltalk | `USE_EMACS` 1 (plain `=`) | gst GUI-package build deps (product) | `USE_EMACS` flips | clang-tools-extra rides with emacs today |
| spimulator | `USE_EMACS`, `BUILD_TREE_SITTER`, `BUILD_DOCS`, `RUN_SANITIZERS` all 1 | — | `USE_EMACS`, `BUILD_DOCS` flip; **tree-sitter + sanitizers stay** | gates exempt |
| texExpToPng | `USE_EMACS` 1 (plain `=`) | TeX (product) | `USE_EMACS` flips | template for billsEmacsConfigs |
| billsEmacsConfigs ×20 | `USE_EMACS` 1 (plain `=`) | TeX + each toolchain | `USE_EMACS` flips (judgement call: Emacs is their point) | one codemod |
| modelviewprojection | `BUILD_DOCS`, `USE_EMACS`, `USE_JUPYTER`, `USE_X_WINDOWS` 1; `USE_SPYDER` 0 | — | `USE_EMACS`, `USE_JUPYTER` flip; **`BUILD_DOCS` (book gate) and `USE_X_WINDOWS` (headless Mesa) stay** | `morePorts` checkout has no `PODMAN_RUN_FLAGS` — verify master |
| runClaudeInContainer (sandbox image) | `USE_EMACS_CONFIG` 1 | `01-install-base.sh` ~430 pkgs | new `FULL_TOOLCHAIN` + `00-install-minimal.sh`, runCrush-style | installer needs network regardless |
| imps/n64 ×4 | — | Ubuntu 22.04/24.04 mirrors of upstream CI | **N/A** — fidelity to CI is the design | |
| impo/openstax ×16 | hardcoded `PODMAN_RUN_FLAGS = --cgroups=disabled` | TeX schemes/collections (product) | **N/A** — nothing to cut | still want the `?=` PODMAN_RUN_FLAGS form |
| Craft, imps, impo | — | no container | **N/A** | |

**Containerized but outside the survey's criterion (no `CLAUDE.md`):** `lldbassemblyhelper` (Fedora 43;
emacs + npm pyright unconditional — would flip), `graphicalcontainer` (a GUI demo box; lean is
meaningless), `multivariate-math/multivariate-math`, `n64/billBuildMM`. Listed so nobody re-surveys.

**Side findings (pre-existing, not part of this work):** `PODMAN_RUN_FLAGS` in its `?= $(if …)` form is
absent from pyNuklear, texExpToPng, programmingFromTheGroundUp, lldbassemblyhelper, graphicalcontainer
and the mvp `morePorts` checkout, although the 2026-08-29 rollout record lists mvp, texExpToPng and
pgu as converted — re-check on `master` before assuming the record is wrong.

## 4. Re-sync check

`grep -ln 'NESTED_PODMAN)),0,1)' /foo/opt/*/Makefile /foo/opt/*/*/Makefile /foo/opt/*/client/Makefile`
from the sandbox lists the converted projects; a project in §3's "lean variant" column that is missing
from that list has not been done yet (or drifted back).
