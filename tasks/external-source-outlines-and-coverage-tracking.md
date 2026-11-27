# A convention for holding an external book's outline, citing it, and tracking which of its topics a project has covered

**Status:** ready — the five questions were answered 2026-11-27 (see "Notes / decisions"); not started
**Priority:** 4
**Difficulty:** 5
**Created:** 2026-11-27 (William Emerison Six <billsix@gmail.com>)
**Touches:** this repo (a new convention, possibly a shared tool beside `tasks/reference/review_status.py`);
github.com/billsix/runCrushInContainer through its mirror task
`tasks/external-source-outlines-and-coverage-tracking.md`; github.com/billsix/geometricalgebra as the
first consumer; github.com/billsix/impo through `tasks/research-illustrative-mathematics-geometry-build.md`.
**Related:** `tasks/review-record-shows-dispositions.md` (the same derived-status problem, for review records)

## BLUF

The maintainer wants a systematic way to hold the outline of a book he does not own the rights to
(chapters, lessons, topics, page numbers), to cite it from his own book, and to see at any time which
of its topics his book has covered, plans to cover, has decided to skip, or has not addressed. The
investigation of 2026-11-27 concluded that a hand-maintained reference doc is the wrong home for the
coverage half, and the maintainer chose a data file per source plus a status derived by a tool. The
outline is never finished: he adds to it over months, a few topics at a time. Done means the
convention is written into the shared conventions, the tool exists, and geometricalgebra uses both
for its first source.

## Context

**What the maintainer is trying to do** (2026-11-27, paraphrased from the conversation that made this
task). github.com/billsix/geometricalgebra is a library and a book, "Geometry 2": a course for high
school or early college that sits where "Algebra 2" sits for algebra, and that bridges to linear
algebra by teaching geometric algebra (frames, for example, carry much of what a linear algebra course
teaches). Linear algebra had little meaning to him as a student; this book is meant to give it one.
To write it he reads a standard high-school geometry textbook (Charles et al., *Geometry: Common
Core*, Pearson, 2012) and picks the topics he wants to connect to geometric algebra. That reading
takes months, and so does the writing, with long gaps between deciding "I want to cover this" and
doing it. In his words: "I won't be able to remember." He wants to comply with US copyright law and
to cite heavily.

**What exists today in geometricalgebra** (read 2026-11-27):

- `tasks/reference/high-school-geometry-objects.md` lists the textbook's geometric objects with a
  vector construction, a gacalc call and a "Where" column naming the book page that builds each one,
  with entries such as "(not built)". That column is typed by hand. The doc says the textbook "was
  not read": its lesson titles and page numbers came from two public web lists and are marked to be
  confirmed against the maintainer's copy.
- The maintainer has since typed the table of contents from his own copy into an untracked file,
  `fromPearsonbook.txt`, in his checkout: twelve chapters and their lesson titles as an outline, with
  no page numbers. Compared with the reference doc it confirms the lesson numbering of chapters 4, 5
  and 7 to 12 and lacks a few lessons the doc cites (1-6 to 1-8, a first lesson in chapters 1 and 3,
  one lesson in chapter 6, and chapter 13).
- Two book pages (`book/docs/geometry-from-vectors.rst`, `book/docs/product-from-projection.rst`) cite
  the textbook by hand in prose. The book has no bibliography mechanism.
- The repo already has a grep-able pairing convention: a Lean theorem and its Python twins carry the
  same `twin: <qualified Lean name>` comment (`tasks/reference/lean-python-notebook-workflow.md`
  there). It has no checker; the decision was grep.

**What these conventions already say** (this repo, read 2026-11-27: the shared `CLAUDE.md`, the
reference, task and review convention docs, the slash commands, `review_status.py`, `README.md`,
`FORKING.md` and the docs nearest the question in full; the language standards, the podman docs, most
of the archive and the build files were keyword-searched only):

- A reference doc "states what is TRUE" and is updated in place
  (`tasks/reference/reference-doc-conventions.md`). A fixed edition's outline fits that. A pinned
  external source gets a banner and a re-sync check ("Reference docs for a versioned dependency");
  for a book the banner is the edition, ISBN and printing.
- Status is the part that does not fit. `tasks/reference/repo-review-conventions.md`: "Status is
  derived, never written into the record", and the first deep review found a dated coverage table in
  `tasks/reference/` that had become false.
