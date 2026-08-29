# Fan out `make shell-exec` to the core projects

**Status:** implemented 2026-08-29 — all in-scope projects done and staged (NOT committed — Bill
commits). Core (9, minus the excluded `graphicalcontainer`) + bulk (36) + **runCrushInContainer/client**
(the metaproject port, done last as Bill directed). Reference impl: `add-shell-exec-target.md`.
Remaining: Bill commits each repo; the personal-overlay convention + the standardization task
(`standardize-project-container-template.md`, in both meta-repos) await Bill's go-ahead. William
Emerison Six <billsix@gmail.com>.

**runCrushInContainer/client (metaproject port):** `REPO_MOUNT=/work` (mounts the driven PROJECT there);
`SHELL_RUN_FLAGS` bundles its full block (NESTED_PODMAN env, SELinux/net flags, TMUX/GNUPG/GITCONFIG/
PERSONAL/STACK mounts, EXTRA_MOUNTS); `shell.sh` is **BAKED** (needs `make image`) — `set -e` + guarded
Crush/tunnel hint + `exec bash "$@"`. `make -n shell` byte-identical; payload `cd /work && …`; guard via
`make -n` (its image is ~22 GB — known to overflow the RAM store — so NOT built/tested here). README
updated. Staged.
**Priority:** 4
**Difficulty:** 4

## Scope (decided with Bill, 2026-08-29)

Recon found **~48 `make shell` targets across 13 repos** — far more than expected. Boundary:

- **IN scope (this task):** the 9 core "container-per-project template" repos —
  - **Tier 1 (real `shell.sh` setup — kinks live here):** geometricalgebra, modelviewprojection,
    hanoi, multivariate-math, texExpToPng
  - **Tier 2 (simple / no heavy setup):** apue, spimulator, regardingBritt, graphicalcontainer
- **BULK — now IN scope** (Bill re-scoped 2026-08-29: "do all the other repos that have a make shell").
  `billsEmacsConfigs/*` (20 language subdirs, one git repo) and `openstax/osbooks-*` (16 book repos,
  **each its own git repo**). Both are uniform templates → done via an idempotent codemod
  (`tasks/adhoc/fan-out-shell-exec/apply_bulk.py`). See "Bulk results" below.
- **Not applicable:** `gltron` has no `make shell`.
- **runCrushInContainer** is the LAST step (the other template repo), its own task after the kinks are
  worked out here.

Each is a **separate git repo** — stage per-repo; Bill commits each.

## Per-project recipe (from the phase-1 reference — `add-shell-exec-target.md`)

Do one project at a time, verify, then move on. Per project:

1. **`REPO_MOUNT`** — set to the project's **actual** in-container mount path, read from its existing
   `FILES_TO_MOUNT` (NOT `$(notdir $(CURDIR))` — gacalc's dir is `geometricalgebra` but it mounts at
   `/gacalc`; mvp's is `modelviewprojection` but mounts at `/mvp`). Used by `shell-exec`.
2. **`SHELL_RUN_FLAGS`** — bundle that project's `shell` mount/flag block (everything between
   `run … --rm` and `$(CONTAINER_NAME)`) into one variable; refactor `shell` to consume it. Verify
   **`make -n shell` byte-identical** (token list) before/after — the regression check.
3. **`SHELL_EXEC_ARGS`** = `-c 'cd $(REPO_MOUNT) && $(if $(CMD),$(CMD),exec bash $(SCRIPT))'`, and the
   **`shell-exec`** target (= `shell` minus `-it`, plus the empty-invocation guard), reusing
   `SHELL_RUN_FLAGS`.
4. **`shell.sh`** — add `set -e` (fail-fast setup) and change the final `exec bash` → `exec bash "$@"`.
   - **Verify the final `exec` line** is actually `exec bash` (adapt to whatever it really is).
   - **Verify `set -e`-safety**: no setup step legitimately returns nonzero (a bare `[ … ]` as a
     standalone command trips `-e`; `if … fi` conditionals are exempt). Tier-1 projects have real
     setup (venv/codegen/install) — run it under `set -e` and confirm it still succeeds.
   - Use targeted edits (preserve mode 755); confirm `git ls-files -s` after.
