---
description: Scaffold a new task document at tasks/<slug>.md in the current repo
argument-hint: <kebab-slug>
---

Create a new task document for the project we're currently in.

Slug: `$ARGUMENTS`

Steps:

1. Determine the repo root — prefer `git rev-parse --show-toplevel` if it's a git repo; otherwise use the current working directory.
2. If `$ARGUMENTS` is empty or not kebab-case, stop and ask me for a valid slug.
3. Ensure `<repo-root>/tasks/` exists; create it if missing.
4. If `tasks/$ARGUMENTS.md` already exists, stop and tell me — show me its current status and ask whether I want to resume the existing task instead of clobbering it. Do not overwrite.
5. Otherwise, create `tasks/$ARGUMENTS.md` with this skeleton:

   ```markdown
   # <Title>

   **Status:** in-progress
   **Priority:** <1–10, 1=highest>
   **Difficulty:** <1–10, 1=easiest>
   **Started:** <today, YYYY-MM-DD>

   ## BLUF

   <1–4 sentences: what this task IS and what "done" means — the bottom line, up front>

   ## Context

   <Cold-start orientation: what to read first (files, related/prior tasks, reference docs),
   the current state of the relevant code, and any decisions already made with their rationale —
   enough that a fresh reader can act without the conversation that produced this task.>

   ## Goal

   <one-paragraph statement of what we're trying to accomplish>

   ## Plan

   - [ ] <first step>

   ## Notes / decisions

   ## Open questions
   ```

   (`## BLUF` and `## Context` are the standing task-doc default — see "Task documents" in
   `CLAUDE.md`: every task is written to be executed **cold**, so a fresh reader/LLM needs no
   prior conversation. Don't preface them with "this is self-contained" — just fill them in.)

6. Ask me for the title and one-paragraph goal (don't invent them from the slug). Fill them in once I answer, then **draft the `## BLUF`** (1–4 sentences — what the task is and what "done" means) from the title/goal for me to tweak, and **populate `## Context`** with what you already know — the files a fresh reader should read first, related/prior tasks and reference docs, the current state of the relevant code, and any decisions already made with rationale (this is the cold-execution default; if you don't yet have enough for Context, leave a stub prompting for it rather than dropping the section). Also **propose a Priority and Difficulty** (1–10 each, per the scale in the "Task documents" section of `CLAUDE.md` — 1=highest priority / easiest, geometric ~1.5×/step) with a one-line rationale for each, and let me adjust before finalizing. Leave Plan/Notes/Open questions for me or for our work to populate.
   - **If the task can't start until an external condition changes** (an upstream feature ships, a release lands, a standard stabilizes, or I run a hands-on verification), set `**Status:** blocked` instead of `in-progress`, give it a high Priority number, and add `**Blocked on:**` (the condition, one line) and `**Recheck:**` (a cheap runnable check + the cleared signal) directly under the header — per the "Blocked tasks" convention in `CLAUDE.md`. `/recheck-blocked` will later test the `Recheck:`.
7. Confirm the path of the created file.
