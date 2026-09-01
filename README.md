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

## Auth — staying logged in

**Log in through the browser once, and it sticks.** `make shell` bind-mounts the **two**
files Claude Code keeps its auth in, so a fresh browser login is needed only rarely (roughly
monthly, or after `/logout`) — not every run:

1. **`~/.claude/` — your credentials & sessions.** Holds `.credentials.json` (the OAuth
   tokens, which auto-refresh), your sessions, and agent memory. Persisting it is the fix from
   `tasks/archive/2026/07/09/persist-claude-login-across-containers.md` (before it, the mount
   silently no-op'd and you re-signed-in every time).

2. **`~/.claude.json` — your onboarding state.** Holds `hasCompletedOnboarding` and your
   account info. It's a **sibling** of `~/.claude`, so the mount above doesn't cover it; left
   unmounted it died with each `--rm` container, and Claude — seeing no onboarding record —
   showed the **"Select login method"** menu on *every* launch, even with valid credentials
   mounted. `make shell` now bind-mounts it too (seeding an empty `{}` on the host the first
   time), so onboarding persists. **This, not token expiry, was the real "log in every
   session" cause.** Both files are created for you on first `make shell`.

Both mounts are automatic — sign in once and you're done.

### Optional: a long-lived token for headless / scripted use

If you run Claude Code **non-interactively** (`claude -p "…"`, CI, cron) and want auth
independent of the mounted login, generate a ~1-year token. **This is not needed for the
interactive login above** — and it does *not* silence the interactive menu (that menu is
gated on onboarding state, item 2 above, not on this token):

```sh
claude setup-token                    # prints a token; uses your existing SUBSCRIPTION
# then add to your ~/.bashrc / ~/.zshrc so it's always set:
export CLAUDE_CODE_OAUTH_TOKEN=...
```

The env var name is **`CLAUDE_CODE_OAUTH_TOKEN`** (same on host and in the container). It is
read from your host environment and **never stored in this repo**. `make shell` only adds the
`-e` passthrough when the variable is actually set, so leaving it unset changes nothing.
*(Forks that bill per-token instead of a subscription can export `ANTHROPIC_API_KEY` instead —
also passed through — but that uses the metered Console API, not a subscription.)* Until a
token is set, `make shell` prints a one-line reminder at startup. A token crosses to the
container only if it's **exported** (`declare -p CLAUDE_CODE_OAUTH_TOKEN` shows `declare -x`,
not `--`) and only a **fresh** sandbox picks up a new export.

## Quick start

```sh
make image                  # build the OCI image (tagged "claudecontainer")
make shell                  # interactive shell in an ephemeral (--rm) container
make shell NESTED_PODMAN=1  # ^ same, but also able to run `podman` inside the sandbox
make shell-exec SCRIPT=path/to/script.sh   # run a script in that same env (no TTY), then exit
make shell-exec CMD='some command'         # ^ or an inline command
```

Inside the shell you start at `/`, with your current project mounted at
`/<project-dir-name>`. Run `claude` to launch Claude Code.

`make shell-exec` is the batch twin of `make shell`: the same container and mounts (graphics
and `NESTED_PODMAN=1` included), but it runs a script (`SCRIPT=`, repo-relative, run from the
repo root) or an inline `CMD=` and exits, instead of dropping you into bash — for ad-hoc or CI
use. `SCRIPT=` is best for anything non-trivial; `CMD=` is for simple one-liners (a `$VAR` in
`CMD=` expands on the host, and single quotes in it need care).

