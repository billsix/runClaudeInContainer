# Resolve the C/C++ standards' else-after-return contradiction

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 4
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §4.3, §4.5 F12

## BLUF

The C and C++ standards list clang-tidy's `readability-else-after-return` as an authority while the Dispatch rule requires the `if`/`else if`/`else` return chains it flags. Drop it from tier (a) with a note saying why, the way the Python standard handles RET505/RET506 (maintainer decision 2026-11-15). Also brace the C example that breaks `readability-braces-around-statements`.

## Context

- `tasks/reference/c-coding-standard.md:48-49` and the Dispatch rule `:279-322`; `cpp-coding-standard.md:49`; `python-coding-standard.md:332` is the model.
- `c-coding-standard.md:137`: an unbraced `if`.
- Documentation only; no project's `.clang-tidy` changes.

## Plan

1. Remove `readability-else-after-return` from both tier-(a) lists; add the note.
2. Brace the example.
3. Re-copy both standards into runCrushInContainer in its batch.