- `tasks/reference/review_status.py` derives done / open / untracked for a review record from the
  `**Source:**` lines of tasks. It reads only two heading levels and `[F<n>]` follow-up IDs, and its
  "done" means "the citing task is archived"; it has no field for where a product covers an item.
- `tasks/review-record-shows-dispositions.md` (open) is the same problem for review records; its
  leaning is a generated, committed status sidecar written by `review_status.py --write`.
- The closest precedent for indexing a copyrighted book is `tasks/reference/cpp-coding-standard.md`,
  which paraphrases Meyers' *Effective C++* items in one line each, "kept with their item numbers so
  a review can cite them". It has no pages and no coverage.
- `/new-reference-set` makes a `README.md` map with `compared-to` and Status columns; that board is
  hand-maintained.
- Line numbers rot; cite by stable named anchor. The same holds for the page numbers of the
  maintainer's own book, which shift as it is revised.
- Nothing in the conventions covers quoting third-party prose, fair use, or keeping copyrighted book
  text out of git; the licence rules (`tasks/reference/reimplementing-third-party-libraries.md`,
  `tasks/reference/vendoring-third-party-source-deps.md`) are about code. There is no convention for
  structured data files beside docs.
- A precedent for structured data that follows a book's chapters exists in github.com/billsix/impo:
  `study/cliffnotes/*.toml` and `study/bank/*.toml`, from which PDFs and a quiz are generated.

**Copyright, from the primary sources** (fetched 2026-11-27; the agent is not a lawyer, and
`tasks/reference/reimplementing-third-party-libraries.md` already says "This is not legal advice"):

