# Made the shared checkers fail loudly, and fixed their own bugs

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 2
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §4.1, §4.2, §5.1, §5.2, §5.3, §5.4, §6.1 F3 F8 F9

## What this did

Three shared gates could pass while checking nothing, and two shared tools had bugs. All four
canonical copies in `tasks/reference/` were fixed:

- `check_local_annotations.py`: `iter_py` raises `FileNotFoundError` on a missing path, and `main`
  exits 2 on that or when no `.py` file matches (it exited 0). `display_path` prints a file outside
  the repo root as given (it raised `ValueError`). Every binding is annotated, the functions have
  Google docstrings, the two PERF402 loops use `extend`, the file is executable and
  ruff-formatted, the docstring's usage and exit statuses are current, and the rule's origin is
  cited by repo URL.
- `c_designated_init_check.py`: exits 2 when a source path does not exist, `clang` is missing, the
  compile database is missing or empty, or a translation unit cannot be parsed (it exited 0, or
  aborted with a `CalledProcessError` traceback and exit 1). An unparseable file is reported on
  stderr and the rest are still checked.
- `c_dispatch_check.py`: exits 2 with a message when the compile database or `clang` is missing
  (it exited 1 with a traceback).
- `review_status.py`: `latest_record` only considers dated `<YYYY>/<MM>/<DD>/*.md` records;
  `refs_for` gives each record only the § refs and IDs after its own path on a multi-record
  Source line; the tier regex accepts multi-word tiers ("Nice to have").

## Verification

- ruff, `ruff format --check`, ty and `check_local_annotations.py --include-module` are clean on
  all four; the new doctests (`iter_py`, `display_path`, `refs_for`) pass.
- Scratch C tree: positional site → 1; nonexistent source → 2; missing database → 2 (both C
  tools); an unparseable file next to a positional one → the site is listed and the exit is 2;
  clean file → 0. `check_local_annotations.py` on a missing path and on an empty directory → 2.
- Real trees still pass: spimulator `c_designated_init_check.py builddir src include` → 0,
  `c_dispatch_check.py builddir src` → 0 (16 units, 0 flagged); methodfinder `src` → 0.
- Scratch `tasks/review/` with a `README.md` and a "Nice to have" tier: the dated record is chosen
  and the tier is parsed.

## Follow-ups

- runCrushInContainer's mirrored copies: re-copied by that repo's batch.
- Other repos' vendored copies: `tasks/recopy-shared-checkers-downstream.md`.
