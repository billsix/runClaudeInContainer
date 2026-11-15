# Replace bare first-name stamps with Name <email>

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 5
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.11, §9.5 F15

## BLUF

The shared `CLAUDE.md` and many reference docs stamp decisions "(Bill, …)", against the shared rule that a stamp is `Name <email>` and prose uses a role. Done means no bare-name stamp remains outside the archive's historical text.

## Context

- §1.11 lists each site (shared `CLAUDE.md:629,638,647`; task-doc, reference-doc, git-workflow, diversion, llm-overused, python standard, nested-run, shell-and-gate docs).
- Archive docs are historical and stay.

## Plan

1. Replace stamps with `William Emerison Six <billsix@gmail.com>`; prose mentions with "the maintainer".
2. `git grep -n '\bBill\b' -- ':!tasks/archive'` = 0 stamps.
