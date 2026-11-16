# Re-copy `check_local_annotations.py` over its four stale vendored copies

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

To find the vendored copies again, list each mounted repo's tracked files and `cmp` the hits
against the canonical:

```sh
git -C <repo> ls-files | grep check_local_annotations.py
```
