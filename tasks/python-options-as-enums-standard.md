# Python standard: options and mode parameters are enums, not strings

**Status:** proposed — waits on the gacalc sweep (github.com/billsix/geometricalgebra `tasks/options-as-enums.md`)
**Priority:** 4
**Difficulty:** 2
**Created:** 2026-11-10 (William Emerison Six <billsix@gmail.com>)
**Branch:** `python-standard-enum-options`

## BLUF

Add a judgment-call rule to `tasks/reference/python-coding-standard.md` (section "(b) Judgment calls"):
a parameter that selects one of a fixed set of options takes an `enum.Enum`, never a string or a
`Literal[...]` of strings, and the function dispatches on it with `match` + `case _` (ties to the
existing "Prefer match + case _" rule). Cite the gacalc sweep as the worked example once it is done.
Then mirror the identical text into github.com/billsix/runCrushInContainer (its
`tasks/reference/python-coding-standard.md` and the baked copy under
`client/entrypoint/dotfiles/.config/crush/reference/`; task `tasks/python-options-as-enums-standard.md`
there). Done means: the rule is in all three copies, byte-identical where the copies are meant to be.
