# Fail-fast setup convention: a failed setup step must abort rather than drop you
# into (or run a shell-exec script against) a half-set-up environment. `exec bash`
# below starts a FRESH bash not under -e, so interactive/script behaviour is
# unchanged. `set -e` only, not `set -u` (the auth hint reads possibly-unset vars).
# (This repo's shell.sh has no heavy setup; the convention matters in projects whose
# shell.sh does venv/editable-install/codegen -- see tasks/archive/2026/08/29/add-shell-exec-target.md.)
set -e

cd /

# Auth hint (printed once per shell, only when no long-lived token is set, and only
# in interactive mode -- $# is 0 for `make shell`, nonzero for `make shell-exec`).
# Interactive login now persists automatically via the ~/.claude and ~/.claude.json
# mounts (log in once, it sticks) -- so no token is needed for normal use. A
# long-lived token from `claude setup-token` is only for HEADLESS/CI use (`claude
# -p ...`); it does NOT change the interactive login. Mention it, briefly, when unset.
if [ "$#" -eq 0 ] && [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    printf '\n\033[33m[claude auth]\033[0m Interactive login persists via the ~/.claude mounts — log in\n'
    printf '  once and it sticks. Only for HEADLESS/CI use (`claude -p ...`) do you need a token:\n'
    printf '    1. run  \033[36mclaude setup-token\033[0m  once (a ~1yr token; uses your subscription)\n'
    printf '    2. on the HOST, add to ~/.bashrc / ~/.zshrc:  \033[36mexport CLAUDE_CODE_OAUTH_TOKEN=...\033[0m\n'
    printf '  `make shell` passes it through automatically. See README.md ("Auth").\n\n'
fi

# Nested podman: warn when the host image store is mounted (NESTED_PODMAN=1 and
# NESTED_PODMAN_HOST_IMAGESTORE) but podman does not list it as an additional image store.
# Then nested builds silently rebuild from scratch instead of reusing host images; the
# usual cause is a vendor storage drop-in overriding ours (~/.claude/reference/nested-podman-design.md,
# "Which storage config the nested podman reads"). Interactive only, and bounded by a timeout
# so a held store lock can't stall the shell.
if [ "$#" -eq 0 ] && [ -d /var/lib/shared-images/overlay-images ] && command -v podman >/dev/null; then
    stores=$(timeout 10 podman info --format '{{json .Store.GraphOptions.additionalImageStores}}' 2>/dev/null || true)
    case "$stores" in
    *'"/var/lib/shared-images"'*) ;;
    *)
        printf '\n\033[33m[nested podman]\033[0m The host image store is mounted at /var/lib/shared-images,\n'
        printf '  but podman is not using it (additional stores: %s).\n' "${stores:-unknown}"
        printf '  Nested builds will not reuse host images. See ~/.claude/reference/nested-podman-design.md.\n\n'
        ;;
    esac
fi

# Nested podman: buildah keeps its temp files (each build's context mount) in
# /var/lib/containers/tmp, on the store volume, because the kernel refuses a native overlay
# on this container's own overlay root (containers.conf.d/50-runclaude-nested.conf). Create
# it for interactive and batch runs alike. Then, interactively, warn when podman does not
# report a native overlay diff: an image built before the switch from fuse-overlayfs walks
# the whole image on every layer commit. Rebuild it (`make image` on the host).
if [ "${NESTED_PODMAN:-0}" = 1 ]; then
    mkdir -p /var/lib/containers/tmp
    if [ "$#" -eq 0 ] && command -v podman >/dev/null; then
        native=$(timeout 10 podman info --format '{{index .Store.GraphStatus "Native Overlay Diff"}}' 2>/dev/null || true)
        if [ "$native" != true ]; then
            printf '\n\033[33m[nested podman]\033[0m podman reports no native overlay diff (%s), so every\n' "${native:-unknown}"
            printf '  nested layer commit walks the whole image. Rebuild the image on the host\n'
            printf '  (`make image`). See ~/.claude/reference/nested-podman-design.md ("Storage driver").\n\n'
        fi
    fi
fi

# No args -> interactive shell (identical to before). Args (a `-c '...'` payload
# from `make shell-exec`) -> run them after setup, in a fresh bash not under -e.
exec bash "$@"
