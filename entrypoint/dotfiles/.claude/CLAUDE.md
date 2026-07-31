# Cross-project conventions

## Confirm before acting

When I ask you to **list, identify, find, plan, or investigate** something, that's a request for the information — **not** authorization to make changes. Produce the list / plan / findings and **stop**. Wait for my explicit go-ahead ("do it", "apply them", "go ahead") before editing files or running mutating commands. When a request is ambiguous between "tell me" and "do it," treat it as "tell me" and ask.

## "Use your discretion" — what that means, and use it

Once I've given the go-ahead, **"use your discretion" means finish the job and tell me
afterward — not come back and ask about each case.** If I've already stated the goal and
the constraint, don't re-ask me to confirm the thing I just said; deduce it. Re-asking
a settled question is the failure mode I'm trying to name here.

Discretion is **not** "do whatever." It's this, in order:

1. **Do the safe bulk automatically.** The large mechanical majority gets fixed without
   consultation.
2. **Pick the right mechanism per case** rather than one blunt tool. Different instances
   of "the same" problem often need different fixes.
3. **Notice where the obvious fix would destroy something valuable, and don't do it.**
   Opt out explicitly, in-code, with a written reason — never silently mangle it, and
   never silently skip it either.
4. **Notice where the obvious fix would be outright wrong** — the tool flagging it can't
   see the context that makes it unsafe. Use a different fix.
5. **Report the exceptions afterward**, briefly: what I did in bulk, what I opted out of
   and why. That's the part I actually need to review.

**This is language-agnostic.** I work in C, C++, assembly, shell, Make, Emacs Lisp, TeX
and Python; the shape above applies to any of them and to any enforcement tool —
`clang-tidy`/`clang-format`, a compiler warning sweep, `shellcheck`, `rustfmt`, a linter,
a codemod. The worked example below is Python because that's where it came up; read the
*structure*, not the tooling. The per-language particulars that change are only: what the
comment marker is, which tool reflows what, and how you spell an opt-out
(`# noqa: RULE`, `// NOLINT(rule)`, `/* clang-format off */`, `// eslint-disable-line`,
`#pragma GCC diagnostic ignored`, a `.editorconfig` exception).

