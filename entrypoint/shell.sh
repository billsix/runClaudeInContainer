# Fail-fast setup convention: a failed setup step must abort rather than drop you
# into (or run a shell-exec script against) a half-set-up environment. `exec bash`
# below starts a FRESH bash not under -e, so interactive/script behaviour is
# unchanged. `set -e` only, not `set -u` (the auth hint reads possibly-unset vars).
# (This repo's shell.sh has no heavy setup; the convention matters in projects whose
# shell.sh does venv/editable-install/codegen -- see tasks/add-shell-exec-target.md.)
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

# No args -> interactive shell (identical to before). Args (a `-c '...'` payload
# from `make shell-exec`) -> run them after setup, in a fresh bash not under -e.
exec bash "$@"