- 37 CFR 202.1(a) lists as not subject to copyright "Words and short phrases such as names, titles,
  and slogans" and "mere listing of ingredients or contents"
  (https://www.law.cornell.edu/cfr/text/37/202.1). Copyright Office Circular 33, revised 03/2021,
  says the same (https://www.copyright.gov/circs/circ33.pdf).
- 17 U.S.C. 102(b): copyright does not extend to "any idea, procedure, process, system", concepts or
  principles (https://www.law.cornell.edu/uscode/text/17/102). The mathematics is free; the
  publisher's wording, figures, examples and exercises are protected expression.
- A compilation can have thin protection for its selection and arrangement (Feist v. Rural). No
  ruling on a textbook's table of contents was found. A whole table of contents copied verbatim into
  a public repository is the one soft spot; the fair-use factors (17 U.S.C. 107,
  https://www.law.cornell.edu/uscode/text/17/107) look favourable for a factual citation index that
  replaces nothing, but this is a judgment, not a finding.
- geometricalgebra has a public GitHub remote, so anything committed there is published.
- Illustrative Mathematics' terms of use (https://www.illustrativemathematics.org/terms-of-use,
  "Effective as of May 21, 2026"): the first edition of IM K–12 Math (© 2019–2021), which includes a
  high-school Geometry course, is CC BY 4.0; the second edition, v.360 (© 2024), is CC BY-NC 4.0. A
  text the maintainer may quote and adapt with attribution.
- The Common Core standards' public license grants copying "for purposes that support the Common
  Core State Standards Initiative" and requires a copyright notice. That text was read on an
  unofficial mirror (https://www.thecorestandards.org/public-license/) and needs checking against
  the licensor's own page before anyone relies on it.
- State textbook adoption uses the same shape as the proposal below: a publisher fills a correlation
  chart that gives a page number per standard (for example Virginia's,
  https://doe.virginia.gov/home/showpublisheddocument/53833/638488786004870000).

## Goal

A convention, and whatever small tool it needs, by which a project can (1) hold the outline of an
external source in a form that is cheap for the maintainer to add to, (2) cite that source
consistently from the project's product, and (3) get, on demand, an accurate list of the source's
topics by status, without anyone maintaining that list by hand.

## The design (the agent's proposal, accepted by the maintainer 2026-11-27)

1. **One data file per external source**, for example `book/sources/pearson-geometry-2012.toml` in
   geometricalgebra. A banner pins the edition and ISBN. Each lesson or topic has a stable ID (such
   as `pearson-geo/5-4/median`), the source's page number with a flag saying whether it was verified
   against the maintainer's copy, the topic in the maintainer's own words, and a decision: want,
   skip (with the reason) or undecided.
2. **Coverage is read from the product, not typed into the data file.** A book page or notebook
   carries a grep-able tag naming the source ID, like the `twin:` tags. A task that plans a topic
   cites the same ID. The tag points at a page name or equation label of the maintainer's book,
   never its page number.
3. **A report tool** prints each topic as covered (a page tags it), planned (an open task cites it),
   skipped on purpose, or not addressed, and flags tags whose ID does not exist. A report, not a
   gate.
4. **A reference doc keeps the prose** (in geometricalgebra, the vector construction per object);
   its hand-kept status column goes away.
5. **Citations come from the same data**: one citation key per source file, so the wording and page
   numbers in the product are consistent.
6. **Capture stays free-form.** The maintainer types rough outlines (as in `fromPearsonbook.txt`);
   an agent turns them into entries. Only the maintainer can supply page numbers.
7. **What is committed:** lesson titles, page numbers and own-words descriptions. Never the
   publisher's definitions, exercises or figures. Verbatim study notes stay out of git.

### The outline grows over time (a requirement, the maintainer, 2026-11-27)

The maintainer will keep asking an agent to add material to an outline: a lesson he has just read,
a page number, a topic inside a lesson, a whole new source. Additions and the writing that covers
them may be months apart. So the convention must hold these:

- **A partial outline is valid.** A source file may hold three lessons of one chapter. The report
  says what it has; it never treats a missing lesson as an error.
- **Adding never renumbers.** A topic's ID is fixed when it is first written and is never reused or
  changed, because book pages and tasks cite it. A correction to a title or page number edits the
  entry and keeps the ID. A topic entered by mistake is marked withdrawn, not deleted, if anything
  cites it.
- **Every entry records when it was added** and, for a page number, whether the maintainer checked
  it against his copy. The report can then list "added since <date>" and "page not verified".
- **Adding is one small request.** "Add lesson 5-4, medians and altitudes, p. 312, I want medians"
  is enough: the agent writes the entries, leaves the decision `undecided` where he gave none, and
  runs the report. The convention says what the agent does with such a request, so each session does
  it the same way.
- **A new topic starts as "not addressed"** with no further work: status is derived, so nothing else
  has to be updated when an entry is added.
- **A new source is a new file** in the same format (a linear algebra text, Illustrative Mathematics
  Geometry), and one topic of the maintainer's book may cite several sources.

Alternatives considered:

- **A plain reference doc with a hand-kept status column.** Simplest; it is what exists today, and
  it drifts.
- **A layered reference set** whose `README.md` map has the `compared-to` and Status columns. Fits
  the "compare to a baseline the reader knows" rule, but the board is hand-maintained.
- **Treat the outline as a frozen record and reuse `review_status.py`.** The tool would need topic
  IDs, a third level and a field for where the product covers a topic; a small sibling tool, or the
  `--write` sidecar proposed in `tasks/review-record-shows-dispositions.md`, is the real cost.

## Plan

- [x] The maintainer answers the open questions (2026-11-27).
- [ ] Write the convention: a section in the shared `CLAUDE.md` (terse) and a reference doc (the
      detail, including the copyright rule of thumb and its sources), mirrored to runCrushInContainer.
- [ ] Build or extend the tool, decided together with `tasks/review-record-shows-dispositions.md`
      if question 5 is answered yes.
- [ ] In geometricalgebra, as its own task there: the first source file from `fromPearsonbook.txt`
      and `tasks/reference/high-school-geometry-objects.md`, tags on the pages that already cover a
      topic, and the reference doc's status column removed.

## Notes / decisions

- 2026-11-27: investigation only. No file in geometricalgebra was changed.
- **Decisions (William Emerison Six <billsix@gmail.com>, 2026-11-27: "your recommendations for all
  5"):**
  1. A data file per source plus a report tool, not a hand-maintained reference doc.
  2. Coverage is read from tags in the product's pages, like the `twin:` tags, not typed into the
     data file.
  3. Illustrative Mathematics Geometry, first edition (CC BY 4.0), becomes a second source. Whether
     impo builds it is a separate question the maintainer has deferred
     (github.com/billsix/impo `tasks/research-illustrative-mathematics-geometry-build.md`).
  4. Each topic may carry its Common Core code as a key shared across textbooks.
  5. This is designed together with `tasks/review-record-shows-dispositions.md`: one derived-status
     mechanism for review records and source outlines.
- The same day he asked that the task account for the outline growing over time; that is "The
  outline grows over time" above.
- The strongest argument for a mechanism over one document is that the geometry textbook will not be
  the only source: the bridge to linear algebra means a linear algebra text gets the same treatment,
  and each is one more file.

## Open questions

None open. The five asked on 2026-11-27 are answered under "Notes / decisions".
