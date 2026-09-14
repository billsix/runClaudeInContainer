# Communication — status updates, questions, and README shape

**Reference document** — the full rationale, incidents, and BAD/GOOD examples behind the
terse status-update / question / README rules in the cross-project `CLAUDE.md`. Read on demand
when writing a status update, asking the user a decision question, creating a task with open
questions, or shaping a project README. (Relocated verbatim from `CLAUDE.md`, 2026-09-14.)

## How much to tell me: if it went well, four sentences

**When the work went as planned, four sentences or fewer is perfect.** Say what the
outcome was and where the detail is written down. That's the whole report.

**The detail isn't omitted — it's RELOCATED**, into the task doc as you go (and into a
`tasks/reference/` doc if it outlives the task). Never write something into a doc and then
repeat it to me in chat; point at it instead, in one clause ("details in the task"), so I
can audit you cheaply when a commit smells wrong later.

**This is not a new rule.** It's "report the exceptions afterward" (see "Use your
discretion") applied to reporting in general: the exceptions earn chat, the rule-abiding
bulk doesn't — however much of it there was, and however well it went.

**The test is whether it changes what I do next, not whether it surprised you.**

- **Chat.** Something that changes what I believe about my own repo and that *predates
  your work* — a file that's been broken for a month, a doc claim that turns out to be
  false, work already finished but tracked as pending. A blocker. An action only I can
  take (`make html`, a hardware run, a decision). A question you need answered (those also
  keep their own numbered list — see "Questions for me go inline AND in a closing list").
- **The task doc.** Gates passing. Counts, timings, proofs, "the second run reported zero
  changes". Mistakes you made and then fixed inside the same piece of work — including a
  number you got wrong in your own task doc and corrected. Record them with the lesson;
  they change nothing for me.

**When things are NOT going to plan, invert this and give me the detail, at whatever
length it takes.** Four sentences is the reward for a clean run, not a cap on bad news.

**This calibration is a first draft, and we're still finding it (William Emerison Six
<billsix@gmail.com>, 2026-09-09).** Four sentences is a target, not a hard cap, and the
chat/doc split above is a starting partition rather than a settled one. When you genuinely
can't tell which side something falls on, **default to the task doc and say in one line
that you weren't sure** — that's cheap, because I can always ask for more, whereas I can't
un-read three paragraphs. And when a case comes up where this section reads wrong, say so
and we'll discuss it: this is meant to be revised as we learn what I actually need, not
applied rigidly.

## Questions for me go inline AND in a closing list

**This is the one deliberate exception to the "caveats stay inline only" rule, and it
applies only to questions you need *me* to answer** — not to caveats, warnings, or
recommendations, which stay inline only.

Raise a question at the point in the response where it arises — that's where the context
is. **Then repeat every one of them at the end, as a NUMBERED list**, one or two
sentences each. Without that list I have to re-read a long response hunting for what you
actually need from me, and questions buried mid-prose get missed (2026-07-18: I ended a
long status update with two questions in different paragraphs and the user's reply was "what
are you asking me?").

- **Number them (1., 2., 3.)**, not bullets, so I can answer by number.
- One item per question, phrased so it can be answered on its own. **Exactly one ask per
  numbered item — never staple a second, independent question onto the same one** (the tells
  are "…and separately, do you want X?", "also, should Y?", "…, and do you want it merged?").
  Two asks in one item means a one-word reply ("sure", "yes", "go ahead") answers only one and
  leaves you to silently drop or guess the other — split them into two numbered items instead.
  (2026-09-05: I bundled "archive the 8 now?" with "merge the branch or not?" into a single
  item; a bare "sure" could not decode to both, which is the whole failure this rule prevents.)
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

## Caveats belong with the step they affect

When you give me steps or instructions and one of them carries a caveat, warning, or gotcha, attach the caveat **to that step, inline, at the point I'd act on it** — not in a separate "notes" / "caveats" block afterward. If step 3 is risky, the warning goes **in step 3**, so I read it before I do the thing. Don't show me how to do something, let me do it, and then hand me a warning about an earlier step paragraphs (or 15 steps) later — by then it's too late to be useful, and it's frustrating. Same for summaries and recommendations: fold "but watch out for X" into the relevant line, don't append a trailing list of caveats I have to retroactively apply.

## A project's README is commands-forward; prose belongs in reference docs

**A README's job is to get me running, not to explain itself.** Keep it explicit and concise —
**commands forward, rationale trimmed.** The happy path should read as a short, copy-pasteable
sequence: ideally **few invocations** (prefer one wrapper / `make` target over five hand-run steps
where combining them hides nothing I need to see), each labelled with the environment it runs in
(`[HOST]` / `[CONTAINER]` / `[MAC]`, per "Host shell vs container shell") and a **one-line** "what it
does" — not a paragraph.

The prose-heavy material — *why* it works this way, design rationale, declined alternatives, deep
mechanics, the reasoning behind a flag — **is worth keeping, but does not belong in the README.** Move
it to a **reference doc** (`tasks/reference/<slug>.md`, per "Reference documents") and **link to it**
from the README with a one-liner ("Design details: `tasks/reference/architecture.md`"). The README
*points*; the reference doc *explains*. That keeps the README scannable for whoever just wants to run
the thing, while the *why* stays discoverable — and lives in the place I actually re-read.

- **Commands forward:** lead each step with the command block; put the one-line gloss after, not a
  preamble before.
- **Trim, don't delete:** a caveat that actually matters (a flag you MUST pass, a footgun that
  silently corrupts the output) stays inline — condensed to a `>`-quote or a single bold clause — but
  the *explanation* of why moves to the reference doc.
- **This is the same split as "harvest durable knowledge into reference docs," applied to the README:**
  task docs track the work, reference docs hold the *why*, the README holds the lean *how-to-run* and
  links to the other two.

**Worked example (William Emerison Six <billsix@gmail.com>, 2026-08-22).** runCrushInContainer's
"Airgapped rebuild" README section had grown to ~58 lines — three actual steps buried under paragraphs
explaining *why* the base image isn't vendored, *why* `hf` is flag-gated, and so on. Rewritten to ~41
lines: three numbered steps, command blocks first, each critical warning condensed to a one-line
`>`-quote, and the design rationale pushed into `tasks/reference/architecture.md` and linked. The
README now answers "what do I type?" at a glance; the "why" is one hop away for whoever needs it.
