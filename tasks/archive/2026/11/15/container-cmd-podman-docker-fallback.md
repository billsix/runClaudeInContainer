# CONTAINER_CMD auto-detects podman, else docker, across the fleet

**Status:** complete
**Completed:** 2026-11-15
**Created:** 2026-09-03 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §9.2 F7

## What this did

- **2026-09-03:** every container-template Makefile got
  `CONTAINER_CMD ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)`:
  47 Makefiles (apue, billsEmacsConfigs ×20, geometricalgebra, graphicalcontainer, hanoi,
  modelviewprojection, multivariate-math, runClaudeInContainer, the runCrushInContainer client,
  spimulator and its pgu, texExpToPng, and impo's 16 book Makefiles), applied by an idempotent
  codemod (`tasks/adhoc/container-cmd-podman-docker-fallback/rollout.py`, double-run proven). The
  16 upstream OpenStax source checkouts were skipped (read-only upstreams). impo was committed as
  `6355242`; the other repos were staged for the maintainer.
- **2026-11-15:** the personal overlay's Makefile contract states the line
  (github.com/billsix/dotfiles `.ai-coding-conventions.personal.md`, "Header (invariant)"), with
  the note that detecting docker is not running correctly on it. There is no project generator in
  either sandbox; the contract is the template a new project copies, so updating it covers new
  projects.

## Decisions (with the maintainer, 2026-09-03)

- One fan-out task, not one per project.
- Scope was the `CONTAINER_CMD` swap only. Running correctly on docker (the `:Z` relabel,
  `--cgroups=disabled`, rootless UID mapping) is a separate task, to open only if that is ever the
  goal.

The one-shot codemod was removed with the archive commit.
