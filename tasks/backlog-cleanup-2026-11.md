# Clean up the open-task backlog the review found stale

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 3
**Difficulty:** 2
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §9.1, §9.2, §9.3, §9.4, §9.5 F7

## BLUF

Several open tasks are done, dropped, overlapping or built on an overturned premise. Done means each is archived, rewritten or cross-linked so the backlog reads true.

## Context

- `tasks/minimal-image-for-nested-podman-standard.md` rolls out the old `NESTED_PODMAN`-keyed idiom (now `MINIMAL_IMAGE`).
- `tasks/container-cmd-podman-docker-fallback.md`: rollout done 2026-09-03; leftovers are the personal overlay's `CONTAINER_CMD = podman` invariant and new-project scaffolding.
- `tasks/minimal-sandbox-image.md` (dropped) and `tasks/adhoc-scripts-repo-relative-paths.md` (resolved) should be archived.
- `tasks/default-allow-file-rw-in-sandbox.md` and `tasks/suppress-claude-session-trailer.md` share the settings-placement question; `tasks/emacs-contract-conformance.md` and `tasks/verify-emacs-config-build-flag.md` should cross-link.
- §9.5: missing BLUF/Context in three tasks, a bare "Bill" stamp, the deleted regardingBritt, an odd date, an elided archive path, no `.keep` under `tasks/`.

## Plan

1. Rewrite `minimal-image-for-nested-podman-standard` around `MINIMAL_IMAGE` (or close it if nothing is left).
2. `container-cmd-podman-docker-fallback`: fix the Status, update the overlay contract line (dotfiles), and archive what is done.
3. Archive `minimal-sandbox-image` and `adhoc-scripts-repo-relative-paths`.
4. Make the settings task depend on the trailer task's layering decision; cross-link the emacs tasks.
5. The §9.5 header fixes and `.keep` files.
