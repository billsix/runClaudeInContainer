# Rethink nested-podman inner storage: RAM tmpfs vs a disk directory (+ reuse host images)

**Status:** proposed — investigation + recommendation (needs go-ahead to implement). **Actively
reconsidered by the maintainer 2026-09-27** (William Emerison Six <billsix@gmail.com>): "I'm
questioning whether I want the container files to be in tmpfs ram backed … it can cause RAM filling
up … perhaps use the default podman container storage? or store them in a folder deleted at session
end, like how runCrush cleans up its networking files. Research the tradeoffs, log them in a task."
**Priority:** 3 (was 5 — the maintainer raised it by asking)
**Difficulty:** 6
**Created:** 2026-07-06; reconsideration + options added 2026-09-27.
**See also:** `tasks/reference/nested-podman-design.md` ("The store is RAM", "Open thread"),
`tasks/decouple-minimal-image-from-nested-podman.md` (the naming half of this reconsideration — a
disk store makes the lean-image idea optional rather than forced, and both hinge on decoupling
`NESTED_PODMAN`'s meanings).

**Motivation:** the nested-podman inner store `/var/lib/containers` is currently a **RAM-backed tmpfs**
(default 8g, `NESTED_PODMAN_TMPFS_SIZE`). Large inner image builds overflow it: on 2026-07-06 a nested
`make image` for an OpenStax book (Fedora + **TeX Live**, ~6 GB image) failed with
`write .../texlive/.../*.vf: no space left on device` even at `NESTED_PODMAN_TMPFS_SIZE=16g` once a
prior ~6 GB image was already resident. Second data point (2026-08-19): building the
runCrushInContainer client image (a 22.3 GB full-toolchain rootfs) completed the `dnf install` but
failed at the *layer commit* with `no space left on device` in a 32g tmpfs — commit peak
(base+diff+temp) exceeds the final image size; a `mount -o remount,size=50g /var/lib/containers`
unblocked it. RAM is the scarce resource; disk is plentiful. Investigate
backing the inner store with a **host directory (bind mount)** instead of tmpfs.

## Why it is a tmpfs today (the answer to "I'm not sure why I made that decision")

It was **not** an arbitrary default. Leaving `/var/lib/containers` as a plain directory on the
sandbox's own root filesystem fails: the sandbox rootfs is itself an **overlay** mount (the image
layers), and the inner podman's `fuse-overlayfs` layered on top is **overlay-on-overlay under a
nested userns, which the kernel rejects** (`nested-podman-design.md`, the tmpfs row). A tmpfs is a
*real* filesystem, so fuse-overlayfs runs on it cleanly — that is the actual reason tmpfs was chosen,
not laziness. The key realization for this task: **a host *directory* bind-mounted from the host's
real disk fs (ext4/xfs) is ALSO a real filesystem**, so it sidesteps overlay-on-overlay exactly like
tmpfs does — but disk-backed, so no RAM ceiling. (The one thing that does *not* work is pointing the
inner store at the host's **default podman overlay store** directly — that is overlay-on-overlay
again. "Default podman container storage" has to mean a plain dir on disk, not the host's overlay
graphroot.)

## The three options the maintainer named, with tradeoffs (2026-09-27)

