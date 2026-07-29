# Overused LLM words/phrases — catalog, alternatives, and CLAUDE.md guidance

**Status:** done 2026-07-29 — deliverables staged, awaiting Bill's review (archive after)
**Started:** 2026-07-29

## Goal

Research online what words **and multi-word phrases** are overused by Claude Code and
LLMs generally, and turn that into actionable writing guidance for the sandbox. Both
kinds are in scope: single-word tells (the "delve"/"tapestry" class) and phrase-level
tells (e.g. **"load-bearing"**, per Bill — figurative uses like "this comment is
load-bearing"). For each overused word/phrase: explain what it means, gather ~15 similar
words/phrases that could be used instead, and evaluate which of those alternatives are
actually worth remembering. The final deliverable is an update to this repo's tracked
cross-project conventions — `entrypoint/dotfiles/.claude/CLAUDE.md` (the copy mounted
over `~/.claude` in every sandbox session, per "The two-layer Claude config" in the root
`CLAUDE.md`) — instructing the LLM that it tends to overuse these phrases and to
consider the vetted alternatives.

**Purpose (Bill, 2026-07-29):** this is **not** about hiding LLM authorship — Bill is
not concealing that he uses an LLM. The point is to make the output **less annoying,
more varied, and more interesting to read**. Verdicts and the CLAUDE.md guidance are
judged by readability, not by whether they'd fool an AI detector.

## Plan

- [x] **1. Identify** — researched online: Wikipedia's "Signs of AI writing" guide,
      the Science Advances excess-vocabulary study (15M PubMed abstracts), two HN
      threads on claudisms (incl. one devoted to "load-bearing"), the Register /
      GitHub issue #3382 on "You're absolutely right!", and Claude-specific
      style guides. Compiled 26 word/phrase entries plus 6 structural tics.
- [x] **2. Define** — each entry has a meaning explanation (sentence or paragraph as
      appropriate) in `entrypoint/dotfiles/.claude/reference/llm-overused-phrases.md`.
- [x] **3. Alternatives** — ~15 alternatives listed per entry (390+ total).
- [x] **4. Evaluate** — keepers bolded per entry with a Verdict line; recurring result:
      deletion, specificity, or the plainest word beats synonym rotation, and several
      circulating "alternatives" (unpack, foundational, utilize, frictionless) are
      themselves clichés.
- [x] **5. Apply** — added "Words and phrases you overuse — notice them, and vary" to
      `entrypoint/dotfiles/.claude/CLAUDE.md` (after the "Caveats" section): grouped
      offender list, the delete→specify→plainest-word fix order, and a pointer to the
      full reference catalog.

## Notes / decisions

- Parts 1–4 are research; their output is a findings document. Given the "will this
  still be worth reading after the work is finished?" test, the catalog (words,
  meanings, vetted alternatives) belongs in `tasks/reference/` (created 2026-07-29 —
  first reference doc in this repo), with part 5 distilling it into a lean CLAUDE.md
  section rather than pasting the whole catalog there.
- Framing per Bill (mid-task, 2026-07-29): the purpose is readability — less
  annoying, more varied, more interesting output — **not** hiding LLM authorship.
  Both the reference doc and the CLAUDE.md section state this explicitly, and the
  verdicts are judged by readability rather than detector evasion.
- CLAUDE.md placement: after "Caveats belong with the step they affect", among the
  communication conventions. Cross-repo pointer uses the GitHub URL
  (github.com/billsix/runClaudeInContainer) per convention, not the Pi remote or a
  container path.
- Key research surprise worth keeping: the tell vocabulary drifts by model era, and
  "delve" measurably *declined* after being called out publicly in 2024 — so the
  catalog is a snapshot, not a fixed law; revisit occasionally.
- Follow-up (Bill, 2026-07-29): the catalog must be readable in **every** container
  session, so the mounted CLAUDE.md's pointer is always valid and the read can happen
  at session start. Done by mounting the doc **in place**: the canonical file stays at
  `tasks/reference/llm-overused-phrases.md` (its conventional home), and
  `CLAUDE_DOTFILES_MOUNT` gained `-v ./tasks/reference:/root/.claude/reference:Z`.
  The mounted CLAUDE.md section says "Read `~/.claude/reference/llm-overused-phrases.md`
  at the start of every session". (First attempt moved the file into
  `entrypoint/dotfiles/.claude/reference/`; Bill preferred mount-in-place, so that
  move was reverted — no copy exists.) Repo-root CLAUDE.md and README document the
  third mount. Note the consequence: **everything** in `tasks/reference/` is now
  visible at `~/.claude/reference/` in every session, so future reference docs in
  this repo ride along automatically.
- The edit target is the **entrypoint** copy (`entrypoint/dotfiles/.claude/CLAUDE.md`),
  not the repo-root `CLAUDE.md` and not the host's live `~/.claude/CLAUDE.md` — edits
  belong in the tracked copy so they flow back to git.

## Open questions

- None yet.
