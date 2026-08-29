# PODMAN_RUN_FLAGS passthrough — nested runs work with no hand-edits, hosts unchanged

**Status:** complete (2026-08-29) — design implemented, pilot done, cold fresh-session
verification passed (after the maintainer's rebuild + relaunch: `NESTED_PODMAN=1` reached the
session, `make image BUILD_DOCS=0` built nested, and a plain `make test` auto-applied
`--cgroups=disabled` — 411 passed, zero hand-edits), and the fan-out to all 8 remaining
projects done and verified (see the checklist).
**Completed:** 2026-08-29
**Priority:** 4
**Difficulty:** 3
**Started:** 2026-08-29 (William Emerison Six <billsix@gmail.com>)

## BLUF

Replace the hand-append-`--cgroups=disabled`-per-run workflow with a standing convention: the
sandbox exports `NESTED_PODMAN=1` into nested-capable sessions, and every container-template
project's Makefile carries `PODMAN_RUN_FLAGS ?= $(if $(filter 1,$(NESTED_PODMAN)),--cgroups=disabled)`
threaded into its `$(CONTAINER_CMD) run` lines. Nested `make test`/`run`/`docs` Just Work; on the
maintainer's host (env var absent) every Makefile behaves byte-identically — no flags, ever. Done =
convention in both sandboxes + docs + personal overlay, pilot verified, and the fan-out checklist
below completed.

## Context

Read first: `tasks/reference/nested-podman-design.md` — "The `PODMAN_RUN_FLAGS` convention" section
(the design of record) and the wall-2 UPDATE (the empirical finding that motivated re-design).

