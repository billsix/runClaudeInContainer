# Replaced bare first-name stamps with Name <email>

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 5
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.11, §9.5 F15

## What this did

Every `(Bill, <date>…)` stamp outside the archive became `(William Emerison Six
<billsix@gmail.com>, <date>…)`, and the prose mentions ("Bill flagged it", "Bill isn't",
"Bill's seed example", "Get Bill's decision") became "the maintainer". Files: the shared
`entrypoint/dotfiles/.claude/CLAUDE.md` (three section headings), `tasks/reference/`
`diversion-stack-and-scope.md`, `git-workflow-conventions.md`, `llm-overused-phrases.md`,
`nested-run-and-gates.md`, `python-coding-standard.md`, `reference-doc-conventions.md`,
`shell-and-gate-scripts.md`, `task-doc-conventions.md`, and the open task
`tasks/standardize-project-container-template.md`.

Kept: the two quoted examples in the shared `CLAUDE.md` rule itself ("who do not know who
\"Bill\" is", "littered … with bare \"Bill\""), and the archive's historical stamps.

## Verification

`git grep -n -E '\bBill\b' -- ':!tasks/archive' ':!tasks/review'` lists only the rule's two quoted
examples (and this batch's own task text describing the finding).
