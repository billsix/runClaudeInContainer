# Bulk operations: shell-first discovery → data-file worklog → iterate → verify

**Status:** implemented 2026-09-18 — staged; archive owed after the work commit
**Priority:** 3
**Difficulty:** 4
Created 2026-09-18 (William Emerison Six <billsix@gmail.com>).

> **Implemented (2026-09-18).** Four edits landed (staged, not committed — the maintainer commits):
> 1. `tasks/reference/task-doc-conventions.md` "Ad-hoc scripts" — added the "Bulk operations" paragraph
>    (shell-first discovery, `discover.sh` + `data/` worklog, content-matching fix, idempotency
>    optional, the skip-one-liner carve-out).
> 2. Nested/runtime `entrypoint/dotfiles/.claude/CLAUDE.md` "Ad-hoc scripts" — added the terse bulk-op
>    mirror + pointer to the shell doc.
> 3. `tasks/reference/shell-and-gate-scripts.md` — new section "## Bulk find → log → iterate → fix"
>    with the full command idioms (rg/git grep, reverse-order + content-matching, sed/perl, the read
>    loop, verify, gotchas).
> 4. Nested CLAUDE.md reference-docs index — extended the `shell-and-gate-scripts.md` read trigger to
>    include "doing a bulk find-and-fix across many files".
>
> **Blast radius:** this is the shared cross-project layer (mounted at `~/.claude/`), so it reaches the
> agent on **every** project at the next `make shell` — no image rebuild (these docs are mounted, not
> baked). **Owed:** archive this task as its own commit after the work commit.

