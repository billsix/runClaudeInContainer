# Date-bucketed archive layout for tasks/

**Status:** in-progress
**Started:** 2026-06-02

## Goal

Replace the flat `tasks/archive/<slug>.md` convention with a date-bucketed layout (`tasks/archive/<year>/<month>/<day>/<slug>.md`) so no single directory accumulates an unmanageable number of entries. Update the archive-task skill and the global CLAUDE.md to describe the new structure, and decide what date to bucket by (archive date vs. task-start date).

## Plan

- [x] Decide bucketing key: archive date (today), zero-padded `YYYY/MM/DD`.
- [x] Update `entrypoint/dotfiles/.claude/CLAUDE.md` to describe the new layout.
- [x] Update `entrypoint/dotfiles/.claude/commands/archive-task.md` to write into the date hierarchy and to detect/offer to port legacy flat archives.
- [ ] Rebuild the container image (`make image`) so the COPY of dotfiles into the image picks up the changes — note that the bind mounts already cover live sessions; rebuild only matters for fresh containers without the host `~/.claude` mount.
- [ ] Commit the changes.
- [ ] Once stable, archive this task via `/archive-task organize-archived-tasks` (which will exercise the new path).

## Notes / decisions

- **Bucket key = archive date**, not task-start date. Simpler, no parsing of `**Started:**` from the doc, matches the natural mental model of "I archived a bunch on day X, look there."
- **Zero-padded `YYYY/MM/DD`** so lexicographic sort matches chronological order.
- **Legacy migration is baked into `/archive-task`** rather than a separate `/port-archive` command. Tradeoff: it re-prompts on every run until ported, since there's no persistent state to record a "user said no" answer. Accepted because porting is meant to be a one-time action per repo.
- **Migration date source:** `git log -1 --format=%ad --date=format:%Y/%m/%d -- <file>` (last time the file was touched in git). Fallback to mtime for untracked files, flagged as such when surfaced.
- **No `/new-task` change** — that command only writes under `tasks/`, not `tasks/archive/`.
- **No automatic mass migration** at session start or globally — only when the user runs `/archive-task` in a repo that has legacy files.

## Open questions

- Does the rebuild matter in practice? In typical use the host's `~/.claude` is bind-mounted, so live edits flow back regardless. The `COPY entrypoint/dotfiles/ /root/` line in the Dockerfile only matters for containers run without the host mount.
- Should there be a way to opt out of the port-prompt persistently (e.g., a `.archive-no-port` marker file)? Not implementing now; revisit if the re-prompt becomes annoying.
