# Pipe a long-lived Claude auth token into the container via a host env var

**✅ VERIFIED COMPLETE (2026-08-16).** The maintainer ran a second fresh sandbox and got
in **with no browser login prompt** — automode, the desired outcome. The `CLAUDE_JSON_MOUNT`
fix (persisting `~/.claude.json` onboarding state) is confirmed working end-to-end. Task
archived (William Emerison Six <billsix@gmail.com>, 2026-08-16).

**Two host-side close-out steps remain (they do not block the fix, but are required
hygiene):**
1. **Rotate the exposed token** — the live `sk-ant-oat01-…` was pasted into chat on
   2026-08-15/16. `[HOST]` `claude setup-token`, replace the value in `~/.bashrc`, open a
   fresh terminal. See the ⚠️ note below.
2. **Delete the token-leaking scratch files** — `results.txt` and `results3.txt` at the
   repo root (untracked) each contain the live token in plaintext; remove them.

**Note (2026-08-16):** the `HOW-TO-STOP-WEB-LOGIN.md` runbook referenced below was a
debugging-phase testing aid and was **removed** after the fix was verified (it never
shipped). Its durable content lives on: the diagnostic checklist moved to
`tasks/reference/claude-config-layering.md` ("If the login menu returns despite the
mounts"), and README's Auth section covers the rest. Mentions of it below are kept as
historical record.

---

**Launch #1 verified live in-container (2026-08-16).** The maintainer ran the first fresh
sandbox and logged in through the browser (expected). Checked from inside that container:
`/root/.claude.json` is a **real bind mount** to the host (`mount` shows it on the host
btrfs `subvol=/home`, not the `--rm` overlay), and it now carries
`hasCompletedOnboarding": true` + `oauthAccount`, written by the browser login;
`.credentials.json` is present; Claude Code is 2.1.233. Because the onboarding write landed
in a host-backed file, it survives container exit → **launch #2 is predicted to skip the
login menu.** Maintainer is about to exit and run the second launch to confirm the pass.

**Status (2026-08-16, corrected): ROOT CAUSE FOUND — it was never the token.** The
"log in via the web every session" symptom is caused by **`~/.claude.json` being
ephemeral**, not by token expiry, and the repeated "stale sandbox" diagnosis below was
**wrong** (refuted by the maintainer's own `results2.txt`/`results3.txt`: the token was
present *inside* the container via `printenv`, yet `claude` still showed "Select login
method").

Claude Code stores auth in two files: `~/.claude/.credentials.json` (the OAuth tokens —
**persisted**, it's inside the mounted `~/.claude`) and **`~/.claude.json`** (onboarding
state: `hasCompletedOnboarding`, `oauthAccount`, `userID`). The latter is a **sibling** of
`~/.claude`, so `CLAUDE_CONFIG_MOUNT` never caught it; on the `--rm` container it started
absent every launch → Claude treated onboarding as never completed → showed the login menu
**despite valid mounted credentials**. `CLAUDE_CODE_OAUTH_TOKEN` can't fix this because the
menu is gated on onboarding state, not API auth (and the docs only ever framed the token as
a headless/CI mechanism; bare mode doesn't even read it).

**Fix (implemented 2026-08-16):** added **`CLAUDE_JSON_MOUNT`** to the `Makefile` — seeds
`$(HOME)/.claude.json` to `{}` if absent, then bind-mounts it to `/root/.claude.json`
(wired into `shell:` next to `CLAUDE_CONFIG_MOUNT`). Log in through the browser **once**;
Claude writes `hasCompletedOnboarding: true` to the now-persistent file; the menu never
returns (until ~28 days of disuse lapses the refresh token, or `/logout`). Verified: `make
-n shell` emits `-v …/.claude.json:/root/.claude.json:Z`; `make help` parses. Rewrote
`HOW-TO-STOP-WEB-LOGIN.md` around this (happy path at top; env token demoted to an optional
headless section). **Outstanding:** maintainer confirms a *second* fresh sandbox no longer
prompts, then archive.

**The `CLAUDE_AUTH_ENV` token passthrough stays** — it's correct and useful for
headless/`-p`/CI use — but it is **not** the fix for the interactive login menu. The
sections below are the original (token-focused) task record, kept for history; their
"stale sandbox" conclusion is superseded by the root cause above.

---

**Status:** DONE (implemented) 2026-08-15 — pending the maintainer's final end-to-end check.
Maintainer confirmed **subscription** (not per-token), so `CLAUDE_CODE_OAUTH_TOKEN` is the
documented default. Implemented: `Makefile` `CLAUDE_AUTH_ENV` conditional passthrough wired into
`shell:`; dead `claude:` target removed; `entrypoint/shell.sh` prints a startup hint when no token
is set; documented in `README.md` ("Auth"), `CLAUDE.md`, and `tasks/reference/claude-config-layering.md`.
**Committed 2026-08-15.** Diagnosed 2026-08-15: the wiring is correct — the maintainer's "still
prompts for web auth" was a **stale session** (the sandbox was launched before the host `export`
existed), not a bug. Run the host-side verification below, then archive. See **"Verification —
end-to-end"**.

**2026-08-15 (later): the maintainer couldn't find the steps** — they were split between this task
doc and the README Auth section. Wrote a single copy-paste runbook,
`HOW-TO-STOP-WEB-LOGIN.md` at the repo root (every command tagged
`[HOST]`/`[CONTAINER]`, uses the maintainer's actual `make shell …` launch line), and linked it from
README. *(Removed 2026-08-16 — see the note at the top of this doc.)*

**2026-08-16: re-diagnosed live and confirmed the wiring is correct — again a stale sandbox.**
Every host-side factor checked green, so the passthrough has **no bug**:
- `declare -p CLAUDE_CODE_OAUTH_TOKEN` → `declare -x …` (exported).
- `make -n shell | grep -- '-e CLAUDE_CODE_OAUTH_TOKEN'` → emits the flag (trailing `\` is just the
  Makefile line-continuation, not a defect — this specifically confused the maintainer).
- Token well-formed: `len=108`, `head=sk-ant-oat01`, clean tail (no truncation/quotes).
- In-container: `claude --version` = 2.1.233 (≥ 2.1.225).

The **only** failing factor was, once more, that `claude` was run in a sandbox launched *before*
the export — the running container (the agent's own session) had `printenv CLAUDE_CODE_OAUTH_TOKEN`
**empty**. A running container can't inherit the token retroactively; only a fresh `make shell` does.

**Rewrote `HOW-TO-STOP-WEB-LOGIN.md` for a copy-paste-only reader** (the maintainer asked to be
treated as "someone who can only copy-paste"): restructured into **Part A** (post-reboot happy path
for someone who already has a token: `declare` check → `make image` → `make -n` check →
`./exampleRunClaude.sh` → in-container `printenv` gate → `claude`), **Part B** (first-time token
generation), and a **triage table** whose #1 row is the stale-sandbox trap. Every block now has a
"✅ you should see" line, and the launch step uses `./exampleRunClaude.sh` (one command, nothing to
mistype). Leads with the golden rule: *set the token, then start a brand-new sandbox — reboot for a
clean slate.* **Verification still outstanding**: the maintainer will reboot, `make image`, and
launch per Part A. When `/status` is clean (no browser prompt), archive this task.
**Priority:** 4
**Difficulty:** 2

## Verification — end-to-end (run outside the container, then archive)

**Diagnosis (2026-08-15).** The passthrough is correct; the earlier failure was a stale session.
Confirmed on the host:

- `declare -p CLAUDE_CODE_OAUTH_TOKEN` → `declare -x …`: the var **is exported**, so make's
  `$(shell …)` (which inherits only *exported* vars) can see it. A merely-*set* var — `echo
  ${#VAR}` shows a length but `declare -p` shows no `-x` — would be invisible to make.
- `make -n shell | grep -- '-e CLAUDE_CODE_OAUTH_TOKEN'` → emits the flag, so `podman run` passes
  the token into the container.

The earlier "still asks for web auth" happened because that sandbox was launched **before** the
export existed; a running container predates the change, so only a **fresh `make shell`** picks it
up. Also confirmed: the image is Claude Code **2.1.233** (≥ 2.1.225, past the mid-session
token-clobber bug), and per the [auth docs](https://code.claude.com/docs/en/authentication.md)
`CLAUDE_CODE_OAUTH_TOKEN` (precedence rank 5) **overrides** the mounted `/login` credentials
(rank 7) — so it authenticates even with valid mounted creds present.

**⚠️ ROTATE THE TOKEN ONCE THIS IS SOLVED (deferred, at the maintainer's request 2026-08-16).**
The live `sk-ant-oat01-…` value was pasted into a chat transcript on **2026-08-15 and 2026-08-16**
— treat it as **exposed**. The maintainer chose **not** to rotate mid-debug (rotating changes the
token and adds a variable while solving). So: **do not rotate until the interactive-login fix is
verified working.** After the second-launch test passes, **[HOST]** run `claude setup-token`,
replace the value in `~/.bashrc`, open a fresh terminal — then archive. The old token keeps working
until replaced, which is exactly why it must be rotated. **This is a required close-out step, not
optional.**

**Steps (the real fix — verify the `~/.claude.json` mount):**

1. **[HOST]** `./exampleRunClaude.sh` (fresh sandbox with the updated `Makefile`).
2. **[CONTAINER]** `claude` → if the login menu appears, log in through the browser **once**
   (`/status` should then show logged in).
3. **[HOST]** close it, `./exampleRunClaude.sh` **again**, `claude` → **the menu must NOT
   appear the second time.** That's the pass condition (proves onboarding persisted via the
   `~/.claude.json` mount).

When the **second** launch shows no browser prompt: (a) rotate the exposed token per the ⚠️
note above, then (b) archive this task (`/archive-task long-lived-auth-token-env-var`).

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

## Open questions (for the maintainer) — resolved

1. ~~Proceed with wiring the Makefile passthrough + docs now?~~ **Yes — done and committed
   2026-08-15.** `CLAUDE_CODE_OAUTH_TOKEN` is the documented default (subscription).
2. ~~Support both `CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY`?~~ **Both supported** in
   `CLAUDE_AUTH_ENV`; OAuth token is the recommended default, API key is the fork/Console path.
