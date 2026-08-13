# Extract host-runnable steps out of Dockerfiles into standalone scripts

**Status:** first pass DONE 2026-08-12 (modelviewprojection package extraction +
convention documented); expand to other projects after user confirms (see Work log)
**Priority:** 5
**Difficulty:** 6
**Created:** 2026-08-12
**Updated:** 2026-08-12 — implemented the modelviewprojection worked example and the
runClaudeInContainer convention.

## Work log (2026-08-12)

**Design (Bill's preference, mid-task): one optionless script per group; the Dockerfile
decides which to run.** Rejected the first cut (a single `install-packages.sh` that
re-read the flags as env vars) in favor of per-group scripts with NO options — the flag
logic lives only in the Dockerfile. Cleaner: each script is a flat package list; no env
plumbing; a host user can run exactly the groups they want.

**modelviewprojection (the worked example):**
- New **`entrypoint/0N-install-*.sh`** (six scripts): `01-install-base.sh` (guard +
  `dnf upgrade` + base + pinentry + libatomic; accumulates exit status), `02-install-docs.sh`
  (BUILD_DOCS), `03-install-xwindows.sh` (USE_X_WINDOWS), `04-install-emacs.sh`
  (USE_EMACS), `05-install-jupyter.sh` (USE_JUPYTER packages), `06-install-spyder.sh`
  (USE_SPYDER package). Each feature script is a single `dnf install` (its exit is its
  gate). COPYed to `/usr/local/bin` by the existing `COPY entrypoint/*.sh` line; all +x.
- **`Dockerfile`** — the big `RUN` now dispatches: always `01-install-base.sh`, then
  `if [ "$FLAG" = "1" ]; then …; fi` per group, joined with `&&` (a failed install fails
  the build). Kept the `--mount=type=cache` dnf cache mounts + `keepcache=True`.
  Container-path steps stay in the Dockerfile: `/venv`, pip, the jupyter config
  (moviepy/jupytext-config/labextension) and spyder `spyder.ini` config (each still under
  its own flag check), `.bashrc`/`.bash_history` seeding, texExpToPng build, gacalc sdist.

**Verification:**
- **Faithfulness:** the union of all six scripts' packages vs the original Dockerfile's
  is **identical — 96 packages, both** (dnf-arg parser, empty symmetric diff).
- **Standalone (the point):** a group script runs in a fresh `fedora:44` guest with no
  project image (verified earlier with the single-script cut: base run exit 0, and a
  feature group installed its packages).
- **Permutation image builds — ALL PASSED.** Nested `podman build` of the real Dockerfile
  across flag permutations — p1 `all off`, p2 `emacs+jupyter+spyder+X` (no docs), p3
  `docs only` (TeX + texExpToPng meson build) — and in each image verified every group's
  script ran **iff** its flag was on (15/15 checks). p3's docs build committed with 313
  texlive install lines + the texExpToPng build.
  Harness: `tasks/adhoc/extract-dockerfile-steps-into-host-scripts/verify-permutations.sh`.

  **Verify method — `dnf repoquery --userinstalled`, not sentinel `rpm -q`.** A sentinel
  package per group gives false results: Fedora dep trees are deep, so a "sentinel" is
  often a transitive dep of *another* group (texlive-luahbtex via texlive-collection-basic,
  libxkbcommon via wxGTK-devel, inkscape via jupyter/spyder — all present with their own
  flag off), and `dnf install spyder` actually installs `python3-spyder`.
  `--userinstalled` lists only *explicitly requested* packages — exactly what the scripts
  ran `dnf install` on, never transitive deps — so a group's package is user-installed iff
  its script ran. (Even the docs representative needs care: `texlive-standalone` is pulled
  by base, so a re-request never flips its reason; `inkscape` is clean — base never pulls
  it, jupyter/spyder pull it only as a dep, docs installs it explicitly.)

**runClaudeInContainer convention:** added **"Host-agnostic setup belongs in a script the
Dockerfile sources"** to the mounted cross-project `CLAUDE.md` (container-per-project
template) + a line in the Quick conformance check.

## Rollout to all other projects (2026-08-13)

