# Default-allow file read/write inside the sandbox (stop the per-file permission prompts)

**Status:** proposed — design settled (all open questions resolved by the maintainer 2026-10-26);
ready to implement on go-ahead.
**Priority:** 4 **Difficulty:** 2
**Created:** 2026-10-26 (William Emerison Six <billsix@gmail.com>). From the maintainer: "why does
claude, as in runClaudeInContainer, keep asking me for permissions to read and write files and
folders? I run it all in a container, I expect that anything in the container can be read or written
by claude. can you make a task ... to allow this by default?"

## BLUF

Claude Code, running inside this sandbox, prompts the maintainer to approve file reads/writes/deletes
(reading a path outside the working dir, editing/creating files, `rm`-ing them). The **container is
the trust boundary** for files, so those prompts are friction. Ship a **baked `settings.json`** in
the sandbox's `~/.claude` layer that, by default, **allows reading, writing, and deleting files/folders**
across the container — but **grants nothing about the network**, and does **not** invite deleting the
mounted-in project repos themselves (those are the maintainer's real git repos on the host). "Done" =
a new `make shell` session never prompts for an ordinary file read / edit / create / delete done while
implementing a task, while network actions (and whole-repo destruction) still surface; the setting is
documented + version-controlled in this repo.

## Maintainer decisions (2026-10-26)

- **Grant by default: read, write, AND delete files/folders** done as part of implementing a task. The
  original Q1 is resolved toward the *file-scoped* side — but explicitly including **delete**, not just
  edit/create.
- **Grant NOTHING about the network by default.** Network actions (curl/wget, `git push`/`fetch`, pip/
  npm/cargo installs that reach out, ssh) must still prompt. This is the firm boundary.
- **Protect the mounted-in project repos.** The agent should not delete a mounted project (or its
  `.git`) — those live on the host. Whether this is a hard settings-level guard or agent judgment is
  Open question 2.
- **Do NOT mirror this to `runCrushInContainer`** — the runCrush client "handles things differently",
  so this stays runClaude-only (supersedes the earlier "mirror to the twin" idea).

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

## Design (from the decisions — settle the remaining forks in Open questions)

A baked `settings.json` (not a launch flag — declarative, also applies to nested/headless runs). Its
shape, given "files yes / network no / delete yes / don't nuke the repos":

- **Edit/Write/Read:** `permissions.allow: ["Read", "Edit", "Write"]` (plus `additionalDirectories`
  covering the mount roots so cross-repo *reads* don't prompt). Alternatively `defaultMode:
  "acceptEdits"` for the Edit/Write half. This part is uncontentious.
- **Delete is the subtlety:** deletion is **not a distinct tool** — it happens through the **Bash tool**
  (`rm`, `rmdir`, `git rm`). So "allow delete by default, but not network" means **allowing the
  file-mutating shell commands** (`rm`, `rmdir`, `mv`, `mkdir`, `cp`, `touch`, `git rm`, `git mv`) via
  `permissions.allow: ["Bash(rm:*)", …]` **while the network stays on the default (ask)** path. A
  blanket `Bash` allow is wrong here — it would silence network commands too. (Open question 1 fixes
  the exact command set and whether to express it as an allowlist or as narrow network-focused
  `deny` rules layered under a broader allow.)
- **Protecting the mounted repos** (Open question 2): a settings `deny` on removing a repo root / its
  `.git` is possible but *fragile* (path-pattern matching on `rm` args is easy to slip past), so it may
  be better treated as agent judgment than a hard rule. Decide which.
- `bypassPermissions` / `--dangerously-skip-permissions` is explicitly **rejected** — it would silence
  the network too, which the maintainer ruled out.

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
   a line in `tasks/reference/claude-config-layering.md`. **Do not mirror to runCrush** (maintainer:
   it handles things differently).

## Gates / verify

- Fresh sandbox session: ordinary `Read`/`Edit`/`Write`/file-create across the mounted repos does not
  prompt.
- The setting is committed in `entrypoint/dotfiles/.claude/` (version-controlled, not a host-only
  tweak), and survives a rebuild.

## Open questions — RESOLVED (maintainer, 2026-10-26)

1. **How to express "delete allowed, network not" over the Bash tool → (a) the allowlist of file-ops
   commands.** `Bash(rm:*)`, `Bash(rmdir:*)`, `Bash(mv:*)`, `Bash(mkdir:*)`, `Bash(cp:*)`,
   `Bash(touch:*)`, `Bash(git rm:*)`, `Bash(git mv:*)` allowed; every other Bash command still on ask
   (so network tools are never silenced). Fails safe. (Not the broad-allow-with-network-deny option.)
2. **Guard the mounted repos → by judgment, no hard deny-rule.** The maintainer: "you shouldn't really
   need to delete folders unless you know why as part of the task" — deletion is a purposeful,
   understood act, so this is agent discipline, not a settings guard (a path-pattern `deny` would be
   best-effort and evadable anyway). Do NOT add a deny-rule for the repo roots.
3. **Also allowlist ordinary safe non-file commands → yes.** Add the common read-only / build commands
   — `Bash(ls:*)`, `Bash(cat:*)`, `Bash(grep:*)` (and `rg`/`find`), `Bash(make:*)`, and the project
   gate commands (format/test/type-check) — so they don't prompt either. Still nothing network.

Implementation note from these: a `settings.json` with `permissions.allow` = `["Read", "Edit", "Write"]`
+ the file-ops Bash allowlist (Q1) + the safe read-only/build Bash allowlist (Q3) + `additionalDirectories`
for the mount roots; NO network commands allowed; NO repo-deletion deny-rule (Q2, judgment). Verify the
exact `Bash(cmd:*)` rule syntax against current Claude Code docs before shipping.

## Pointers

- `tasks/reference/claude-config-layering.md` — how `~/.claude` / auth / sessions / mounts assemble
  (read before placing the settings file).
- `entrypoint/dotfiles/.claude/` — the committed `.claude` layer (where the settings file goes).
- `Makefile` (~136–177) + `entrypoint/shell.sh` — the `~/.claude` / `~/.claude.json` mounts and the
  `claude` launch path.
- Sibling: `tasks/suppress-claude-session-trailer.md` (another "configure Claude Code's behaviour in
  the sandbox by default" task).
