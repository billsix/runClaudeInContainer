# Task documents & ad-hoc scripts — full conventions, lifecycle, and rationale

**Reference document** — the full detail behind the terse "Task documents", "Priority &
difficulty", "Blocked tasks", "Step tasks", and "Ad-hoc scripts" rules in the cross-project
`CLAUDE.md`. Read on demand when creating/archiving a task, scaffolding a step-task tree, or
saving/promoting an ad-hoc script. (Relocated verbatim from `CLAUDE.md`, 2026-09-14.)
Companion: `~/.claude/reference/reference-doc-conventions.md` (reference docs, harvesting, the
session-end sweep) and `~/.claude/reference/git-workflow-conventions.md` (the commit
boundaries the archive lifecycle rides on).

## Task documents

For non-trivial work — multi-step features, refactors, investigations, anything worth resuming in a later session — keep a spec/notes doc at `tasks/<short-kebab-slug>.md` in the **repo root** of whichever project is currently mounted. One file per task. Update it as work progresses (status, decisions, open questions).

**Write every task doc to be executed COLD.** Assume whoever picks it up — a fresh LLM session, you months later, a colleague — has **none** of the conversation that produced it. Everything a fresh reader needs is in the doc, or in files it points to: what to read first, the current state of the relevant code, links to related/prior tasks and reference docs, and any decisions already made **with their rationale** (not just the conclusion). Never lean on session memory or "as we discussed." This is the **standing default, so a task never *announces* that it's self-contained — it just is.** It's the task-level form of the same "assume the reader lacks context" discipline the response rules already demand (gloss every label; cite the file path). Concretely, a non-trivial task **leads with two short standard sections** (scaled to the task — a tiny task may need neither):

- **`## BLUF`** (Bottom Line Up Front) — 1–4 sentences: what this task *is* and what "done" means, right under the header. From US-Army writing (AR 25-50): the main point / conclusion / required action goes **first**, so a reader grasps the essence immediately without wading through detail. Full write-up: `~/.claude/reference/bluf-bottom-line-up-front.md`.
- **`## Context`** — the cold-start orientation: what to **read first** (files, related/prior tasks, reference docs), the **current state** of the relevant code, and **decisions already made with their rationale** — enough that a fresh reader can act without the originating conversation.

### Priority & difficulty (rough triage for "what to work on next")

Every task doc carries two 1–10 ratings in its header, directly under `**Status:**`:

- **`**Priority:** N`** — `1` = highest (do first), `10` = least. Judge by value × urgency × whether finishing it unblocks other work. Parked / not-approved / someday tasks get a *high* number (low priority) — as do **blocked** tasks (see "Blocked tasks" below), which aren't actionable until an external condition clears.
- **`**Difficulty:** N`** — `1` = easiest, `10` = hardest. Effort + design risk + blast radius.

**The scale is geometric — each step is ~1.5× the previous** (so a 10 is ~1.5⁹ ≈ 38× a 1). The high end deliberately compresses many hard/low-priority items; this is for *rough ranking to decide what's next*, not for estimation. Rough anchors:

- **Difficulty:** 1 trivial (minutes, mechanical) · 3 small (≤ an hour, localized) · 5 medium (a session, some design) · 7 large (multi-session, cross-cutting) · 9 very large (major subsystem / real risk) · 10 project-scale.
- **Priority:** 1–2 do-next / blocking / high value · 3–4 important soon · 5–6 normal backlog · 7–8 nice-to-have · 9–10 someday / parked.

**Use them to choose next work:** scan a project's `tasks/` for the **lowest priority-number combined with the lowest difficulty-number** — high-value easy wins first. Assign both at creation (via `/new-task`) and revise as scope becomes clear.

### Blocked tasks — deferred until an external condition changes

Some tasks can't start until something **outside our control** changes — an upstream tool ships a feature, a dependency cuts a release, an external standard stabilizes, or *I* run a hands-on verification only I can do (hardware, a display). Mark these `**Status:** blocked` and give them two fields directly under the header, alongside Priority/Difficulty:

- **`**Blocked on:**`** — the external condition, in one line ("Zed dev-container support loses its 'still in development' caveat").
- **`**Recheck:**`** — a **cheap, runnable** check that answers *"has it cleared yet?"* without re-deriving anything: a URL to `WebFetch` **plus the exact signal to look for**, a version/release to compare (with a version-aware sort — see "Version numbers don't sort like strings"), or a command to run. For a human-gated block, name the one manual step I have to run. State what a *cleared* result looks like. (This is the task-doc twin of the reference-doc "re-sync check" — a pinned condition plus a one-line way to detect drift.)

