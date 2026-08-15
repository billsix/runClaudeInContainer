.DEFAULT_GOAL := help

# ============================================================================
#  make image                 build the OCI image
#  make shell                 interactive shell in an ephemeral container
#  make shell NESTED_PODMAN=1 ^ same, but ALSO able to run `podman` inside the
#                               sandbox (podman-in-podman). Opt-in; see below.
#  make shell EXTRA_MOUNTS="-v /host/path:/path:Z"   bind extra host dirs
# ============================================================================

CONTAINER_CMD = podman
CONTAINER_NAME = claudecontainer

EXTRA_MOUNTS ?=

# Opt-in nested Podman (run `podman` inside the sandbox). Off by default to keep
# normal sessions minimal. The host podman stays rootless either way: these flags
# only let the container's (already unprivileged, namespace-mapped) root drive an
# inner podman via fuse-overlayfs. No privilege is granted on the real host.
#   usage: make shell NESTED_PODMAN=1
NESTED_PODMAN ?= 0
# Size of the tmpfs backing the inner podman image store (/var/lib/containers).
# It is RAM-backed (only consumes memory as images are written, but a full store
# costs that much RAM + swap), so the default is a lean 8g. Override per-run for a
# bigger inner build, e.g.:  make shell NESTED_PODMAN=1 NESTED_PODMAN_TMPFS_SIZE=16g
NESTED_PODMAN_TMPFS_SIZE ?= 8g
ifeq ($(NESTED_PODMAN),1)
# The host's $XDG_RUNTIME_DIR is bind-mounted in for Wayland/Pulse passthrough, and it
# carries the *host* podman's rootless state (libpod/tmp/pause.pid -> a host PID). The
# inner podman would try to setns-join that nonexistent PID's userns and die with
# "cannot re-exec process to join the existing user namespace". Shadow just the libpod
# state dir with an empty tmpfs so the inner podman starts clean; the Wayland/Pulse
# sockets in the rest of the dir are untouched.
NESTED_PODMAN_RUNTIME_TMPFS := $(if $(XDG_RUNTIME_DIR),--tmpfs $(XDG_RUNTIME_DIR)/libpod:rw)
# The inner podman runs *rootful* (container-root), so it uses the netavark backend,
# not pasta/slirp4netns (those are rootless-only). netavark configures a bridge + veth
# over netlink, which needs CAP_NET_ADMIN -> without it you get
# "netavark: Netlink error: Operation not permitted". Hence net_admin below.
# netavark also writes per-interface sysctls (e.g. net/ipv4/conf/eth0/arp_notify) when it
# brings up the bridge. The sandbox's /proc/sys is mounted read-only by the outer podman,
# so even with CAP_NET_ADMIN that write fails ("set sysctl ...: Read-only file system") and
# bridged networking breaks. --security-opt unmask=ALL unmasks /proc/sys (and friends) so
# the inner netavark can write them. Verified: without it, only --network=host works.
# cgroup v2: the sandbox's /sys/fs/cgroup is mounted read-only, so the inner crun can't
# create its cgroup ("/sys/fs/cgroup/cgroup.subtree_control: read-only file system").
# --cgroupns=private alone does NOT fix this (tested: cgroup2 stayed ro). The supported
# path is to run the inner container with `--cgroups=disabled`, e.g.
#   podman run --cgroups=disabled ...
# which is fine on a dev box that isn't enforcing resource limits. See README / task doc.
# (--device /dev/net/tun is retained for the rootless/pasta path; the rootful netavark
# path above does not use it.)
NESTED_PODMAN_FLAGS := --device /dev/fuse \
                       --device /dev/net/tun \
                       --security-opt label=disable \
                       --security-opt unmask=ALL \
                       --cap-add=sys_admin,mknod,net_admin \
                       --tmpfs /var/lib/containers:rw,size=$(NESTED_PODMAN_TMPFS_SIZE) \
                       $(NESTED_PODMAN_RUNTIME_TMPFS)
else
NESTED_PODMAN_FLAGS :=
endif

TMUX_FILE := $(HOME)/.tmux.conf
TMUX_REAL_PATH := $(shell readlink -f $(TMUX_FILE))
TMUX_MOUNT := $(shell if [ -f $(TMUX_REAL_PATH) ]; then echo "-v $(TMUX_REAL_PATH):/root/.tmux.conf:Z" ; fi)