**Worked example — enforcing an 80-column limit (mvp, Python/ruff, 2026-07-18).** 78
over-long lines, one instruction ("80 is good, I make a PDF of it; fix as much as
possible with your discretion"):

- **70 were prose** — comments and docstrings. Rewrapped automatically, no questions.
  Handled RST bullet continuation indent and Sphinx `#:` markers so the rewrap didn't
  corrupt structure.
- **2 were `import a.b.c as name`** at 88 chars. Rewrote as `from a.b import name` —
  identical binding, 71 chars. A different mechanism than wrapping, because wrapping an
  import is ugly and this is just better.
- **1 was an f-string.** Split with implicit concatenation, which cannot change the
  runtime value.
- **1 was a `//` comment inside a GLSL shader string.** Wrapping it would have pushed
  half a comment onto a new line as *invalid GLSL* — the linter can't see that it's
  shader source. Shortened the comment text instead.
- **4 were a hand-aligned 4×4 matrix literal** in a book *about matrices*, already
  carrying `# fmt: off` — the alignment IS the documentation. Left long with
  `# noqa: E501` and a comment saying why. Reflowing would have been technically
  compliant and actively worse.

## Never orphan a word on its own comment line

**Reflow the whole paragraph, not the offending line.** When a comment or docstring line
is over the limit, re-wrap the entire contiguous paragraph as a unit. Fixing the single
long line in isolation produces this, which I don't want:

```python
# stored ``steps`` field stay typed tuple[Step, ...] for readers while
# the
# constructor accepts the broader input.
```

A comment line holding one word or a short sentence fragment is always wrong. **This
applies to every comment syntax I use** — `#`, `//`, `/* … */`, `;;`, `--`, `%`, `!` —
and to doc comments (docstrings, doxygen `/** … */`, javadoc, `///` Rust doc comments)
just the same.

### Changing a line-length limit without causing that

Language-agnostic; the tool names are examples.

1. **Set the limit in config, in one place**, so the formatter and the linter agree.
   `[tool.ruff] line-length` (governs both `ruff format` and E501), `ColumnLimit` in
   `.clang-format`, `max_width` in `rustfmt.toml`, `printWidth` for prettier,
   `max_line_length` in `.editorconfig`. Then **remove any per-invocation
   `--line-length`-style flags** from format scripts so there's a single source of truth
   — a formatter at 80 with a linter at 88 quietly lets new long lines land.
2. **Run the formatter first.** It reflows *code* for free. Whatever survives is prose
   and unbreakable tokens — that's the real work-list, and it's much smaller. Note which
   side of the line your formatter sits on: `ruff format`/`black`/`gofmt` won't touch
   comment prose at all, while `clang-format` *will* if `ReflowComments` is on — and if
   it is, let it do the bulk and only hand-check what it leaves.
3. **Fix the residue paragraph-wise, and do NOT try to automate it.** I tried; it doesn't
   generalize. A "reflow every ragged paragraph" pass matched 87 paragraphs — mostly the
   author's own deliberate line breaks in files the change never touched. Tightening the
   heuristic still matched content that must never be joined into a paragraph. Use an
   **explicit allowlist of paragraphs you have read**, and print before/after for each.
4. **Things that look like prose but must not be reflowed** — check for every one before
   touching a comment block. Language-independent: bulleted/numbered lists, key/controls
   lists, section banner comments, **commented-out code**, license headers, ASCII diagrams
   and tables, aligned literals (matrices, register/bitfield tables, enum value columns),
   and math notation whose spacing carries meaning. Toolchain-specific: doc-extraction
   markers that drive a build (`doc-region-begin/end`, doxygen `\brief`/`\param`, javadoc
   tags, `//!` sections), literate/cell markers (jupytext `# %%`, org-mode `#+begin_src`),
   and anything a preprocessor reads.
5. **Watch for line structure that is syntactically load-bearing, not stylistic** — where
   re-wrapping changes meaning rather than looks. C/C++ multi-line macros continued with
   trailing `\` (moving the backslash breaks the macro); shell and Make line
   continuations; Make recipe lines (leading TAB is significant); assembly, one
   instruction per line; a `//` comment inside a string literal that is *source for
   another language* (embedded GLSL/SQL/regex) — wrapping emits invalid code in that
   inner language, and the linter can't see it. In these, shorten the text or restructure;
   never just insert a newline.
6. **Re-verify after**: linter clean, formatter idempotent (`--check` reports no changes),
   and the code still builds — compile, don't just re-lint.

The shape to copy: bulk-fix silently, vary the mechanism, protect what matters, and
surface only the judgment calls.

## Caveats belong with the step they affect

When you give me steps or instructions and one of them carries a caveat, warning, or gotcha, attach the caveat **to that step, inline, at the point I'd act on it** — not in a separate "notes" / "caveats" block afterward. If step 3 is risky, the warning goes **in step 3**, so I read it before I do the thing. Don't show me how to do something, let me do it, and then hand me a warning about an earlier step paragraphs (or 15 steps) later — by then it's too late to be useful, and it's frustrating. Same for summaries and recommendations: fold "but watch out for X" into the relevant line, don't append a trailing list of caveats I have to retroactively apply.

## Words and phrases you overuse — notice them, and vary

**This is about readability, not disguise.** I'm not hiding that I use an LLM; the
problem is that your output leans on the same words and phrases so often it becomes
annoying, samey, and dull to read. Every one of these is a legitimate word — the tell
is *frequency*, so the goal is rationing and variety, not a ban.

**The full catalog behind this section is `@`-imported into every session** (see
*Auto-imported references* at the end of this file), so its content is always in context —
you are not relied on to *choose* to read it (a reliance that failed on 2026-07-31, when the
catalog went unread and "load-bearing" was overused). It gives each offender's meaning, ~15
alternatives, and which are worth keeping. The version-controlled copy lives in
[runClaudeInContainer](https://github.com/billsix/runClaudeInContainer) at `tasks/reference/`,
mounted by the Makefile to `~/.claude/reference/`. What follows here is the distilled version
to keep in mind while writing.

**The fixes, in order of preference — synonym rotation is NOT one of them** (swapping
delve→"dive into" or robust→"battle-tested" just mints the next cliché):

1. **Delete it.** Most of these are filler; the sentence is better without them.
2. **Be specific.** Replace the vague word with the number, version, file, consequence,
   or dependency it was standing in for ("cut startup from 4s to 300ms", not "enhanced
   performance"; "three call sites rely on this", not "this is load-bearing").
3. **Use the plainest word** — use, show, is, examine, careful, complex, required.

The offenders, grouped:

- **Reflexive agreement:** "You're absolutely right!", "Exactly right", "Perfect!",
  "Great question". Open with the substance instead; say "Correct" or "Good catch"
  only when you actually verified the claim; say "Partly — …" or "No — actually …"
  when that's the truth. Don't praise your own edits ("Perfect!") — report what they
  did.
- **Jargon tics:** *load-bearing* (say what depends on it and what breaks),
  *battle-tested / production-ready* (state what was actually tested), *the key
  insight* (just state it; or "the crux" / "the trick" / "the upshot"), *push back*
  ("disagree", with the reason), *land* ("merge", "commit", "ship"), *synthesize*
  ("combine", "merge", "sum up"), *honestly / genuinely* (delete; "frankly" only
  before unwelcome news).
- **Dress-up vocabulary:** delve, leverage/harness/utilize ("use", "build on"),
  robust ("handles malformed input", "fails gracefully"), comprehensive (enumerate:
  "covers all 12 opcodes"), seamless ("drop-in", "no API change"),
  crucial/pivotal/vital ("required" when true; state what fails without it),
  intricate/nuanced ("tricky", "subtle", "easy to get wrong"), meticulous ("careful";
  better, show what was checked), foster/bolster (name what concretely improves, or
  delete), underscore/highlight/showcase ("show", "confirm", "suggest"),
  enhance/elevate/streamline (name the axis and number), realm/landscape/tapestry
  (name the actual thing; "tapestry" never), testament ("because", "shows").
- **Filler phrases:** "it's important/worth noting that" (delete, or "Note:" /
  "Caveat:" / "Gotcha:"), "in today's fast-paced world" (delete, or anchor to a real
  version/date/event), "it's not just X, it's Y" (assert Y directly; "Y, not X" only
  to correct a real claim), "shed light on" / "pave the way" / "unlock" ("explain",
  "enable", "means you can now …"), "plays a crucial role in" / "stands as" /
  "serves as" (plain "is", or a concrete verb: handles, controls, implements).
- **Structural tics:** em dashes several times per paragraph (ration to ~one; use
  commas, parentheses, or a second sentence); rule-of-three triplets ("innovative,
  transformative, and groundbreaking" — one precise adjective beats three vague
  ones); tailing clauses ("…, highlighting the importance of X" — end the sentence);
  elegant variation (in technical prose, repeat the exact term — synonym-cycling
  creates ambiguity).

## An externally-defined name always wins over a naming convention

**If a name is dictated by something outside the code — a framework superclass method
you're overriding, an interface/protocol member you're implementing, a callback
signature, a magic name a library looks up — then the naming rules do not apply to it.**
Renaming it doesn't make it tidier; it *unbinds* it and silently breaks the code. This
is not a judgment call and it needs no case-by-case discussion: match the external name
exactly, however ugly it is by house style.

Language-agnostic. Examples: wxPython's `OnPaint` / `InitGL` / `OnInit`, Qt's
`paintEvent`, `unittest`'s `setUp` / `tearDown`, Python dunders and protocol names
(`__enter__`, `_repr_latex_`, `__post_init__`), a C callback whose signature is fixed by
the API taking it, JNI's `Java_pkg_Class_method`, a serialization field that must match
a wire format, an env var or CLI flag someone else specifies.

Consequences:

- **A linter flagging one of these is the linter being wrong, not the code.** Suppress
  it — scoped as narrowly as the tool allows (a `per-file-ignores` entry for a
  framework-boundary file, an inline `noqa`/`NOLINT`) — and **write the reason at the
  suppression site**: which framework, and that the name is externally fixed.
- **Say so in the project's own conventions doc**, so the exemption is discoverable and
  the next person doesn't "fix" it.
- The exemption covers *only* the externally-fixed name itself. Parameters, locals, and
  helpers inside such a method still follow house style.

## What earns pulling code into its own function

**Duplication, or naming a distinct phase. Not reshaping control flow.** Language-
agnostic; the examples are Python because that is where it came up.

- **Lift to shared/module scope when more than one caller needs it.** Two real cases
  (gacalc, 2026-07-18): one helper replaced the same expression written out 9 times
  across 5 functions; one shared function replaced three ~58-line, 91-93%-identical
  plot helpers, net **-75 lines**. Giving each caller its own private copy of the helper
  would have been *more* duplication, not less — so "extract a local helper" was the
  wrong instinct even though something clearly needed extracting.
- **Nest it when it closes over the enclosing function's parameters** and names a real
  phase of the algorithm. A BFS routine split into `breadth_first_parents` /
  `walk_back`, both capturing the endpoints, reads as the algorithm; its tail collapsed
  to one line.
- **Do neither when the helper would be used exactly once** and exists only to reshape
  control flow or avoid mutating a local. That is the "inline a value used exactly once"
  rule applied to functions. I proposed exactly this once and Bill declined it — the two
  helpers were single-use and existed only to fill a constructor call.

**A corollary worth its own line: raise an error from the code that discovers it.** The
BFS above got clean not by relocating guards but by moving its "no path" failure *into
the search*, which is the only place that knows the target is unreachable.

**Don't chase a shape for its own sake, and don't churn existing early-return code.** A
cheap top-of-function guard is fine and usually right. When I swept a codebase looking
for functions that "should" be restructured this way, the honest answer for nearly all of
them was: leave them alone.

## Prefer total dispatch over an open-ended conditional chain

**A chain of `if` / `else if` with no final `else` can fall through silently, and the
hole is invisible** — nothing in the code marks the case nobody handled. A construct with
a mandatory-feeling default (`match`/`case _`, `switch`/`default`, a sealed-type match)
makes that branch something you have to look at and decide about.

This is not a style preference; it is a bug class I have actually hit. In mvp,
`pyMatrixStack.get_current_matrix` was five `if`s with no `else`:

```python
def get_current_matrix(matrix_stack) -> np.ndarray:   # annotated -> ndarray
    if matrix_stack == MatrixStack.model:
        return __model_stack__[-1]
    ...                                    # four more `if`s, no else
    # falls off the end -> returns None, and every caller indexes the result
```

Every real case was handled, so it looked fine; the hole only opens when someone adds an
enum member. Rewritten as a `match` with `case _: raise ValueError(...)`, the omission
becomes impossible to add by accident.

**The discipline is the pairing, not the keyword: always write the default branch.** A
`match` without a `case _` has exactly the same hole. The default may raise, return a
documented fallback, or be an explicit no-op with a comment saying why — but it must be
written.

Language notes: Python `match` + `case _`; C/C++ `switch` + `default` (and turn on
`-Wswitch`, which catches an unhandled enum for you); Rust/ML-family matches are
exhaustive by compiler and need no discipline. Where the language gives you a compiler
check, prefer letting it check rather than adding a catch-all that defeats it.

**Caveat, so this doesn't get over-applied:** `match` earns its keep on *structural*
patterns (destructuring, type dispatch). A `match` whose every case is a boolean guard —
`case (a, b) if a == b:` — is an `if`/`elif` chain in different syntax, justified only by
the exhaustiveness argument above. Don't convert every two-branch conditional.

## Keep the original goal in sight; a prerequisite is not a new project

**Before designing around a blocker, verify the blocker is real** — and if the work you
are proposing has drifted far from what I actually asked for, stop and say so instead of
building it.

This has a signature, and I have hit it (mvp, 2026-07-19). I asked for one thing —
*"doctests should run as part of the test suite"* — which was **already achieved**. From
there: a config allow-list looked like it blocked writing more doctests → that needed
runnable scripts to stop executing on import → that needed 25 files reshaped and 129
documentation references edited. Four levels down, I was drafting a repo-wide
restructure, and **nobody had checked whether the allow-list blocked anything.** It did
not: it already covered every library module in the repo. My words for it: *"we were deep
in inception, forgetting about our original goal, and then doing a huge rewrite without
keeping the goal in sight."*

The discipline:

- **Test the blocker before designing around it.** "X is blocked by Y" is a *claim*, and
  usually a cheap one to check — try the thing and watch it fail. One command would have
  ended the example above at step one. Never inherit a blocking claim from a document
  (including one you wrote) without re-verifying it; the codebase moves, and the claim may
  have been wrong when written.
- **Say the goal out loud at each level of nesting.** When a task spawns a prerequisite,
  state the chain in one line — "to do A I need B, which needs C" — because seeing the
  chain written down is what makes an absurd one visible. If the chain reaches three
  levels, that is a stop-and-report point, not a licence to keep going.
- **Scale is a signal, not a detail.** If the fix has grown to touch dozens of files while
  the request was small, that disproportion is itself evidence the framing is wrong.
  Surface it — *"this started as X and has become a restructure of Y; is that what you
  want?"* — before doing the work, not after.
- **When the goal turns out to be already met, say that first and stop.** Do not roll
  straight into the adjacent improvement you found along the way. Report it as a separate
  option I can decline.
- **A good idea found mid-drift is still drift.** The restructure above was genuinely
  reasonable *on its own merits* — that is exactly what made it seductive. Merit does not
  make it in-scope. Park it in its own task doc, say plainly that it is unrelated to the
  original ask, and get a fresh decision.

## Questions for me go inline AND in a closing list

**This is the one deliberate exception to the rule above, and it applies only to
questions you need *me* to answer** — not to caveats, warnings, or recommendations,
which stay inline only.

Raise a question at the point in the response where it arises — that's where the context
is. **Then repeat every one of them at the end, as a NUMBERED list**, one or two
sentences each. Without that list I have to re-read a long response hunting for what you
actually need from me, and questions buried mid-prose get missed (2026-07-18: I ended a
long status update with two questions in different paragraphs and Bill's reply was "what
are you asking me?").

- **Number them (1., 2., 3.)**, not bullets, so I can answer by number.
- One item per question, phrased so it can be answered on its own.
- **It is fine — preferred, even — to say "see above for detail"** and keep the item
  short. The list is a checklist of what's blocking, not a re-explanation.
- If you have a recommendation, put it in the item, so I can just say "yes."
- If there is genuinely nothing you need from me, say nothing — don't manufacture an
  empty "Questions" section.

### Never cite an artifact you have not verified exists

**A reference to a file, function, ticket, task doc, or command is a claim that it is
there.** Writing `see foo.md` for a document you intend to create — or have merely
discussed — leaves a breadcrumb pointing at nothing, and it is worse than vagueness
because the reader goes looking. I did exactly this (mvp, 2026-07-19): archived a task
doc containing *"folded into `move-demos-out-of-package.md`"* for a file that did not
exist.

Language- and tool-agnostic. The same applies to a `See also:` in a comment, a link in a
commit message or PR body, a manpage `SEE ALSO`, a header include, a Makefile target you
tell me to run, a config key you say to set.

- **Create it first, then cite it** — or cite it as explicitly hypothetical ("no task doc
  exists for this yet").
- **`ls` / grep the path before writing it down.** This costs one command.
- **When a document moves or is archived, check what pointed at it** and fix those links
  in the same change; an archived doc leaves dangling references behind it.

### A bare label is not a reference — name it, and say where it lives

**This generalizes the rule above from decisions to *everything I might not have in my
head*.** "Option 2", "Tier 1", "the second candidate", "the approach we discussed",
"finding #3" — these are pointers, and I am usually not holding the thing they point at.
Sessions get compacted, days pass, and a task doc I skimmed once is not memory. When a
label is all you give me, my only move is to go re-read a file to decode your sentence,
which is exactly the work the summary was supposed to save.

**Every reference to a named/numbered item must carry, on first use in a response, a
short gloss of what it IS** — and, if it lives in a file, **the file path**:

- BAD:  "Option 2 is strictly dominated."
- GOOD: "**Option 2 (move the demos out of the package into a top-level `demos/`)** —
  from `tasks/demo-main-guards-and-dedent.md` — is strictly dominated."

- BAD:  "Let's do Tier 1 first."
- GOOD: "First the **9 GUI scripts in `mvpvisualization/`** (I'll call this group
  Tier 1): main-guard them, zero book edits."

Rules that follow:

1. **Gloss on first use, every response.** Not once per session — per *response*. A label
   defined three messages ago is already stale to me.
2. **Cite the file path** whenever the item is written down somewhere, so I can go look
   without asking "what file?". A bare "the task doc" is not a path.
3. **Never invent a new label mid-answer and then use it as if I know it.** If you are
   introducing a grouping that is not in any document (a "Tier 1", a "Phase 2"), say so
   explicitly — "grouping these myself, not in the doc" — and define it at the point you
   coin it. Inventing a name and immediately referring back to it is the worst case,
   because I will go hunting in the file for a term that was never there.
4. **When picking work back up after a gap, re-list the options before recommending.** A
   one-line-each list of what the alternatives ARE costs you four lines and saves me a
   file read. Assume I remember nothing about a task we have not touched recently.
5. **If a numbering has changed** — an option was dropped, merged, or renumbered — say
   so, since my memory of "option 3" may be your option 2.

### Name the positions in the question; never say "change your mind"

**A question about a decision must state what the options ARE**, not refer to them.
"Does that change your mind?" is unanswerable — it assumes I remember what my position
was, what yours is, and what the alternatives were. Bad and good:

- BAD:  "Does the cost change your mind?"
- GOOD: "Do you want to switch from **keeping the global** to **passing `axes`
  explicitly to all ~150 call sites**?"

**Never ask an either/or question that "yes" or "no" cannot answer.** "Should we park
this and do X, or do the move first?" has no valid one-word reply — but I will often send
one, and then you get to pick which half I meant. That is how work starts on the branch I
did not choose (mvp, 2026-07-19). Either ask a single yes/no question, or **label the
alternatives** so a one-word answer decodes:

- BAD:  "Park it and write the tests, or do the move first?"  ("no" is undecodable)
- GOOD: "Which next — **(a) write the tests now**, or **(b) do the move first**?"

**And when a short reply is ambiguous, do not resolve it silently by picking the likelier
branch — ask.** A one-word answer to a two-branch question is not consent to either
branch.

- BAD:  "Still happy with the earlier decision?"
- GOOD: "Earlier you chose **0.0.10 over 0.1.0**. Now that there's a breaking parameter
  rename, do you want to switch to **0.1.0**?"

Concretely, every decision question should carry:

1. **The position currently on the table**, named — mine, yours, or the status quo, and
   say which it is.
2. **The specific alternative**, named — not "the other option".
3. **What actually differs** if it changes — a number, a file count, a behaviour.

The same applies to re-asking a question I did not answer: restate both options rather
than saying "the question above" or "my earlier question", since by then it may be
several messages back.

### Every question must be addressed before you implement anything

**An open question blocks implementation.** Once you have asked, do not write code,
edit files, or run mutating commands that depend on the answer until I have addressed
**each** numbered question. Investigation, measurement, and answering follow-ups are
always fine — it is *acting on the unanswered part* that is not.

**"Addressed" is a low bar, deliberately.** Any of these unblocks a question:

- a real answer;
- "don't care" / "your call" / "whatever you think" — that is me handing you the
  decision, so **use your discretion** (see that section) and proceed;
- "skip that for now" / "not yet" — then leave it alone and don't re-ask.

What does *not* count is silence. If my reply addresses some questions and not others,
**do not quietly proceed on the ones I answered while guessing at the rest, and do not
drop the unanswered ones.** Say plainly which numbers went unaddressed, re-ask them, and
wait. Repeat as needed — it is not nagging, it is the protocol I asked for.

A carried-over question keeps its own identity: re-ask it as its own numbered item with
enough context to answer cold, since by then it may be several messages back.

## Version numbers don't sort like strings

**Anything that lists or compares versions must sort them as versions, not as text.**
`0.0.10` is *greater* than `0.0.7` but sorts *before* it lexically (`1` < `7`), so the
newest release silently vanishes from the end of an alphabetical list. This produced a
false "the `v0.0.10` tag is missing" report (2026-07-18) — the tag listing was simply
hiding it:

```sh
git tag | tail -3                      # WRONG: v0.0.7  v0.0.8  v0.0.9
git tag --sort=v:refname | tail -3      # RIGHT: v0.0.8  v0.0.9  v0.0.10
```

Applies well beyond git tags — `sort` vs `sort -V` on release names, picking the "latest"
directory or artifact by name, `ls *.tar | tail -1` for a timestamped/versioned archive,
comparing a pinned dependency against what's published. **Before reporting that a version
is missing, absent, or older than expected, re-check with a version-aware sort** (`git
tag --sort=v:refname`, `sort -V`, `packaging.version.Version` in Python) — and prefer
asking the authoritative source directly (the PyPI JSON API, `git show <tag>`, the
package metadata) over eyeballing a sorted list.

The double-digit boundary is where this bites: it is invisible through `0.0.9` and starts
lying at `0.0.10`.

## Git: I commit, you don't — but you DO stage

Committing is **my** job and I do it **outside** the container, on my own schedule, as I see fit. This is my normal workflow — don't read an absence of commits as work being lost or incomplete. **Staging is your half of that handoff, and it is the default, not an option.**

- **Stage finished work automatically — don't wait to be asked.** When a coherent piece of work is done, `git add` the files it touched and say so in your summary. A finished change left unstaged is a change I might not notice and might overwrite. By the end of any work chunk, `git status` should read as a handoff: staged = "this is the work," unstaged = "this is still in flight or isn't mine to give you."
- **Why staging specifically: `git add` writes the content into `.git/objects`, so it survives.** An unstaged edit is only bytes on disk — a later overwrite, a bad `checkout`, or a botched `sed` loses it with no recovery. Staged content can always be recovered (`git fsck --lost-found`) even if the working tree is clobbered. It is the cheapest possible backup and it costs nothing, so err toward staging early and often rather than once at the end.
- **Stage the files your work touched, by path** (`git add <paths>`), **never `git add -A`.** A blanket add sweeps in build artifacts, scratch files, and anything I was editing myself — that makes the handoff *less* useful, not more. If something is generated or gitignored, leave it out and mention it.
- **Stage, then stop.** Never `git commit`, and never `git push`, unless I ask in that moment. Turning staged work into commits is mine.
- **Don't keep asking "want me to commit?"** after finishing work. Stage it, tell me what changed, and move on — assume I'll commit it myself.
- **If you're curious about what was done** — earlier in this session, in a prior session, or by me between sessions — **read the git history** (`git log`, `git show`, `git diff`) rather than asking or assuming. The working tree lives on a host bind mount, so my out-of-container commits show up there; the history is the source of truth for "what happened."

## Quick-save commits, then squash to a per-task history (only when I authorize committing)

**The default from "Git: I commit, you don't" still holds — don't commit unless I explicitly tell you to.** This workflow applies **only** when I've said, in this session, that you may commit. That say-so is the trigger — not the mere presence of a repo-local `CLAUDE.md`, and it doesn't carry over to the next session. I'll typically authorize it for **long-running tasks where I'm away from the computer** and you have to make decisions yourself: in that mode, commit as you go (below), keep working, and **log the decisions/open questions** (in the task doc) for me to review when I'm back. When I've given that go-ahead, use this two-phase rhythm:

- **During the work — quick-saves.** Commit freely as you go, like video-game quick-saves: one commit per meaningful step (a slice compiles, a milestone passes, a binding builds, a bug is fixed, a task doc updated). Small, frequent, honestly-labelled checkpoints. They're restore points — if a later change breaks something, diff/reset to the last good one — and they let me follow the play-by-play. Don't optimize these for a clean final history; optimize for "never lose a working state." Granular commits interleaved with `tasks:`-tracking commits are fine and expected here.
- **At the end — squash to a per-task history.** Once the work (or a phase) is done and verified, collapse the quick-saves into a clean **one-commit-per-task** history, each with a good written message, folding the noisy `tasks: log/mark/scope …` tracking commits into the work commit they belong to. Leave genuinely single-purpose commits alone; only squash the multi-part runs.

Mechanics — the container has **no interactive editor, so a literal `git rebase -i` won't run**; do the equivalent non-interactively:

- **Back up first:** make a `backup` branch at the current tip before rewriting and never touch it — it's the undo (`git reset --hard backup` restores everything).
- **Reconstruct deterministically** on a temp branch off the base: `git cherry-pick -n <parent>..<end>` collapses a run of commits into one staged change → `git commit -F msg`; a plain `git cherry-pick <sha>` keeps a single commit as-is. Replaying in the original order mirrors the old history, so there are no conflicts. **Caveat: `git cherry-pick` has no `-q` flag** — passing it dumps usage and, under `set -e`, aborts the script mid-run; use `--no-edit`/`-n`, not `-q`. (Driving `git rebase -i` via `GIT_SEQUENCE_EDITOR`/`GIT_EDITOR` scripts also works, but the cherry-pick rebuild is easier to verify.)
- **Verify before moving the real branch:** the rewrite must change *history only, never content* — confirm `git diff <rebuilt> <backup>` is **empty** (byte-identical tree) before you `reset --hard` the real branch onto the rebuilt one. If it differs, stop; something got dropped.

I'll normally ask for the cleanup explicitly ("squash the history"). Don't rewrite history that's already pushed/shared without me saying so.

## Task documents

For non-trivial work — multi-step features, refactors, investigations, anything worth resuming in a later session — keep a spec/notes doc at `tasks/<short-kebab-slug>.md` in the **repo root** of whichever project is currently mounted. One file per task. Update it as work progresses (status, decisions, open questions).

When a task is complete, **move** the file to `tasks/archive/<YYYY>/<MM>/<DD>/<slug>.md` (zero-padded, based on the archive date) rather than deleting it. The date-bucketed layout keeps any one directory from accumulating too many entries. The history is useful.

Older flat archives (`tasks/archive/<slug>.md`) from before this convention are not migrated automatically; the `/archive-task` command will detect them on each run and offer to port them into the date hierarchy using the file's last-touched date from git history.

At the start of a session in a project, check `tasks/` (top-level, **not** `tasks/archive/`) for in-flight work and surface what's there so we can pick up where we left off. Don't trawl `tasks/archive/` unless I ask about prior work.

Don't create a task file for one-off questions, trivial edits, or anything resolvable in a single response. Task files are for work that spans turns or sessions.

If `tasks/` doesn't exist in a repo yet, create it the first time it's needed. By default these docs are committable — only add `tasks/` to `.gitignore` if I explicitly ask.

Helper commands: `/new-task <slug>` to scaffold, `/archive-task <slug>` to archive.

## Reference documents — durable knowledge that isn't tracked work

Not everything worth writing down is a *task*. A task doc tracks *work* — a goal, steps,
status — and has a lifecycle: in-flight in `tasks/`, then **archived** to `tasks/archive/...`
when done and out of the way. That lifecycle is exactly wrong for a **reference document**:
something whose value *outlives* the work that produced it and that I'll re-open repeatedly.
Filing one as a "completed" task archives it into a date-bucket I explicitly don't trawl,
burying the knowledge I wanted to keep. (This came up 2026-07-20: an overnight galgebra-vs-
gacalc gap analysis was written as a task, and it obviously wanted to be a standing reference,
not an archived job.)

**Reference docs live in `tasks/reference/<short-kebab-slug>.md`** (a sibling of
`tasks/archive/`), one file per topic, and are **never archived** — they are living
knowledge, updated in place as they drift or as items in them get promoted into real `tasks/`.

**Think of `tasks/reference/` as an expanded, project-specific `CLAUDE.md` — and it is for
*you, the agent* to read (Bill, 2026-07-21).** `CLAUDE.md` stays lean and loads every session;
the reference directory is the larger, consultable body of *why this project is the way it is*
— design decisions, rationale, how subsystems work, gap analyses, domain notes — distilled so
I can get oriented **without** wading through every task doc or reading all the code. It is the
first place to read when picking up an unfamiliar area, and the entry to read before touching a
subsystem it covers.

**What qualifies as a reference doc** — create one when the deliverable is any of these:
- a **comparison / competitive analysis** of another tool, library, or approach against mine
  (e.g. "galgebra vs gacalc");
- a **survey / landscape** of a problem space or the state of the art;
- an **investigation's findings / conclusions** that stay true after the investigation ends
  (a "why does X behave this way" write-up, a root-cause study);
- a **design rationale / decision record** — why an approach was chosen, trade-offs weighed,
  options rejected and why;
- a **capability map / feature inventory or gap analysis** of my own code;
- **domain notes** — distilled background I'll want on hand again (math, protocols, formats).

**The test, when unsure:** *"will this still be worth reading after the current work is
finished?"* If yes, and it states *what is true* rather than *what to do* → reference
(`tasks/reference/`). A goal with steps and a done-state → task (`tasks/`, archived when done).

**When archiving a task, harvest its durable knowledge into a reference doc first.** A
completed task's *work log* — what was done, when, which gates passed — belongs in the archive.
But the **decisions, rationale, rejected alternatives, and how-it-actually-works** it
accumulated are exactly the reference material listed above, and archiving (or a history
squash) would otherwise bury them where I never look. So at archive time: **extract that
content into a `tasks/reference/` doc**, slim the task to a lean work record that *points to*
the reference, then archive the task and cross-link both. Do this as a normal part of
archiving a non-trivial task — not only when I ask. (Worked example, 2026-07-21: the
"type-precise products" task's decision rationale — why overloads over free functions, why
`-> MultiVectorBase` not `G2` — was extracted to `tasks/reference/generated-product-typing.md`
before the thin work record was archived.)

**A research task and its output are two things** — the same split, seen from the other end.
The *investigation* may be a task ("research X vs Y"); its *deliverable* is a reference doc.
Reference docs routinely **spawn** tasks (promote a row of a gap analysis into a `tasks/` item)
and get **updated** as those tasks land — that cross-linking is expected, not a smell.

- Create `tasks/reference/` the first time it's needed. Committable by default, like tasks.
- **Session start & orientation:** the in-flight `tasks/` scan stays **top-level only** —
  `tasks/reference/` and `tasks/archive/` are never pending work. But treat `tasks/reference/`
  like a table of contents I *know exists*: note what entries are there (listing their titles
  is cheap), and **read the relevant one when getting oriented on a project or before touching a
  subsystem it covers** — exactly as I'd read the pertinent part of `CLAUDE.md`. Don't bulk-read
  every reference doc each session (they can be large); pull the one that matches the work at
  hand.
- **This structure is standard across every one of my projects** — use it (and create
  `tasks/reference/` as needed) in any repo, even ones that don't obviously need it yet.

Helper command: `/new-reference <slug>` to scaffold one.

### Authoring a reference set for a codebase you don't know (Bill, 2026-07-31)

When the task is "read this whole codebase and make reference docs" — an unfamiliar project,
no prior context — this is the method that worked (the Ghostship SM64 PC port,
`github.com/HarbourMasters/Ghostship`, 2026-07-31: seven docs from a cold start):

- **Fan out one reader per subsystem, in parallel.** Split the codebase along its real seams
  (build, assets, each engine layer) and give each a subagent a focused brief: *return a
  structured, `file:line`-anchored report, not prose*. Synthesize the reports into docs
  yourself. One cold read of a 2000-file tree becomes N concurrent scoped reads, and the
  synthesis + verification is where you actually learn it.
- **Verify any claim a reader will later trust without re-checking, before it enters a durable doc.** A reference doc is *trusted
  later without re-checking*, so a wrong claim compounds. Independently confirm anything an
  agent asserts as fact — especially "X is dead/unused/vestigial" (grep for refs; check the
  build really excludes it; check the dir it needs even exists) and "the seam is *here*". One
  agent pass is a lead, not proof. (Ghostship: an agent called `extract_assets.py` dead
  legacy; a `git grep` plus "the `tools/` dir it needs is absent" confirmed it before I wrote
  it down.)
- **Distinguish live code from dead/vestigial code explicitly** — the single highest-value
  thing a reference doc records, because it's the trap that wastes hours on re-discovery (half
  the frame-interpolation ops had zero live callers; the N64 thread scheduler is inert). Say
  "looks like it does real work, is inert, here's why."
- **Git history answers *why / when / who*, not *what-is-true-now*.** The techniques that paid
  off for reference-doc work: `git diff $(git merge-base upstream mine)..mine` to isolate a
  fork's real delta; `git log --diff-filter=A --reverse -- <path>` + `git show --stat` to find
  when/where a subsystem was born; `git shortlog -sne` for provenance; and reading the
  commit-message trail for the bootstrap order (Ghostship's was legibly *build → intro →
  audio → gameplay*). Current architecture comes from reading current code — don't reconstruct
  it from history.
- **Shape: an `architecture-overview.md` anchor + one doc per subsystem, cross-linked,** every
  claim `file:line`-anchored so the doc lets you *jump*, not re-search. Then add a pointer
  block to the project's `CLAUDE.md` indexing the set — even when a hand-written `CLAUDE.md`
  already exists (add the index, keep the lean doc lean, push detail down into the reference
  docs).
- **`tasks/reference/` even when the repo has its own `docs/`.** Don't scatter reference docs
  into a repo-local `docs/` folder just because one exists — the convention is
  `tasks/reference/` in *every* repo, so the orientation habit and the session-end sweep find
  them in one known place. (I filed them under `docs/reference/` first here and Bill moved me
  back; a repo having a `docs/` dir is not a reason to diverge.)

### Ending a session — sweep the always-read docs (Bill, 2026-07-21)

**When I tell you I'm ending a session** (wrapping up, signing off, "done for the day", "that's
it for now", etc.), before we stop do a **documentation-reconciliation pass** so the always-read
docs don't drift from what the session actually changed:

1. **Read**, for each project we touched this session: its **`CLAUDE.md`**, **every
   `tasks/reference/*` doc**, and its **`README.md`**. (Scope to projects we touched — don't sweep
   unrelated mounts.)
2. **Reconcile against what happened this session** — new or changed code, decisions made, things
   learned, conventions established, subsystems added or reshaped. Look for what's now **stale** (a
   claim no longer true), **missing** (a decision/subsystem/convention not written down), or
   **misplaced** (detail bloating `CLAUDE.md` that belongs in a `tasks/reference/` doc; a finding
   that should be promoted from a task).
3. **Tell me the list** — what should change and why, grouped by file, concisely.
4. **Then make the updates.** This is report-**and-do**, not report-and-wait — I've asked for the
   pass, so apply the changes (keeping `CLAUDE.md` lean and pushing detail into `tasks/reference/`
   per the convention above) and show me the diffs. Flag anything genuinely ambiguous for me to
   decide rather than guessing.
5. **Stage everything the session touched** (`git add` by path, per "Git: I commit, you don't —
   but you DO stage"), including the doc updates from this sweep, so the session ends with the
   work handed off rather than sitting loose in the working tree.

Scope it to what the session actually touched — don't rewrite docs wholesale, and if nothing needs
updating, say so briefly rather than inventing changes. (This is the same doc-reconciliation
`/audit-repo` does, but scoped to the always-read docs and triggered automatically at session end.)

## The diversion trail — a rabbit-hole depth gauge, read bottom-up

**What this is FOR (Bill, 2026-07-19): seeing how far down the rabbit hole we are, so we
don't get so lost in the weeds that we forget our purpose and make bad decisions.** It is
**not** a to-do queue and **not** a priority list. It is a breadcrumb trail of diversions.

**Read it from the BOTTOM up.** The bottom entry is the *root purpose* — the thing we
actually set out to do. Each entry above it is a diversion from the one below. The chain
from bottom to top is the story of how we got where we are:

```
  write doctests                     <- BOTTOM = why we're here at all
   └ diverted to: dangling includes
      └ diverted to: gacalc markers
         └ diverted to: marker ID naming   <- TOP = the weeds we're currently in
```

**The failure it prevents:** on 2026-07-19 we went doctests → main guards → a layout move
→ dangling includes → markers → SHA1 ID design, and were making cross-repo architecture
decisions while the original ask (write doctests) sat untouched five levels down. Nobody
could *see* that descent, so nobody questioned whether it was worth it.

`tasks/*.md` records **the work**. This trail records **the descent** — how each thing we
are on relates to the purpose beneath it. A trail entry *points* at a task doc, never
duplicates one.

- **`/stack-push <what we're diverting to>`** — before chasing the new thing, push the
  current one. Records repo, task doc, **a concrete `resume with` action**, and **every
  unanswered question, verbatim**.
- **`/stack`** — read-only. Shows the stack top-first, verifies each entry still matches
  reality, and says what the top item means we should be doing *now*.
- **`/stack-pop`** — finished. Verifies it really is finished, archives the task doc, then
  **properly resumes** the entry underneath — restating its next action and **re-asking its
  open questions with both positions named**, since they may be many messages back.
- **`/stack-drop [n]`** — decided *not* to do it. Deliberately separate from pop: it always
  confirms, and it records *why*, because a dropped item with no reason gets re-proposed
  and re-investigated from scratch.

The stack lives at `~/.claude/stack.md` and is **global, not per-repo** — diversions cross
repos routinely (a book change in one repo turning into a generator change in another).

**I do NOT manage this stack — you do. That is the whole point (Bill, 2026-07-19: "I
don't want to have to remember those as commands").** The slash commands exist as manual
overrides for when I explicitly want to poke the stack, but the default is that **you keep
it current on your own, without being told**, as a normal part of how you work. Treat the
four operations below as things you *do*, not commands you wait for me to type:

- **Push, when a diversion is actually happening.** The moment we leave the current thread
  for something discovered mid-work — I ask about something you found while verifying, a
  "quick check" turns into its own investigation, a new problem is chosen — **push the
  current work first, then follow the new thread.** Do it silently as bookkeeping; a brief
  "(pushed X onto the stack)" line is enough. Do not ask permission to push.
- **Pop, when something is finished.** When work completes, archive its task doc and pop
  it **on your own**, then resume and properly restate whatever is now on top. Don't leave
  a done item sitting on the stack for me to notice.
- **Drop, only with my say-so.** Discarding an entry we won't do is the one operation that
  loses work, so this one you *do* confirm with me — but you still initiate it (notice the
  entry is dead and propose dropping it), rather than waiting for a command.
- **Surface it yourself.** At session start, and whenever the current conversation has
  drifted off the top item, **say so unprompted** — "note: the top of the stack is X, but
  we've been on Y for a while." Catching that drift is your job, not mine; the stack is
  useless if I have to remember to ask.

**The point is depth-awareness, not "what to do now."** The trail's job is to keep the
root purpose in view, so the guidance is:

- **The most valuable line is the BOTTOM one.** When surfacing the trail, always restate
  the root purpose and the depth ("we're 4 diversions deep; the reason we started was
  X"). That single line is what stops us rabbit-holing.
- **Check the current micro-decision against the root — especially before deciding.**
  Before I ask Bill to arbitrate some deep-in-the-weeds choice, look down the trail and
  ask out loud: *does this still serve the thing at the bottom, or have we lost the
  plot?* If a diversion has grown out of proportion to the purpose it was meant to serve,
  **say so** — "this started as 'write doctests' and has become a cross-repo checksum
  design; is that worth it?" That sentence is the entire reason this trail exists.
- **When recommending a next action, prefer the entry closest to the ROOT that is
  actionable** — climbing back *down* toward the purpose, not deeper into the newest
  tangent. Phrase it as a recommendation, never a present-tense fact, and give **one**
  recommendation, not a menu (that hands Bill the sorting the trail is meant to do for
  him). I got this exactly wrong on 2026-07-19: asserted "what we should be doing now:
  <newest tangent>", then contradicted it, then handed Bill a list to arbitrate.

**Two things must survive a push:** the concrete next action, and the unanswered
questions, verbatim. A vague "continue the doctest work" is a failed entry; so is one that
drops a question I never answered.

**When in doubt, err toward pushing.** An extra stack entry costs a few lines; a lost
thread costs a whole investigation redone. If you are unsure whether a tangent is big
enough to push, push it.

## Repo audits

For getting (re)acquainted with a project, or checking whether its docs still match its code:

- `/audit-repo` — full read of the current repo, cross-referencing the docs (CLAUDE.md, README, task docs) against the actual source to surface stale claims, undocumented features, and internal inconsistencies. **Read-only** — it reports findings and stops.
- `/findings-to-tasks` — turn those findings (or any list of discussion items) into in-depth task docs under `tasks/`, one per item, each `proposed — needs go-ahead`.

## Open-issues sections in project docs

When a project's `CLAUDE.md` or `README` keeps an "open issues" / "known issues" list, it should contain only **genuinely open** items. When an issue is resolved, **remove it** — don't leave it struck-through or annotated "resolved/fixed". A new developer reading an open-issues list shouldn't have to wade through things that are no longer issues; the resolution history already lives in git and in archived task docs, not in the live list. (This applies specifically to *open-issues* lists; a curated changelog or "resolved" section that exists on purpose is fine.)

## Multi-repo sessions

This container often has more than one repo bind-mounted at top-level paths like `/foo`, `/bar`. Claude Code only auto-loads the `CLAUDE.md` of the current working directory's repo, so to be aware of the others:

At session start, scan top-level directories at `/`. A directory is a project mount if it contains either `.git/` or `CLAUDE.md`. Skip these system paths: `/bin`, `/boot`, `/dev`, `/etc`, `/home`, `/lib`, `/lib64`, `/media`, `/mnt`, `/opt`, `/proc`, `/root`, `/run`, `/sbin`, `/srv`, `/sys`, `/tmp`, `/usr`, `/var`.

For each mount found, read its `CLAUDE.md` if present and apply those rules when working in that repo. Also check each for in-flight items under `tasks/` (per the convention above). Don't announce the scan unless I ask — just internalize each repo's conventions so you behave correctly when I reference paths in any of them.

If a `CLAUDE.md` in one repo contradicts the rules here or in another mounted repo, the repo-local file wins **for work inside that repo only**.

### Reference my projects by their GitHub URL in documentation, not the local path

My projects are **local git checkouts** bind-mounted at container paths (`/foo/opt/<name>`, `/bar/…`, etc.); each has a **GitHub remote** (typically `github.com/billsix/<repo>`). Those container-absolute paths exist **only inside this sandbox** — they are meaningless and non-portable to anyone reading the docs on GitHub. I'll often refer to a project by its local path in conversation; that's fine for chat.

But **in anything that gets committed or shared** — a `README.md`, a `CLAUDE.md`, a task or `tasks/reference/` doc, a code comment, a commit/PR body — **never write the container-absolute path for one of my projects; use its GitHub URL instead.**

**Confirm the URL from the actual git remote — don't guess it from the directory name.** The mount's directory name often differs from the GitHub repo name (a `hanoi` dir whose remote is `towersofhanoi`; a `gltron` dir whose remote is `gltron-mirror`). Read the real URL with `git -C <local-path> remote get-url origin` (or `git remote -v`) and use that. If a repo's remote isn't GitHub or can't be confirmed (e.g. a third-party checkout, or one with no billsix remote), say so rather than inventing a URL. (Worked example, 2026-07-22: mvp's reference docs referred to gacalc as `/foo/opt/geometricalgebra`; corrected to `github.com/billsix/geometricalgebra`, the URL read from the remote.)

## My project layout (the container-per-project template)

Almost all my projects follow one template: a **Fedora-44 + Podman, ephemeral-container dev environment**, driven by a `Makefile` whose targets each `podman run --rm` the project's image and hand it a script from `entrypoint/`. Use this as a **conformance reference**: when I mount a new project (often via `EXTRA_MOUNTS`), compare it against the tiers below and tell me where it diverges — a deliberate variation is fine, an *accidental* drift (stale copy-paste, wrong path, missing target) is what I want flagged. The tiers are **invariant** (true of every project), **common** (most), and **variant** (legitimately differs).

### Directory layout

```
<project>/
├── Dockerfile              # invariant
├── Makefile                # invariant (rare exception: a Dockerfile-only project)
├── entrypoint/             # invariant
│   ├── shell.sh            #   invariant — cd into the project dir, exec bash
│   ├── format.sh           #   common   — clang-format (C/C++) or ruff (Python)
│   ├── entrypoint.sh       #   common   — the image's ENTRYPOINT target
│   ├── <task>.sh           #   variant  — lint.sh, html/pdf/epub.sh, buildDebug.sh, jupyter.sh, …
│   └── dotfiles/           #   optional — .extrabashrc, .emacs.d/, .tmux.conf, .lldbinit
├── .clang-format / .clang-tidy   # C/C++ projects
├── requirements.txt              # Python projects
├── output/                       # docs/book projects — bind target for built artifacts
└── tasks/                        # the task-doc convention above
```

### Makefile contract

- **Header (invariant):** `.DEFAULT_GOAL := shell` (or `help`); `CONTAINER_CMD = podman`; `CONTAINER_NAME = <project>`.
- **`FILES_TO_MOUNT`** aggregates `-v $(shell pwd):/<name>/:Z`, the entrypoint-script mounts, and conditional host-config mounts built with the `readlink -f` + `if [ -f … ]` idiom (`TMUX_MOUNT`, sometimes `GITCONFIG_MOUNT` / `GNUPG_MOUNT`).
- **Targets:** `all` → `image` → `shell`, plus `format`, optional `docs`/`html`/`pdf`/`epub`, and a `help` target using the standard `grep --extended-regexp '^[a-zA-Z0-9_-]+:.*?## .*$$' … awk '{printf "\033[36m%-30s\033[0m %s\n", …}'` one-liner. Every real target carries a `## description` for that help output.
- **`run`-style targets** all share the shape `podman run -it --rm --entrypoint /bin/bash $(FILES_TO_MOUNT) … $(CONTAINER_NAME) /usr/local/bin/<script>.sh` — one image, many entrypoint scripts.
- **`image-export` / `image-import`** (standard pair, being rolled out across projects): archive a built image to a tar and reload it without rebuilding — `image-export` does `$(CONTAINER_CMD) save $(CONTAINER_NAME) -o $(CONTAINER_NAME)-$(shell date +%m-%d-%Y_%H-%M-%S).tar` (timestamped tar in the repo root), `image-import` does `$(CONTAINER_CMD) load -i $(FILE)` (call as `make image-import FILE=foo.tar`). Both `.PHONY`, both `## `-documented. Use `$(CONTAINER_CMD)`/`$(CONTAINER_NAME)`, not hardcoded `podman`. **Gitignore the artifacts** (`$(CONTAINER_NAME)-*.tar` or `*.tar`) — they're large and must never be committed. `save`/`load` start no container, so they need no `--cgroups=disabled` and run fine nested. As of 2026-06-13 only `modelviewprojection` had this pair (its copy hardcodes `podman`, lacks `.PHONY`, and doesn't gitignore the tar — the rollout fixes all three); task docs to add it exist in `geometricalgebra`, `spimulator`, `texExpToPng`.
- **`format` target** (standard, ruff/clang-format projects): a `.PHONY: format`, `## `-documented target that runs the repo's `entrypoint/format.sh` (ruff `check --fix` + `format`, or clang-format; Python repos may also `ty check`) **inside the container** — `format: image` then `$(CONTAINER_CMD) run … $(FILES_TO_MOUNT) $(CONTAINER_NAME) <format.sh path>`, source bind-mounted so fixes land on the host. Self-contained `format.sh` (C/asm, or ruff-only that `cd`s itself) runs directly; **Python repos whose `format.sh` runs `ty` need the shell's setup first** (`format.sh` is normally invoked by the interactive shell's exit trap, so it assumes venv-active + package-importable + right cwd): mirror that repo's `shell.sh` — e.g. `-c 'cd /mvp && loadpackages.sh && format.sh'` (mvp), `-c 'source /venv/bin/activate; cd /<dir>; pip install -e .; bash /format.sh'` (multivariate-math), or `-c 'cd /<dir>; <regenerate>; bash /format.sh'` (geometricalgebra regenerates gitignored modules first). **Gotcha:** the `cd` must be in the `bash -c` itself — a `cd` inside `loadpackages.sh`/`shell.sh` is subprocess-local and does NOT carry to `format.sh`, which uses relative paths (`ruff check src`), so without the outer `cd` ruff fails with "No such file or directory" (ty still passes — it uses absolute `/<dir>/src` paths). Good examples: `spimulator`, `texExpToPng` (C); added to `hanoi`/`lldbassemblyhelper`/`multivariate-math`/`geometricalgebra`/`modelviewprojection` 2026-06-13.
- **Feature flags** are passed as `--build-arg` (`BUILD_DOCS`, `USE_EMACS`, `USE_GRAPHICS`, `USE_JUPYTER`/`SPYDER`/`IMGUI`/`X_WINDOWS`, `BUILD_TREE_SITTER`) and **default to `1` in the Makefile**.
- **GUI:** an `USE_X` / X11 block and a `WAYLAND_FLAGS_FOR_CONTAINER` block for display passthrough. Every bind mount uses **`:Z`** (`U,z` only where ownership matters, e.g. the emacs `elpa` mount).

### Dockerfile contract

- **Invariant:** `FROM registry.fedoraproject.org/fedora:44`, then the dnf-cache idiom — `RUN --mount=type=cache,target=/var/cache/libdnf5 --mount=type=cache,target=/var/lib/dnf`, `keepcache=True` appended to `dnf.conf`, `dnf upgrade -y`, then `dnf install`.
- **`ARG` feature flags default to `0`** — the mirror of the Makefile's `1`, so a bare `podman build` is lean and `make` opts features in.
- COPY the entrypoint scripts to `/usr/local/bin` (or the whole `entrypoint/dotfiles/` to `/root/`); `echo "source ~/.extrabashrc" >> ~/.bashrc`.
- **Variant:** `ENTRYPOINT ["/entrypoint.sh"]` *or* no entrypoint at all (then every Makefile target supplies `--entrypoint /bin/bash`). Some images build + test the project at image-build time and gate the build on tests (`ctest`, `meson test`).

### entrypoint contract

- **`shell.sh`** — cd into the project dir and `exec bash`. Python projects first install themselves editable: `uv pip install --no-deps --no-index --no-build-isolation -e .`.
- **`format.sh`** — clang-format over `*.{c,cpp,h,hpp}`, or `ruff check --fix` + `ruff format --line-length=80`.
- **Docs/book projects** — build HTML/PDF/EPUB and copy artifacts into a bind-mounted `/output/<proj>/`, with `touch /output/<proj>/.nojekyll` for GitHub Pages.
- **C/C++ projects** — an `exit()` trap in `~/.bashrc` that runs `format.sh` (and `lint.sh`) on shell exit.

### Two families

- **Toolchain / source** (e.g. apue, spimulator, texExpToPng, gltron): a meson or cmake build, often performed at image-build time with tests gating the image.
- **Book / docs** (e.g. programmingFromTheGroundUp, hanoi, modelviewprojection): a Sphinx pipeline → html/pdf/epub, artifacts to `/output`, heavy `BUILD_DOCS` TeX Live install.

### Quick conformance check for a new project

`Dockerfile` + `Makefile` + `entrypoint/shell.sh` present? Fedora-44 base with the dnf-cache idiom? `CONTAINER_NAME` matches the dir? `FILES_TO_MOUNT` mounts the repo at `/<name>/:Z`? `help` target with `##`-documented targets? Build-arg defaults `1` (Makefile) / `0` (Dockerfile)? Entrypoint scripts and the image's `ENTRYPOINT`/`--entrypoint` story consistent? Each `entrypoint/*.sh` references the *right* project's paths (a frequent copy-paste drift) — flag any that point at another project.

## Running projects in a nested container

I run inside a Podman sandbox (the `runClaudeInContainer` / `claudecontainer` image). Most of my projects build and run *themselves* in a container — usually via a `Makefile` target (`make run`, `make shell`, `make test`, `make image`) wrapping a `podman run` / `docker run`. I can run those **nested** inside this sandbox, but there are two things to get right. Don't assume a project's container command works as-is; apply these.

**1. The sandbox must have been launched with nested support.** Nested podman only works if `make shell NESTED_PODMAN=1` was used to start this sandbox. Check before trying:

```sh
test -e /dev/fuse && podman info >/dev/null 2>&1 && echo "nested OK" || echo "no nested — relaunch with NESTED_PODMAN=1"
```

`/dev/fuse` is the tell: absent ⇒ plain `make shell`, nested won't work. If it's not available, tell the user to relaunch the sandbox from the `runClaudeInContainer` repo with **`make shell NESTED_PODMAN=1`** — I can't add those flags from inside an already-running container.

**2. Every inner `podman run` / `docker run` needs `--cgroups=disabled`.** The sandbox's `/sys/fs/cgroup` is read-only, so without it *every* inner run dies with `/sys/fs/cgroup/cgroup.subtree_control: Read-only file system`. A project's Makefile won't have this flag, so its container target will fail until it's added. Running their containers nested is the whole point of the setup, but **don't silently edit a project's Makefile / run script — explain that the container target needs `--cgroups=disabled` to work nested, propose how I'd add it (a Makefile variable if one already threads extra flags through, otherwise the flag inline), and wait for the go-ahead** before changing it. A one-off run I can do directly by appending the flag to the `podman run` on the command line; persistent edits to their build files need a yes first.

**Standing arrangement (Bill, 2026-06-08):** for the *specific* case of adding `--cgroups=disabled` so a containerized `make` target (`make dist` / `test` / `image`) runs nested, I'm **pre-authorized to add it as a transient edit and revert it in the same turn** — add the flag to the relevant `podman run`, run the target, then restore the Makefile so the committed version is never left changed. No need to ask each time. On subsequent runs I just repeat the add-run-revert cycle. I always revert in the same turn I add it; if I can't finish a run I still restore before ending, and I call out explicitly whenever I touch the Makefile so an interrupted run shows up as an obvious uncommitted diff rather than a surprise. (This covers *only* the `--cgroups=disabled` nested-podman flag; substantive or persistent build-file changes still need a yes first.)

**Standing arrangement — temporary build-file additions (Bill, 2026-06-09):** generalizing the above beyond the cgroups flag. When a task genuinely needs a tool or dependency that the project's image/build doesn't ship — a sanitizer runtime (`libasan`), a debugger, a profiler, an extra dev package, a one-off build flag — I'm **pre-authorized to add it to the `Dockerfile` / build files (and rebuild the image) without asking each time, *as long as it's temporary*.** The contract: by the time the task is **done**, I've removed those additions so the committed build files are back to only what the project actually ships. While the task is in flight the addition can stay (image rebuilds are expensive, so I don't add-and-revert every turn the way I do for the cgroups flag) — but I **track what I added** so cleanup isn't forgotten: a note in the task doc *and* a comment in the Dockerfile marking the line dev-only / to-be-removed, and I call it out when I add it. **Exception — keep, don't remove:** anything whose only purpose is making *nested* podman runs work (the `--cgroups=disabled` flag, a `PODMAN_RUN_FLAGS`-style passthrough variable threaded through a Makefile, etc.) is fine to leave in permanently — it's harmless to a normal host build and saves re-adding it each session. What still needs a yes: a **permanent** change to what the image ships (a real runtime dependency the project should carry going forward), as opposed to a temporary dev/debug aid.

**Other specifics:**
- **GUI apps CAN be run and screenshotted headlessly — without touching the project's Dockerfile.** The sandbox already ships `Xvfb` (`xorg-x11-server-Xvfb`, explicit in `runClaudeInContainer`'s `Dockerfile`) plus ImageMagick (`import`/`convert`) and Mesa's software GL. **Run the X server in the sandbox and share its socket into the nested container** — do NOT add xvfb to the project's image (Bill, 2026-07-18: "can you not change the Dockerfile for mvp?"). The recipe, verified on mvp's OpenGL demos:
  ```sh
  Xvfb :99 -screen 0 1280x800x24 &
  podman run --rm --cgroups=disabled -e DISPLAY=:99 \
      -v /tmp/.X11-unix:/tmp/.X11-unix -v "$(pwd)":/proj:Z <image> …
  ```
  Software GL works through this (glfw reports `4.6 (Compatibility Profile) Mesa`), so real GL demos render. Then **verify pixels, not just exit codes**: a GUI app that doesn't crash may still be drawing nothing. `import -display :99 -window root shot.png`, then check unique-colour count / non-black fraction, and *look at the PNG*. A long-running demo has no exit code worth reading — wrap it in `timeout N` and treat rc=124 as "ran the full duration", with a screenshot as the actual evidence.
- **If a project's editable install is broken, `-e PYTHONPATH=/proj/src` gets you running anyway** — don't let a packaging bug block behavioural verification. (mvp's `loadpackages.sh` currently fails on a missing `setuptools` build dep; the demos still run fine with PYTHONPATH set.)
- **`:Z` on EXTRA_MOUNTS poisons repos for host-side `make shell`.** The sandbox runs `--security-opt label=disable`, so a `:Z` project mount at sandbox launch relabels the whole repo to `container_file_t:s0:c1022,c1023` — which a normal *confined* container (the project's own `make shell`) cannot read, and its `:Z` won't relabel away. Symptom: `cd /<project>: Permission denied` inside the project container while the sandbox is (or was) up. Host-side fix: `sudo restorecon -R <repo>`; prevention: use `:z` or no label flag on EXTRA_MOUNTS entries (the label-disabled sandbox doesn't need `:Z` at all). Diagnosed 2026-07-07 (spimulator).
- **Networking just works** — default bridged/netavark networking is verified (an inner `apt update` / package pull reaches the network). No `--network` flag needed. If a run ever dies on `netavark: set sysctl ... Read-only file system`, `--network=host` is a working fallback.
- **Bind mounts use `:Z`** (SELinux relabel), e.g. `-v "$(pwd)":/workspace:Z`, matching this repo's convention.
- **Inner image store is ephemeral** (tmpfs) — pulled/built images don't survive the session; expect re-pulls.
- **Manage inner images by RAM pressure, not eagerly.** The store is a small **RAM-backed** tmpfs (`/var/lib/containers`, sized by `NESTED_PODMAN_TMPFS_SIZE`, **default 8g**), so every pulled/built image costs real memory. **Don't** `rmi` an image the moment you're done with it — keeping it avoids an expensive rebuild if you need it again this session. Instead, **before building or pulling a new image**, estimate its size (a Fedora/full-toolchain image is multiple GB; a slim base is hundreds of MB) and check headroom with `df -h /var/lib/containers`. Only if there isn't enough room, **evict** — `podman rmi` an existing image that seems unlikely to be needed again soon (and `podman image prune -f` for dangling layers) to make space. (`--rm` removes the *container*; the *image* persists until you `rmi` it.) The goal is fewest rebuilds within the RAM budget, not a clean store. Also: when validating in a throwaway image, install the baseline tools your check depends on first — a minimal base (e.g. `ubuntu:24.04`) ships no `python3`, which can make a check *silently pass*.
- **Storage is fuse-overlayfs**; `podman info --format '{{.Store.GraphDriverName}}'` reports `overlay` driven by it.
- The host Podman stays **rootless** — nested runs never gain privilege on the real host. Full rationale lives in the `runClaudeInContainer` repo's `CLAUDE.md` / `README.md` and `tasks/archive/.../nested-podman.md`.

## Verification gates in nested containers

When nested podman is available, "done" for a code change means **the project's own containerized gate passed** — the `make image` / `make test` / `make dist` target that repo's CLAUDE.md names as its gate — not merely an in-sandbox build and unit-test run. Build the nested container and run the real gate before calling a change verified.

- **Flag coverage is part of the gate.** Trimming feature flags (`BUILD_DOCS=0`, `BUILD_TREE_SITTER=0`, `USE_EMACS=0`, …) to speed a gate up is legitimate **only when the diff cannot affect the trimmed paths**. If a change touches any input that a flag-gated feature consumes — a shared header, a codegen/table source, docs sources — that flag must be ON in the gate; a green gate with the consuming feature compiled out verifies nothing about it. (Learned 2026-07-07 in spimulator: an `opcodes.h` tag rename sailed through three `BUILD_TREE_SITTER=0` image gates, then broke Bill's plain `make image` inside the tree-sitter keyword pipeline.)
- **Before ending a work session, run one gate with the repo's default flags** (a plain `make image`) — the defaults are what Bill actually runs — or, if that's genuinely not possible, say explicitly in the summary which flag-gated paths went unexercised.

## A multi-step check script must propagate every step's failure

**The design intent of `format.sh` (and any `make format` / `lint` / `check` target
that chains tools) is "run EVERY step, so one pass reports ALL the red" — deliberately
not fail-fast.** But a plain command sequence in a shell script exits with the **last
command's status alone**, so `make` reports green whenever the final step passes,
silently masking every earlier failure. This is not hypothetical; it has bitten twice:

- **mvp, 2026-07-09:** 79 `ty` diagnostics in `src/` hid for weeks behind a green
  format gate (the final `ty check` in the sequence happened to pass).
- **gacalc, 2026-07-29:** 3 `ty` errors were printed mid-output, then the last step
  (`ty check tools`) printed its own "All checks passed!" and `make format` exited 0 —
  the error report and the green verdict in the same scroll, and the gate was trusted
  over the scroll.

**The required shape — both properties at once** (every step still runs; any failure
fails the script):

```bash
status=0
ruff check . --fix       || status=1
ruff format              || status=1
ty check src             || status=1
ty check tests           || status=1
exit $status
```

(mvp's variant wraps this in a `run() { "$@" || status=1; }` helper — same thing.)

- **`set -e` is the WRONG fix** — it makes the script fail-*fast*, losing the
  report-everything property the multi-step design exists for. Accumulate, don't abort.
- **Loops need it per-iteration**: `for f in …; do clang-format -i "$f" || status=1;
  done` — a bare loop's exit is its last iteration's (this was gltron's flaw).
- **Safe by shape, no change needed:** a single-command script (its exit *is* the
  gate), and `find … -print0 | xargs -0 tool` (xargs exits 123 if any invocation
  failed — spimulator/texExpToPng's shape).
- **When writing or reviewing ANY gate script, check the exit-code story first:**
  "if step 1 fails and the last step passes, what does `make` see?" And don't trust a
  green gate over an error-bearing scroll — the 2026-07-29 case printed both.
- Audit of all mounted repos (2026-07-29): mvp was already correct; **gacalc, hanoi,
  multivariate-math, gltron fixed**; spimulator/texExpToPng safe by shape; the rest
  have no format script.

## Instrumentation-driven debugging (make the tools tell you what to do)

This is the working method Bill wants applied to any "I can't figure out why this won't work / where to even start" problem — build fights, upgrades, ports, migrations, flaky behavior, unfamiliar codebases. It's language- and tool-agnostic; the examples below are just whatever tool happens to be in front of you. The through-line: **make the machine tell you the truth, and make being wrong cheap.** Don't reason abstractly about what's probably wrong — instrument it so the tools *emit* the answer, then let their output *be* the plan.

- **The tool is the oracle, not your intuition.** Whatever tool sits closest to the problem — compiler, linker, type checker, linter, test runner, the program's own logs/stderr/exit code, `strace`/`ltrace`, a profiler, `git bisect` — is a source of precise, free, location-attached to-do items. Your job is mostly to *run the right probe and listen in the right order*, not to theorize. Prefer an experiment that makes the tool speak over an argument about what it would probably say.
- **Collect the whole truth, not the first casualty.** Most tools stop at the first failure and lie about scale. Force them to keep going and report everything — keep-going/max-errors modes, "run the whole suite not fail-fast," full-output not summary — then **categorize by failure-class × count × location.** That reframing is most of the value: it turns a vague dread ("this whole thing is broken / too old to fix") into *N failures, 2 classes that matter, most of them in one place* — a checklist with a denominator you can watch shrink.
- **Change one variable at a time.** Toggle a single flag / version / config / input per probe. When each probe isolates one dimension, the result attributes its own cause. **Throwaway containers are what make this cheap:** each `podman run --rm` is a clean, disposable universe where you can be wrong with zero blast radius and perfect reproducibility — copy the inputs in, work out-of-tree, and capture logs to a **mounted** path (anything written only *inside* the container dies with it; mount `-v scratch:/out` and write there). Reach for a fresh container the moment "did my environment change?" becomes a question.
- **To prove a refactor changed nothing, DERIVE the "before" mechanically — never hand-transcribe it.** When verifying that a migration is behaviour-preserving, the instinct is to write a reference implementation of the old code from reading it. That is a bug factory: I did it for a `np.matrix`→`np.ndarray` migration (mvp, 2026-07-18), fat-fingered a sign in one transcribed formula, and got a 14.5-unit "regression" that was entirely my own reference being wrong. Instead, **take the current source and mechanically revert only the one thing that changed** (`src.replace("np.array(", "np.matrix(")`), load it as a second module (`exec(compile(old_src, …), mod.__dict__)`), run the *same* driver against both, and diff the outputs. Same source, one variable, zero transcription — the honest answer came back `0.0` on every output. Generalizes to any language where you can build the old artifact from the new tree: check out the parent commit into a worktree, build both, diff the outputs.
- **Separate "make it work" from "make it right," on purpose.** First reach a known-good baseline with the *least invasive* crutches (suppressions, pinned versions, disabled features), so you have something that runs and a fixed point to diff against. Then remove the crutches *as the actual work*, one class at a time. Conflating the two is how you get stuck — you can't improve what you can't first run, and you can't tell a real fix from a lucky one without a baseline to compare to.
- **Move the wall, and log every wall.** Each fix uncovers the next failure; treat the problem as a sequence of walls and write each one down (the running findings log in the task doc) with the exact change that got past it. The path becomes reproducible and the "why" survives into the next session.
- **Two gates per change, never one.** Every step gets a **regression** check (does the known-good baseline still pass?) *and* a **progress** metric (did the target failure count drop?). Green-but-no-progress and progress-but-broken are both failures; watching only one hides the other.
- **Instrument the artifact, not just the build.** The same reflex applies once it compiles/starts: run it on a tiny known input (a one-line smoke test), diff actual output/exit code against expected, and bisect flags/inputs until a single variable explains the delta. When a symptom is opaque, find the *narrowest* invocation that reproduces it, then vary one thing at a time.

The habit in one line: **turn an unknown into a measured list, isolate causes in disposable environments, fix by class while a metric and a regression gate both stay honest.**

## Auto-imported references

Claude Code inlines `@`-path references from this file into context at load (recursively, up
to ~5 hops), so the referenced file's *content* is present every session rather than being
something I have to remember to open. This is the deterministic fix for "CLAUDE.md tells me to
read X but I skip it": the content is loaded by the harness, not by my choosing. Only the
always-relevant catalog goes here — the situational reference docs
(`nested-podman-design.md`, `claude-config-layering.md`, `sandbox-capability-map.md`) stay
read-on-demand, since inlining them every session would bloat context for no gain.

@~/.claude/reference/llm-overused-phrases.md
