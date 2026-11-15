# Fan out `make shell-exec` to the core projects

**Status:** complete
**Completed:** 2026-08-29

## What this did

Added the `make shell-exec SCRIPT=… | CMD=…` batch twin of `make shell` to every repo with a
`make shell` target, following the phase-1 reference implementation in
`tasks/archive/2026/08/29/add-shell-exec-target.md`. Each repo was staged separately and
committed by the maintainer (William Emerison Six <billsix@gmail.com>).

## Scope (decided with the maintainer, 2026-08-29)

Recon found ~48 `make shell` targets across 13 repos.

- **Core, 9 template repos.** Tier 1 (real `shell.sh` setup): geometricalgebra,
  modelviewprojection, hanoi, multivariate-math, texExpToPng. Tier 2: apue, spimulator,
  regardingBritt, graphicalcontainer.
- **Bulk, re-scoped in by the maintainer** ("do all the other repos that have a make shell"):
  `billsEmacsConfigs/*` (20 language subdirs, one repo) and `openstax/osbooks-*` (16 repos),
  via an idempotent codemod, `tasks/adhoc/fan-out-shell-exec/apply_bulk.py` (one-shot, since
  removed; its diff lives in the work commits).
- **runCrushInContainer/client**, done last as the maintainer directed.
- `gltron` has no `make shell`, so it was not applicable.

## Per-project recipe

1. `REPO_MOUNT` = the project's real in-container mount path, read from `FILES_TO_MOUNT`, never
   `$(notdir $(CURDIR))` (geometricalgebra mounts at `/gacalc`, modelviewprojection at `/mvp`).
2. `SHELL_RUN_FLAGS` bundles the `shell` mount/flag block; `shell` consumes it; `make -n shell`
   verified token-identical before/after.
3. `SHELL_EXEC_ARGS = -c 'cd $(REPO_MOUNT) && $(if $(CMD),$(CMD),exec bash $(SCRIPT))'`, and
   `shell-exec` = `shell` minus `-it`, plus the empty-invocation guard.
4. `shell.sh`: `set -e` and `exec bash "$@"`, with the setup reviewed for `set -e` safety and
   file modes preserved.

## Results

- **geometricalgebra:** verified nested end to end: 42 tokens identical; setup ran under
  `set -e`; cwd `/gacalc`; exit status propagated (0→0, 5→5); guard exits 2. No kinks.
- **modelviewprojection:** verified nested end to end (image built, tested, removed): 48 tokens
  identical; `loadpackages.sh` ran under `set -e`; exit 4→4; guard exits 2.
- **hanoi, multivariate-math, texExpToPng, apue, spimulator, regardingBritt:** code, `make -n`
  identical, and `set -e` review. texExpToPng and apue mount only part of the repo, so `SCRIPT=`
  resolves only for mounted paths (noted in each Makefile). regardingBritt's `shell.sh` is baked,
  so its edit needs `make image`.
- **graphicalcontainer:** standardized into the template (the maintainer chose this over
  excluding it): new `entrypoint/shell.sh`, repo mounted at `/$(CONTAINER_NAME)`, the
  `shell`/`shell-exec` pair. A deliberate behavior change, so no identity check.
- **Bulk:** billsEmacsConfigs (`REPO_MOUNT=/root/texExpToPng`, selective mount; identity
  verified on python/rust/haskell/zsh; 40 files) and the 16 osbooks (`REPO_MOUNT=/$(CONTAINER_NAME)`;
  `shell-exec` appended to the combined `.PHONY` line; identity verified on physics and
  writing-guide). All 36 `shell.sh` passed `bash -n`. The codemod ran twice with the second run
  skipping everything. No bulk images were built.
- **runCrushInContainer/client:** `REPO_MOUNT=/work` (the driven project); `SHELL_RUN_FLAGS`
  bundles its full block; baked `shell.sh` got `set -e`, a guarded hint block and
  `exec bash "$@"`; `make -n shell` identical; checked by `make -n` only (its ~22 GB image
  overflowed the RAM store). README updated.

**Decision (the maintainer, 2026-08-29):** `shell-exec` depends on `image`, never `format`, so a
runner does not reformat source. Applied to texExpToPng, spimulator and the 20 billsEmacs
languages; billsEmacs was already committed with `format`, so the change went on top.

## Variations the fan-out surfaced

1. `shell.sh` path: `/shell.sh` (gacalc, mvm, hanoi, runClaude) vs `/usr/local/bin/shell.sh`
   (mvp, texExpToPng, apue, spimulator); `shell-exec` must use the same path as `shell`.
2. `shell.sh` delivery: bind-mounted (live) vs baked via `COPY` (regardingBritt, runCrush client).
3. `REPO_MOUNT` differs from the dir name in most repos.
4. Selective-mount projects limit `SCRIPT=` to mounted paths.
5. regardingBritt's `$(PODMAN_RUN_FLAGS)` sits before `--entrypoint`, so `SHELL_RUN_FLAGS` starts
   at `--entrypoint`.
6. `shell:` prerequisites vary (none / `image` / `format`).
7. X-flags variable name varies (`$(X_FLAGS_FOR_CONTAINER)` vs `$(USE_X)`).
8. `shell.sh` mode varies (755 vs 644 for hanoi, which is invoked as `bash shell.sh`).
9. A bare `make shell-exec` runs its prerequisite before the guard prints usage.
10. osbooks list `shell` in a combined `.PHONY` line.

These fed `tasks/standardize-project-container-template.md`. The personal-overlay convention
was left for the maintainer's go-ahead at the time.
