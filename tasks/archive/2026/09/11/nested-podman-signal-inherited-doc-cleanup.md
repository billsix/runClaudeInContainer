# Nested-podman signal is inherited, not typed — doc cleanup

**Status:** complete
**Completed:** 2026-09-11

## What this did

Corrected the agent-facing docs so they no longer implied the agent should pass
`NESTED_PODMAN=1` to nested `make` commands. The signal is set once, at the outermost
`make shell NESTED_PODMAN=1` host launch (which adds `-e NESTED_PODMAN=1` alongside the
`/dev/fuse`, caps and store flags), and every project Makefile reads it with
`NESTED_PODMAN ?= 0`; GNU make's `?=` keeps an env-provided value, so every nested
`make image` / `make test` / `make shell` inherits it with nothing typed. Doc-only; no
Makefile changed.

## Mechanism, verified 2026-09-11 in a live nested session

- From a runClaude session carrying the signal, runCrush's `client/Makefile` resolved
  `NESTED_PODMAN=1 → FULL_TOOLCHAIN=0, PODMAN_RUN_FLAGS=[--cgroups=disabled]` with no flag
  on the command line; with `NESTED_PODMAN` unset it reverted to the host values.
- A throwaway `NESTED_PODMAN ?= 0` Makefile confirmed the `?=` rule directly (env `1` →
  make sees `1`; a command-line assignment overrides in both directions).

## Decisions (William Emerison Six <billsix@gmail.com>, 2026-09-11)

- **Scope (a), doc cleanup only.** Rejected (b), auto-detecting nested from a `/dev/fuse`
  probe in the Makefile: `/dev/fuse` exists on most bare Linux hosts, so it would
  false-positive and weaken isolation on a normal host `make shell`. The exported env var
  plus `?=` already detects nesting correctly, coupled to the launch that provides it.
- `make shell NESTED_PODMAN=1` at the outermost host launch stayed documented as the one
  human touch.
- The signal is deliberately **not** baked into the image (`ENV NESTED_PODMAN=1`): a plain
  non-nested `make shell` would then advertise a capability it lacks.

## What changed (commit `04a2267`)

- `entrypoint/dotfiles/.claude/CLAUDE.md`, "Running projects in a nested container": run
  the plain nested command; never pass `NESTED_PODMAN=1` downstream.
- `tasks/reference/nested-podman-design.md`, "The `PODMAN_RUN_FLAGS` convention": the
  inheritance mechanism and the don't-bake-it note.
- Root `CLAUDE.md`, "Nested Podman": the same, host-launch content kept.

Superseded: `FULL_TOOLCHAIN` was removed 2026-09-12, and lean images keyed off
`NESTED_PODMAN` were replaced by the separate `MINIMAL_IMAGE` opt-in 2026-09-27
(`tasks/reference/minimal-nested-images.md`); the tmpfs nested store was replaced by a
disk directory 2026-09-27. The inheritance rule itself still holds.

Sibling: runCrushInContainer carries the twin task at the same archive path.
