---
description: Test whether any blocked task's external gate has cleared, by running its Recheck field
argument-hint: "[--all]"
---

Re-check `blocked` tasks — tasks that carry a `**Blocked on:**` external condition and a
runnable `**Recheck:**` check (per the "Blocked tasks" convention in `CLAUDE.md`).

Args: `$ARGUMENTS` — pass `--all` to sweep **every mounted repo**; with no args, only the
**current repo**.

Steps:

1. **Pick the scope.**
   - No args → the current repo (prefer `git rev-parse --show-toplevel`, else cwd).
   - `--all` → every project mount. Scan top-level dirs at `/` for a mount (contains `.git/`
     or `CLAUDE.md`), skipping the system paths listed in the "Multi-repo sessions" section
     of `CLAUDE.md`. Also include mounts under the usual non-`/` roots if they're already
     visible in this session (e.g. `/mnt/*`, `/foo/opt/*`).

2. **Find the blocked tasks.** In each in-scope repo, look at `tasks/*.md` (top level, **not**
   `tasks/archive/`) for files whose header has `**Status:**` containing `blocked` **and** a
   `**Recheck:**` field. Collect: repo, slug, `Blocked on:` line, and the `Recheck:` text.
   If none, say so and stop.

3. **List what you're about to check** — one line per blocked task (`repo/slug` — `Blocked on:`
   … — `Recheck:` …) — before running anything, so I can see the batch.

4. **Run each `Recheck:`** exactly as written. It is one of:
   - a **URL + signal** → `WebFetch` the URL and report whether the stated signal is present
     (e.g. "the 'still in development' caveat is gone");
   - a **version/release comparison** → fetch the authoritative source (PyPI JSON, `git tag
     --sort=v:refname`, a releases page) and compare with a **version-aware** sort (per
     "Version numbers don't sort like strings" in `CLAUDE.md`) — never lexically;
   - a **command** → run it and read the exit status / output;
   - a **human-gated step** → don't run it; just report it's still waiting on me and name the
     one action I have to take.
   If a check can't run (network down, URL moved, command missing), report that as
   **unknown**, not cleared — and note the URL/command so the `Recheck:` can be fixed.

5. **Report a table** — for each: `CLEARED` / `still blocked` / `unknown`, with the one-line
   evidence. Order cleared-first.

6. **For each CLEARED task, offer to un-block it** (don't do it unprompted): drop the
   `Blocked on:`/`Recheck:` fields, set a real `**Status:**` and a fresh `**Priority:**`
   (propose one with a one-line rationale), and — if I say go — make that edit and stage the
   file. Leave `still blocked` / `unknown` tasks untouched.

7. **Don't commit** — staging only, per "Git: I commit, you don't — but you DO stage".

This command is the **on-demand** re-check; it is never run automatically. The session-start
scan and session-end sweep only *remind* that blocked tasks exist — they don't fire these
network checks on their own.
