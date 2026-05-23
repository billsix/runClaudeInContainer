# Cross-project conventions

## Task documents

For non-trivial work — multi-step features, refactors, investigations, anything worth resuming in a later session — keep a spec/notes doc at `tasks/<short-kebab-slug>.md` in the **repo root** of whichever project is currently mounted. One file per task. Update it as work progresses (status, decisions, open questions).

When a task is complete, **move** the file to `tasks/archive/<slug>.md` rather than deleting it. The history is useful.

At the start of a session in a project, check `tasks/` (top-level, **not** `tasks/archive/`) for in-flight work and surface what's there so we can pick up where we left off. Don't trawl `tasks/archive/` unless I ask about prior work.

Don't create a task file for one-off questions, trivial edits, or anything resolvable in a single response. Task files are for work that spans turns or sessions.

If `tasks/` doesn't exist in a repo yet, create it the first time it's needed. By default these docs are committable — only add `tasks/` to `.gitignore` if I explicitly ask.

Helper commands: `/new-task <slug>` to scaffold, `/archive-task <slug>` to archive.
