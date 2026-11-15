# Make the shared Python-deps rule match the personal overlay (distro first)

**Status:** proposed — in the 2026-11-15 audit batch
**Priority:** 3
**Difficulty:** 2
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.1 F4

## BLUF

The shared `CLAUDE.md` and `python-coding-standard.md` say "the venv copy wins" (install every package with uv into `/venv`), while the personal overlay says prefer distro `python3-*` with `--system-site-packages`. The maintainer chose the overlay's newer rule. Done means the shared texts say the same thing and no doc still teaches the other.

## Context

- Shared `entrypoint/dotfiles/.claude/CLAUDE.md` section "Python deps in a container image: the venv copy wins, and lock everything".
- `tasks/reference/python-coding-standard.md:478-506` ("Pin direct dependencies").
- The personal overlay (github.com/billsix/dotfiles `.ai-coding-conventions.personal.md`, "Python deps — prefer distro `python3-*` …") is the rule to keep; it stays as is.
- runCrushInContainer mirrors this in its own batch (`crush/CLAUDE.md:398` and its standard copies).

## Plan

1. Rewrite the shared `CLAUDE.md` section to the distro-first rule (terse, pointing at the standard).
2. Rewrite the standard's section to match, keeping the pinning rules both agree on.
3. grep for other "venv copy wins" text and fix it.
