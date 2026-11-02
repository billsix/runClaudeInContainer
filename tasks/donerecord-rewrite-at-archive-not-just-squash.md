# Make the done-record rewrite a step of ARCHIVING, not just pre-squash

**Status:** DONE 2026-11-02 (William Emerison Six <billsix@gmail.com>) — Option 2 implemented across both
sandbox repos; staged, not committed. Archive after the maintainer's work commit.
**Priority:** 3 **Difficulty:** 3

## BLUF

The "normalize a task doc into a lean done-record" rewrite is currently defined **only as a pre-squash
step**. Squashing is conditional (only when committing is authorized for a long unattended batch), but
**archiving always happens** — including in the stage-only default and ad-hoc-commit flows. So a task
archived without a squash keeps its forward-looking BLUF/Context/Plan/Open-questions scaffolding and
stale `Status:` line. Fix: make the done-record rewrite an explicit step of **completing/archiving** a
task, decoupled from squash — done **before** the `git mv`, so a scaffolded doc can never reach the
archive. Applies to both sandbox repos (github.com/billsix/runClaudeInContainer and
github.com/billsix/runCrushInContainer).

## Context — the root cause (diagnosed 2026-11-02)

- The archive lifecycle (`tasks/reference/task-doc-conventions.md` §"Archiving a completed task"; the
  `## Task documents` "Archiving:" paragraph in the shared `CLAUDE.md`) mandates only: harvest durable
  knowledge to a *reference* doc, fix inbound pointers, `git mv`, `git rm` one-shot scripts. It does
  **not** mandate rewriting the task doc itself.
- The only place the task-doc rewrite is required is the **squash** path
  (`git-workflow-conventions.md` §"Quick-save commits, then squash"; the shared `CLAUDE.md` squash
  section; authorized-batch step 3, literally named "pre-squash rewrite").