**Blocked ≠ parked:** *parked* is a subjective "not approved / not now" (just a high Priority number); *blocked* is a concrete, **testable** gate. Both get a **high priority-number** (neither is next-work) and both are **excluded from the easy-wins ranking** — but a blocked task carries a check anyone can run.

- **`/recheck-blocked`** runs the `Recheck:` of every blocked task and reports which gates cleared, offering to flip `blocked` → actionable and re-rate Priority. Re-checking is **on demand — never automatic**: don't fire network checks on your own at session start/end (that manufactures work and is slow); just surface that blocked tasks exist and that the command can test them.
- When a gate clears, drop the `Blocked on:`/`Recheck:` fields, set a real Status/Priority, and proceed.

### Step tasks — an umbrella task with sequenced children

For a **multi-step initiative** too big for one task doc — a refactor that runs in phases, a migration with natural commit boundaries, anything where step N can't sensibly start until step N-1 lands — split it into an **umbrella task** plus one **step-task per step**. This keeps each step executable and cold-readable on its own while the umbrella holds the shared *why*.

- **The umbrella** (`tasks/<initiative>.md`) holds the **vision, rationale, the ordered list of steps (it IS the index), cross-cutting risks, and the decisions that span steps** — but *not* each step's detail. It links down to the step-tasks; it does not duplicate them. Give it the initiative's overall Priority/Difficulty.
- **Each step-task** (`tasks/<initiative>-step-N-<slug>.md`, so they sort together) is a normal task doc — BLUF, Context, verification, its own Priority/Difficulty — carrying three header links right under the ratings: **`**Part of:**`** (the umbrella), **`**Depends on:**`** (the previous step, if any), and **`**Next:**`** (the following step). A fresh reader of any one step can find the whole chain.
- **Express step ordering with Priority + a "Depends on" note, NOT with `blocked`.** `blocked` is reserved for gates *outside our control* (see "Blocked tasks"); a step waiting only on an earlier step is entirely within our control — you just do them in order. So the currently-actionable step gets a **low** priority-number (it's next-work), and later steps get **higher** priority-numbers (not next-work yet) with a plain "do not start until step N-1 has landed" line. This keeps the easy-wins scan honest: only the ready step surfaces as next.
- **Track step status in two places, deliberately:** each step-task's own `Status`, and a one-line-per-step checklist in the umbrella (the umbrella is where I look to see how far the initiative has gotten). For a per-item step (e.g. "do this to all 11 games"), a small status **table** inside the step-task is the right grain.
- **Lifecycle:** each step-task **archives on its own completion** (the normal unprompted-archive rule — harvest durable knowledge to a reference doc, fix inbound pointers, `git mv`, stage). The **umbrella archives when the last step is done**, and is the natural place to harvest the initiative's overall rationale into a `tasks/reference/` doc. The per-step commit/handoff boundaries are real — I'll often commit after each step.
- **Don't over-scaffold.** This is for genuinely multi-phase work. A two-step job is usually just one task with two phases in its body; reach for the umbrella+children shape when there are three-plus sizeable, sequential chunks, or when a step has its own commit boundary I'll want to stop at. When in doubt, one task with a phase list is the lighter default.

### Archiving a completed task

When a task is complete, **move** the file to `tasks/archive/<YYYY>/<MM>/<DD>/<slug>.md` (zero-padded, based on the archive date) rather than deleting it. The date-bucketed layout keeps any one directory from accumulating too many entries. The history is useful.

**Archiving is yours to do, proactively, at the moment of completion — no go/no-go question (Bill,
2026-08-31; timing corrected 2026-09-07).** The instant a task's done-state is met and its gates are
green, the archive is *owed*: harvest to reference docs, fix inbound pointers, `git mv` the task into
`tasks/archive/…`, and `git rm` any one-shot adhoc scripts. **Never ask whether to archive, and never
present a done task as an archive *candidate*** — that surprise-me-by-asking behavior is the failure
this rule exists to stop (origin: two verifiably-done gacalc tasks presented with a go/no-go question
— "I'm just surprised you didn't archive what you thought was done"). Ask only when the done-state
itself is genuinely ambiguous.

**BUT the archive is its own commit, AFTER the work commit — never bundled into the work's staged
handoff (Bill, 2026-09-07).** The maintainer's lifecycle is **three commits**: (1) task-add, ideally
standalone; (2) work + adhoc scripts, together; (3) archive-move + the one-shot adhoc `git rm`,
together, in a *separate* commit after the work commit — so `git log` shows "work + its scripts" and
"archive + script deletion" as two related, self-contained points. So **do NOT `git mv` the task or
`git rm` its scripts into the same staged set as the work.** Instead: stage the work and stop; once
its commit exists (by default *I* make it — see "Git: I commit, you don't"), **proactively** stage the
archive set (the `git mv`, the reference harvest, the one-shot `git rm`) as commit 3. At completion the
archive is therefore an **owed, tracked** action — record it in the task's `Status` or the stack —
executed the moment the work commit lands (same session if I commit then, next session otherwise); say
so plainly (*"done and staged; I'll archive it in its own commit once you've committed the work"*),
never as a question. **When I've authorized you to commit this session** (per-project, per-session —
the quick-save mode), you make the commits yourself: commit the work (+ adhoc scripts), then commit the
archive-move + one-shot `git rm` as a **separate** commit — the same two boundaries, never one combined
"work + archive" commit. "Pending review" applies to the *work*, not the lifecycle move.

