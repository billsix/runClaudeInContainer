# Make the lean-image-when-nested convention a standard across every containerized project

**Status:** proposed — research done 2026-09-10; the convention text and the fleet survey are written
(`tasks/reference/minimal-nested-images.md`); **implementation needs go-ahead** (it edits the tracked
cross-project `CLAUDE.md`, its runCrushInContainer port, `nested-podman-design.md`, and the maintainer's
personal-overlay project template). Umbrella for the per-project children listed below. Created
2026-09-10 at the maintainer's request (William Emerison Six <billsix@gmail.com>: "make this idea of a
minimal image for nested podman use a standard across my projects … I want every new project to have
it").
**Priority:** 3
**Difficulty:** 3

## BLUF

runCrushInContainer proved the idiom (2026-09-10): `FULL_TOOLCHAIN ?= $(if $(filter
1,$(NESTED_PODMAN)),0,1)` makes a nested `make image` build the lean 1.65 GB image and a host `make
image` the full 22 GB one, no flag to remember — the `PODMAN_RUN_FLAGS` pattern applied to a build
flag. This task makes that the rule everywhere: **every optional-feature build flag (editors, docs
toolchains, notebooks, GUI extras) defaults to its lean value when `NESTED_PODMAN=1`; a project's
gates and its product's own build dependencies are never trimmed; new projects start that way.** Done =
the rule is in the tracked `CLAUDE.md` (+ the Crush port), the design doc, and the personal template;
each child task below is implemented or recorded N/A; the reference doc's table has measured sizes.

## Context — read first

- `tasks/reference/minimal-nested-images.md` — the standard in full, the idiom, the rules, the
  per-project survey with what "minimal" means for each, and the N/A cases.
- `tasks/reference/nested-podman-design.md` › "The `PODMAN_RUN_FLAGS` convention" — the sibling
  convention this one copies, including the paragraph already added 2026-09-10 pointing at runCrush.
- runCrushInContainer `client/Makefile` (`FULL_TOOLCHAIN`) and its `tasks/archive/2026/09/10/minimal-client-image.md` —
  the reference implementation and the decisions behind it (same image tag for both variants; no
  language servers in the lean image).
- `entrypoint/dotfiles/.claude/CLAUDE.md` › "Running projects in a nested container" (points 1–2) —
  where point 3 goes; and "My project layout" — which defers the template spec to the personal overlay.

## Plan

### 1. The convention text (this repo, runCrushInContainer, the personal overlay)

- [ ] `entrypoint/dotfiles/.claude/CLAUDE.md` "Running projects in a nested container": add **point 3 —
      the lean-image default** (draft in the reference doc §2): what the idiom is, which flags flip
      (editors/docs/notebooks/GUI extras), which never do (gates, product build deps), that `FLAG=1` on
      the command line overrides, and that new template projects carry it from the start. Keep it to one
      paragraph; the reference doc carries the detail.
- [ ] runCrushInContainer `client/entrypoint/dotfiles/.config/crush/CLAUDE.md` § "Running projects in a
      nested container": the same point 3 (its sibling task: runCrushInContainer
      `tasks/port-lean-image-nested-convention.md`).
- [ ] `tasks/reference/nested-podman-design.md`: promote the 2026-09-10 runCrush paragraph into a named
      sub-convention ("The lean-image default") with the rollout table (which project, which flags,
      status) — mirroring the PODMAN_RUN_FLAGS rollout record.
- [ ] **Personal overlay (maintainer's own edit, host file `~/.ai-coding-conventions.personal.md`):** the
      container-per-project template spec lives there (blank in the sandbox, so the agent cannot edit
      it); add to the template's Makefile flag block the nested-aware default for every optional flag,
      so a new project has it on day one. Suggested text in the reference doc §2.

### 2. The rollout — one child task per project (research done; implementation per child)

| Project | Child task | Flags that flip nested | Stay on (gate / product) | Status |
|---|---|---|---|---|
| runCrushInContainer | `tasks/archive/2026/09/10/minimal-client-image.md` | `FULL_TOOLCHAIN` | — | **done** (reference) |
| apue | `tasks/minimal-nested-image.md` | new `USE_EMACS` | musl build | proposed |
| epix-mirror | `tasks/minimal-nested-image.md` | new `BUILD_DOCS`, `USE_JUPYTER` | meson/nanobind/ASan | proposed |
| geometricalgebra | `tasks/minimal-nested-image.md` | `BUILD_DOCS`, `USE_EMACS` (make it live), new `USE_JUPYTER` | `make test`, venv/pyright | proposed |
| gltron | `tasks/minimal-nested-image.md` | `USE_GRAPHICS`, new `USE_EMACS` | image-time `ctest` | proposed |
| hanoi | `tasks/minimal-nested-image.md` | `BUILD_DOCS` | — | proposed |
| programmingFromTheGroundUp | `tasks/minimal-nested-image.md` | `BUILD_DOCS`, `USE_GRAPHICS`, new `USE_EMACS` | i686 runtime, debuggers | proposed |
| pyNuklear | `tasks/minimal-nested-image.md` | none — already lean | — | proposed (measure + PODMAN_RUN_FLAGS) |
| smalltalk | `tasks/minimal-nested-image.md` | `USE_EMACS` | gst build deps incl. GUI libs | proposed |
| spimulator | `tasks/minimal-nested-image.md` | `USE_EMACS`, `BUILD_DOCS` | **`BUILD_TREE_SITTER`, `RUN_SANITIZERS`** (gates) | proposed |
| texExpToPng | `tasks/minimal-nested-image.md` | `USE_EMACS` | TeX (product) | proposed |
| billsEmacsConfigs (20) | `tasks/minimal-nested-image.md` | `USE_EMACS` ×20 (decided: off nested) | each language toolchain + TeX | proposed |
| modelviewprojection | `tasks/minimal-nested-image.md` | `USE_EMACS`, `USE_JUPYTER` | **`BUILD_DOCS`** (book gate), **`USE_X_WINDOWS`** (headless GL) | proposed |
| runClaudeInContainer (this image) | `tasks/minimal-sandbox-image.md` | new `FULL_TOOLCHAIN` | Claude Code installer | proposed |
| imps/n64 (4 Ubuntu CI mirrors) | — | N/A: the Dockerfiles mirror upstream CI by design | | recorded |
| impo/openstax (16 osbooks) | — | N/A: TeX *is* the product; nothing to cut (they still need the `?=` PODMAN_RUN_FLAGS form) | | recorded |
| Craft, imps, impo (carriers) | — | N/A: no container | | recorded |

Out of the survey's criterion ("projects with a `CLAUDE.md`") but containerized: `lldbassemblyhelper`,
`graphicalcontainer`, `multivariate-math`, `n64/billBuildMM` — listed in the reference doc, no tasks.

### 3. Verification

Each child: a flagless nested `make image` builds, the project's gate passes in it, both sizes recorded.
This umbrella: `grep -rn "NESTED_PODMAN)),0,1)" /foo/opt/*/Makefile` (from the sandbox) lists every
converted project — compare against the table.

## Open questions

Both resolved 2026-09-10 (William Emerison Six <billsix@gmail.com>):

1. ~~billsEmacsConfigs: flip `USE_EMACS` nested?~~ **Yes — turn it off** ("sure, turn it off").
2. ~~Sequencing~~ — **the recommendation**: implement §1 (the convention text) first, then the four
   children with real savings (epix-mirror, geometricalgebra, modelviewprojection, this repo's own
   image); the remaining one-line flag flips happen when each repo is next visited, not in one big
   pass. Nothing is implemented until the maintainer says go ("don't implement it yet, just make the
   tasks").
