---
description: Show the work stack — what we're on, and what's waiting underneath
argument-hint: (none)
---

Show me the current work stack from `~/.claude/stack.md`.

Steps:

1. If the file is missing or has no entries, say "the stack is empty" and stop. Do not
   invent entries.

2. Print the stack **top first**, numbered, compactly — one block per entry:

   ```
   1. [repo] <description>          <- TOP: what we should be doing now
      resume with: <concrete next action>
      open questions: <numbered, or none>
      pushed <date>, diverted to: <what>
   ```

3. **Verify each entry against reality before showing it** — this is the part that makes
   the command trustworthy:
   - if it names a task doc, confirm the file still exists (and report if it has been
     archived or deleted);
   - if the entry looks already-done (the task doc says complete, or the work is
     obviously landed), **say so and suggest `/stack-pop`** rather than presenting stale
     work as pending.

4. After the list, state plainly: **what the top item means we should be doing right
   now.** If the current conversation has drifted off the top item, say that too — that
   drift is the thing this stack exists to catch.

5. Do not modify the stack. This command is read-only.
