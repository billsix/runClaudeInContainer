# Add a `make shell-exec` target — run a script in the container env

**Status:** proposed — approved for creation; implementation NOT started (needs go-ahead to implement).
William Emerison Six <billsix@gmail.com>, 2026-08-29.
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

### 1. `entrypoint/shell.sh` — one-token change

Change the trailing `exec bash` → **`exec bash "$@"`**. This handles both modes with no branch:
- no args → `exec bash` = interactive shell, **identical to today**;
- a script-path arg → `exec bash <script>`, run **after the same setup**;
- `-c '<cmd>'` args → `exec bash -c '<cmd>'`, inline command after the same setup.

**Also:** skip the interactive-only auth hint when running a script. Guard the hint block with
`if [ "$#" -eq 0 ]; then … fi` (or `[ -t 1 ]`) so batch runs aren't polluted with the login reminder.

### 2. Makefile — a `shell-exec` target

The `shell` target **minus `-it`** (batch, CI-safe — Bill: "absolutely, drop it"), forwarding the
user's script/command into `shell.sh`. Same mount/flag set as `shell` (so `NESTED_PODMAN=1`,
`EXTRA_MOUNTS`, and — for this repo — the Claude config/auth mounts all carry over); the GUI/TTY
flags are irrelevant to a batch run and can be omitted or left (harmless).

Interface (both, per Bill — `SCRIPT=` is the headline, `CMD=` is the near-free convenience):
- `make shell-exec SCRIPT=tasks/adhoc/foo.sh` — a **repo-relative** script path; rides the existing
  `-v $(pwd):/<proj>/:Z` mount, so no extra mount is needed. Runs `bash <path>` from the repo root.
- `make shell-exec CMD='ruff check . && pytest -x'` — an **inline** command. Maps to `-c '<cmd>'`.

Arg construction (single source, prefers CMD when both given):
```make
SHELL_EXEC_ARGS = $(if $(CMD),-c '$(CMD)',$(SCRIPT))
```
```make
.PHONY: shell-exec
shell-exec: ## Run a script in the container env (no TTY): make shell-exec SCRIPT=path OR CMD='...'
	$(CONTAINER_CMD) run --rm \
		--entrypoint /bin/bash \
		$(FILES_TO_MOUNT) \
		-v ./entrypoint/shell.sh:/shell.sh:Z \
		$(EXTRA_MOUNTS) \
		$(NESTED_PODMAN_FLAGS) \
		$(CLAUDE_CONFIG_MOUNT) $(CLAUDE_JSON_MOUNT) \
		$(CLAUDE_DOTFILES_MOUNT) $(CLAUDE_PERSONAL_MOUNT) $(CLAUDE_AUTH_ENV) \
		$(CONTAINER_NAME) \
		/shell.sh $(SHELL_EXEC_ARGS)
```
(Exact mount list = whatever this repo's `shell` target carries; downstream projects mirror **their
own** `shell` target's list. The GUI/controller flags are dropped since there's no display for batch.)

**Caveat to verify — `CMD=` quoting.** The recipe runs under `/bin/sh`, which word-splits
`-c '$(CMD)'`; a `CMD` value containing single quotes will break the quoting. Document `CMD=` as "for
simple commands; use `SCRIPT=` for anything with quotes or multiple statements." Verify the argv
actually arrives intact (`make shell-exec CMD='echo hi && echo bye'` → both run) before calling it
done — the `$(pwd)`→`/shell.sh`→`bash -c` hop is the fiddly part.

## Docs to update (part of this task)

- **`README.md`** (this repo): add `make shell-exec` to **Quick start** (a one-liner with `SCRIPT=`)
  and to the **Layout** table's Makefile row / target list. Keep it commands-forward.
- **The personal overlay `~/.ai-coding-conventions.personal.md`** (a HOST file, NOT committed to this
  repo — Bill edits it, or approves the edit): this is where the cross-project template *contract*
  lives, so the convention must be recorded there for the phase-3 fan-out to be discoverable:
  - **Makefile contract** → add `shell-exec` to the standard-targets list (next to `shell`/`format`),
    noting it's the batch twin of `shell` (no `-it`, `SCRIPT=`/`CMD=`, routes through `shell.sh`).
  - **entrypoint contract** → change the `shell.sh` description from "cd + `exec bash`" to
    "setup + `exec bash "$@"` (interactive when no args; runs the script/command otherwise)".
- **No Dockerfile change** — the image already has bash; this is Makefile + entrypoint only.

## Verification (nested container — this repo builds/runs itself nested)

- `make image` (or reuse a built image), then:
  - `make shell` still drops into interactive bash unchanged (the `"$@"` no-arg path).
  - `make shell-exec CMD='whoami && pwd'` runs and exits 0, no interactive prompt, no auth-hint noise.
  - `make shell-exec SCRIPT=<a tiny repo-relative test script>` runs it from the repo root and its
    writes land on the host through the bind mount.
  - A script that exits non-zero makes `make shell-exec` exit non-zero (batch failures propagate).
  - `make shell-exec NESTED_PODMAN=1 CMD='podman info >/dev/null && echo nested-ok'` works with the
    nested flags (inner runs still need `--cgroups=disabled`, unchanged).
- Confirm `entrypoint/shell.sh` stays mode 755 after editing (a full rewrite drops +x — see this
  repo's/runCrushInContainer's note; here it's a one-line edit, but check `git ls-files -s`).

## Phasing (spun off after this lands)

- **Phase 2:** port to `runCrushInContainer` (same target; its Crush-specific mount set + its
  `shell.sh`). Its own task in that repo.
- **Phase 3:** fan out to every main-folder project that has a `make shell` (gacalc, mvp, hanoi,
  spimulator, texExpToPng, multivariate-math, gltron, …): the uniform `shell-exec` target mirroring
  each project's own `shell` mounts + the one-token `shell.sh` edit. Enumerate them and **flag any
  naming collision** (a project already using `run`/`exec` for something else) before touching it.
  Likely one task, or one per project if they diverge.

## Open questions

1. **Include `CMD=` or `SCRIPT=`-only?** Decided: **both** (Bill, 2026-08-29) — `SCRIPT=` primary,
   `CMD=` as the near-free inline convenience, with the quoting caveat above. (Recorded so a later
   session doesn't re-litigate; flip to SCRIPT-only if the CMD quoting proves more trouble than worth.)
