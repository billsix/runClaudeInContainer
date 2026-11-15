# Overused LLM words/phrases — catalog, alternatives, and CLAUDE.md guidance

**Status:** complete
**Completed:** 2026-07-29

## What this did

Researched which words and multi-word phrases Claude Code and LLMs generally overuse
(single-word tells such as "delve"/"tapestry", and phrase-level tells such as a figurative
"load-bearing"), and turned the result into writing guidance for the sandbox.

**Purpose (William Emerison Six <billsix@gmail.com>, 2026-07-29):** readability (less
annoying, more varied, more interesting output), not hiding LLM authorship. The verdicts
are judged by readability, not by whether they would fool an AI detector.

## What was built

- **The catalog, `tasks/reference/llm-overused-phrases.md`** (the first reference doc in
  this repo): 26 word/phrase entries plus 6 structural tics, each with a meaning, ~15
  alternatives (390+ total), and a Verdict line with the keepers bolded. Sources:
  Wikipedia's "Signs of AI writing", the Science Advances excess-vocabulary study (15M
  PubMed abstracts), two HN threads on claudisms (one on "load-bearing"), the Register /
  GitHub issue #3382 on "You're absolutely right!", and Claude-specific style guides.
- **"Words and phrases you overuse — notice them, and vary"** in
  `entrypoint/dotfiles/.claude/CLAUDE.md`, after "Caveats belong with the step they
  affect": the grouped offender list, the delete → specify → plainest-word fix order, and a
  pointer to the catalog. The cross-repo pointer uses github.com/billsix/runClaudeInContainer.

## Findings and decisions

- Deletion, specificity, or the plainest word beats synonym rotation; several circulating
  "alternatives" (unpack, foundational, utilize, frictionless) are themselves clichés.
- The tell vocabulary drifts by model era ("delve" measurably declined after being called
  out in 2024), so the catalog is a snapshot to revisit occasionally.
- The catalog belongs in `tasks/reference/` (it passes the "still worth reading after the
  work is done" test); CLAUDE.md carries only a lean distillation.
- **Mount in place (the maintainer, 2026-07-29):** the canonical file stayed at
  `tasks/reference/llm-overused-phrases.md`, and `CLAUDE_DOTFILES_MOUNT` gained
  `-v ./tasks/reference:/root/.claude/reference:Z`, so every session can read it at
  `~/.claude/reference/`. A first attempt that moved the file into the dotfiles tree was
  reverted at the maintainer's preference; no copy exists. Consequence: everything in
  `tasks/reference/` is visible in every session. The root `CLAUDE.md` and `README`
  documented the third mount.
- Edits went to the tracked `entrypoint/dotfiles/.claude/CLAUDE.md`, not the repo-root
  `CLAUDE.md` or the host's live `~/.claude/CLAUDE.md`.

Superseded: the "read the catalog at the start of every session" instruction became a
read-on-demand trigger 2026-09-14 (the "Reference docs — read-on-demand at a trigger" section
of `entrypoint/dotfiles/.claude/CLAUDE.md`), with the distilled offender list kept inline.
