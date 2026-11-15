# Index the orphan reference docs and define "upstream-only checkout" for forks

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 5
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.10, §1.12 F17

## BLUF

Three reference docs have no trigger entry or inbound link, and the shared commands rely on "upstream-only checkout", which only the maintainer's overlay defines. Done means each orphan is reachable and the fork template defines the term.

## Context

- Orphans: `lean-proof-methodology.md`, `makefile-feature-flag-guards.md`, `shell-exec-and-container-template.md`.
- Users: `commands/audit-repo.md:16`, `commands/findings-to-tasks.md:23`, `repo-review-conventions.md:100`; template: `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md`.

## Plan

1. Add trigger entries (or parent-doc links) for the three docs.
2. Add an "upstream-only checkouts" stub to the example overlay.
