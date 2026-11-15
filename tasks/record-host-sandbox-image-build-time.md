# Record the host build time of the sandbox image after the layer reorder

**Status:** blocked
**Blocked on:** the maintainer reporting how long `[HOST] time make image` took in runClaudeInContainer for the 2026-11-15 rebuild (or the next one).
**Recheck:** ask the maintainer for the number; cleared once one is reported.
**Priority:** 8
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/archive/2026/11/15/nested-native-overlay.md ("Verification", the items left to the maintainer)

## BLUF

The 2026-11-15 hygiene reorder changed the package layer's parent, so the first host rebuild re-ran that layer. No host timing has been recorded; the only full-build figure is the nested one (29m46s on a native store). Done means one host `make image` time is written into `tasks/reference/nested-run-and-gates.md` ("Storage speed") next to the nested figure. Optional: it informs expectations only, and nothing depends on it.

## Context

- The nested build time is in `tasks/archive/2026/11/15/nested-native-overlay.md` ("Verification").
- Note whether the timed build was a full rebuild or mostly cached; a cached rebuild says nothing about layer cost.
