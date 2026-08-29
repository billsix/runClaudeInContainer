# Add a `make shell-exec` target — run a script in the container env

**Status:** phase 1 IMPLEMENTED + verified 2026-08-29 (Makefile + `entrypoint/shell.sh` + README).
One item pending: the personal-overlay convention text (a HOST file — awaiting Bill's approval, drafted
below). Phases 2–3 remain (see Phasing). William Emerison Six <billsix@gmail.com>, 2026-08-29.

**Verification run (2026-08-29, all green):** `make -n shell` byte-identical (48 tokens) before/after the
`SHELL_RUN_FLAGS` refactor; `shell-exec` `SCRIPT=`/`CMD=` produce cwd-pinned `-c 'cd /runClaudeInContainer
&& …'` payloads; empty `make shell-exec` → usage + exit 2; container integration (against `fedora:44` —
the heavy `claudecontainer` image was NOT rebuilt, and this repo's `shell.sh` has no venv/install setup so
a light image faithfully exercises the mechanics): script runs from the repo root despite `shell.sh`'s
`cd /`, host-write lands via the bind mount, exit codes propagate (7→7); fail-fast — a failing setup step
aborts before the script runs (script line absent, non-zero); `SCRIPT=` file resolves + runs; interactive
no-arg path unchanged (hint + `exec bash`); graphics parity — `shell` and `shell-exec` carry identical
`DISPLAY`/`WAYLAND_DISPLAY`/`/dev/input` tokens; `shell.sh` stays mode 755, `bash -n` clean.
**Priority:** 3
**Difficulty:** 3
**Created:** 2026-08-29

## Goal

A batch twin of `make shell`: run an arbitrary bash script (or inline command) **inside the same
ephemeral `--rm` container, with the same setup and environment `make shell` gives** — for ad-hoc
scripts, one-offs, CI-style runs — without dropping into an interactive shell and pasting commands.

This is **phase 1** (the reference implementation + the cross-project convention). Phases 2–3 are
spun off once this shape is proven (see "Phasing").

## The design (settled with Bill, 2026-08-29)

The key realization: **`make shell` is not "bare container + bash" — the `entrypoint/shell.sh` does
real setup first** (activate venv, editable-install the package, generate files, `cd` to the repo
root) and *then* `exec bash`. That post-setup state IS "the container's environment." So `shell-exec`
must route through the **same `shell.sh`**, or a script would run with no venv / no install / wrong
cwd. (runClaudeInContainer's own `shell.sh` is lighter — `cd /`, an auth hint, `exec bash` — but the
downstream projects, e.g. `github.com/billsix/geometricalgebra` and
`github.com/billsix/modelviewprojection`, do the heavy setup; the design must serve both.)

### 1. `entrypoint/shell.sh` — fail-fast setup, then `exec bash "$@"`

Two changes:

- **`exec bash` → `exec bash "$@"`.** No args → interactive shell, **identical to today**. Args (a
  `-c '…'` payload from `shell-exec`, see §2) → run them after the same setup. One line, no branch.