Older flat archives (`tasks/archive/<slug>.md`) from before this convention are not migrated automatically; the `/archive-task` command will detect them on each run and offer to port them into the date hierarchy using the file's last-touched date from git history.

At the start of a session in a project, check `tasks/` (top-level, **not** `tasks/archive/`) for in-flight work and surface what's there so we can pick up where we left off — **list each with its Priority/Difficulty, sorted easy-wins first** (lowest priority-number, then lowest difficulty-number) so it's immediately clear what's worth doing next. **List any `blocked` tasks separately** — call them out as not-actionable (with their one-line `Blocked on:`) and keep them out of the easy-wins ranking, since their gate hasn't cleared; note that `/recheck-blocked` can test whether it has. Don't trawl `tasks/archive/` unless I ask about prior work.

Don't create a task file for one-off questions, trivial edits, or anything resolvable in a single response. Task files are for work that spans turns or sessions.

If `tasks/` doesn't exist in a repo yet, create it the first time it's needed. By default these docs are committable — only add `tasks/` to `.gitignore` if I explicitly ask. Give every convention directory an empty `.keep` when you create it (see "Ad-hoc scripts" for why).

**When a task you create (or substantially flesh out) has open questions, surface them to me at report time — don't bury them in the doc.** If the task's **Open questions** section is non-empty, repeat those questions as a **numbered list at the very end of the message** that tells me you made the task (this is the "Questions for me go inline AND in a closing list" rule, applied to task creation — I should see what you need from me in the message, not have to open the file to find it). Number them, name the positions, and include your recommendation per question. And per "Every question must be addressed before you implement anything": a question that blocks the work still blocks it even though the task is "made" — don't start implementing until I've addressed the numbered questions, and don't read a bare "go ahead" as answering them unless it actually resolves each one.

Helper commands: `/new-task <slug>` to scaffold, `/archive-task <slug>` to archive, `/recheck-blocked` to test whether any blocked task's external gate has cleared.

## Ad-hoc scripts — save the substantive ones under `tasks/adhoc/`

While doing a task I often write throwaway scripts — codemods, bulk edits, one-off verification harnesses, or a **one-time generative setup** (running a scaffolding tool, then transforming its output — e.g. `sphinx-quickstart` then editing the generated `conf.py`). **When such a script is substantive, save it under `tasks/adhoc/<task-slug>/<name>` in the repo and run it from there**, instead of executing it only from the ephemeral session scratchpad. The point is that you get a *committed record of the mechanical "how"* behind a large diff — and of *whether* a change was verified — not just the resulting diff.

**What to save (the threshold — do NOT clutter this with one-liners):**

