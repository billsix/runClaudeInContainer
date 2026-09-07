# Archiving is its own commit AFTER the work commit — stop bundling the archive into the work handoff

**Status:** proposed — needs go-ahead (do NOT edit the conventions until approved)
**Priority:** 3
**Difficulty:** 3

## BLUF

The maintainer's task/adhoc lifecycle is a **three-commit sequence**, and the
agent has been collapsing two of them. The current `CLAUDE.md` prose (from
`7b33462 "archive at time of completion"`, 2026-08-30) tells the agent to archive
a finished task **"in the same handoff [the] code and doc deltas ship in"** and
that **"the `git mv` just joins the staged set"** — i.e. stage the archive move
*with the work*. That bundles the archive into the **work** commit, so
`git log` no longer shows "work + its scripts" and "archive + script deletion" as
two related, self-contained points. Fix: reword the archiving guidance in **both**
shared `CLAUDE.md` files so the archive (the `git mv`, the reference-doc harvest,
and the one-shot adhoc `git rm`) is staged as its **own** set **after the work
commit exists** — never bundled with the work — while **keeping** the "proactive,
unprompted, don't-make-me-ask" intent that `7b33462` was added to establish.
Reconcile the adhoc-`git rm`-timing note (added 2026-09-06) and the agent memory
`archive-on-completion-no-asking` to match. **This is a conventions/doc change
only — no code.**

## Context — read these first

- **The maintainer's workflow, in his words (2026-09-07):** *"tasks get added
  whenever, ideally in their own commit. work gets done, adhoc scripts are added
  as part of that. a commit is done. archiving happens in a next commit, and adhoc
  scripts are deleted in that commit. this way, when looking through git history,
  these things are all related."* And: *"you shouldn't archive the task before I
  make the commit myself that was part of the work … don't stage the archiving."*

  As three commits:
  1. **task-creation commit** — the task doc added, ideally standalone, whenever.
  2. **work commit** — the change done + the adhoc scripts added, together.
  3. **archive commit** — the `git mv` to `tasks/archive/…` **and** the one-shot
     adhoc `git rm` together, in a separate commit **after** the work commit.

  The adhoc script's whole visible lifetime runs from commit 2 (added with the
  work) to commit 3 (deleted with the archive); pairing the delete with the
  archive-move keeps history legible.

