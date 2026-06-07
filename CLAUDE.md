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

## Nested Podman

`make shell NESTED_PODMAN=1` (opt-in, default off) lets you run `podman` inside the
sandbox. It appends `--device /dev/fuse`, `--device /dev/net/tun`, `--security-opt
label=disable`, `--cap-add=sys_admin,mknod`, a tmpfs `/var/lib/containers`, and a tmpfs
over `$XDG_RUNTIME_DIR/libpod` to the `shell` target's `podman run`. The inner podman
uses `fuse-overlayfs` (configured by
`entrypoint/dotfiles/.config/containers/storage.conf`).

Two non-obvious flags and why they exist:
- **`--device /dev/net/tun`** — rootless networking (pasta) opens `/dev/net/tun`;
  without it `podman run` fails at network setup (`--network=none` would still work).
- **tmpfs over `$XDG_RUNTIME_DIR/libpod`** — the host's `$XDG_RUNTIME_DIR`
  (`/run/user/<uid>`) is bind-mounted in for Wayland/Pulse, and it carries the *host*
  podman's `libpod/tmp/pause.pid` pointing at a host PID. Without shadowing it, the
  inner podman tries to join that nonexistent PID's userns and dies with `cannot
  re-exec process to join the existing user namespace`. The tmpfs gives it a clean
  state dir while leaving the Wayland/Pulse sockets in the rest of the dir intact.
  (subuid/subgid are *not* needed — inner podman runs rootful-in-userns.)

Security trade-off: the host Podman is **rootless** (container-root maps to host UID
1000, never host root), and this stays true with the flags on — even `--privileged`
under a rootless host only grants privilege within the user namespace. The costs are
SELinux disabled for that container, a broad `sys_admin` capability (namespace-confined),
and slower/ephemeral nested storage. Full rationale and declined alternatives are in
`tasks/nested-podman.md` (or its archive).

## Housekeeping notes

- `foo.txt` and `faoeuaoeu.txt` in the repo root are scratch/scratchpad files, not
  part of the build. They are not gitignored.
