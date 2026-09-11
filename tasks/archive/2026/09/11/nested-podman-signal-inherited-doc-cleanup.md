# Nested-podman signal is inherited, not typed — doc cleanup

**Status:** proposed — needs go-ahead
**Priority:** 4
**Difficulty:** 2

## BLUF

`NESTED_PODMAN=1` is set exactly once, at the outermost `make shell NESTED_PODMAN=1`
host launch of this sandbox, and from there it is inherited automatically by every
nested `make` the agent runs (downstream projects **and** the runCrush client) — because
every Makefile declares `NESTED_PODMAN ?= 0` and GNU make's `?=` respects a value already
in the environment. So the agent never needs to type `NESTED_PODMAN=1` on a
`make image` / `make test` / `make shell` command; podman-in-podman volumes/store already
build correctly with a plain invocation. The docs still imply the agent should pass the
flag. **Done = the agent-facing conventions reflect the auto-inheritance; no Makefile
change.**

## Context

**Read first**
- `entrypoint/dotfiles/.claude/CLAUDE.md` — the mounted cross-project conventions;
  sections "Running projects in a nested container" (~L1205) and "Verification gates in
  nested containers" (~L1269). This is the primary agent-facing doc to fix.
- Root `CLAUDE.md` — the "## Nested Podman" section (host-launch design; mostly keep).
- `tasks/reference/nested-podman-design.md` — "The `PODMAN_RUN_FLAGS` convention" section.
- `tasks/reference/minimal-nested-images.md` — the lean-image-when-nested standard.

**Current state / mechanism (verified 2026-09-11 in a live nested session)**
- `make shell NESTED_PODMAN=1` adds `-e NESTED_PODMAN=1` (`Makefile:69`, inside the
  `ifeq ($(NESTED_PODMAN),1)` block that also adds `--device /dev/fuse`, the caps,
  `unmask=ALL`, and the `/var/lib/containers` tmpfs). That `-e` is what puts the signal in
  the session.
- Every project/repo Makefile reads `NESTED_PODMAN ?= 0`; `?=` does not override an
  env-provided value, so the signal propagates to nested `make` with nothing typed.
- **Proof:** from a runClaude session carrying the signal, runCrush's real
  `client/Makefile` resolved `NESTED_PODMAN=1 → FULL_TOOLCHAIN=0,
  PODMAN_RUN_FLAGS=[--cgroups=disabled]` with **no flag on the command line**; running the
  same probe with `NESTED_PODMAN` unset reverted to `FULL_TOOLCHAIN=1` and empty flags (the
  host case). A throwaway `NESTED_PODMAN ?= 0` Makefile confirmed the `?=` rule directly
  (env `1` → make sees `1`; command-line assignment overrides both directions).

**Decision (William Emerison Six <billsix@gmail.com>, 2026-09-11)**
- Scope **(a), doc-cleanup only**. No Makefile change.
- Rejected scope (b) — auto-detecting nested from a `/dev/fuse` probe in the Makefile —
  because `/dev/fuse` exists on most bare Linux **hosts** too, so it would false-positive
  and silently enable nested (weakened isolation; and on runCrush, the lean image) on a
  normal host `make shell`. The exported-env-var + `?=` inheritance already does the
  detection correctly, coupled to the launch that actually provides the capability.

**Boundary to preserve**
- `make shell NESTED_PODMAN=1` at the **outermost host launch** is the one correct human
  touch — keep it documented as-is. Only the agent-facing "pass `NESTED_PODMAN` to
  nested/downstream make targets" guidance is redundant and should go.
- The signal is deliberately **not** baked into the image (`ENV NESTED_PODMAN=1`): it must
  stay coupled to the launch flags, or a plain non-nested `make shell` would falsely
  advertise nested capability (`/dev/fuse`/caps/tmpfs absent) and downstream Makefiles
  would misbehave.

## Work

1. **`entrypoint/dotfiles/.claude/CLAUDE.md`, "Running projects in a nested container":**
   trim any implication that the agent passes `NESTED_PODMAN=1` to nested/project make
   commands. State plainly: the signal is inherited from the outermost
   `make shell NESTED_PODMAN=1` launch via `?=`, so **run plain `make image` / `make test`
   / `make shell`** for nested projects; the flag is needed only at the outermost host
   launch (a user action). Keep the `test -e /dev/fuse && podman info` probe as the "is
   nested actually available" check, and keep "if it's absent, ask the user to relaunch
   nested" (a host action the agent cannot take from inside).
2. **Add the "don't bake it into the image" note** (one line, near the design/convention
   text — reference doc and/or root `CLAUDE.md`): the signal is intentionally emitted only
   alongside the capability flags, so `ENV NESTED_PODMAN=1` must not be added.
3. **Consistency sweep** of root `CLAUDE.md` "## Nested Podman",
   `tasks/reference/nested-podman-design.md`, and `tasks/reference/minimal-nested-images.md`
   — keep host-launch/design content; fix only agent-facing "type the flag downstream"
   phrasing.
4. **Stage** the doc edits (per "Git: I commit, you don't — but you DO stage").

## Verification

- `grep -rn 'NESTED_PODMAN=1'` over the touched docs; confirm every remaining occurrence is
  either the outermost host-launch command or an explanatory mention — not an instruction
  telling the agent to pass it to a nested/project target.
- `git status` shows **only doc files** changed (no Makefile), confirming scope (a).

## Sibling

runCrushInContainer carries the twin task, `tasks/archive/2026/09/11/nested-podman-signal-inherited-doc-cleanup.md`.
