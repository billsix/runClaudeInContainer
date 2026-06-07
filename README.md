# runClaudeInContainer

A Podman-based Fedora dev sandbox for running [Claude Code](https://claude.com/claude-code)
(and doing general development) inside a disposable container, with your host's
Claude configuration, git/GPG identity, and project directories bind-mounted in.

The image is a "batteries-included" Fedora 44 box: compilers and runtimes for a
couple dozen languages, build tooling, debuggers/profilers, graphics dev libraries,
a scientific-Python stack, databases, networking/security tools, and editors — plus
the Claude Code native binary.

## Requirements

- [Podman](https://podman.io/)
- `make`
- A host `~/.claude` directory (for Claude auth/sessions) — optional but recommended
- For GUI apps: an X11 or Wayland session on the host

## Quick start

```sh
make image     # build the OCI image (tagged "claudecontainer")
make shell     # run an interactive shell in an ephemeral (--rm) container
```

Inside the shell you start at `/`, with your current project mounted at
`/<project-dir-name>`. Run `claude` to launch Claude Code.

`make help` lists the available targets.

## How it works

The build (`Dockerfile`):

1. `FROM registry.fedoraproject.org/fedora:44`, then `dnf upgrade`.
2. Copies `entrypoint/dotfiles/` into `/root/` (bash prompt, Emacs config, the
   tracked `.claude/` conventions).
3. `dnf install`s the full toolchain (~300 packages). dnf cache mounts keep
   rebuilds fast.
4. Installs Claude Code via `curl -fsSL https://claude.ai/install.sh | bash`.
5. `ENTRYPOINT` is `/entrypoint.sh` (which just `exec bash`).

The run (`make shell`) mounts, on top of the image:

- The current working directory at `/<project-dir-name>` (`:Z` SELinux relabel).
- Host `~/.tmux.conf`, `~/.gitconfig`, `~/.gnupg`, and `~/.claude` — **only if they
  exist** on the host.
- The repo-tracked `CLAUDE.md` and `commands/` from
  `entrypoint/dotfiles/.claude/`, layered over the host `~/.claude` mount. This
  keeps your conventions and slash commands in version control while auth,
  sessions, and credentials still come from the host mount.
- X11 and Wayland sockets, so GUI programs (Firefox, GTK Emacs, etc.) display on
  the host.

Containers run with `--rm`, so each session is fresh; persistent state lives in the
host directories that are mounted in.

### Mounting extra directories

Use `EXTRA_MOUNTS` to bind additional host paths:

```sh
make shell EXTRA_MOUNTS="-v /home/me/project:/project:Z"
```

`run.sh` is a saved example of this (it mounts a SPIM simulator and assembly-tutorial
directories).

### Building containers inside the sandbox (nested Podman)

`podman` is installed in the image, but running it *inside* the sandbox needs a few
extra flags (overlay-on-overlay under nested user namespaces requires
`fuse-overlayfs`). These are opt-in:

```sh
make shell NESTED_PODMAN=1
```

This adds `--device /dev/fuse`, `--security-opt label=disable`,
`--cap-add=sys_admin,mknod`, and a tmpfs-backed inner image store. The host Podman
stays **rootless** — the container's root is a namespace-mapped unprivileged user, so
nothing here grants privilege on the real host. The inner image store is ephemeral
(tmpfs); pulled images don't persist across sessions.

Quick check inside the shell:

```sh
podman info --format '{{.Store.GraphDriverName}}'   # -> fuse-overlayfs
podman run --rm docker.io/library/alpine echo "nested ok"
```

## Layout

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Image definition (Fedora base + toolchain + Claude Code) |
| `Makefile` | `make image` / `make shell`; host-mount detection; X11/Wayland passthrough |
| `run.sh` | Saved `make shell` invocation with extra mounts |
| `entrypoint/entrypoint.sh` | Image entrypoint (`exec bash`) |
| `entrypoint/shell.sh` | `make shell` launcher (`cd /` then `exec bash`) |
| `entrypoint/dotfiles/` | Files copied into `/root/`: `.extrabashrc`, `.emacs.d/`, `.claude/` |
| `entrypoint/dotfiles/.claude/` | Tracked Claude conventions (`CLAUDE.md`) and slash commands |

## License

Source code under the GNU General Public License v2. Copyright © 2025 William
Emerison Six. See `LICENSE`.
