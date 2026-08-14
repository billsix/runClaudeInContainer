# The layered `~/.claude` — what persists, what's tracked, and why

**What this is:** the standing description of how the sandbox assembles
`/root/.claude` from the host's private state, this repo's tracked config, and a
per-user personal overlay — plus the persistence rationale and the alternatives that
were rejected. Read this before touching `CLAUDE_CONFIG_MOUNT`,
`CLAUDE_DOTFILES_MOUNT`, `CLAUDE_PERSONAL_MOUNT`, or the
`entrypoint/dotfiles/.claude/` layout.
Consolidated 2026-07-30 from the root `CLAUDE.md`, `Makefile` comments, and the
archived incident task
(`tasks/archive/2026/07/09/persist-claude-login-across-containers.md`).

## The four mounts, in stacking order

The `shell` target mounts, in order (later mounts shadow earlier paths):

1. **Host `~/.claude` → `/root/.claude`** (`CLAUDE_CONFIG_MOUNT`) — the private,
   *unversioned* layer: OAuth credentials (`.credentials.json`), session
   history and resumable transcripts, per-project **agent memory**
   (`projects/<project>/memory/`), settings, plugins, file-history.
2. **`entrypoint/dotfiles/.claude/CLAUDE.md` → `/root/.claude/CLAUDE.md`** and
   **`.../commands/ → /root/.claude/commands/`** (`CLAUDE_DOTFILES_MOUNT`) —
   the *tracked* layer: cross-project conventions and slash commands,
   version-controlled in this repo. Edits made in a live session flow straight
   back to the git working tree.
3. **`tasks/reference/ → /root/.claude/reference/`** (same variable) — this
   repo's reference docs, mounted so that pointers in the tracked `CLAUDE.md`
   ("read `~/.claude/reference/llm-overused-phrases.md` at session start")
   resolve in **every** session. The docs stay in their conventional
   `tasks/reference/` home; the mount is just an alias.
4. **Host `~/.ai-coding-conventions.personal.md` → `/root/.claude/ai-coding-conventions.personal.md`**
   (`CLAUDE_PERSONAL_MOUNT`, added 2026-08-14) — the *personal overlay*. The tracked
   `CLAUDE.md` ends with `@~/.claude/ai-coding-conventions.personal.md`; the repo ships a **blank** default
   (`entrypoint/dotfiles/.claude/ai-coding-conventions.personal.md`, baked by the Dockerfile `COPY`) so a bare
   `podman run` resolves the import instead of dangling, and `make shell` shadows it with
   the host's `~/.ai-coding-conventions.personal.md` — **`touch`ed if absent at parse time,
   the same idiom as `CLAUDE_CONFIG_MOUNT`'s `mkdir -p` below, and unconditional because
   the `@`-import target must always exist**. This keeps the *tracked* conventions
   maintainer-agnostic while each user's specifics (identity, repo→URL mapping, project
   template, standing authorizations) live only on their host file, never committed. **The
   host and container basenames differ on purpose** — the host file is a hidden dotfile (out
   of the way among the user's dotfiles), while the repo/container copy is un-dotted so the
   baked default and the `.example` template stay visible in `ls`; the bind mount bridges the
   two names. See
   the root `CLAUDE.md` "personal overlay" note, `FORKING.md`,
   `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md`, and
   `tasks/separate-general-and-personal-conventions.md`.

Auth and sessions never live in git; conventions never live only in a container; personal
specifics never live in the tracked repo. That split is the whole design.

## Why the host mount is `mkdir -p`, not an existence check

The other host mounts (`~/.tmux.conf`, `~/.gitconfig`, `~/.gnupg`) are
*conditional* — skipped if absent, correctly, because they're optional
conveniences. `~/.claude` is different: **if the mount silently no-ops, the
whole private layer is written to the container's overlay and dies with the
container.** That actually happened (diagnosed 2026-07-09): the host had no
`~/.claude` (Claude Code had only ever run inside the sandbox), the
`$(shell if [ -d ... ])` evaluated to empty with no warning, and the cost was a
re-sign-in every launch **plus silent loss of agent memory and resumable
sessions** — memory notes written in good faith each session, discarded at exit.

Hence (`Makefile`):

```make
CLAUDE_CONFIG_MOUNT := $(shell mkdir -p $(CLAUDE_CONFIG_DIR); echo "-v $(CLAUDE_CONFIG_DIR):/root/.claude:Z")
```

Two details that matter and are easy to "clean up" into a regression:

- **The `mkdir -p` must live inside the `$(shell …)`.** The variable is
  `:=`-expanded at Makefile *parse* time; a `mkdir` recipe line in the `shell:`
  target would run after the flag was already computed. And `make` runs on the
  host, so this creates the host-side directory itself — no manual step.
- **Do not revert it to an existence check** because it "matches the other
  mounts." The asymmetry is the point: optional mounts may skip; this one must
  never skip.

Caveat: `:Z` relabels host `~/.claude` with a container SELinux type —
harmless to the (unconfined) host user's own processes; `:z`/no flag would also
work since the sandbox runs `label=disable`.

## Why the container stays ephemeral (`--rm`)

Rejected alternatives from the 2026-07-09 incident, kept rejected on purpose:

- **A long-lived / named container** (`podman start` reuse): would persist login
  but sacrifices the fresh-state guarantee, delays image upgrades, and diverges
  from the ephemeral-container template every other project follows.
- **A named volume for `/root/.claude`:** persists but hides state from the
  host filesystem. A plain host directory is inspectable, backupable, and is
  what the layered design already reaches for.

Persistence belongs in *host directories mounted in*, never in the container.

## Editing workflow

- **Conventions / slash commands:** edit `entrypoint/dotfiles/.claude/` (in
  this repo). In a live session the bind mounts make the edit take effect on
  the next read *and* land in the working tree for commit.
- **Reference docs:** edit `tasks/reference/` as usual; same live-mount effect.
- The Dockerfile's `COPY entrypoint/dotfiles/ /root/` matters **only** for
  containers run without the host `~/.claude` mount (e.g. someone else's bare
  `podman run`); in normal `make shell` use, the mounts shadow the baked copy,
  so an image rebuild is *not* needed for config changes.
- Never route secrets through the repo: `.credentials.json` is host-layer only
  (the 2026-07-09 task explicitly declined shuttling it through git — sign in
  fresh instead).

## Related

- `tasks/reference/nested-podman-design.md` — the other big Makefile subsystem.
- Root `CLAUDE.md` "The layered Claude config" — the short operational
  summary of this doc.
