# Trimmed the shared CLAUDE.md where it restated its topic docs, and deduped three sections

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 5
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §3.1, §1.14 F16

## What this did

- `entrypoint/dotfiles/.claude/CLAUDE.md` (paid every turn): the "Archiving" paragraph and the
  session-end block were cut to their rules plus a pointer, from 11,928 to 11,504 words. Every
  rule stayed: archive at completion without asking, the done-record rewrite whether or not a
  squash follows, the three commits, never a plain `mv`, stage and stop until the work commit
  exists, the session-start scan; and, at session end, trim the stack, review token waste, run
  the CI gate. The detail that left (the stack's keep/delete lists and the 474 → ~30 example, the
  token-waste examples) moved into `tasks/reference/reference-doc-conventions.md`'s checklist
  (steps 8–9); the archiving detail was already in `task-doc-conventions.md`.
- Labels: the coding-standards heading names all six standards; `doctests-by-default.md` is titled
  "(Python, Rust and C++)".
- Duplicates: `cpp-build-modernization.md`'s blame-ignore and generated-files sections point at
  the canonical sections in `code-style-conventions.md` and `codegen-conventions.md`, keeping only
  their C++-specific examples. The `modernize-loop-convert` lesson stays in both
  `code-style-conventions.md` (general) and `cpp-ownership-migration.md` (the clang-tidy
  specifics), which already cross-link.

## Verification

Read the old and new Archiving and session-end text side by side: each rule in the old text
appears in the new text or, for detail, in the topic doc it points at.
