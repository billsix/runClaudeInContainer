# Date-bucketed archive layout for tasks/

**Status:** complete
**Completed:** 2026-06-02

## What this did

Replaced the flat `tasks/archive/<slug>.md` convention with a date-bucketed layout,
`tasks/archive/<YYYY>/<MM>/<DD>/<slug>.md`, so no single directory accumulates an
unmanageable number of entries.

- Updated `entrypoint/dotfiles/.claude/CLAUDE.md` to describe the layout.
- Updated `entrypoint/dotfiles/.claude/commands/archive-task.md` to write into the date
  hierarchy and to detect and offer to port legacy flat archives.
- Rebuilt the image (`make image`) so the dotfiles `COPY` carried the change; this matters
  only for containers run without the host `~/.claude` mount, since live sessions see the
  bind-mounted copy.
- Archived this task through `/archive-task`, which exercised the new path.

## Decisions

- **Bucket key = archive date**, not task-start date: no parsing of `**Started:**`, and it
  matches "I archived a bunch on day X, look there."
- **Zero-padded `YYYY/MM/DD`**, so lexicographic order is chronological.
- **Legacy migration lives in `/archive-task`**, not a separate `/port-archive` command. It
  re-prompts on every run until a repo is ported, because there is no persistent state to
  record a "no"; accepted since porting is a one-time action per repo.
- **Migration date source:** `git log -1 --format=%ad --date=format:%Y/%m/%d -- <file>`,
  falling back to mtime for untracked files (flagged as such).
- No `/new-task` change (it writes only under `tasks/`), and no automatic mass migration.
- A persistent opt-out of the port prompt (e.g. an `.archive-no-port` marker) was
  considered and not implemented.
