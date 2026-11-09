# Sandbox commands in `tools/bin/`, on PATH in both sandboxes (`review-status` first)

**Status:** proposed — needs go-ahead
**Priority:** 6
**Difficulty:** 3
**Created:** 2026-11-09
**Source:** conversation, 2026-11-09
**Decisions** (William Emerison Six <billsix@gmail.com>, 2026-11-09):

1. This is its own task, not done as part of the review-status work.
2. The command is named `review-status`, matching the `/review-status` slash command.
3. runClaudeInContainer and runCrushInContainer use the same mechanism. The maintainer left the
   choice open ("either way, but make it consistent"). Chosen: **bake `tools/bin/` into each image
   and bind-mount each file over its baked copy at run time**, the pattern both sandboxes already use
   for their dotfiles (baked by `COPY`, the live copy mounted over it). The image works offline on
   its own, and a host edit still shows up on the next launch without a rebuild.

## BLUF

Give the sandboxes a home for **commands they provide to the agent**: a `tools/bin/` directory in each
repo whose files appear in `/usr/local/bin` inside the container, named without their extension. The
first is `tasks/reference/review_status.py`, which becomes `tools/bin/review-status`, so `/review-status`
and `/audit-repo deep` call `review-status` instead of `python3 ~/.claude/reference/review_status.py`.
Done means `review-status` runs from any repo root in a freshly launched container of both sandboxes,
and every caller and doc uses the new name.

## Context

- **Why:** `tasks/reference/` is the durable-knowledge directory ("states what is TRUE"), but it holds
  three scripts only because it is the directory that gets mounted (at `~/.claude/reference/`, by
  `CLAUDE_DOTFILES_MOUNT` in the `Makefile`). A script there runs as
  `python3 ~/.claude/reference/<name>.py`; a command on PATH is shorter and keeps docs and tools apart.
- **The tool now:** `tasks/reference/review_status.py` (SHARED TOOL banner, `+x`, shebang
  `#!/usr/bin/env python3`), mirrored byte-identically in runCrushInContainer `tasks/reference/` and
  `client/entrypoint/dotfiles/.config/crush/reference/`. Built and archived in
  `tasks/archive/2026/11/09/review-status-tool.md`.
- **Files that name it today** (`git grep -l review_status`, outside `tasks/archive/`):
  - runClaudeInContainer: `CLAUDE.md`, `entrypoint/dotfiles/.claude/CLAUDE.md`, the commands
    `entrypoint/dotfiles/.claude/commands/audit-repo.md` and `review-status.md`, and
    `tasks/reference/repo-review-conventions.md`;
  - runCrushInContainer: the Crush `CLAUDE.md` and the `audit-repo.md`/`review-status.md` commands under
    `client/entrypoint/dotfiles/.config/crush/`, plus both copies of `container-file-layout.md` (its
    mapping table) and of `repo-review-conventions.md`.
- **Why `tools/bin/`, not `tools/`:** runClaudeInContainer's `tools/` holds repo-maintenance scripts
  (`check_helm_file_at_point.sh` and its `.el`), and runCrushInContainer's holds egress-sweep and probe
  scripts. Those aren't sandbox commands, and an `.el` is no command at all.
- **Mounting:** don't mount a directory over `/usr/local/bin`, which would hide the image's own files.
  Generate one read-only mount per file with a wildcard, so adding a command means adding a file:
  `$(foreach f,$(wildcard tools/bin/*),-v $(CURDIR)/$(f):/usr/local/bin/$(notdir $(f)):ro,Z)`.
  The files in `tools/bin/` already carry their final names (no extension), so `notdir` is enough.
  Thread it into the `shell`/`shell-exec` flags (`SHELL_RUN_FLAGS` in runClaude; the client's
  shell/shell-exec flags in runCrush), and keep host mounts conditional as the repos' `CLAUDE.md` rules
  require.
- **Out of scope (deliberately):** the vendored tools `check_local_annotations.py` and
  `update_dep_common.sh` stay in `tasks/reference/`. Projects copy them into their own `tools/`, and
  their banners and several project `CLAUDE.md` files name `tasks/reference/` as canonical, so moving
  them would mean updating pointers across the fleet. Raise that as its own task if wanted.
- **Gotchas:** a `Write` rewrite drops `+x` (restore with `git add --chmod=+x`). The `COPY` must
  preserve the mode. Outside a container, neither the command nor `~/.claude/reference/` exists, so
  nothing on the host changes.

## Plan

- [ ] runClaudeInContainer: `git mv tasks/reference/review_status.py tools/bin/review-status`; update its
  SHARED TOOL banner (canonical path, mirrors, how it is invoked). Its `__doc__`/argparse usage should
  read `review-status`.
- [ ] runClaudeInContainer: add `COPY tools/bin/ /usr/local/bin/` to the `Dockerfile`, and the wildcard
  mount to the `Makefile`'s shell flags.
- [ ] runCrushInContainer: the same move (into `client/tools/bin/` or a repo-level `tools/bin/`, whichever
  the client build context can `COPY` from; check `client/Makefile`'s context), the client `Dockerfile`
  `COPY`, and the wildcard mount. Remove both `review_status.py` copies from the reference directories.
- [ ] Update every caller and doc listed above to `review-status`. In both `container-file-layout.md`
  copies, replace the reference-directory row with a `tools/bin/` row, and in runClaudeInContainer's
  `CLAUDE.md` move the tool out of the "SHARED, VENDORED tool scripts" paragraph into a short
  `tools/bin/` note.
- [ ] Verify in each sandbox: `make help`; `make -n shell` shows the mount; `make image`; then in a fresh
  `make shell`, `command -v review-status` and `review-status` from github.com/billsix/geometricalgebra's
  root (expect the 2026-11-08 record's table). Check that a host edit to `tools/bin/review-status` shows
  up after a relaunch with no rebuild. Never run a `: image` target just to look at a recipe; use
  `make -n`.
- [ ] Stage by path in both repos.

## Open questions

None.