- **Guard the setup fail-fast** (Bill's #3, 2026-08-29 — "fail fast"). Add `set -e` at the top so a
  failed setup step (generate, editable install, `loadpackages.sh`) **aborts** instead of running the
  script in a half-set-up environment — for the batch/CI case a broken install must not silently
  proceed and mask the real cause. The final `exec bash` starts a **fresh** bash *not* under `-e`
  (`set -e` isn't inherited across `exec bash` unless SHELLOPTS is exported), so interactive/script
  behaviour is unchanged — only the setup is fail-fast, and it's fail-fast for interactive `make shell`
  too (a good thing: a failed install should stop, not hand you a broken shell).
  - Use **`set -e` only, NOT `set -u`** — the auth-hint block references possibly-unset
    `$CLAUDE_CODE_OAUTH_TOKEN`/`$ANTHROPIC_API_KEY`.
  - **Per project, verify the setup is `set -e`-safe** before adding it: no setup step may legitimately
    return nonzero. A bare `[ … ]` test used as a standalone command would trip `-e`; conditionals
    *inside* `if … fi` are exempt, so the existing auth-hint block is fine — but check each project's
    `shell.sh` (e.g. a `grep` whose "no match" is expected would abort under `-e`).

**Also:** skip the interactive-only auth hint in script mode — guard the hint block with
`if [ "$#" -eq 0 ]; then … fi` so batch runs aren't polluted with the login reminder.

### 2. Makefile — a `shell-exec` target

The `shell` target with **exactly one thing removed: `-it`** (batch, CI-safe — Bill: "absolutely,
drop it"), forwarding the user's script/command into `shell.sh`. **Everything else `shell` carries
carries over**, including the **X11 and Wayland flags** and the controller passthrough — Bill,
2026-08-29: *"if the project supports graphics in make shell, I want graphics support in any script I
run."* So `NESTED_PODMAN=1`, `EXTRA_MOUNTS`, the Claude config/auth mounts, AND the display/GPU/gamepad
flags all carry over; a script that opens a window (or renders headlessly via the shared Xvfb) behaves
exactly as it would inside `make shell`. `-it` is the *only* difference.

Interface (both, per Bill — `SCRIPT=` is the headline, `CMD=` is the near-free convenience). **Both
run from the repo root** (see the cwd fix), so `SCRIPT=` is repo-relative and means the same thing in
every project:
- `make shell-exec SCRIPT=tasks/adhoc/foo.sh` — a **repo-relative** script path; runs `bash foo.sh`
  from the repo root, riding the existing `-v $(pwd):<mount>:Z` mount (no extra mount needed).
- `make shell-exec CMD='ruff check . && pytest -x'` — an **inline** command, also run from the repo
  root.

**Pin the payload to the repo root — do NOT trust `shell.sh`'s cwd** (Bill's #1, 2026-08-29). The
downstream projects' `shell.sh` happens to `cd` to the repo root (`cd /gacalc/`, `cd /mvp/`), but
runClaudeInContainer's does **`cd /`** while the repo is at `/$(PROJECT_DIR)` — so a naive
`bash $(SCRIPT)` would look for `/tasks/adhoc/foo.sh` and fail, **in the very repo phase 1 lands in**.
(The existing `format` target already sidesteps this: `-c 'cd /$(PROJECT_DIR) && bash …'`, not trusting
`shell.sh`.) So `shell-exec` `cd`s to the repo mount **itself**, in the payload, fully decoupling it
from `shell.sh`'s cwd:

```make
SHELL_EXEC_ARGS = -c 'cd $(REPO_MOUNT) && $(if $(CMD),$(CMD),exec bash $(SCRIPT))'
```
`shell.sh` runs its setup, then `exec bash -c 'cd /<repo> && <payload>'` — the payload always runs
from the repo root regardless of where `shell.sh` left the cwd.

**`REPO_MOUNT` — define the in-container mount path ONCE, share it with `FILES_TO_MOUNT`** (same
single-source-of-truth spirit as `SHELL_RUN_FLAGS`; kills the hardcoded-path drift). runClaudeInContainer
already has `PROJECT_DIR ?= $(notdir $(CURDIR))` and mounts at `/$(PROJECT_DIR)`, so here
`REPO_MOUNT = /$(PROJECT_DIR)`. **Phase-3 pitfall — do NOT blindly derive it from `$(notdir $(CURDIR))`:**
several projects mount at a name that differs from their directory (gacalc's dir is `geometricalgebra`
but it mounts at **`/gacalc`**; mvp's dir is `modelviewprojection` but it mounts at **`/mvp`**). Set
`REPO_MOUNT` to each project's **actual current mount path** (read it out of that project's existing
`FILES_TO_MOUNT`), then route both `FILES_TO_MOUNT` and `shell-exec` through it.

**Bundle the shared invocation into one variable so the two targets can't drift** (Bill, 2026-08-29).
Rather than have `shell-exec` re-list the mount/flag block (the copy-paste that *is* the drift
surface, and the exact "stale copy-paste" failure the template conventions warn about), extract
everything between `run … --rm` and `$(CONTAINER_NAME)` into a single `SHELL_RUN_FLAGS` variable that
**both** targets reference. Then the environment is defined once, and the two targets differ only in
the two things that *should* differ — `-it` and the trailing args — both visible on the `run` line.

```make
# Single source of truth for the shell / shell-exec container invocation, so the
# two targets can never drift. Scoped to this pair ONLY -- do NOT fold in
# format/jupyter/test/docs, which deliberately carry different mount sets.
SHELL_RUN_FLAGS = \
	--entrypoint /bin/bash \
	$(FILES_TO_MOUNT) \
	-v ./entrypoint/shell.sh:/shell.sh:Z \
	$(EXTRA_MOUNTS) \
	$(NESTED_PODMAN_FLAGS) \
	$(CLAUDE_CONFIG_MOUNT) $(CLAUDE_JSON_MOUNT) \
	$(CLAUDE_DOTFILES_MOUNT) $(CLAUDE_PERSONAL_MOUNT) $(CLAUDE_AUTH_ENV) \
	$(X_FLAGS_FOR_CONTAINER) \
	$(WAYLAND_FLAGS_FOR_CONTAINER) \
	$(CONTROLLER_FLAGS_FOR_CONTAINER)

# The in-container repo mount path, defined ONCE (shared with FILES_TO_MOUNT).
REPO_MOUNT = /$(PROJECT_DIR)

# shell-exec payload: cd to the repo root (independent of shell.sh's cwd), then run
# the inline CMD, else the repo-relative SCRIPT. Single source; prefers CMD if both given.
SHELL_EXEC_ARGS = -c 'cd $(REPO_MOUNT) && $(if $(CMD),$(CMD),exec bash $(SCRIPT))'

.PHONY: shell
shell: ## <keep the existing description>
	$(CONTAINER_CMD) run -it --rm $(SHELL_RUN_FLAGS) $(CONTAINER_NAME) /shell.sh

.PHONY: shell-exec
shell-exec: ## Run a script in the container env (no TTY): make shell-exec SCRIPT=path OR CMD='...'
	@[ -n "$(SCRIPT)$(CMD)" ] || { echo 'usage: make shell-exec SCRIPT=<repo-relative path> | CMD="..."'; exit 2; }
	$(CONTAINER_CMD) run --rm $(SHELL_RUN_FLAGS) $(CONTAINER_NAME) /shell.sh $(SHELL_EXEC_ARGS)
```
The `@[ -n … ]` guard (Bill's #2) turns a bare `make shell-exec` — which would otherwise run the full
setup and then a TTY-less `bash` that reads EOF and silently exits — into a clear usage error.

Two parts of this are **refactors of the working `shell` target**, so treat them carefully:
- **`shell` is rewritten to consume `SHELL_RUN_FLAGS`** instead of its inline block. This must be
  **behaviour-preserving**: `make -n shell` prints a **byte-identical** command (whitespace aside)
  before and after the refactor — that diff is the regression check, run it. `SHELL_RUN_FLAGS` must
  therefore contain **exactly** what `shell` lists today, in the same order (copy `shell`'s current
  block into the variable, don't retype it).
- **Scope `SHELL_RUN_FLAGS` to the shell/shell-exec pair only.** `format`, `jupyter`, `test`, `docs`
  carry deliberately different mount sets (no `-it`, `EXPOSE_PORT`, `output/` mounts…); do NOT route
  them through this variable — over-bundling recreates the drift problem in the other direction.

Downstream projects do the same per-project: bundle **their own** `shell` block into their own
`SHELL_RUN_FLAGS`, then both targets reference it — so a graphics-capable project keeps its
X/Wayland/GPU flags in `shell-exec` automatically, and the phase-3 fan-out is a small self-verifying
edit rather than a block copy-paste.

**Caveat — `CMD=` quoting AND host expansion.** Two footguns, both `CMD`-only (Bill's #4):
1. **Quoting:** the recipe runs under `/bin/sh`, which word-splits `$(SHELL_EXEC_ARGS)`; a `CMD`
   containing single quotes breaks the surrounding `-c '…'`.
2. **Host expansion:** `$VAR` in a `CMD` expands on the **host** (make, then `/bin/sh`) *before* it
   reaches the container — `CMD='echo $HOME'` prints the **host's** `$HOME`, not the container's.
Document `CMD=` as: "simple commands only; for anything with single quotes, multiple statements, or a
container-side `$VAR`, use `SCRIPT=` (or `$$VAR` to defer expansion)." Verify the argv arrives intact
(`make shell-exec CMD='echo hi && echo bye'` → both run) — the `make`→`/bin/sh`→`/shell.sh`→`bash -c`
hop is the fiddly part.

## Docs to update (part of this task)

- **`README.md`** (this repo): add `make shell-exec` to **Quick start** (a one-liner with `SCRIPT=`)
  and to the **Layout** table's Makefile row / target list. Keep it commands-forward.
- **The personal overlay `~/.ai-coding-conventions.personal.md`** (a HOST file, NOT committed to this
  repo — Bill edits it, or approves the edit): this is where the cross-project template *contract*
  lives, so the convention must be recorded there for the phase-3 fan-out to be discoverable:
  - **Makefile contract** → add `shell-exec` to the standard-targets list (next to `shell`/`format`),
    noting it's the batch twin of `shell` (no `-it`, `SCRIPT=`/`CMD=`, routes through `shell.sh`), AND
    record the anti-drift convention: **`shell` and `shell-exec` share one `SHELL_RUN_FLAGS` variable**
    (the whole `run … --rm` → `$(CONTAINER_NAME)` block) so they can't diverge; scoped to that pair
    only, not `format`/`jupyter`/`test`/`docs`.
  - **entrypoint contract** → change the `shell.sh` description from "cd + `exec bash`" to
    "setup + `exec bash "$@"` (interactive when no args; runs the script/command otherwise)".
- **No Dockerfile change** — the image already has bash; this is Makefile + entrypoint only.

## Verification (nested container — this repo builds/runs itself nested)

- **Refactor regression check (do this first, before building anything):** `make -n shell` prints a
  **byte-identical** command (whitespace aside) before and after moving `shell`'s block into
  `SHELL_RUN_FLAGS`. Capture `make -n shell` on the pre-refactor Makefile, apply the refactor, diff —
  it must be empty. This proves the `SHELL_RUN_FLAGS` extraction changed `shell`'s behaviour by
  nothing.
- `make image` (or reuse a built image), then:
  - `make shell` still drops into interactive bash unchanged (the `"$@"` no-arg path).
  - `make shell-exec CMD='whoami && pwd'` runs and exits 0, no interactive prompt, no auth-hint noise.
  - **Cwd fix (#1):** `make shell-exec CMD='pwd'` prints `$(REPO_MOUNT)` (the repo root), NOT `/` —
    proving `shell-exec` overrides `shell.sh`'s `cd /`. And `make shell-exec SCRIPT=<tiny repo-relative
    test script>` resolves and runs **here in runClaudeInContainer** (where `shell.sh` does `cd /`),
    with its writes landing on the host through the bind mount.
  - **Empty-invocation guard (#2):** bare `make shell-exec` (no SCRIPT, no CMD) prints the usage line
    and exits 2 — it does NOT run setup or a silent no-op bash.
  - **Fail-fast setup (#3):** force a setup failure (e.g. temporarily break the editable-install step)
    and confirm `make shell-exec SCRIPT=…` **aborts before the script runs**, non-zero — then revert.
  - A script that exits non-zero makes `make shell-exec` exit non-zero (batch failures propagate).
  - `make shell-exec NESTED_PODMAN=1 CMD='podman info >/dev/null && echo nested-ok'` works with the
    nested flags (inner runs still need `--cgroups=disabled`, unchanged).
  - **Graphics parity** (the reason X/Wayland stay): on a project whose `shell` supports graphics, a
    `shell-exec` script that touches the display works the same as inside `make shell` — verify the
    `$DISPLAY` / Wayland socket is present in the script's env (`make shell-exec CMD='echo $DISPLAY;
    ls -la $XDG_RUNTIME_DIR/wayland-* 2>/dev/null'`), and ideally that a real headless render (the
    shared-Xvfb recipe) or a windowed demo behaves as under `shell`. This is the check that would
    catch a regression if someone later trims the GUI flags from `shell-exec`.
- Confirm `entrypoint/shell.sh` stays mode 755 after editing (a full rewrite drops +x — see this
  repo's/runCrushInContainer's note; here it's a one-line edit, but check `git ls-files -s`).

## Phasing (spun off after this lands)

- **Phase 2:** port to `runCrushInContainer` (same target; its Crush-specific mount set + its
  `shell.sh`). Its own task in that repo.
- **Phase 3:** fan out to every main-folder project that has a `make shell` (gacalc, mvp, hanoi,
  spimulator, texExpToPng, multivariate-math, gltron, …). Per project, the same moves as phase 1:
  - a `REPO_MOUNT` var = that project's **actual** mount path (NOT `$(notdir $(CURDIR))` — see the
    pitfall above; gacalc dir `geometricalgebra` → `/gacalc`), used by both `FILES_TO_MOUNT` and
    `shell-exec`;
  - bundle that project's `shell` block into its own `SHELL_RUN_FLAGS` (verified byte-identical via
    `make -n shell`), add the `shell-exec` target reusing it;
  - the `shell.sh` edits (fail-fast `set -e` + `exec bash "$@"`) — **not blindly mechanical:** verify
    each project's `shell.sh` actually ends in `exec bash` (append `"$@"` to whatever its real final
    `exec bash…` line is) and that its setup is `set -e`-safe (per §1) before applying.

  The shared vars make each edit small and self-verifying instead of a block copy-paste. Enumerate the
  projects and **flag any naming collision** (a project already using `run`/`exec` for something else)
  before touching it. Likely one task, or one per project if they diverge.

## Decisions (settled 2026-08-29 with Bill — recorded so a later session doesn't re-litigate)

1. **Both `SCRIPT=` and `CMD=`** — `SCRIPT=` primary, `CMD=` the near-free inline convenience (with the
   quoting + host-expansion caveats). Flip to SCRIPT-only if `CMD` proves more trouble than worth.
2. **#1 — pin the payload to the repo root** (`cd $(REPO_MOUNT)`), decoupled from `shell.sh`'s cwd, so
   `SCRIPT=` is repo-relative and consistent in every project. `REPO_MOUNT` is a shared var set to each
   project's real mount path (not `$(notdir $(CURDIR))`).
3. **#2 — empty-invocation usage guard** on the target.
4. **#3 — fail-fast setup**: `set -e` in `shell.sh` (setup only; the exec'd bash is fresh, not under
   `-e`); `set -e`-safety verified per project.
5. **#4 — folded in**: the `CMD=` host-expansion caveat, and the phase-3 "verify the real `exec` line
   and `set -e`-safety" note.

No open questions remain — ready to implement on go-ahead.
