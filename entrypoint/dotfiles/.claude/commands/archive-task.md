---
description: Move a completed task from tasks/<slug>.md to tasks/archive/<YYYY>/<MM>/<DD>/<slug>.md
argument-hint: <slug>
---

Archive a completed task in the current repo.

Slug: `$ARGUMENTS`

Steps:

1. Determine the repo root — prefer `git rev-parse --show-toplevel`, else current working directory.
2. **Port-check for legacy flat archives.** Look for any files directly under `tasks/archive/*.md` (depth 1 only — anything already nested in `<YYYY>/<MM>/<DD>/` is fine). For each one found:
   - Determine its archive date via `git log -1 --format=%ad --date=format:%Y/%m/%d -- <file>`.
   - If the file has no git history (untracked or never committed), fall back to its mtime (`date -r <file> +%Y/%m/%d`) and flag this as a fallback when surfacing it.
   - Show the user the full list (file → proposed destination, with fallback flags) and ask whether to port them. If yes, `git mv` each into `tasks/archive/<Y>/<M>/<D>/<slug>.md` (or plain `mv` if untracked), creating intermediate dirs as needed. If no, continue without porting — note that the prompt will recur next run, since there's no state to suppress it.
3. If `$ARGUMENTS` is empty, stop and ask me which task to archive. List the contents of `tasks/` (top level only, not `archive/`) so I can pick.
4. Verify `tasks/$ARGUMENTS.md` exists. If not, stop, list what's actually in `tasks/`, and ask me to pick the right slug.
5. Compute today's date as `<YYYY>/<MM>/<DD>` (zero-padded). Ensure `tasks/archive/<YYYY>/<MM>/<DD>/` exists; create it (with intermediate dirs) if missing.
6. If `tasks/archive/<YYYY>/<MM>/<DD>/$ARGUMENTS.md` already exists, stop and ask whether to overwrite or pick a different destination name.
7. Edit the file in place before moving: set `**Status:** complete` and add a `**Completed:** <today, YYYY-MM-DD>` line directly under it if not already present. Leave the rest of the content alone.
8. Move the file. If we're in a git repo, use `git mv`. Otherwise plain `mv`.
9. Confirm the destination path. Do not commit — leave staging to me.