GITCONFIG_FILE := $(HOME)/.gitconfig
GITCONFIG_REAL_PATH := $(shell readlink -f $(GITCONFIG_FILE))
GITCONFIG_MOUNT := $(shell if [ -f $(GITCONFIG_REAL_PATH) ]; then echo "-v $(GITCONFIG_REAL_PATH):/root/.gitconfig:Z" ; fi)

GNUPG_FILE := $(HOME)/.gnupg
GNUPG_REAL_PATH := $(shell readlink -f $(GNUPG_FILE))
GNUPG_MOUNT := $(shell if [ -d $(GNUPG_REAL_PATH) ]; then echo "-v $(GNUPG_REAL_PATH):/root/.gnupg:Z" ; fi)

CLAUDE_CONFIG_DIR := $(HOME)/.claude
# mkdir -p, not an existence check: if the host dir is missing, a conditional
# silently skips the mount and auth/sessions/memory die with the container
# (re-sign-in every launch). Created here at parse time — a recipe-line mkdir
# would run after this := is already expanded. make runs on the host, so this
# creates the host-side dir itself.
CLAUDE_CONFIG_MOUNT := $(shell mkdir -p $(CLAUDE_CONFIG_DIR); echo "-v $(CLAUDE_CONFIG_DIR):/root/.claude:Z")

# Repo-tracked Claude config (CLAUDE.md + slash commands + reference docs)
# layered on top of the host's ~/.claude mount so edits flow back to git.
# Auth/sessions/credentials still come from the host mount above. tasks/reference
# holds docs the mounted CLAUDE.md tells the agent to read (e.g. the overused-
# words catalog, read at session start); mounting it keeps those pointers valid
# in every session while the docs stay in their conventional tasks/reference home.
CLAUDE_DOTFILES_MOUNT := -v ./entrypoint/dotfiles/.claude/CLAUDE.md:/root/.claude/CLAUDE.md:Z \
                         -v ./entrypoint/dotfiles/.claude/commands:/root/.claude/commands:Z \
                         -v ./tasks/reference:/root/.claude/reference:Z

# Personal overlay. The tracked CLAUDE.md @-imports ~/.claude/ai-coding-conventions.personal.md; the repo
# ships a BLANK ai-coding-conventions.personal.md as the baked default (so a bare `podman run` without this
# mount still resolves the import). Here we shadow it with the host's
# ~/.ai-coding-conventions.personal.md, so your personal conventions layer in without editing
# the tracked file. The host and container basenames differ ON PURPOSE: the host file is a
# hidden dotfile (tidy among your other dotfiles), while the repo/container copy is un-dotted
# so the baked default and the .example template stay visible in `ls`; this mount bridges the
# two names. touch (not an existence check) at parse time creates the host file if
# absent — exactly like CLAUDE_CONFIG_MOUNT's mkdir -p above; make runs on the host, so
# this creates it there. The mount is unconditional: the @-import target must always exist.
CLAUDE_PERSONAL_FILE := $(HOME)/.ai-coding-conventions.personal.md
CLAUDE_PERSONAL_MOUNT := $(shell touch $(CLAUDE_PERSONAL_FILE); echo "-v $(CLAUDE_PERSONAL_FILE):/root/.claude/ai-coding-conventions.personal.md:Z")

# Optional non-interactive auth, passed THROUGH from the host env (never stored
# in the repo). The ~/.claude mount above already persists your login across
# runs, but a subscription's OAuth *session* token still expires periodically —
# so you re-login now and then. To stop that entirely, generate a long-lived
# (~1yr) token once with `claude setup-token` and export it on the host:
#     export CLAUDE_CODE_OAUTH_TOKEN=...   # in ~/.bashrc / ~/.zshrc
# It uses your existing SUBSCRIPTION (no per-token billing). ANTHROPIC_API_KEY is
# also honored (Console API key, separate per-token billing) for forks that want
# it. Each `-e VAR` is added ONLY when the host var is set, so an unset var never
# shadows the mounted credentials with an empty value. See README.md ("Auth").
CLAUDE_AUTH_ENV := $(shell \
	[ -n "$$CLAUDE_CODE_OAUTH_TOKEN" ] && printf -- '-e CLAUDE_CODE_OAUTH_TOKEN '; \
	[ -n "$$ANTHROPIC_API_KEY" ]       && printf -- '-e ANTHROPIC_API_KEY ')


PROJECT_DIR ?= $(notdir $(CURDIR))

