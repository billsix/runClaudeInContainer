cd /

# Auth hint (printed once per shell, only when no long-lived token is set).
# The mounted ~/.claude persists your login across runs, but a subscription's
# OAuth *session* token expires periodically -- so you re-login now and then.
# A long-lived token from `claude setup-token`, exported on the host, stops
# that for good; `make shell` passes it through. Show how, until it's set.
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
	printf '\n\033[33m[claude auth]\033[0m No CLAUDE_CODE_OAUTH_TOKEN set — you are relying on the\n'
	printf '  mounted ~/.claude login, which can expire (periodic re-login). To stop that:\n'
	printf '    1. run  \033[36mclaude setup-token\033[0m  once (a ~1yr token; uses your subscription)\n'
	printf '    2. on the HOST, add to ~/.bashrc / ~/.zshrc:  \033[36mexport CLAUDE_CODE_OAUTH_TOKEN=...\033[0m\n'
	printf '  `make shell` then passes it through automatically. See README.md ("Auth").\n\n'
fi

exec bash
