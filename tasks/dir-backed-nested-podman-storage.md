# Investigate: disk-directory-backed nested-podman storage (vs the RAM tmpfs)

**Status:** proposed — investigation only (needs go-ahead to implement)
**Created:** 2026-07-06
**Motivation:** the nested-podman inner store `/var/lib/containers` is currently a **RAM-backed tmpfs**
(default 8g, `NESTED_PODMAN_TMPFS_SIZE`). Large inner image builds overflow it: on 2026-07-06 a nested
`make image` for an OpenStax book (Fedora + **TeX Live**, ~6 GB image) failed with
`write .../texlive/.../*.vf: no space left on device` even at `NESTED_PODMAN_TMPFS_SIZE=16g` once a
prior ~6 GB image was already resident. RAM is the scarce resource; disk is plentiful. Investigate
backing the inner store with a **host directory (bind mount)** instead of tmpfs.

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
