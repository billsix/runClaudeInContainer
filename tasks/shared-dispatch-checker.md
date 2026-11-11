# A shared, vendored checker for the C standard's dispatch rules

**Status:** in progress (branch `shared-dispatch-checker`, stacked on `c-dispatch-rules`)
**Priority:** 4
**Difficulty:** 3
**Created:** 2026-11-11 (William Emerison Six <billsix@gmail.com>)

## BLUF

Add `tasks/reference/c_dispatch_check.py`, a SHARED, VENDORED tool (like `check_local_annotations.py`)
that reads clang's JSON AST and lists the C sites the `c-coding-standard.md` "Dispatch" rules flag.
Those are a one-value chain that should be a `switch`, a chain with no final `else`, a run of
early-exit `if`s, and a `switch` with no `default`. It must work in any C project, not just
spimulator. Done means:
- the tool is in this repo with its banner, mirrored byte-identically in runCrushInContainer;
- it reproduces spimulator's results;
- it runs on a second C project;
- the docs that list the shared tools name it.

## Context

- **Where it comes from:** github.com/billsix/spimulator `tools/dispatch_candidates.py`, written for
  that repo's `tasks/archive/2026/11/11/c-switch-and-else-if-chains.md`. It hardcodes `src/*.c` and
  the repository layout, and has no way to accept a site.
- **What changes for the shared version:**
  - The sources are an argument, as directories or files relative to the working directory, which
    is the project root.
  - A site can be accepted in the source: a `dispatch-check: ok` comment, with the reason, on the
    line of the flagged `if`/`switch` or the line before. A clean project then runs it as a gate.
  - The exit status is 1 if anything is flagged.
  - More no-return functions can be named on the command line, for a project whose fatal-error
    function isn't marked `[[noreturn]]`.
- **The tricky part is clang's JSON locations.** A location omits its `file` and `line` when they
  equal the previous one printed, so the tool must follow them in printing order. Paths are
  relative to the compile command's directory.
- **Mirrors:** runCrushInContainer `tasks/reference/c_dispatch_check.py`. The baked Crush client set
  carries only docs and `review_status.py`, which runs in place; vendored tools are copied into
  projects, so the client set doesn't need this one.
- Read first: `tasks/reference/c-coding-standard.md` ("Dispatch"), `tasks/reference/python-coding-standard.md`
  (the tool is Python), and `tasks/reference/check_local_annotations.py` (the banner and shape).

## Plan

1. Write the tool from the spimulator one with the changes above. Check it with ruff, ty and the
   annotation checker.
2. Verify against spimulator: on its current branch, it should flag only `run_spim`'s fetch chain.
   On a master checkout from before the dispatch work, its counts should match the spimulator
   tool's. Then test the accept marker on a scratch copy.
3. Run it on a second C project, to prove nothing spimulator-specific remains.
4. Docs: this repo's `CLAUDE.md` shared-tools paragraph, and the C standard's Dispatch section.
5. Mirror into runCrushInContainer (its own task doc), done-record, archive.
