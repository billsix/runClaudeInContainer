# Rewrite stale archive docs into done-records and repoint dangling paths and SHAs

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 6
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §10.1, §10.2, §10.3, §10.4, §2.2 F19 F11

## BLUF

About twelve archive docs predate the done-record rule and still carry Plan / Open questions scaffolding, one was archived as "proposed", four SHAs were squashed away, and many archive paths point at tasks that later moved. Done means each listed doc is a past-tense done-record and every path and SHA in the archive resolves.

## Context

- §10.1–§10.4 list each doc, SHA and path.
- The squashed SHAs (`9cbba23`, `eccac33`, `3606c06`, `1319adb`) map to `05a7ce0` / `6f1bed1`.

## Plan

1. Rewrite `2026/09/11/nested-podman-signal-inherited-doc-cleanup.md` first, then the §10.3 list.
2. Repoint the paths and SHAs; check each with `test -e` / `git cat-file -e`.
