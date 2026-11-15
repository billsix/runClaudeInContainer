# Checked the Python-deps rule across the shared conventions and the overlay: already consistent

**Status:** complete — no change needed
**Completed:** 2026-11-15
**Priority:** 3
**Difficulty:** 2
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.1 F4

## What this found

The review (§1.1) reported that the shared `CLAUDE.md` and `python-coding-standard.md` ("the venv
copy wins") contradicted the personal overlay ("prefer distro `python3-*` with
`--system-site-packages`"). The overlay the review read was a stale copy mounted into the sandbox
at session start. The overlay itself (github.com/billsix/dotfiles
`.ai-coding-conventions.personal.md`, "Python deps — every package in the venv (the venv copy
wins); lock the whole set") was revised on 2026-11-12, after the modelviewprojection incident in
which distro-matching pins duplicated 15 packages and plain `pip` left `/venv/bin` without
`pytest`/`sphinx-build`. All three files state the venv-wins rule.

The maintainer's answer to the review's question 2 was "go with the newer one", which is that
rule. The record carries a dated correction.

## Verification

`grep -c "venv copy wins"` → 1 in the dotfiles overlay and 0 in the stale mounted copy;
`cmp` shows the mounted copy differs from the overlay. No file changed.