Applied the per-group optionless-script pattern to **every** mounted Fedora project.
Each: `dnf install` groups split into `entrypoint/0N-install-*.sh` (base always;
feature groups gated by the Dockerfile's ARG `if` blocks); the Dockerfile keeps the
cache mount / keepcache / tsflags sed / venv / config / build steps. **Faithfulness
proven for every one** (union of the group scripts' packages == the original committed
Dockerfile's package set, via `tasks/adhoc/.../faith.py`-style dnf-arg diff):

| project | groups | pkgs | faithful | build-verified |
| --- | --- | --- | --- | --- |
| modelviewprojection | base/docs/x/emacs/jupyter/spyder | 96 | ✓ | ✓ (3-perm, prior) |
| hanoi | base/docs | 27 | ✓ | ✓ (BUILD_DOCS=0) |
| regardingBritt | base/docs | 16 | ✓ | ✓ (BUILD_DOCS=0) |
| gltron | base/graphics | 58 | ✓ | ✓ (USE_GRAPHICS=0, cmake+ctest passed) |
| texExpToPng | base/emacs | 18 | ✓ | ✓ (meson build+test passed) |
| multivariate-math | base/emacs/spyder/notebook-tex | 54 | ✓ | ✓ (defaults, dispatch checked) |
| geometricalgebra | base/spyder/notebook-tex/docs | 58 | ✓ | faithfulness only (TeX-heavy) |
| graphicalcontainer | base (single, no flags) | 21 | ✓ | ✓ |
| runClaudeInContainer | base (single, no flags) | 430 | ✓ | faithfulness only (the sandbox image itself) |
| spimulator | base/emacs/docs/tree-sitter | 37 | ✓ | ✓ (BUILD_DOCS=0, meson build+test) |

Notes:
- **`dnf upgrade` placement** preserved per project: kept in the base script where the
  original had it inline in the install RUN; kept in the Dockerfile where the original
  had it in a separate earlier RUN (before a COPY) — the base script is then pure install.
- **Single-group projects** (graphicalcontainer, runClaudeInContainer: no feature flags)
  get a lone `01-install-base.sh` the Dockerfile calls unconditionally.
- **Verification method** for the multi-flag ones is `dnf repoquery --userinstalled`, not
  sentinel `rpm -q` — package *names* differ from install names (`spyder`→`python3-spyder`,
  `pandoc`→`pandoc-cli`) and Fedora dep trees are deep, so a sentinel present/absent check
  false-fails; only explicitly-requested packages are user-installed.

### Still-deferred (beyond package installs)

The from-source dependency builds (texExpToPng git-clone+meson in mvm/gacalc; the gacalc
sdist fetch) are also host-agnostic and extractable, but left in the Dockerfiles for now —
they are single pinned steps, not package lists, and lower value. Revisit if wanted.

**Motivation:** much of what a project's `Dockerfile` does is not actually
Docker/Podman-specific — it's ordinary host setup (install these packages, build this
dependency, fetch this pinned tool) that happens to run inside `RUN` lines. If those
steps lived in **standalone scripts**, they could run **on a bare host or in a guest
that has no docker/podman**, and the Dockerfile would just call the script. The obvious
first case: **package installation** — a `dnf install ...` list embedded in a `RUN` is
trivially a `install-packages.sh` that runs the same on a host. Investigate what *else*
across the projects is similarly extractable, then codify the pattern.

## Goal

1. A **reusable pattern** for splitting a Dockerfile's host-agnostic setup into scripts
   the Dockerfile sources, so the same setup runs with or without a container runtime.
2. A survey, **across my mounted projects**, of which Dockerfile steps qualify.
3. An update to **runClaudeInContainer's root `CLAUDE.md`** stating what should be done
   for sub-containers (the projects the sandbox builds) re: this extraction.

## What to investigate

1. **Inventory Dockerfile steps across projects** (start with the mounted set:
   runClaudeInContainer, geometricalgebra, modelviewprojection, and others under
   `/*/opt/*`). Classify each `RUN` as:
   - **Host-agnostic** → extractable (package installs, building/installing a pinned
     dependency like texExpToPng, fetching + verifying a tool, `pip install` sets,
     language-toolchain setup).
   - **Container-specific** → stays in the Dockerfile (`COPY`, `ENTRYPOINT`, `ARG`/build
     flags, cache-mount plumbing, `WORKDIR`, image-layer ordering, `USER`).
2. **The package-install case, done right.** Extracting a `dnf install` means deciding:
   how the package list is stored (a file the script reads vs inline), how to keep the
   **dnf cache-mount speedup** the Dockerfile relies on (the script won't have
   `--mount=type=cache` — measure the rebuild-time cost and decide whether the Dockerfile
   keeps the cache mount while `RUN`-ing the script, which still works), and distro
   assumptions (these are all Fedora `dnf`; a host script should fail loudly on non-dnf,
   not silently). **Caveat to carry:** don't lose the cache-mount idiom the project
   `CLAUDE.md` says to preserve — the extraction must keep it, not drop it.
3. **What generalizes vs what's per-project.** Some steps (Fedora package install) share
   a shape across projects; others are one-offs. Decide what becomes a shared helper vs a
   per-repo script.

## Plan (confirmed 2026-08-12)

- **First pass: modelviewprojection only.** Do the worked extraction there — start with
  package install, then whatever else in mvp's Dockerfile is host-agnostic (per the
  classification above). Script(s) saved under `tasks/adhoc/<this-slug>/` per the
  ad-hoc-scripts convention; the Dockerfile changed to source them. Verify the image
  still builds (`make image`, nested) **and** the script runs standalone on a bare host.
- **Then expand after Bill confirms** — apply the pattern to the other projects.
- **Update runClaudeInContainer's CLAUDE.md** with the sub-container convention (which
  Dockerfile steps become host-runnable scripts, where they live, and that they must
  work with no container runtime). Note the *which* CLAUDE.md below.

## Deliverables

- The mvp worked example (scripts + Dockerfile edit), verified both ways.
- A short findings write-up of what else across projects is extractable (candidate:
  promote to `tasks/reference/` as a durable pattern description) — as the input to the
  "expand after confirmation" step.
- The **CLAUDE.md addition** in runClaudeInContainer. Home: the guidance is cross-project
  (it governs how *any* project's container is built), so it belongs in the mounted
  cross-project `entrypoint/dotfiles/.claude/CLAUDE.md` (and/or the container-per-project
  template section), not only the repo-local root `CLAUDE.md`.

## Open questions

1. **Where do shared scripts live** if a step generalizes across repos — in each repo
   (self-contained, duplicated) or centralized in runClaudeInContainer and mounted?
   Recommend self-contained per-repo scripts to start; centralize only if duplication
   becomes real. (Not blocking the mvp first pass.)

## See also

- Root `CLAUDE.md` → "Conventions for changing this repo" (package list, dnf cache
  mounts) and the container-per-project template in the cross-project `CLAUDE.md`.
- `tasks/sphinx-human-readable-reference-docs.md` — also touches "Dockerfiles build
  outputs"; coordinate the Dockerfile edits.
