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
   **Started:** <today, YYYY-MM-DD>

   ## Goal

   <one-paragraph statement of what we're trying to accomplish>

   ## Plan

   - [ ] <first step>

   ## Notes / decisions

   ## Open questions
   ```

6. Ask me for the title and one-paragraph goal (don't invent them from the slug). Fill them in once I answer. Leave Plan/Notes/Open questions for me or for our work to populate.
7. Confirm the path of the created file.
