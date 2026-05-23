---
description: Move a completed task from tasks/<slug>.md to tasks/archive/<slug>.md
argument-hint: <slug>
---

Archive a completed task in the current repo.

Slug: `$ARGUMENTS`

Steps:

1. Determine the repo root — prefer `git rev-parse --show-toplevel`, else current working directory.
2. If `$ARGUMENTS` is empty, stop and ask me which task to archive. List the contents of `tasks/` (top level only, not `archive/`) so I can pick.
3. Verify `tasks/$ARGUMENTS.md` exists. If not, stop, list what's actually in `tasks/`, and ask me to pick the right slug.
4. Ensure `tasks/archive/` exists; create it if missing.
5. If `tasks/archive/$ARGUMENTS.md` already exists, stop and ask whether to overwrite or pick a different destination name.
6. Edit the file in place before moving: set `**Status:** complete` and add a `**Completed:** <today, YYYY-MM-DD>` line directly under it if not already present. Leave the rest of the content alone.
7. Move the file. If we're in a git repo, use `git mv`. Otherwise plain `mv`.
8. Confirm the destination path. Do not commit — leave staging to me.
