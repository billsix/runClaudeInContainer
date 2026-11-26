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

- **`Dockerfile`** — least-volatile layers first: Fedora 45 base and `dnf upgrade`;
  **`entrypoint/01-install-base.sh`** (the ~460-package toolchain — a host-runnable script
  the Dockerfile sources, not an inline `dnf install`); `entrypoint/01b-install-binary-tools.sh`
  (shfmt, procs); Claude Code via the official `install.sh`; Lean via
  `entrypoint/install-lean.sh`; then the often-edited part: `entrypoint/dotfiles/` into `/root/`,
  the nested podman's `storage.conf` / `containers.conf` drop-ins, and the `USE_EMACS_CONFIG`
  opt-out. Entrypoint is `/entrypoint.sh`.
- **`Makefile`** — the control surface. `make image` builds; `make shell` runs an
  ephemeral (`--rm`) container; **`make shell-exec SCRIPT=… | CMD=…`** is its batch
  twin (runs a script/command in the same env, no TTY). `shell` and `shell-exec`
  share one **`SHELL_RUN_FLAGS`** variable so they can't drift. It conditionally
  mounts host `~/.tmux.conf`, `~/.gitconfig`, `~/.gnupg` and `~/.vimrc` (each only if it
  exists) and always `~/.claude` and `~/.claude.json` (created if missing), mounts the CWD at `/<project-dir>`, and sets up X11 + Wayland
  passthrough.
- **`entrypoint/entrypoint.sh`** — image entrypoint; just `exec bash`.
- **`entrypoint/shell.sh`** — what `make shell` / `make shell-exec` run; `set -e`,
  `cd /`, then **`exec bash "$@"`** (interactive with no args; runs the `shell-exec`
  payload otherwise).
- **`entrypoint/dotfiles/`** — copied into `/root/` at build time: `.extrabashrc`
  (prompt, `GPG_TTY`, `ls` alias), `.emacs.d/`, and `.claude/`.
- **`exampleRunClaude.sh`** — a saved `make shell` invocation with `NESTED_PODMAN=1`
  and `EXTRA_PODMAN_FLAGS` populated.
- **`tools/`** — repo tools, not copied into the image. `check_helm_file_at_point.{sh,el}` is an ERT
  check that a vendored `.emacs.d`'s `C-x C-f` prefills a repo-root-relative doc path from any depth
  (`bash tools/check_helm_file_at_point.sh <.emacs.d>`; needs that config's `elpa/`). runCrushInContainer
  mirrors it byte-identically. The contract it checks: `tasks/reference/emacs-container-contract.md`.

## The layered Claude config

`entrypoint/dotfiles/.claude/CLAUDE.md` and `commands/` are **mounted over** the
host's `~/.claude` at run time, and this repo's `tasks/reference/` is mounted at
`~/.claude/reference/` alongside them (see `CLAUDE_DOTFILES_MOUNT` in the
`Makefile`). The `CLAUDE.md` holds the user's *cross-project conventions* (which
reference the topic docs **read-on-demand** at task triggers, and `@`-import only the
diversion stack and the personal overlay `~/.claude/ai-coding-conventions.personal.md`);
auth, sessions, and credentials come from the host `~/.claude` mount instead. Edit
conventions/commands in `entrypoint/dotfiles/.claude/` and reference docs in
`tasks/reference/` — both flow back to git.

