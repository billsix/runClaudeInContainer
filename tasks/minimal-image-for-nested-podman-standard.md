# Lean-image-when-nested standard: superseded by the opt-in MINIMAL_IMAGE flag

**Status:** superseded — closed 2026-11-15
**Completed:** 2026-11-15
**Priority:** 3
**Difficulty:** 3
**Created:** 2026-09-10 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §9.1 F7

## What happened

This task (2026-09-10) proposed making every downstream project's optional-feature build flags
default to lean when `NESTED_PODMAN=1` (`FLAG ?= $(if $(filter 1,$(NESTED_PODMAN)),0,1)`), and was
re-scoped on 2026-09-12 to exclude the two sandboxes. On 2026-09-27 the idea was replaced: image
content keys off a separate opt-in flag, `MINIMAL_IMAGE`, and `NESTED_PODMAN` is run capability
only (`tasks/archive/2026/09/27/decouple-minimal-image-from-nested-podman.md`;
`tasks/reference/minimal-nested-images.md`). A nested `make image` builds the full image.

Closed rather than rewritten, because its goal is met in the new form:
- The rule is in the shared `CLAUDE.md` ("Running projects in a nested container") and the
  personal overlay's feature-flag section (the `MINIMAL_IMAGE` idiom).
- A sweep on 2026-11-15 of every `Makefile` under `/mnt/sda1` (excluding the sandboxes and
  upstream clones) found the `NESTED_PODMAN`-keyed idiom nowhere, and `MINIMAL_IMAGE` in
  duckgamevst, epix-mirror, geometricalgebra, hanoi (root, `cpp/`, `python/`, `rust/`),
  modelviewprojection and spimulator.