- **Save:** scripts that **mutate repo files** (rename passes, codemods, generated transformations); non-trivial multi-step programs; task-specific **verification / proof harnesses** (cross-reference checkers, before/after AST diffs, differential state traces); and **one-time generative setup** (a scaffolding tool plus the edits that shape its output into what the project keeps).
- **Skip:** trivial shell pipelines, `grep`/`sed`/`awk` one-liners, `python -c` snippets, and interactive exploration (they belong in the terminal/scratchpad — saving them buries the meaningful scripts); **a script that merely reproduces a permanent file edit** (a `Dockerfile`/`Makefile`/config change — scripting it only duplicates what is already committed in the file, so edit the file directly); and **environment setup outside the project** (`dnf install`ing into the sandbox/container is not project work — its durable form is the project's own `Dockerfile`, or it's just sandbox state — so it is never an ad-hoc script).
- **The test when unsure:** *would the diff alone leave you wondering how I did this, or whether it was safe?* If yes → save it.

**Write them relative — to themselves or to the repo root — and NEVER to a container-absolute path.** A saved script is committed and re-run later, on another machine or a differently-launched sandbox, so it must not encode where this session happened to see the repo. A mount path like `/foo/opt/<project>` exists **only** because *this* `make shell` was launched with that `EXTRA_DIRS`; a different launch, a different user, or a plain host checkout puts the same repo somewhere else and the script is dead on arrival. Same for the ephemeral session scratchpad. Derive the repo from the script's own location — a script at `tasks/adhoc/<slug>/<name>` sits three directories below the root:

```python
REPO = pathlib.Path(__file__).resolve().parents[3]   # tasks/adhoc/<slug>/ -> repo root
```

```sh
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"   # or: git rev-parse --show-toplevel
```

— then address everything from there (`REPO / "src" / …`). **This covers the paths the script READS and WRITES, not just where it starts:** an output file, a baseline copy, a log, a temp directory. Each belongs under the repo, or under a path passed in as an argument — never a hardcoded mount path. A script that only runs under one sandbox launch is not a re-runnable record, it is a dead artifact with comments.

**Comment them for a reader with basic command-line knowledge** — explain the tool's flags and any non-obvious step, but don't explain piping, environment variables, or redirection (assume those are known). A saved scaffold is meant to *teach* the how, so a newcomer can follow it and learn from it, not just re-run it.

**Namespacing:** `tasks/adhoc/<task-slug>/` — one subdir per task, matching the task doc's slug, so archiving can remove it in one step. For scripted work with no tracked task, use a short descriptive subdir name.

**Git lifecycle — committed during the task; at archive, PROMOTE or remove.** Stage ad-hoc scripts with the task's work (this is the one place a committed-then-deleted artifact is intended — it's the audit trail). **When an adhoc script needs to change mid-task, REVERT its inputs to the pre-script state, update the script, and re-run the FINAL script once — do NOT patch the script and re-apply it on top of already-transformed files. The saved script must reproduce its own diff *run once on the original input*; a script that only works applied on top of an earlier version is a broken audit trail. Reverting is cheap (`git checkout <paths>` / `git stash`, or ask me to undo an out-of-container commit), and you should verify the final script reproduces the committed result. **Scope the revert to the PROCESSED FILES, by path — `git checkout <pre-script-SHA> -- <the files the script transforms>`, NEVER a whole-tree `git checkout <SHA>` (that would revert away the script itself and any other in-flight work). Then run the final script once and confirm `git diff` on those files is empty: an empty diff IS the proof it reproduces the committed result. No restore is needed when the diff is empty (the tree already matches); otherwise investigate before squashing.** This extra revert step is worth it — I'd rather that than a squashed history whose codemod can't reproduce the change. (The squash then safely discards the intermediate iterations; keep any lesson from them in the task doc.)**

**Make a file-mutating codemod idempotent, and PROVE it by running it twice — the second run must report zero changes.** A transform that re-matches its own output silently corrupts on any re-run, and that is exactly the failure the revert-and-rerun rule above depends on *not* happening. Worked example (mvp gacalc-0.0.16 adoption, 2026-08-13): a codemod split `from …mathutils import Vector3, helper` into a `from gacalc.g3 import Vector` line plus the leftover helper import — but it fired whenever the mathutils line matched, not only when `Vector3` was still on it, so a second run re-fired and inserted a **duplicate** `from gacalc.g3 import Vector` every time (58 files, then 13 more on the next run). Guarding it to act only when the suffixed name is actually present made re-runs a clean no-op. The double-run check is the cheapest proof the saved script reproduces its own diff, and it's the "formatter idempotent (`--check` reports no changes)" discipline applied to your own codemods — cheap to run, and it catches the whole class of self-re-matching bugs before they reach my tree. At archive time, `/archive-task` triages each script:

