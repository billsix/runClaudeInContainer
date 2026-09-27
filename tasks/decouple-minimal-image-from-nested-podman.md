# Decouple the lean-image signal from NESTED_PODMAN (give it its own name)

**Status:** proposed — needs go-ahead (design + fleet decision; touches the tracked cross-project
`CLAUDE.md`, its runCrush port, the reference docs, ~a dozen downstream Makefiles, and the personal
template).
**Priority:** 3
**Difficulty:** 4
**Created:** 2026-09-27 (William Emerison Six <billsix@gmail.com>: "NESTED_PODMAN doesn't mean
anything other than let runClaudeInContainer/runCrushInContainer run podman nestedly. A name like
MINIMAL_IMAGE would make more sense.")

## BLUF

Today a downstream project's Makefile keys its lean-vs-full image off `NESTED_PODMAN`
(`FLAG ?= $(if $(filter 1,$(NESTED_PODMAN)),0,1)`). That overloads one variable with two unrelated
jobs — **run-time nested capability** and **build-time image content** — which already caused a real
bug in the runCrush client (reverted 2026-09-12; `runCrushInContainer
tasks/reference/nested-podman-vs-image-content.md`). The fix that reversion applied stopped at the
sandboxes; the maintainer now wants the naming fixed everywhere: **introduce a dedicated
`MINIMAL_IMAGE` (or `LEAN_IMAGE`) build signal for image content, and let `NESTED_PODMAN` mean only
"add the podman-in-podman run flags."** Done = the lean-image standard, the reference docs, the
downstream Makefiles, and the personal template use the new name; `NESTED_PODMAN` no longer appears
in any `--build-arg`-selecting expression.

## Context — read first

- `tasks/reference/nested-podman-design.md` § "The `PODMAN_RUN_FLAGS` convention" (the two-meaning
  overload is spelled out there) and § "The store is RAM".
- `tasks/reference/minimal-nested-images.md` — the lean-image standard, currently written against
  `NESTED_PODMAN`; the fleet survey/rollout table lives here.
- `tasks/minimal-image-for-nested-podman-standard.md` — the umbrella this reconsiders.
- runCrushInContainer `tasks/reference/nested-podman-vs-image-content.md` § 2 — "The two meanings of
  `NESTED_PODMAN`", the crux of why the name is wrong for build content.
- `tasks/dir-backed-nested-podman-storage.md` — the storage half. **These two are entangled:** if the
  inner store moves to disk (no RAM ceiling), a full image builds nested fine, so the lean image
  becomes an *opt-in* (export size / airgap) rather than a nested necessity — which changes whether
  the sandbox should auto-set the new signal at all.

## The proposal

1. **Name.** `MINIMAL_IMAGE` reads best for the polarity the maintainer wants ("build a minimal
   image" — the signal says what it does, and the feature flags flip *off* under it, same as today).
   `LEAN_IMAGE` is the synonym; pick one (open question 1).
2. **Downstream Makefiles.** `USE_EMACS ?= $(if $(filter 1,$(MINIMAL_IMAGE)),0,1)` etc. `NESTED_PODMAN`
   keeps *only* its `PODMAN_RUN_FLAGS ?= $(if $(filter 1,$(NESTED_PODMAN)),--cgroups=disabled)` role.
3. **Does the sandbox auto-export `MINIMAL_IMAGE=1`?** Two coherent choices, and the storage decision
   drives it (open question 2):
   - **If the store stays RAM tmpfs:** the sandbox should still auto-export `MINIMAL_IMAGE=1` so a
     nested `make image` "just works" (fits the RAM store) with nothing typed — preserving today's
     ergonomics while fixing the name. It exports two independent signals: `NESTED_PODMAN=1` (run
     caps) and `MINIMAL_IMAGE=1` (build content).
   - **If the store moves to disk (the sibling task):** the RAM ceiling is gone, so the sandbox
     should NOT auto-set it — full images build nested fine, and `MINIMAL_IMAGE=1` becomes a
     deliberate opt-in for a small export/airgap image.
4. **Sandboxes themselves stay excluded** either way (the 2026-09-12 rule): a sandbox is built on the
   host; `MINIMAL_IMAGE` would only ever be typed there deliberately, never inferred.

## Tradeoffs / why bother

- **Pro:** the name finally matches the job; the two-meaning overload that bit the runCrush client
  can't recur (a typed `NESTED_PODMAN=1` can never again silently pick a minimal image); a reader of
  a downstream Makefile sees intent, not a proxy.
- **Con:** it's a fleet-wide rename (a codemod over the converted Makefiles + three docs + the
  personal template), and it splits "one flag to remember" into two signals the sandbox exports.
- **Migration:** keep reading `NESTED_PODMAN` as a deprecated fallback for one cycle
  (`MINIMAL_IMAGE ?= $(if $(filter 1,$(NESTED_PODMAN)),1,)`) so unconverted repos don't silently
  switch to full mid-rollout — or do it as one atomic sweep. (Open question 3.)

## Impact on work already done

- **geometricalgebra** was converted 2026-09-27 using the `NESTED_PODMAN` idiom (its
  `tasks/minimal-nested-image.md`). It is gate-verified (lean image 2.42 GB, 649 tests) but its
  signal name is **provisional pending this decision** — if the rename lands, its four flags
  (`USE_EMACS`/`BUILD_DOCS`/`USE_JUPYTER`/`USE_LEAN`) switch from `$(…NESTED_PODMAN…)` to
  `$(…MINIMAL_IMAGE…)` in one line each. Nothing else about that work changes.

## Personal overlay (`~/.ai-coding-conventions.personal.md`) — what needs updating

The maintainer's overlay refers to `NESTED_PODMAN` in: the `PODMAN_RUN_FLAGS` convention (STAYS —
that is the correct run-capability use), the `shell-exec` "mirror NESTED_PODMAN" note (STAYS), the
template conformance checklist, and the offline-export test recipe (`make shell NESTED_PODMAN=1`).
Only the **image-content** references would gain a `MINIMAL_IMAGE` mention; the run-capability ones
are correct as-is. The overlay is host-side (blank in the sandbox), so the maintainer edits it — this
task just lists the lines.

## Open questions

1. `MINIMAL_IMAGE` or `LEAN_IMAGE` for the new signal name? (Recommend `MINIMAL_IMAGE`.)
2. Should the sandbox auto-export the new signal, or make it opt-in? (Depends on the storage
   decision in `tasks/dir-backed-nested-podman-storage.md` — recommend: auto-export iff the store
   stays RAM; opt-in if it moves to disk.)
3. Atomic fleet rename, or a one-cycle `NESTED_PODMAN`-fallback for backward compatibility?
