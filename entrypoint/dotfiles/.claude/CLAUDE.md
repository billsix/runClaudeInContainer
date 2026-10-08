# Cross-project conventions

This file holds the **rules**, terse. The long rationale, worked examples, dated incidents, and
rejected-alternatives for each section are **relocated into topic reference docs** under
`~/.claude/reference/` (indexed at the end), read on demand — so a session pays their cost only
when the topic comes up. Each section keeps its rule inline and points at its doc for the "why".

## This file is the SHARED layer — personal specifics go in the overlay, not here

This file holds **portable, cross-project** conventions meant for anyone who adopts this
sandbox; it is version-controlled and shared. At the end it `@`-imports a **per-user
personal overlay**, `@~/.claude/ai-coding-conventions.personal.md`, which is NOT committed
to this repo — a blank default ships here, and each user's real file lives on their host and
is mounted in (see `FORKING.md`).

**So when you record or update anything maintainer-specific, write it to the personal
overlay — never to this file.** That includes: the user's identity/attribution format,
their project → repository-URL mapping, host/machine paths, mount layout, personal standing
authorizations, and any private project template. Keep this file person- and agent-generic;
the overlay carries "who I am and what my projects are." Its structure is shown in
`entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md`.

## Who "the user" is — identified by git config

Throughout these conventions the first person ("I", "me", "my") is the **user** — the
person running this session — and the second person ("you") is the agent. The user is
**not a fixed individual**: identify whoever is in the current session by their
`git config user.name` and `user.email` (the host `~/.gitconfig` is mounted into the
sandbox, and the shell exports `CLAUDE_USER_NAME` / `CLAUDE_USER_EMAIL` at start). Other
people will contribute over time; "the user" always means the current one, and you should
refer to them by that git identity rather than assuming a specific person.

- **When you write a new dated attribution or decision stamp, identify the user uniquely
  by name and email** — e.g. `(Your Name <you@example.com>, 2026-08-12)` — so
  a multi-contributor history stays unambiguous about who decided what. (Existing
  historical stamps and authorship credits are left as written; they already record who.)
  - **This is not just for git commits — it applies in TASK docs and especially REFERENCE
    docs, because the reader may not be you.** A `tasks/reference/` doc is read by other
    contributors (and future me) who do not know who "Bill" is; a bare first name there is
    ambiguous and violates this rule. **Never use a bare first name as a stamp** — always the
    full `Name <email>`. In doc *prose* (as opposed to a dated stamp), refer to the person by
    **role** ("the maintainer", "the author") or the full identity, introduced once at first
    use — not a first name the reader has to already know. (Learned 2026-08-14: I littered a
    gacalc reference doc with bare "Bill"; the fix is role-in-prose + `Name <email>`-in-stamps.)
- **When no git identity is available** (no `~/.gitconfig` mounted), treat the user as an
  unknown user rather than assuming a specific person.

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
a codemod. The per-language particulars that change are only: what the comment marker is,
which tool reflows what, and how you spell an opt-out (`# noqa: RULE`, `// NOLINT(rule)`,
`/* clang-format off */`, `// eslint-disable-line`, `#pragma GCC diagnostic ignored`, a
`.editorconfig` exception).

The worked example (an 80-column enforcement in mvp/Python/ruff — 78 lines fixed five
different ways, one deliberately left long) lives in
`~/.claude/reference/code-style-conventions.md` — read the *structure*, not the tooling.

## Never orphan a word on its own comment line

**Reflow the whole contiguous paragraph, not the offending line** — never leave a comment or
docstring line holding one word or a short sentence fragment. Applies to every comment syntax
(`#`, `//`, `/* … */`, `;;`, `--`, `%`, `!`) and to doc comments (docstrings, doxygen, javadoc,
`///`).

### Changing a line-length limit without causing that

