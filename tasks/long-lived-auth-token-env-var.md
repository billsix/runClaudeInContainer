# Pipe a long-lived Claude auth token into the container via a host env var

**Status:** DONE (implemented) 2026-08-15 — pending the maintainer's one-time host setup
(`claude setup-token` + `export CLAUDE_CODE_OAUTH_TOKEN`). Maintainer confirmed **subscription**
(not per-token), so `CLAUDE_CODE_OAUTH_TOKEN` is the documented default. Implemented: `Makefile`
`CLAUDE_AUTH_ENV` conditional passthrough wired into `shell:` (verified via `make -n shell` with/
without the var); dead `claude:` target removed; `entrypoint/shell.sh` prints a startup hint when no
token is set; documented in `README.md` ("Auth") and `CLAUDE.md`. Ready to archive after the
maintainer reviews.
**Priority:** 4
**Difficulty:** 2

## Background — reconcile with the prior decision (READ FIRST)

`tasks/archive/2026/07/09/persist-claude-login-across-containers.md` already root-caused and fixed
"every `make shell` requires signing in again": the `~/.claude` mount was **conditional** on the host
dir existing, silently no-op'd, and credentials died on the ephemeral container. Fix: unconditional
`mkdir -p` in the `Makefile`. That task **deliberately declined** shuttling `.credentials.json`
through **git** (it's a secret) and rejected a long-lived / named container and a named volume.

**Why this task is not redundant with that one.** The mount fix persists `.credentials.json` across
runs, but a **subscription OAuth session token still expires** — so periodic re-auth remains, which
the mount cannot prevent. The fix for *expiry* (not for the mount no-op the old task solved) is a
**long-lived token**, piped in as a **host environment variable** — which is **not** committing a
secret to git, so it honors the old decision.

## The mechanism (researched 2026-08-15)

Claude Code reads two non-interactive auth env vars (both override the interactive/mounted session):

- **`CLAUDE_CODE_OAUTH_TOKEN`** — a long-lived (~1 year) OAuth token from **`claude setup-token`**.
  **Uses your existing subscription** (no extra billing). Intended exactly for
  "scripts / CI / no interactive browser login." **Recommended** for this repo.
- **`ANTHROPIC_API_KEY`** — a Console API key. Works too, but bills **per-token on a separate API
  account**, not the subscription. Alternative, not the default.

A commented-out `-e ANTHROPIC_API_KEY=...` already sits in the dead `claude:` target in the
`Makefile` (with a stale `-w /geometricalgebra` path) — this task supersedes/cleans that.

## Plan

1. **Makefile — conditional passthrough on the `shell` target.** A `:=` var computed at parse time
   that adds `-e <VAR>` **only when the host var is set** (so an unset var never shadows the mounted
   credentials):
   ```make
   # Optional non-interactive auth: pass a long-lived token from the host so you
   # don't re-login when the mounted session token expires.  Prefer
   # CLAUDE_CODE_OAUTH_TOKEN (`claude setup-token`, ~1yr, uses your subscription);
   # ANTHROPIC_API_KEY also works (separate per-token API billing).  Added only
   # when set, so it never overrides the ~/.claude mount with an empty value.
   CLAUDE_AUTH_ENV := $(shell \
     [ -n "$$CLAUDE_CODE_OAUTH_TOKEN" ] && printf -- '-e CLAUDE_CODE_OAUTH_TOKEN '; \
     [ -n "$$ANTHROPIC_API_KEY" ]       && printf -- '-e ANTHROPIC_API_KEY ')
   ```
   then add `$(CLAUDE_AUTH_ENV)` to the `shell:` `podman run` flag block. (`-e VAR` with no `=value`
   passes the host value through; podman inherits make's env, which has the exported host var.)
   Clean up the dead commented `claude:` target while here.
2. **Default host env var to set → `CLAUDE_CODE_OAUTH_TOKEN`** (same name host + container; the
   Makefile passes it through). One-time host setup:
   ```sh
   claude setup-token                     # prints a token; uses your subscription
   export CLAUDE_CODE_OAUTH_TOKEN=...      # add to ~/.bashrc / ~/.zshrc to persist
   ```
   Then `make shell` never prompts to log in again until the token's ~1-year expiry.
3. **Document** in `README.md` (Requirements / Quick start — an auth note) and `CLAUDE.md` ("The
   layered Claude config" — note the env-var override as the expiry-proof alternative to the mount).
   Cross-reference the archived task and `tasks/reference/claude-config-layering.md`.
4. **Never commit the token.** It lives only in the host env; the repo just passes it through. (Same
   spirit as the 2026-07-09 "don't put `.credentials.json` in git" decision.)

## Open questions (for the maintainer)

1. Proceed with wiring the Makefile passthrough + README/CLAUDE docs now? (Recommended:
   `CLAUDE_CODE_OAUTH_TOKEN`, subscription-friendly.) Or keep this as a documented task only?
2. Support **both** `CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY` passthrough (as sketched), or
   only the OAuth token to steer everyone to the subscription path?