Decisions made 2026-08-29 (maintainer gave full discretion; agent's calls, recorded):

- **The signal is `NESTED_PODMAN=1` in the environment**, exported by the sandbox launch flags
  (`-e NESTED_PODMAN=1` inside `NESTED_PODMAN_FLAGS`, this repo's `Makefile`) — only when the
  sandbox is actually nested-capable; a plain `make shell` exports nothing.
  runCrushInContainer's client already exported it (its `Makefile:202`); this repo now matches.
- **The consumer is a per-project `PODMAN_RUN_FLAGS ?=` auto-default** (see the reference doc for
  the exact block), threaded into **`run` invocations only, never `build`** (`podman build`
  rejects `--cgroups` and does not need it — verified). Overridable per invocation.
- **The auto value stays `--cgroups=disabled` even though the current host stack no longer needs
  it** (cgroup2 now mounts rw in the sandbox; flagless inner runs verified working 2026-08-29).
  The flag is harmless when applied and keeps older podman stacks, other machines, and the
  three-deep runCrush-client case working without re-diagnosis.
- **Name is `PODMAN_RUN_FLAGS`** — the idiom the personal overlay already blesses as a permanent
  Makefile addition, prototyped (manual, empty-default) in regardingBritt.
- **Known inheritance side effect, accepted:** the sandbox repos' own launch variable is also
  named `NESTED_PODMAN` with `?=`, so launching one sandbox from inside another inherits nested
  capability inward. Coherent for three-deep use; costs nothing otherwise.

## Plan / rollout checklist

- [x] runClaudeInContainer `Makefile`: `-e NESTED_PODMAN=1` added to `NESTED_PODMAN_FLAGS`.
- [x] Docs: `tasks/reference/nested-podman-design.md` (convention section + wall-2 update),
      `entrypoint/dotfiles/.claude/CLAUDE.md` ("Running projects in a nested container" points
      1–2 rewritten; converting a project's Makefile to the pattern is now pre-authorized),
      `tasks/reference/sandbox-capability-map.md` (two mentions updated).
- [x] Personal overlay (`~/.ai-coding-conventions.personal.md` via the mount): template contract +
      standing-authorization section updated to the new convention.
- [x] runCrushInContainer: client `Makefile` gets the same `PODMAN_RUN_FLAGS` auto-default on its
      run targets (for the three-deep case); its `CLAUDE.md` nested bullet + its
      `tasks/reference/nested-podman-design.md` copy updated.
- [x] **Pilot: geometricalgebra** — `PODMAN_RUN_FLAGS` added + threaded through all 12 run
      invocations. Verified both ways: host-parity — `make -n` over shell/shell-exec/test/format/
      image with the env var unset is identical to pre-edit modulo one collapsed space (the empty
      expansion), i.e. behaviorally identical; nested — with `NESTED_PODMAN=1`, `make image
      BUILD_DOCS=0` built nested and a plain `make test` ran the full suite (**411 passed**) with
      zero hand-edits, the flag auto-applied.
- [x] Fan-out to the remaining container-template projects (2026-08-29, maintainer go-ahead):
      apue · graphicalcontainer · hanoi · multivariate-math · modelviewprojection ·
      regardingBritt (manual `PODMAN_RUN_FLAGS ?=` upgraded to the auto-default; its run lines
      already threaded the variable) · spimulator · texExpToPng. A mount scan found no other
      Makefile+Dockerfile+entrypoint project; /mnt/sda1 and /foo/opt were confirmed the same
      files (same device:inode), so each repo was edited once. Verified both ways per repo:
      host-parity — before/after `make -n` capture of EVERY target with `NESTED_PODMAN` unset
      is identical modulo collapsed spaces (only `image-export` diffs, and only by its embedded
      `date` timestamp); nested — with `NESTED_PODMAN=1`, `make -n shell` shows
      `--cgroups=disabled` auto-applied in all 8. No per-repo nested *runs* were exercised —
      none of the 8 images is cheap (multi-GB toolchains vs the 8g RAM store already holding
      the pilot image); the mechanism itself was proven end-to-end on the pilot the same day.
      All 8 Makefiles staged. Notes: graphicalcontainer names its command variable
      `$(PODMAN_CMD)` (not `$(CONTAINER_CMD)`) and its `all: image run` names a nonexistent
      `run` target — both pre-existing, left as-is; texExpToPng has one literal `podman run`
      line (its `example` target — a drift from `$(CONTAINER_CMD)`), which also got the flag
      threaded.

## Fresh-session verification (the maintainer is rebuilding + relaunching to test this cold)

The maintainer plans to exit the session, rebuild runClaudeInContainer, and relaunch so every
layer loads fresh. What the NEW session (and the maintainer) need to know:

1. **An image rebuild is not actually required for this feature** — `-e NESTED_PODMAN=1` is a
   `podman run` flag in the Makefile, live on the next `make shell NESTED_PODMAN=1` launch with
   no `make image`. Rebuilding anyway is harmless and also picks up the freshly-edited baked
   conventions copy (`entrypoint/dotfiles/.claude/CLAUDE.md`) for mount-less use; in normal
   `make shell` use, that file and the reference docs are bind-mounted, so they're live already.
2. **In the fresh session, verify in order:**
   - `echo $NESTED_PODMAN` → `1` (proves the new Makefile export reached the session);
   - the loaded conventions (`~/.claude/CLAUDE.md`, "Running projects in a nested container"
     point 2) and the personal overlay (`~/.claude/ai-coding-conventions.personal.md`,
     `PODMAN_RUN_FLAGS` bullet + the 2026-08-29 update to the 2026-06-08 standing arrangement)
     describe the convention — both were edited this session and should load fresh;
   - the pilot works cold: `cd /foo/opt/geometricalgebra && make image BUILD_DOCS=0 && make test`
     — NOTE the image must be rebuilt first (the nested store is an ephemeral RAM tmpfs; images
     do not survive sessions; the lean build takes a few minutes) — expect 411 passed with zero
     hand-edits and `--cgroups=disabled` visible in the expanded command (`make -n test | head`).
3. **Then continue the fan-out checklist above** (the remaining unconverted projects). Per
   project: add the variable block + thread `$(PODMAN_RUN_FLAGS)` into every
   `$(CONTAINER_CMD) run ` line (a `sed 's|$(CONTAINER_CMD) run |…|g'` did it cleanly for the
   pilot), then verify host-parity via before/after `make -n` capture (expect only collapsed
   spaces) and, where an image is cheap, one nested run. regardingBritt: replace its manual
   `PODMAN_RUN_FLAGS ?=` with the auto-default and keep its threading.
4. **Everything is staged, uncommitted**, in three repos: runClaudeInContainer (Makefile, two
   reference docs, dotfiles conventions, this task doc), runCrushInContainer (client/Makefile —
   including dropping a stale `-e CRUSH_AT_IMPORT` from the vendor target, CLAUDE.md, its
   nested-podman reference copy), geometricalgebra (Makefile). The personal overlay edits are in
   the HOST file `~/.ai-coding-conventions.personal.md` (not a repo — already durable).

## Correction (2026-08-29, post-archive)

The fan-out checklist's claim "a mount scan found no other Makefile+Dockerfile+entrypoint
project" was **wrong**: that scan was depth-1 over `/foo/opt/*/` and did not follow the
symlinks into `/mnt/sda1`, so it missed every nested repo. A symlink-following depth-4 sweep
the same day found: the **16 openstax `osbooks-*` repos** (each its own git repo, each with a
hardcoded `PODMAN_RUN_FLAGS = --cgroups=disabled` — converted to the auto-default the same
day, prompted by the maintainer asking about openstax), the **20 billsEmacsConfigs
per-language Makefiles**, **smalltalk**, and **epix-mirror** (manual empty `?=` variants), and
**spimulator/pgu** (no variable at all) — all of which were then also converted the same day
with maintainer approval ("convert all of them"), with host-parity and nested verification
per group. Current status lives in `tasks/reference/nested-podman-design.md` ("The
PODMAN_RUN_FLAGS convention"). Also: the regardingBritt repo was deleted by the maintainer
later the same day.

## Notes / decisions

- The stale-lore discovery that triggered the redesign: `/sys/fs/cgroup` is mounted rw
  (`nsdelegate`) in a `NESTED_PODMAN=1` sandbox on the current host stack, and plain flagless
  inner `podman run`s succeed — the June-2026 "every inner run needs `--cgroups=disabled`" wall
  is gone here. Recorded with recheck guidance in `nested-podman-design.md`.
- Host-parity nuance: the empty `$(PODMAN_RUN_FLAGS)` expansion leaves one extra space in the
  expanded command — shells collapse it, so behavior is identical, but a byte-level `make -n`
  diff shows it. Expected; not a defect.

## Open questions

None — maintainer delegated the design calls 2026-08-29 ("you figure it out … whatever your
recommendation is").
