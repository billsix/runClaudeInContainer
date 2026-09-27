# Rethink nested-podman inner storage: RAM tmpfs vs a disk directory (+ reuse host images)

## UPDATE 2026-09-27 — verified in-session, one bug found and FIXED (read first)

The maintainer relaunched both sandboxes with the disk store and started a session inside.
In-session verification (from inside `runClaudeInContainer`):

- **Disk store: WORKS.** `df -T /var/lib/containers` → `btrfs` on `/dev/nvme0n1p3` (a real host
  disk fs, **not tmpfs**); `podman info` store driver `overlay`; a throwaway `FROM scratch` build
  committed to the store cleanly. RAM ceiling / OOM-at-commit class is gone, and btrfs (the fs the
  risks list flagged) is fine.
- **Image reuse via `additionalimagestores`: was BROKEN, now FIXED.** `podman images` was **empty**
  and podman's effective additional store was the *default* `/usr/lib/containers/storage` — our
  `/var/lib/shared-images` was ignored. **Root cause:** the nested podman runs **ROOTFUL**
  (`rootless=false`, graphroot `/var/lib/containers/storage`), so it reads
  `/etc/containers/storage.conf` — but `storage.conf` was delivered only to the **rootless** path
  `~/.config/containers/storage.conf` (via `COPY entrypoint/dotfiles/ /root/`), which rootful podman
  never reads. (`/etc/containers/storage.conf` did not exist; readability of the host store was NOT
  the problem — the store is populated with ~655 images incl. `fedora:44` and is readable by the
  mapped root uid.)
- **Fix (applied, both sandboxes):** each Dockerfile now also
  `COPY entrypoint/dotfiles/.config/containers/storage.conf /etc/containers/storage.conf` so the
  rootful nested podman reads it. Proven live in-session by `cp`-ing the file to `/etc/containers/`
  in the running container: `podman images` then listed every host-built image (`claudecontainer`,
  `smc`, `crushcontainer`, osbooks bundles, …) as **`R/O`**, the effective additional store became
  `/var/lib/shared-images`, `mount_program` became `fuse-overlayfs`, and a `FROM localhost/smc:latest`
  build committed a new layer **without pulling**.
- **DONE for runClaude 2026-09-27:** the maintainer did the `make image` rebuild + relaunch, and a
  fresh in-session check confirmed the baked `/etc` COPY took effect — `podman info` reads
  `/etc/containers/storage.conf`, `additionalimagestores`/`imagestore` resolve to
  `/var/lib/shared-images`, host-built images list **read-only**, and `FROM localhost/smc:latest`
  builds without pulling. The writable store is the ephemeral `mktemp` dir on btrfs (relocatable via
  `NESTED_PODMAN_STORE_BASE`), cleaned by an `EXIT INT TERM HUP` trap (HUP added this session).
  **runClaude is fully verified end-to-end.**
- **DONE for runCrush 2026-09-27:** the maintainer rebuilt + relaunched the client with the disk
  store; the in-session check passed on every point (store on `ext4` disk not tmpfs,
  `/var/lib/shared-images` mounted read-only, host-built images `crushcontainer`/`claudecontainer`/`smc`
  read-only, a `FROM localhost/crushcontainer:latest` build with no pull). A **forced ~20 GB fresh
  layer** was then built nested (a 46 GB image, `Containerfile` = `FROM crushcontainer` + a 20 GB
  `dd` of `/dev/urandom`) and **committed cleanly to the disk store with no `no space left on device`**
  — the exact tmpfs OOM-at-commit failure that motivated the task, now retired. **Both sandboxes fully
  verified end-to-end.**
- **Doc reconciliation — flat "default = RAM" claims FIXED 2026-09-27; deep mechanics fold DONE
  2026-09-27.** Every always-read doc that asserted the RAM tmpfs was the *default* was corrected to
  say the on-disk dir is the default and RAM is opt-in: runClaude `nested-podman-design.md` (the
  `--tmpfs` table row + "The store is RAM" section), `nested-run-and-gates.md` (RAM-pressure advice
  now scoped to tmpfs mode), `minimal-nested-images.md`, `sandbox-capability-map.md`; runCrush
  `architecture.md`, `nested-podman-vs-image-content.md`, `nested-podman-design.md` (+ its baked
  twin), and the baked `sandbox-capability-map.md`. **Confirmed mechanics folded in 2026-09-27** (once
  verified, per plan): the positive write-up of ownership, fuse-overlayfs-on-a-disk-dir behavior, and
  the reuse mechanics now live in `nested-podman-design.md`'s "Store backend" section (runClaude) and
  the disk-store bullet under "Operating it" (both runCrush copies), all marked verified in both
  sandboxes.

## BLUF — COMPLETE, both sandboxes verified end-to-end 2026-09-27 (read first)

