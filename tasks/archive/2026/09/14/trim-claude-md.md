# Trim runClaudeInContainer's root CLAUDE.md (14,167 B ≈ 3.5K tok, loaded every session)

**Status:** complete
**Completed:** 2026-09-13 (archived 2026-09-14)

## What this did

This repo's root `CLAUDE.md` is inlined into context every turn, and two sections carried deep
rationale that already had a home in `tasks/reference/`. The trim cut it from 14,167 B to
8,477 B by relocating detail, not deleting it. Method and measured numbers:
runCrushInContainer `tasks/reference/crush-context-assembly.md`.

## Decision

Asked whether to (a) stub the "Nested Podman" section with a pointer, or (b) first reconcile any
detail the CLAUDE.md version had that `nested-podman-design.md` lacked, the recommendation (b)
was taken: reconcile, then stub.

## What moved

- **"Nested Podman":** the flag-by-flag rationale, the `PODMAN_RUN_FLAGS` history, the two
  read-only walls and the security trade-off went to `tasks/reference/nested-podman-design.md`.
  The near-duplicate was reconciled; the unique "costs" list and the `/dev/net/tun` detail were
  appended verbatim. A usage stub and the tmpfs size knob stayed inline.
- **"The layered Claude config":** the auth diagnosis and onboarding-vs-token detail were already
  in `tasks/reference/claude-config-layering.md`; the `@`-import history and the "SHARED layer"
  note were appended there. The two-auth-mounts essentials and a `CLAUDE_AUTH_ENV` line stayed.
- **"Host shell vs container shell":** the `declare -p` / parse-time mechanism was already in
  `claude-config-layering.md` ("Gotcha that bit the maintainer"); CLAUDE.md kept the
  `[HOST]`/`[CONTAINER]` label rule, "the shell is bash", a one-line export guardrail and a
  pointer.
- "What the pieces do" and "Conventions for changing this repo" stayed as they were; the header
  was trimmed. No new reference doc was needed.

Superseded: the tmpfs nested store kept inline here was replaced by a disk directory as the
default 2026-09-27 (tmpfs remains an opt-in, `NESTED_PODMAN_STORE=tmpfs`).
