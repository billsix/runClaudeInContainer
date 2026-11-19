# Python standard: a package ships its type information

**Status:** proposed — needs go-ahead (open questions below)
**Priority:** 4
**Difficulty:** 2
**Created:** 2026-11-19 (William Emerison Six <billsix@gmail.com>)
**Touches:** this repo and github.com/billsix/runCrushInContainer (the two copies); not the personal overlay.

## BLUF

Add a rule to the shared Python coding standard: a Python package that others install ships its
type information, so their type checkers can check the code that calls it. That means a `py.typed`
marker for a typed pure-Python package, a `.pyi` stub for a compiled extension, and an install
mode that static checkers can follow wherever one is meant to check against the package. Done
means the rule is in `tasks/reference/python-coding-standard.md` here, and runCrushInContainer's
two copies are byte-identical to it again.

## Context

- **Where the rule goes.** `tasks/reference/python-coding-standard.md` is the canonical copy. Its
  banner names two byte-identical copies in runCrushInContainer
  (github.com/billsix/runCrushInContainer): its `tasks/reference/python-coding-standard.md`, and
  the baked Crush client set `client/entrypoint/dotfiles/.config/crush/reference/python-coding-standard.md`.
  The rule is "edit the canonical, then re-copy it over the other two". On 2026-11-19 all three
  were byte-identical (`cmp`).
- **Why (found 2026-11-19, in github.com/billsix/geometricalgebra's
  `tasks/archive/2026/11/19/notebooks-one-directory.md`).** Three gaps together kept pyright from
  checking 31 notebooks:
  1. ePiX (github.com/billsix/epix-mirror) ships a nanobind extension with no `.pyi` and no
     `py.typed`. Everything re-exported from it is unknown to a checker, and pyright reports each
     such name as an "unknown import symbol" error. epix-mirror's fix is its
     `tasks/archive/2026/11/19/ship-python-type-information.md`.
  2. gacalc, which other projects import (modelviewprojection), ships no `py.typed`.
     geometricalgebra's `tasks/gacalc-ships-py-typed.md` fixes that.
  3. setuptools' default editable install (`pip install -e`, `uv pip install -e`) writes an
     import-hook finder (`__editable___<name>_finder.py`). pyright and ty cannot follow it, even
     when the package does carry stubs. `--config-settings editable_mode=compat` (a path-based
     `.pth`) or a non-editable install can be followed.
- **Facts the rule can cite.** PEP 561 defines the `py.typed` marker and stub packages
  (`<name>-stubs`). Without the marker, mypy does not use a package's inline annotations at all,
  and pyright infers types from the source instead (`useLibraryCodeForTypes`), which is weaker.
  `nanobind.stubgen` (`python -m nanobind.stubgen -m <pkg>.<ext>`) and pybind11-stubgen write a
  `.pyi` from a built extension, including its argument names.

## Plan

1. Add a section to the "(b) Judgment calls" part of the canonical standard, near "Type
   annotations — annotate every binding". It says:
   - a package others install ships `py.typed`, listed as package data;
   - a compiled extension ships a generated `.pyi`, committed, with a gate that regenerating it
     changes nothing (or regenerated on every build, if that is the decision below);
   - a project whose checkers must see an editable-installed dependency installs it in compat
     mode;
   - a project that cannot fix a dependency allows that one module to be unresolved, by name
     (ty's `allowed-unresolved-imports`), and records the exclusion with a pointer to the
     upstream task, never a blanket rule suppression.
2. Cite the incident in one line, by repository URL (no container paths).
3. Re-copy the file over runCrushInContainer's two copies, and `cmp` all three.
4. List the projects the sweep would touch (any repo of the maintainer's that builds a package or
   an extension), but do not change them in this task; each fix is a task in its own repository.

## Open questions

1. **A committed `.pyi`, or generate it at build time?** Recommend: committed, plus a gate that
   regenerating it changes nothing, so the API is readable without a compiler and a binding
   change shows up in review. This matches epix-mirror's task, Q1.
2. **Scope: only packages other projects install, or every package?** Recommend: only packages
   other code imports (a library, a published tool's API). An application nobody imports gains
   nothing from `py.typed`.