To run containers *inside* the sandbox (podman-in-podman), add `NESTED_PODMAN=1` —
see [Building containers inside the sandbox](#building-containers-inside-the-sandbox-nested-podman).

`make help` lists the available targets.

**Forking this for your own use?** See `FORKING.md`. In short: put your personal
conventions in `~/.ai-coding-conventions.personal.md` (copy the template from
`entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md`), swap the dotfiles, and build with
`make image USE_EMACS_CONFIG=0` if you don't want the vendored Emacs config.

## How it works

The build (`Dockerfile`):

1. `FROM registry.fedoraproject.org/fedora:44`, then `dnf upgrade`.
2. Copies `entrypoint/dotfiles/` into `/root/` (bash prompt, Emacs config, the
   tracked `.claude/` conventions).
3. Runs `entrypoint/01-install-base.sh` to `dnf install` the full toolchain
   (~430 packages). The package list lives in that script — host-runnable on its
   own (`sudo ./entrypoint/01-install-base.sh` on a bare Fedora box), not just at
   build time — while the dnf cache mounts (which keep rebuilds fast) stay in the
   `Dockerfile`.
4. Installs Claude Code via `curl -fsSL https://claude.ai/install.sh | bash`.
5. `ENTRYPOINT` is `/entrypoint.sh` (which just `exec bash`).

The run (`make shell`) mounts, on top of the image:

- The current working directory at `/<project-dir-name>` (`:Z` SELinux relabel).
- Host `~/.tmux.conf`, `~/.gitconfig`, `~/.gnupg`, and `~/.claude` — **only if they
  exist** on the host.
- The repo-tracked `CLAUDE.md` and `commands/` from
  `entrypoint/dotfiles/.claude/`, layered over the host `~/.claude` mount, plus
  this repo's `tasks/reference/` at `~/.claude/reference/` (reference docs the
  `CLAUDE.md` `@`-imports into every session — the overused-words catalog plus the
  nested-podman, sandbox-capability-map, config-layering, and print-debugging docs). This keeps your
  conventions, slash commands, and those reference docs
  in version control while auth, sessions, and credentials still come from the
  host mount.
- Your **personal overlay**: the tracked `CLAUDE.md` `@`-imports
  `~/.claude/ai-coding-conventions.personal.md`, over which `make shell` mounts your host's
  `~/.ai-coding-conventions.personal.md` (auto-created empty if absent). This is where
  your own identity, project→URL mapping, and mount layout go, so the portable
  conventions stay maintainer-agnostic. See `FORKING.md` and
  `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md`.
- X11 and Wayland sockets, so GUI programs (GTK Emacs, etc.) display on
  the host.

Containers run with `--rm`, so each session is fresh; persistent state lives in the
host directories that are mounted in.

### Mounting extra directories

Use `EXTRA_MOUNTS` to bind additional host paths:

```sh
make shell EXTRA_MOUNTS="-v /home/me/project:/project:z"
```

> **Use `:z` or no label flag — never `:Z`.** The sandbox runs
> `--security-opt label=disable`, so `:Z` gains it nothing — but it still
> relabels the mounted host directory with this container's private SELinux
> category pair, which locks every normal *confined* container (e.g. a
> `podman build` of that repo on the host) out of those files until you run
> `sudo restorecon -R <dir>`.

`exampleRunClaude.sh` is a saved example of this (nested Podman enabled, mounting
several host directories). Its paths are the maintainer's — edit them for your own
use; see `FORKING.md`.

### Building containers inside the sandbox (nested Podman)

`podman` is installed in the image, but running it *inside* the sandbox needs a few
extra flags (overlay-on-overlay under nested user namespaces requires
`fuse-overlayfs`). These are opt-in:

```sh
make shell NESTED_PODMAN=1
```

