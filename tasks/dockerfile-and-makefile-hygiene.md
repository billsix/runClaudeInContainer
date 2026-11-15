# Reorder the Dockerfile and fix the Makefile and script hygiene

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 4
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §8.1, §8.2, §8.3, §8.4, §2.4, §4.5 F13 F20

## BLUF

The Dockerfile copies the dotfiles before the slow package layer, the Makefile lacks `PODMAN_RUN_FLAGS` and puts `:Z` on host mounts, and several small build and script defects remain. Done means the image builds, the layers are least-volatile-first, and each listed defect is gone.

## Context

- §8.1: `COPY entrypoint/dotfiles/ /root/` and the `USE_EMACS_CONFIG` step sit before the package layer.
- Maintainer decisions: add `PODMAN_RUN_FLAGS` to every `podman run` (never `build`) with whatever that implies; "never `:Z`" for host mounts.
- §8.3: `format.sh` lost `+x`, shfmt diff in `01b-install-binary-tools.sh`. §8.4: `.gitignore` `#*#`, `tasks/reference/__pycache__/`, no `.dockerignore`. §2.4: the `/etc/containers/storage.conf` COPY is unused. §4.5: SC2155 in `.extrabashrc`, `#!/bin/env bash` in `entrypoint.sh`.
- `shell-exec` gets the `image` prerequisite only if it does not slow a normal run; otherwise documented.

## Plan

1. Move the dotfiles COPY and the Emacs-config step after the package, Claude Code and Lean layers.
2. Add `PODMAN_RUN_FLAGS` and thread it into every `podman run`; drop `:Z` from host mounts (`:z` or none) where `label=disable` makes it pointless.
3. The small fixes; `.dockerignore`.
4. Verify: `make help`, `make -n shell`, `make image` (nested), shfmt/shellcheck clean.
