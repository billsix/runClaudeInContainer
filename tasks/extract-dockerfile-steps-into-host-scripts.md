# Extract host-runnable steps out of Dockerfiles into standalone scripts

**Status:** proposed — first pass = modelviewprojection, needs go-ahead
**Priority:** 5
**Difficulty:** 6
**Created:** 2026-08-12
**Updated:** 2026-08-12 — Bill: try it in **modelviewprojection first**, expand after
confirmation; update runClaudeInContainer's CLAUDE.md with the sub-container convention

**Motivation:** much of what a project's `Dockerfile` does is not actually
Docker/Podman-specific — it's ordinary host setup (install these packages, build this
dependency, fetch this pinned tool) that happens to run inside `RUN` lines. If those
steps lived in **standalone scripts**, they could run **on a bare host or in a guest
that has no docker/podman**, and the Dockerfile would just call the script. The obvious
first case: **package installation** — a `dnf install ...` list embedded in a `RUN` is
trivially a `install-packages.sh` that runs the same on a host. Investigate what *else*
across the projects is similarly extractable, then codify the pattern.

## Goal

1. A **reusable pattern** for splitting a Dockerfile's host-agnostic setup into scripts
   the Dockerfile sources, so the same setup runs with or without a container runtime.
2. A survey, **across my mounted projects**, of which Dockerfile steps qualify.
3. An update to **runClaudeInContainer's root `CLAUDE.md`** stating what should be done
   for sub-containers (the projects the sandbox builds) re: this extraction.

## What to investigate

1. **Inventory Dockerfile steps across projects** (start with the mounted set:
   runClaudeInContainer, geometricalgebra, modelviewprojection, and others under
   `/*/opt/*`). Classify each `RUN` as:
   - **Host-agnostic** → extractable (package installs, building/installing a pinned
     dependency like texExpToPng, fetching + verifying a tool, `pip install` sets,
     language-toolchain setup).
   - **Container-specific** → stays in the Dockerfile (`COPY`, `ENTRYPOINT`, `ARG`/build
     flags, cache-mount plumbing, `WORKDIR`, image-layer ordering, `USER`).
2. **The package-install case, done right.** Extracting a `dnf install` means deciding:
   how the package list is stored (a file the script reads vs inline), how to keep the
   **dnf cache-mount speedup** the Dockerfile relies on (the script won't have
   `--mount=type=cache` — measure the rebuild-time cost and decide whether the Dockerfile
   keeps the cache mount while `RUN`-ing the script, which still works), and distro
   assumptions (these are all Fedora `dnf`; a host script should fail loudly on non-dnf,
   not silently). **Caveat to carry:** don't lose the cache-mount idiom the project
   `CLAUDE.md` says to preserve — the extraction must keep it, not drop it.
3. **What generalizes vs what's per-project.** Some steps (Fedora package install) share
   a shape across projects; others are one-offs. Decide what becomes a shared helper vs a
   per-repo script.

## Plan (confirmed 2026-08-12)

- **First pass: modelviewprojection only.** Do the worked extraction there — start with
  package install, then whatever else in mvp's Dockerfile is host-agnostic (per the
  classification above). Script(s) saved under `tasks/adhoc/<this-slug>/` per the
  ad-hoc-scripts convention; the Dockerfile changed to source them. Verify the image
  still builds (`make image`, nested) **and** the script runs standalone on a bare host.
- **Then expand after Bill confirms** — apply the pattern to the other projects.
- **Update runClaudeInContainer's CLAUDE.md** with the sub-container convention (which
  Dockerfile steps become host-runnable scripts, where they live, and that they must
  work with no container runtime). Note the *which* CLAUDE.md below.

## Deliverables

- The mvp worked example (scripts + Dockerfile edit), verified both ways.
- A short findings write-up of what else across projects is extractable (candidate:
  promote to `tasks/reference/` as a durable pattern description) — as the input to the
  "expand after confirmation" step.
- The **CLAUDE.md addition** in runClaudeInContainer. Home: the guidance is cross-project
  (it governs how *any* project's container is built), so it belongs in the mounted
  cross-project `entrypoint/dotfiles/.claude/CLAUDE.md` (and/or the container-per-project
  template section), not only the repo-local root `CLAUDE.md`.

## Open questions

1. **Where do shared scripts live** if a step generalizes across repos — in each repo
   (self-contained, duplicated) or centralized in runClaudeInContainer and mounted?
   Recommend self-contained per-repo scripts to start; centralize only if duplication
   becomes real. (Not blocking the mvp first pass.)

## See also

- Root `CLAUDE.md` → "Conventions for changing this repo" (package list, dnf cache
  mounts) and the container-per-project template in the cross-project `CLAUDE.md`.
- `tasks/sphinx-human-readable-reference-docs.md` — also touches "Dockerfiles build
  outputs"; coordinate the Dockerfile edits.
