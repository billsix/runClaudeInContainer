# Reference documents — full conventions, layered LoD, cold authoring, and the session-end sweep

**Reference document** — the full detail behind the terse "Reference documents", "Layered
reference documents", "Authoring a reference set for a codebase you don't know", "Reference
docs for a versioned dependency", and "Ending a session" rules in the cross-project
`CLAUDE.md`. Read on demand when deciding task-vs-reference, authoring or updating a reference
doc/set, documenting a pinned dependency, or running the end-of-session sweep. (Relocated
verbatim from `CLAUDE.md`, 2026-09-14.) Companion:
`~/.claude/reference/task-doc-conventions.md`.

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

**When you archive a survey / investigation / research task, create the follow-on task your
recommendation implies — do NOT leave the recommendation stranded in the archived doc.** A survey that
concludes "embed Lua," an investigation that concludes "use a texture array," a gap analysis that says
"port feature X" — each has a *next action*. The moment you write the lean archived record + the
reference doc, also scaffold a `tasks/<slug>.md` for that action: `proposed — needs go-ahead` if it's
just awaiting my nod, or `blocked` on the single decision it hinges on (with `Blocked on:`/`Recheck:`),
cross-linked both ways to the reference doc. The reference doc holds the *why*; the new task carries the
*do*. This is not optional — an archived recommendation with no task is exactly how a good conclusion
gets lost. (Corollary: a "don't do X" recommendation needs no task; and findings that belong in an
existing task should be folded there rather than spawning a duplicate.)

- Create `tasks/reference/` the first time it's needed (with an empty `.keep` — see "Ad-hoc scripts"). Committable by default, like tasks.
- **Session start & orientation:** the in-flight `tasks/` scan stays **top-level only** —
  `tasks/reference/` and `tasks/archive/` are never pending work. But treat `tasks/reference/`
  like a table of contents I *know exists*: note what entries are there (listing their titles
  is cheap), and **read the relevant one when getting oriented on a project or before touching a
  subsystem it covers** — exactly as I'd read the pertinent part of `CLAUDE.md`. Don't bulk-read
  every reference doc each session (they can be large); pull the one that matches the work at
  hand.
- **This structure is standard across every one of my projects** — use it (and create
  `tasks/reference/` as needed) in any repo, even ones that don't obviously need it yet.

### Layered reference documents — levels of detail (LoD)

A reference doc need not be one flat file. For a big topic — or a *set* of
related topics — write it at **layered levels of detail**, so a reader enters at
the altitude they need:

- **L0 — capsule** (≤1 paragraph): the whole topic in a breath. Every L0 of a
  set aggregates into one top **map doc** (`tasks/reference/<set>/README.md`),
  which doubles as the set's table of contents and status board.
- **L1 — orientation** (~1 page, NO code): the mental model. Written only when
  it earns its place (below).
- **L2 — mechanism** (the anchored core): the full algorithm / data flow.
- **L3 — the source itself**; cite it by **stable named anchor** (a symbol name,
  or a `doc-region`/`literalinclude` marker), **not a line number** — line
  numbers rot (a run once found a function that had moved 1065 -> 2251).

Naming: L2 = `<topic>.md`, L1 = `<topic>-overview.md`, L0 = a row in the set's
`README.md` map. Each doc links UP to its capsule and DOWN to its detail.

Rules (learned building a 23-topic set — imps mario64, 2026-09):

1. **Generate deepest-first, then compress upward**, each level ~half the lines
   of the one below — a size budget, not delete-half; write each level fresh at
   its altitude (an L0 is a re-conception, not a shrunken L2).
2. **Write L1 only when the mental model is non-obvious AND self-contained AND
   not another topic's job.** Levels are horizontal as well as vertical: if the
   idea belongs to another topic, cross-link to that owner, don't duplicate it.
3. **Compare to a baseline the reader knows** (a course, a prior system) — that
   framing forces the right altitude and turns a code tour into teaching text.
4. **The set is grown top-down too:** writing an L0 map (or a book on top of the
   set) surfaces gaps that spawn new topics and deeper levels.
5. **A "what's absent" capsule** (with the check that proves it) is durable
   negative knowledge — give it a map row so nobody re-searches for it.

Not every topic needs every level; small ones fuse L0+L2. Scaffold a layered set
with `/new-reference-set`.

Helper commands: `/new-reference <slug>` (single doc) and
`/new-reference-set <set> [topic]` (a layered set) to scaffold.

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
  them in one known place. (I filed them under `docs/reference/` first here and the user moved me
  back; a repo having a `docs/` dir is not a reason to diverge.)

### Reference docs for a versioned dependency — pin, banner, re-sync (Bill, 2026-07-31)

When a reference set describes a **dependency the project pins by submodule/SHA** (a vendored engine,
a git submodule), the docs rot the moment the pin moves. Hard-won documenting libultraship, which
three sibling ports pin at three different commits (Ghostship `1.3.1-399`, Shipwright `1.3.1-463`,
upstream main `1.3.1-472`):

