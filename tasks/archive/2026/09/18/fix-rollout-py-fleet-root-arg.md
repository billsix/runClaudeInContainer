# Fix rollout.py: derive the fleet root instead of hardcoding /foo/opt

**Status:** applied 2026-09-18 — awaiting maintainer review (may be reverted)
**Priority:** 4
**Difficulty:** 2
Created 2026-09-18 (William Emerison Six <billsix@gmail.com>).

## BLUF

`tasks/adhoc/container-cmd-podman-docker-fallback/rollout.py:46` hard-codes `/foo/opt` in its
`find -L … -name Makefile` fleet scan — an ephemeral mount path, exactly what the ad-hoc-script
convention forbids. This task removes the hardcode: the fleet root is now taken from an optional
CLI arg, else `$FLEET_ROOT`, else derived from the script's own location. Applied 2026-09-18 so
the maintainer can see the diff; may be reverted. Part of the broader audit in
`tasks/adhoc-scripts-repo-relative-paths.md`.

## Context (cold-start)

`rollout.py` is an archived one-shot codemod that rolled the `CONTAINER_CMD` podman/docker
auto-detect across every project. It is **deliberately fleet-wide** — it scans *all* projects,
not just this repo — so the plain repo-root idiom (`parents[3]`) is the wrong fix: rooting it in
this repo would break its purpose. The fleet root is the directory that *holds* all the projects
(this session mounted it at `/foo/opt`; another launch/machine/user mounts it elsewhere).

Convention being enforced: runtime `CLAUDE.md` "Ad-hoc scripts" section (also
`tasks/reference/task-doc-conventions.md:108`) — never encode a container-absolute mount path.

## What was done

Edited `tasks/adhoc/container-cmd-podman-docker-fallback/rollout.py`:
- Added a `fleet_root()` helper: `sys.argv[1]` → `$FLEET_ROOT` → `Path(__file__).resolve().parents[4]`
  (this repo sits directly under the fleet root; the script is at
  `<fleet>/<repo>/tasks/adhoc/<slug>/rollout.py`, so `parents[4]` is the fleet root).
- `find_makefiles()` now scans `str(fleet_root())` instead of the literal `/foo/opt`.
- Updated the module docstring's "Run from anywhere" line to document the arg/env/default.
- `import sys` added. Edited in place (Edit, not Write) so the `+x` mode is preserved.

## Verification

- Non-destructive: confirmed `fleet_root()` with no arg/env resolves to `/foo/opt` in this
  session — i.e. the new default equals the old hardcoded value, so behavior is unchanged here.
- **Did NOT re-run the codemod across the fleet.** Running it would mutate Makefiles in ~all
  projects; the rollout already happened and is archived, and a fleet-wide re-run is out of scope
  for a path fix. The derivation-equals-prior-value check above is the proof that matters.

## Open questions

None. (The fleet-root-supply decision — arg > env > derived default — was taken here per the
recommendation in `tasks/adhoc-scripts-repo-relative-paths.md` open question 1.)
