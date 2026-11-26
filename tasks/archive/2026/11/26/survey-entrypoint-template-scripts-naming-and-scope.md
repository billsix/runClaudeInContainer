# Applied the bash naming and scope rules to every project's `entrypoint/*.sh`, once for the fleet

**Completed:** 2026-11-26
**Created:** 2026-11-25 (William Emerison Six <billsix@gmail.com>, asked whether the template's `entrypoint/*.sh` scripts should be surveyed once in this repository or per repository: "fleet wide"). Go-ahead 2026-11-26.
**Source:** github.com/billsix/towersofhanoi `tasks/archive/2026/11/25/apply-naming-and-scope-rules-per-language-across-repositories.md` ("Not decided").

## What was done

The bash rules ("Names and scope in bash" in `tasks/reference/shell-and-gate-scripts.md`) were applied to the 268 tracked `entrypoint/*.sh` scripts of 26 project repositories in one pass. Two scripts changed. Each repository's `tasks/apply-naming-and-scope-rules-per-language.md` (23 repositories have both that task and `entrypoint/` scripts) gained one line saying its `entrypoint/` scripts were covered here.

## Method

`python3 tasks/reference/survey_names_and_scope.py --language bash` was run in each repository and its output filtered to paths matching `entrypoint/<name>.sh`. Upstream-only checkouts were skipped. The survey printed 20 leads; each was read.

## The 20 leads

| Lead | Where | Decision |
|---|---|---|
| `NBSRC` | github.com/billsix/epix-mirror `entrypoint/build_py.sh` | **Inlined** into the `g++` command; it was a plain string built from `NBDIR`, used once. |
| `bn` | github.com/billsix/impo `openstax/tooling/entrypoint/pdf.sh` | **Absorbed**: `basename "$c" .collection.xml` strips the suffix itself, so the variable and the `${bn%…}` expansion went. |
| `PYINC`, `NBINC`, `EXT` | epix-mirror `entrypoint/build_py.sh` | Kept: each is a command substitution whose failure must stop the script (`set -e` ignores one inside another command's arguments). |
| `site` | github.com/billsix/geometricalgebra `entrypoint/install-epix-stubs.sh` | Kept, same reason. |
| `DEV_DIMS` | geometricalgebra `entrypoint/shell.sh` | Kept: a named setting with a comment that explains its value. |
| `site_base` | impo `openstax/tooling/entrypoint/html.sh` | Kept: a default the environment may override. |
| `UPSTREAM` | imps `unixutils/ripgrep/entrypoint/warm-cargo-cache.sh` | Kept: a setting. |
| `SHFMT_SHA256`, `PROCS_SHA256` (two repositories) | this repository and github.com/billsix/runCrushInContainer, `01b-install-binary-tools.sh` | Kept: pinned checksums in the block a reader edits. |
| `_CONN`, `_ROUTER` | runCrushInContainer `client/entrypoint/03-build-crush.sh` | Kept: each is a path about 90 characters long, and inlined into its `grep` it would not fit on the line. |
| `render_one`, `warm_one` | epix-mirror `entrypoint/examples.sh`, imps `android/fossify/entrypoint/warm-gradle-cache.sh` | Functions with one caller; a bash function is never nested. |
| `PYTHONPATH=..`, `CC=clang CXX=clang++` (two lines) | github.com/billsix/methodfinder `entrypoint/test.sh`, github.com/billsix/spimulator `entrypoint/buildDebug.sh` | Not assignments: an environment prefix on a command. |

## Found on the way

The task expected groups of identical scripts, one decision per group. The scripts are not identical: `format.sh` and `shell.sh` have a different checksum in almost every repository (one pair matches). No lead recurred across repositories except the two checksum settings that this repository and runCrushInContainer share.

## Verification

- `bash -n` and `shellcheck -S warning` pass on both changed scripts; both keep mode 100755.
- `basename ../collections/foo.collection.xml .collection.xml` prints `foo`, the value the removed expansion produced.
- Not run: `make py-ext` in epix-mirror and `make pdf` in impo, the targets that execute the two scripts. Neither repository's format gate reads shell scripts.

## Handoff

The two script changes and the one-line notes are staged, not committed, in the other repositories, next to the task documents already staged there. In this repository and in runCrushInContainer the note is committed on a branch.
