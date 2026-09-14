# Trim runClaudeInContainer's root CLAUDE.md (14,167 B ≈ 3.5K tok, loaded every session)

**Status:** Done — trimmed 2026-09-13 (archived 2026-09-14)
**Priority:** 5
**Difficulty:** 3

**Result:** CLAUDE.md 14,167 B → 8,477 B. Moves (MODERATE target): "Nested Podman"
flag-by-flag rationale / `PODMAN_RUN_FLAGS` history / two-walls / security trade-off →
`tasks/reference/nested-podman-design.md` (near-duplicate reconciled; unique "costs"
enumeration + `/dev/net/tun` detail appended verbatim; usage stub + tmpfs knob kept
inline). "The layered Claude config" auth diagnosis + onboarding-vs-token detail already
present in `claude-config-layering.md`; the `@`-import history and "SHARED layer"
self-maintaining note appended there verbatim (auth essentials + `CLAUDE_AUTH_ENV`
one-liner kept inline). "Host shell vs container shell" `declare -p`/parse-time
mechanism already in `claude-config-layering.md` ("Gotcha that bit the maintainer");
CLAUDE.md keeps the `[HOST]`/`[CONTAINER]` label rule + "shell is bash" + one-line
exported guardrail + pointer.

## BLUF
This repo's own root `CLAUDE.md` is 14,167 B (≈3.5K tok) and is spliced into the agent's context
on every session/turn in this repo. Two sections carry deep rationale that already has a home in
`tasks/reference/` — the flag-by-flag nested-podman walkthrough and the auth/config-layering
diagnosis history. Fold that detail into the existing `nested-podman-design.md` and
`claude-config-layering.md`, leaving a lean operational file of ≈7 KB (detail relocated, not
deleted).

## Context
- Why: `CLAUDE.md` is inlined into the system prompt on every turn, so an oversized one wastes
  context budget continuously. Method + measured numbers:
  `runCrushInContainer tasks/reference/crush-context-assembly.md`.
- Current size: 14,167 B ≈ 3.5K tok. `@`-imports: **none in this file** (this root CLAUDE.md has
  no bare `@path` lines; the auto-import machinery it *describes* lives in the mounted
  `entrypoint/dotfiles/.claude/CLAUDE.md`, a different file).
- Convention: `CLAUDE.md` stays lean + operational, loaded every session; durable detail moves to
  `tasks/reference/<slug>.md`, read on demand. Prefer folding into an EXISTING reference doc.
- Existing `tasks/reference/` docs (fold-into targets): `nested-podman-design.md` (14.9 KB — the
  full nested-podman design/flags/lore; primary MOVE target), `claude-config-layering.md`
  (11.8 KB — what persists where, the `mkdir -p` rationale, auth-mount history; the other MOVE
  target), `minimal-nested-images.md`, `sandbox-capability-map.md`, `shell-exec-and-container-template.md`,
  `bluf-bottom-line-up-front.md`, `print-debugging.md`, `llm-overused-phrases.md`.

## Stay vs move (section-by-section)

| CLAUDE.md section (heading) | ~bytes | Verdict | Destination |
|---|---|---|---|
| Header "what this repo is for" (L1–11) | ~900 | TRIM | CLAUDE.md — keep the one-paragraph purpose; trim the overlap-with-personal-overlay aside to one clause. |
| "What the pieces do" (L13–34) | ~1200 | STAY | CLAUDE.md — lean, operational layout (`Dockerfile`/`Makefile`/entrypoints/`exampleRunClaude.sh`). |
| "The layered Claude config" (L36–84) | ~3500 | TRIM | Keep in CLAUDE.md: the essential "two host mounts needed for auth (`~/.claude` + `~/.claude.json`)" + a one-line `CLAUDE_AUTH_ENV` note + where conventions are edited. MOVE the 2026-08-16 root-cause diagnosis, the onboarding-vs-token distinction detail, and the reference-doc `@`-import history → `claude-config-layering.md` (already the home for "what persists where + rejected alternatives"). |
| "Host shell vs container shell" (L86–107) | ~1600 | TRIM | Keep the `[HOST]`/`[CONTAINER]` labeling rule + "container shell is bash" + a one-line "env vars must be *exported* to cross" guardrail in CLAUDE.md. MOVE the `declare -p`/`$(shell …)`-parse-time deep explanation → `claude-config-layering.md` (it is the `CLAUDE_AUTH_ENV` mechanism). |
| "Conventions for changing this repo" (L109–129) | ~1400 | STAY | CLAUDE.md — already lean guardrails (add packages to `01-install-base.sh` sorted; keep dnf cache mounts; conditional mounts; `:Z`; `make help`/`make image` sanity checks). Keep. |
| "Nested Podman" (L131–197) | ~4500 | MOVE | The one-command usage + tmpfs knob (`NESTED_PODMAN_TMPFS_SIZE`, 8g default) STAY as ≈4 lines in CLAUDE.md. MOVE the flag-by-flag rationale, the `PODMAN_RUN_FLAGS` history, the "non-obvious flags and why" block, and the security trade-off → `nested-podman-design.md` (already holds exactly this, in more depth — near-duplicate). Leave a pointer. Biggest single MOVE. |

## Projected result
- Trimmed CLAUDE.md ≈ 7 KB (from 14.2 KB) — repo purpose, "what the pieces do", the auth
  essentials + pointer, the shell-labeling guardrail + pointer, the change conventions, and a
  ~4-line nested-podman usage block + pointer.
- Reference docs updated: `nested-podman-design.md` (absorbs the flag rationale / security
  trade-off already largely present — reconcile, don't duplicate), `claude-config-layering.md`
  (absorbs the auth root-cause history + the env-var-export mechanism). No new reference doc
  needed.

## Open questions (for the maintainer)
1. The "Nested Podman" section is nearly a duplicate of `nested-podman-design.md` already — do
   you want me to (a) reduce CLAUDE.md to a usage stub + pointer and verify the reference doc
   covers everything removed, or (b) also reconcile any detail the CLAUDE.md version has that the
   reference doc lacks before trimming? Recommendation: (b) — reconcile first so nothing is lost,
   then stub.

## Related
- `runCrushInContainer tasks/reference/crush-context-assembly.md` — measurement + method.
- `tasks/reference/nested-podman-design.md`, `tasks/reference/claude-config-layering.md` — the
  two fold-into targets.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
