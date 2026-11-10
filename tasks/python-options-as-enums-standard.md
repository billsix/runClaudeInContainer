# Python standard: options and mode parameters are enums, not strings

**Created:** 2026-11-10 (William Emerison Six <billsix@gmail.com>) · **Done:** 2026-11-10

Added the judgment-call section "Options are enums, not strings" to `tasks/reference/python-coding-standard.md`
(right after "Prefer `match` + `case _`"): a parameter selecting one of a fixed set of options takes an
`enum.Enum`, defaulted to a member and dispatched with `match`, whose `case _` raises `TypeError`
naming the enum; labels, titles, file names and library-dictated values stay `str`; converting a
published API is a breaking change. The worked example is github.com/billsix/geometricalgebra
(`frame.InverseMethod`, `functions.MatrixBackend`; its archived task
`tasks/archive/2026/11/10/options-as-enums.md`).

The same section went into github.com/billsix/runCrushInContainer (its `tasks/reference/` copy and the
baked copy under `client/entrypoint/dotfiles/.config/crush/reference/`), inserted into each copy
as-is: the three copies already differed before this change, and re-syncing them is runCrush's
`tasks/audit-baked-reference-doc-drift.md`.
