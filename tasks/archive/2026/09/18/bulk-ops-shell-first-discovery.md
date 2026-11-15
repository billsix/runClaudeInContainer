# Bulk operations: shell-first discovery → data-file worklog → iterate → verify

**Status:** complete
**Completed:** 2026-09-18
**Created:** 2026-09-18 (William Emerison Six <billsix@gmail.com>)

## What this did

Added a convention for bulk operations (find many instances, then fix each): the first move is a
shell discovery command (`rg -n` / `git grep -n` / `grep -Rn`) whose matches are logged to a
committed data file, then an iterate-and-fix pass, then a re-grep verification, instead of a
Python script that walks the tree. The motivation: one `rg` call returns just the hits, so the
agent (especially a local model with a small context window) does not spend context reading
files one by one. This is the shared cross-project layer, so it reached every project at the
next `make shell` with no image rebuild. runCrushInContainer carries the twin task
(`tasks/archive/2026/09/18/bulk-ops-shell-first-discovery.md` there).

## Decisions (William Emerison Six <billsix@gmail.com>, 2026-09-18)

1. **Data file location:** per-slug `tasks/adhoc/<slug>/data/`, removed with the script.
2. **The worklog is the point**, a list to iterate over; idempotency is a bonus, not required.
   Content/marker matching and bottom-up processing stay as correctness advice (a stale offset
   edits the wrong line), not as an idempotence mandate. The data file is a snapshot, never a
   line-number replay driver.
3. **Reference home:** this repo extended `tasks/reference/shell-and-gate-scripts.md`; runCrush
   was to get a focused doc of its own (it had no shell doc).
4. **Scope:** fleet-wide, confirmed intended.

## Tensions resolved in the text

- **"Skip one-liners" vs saving the discovery command:** a bulk discovery command whose output
  drove a committed diff is substantive, so `discover.sh` is saved (the existing "would the diff
  alone leave you wondering how I did this?" test).
- **Stale line numbers vs "reproduce its own diff":** the fix re-derives locations live by
  content or marker, following `tasks/reference/print-debugging.md`'s `DBG` marker precedent and
  the "cite by stable anchor, never a line number" rule.
- **The reproduce-the-diff proof applies to scripted codemods**, not to a hand-worked worklog,
  whose audit trail is `discover.sh` + the data file + the diff.
- **Lifecycle:** the data file rides the work commit with `discover.sh` and the fix script and is
  `git rm`'d with the slug dir at archive; a fix script promoted to `tools/` leaves its data file
  behind.

## What changed

1. `tasks/reference/task-doc-conventions.md`, "Ad-hoc scripts": the "Bulk operations" paragraph.
2. `entrypoint/dotfiles/.claude/CLAUDE.md`, "Ad-hoc scripts": the terse bulk-op rule and pointer.
3. `tasks/reference/shell-and-gate-scripts.md`: new section "Bulk find → log → iterate → fix",
   holding the command idioms researched for this task (rg/git grep output forms, NUL-safe
   filenames, bottom-up and content-matching edits, `sed -i` / `perl -0777 -pi` / `gawk -i
   inplace`, the `while IFS= read -r` loop, re-grep and count-diff verification, gotchas).
4. The CLAUDE.md reference-docs index: the `shell-and-gate-scripts.md` trigger gained "doing a
   bulk find-and-fix across many files".
