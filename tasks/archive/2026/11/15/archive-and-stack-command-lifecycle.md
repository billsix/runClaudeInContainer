# Fixed /archive-task, /stack-pop and /stack-push to the documented lifecycle and stack layout

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 3
**Difficulty:** 2
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.16, §1.9, §1.17 F6 F18

## What this did

The commands and two convention docs disagreed with the shared `CLAUDE.md`. Changed, in
`entrypoint/dotfiles/.claude/commands/` and `tasks/reference/`:

- `archive-task.md`: step 8 stages the done-record rewrite with the work (commit 2); step 9 moves
  the file only once the work commit exists, otherwise records the move as owed, and never uses
  a plain `mv` in a git repo; step 11 stages by path (it said "do not commit — leave staging to
  me", against "staging is the agent's half").
- `stack-pop.md`: closes the task doc without archiving early; an owed move is recorded in the
  task's Status and the stack's "Owed to the maintainer" section.
- `stack-push.md`: creates the sectioned stack and pushes into "Active diversion chain".
- `new-task.md`: new tasks start `proposed — needs go-ahead` with a `Created:` stamp in
  `Name <email>` form (it used `in-progress` / `Started:`).
- `audit-repo.md`: quick mode names `check_local_annotations.py` alongside the C checkers.
- `diversion-stack-and-scope.md`: `/stack` shows the trail root first; a stale thread is parked
  in a task doc, not a paused section of the stack.
- `reference-doc-conventions.md`: the session-end checklist gains the stack-trim and token-waste
  steps the shared `CLAUDE.md` requires.

## Verification

Read each changed step against the shared `CLAUDE.md` "Task documents" / "Archiving",
`task-doc-conventions.md` (three-commit lifecycle), `git-workflow-conventions.md` (staging) and
"Ending a session". runCrushInContainer mirrors the command changes in its own batch
(`tasks/command-lifecycle-mirror.md` there).