- `git-workflow-conventions.md:36` already generalizes it ("whenever you harvest before a squash, **and
  whenever you finalize or substantially update a task or reference doc**, rewrite it...") — but that
  sentence is buried in a read-on-demand doc, framed under the squash heading, and absent from the
  archive step-list, so it does not fire.
- **Incident:** the four 2026-11-02 hanoi tasks (the three no-network gates + the egui disc-picker) were
  archived with full scaffolding and stale "staged, not committed" status; they had to be rewritten by
  hand afterward. That manual catch is the failure this change removes.

### Two secondary findings (this change must account for them)

1. **The two `CLAUDE.md` copies drifted.** runCrush's `CLAUDE.md` inlines the general "whenever you
   finalize... rewrite it" rule in its always-loaded layer; runClaude's relocated that detail to the
   on-demand `git-workflow-conventions.md` and kept only the squash-framed "normalize into ONE
   consistent tense/voice." Keep the two copies consistent after this change.
2. **runCrush carries no workflow reference docs** (no `git-workflow-`, `task-doc-`, `reference-doc-`,
   `communication-conventions.md`); it inlines those rules in its `CLAUDE.md`. So reference-doc edits
   land in runClaude only; the runCrush equivalent is its `CLAUDE.md` prose. Don't fix one and forget
   the other.

## Options considered

1. **Codify move→commit→rewrite→commit (a 4th archive commit).** Lifecycle: (1) task-add, (2) work, (3)
   `git mv`, (4) rewrite-in-archive. *Pros:* matches what we did 2026-11-02; the move stays a pure
   rename, the rewrite is an isolated content diff. *Cons:* the doc enters the archive still scaffolded
   and is cleaned *after* — if step 4 is skipped (session ends, no prompt) the archived doc stays messy,
   i.e. the same failure relocated to the last step; adds a 4th commit.
2. **(CHOSEN) Rewrite as the completion step, BEFORE the `git mv`, decoupled from squash.** Lifecycle
   stays three commits: (1) task-add, (2) work **+ the done-record rewrite of the task doc** (both in
   `tasks/`), (3) `git mv` (a pure rename of an already-clean doc). *Pros:* the clean done-record is a
   **precondition** of the `git mv`, so it is structurally unmissable; no extra commit; the move stays a
   rename git detects; unifies with the existing "a finished unit's doc deltas ship with its staging"
   rule (the task doc IS that unit's doc delta). *Cons:* the rewrite diff rides the work commit rather
   than being fully isolated (minor).
3. **Wording only.** Promote the existing generalization out of the on-demand doc and the squash
   paragraph into the always-loaded `CLAUDE.md` and the archive step-list. *Pros:* smallest edit.
   *Cons:* still a "remember to" rule, not a structural precondition — weaker than 1/2.

## Decision (William Emerison Six <billsix@gmail.com>, 2026-11-02)

**Option 2**, folding in Option 3's wording cleanup: reframe the done-record rewrite as a **completion**
action (one rule) that fires at archive time, with the squash merely reusing the same rewrite when it
also happens. The clean done-record becomes a precondition of the `git mv`.

## Done — what was changed (2026-11-02)

Option 2 applied: the done-record rewrite is now a completion step of archiving (before the `git mv`,
shipped in the work commit), decoupled from squash, with the wording promoted into the always-loaded
layer. Files edited (staged, not committed):

- **runClaude `CLAUDE.md`** (`entrypoint/dotfiles/.claude/CLAUDE.md`): the `## Task documents`
  "Archiving:" paragraph gained the named "rewrite the task doc into a lean done-record" step and a
  "NOT contingent on a squash" clause, and the three-commit lifecycle now lists the rewrite in commit 2;
  the `## Quick-save … squash` section reframes "normalize…" as the archive-time done-record rewrite the
  squash merely reuses; authorized-batch step 3 renamed "pre-squash rewrite" → "done-record rewrite".
- **runCrush `CLAUDE.md`** (`client/entrypoint/dotfiles/.config/crush/CLAUDE.md`): the same four changes
  mirrored into its inline sections (it carries no separate workflow reference docs), keeping the two
  copies consistent.
- **`tasks/reference/task-doc-conventions.md`** (runClaude): added "The done-record rewrite (do it at
  archive, not only before a squash)" and folded the step into the §Archiving "owed" list.
- **`tasks/reference/git-workflow-conventions.md`** (runClaude): reframed the §squash rewrite sentence
  and authorized-batch step so the rewrite is completion-triggered (squash is one occasion).
- **`tasks/reference/reference-doc-conventions.md`** (runClaude): the archive-harvest paragraph now also
  says to rewrite the task into a done-record.
- **The `/archive-task` command, both repos** (`…/commands/archive-task.md`): step 8 was "set Status,
  **leave the rest alone**" — the very behavior that carried scaffolding into the archive. Rewrote it to
  perform the done-record rewrite (normalize to one past-tense voice; fold the forward-looking
  scaffolding; set `Status: complete` + `Completed:`; symbol refs over `file:line`). `/new-task` was left
  unchanged — it scaffolds a *new* task, where the forward-looking BLUF/Context/Plan/Open-questions
  structure is correct; the done-record rewrite is an archive-time step only.

Verified the term "pre-squash rewrite" no longer appears anywhere (renamed to "done-record rewrite"),
while "pre-squash harvest" (the changelog `[Unreleased]` reconciliation, legitimately pre-squash) was
left intact. The two `CLAUDE.md` copies were checked against each other for consistency.

**Follow-up sweep (2026-11-02):** read both repos end-to-end for anything else touching this flow. One
miss found and fixed — the **"Reference documents" section of both `CLAUDE.md` copies** said "slim the
task to a lean work record" / "archive the thin work record" without naming the done-record rewrite;
updated both to point at it (one past-tense voice, scaffolding dropped, regardless of squash). Also
confirmed the `/archive-task` fix (above) and that `/new-task`, the READMEs, the personal-overlay
example, and the stack commands need no change; the remaining "pre-squash harvest" hits are the
changelog reconciliation (correctly left); archived task docs (2026/09/03, 09/07, 09/18) are historical
records and were not touched.

## Related

- `tasks/reference/task-doc-conventions.md` — the archive lifecycle this amends.
- `tasks/reference/git-workflow-conventions.md` — the squash/harvest rules this decouples from.
- `tasks/reference/reference-doc-conventions.md` — the durable-knowledge harvest that runs alongside.
- The incident that motivated it: the 2026-11-02 hanoi archives (github.com/billsix/towersofhanoi
  `tasks/archive/2026/11/02/`).
