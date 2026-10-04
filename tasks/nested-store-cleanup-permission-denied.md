# Nested `dir`-store cleanup fails with "Permission denied" and leaks the store dir

## BLUF — FIX COMMITTED (2026-10-02, `d339fad`); FIRST REAL HOST-EXIT TEST STILL PENDING

On exit from a nested-podman `dir`-store session (`make shell NESTED_PODMAN=1`), the cleanup trap's
`rm -rf "$STORE"` printed a wall of `rm: cannot remove '…/storage/overlay/…/diff/…': Permission
denied` and left the store directory behind — so `NESTED_PODMAN_STORE_BASE` accumulates dead
`*-nested.*` dirs instead of being cleaned at session end. The trap runs on the **host** as the
unprivileged user; GNU `rm` never `chmod`s, so it cannot unlink entries from a directory that has
no owner-write bit, and the image layers' `diff/` dirs mirror the image's `/` (mode 555 on Fedora)
and `/root` (550). **Fix:** run the cleanup inside the rootless user namespace —
`$(CONTAINER_CMD) unshare rm -rf "$STORE"` — where the host user is root (gains
`CAP_DAC_OVERRIDE`, which bypasses directory write bits and owns the whole subuid range) and can
delete everything. Shipped **identically to both sandboxes** (runClaude `Makefile`, runCrush
`client/Makefile`), each in both the `shell` and `shell-exec` targets. "Done" = a real nested
session **launched after the fix** exits with **no** `rm` errors and leaves **no** leftover dir
under `NESTED_PODMAN_STORE_BASE`.

**Status:** in progress — fix committed, awaiting the first exit of a post-fix session (see
"Timeline / evidence ledger"). The 2026-10-04 exit that still printed errors was a **pre-fix**
session and is NOT a failure of the fix (see "What happened on 2026-10-04"). Verification spans
sessions, so this doc carries an append-only ledger and a step plan that a cold session can
execute; the proposed cleanup **log** (step 2 of the plan) is what gives a later session evidence
to read. Archive once the ledger records one clean post-fix exit.
**Priority:** 2 (a visible, every-exit failure that also silently fills the disk). **Difficulty:** 3.
**Created:** 2026-10-02 (William Emerison Six <billsix@gmail.com>). **Owner:** William Emerison Six
<billsix@gmail.com>.
**See also:** `tasks/archive/2026/09/27/dir-backed-nested-podman-storage.md` (the task that
introduced the ephemeral `dir` store and this trap), `tasks/reference/nested-podman-design.md`
("Store backend" / the trap bullet), and the runCrush twin
`runCrushInContainer/tasks/nested-store-cleanup-permission-denied.md` (client-perspective record;
same plan, `crush-nested.*` names).

## Context — how to read this cold

The disk-backed nested store (2026-09-27) replaced the RAM tmpfs with an ephemeral host directory
created per launch and deleted on exit. The `shell`/`shell-exec` recipes (runClaude `Makefile`, the
two blocks under the comment "Nested `dir` store"; runCrush `client/Makefile`, same comment) do:

```sh
STORE="$(mktemp -d "$(NESTED_PODMAN_STORE_BASE)/runclaude-nested.XXXXXX")"
trap 'podman unshare rm -rf "$STORE"' EXIT INT TERM HUP      # was: trap 'rm -rf "$STORE"' …
podman run -it --rm -v "$STORE":/var/lib/containers:Z … /shell.sh
```

The `mktemp` and the `trap` run on the **host**, as the host user. The `podman run` launches the
sandbox; inside it the **rootful** inner podman writes its image store into `$STORE` through the
sandbox's user namespace. Two consequences for a host-side `rm`:

1. **Ownership.** Rootless podman maps container uid 0 to the **host user** and uids 1–65535 to the
   host user's **subuid range**. So layer files that are root-owned in the image (the vast majority)
   land owned by the host user; files owned by other uids in the image land owned by subuids, which
   the host user cannot touch at all.
