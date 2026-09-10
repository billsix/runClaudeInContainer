# Lean image for nested-podman builds — what "minimal" means for runClaudeInContainer

**Status:** proposed — research done 2026-09-10 (survey of the Dockerfile + Makefile from the
runClaudeInContainer sandbox); **implementation needs go-ahead**. One of the per-project children of
runClaudeInContainer `tasks/minimal-image-for-nested-podman-standard.md` (the convention: every optional-feature build flag defaults to its lean value when
`NESTED_PODMAN=1`); the fleet-wide findings table is runClaudeInContainer `tasks/reference/minimal-nested-images.md`. Created 2026-09-10 at the maintainer's
request (William Emerison Six <billsix@gmail.com>: "go through all of my projects with CLAUDE.md …
research what a minimal nested podman container would be for them").
**Priority:** 6
**Difficulty:** 4

## BLUF

Make `make image` inside a sandbox (which exports `NESTED_PODMAN=1`) build a lean image that fits
the nested RAM store and still runs this project's gate, while a host `make image` stays
byte-identical — via the idiom `FLAG ?= $(if $(filter 1,$(NESTED_PODMAN)),0,1)` on each optional-feature flag (the `PODMAN_RUN_FLAGS`
pattern applied to build flags; reference implementation: runCrushInContainer `client/Makefile`,
`FULL_TOOLCHAIN`). Done = the flags below carry the nested-aware default, a nested `make image`
builds and passes the gate, both image sizes are measured and recorded here and in `CLAUDE.md`.

## Context — read first

- runClaudeInContainer `tasks/reference/minimal-nested-images.md` — the standard, the idiom, the rules (a project's *gates* and *product build deps* are never
  trimmed; only editors, docs toolchains, notebooks, GUI extras), and every project's row.
- This repo's `Dockerfile`, `Makefile` (flag block + `image` target), `entrypoint/*install*.sh`.
- The flag-coverage rule (cross-project `CLAUDE.md` › "Verification gates in nested containers"): a
  lean build verifies nothing about the layers it skips — when a change touches what a skipped layer
  consumes, build with that flag ON.

## Findings (2026-09-10)

**What the image installs today.** The sandbox image itself: `01-install-base.sh` (~430 packages, deliberately maximal), the Claude Code installer (network), and `USE_EMACS_CONFIG` (vendored Emacs config on/off). No lean variant. Building it nested means building the sandbox inside a sandbox — done only to verify Dockerfile/entrypoint changes, and today it cannot be (the image is far over the RAM store).

**What "minimal" is here.** Mirror runCrushInContainer exactly: an always-run `00-install-minimal.sh` (git, ripgrep, strace, tcpdump, the few runtime utilities Claude Code shells out to, `curl` for the installer) + `01-install-base.sh` gated by `FULL_TOOLCHAIN`, defaulting lean when nested. runCrush's script is the starting point (it was derived from this repo's list).

**Notes.** The Claude Code installer needs the network at build time either way — no vendored/offline story here, and none is asked for.

## Plan

- [ ] Copy runCrush's `client/entrypoint/00-install-minimal.sh` shape; verify Claude Code's runtime shell-outs (rg, gh) the way runCrush did for Crush.
- [ ] Dockerfile: `ARG FULL_TOOLCHAIN=0` gating `01-install-base.sh`; Makefile `FULL_TOOLCHAIN ?= $(if $(filter 1,$(NESTED_PODMAN)),0,1)`.
- [ ] Nested proof: flagless `make image` builds; `claude --version` runs; sentinels absent. Measure; root `CLAUDE.md` + `tasks/reference/sandbox-capability-map.md`.
- [ ] Record both sizes (host full vs nested lean) here and in `CLAUDE.md`; add the standard's one-line
      rule to `CLAUDE.md` ("nested = lean image automatically; `FLAG=1` overrides").

## Open questions

None — the standard's decisions (dnf-only, gates never trimmed) were the maintainer's on 2026-09-10;
anything project-specific to decide is flagged inline above.
