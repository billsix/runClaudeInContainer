# Convention: on "I'm going to squash", harvest the full decision history into the task doc first

**Status:** complete
**Completed:** 2026-09-03

## What this did

Added a standing convention next to "Quick-save commits, then squash to a per-task history" in
`entrypoint/dotfiles/.claude/CLAUDE.md`: before a squash, the agent walks every commit in
`<upstream>..HEAD` (the unpushed range; `<upstream>` from `git rev-parse --abbrev-ref @{u}`),
reads the task-doc and code diffs at each, and updates the task doc with a chronological record
of every decision: what changed, why, what was rejected and why, what each step discovered. After
the squash the per-commit trail is gone, so the archived task doc becomes the only record of the
reasoning. The agent does this unprompted as part of the squash.

## Decisions

- **Conventions layer, not the personal overlay:** it is a general working practice.
- **Placement (the maintainer, 2026-09-03):** both sandboxes' conventions files, this repo's
  `entrypoint/dotfiles/.claude/CLAUDE.md` and runCrushInContainer's
  `client/entrypoint/dotfiles/.config/crush/CLAUDE.md`, with the same wording trimmed to each
  file's density. Twin task: runCrushInContainer
  `tasks/archive/2026/09/03/squash-harvest-decision-history.md`.
- The harvest target during a squash is the task doc; the reference-doc harvest stays at
  archive time.

Superseded in part: the done-record rewrite was decoupled from squashing and made an archive-time
completion step 2026-11-02 (`tasks/reference/task-doc-conventions.md`, "The done-record
rewrite"); a squash now reuses it.
