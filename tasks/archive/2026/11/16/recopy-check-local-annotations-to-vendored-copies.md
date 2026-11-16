# Re-copy the shared checkers over their stale vendored copies

**Done:** 2026-11-16. **Created:** 2026-11-16 (William Emerison Six <billsix@gmail.com>).
**Spans:** github.com/billsix/modelviewprojection, github.com/billsix/methodfinder,
github.com/billsix/spimulator, github.com/billsix/impo. Each repo's copy was changed and staged
in that repo; nothing changed here.

Four projects vendored an older `check_local_annotations.py` than the canonical
`tasks/reference/check_local_annotations.py` (at commit 6929441, 2026-11-15). Each copy still cited
the pre-archive path `tasks/annotate-all-local-variables.md`, and none had the exit-2 behaviour.
The canonical was copied over all four; each is now byte-identical to it, and each kept its file
mode.

Found by modelviewprojection's dangling-path sweep, which left mvp's copy alone because it is
vendored (github.com/billsix/modelviewprojection
`tasks/archive/2026/11/16/repoint-dangling-task-doc-paths.md`). runCrushInContainer's mirror was
already identical.

## Copies and gates

| Repo | Path | Diff lines before | Gate run after the copy |
|---|---|---|---|
| modelviewprojection | `tools/check_local_annotations.py` | 165 | `make type-check`: pass |
| methodfinder | `tools/check_local_annotations.py` | 153 | `make type-check`: pass |
| spimulator | `tools/check_local_annotations.py` | 153 | the checker with `port/python/lint.sh`'s arguments (`--include-module port/python/spimulator_py`): pass. No make target runs `lint.sh`; spimulator `tasks/review/2026/11/11/repo-review.md` §5.3 records that gap. |
| impo | `openstax/tooling/tools/check_local_annotations.py` | 182 | `make type-check` in `openstax/tooling` (ruff, the checker, ty, pytest): pass |

The new exit-2 check (a given path is missing or matches nothing) fired nowhere, so no repo's
arguments needed changing.

## The C checkers in spimulator (same day, same cause)

A follow-up scan compared every shared vendored tool against its canonical
(`check_local_annotations.py`, `c_dispatch_check.py`, `c_designated_init_check.py`,
`update_dep_common.sh`, `review_status.py`) in every mounted repo. Two more stale copies turned up,
both in spimulator and both missing the same commit 6929441:

| Path | Diff lines before | Gate run after the copy |
|---|---|---|
| `tools/c_dispatch_check.py` | 19 | `make image`: the meson test `dispatch_check` passed (54/54 tests OK) |
| `tools/c_designated_init_check.py` | 65 | `make image`: the meson test `designated_init_check` passed |

The maintainer approved adding these to this task (2026-11-16). Every other copy was already
identical: runCrushInContainer's mirrors of all five tools, and github.com/billsix/Craft
`tools/update_dep_common.sh`.

To find the vendored copies again, list each mounted repo's tracked files and `cmp` the hits
against the canonical in `tasks/reference/`:

```sh
git -C <repo> ls-files | grep -E '(check_local_annotations|c_dispatch_check|c_designated_init_check)\.py|update_dep_common\.sh|review_status\.py'
```
