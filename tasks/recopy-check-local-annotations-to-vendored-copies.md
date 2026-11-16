# Re-copy `check_local_annotations.py` over its four stale vendored copies

**Status:** proposed — needs go-ahead
**Priority:** 5
**Difficulty:** 2
**Created:** 2026-11-16 (William Emerison Six <billsix@gmail.com>)
**Spans:** github.com/billsix/modelviewprojection, github.com/billsix/methodfinder,
github.com/billsix/spimulator, github.com/billsix/impo. Each repo's copy is changed and staged
in that repo; nothing changes here.

## BLUF

Four projects vendor an older `check_local_annotations.py` than the canonical
`tasks/reference/check_local_annotations.py`. Each still cites the pre-archive path
`tasks/annotate-all-local-variables.md`, and none has the 2026-11-15 exit-2 behaviour. Done means
each copy is byte-identical to the canonical and that repo's `make type-check` passes.

## Context

- The canonical's header says to edit the canonical and then re-copy it over every vendored copy.
  runCrushInContainer's mirror (`tasks/reference/check_local_annotations.py`) is already
  identical.
- The canonical picked up the path fix and the stricter exit status in commit 6929441
  (2026-11-15, "shared checkers: exit 2 when nothing matches or the check cannot run …"). The
  stricter exit status is 0 for no findings, 1 for findings, and 2 when a given path is missing,
  nothing matches, or the check cannot run. The vendored copies predate that commit.
- Found 2026-11-16 by modelviewprojection's dangling-path sweep. That sweep left mvp's copy alone
  because it is vendored (modelviewprojection `tasks/repoint-dangling-task-doc-paths.md`, moving
  to its `tasks/archive/2026/11/16/` once archived).

## The copies (snapshot 2026-11-16, `diff | wc -l` against the canonical)

| Repo | Path | Diff lines |
|---|---|---|
| modelviewprojection | `tools/check_local_annotations.py` | 165 |
| methodfinder | `tools/check_local_annotations.py` | 153 |
| spimulator | `tools/check_local_annotations.py` | 153 |
| impo | `openstax/tooling/tools/check_local_annotations.py` | 182 |

To re-find them: `git -C <repo> ls-files | grep check_local_annotations.py` over each mounted repo,
then `cmp` against the canonical.

## Plan

For each repo, modelviewprojection first:
1. `cp` the canonical over the vendored copy. Keep the mode (`git ls-files -s`), and restore `+x` if
   the copy was executable.
2. Run that repo's `make type-check`.
   - **Watch for exit 2.** The new exit status fails the gate where an argument path no longer
     exists or matches no files, which the old copy passed silently.
   - If that happens, fix the repo's `--include-module`/path arguments; never patch the vendored
     copy.
3. Stage the copy (and any argument fix) in that repo by path.

## Open questions

None.
