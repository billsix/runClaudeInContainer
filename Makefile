.DEFAULT_GOAL := help

CONTAINER_CMD = podman
CONTAINER_NAME = claudecontainer

EXTRA_MOUNTS ?=

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
shell: ## Get shell.  make shell EXTRA_MOUNTS="-v /home/wsix/opt/marioteachestyping/:/mario:Z"
	$(CONTAINER_CMD) run -it --rm \
		--entrypoint /bin/bash \
		$(FILES_TO_MOUNT) \
		-v ./entrypoint/shell.sh:/shell.sh:Z \
		$(EXTRA_MOUNTS) \
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
