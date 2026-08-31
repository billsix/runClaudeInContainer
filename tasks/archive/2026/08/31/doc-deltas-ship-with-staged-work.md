# Doc deltas ship with staged work — reconcile always-read docs per unit, not only at session end

**Status:** DONE — implemented and archived 2026-08-31 (go-ahead given the same day); both
conventions files carry the amended wording.
**Priority:** 3
**Difficulty:** 2
**Created:** 2026-08-31 (William Emerison Six <billsix@gmail.com>)
**Sibling:** runCrushInContainer `tasks/archive/2026/08/31/doc-deltas-ship-with-staged-work.md` (the same change, applied to its ported conventions the same day)

## BLUF

Amend the tracked cross-project conventions (`entrypoint/dotfiles/.claude/CLAUDE.md`) so that
**reconciling the always-read docs is part of finishing a unit of work, triggered at the existing
staging moment** — when a coherent piece of work is done and `git add`ed, the CLAUDE.md / README /
reference-doc deltas that unit implies are updated and staged in the same handoff. The session-end
sweep stays, **demoted to a verification net** expected to find nothing from finished units. Done
means both conventions files carry the amended wording.

## Context

- **Origin (maintainer, 2026-08-31):** *"many times, the session end sweep is causing updates …
  when they should have been done when a unit of work is done. or maybe, at least when the task is
  archived."* Observed concretely in a gacalc session that day: the sweep updated CLAUDE.md,
  README, and three reference docs with content knowable the moment the cross-product/display-symbols
  work passed its gate — the conventions put doc-reconciliation only in "Ending a session", so it
  piles up there by construction.
- **Decisions (maintainer answered 2026-08-31, all "your recommendation"):**
  1. **Trigger = the staging moment.** The conventions already define "unit is committable"
     precisely ("Stage finished work automatically … when a coherent piece of work is done,
     `git add` the files it touched"). Piggyback on that signal — no new judgment call. NOT
     archive-time-only: work can be done and committed long before its task archives (the gacalc
     cross work awaited a release), so archive-only leaves docs stale across sessions. The
     archive-time reference-doc harvest stays as-is, on top.
  2. **Scope per unit = the docs the unit conceptually touches** (the module-layout line, the
     feature's README mention, the relevant reference doc) — NOT a full always-read re-read per
     unit; the full re-read remains the session-end sweep's job.
  3. **Both repos**: this file's edits here, and the same change to runCrushInContainer's ported
     conventions (its `client/entrypoint/dotfiles/.config/crush/CLAUDE.md`).
- **Accepted cost:** a unit redesigned later in the same session gets its docs written twice —
  same cost the code pays; that is why the trigger is "verified + staged", not "every edit".

## Edit points (this repo: `entrypoint/dotfiles/.claude/CLAUDE.md`)

1. **"Git: I commit, you don't — but you DO stage"** — extend the "Stage finished work
   automatically" bullet (or add a sibling bullet): staging a finished unit INCLUDES the
   always-read-doc deltas it implies (project CLAUDE.md, README, the pertinent
   `tasks/reference/` doc), so staged = complete handoff, docs included.
2. **"Ending a session — sweep the always-read docs"** — reword the preamble: the sweep is now a
   *verification pass* that should find nothing from properly-finished units; it still catches
   decisions made only in conversation, cross-repo drift, and units redefined mid-session.
   Cross-reference the staging rule.
3. Edits are live immediately (the file is bind-mounted as `~/.claude/CLAUDE.md`); no image
   rebuild needed.

## Open questions

None — design settled; the remaining gate is the maintainer's go-ahead to make the edits.
