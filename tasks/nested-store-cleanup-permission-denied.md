# Nested `dir`-store cleanup failed with "Permission denied" and leaked the store dir

**Done 2026-11-08** (William Emerison Six <billsix@gmail.com>). Fix `d339fad` (2026-10-02); cleanup
log added 2026-10-04; verified from 11 clean post-fix host exits.
**See also:** `tasks/reference/nested-podman-design.md` (the trap bullet holds the mechanism, the
log format and the fallback ranking); `tasks/archive/2026/09/27/dir-backed-nested-podman-storage.md`
(the task that introduced the ephemeral `dir` store and this trap); the runCrush twin
`runCrushInContainer/tasks/nested-store-cleanup-permission-denied.md` (same fix in `client/Makefile`).

## Problem

On exit from a `make shell NESTED_PODMAN=1` session with the disk-backed store, the host-side trap
`rm -rf "$STORE"` printed a wall of `rm: cannot remove '…/storage/overlay/<layer>/diff/<dir>':
Permission denied` and left the `runclaude-nested.*` dir behind under `NESTED_PODMAN_STORE_BASE`, on
every normal exit. Five leaked dirs had accumulated between 2026-09-27 and 2026-10-02.

## Root cause

The `mktemp`, the `trap` and the `rm` run on the **host** as the unprivileged user; the inner
**rootful** podman writes the store through the sandbox's user namespace. Rootless podman maps
container uid 0 to the host user and other uids to the subuid range, and extracted layers keep the
image's modes: each layer's `diff/` mirrors the image's `/` (555 on Fedora) and `/root` (550). GNU
`rm` never `chmod`s, so even as owner it could not unlink direct children of a 555/550 dir. A
pre-fix leftover inspected 2026-10-04 (`runclaude-nested.X5tCAd`, 88 KB) held only the empty
top-level dirs inside 555 `diff/` parents, which pinned the blocker to the directory write bit rather
than to subuid ownership.

## Fix

All four recipe blocks (runClaude `Makefile` `shell` + `shell-exec`, runCrush `client/Makefile`
`shell` + `shell-exec`) clean with `$(CONTAINER_CMD) unshare rm -rf "$$STORE"`. Inside podman's
rootless user namespace the host user is root with `CAP_DAC_OVERRIDE`, which bypasses the write bits
and owns the whole subuid range. On 2026-10-04 the trap also gained an append-only log at
`$(NESTED_PODMAN_STORE_BASE)/<prefix>-nested-cleanup.log` (outside the store, so it survives the `rm`)
recording the store name, `rm`'s exit status, and `== clean` or `== LEFTOVER: <path>`.

`make` reads the recipe at launch, so only sessions launched after a trap change exercise it. The
2026-10-04 exit that still printed errors was the `X5tCAd` session, launched before `d339fad`, and
was not evidence against the fix.

## Evidence ledger

| When (local) | Store | Trap | Exit result | Source |
|---|---|---|---|---|
| 2026-09-27 … 2026-10-02 | 4 × `runclaude-nested.*` | pre-fix | leaked | `ls` of the base dir; removed in-session 2026-10-02 |
| 2026-10-02 → 2026-10-04 10:33 | `X5tCAd` | pre-fix | leaked; 9 `Permission denied` lines, 88 KB left | maintainer's pasted exit log; in-sandbox inspection |
| 2026-10-04 10:58 → ? | `wmIfwl` | post-fix, unlogged | no leftover dir as of 2026-11-08; exit output not captured | `ls` of the base dir 2026-11-08 |
| 2026-10-04 16:14 … 2026-11-08 12:20 | 11 stores (`uLRZiY`, `Q7EMVn`, `7NLNBY`, `Fd5jcT`, `4C8BVO`, `yAKm2Z`, `MhzWhb`, `TKi3ZN`, `GTqBmD`, `Qvg8vS`, `8axMry`) | post-fix, logged | every one `rm exit=0`, `== clean` | `/mnt/sda1/tmpContainerStorage/runclaude-nested-cleanup.log`, read 2026-11-08 |

The only `runclaude-nested.*` dirs present on 2026-11-08 were the running session's store and the
pre-fix `X5tCAd` leftover.

## Verification

- [x] Dry run (`make -n shell NESTED_PODMAN=1`) in both sandboxes emitted the `podman unshare` trap
  (2026-10-02) and, after the log change, the logging trap (2026-10-04).
- [x] Host: sessions launched after `d339fad` exited with `rm exit=0` and no leftover dir (11 logged
  exits, read 2026-11-08).