5. **Verify nested** (`--cgroups=disabled`; reuse the project's built image if present):
   - `make -n shell` byte-identical (step 2).
   - `make shell-exec CMD='pwd'` → the repo mount path (cwd fix), setup ran, exit 0.
   - `make shell-exec SCRIPT=<tiny repo-relative script>` runs from repo root; host-write lands.
   - non-zero script → non-zero exit; bare `make shell-exec` → usage + exit 2.
   - graphics parity: `shell` and `shell-exec` carry identical `DISPLAY`/`WAYLAND`/GPU tokens
     (`make -n` grep) on graphics-capable projects.
6. **Docs:** each project's README/help if it lists `shell` (many are terse — match local style).

## Checklist

Tier 1:
- [x] **geometricalgebra** — DONE + fully verified nested 2026-08-29 (image was already built).
      `REPO_MOUNT=/gacalc` (dir≠mount pitfall handled); `make -n shell` byte-identical (42 tokens);
      real setup ran under `set -e` (gacalc importable); cwd=/gacalc; exit propagation 0→0/5→5; guard
      exits 2; shell.sh mode 755. **Zero kinks** — phase-1 recipe worked as-is. Staged.
- [ ] modelviewprojection (`REPO_MOUNT=/mvp`; shell.sh: venv + `loadpackages.sh`) — code in
      `modelviewprojection/modelviewprojection`
- [ ] hanoi
- [ ] multivariate-math
- [ ] texExpToPng

- [x] **modelviewprojection** — DONE + fully verified nested 2026-08-29 (built image, tested, `podman
      rmi`'d). `REPO_MOUNT=/mvp`; byte-identical (48 tok); `loadpackages.sh` ran under `set -e`
      (`mvp-import-OK`); cwd=/mvp; exit 4→4; guard exits 2. Staged. shell.sh at `/usr/local/bin/shell.sh`.
- [x] **hanoi** — DONE (code + dry-run + set-e review) 2026-08-29. `REPO_MOUNT=/$(CONTAINER_NAME)`
      (=/hanoi); byte-identical (18 tok); `--system` pip setup (set-e-safe); shell.sh mode **644**
      (invoked `bash shell.sh`, +x not needed); invoked bare `shell.sh` (cwd=/ resolves /shell.sh). Staged.
- [x] **multivariate-math** — DONE (code + dry-run + set-e review) 2026-08-29. `REPO_MOUNT=/mvm`;
      byte-identical (48 tok); venv+editable setup (same pattern gacalc proved nested). Staged.
- [x] **texExpToPng** — DONE (code + dry-run) 2026-08-29. `REPO_MOUNT=/root/texExpToPng`; byte-identical
      (61 tok incl `format`+`image` prereqs). **Selective mount** (only meson.build/src/tests) → `CMD=`
      general, `SCRIPT=` only for mounted paths (noted in Makefile). `shell:`/`shell-exec:` keep the
      `format` prereq for parity. Staged.

Tier 2:
- [x] **apue** — DONE (code + dry-run) 2026-08-29. `REPO_MOUNT=/apue`; byte-identical; **selective mount**
      (only apue.3e) → same `SCRIPT` caveat. `shell:`/`shell-exec:` keep `image` prereq. Staged.
- [x] **spimulator** — DONE (code + dry-run) 2026-08-29. `REPO_MOUNT=/spimulator` (whole repo mounted);
      byte-identical; `format` prereq kept. (Only 1 real shell target; the "2" in recon was a submatch.) Staged.
- [x] **regardingBritt** — DONE (code + dry-run) 2026-08-29. `REPO_MOUNT=/$(CONTAINER_NAME)`
      (=/regardingbritt); byte-identical; **`$(PODMAN_RUN_FLAGS)` passthrough kept on the run line** for
      both targets; `shell.sh` is **BAKED** (COPY, not bind-mounted) → the edit needs `make image` to take
      effect (noted in shell.sh). `image` prereq kept. Staged.
- [x] **graphicalcontainer** — **STANDARDIZED INTO the template** 2026-08-29 (Bill chose standardize-in
      over exclude). Was an outlier (`shell` ran `bash` directly, no `shell.sh`, no repo mount). Now: new
      `entrypoint/shell.sh` (`set -e` + `exec bash "$@"`), repo mounted at `/$(CONTAINER_NAME)`,
      bind-mounted launcher, `shell`/`shell-exec` pair (`make shell-exec CMD='glxgears'` runs a demo
      headlessly). A deliberate behavior change (now mounts the repo + uses shell.sh), so no
      byte-identical check. Staged.

**Post-decision change (Bill, 2026-08-29):** `shell-exec` now depends on **`image`, not `format`** (a
runner must not reformat source). Applied to texExpToPng, spimulator, and the 20 billsEmacs langs (the
only `format`-prereq runners); the codemod was updated to emit `image`. billsEmacs was already committed
by Bill with `format`, so the `format`→`image` delta was applied on top (can't rewrite a pushed commit).

## Kinks log — per-project variations the fan-out surfaced (reflect record)

The phase-1 recipe held, but real projects vary in ways the generic "mirror the project's own shell
block" covers. Recorded here (and feeding the standardization task):

1. **`shell.sh` invocation path varies:** `/shell.sh` (gacalc, mvm, hanoi[bare], runClaude), `/usr/local/bin/shell.sh`
   (mvp, texExpToPng, apue, spimulator). shell-exec must invoke the SAME path the `shell` target uses.
2. **`shell.sh` delivery varies:** bind-mounted (gacalc/mvp/mvm/hanoi/texExpToPng/apue/spimulator — edit
   is live) vs **BAKED via COPY** (regardingBritt — edit needs `make image`). Must check per project.
3. **`REPO_MOUNT` ≠ dir name; read it from `FILES_TO_MOUNT`:** `/gacalc`, `/mvm`, `/mvp`, `/spimulator`,
   `/apue`, `/root/texExpToPng`, or `/$(CONTAINER_NAME)` (hanoi, regardingBritt). NEVER `$(notdir $(CURDIR))`.
4. **Selective-mount projects** (texExpToPng: only meson.build/src/tests; apue: only apue.3e) mount part
   of the repo → `CMD=` always works; `SCRIPT=` only resolves for a mounted path. Noted in each Makefile.
5. **`$(PODMAN_RUN_FLAGS)` passthrough** (regardingBritt) sits BEFORE `--entrypoint` on the run line —
   keep it there on BOTH targets; `SHELL_RUN_FLAGS` is `--entrypoint …` onward only.
6. **`shell:` prerequisites vary:** none (gacalc/mvm/hanoi), `image` (apue/regardingBritt), `format`
   (spimulator/texExpToPng). shell-exec mirrors the same prereq for parity (note: a `format` prereq
   reformats before every shell-exec — a judgment call, kept for parity).
7. **X-flags var name varies:** `$(X_FLAGS_FOR_CONTAINER)` (gacalc/mvm) vs `$(USE_X)` (mvp/apue).
8. **`shell.sh` mode varies:** 755 (most) vs 644 (hanoi) — invoked as `bash shell.sh`, so +x not required;
   preserve whatever it is (targeted Edits preserve mode).

**Full nested integration tests done:** geometricalgebra, modelviewprojection (the two most complex
setups — venv+codegen+editable, and loadpackages — both green under `set -e`). Others: code + `make -n`
byte-identical + `set -e`-safety review of the setup (all safe). Building every image was avoided by the
`podman rmi`-after-each policy applied to the two that were built.

9. **`make shell-exec` with no args runs the `image`/`format` PREREQUISITE before the empty-guard
   fires** (make runs prereqs before the recipe). So on a prereq-carrying project a bare `make
   shell-exec` will build the image / reformat, *then* print usage + exit 2. Not wrong, but a wart —
   and it means the guard can only be quickly tested on no-prereq projects (or via `make -n`).
10. **shell-exec inheriting a `format` prereq reformats the tree before every run** (texExpToPng,
    spimulator, billsEmacsConfigs). Kept for strict parity with `shell`, but a *runner* that reformats
    first is arguably surprising — a **standardization question** (see the standardization task).
11. **osbooks list `shell` in a combined `.PHONY: all image shell …` line** (target list varies per
    book) rather than a dedicated `.PHONY: shell` — the codemod appends `shell-exec` to whichever
    `.PHONY` line names `shell`.

## Bulk results (2026-08-29)

Applied via `tasks/adhoc/fan-out-shell-exec/apply_bulk.py` (idempotent; run twice → all skip; exact
per-family template match, reports drift instead of mangling):

- **billsEmacsConfigs (20 langs, 1 git repo):** `REPO_MOUNT=/root/texExpToPng` (selective mount, like
  texExpToPng → `CMD=` general, `SCRIPT=` mounted-paths only); `format` prereq kept; `PODMAN_RUN_FLAGS`
  passthrough kept. shell.sh bind-mounted. **byte-identical `make -n shell`** verified on python/rust/
  haskell/zsh; payload + guard correct. 40 files staged in the one repo.
- **openstax osbooks (16, each its own git repo):** `REPO_MOUNT=/$(CONTAINER_NAME)` (whole repo mounted
  → `SCRIPT=` works); `image` prereq kept; `PODMAN_RUN_FLAGS` passthrough kept; `shell-exec` added to
  the combined `.PHONY` line. **byte-identical** verified on physics/writing-guide; payload + guard
  correct. Each repo staged individually.
- All 36 bulk `shell.sh`: `set -e` + `exec bash "$@"`, `bash -n` clean, bind-mounted.
- No bulk images were built to completion (mechanism proven by the core nested tests; the bulk has no
  runtime setup so no `set -e` risk). A `texexptopng-rust` image built as a side effect of a guard
  test was `podman rmi`'d.

**Codemod lifecycle:** committed with this work (audit trail). At archive, `/archive-task` should
`git rm` it (one-shot bulk edit, not reusable) — its diff survives in the work commits.

## Cross-links

- `tasks/add-shell-exec-target.md` — the phase-1 reference implementation + design rationale.
- Personal overlay Makefile/entrypoint contract (host file) — the convention these all follow.
