# Use native kernel overlay for the nested store, and keep the RAM store behind its toggle

**Status:** blocked — implemented and verified in the sandbox 2026-11-15; waiting on the maintainer's host rebuild + relaunch
**Blocked on:** `[HOST] make image` in runClaudeInContainer, then `[HOST] make shell NESTED_PODMAN=1` (or `exampleRunClaude.sh`), so a sandbox actually runs the new config.
**Recheck:** `[CONTAINER] podman info --format '{{index .Store.GraphStatus "Native Overlay Diff"}}'` prints `true`, the shell prints no `[nested podman] … no native overlay diff` warning, and a small nested build (`FROM <a host image>` + one `RUN`) commits in seconds. Cleared → rewrite this into a done-record and archive it.
**Priority:** 1
**Difficulty:** 4
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §11, §3.2 F1 F2

## BLUF

The nested podman drives overlay through fuse-overlayfs, so every layer commit walks the whole image. Native kernel overlay works on both nested stores (the ext4 dir and the tmpfs). Switch to it, document the RAM store's toggle, and rewrite the "build big images on the host" rule. Done means a freshly launched sandbox reports `"Native Overlay Diff":"true"` and the docs match. The relaunch is the maintainer's, so this ends `blocked` on that check.

## Context

- Record §11: the sandbox is root in a user namespace with `cap_sys_admin`; native overlay fails on the overlay rootfs but works on the ext4 store volume and on tmpfs.
- Validated 2026-11-15 with a scratch store (`CONTAINERS_STORAGE_CONF` with no `mount_program`, `mountopt = "nodev"`; `CONTAINERS_CONF_OVERRIDE` with `[engine] image_copy_tmp_dir` on the store volume). The same two-step build (`RUN echo …`, `RUN dnf install cowsay`) on the 3.1 GB `localhost/spimulator` base took **13 s native against 62 s with fuse-overlayfs**; native on a tmpfs store took 9 s. Host images were read from `/var/lib/shared-images` read-only in both.
- The vendor drop-in `00-vendor-rootful.conf` sets `mountopt = "nodev,metacopy=on"`; `metacopy` is rejected in a user namespace, so our drop-in overrides `mountopt`.
- buildah mounts the build context under its temp dir (default `/var/tmp`, on the overlay rootfs), which fails natively; `image_copy_tmp_dir` moves it onto the store volume.
- Maintainer decision (record, "Answers"): keep the RAM store behind `NESTED_PODMAN_STORE=tmpfs`; README and `CLAUDE.md` say how; `exampleRunClaude.sh` keeps the current command uncommented and a fixed commented-out RAM variant (the current one sets `NESTED_PODMAN_TMPFS_SIZE` without `NESTED_PODMAN_STORE=tmpfs`).

## Plan

1. `entrypoint/dotfiles/.config/containers/storage.conf`: drop `mount_program`, set `mountopt = "nodev"`, rewrite the header comment.
2. A `containers.conf` drop-in with `image_copy_tmp_dir` on the store volume (`/var/lib/containers/tmp`), created at start by `entrypoint/shell.sh`; install it in the `Dockerfile`.
3. `shell.sh`: warn at start when `Native Overlay Diff` is false (an old image), so slow commits are explained.
4. Rewrite the fuse-overlayfs rationale and the build-on-host rule: `README.md`, project `CLAUDE.md`, shared `CLAUDE.md` ("Running projects in a nested container"), `nested-run-and-gates.md`, `nested-podman-design.md`, `image-build-and-storage-pipeline.md`, `Makefile` comments.
5. RAM toggle: README + `CLAUDE.md` section; fix `exampleRunClaude.sh`.
6. Verify the image builds (`make image`, nested, using the native store) and the new config gives native diff; then `blocked` on the maintainer's host rebuild + relaunch.

## Log

- **2026-11-15, implemented** (commit "nested podman: native kernel overlay instead of
  fuse-overlayfs"): `storage.conf` without `mount_program` and with `mountopt = "nodev"`; the
  `containers.conf` drop-in (`image_copy_tmp_dir = "/var/lib/containers/tmp"`), installed by the
  `Dockerfile`; `entrypoint/shell.sh` creates the dir and warns when podman reports no native diff;
  the docs and `exampleRunClaude.sh` as planned.
- **2026-11-15, verified in the sandbox.** Without the `containers.conf` override, a native build
  fails (`mounting an overlay over build context directory … invalid argument`), so the drop-in is
  required. `make image` built on a scratch native-overlay store in 29m46s (24.6 GB image, the full
  459-package install). Inside the built image: no `mount_program` in either storage file,
  `mountopt = "nodev"`, the `image_copy_tmp_dir` drop-in, Lean 4.35.0, `claude` on the login
  `PATH`. The RAM toggle: `make -n shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=tmpfs` gives
  `tmpfs /var/lib/containers:rw,size=8g`. Not verifiable here: a sandbox launched from that image
  (this session runs the old one), which is the Recheck above.
