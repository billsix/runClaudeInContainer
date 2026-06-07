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
ifeq ($(NESTED_PODMAN),1)
# The host's $XDG_RUNTIME_DIR is bind-mounted in for Wayland/Pulse passthrough, and it
# carries the *host* podman's rootless state (libpod/tmp/pause.pid -> a host PID). The
# inner podman would try to setns-join that nonexistent PID's userns and die with
# "cannot re-exec process to join the existing user namespace". Shadow just the libpod
# state dir with an empty tmpfs so the inner podman starts clean; the Wayland/Pulse
# sockets in the rest of the dir are untouched.
NESTED_PODMAN_RUNTIME_TMPFS := $(if $(XDG_RUNTIME_DIR),--tmpfs $(XDG_RUNTIME_DIR)/libpod:rw)
NESTED_PODMAN_FLAGS := --device /dev/fuse \
                       --device /dev/net/tun \
                       --security-opt label=disable \
                       --cap-add=sys_admin,mknod \
                       --tmpfs /var/lib/containers:rw,size=8g \
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
CLAUDE_CONFIG_MOUNT := $(shell if [ -d $(CLAUDE_CONFIG_DIR) ]; then echo "-v $(CLAUDE_CONFIG_DIR):/root/.claude:Z" ; fi)

# Repo-tracked Claude config (CLAUDE.md + slash commands) layered on top of the
# host's ~/.claude mount so edits flow back to git. Auth/sessions/credentials
# still come from the host mount above.
CLAUDE_DOTFILES_MOUNT := -v ./entrypoint/dotfiles/.claude/CLAUDE.md:/root/.claude/CLAUDE.md:Z \
                         -v ./entrypoint/dotfiles/.claude/commands:/root/.claude/commands:Z


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

.PHONY: all
all: image  ## Build the image

.PHONY: image
image: ## Build the OCI image
	$(CONTAINER_CMD) build -t $(CONTAINER_NAME) \
                         .
.PHONY: shell
shell: ## Get shell. Opts: NESTED_PODMAN=1 (podman-in-podman), EXTRA_MOUNTS="-v /host:/path:Z"
	$(CONTAINER_CMD) run -it --rm \
		--entrypoint /bin/bash \
		$(FILES_TO_MOUNT) \
		-v ./entrypoint/shell.sh:/shell.sh:Z \
		$(EXTRA_MOUNTS) \
		$(NESTED_PODMAN_FLAGS) \
		$(CLAUDE_CONFIG_MOUNT) \
		$(CLAUDE_DOTFILES_MOUNT) \
		$(X_FLAGS_FOR_CONTAINER) \
		$(WAYLAND_FLAGS_FOR_CONTAINER) \
		$(CONTAINER_NAME) \
		/shell.sh

# .PHONY: claude
# claude: ## Run Claude Code in an ephemeral container with project mounted
# 	$(CONTAINER_CMD) run -it --rm \
# 		--entrypoint /usr/local/bin/claude \
# 		$(FILES_TO_MOUNT) \
# 		-e ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY) \
# 		-w /geometricalgebra \
# 		$(CONTAINER_NAME)
.PHONY: help
help:
	@grep --extended-regexp '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
