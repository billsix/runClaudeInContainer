# runClaudeInContainer — project notes

This repo builds the **Podman container that Claude Code itself runs in** — a tool for
**developing your other codebases with Claude Code in a disposable container**. Its job
is two-fold: **run the agent** (pointed at whatever project you mount in), and **deliver
to the agent the conventions** that teach it how your projects are structured and built —
the layered `CLAUDE.md` + your personal overlay (`ai-coding-conventions.personal.md`) + the reference docs (see "The
layered Claude config"). When you work here, you are editing the recipe for your own
sandbox — the *runner*, not a template for the codebases you build with it (those follow
the container-per-project conventions the agent is taught, which live in the personal
overlay). See `README.md` for the user-facing overview.

## What the pieces do

- **`Dockerfile`** — Fedora 44 base, `dnf upgrade`, copies `entrypoint/dotfiles/`
  into `/root/`, then runs **`entrypoint/01-install-base.sh`** (the ~430-package
  toolchain — a host-runnable script the Dockerfile sources, not an inline
  `dnf install`), then installs Claude Code via the official `install.sh`. Entrypoint is
  `/entrypoint.sh`.
- **`Makefile`** — the control surface. `make image` builds; `make shell` runs an
  ephemeral (`--rm`) container; **`make shell-exec SCRIPT=… | CMD=…`** is its batch
  twin (runs a script/command in the same env, no TTY). `shell` and `shell-exec`
  share one **`SHELL_RUN_FLAGS`** variable so they can't drift. It conditionally
  mounts host `~/.tmux.conf`, `~/.gitconfig`, `~/.gnupg`, and `~/.claude` (each only
  if it exists), mounts the CWD at `/<project-dir>`, and sets up X11 + Wayland
  passthrough.
- **`entrypoint/entrypoint.sh`** — image entrypoint; just `exec bash`.
- **`entrypoint/shell.sh`** — what `make shell` / `make shell-exec` run; `set -e`,
  `cd /`, then **`exec bash "$@"`** (interactive with no args; runs the `shell-exec`
  payload otherwise).
- **`entrypoint/dotfiles/`** — copied into `/root/` at build time: `.extrabashrc`
  (prompt, `GPG_TTY`, `ls` alias), `.emacs.d/`, and `.claude/`.
- **`exampleRunClaude.sh`** — a saved `make shell` invocation with `NESTED_PODMAN=1`
  and `EXTRA_MOUNTS` populated.

## The layered Claude config

`entrypoint/dotfiles/.claude/CLAUDE.md` and `commands/` are **mounted over** the
host's `~/.claude` at run time, and this repo's `tasks/reference/` is mounted at
`~/.claude/reference/` alongside them (see `CLAUDE_DOTFILES_MOUNT` in the
`Makefile`). The `CLAUDE.md` holds the user's *cross-project conventions* and is
version-controlled here; auth, sessions, and credentials come from the host
`~/.claude` mount instead. **Auth persistence needs TWO host mounts, because Claude Code
splits its auth state across two files:** `~/.claude/.credentials.json` (OAuth tokens —
covered by the `~/.claude` mount, `CLAUDE_CONFIG_MOUNT`) **and `~/.claude.json`**
(onboarding state: `hasCompletedOnboarding`, account info). The latter is a *sibling* of
`~/.claude`, so the dir mount misses it; unmounted it dies with the `--rm` container, and
Claude — seeing no onboarding record — shows the "Select login method" menu on **every**
launch despite valid mounted credentials. `CLAUDE_JSON_MOUNT` (in the `Makefile`) fixes this
by seeding host `~/.claude.json` to `{}` if absent and bind-mounting it; log in once and it
sticks. **This ephemeral-`~/.claude.json` issue — not token expiry — was the real "log in
every session" cause** (diagnosed 2026-08-16; see
`tasks/archive/2026/08/16/long-lived-auth-token-env-var.md`). Separately, **`CLAUDE_AUTH_ENV`** passes a host
`CLAUDE_CODE_OAUTH_TOKEN` (or `ANTHROPIC_API_KEY`) through with `-e` **only when set** — a
long-lived `claude setup-token` token for **headless/CI/`-p`** use; it authenticates API
calls but does **not** silence the interactive login menu (that's gated on onboarding state,
above), so it is not the fix for interactive re-logins. `entrypoint/shell.sh` prints a setup
hint until it's set. Never commit the token; it lives only in the host env. See README.md
("Auth") and the archived `persist-claude-login-across-containers.md`.
The `tasks/reference/` mount exists because the mounted
`CLAUDE.md` **`@`-imports all five reference docs** (the overused-words catalog plus the
nested-podman, sandbox-capability-map, config-layering, and print-debugging docs), so their
content is inlined into every session — which means those paths must resolve in the container
(2026-08-02: the three sandbox/config docs were promoted from read-on-demand to auto-import;
2026-08-13: print-debugging joined them). Edits to the
conventions or commands go in `entrypoint/dotfiles/.claude/`; the reference docs are
edited in `tasks/reference/` as usual — both flow back to git.

