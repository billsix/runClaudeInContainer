# Fix the stale and contradictory infra docs

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 3
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.2, §1.3, §1.4, §1.5, §1.6, §1.7, §1.13, §1.14, §1.15, §2.1, §2.2, §2.3, §2.5, §8.5 F10 F11 F21

## BLUF

Many docs describe the build, mounts and nested podman as they were months ago, contradict each other on `:Z`, or point at tasks that were archived. Done means each listed claim matches the tree and every in-repo pointer resolves.

## Context

- Record §1.2–§1.7 and §2.1–§2.5 list each claim with its file and line; §1.13–§1.15 and §8.5 the smaller ones.
- Maintainer decision: "never `:Z`" for host trees (the Makefile side is in `tasks/dockerfile-and-makefile-hygiene.md`).
- The nested-storage rewrite itself is in `tasks/nested-native-overlay.md`; this task fixes the rest.

## Plan

1. Work through §1.2–§1.7, §2.1–§2.5, §1.13–§1.15, §8.5, fixing each claim.
2. Re-grep for each stale string ("~430", "Fedora 44", "only if it exists", the bare-`rm` sweep, dangling `tasks/*.md` pointers) to confirm zero.
