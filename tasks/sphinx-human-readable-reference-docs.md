# Human-readable Sphinx docs for gacalc's code generation, alongside the LLM markdown

**Status:** ready — all decisions made; awaiting go-ahead to implement
**Priority:** 5
**Difficulty:** 6
**Created:** 2026-08-12
**Updated:** 2026-08-12 — decisions locked: keep markdown for LLMs, ADD a **separate**
human Sphinx doc set (not the existing book), building **HTML + PDF**; first target is
gacalc's Python code generation; drift checked at task completion AND session end.

**Motivation:** the reference docs (`tasks/reference/*.md`) are markdown written for *the
agent*. Bill wants a **human-readable** reference, built with **Sphinx / reStructuredText**,
**in addition** to the markdown — not a replacement. The first concrete target is
**gacalc's Python code generation** (`tools/gen_specialized.py` + `astbuild.py`), currently
documented for the LLM in `tasks/reference/code-generator-architecture.md` and
`generated-product-typing.md`. Both tracks are wanted: markdown for LLMs, Sphinx for humans.

## Confirmed decisions (2026-08-12)

1. **Two tracks, both kept.** Markdown reference stays the machine/LLM-readable doc
   (as today). A **separate** human-readable Sphinx RST doc is added. Not a port,
   not generated from the markdown — **separate sources**. (That they are separate is
   exactly why drift is expected and must be checked; a generated doc couldn't drift.)
2. **First target = gacalc code generation.** The human Sphinx doc covers the Python
   code-generation story (how `G1`/`G2`/`G3` + graded types are generated from `Gn`).
3. **A separate Sphinx doc set** (locked 2026-08-12) — *not* folded into gacalc's
   existing `book/docs/` book. Stand up its own Sphinx project (a top-level document +
   reference sections), building **HTML + PDF** into `output/`. The scaffold is therefore
   real work and must be saved as an ad-hoc script (see below).
4. **Drift is a first-class maintenance obligation.** Because the markdown (LLM) and RST
   (human) docs describe the same machinery from two sources, they will drift. **Check
   for drift both at task completion and at session end** — codified as a convention in
   runClaudeInContainer's CLAUDE.md (extends the existing "Ending a session — sweep the
   always-read docs" pass).

## What to do

1. **Stand up a separate Sphinx/RST doc set in gacalc** (its own project, not the
   `book/docs/` book) and write the human code-generation doc in it — a top-level
   document + a code-generation reference section, pitched at a human reader (the design
   intuition, the `Gn`→specialized story, the symbolic→AST bridge — the *why/what*, not
   the agent's file:line bookkeeping).
2. **Keep** `tasks/reference/code-generator-architecture.md` and
   `generated-product-typing.md` as the LLM markdown track.
3. **Build HTML + PDF into `output/`** via gacalc's Dockerfile (the book pipeline already
   emits to `output/`; add a target/step for this separate doc set). Coordinate Dockerfile
   edits with `tasks/extract-dockerfile-steps-into-host-scripts.md`.
4. **Save the Sphinx scaffold as an ad-hoc script** under `tasks/adhoc/<this-slug>/` per
   the "one-time generative setup" rule — `sphinx-quickstart` for the new doc set plus the
   `conf.py` edits that shape it (HTML + PDF/LuaLaTeX). Since this is a *separate* project
   (not `.rst` files dropped into the existing book), there is real scaffolding to record.
5. **Add the drift-check convention** to runClaudeInContainer's mounted cross-project
   `CLAUDE.md` (`entrypoint/dotfiles/.claude/CLAUDE.md`): for any topic documented in
   *both* an LLM markdown reference and a human Sphinx doc, reconcile the two at task
   completion and at session end. Consider a small helper (a `tools/` checker that lists
   the paired doc topics) so the check isn't purely manual — decide during the work.

## Decisions (locked 2026-08-12)

1. **Separate Sphinx doc set**, not folded into gacalc's `book/docs/` book.
2. **Build HTML + PDF** into `output/`.

## Open questions

1. **Drift-check mechanism:** manual reconciliation (read both, fix), or a small
   `tools/` helper that at least *lists the paired topics* to reconcile? Recommend
   starting manual + a topic-pairing note in each doc's header, adding a helper only if
   the pairing grows. (Not blocking — can be decided during the work.)

## See also

- gacalc `tasks/reference/code-generator-architecture.md`, `generated-product-typing.md`
  — the LLM markdown track this pairs with.
- gacalc `tasks/reference/book-and-docs-pipeline.md` — the Sphinx→HTML/PDF pipeline.
- `tasks/extract-dockerfile-steps-into-host-scripts.md` — the other Dockerfile-editing task.
- `tasks/print-debugging-guidance-multilang.md` — stays markdown-only (LLM), decided here.
- Cross-project `CLAUDE.md` → "Reference documents" and "Ending a session — sweep the
  always-read docs" — the conventions the drift-check extends.
