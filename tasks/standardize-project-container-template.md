# Standardize the project container-template (mounts, shell.sh, shell-exec)

**Status:** proposed — needs go-ahead. Surfaced by the `shell-exec` fan-out
(`fan-out-shell-exec-to-projects.md`), 2026-08-29. William Emerison Six <billsix@gmail.com>.
**Priority:** 5
**Difficulty:** 5

## Why

Adding `make shell-exec` across ~45 projects exposed how much the "one container-per-project template"
has **drifted** in ways that are accidental, not deliberate. Each divergence made the fan-out a
per-project judgment call instead of a mechanical edit. This task proposes formalizing a standard in
the template contract (the **nested CLAUDE.md** / personal-overlay Makefile+entrypoint contract that
runClaudeInContainer and runCrushInContainer define for the projects they manage), so future projects
conform and the next cross-cutting change is mechanical. **A sibling task exists in
runCrushInContainer** — the same standard should land in both meta-repos' contract docs.

## Divergences found (the evidence)

| Aspect | Variants seen in the wild |
| --- | --- |
| `shell.sh` invocation path | `/shell.sh` (gacalc, mvm, hanoi[bare], runClaude), `/usr/local/bin/shell.sh` (mvp, texExpToPng, apue, spimulator, billsEmacs, osbooks) |
| `shell.sh` delivery | bind-mounted (edit is live) vs **BAKED via COPY** (regardingBritt — edit needs `make image`) |
| repo mount path | `/gacalc`, `/mvm`, `/mvp`, `/spimulator`, `/apue`, `/root/texExpToPng`, `/$(CONTAINER_NAME)`, `/osbooks-*` — often ≠ the directory name |
| what's mounted | whole repo (`-v .:/x`) vs **selective files** (texExpToPng, apue, billsEmacs mount only source) |
| nested passthrough | `$(PODMAN_RUN_FLAGS)` present (regardingBritt, billsEmacs, osbooks) vs absent (gacalc, mvp, …) |
| `shell:` prereqs | none / `image` / `format` |
| X11 flag var name | `$(X_FLAGS_FOR_CONTAINER)` vs `$(USE_X)` |
| `shell.sh` mode | 755 vs 644 |
| outliers | `graphicalcontainer`: no `shell.sh`, no repo mount, `shell` runs `bash` directly |

## Proposed standard (to encode in the contract doc — confirm each)

1. **One `shell.sh` mount path.** Pick `/usr/local/bin/shell.sh` (the majority) and always **bind-mount**
   it (never bake the launcher), so edits to `shell.sh` are live without an image rebuild.
2. **`REPO_MOUNT` variable, mandatory.** Every Makefile defines `REPO_MOUNT` = the project's real
   in-container mount path, used by BOTH `FILES_TO_MOUNT` and `shell-exec`. Never derive it from
   `$(notdir $(CURDIR))` (dir name ≠ mount name in several projects).
3. **Mount the whole repo at `REPO_MOUNT`** (`-v $(pwd):$(REPO_MOUNT):Z`) as the default, so
   `SCRIPT=` resolves for any repo-relative path. A project that deliberately mounts selectively
   (texExpToPng/apue/billsEmacs) documents that `SCRIPT=` is limited to mounted paths — the exception,
   flagged in-Makefile, not the norm.
4. **`SHELL_RUN_FLAGS` shared by `shell` + `shell-exec`** (already the fan-out pattern) — the one
   source of truth for the invocation; scoped to that pair only.
5. **`$(PODMAN_RUN_FLAGS)` passthrough on every project** (harmless on a normal host, enables nested
   `--cgroups=disabled` without re-editing) — standardize its presence and position (on the `run` line).
6. **`shell.sh` = `set -e` (fail-fast setup) then `exec bash "$@"`** — the fan-out convention.
7. **Prereq policy — DECIDE:** should `shell` / `shell-exec` carry `image` / `format` prereqs? Open
   question: a `format` prereq means `make shell-exec` **reformats the tree before running the script**,
   which is surprising for a runner. Options: (a) drop `format` from `shell`/`shell-exec` (make it its
   own step), (b) keep on `shell` but NOT `shell-exec`, (c) keep both for parity. **Lean: (b)** — a
   runner shouldn't mutate source as a side effect.
8. **One X11 flag var name** (`$(X_FLAGS_FOR_CONTAINER)`), rename `$(USE_X)`.
9. **`graphicalcontainer`**: either bring it into the template (add a bind-mounted `shell.sh` + repo
   mount) or explicitly document it as a non-template demo image excluded from these conventions.

## Plan

- [ ] Get Bill's decision on each numbered item (esp. #3 whole-vs-selective and #7 prereq policy).
- [ ] Encode the agreed standard in the **template contract** (personal-overlay Makefile/entrypoint
      contract + the meta-repos' CLAUDE.md), with a short "conformance checklist" line per item.
- [ ] (Optional, separate) a conformance checker under `tools/` that flags a project diverging from the
      standard — the runnable sibling of the checklist.
- [ ] Migrate the divergent projects to the standard (a follow-on; the fan-out already normalized the
      `shell`/`shell-exec` pair — this is the remaining mount/path/prereq normalization).

## Decisions (Bill, 2026-08-29) — 3 of the items settled; already applied where noted

1. **#3 whole-repo mount = the default** (selective mount is a documented per-project exception). ✅ decided.
2. **#7 `shell-exec` prereq: `image`, never `format`** — a runner must not reformat source. ✅ decided AND
   **applied**: `shell-exec: format` → `shell-exec: image` in texExpToPng, spimulator, and the 20
   billsEmacsConfigs langs (the only projects where the runner had a `format` prereq). The bulk codemod
   was updated to emit `image`.
3. **#9 `graphicalcontainer`: standardize INTO the template.** ✅ decided AND **applied** 2026-08-29:
   added `entrypoint/shell.sh` (`set -e` + `exec bash "$@"`), a repo mount at `/$(CONTAINER_NAME)`, a
   bind-mounted launcher, and the `shell`/`shell-exec` pair (`make shell-exec CMD='glxgears'` runs a demo
   headlessly). Staged.

## Still open (the remaining standardization — needs go-ahead to migrate)

The `shell`/`shell-exec` PAIR is now normalized everywhere. The remaining drift (items 1, 2, 5, 8, and
the baked-vs-bind-mount of the *setup*, not the launcher) is a separate migration:
- one `shell.sh` mount path (`/usr/local/bin/shell.sh`), always bind-mounted (migrate the baked ones:
  regardingBritt, runCrush client);
- one X11 flag var name (`$(X_FLAGS_FOR_CONTAINER)`; rename `$(USE_X)` in mvp/apue);
- encode the whole standard + a conformance checklist in the contract doc (the personal overlay already
  got the `shell-exec`/`shell.sh` half, 2026-08-29).

## Cross-links

- `tasks/reference/shell-exec-and-container-template.md` — the harvested design + divergence table.
- `tasks/archive/2026/08/29/fan-out-shell-exec-to-projects.md` — the fan-out that surfaced all of this
  (full kinks log; archived).
- `tasks/archive/2026/08/29/add-shell-exec-target.md` — the `shell-exec` reference implementation (archived).
- runCrushInContainer: the sibling standardization task (same standard, that meta-repo's contract doc).
