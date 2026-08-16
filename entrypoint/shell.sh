cd /

# Auth hint (printed once per shell, only when no long-lived token is set).
# Interactive login now persists automatically via the ~/.claude and ~/.claude.json
# mounts (log in once, it sticks) -- so no token is needed for normal use. A
# long-lived token from `claude setup-token` is only for HEADLESS/CI use (`claude
# -p ...`); it does NOT change the interactive login. Mention it, briefly, when unset.
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    printf '\n\033[33m[claude auth]\033[0m Interactive login persists via the ~/.claude mounts — log in\n'
    printf '  once and it sticks. Only for HEADLESS/CI use (`claude -p ...`) do you need a token:\n'
    printf '    1. run  \033[36mclaude setup-token\033[0m  once (a ~1yr token; uses your subscription)\n'
    printf '    2. on the HOST, add to ~/.bashrc / ~/.zshrc:  \033[36mexport CLAUDE_CODE_OAUTH_TOKEN=...\033[0m\n'
    printf '  `make shell` passes it through automatically. See README.md ("Auth").\n\n'
fi

exec bash
