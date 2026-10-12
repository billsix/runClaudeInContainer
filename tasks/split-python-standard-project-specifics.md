# Split project-specifics out of the shared Python coding standard

**Status:** done 2026-10-12 (William Emerison Six <billsix@gmail.com>)
**Priority:** 5
**Difficulty:** 4

## BLUF

The shared `tasks/reference/python-coding-standard.md` — meant to be portable across the
maintainer's Python repos — had accumulated **modelviewprojection- and gacalc-specific**
content: an entire `## modelviewprojection-specific additions` section, gacalc worked examples
(`base.reject`, `nbplotutils._to_xy`, `measure.content_by_rejection`), gacalc type-layer asides
(`ComposableFunction`/`InvertibleFunction` invariance, the annotation-sweep exemptions), and
cross-links to two gacalc-only docs. This task did the **full split**: the shared doc now holds
**portable rules only**, and every project-specific rule, worked example, and file path moved to
that project's own additions doc. Done = the shared doc names no one project's files, each
project's `CLAUDE.md` points at both the shared doc and its own additions doc, and the three
byte-identical copies are back in sync.

## What moved where

- **Shared doc (canonical: this repo `tasks/reference/python-coding-standard.md`):** kept the
  portable rules; removed the mvp section; genericized every gacalc example/aside (the fold
  example, the loop/unpack and reuse-across-loops examples, the generics example, the
  externally-defined-name and protected-terse-name examples, the docstring example, the modern-
  Python `requires-python` aside); rewrote the extraction section to state the rule without the
  `base.reject` code block; replaced the two gacalc Cross-links with pointers to the per-project
  additions docs; updated the header/provenance.
- **modelviewprojection** → new `tasks/reference/python-coding-standard-mvp.md` (line-length 80,
  the wx boundary, book-shorthand naming, the `m·x+b` keyword-call rule, composition style, the
  "`match` that was bitten" example, mvp inner-function precedents, GL/matrix conventions, the
  gacalc vector dialect, behaviour-faithful ports, demos duplication). mvp `CLAUDE.md` points at
  both docs.
- **geometricalgebra** → new `tasks/reference/python-coding-standard-gacalc.md` (the
  `content_by_rejection` fold example, the annotation-sweep exemptions + `check_annotations.py`,
  the `ComposableFunction`/`InvertibleFunction` invariance specifics, the `base.reject` /
  `nbplotutils` / `_draw_labelled_triangle` extraction examples, and the two gacalc cross-links).
  gacalc `CLAUDE.md` points at both docs.

## Files touched (4 repos)

- `runClaudeInContainer`: `tasks/reference/python-coding-standard.md` (the de-project-specified
  canonical) + this task doc.
- `runCrushInContainer`: the two byte-identical mirrors re-copied from the canonical —
  `tasks/reference/python-coding-standard.md` and
  `client/entrypoint/dotfiles/.config/crush/reference/python-coding-standard.md` (verified
  `diff`-clean against the canonical).
- `modelviewprojection`: new `tasks/reference/python-coding-standard-mvp.md`; `CLAUDE.md` pointer.
- `geometricalgebra`: new `tasks/reference/python-coding-standard-gacalc.md`; `CLAUDE.md` pointer.

## Context / why

The 2026-09-13 trim had moved mvp's rules *into* the shared doc so mvp's `CLAUDE.md` could point
at one place; convenient, but it made the "shared" doc carry one project's specifics (and the
general rules were illustrated almost entirely with gacalc code). The maintainer decided
2026-10-12 to reverse that: shared = portable, each project owns its specifics and worked
examples. Precedent for the shape already existed — gacalc already owned
`conditional-refactoring-rules.md` / `type-annotation-exemptions.md`, and both projects' CLAUDE.md
already kept repo-specific invariants inline.

## Note

The banner's rule stands: edits to the canonical must be re-copied to the two mirrors. Done here;
re-run `diff` against the canonical if in doubt.