FILES_TO_MOUNT = -v $(shell pwd):/$(PROJECT_DIR)/:Z \
		-v ./entrypoint/entrypoint.sh:/entrypoint.sh:Z \
                $(TMUX_MOUNT) \
                $(GNUPG_MOUNT) \
                $(GITCONFIG_MOUNT)

X_FLAGS_FOR_CONTAINER = -e DISPLAY=$(DISPLAY) \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	--security-opt label=type:container_runtime_t

WAYLAND_FLAGS_FOR_CONTAINER = -e "WAYLAND_DISPLAY=${WAYLAND_DISPLAY}" \
                              -e "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}" \
                              -v "${XDG_RUNTIME_DIR}:${XDG_RUNTIME_DIR}"

# Game controllers / joysticks. SDL2 (and most engines) read gamepads from the
# host's evdev nodes (/dev/input/event*, and the legacy /dev/input/js*), which
# are not visible in the container by default. Bind-mount the input tree in, and
# carry the host user's supplementary groups so the 0660 device nodes are
# readable (on Fedora the logged-in user already gets read access via
# systemd-logind's `uaccess` ACLs, which apply because rootless podman maps
# container-root to the host user). Caveats:
#   * Plug the controller in BEFORE launching the app — there is no udev hotplug
#     in the container, so SDL only enumerates devices present at startup.
#   * Set USE_CONTROLLER=0 to skip the passthrough.
#   * If SELinux denies access (check `ausearch -m avc -ts recent`), add
#     `--security-opt label=disable` for the run.
USE_CONTROLLER ?= 1
ifeq ($(USE_CONTROLLER),1)
  CONTROLLER_FLAGS_FOR_CONTAINER := $(shell if [ -d /dev/input ]; then echo "-v /dev/input:/dev/input --group-add keep-groups"; fi)
else
  CONTROLLER_FLAGS_FOR_CONTAINER :=
endif

# The vendored ~/.emacs.d/ Emacs config (under entrypoint/dotfiles/) is the maintainer's
# personal editor setup. It is opt-OUT: on by default for `make image`, but
# USE_EMACS_CONFIG=0 builds a clean box without it (useful for forks). Fleet convention:
# the Makefile defaults the flag ON while the Dockerfile ARG defaults it OFF, so a bare
# `podman build` is lean and `make` opts the personal config in.
USE_EMACS_CONFIG ?= 1

.PHONY: all
all: image  ## Build the image

.PHONY: image
image: ## Build the OCI image (USE_EMACS_CONFIG=0 for a clean box without the vendored Emacs config)
	$(CONTAINER_CMD) build -t $(CONTAINER_NAME) \
                         --build-arg USE_EMACS_CONFIG=$(USE_EMACS_CONFIG) \
                         .
.PHONY: shell
shell: ## Get shell. Opts: NESTED_PODMAN=1 (podman-in-podman), NESTED_PODMAN_TMPFS_SIZE=16g, EXTRA_MOUNTS="-v /host:/path:Z", USE_CONTROLLER=0 (skip gamepad passthrough)
	$(CONTAINER_CMD) run -it --rm \
		--entrypoint /bin/bash \
		$(FILES_TO_MOUNT) \
		-v ./entrypoint/shell.sh:/shell.sh:Z \
		$(EXTRA_MOUNTS) \
		$(NESTED_PODMAN_FLAGS) \
		$(CLAUDE_CONFIG_MOUNT) \
		$(CLAUDE_DOTFILES_MOUNT) \
		$(CLAUDE_PERSONAL_MOUNT) \
		$(CLAUDE_AUTH_ENV) \
		$(X_FLAGS_FOR_CONTAINER) \
		$(WAYLAND_FLAGS_FOR_CONTAINER) \
		$(CONTROLLER_FLAGS_FOR_CONTAINER) \
		$(CONTAINER_NAME) \
		/shell.sh

.PHONY: image-export
image-export: ## export the OCI image to a timestamped tar in the repo root
	$(CONTAINER_CMD) save $(CONTAINER_NAME) -o $(CONTAINER_NAME)-$(shell date +%m-%d-%Y_%H-%M-%S).tar

.PHONY: image-import
image-import: ## import an OCI image tar: make image-import FILE=foo.tar
	$(CONTAINER_CMD) load -i $(FILE)

.PHONY: help
help:
	@grep --extended-regexp '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