Language-agnostic (tool names are examples): **(1)** set the limit in config in ONE place so
formatter and linter agree, and drop per-invocation `--line-length` flags; **(2)** run the
formatter first (it reflows code for free — the residue is prose + unbreakable tokens);
**(3)** fix the residue paragraph-wise with an **explicit allowlist you have read**, printing
before/after — do NOT try to automate it (it doesn't generalize); **(4)** never reflow
lists/tables, aligned literals, commented-out code, license headers, ASCII diagrams,
build-driving markers (doc-region, doxygen/javadoc tags, jupytext/org markers), or math whose
spacing carries meaning; **(5)** watch for line structure that is syntactically load-bearing
(macro trailing `\`, shell/Make continuations, Make recipe TABs, one-instruction-per-line asm,
a `//` comment inside embedded GLSL/SQL/regex) — shorten/restructure, never just insert a
newline; **(6)** re-verify: linter clean, formatter idempotent (`--check` no changes), code
still **builds**. Full detail + examples: `~/.claude/reference/code-style-conventions.md`.

## How much to tell me: if it went well, four sentences

**Work went as planned → four sentences or fewer**: the outcome and where the detail is
written down ("details in the task"). The detail isn't omitted, it's **relocated** into the
task doc as you go — never write it into a doc and then repeat it to me in chat. **The test
is whether it changes what I do next, not whether it surprised you.** Chat: something that
predates your work and changes what I believe about my repo (a long-broken file, a false doc
claim, work done-but-tracked-pending), a blocker, an action only I can take, a question you
need answered. Task doc: gates passing, counts, timings, proofs, mistakes you made and fixed
within the same unit. **Not going to plan → invert this and give me the detail**, at whatever
length it takes — four sentences is the reward for a clean run, not a cap on bad news. This is
a first-draft calibration (William Emerison Six <billsix@gmail.com>, 2026-09-09); when you
can't tell which side something falls on, default to the task doc and say so in one line. Full
rationale + incidents: `~/.claude/reference/communication-conventions.md`.

## Caveats belong with the step they affect

Attach a caveat/warning/gotcha **inline, at the step where I'd act on it** — not in a trailing
"notes"/"caveats" block. If step 3 is risky, the warning goes **in step 3**. Same for
summaries and recommendations: fold "but watch out for X" into the relevant line, don't append
a trailing list I have to retroactively apply. (See `~/.claude/reference/communication-conventions.md`.)

## Comments and docstrings describe the present, not the history

A comment or docstring says what the code **does now** — never what it *used to* do or *why it
changed*. Don't write "this replaces the old X", "previously returned Y (which was wrong)", "changed
from Z", or "new in vN" in a docstring/comment: a reader wants the current behavior, and the
change-history/rationale belongs in the **`CHANGELOG`** (for a consumer-facing change) and the
**commit message** (always) — not in source text every future reader re-reads. Describe the behavior,
cite a proof/spec/equation if it helps, and let git + the changelog carry "what it was and why it
moved." Language-agnostic (every comment and doc-comment syntax). This is the same spirit as the
open-issues rule below (docs hold the current state; history lives in git). Detail + examples:
`~/.claude/reference/code-style-conventions.md`.

## Words and phrases you overuse — notice them, and vary

**This is about readability, not disguise.** Every one of these is a legitimate word — the
tell is *frequency*, so the goal is rationing and variety, not a ban. **The distilled offender
list below stays inline here — always in front of you.** The **full catalog** (each offender's
meaning, ~15 alternatives, which are worth keeping) is **`~/.claude/reference/llm-overused-phrases.md`**
— **read it on demand when you want the alternatives or rationale for a specific offender.**

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

## Python: the shared coding standard lives in a reference doc

For **Python** specifically, the full coding standard — the ruff-enforced tiers plus the judgment
calls ruff can't check (naming grammar, expression / mutate-vs-return, reduce-with-`sum`, annotate every
binding, the idiom checklist) — is a shared cross-project reference doc, **read on demand:
`~/.claude/reference/python-coding-standard.md`** (not auto-imported, so it costs nothing until you
open it). The language-agnostic conventions in this file apply to Python too; a project keeps only
its own repo-specific Python invariants inline in its `CLAUDE.md`. The canonical source and its
mirrors (including the Crush client's baked copy) are named in that doc's header.

## An externally-defined name always wins over a naming convention

**A name dictated by something outside the code — a framework superclass method you override, a
protocol/interface member, a callback signature, a magic name a library looks up, a wire-format
field, an env var or CLI flag someone else specifies — is exempt from the naming rules.**
Renaming it doesn't tidy it, it *unbinds* it and silently breaks the code; match it exactly,
however ugly. A linter flagging it is wrong — suppress narrowly (`per-file-ignores`, inline
`noqa`/`NOLINT`) **with the reason at the site**, note the exemption in the project's conventions
doc, and keep house style for the parameters/locals/helpers *inside* such a method. Examples +
full detail: `~/.claude/reference/code-style-conventions.md`.

## What earns pulling code into its own function

**Duplication, or naming a distinct phase — NOT reshaping control flow** (language-agnostic).
Lift to shared/module scope when more than one caller needs it; nest it when it closes over the
enclosing function's parameters and names a real phase; do **neither** when the helper would be
used exactly once and only reshapes control flow or avoids mutating a local. Corollary: **raise
the error from the code that discovers it.** Don't chase a shape for its own sake or churn
existing early-return code — a cheap top-of-function guard is usually right. Cases + net-line
counts: `~/.claude/reference/code-style-conventions.md`.

## Prefer total dispatch over an open-ended conditional chain

**An `if`/`else if` chain with no final `else` can fall through silently, and the hole is
invisible.** Prefer a construct with a mandatory-feeling default (`match`/`case _`,
`switch`/`default`, a sealed-type match) — **the discipline is the pairing: always write the
default branch** (raise, a documented fallback, or an explicit commented no-op). Where the
language checks it for you (`-Wswitch`, exhaustive ML matches), let it. Caveat: `match` earns
its keep on *structural* patterns; a `match` whose every case is a boolean guard is an
`if`/`elif` chain in disguise — don't convert every two-branch conditional. Bug-class example:
`~/.claude/reference/code-style-conventions.md`.

## Keep the original goal in sight; a prerequisite is not a new project

**Before designing around a blocker, verify the blocker is real** (try it, watch it fail — don't
inherit a blocking claim from a doc, including one you wrote). **Say the goal chain out loud at
each level of nesting** ("to do A I need B, which needs C"); three levels deep is a
stop-and-report point. If a small request has grown to touch dozens of files, surface that
disproportion **before** doing the work. If the goal turns out already met, say so and stop —
don't roll into an adjacent improvement (a good idea found mid-drift is still drift; park it in
its own task doc for a fresh decision). Signature incident + discipline:
`~/.claude/reference/diversion-stack-and-scope.md`.

## Questions for me go inline AND in a closing list

**The one deliberate exception to "caveats stay inline only", and only for questions you need
*me* to answer.** Raise a question where it arises, **then repeat every one at the end as a
NUMBERED list** (1., 2., 3.), one per line, so I can answer by number. **Exactly one ask per
item** — never staple a second independent question on (a one-word "sure" then answers only one).
It's fine to say "see above for detail" and keep the item short; put your recommendation in the
item; don't manufacture an empty "Questions" section. Rationale + incidents:
`~/.claude/reference/communication-conventions.md`.

### Never cite an artifact you have not verified exists

**A reference to a file, function, ticket, task doc, or command is a claim it is there** —
`ls`/grep the path before writing it down, create-then-cite (or mark it explicitly
hypothetical), and when a doc moves/archives, fix what pointed at it in the same change.
Applies to `See also:`, commit/PR links, manpage `SEE ALSO`, header includes, a Makefile target
you tell me to run. (Detail: `~/.claude/reference/communication-conventions.md`.)

### A bare label is not a reference — name it, and say where it lives

"Option 2", "Tier 1", "the approach we discussed" are pointers I am usually not holding.
**Every reference to a named/numbered item must carry, on first use *each response*, a short
gloss of what it IS and — if it lives in a file — the file path.** Never invent a new label
mid-answer and use it as if I know it (say "grouping these myself, not in the doc"); re-list the
options before recommending after a gap; say so if a numbering changed. BAD/GOOD examples:
`~/.claude/reference/communication-conventions.md`.

### Name the positions in the question; never say "change your mind"

**A decision question must state what the options ARE** — never "does that change your mind?".
Carry: the position on the table (named, and whose it is), the specific alternative (named), and
what actually differs (a number/file-count/behaviour). **Never ask an either/or that yes/no
can't answer** — either ask a single yes/no or label the alternatives ("(a) … or (b) …") so a
one-word reply decodes; when a short reply is ambiguous, ask rather than picking the likelier
branch. Same when re-asking an unanswered question. BAD/GOOD:
`~/.claude/reference/communication-conventions.md`.

### Every question must be addressed before you implement anything

**An open question blocks implementation** — don't write code / edit / run mutating commands
that depend on the answer until each numbered question is addressed. "Addressed" is a low bar:
a real answer; "your call"/"don't care" (→ use your discretion, proceed); "skip that for now"
(→ leave it). **Silence does not count** — say which numbers went unaddressed, re-ask them
(as their own numbered items, answerable cold), and wait. Investigation and measurement are
always fine. (Detail: `~/.claude/reference/communication-conventions.md`.)

## Version numbers don't sort like strings

**Sort/compare versions AS versions, not text** — `0.0.10` > `0.0.7` but sorts before it
lexically, so the newest release vanishes from the end of an alphabetical list. Use `sort -V` /
`git tag --sort=v:refname` / `packaging.version.Version`; **before reporting a version missing
or older than expected, re-check with a version-aware sort** and prefer asking the authoritative
source (PyPI JSON API, `git show <tag>`, package metadata). The double-digit boundary is where
it bites: invisible through `0.0.9`, lying at `0.0.10`. Full example:
`~/.claude/reference/versioning-and-changelogs.md`.

## Changelogs, versioning, and communicating breaking changes

For any project **others pin/consume** (a library on a registry, a tool people pin), two
artifacts prevent silent breakage: a **version number** and a **`CHANGELOG.md`**. A private app
nobody pins needs neither. Full rules — breaking-change list, when to write entries, retro-fill —
in `~/.claude/reference/versioning-and-changelogs.md`.

### Versioning (SemVer), and the pre-1.0 reality

`MAJOR.MINOR.PATCH`: breaking→MAJOR, feature→MINOR, fix→PATCH. **Pre-1.0 (`0.y.z`)** may break
anything, but *permission to break is not permission to break silently* — still bump (breaking →
`0.Y.0`, compatible → PATCH) and **always changelog it**. **Bump the version BEFORE publishing**
(registries permanently reject a re-used number). Split: you (agent) stage the bump + changelog
entry; I (user) tag and publish. (Detail: `~/.claude/reference/versioning-and-changelogs.md`.)

### What counts as "breaking" (the things a consumer must be told)

A public name renamed/removed; a default value or behavior changed; a return/accepted-input type
changed or validation tightened; a new required parameter, or a type made immutable/unhashable;
dropped platform/version/dependency support; a license change. **The test:** would a consumer who
bumps the pin have to change their code, or be surprised? If yes, it's breaking — flag it. (Full
list: `~/.claude/reference/versioning-and-changelogs.md`.)

