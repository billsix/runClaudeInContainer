# Persist Claude Code login (and all of `~/.claude`) across container runs

**Status:** DONE, ARCHIVED 2026-07-09. The Makefile `mkdir -p` fix is
applied (Bill's suggestion) and verified via `make -n shell`. The remaining
one-time sign-in happens naturally on the next `make shell` — nothing left to
track. (The optional memory rescue of the 2026-07-09 sandbox was not
performed; if that sandbox is gone, the memory rebuilds organically.)
Diagnosed 2026-07-09 from inside a running sandbox (the multi-day mvp/gacalc
session).

**Symptom (Bill):** every `make shell` requires signing in to Claude Code
again.

## Root cause — the persistence mount silently no-ops

The container being ephemeral (`--rm`) is **not** the problem and should stay
— fresh environment, image upgrades take effect, no drift. The design already
intends for login state to persist: this repo's `CLAUDE.md` ("The two-layer
Claude config") says *"auth, sessions, and credentials come from the host
`~/.claude` mount instead."* The mechanism exists in the `Makefile`:

```make
CLAUDE_CONFIG_DIR := $(HOME)/.claude                                    # line 75
CLAUDE_CONFIG_MOUNT := $(shell if [ -d $(CLAUDE_CONFIG_DIR) ]; then echo "-v $(CLAUDE_CONFIG_DIR):/root/.claude:Z" ; fi)
```

…but it is **conditional on host `~/.claude` existing**, and on Bill's host it
doesn't (Claude Code has never been run outside the container, so nothing ever
created the directory). The `$(shell if …)` evaluates to empty with no
warning, `/root/.claude` lands on the container's overlay filesystem, and
credentials die with the container.

Verified in the live sandbox: `findmnt -T /root/.claude` → `overlay` (not a
bind mount); only the two `CLAUDE_DOTFILES_MOUNT` submounts (`CLAUDE.md`,
`commands/`) are host-backed; `/root/.claude/.credentials.json` exists on the
overlay, freshly recreated at that day's sign-in.

## Impact — more than sign-in

Everything under `/root/.claude` is lost on each container exit:

- **OAuth credentials** (`.credentials.json`) → the re-sign-in Bill sees.
- **Persistent agent memory** (`projects/<project>/memory/`) — Claude's
  cross-session memory notes. Written in good faith each session, silently
  discarded at exit. The 2026-07-07→09 session's notes (package-cache
  convention, session loose ends) existed only in that container's overlay.
- **Session history / resumable transcripts** (`history.jsonl`, `projects/`,
  `sessions/`) — no `claude --resume` across container restarts.
- **Settings, plugins, file-history.**

## Fix (container stays ephemeral)

1. **Makefile hardening — APPLIED 2026-07-09 (staged).** The existence check
   was replaced with an unconditional `mkdir -p` *inside the `$(shell …)`
   that computes the variable*:

   ```make
   CLAUDE_CONFIG_MOUNT := $(shell mkdir -p $(CLAUDE_CONFIG_DIR); echo "-v $(CLAUDE_CONFIG_DIR):/root/.claude:Z")
   ```

   Placement matters: `CLAUDE_CONFIG_MOUNT` is `:=`-expanded at Makefile
   *parse* time, so a `mkdir` as a recipe line in the `shell:` target would
   run **after** the flag was already computed — the `$(shell)` runs before.
   And since `make` runs on the host, this creates the host-side `~/.claude`
   itself; no manual host step needed. Verified by `make -n shell` (flag
   emitted). The `CLAUDE_DOTFILES_MOUNT` over-mounts (`CLAUDE.md`,
   `commands/`) stack on top of the parent mount unchanged.

2. **Bill, on next `make shell`:** sign in one final time — it lands in the
   now-persistent host directory and sticks thereafter. Caveat: the mount
   keeps `:Z` (consistent with this Makefile's other mounts), which relabels
   host `~/.claude` to a container SELinux type — harmless to Bill's own
   (unconfined) host processes; the sandbox runs `--security-opt
   label=disable` so `:z`/no flag would also work if relabeling under
   `$HOME` is ever unwanted.

3. **Optional rescue, only while the 2026-07-09 sandbox is still running:**
   copy `/root/.claude/projects/-foo-opt/memory/` out through a host-visible
   mount (a scratch path in this repo, not committed), then move it into the
   new host `~/.claude/projects/-foo-opt/` after step 1. Do **not** shuttle
   `.credentials.json` through a git repo — it's a secret; just sign in fresh
   once. If that sandbox is already gone, skip — the memory is lost and will
   be rebuilt organically.

## What was deliberately NOT chosen

- **A long-lived / named container** (dropping `--rm`, `podman start` reuse):
  solves sign-in but sacrifices the ephemeral guarantees (clean state each
  run, image updates applying immediately) and diverges from the
  container-per-project template all other repos follow. Rejected.
- **A named volume for `/root/.claude`:** persists, but hides the state from
  the host filesystem; a plain host directory is inspectable/backupable and
  is what the existing design already reaches for. Rejected.
