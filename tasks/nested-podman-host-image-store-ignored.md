# Nested podman ignores the host image store again (podman 6 skips /etc/containers/storage.conf)

**Status:** proposed — needs go-ahead
**Priority:** 3
**Difficulty:** 3
**Started:** 2026-11-12
**Sibling:** runCrushInContainer `tasks/nested-podman-host-image-store-ignored.md` (same bug in the
Crush client image; fix both the same way).

## BLUF

Inside the sandbox, nested podman no longer sees the host's image store, even though the store is
mounted. So every nested `make image` rebuilds from scratch instead of reusing layers the
maintainer already built on the host. Done means:
- a drop-in at `/etc/containers/storage.conf.d/` (or an equivalent proven fix) restores the
  read-only host store;
- `README.md` and `exampleRunClaude.sh` show how to use host image reuse;
- the reference docs record the podman 6 behaviour;
- a cheap check makes the next silent regression loud.

## Context

- **The mechanism.** The design is in `tasks/reference/nested-podman-design.md`, in the passage
  starting "reads `/etc/containers/storage.conf`, **not** the rootless", and in
  `tasks/reference/image-build-and-storage-pipeline.md`, which shows the
  `/var/lib/shared-images` bind and lists the store mounts in a table.
  - The `Makefile` defaults `NESTED_PODMAN_HOST_IMAGESTORE` to `$(HOME)/.local/share/containers/storage`.
  - `NESTED_PODMAN_IMAGESTORE_MOUNT` bind-mounts that path read-only at `/var/lib/shared-images`.
  - `entrypoint/dotfiles/.config/containers/storage.conf` sets
    `additionalimagestores = [ "/var/lib/shared-images" ]` and `mount_program = fuse-overlayfs`.
  - The `Dockerfile` copies that file to `/etc/containers/storage.conf`. The comment above that
    `COPY` records the 2026-09-27 fix.
- **It worked on 2026-09-27.** `nested-podman-design.md` ("Confirmed live after the rebuild")
  records `podman images` listing the host images read-only.
- **It is broken now.** Observed 2026-11-12 in a sandbox with podman 6.1.3 and containers-common
  0.69.2-1.fc45:
  - The mount is present (`/dev/sdf1 on /var/lib/shared-images type ext4 (ro…)`). The store is
    readable: its `overlay-images/images.json` lists 878 images, including host builds of
    `modelviewprojection`, `gacalc` and `claudecontainer`.
  - `/etc/containers/storage.conf` holds the right `additionalimagestores` line.
  - Plain podman ignores it. `podman info --format '{{json .Store.GraphOptions}}'` reports
    `"additionalImageStores":["/usr/lib/containers/storage"]` (the built-in default), and
    `podman images` lists only images built inside the sandbox.
  - Two things restore the store. Both were tested 2026-11-12; each listed 85 read-only host images:
    1. `CONTAINERS_STORAGE_CONF=/etc/containers/storage.conf podman …`.
    2. A drop-in `/etc/containers/storage.conf.d/50-test.conf` containing only
       `[storage.options]` and `additionalimagestores = [ "/var/lib/shared-images" ]`. The
       test file was removed afterwards.
  - containers-common now ships `/usr/share/containers/storage.conf.d/00-vendor.conf` (only
    `[storage] driver = "overlay"`). The **likely** cause is that this podman's config loader
    reads the `/usr/share` file plus `storage.conf.d/` drop-ins and no longer reads
    `/etc/containers/storage.conf`. That is unconfirmed. Step 1 below confirms it from podman's
    docs or source before the reference doc states it as fact.
- **Cost seen so far.** No nested build on 2026-11-12 reused a host layer. mvp and gacalc full
  image builds ran from scratch inside the sandbox: about 40 minutes for gacalc, mostly the
  Lean/Mathlib layer. They would have been near-instant from the host's copies.

## Plan

