# Make the shared checkers fail loudly, and fix their own bugs

**Status:** in progress
**Priority:** 2
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §4.1, §4.2, §5.1, §5.2, §5.3, §5.4, §6.1 F3 F8 F9

## BLUF

Three shared gates can pass while checking nothing, and two shared tools have bugs. Fix them in
the canonical copies here and re-copy them byte-identically into runCrushInContainer. Done means
each tool exits 2 on "nothing matched" and on setup errors, the listed bugs have doctests that
would have caught them, and the tools pass ruff, ty and `check_local_annotations.py` on
themselves.

## Context

- `tasks/reference/check_local_annotations.py`: exits 0 on a missing path or when no `.py`
  file matches (§5.1); fails its own annotate-every-binding rule, ruff (EXE001, PERF402) and
  `ruff format` (§4.1); crashes with `ValueError` on a file outside the repo root (§4.2).
- `tasks/reference/c_designated_init_check.py`: exits 0 when no translation unit matches; one
  unparseable file raises `CalledProcessError` and exits 1, which reads as "sites found" (§5.2).
- `tasks/reference/c_dispatch_check.py`: a missing `compile_commands.json` or `clang` exits 1 with
  a traceback instead of 2 (§5.3).
- `tasks/reference/review_status.py`: `latest_record` would pick `tasks/review/README.md`;
  `citations` credits one record with another record's §refs; the tier regex misses multi-word
  tiers (§5.4).
- The vendored copies in downstream projects (spimulator, methodfinder, …) are re-copied by a
  follow-up task, since they live in other repos.

## Plan

1. Fix each tool; add doctests for each failure path.
2. Run ruff, `ruff format --check`, ty, and `check_local_annotations.py --include-module` on all
   four; exercise each fix on a scratch input.
3. Re-copy all four into runCrushInContainer (`tasks/reference/` and the baked
   `client/entrypoint/dotfiles/.config/crush/reference/` where present) in the runCrush batch.
4. Scaffold the follow-up task for the downstream vendored copies.