- **Pin the docs to the exact commit the consumer builds — not latest upstream — and banner it in
  every doc** (record the SHA + `git describe`), so a future session can detect drift. If you cloned
  the dependency separately, reset that clone to the submodule's SHA before studying it (fetch the
  object first — a `reset --hard` to an un-fetched SHA silently lands somewhere else).
- **Give a one-line re-sync check** ("compare `git -C <consumer>/<dep> rev-parse HEAD` to the banner
  SHA; if they differ, reset the doc checkout and re-verify"). Without it, nobody knows the docs rotted.
- **A version bump can be a *structural refactor*, not line drift — re-verify, don't assume.** Between
  LUS `399` and `472`, `Context` went singleton (`GetInstance()` + `Init*` methods) → Component tree
  (`CreateDefaultInstance`, `GetChildren().GetFirst<T>()`), files moved (`ship/Context.cpp` →
  `ship/core/Context.cpp`), and whole subsystems appeared (events bus, scripting, keystore, tests). A
  "re-anchor the line numbers" pass would have been wrong on nearly every page.
- **Re-study method that worked: hand each reader the OLD-version doc as a baseline and demand
  deltas** — each subagent returns STILL-TRUE (corrected anchors) / CHANGED (old claim → new fact) /
  NEW-ABSENT. Faster and more accurate than re-mapping from scratch, and it pinpoints exactly what moved.
- **Name the doc by what's actually present at the pinned version.** At `399` there was no event bus
  or scripting, so `config-events-scripting.md` became `config-cvars-logging.md`. Don't carry a
  name/scope across a version that no longer has those parts.
- **When a *consumer's* doc cites the dependency's internals, point to the dependency's own pinned
  docs — never embed drifting line numbers.** Ghostship's interpolation doc had cited LUS
  `interpreter.cpp` line numbers from the wrong (newer) checkout — silently wrong for the version
  Ghostship builds. Keep only the consumer's own `file:line` inline; banner which dependency commit
  any borrowed anchor came from.

**Sharpening the verify rule: parallel readers confidently contradict each other — resolve it
yourself.** One LUS reader reported `OtrSignatureCheck` exists nowhere (grep-negative); another placed
it exactly (`ResourceManager.cpp`). I grepped — it exists. Treat two readers disagreeing as a flag to
check yourself, and remember **a subagent's "grep found nothing" is not proof of absence** (wrong
scope, wrong path, a typo'd pattern). This is why the pass pays for itself: it caught a fictional
`AudioDmaRegistry`, non-existent bridge statics, and a "`ThreadPool` component" that was really a
plain member — before any reached a doc.

### Ending a session — sweep the always-read docs (Bill, 2026-07-21)

**When I tell you I'm ending a session** (wrapping up, signing off, "done for the day", "that's
it for now", etc.), before we stop do a **documentation-reconciliation pass** so the always-read
docs don't drift from what the session actually changed.

**This sweep is a VERIFICATION NET, not the primary mechanism (Bill, 2026-08-31):** per "Git: I
commit, you don't — but you DO stage", each finished unit already ships its own doc deltas at
staging time, so the sweep should expect to find **nothing** from properly finished units. What
it still exists to catch: decisions made only in conversation that never became a staged unit,
cross-repo drift, misplaced detail, and units redefined mid-session. Finding a finished unit's
doc updates here means the staging-time rule was missed — do the update, and tighten up.

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
5. **Run each touched project's format + type-check gate, and fix what it reports (Bill, 2026-10-01).**
   Run the gate **CI runs** — `.github/workflows/*` is a thin wrapper over `make <target>`, typically
   **`make format`** / **`make type-check`** / **`make lint`**. I commit **and push** at session end,
   so a green local gate is what keeps CI green (CI was failing more often than it should because this
   step was skipped). **Critical: a project's `make test` is usually NOT the type-check/lint gate** —
   e.g. gacalc's `make test` is pytest-only while `ruff` + `ty` run under `make format`, and
   type/lint errors slip past the tests **silently**. So run the actual format/type-check/lint gate,
   not just the tests, and run the **same `make` targets the workflows invoke** so local == CI. Gate
   runs that auto-fix (`ruff --fix`/format) **mutate files** — those fixes get staged in step 6. If a
   gate genuinely can't run here (no nested podman, a display/FUSE need only I can satisfy), **say so
   explicitly** and name which gate went unrun rather than skipping silently.
6. **Reconcile any touched repo's `CHANGELOG.md`** — `[Unreleased]` against everything since the last
   tag (see "The changelog") — then **stage everything the session touched** (`git add` by path, per "Git: I commit, you don't —
   but you DO stage"), including the doc updates from this sweep **and any gate auto-fixes from step 5**,
   so the session ends with the work handed off rather than sitting loose in the working tree.
7. **Blocked-task reminder.** If any touched project has `blocked` tasks (per "Blocked tasks"),
   list them one line each with their `Blocked on:`, and remind me `/recheck-blocked` can test
   whether their gate cleared. **Don't run the network re-checks yourself** — just surface that
   they're there.

Scope it to what the session actually touched — don't rewrite docs wholesale, and if nothing needs
updating, say so briefly rather than inventing changes. (This is the same doc-reconciliation
`/audit-repo` does, but scoped to the always-read docs and triggered automatically at session end.)
