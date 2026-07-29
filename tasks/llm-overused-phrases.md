# Overused LLM words/phrases — catalog, alternatives, and CLAUDE.md guidance

**Status:** proposed — needs go-ahead to start
**Started:** 2026-07-29

## Goal

Research online what words and phrases are overused by Claude Code and LLMs generally
(the "delve"/"tapestry"-class tells), and turn that into actionable writing guidance for
the sandbox. For each overused word/phrase: explain what it means, gather ~15 similar
words/phrases that could be used instead, and evaluate which of those alternatives are
actually worth remembering. The final deliverable is an update to this repo's tracked
cross-project conventions — `entrypoint/dotfiles/.claude/CLAUDE.md` (the copy mounted
over `~/.claude` in every sandbox session, per "The two-layer Claude config" in the root
`CLAUDE.md`) — instructing the LLM that it tends to overuse these phrases and to
consider the vetted alternatives.

## Plan

- [ ] **1. Identify** — research online (articles, studies, word-frequency analyses of
      LLM output, community lists) which words/phrases are overused by Claude Code and
      LLMs. Compile the list.
- [ ] **2. Define** — for each item, explain in a sentence or paragraph (whichever is
      appropriate) what it means.
- [ ] **3. Alternatives** — for each item, identify ~15 similar words/phrases that could
      be used instead.
- [ ] **4. Evaluate** — for each set of ~15 alternatives, judge which are worth
      remembering (and which are themselves clichés, awkward, or worse than the
      original).
- [ ] **5. Apply** — update `entrypoint/dotfiles/.claude/CLAUDE.md` to instruct the LLM
      that it can overuse some of these phrases and should consider the vetted
      alternatives.

## Notes / decisions

- Parts 1–4 are research; their output is a findings document. Given the "will this
  still be worth reading after the work is finished?" test, the catalog (words,
  meanings, vetted alternatives) likely belongs in `tasks/reference/` (to be created —
  this repo doesn't have one yet), with part 5 distilling it into a lean CLAUDE.md
  section rather than pasting the whole catalog there.
- The edit target is the **entrypoint** copy (`entrypoint/dotfiles/.claude/CLAUDE.md`),
  not the repo-root `CLAUDE.md` and not the host's live `~/.claude/CLAUDE.md` — edits
  belong in the tracked copy so they flow back to git.

## Open questions

- None yet.
