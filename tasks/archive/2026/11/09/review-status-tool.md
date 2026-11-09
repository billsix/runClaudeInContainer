# A derived status view for review records: `review_status.py`, `/review-status`, and the deep audit's "Carried over"

**Created:** 2026-11-09
**Completed:** 2026-11-09 (archive owed after the maintainer's work commit)
**Decisions** (William Emerison Six <billsix@gmail.com>, 2026-11-09):

1. Status is *derived*, not hand-maintained, and the review record stays frozen.
2. It is exposed both as a `/review-status` command and as a step in `/audit-repo deep` that seeds
   the next review's "Carried over" section.

## What was built

A `tasks/review/…` record is frozen, so on its own it could not say which findings had been dealt
with. Tasks made from it cite it in a `**Source:**` line. `tasks/reference/review_status.py` now
reads those lines and prints each section and follow-up of a record as **done** (every citing task
archived), **open** (a citing task in `tasks/`) or **untracked**.

- **The tool**, `tasks/reference/review_status.py`, is a shared tool beside the conventions doc,
  run in place from a project's repo root as `python3 ~/.claude/reference/review_status.py [record]
  [--carried-over]`. It is not vendored, so it lives in `tasks/reference/`, not the planned
  `tools/`. With no argument it uses the newest record. It has doctests (17) and is clean under
  ruff, ty and `check_local_annotations.py`.
- **Follow-up IDs.** Matching by section alone over-reports "done": a section holds several
  findings, and an archived task citing it does not prove that *this* bullet is done. The
  conventions now number follow-up bullets `[F1]`, `[F2]`, … across the record, and a task's
  `**Source:**` line carries the IDs it covers (`… repo-review.md §5.1 F7`). A bullet with an ID is
  matched only by ID. A bullet without one, as in records written before this convention, is
  matched by section and its status is marked "(by §)" as a lead to check.
- **Section rows** count their subsections' citations, so `§5` is open while a task citing `§5.2`
  is. Tasks that cite the record with neither a § nor an ID are listed separately.
- **The conventions** (`tasks/reference/repo-review-conventions.md`): the record layout requires IDs
  and §s on follow-ups, and "Lifecycle" now covers the `**Source:**` line format, the derived status,
  and seeding "Carried over" with `--carried-over`, then re-checking each row against the tree.
- **The commands:**
  - a new `entrypoint/dotfiles/.claude/commands/review-status.md`;
  - `audit-repo.md` deep step 2 runs the tool on the baseline, and step 5 asks for IDs;
  - `findings-to-tasks.md` always writes every § and the IDs into `**Source:**`;
  - the shared `CLAUDE.md` "Repo audits" lists `/review-status`;
  - this repo's `CLAUDE.md` names the tool among the shared `tasks/reference/` scripts.
- **The runCrushInContainer mirror:**
  - the tool and the conventions doc are byte-identical in `tasks/reference/` and the baked
    `client/entrypoint/dotfiles/.config/crush/reference/`;
  - the commands use `$RECORD` and `~/.config/crush` paths, with no frontmatter;
  - the Crush `CLAUDE.md` lists the command;
  - `tasks/reference/container-file-layout.md` (both copies) gained a `review_status.py` row, and
    its stale file counts were corrected to 11 commands and 25 reference files.

## Verification

- **On a synthetic repo** (three follow-ups with IDs, two of them sharing §1.1): one archived task
  citing F1, one open task citing F3, and one task with no §. The output was F1 done, F2 untracked
  (despite sharing §1.1 with F1), F3 open, §1 open, and the §-less task listed separately.
- **On github.com/billsix/geometricalgebra** `tasks/review/2026/11/08/repo-review.md` (no IDs, written
  before the convention): 38 follow-ups, 31 done, 0 open, 7 untracked, all 31 marked as matched by
  section only; 24 task citations, all archived.
  - The untracked seven are §5.2 check_annotations (handled in
    `tasks/annotation-auditor-floor-drift.md`, whose `**Source:**` does not cite the record), §8.3,
    §10.x, §3.6 and §6.4.
  - The by-§ "done" rows include items only adjacent to the work, such as §8.1 "pin the image's
    dependencies" and §9.1 "merge the proof-notebook tasks". These are why the IDs exist.
