# Choosing a script's language — shell for glue, Python for logic

Durable guidance for deciding, when you **write an ad-hoc script or a `tools/` tool**,
whether it should be **Bash or Python** — and, once written, when a helper inside it
earns promotion to a shared module. Companion to `~/.claude/reference/code-style-conventions.md`
(the "never orphan a word", extraction, and total-dispatch rules apply to both languages),
`~/.claude/reference/task-doc-conventions.md` (the ad-hoc-vs-`tools/` *promotion* rule, which is
orthogonal to language), and `~/.claude/reference/shell-and-gate-scripts.md` (the mechanics a
shell gate must honour). Written after a 2026-10-29 cross-repo sweep converted the worst offenders
(William Emerison Six <billsix@gmail.com>).

## The rule

**Shell is for ORCHESTRATION; Python is for LOGIC.** Default to shell when the script's
job is to *drive other programs* — spawn processes, thread pipes and redirects, sequence
`git`/`make`/`podman`/compiler invocations, move files, set env and `exec`. Reach for
Python the moment the script's job is *data or control logic that shell expresses only
awkwardly*. The test is not length — a 200-line pipeline of real tools is fine shell; a
40-line script doing graph traversal is not.

### Tells that a script should be Python (any ONE is enough)

- **Associative arrays / `declare -A`** used as maps or sets.
- **Recursion, or graph/tree traversal** (a transitive-closure / dependency walk).
- **Arithmetic or bit logic**: bit-twiddling (`1 << n`, `i >> j & 1`), power sets /
  combinatorics, a hand-rolled PRNG or integer hash, modular/sequence math.
- **Set logic faked with strings**: the `case " $list " in *" $x "*)` substring-membership
  idiom, canonical-ordering a subset by re-scanning a master list.
- **Parsing structured text** — JSON, CSV, TOML, a compile-commands database. An embedded
  `python3 - <<'PY'` heredoc or a `jq` dependency *inside a bash script* is itself the smell
  that the script already wanted to be Python.
- **Non-trivial arrays threaded through logic** (`mapfile` + index bookkeeping + several
  parallel arrays you must keep in step), as opposed to a single list you just iterate.
- **String munging that encodes logic** via chained `sed`/`awk` you have to decode to read.

### What stays shell even when it is long

- A **pipeline of real tools**: compiler + diff, `git` sequences, `cmake`/`ninja`,
  `grep -rn … | xargs`, `find -print0 | xargs -0`.
- **Process / signal / job control**: `trap` cleanup, `set -m` + process groups,
  `kill -INT -- -$pid`, PATH shims that mimic a binary (`ssh`/`make` fakes) — this is
  shell's home turf and Python's `subprocess`/`signal` only re-implements it more verbosely.
- **Env-var + `exec` wrappers**, and the thin shim described below.
- **The container template's own scripts** — `entrypoint/*.sh`, `format.sh`, gate scripts
  — **must stay host-runnable shell** by the fleet contract; don't convert these.
- **Dependency-updater scripts** (`update-<dep>.sh` + `update_dep_common.sh`): `git clone` /
  `git archive` / `tar` / `cp` / `curl` glue. Short, linear, and already a documented
  vendored system — a Python port would add a `subprocess` call per step for no clarity gain
  and would ripple through the canonical + mirrors + reference doc. **Deliberately stays bash.**

## Converting an existing tool without breaking callers

Keep the old `tools/foo.sh` path alive as a **2-line shim** and move the logic to
`tools/foo.py`:

```sh
#!/usr/bin/env bash
exec python3 "$(dirname "$0")/foo.py" "$@"
```

Callers — Makefiles, Dockerfiles, docs, sibling tools that invoke it by path — change
nothing. Keep the shim's executable bit (`git add --chmod=+x`; a `Write` rewrite drops it).
This shim pattern is already idiomatic (imps' per-project `check-comment-only.sh` wrappers
are themselves `exec`-shims). **Prove the port is behaviour-identical before relying on it**:
capture the old script's output on real inputs, run the new one, `diff` — byte-identical is
the bar for a gate/tool whose output other scripts parse.

## Promotion is orthogonal to language

*Whether* a script graduates from `tasks/adhoc/` to `tools/` follows the existing rule
(reusable → `tools/` with a docstring; one-shot → `git rm` at archive) regardless of
Bash-vs-Python. And a **helper inside** a tool (e.g. a `git()` subprocess wrapper) is
promoted to a **shared module** only at the same bar as any shared/vendored tool —
**two or three real consumers that need it identically** (the bar `check_local_annotations.py`
and `update_dep_common.sh` cleared). Below that, **inline the helper per-tool**; a shared
module with one consumer is speculative coupling, not reuse.

## Worked examples (2026-10-29 sweep)

- **Converted** (logic, not glue): imps `tools/apply_unit.py` (a transitive `DEPENDS`
  graph DFS — was `declare -A VISITED` + recursion echoed into `mapfile`); imps
  `tools/check_comment_only_streams.py` (family discovery + `LANG` dispatch + array
  bookkeeping); runCrush `tools/sweep_egress_patch_combos.py` (power sets via `1 << n`,
  a hand-rolled integer-hash PRNG, substring-match canonical ordering). Each kept a `.sh`
  shim; each proven byte-identical to its bash.
- **Left as bash** (orchestration): imps `check_patches_apply.sh` /
  `check_upstreamable_applies.sh` (≈70% `git` subprocess loops), `asmdiff.sh` /
  `asmdiff_tree.sh` (compiler + `diff` pipelines; also a delicate codegen gate),
  `prove_comment_only.sh` (`gcc -fpreprocessed` + `cmp` loop), `verify_appimage_builds.sh`
  (`make` + `file` orchestration); runCrush `check_launchers.sh` (process-group signal
  testing with PATH shims); gltron `sanitizer-gate.sh` / `lint.sh`; smc `smoke_headless.sh`
  (Xvfb + `timeout` + `ps` audit); every `update-<dep>.sh`.
- **The `git()`-helper question**: evaluated whether the small `git()` wrapper used by the
  two new imps Python tools should become a shared template in the sandbox repos. Answer:
  **no** — those repos' durable Python (`check_local_annotations.py`, `checksum.py`,
  `triage_dependency_egress.py`, `ty_lsp_probe.py`) does hashing / AST / LSP / dependency
  work, essentially **no `git` subprocess** — zero consumers for a shared git helper there.
  It is git-heavy *imps* that has two copies; even there, extract `imps/tools/_gitutil.py`
  only when a third git-using Python tool appears (the two-to-three-consumer bar above).
