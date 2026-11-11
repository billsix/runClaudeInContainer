# A shared, vendored checker for the C standard's dispatch rules

**Created:** 2026-11-11 (William Emerison Six <billsix@gmail.com>)
**Completed:** 2026-11-11
**Branch:** `shared-dispatch-checker`, stacked on `c-dispatch-rules`

## Outcome

`tasks/reference/c_dispatch_check.py` is a SHARED, VENDORED tool, mirrored byte-identically in
runCrushInContainer `tasks/reference/`. It reads clang's JSON AST through a build's
`compile_commands.json` and lists the sites that `c-coding-standard.md`'s "Dispatch" rules flag:
`switch-chain`, `no-else`, `guard-run` and `no-default`. Run it from a project's root as
`python3 tools/c_dispatch_check.py BUILDDIR [SOURCE ...] [--noreturn NAME ...] [--out OUTDIR]`.
A `dispatch-check: ok` comment, with the reason, accepts a site. The exit status is 0 when clean,
1 when something is flagged, and 2 on a parse failure or when no source matches.

The C standard's Dispatch section and both repos' `CLAUDE.md` shared-tools paragraphs name it.

## How it differs from its source

It was generalized from github.com/billsix/spimulator `tools/dispatch_candidates.py`, which
hardcodes `src/*.c`. The shared version:
- takes the sources as arguments, relative to the working directory, and errors when they match
  nothing;
- honours the accept marker;
- takes `--noreturn` for unmarked fatal functions;
- accepts compile entries in `command` or `arguments` form, with joined or split
  `-I`/`-D`/`-U`/`-isystem`/`-iquote`/`-include`;
- reports a file clang can't parse and goes on.

The Crush client's baked reference set doesn't get it: vendored tools are copied into projects,
not read in place.

## Verification

- ruff, ty and `check_local_annotations.py` are clean.
- **spimulator:** at `7e2eb03`, before its dispatch work, the two tools agree on all 88 flagged
  sites (10 switch-chain, 37 no-else, 20 guard-run, 21 no-default). At master both report the single
  accepted-by-design site. With a `dispatch-check: ok` comment added to a scratch copy, that site
  shows as accepted and the exit status is 0. A single-file source filter checks one unit.
- **A synthetic compile database** exercises the `arguments` form with split flags, the `command`
  form, a file that doesn't parse (exit 2, with the others still checked), and an empty match
  (exit 2).
- **github.com/billsix/Craft `src/`** (configured into a scratch build; its tree untouched): all 13
  translation units parse, and 18 sites are flagged. Both spot-checked findings, a guard run in
  `client_send` and an open chain in `map_set`, are real.

## Follow-ups

- spimulator still runs its own `tools/dispatch_candidates.py`. To switch it to the shared tool,
  vendor `c_dispatch_check.py` into its `tools/`, add the accept marker to `run_spim`'s fetch chain,
  and point its `CLAUDE.md` at the new command. That is a spimulator change, so it isn't done here.