The mounted `CLAUDE.md` also `@`-imports **`~/.claude/ai-coding-conventions.personal.md`**, a personal
overlay that keeps maintainer-specific content (identity, project→URL mapping, project
template, standing authorizations) out of the portable conventions. The tracked default
`entrypoint/dotfiles/.claude/ai-coding-conventions.personal.md` is **blank**; `make shell` mounts the host's
`~/.ai-coding-conventions.personal.md` over it (auto-`touch`ed if absent). This is what lets
a fork adopt the portable conventions and swap in its own personal layer — see
`FORKING.md`, `ai-coding-conventions.personal.example.md`, and `tasks/separate-general-and-personal-conventions.md`.
The mounted `CLAUDE.md`'s opening section (**"This is the SHARED layer…"**) instructs the
agent to route any maintainer-specific content to this overlay, never to the shared file,
so the separation stays self-maintaining.

This root `CLAUDE.md` (the one you're reading) is project-specific guidance for
working on the container builder; it is distinct from the mounted cross-project
conventions. The full layering design — what persists where, the `mkdir -p`
rationale, and the rejected alternatives — is in
`tasks/reference/claude-config-layering.md`.

## Host shell vs container shell

Two environments are in play and a command means different things in each, so when you
write instructions for the maintainer, **label them `[HOST]` vs `[CONTAINER]`**. `[HOST]`
is the machine you run `make shell` / `exampleRunClaude.sh` from; `[CONTAINER]` is the
sandbox it launches.

- **The container's interactive shell is bash.** `entrypoint/entrypoint.sh` and
  `entrypoint/shell.sh` both `exec bash`, and root's login shell is `/bin/bash`. (Claude
  Code's own Bash *tool* may run through whatever login shell the *outer* sandbox happens
  to set — e.g. `$SHELL=/usr/bin/zsh` in some sandboxes — which is independent of this
  image and is the cross-project note's concern, not this repo's.)
- **An env var crosses HOST → CONTAINER only if it is _exported_ on the host.** The
  `Makefile`'s `CLAUDE_AUTH_ENV` (and any `-e VAR` passthrough) is computed by
  `$(shell …)` at parse time, and that subshell inherits only **exported** variables. A
  var that is merely *set* — `echo ${#VAR}` prints a length, but `declare -p VAR` shows no
  `-x` — is invisible to make, so the flag is never added and the container never sees it.
  This is the usual reason a `CLAUDE_CODE_OAUTH_TOKEN` "that's set" still doesn't reach
  Claude Code. Fix: put `export VAR=…` in the host shell's rc (`~/.bashrc` for bash),
  start a fresh shell, and confirm with `make -n shell | grep -- '-e VAR'` **[HOST]**
  before launching — a fresh `make shell` is required, since a running container predates
  the export.

## Conventions for changing this repo