This adds `--device /dev/fuse` (overlay storage), `--device /dev/net/tun` (rootless
networking via pasta), `--security-opt label=disable`, `--security-opt unmask=ALL` (so the
inner netavark can write the per-interface sysctls that bridged networking needs — the
sandbox's `/proc/sys` is otherwise read-only), `--cap-add=sys_admin,mknod,net_admin`, a
tmpfs-backed inner image store, and a tmpfs over the host runtime dir's `libpod` state
(so the inner podman doesn't trip over the *host* podman's leftover state — see note
below). The host Podman stays **rootless** — the container's root is a namespace-mapped
unprivileged user, so nothing here grants privilege on the real host. The inner image
store is ephemeral (tmpfs); pulled images don't persist across sessions. That tmpfs
defaults to **8g** and is RAM-backed; raise it for a large inner build with
`make shell NESTED_PODMAN=1 NESTED_PODMAN_TMPFS_SIZE=16g`.

**Test it — run Podman inside the container:**

```sh
podman info --format '{{.Store.GraphDriverName}}'   # -> overlay (driven by fuse-overlayfs)

# full path — pull (networking) + unpack (fuse-overlayfs) + run, with a bind mount:
podman run --rm -it --cgroups=disabled -v "$(pwd)":/workspace:Z ubuntu:latest bash
```

`--cgroups=disabled` was historically **required** on every inner run (the sandbox's
`/sys/fs/cgroup` was mounted read-only, so crun failed with
`/sys/fs/cgroup/cgroup.subtree_control: Read-only file system`); on current host stacks
cgroup2 mounts rw and it's optional, but it stays harmless — keep it for portability.
Project Makefiles converted to the `PODMAN_RUN_FLAGS` convention apply it automatically
inside the sandbox (which exports `NESTED_PODMAN=1`) and stay flag-free on a host — see
`tasks/reference/nested-podman-design.md`.

The run above leaves networking at the **default (bridged/netavark)** path, which is
**verified working** — `apt update` inside a nested `ubuntu` reaches the network end-to-end.
That path needs the inner netavark to write per-interface sysctls under `/proc/sys`, which the
sandbox mounts read-only; `--security-opt unmask=ALL` (in the `NESTED_PODMAN=1` flag set) is what
unmasks it. You don't need any `--network` flag. If you ever hit
`netavark: set sysctl ... Read-only file system` (e.g. on a host where `unmask=ALL` didn't take),
`--network=host` is a working fallback:

```sh
podman run --rm -it --network=host --cgroups=disabled -v "$(pwd)":/workspace:Z ubuntu:latest bash
```

For a deeper smoke test you can even build this repo's own image from within the
sandbox: `podman build -t selftest .`.

> **Note:** you must launch with `NESTED_PODMAN=1`. A plain `make shell` won't have
> `/dev/fuse` or the capabilities, and `podman run` will fail. The `NESTED_PODMAN=1`
> flag set is also what shadows the host's bind-mounted `$XDG_RUNTIME_DIR/libpod`;
> without that shadow the inner podman fails with `cannot re-exec process to join the
> existing user namespace` because it finds the host podman's stale `pause.pid`.

## Layout

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Image definition (Fedora base + toolchain + Claude Code) |
| `Makefile` | `make image` / `make shell` / `make shell-exec` (shared `SHELL_RUN_FLAGS`); host-mount detection; X11/Wayland passthrough |
| `exampleRunClaude.sh` | Saved `make shell` invocation with extra mounts |
| `entrypoint/01-install-base.sh` | The ~430-package `dnf install`, host-runnable; the Dockerfile sources it |
| `entrypoint/entrypoint.sh` | Image entrypoint (`exec bash`) |
| `entrypoint/shell.sh` | `make shell` / `make shell-exec` launcher (`set -e` setup, then `exec bash "$@"`) |
| `entrypoint/dotfiles/` | Files copied into `/root/`: `.extrabashrc`, `.emacs.d/`, `.claude/` |
| `entrypoint/dotfiles/.claude/` | Tracked Claude conventions (`CLAUDE.md`) and slash commands |
| `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.md` | Blank personal-overlay default (`@`-imported; your host file mounts over it) |
| `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md` | Template for your `~/.ai-coding-conventions.personal.md` |
| `tasks/reference/` | Reference docs, mounted at `~/.claude/reference/` for the conventions to cite |
| `FORKING.md` | What to change when adopting this sandbox for your own use |

## License

Source code under the GNU General Public License v2. Copyright © 2025 William
Emerison Six. See `LICENSE`.