### The changelog: what goes in, and WHEN

A root `CHANGELOG.md`, newest-first, `[Unreleased]` at top then `## [version] — date`; group by
Keep-a-Changelog categories and **call out breaking items explicitly**. Lean — only what would
break/surprise a consumer, prefer a one-line entry linking the *why*. **Write the entry WHEN you
make the change** (it's a finished unit's doc delta) and **reconcile at the three look-back
moments** (pre-squash harvest, session-end sweep, release): diff the public surface since the last
tag against `[Unreleased]`. Promoting `[Unreleased]` → `## [version] — date` is part of the version
bump (same commit as the tag). Full detail incl. `tools/check_changelog.py` and retro-fill:
`~/.claude/reference/versioning-and-changelogs.md`.

## Git: I commit, you don't — but you DO stage

Committing (and pushing) is **mine**, done outside the container on my own schedule — don't read
an absence of commits as work lost. **Staging is your half of the handoff and is the default, not
an option:** when a coherent unit is done, `git add` the files it touched **by path** (never
`git add -A`) and say so; by end of a work chunk `git status` should read as a handoff (staged =
the work, unstaged = in-flight or not yours to give). **A finished unit's doc deltas ship in that
same staging** — the `CLAUDE.md`/`README`/`tasks/reference/` entries the unit conceptually touches,
and a `CHANGELOG.md` `[Unreleased]` entry where the repo has one (unit-scoped, not a full
always-read re-read — that's the session-end sweep). Staging writes content into `.git/objects` so
it survives a clobber; err toward staging early and often. **Stage, then stop** — never `git commit`
/ `git push` unless I ask in that moment, and don't keep asking "want me to commit?". To learn what
happened, **read the git history**. Full bullets + rationale:
`~/.claude/reference/git-workflow-conventions.md`.

## Quick-save commits, then squash to a per-task history (only when I authorize committing)

**Only when I've said, this session, that you may commit** (typically a long unattended task) —
the say-so is the trigger and doesn't carry to the next session. Then: **quick-saves** as you go
(one commit per meaningful step, restore points, honestly labelled) → at the end **squash to
one-commit-per-task**, folding `tasks:` tracking commits into the work commit. Mechanics
(no interactive editor): back up to a `backup` branch, reconstruct on a temp branch with
`git cherry-pick -n <parent>..<end>` + `git commit -F msg` (note: `cherry-pick` has no `-q`),
and verify `git diff <rebuilt> <backup>` is **empty** before `reset --hard`. **Before a squash,
harvest the commit history into the task doc** (walk `<upstream>..HEAD`, record every
decision/rejection chronologically, reconcile `[Unreleased]`) and **normalize the doc into ONE
consistent tense/voice**. Full detail: `~/.claude/reference/git-workflow-conventions.md`.

## Task documents

For non-trivial / multi-step / resumable work, keep `tasks/<slug>.md` in the repo root, one per
task, updated as it progresses. **Write it to be executed COLD** — everything a fresh reader needs
is in the doc or files it points to (what to read first, current code state, links to related
tasks/reference docs, decisions **with rationale**); never lean on session memory. A non-trivial
task **leads with `## BLUF`** (1–4 sentences: what it is + what "done" means; full write-up
`~/.claude/reference/bluf-bottom-line-up-front.md`) **and `## Context`** (cold-start orientation).
Don't make a task for one-off questions. If a task's Open questions are non-empty, surface them as
a numbered list when you report making it (and they still block implementation). Full conventions +
lifecycle: `~/.claude/reference/task-doc-conventions.md`. Helpers: `/new-task`, `/archive-task`,
`/recheck-blocked`.

### Priority & difficulty (rough triage for "what to work on next")

Two 1–10 ratings under `**Status:**`: **`**Priority:**`** (1 = do-first, 10 = least; parked and
blocked tasks get a high number) and **`**Difficulty:**`** (1 = easiest, 10 = hardest). The scale
is **geometric** (~1.5× per step). **Pick next work by lowest priority-number, then lowest
difficulty-number** — high-value easy wins first. Anchors + rationale:
`~/.claude/reference/task-doc-conventions.md`.

### Blocked tasks — deferred until an external condition changes

For work gated on something **outside our control** (upstream ships X, a release, a hands-on
verification only I can do), set `**Status:** blocked` plus **`**Blocked on:**`** (the condition,
one line) and **`**Recheck:**`** (a cheap runnable check + the signal that means "cleared"). Both
blocked and parked tasks get a high priority-number and are excluded from the easy-wins ranking;
**blocked ≠ parked** (blocked is a concrete testable gate). `/recheck-blocked` tests them **on
demand — never automatic**. Detail: `~/.claude/reference/task-doc-conventions.md`.

### Step tasks — an umbrella task with sequenced children

For a **multi-step initiative too big for one doc** (3+ sizeable sequential chunks, or steps with
their own commit boundaries): an **umbrella** (`tasks/<initiative>.md` — vision, rationale, the
ordered step list = the index, cross-step decisions) plus one **step-task** each
(`tasks/<initiative>-step-N-<slug>.md`, header links `Part of:` / `Depends on:` / `Next:`).
**Express ordering with Priority + a "Depends on" note, NOT `blocked`** (a step waiting on an
earlier step is within our control). Track status in both the step-task and an umbrella checklist;
each step archives on its own completion, the umbrella when the last step lands. **Don't
over-scaffold** — a two-step job is one task with a phase list. Detail:
`~/.claude/reference/task-doc-conventions.md`.

Archiving: when complete, **move** the file to `tasks/archive/<YYYY>/<MM>/<DD>/<slug>.md`.
**Archiving is yours to do proactively at the moment of completion — no go/no-go question**
(harvest to reference docs, fix inbound pointers, `git mv`, `git rm` one-shot adhoc scripts); never
present a done task as an archive *candidate*. **BUT the archive is its OWN commit AFTER the work
commit** — the three-commit lifecycle is (1) task-add, (2) work + adhoc scripts, (3) archive-move +
one-shot `git rm`. **Always `git mv` the archive (and `git add` its new path) so the rename is
STAGED — never a plain `mv`.** A plain `mv` leaves the old path tracked-deleted and the new path
untracked, so a `git add -u`/`git commit -a` of the work then commits the deletion and **orphans**
the archived doc — it lands in HEAD nowhere, surviving only as an untracked file (incident: gacalc
2026-10-08). "Separate commit" means a separate *commit*, NOT *unstaged*: keep the archive out of the
*work's* commit by committing the work paths first, then the archive paths — never one combined
"work + archive". When I commit by default, stage the archive rename (an owed, tracked action I commit
separately); when you're authorized to commit this session, you make both commits. At session start, scan `tasks/` (not
`tasks/archive/`) for in-flight work, list easy-wins-first, and list `blocked` tasks separately.
Full lifecycle + incidents: `~/.claude/reference/task-doc-conventions.md`.

