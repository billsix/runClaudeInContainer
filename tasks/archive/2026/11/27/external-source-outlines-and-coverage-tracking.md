# A convention for holding an external book's outline, citing it, and tracking which of its topics a project has covered

**Status:** done 2026-11-27
**Priority:** 4
**Difficulty:** 5
**Created:** 2026-11-27 (William Emerison Six <billsix@gmail.com>)
**Touched:** this repo; github.com/billsix/runCrushInContainer (its mirror task of the same name);
github.com/billsix/geometricalgebra (the first user, its
`tasks/archive/2026/11/27/external-source-outline-pearson-geometry.md`).
**Related:** `tasks/review-record-shows-dispositions.md` (the same derived-status problem, for review
records); github.com/billsix/impo `tasks/research-illustrative-mathematics-geometry-build.md`
(deferred by the maintainer).

## What this did

Added a convention and a tool by which a project keeps the outline of a book it does not own
(chapters, lessons, topics, page numbers) in `tasks/sources/<key>.toml`, tags the pages of its own
product that cover an entry, and gets the list of covered, planned, skipped and not-addressed
entries from a report, never from a hand-kept column. The durable description is
`tasks/reference/external-source-outlines.md`; this record keeps what led to it.

## Why

The maintainer's github.com/billsix/geometricalgebra is a library and a book, "Geometry 2": a
course for high school or early college, placed where "Algebra 2" sits for algebra, that bridges
to linear algebra through geometric algebra. He reads a standard high-school geometry textbook
(Charles et al., *Geometry: Common Core*, Pearson, 2012) for topics to connect to it. Deciding to
cover a topic and writing it are months apart ("I won't be able to remember"), and he keeps adding
topics as he reads. He wanted to comply with US copyright law and to cite heavily. He asked
whether a reference doc was the right home for the outline.

## What the investigation found (2026-11-27)

- geometricalgebra's `tasks/reference/high-school-geometry-objects.md` already listed the
  textbook's objects with a hand-typed "Where" column ("(not built)", a page name). That is the
  hand-kept status the review conventions rule out: "Status is derived, never written into the
  record" (`tasks/reference/repo-review-conventions.md`), and the first deep review had found such
  a table gone false.
- The outline itself fits a reference doc (a fixed edition does not change), but it is data: it
  grows entry by entry and a tool has to read it.
- `tasks/reference/review_status.py` could not be reused as it stood: it reads two heading levels
  of a Markdown record and `F<n>` IDs, and its "done" means "the citing task is archived".
- Nothing in the conventions covered quoting third-party prose or keeping book text out of git; the
  licence rules were about code. No convention existed for data files beside docs. The nearest
  precedents: `tasks/reference/cpp-coding-standard.md` paraphrases Meyers' items by number, and
  github.com/billsix/impo generates study material from `study/cliffnotes/*.toml`.
- Copyright, from primary sources (quoted in the reference doc, "What may be committed"): titles,
  short phrases and bare listings of contents are not protected (37 CFR 202.1(a), Circular 33);
  ideas are not, their expression is (17 U.S.C. 102(b)); a whole table of contents copied verbatim
  is the one soft spot (compilation, Feist), and no ruling on a textbook's was found.
- Illustrative Mathematics' first edition, which includes a Geometry course, is CC BY 4.0; its
  v.360 edition is CC BY-NC 4.0. The Common Core standards' public license was read only on an
  unofficial mirror.

What was read: the shared `CLAUDE.md`, the reference, task and review convention docs, the slash
commands, `review_status.py`, `README.md`, `FORKING.md` and the docs nearest the question in full;
the language standards, the podman docs, most of the archive and the build files by keyword only.

## Decisions (William Emerison Six <billsix@gmail.com>, 2026-11-27: "your recommendations for all 5")

1. A data file per source plus a report tool, not a hand-maintained reference doc.
2. Coverage is read from tags in the product's pages, like geometricalgebra's `twin:` tags, not
   typed into the data file.
3. Illustrative Mathematics Geometry, first edition, becomes a second source. Not done here:
   whether impo builds it is the deferred impo task above, and no outline of it exists yet.
4. Each entry may carry its Common Core code (the `standards` field; none entered yet).
5. Designed together with `tasks/review-record-shows-dispositions.md`.

