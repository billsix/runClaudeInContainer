# Trim the always-loaded shared CLAUDE.md where it restates its topic docs

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 5
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §3.1, §1.14 F16

## BLUF

The shared `CLAUDE.md` (about 16K tokens, paid every turn) restates its topic docs at length in places, and three sections are duplicated across reference docs. Cut those to rule + pointer and dedupe. Done means the rules are unchanged and the file is shorter.

## Context

- §3.1: "Archiving" (`:527-547`) restates `task-doc-conventions.md:57-104`; the session-end block (`:647-682`) is about 35 lines.
- §1.14: the heading "Python, C++, and C" (six standards exist); `doctests-by-default.md` title; three duplicated sections (`.git-blame-ignore-revs`, "Generated files", `modernize-loop-convert`).

## Plan

1. Cut the two sections to the rule plus a pointer, moving any unique detail into the topic doc.
2. Fix the labels; keep one copy of each duplicated section and point at it.
3. Diff the rule set before and after: nothing dropped.
