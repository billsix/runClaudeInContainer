# Use native kernel overlay for the nested store, and keep the RAM store behind its toggle

**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Completed:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §11, §3.2 F1 F2

## Summary

The nested podman stopped using fuse-overlayfs, which walked the whole image on every layer
commit, and now uses the kernel's native overlay on both inner stores (the ext4 dir and the
tmpfs). The RAM store stayed behind `NESTED_PODMAN_STORE=tmpfs`, documented in the README and
`CLAUDE.md`. The "build big images on the host" rule was rewritten. Mechanism, requirements and
measurements are in `tasks/reference/nested-run-and-gates.md` ("Storage speed") and
`tasks/reference/nested-podman-design.md`.

## What changed

- `entrypoint/dotfiles/.config/containers/storage.conf` dropped `mount_program` and set
  `mountopt = "nodev"`. The vendor drop-in's `metacopy=on` is rejected in a user namespace.
- A `containers.conf` drop-in (`image_copy_tmp_dir = "/var/lib/containers/tmp"`), installed by the
  `Dockerfile`, moved buildah's temp dir onto the store volume. Without it a native build failed
  (`mounting an overlay over build context directory … invalid argument`), because `/var/tmp` sits on
  the sandbox's overlay rootfs.
- `entrypoint/shell.sh` created that directory and warned at start when podman reported no native
  overlay diff (a sandbox image from before the switch).
- The docs (`README.md`, project and shared `CLAUDE.md`, `nested-run-and-gates.md`,
  `nested-podman-design.md`, `image-build-and-storage-pipeline.md`, `Makefile` comments) and
  `exampleRunClaude.sh` were updated. `exampleRunClaude.sh` gained a working commented-out RAM variant.

## Verification

- **In the old sandbox, 2026-11-15:** with a scratch store, a two-step build on spimulator took 13 s
  native, 9 s native on tmpfs, and 62 s under fuse-overlayfs. `make image` built on a native store in
  29m46s (24.6 GB). The built image contained the new config, Lean 4.35.0 and `claude` on the login
  `PATH`. `make -n shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=tmpfs` produced
  `tmpfs /var/lib/containers:rw,size=8g`.
- **In a sandbox launched from the rebuilt image via `exampleRunClaude.sh` (disk store),
  2026-11-15:**
  - `podman info` reported `overlay`, Native Overlay Diff `true`, `overlay.mountopt=nodev`, and the
    additional image store `/var/lib/shared-images`.
  - `/var/lib/containers/tmp` and the drop-in were in place.
  - All host images listed `ReadOnly=true`, with none in the inner store.
  - Build timings:
    - `FROM localhost/spimulator` plus `RUN echo` plus `RUN dnf install -y cowsay`: 14.3 s. The
      networked `RUN` worked under `BUILDAH_ISOLATION=chroot`.
    - One `RUN` on the 17.2 GB gacalc image: 1.2 s (fuse: about 4 minutes).
    - github.com/billsix/texExpToPng's `make image`: 5 s, with 19 of 20 steps from the host cache.
  - A nested `podman run --cgroups=disabled` ran in 0.7 s.
  - `git log`, `gpg -K` and writes under `/mnt/sda1` worked through the `:z` mounts.
  - `podman info` also listed `"imagestore":"/var/lib/shared-images"` in `GraphOptions`, though no
    config sets that key. Builds wrote to the normal inner store, so this was only how podman 6.1.3
    displays the additional store.
- **Left to the maintainer, not blocking**, each a blocked follow-up task:
  - the host `make image` time (`tasks/record-host-sandbox-image-build-time.md`);
  - a relaunch with the RAM store (`tasks/verify-ram-store-toggle.md`);
  - the host `make -n shell` check (`tasks/verify-host-shell-has-no-cgroups-flag.md`).
- The sibling change in runCrushInContainer was tracked separately in its own
  `tasks/nested-native-overlay.md`.
