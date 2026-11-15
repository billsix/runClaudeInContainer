# Verify the host `make shell` carries no --cgroups=disabled

**Status:** blocked
**Blocked on:** a `[HOST]` run (it has to run outside the sandbox, where `/run/.containerenv` is absent).
**Recheck:** `[HOST] make -n shell NESTED_PODMAN=1 | grep -c cgroups=disabled` in runClaudeInContainer prints `0`. Cleared → done-record + archive.
**Priority:** 7
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/archive/2026/11/15/nested-native-overlay.md ("Verification", the items left to the maintainer)

## BLUF

`PODMAN_RUN_FLAGS` in the runClaudeInContainer `Makefile` keys on `/run/.containerenv`, so only a `podman run` from inside a container gets `--cgroups=disabled`; the outermost host launch must not. Inside the sandbox the check would print a nonzero count by design, so it has to run on the host. Done means the host count is `0`. Optional: the sandbox launched fine on the host, which already suggests the flag is absent.

## Context

- If the count is not `0`, read the `PODMAN_RUN_FLAGS` definition in the `Makefile` and `tasks/reference/nested-podman-design.md` ("The PODMAN_RUN_FLAGS convention").
