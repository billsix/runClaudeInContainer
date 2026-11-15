# Re-copy the fixed shared checkers into the downstream projects that vendor them

**Status:** proposed — needs go-ahead
**Priority:** 3
**Difficulty:** 2
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §5.1, §5.2, §5.3 F3

## BLUF

`tasks/archive/2026/11/15/shared-checker-gate-fixes.md` fixed the canonical
`check_local_annotations.py`, `c_dispatch_check.py` and `c_designated_init_check.py` here (they now
exit 2 instead of 0 when nothing matches or the check cannot run). The vendored copies in other
repos still carry the old, vacuously passing code. Done means each copy below is byte-identical
to the canonical again (or, for a fork, has the fix merged) and that project's gate still passes.

## Context

Vendored copies found on 2026-11-15 (`ls -d /mnt/sda1/*/tools/…` in the sandbox):

| Project | Copy | Note |
|---|---|---|
| github.com/billsix/spimulator | `tools/check_local_annotations.py`, `tools/c_dispatch_check.py`, `tools/c_designated_init_check.py` | byte mirrors; its meson tests `dispatch_check` and `designated_init_check` run the C two |
| github.com/billsix/methodfinder | `tools/check_local_annotations.py` | byte mirror |
| github.com/billsix/modelviewprojection | `modelviewprojection/tools/check_local_annotations.py` | the canonical minus its 11-line banner |
| impo (`openstax/tooling/tools/check_local_annotations.py`) | a modified fork (different docstring; checks module level by default) | merge the exit-2 handling by hand |

runCrushInContainer's copies are re-copied by its own batch, not by this task.

## Plan

1. Copy the canonical over each byte mirror; restore the banner for modelviewprojection; merge
   the `iter_py`/`main` changes into the impo fork by hand.
2. Run each project's gate (`make type-check` for the Python projects, `make image` for spimulator)
   and confirm it still passes. A gate that now exits 2 has a wrong path in its invocation; fix
   the invocation.
3. Commit per project.
