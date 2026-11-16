# A review record should show which findings were handled, by which task, and in which commit

**Status:** proposed — needs go-ahead (exploration first; the option is the maintainer's decision)
**Priority:** 4
**Difficulty:** 4
**Created:** 2026-11-16 (William Emerison Six <billsix@gmail.com>)
**Touches:** this repo (the conventions, the commands, `review_status.py`), and
github.com/billsix/runCrushInContainer through its mirror task `tasks/review-record-shows-dispositions.md`

## BLUF

The maintainer (2026-11-16): "if I'm looking at a review, and I know some findings were created
from it, it's not clear to me by looking at the review what was handled and fixed, and in what
commit." Their first idea: when findings become tasks, one of the last items on each task is to
update the review with the task's path and its status. This task explores that idea and the
alternatives, then implements the one the maintainer picks across the conventions doc, the
commands and the tool. Done means that someone reading a review can tell, for each finding,
whether it was handled, by which task, and in which commit.

## Context

### What exists (2026-11-16)

- **`tasks/reference/repo-review-conventions.md` ("Lifecycle")** has three relevant rules:
  - *"Never edit a record after it is written"*, with two dated-note exceptions: correcting the
    reviewer's own error, and answering an open question;
  - a task made from a record cites it in one `**Source:**` line (path, §s, follow-up IDs such as
    `F7`);
  - *"Status is derived, never written into the record."*
- **`tasks/reference/review_status.py`** (run as `/review-status [record]`, and seeded into the
  next review's "Carried over" by `/audit-repo deep`) reads the `**Source:**` lines in `tasks/` and
  `tasks/archive/`. It prints each section and follow-up as **done** (every citing task archived),
  **open** or **untracked**. It names neither the task paths nor any commit.
- **Why it is derived:** decision 1 of `tasks/archive/2026/11/09/review-status-tool.md`
  (William Emerison Six <billsix@gmail.com>, 2026-11-09): status is derived, not hand-maintained,
  and the record stays frozen, so that it remains an exact baseline for the next review to diff
  against.
- **The gap, as the maintainer sees it:** the record is what they read, in Emacs or on GitHub, and
  it says nothing about what happened afterwards. The status view exists only when someone runs a
  command. Nothing anywhere links a finding to the commit that fixed it.
- **Commands involved:** `entrypoint/dotfiles/.claude/commands/findings-to-tasks.md` (writes the
  tasks and their `**Source:**` line), `archive-task.md` (where a task's last steps happen),
  `review-status.md`, and `audit-repo.md`.
- **Commit SHAs rot:** the maintainer sometimes squashes history (`CLAUDE.md`, "A commit SHA is
  such an artifact"). A SHA written down at archive time can stop resolving later.
- **Records that exist now:** this repo's `tasks/review/2026/11/15/repo-review.md`, runCrush's
  `tasks/review/2026/11/15/repo-review.md`, and github.com/billsix/geometricalgebra's
  `tasks/review/2026/11/08/repo-review.md`, the one with the most tasks made from it, which makes
  it the best test case.

### Options to explore (grouping mine; refine during the exploration)

- **(A) The task writes back into the record (the maintainer's first idea).** The archive step adds
  a line under the finding or follow-up: task path, status, commit.
  - *For:* the answer is exactly where the reader looks.
  - *Against:* it reverses the frozen-record rule. The baseline then mixes what was found with what
    was done later. Every archive edits a shared file, which risks merge conflicts between task
    branches. A written status rots if a task is later dropped or reopened.
  - A softer form keeps the findings' text untouched and allows only appended, dated "Disposition"
    lines. That would be a third exception to "never edit", like the existing two.
- **(B) A hand-maintained sidecar next to the record** (`repo-review.dispositions.md`), which each
  task updates at archive. The record stays frozen, but the reader opens two files, and the sidecar
  is still hand-maintained.
- **(C) A generated sidecar.** `review_status.py --write` regenerates `repo-review.status.md`, a
  table per section and follow-up showing status, citing task path(s), and commit(s). It runs at
  archive time (an `archive-task` step) and in the session-end sweep, and is committed, so it shows
  on GitHub next to the record.
  - Commits can be **derived from git** instead of written down: the commit that added the archived
    task (`git log --diff-filter=A --format=%h -- tasks/archive/…/<slug>.md`) plus the commits
    before it that touched the task. That avoids the squash-rot problem as long as the file is
    regenerated after a squash.
- **(D) An annotated view, never stored.** `review_status.py --annotate` prints (or publishes as a
  page) the record with each finding's status, tasks and commits inline. Nothing in git goes
  stale, but the reader has to run something.
- **(E) Combinations,** such as (C) with a one-line pointer at the top of the record ("dispositions:
  `repo-review.status.md`, regenerated by `/review-status --write`"). The pointer is a fixed,
  dated note, like the existing exceptions, so the record otherwise stays frozen.

### Questions the exploration should answer (for the reference doc)

- Which option makes "look at the review, see what was handled" true with the least
  hand-maintenance and the least risk to the baseline?
- How is a finding's commit found reliably? Write it at archive, or derive it from git each time?
  What happens after a squash?
- What does the next review's "Carried over" section read from, after the change?
- What happens to the records that already exist? Backfill, or start with the next review?

## Plan (draft)

1. Prototype the options on github.com/billsix/geometricalgebra's 2026-11-08 record, the one with
   the most tasks. Produce, without committing, what (A), (C) and (D) would each look like for
   three of its findings, including the commit lookup from git.
2. Present the prototypes and a recommendation to the maintainer. Wait for the decision.
3. Implement the decision:
   - `repo-review-conventions.md` ("Lifecycle", and "The record's layout" if the record changes);
   - `review_status.py`, with doctests and clean ruff, ty and `check_local_annotations.py`;
   - `findings-to-tasks.md`, so each generated task carries the closing step if (A) or (B) is
     chosen;
   - `archive-task.md`, so archiving updates the record or sidecar, or regenerates it;
   - `review-status.md` and `audit-repo.md`;
   - the `CLAUDE.md` "Repo audits" section.
4. Apply it to the existing records if the decision says to backfill.
5. Hand the mirror work to runCrushInContainer's `tasks/review-record-shows-dispositions.md`.

## Open questions

1. **Which option:** (A), the record updated by each task's last step, as you first suggested; (C),
   a generated, committed status file beside the record; (D), a view only; or a combination?
   *(Leaning, before prototyping: (C) plus a one-line pointer in the record, with commits derived
   from git. It shows on GitHub next to the record and keeps the record an exact baseline. Answer
   after seeing the prototypes, if you prefer.)*
2. **Backfill:** apply the chosen form to the three existing records, or start with the next
   review? *(Recommend backfilling geometricalgebra's 2026-11-08 record at least, since that's
   where you hit the problem.)*
