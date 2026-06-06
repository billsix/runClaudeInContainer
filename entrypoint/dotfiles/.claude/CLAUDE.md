# Cross-project conventions

## Confirm before acting

When I ask you to **list, identify, find, plan, or investigate** something, that's a request for the information — **not** authorization to make changes. Produce the list / plan / findings and **stop**. Wait for my explicit go-ahead ("do it", "apply them", "go ahead") before editing files or running mutating commands. When a request is ambiguous between "tell me" and "do it," treat it as "tell me" and ask.

## Task documents

For non-trivial work — multi-step features, refactors, investigations, anything worth resuming in a later session — keep a spec/notes doc at `tasks/<short-kebab-slug>.md` in the **repo root** of whichever project is currently mounted. One file per task. Update it as work progresses (status, decisions, open questions).

When a task is complete, **move** the file to `tasks/archive/<YYYY>/<MM>/<DD>/<slug>.md` (zero-padded, based on the archive date) rather than deleting it. The date-bucketed layout keeps any one directory from accumulating too many entries. The history is useful.

Older flat archives (`tasks/archive/<slug>.md`) from before this convention are not migrated automatically; the `/archive-task` command will detect them on each run and offer to port them into the date hierarchy using the file's last-touched date from git history.

At the start of a session in a project, check `tasks/` (top-level, **not** `tasks/archive/`) for in-flight work and surface what's there so we can pick up where we left off. Don't trawl `tasks/archive/` unless I ask about prior work.

Don't create a task file for one-off questions, trivial edits, or anything resolvable in a single response. Task files are for work that spans turns or sessions.

If `tasks/` doesn't exist in a repo yet, create it the first time it's needed. By default these docs are committable — only add `tasks/` to `.gitignore` if I explicitly ask.

Helper commands: `/new-task <slug>` to scaffold, `/archive-task <slug>` to archive.

## Repo audits

For getting (re)acquainted with a project, or checking whether its docs still match its code:

- `/audit-repo` — full read of the current repo, cross-referencing the docs (CLAUDE.md, README, task docs) against the actual source to surface stale claims, undocumented features, and internal inconsistencies. **Read-only** — it reports findings and stops.
- `/findings-to-tasks` — turn those findings (or any list of discussion items) into in-depth task docs under `tasks/`, one per item, each `proposed — needs go-ahead`.

## Multi-repo sessions

This container often has more than one repo bind-mounted at top-level paths like `/foo`, `/bar`. Claude Code only auto-loads the `CLAUDE.md` of the current working directory's repo, so to be aware of the others:

At session start, scan top-level directories at `/`. A directory is a project mount if it contains either `.git/` or `CLAUDE.md`. Skip these system paths: `/bin`, `/boot`, `/dev`, `/etc`, `/home`, `/lib`, `/lib64`, `/media`, `/mnt`, `/opt`, `/proc`, `/root`, `/run`, `/sbin`, `/srv`, `/sys`, `/tmp`, `/usr`, `/var`.

For each mount found, read its `CLAUDE.md` if present and apply those rules when working in that repo. Also check each for in-flight items under `tasks/` (per the convention above). Don't announce the scan unless I ask — just internalize each repo's conventions so you behave correctly when I reference paths in any of them.

If a `CLAUDE.md` in one repo contradicts the rules here or in another mounted repo, the repo-local file wins **for work inside that repo only**.