The nested inner image store (`/var/lib/containers`) moved from a **RAM-backed tmpfs** (which filled
RAM and OOM'd on big images / at layer-commit) to an **ephemeral on-disk directory**, plus read-only
**reuse of the host's image store** so nested builds don't re-pull images built outside the project.
Implemented identically in **both sandboxes** (`runClaudeInContainer/` and
`runCrushInContainer/client/`). Decided by the maintainer 2026-09-27: option **C + additionalimagestores**;
"land the disk-store change first" (before the `NESTED_PODMAN`→`MINIMAL_IMAGE` rename), "also runCrush".

**What changed (both sandboxes, identical):**
- **`Makefile`:** new `NESTED_PODMAN_STORE` (default **`dir`** = ephemeral disk dir; `tmpfs` = old RAM
  store), `NESTED_PODMAN_STORE_BASE` (`$(HOME)/.cache`), `NESTED_PODMAN_HOST_IMAGESTORE`
  (`$(HOME)/.local/share/containers/storage`). `shell`/`shell-exec` `mktemp -d` a fresh store, bind it
  at the inner `/var/lib/containers`, and `trap 'rm -rf' EXIT INT TERM`. The old `--tmpfs` line became
  `$(NESTED_PODMAN_STORE_FLAG)` (tmpfs mode only) + a read-only `-v <hoststore>:/var/lib/shared-images:ro`
  (emitted only if the host path exists).
- **`storage.conf`:** `additionalimagestores = [ "/var/lib/shared-images" ]` (missing path tolerated).

**Verified from inside (all pass):** `make -n shell` in all three modes — `dir` (mktemp+trap, `-v $STORE`,
no `--tmpfs`), `tmpfs` (`--tmpfs`, no mktemp), `NESTED_PODMAN=0` (no nested flags → host byte-identical).
Fallback to the old behavior is one flag: `make shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=tmpfs`.

**NOT verifiable from inside** (it's the outer host launch): fuse-overlayfs on the disk dir, the
additionalimagestores reuse actually working, rootless ownership of the read-only host store, and
cleanup-on-exit. → **Run the "## Verification" § host test on the host before trusting it.** Known risks
are listed there (host-store readability for the mapped UID; mounting the store into a sandbox launched
from it; fuse-overlayfs xattrs on the host fs).

**In-session check** (a NEW session after relaunch): the "## Verification" § has the exact commands the
agent runs from inside to confirm the store is on disk (`df -T /var/lib/containers` → host fs, not tmpfs)
and the host store is mounted for reuse.

**Remaining (design decided, not started — needs go-ahead):** the fleet-wide
`NESTED_PODMAN`→`MINIMAL_IMAGE` rename, sequenced AFTER this disk-store change is host-verified
(`tasks/decouple-minimal-image-from-nested-podman.md`).

---

**Status:** COMPLETE — **both sandboxes FULLY VERIFIED end-to-end 2026-09-27** (rebuild + relaunch +
in-session check all green in each: disk store on a host disk not tmpfs, `/etc` COPY effective, host
images reused read-only, `FROM` a host image builds without pulling, and a forced ~20 GB layer commits
with no `no space left on device` — the OOM-at-commit class is retired). Image reuse had been found
broken (rootful podman ignored the rootless-path `storage.conf`) and **fixed** — both Dockerfiles now
`COPY` the store config to `/etc/containers/storage.conf`; the `mktemp` store trap gained `HUP` so a
terminal/SSH-drop can't leak it. Confirmed mechanics are folded into the reference docs. Ready to
archive. See the "## UPDATE 2026-09-27" block above.
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

## Decision (2026-09-27, William Emerison Six <billsix@gmail.com>): option C + additionalimagestores

**Chosen: option C (ephemeral disk dir, `rm`'d at session end) for the writable layer, PLUS
`additionalimagestores` mounting the host image store READ-ONLY so nested builds reuse images built
outside the project without copying.** Keep the tmpfs available behind `NESTED_PODMAN_TMPFS_SIZE` for
the rare all-RAM-speed case. Rationale: C removes the RAM ceiling and the OOM-at-commit class of
failures (the whole reason big books/clients needed `remount,size=50g`), matches the maintainer's own
"cleaned up at session end like the network files" instinct, and — via `additionalimagestores` —
reuses host-built images so a nested `make image` is fast and a pre-built base need not be re-pulled.
**This makes the lean-image standard *optional* (a big image now fits on disk), not a nested
necessity — paired with `tasks/decouple-minimal-image-from-nested-podman.md`.** Implementation still
needs a go-ahead; the mechanics/verification checklist below ("What to investigate", "Acceptance")
stands, now scoped to C + additionalimagestores rather than an open A/B/C question.

**Implementation notes for C + additionalimagestores (research findings):**
- `additionalimagestores` must point at a real containers/storage image store (not a dir of tarballs),
  exposed **world-readable**, and is **read-only** — the writable container/layer stays in the option-C
  ephemeral dir. Set both in the inner `storage.conf`
  (`entrypoint/dotfiles/.config/containers/storage.conf`): `additionalimagestores = ["<host store>"]`
  under `[storage.options]`, keeping `mount_program = /usr/bin/fuse-overlayfs`.
- The host's rootless store is typically `~/.local/share/containers/storage`; bind-mount it read-only
  into the sandbox and point `additionalimagestores` at it. Rootless ownership crosses via
  fuse-overlayfs xattrs (UID/GID shift) — verify the mapped user can read it.
- Ephemeral dir: a `mktemp -d` (on disk, not tmpfs) bind-mounted at the inner `/var/lib/containers`,
  removed by an EXIT/cleanup trap — the same shape as the existing network-file cleanup. A killed
  session leaks the dir; document a `make` clean target or a boot-time sweep of the temp root.

## What was implemented (2026-09-27) — both sandboxes

Identical change in `runClaudeInContainer/` and `runCrushInContainer/client/`:

- **`Makefile`:** new vars `NESTED_PODMAN_STORE` (default `dir`; `tmpfs` selects the old RAM store),
  `NESTED_PODMAN_STORE_BASE` (default `$(HOME)/.cache`), `NESTED_PODMAN_HOST_IMAGESTORE` (default
  `$(HOME)/.local/share/containers/storage`). The old `--tmpfs /var/lib/containers` line became
  `$(NESTED_PODMAN_STORE_FLAG)` (only set in tmpfs mode) plus `$(NESTED_PODMAN_IMAGESTORE_MOUNT)`
  (a read-only `-v <hoststore>:/var/lib/shared-images:ro`, emitted only if the path exists). `shell`
  and `shell-exec` gained an inline prelude: in `dir` mode, `mktemp -d` a fresh store dir under
  `STORE_BASE`, bind it at the inner `/var/lib/containers`, and `trap 'rm -rf' EXIT INT TERM`.
- **`storage.conf`:** added `[storage.options] additionalimagestores = [ "/var/lib/shared-images" ]`
  (read-only host store for image reuse; a missing path is tolerated).
- **Verified from inside (all passed):** `make -n shell` in all three modes — `dir` (mktemp+trap,
  `-v $STORE`, no `--tmpfs`), `tmpfs` (`--tmpfs …`, no mktemp), and `NESTED_PODMAN=0` (no nested
  flags at all — host runs byte-identical). Imagestore mount emits when the path exists.

## Verification

### Host test (maintainer, `[LINUX HOST]`) — do this before trusting it

The core (fuse-overlayfs on a disk dir + `additionalimagestores` reuse + rootless ownership +
cleanup) can only be exercised from the **host**, not from inside a running sandbox.

1. `cd` into `runClaudeInContainer` (then repeat for `runCrushInContainer/client`).
2. `make shell NESTED_PODMAN=1` — it should start normally (dir mode is now the default).
3. **Inside**, confirm the store is on disk, not RAM: `podman info --format '{{.Store.GraphRoot}}'`
   then `df -T /var/lib/containers` — the type should be the host fs (ext4/xfs/btrfs) via the bind,
   **not `tmpfs`**.
4. **Build a large image nested** that used to OOM the tmpfs (e.g. a downstream `make image` for a
   TeX-Live book, or the client image): it should complete without `no space left on device`.
5. **Reuse check:** with a base image already in the host store, a nested `podman images` (or a build
   `FROM` it) should find it via the additional store **without pulling** (`podman images --storage-opt`
   / check it appears read-only). If ownership blocks it, see risks below.
6. **Cleanup check:** exit the shell; the `mktemp` dir under `~/.cache/runclaude-nested.*` (or
   `crush-nested.*`) should be **gone**. (A hard `kill -9` of make may leak it — `rm -rf ~/.cache/*-nested.*`.)
7. Fallback if anything misbehaves: `make shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=tmpfs` restores the
   old RAM store exactly.

**Known risks to watch for (unverified from inside):** (a) the host rootless store is owned by your
user and may not be world-readable — `additionalimagestores` may need it readable by the mapped UID,
or it silently contributes nothing; (b) mounting the host store into a sandbox that podman itself
launched from that same store (read-only) — watch for lock/consistency warnings; (c) fuse-overlayfs
xattr support on the host fs (fine on ext4/xfs; btrfs has had overlay quirks).

### In-session check (a NEW session with the agent, after the maintainer relaunches)

When the maintainer next starts a session **inside a sandbox relaunched with this change**, the agent
can confirm it landed by running, **from inside**:

```sh
df -T /var/lib/containers | tail -1        # TYPE must be the host fs (ext4/xfs/btrfs), NOT tmpfs
mount | grep ' /var/lib/shared-images '    # present + 'ro' iff the host store was mounted for reuse
podman info --format '{{.Store.GraphRoot}} {{.Store.GraphDriverName}}'   # overlay via fuse-overlayfs
grep -c additionalimagestores /etc/containers/storage.conf ~/.config/containers/storage.conf 2>/dev/null
```

`tmpfs` at step 1 means the relaunch still used the old store (change not picked up, or
`NESTED_PODMAN_STORE=tmpfs` was set); a host-fs type means the disk-store change is live. This block
is the durable record so a future session doesn't have to re-derive the check.

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
