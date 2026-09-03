# Convention: on "I'm going to squash", harvest the full decision history into the task doc first

**Status:** proposed — needs go-ahead (placement settled: both nested CLAUDE.md; wording only)
**Priority:** 3
**Difficulty:** 2

## BLUF

Add a standing convention: **when the maintainer says they're about to squash**, the agent first walks **every
commit from the remote-tracked branch tip to HEAD** (the unpushed range), reads both the **task-doc changes** and
the **code changes** across them, and **updates the task doc with a chronological record** of every decision made
— what changed, why, what was rejected and why. Then the squash can collapse the commits, and the *task doc*
still carries the play-by-play. The point: after squashing, the granular history is gone from git, but the
archived task doc preserves "everything that happened and why" for whoever reads it later. "Done" = the
convention is written into the chosen conventions file, next to the existing squash convention.

## Context

- Where the related conventions already live (shared `entrypoint/dotfiles/.claude/CLAUDE.md`):
  **"Quick-save commits, then squash to a per-task history"** (~line 586) — the *mechanics* of squashing; and
  **"Task documents"** (~line 601) — task docs must be cold-readable, decisions recorded **with rationale**. This
  new rule is the bridge: it makes squashing *feed* the task doc's decision record before the granular commits
  are collapsed.
- This is a **general working practice** (not maintainer identity / URLs / standing authorizations), so it
  belongs in the conventions layer, not the personal overlay.
- **Placement decided (maintainer, 2026-09-03): the nested conventions CLAUDE.md of BOTH sandboxes** — this repo's
  `entrypoint/dotfiles/.claude/CLAUDE.md` AND runCrushInContainer's
  `client/entrypoint/dotfiles/.config/crush/CLAUDE.md`. The runCrush copy of this task is
  `runCrushInContainer/tasks/squash-harvest-decision-history.md`; keep the wording in sync.

## The convention to add (draft wording)

> **Before a squash, harvest the commit history into the task doc.** When I say I'm going to squash: walk every
> commit in `<upstream>..HEAD` (the unpushed range — find `<upstream>` with `git rev-parse --abbrev-ref
> @{u}` / the remote-tracked branch), and read the task-doc AND code diffs at each. Then update the task doc so it
> records, in order, every decision we made and **why** — what changed, what we rejected and why, what each step
> discovered. The squash then collapses the commits; the task doc keeps the chronological account. This matters
> because after the squash the per-commit trail is gone — the archived task doc becomes the only record of the
> reasoning, so it must carry it before the history is flattened. (Do this as part of the squash, unprompted,
> the same way staging is automatic.)

## Open questions

1. **Wording** — use the draft above (kept identical in both repos' nested CLAUDE.md), or adjust per each file's
   density? *Recommend the same wording in both, trimmed to match.* Harvest target = the task doc during squash;
   the reference-doc harvest stays at archive time (per the existing "harvest to reference docs" rule). (Placement
   is settled — both nested CLAUDE.md files; see Context.)
