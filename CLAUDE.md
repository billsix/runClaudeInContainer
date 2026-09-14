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
  mounts host `~/.tmux.conf`, `~/.gitconfig`, `~/.gnupg`, `~/.vimrc`, and `~/.claude` (each only
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
`Makefile`). The `CLAUDE.md` holds the user's *cross-project conventions* (which
`@`-import the reference docs and the personal overlay `~/.claude/ai-coding-conventions.personal.md`);
auth, sessions, and credentials come from the host `~/.claude` mount instead. Edit
conventions/commands in `entrypoint/dotfiles/.claude/` and reference docs in
`tasks/reference/` — both flow back to git.

**Auth persistence needs TWO host mounts**, because Claude Code splits its auth state:
`~/.claude/.credentials.json` (OAuth tokens, covered by the `~/.claude` mount,
`CLAUDE_CONFIG_MOUNT`) **and `~/.claude.json`** (onboarding state — a *sibling* of
`~/.claude`, so `CLAUDE_JSON_MOUNT` mounts it separately; without it Claude shows the
"Select login method" menu every launch despite valid credentials). Log in once and it
sticks. Separately, **`CLAUDE_AUTH_ENV`** passes a host `CLAUDE_CODE_OAUTH_TOKEN` (or
`ANTHROPIC_API_KEY`) through with `-e` **only when set** — a long-lived token for
headless/CI/`-p` use that authenticates API calls but does **not** silence the interactive
login menu (never commit it; it lives only in the host env).

This root `CLAUDE.md` is project-specific guidance for working on the container builder,
distinct from the mounted cross-project conventions. The full layering design — the five
mounts and stacking order, the ephemeral-`~/.claude.json` root-cause (diagnosed 2026-08-16,
not token expiry), the onboarding-vs-token distinction, the personal-overlay routing, the
`@`-import history, the `mkdir -p` rationale, and the rejected alternatives — is in
`tasks/reference/claude-config-layering.md`. See also `README.md` ("Auth").

## Host shell vs container shell

Two environments are in play and a command means different things in each, so when you
write instructions for the maintainer, **label them `[HOST]` vs `[CONTAINER]`**. `[HOST]`
is the machine you run `make shell` / `exampleRunClaude.sh` from; `[CONTAINER]` is the
sandbox it launches.

- **The container's interactive shell is bash.** `entrypoint/entrypoint.sh` and
  `entrypoint/shell.sh` both `exec bash`, and root's login shell is `/bin/bash`. (Claude
  Code's own Bash *tool* may run through whatever login shell the *outer* sandbox sets —
  e.g. zsh — which is independent of this image, not this repo's concern.)
- **Guardrail: an env var crosses HOST → CONTAINER only if it is _exported_ on the host.**
  `CLAUDE_AUTH_ENV` and any `-e VAR` passthrough are computed by `$(shell …)` at Makefile
  parse time, which sees only exported vars, and a running container predates a new export.
  The `declare -p` / parse-time mechanism (the usual reason a "set" `CLAUDE_CODE_OAUTH_TOKEN`
  still doesn't reach Claude Code, with the exact confirm/fix steps) is in
  `tasks/reference/claude-config-layering.md` ("Gotcha that bit the maintainer").

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
sandbox: it appends the capability/device flags (`--device /dev/fuse`, `--security-opt
label=disable`/`unmask=ALL`, `--cap-add=sys_admin,mknod,net_admin`, a tmpfs
`/var/lib/containers`, and a tmpfs over `$XDG_RUNTIME_DIR/libpod`) to the `shell` target's
`podman run`, and the inner podman uses `fuse-overlayfs` (configured by
`entrypoint/dotfiles/.config/containers/storage.conf`).

The `/var/lib/containers` tmpfs is **RAM-backed**, defaults to **8g**, and is sized by
`NESTED_PODMAN_TMPFS_SIZE` (e.g. `make shell NESTED_PODMAN=1 NESTED_PODMAN_TMPFS_SIZE=16g`
for a large inner build). A `NESTED_PODMAN=1` launch also exports `NESTED_PODMAN=1` into the
session, so converted project Makefiles auto-apply `--cgroups=disabled` via their
`PODMAN_RUN_FLAGS` variable — the agent runs plain `make image`/`make test` nested and
**never passes `NESTED_PODMAN=1` on a downstream command** (it belongs only on the outermost
host launch).

Why each flag exists (the rootful/netavark `net_admin` and `unmask=ALL` needs, the
`/dev/net/tun` and `libpod`-tmpfs reasons), the `PODMAN_RUN_FLAGS` convention and its
fleet rollout, the lean-image-when-nested rule (downstream projects only, never the two
sandboxes), the two read-only walls (`/proc/sys`, `/sys/fs/cgroup`), the security
trade-off, declined alternatives, and operating lore are in
`tasks/reference/nested-podman-design.md`. (Downstream lean-image scope also:
`tasks/reference/minimal-nested-images.md`; the runCrush client's reverted image coupling:
runCrushInContainer `tasks/reference/nested-podman-vs-image-content.md`.)
