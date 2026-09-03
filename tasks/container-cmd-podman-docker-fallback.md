# `CONTAINER_CMD` should default to podman, fall back to docker — convention + fleet rollout

**Status:** proposed — needs go-ahead
**Priority:** 4
**Difficulty:** 4

## BLUF

Every container-per-project Makefile currently hardcodes `CONTAINER_CMD = podman`, so the projects don't run on
a host that has only docker. Change the idiom to auto-detect:
```make
CONTAINER_CMD ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)
```
Then (a) **document** it as a standing convention in the container-per-project template spec, (b) **roll it out**
to every project's Makefile, (c) apply it to **runClaudeInContainer** and **runCrushInContainer** themselves, and
(d) make sure the two sandboxes' **new-project scaffolding** emits the new idiom. "Done" = the convention is
documented once, every mounted container-template Makefile uses the auto-detect form, both sandbox repos use it,
and new projects are created with it.

## Context

**Read first:** the `PODMAN_RUN_FLAGS` rollout, which this mirrors exactly — same shape of change (a Makefile idiom
threaded fleet-wide, documented once, auto-detecting from the environment): `tasks/reference/nested-podman-design.md`
("The `PODMAN_RUN_FLAGS` convention") and its work record `tasks/archive/2026/08/29/nested-podman-run-flags-passthrough.md`.
Also the container-per-project template spec in the **personal overlay**
(`~/.ai-coding-conventions.personal.md` → "My project layout / Makefile contract") and
`entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md`.

**Current state (verified 2026-09-03):**
- `runClaudeInContainer/Makefile:16` — `CONTAINER_CMD = podman` (hardcoded, `=`).
- `runCrushInContainer/client/Makefile:18` — `CONTAINER_CMD  = podman` (hardcoded).
- Every mounted container-template project's Makefile has the same hardcoded line (the fleet PODMAN_RUN_FLAGS
  rollout touched these same files, so the project list is essentially that rollout's list).

**Why `?=` not `=`:** `?=` lets a caller or CI override (`make CONTAINER_CMD=docker …`), and lets the auto-detect
default apply only when unset — same reason `PODMAN_RUN_FLAGS` uses `?=`. **Caveat, attach it to the rollout step:**
the `$(shell …)` runs at Makefile parse time on the host; on a host with neither podman nor docker it resolves to
`docker` (the `||` fallback), which then fails at first use with a clear "command not found" — acceptable (there's no
container runtime anyway), but note it rather than adding a third error branch.

## Where the convention lives (the "where does it go" question the maintainer raised)

Same answer as PODMAN_RUN_FLAGS: the **executable idiom lives in each project's Makefile** (it's Makefile code, so it
can't live in the prose conventions), and the **convention is documented once** in the container-per-project template
spec in the personal overlay (the Makefile-contract section), so new/edited projects adopt it. The two sandbox repos
carry it in their own Makefiles *and* in whatever generates a new project's Makefile.

## Plan

1. **Document** the idiom in the personal-overlay Makefile-contract section (one paragraph, beside the
   `PODMAN_RUN_FLAGS` note) and in this repo's `README`/`CLAUDE.md` if they show the template Makefile header.
2. **Convert the two sandbox repos:** `runClaudeInContainer/Makefile:16` and `runCrushInContainer/client/Makefile:18`
   (and `server/Makefile` if it has one) → the `?=` auto-detect line.
3. **Fan out** to every mounted container-template project's Makefile (the PODMAN_RUN_FLAGS list), converting the
   hardcoded `CONTAINER_CMD = podman` to the auto-detect `?=` form. Mechanical; verify each still `make image`/`shell`
   parses (a `make -n shell` smoke test per repo).
4. **New-project scaffolding:** find where each sandbox creates a new project's Makefile (a template/skeleton or a
   documented "adding a project" step) and update it to emit the auto-detect line, so this doesn't regress on the next
   new project.
5. Save the rollout as an ad-hoc codemod under `tasks/adhoc/` (idempotent; prove with a double-run), per the
   ad-hoc-script convention — the same way the PODMAN_RUN_FLAGS fan-out was recorded.

## Decisions (settled with the maintainer, 2026-09-03)

1. **Single fan-out task, not one per project.** This doc IS the rollout task; the project list is enumerated here
   (the PODMAN_RUN_FLAGS fleet list). Matches the two prior fleet rollouts (PODMAN_RUN_FLAGS, shell-exec).
2. **Scope = the `CONTAINER_CMD` swap only.** Genuine docker-runtime compatibility (the `:Z` SELinux relabel,
   `--cgroups=disabled` being podman-only, rootless UID mapping) is a **separate** task to open only if the intent is
   to actually *run* on docker, not merely detect it. This task just makes the runtime auto-detected.

## Status / next

Design settled (above). **Not yet executed** — executing means editing ~45 fleet Makefiles + both sandbox repos +
the new-project scaffolding, a large multi-repo mutation, so it awaits an explicit "do the rollout" go-ahead.

## Open questions

1. **Execute the fleet rollout now, or leave queued?** The design is settled; this is just timing. *Recommend
   queuing it as its own focused session (a ~45-repo mechanical sweep deserves undivided attention + per-repo
   `make -n` verification), rather than interleaving it with the current impo work.*
