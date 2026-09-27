# Decouple the lean-image signal from NESTED_PODMAN (give it its own name)

**Status:** DONE 2026-09-27 — the fleet rename is applied and verified; meets the BLUF's "done" test
(`NESTED_PODMAN` no longer appears in any `--build-arg`-selecting expression). Actual Makefile blast
radius was ONE file (`hanoi`; gacalc was already on `MINIMAL_IMAGE`) — every other Makefile used
`NESTED_PODMAN` only for the run-capability `PODMAN_RUN_FLAGS`, which is unchanged. The personal overlay
needs no rename (checked; all its `NESTED_PODMAN` uses are run-capability); one OPTIONAL host-side
template addition remains at the maintainer's discretion (§ "Personal overlay").
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

## Decisions (2026-09-27, William Emerison Six <billsix@gmail.com>)

1. **Name: `MINIMAL_IMAGE`.** (resolved)
2. **Opt-in, NOT auto-exported. Make it a documented option.** ("no, just make sure it's a documented
   option.") The sandbox does not set `MINIMAL_IMAGE`; a downstream nested `make image` builds FULL
   unless the user passes `MINIMAL_IMAGE=1`. This is consistent with the storage decision (disk store
   → no RAM ceiling → lean is optional), so no auto-inference is needed. `NESTED_PODMAN` keeps ONLY
   its `PODMAN_RUN_FLAGS` run-capability role. (resolved)

## Progress

- **geometricalgebra: converted 2026-09-27** — its four flags now read
  `?= $(if $(filter 1,$(MINIMAL_IMAGE)),0,1)`, `PODMAN_RUN_FLAGS` still keyed on `NESTED_PODMAN`.
  Verified: plain `make image` → full, `make image MINIMAL_IMAGE=1` → lean (2.42 GB, 649 tests).
  gacalc `tasks/minimal-nested-image.md`. This is the reference example for the fleet rollout.
- **Fleet rollout DONE 2026-09-27** (atomic, disk-store already landed the same session):
  - `hanoi/Makefile` — `BUILD_DOCS` now keys off `MINIMAL_IMAGE` (verified with `make -n`: default full,
    `MINIMAL_IMAGE=1` → lean, `NESTED_PODMAN=1` no longer affects it, per-flag `BUILD_DOCS=1` override
    still wins). The **only** downstream Makefile that needed it — the re-sync grep found no others
    keyed on `NESTED_PODMAN` (gacalc was already converted). Intended behavior change: a nested
    `make image` now builds FULL (the disk store fits it); lean is the opt-in `MINIMAL_IMAGE=1`.
  - Reference docs: `tasks/reference/minimal-nested-images.md` retitled + reframed (auto-lean-when-nested
    → opt-in `MINIMAL_IMAGE`; title, intro banner, §1/§2 idiom, "For new projects", and the §4 re-sync
    grep all updated), and `tasks/reference/nested-podman-design.md`'s PODMAN_RUN_FLAGS-convention
    overload paragraph rewritten (image content = `MINIMAL_IMAGE`, run capability = `NESTED_PODMAN`,
    independent).
  - Cross-project conventions (the in-sandbox `CLAUDE.md`): runClaude
    `entrypoint/dotfiles/.claude/CLAUDE.md` and the runCrush client's baked
    `client/entrypoint/dotfiles/.config/crush/CLAUDE.md` both now state `NESTED_PODMAN` = run capability
    only and document `MINIMAL_IMAGE=1` as the opt-in image-content flag.
- **Personal overlay — checked 2026-09-27: NO required change.** Every `NESTED_PODMAN` reference in
  `~/.ai-coding-conventions.personal.md` is run-capability (`PODMAN_RUN_FLAGS`, the `shell-exec` mirror
  note, the offline-export `make shell NESTED_PODMAN=1`, the conformance checklist, the `--cgroups`
  standing authorization) — all correctly stay, and there is no image-content/`--build-arg` keying to
  rename. The task doc's pre-implementation guess (that the template spec/checklist referenced the lean
  idiom) was wrong: the overlay carries no lean idiom. **OPTIONAL (maintainer, host-side):** if you want
  new projects scaffolded from the template to expose the lean option, add the
  `FLAG ?= $(if $(filter 1,$(MINIMAL_IMAGE)),0,1)` block to the overlay's template spec. Not required
  for this task's "done"; the agent can't edit the overlay (host-side).

## Open questions — resolved

1. **Fleet rename: atomic, NO deprecated fallback (resolved 2026-09-27).** The disk-store change landed
   first (same session), and the survey found only `hanoi` actually keyed image content on
   `NESTED_PODMAN` (gacalc already on `MINIMAL_IMAGE`), so there was no fleet of unconverted repos to
   protect — an atomic rename was clean. No `MINIMAL_IMAGE ?= $(if …NESTED_PODMAN…)` fallback was added.
