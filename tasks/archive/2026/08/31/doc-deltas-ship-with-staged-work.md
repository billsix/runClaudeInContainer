# Doc deltas ship with staged work — reconcile always-read docs per unit, not only at session end

**Status:** complete
**Completed:** 2026-08-31
**Created:** 2026-08-31 (William Emerison Six <billsix@gmail.com>)
**Sibling:** runCrushInContainer `tasks/archive/2026/08/31/doc-deltas-ship-with-staged-work.md` (the same change to its ported conventions, the same day)

## What this did

Amended the cross-project conventions (`entrypoint/dotfiles/.claude/CLAUDE.md`) so that
reconciling the always-read docs is part of finishing a unit of work, triggered at the staging
moment: when a coherent unit is done and `git add`ed, the CLAUDE.md / README / reference-doc
deltas it implies are updated and staged in the same handoff. The session-end sweep stayed,
demoted to a verification net expected to find nothing from finished units.

**Origin (the maintainer, 2026-08-31):** *"many times, the session end sweep is causing updates …
when they should have been done when a unit of work is done. or maybe, at least when the task is
archived."* A gacalc session that day had its sweep update CLAUDE.md, README and three reference
docs with content knowable the moment the cross-product/display-symbols work passed its gate.

## Decisions (the maintainer, 2026-08-31, all "your recommendation")

1. **Trigger = the staging moment**, which the conventions already defined ("when a coherent
   piece of work is done, `git add` the files it touched"). Not archive-time only: work can be
   committed long before its task archives (the gacalc work awaited a release), which would
   leave docs stale across sessions. The archive-time reference-doc harvest stays on top.
2. **Scope per unit = the docs the unit conceptually touches**, not a full always-read re-read;
   that remains the session-end sweep's job.
3. **Both repos:** this file and runCrushInContainer's
   `client/entrypoint/dotfiles/.config/crush/CLAUDE.md`.

Accepted cost: a unit redesigned later in the same session gets its docs written twice, which is
why the trigger is "verified + staged", not "every edit".

## What changed

- "Git: I commit, you don't — but you DO stage": staging a finished unit includes the doc deltas
  it implies, so staged = complete handoff.
- "Ending a session — sweep the always-read docs": the sweep is a verification pass that catches
  conversation-only decisions, cross-repo drift, and units redefined mid-session.

The edits were live immediately (the file is bind-mounted as `~/.claude/CLAUDE.md`).