1. **Confirm the cause.**
   - Check how podman 6 / containers-common 0.69 finds storage config (the
     `containers-storage.conf(5)` man page in the image, or the containers/storage config loader):
     does `/etc/containers/storage.conf` still load when `/usr/share/containers/storage.conf.d/`
     exists, and in which order do drop-ins apply?
   - Record the answer, with its source, in `tasks/reference/nested-podman-design.md`.
2. **Fix in the image.** Recommended: ship the setting as a drop-in,
   `/etc/containers/storage.conf.d/50-runclaude-nested.conf`, holding `additionalimagestores` and
   `mount_program`.
   - Keep the full `/etc/containers/storage.conf` too, so an older podman still works, unless
     step 1 shows that harms anything.
   - Why a drop-in, not `ENV CONTAINERS_STORAGE_CONF`: the drop-in is podman's documented layering
     mechanism. The env var replaces the whole config search and would also have to reach every
     subprocess, such as `make` recipes and buildah.
   - If step 1 shows the drop-in is not reliable, use `ENV CONTAINERS_STORAGE_CONF=/etc/containers/storage.conf`
     in the `Dockerfile` instead.
   - Update the comment above the `COPY` in `Dockerfile` to describe the current mechanism. It
     describes what the code does now; the history goes in the commit message.
3. **Make a regression loud.** In `entrypoint/shell.sh`'s nested setup, warn once if
   `/var/lib/shared-images` is mounted but `podman info` does not list it in
   `additionalImageStores`. It is a warning, not a failure, because a launch without the store
   mounted is legitimate.
4. **README.md.** In "Building containers inside the sandbox (nested Podman)", add a short
   subsection on host image reuse:
   - what it gives (a nested `make image` reuses layers built on the host);
   - `NESTED_PODMAN_HOST_IMAGESTORE` (default `~/.local/share/containers/storage`, mounted
     read-only, skipped if the path is absent);
   - how to check it from inside (`podman images` shows the host images as read-only, or
     `podman info --format '{{json .Store.GraphOptions.additionalImageStores}}'`).
   - Commands first, with a link to the reference doc for the why.
5. **`exampleRunClaude.sh`.** Pass `NESTED_PODMAN_HOST_IMAGESTORE=$HOME/.local/share/containers/storage`
   explicitly on the `make shell` line, with a header-comment entry beside `NESTED_PODMAN_TMPFS_SIZE`
   saying what it is and that it's the default (shown so a fork sees the knob).
6. **Reference docs and CLAUDE.md.** Update `CLAUDE.md` (the "Nested Podman" note that says
   `storage.conf` must live at `/etc/containers/storage.conf`), `tasks/reference/nested-podman-design.md` and
   `tasks/reference/image-build-and-storage-pipeline.md`, and the copy of the design doc baked into
   the runCrush client (see the sibling task). Also check
   `tasks/reference/nested-run-and-gates.md` for any claim that nested builds reuse the host's layers.
7. **Verify.**
   - Rebuild the sandbox image on the host. Only the maintainer can do this, since the sandbox
     doesn't rebuild itself.
   - Relaunch with `NESTED_PODMAN=1`. From inside, `podman images` lists the host images as
     read-only, and `make -C <a project> image` reuses cached host layers (no long first step).
   - Confirm the shell.sh warning fires when the store is ignored (simulate it with
     `CONTAINERS_STORAGE_CONF` pointed at a config without the store) and stays silent when it
     is used.

## Open questions

1. What should `exampleRunClaude.sh` "use"? This task reads the instruction as "show the host
   image-store reuse explicitly" (step 5). If the maintainer instead wants the launcher to carry
   the fix itself (for example `-e CONTAINERS_STORAGE_CONF=…` in `EXTRA_PODMAN_FLAGS`, like the
   existing `BUILDAH_ISOLATION=chroot`), step 2 moves out of the image and into the example.
   Recommendation: fix it in the image, so every launch gets it, and only document the knob in
   the example.
