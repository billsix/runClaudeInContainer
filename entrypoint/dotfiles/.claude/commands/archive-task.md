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
7. **Harvest durable knowledge into a reference doc, and reconcile existing ones** (per the "Reference documents" convention in `~/.claude/CLAUDE.md` — reference docs are an expanded, agent-facing `CLAUDE.md`, and archiving otherwise buries decisions in a don't-trawl bucket). Read the task's content and decide:
   - Does it hold **durable decisions / rationale / rejected alternatives / how-it-actually-works** that outlive the work? If so, **extract that into `tasks/reference/<topic>.md`** (create it, or update an existing reference doc it belongs to), **slim the task to a lean work record that points to the reference**, and cross-link both. Keep the *work log* (what was done, which gates passed) in the task.
   - Independently, **double-check the other `tasks/reference/*` docs** (and, if relevant, `CLAUDE.md` / `README.md`): does completing this task make any of them **stale** (a claim no longer true) or **incomplete** (a decision/subsystem now missing)? Update as appropriate.
   - Surface what you extracted/updated, concisely. If the task is purely mechanical with nothing durable to harvest and nothing to reconcile, say so and skip.
8. Edit the file in place before moving: set `**Status:** complete` and add a `**Completed:** <today, YYYY-MM-DD>` line directly under it if not already present. Leave the rest of the content alone.
9. Move the file. If we're in a git repo, use `git mv`. Otherwise plain `mv`.
10. Confirm the destination path (and any reference-doc created/updated in step 7). Do not commit — leave staging to me.
