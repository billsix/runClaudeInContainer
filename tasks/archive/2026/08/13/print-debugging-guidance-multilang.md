# Print-statement debugging guidance — augment source, then read the output — across languages

**Status:** DONE 2026-08-13 — reference doc written + all 9 recipes verified in-sandbox;
lean pointer added to the cross-project CLAUDE.md.
**Priority:** 4
**Difficulty:** 4
**Created:** 2026-08-12
**Updated:** 2026-08-13 — implemented.

## Work log (2026-08-13)

- Wrote **`tasks/reference/print-debugging.md`**: the language-independent method
  (stderr, flush, bracket, self-label, `DBG` marker, diff-the-trace) + per-language
  recipes (stderr+flush idiom, compound-value dump, gotcha) for **C, C++, Python, Java,
  Scheme, Haskell, Rust, Go, shell** + a Removal section.
- Added a lean pointer in the mounted cross-project `CLAUDE.md`
  (`entrypoint/dotfiles/.claude/CLAUDE.md`) at the end of "Instrumentation-driven
  debugging" — framed as the hand-instrumentation half, pointing at the reference doc.
- **Every recipe verified in the sandbox** (not just written from memory): Python
  `{x=}`, shell `>&2`/`declare -p`, C `fprintf`+`__FILE__`, C++ `std::cerr`, Rust
  `eprintln!`/`dbg!` (confirmed `dbg!` prints `[file:line:col] expr = value` and returns
  the value), Haskell `trace`/`traceShowId` (confirmed the lazy interleave), Go
  `%+v`/`%#v`/`log`, Java `System.err`/`Arrays.toString`, Racket `eprintf`. All produced
  the documented output.

**Motivation:** print-based instrumentation is one of the most effective ways to debug
an unfamiliar or misbehaving program, and it generalizes across every language — but the
*mechanics* differ per language (how you emit to stderr unbuffered, how you dump a
struct/record/tree, how you avoid the print being optimized/buffered away). The agent did
this well on the Majora's Mask work; that method should be captured as **standing
guidance** so it's applied consistently. This is the print-statement sibling of the
existing "Instrumentation-driven debugging" convention (which is currently framed around
compilers/linters/tracers as oracles) — this adds the *hand-instrumentation* half.

## Goal

Write durable guidance on **augmenting source code with print/trace statements to
debug**, then removing them cleanly — with concrete, correct per-language recipes.

Languages to cover (locked 2026-08-12): **C, Python, Java, Scheme, Haskell** (named) +
**C++, Rust, Go, shell** (the common sandbox toolchains Bill added). Nine total.

## What each language section needs

A short, checkable recipe, not prose. Per language:

- **The idiomatic print + where it goes** (prefer **stderr**, so it doesn't corrupt stdout
  data), and the **unbuffered/flush** trick so output isn't lost on a crash — this is the
  gotcha that bites in most languages:
  - C: `fprintf(stderr, ...)` + `fflush(stderr)` (or `setvbuf`); `__FILE__`/`__LINE__`/
    `__func__`.
  - Python: `print(..., file=sys.stderr, flush=True)` (or `logging`); `f"{x=}"` self-labeling.
  - Java: `System.err.println` (auto-flush) vs `System.out`; `Objects.toString`.
  - Scheme: `(write x (current-error-port))` / `display` + `newline`; flushing the port.
  - Haskell: `Debug.Trace.trace` / `traceShow` (pure code, the key one — you can't just
    `putStrLn` inside a pure function); `hPutStrLn stderr` + `hFlush` in `IO`; note the
    laziness caveat (a trace tied to a thunk fires only when forced).
- **Dumping a compound value** (struct/record/object/tree) legibly.
- **Making it findable and removable** — a distinctive marker prefix (e.g. `DBG:`) so a
  single grep finds every temporary print for removal, and a note to strip them before
  calling work done.

## Cross-cutting method (the reusable part)

- **Bracket the suspect region:** print on entry/exit with a tag, so you see control flow,
  not just values.
- **One variable per probe**, labeled with its name (`x=` style), so output attributes
  itself.
- **Flush or you'll lie to yourself:** a buffered print swallowed by a crash points at the
  wrong line — always flush/unbuffer stderr when chasing a crash.
- **Diff the trace** against a known-good run when one exists (ties into the existing
  "derive the before mechanically" convention).

## Where this lives (confirmed 2026-08-12: runClaudeInContainer)

Home = **runClaudeInContainer** (Bill confirmed). Concretely: a new **reference doc** in
`tasks/reference/` (which is mounted at `~/.claude/reference/` and, per this repo's
convention, is the place for detailed guidance), with a short pointer added to the mounted
cross-project `CLAUDE.md` "Instrumentation-driven debugging" section — keeping `CLAUDE.md`
lean. This is agent-facing debugging guidance, so it stays **markdown** (the LLM track);
it does not need a human-readable Sphinx version.

## Open questions

None — ready to implement on go-ahead. (Language set decided above: the nine listed.)

## See also

- Cross-project `CLAUDE.md` → "Instrumentation-driven debugging (make the tools tell you
  what to do)" — the section this extends.
- `tasks/sphinx-human-readable-reference-docs.md` — decides the format any new reference
  doc is written in.
