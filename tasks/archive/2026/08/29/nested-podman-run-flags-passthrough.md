# PODMAN_RUN_FLAGS passthrough — nested runs work with no hand-edits, hosts unchanged

**Status:** complete
**Completed:** 2026-08-29
**Started:** 2026-08-29 (William Emerison Six <billsix@gmail.com>)

## What this did

Replaced the hand-append-`--cgroups=disabled`-per-run workflow with a standing convention: the
sandbox exports `NESTED_PODMAN=1` into nested-capable sessions, and every container-template
project's Makefile carries
`PODMAN_RUN_FLAGS ?= $(if $(filter 1,$(NESTED_PODMAN)),--cgroups=disabled)` threaded into its
`$(CONTAINER_CMD) run` lines. Nested `make test`/`run`/`docs` work unedited; on the maintainer's
host (env var absent) every Makefile behaves identically to before. The design of record is
`tasks/reference/nested-podman-design.md`, "The `PODMAN_RUN_FLAGS` convention".

## Decisions (the agent's calls under full maintainer discretion, 2026-08-29)

- **The signal is `NESTED_PODMAN=1` in the environment**, added as `-e NESTED_PODMAN=1` to
  `NESTED_PODMAN_FLAGS` in this repo's `Makefile`, so only a nested-capable launch exports it.
  runCrushInContainer's client already exported it.
- **The consumer is a per-project `PODMAN_RUN_FLAGS ?=` auto-default**, threaded into `run`
  invocations only, never `build` (`podman build` rejects `--cgroups`, verified). Overridable
  per invocation.
- **The auto value stays `--cgroups=disabled`** although the current host stack no longer needs
  it (cgroup2 mounts rw, `nsdelegate`, in the sandbox; flagless inner runs verified 2026-08-29).
  It is harmless and keeps older stacks and the three-deep runCrush-client case working. The
  stale June-2026 "every inner run needs the flag" lore is recorded with recheck guidance in the
  reference doc.
- **Name `PODMAN_RUN_FLAGS`**, the idiom the personal overlay already blessed.
- **Accepted side effect:** the sandboxes' own launch variable is also `NESTED_PODMAN ?=`, so a
  sandbox launched inside another inherits nested capability inward; coherent for three-deep use.

## What changed

- This repo: `Makefile` (`-e NESTED_PODMAN=1`); `tasks/reference/nested-podman-design.md`
  (convention section + wall-2 update); `entrypoint/dotfiles/.claude/CLAUDE.md` ("Running
  projects in a nested container", with converting a Makefile to the pattern made
  pre-authorized); `tasks/reference/sandbox-capability-map.md`.
- The personal overlay: template contract and the standing-authorization section.
- runCrushInContainer: client `Makefile` got the auto-default on its run targets (and lost a
  stale `-e CRUSH_AT_IMPORT` from the vendor target); its `CLAUDE.md` and reference copy.
- **Pilot, geometricalgebra:** threaded through all 12 run invocations.
- **Fan-out (maintainer go-ahead):** apue, graphicalcontainer, hanoi, multivariate-math,
  modelviewprojection, regardingBritt (manual `?=` upgraded), spimulator, texExpToPng.
  Pre-existing drift left as-is: graphicalcontainer's `$(PODMAN_CMD)` and its `all: image run`
  naming a nonexistent `run`; texExpToPng's one literal `podman run` line also got the flag.

## Verification

- **Host parity, every repo:** before/after `make -n` of every target with `NESTED_PODMAN`
  unset was identical modulo one collapsed space (the empty expansion; shells collapse it) and
  `image-export`'s embedded timestamp.
- **Nested:** `make -n shell` showed `--cgroups=disabled` auto-applied in all 8 fan-out repos.
  Only the pilot was run nested (the other images were multi-GB): `make image BUILD_DOCS=0` then
  a plain `make test`, 411 passed, zero hand-edits.
- **Cold fresh-session check** after the maintainer rebuilt and relaunched: `NESTED_PODMAN=1`
  reached the session, the pilot rebuilt nested, and `make test` passed 411 with the flag
  auto-applied. (The image rebuild was not required for the feature itself; `-e` is a run flag.)

## Correction (2026-08-29, post-archive)

The fan-out claim "a mount scan found no other Makefile+Dockerfile+entrypoint project" was
wrong: the scan was depth-1 over `/foo/opt/*/` and did not follow symlinks into `/mnt/sda1`. A
symlink-following depth-4 sweep the same day found the 16 openstax `osbooks-*` repos (hardcoded
`PODMAN_RUN_FLAGS = --cgroups=disabled`), the 20 billsEmacsConfigs per-language Makefiles,
smalltalk and epix-mirror (manual empty `?=`), and spimulator/pgu (no variable). All were
converted the same day with maintainer approval ("convert all of them"), verified per group.
The regardingBritt repo was deleted by the maintainer later that day.

Superseded: the 8g RAM tmpfs nested store used here was replaced by a disk directory as the
default 2026-09-27 (tmpfs kept as an opt-in).
