# Indexed the orphan reference docs and defined "upstream-only checkout" for forks

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 5
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.10, §1.12 F17

## What this did

- The shared `CLAUDE.md`'s read-on-demand index gained trigger entries for the three reference docs
  nothing linked to: `makefile-feature-flag-guards.md`, `shell-exec-and-container-template.md` and
  `lean-proof-methodology.md`.
- The fork template `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md` gained an
  "Upstream-only checkouts (read-only)" section, so a fork's overlay defines the term the shared
  commands (`/audit-repo`, `/findings-to-tasks`, `/spell-out-names`) and
  `repo-review-conventions.md` rely on.

## Verification

`git grep -l <doc name> -- ':!tasks/archive'` now finds each of the three docs cited from the shared
`CLAUDE.md`.