2. **Modes.** Extracted layers keep the image's modes. Each layer's `diff/` dir takes the mode of the
   tar's `./` entry — the image's `/`, which on Fedora is `dr-xr-xr-x` (555) — and `/root` is
   `dr-xr-x---` (550). GNU `rm -rf` never `chmod`s, so even as the **owner** it cannot unlink an
   entry from a directory without the owner-write bit → `Permission denied` on every direct child
   of such a dir, while everything beneath them in ordinary 755 dirs is deleted.

**Important make detail for verification:** `make` reads the recipe when `make shell` starts, so a
Makefile change to the trap takes effect only for sessions **launched after** the change. A
session that was already running when the fix was committed exits with the OLD trap.

### Evidence (observed 2026-10-02, from inside a relaunched sandbox)

`NESTED_PODMAN_STORE_BASE` was `/mnt/sda1/tmpContainerStorage/` and held **five** leaked
`runclaude-nested.*` dirs (Sep 27 – Oct 2). The reported-failing one,
`runclaude-nested.9JadWE/storage/overlay/*/diff/`, showed `dr-xr-xr-x` / `dr-xr-x---` dirs owned
by (as seen from the sandbox userns) uid 0. The user's pasted exit log named exactly these diff
paths (`…/diff/venv`, `…/diff/root/.jupyter`, `…/diff/usr/bin/pandoc`, `…/diff/root/.emacs.d`, …).
The four dead leaked dirs were removed in-session; the fifth, `runclaude-nested.X5tCAd`, was the
**active** store of the running session and was left alone.

## What happened on 2026-10-04 (the exit the maintainer pasted) — NOT a fix failure

The maintainer closed the sandbox on the morning of 2026-10-04 and saw nine `rm: cannot remove
'/mnt/sda1/tmpContainerStorage//runclaude-nested.X5tCAd/storage/overlay/<layer>/diff/<dir>':
Permission denied` lines (`<dir>` ∈ `gacalc`, `tmp`, `venv`, `root`, `opt`, across five layers).

- **That session predates the fix.** `X5tCAd` is the store the 2026-10-02 evidence calls "the
  active store of the running session"; the fix commit `d339fad` was made at 21:44 that evening
  while it ran, so its trap was still the bare `rm -rf`. The current session (store
  `runclaude-nested.wmIfwl`, created 2026-10-04 10:58, i.e. launched after the commit) is the first
  one whose exit actually tests `podman unshare`.
- **What the leftover shows (inspected from the 2026-10-04 session).** `X5tCAd` is 88 KB: five
  `storage/overlay/<layer>/diff` dirs, each mode **555**, each holding only the **empty** top-level
  dirs named in the error (mode 755/1777, owner uid 0 as seen in-sandbox = the host user). So the
  bare `rm` deleted every file *beneath* `diff/gacalc`, `diff/venv`, … and failed only at unlinking
  those entries from their 555 parent. That pins the blocker to the directory write bit, not to
  subuid ownership (which would have left the files too). `/` on the sandbox image is 555 —
  confirmed `stat -c %a /` → `555` — which is where `diff/`'s mode comes from.
- **Why it matters for the fix:** `CAP_DAC_OVERRIDE` (root in the userns under `podman unshare`)
  bypasses directory write bits, so the fix covers exactly this case. Nothing about the 2026-10-04
  output contradicts the fix; it only confirms the pre-fix diagnosis with cleaner evidence.
- The doubled slash in the path is cosmetic: `NESTED_PODMAN_STORE_BASE` was given with a trailing
  `/`.

## Timeline / evidence ledger (append-only; a later session adds the next row)

| When (local) | Store | Launched with | Exit result | Source of evidence |
|---|---|---|---|---|
| 2026-09-27 … 2026-10-02 | 4 × `runclaude-nested.*` | pre-fix trap | leaked (`Permission denied`) | `ls` of the base dir 2026-10-02; removed in-session |
| 2026-10-02 (launch) → 2026-10-04 10:33 (exit) | `runclaude-nested.X5tCAd` | **pre-fix** trap (fix committed 21:44 on 10-02 while it ran) | leaked; 9 `Permission denied` lines; 88 KB of empty 555-parented dirs left | maintainer's pasted exit log; in-sandbox inspection 2026-10-04 |
| 2026-10-04 10:58 (launch) → *pending* | `runclaude-nested.wmIfwl` | **post-fix** trap (`podman unshare rm -rf`) | *to be recorded* | the maintainer's terminal at exit (paste it), `ls -d /mnt/sda1/tmpContainerStorage/*-nested.*` afterwards; the cleanup log once step 2 ships |

