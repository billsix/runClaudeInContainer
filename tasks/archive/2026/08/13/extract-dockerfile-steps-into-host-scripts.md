# Extract host-runnable steps out of Dockerfiles into standalone scripts

**Status:** complete
**Completed:** 2026-08-13

## What this did

Much of a project `Dockerfile` is ordinary host setup that happens to run in a `RUN` line.
This task moved the package installation of every mounted Fedora project into standalone
`entrypoint/0N-install-<group>.sh` scripts the Dockerfile calls, so the same setup also
runs on a bare host or in a guest with no container runtime, and documented the pattern as
a cross-project convention.

## Design (decided mid-task by the maintainer, 2026-08-12)

**One optionless script per package group; the Dockerfile decides which to run.** The first
cut, a single `install-packages.sh` that re-read the feature flags as env vars, was
rejected: with per-group scripts the flag logic lives only in the Dockerfile's ARG `if`
blocks, each script is a flat package list, and a host user runs exactly the groups they
want.

- The base script guards on `command -v dnf` and fails loudly on a non-dnf host; a script
  with several `dnf` calls accumulates its exit status. Each feature script is a single
  `dnf install`, so its exit is its gate. Groups are dispatched with `&&`.
- The Dockerfile keeps the `--mount=type=cache` dnf cache mounts and `keepcache=True`, and
  every container-path step: `/venv`, pip, jupyter/spyder config (each under its own flag),
  `.bashrc`/`.bash_history` seeding, from-source builds.
- `dnf upgrade` stayed wherever the original had it: in the base script if it was inline in
  the install `RUN`, in the Dockerfile if it ran in an earlier separate `RUN`.
- Shared scripts stayed self-contained per repo; centralizing them was not needed.

## Worked example: modelviewprojection (2026-08-12)

Six scripts: `01-install-base.sh` (guard + `dnf upgrade` + base + pinentry + libatomic),
`02-install-docs.sh` (BUILD_DOCS), `03-install-xwindows.sh` (USE_X_WINDOWS),
`04-install-emacs.sh` (USE_EMACS), `05-install-jupyter.sh` (USE_JUPYTER packages),
`06-install-spyder.sh` (USE_SPYDER package), copied to `/usr/local/bin` by the existing
`COPY entrypoint/*.sh` line.

Verification:
- **Faithfulness:** the union of the six scripts' packages equals the original
  Dockerfile's, 96 packages each (dnf-arg parser, empty symmetric diff).
- **Standalone:** a group script ran in a fresh `fedora:44` guest with no project image.
- **Permutation builds, all passed:** nested `podman build` with all flags off; with
  emacs+jupyter+spyder+X; and docs only (TeX + the texExpToPng meson build). Each group's
  script ran iff its flag was on (15/15 checks). The harness was
  `tasks/adhoc/extract-dockerfile-steps-into-host-scripts/verify-permutations.sh`, since
  removed.
- **Check with `dnf repoquery --userinstalled`, not a sentinel `rpm -q`.** Fedora dep trees
  are deep, so a sentinel is often a transitive dep of another group (texlive-luahbtex,
  libxkbcommon, inkscape all appeared with their own flag off), and install names differ
  from package names (`spyder` → `python3-spyder`, `pandoc` → `pandoc-cli`).
  `--userinstalled` lists only explicitly requested packages.

## Rollout to the other projects (2026-08-13)

Faithfulness (script union == original package set) was proven for every project:

| project | groups | pkgs | build-verified |
| --- | --- | --- | --- |
| modelviewprojection | base/docs/x/emacs/jupyter/spyder | 96 | yes (3 permutations) |
| hanoi | base/docs | 27 | yes (BUILD_DOCS=0) |
| regardingBritt | base/docs | 16 | yes (BUILD_DOCS=0) |
| gltron | base/graphics | 58 | yes (USE_GRAPHICS=0, cmake+ctest) |
| texExpToPng | base/emacs | 18 | yes (meson build+test) |
| multivariate-math | base/emacs/spyder/notebook-tex | 54 | yes (defaults) |
| geometricalgebra | base/spyder/notebook-tex/docs | 58 | faithfulness only (TeX-heavy) |
| graphicalcontainer | base only | 21 | yes |
| runClaudeInContainer | base only | 430 | faithfulness only (the sandbox image) |
| spimulator | base/emacs/docs/tree-sitter | 37 | yes (BUILD_DOCS=0, meson build+test) |

Projects with no feature flags got a lone `01-install-base.sh` called unconditionally.
(regardingBritt was later deleted.)

**Not done:** the from-source dependency builds (texExpToPng git-clone+meson in
multivariate-math/geometricalgebra; the gacalc sdist fetch) are also host-agnostic but
stayed in the Dockerfiles, being single pinned steps of lower value.

## Convention

Added "Host-agnostic setup belongs in a script the Dockerfile sources" to the mounted
cross-project `entrypoint/dotfiles/.claude/CLAUDE.md` (container-per-project template),
plus a line in its Quick conformance check. That template section later moved to the
personal overlay. Related: `tasks/archive/2026/08/13/sphinx-human-readable-reference-docs.md`
touched the same Dockerfiles.
