# Rewrote stale archive docs into done-records and repointed dangling paths and SHAs

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 6
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §10.1, §10.2, §10.3, §10.4, §2.2 F19 F11

## What this did

Done by a delegated agent (edits only, under `tasks/archive/`), reviewed and committed here.

- **Done-records (15 docs):** `2026/09/11/nested-podman-signal-inherited-doc-cleanup.md` (archived
  as "proposed"; the work was commit `04a2267`), and `06/02/organize-archived-tasks`,
  `07/29/llm-overused-phrases`, `08/13/extract-dockerfile-steps-into-host-scripts`,
  `08/29/nested-podman-run-flags-passthrough`, `08/29/fan-out-shell-exec-to-projects`,
  `08/31/doc-deltas-ship-with-staged-work`, `09/03/squash-harvest-decision-history`,
  `09/10/vim-user-toolkit-in-base-image`, `09/14/trim-claude-md`,
  `09/18/bulk-ops-shell-first-discovery`, `09/18/fix-rollout-py-fleet-root-arg`,
  `10/01/dockerfile-cache-mount-fleet-audit`, `10/15/c-coding-standard`, `11/09/review-status-tool`.
  Each is `Status: complete` with a `Completed:` date, one past-tense voice, no Plan / Open
  questions / unchecked boxes; superseded decisions carry a "Superseded:" line (FULL_TOOLCHAIN,
  tmpfs store, `NESTED_PODMAN`-keyed lean images, read-every-session references, fuse-overlayfs).
  Work never done is stated as not done (the vim task's host `make image` check: no result
  recorded).
- **SHAs:** in `2026/11/13/nested-podman-host-image-store-ignored.md`, `9cbba23`, `eccac33` and
  `3606c06` → `05a7ce0` ("nested storage works"), `1319adb` → `6f1bed1` ("archived").
- **Paths:** 11 stale in-repo references in 6 archive docs repointed to the files' current homes.

## Verification

Every hex string in `tasks/archive/` resolves with `git cat-file -e` except `6355242` (impo) and
`7e2eb03` (spimulator), which resolve in those repos. A grep of the 15 rewritten docs for
`## Plan`, `## Open questions`, `## BLUF`, `- [ ]` and `Status: proposed|in progress` finds none.
Five docs touched only for a path (`08/13/print-debugging-guidance-multilang`,
`08/13/sphinx-human-readable-reference-docs`, `09/13/scope-lean-image-to-downstream-not-sandboxes`,
`09/27/dir-backed-nested-podman-storage`, `10/15/cpp-coding-standard`) still carry scaffolding
headings; they were not in the review's list and were left.
