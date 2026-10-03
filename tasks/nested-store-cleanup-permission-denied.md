# Nested `dir`-store cleanup fails with "Permission denied" and leaks the store dir

## BLUF — FIXED (2026-10-02); maintainer verifies on next real exit

On exit from a nested-podman `dir`-store session (`make shell NESTED_PODMAN=1`), the
cleanup trap's `rm -rf "$STORE"` printed a wall of `rm: cannot remove '…/storage/overlay/…/diff/…':
Permission denied` and left the store directory behind — so `NESTED_PODMAN_STORE_BASE`
accumulates dead `*-nested.*` dirs instead of being cleaned at session end. The trap runs on
the **host** as the unprivileged user; the inner image-layer `diff/` dirs carry the image's
original **read-only** permissions (`dr-xr-xr-x`, `dr-xr-x---` — no owner write bit) and are owned
by **mapped subuids**, not the host user, so a plain host `rm` can neither traverse the
read-only dirs nor unlink the subuid-owned files. **Fix:** run the cleanup inside the rootless
user namespace — `$(CONTAINER_CMD) unshare rm -rf "$STORE"` — where the host user is root over
its full subuid range (gains `CAP_DAC_OVERRIDE`) and can delete everything. Shipped **identically
to both sandboxes** (runClaude `Makefile`, runCrush `client/Makefile`), each in both the `shell`
and `shell-exec` targets. "Done" = a real nested session exits with **no** `rm` errors and leaves
**no** leftover dir under `NESTED_PODMAN_STORE_BASE`.

**Status:** done — NOT YET ARCHIVED. The fix is implemented, dry-run-verified, and staged, but the
one check that matters (no `rm` errors + no leftover store dir on a real **host** exit) can only be
run by the maintainer on leaving a `make shell NESTED_PODMAN=1` session, because the failure
reproduces only as the unprivileged host user, not from inside the uid-0 sandbox. Archive this once
that host-exit test passes (see "Verification"). If it does NOT pass, reopen here.
**Priority:** 2 (a visible, every-exit failure that also silently fills the disk). **Difficulty:** 3.
**Created:** 2026-10-02 (William Emerison Six <billsix@gmail.com>). **Owner:** William Emerison Six
<billsix@gmail.com>.
**See also:** `tasks/archive/2026/09/27/dir-backed-nested-podman-storage.md` (the task that
introduced the ephemeral `dir` store and this trap), `tasks/reference/nested-podman-design.md`
("Store backend"), and the runCrush twin
`runCrushInContainer/tasks/archive/2026/09/27/dir-backed-nested-podman-storage.md`.

## Context — how to read this cold

The disk-backed nested store (2026-09-27) replaced the RAM tmpfs with an ephemeral host
directory created per launch and deleted on exit. The `shell`/`shell-exec` recipes do
(runClaude `Makefile:272-278` and `283-289`; runCrush `client/Makefile:355-361` and `366-372`):

```sh
STORE="$(mktemp -d "$(NESTED_PODMAN_STORE_BASE)/runclaude-nested.XXXXXX")"
trap 'rm -rf "$STORE"' EXIT INT TERM HUP
podman run -it --rm -v "$STORE":/var/lib/containers:Z … /shell.sh
```

The `mktemp` and the `trap` run on the **host**, as the host user. The `podman run` launches the
sandbox; inside it the **rootful** inner podman writes its image store into `$STORE` via the
sandbox's user namespace. So the files land on the host owned by the host user's **subuid range**
(the userns maps inner uids → host subuids), and the extracted image layers keep their original
modes — many top-level dirs (`/usr`, `/root`, `/etc`, a project `/venv`, `/gacalc`) are **not
owner-writable** (`dr-xr-xr-x`, `dr-xr-x---`).

When `make shell` exits, the trap fires and `rm -rf "$STORE"` runs **as the host user in the
initial namespace**. For each read-only `diff/<dir>`, the host user is neither its owning subuid
nor root-with-`CAP_DAC_OVERRIDE`, so it cannot get write access to unlink the contents →
`Permission denied`, and the dir survives. This happens on **every normal exit**, not only on
`SIGKILL` — correcting the original task's claim that "only `SIGKILL` can still leak one."

### Evidence (observed 2026-10-02, from inside a relaunched sandbox)

`NESTED_PODMAN_STORE_BASE` was `/mnt/sda1/tmpContainerStorage/` and held **five** leaked
`runclaude-nested.*` dirs (Sep 27 – Oct 2). The reported-failing one,
`runclaude-nested.9JadWE/storage/overlay/*/diff/`, showed `dr-xr-xr-x` / `dr-xr-x---` dirs owned
by (as seen from the sandbox userns) uid 0 — i.e. image-layer perms with no owner write bit; from
the host those same files are subuid-owned. The user's pasted exit log named exactly these diff
paths (`…/diff/venv`, `…/diff/root/.jupyter`, `…/diff/usr/bin/pandoc`, `…/diff/root/.emacs.d`, …).

## The fix

Change the trap in all four recipe blocks from:

```sh
trap 'rm -rf "$$STORE"' EXIT INT TERM HUP;
```

to:

```sh
trap '$(CONTAINER_CMD) unshare rm -rf "$$STORE"' EXIT INT TERM HUP;
```

`podman unshare` runs its argument in the same rootless user namespace podman itself uses, where
the host user is mapped to root and owns the whole subuid range — so `rm -rf` has
`CAP_DAC_OVERRIDE` over the read-only dirs and the subuid-owned files and deletes the store
completely and quietly. No fallback is needed or wanted: this code path is reached **only** when
`NESTED_PODMAN=1` and `NESTED_PODMAN_STORE=dir`, which is inherently a podman-nested run, so
`$(CONTAINER_CMD)` is `podman` by construction; if `podman unshare` ever failed, its error is more
useful than silently re-introducing the old wall via a plain-`rm` fallback.

Files changed (both sandboxes, identical):
- runClaude `Makefile` — `shell` and `shell-exec` traps.
- runCrush `client/Makefile` — `shell` and `shell-exec` traps.
- `tasks/reference/nested-podman-design.md` (runClaude) + both runCrush twins — the "only SIGKILL
  can leak" bullet corrected, and the `unshare` requirement recorded.

## Cleaning the already-leaked dirs

The four dead leaked dirs were removed in-session (the fifth, `runclaude-nested.X5tCAd`, was the
**active** store of the running session and was left alone). On the host, the maintainer removes
any future stragglers the same way the trap now does:

```sh
podman unshare rm -rf ~/.cache/runclaude-nested.* ~/.cache/crush-nested.*   # adjust STORE_BASE
```

(From inside a uid-0 sandbox a plain `rm -rf` also works, because there the files are already
owned by uid 0 with `CAP_DAC_OVERRIDE` — which is why the leak is invisible from inside and only
bites the host user.)

## Verification

- **Dry run** (`make -n shell NESTED_PODMAN=1`) in both sandboxes: the emitted trap line reads
  `trap 'podman unshare rm -rf "$STORE"' EXIT INT TERM HUP`.
- **Host, maintainer:** `make shell NESTED_PODMAN=1`, run an inner `podman build`/`pull` to
  populate the store, exit, and confirm (a) **no** `rm: cannot remove …` output and (b)
  `ls -d $NESTED_PODMAN_STORE_BASE/*-nested.*` finds nothing from that session.

## Open questions

None.
