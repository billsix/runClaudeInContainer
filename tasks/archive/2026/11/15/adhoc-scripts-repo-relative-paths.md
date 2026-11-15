# Ad-hoc scripts use repo-relative paths, never container-absolute

**Status:** complete
**Completed:** 2026-11-15
**Created:** 2026-09-18 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §9.3 F7

## What this did

The rule (an ad-hoc script's paths are relative to the script or the repo root, never
container-absolute) is in the shared `CLAUDE.md` ("Ad-hoc scripts") and
`tasks/reference/task-doc-conventions.md`. The one offender, `rollout.py`'s hard-coded fleet root,
was fixed and archived on 2026-09-18 (`tasks/archive/2026/09/18/fix-rollout-py-fleet-root-arg.md`).
The second finding was confirmed benign.

## Verification

2026-11-15: `grep -nE '/foo/opt|/mnt/sda1|scratchpad'` over `tools/` and every script under
`tasks/adhoc/` found only docstrings in `rollout.py` (lines 9 and 53), no path a script uses.