- **The package list is intentionally large.** Don't prune it for "cleanliness" —
  it's a deliberately maximal dev box. Add packages alphabetically to keep the list
  in **`entrypoint/01-install-base.sh`** sorted (the list lives in that host-runnable
  script now, not inline in the `Dockerfile` — per the cross-project convention
  "Host-agnostic setup belongs in a script the Dockerfile sources"). This repo has a
  single package group, so there's just the one `01-install-base.sh` (no per-feature
  install scripts). Its one build flag is **`USE_EMACS_CONFIG`** (Makefile default `1`,
  Dockerfile ARG default `0` per fleet convention): `make image USE_EMACS_CONFIG=0`
  drops the vendored `.emacs.d/` for a clean box — used by forks that don't want the
  maintainer's Emacs setup.
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
label=disable`, `--security-opt unmask=ALL`, `--cap-add=sys_admin,mknod,net_admin`, a
tmpfs `/var/lib/containers`, and a tmpfs over `$XDG_RUNTIME_DIR/libpod` to the `shell`
target's `podman run`. The inner podman uses `fuse-overlayfs` (configured by
`entrypoint/dotfiles/.config/containers/storage.conf`).

The `/var/lib/containers` tmpfs defaults to **8g** and is **RAM-backed** (it only
uses memory as inner images are written, but a full store costs that much RAM+swap).
Bump it for a large inner build via `NESTED_PODMAN_TMPFS_SIZE`, e.g.
`make shell NESTED_PODMAN=1 NESTED_PODMAN_TMPFS_SIZE=16g`.

**Inner runs and `--cgroups=disabled` — the `PODMAN_RUN_FLAGS` convention (2026-08-29).**
Historically the sandbox's `/sys/fs/cgroup` was mounted read-only (and `--cgroupns=private`
did *not* make it writable), so every inner `podman run` failed without `--cgroups=disabled`;
on the current host stack cgroup2 mounts rw and flagless inner runs work, but the flag is
kept as harmless belt-and-braces. A `NESTED_PODMAN=1` launch now exports `NESTED_PODMAN=1`
into the session, and converted project Makefiles auto-apply the flag via
`PODMAN_RUN_FLAGS ?= $(if $(filter 1,$(NESTED_PODMAN)),--cgroups=disabled)` on their `run`
lines — so containerized targets Just Work nested and are unchanged on a host. Design: `tasks/reference/nested-podman-design.md`; rollout completed fleet-wide
2026-08-29 (work record:
`tasks/archive/2026/08/29/nested-podman-run-flags-passthrough.md`).

Non-obvious flags and why they exist:
- **`--cap-add=...,net_admin`** — the inner podman runs *rootful* (container-root), so it
  uses the **netavark** backend, which builds a bridge + veth over netlink and needs
  `CAP_NET_ADMIN`. Without it: `netavark: Netlink error: Operation not permitted`.
  (netavark + aardvark-dns ship in `/usr/libexec/podman/`, not on `$PATH`.)
- **`--security-opt unmask=ALL`** — netavark also writes per-interface sysctls
  (e.g. `net/ipv4/conf/eth0/arp_notify`) bringing up the bridge, but the sandbox's
  `/proc/sys` is read-only, so even with `CAP_NET_ADMIN` that write fails and bridged
  networking breaks. Unmasking lets the inner netavark write them. *(Host-verified
  2026-06-07: bridged networking works end-to-end — `apt update` in a nested `ubuntu`
  reached the network with no `--network` flag. `--network=host` remains a fallback.)*
- **`--device /dev/net/tun`** — rootless networking (pasta) opens `/dev/net/tun`;
  without it `podman run` fails at network setup (`--network=none` would still work).
  Retained for the rootless/pasta path; the rootful netavark path above does not use it.
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
SELinux disabled for that container (`label=disable` + `unmask=ALL`), broad
`sys_admin`/`net_admin` capabilities (namespace-confined), and slower/ephemeral nested
storage. Full rationale, declined alternatives, and operating lore are in
`tasks/reference/nested-podman-design.md`.