## Ad-hoc scripts — save the substantive ones under `tasks/adhoc/`

Save **substantive** throwaway scripts (codemods, bulk edits, verification/proof harnesses,
one-time generative setup) under `tasks/adhoc/<task-slug>/<name>` and run them from there — a
committed record of the mechanical "how". **Skip one-liners**, scripts that merely reproduce a
permanent file edit, and env setup outside the project. **Paths must be relative — to the script
itself or the repo root — NEVER container-absolute** (`pathlib.Path(__file__).resolve().parents[3]`
or `git rev-parse --show-toplevel`), covering what the script reads AND writes. **Make a
file-mutating codemod idempotent and prove it** (run twice, second run = zero changes). If it
changes mid-task, revert the **processed files** by path (`git checkout <pre-script-SHA> --
<files>`, never whole-tree) and re-run the FINAL script once, confirming `git diff` is empty. At
archive: **one-shot → `git rm`** (in the archive commit, after the work commit — track the owed
deletion); **reusable → promote to `tools/`** (light cleanup + docstring, note it in a reference
doc, propose but don't auto-wire a gate). Put a `.keep` in every convention dir.

**Bulk op (find-many → fix-each)? Discover with a shell tool, don't tree-walk in Python** — one
`rg -n` / `git grep -n` returns just the matches instead of the model reading every file
front-to-back. Log them to `tasks/adhoc/<slug>/data/` (a committed *snapshot* worklog, `git rm`'d
with the script) and save the discovery command as `discover.sh` — a bulk discovery command IS
substantive (its output drove the diff), so it is exempt from "skip one-liners". The fix matches on
**content or a marker, not the saved line numbers** (they rot as edits shift lines — cf.
`print-debugging.md`'s `DBG` marker); process bottom-up if it changes line count; idempotency is a
bonus, not required (the point is the worklog). Verify by re-grep = zero.

Full detail + incidents: `~/.claude/reference/task-doc-conventions.md`; bulk-op command idioms:
`~/.claude/reference/shell-and-gate-scripts.md`.

## Reference documents — durable knowledge that isn't tracked work

Durable knowledge that **outlives** the work that produced it (comparisons, survey/landscape,
investigation conclusions, design rationale/decision records, capability maps/gap analyses, domain
notes) lives in `tasks/reference/<slug>.md`, one per topic, **never archived**, updated in place.
The test: "still worth reading after the work is done, and states what is TRUE not what to DO."
Think of it as an expanded, agent-facing `CLAUDE.md`. **When archiving a task, first harvest its
decisions/rationale into a reference doc**, then slim the task to a lean work record that points to
it. **When you archive a survey/investigation whose deliverable recommends an action, also scaffold
the follow-on task** (`proposed — needs go-ahead`, or `blocked` on the one decision), cross-linked
— don't strand the recommendation. Read the relevant reference doc before touching a subsystem it
covers. Full conventions: `~/.claude/reference/reference-doc-conventions.md`. Helpers:
`/new-reference`, `/new-reference-set`.

### Layered reference documents — levels of detail (LoD)

A big topic (or a *set*) can be written at layers: **L0** a one-paragraph capsule (all L0s
aggregate into a set's `tasks/reference/<set>/README.md` map = TOC + status board), **L1** a
code-free one-page mental model (only when non-obvious, self-contained, and not another topic's
job), **L2** the anchored mechanism, **L3** the source (cite by **stable named anchor**, never a
line number — they rot). Generate **deepest-first, then compress upward** (~half the lines per
level), and **compare each doc to a baseline the reader knows**. Rules + naming:
`~/.claude/reference/reference-doc-conventions.md`.

### Authoring a reference set for a codebase you don't know (Bill, 2026-07-31)

Fan out **one reader per subsystem in parallel** (each returns a structured, `file:line`-anchored
report), synthesize yourself, and **verify any claim a durable doc will be trusted on** —
especially "X is dead/vestigial" and "the seam is here" (one agent pass is a lead, not proof; "grep
found nothing" is not proof of absence). **Distinguish live from dead code explicitly.** Use git
history for *why/when/who*, current code for *what-is-true-now*. Full method:
`~/.claude/reference/reference-doc-conventions.md`.

### Reference docs for a versioned dependency — pin, banner, re-sync (Bill, 2026-07-31)

When a reference set describes a **dependency pinned by submodule/SHA**, the docs rot when the pin
moves: **pin the docs to the exact commit the consumer builds** (banner the SHA + `git describe`),
give a **one-line re-sync check**, and re-verify on a bump (a version bump can be a structural
refactor, not line drift). Name the doc by what's present at the pinned version; a consumer's doc
cites the dependency's own pinned docs, never drifting line numbers. Full method:
`~/.claude/reference/reference-doc-conventions.md`.

### Ending a session — sweep the always-read docs (Bill, 2026-07-21)

When I signal end-of-session, reconcile each touched project's always-read docs (`CLAUDE.md`, every
`tasks/reference/*`, `README.md`) against what changed — flag stale/missing/misplaced, then **apply
the updates** (keep `CLAUDE.md` lean, push detail to reference docs), reconcile any `CHANGELOG.md`
`[Unreleased]`, and **stage everything**. **This sweep is a VERIFICATION NET** — each finished unit
already shipped its doc deltas at staging time, so expect to find nothing from properly finished
units; it catches conversation-only decisions, cross-repo drift, and mid-session redesigns. Also
remind me of any `blocked` tasks (don't run their network re-checks yourself).

**Then run each touched project's format + type-check gate** (whatever its `CLAUDE.md`/`README`
names — e.g. `make format` / `make type-check` / `make lint`), and fix what it reports, **before I
commit** — I commit and push at session end, so a green local gate is what keeps CI green.
**A project's *test* gate often does NOT run the type-checker or linter** (e.g. a `make test` that is
pytest-only while `ty`/ruff run under `make format`) — and `ty`/type errors slip through tests
silently — so run the actual **format/type-check/lint** gate CI runs, not just the tests. Match CI:
run the same `make` targets `.github/workflows/*` invoke. Full checklist:
`~/.claude/reference/reference-doc-conventions.md`.

## A project's README is commands-forward; prose belongs in reference docs

A README gets me running: **commands forward, rationale trimmed, few invocations** (prefer one
wrapper/`make` target over many hand-run steps), each step labelled with where it runs
(`[HOST]`/`[CONTAINER]`/`[MAC]`) + a one-line gloss. Prose-heavy *why* (design rationale, declined
alternatives, deep mechanics, the reasoning behind a flag) moves to a reference doc, **linked** from
the README. Trim, don't delete: a caveat that actually matters stays inline as a one-line `>`-note,
its explanation in the reference doc. Worked example: `~/.claude/reference/communication-conventions.md`.

## The diversion trail — a rabbit-hole depth gauge, read bottom-up

A **global (cross-repo)** breadcrumb trail of diversions at `~/.claude/stack.md` (`@`-imported every
session), read **bottom-up**: the bottom entry is the root purpose, each entry above is a diversion
from the one below. It is a depth gauge, **not** a to-do list. **You keep it current yourself,
unprompted:** push the current work before chasing something discovered mid-task (do it silently;
two things must survive a push — the concrete next action and every unanswered question verbatim),
pop when done, drop only with my say-so (recording why), reconcile at session start, and **surface
drift unprompted** ("we're 4 diversions deep; the root purpose was X"). When a deep choice comes up,
check it against the root and say so if the tangent has grown out of proportion. Slash commands
(`/stack-push`, `/stack`, `/stack-pop`, `/stack-drop`) are manual overrides. Full rationale +
mechanics: `~/.claude/reference/diversion-stack-and-scope.md`.

## Repo audits

- `/audit-repo` — full read of the current repo, cross-referencing the docs (CLAUDE.md, README, task docs) against the actual source to surface stale claims, undocumented features, and internal inconsistencies. **Read-only** — it reports findings and stops.
- `/findings-to-tasks` — turn those findings (or any list of discussion items) into in-depth task docs under `tasks/`, one per item, each `proposed — needs go-ahead`.

## Open-issues sections in project docs

An "open/known issues" list in a `CLAUDE.md` or `README` holds only **genuinely open** items —
when one is resolved, **remove it** (don't leave it struck-through/annotated "resolved"); the
history lives in git and archived tasks. A curated changelog or deliberate "resolved" section is
fine. (See `~/.claude/reference/task-doc-conventions.md`.)

## Multi-repo sessions

This container often has more than one repo bind-mounted at top-level paths like `/foo`, `/bar`. Claude Code only auto-loads the `CLAUDE.md` of the current working directory's repo, so to be aware of the others:

At session start, scan top-level directories at `/`. A directory is a project mount if it contains either `.git/` or `CLAUDE.md`. Skip these system paths: `/bin`, `/boot`, `/dev`, `/etc`, `/home`, `/lib`, `/lib64`, `/media`, `/mnt`, `/opt`, `/proc`, `/root`, `/run`, `/sbin`, `/srv`, `/sys`, `/tmp`, `/usr`, `/var`.

For each mount found, read its `CLAUDE.md` if present and apply those rules when working in that repo. Also check each for in-flight items under `tasks/` (per the convention above). Don't announce the scan unless I ask — just internalize each repo's conventions so you behave correctly when I reference paths in any of them. If a `CLAUDE.md` in one repo contradicts the rules here or in another mounted repo, the repo-local file wins **for work inside that repo only**.

### Reference projects by their canonical URL in committed docs, not the container path

My projects are local git checkouts bind-mounted at container paths (`/foo/opt/<name>`, etc.) that
exist **only inside this sandbox**. In conversation the local path is fine; **in anything committed
or shared** (README, CLAUDE.md, task/reference doc, code comment, commit/PR body) **use the
project's canonical remote URL, read from the appropriate git remote — and if you can't confirm it,
ask rather than invent one** (a mount's directory name can differ from the repo name). Which remote
to read and the project → URL mapping are personal — see `ai-coding-conventions.personal.md`.

## My project layout (the container-per-project template)

Most of my projects share one container-per-project template (Fedora + Podman
ephemeral-container: a `Dockerfile`, a `Makefile` of `podman run --rm` targets, `entrypoint/`
scripts). When a new project is mounted, use it as a **conformance reference** — flag accidental
drift (stale copy-paste, wrong paths, missing targets); deliberate variation is fine. The
tier-by-tier spec and per-project examples are personal (`ai-coding-conventions.personal.md`);
per-project specifics belong in that project's own `CLAUDE.md`.

## Running projects in a nested container

Most of my projects build/run *themselves* in a container (a `Makefile` target wrapping `podman
run`); you can run those **nested** inside this sandbox. **Assume nested support is present and just
run the plain nested command** (`make image`/`make test`/`make shell`) — the sandbox exports
`NESTED_PODMAN=1` into the session and each converted Makefile's `PODMAN_RUN_FLAGS` auto-applies
`--cgroups=disabled`; **never pass `NESTED_PODMAN=1` on a downstream command** (it belongs only on
the outermost host launch, which is the user's to run). Verify only **if a run errors**
(`/dev/fuse` absent ⇒ tell me to relaunch with `make shell NESTED_PODMAN=1`). Converting an
unconverted project's Makefile to `PODMAN_RUN_FLAGS` is pre-authorized. **`NESTED_PODMAN` is run
capability ONLY; image *content* keys off a separate opt-in `MINIMAL_IMAGE`** (renamed from the old
overloaded `NESTED_PODMAN` 2026-09-27): pass `MINIMAL_IMAGE=1` to `make image` for a lean
export/airgap image — a nested `make image` builds FULL by default now that the inner store is on disk
— and it never applies to the sandboxes themselves (`~/.claude/reference/minimal-nested-images.md`).
Standing nested-run authorizations are personal (`ai-coding-conventions.personal.md`). Full specifics — the headless
Xvfb/screenshot recipe, PYTHONPATH escape hatch, `:Z`-poisons-repos, RAM store management,
networking — in `~/.claude/reference/nested-run-and-gates.md`; flag design/lore in
`~/.claude/reference/nested-podman-design.md`.

## The Bash tool runs commands through the user's login shell (here: zsh) — wrap patterns in `bash -c`

My Bash tool runs each command through the user's interactive login shell, **`zsh`, not `bash`**, so
unquoted globs error (`no matches found`), and `[...]`/`|`/`[[ ]]`/heredocs can trip zsh parsing
(`(eval):N:`, `parse error near '<word>'`). **Fix: wrap any command using shell patterns, bashisms,
or multi-line constructs in `bash -c '…'`** (single-quoted body handed to bash verbatim). A bare
simple command (`git status`, `ls`, a single tool with quoted args) is fine as-is. Symptoms +
detail: `~/.claude/reference/shell-and-gate-scripts.md`.

## Verification gates in nested containers

When nested podman is available, "done" for a code change means **the project's own containerized
gate passed** (`make image`/`test`/`dist` — whatever its CLAUDE.md names), not just an in-sandbox
build. **Flag coverage is part of the gate:** trimming a feature flag to speed it up is legitimate
only when the diff can't affect the trimmed paths — if the change touches an input a flag-gated
feature consumes, that flag must be ON. **Before ending a session, run one gate with the repo's
default flags** (or say which flag-gated paths went unexercised). **Gotcha (2026-10-04): a gate target
declared `: image` re-runs the whole `podman build` when nested** (the host image is only a read-only
base, not build cache) — run the gate's own `podman run` line against the existing image instead.
Incident + detail: `~/.claude/reference/nested-run-and-gates.md`.

## A multi-step check script must propagate every step's failure

A `format`/`lint`/`check` script that chains tools must run **every** step (report all the red) yet
fail if **any** failed — a plain sequence exits with only the last command's status, silently
masking earlier failures. Required shape: `status=0; cmd || status=1; … exit $status`
(per-iteration in loops). **`set -e` is the WRONG fix** (fail-fast loses the report-everything
property). Safe by shape: a single-command script, or `find … -print0 | xargs -0 tool`. Incidents +
the code shape: `~/.claude/reference/shell-and-gate-scripts.md`.

## Rewriting a script's contents drops its executable bit — restore it

`Write` (any full-file rewrite) creates mode 644, so rewriting a committed script strips its `+x` —
even a content-only pass. A script **invoked directly** (a Dockerfile `RUN /path/foo.sh`, a Makefile
recipe by path) then dies with `Permission denied`, often commits later; ones invoked as `bash
foo.sh` survive, which is why it's easy to miss. **After editing any script, check the modes and
restore in the same change:** `git ls-files -s -- '*.sh'`, then `chmod +x <paths> && git add
--chmod=+x <paths>`. Incident: `~/.claude/reference/shell-and-gate-scripts.md`.

## Write format/check scripts to run BOTH in the container AND on the host from the repo root

A `format.sh`/gate script should be **portable** — runnable in-container and on the host from the
repo root. Avoid the two things that make it container-only: **(1)** an unguarded `source
/venv/bin/activate` (guard it: `[ -f /venv/bin/activate ] && source …`); **(2)** absolute container
tool paths (use RELATIVE paths and let the caller `cd` to the root) — or **(3)** guard a
hardcoded self-`cd` so it no-ops on the host (`[ -d /<proj> ] && cd /<proj>`, not `cd /<proj> || exit
1`). The host run still needs the package importable for the type-checker step. Rules + the
cross-repo sweep: `~/.claude/reference/shell-and-gate-scripts.md`.

## Instrumentation-driven debugging (make the tools tell you what to do)

**Make the machine tell you the truth, and make being wrong cheap.** The tool closest to the problem
(compiler, linter, type-checker, test runner, logs/stderr/exit code, `strace`, profiler,
`git bisect`) is a precise, location-attached to-do list — run the right probe and listen, don't
theorize. Collect the **whole** truth (keep-going mode, categorize by class × count × location),
change **one variable at a time** in disposable containers, keep a **regression** check *and* a
**progress** metric per step, and reach a known-good baseline before removing crutches by class. To
prove a refactor changed nothing, **derive the "before" mechanically** (revert the one thing, diff
outputs) — never hand-transcribe it. Full method + the hand-instrumentation (print/trace) per-language
recipes: **`~/.claude/reference/print-debugging.md`** — read it **before** hand-instrumenting a bug
in an unfamiliar language.

## Generating source code (any target language)

When you write a **code generator**, prefer building **STRUCTURED output** (an AST + pretty-printer,
a builder API — Python `ast` + `ast.unparse`) over concatenating strings: correct-by-construction,
a whole bug class gone. The ergonomic sweet spot is **template-splice / quasiquote** (parse a snippet
with holes, fill programmatically), between raw strings and hand-built nodes. Define "same output" as
**equivalence** (structural `ast.dump` + behavioural test parity), not byte-identity; build a
**parity harness first**, convert one emitter at a time; guard **run-to-run determinism** as a gate.
**Never hand-edit a generated file** — change its template/list/generator and regenerate; the project
`CLAUDE.md` records the output → source mapping. Full lessons + the gacalc A/B/C study:
`~/.claude/reference/codegen-conventions.md`.

## Reference docs — read-on-demand at a trigger, plus the two that are auto-imported

Claude Code inlines `@`-path references from this file at load, putting the target's *content* in
context every session. That is the right default only for things that must be **present and current
every session regardless of the task** — so only **two** are `@`-imported: the diversion stack and
the personal overlay (below). The **topic** reference docs are **not** auto-imported — they would
cost many thousands of tokens every session for material most sessions never touch. Each is instead
**read-on-demand at a trigger**, so its cost is paid only when the topic actually comes up. To avoid
the failure that first motivated auto-importing (2026-07-31: a passively-referenced catalog went
unread), each trigger below is a **standing instruction — read the doc when the trigger fires**, not
a passive "see also", and each doc's *everyday* essence is kept inline in its own section so the
always-relevant part is never gated behind a lookup (William Emerison Six <billsix@gmail.com>,
2026-09-14; this revised the 2026-08-13 "auto-import everything" approach once its cost was measured,
then split the long single-CLAUDE.md rationale into the per-topic docs below):

- **`~/.claude/reference/llm-overused-phrases.md`** — read for the ~15 alternatives / the rationale on
  a specific offender. (The distilled list is inline in "Words and phrases you overuse".)
- **`~/.claude/reference/python-coding-standard.md`** — read **before** writing/reviewing Python, for
  the ruff tiers and the naming/idiom judgment calls ruff can't check (incl. the Google/napoleon
  docstring standard).
- **`~/.claude/reference/sphinx-book-conventions.md`** — read when setting up or debugging a Sphinx
  book's autodoc rendering / lualatex PDF (autodoc typehints, `api.rst` coverage, missing-glyph font
  fallbacks, reading real build warnings).
- **`~/.claude/reference/code-style-conventions.md`** — read when reflowing comments, changing a
  line-length limit, handling an externally-defined name, naming a loop/iteration variable,
  extracting a function, or choosing total dispatch (the "use your discretion" 80-column worked
  example lives here too).
- **`~/.claude/reference/communication-conventions.md`** — read when writing a status update, asking a
  decision question, creating a task with open questions, or shaping a README.
- **`~/.claude/reference/git-workflow-conventions.md`** — read when staging finished work, or (if I've
  authorized committing) for the quick-save/squash rhythm and the pre-squash harvest.
- **`~/.claude/reference/task-doc-conventions.md`** — read when creating/archiving a task, scaffolding
  step-tasks, or saving/promoting an ad-hoc script (also holds the open-issues rule).
- **`~/.claude/reference/reference-doc-conventions.md`** — read when deciding task-vs-reference,
  authoring a reference doc/set, documenting a pinned dependency, or running the session-end sweep.
- **`~/.claude/reference/versioning-and-changelogs.md`** — read when comparing/listing versions,
  bumping a version, or maintaining a `CHANGELOG.md`.
- **`~/.claude/reference/codegen-conventions.md`** — read **before** writing a code generator, or
  when tempted to edit a generated file.
- **`~/.claude/reference/porting-with-an-output-oracle.md`** — read **before** verifying a port
  (new front-end, build system, language translation, modernization) by comparing outputs: when
  byte identity is the right bar vs equivalence, forcing the output format, one process per case.
- **`~/.claude/reference/cpp-python-bindings.md`** — read **before** binding a C++ library to Python
  (nanobind/pybind11): `nm`-check before binding, trampolines, arity dispatch, overload order.
- **`~/.claude/reference/cpp-build-modernization.md`** — read **before** porting a C++ build to Meson,
  pinning/bumping `-std`, migrating to `enum class`, or adding a tree-wide reformat commit
  (`.git-blame-ignore-revs`); `cpp-ownership-migration.md` is the ownership half.
- **`~/.claude/reference/diversion-stack-and-scope.md`** — read when a task spawns a prerequisite, a
  diversion is deepening, or you need the stack's full mechanics.
- **`~/.claude/reference/nested-run-and-gates.md`** — read **before** building/running a project's
  containers nested or calling a change verified; **`~/.claude/reference/nested-podman-design.md`** for
  the flag design/lore and **`~/.claude/reference/minimal-nested-images.md`** for the RAM-store /
  lean-image scope.
- **`~/.claude/reference/sandbox-capability-map.md`** — read **before** concluding "the sandbox can't
  do X," or when you need to know what tools/services/languages the image ships.
- **`~/.claude/reference/shell-and-gate-scripts.md`** — read when writing/reviewing a gate or format
  script, editing a committed script, doing a bulk find-and-fix across many files, or a Bash tool
  command fails with zsh-flavoured errors.
- **`~/.claude/reference/print-debugging.md`** — read **before** hand-instrumenting a bug with
  print/trace statements in an unfamiliar language (also holds the instrumentation-driven method).
- **`~/.claude/reference/claude-config-layering.md`** — read when reasoning about or changing how
  `~/.claude`, auth/login, sessions, or the mounts are assembled.
- **`~/.claude/reference/bluf-bottom-line-up-front.md`** — read when writing a task's `## BLUF`.

All these paths, and the two `@`-imports below, resolve in the container, where the Makefile mounts
`tasks/reference/` to `~/.claude/reference/`.

`@~/.claude/stack.md` imports the **global diversion stack** (see "The diversion trail" above),
so its current contents are in context at the start of every session — you never have to
remember to open it, and it cannot silently drift out of sync with what we're actually doing.
This is the enforcement the stack always lacked: the trail's rule is that YOU keep it current
unprompted, and auto-importing it makes "is the stack stale?" a question you can always answer,
because the stack is right there. It resolves through the `~/.claude` mount
(`CLAUDE_CONFIG_MOUNT`); the Makefile seeds a starter `stack.md` if the host has none, so the
import never dangles. Keep it SMALL — a breadcrumb trail that points at task docs, never a task
log (a big `stack.md` bloats every session's context).

Finally, `@~/.claude/ai-coding-conventions.personal.md` imports the **personal overlay** — the maintainer-specific
layer (identity, project→URL mapping, project template, standing authorizations). The tracked
default is blank; `make shell` mounts the host's `~/.ai-coding-conventions.personal.md` over it, so the
conventions above stay portable while personal specifics layer in per-user. See
`ai-coding-conventions.personal.example.md` and `FORKING.md`.

@~/.claude/stack.md
@~/.claude/ai-coding-conventions.personal.md