- **One-shot** — a codemod / bulk edit whose job is done and that you would not run again: **remove from version control** (`git rm -r`). The history survives in the work commits, so nothing is lost — `git log` / `git show` still recover it. (A task archived before its scripts were ever committed just deletes them — an accepted edge case, not a bug.) **Timing: the one-shot's `git rm` belongs IN the archive commit (commit 3), paired with the task's `git mv` — after the work commit that carried the script.** When you stage but I commit later, a one-shot must first land in the work commit (that IS the audit trail); staging an *add* and a *remove* of the same file before any commit nets to nothing and the script never reaches history. So the removal is an **owed action performed with the archive**, after the work commit — never bundled into the work's staged set (see the three-commit lifecycle under "When a task is complete" above). Record the owed deletion (in the archived task doc or the stack). (mvp, 2026-09-06: two one-shot codemods were archived with their tasks but `git rm`'d only after the work commit that carried them landed — correct, but I had not *tracked* the owed deletion, so it waited until the maintainer asked. Track it.)
- **Reusable** — a checker / linter / report / proof-harness you *would* run again against future changes (the test is exactly that: *would I re-run this?*): **promote it** instead of deleting.

**Promotion — a reusable script becomes a first-class tool.** When a script has ongoing value:

- **Move it to the repo's tools location** — `tools/` where that exists (create one if not, or **fold it into an existing tool** rather than inventing a new directory) — with a **light cleanup**: make it repo-relative and self-contained, and give it a docstring saying *when to run it*. It is now maintained code, not a scratch artifact.
- **Update the relevant reference doc** to note it (what it checks, when to run it). This is the runnable sibling of the "harvest durable knowledge into reference docs" step — the reference doc often gets both the rationale and a pointer to the tool.
- **Investigate whether it should run as a make target.** Read the repo's `Makefile`, `Dockerfile`, and entrypoint scripts to see whether it belongs in an existing gate (`format` / `check-*` / `test`), wants its own `## `-documented target, must run **in-container after setup** (some checks can only run once generated/populated files exist — so they live in `entrypoint.sh`, not a host-side target), and/or needs a Dockerfile dependency. Then **propose** the specific wiring — shaped to the gate conventions (a multi-step check script must propagate every step's failure; the real gate runs in the container). **Do not auto-wire it**; changing the build/gate is the user's to approve. "Manual tool, documented, not gated" is a valid outcome — not everything reusable should be a pass/fail gate (an informational audit like a dead-marker report shouldn't fail the build).
- **Default to delete; promote only when the ongoing-use case is clear, and ASK when borderline.** A wrongly-promoted script rots in `tools/`; a wrongly-deleted one is still in git history.

The session **scratchpad still handles true ephemera** (baseline copies, intermediate data, throwaway venvs); only substantive scripts move into `tasks/adhoc/`. And not every change is a script — many edits go through the editor directly and are captured by the diff and the task doc, so `tasks/adhoc/` records only the *scripted* subset, not "everything I did". Create `tasks/adhoc/` the first time it's needed; committable by default (that's the point), gitignore only if I ask. **A directory the conventions promise must survive being empty: git tracks files, not
directories, so put an empty `.keep` file in `tasks/adhoc/` (and in `tasks/reference/`,
`tasks/archive/`, `tools/` — any directory these conventions tell a reader to look in) the moment
you create it, and never `git rm` the `.keep`.** Otherwise the first cleanup that removes the last
file removes the directory from the repo, and the next reader finds the conventions pointing at a
path that isn't there (2026-09-06, mvp: archiving the last one-shot codemods `git rm`'d
`tasks/adhoc/` itself; the maintainer restored it with a `.keep`).

## Open-issues sections in project docs

When a project's `CLAUDE.md` or `README` keeps an "open issues" / "known issues" list, it should contain only **genuinely open** items. When an issue is resolved, **remove it** — don't leave it struck-through or annotated "resolved/fixed". A new developer reading an open-issues list shouldn't have to wade through things that are no longer issues; the resolution history already lives in git and in archived task docs, not in the live list. (This applies specifically to *open-issues* lists; a curated changelog or "resolved" section that exists on purpose is fine.)