- **Who makes the commits (2026-09-07):** by default **the maintainer makes every
  commit** — the agent only ever *stages* (the standing "Git: I commit, you don't
  — but you DO stage" rule). The sole exception is when the maintainer has
  **explicitly authorized the agent to commit for that session**, granted
  **per-project and per-session** (it does not carry over) — normally when he's
  going to bed and the agent is running long unattended (the "Quick-save commits,
  then squash to a per-task history (only when I authorize committing)" mode). So
  the three commits above are the **maintainer's** by default; in the authorized
  session mode the **agent** makes them itself, still as the same three separate
  commits in order. The commit *boundaries* are identical either way — only *who*
  runs `git commit` differs.

- **What changed / the culprit:** `git -C <runClaudeInContainer> show 7b33462 --
  entrypoint/dotfiles/.claude/CLAUDE.md`. Before that commit the agent archived as
  a distinct step; `7b33462` added the "Archiving is yours to do … in the same
  handoff … the `git mv` just joins the staged set" paragraph, which conflated two
  separate goods: **(a)** archive proactively without asking (the real point —
  its origin was the maintainer being surprised the agent *didn't* archive and
  instead asked go/no-go), and **(b)** stage it *with the work*. (b) is the bug;
  (a) must be preserved.

- **Where the bad guidance lives (fix both):**
  - runClaudeInContainer `entrypoint/dotfiles/.claude/CLAUDE.md` **line ~668**,
    the paragraph beginning *"Archiving is yours to do, at the moment of completion
    — unprompted (Bill, 2026-08-31)."* — the phrases "in the same handoff its code
    and doc deltas ship in" and "the `git mv` just joins the staged set; my commit
    timing is independent" are the exact wrong part.
  - runCrushInContainer `client/entrypoint/dotfiles/.config/crush/CLAUDE.md`
    **lines ~105-107**, the condensed twin: *"yours to do at the moment of
    completion, unprompted (2026-08-31): … `git mv`, stage) in the same handoff as
    the unit's code and doc deltas; don't ask, and don't hold because staged…"*.

- **Already correct — leave alone:** the `/archive-task` commands in both repos
  (`…/commands/archive-task.md`). They do `git mv` (step 9) **and** the one-shot
  `git rm` (step 10) **together** and end (step 11) with *"Do not commit — leave
  staging to me."* — which is exactly commit 3. The commands are fine; only the
  free-prose "do it in the same handoff as the work" guidance is wrong. (Optional
  hardening: have the command note that a one-shot `git rm` is safe only once the
  script's work commit exists — see the adhoc-timing note below.)

- **Interplay with "Git: I commit, you don't — but you DO stage":** that section
  is unchanged in spirit — the agent still stages, the maintainer commits. This
  task only fixes *what belongs in which staged set*: the archive is its own set,
  gated on the work commit having landed.

- **The adhoc-`git rm`-timing note (added 2026-09-06, this needs reconciling):**
  the One-shot bullet now says the removal *"trails the archive by one commit
  boundary."* That was directionally right but imprecise — under the maintainer's
  workflow the `git rm` doesn't merely *trail*, it belongs **in the archive
  commit** (paired with the `git mv`), which itself follows the work commit. Reword
  to say that.

## The operating rule to encode (how "proactive" and "separate commit" coexist)

"Don't ask" is about *permission*; the commit boundary is about *timing*. At task
completion the agent still acts proactively and without a go/no-go question — but
what it does next depends on which commit mode the session is in.

**Default mode (the maintainer commits — the normal case):**

1. Stage the **work + adhoc scripts**, report the handoff, and **stop**. Do **not**
   `git mv` the task doc or `git rm` any adhoc script yet.
2. The maintainer makes the **work commit**.
3. **Once that commit exists** (agent detects it — HEAD moved / the work files are
   no longer pending), the agent **proactively** stages the **archive set**: the
   `git mv` to `tasks/archive/…`, the reference-doc harvest, and the one-shot adhoc
   `git rm` — together — for the maintainer to commit as commit 3. Still no
   permission asked.

At completion the archive is therefore an **owed** action, tracked (in the task
doc's status and/or the stack), executed after the work commit — within the same
session if the maintainer commits then, or next session otherwise. The agent says
so plainly (*"task is complete and staged; I'll archive it in its own commit once
you've committed the work"*), and never presents a go/no-go archive question.

**Authorized-to-commit mode (the maintainer has granted commit access this session,
per-project — the overnight/quick-save case):** same boundaries, agent runs the
commits: stage + **commit** the work (+ adhoc scripts); then, as a **separate**
commit, `git mv` the archive and `git rm` the one-shot scripts and **commit** that.
Two commits, in order, both by the agent — never one combined "work + archive"
commit. (This slots into the existing quick-save-then-squash rhythm; the archive
stays its own logical commit through the squash.)

## Proposed changes (do NOT apply until approved)

1. **runClaude `CLAUDE.md` ~L668** — rewrite the paragraph: keep "archiving is
   yours to do, proactively, unprompted — don't present go/no-go candidates", but
   replace "in the same handoff … `git mv` just joins the staged set" with the
   operating rule above (stage the archive as its own set *after* the work commit;
   never bundle it into the work handoff; it is commit 3).
2. **runCrush `CLAUDE.md` ~L105-107** — same fix, condensed to that file's style.
3. **Both files, the adhoc One-shot bullet** — reword "trails the archive by one
   commit boundary" → "goes **in the archive commit** (paired with the `git mv`),
   which follows the work commit."
4. **Optional:** add a one-line "the lifecycle is three commits: task-add /
   work+adhoc / archive+adhoc-delete" statement near the archiving guidance or in
   "Git: I commit, you don't", so the whole shape is stated once.
5. **Agent memory** `archive-on-completion-no-asking` — update its body to carry
   the corrected timing (proactive yes; staged as its own commit after the work
   commit, not bundled with the work). Not one of the three repos, but it encodes
   the same now-wrong rule and will re-mislead if left.

## Verification

Docs-only; no gate. After editing, re-read each changed paragraph end-to-end for
one coherent story (no leftover "same handoff" phrasing), confirm runClaude and
runCrush say the same thing at their two levels of detail, and confirm the memory
matches. Stage the changes in each repo by path; the maintainer commits.

## Decisions made

- **Memory-update scope (maintainer: "whatever you recommend", 2026-09-07):** fix
  only the existing memory `archive-on-completion-no-asking`'s body to carry the
  corrected timing (proactive yes; archive is its own commit after the work commit,
  never bundled with the work — noting the who-commits default/authorized split).
  Keep it one-fact; the full three-commit lifecycle lives in the shared `CLAUDE.md`
  the memory points to. No separate lifecycle memory.

No open questions remain — this is ready to implement on the maintainer's
go-ahead.
