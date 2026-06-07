# runClaudeInContainer — project notes

This repo builds the **Podman container that Claude Code itself runs in**. When you
work here, you are editing the recipe for your own sandbox. See `README.md` for the
user-facing overview.

## What the pieces do

- **`Dockerfile`** — Fedora 44 base, `dnf upgrade`, copies `entrypoint/dotfiles/`
  into `/root/`, `dnf install`s ~300 packages (the big toolchain list), then
  installs Claude Code via the official `install.sh`. Entrypoint is
  `/entrypoint.sh`.
- **`Makefile`** — the control surface. `make image` builds; `make shell` runs an
  ephemeral (`--rm`) container. It conditionally mounts host `~/.tmux.conf`,
  `~/.gitconfig`, `~/.gnupg`, and `~/.claude` (each only if it exists), mounts the
  CWD at `/<project-dir>`, and sets up X11 + Wayland passthrough.
- **`entrypoint/entrypoint.sh`** — image entrypoint; just `exec bash`.
- **`entrypoint/shell.sh`** — what `make shell` runs; `cd /` then `exec bash`.
- **`entrypoint/dotfiles/`** — copied into `/root/` at build time: `.extrabashrc`
  (prompt, `GPG_TTY`, `ls` alias), `.emacs.d/`, and `.claude/`.
- **`run.sh`** — a saved `make shell` invocation with `EXTRA_MOUNTS` populated.

## The two-layer Claude config

`entrypoint/dotfiles/.claude/CLAUDE.md` and `commands/` are **mounted over** the
host's `~/.claude` at run time (see `CLAUDE_DOTFILES_MOUNT` in the `Makefile`). That
file holds the user's *cross-project conventions* and is version-controlled here;
auth, sessions, and credentials come from the host `~/.claude` mount instead. Edits
to those conventions should be made in `entrypoint/dotfiles/.claude/` so they flow
back to git.

This root `CLAUDE.md` (the one you're reading) is project-specific guidance for
working on the container builder; it is distinct from the mounted cross-project
conventions.

## Conventions for changing this repo

- **The package list is intentionally large.** Don't prune it for "cleanliness" —
  it's a deliberately maximal dev box. Add packages alphabetically to keep the list
  in the `Dockerfile` sorted.
- **Preserve the dnf cache mounts** (`--mount=type=cache,...`) on `dnf` steps; they
  keep rebuilds fast.
- **Keep host mounts conditional.** New host-file mounts in the `Makefile` should
  follow the existing `readlink -f` + existence-test pattern so the build/run still
  works on machines that lack the file.
- **Use `:Z`** on bind mounts for SELinux relabeling, matching the existing mounts.
- After changing the `Makefile`, sanity-check with `make help` and a dry run; after
  changing the `Dockerfile`, a `make image` is the real test (it is slow — full
  toolchain install).

## Housekeeping notes

- `foo.txt` and `faoeuaoeu.txt` in the repo root are scratch/scratchpad files, not
  part of the build. They are not gitignored.
