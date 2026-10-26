# Default-allow file read/write inside the sandbox (stop the per-file permission prompts)

**Status:** proposed — needs go-ahead (the maintainer asked to file this task, 2026-10-26).
**Priority:** 4 **Difficulty:** 2
**Created:** 2026-10-26 (William Emerison Six <billsix@gmail.com>). From the maintainer: "why does
claude, as in runClaudeInContainer, keep asking me for permissions to read and write files and
folders? I run it all in a container, I expect that anything in the container can be read or written
by claude. can you make a task ... to allow this by default?"

## BLUF

Claude Code, running inside this sandbox, prompts the maintainer to approve file reads/writes
(reading a path outside the working dir, editing/creating files). The **container is already the
trust boundary** — nothing in it is precious that a clobber would lose (repos are bind-mounted and
committed/pushed from the host; the store is ephemeral), so those prompts are pure friction. Ship a
**baked `settings.json`** in the sandbox's `~/.claude` layer that **allows file reads/writes by
default** across the container, so a fresh sandbox is quiet out of the box without the maintainer
touching anything. "Done" = a new `make shell` session never prompts for an ordinary `Read`/`Edit`/
`Write`/file-create, the setting is documented + version-controlled in this repo, and the broader
blast radius (does this also silence *bash* prompts?) is a conscious, documented choice — not a
side effect.

## Context (read first)

- **How `~/.claude` is assembled:** `tasks/reference/claude-config-layering.md`. The sandbox's
  committed `.claude` layer lives at `entrypoint/dotfiles/.claude/` (`CLAUDE.md`, the personal
  overlay, `commands/`, reference docs). The host's real `~/.claude` is **mounted** over parts of it
  so interactive login + edits persist back (see the `Makefile` `~/.claude` / `~/.claude.json` mount
  comments around lines 136–177, and `entrypoint/shell.sh`). **There is no `settings.json` today**
  (`find . -name 'settings*.json'` is empty) — so this is a net-new file, with the one real question
  being *where it sits in the mount/bake layering* so it takes effect and doesn't get shadowed by the
  host mount (resolve against `claude-config-layering.md`).
- **Claude Code's permission model (verify current semantics with the `update-config` skill / docs
  before implementing — this is the 2026-01 understanding):**
  - `settings.json` has a `permissions` block: `allow` / `ask` / `deny` **rule lists** (e.g.
    `"Read"`, `"Edit"`, `"Write"`, or tool-scoped like `"Read(//**)"`), plus `additionalDirectories`
    (extra roots that don't prompt on Read) and `defaultMode`.
  - **Permission modes:** `default` (prompts), `acceptEdits` (auto-accepts Edit/Write + file
    creation, still prompts for bash etc.), `plan`, and `bypassPermissions` (skips *all* prompts,
    including bash — the broadest).
  - A Read of a path **outside the working directory** prompts to add that directory; the sandbox
    mounts several repos at top-level paths (`/foo/opt/*`, `/<repo>`), so cross-repo reads are a
    common source of the prompts the maintainer is hitting.
- **Why this is safe HERE specifically:** the container is ephemeral and the file-system IS the
  sandbox — the usual reason to gate Write/Edit (protecting the host) doesn't apply. The caveat is
  only *within* the container: outward-facing / irreversible actions (network sends, `git push`,
  deletes) still deserve thought, which is why a **file-scoped** allow is cleaner than a blanket
  bypass (see Open question 1).

## Options (decide in Open questions)

1. **File-scoped allowlist (recommended).** A baked `settings.json` with
   `permissions.allow: ["Read", "Edit", "Write"]` plus `additionalDirectories` covering the mount
   roots (so cross-repo Reads don't prompt) — or equivalently `permissions.defaultMode: "acceptEdits"`
   with `additionalDirectories`. Silences the file prompts the maintainer named, while bash / network
   / destructive actions still surface. Narrowest fix that solves the stated problem.
2. **`defaultMode: "bypassPermissions"`** (or launching `claude --dangerously-skip-permissions`).
   Silences *everything*, not just files. Simplest, but it also removes the bash/network confirmations
   — a bigger blast radius than the maintainer asked for. Only if option 1's file rules turn out
   insufficient or fiddly.
3. **Launch-flag vs settings-file.** A flag on the `claude` invocation lives in the launcher
   (`entrypoint/shell.sh` / `Makefile`); a `settings.json` is declarative and also applies to nested
   / headless invocations. Prefer the settings file (option 1/2 are expressed through it) unless a
   flag is needed for a reason the file can't express.

## Plan (sketch — refine after the decision)

1. Confirm the current Claude Code permission schema (keys, rule syntax, mode names) via the
   `update-config` skill / docs — don't hardcode from memory.
2. Add `entrypoint/dotfiles/.claude/settings.json` with the chosen permissions, placed so the mount
   layering actually applies it (check against `claude-config-layering.md`; may need a Makefile mount
   or a bake step, like the other `.claude` files).
3. Verify in a **fresh** `make shell`: Read a file in another mounted repo, Edit an existing file,
   create a new file — none should prompt. Confirm whatever was deliberately left prompting (bash, if
   option 1) still does.
4. Document it: a short note in this repo's `README`/`CLAUDE.md` and, if it's a reusable convention,
   a line in `tasks/reference/claude-config-layering.md`. Mirror into the runCrush twin if it applies
   there too (its config layering is the sibling).

## Gates / verify

- Fresh sandbox session: ordinary `Read`/`Edit`/`Write`/file-create across the mounted repos does not
  prompt.
- The setting is committed in `entrypoint/dotfiles/.claude/` (version-controlled, not a host-only
  tweak), and survives a rebuild.

## Open questions

1. **File-scoped allow (option 1) or full bypass (option 2)?** The request is specifically "read or
   write ... files and folders", so option 1 (recommended) matches it and keeps bash/network/delete
   confirmations. Confirm you want those kept, or say "bypass everything" for option 2.
2. **Does this belong in the runCrush twin (`runCrushInContainer`) too**, kept in step like the other
   shared `.claude` layer pieces? (Recommend yes if its layering is the same.)

## Pointers

- `tasks/reference/claude-config-layering.md` — how `~/.claude` / auth / sessions / mounts assemble
  (read before placing the settings file).
- `entrypoint/dotfiles/.claude/` — the committed `.claude` layer (where the settings file goes).
- `Makefile` (~136–177) + `entrypoint/shell.sh` — the `~/.claude` / `~/.claude.json` mounts and the
  `claude` launch path.
- Sibling: `tasks/suppress-claude-session-trailer.md` (another "configure Claude Code's behaviour in
  the sandbox by default" task).