> **Decisions (William Emerison Six <billsix@gmail.com>, 2026-09-18):**
> 1. Data-file location: **per-slug `tasks/adhoc/<slug>/data/`** (removed with the script).
> 2. **The primary purpose is the worklog** — a list to iterate over so the model isn't reading
>    every file front-to-back to decide what to do next. **Idempotency is a nice-to-have, NOT
>    required.** Content/marker-matching and bottom-up processing stay in the doc as *correctness*
>    advice (don't edit the wrong line via a stale offset), not as an idempotence mandate. The data
>    file is a snapshot/audit worklog, never a line-number replay driver.
> 3. Reference-doc home: this repo **extends `tasks/reference/shell-and-gate-scripts.md`**; runCrush
>    gets a **new focused `bulk-edit-shell-first.md`** (it has no shell doc).
> 4. Scope confirmed intended: this is the shared cross-project layer, so it applies whenever the
>    sandbox develops any project — that's the point of the image.

## BLUF

Add a convention: when a task is a **bulk operation** (find many instances of something, then
fix each), the first move is a **Linux shell discovery command** (`rg` / `git grep` / `grep -Rn`)
that logs the matches to a committed **data file**, followed by an **iterate-and-fix** pass and a
**re-grep verification** — instead of defaulting to a Python ad-hoc script that walks the tree
blindly. Motivation is concrete and citable: the agent (especially a local model with a **small
context window** — nested `CLAUDE.md:4–6`) should not burn its context reading files one-by-one to
find matches when one `rg` call returns just the hits. This repo's nested `CLAUDE.md` and
`tasks/reference/` are the **shared cross-project convention layer** (mounted at `~/.claude/` for
every project), so this change is fleet-wide; a coordinated sibling task exists in runCrush. "Done"
= the paired terse-rule + reference-doc edits below are made, the skip-one-liner and
idempotence/stale-line tensions are resolved in-text, and the two repos' wording is consistent.

## Context (cold-start)

**The existing ad-hoc-script convention** (verified 2026-09-18) lives in two coordinated places:
- Full rationale: `tasks/reference/task-doc-conventions.md`, "## Ad-hoc scripts" (lines 98–144).
- Terse mirror: nested/runtime `entrypoint/dotfiles/.claude/CLAUDE.md`, "## Ad-hoc scripts" (lines
  405–419). This is the file mounted over `~/.claude/CLAUDE.md`.

It already: saves substantive scripts under `tasks/adhoc/<slug>/`; **skips one-liners** incl.
`grep`/`sed`/`awk` one-liners (`task-doc-conventions.md:105`, verbatim: *"Skip: trivial shell
pipelines, `grep`/`sed`/`awk` one-liners, `python -c` snippets, and interactive exploration"*);
requires codemods be **idempotent, proven by running twice → zero changes** (`:126`); requires the
saved script **reproduce its own diff run once on the original input** (`:124`); and already
sanctions writing outputs/logs **under the repo** (`:118`). The three-commit lifecycle (task-add /
work+adhoc / archive+`git rm`) and the `.keep` rule are at `:70–84`, `:128`, `:138–144`.

**Nearest prior art in-repo** — `tasks/reference/print-debugging.md:25`: *"Tag every line with a
grep-able marker (this doc uses `DBG`). A single `grep -rn DBG` then finds every temporary print for
removal."* This is a discover-via-grep-then-iterate pattern that uses an **in-file, re-grep-able
marker instead of persisted line numbers** — exactly the resolution to the stale-line-number
problem below. Cite it as precedent.

**What does NOT exist** (grep-authoritative, both repos): no "data file", "worklog", "find-then-
iterate", or `tasks/adhoc/data` concept anywhere. This convention is genuinely new. There is **no**
documented claim that Glimmer is a "weak model" — do NOT assert that; motivate from the citable
"local model has a small context window" fact and from ordinary good practice.

**Tooling is guaranteed present** (checked in `entrypoint/01-install-base.sh`): `ripgrep` (`rg`,
:357), `gawk` (:112), `perl` (:292), `sed` (:376), `the_silver_searcher` (:420), findutils. These
boxes are **GNU/Linux only**, so the convention can use GNU idioms and skip BSD-`sed` portability
(note it in one line for copy-paste-into-mixed-environments safety).

## The convention to add

### The workflow (find → log → iterate → fix → verify)

1. **Discover with a shell tool, first move.** Prefer `rg -n` (fast, skips binaries and `.gitignore`
   by default), or `git grep -n` when the scope is "every tracked file" (respects the git index, no
   gitignore blind spot), or `grep -Rn` as the always-present fallback. One call returns just the
   matches — no context spent reading files to find them.
2. **Log matches to a committed data file** under the script's own slug dir (see open question 1),
   e.g. `tasks/adhoc/<slug>/data/matches.txt`. This is the **audit record of what existed at
   discovery time** — a worklog, **not** a replay input.
3. **Save the discovery command itself** as `tasks/adhoc/<slug>/discover.sh` (see the skip-one-liner
   carve-out below) so the history shows exactly how the targets were found.
4. **Iterate and fix** with a shell (`sed -i` / `perl -0777 -pi -e` / `gawk -i inplace`) or Python
   script that **matches on content/marker, not on the saved line numbers** — so it is idempotent by
   construction. Where an edit changes line count, process each file **bottom-up (reverse line
   order)** so earlier edits don't shift not-yet-applied offsets.
5. **Verify by re-grepping**: the same discovery command must now report **zero** remaining matches
   (or the expected, explained residue); a before/after count diff catches partial fixes.

### Terse rule to add to nested `CLAUDE.md:405–419` (draft, ~4 lines)

> **Bulk op (find-many → fix-each)? Discover with a shell tool, don't tree-walk in Python.** Run
> `rg -n`/`git grep -n` once, log matches to `tasks/adhoc/<slug>/data/` (a committed *snapshot*
> worklog, git-rm'd with the script), and save the discovery command as `discover.sh` — a bulk
> discovery command IS substantive (its output drove a large diff), so it's exempt from "skip
> one-liners". The fix must match on **content/marker, not the saved line numbers** (they rot as
> edits shift lines — see `print-debugging.md`'s `DBG` marker); process bottom-up if it changes line
> count (a correctness measure — a stale offset edits the wrong line — not an idempotence mandate).
> The worklog exists so the model works a list instead of reading every file front-to-back;
> idempotency is a bonus, not required. Verify by re-grep = zero matches. Full idioms:
> `~/.claude/reference/shell-and-gate-scripts.md`.

### Full detail → `tasks/reference/shell-and-gate-scripts.md`

Add a new section "## Bulk find → log → iterate → fix" (this doc already covers grep/sed/awk gate
scripts, failure propagation, and the zsh `bash -c` wrapping — the natural home). Fold in the idiom
appendix at the end of this task. Cross-link it from the `task-doc-conventions.md` ad-hoc section,
and **extend that doc's read-on-demand trigger** in the CLAUDE.md reference-docs index to include
"…or doing a bulk find-and-fix across many files".

## Tensions to resolve IN THE TEXT (do not leave implicit)

1. **"Skip one-liners" vs "save the discovery command."** Amend `task-doc-conventions.md:105`: skip
   *exploratory* one-liners with no downstream artifact, **but** the discovery command of a bulk
   operation whose data file/diff is committed **is substantive — save it**. Lever: the existing
   "would the diff alone leave you wondering how I did this?" test (`:106`) — a bulk diff does.
2. **Stale line numbers vs "reproduce its own diff run once on the original input" (`:124`).** The
   data file stores a snapshot of `file:line` matches; those offsets rot the instant the fix shifts
   lines. **Resolution:** the data file is a *human/audit snapshot*, never the driver; the FIX
   re-derives location live (content/marker match) or processes bottom-up. Mirror the existing rule
   "cite by stable named anchor, never a line number — they rot" (`reference-doc-conventions.md`
   L3 / CLAUDE.md:442).
3. **Idempotence is OPT-IN here, not mandatory** (per the 2026-09-18 decision). The existing
   "run-twice → zero changes" rule (`:126`) is about *codemods run as a proof*; a bulk worklog whose
   point is "give the model a list to iterate" doesn't have to be idempotent. Say so explicitly so a
   reader doesn't think the convention demands it — but keep content/marker-matching and bottom-up as
   *correctness* advice (avoid editing the wrong line via a stale offset). If a fix happens to be a
   clean re-runnable codemod, the run-twice proof is still welcome, just not required.
4. **Don't over-apply the "reproduce diff from original input" proof (`:124`).** That proof is for a
   codemod presented as a reproducible transform. When the workflow is instead "iterate the worklog
   and fix each by hand/judgment," there is no single reproducible diff to prove — the audit trail is
   `discover.sh` + the committed data file + the resulting diff. Note this scope so the two don't
   collide; where a fix IS a scripted codemod, the data file should be regenerable via `discover.sh`.
5. **Clutter (the reason skip-one-liners exists — `:105`).** A bulk task now adds `discover.sh` +
   `data/` + a fix script. Justify: unlike an exploratory one-liner, these three ARE the mechanical
   "how" behind a large diff; keep them in one slug dir so archive removes them together.

## Lifecycle fit

The data file rides **commit 2** (work + adhoc scripts) beside `discover.sh` and the fix script, and
is **`git rm`'d in commit 3** (archive) with the slug dir — matching the user's "git rm when the
adhoc script is removed". If the fix script is instead **promoted to `tools/`**, the one-shot data
file is **not** promoted (it's a record, not a tool) — delete it. `.keep` rule unaffected.

## Idiom appendix (fold into the reference doc; from web research 2026-09-18, sources at end)

**Discovery / machine-readable output**
- `rg -n --column 'PAT' src/` → `file:line:col:text`. Use `rg --vimgrep 'PAT' src/` when you need
  exactly one row per match (multi-match lines otherwise collapse). `rg -l` = filenames only.
  `rg --json` = structured (per-match `line_number`, byte `start`/`end` in `submatches`).
- `git grep -n 'PAT' -- '*.py'` — tracked files only, no gitignore blind spot.
- Portability guard for reusable scripts: `command -v rg >/dev/null 2>&1 || { …grep -R fallback… }`
  (rg absent on minimal images — though present in THESE images).
- NUL-safe filenames: `grep -rlZ 'PAT' . | xargs -0 …`, `find . -name '*.py' -print0 | xargs -0 …`,
  `rg -0 -l 'PAT'`.

**Stale-line-number handling**
- Bottom-up (when the edit changes line count): `grep -n 'PAT' f | sort -t: -k1,1 -rn | while
  IFS=: read -r n _; do sed -i "${n}s/old/new/" f; done`. `tac` is the base primitive.
- Preferred — re-derive live, match by content: `sed -i 's/exact_old/new/' f` or context-scoped
  `sed -i '/anchor/s/old/new/' f`; no saved offset to rot.
- Idempotent substitution: anchor to a field that stops matching once fixed
  (`sed -i 's/^\(version:\).*/\1 2/' f`); guard with `grep -q 'PAT' f && sed -i …` so it fails loud,
  not silent; beware `s/foo/foobar/g` re-matching on re-run.

**Applying edits**
- `sed -i` (GNU here; BSD needs `-i ''` — moot on Linux, note for copy-paste). Multi-line →
  `perl -0777 -pi -e 's/old/new/gs' f` (slurp mode; `.` spans newlines). Field/column work →
  `gawk -i inplace '{…}' f`. `find … -exec cmd {} +` batches like `xargs -0`.
- Greedy-regex trap: sed has no `.*?`; use `[^>]*` not `.*` to stop at the first delimiter.

**Worklog / iterate**
- `while IFS= read -r line; do …; done < matches.txt` — `IFS=` keeps whitespace, `-r` keeps
  backslashes, **redirect from file (not `cat | while`)** so counters survive the subshell; use
  `< <(cmd)` process-substitution to consume a command. Append final `|| [ -n "$line" ]` for a last
  unterminated line. Resumability: move done rows to `matches.done.txt`, compute remaining with
  `grep -vFf matches.done.txt matches.txt`.

**Verify**
- Re-grep zero: `rg -l 'PAT' src/` empty = clean. Before/after: `rg -c 'PAT' src/` into two files +
  `diff`. `git diff -U0` for tight review of many one-line changes (catches greedy over-match).

**Gotchas**: skip binaries (`grep -I`; rg default); `find -L` symlink-loop slowness (prefer plain
`find` for a source sweep); `LC_ALL=C` = byte-wise (fast + safe for pure-ASCII, wrong for Unicode-
sensitive substitutions); never `grep … f | sed -i … f` on the same file in one pipeline — two
phases (discover to file, then edit).

## Open questions

None — all four resolved in the Decisions block at the top (2026-09-18): per-slug data dir;
worklog-first with idempotency optional; extend `shell-and-gate-scripts.md`; fleet-wide scope
confirmed. Implementation (the paired CLAUDE.md + reference-doc edits) awaits a go-ahead.
