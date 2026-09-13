# Scope the lean-image-when-nested convention to downstream projects, not the sandboxes

**Status:** Done — 2026-09-13. Archived 2026-09-13.
**Priority:** 3
**Difficulty:** 3

## BLUF

The "optional build flags default lean when `NESTED_PODMAN=1`" convention is correct for
**downstream** container-per-project repos (the agent builds them nested in the RAM store), but wrong
for the **sandboxes themselves** (runClaudeInContainer and the runCrushInContainer client), which the
maintainer builds and runs on the host and launches nested-capable by *typing* `NESTED_PODMAN=1`.
Applying it to a sandbox turned the launch flag into an image downgrade — the bug that gave the crush
client no language servers. This task **rescoped the convention to downstream-only**, parked the
sandbox-minimal proposal, and recorded the principle in this repo's always-read docs. No
`NESTED_PODMAN`-coupled image variant was added to this sandbox.

## Context

This was the runClaude/fleet half of the decision recorded in runCrushInContainer
`tasks/reference/nested-podman-vs-image-content.md` (William Emerison Six <billsix@gmail.com>,
2026-09-12).

**The principle:** `NESTED_PODMAN` means two things by who sets it — a *typed* launch flag on a
sandbox = run-time capability (add `podman run` flags), an *inherited* env signal in a downstream
project = "I'm being built inside a sandbox, go lean + `--cgroups=disabled`." Coupling image content to
it is only ever right for the inherited (downstream) case.

**State of this repo going in (already mostly right):** no `FULL_TOOLCHAIN` / `NESTED_PODMAN`-keyed
image variant (only `USE_EMACS_CONFIG`), and `make shell`/`shell-exec` had no `image` prerequisite
(never did). So the risk was *future* work re-introducing the coupling — which is what this task
guarded against in the docs.

## What was done

1. **Rescoped the convention docs.** Added an explicit scope boundary to
   `tasks/reference/minimal-nested-images.md` and `tasks/minimal-image-for-nested-podman-standard.md`:
   the standard applies to downstream container-per-project repos only, **never** to the two sandboxes
   themselves (host-built, launched nested — typing `NESTED_PODMAN=1` must not change their image), with
   the sandbox rows in their survey/rollout tables marked N/A — excluded, cross-referencing
   `nested-podman-vs-image-content.md`.
2. **Parked `tasks/minimal-sandbox-image.md`** — marked it `dropped` with the reason (the maintainer
   builds this sandbox on the host; a `NESTED_PODMAN`-coupled lean self-build is the bug, and a lean
   build verifies a different package set than the shipped image). If ever revived, it must use an
   explicit non-`NESTED_PODMAN` flag and a distinct tag.
3. **Recorded the principle** in the always-read docs: the root `CLAUDE.md` "## Nested Podman" section
   and a new point 3 in the mounted cross-project conventions
   (`entrypoint/dotfiles/.claude/CLAUDE.md`, "Running projects in a nested container") — lean-image-
   when-nested is for downstream projects the agent builds, never the sandbox you're in.
4. **Withdrew the sandbox framing** from `tasks/reference/nested-podman-design.md`'s PODMAN_RUN_FLAGS
   note ("the same signal can pick a build variant"), scoping it to downstream projects.

## Verification

- The convention docs state the downstream-only scope and exclude the two sandboxes.
- `tasks/minimal-sandbox-image.md` is marked dropped.
- `grep -rn 'FULL_TOOLCHAIN' Makefile Dockerfile` in this repo returns nothing (no coupling added).

## Related

- runCrushInContainer `tasks/reference/nested-podman-vs-image-content.md` — the decision record.
- runCrushInContainer `tasks/archive/2026/09/13/decouple-full-toolchain-from-nested-podman.md` — the
  client-side implementation this paired with.
- Rescoped `tasks/minimal-image-for-nested-podman-standard.md` and
  `tasks/reference/minimal-nested-images.md`; parked `tasks/minimal-sandbox-image.md`.
