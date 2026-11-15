# Fix /archive-task, /stack-pop and /stack-push to the documented lifecycle and stack layout

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 3
**Difficulty:** 2
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.16, §1.9, §1.17 F6 F18

## BLUF

`/archive-task` does the done-record rewrite, `git mv` and `git rm` in one run and never stages; the conventions require the rewrite with the work commit and the move in its own later commit. `/stack-pop` archives immediately, `/stack-push` writes an unsectioned stack, and two docs disagree with the shared `CLAUDE.md` about the stack and the session-end sweep. Done means the commands and docs match the shared `CLAUDE.md`.

## Context

- `entrypoint/dotfiles/.claude/commands/archive-task.md` steps 8–11; `commands/stack-pop.md:16-18`; `commands/stack-push.md:9-31`.
- `tasks/reference/task-doc-conventions.md:71-90` and the shared `CLAUDE.md` "Archiving" (three commits); `git-workflow-conventions.md:9-12` (staging is the agent's half).
- `diversion-stack-and-scope.md:110-114` (paused/deferred section) and `:77` (`/stack` order) against the shared `CLAUDE.md` and `commands/stack.md:13`; `reference-doc-conventions.md:208-256` lacks the stack-trim and token-waste steps.
- Other command mismatches (§1.17): `new-task.md:21` (`in-progress`/`Started`), `audit-repo.md:27-29` (quick mode names only the C checkers).

## Plan

1. `/archive-task`: phase 1 (harvest, done-record rewrite, stage) and phase 2 (only once the work commit is in HEAD: `git mv`, one-shot `git rm`, stage); never plain `mv`; stage by path.
2. `/stack-pop`: record the archive as owed unless the work commit exists.
3. `/stack-push`: push into "Active diversion chain".
4. Fix the diversion and reference-doc conventions docs, `new-task.md`, `audit-repo.md`.