Caveat for whoever fills in the pending row: the maintainer said (2026-10-04) they will clean
stragglers **as root by hand**. A missing `wmIfwl` dir therefore proves nothing on its own — the
row needs either the terminal output of the exit or the cleanup log (step 2 below).

## Plan — executing and verifying across sessions

Each step is self-contained; a cold session can pick up at the first unchecked one. Every step that
needs the maintainer says so.

- [ ] **Step 1 (maintainer, on the host) — observe the first post-fix exit.** On leaving the current
  `wmIfwl` session: (a) look for any `rm:` or `podman unshare` error text; (b) run
  `ls -d /mnt/sda1/tmpContainerStorage/*-nested.*` **before** cleaning anything by hand; (c) paste
  both into the next session, or write them to `/mnt/sda1/tmpContainerStorage/exit-notes.txt`
  (the base dir is visible from inside the sandbox, so the next session can read it). A clean exit
  = no error text and no `wmIfwl` dir. **Gotcha:** if the shell is closed with a terminal kill
  (SIGKILL) the trap cannot run at all — that is a leak by design, not a fix failure; `HUP` is
  trapped, `KILL` cannot be.
- [x] **Step 2 — make the trap leave a log. APPLIED 2026-10-04 (go-ahead given; both sandboxes,
  all four blocks, `make -n` verified, READMEs repointed to `podman unshare`). Takes effect from the
  NEXT launch — the running `wmIfwl` session still exits with the unlogged `unshare` trap.** Change the trap in all four recipe blocks (runClaude `shell`+`shell-exec`,
  runCrush `client/` `shell`+`shell-exec`) so each exit appends to
  `$(NESTED_PODMAN_STORE_BASE)/<prefix>-nested-cleanup.log` — a file **outside** the store dir, so
  it survives the `rm` and is readable from inside the next sandbox. Intended shape (Makefile
  escaping shown; keep the four blocks identical):

  ```make
  trap 'LOG="$(NESTED_PODMAN_STORE_BASE)/runclaude-nested-cleanup.log"; \
        { echo "== $$(date -Is) store=$$STORE"; \
          $(CONTAINER_CMD) unshare rm -rf "$$STORE" 2>&1; echo "== rm exit=$$?"; \
          [ -e "$$STORE" ] && echo "== LEFTOVER: $$STORE" || echo "== clean"; \
        } 2>&1 | tee -a "$$LOG"' EXIT INT TERM HUP; \
  ```

  This exact shape was rendered and run 2026-10-04 in a scratch Makefile with a stand-in `podman`
  (`make -n` shows valid `sh`; the log gained a `==` block ending `== clean`). Re-verify in place
  with `make -n shell NESTED_PODMAN=1` after applying; the `$?` must be `rm`'s, so the `echo`
  stays directly after the `rm` and before the `-e` test. The log is a
  per-base-dir append file: a later session reads it with
  `cat /mnt/sda1/tmpContainerStorage/*-nested-cleanup.log` and copies each `==` block into the
  ledger above. A `LEFTOVER` line plus the `rm`/`unshare` stderr above it is the failure evidence
  this doc has lacked so far.
- [ ] **Step 3 (any session) — read the evidence and fill the ledger.** Sources, in order of
  reliability: the cleanup log (after step 2); the maintainer's pasted exit text; `exit-notes.txt`;
  and, for a leftover dir, this forensic set run from inside the sandbox (uid 0 = the host user):

  ```sh
  BASE=/mnt/sda1/tmpContainerStorage                      # $NESTED_PODMAN_STORE_BASE
  ls -ld --time-style=full-iso "$BASE"/*-nested.*          # which stores leaked, when they died
  du -sh "$BASE"/*-nested.*                               # 88K = only read-only skeleton left; GBs = rm never ran (SIGKILL?)
  find "$BASE"/*-nested.* -type d ! -perm -u+w | head     # the dirs whose write bit blocked a bare rm
  find "$BASE"/*-nested.* ! -uid 0 | head                  # subuid-owned files (non-root in the image), if any
  findmnt -no SOURCE /var/lib/containers                   # THIS session's store name, for the ledger
  ```

  From the **host** instead, `stat -c %u` on a leftover shows the host uid for image-root files and
  a number ≥ 100000 for subuid-owned ones, and `podman unshare cat /proc/self/uid_map` shows the
  mapping the trap now runs under.
