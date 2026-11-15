# Lean image for nested-podman builds of this sandbox: dropped

**Status:** dropped
**Completed:** 2026-11-15
**Created:** 2026-09-10 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §9.3 F7

## What happened

The task proposed a lean build of this sandbox's own image for nested builds. The maintainer
dropped it on 2026-09-12 (William Emerison Six <billsix@gmail.com>): the sandbox is built on the host, and coupling a lean self-build to
`NESTED_PODMAN` is the bug just removed from the runCrushInContainer client (typing
`make shell NESTED_PODMAN=1` would silently downgrade the image). A lean self-build would also
verify a different package set than the shipped image, which is false confidence, not a gate.
Decision record: github.com/billsix/runCrushInContainer `tasks/reference/nested-podman-vs-image-content.md`.
If in-sandbox verification of this Dockerfile is ever wanted, it needs an explicit
non-`NESTED_PODMAN` flag and a distinct image tag (never `claudecontainer`).

Archived on 2026-11-15; it had stayed in `tasks/` after being dropped.
