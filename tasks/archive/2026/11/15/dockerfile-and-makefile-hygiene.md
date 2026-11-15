# Reordered the Dockerfile and fixed the Makefile and script hygiene

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 4
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §8.1, §8.2, §8.3, §8.4, §2.4, §4.5, §1.3 F13 F20

## What this did

- **Dockerfile, least-volatile first:** base + `dnf upgrade`, the ~460-package install, `01b`
  (shfmt, procs), Claude Code, Lean, then the often-edited part: the dotfiles COPY, the nested
  podman's storage and containers drop-ins, the `USE_EMACS_CONFIG` opt-out. An edit to a dotfile
  or the Emacs config now rebuilds only those layers. The unread `/etc/containers/storage.conf`
  main-file COPY is gone (podman reads the `~/.config` copy and the drop-ins). `claude update` sets
  `PATH` itself instead of sourcing `~/.bashrc`, which sources `~/.extrabashrc` before the dotfiles
  COPY now brings it.
- **Makefile:** `PODMAN_RUN_FLAGS` threaded into the `shell`, `shell-exec` and `format` runs, never
  `build`. It is keyed on `/run/.containerenv` (podman creates it in every container), not on
  `NESTED_PODMAN`, because here `NESTED_PODMAN=1` is the host launch flag and a host run must not
  get `--cgroups=disabled`. Every host mount is `:z` (maintainer decision: never `:Z`; the sandbox
  runs `label=disable`). `shell-exec` depends on `image`, per the template contract.
- **Small fixes:** `entrypoint/format.sh` is executable again; `01b-install-binary-tools.sh` and
  `shell.sh` are shfmt-clean; `.gitignore` escapes `\#*\#` and ignores `__pycache__/`; a
  `.dockerignore` keeps `.git`, `tasks/`, `tools/`, caches and image tars out of the context;
  `.extrabashrc` declares then exports (SC2155); `entrypoint.sh` uses `#!/usr/bin/env bash`.
- **Docs (§1.3):** the Dockerfile summaries in `CLAUDE.md`, `README.md` and
  `tasks/reference/image-build-and-storage-pipeline.md` describe the new order, including `01b`,
  Lean and the drop-ins; `nested-podman-design.md` no longer claims the `/etc` copy is read.

## Verification

- `make help`, `make -n shell NESTED_PODMAN=1`, `make -n format`, `make -n image USE_EMACS_CONFIG=0`
  parse; inside this container the dry run shows `--cgroups=disabled` (`/run/.containerenv` exists).
- `shfmt -d -i 4 entrypoint/*.sh` clean; `shellcheck` clean on `.extrabashrc`;
  `git check-ignore '#foo#'` matches.
- `make image` (nested, on a native-overlay store): the first run failed at `claude update`
  (`/root/.extrabashrc: No such file or directory`, caused by the reorder), fixed as above; the
  rebuild passed in 1m35s, reusing the cached package layer. In the image: no
  `/etc/containers/storage.conf`, both `50-runclaude-nested.conf` drop-ins, `claude`, `lean`,
  `shfmt`, `procs`, `.extrabashrc`, the Emacs config, and no `mount_program`.
