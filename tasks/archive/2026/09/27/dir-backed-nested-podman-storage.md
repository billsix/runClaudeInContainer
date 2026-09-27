# Nested-podman inner storage: RAM tmpfs → disk directory (+ reuse host images)

## BLUF — COMPLETE, both sandboxes verified end-to-end (2026-09-27)

The nested-podman inner image store (`/var/lib/containers`) moved from a **RAM-backed tmpfs** — which
filled RAM and OOM'd on big images and at layer-commit — to an **ephemeral on-disk directory**, plus
read-only **reuse of the host's image store** (`additionalimagestores`) so nested builds no longer
re-pull images built outside the project. The change shipped identically in **both sandboxes**
(`runClaudeInContainer/` and `runCrushInContainer/client/`) and both were verified end-to-end from
inside a relaunched session. The RAM tmpfs remains available as an opt-in (`NESTED_PODMAN_STORE=tmpfs`).

**Status:** COMPLETE 2026-09-27. Both sandboxes fully verified in-session: the store is on a host disk
(not tmpfs), the baked `/etc/containers/storage.conf` is read by the rootful nested podman, host-built
images are reused read-only, a `FROM` a host image builds without pulling, and a forced ~20 GB layer
committed cleanly with no `no space left on device` — the OOM-at-commit class that motivated the task
is retired. One image-reuse bug was found and fixed mid-task (rootful podman ignored the rootless-path
`storage.conf`; both Dockerfiles now `COPY` it to `/etc/containers/storage.conf`), and the `mktemp`
store trap gained `HUP` so a terminal/SSH-drop cannot leak the throwaway dir. Confirmed mechanics were
folded into `tasks/reference/nested-podman-design.md`.
**Priority:** 3 (raised from 5 when the maintainer asked for it). **Difficulty:** 6.
**Created:** 2026-07-06; reconsidered, decided, implemented and verified 2026-09-27.
**See also:** `tasks/reference/nested-podman-design.md` ("Store backend"); the naming half of this
reconsideration, `tasks/decouple-minimal-image-from-nested-podman.md` (renamed `NESTED_PODMAN`'s
image-content meaning to an opt-in `MINIMAL_IMAGE` — a disk store made the lean image optional rather
than a nested necessity), which was done immediately after this and is likewise archived under
`tasks/archive/2026/09/27/`.

## Background — why it OOM'd, and why the store was a tmpfs

The inner store was a **RAM-backed tmpfs** (default 8 g, `NESTED_PODMAN_TMPFS_SIZE`), and large inner
builds overflowed it. Two data points drove the change:
- **2026-07-06:** a nested `make image` for an OpenStax book (Fedora + TeX Live, ~6 GB image) failed
  with `write .../texlive/.../*.vf: no space left on device` even at `NESTED_PODMAN_TMPFS_SIZE=16g`
  once a prior ~6 GB image was already resident.
- **2026-08-19:** building the runCrushInContainer client image (a 22.3 GB full-toolchain rootfs)
  finished the `dnf install` but failed at the *layer commit* with `no space left on device` in a 32 g
  tmpfs — the commit peak (base + diff + temp) exceeds the final image size; a
  `mount -o remount,size=50g /var/lib/containers` unblocked it.

RAM was the scarce resource; disk was plentiful. The store was a tmpfs for a real reason, not laziness:
leaving `/var/lib/containers` as a plain directory on the sandbox's own rootfs fails, because that
rootfs is itself an **overlay** mount (the image layers), and the inner podman's `fuse-overlayfs`
layered on top is **overlay-on-overlay under a nested userns, which the kernel rejects**. A tmpfs is a
*real* filesystem, so fuse-overlayfs runs on it cleanly. The key realization for this task was that a
host **directory** bind-mounted from the host's real disk fs (ext4/xfs/btrfs) is **also** a real
filesystem, so it sidesteps overlay-on-overlay exactly like tmpfs — but disk-backed, with no RAM
ceiling. (Pointing the inner store at the host's own overlay graphroot does *not* work — that is
overlay-on-overlay again; the disk store has to be a plain dir on disk.)

## The options considered, and the decision