- [ ] **Step 4 — decide.** One clean post-fix row in the ledger → check the Verification box, fold
  the final mechanism wording into `tasks/reference/nested-podman-design.md` (already largely done
  2026-10-04), and archive this task (own commit, after the work commit). A `LEFTOVER` row →
  pick the matching fallback below, apply it to all four blocks, and add a ledger row for the next
  launch.

## Fallbacks if `podman unshare rm -rf` does not clean the store

Ranked. Pick by the evidence in the log, never by guess; each one stays identical across the four
recipe blocks.

- **`podman unshare` itself errors** (e.g. "cannot re-exec process to join the existing user
  namespace", or podman missing from `PATH` in a non-interactive `make`): the `rm` never ran, so
  the whole store is left (GBs, not 88 KB). Likely cause is host rootless state, not the fix;
  check `podman unshare true` on the host by hand. Fallback: run the cleanup as a throwaway
  container, which uses the same userns without joining the pause process:
  `podman run --rm -v "$STORE":/s:Z registry.fedoraproject.org/fedora:44 rm -rf /s/storage /s/*`
  (an image the host already has; it cannot remove the mountpoint itself, so follow with a plain
  host `rmdir "$STORE"`).
- **`rm` ran but a 555/550 parent still blocked it** (would mean `CAP_DAC_OVERRIDE` was not
  effective — unexpected): prepend `chmod -R u+rwX "$STORE"` inside the same `unshare`. This also
  works as a *bare-host* fallback for host-user-owned files, but not for subuid-owned ones.
- **Subuid-owned files remain** (`find ! -uid <host uid>` on the host): the unshare mapping did
  not cover them. Check `/etc/subuid` for the host user versus `podman unshare cat
  /proc/self/uid_map`; a mapping change (e.g. `usermod --add-subuids`) is a host fix, after
  which `podman system migrate` picks it up.
- **Clean the store from inside the sandbox instead** (design alternative, not a patch): have
  `shell.sh`'s exit path stop the inner podman and `rm -rf /var/lib/containers/*` — inner uid 0
  has `CAP_DAC_OVERRIDE` in the userns, so this always works — leaving the host trap only a
  `rmdir`. Downside: does nothing if the sandbox is killed rather than exited, so keep the host
  `unshare` trap as the primary either way.

## Cleaning already-leaked dirs (host)

```sh
podman unshare rm -rf /mnt/sda1/tmpContainerStorage/runclaude-nested.* \
                      /mnt/sda1/tmpContainerStorage/crush-nested.*      # adjust to STORE_BASE
```

Running this by hand is also a cheap pre-test of the trap: it is the exact command the trap runs.
(From inside a uid-0 sandbox a plain `rm -rf` also works, because there the user is root with
`CAP_DAC_OVERRIDE` in the userns — which is why the leak is invisible from inside and only bites
the host user. The maintainer may also just remove them as real root.) **Do not clean the current
session's store** (`findmnt -no SOURCE /var/lib/containers` names it) while it runs.

## Verification

- [x] **Dry run** (`make -n shell NESTED_PODMAN=1`) in both sandboxes: the emitted trap line reads
  `trap 'podman unshare rm -rf "$STORE"' EXIT INT TERM HUP` (2026-10-02).
- [ ] **Host, maintainer:** a session **launched after `d339fad`** exits with (a) **no** `rm:` or
  `podman unshare` error output and (b) no leftover dir for that session under
  `NESTED_PODMAN_STORE_BASE` (or, after step 2, a `== clean` block in the cleanup log). Recorded
  in the ledger.

## Open questions

None. (Step 2's go-ahead was given 2026-10-04 and it is applied; step 1's paste remains the only
evidence source for the `wmIfwl` exit, which predates the log.)
