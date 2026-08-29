# `make shell-exec` + the container-per-project template

**Reference document** — the design of the `shell-exec` target and the per-project template
variations the fleet-wide fan-out (~45 projects, 2026-08-29) surfaced. States what is true; the
*open* standardization migration is `tasks/standardize-project-container-template.md`. The
cross-project *contract* (for all projects) lives in the personal `.ai` overlay
(`~/.ai-coding-conventions.personal.md`, source at `github.com/billsix/dotfiles`). Harvested from the
now-archived `add-shell-exec-target.md` + `fan-out-shell-exec-to-projects.md`.

## The design

`make shell-exec SCRIPT=<repo-relative path> | CMD='...'` is the **batch twin of `make shell`**: it
runs a script/command in the *same* container env as `shell` and exits — no TTY — for ad-hoc/CI use.

- **`SHELL_RUN_FLAGS`** — the whole `run … --rm` → `$(CONTAINER_NAME)` mount/flag block, defined ONCE
  and shared by `shell` and `shell-exec` so they can't drift. Scoped to that pair only (NOT
  `format`/`docs`/etc). `shell-exec` = `shell` minus `-it`.
- **`REPO_MOUNT`** — the project's real in-container mount path (read from `FILES_TO_MOUNT`, **never**
  `$(notdir $(CURDIR))`: dir name ≠ mount name in several projects, e.g. `geometricalgebra`→`/gacalc`).
- **`SHELL_EXEC_ARGS = -c 'cd $(REPO_MOUNT) && $(if $(CMD),$(CMD),exec bash $(SCRIPT))'`** — pins the
  payload's cwd to the repo root, independent of `shell.sh`'s own `cd`, so `SCRIPT=` is repo-relative
  everywhere. Empty-invocation guard: `@[ -n "$(SCRIPT)$(CMD)" ] || { echo usage; exit 2; }`.
- **`entrypoint/shell.sh`** — `set -e` (fail-fast setup; use `-e` not `-u`), the project's setup, then
  **`exec bash "$@"`** (no args → interactive as before; a `-c '…'` payload → run it after setup, in a
  fresh bash not under `-e`). Interactive-only banners guarded on `[ "$#" -eq 0 ]`.
- **Prereq rule:** `shell-exec` depends on **`image`, never `format`** — a runner must not reformat the
  source as a side effect.
- **`SCRIPT=` needs the script under a mounted path.** Whole-repo mount (the default) → any path works;
  a *selective-mount* project (only some files) is limited to `CMD=` / mounted-path scripts, noted
  in-Makefile.

## Per-project variations the fan-out surfaced (the reusable map)

| Aspect | Variants in the fleet |
| --- | --- |
| `shell.sh` invocation path | `/shell.sh` (gacalc, mvm, hanoi[bare], runClaude, regardingBritt, runCrush client) vs `/usr/local/bin/shell.sh` (mvp, texExpToPng, apue, spimulator, billsEmacs, osbooks, graphicalcontainer) |
| `shell.sh` delivery | **bind-mounted** (edit is live) — now including runCrush client (bind-mounted 2026-08-29). regardingBritt is BAKED but is a dead project (left as-is). |
| repo mount path (`REPO_MOUNT`) | `/gacalc`, `/mvm`, `/mvp`, `/spimulator`, `/apue`, `/root/texExpToPng`, `/work`, `/$(CONTAINER_NAME)` — often ≠ dir name |
| what's mounted | whole repo vs **selective files** (texExpToPng, apue, billsEmacs mount only source) |
| nested passthrough | `$(PODMAN_RUN_FLAGS)` present (regardingBritt, billsEmacs, osbooks, runCrush) vs absent |
| `shell:` prereqs | none / `image` / `format` |
| X11 flag var name | `$(X_FLAGS_FOR_CONTAINER)` (now standard) — was `$(USE_X)` in mvp/apue (renamed 2026-08-29) |
| `shell.sh` mode | 755 vs 644 (invoked as `bash shell.sh`, so +x not required) |

**A make gotcha worth keeping:** `make shell-exec` with no args runs the `image`/`format` PREREQUISITE
before the empty-guard fires (prereqs run before the recipe) — so on a prereq-carrying project a bare
invocation builds/reformats, then prints usage. Test the guard via `make -n` on prereq projects.

## Applied (2026-08-29) + still open

- **Applied everywhere:** the `shell`/`shell-exec` pair + `SHELL_RUN_FLAGS` + `exec bash "$@"` +
  `set -e` (core 9 incl. graphicalcontainer standardized-in; billsEmacs 20; osbooks 16; runCrush
  client). `shell-exec: image` (not `format`). `USE_X`→`X_FLAGS_FOR_CONTAINER` (mvp, apue).
- **Also done 2026-08-29:** runCrush client launcher bind-mounted (was baked) — the metaproject you
  actively develop shouldn't need a 22 GB rebuild to tweak `shell.sh`.
- **Still open** (`standardize-project-container-template.md`): the cosmetic path unification (one
  `shell.sh` path, `/usr/local/bin/shell.sh`) across the remaining `/shell.sh` projects; encode the
  full conformance checklist in the contract doc. (regardingBritt's baked launcher is left as-is — a
  dead project.)

## Cross-links

- `tasks/standardize-project-container-template.md` — the open migration + the agreed standard.
- Personal `.ai` overlay — the cross-project Makefile/entrypoint *contract* (has the `shell-exec` half).
- `tasks/archive/2026/08/29/add-shell-exec-target.md` / `.../fan-out-shell-exec-to-projects.md` — work records.
- The bulk codemod (`tasks/adhoc/fan-out-shell-exec/apply_bulk.py`) — one-shot; removed at archive (in git history).
