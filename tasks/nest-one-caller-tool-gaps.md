# Close the gaps in `nest_one_caller.py` found while nesting seven repositories

**Status:** proposed — needs go-ahead
**Priority:** 6 (the tool works; each gap costs a workaround or a hand fix in the next repository that hits it)
**Difficulty:** 3 (small edits to one script, mirrored byte-identical in two repositories; the question is how the cross-file check should match)
**Created:** 2026-11-25 (William Emerison Six <billsix@gmail.com>, from `git config`): raised by the agent after running the tool over the seven-repository naming-and-scope batch; the maintainer asked that everything discussed be in a task or on the work stack.

## BLUF

`nest_one_caller.py` (`tasks/reference/nest_one_caller.py`, mirrored in github.com/billsix/runCrushInContainer in `tasks/reference/` and in its baked client copy) nests a Python helper that has one caller into that caller. Running it over seven repositories on 2026-11-25 exposed four gaps, one of which was fixed the same day. This task closes the other three, adds a regression test for all four, and keeps the three copies byte-identical. Done means: a caller whose own helper was skipped is reconsidered; a same-named helper in a sibling script no longer blocks nesting; a jupytext `# %%` cell marker never moves with a helper; and a test run covers each.

## Context

**Read first:** `tasks/reference/nest_one_caller.py` (its docstring lists what it skips) and the section "What earns an extraction" of `tasks/reference/python-coding-standard.md`, which points at it.

**The four gaps** (all found 2026-11-25):
1. **Insertion above a comment (fixed 2026-11-25).** When a second helper nested into a host that had just received one, the tool inserted it between the first helper's comment and its `def`, so the comment ended up above the wrong function. `start_line` now takes any statement, and the insertion point is above the host's first statement and the comments directly above it. The fix is in the three copies. Found in the `epix-mirror` notebooks (`color_sep.py`, `twisted_cubic.py`, `steiner.py`, among others); it has no test.
2. **A caller waiting on a skipped helper is never reconsidered.** The tool nests a helper only after the helper's own pending helper has nested (`if name in pending.values(): continue`). When that inner helper is skipped (a doctest, or named in another file), the outer one is never retried and nothing is printed. Found in `mathnotebooks`: `_add_decimals_split_decimals2` (called only from `add_decimals`) was left at module level because the helper it calls, `_add_decimals_put_zeros_on_end`, is imported by a test; it was nested by hand.
3. **The cross-file check matches same-named helpers in sibling scripts.** `referenced_in_other_files` runs `git grep -nw <name>` over `*.py`, `*.rst` and `*.ipynb` and keeps rows that look like an import or a `.name` access. In `epix-mirror`, 21 notebook helpers (`F`, `f`, `g`, `color`, `circ`) were skipped as "named in another file" because other notebooks define their own `F` or `f`; nothing imports a notebook (the harness `exec`s them). The workaround was a scratch repository per notebook (`nest_isolated.sh` in the batch's adhoc scripts, since removed). The same happened in `geometricalgebra`'s notebooks and figure scripts.
4. **A jupytext cell marker moves with the helper.** The climb over "comments directly above" the helper (`startswith("#")`) takes a `# %%` marker with it, so the marker ends up inside the caller and two notebook cells merge. Found in `geometricalgebra`'s `notebooks/relative-graph-paper.py` (`mapping` into `draw`); fixed by hand. The batch's other repositories had no indented marker.

**Where the batch used the tool** (so a fix can be checked against known results): the archived records `tasks/archive/2026/11/25/apply-2026-11-06-naming-and-scope-rules.md` in the `Programming3DComputerGraphics`, `methodfinder`, `mathnotebooks`, `multivariate-math`, `epix-mirror`, `hanoi` and `geometricalgebra` repositories (each on github.com/billsix/).

## Goal

A tool that, run once over a repository, nests every one-caller helper the rule covers, leaves every comment and cell marker where it was, and reports (rather than silently drops) a helper it did not nest.

## Plan

- [ ] Gap 2: when the pending inner helper is skipped, drop it from `pending` and retry its caller in the same run, and print a line for the caller either way.
- [ ] Gap 3: change `referenced_in_other_files` so a match counts only when the other file imports the defining module (`import <module>`, `from <module> import`, `<module>.<name>`), found from the defining file's stem; keep the "named in another file" skip for a real import. (Decision 1: this rule.)
- [ ] Gap 4: stop the climb over comment lines at a line that starts with `# %%`, so a cell marker stays put.
- [ ] Add a regression test that runs the tool on small source strings in a temporary repository and checks all four gaps (the three open ones and gap 1). It lives beside the script as `tasks/reference/test_nest_one_caller.py` (decision 2).
- [ ] Re-run the tool over the `epix-mirror` notebooks and the `mathnotebooks` helpers in a scratch copy of each repository at its pre-batch commit; the output must match the committed result (no scratch repository per notebook).
- [ ] Copy the changed script, byte-identical, to github.com/billsix/runCrushInContainer (`tasks/reference/` and `client/entrypoint/dotfiles/.config/crush/reference/`); check with `cmp`.
- [ ] Stage by path and stop.

## Notes / decisions

- Gap 1 is fixed in the three copies and committed (the `scoping` commit in runClaudeInContainer, 2026-11-25); the plan items above leave it only the test.

## Decisions (answered 2026-11-25, William Emerison Six <billsix@gmail.com>: "yes to all seven recommendations", the seven being these two and the five in `hanoi/tasks/add-scoping-rules-to-per-language-coding-standards.md`)

1. **How the cross-file check matches:** only an import or attribute access of the defining module's name, found from the file's stem; no `--isolated` flag.
2. **Where the regression test lives:** a separate `tasks/reference/test_nest_one_caller.py` beside the tool, copied to the mirrors with the script.

## Open questions

None open. The status stays `proposed — needs go-ahead`: the maintainer asked for the decisions to be recorded, not yet for the work.