| Option | RAM ceiling? | Persists across sessions? | Build speed | Main risks |
|---|---|---|---|---|
| **A. tmpfs RAM store (the old default)** | **Yes** — fills RAM, OOMs on big/commit | No (ephemeral) | Fastest (RAM) | RAM contention with the host; big images fail; re-pull/rebuild every session |
| **B. persistent host dir** (`-v /big/disk:/var/lib/containers:Z`) | No | **Yes** | Slower than RAM, fine in practice | rootless UID-shift ownership; accumulates → needs `podman system prune`; one-sandbox-per-dir locking; a stale/corrupt store survives |
| **C. ephemeral host dir, deleted at session end** (a temp dir + a `trap rm -rf`, mirroring runCrush's network-file cleanup) | No | No (by design) | Slower than RAM; re-pull each session | rootless ownership + cleanup reliability (a killed session leaks the dir); no cross-session reuse |

A fourth, orthogonal piece proved the highest-value: **reusing host-built images read-only** via
podman's `additionalimagestores`, which mounts the *host's* image store read-only and reuses its
images without copying — directly answering "speed up build times, especially when I've built the image
outside the project." It is not a writable cache and not a dir of tarballs: it must point at a real
containers/storage image store, and the writable container layer stays separate (options A–C still
choose *where the writable layer lives*).

**Decision (2026-09-27, William Emerison Six <billsix@gmail.com>): option C + `additionalimagestores`.**
Option C (ephemeral disk dir, `rm`'d at session end) for the writable layer, plus `additionalimagestores`
mounting the host image store read-only for reuse; the tmpfs kept behind `NESTED_PODMAN_STORE=tmpfs` for
the rare all-RAM-speed case. Rationale: C removed the RAM ceiling and the OOM-at-commit failure class
(the reason big books/clients needed `remount,size=50g`), matched the maintainer's "cleaned up at
session end like the network files" instinct, and — via `additionalimagestores` — reused host-built
images so a nested `make image` was fast and a pre-built base need not be re-pulled. The maintainer also
directed "land the disk-store change first" (before the `NESTED_PODMAN`→`MINIMAL_IMAGE` rename) and
"also runCrush". This made the lean-image standard *optional* (a big image now fits on disk) rather than
a nested necessity — the pairing with `decouple-minimal-image-from-nested-podman.md`.

## What was implemented (both sandboxes, identical)

- **`Makefile`:** new `NESTED_PODMAN_STORE` (default **`dir`** = ephemeral disk dir; `tmpfs` selects the
  old RAM store), `NESTED_PODMAN_STORE_BASE` (default `$(HOME)/.cache`; relocatable per launch, e.g. to
  an HDD to spare an SSD), and `NESTED_PODMAN_HOST_IMAGESTORE` (default
  `$(HOME)/.local/share/containers/storage`). The old `--tmpfs /var/lib/containers` line became
  `$(NESTED_PODMAN_STORE_FLAG)` (set only in tmpfs mode) plus `$(NESTED_PODMAN_IMAGESTORE_MOUNT)` (a
  read-only `-v <hoststore>:/var/lib/shared-images:ro`, emitted only when the host path exists). In
  `dir` mode, `shell` and `shell-exec` gained an inline prelude that `mktemp -d`s a fresh store dir
  under `STORE_BASE`, binds it at the inner `/var/lib/containers`, and `trap`s `rm -rf` on
  `EXIT INT TERM HUP` (HUP added this session so a terminal/SSH-drop cannot leak the dir; only `SIGKILL`
  still can).
- **`storage.conf`:** added `[storage.options] additionalimagestores = [ "/var/lib/shared-images" ]`
  (a missing path is tolerated), keeping `mount_program = /usr/bin/fuse-overlayfs`.
- **Dockerfile (the mid-task fix):** each Dockerfile now also
  `COPY`s `entrypoint/dotfiles/.config/containers/storage.conf` to `/etc/containers/storage.conf`. The
  nested podman runs **rootful** (`rootless=false`, graphroot `/var/lib/containers/storage`), so it
  reads `/etc/containers/storage.conf`, **not** the rootless `~/.config/containers/storage.conf` that
  the dotfiles delivered — without the `/etc` copy, `additionalimagestores` (and `mount_program`) were
  silently ignored and `podman images` was empty. This is the general rule for rootful-in-userns nested
  podman: rootless config paths do not apply.
- **Docs:** the always-read docs that had asserted the RAM tmpfs was the *default* were corrected to say
  the on-disk dir is the default and RAM is opt-in (runClaude `nested-podman-design.md`,
  `nested-run-and-gates.md`, `minimal-nested-images.md`, `sandbox-capability-map.md`; runCrush
  `architecture.md`, `nested-podman-vs-image-content.md`, `nested-podman-design.md` + its baked twin,
  and the baked `sandbox-capability-map.md`). The confirmed mechanics (ownership,
  fuse-overlayfs-on-a-disk-dir, the reuse chain) were folded into `nested-podman-design.md`'s "Store
  backend" section (runClaude) and the disk-store bullet under "Operating it" (both runCrush copies). A
  new `tasks/reference/image-build-and-storage-pipeline.md` documents the two podman levels and where
  every image layer lands. `CLAUDE.md` and `README.md` in both repos gained the disk-store note.

## How it was verified

**From inside, dry (all three modes passed):** `make -n shell` in `dir` mode (mktemp + trap, `-v $STORE`,
no `--tmpfs`), `tmpfs` mode (`--tmpfs …`, no mktemp), and `NESTED_PODMAN=0` (no nested flags at all — the
host run is byte-identical). The one-flag fallback to the old behaviour is
`make shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=tmpfs`.

**Live, after the maintainer rebuilt and relaunched (the parts that can only be checked from the host
launch — fuse-overlayfs on a disk dir, the reuse actually working, ownership, cleanup):**
- **runClaude:** `df -T /var/lib/containers` reported a host fs (not tmpfs); `podman info` read
  `/etc/containers/storage.conf` with `overlay.additionalImageStores`/`imagestore` resolving to
  `/var/lib/shared-images` and `mount_program = fuse-overlayfs`; `podman images` listed the host-built
  images (`smc`, `claudecontainer`, `crushcontainer`, gacalc, osbooks bundles, …) read-only; and a
  `FROM localhost/smc:latest` build committed a layer with no pull. The image-reuse bug above was found
  here (empty `podman images`, default additional store) and fixed. The host store (~655 images) was
  readable by the mapped root uid as-is, so no world-readable chmod was needed.
- **runCrush:** the same in-session check passed on every point (store on `ext4` disk not tmpfs,
  `/var/lib/shared-images` read-only, host images read-only, `FROM localhost/crushcontainer:latest`
  with no pull). A **forced ~20 GB fresh layer** was then built nested (a 46 GB image; `Containerfile` =
  `FROM crushcontainer` + a 20 GB `dd` of `/dev/urandom`) and **committed cleanly with no
  `no space left on device`** — a faithful reproduction of the original OOM, now passing on 400+ GB of
  disk.

**Durable in-session check** (so a future session need not re-derive it), run from inside a relaunched
sandbox:

```sh
df -T /var/lib/containers | tail -1        # TYPE must be the host fs (ext4/xfs/btrfs), NOT tmpfs
mount | grep ' /var/lib/shared-images '    # present + 'ro' iff the host store was mounted for reuse
podman info --format '{{.Store.GraphRoot}} {{.Store.GraphDriverName}}'   # overlay via fuse-overlayfs
grep -c additionalimagestores /etc/containers/storage.conf ~/.config/containers/storage.conf 2>/dev/null
```

A `tmpfs` type at the first line means the relaunch still used the old store (change not picked up, or
`NESTED_PODMAN_STORE=tmpfs`); a host-fs type means the disk store is live.

**Known risks that were checked and cleared:** (a) host-store readability for the mapped UID — fine as-is;
(b) mounting the host store read-only into a sandbox podman itself launched from — no lock/consistency
problems observed; (c) fuse-overlayfs xattrs on the host fs — worked on both btrfs and ext4. The
remaining leak path is a hard `SIGKILL` of the launch (mitigated by the `HUP` trap addition and, if
needed, `rm -rf ~/.cache/*-nested.*`).

## Sources (online research, 2026-09-27)

- Red Hat — [Exploring additional image stores in Podman](https://www.redhat.com/en/blog/image-stores-podman)
  (read-only additional stores for image reuse; not a writable cache, not a dir of tarballs).
- Red Hat — [Podman is gaining rootless overlay support](https://www.redhat.com/sysadmin/podman-rootless-overlay)
  (fuse-overlayfs xattr-based UID/GID mapping for rootless storage).
- OneUptime — [How to Configure Additional Image Stores in Podman](https://oneuptime.com/blog/post/2026-03-18-configure-additional-image-stores-podman/view)
  and [How to Configure Storage Options for Rootless Podman](https://oneuptime.com/blog/post/2026-03-18-configure-storage-options-rootless-podman/view).
- Red Hat — [How to use Podman inside of a container](https://www.redhat.com/en/blog/podman-inside-container)
  and containers/podman issue [#15419 — nested rootless containers](https://github.com/containers/podman/issues/15419)
  (the overlay-on-overlay-under-nested-userns constraint that makes a *real* fs — tmpfs or a disk dir —
  necessary for the inner store).