He also required that the outline can grow over months, a few entries at a time, with one small
request per addition.

## What was built

- `tasks/reference/source_coverage.py`: the report tool, a sibling of `review_status.py`, run in
  place. Doctests, `ruff` (E, F, I, N, UP, B), `ty` and `check_local_annotations.py` pass.
- `tasks/reference/external-source-outlines.md`: the file format, the ID rules, the growth rules
  and the steps for "add this to the outline", what may be committed and the sources for it, the
  `covers:` tag, task citations, the report's options.
- `entrypoint/dotfiles/.claude/commands/source-coverage.md`: `/source-coverage`.
- `entrypoint/dotfiles/.claude/CLAUDE.md`: a short section, "External source outlines", and a
  read-on-demand trigger for the doc.
- `CLAUDE.md` (this repo): the tool named among the shared tools run in place.

Calls made while building, beyond the five decisions:

- **`tasks/sources/`, not a folder inside the product** (the task first proposed
  `book/sources/`). The conventions put every such directory under `tasks/` in every repo, so the
  session-start habit and the tool find it in one known place.
- **Entry IDs are short names, not the source's numbers.** geometricalgebra's lesson numbers came
  from a curriculum map, not the book, and may be corrected; an ID that pages cite must not change
  with them.
- **A tag or citation counts for the entry it names only**, not for the entries under it. A page
  that covers one topic of a lesson does not mark the lesson's other topics covered.
- **Decision 5 in practice:** the two tools share the task citation form, `**Source:** <path>
  <item IDs>`, each reading up to the next `tasks/` path, so one line can cite a review record and
  an outline. No shared module: each tool is one file, mirrored byte for byte. A generated,
  committed status file is option (C) of `tasks/review-record-shows-dispositions.md`, which the
  maintainer has not chosen; `source_coverage.py` has no `--write`, and should gain the same one
  as `review_status.py` if (C) is picked.
- **Citations:** `--cite <key>/<entry>` prints the wording for one entry. Feeding a Sphinx
  bibliography from the outline was not built.
- **A report, not a gate.** It exits 0 whatever it finds.

## Verification

Run in geometricalgebra on its first outline (127 entries, eight tagged book pages, one citing
task): 30 covered, 2 planned, 95 not addressed, no problem lines; `--status planned`,
`--unverified-pages` (31 rows) and `--cite` gave the expected output. The slash command was not
run through a fresh session.

## Order of events (2026-11-27, from the commit history before it was squashed)

1. The maintainer showed a table of contents he had typed from his copy of the textbook and asked
   whether a reference doc was the right home for it. The investigation above followed, and the
   task was added as *proposed* with the proposal, three alternatives (a reference doc with a
   hand-kept column, a layered set's status board, reusing `review_status.py`) and five open
   questions. A mirror task was added in runCrushInContainer and a research task in impo.
2. He answered all five with the agent's recommendations and asked whether the design allowed for
   adding to an outline over time. It did only in passing, so the growth rules were written into
   the task before anything was built: a partial outline is valid, an ID never changes, each entry
   records when it was added, one small request adds an entry.
3. The tool, the reference doc, the command and the conventions section were written, in that
   order, then geometricalgebra's first outline, then the runCrushInContainer mirror. Two things
   changed while writing the first outline: IDs became names instead of lesson numbers (the
   numbers turned out to come from a curriculum map, not the book), and the directory became
   `tasks/sources/`. A first draft of the tool tracked tags of unknown sources in a variable that
   could never be non-empty; it was removed before the first run.
4. The maintainer then asked for a task to outline Illustrative Mathematics' course in
   geometricalgebra and chose its newest edition whatever the licence; that task records what the
   non-commercial licence means for quoting.
5. Archive and session-end sweep: `tasks/sources/` was added to the list of directories that get
   a `.keep` (`tasks/reference/task-doc-conventions.md`), and the reference doc's pointer to this
   record was fixed.

## Left open

- The mirror in runCrushInContainer is staged with this work.
- `tasks/review-record-shows-dispositions.md` now also decides whether `source_coverage.py` gets
  `--write`.
- A second source (decision 3) and Common Core codes (decision 4) are
  github.com/billsix/geometricalgebra `tasks/external-source-outline-illustrative-mathematics-geometry.md`
  (ready; the maintainer chose the newest edition, v.360).
