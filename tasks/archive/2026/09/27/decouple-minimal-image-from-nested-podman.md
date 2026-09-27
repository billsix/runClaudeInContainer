# Decouple the lean-image signal from NESTED_PODMAN (give it its own name: MINIMAL_IMAGE)

**Status:** DONE 2026-09-27 — the fleet rename is applied and verified; meets the "done" test
(`NESTED_PODMAN` no longer appears in any `--build-arg`-selecting expression). The actual Makefile blast
radius was ONE file (`hanoi`; gacalc was already on `MINIMAL_IMAGE`) — every other Makefile used
`NESTED_PODMAN` only for the run-capability `PODMAN_RUN_FLAGS`, which is unchanged.
**Priority:** 3. **Difficulty:** 4.
**Created:** 2026-09-27 (William Emerison Six <billsix@gmail.com>: "NESTED_PODMAN doesn't mean anything
other than let runClaudeInContainer/runCrushInContainer run podman nestedly. A name like MINIMAL_IMAGE
would make more sense."); decided, implemented and verified the same day.

## BLUF

A downstream project's Makefile had keyed its lean-vs-full image off `NESTED_PODMAN`
(`FLAG ?= $(if $(filter 1,$(NESTED_PODMAN)),0,1)`), which overloaded one variable with two unrelated
jobs — **run-time nested capability** and **build-time image content**. That renamed the build-content
meaning to a dedicated, opt-in **`MINIMAL_IMAGE`** flag and left `NESTED_PODMAN` meaning only "add the
podman-in-podman run flags." Result: image content keys off `MINIMAL_IMAGE` (which the sandbox does
**not** auto-export, so a nested `make image` builds FULL unless `MINIMAL_IMAGE=1` is passed), and
`NESTED_PODMAN` no longer appears in any `--build-arg`-selecting expression across the fleet.

## Background — why the overload was wrong

Keying image *content* off `NESTED_PODMAN` conflated two independent things and had already caused a
real bug: the runCrush client keyed a `FULL_TOOLCHAIN` flag off `NESTED_PODMAN` and so silently built a
language-server-less client whenever `make shell NESTED_PODMAN=1` was typed (reverted 2026-09-12;
runCrushInContainer `tasks/reference/nested-podman-vs-image-content.md` § "The two meanings of
`NESTED_PODMAN`"). That reversion stopped at the sandboxes; this task fixed the naming everywhere. It
was entangled with the storage half (`dir-backed-nested-podman-storage.md`, archived alongside): once
the inner store moved to disk and the RAM ceiling was gone, a full image built nested fine, so the lean
image became a deliberate **opt-in** (export size / airgap) rather than a nested necessity — which is
why the sandbox does not auto-set the signal.

## What was decided (2026-09-27, William Emerison Six <billsix@gmail.com>)

1. **Name: `MINIMAL_IMAGE`** — it reads for the polarity wanted ("build a minimal image"; feature flags
   flip *off* under it). (`LEAN_IMAGE` was the rejected synonym.)
2. **Opt-in, NOT auto-exported** ("no, just make sure it's a documented option"). The sandbox does not
   set `MINIMAL_IMAGE`; a nested `make image` builds FULL unless the user passes `MINIMAL_IMAGE=1`.
   Consistent with the storage decision (disk store → no RAM ceiling → lean optional), so no
   auto-inference. `NESTED_PODMAN` keeps ONLY its `PODMAN_RUN_FLAGS` run-capability role.
3. **Sandboxes stay excluded** (the 2026-09-12 rule): a sandbox is built on the host; `MINIMAL_IMAGE`
   is only ever typed there deliberately, never inferred.
4. **Atomic rename, NO deprecated fallback.** The disk-store change landed first (same session), and the
   re-sync grep found only `hanoi` actually keyed image content on `NESTED_PODMAN` (gacalc was already
   on `MINIMAL_IMAGE`), so there was no fleet of unconverted repos to protect — an atomic rename was
   clean, and no `MINIMAL_IMAGE ?= $(if …NESTED_PODMAN…)` fallback was added.

## What was implemented

- **geometricalgebra** had already been converted 2026-09-27 (its four flags read
  `?= $(if $(filter 1,$(MINIMAL_IMAGE)),0,1)`; `PODMAN_RUN_FLAGS` still keyed on `NESTED_PODMAN`;
  gate-verified: plain `make image` → full, `make image MINIMAL_IMAGE=1` → lean, 2.42 GB, 649 tests).
  It was the reference example; nothing about it changed under this task.
- **`hanoi/Makefile`** — `BUILD_DOCS` now keys off `MINIMAL_IMAGE`. This was the **only** downstream
  Makefile that needed it (the re-sync grep found no others keyed on `NESTED_PODMAN`). The intended
  behavior change: a nested `make image` now builds FULL (the disk store fits it); lean is the opt-in.
- **Reference docs:** `tasks/reference/minimal-nested-images.md` was retitled and reframed
  (auto-lean-when-nested → opt-in `MINIMAL_IMAGE`; title, intro banner, §1/§2 idiom, "For new projects",
  and the §4 re-sync grep), and `tasks/reference/nested-podman-design.md`'s PODMAN_RUN_FLAGS-convention
  overload paragraph was rewritten (image content = `MINIMAL_IMAGE`, run capability = `NESTED_PODMAN`,
  independent).
- **Cross-project conventions (the in-sandbox `CLAUDE.md` of both sandboxes):** runClaude
  `entrypoint/dotfiles/.claude/CLAUDE.md` and the runCrush client's baked
  `client/entrypoint/dotfiles/.config/crush/CLAUDE.md` both now state `NESTED_PODMAN` = run capability
  only and document `MINIMAL_IMAGE=1` as the opt-in image-content flag.
- **Personal overlay (`~/.ai-coding-conventions.personal.md`):** checked — it needed **no rename** (every
  `NESTED_PODMAN` reference there is run-capability: `PODMAN_RUN_FLAGS`, the `shell-exec` mirror note,
  the offline-export `make shell NESTED_PODMAN=1`, the conformance checklist, the `--cgroups` standing
  authorization). This corrected the pre-implementation guess that the template spec referenced a lean
  idiom — it carried none. At the maintainer's request the `MINIMAL_IMAGE` template idiom
  (`FLAG ?= $(if $(filter 1,$(MINIMAL_IMAGE)),0,1)`) was **added** to the overlay's Makefile-contract
  "Feature flags" bullet plus a matching conformance-checklist line, so new projects scaffolded from the
  template expose the lean option. (The overlay is a host-side mounted file, not a repo file — it was
  writable in-session, so the edit persists to the host file directly; nothing to git-stage for it.)

## Verification

`hanoi` was checked with `make -n image`: default → `BUILD_DOCS=1` (full); `MINIMAL_IMAGE=1` →
`BUILD_DOCS=0` (lean); `NESTED_PODMAN=1` → still `BUILD_DOCS=1` (image content no longer affected by the
run flag); `MINIMAL_IMAGE=1 BUILD_DOCS=1` → `BUILD_DOCS=1` (per-flag override wins).

## See also

- `tasks/archive/2026/09/27/dir-backed-nested-podman-storage.md` — the storage half; the disk store is
  what made the lean image optional rather than a nested necessity.
- `tasks/reference/minimal-nested-images.md` — the reframed `MINIMAL_IMAGE` standard + the per-project
  survey/rollout table.
- runCrushInContainer `tasks/reference/nested-podman-vs-image-content.md` — the original overload bug.
