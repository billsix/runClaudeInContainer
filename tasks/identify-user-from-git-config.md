# Identify the session user by git name + email; de-hardcode "Bill" in the conventions

**Status:** ready — all decisions made; awaiting go-ahead to implement
**Priority:** 3
**Difficulty:** 4
**Created:** 2026-08-12
**Updated:** 2026-08-12 — decisions locked: category-1-only rewrite; new stamps use
git **name + email** (see Decisions)

**Motivation (confirmed 2026-08-12):** at some point other people will contribute. The
current user *is* Bill today, but **whenever the agent references the user it is
interacting with in the current session, it should uniquely identify them by their
`git config user.name` and `user.email`**, not by a name baked into the conventions. The
host `~/.gitconfig` is already mounted to `/root/.gitconfig`, so the identity is present
— nothing derives from it, and the conventions assume the user is "Bill."

## Goal

1. **Going forward (the rule):** the agent identifies the current session user by git
   name + email, added as a convention to **runClaudeInContainer's mounted cross-project
   `CLAUDE.md`** (`entrypoint/dotfiles/.claude/CLAUDE.md`) — the file loaded into every
   session — so every project inherits it.
2. **Cleanup:** find and fix the existing hardcoded-"Bill" references that stand for
   *the user-as-role*, across all projects.

## What the grep found (2026-08-12) — and why scope needs a decision

"Bill" occurrences fall into distinct categories, and only some are "the user I'm
interacting with":

| Category | Example | runCiC | gacalc | mvp | Should it change? |
| --- | --- | --- | --- | --- | --- |
| **Live user-role reference** (in conventions/reference/task docs) | "Bill wants X", "ask Bill to arbitrate", "Bill declined it" | ~25 lines | some of ~215 | some of ~648 | **Yes** — this is the user-as-role |
| **Historical provenance stamp** | "(Bill, 2026-07-19: …)" | 13 | 20 | 38 | Recommend **leave** (historical record of who advised, when) |
| **Authorship / copyright / AUTHORS / code credit** | book byline, LGPL header, `# Bill Six`, AUTHORS | — | many | many | **No** — real authorship, not a session user |

The per-project totals are dominated by the last two categories (book prose, author
credits), which should **not** be rewritten. The real cleanup is concentrated in the
**conventions/reference docs** (mostly in runClaudeInContainer), where "Bill" = "the
current user."

## What to do (pending Q1)

1. **Add the rule** to `entrypoint/dotfiles/.claude/CLAUDE.md`: identify the session
   user by `git config user.name` / `user.email`; when adding a new attribution/stamp,
   use that identity so multi-contributor history stays unambiguous; fall back to a
   neutral "unknown user" when no gitconfig is mounted (the mount is conditional).
2. **Surface the identity at session start** so the agent actually reads it — an
   entrypoint/dotfile step exposing `git config user.name`/`user.email` (natural home:
   `shell.sh` / `.extrabashrc`).
3. **Genericize the live user-role references** in the conventions + reference docs (the
   category-1 lines) to "the user (per git identity)". Leave categories 2 and 3 verbatim
   unless Q1 says otherwise.
4. **Verify** the conventions still read correctly and no authorship credit was mangled.

## Decisions (locked 2026-08-12)

1. **Category-1 only.** Rewrite only the **live user-role references** in the
   conventions/reference docs + add the going-forward rule. **Leave category 2
   (historical `(Bill, <date>)` stamps) and category 3 (authorship/book/code credits)
   verbatim.**
2. **New attribution format = git name + email.** When the agent writes a *new* dated
   stamp/attribution going forward, uniquely identify the user with **both** name and
   email, e.g. `(William Emerison Six <billsix@gmail.com>, 2026-08-12)`. (Existing
   stamps are not rewritten — decision 1.)

## Open questions

None — ready to implement on go-ahead.

## See also

- `tasks/reference/claude-config-layering.md` — the `~/.claude` + gitconfig mount design.
