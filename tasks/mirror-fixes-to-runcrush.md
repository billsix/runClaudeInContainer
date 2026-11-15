# Re-copy the drifted mirrors into runCrushInContainer

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 4
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.8 F14

## BLUF

Files whose banners claim byte-identity with runCrushInContainer have drifted. Re-copy them (and this batch's fixed shared files) so `cmp` is clean. The work lands in runCrushInContainer's own batch branch.

## Context

- §1.8: `token-and-context-economy.md`, the runCrush client's baked `recursive-design.md` and `rust-coding-standard.md`.
- The runCrush record (its `tasks/review/2026/11/15/repo-review.md` §0.4) found more; its tasks cover them.

## Plan

1. In runCrushInContainer, re-copy each drifted file from here.
2. `cmp` every claimed mirror; zero differences.