| Option | RAM ceiling? | Persists across sessions? | Build speed | Main risks |
|---|---|---|---|---|
| **A. tmpfs RAM store (today)** | **Yes** — fills RAM, OOMs on big/commit | No (ephemeral) | Fastest (RAM) | RAM contention with the host; big images fail; must re-pull/rebuild every session |
| **B. persistent host dir** (`-v /big/disk:/var/lib/containers:Z`) | No | **Yes** | Slower than RAM, fine in practice | rootless UID-shift ownership on the host dir; accumulates → needs `podman system prune`; "one sandbox per dir" locking; a stale/corrupt store survives |
| **C. ephemeral host dir, deleted at session end** (a temp dir + a trap `rm -rf`, mirroring runCrush's network-file cleanup) | No | No (by design) | Slower than RAM; re-pull each session | rootless ownership + cleanup reliability (a killed session leaks the dir); no cross-session reuse |

**Fourth, orthogonal, and probably the highest-value piece — reuse host-built images read-only.**
Podman's **`additionalimagestores`** lets the nested podman mount the *host's* image store **read-only**
and reuse its images without copying — directly answering "speed up build times, especially when I've
built the image outside of the project." It is not a writable cache and not a dir of tarballs: it must
point at a real containers/storage image store, exposed world-readable, and the writable container
layer stays separate (options A–C still choose *where the writable layer lives*). So the likely design
is **(B or C) for the writable layer + `additionalimagestores` pointing at the host store for reuse.**
Online confirmation (2026): Red Hat "Exploring additional image stores in Podman"; rootless overlay +
fuse-overlayfs ownership via xattrs.

## Recommendation (my read — for the maintainer to decide)

**Default to option C (ephemeral disk dir) + `additionalimagestores` read-only from the host store**,
keep tmpfs available behind `NESTED_PODMAN_TMPFS_SIZE` for the rare all-RAM-speed case. Rationale:
C removes the RAM ceiling and the OOM-at-commit class of failures (the whole reason big books/clients
needed `remount,size=50g`), matches the maintainer's own "cleaned up at session end like the network
files" instinct, and — via `additionalimagestores` — reuses host-built images so a nested `make image`
is fast and a pre-built base need not be re-pulled. Persistent (B) is the alternative if cross-session
image caching matters more than a clean slate; its cost is prune hygiene + ownership drift. **This
would make the lean-image standard *optional* (a big image now fits on disk), not a nested necessity —
so pair this decision with `tasks/decouple-minimal-image-from-nested-podman.md`.**

## Goal

Determine what it takes to optionally mount a **host directory** at the inner `/var/lib/containers`
(disk-backed, large, optionally persistent) as an alternative to the RAM tmpfs — and whether it's
worth it. Deliver a findings + recommendation (and, if greenlit, a `Makefile` option like
`NESTED_PODMAN_STORAGE_DIR=/path` that swaps the tmpfs for a `-v` mount).

## What to investigate

1. **Mechanics.** Today the `shell` target adds a tmpfs at `/var/lib/containers` (see
   `NESTED_PODMAN_FLAGS` / CLAUDE.md "Nested Podman"). Replace/augment with
   `-v $(NESTED_PODMAN_STORAGE_DIR):/var/lib/containers:Z` when the var is set (mutually exclusive with
   the tmpfs). Keep the tmpfs the default; the dir mount opt-in. Follow the existing conditional-mount
   idiom (`readlink -f` + existence test, `:Z`).
2. **Rootless UID mapping.** Host podman is rootless (container-root ↔ host UID 1000). A host dir
   bind-mounted in must be writable by the mapped user, and files written by the inner (rootful-in-
   userns) podman will land with shifted ownership on the host. Check `:Z` SELinux relabel + whether
   `:U` (chown to mapped uid) is needed, and whether ownership on the host dir gets mangled.
3. **fuse-overlayfs on a bind mount.** The inner store uses `fuse-overlayfs` (per
   `entrypoint/dotfiles/.config/containers/storage.conf`). Confirm overlayfs-on-overlayfs / fuse works
   when the lower dir is a host bind mount (it did on tmpfs; a real fs may behave differently —
   underlying fs must support the xattrs overlay needs; test on the host's actual fs, e.g. ext4/xfs/
   btrfs — btrfs has had overlayfs quirks).
4. **Persistence trade-off.** A disk dir **persists images across sessions** — pro: no re-pull/re-build
   of the TeX Live image every session (huge time saver). Con: it accumulates (needs periodic
   `podman system prune`), and a stale/corrupt store survives. Decide default hygiene (document, or a
   `make` clean target).
5. **Performance.** tmpfs (RAM) is fast; disk is slower. Quantify the hit for a representative build
   (TeX Live image + a nested `make pdf`). Likely acceptable given the alternative is OOM/failure.
6. **Concurrency / locking.** If two sandboxes point at the same storage dir, podman's locks/`c/storage`
   assume exclusive access — document "one sandbox per storage dir" or namespace by sandbox.
7. **Interaction with `--cgroups=disabled`, netavark, the `libpod` tmpfs shadow.** The storage dir
   change is orthogonal to those, but confirm nothing in the nested-podman flag set assumes tmpfs.

## Acceptance (for the eventual implementation)

- `make shell NESTED_PODMAN=1 NESTED_PODMAN_STORAGE_DIR=/big/disk/store` mounts that dir at the inner
  `/var/lib/containers`, and a nested `make image` of a TeX-Live-sized book **succeeds** where the
  tmpfs OOM'd, with images **persisting** to the next session.
- Default behavior (no var set) is unchanged (RAM tmpfs).
- Documented in CLAUDE.md "Nested Podman" with the RAM-vs-disk trade-off and the ownership/`:Z`/prune
  caveats.

## Notes

- Relates to CLAUDE.md "Nested Podman" (tmpfs default 8g, RAM-backed) and `tasks/nested-podman.md`
  (the original nested-podman design). This is a storage-backend variant of that work.
- Cheapest interim workaround already in use: bump `NESTED_PODMAN_TMPFS_SIZE` and `podman rmi`/`system
  prune` between big builds — but that's RAM-bound and manual; a disk dir removes the ceiling.
