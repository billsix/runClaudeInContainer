# Fix rollout.py: derive the fleet root instead of hardcoding /foo/opt

**Status:** complete
**Completed:** 2026-09-18
**Created:** 2026-09-18 (William Emerison Six <billsix@gmail.com>)

## What this did

`tasks/adhoc/container-cmd-podman-docker-fallback/rollout.py`, the one-shot codemod that rolled
the `CONTAINER_CMD` podman/docker auto-detect across every project, hard-coded `/foo/opt` in its
`find -L … -name Makefile` fleet scan: an ephemeral mount path, which the ad-hoc-script
convention forbids. This task removed the hardcode. Part of the broader audit in
`tasks/archive/2026/11/15/adhoc-scripts-repo-relative-paths.md`.

The script is deliberately fleet-wide, so the usual repo-root idiom (`parents[3]`) was the wrong
fix; the right root is the directory that holds all the projects.

## What changed

- A `fleet_root()` helper: `sys.argv[1]`, else `$FLEET_ROOT`, else
  `Path(__file__).resolve().parents[4]` (the script sits at
  `<fleet>/<repo>/tasks/adhoc/<slug>/rollout.py`). That precedence followed the recommendation in
  the audit task's open question 1.
- `find_makefiles()` scanned `str(fleet_root())`; the docstring's "Run from anywhere" line
  documented the arg/env/default; `import sys` added; the `+x` mode preserved.

## Verification

`fleet_root()` with no arg or env resolved to `/foo/opt` in that session, so the default equalled
the old hardcoded value. The codemod was not re-run across the fleet: the rollout had already
happened, and a re-run would have mutated Makefiles in nearly every project.

The change was applied for the maintainer's review and was kept (committed in `dcd16c0`). The
one-shot `rollout.py` itself was later removed, 2026-11-15 (`9e27488`).