Besides docs, `tasks/reference/` also holds a few **SHARED, VENDORED tool scripts** — currently
`check_local_annotations.py` (the Python annotate-every-binding gate), `c_dispatch_check.py` (the C
dispatch-rules checker, `c-coding-standard.md` "Dispatch"), `c_designated_init_check.py` (the C
positional-struct-initializer checker, "Structs, constants, and the preprocessor") and
`update_dep_common.sh` (the source-dep re-vendor helper; pattern in
`tasks/reference/vendoring-third-party-source-deps.md`).
Each carries a `SHARED, VENDORED TOOL` banner and is **copied into downstream projects' `tools/`**;
this repo holds the **canonical** copy, so edit it here and re-copy over every vendored copy
(runCrush mirrors all four byte-identically). `review_status.py` is another shared tool, but it is
**run in place** (`python3 ~/.claude/reference/review_status.py`, by `/review-status` and
`/audit-repo deep`), not copied into projects; runCrush mirrors it byte-identically too. So are
`nest_one_caller.py` (nests a Python helper that has one caller) and `survey_names_and_scope.py`
(lists leads for the naming and scope rules in Rust, C++, C, Haskell, bash and JavaScript; the rules
are each language standard's "Locals and helpers" section).

**Where the vendored copies are (2026-11-16):**
- `check_local_annotations.py`: github.com/billsix/modelviewprojection, github.com/billsix/methodfinder
  and github.com/billsix/spimulator `tools/`; github.com/billsix/impo `openstax/tooling/tools/`.
- `c_dispatch_check.py` and `c_designated_init_check.py`: spimulator `tools/`.
- `update_dep_common.sh`: github.com/billsix/Craft `tools/`.

Copies drift silently, since nothing compares them with the canonical. After editing a tool here,
`git ls-files | grep <tool>` in each mounted repo, then `cmp` each hit against the canonical. The
2026-11-16 re-copy found five stale copies this way:
`tasks/archive/2026/11/16/recopy-check-local-annotations-to-vendored-copies.md`.

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

## Reviews

Latest deep review: `tasks/review/2026/11/15/repo-review.md` (first review; includes the nested-storage
research). Records are frozen; act on them through tasks.

**A task here may span three repos** (William Emerison Six <billsix@gmail.com>, 2026-11-15):
github.com/billsix/runCrushInContainer is the open-source-tools sibling of this sandbox, and the
maintainer mirrors this repo's changes into it as far as is reasonable. The personal overlay
(github.com/billsix/dotfiles `.ai-coding-conventions.personal.md`) is loaded by both. So a task made
from a review finding here (or any convention change) may also edit runCrush and that overlay, and
should say which of the three it touches. runCrush keeps its own review records in its own
`tasks/review/`.

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
- **Never `:Z` on a host tree.** The sandbox runs `--security-opt label=disable`, so `:Z` gains
  nothing and relabels the host directory with this container's private category, locking other
  confined containers out of it. Use `:z` or no label (README, "Mounting extra directories").
- After changing the `Makefile`, sanity-check with `make help` and a dry run; after
  changing the `Dockerfile`, a `make image` is the real test (it is slow — full
  toolchain install).

## Nested Podman

`make shell NESTED_PODMAN=1` (opt-in, default off) lets you run `podman` inside the
sandbox: it appends the capability/device flags (`--device /dev/fuse`, `--security-opt
label=disable`/`unmask=ALL`, `--cap-add=sys_admin,mknod,net_admin`, the inner image store at
`/var/lib/containers`, and a tmpfs over `$XDG_RUNTIME_DIR/libpod`) to the `shell` target's
`podman run`. The inner podman uses **native kernel overlay** (`entrypoint/dotfiles/.config/containers/storage.conf`,
no `mount_program`), with buildah's temp dir on the store volume
(`entrypoint/dotfiles/.config/containers/containers.conf`); a layer commit costs what it does on the
host. `entrypoint/shell.sh` warns at start when podman reports no native overlay diff (an image
built before the switch). Detail: `tasks/reference/nested-run-and-gates.md` ("Storage speed").

**The inner store has two backends, toggled by `NESTED_PODMAN_STORE`:**
- `dir` (default): an ephemeral directory on the host disk, created under
  `NESTED_PODMAN_STORE_BASE` (default `~/.cache`; point it at another disk to spare an SSD) and
  removed on exit by an `EXIT INT TERM HUP` trap (`podman unshare rm -rf`).
- `tmpfs`: a RAM store sized by `NESTED_PODMAN_TMPFS_SIZE` (default `8g`), e.g.
  `make shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=tmpfs NESTED_PODMAN_TMPFS_SIZE=16g`. Bounded by
  RAM; a full-toolchain image needs well over 8g. `exampleRunClaude.sh` carries this as a
  commented-out alternative to the disk-store line.

Either way the host image store is mounted read-only at `/var/lib/shared-images`
(`additionalimagestores`), so nested builds reuse host-built images. **The store config is
installed as a drop-in too, not only as a main `storage.conf`:** containers-common's
`/usr/share/containers/storage.rootful.conf.d/00-vendor-rootful.conf` resets
`additionalimagestores` and turns on `metacopy` (which native overlay rejects in a user namespace),
so the Dockerfile installs our file as `/etc/containers/storage.conf.d/50-runclaude-nested.conf`,
and `entrypoint/shell.sh` warns when the mounted host store is not in use. Detail:
`tasks/reference/nested-podman-design.md` ("Which storage config the nested podman reads").

A `NESTED_PODMAN=1` launch also exports `NESTED_PODMAN=1` into the session, so converted project
Makefiles auto-apply `--cgroups=disabled` via their `PODMAN_RUN_FLAGS` variable — the agent runs
plain `make image`/`make test` nested and **never passes `NESTED_PODMAN=1` on a downstream
command** (it belongs only on the outermost host launch).

For the **whole build-and-storage pipeline** — the two podman levels (host `make image` vs
nested podman inside the sandbox) and where every image layer is written / how to reclaim
disk — see `tasks/reference/image-build-and-storage-pipeline.md`.

Why each flag exists (the rootful/netavark `net_admin` and `unmask=ALL` needs, the
`/dev/net/tun` and `libpod`-tmpfs reasons), the `PODMAN_RUN_FLAGS` convention and its
fleet rollout, the lean-image-when-nested rule (downstream projects only, never the two
sandboxes), the two read-only walls (`/proc/sys`, `/sys/fs/cgroup`), the security
trade-off, declined alternatives, and operating lore are in
`tasks/reference/nested-podman-design.md`. (Downstream lean-image scope also:
`tasks/reference/minimal-nested-images.md`; the runCrush client's reverted image coupling:
runCrushInContainer `tasks/reference/nested-podman-vs-image-content.md`.)
