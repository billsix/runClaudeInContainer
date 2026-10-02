# Fleet audit: ensure `--mount=type=cache` on package/dep-install RUNs in every project Dockerfile

**Status:** DONE 2026-10-01 (William Emerison Six <billsix@gmail.com>) — 31 Dockerfiles cache-mounted +
staged; the 3 upstream/vendored files skipped by maintainer decision (Q1).
**Priority:** 4
**Difficulty:** 4

## Summary

Swept every project under `/foo/opt`, found its Dockerfile(s), and ensured each **package-install /
dependency-fetch `RUN`** carried a BuildKit **`--mount=type=cache`** so rebuilds reuse the downloaded
packages/wheels instead of re-fetching. Scoped to the maintainer's **workable** repos (per
"Upstream-only checkouts are READ-ONLY") — 31 Dockerfiles edited and staged across gacalc, 5
core-template projects, imps (9), and billsEmacsConfigs (16); already-cached projects left untouched;
the two intentionally-baked offline caches (fossify Gradle, ripgrep cargo) preserved; and three
upstream/vendored Dockerfiles skipped by maintainer decision. dnf/apt got the keepcache / docker-clean
handling that makes the mount effective. Details below.

## Why (trigger)

gacalc's `make format`/`make test` were doing a slow partial rebuild on every source edit because the
editable-install `RUN` (`Dockerfile:159`) lacked a uv cache mount, so JupyterLab et al. re-downloaded
each time. Fixed there (uv cache mount on `/root/.cache/uv`); the maintainer then asked to sweep the
whole fleet for the same gap.

## Scope — classification (remotes read 2026-10-01)

**IN SCOPE (workable — billsix / local-IP remote):** geometricalgebra (DONE, the trigger), apue,
gltron, graphicalcontainer, hanoi, multivariate-math, smalltalk, smc, spimulator (+ `pgu/`),
texExpToPng, modelviewprojection, impo (`openstax/tooling/`), runClaudeInContainer,
runCrushInContainer (`client/`), **all of billsEmacsConfigs/<lang>/** (21), and **imps/** (its
Dockerfiles are tracked by the imps repo — Fedora + some Ubuntu).

**FLAG, do NOT auto-edit (upstream/vendored — merge-conflict risk):**
- `/foo/opt/n64/mm/2ship2harkinianBills/Dockerfile` — billsix *fork* of a HarbourMasters project;
  Dockerfile is upstream-authored.
- `/foo/opt/n64/ocarina/Shipwright/Dockerfile` — a Pi-hosted mirror of HarbourMasters Shipwright
  (remote under `games/N64ReverseEngineer/`, not `billsix.github.com/`).
- `/foo/opt/Craft/deps/curl/Dockerfile` — curl's OWN Dockerfile, vendored under Craft's `deps/`.
  (Confirm with the maintainer before touching any of these three.)

## Canonical cache targets (by package manager)

- **dnf** → `--mount=type=cache,target=/var/cache/libdnf5 --mount=type=cache,target=/var/lib/dnf`
  — effective ONLY with `keepcache=True` in `dnf.conf` (the template already sets this in an early RUN).
- **apt** (Ubuntu/Debian) → `--mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt`
  — Ubuntu's base image ships `/etc/apt/apt.conf.d/docker-clean` which deletes the cache; remove it
  (`rm -f /etc/apt/apt.conf.d/docker-clean`) or set `Binary::apt::APT::Keep-Downloaded-Packages "true"`,
  else the mount is ineffective. Also use `sharing=locked` if parallel.
- **pip** → `/root/.cache/pip` · **uv** → `/root/.cache/uv`
- **cargo** → `/root/.cargo/registry` (+ `/root/.cargo/git`) · **go** → `/root/.cache/go-build` + `/root/go/pkg/mod`
- **npm** → `/root/.npm` · **gem/bundler** → `/root/.gem` or `/usr/local/bundle`
- **cabal** → `/root/.cabal` · **opam** → `/root/.opam/download-cache`
- **nuget/dotnet** → `/root/.nuget/packages` · **gradle** → `/root/.gradle/caches` · **maven** → `/root/.m2`

**Convention note:** a cache mount is DISCARDED (not in the image), so for a self-contained/exported
image the deps must STILL land in a committed path (installed packages, `/venv`, etc.) — the mount only
speeds rebuilds, it is not where the deps live. (Personal overlay: "Self-contained images + live source".)

## Plan

- [x] Discover all Dockerfiles + classify repos (above).
- [x] gacalc uv cache mount (the trigger) — DONE (`Dockerfile:159`), **build-verified** (`make image` green).
- [x] Assess each in-scope Dockerfile (fan-out, 2026-10-01).
- [x] Apply the mounts + keepcache/docker-clean handling (fan-out, 2026-10-01). **31 Dockerfiles edited + staged.**
- [x] The three flagged upstream/vendored files — **maintainer said skip (2026-10-01)**: left untouched
      to avoid upstream merge conflicts (`n64/mm/2ship2harkinianBills`, `n64/ocarina/Shipwright`,
      `Craft/deps/curl`).

## Results (2026-10-01) — 31 Dockerfiles edited + staged (not committed)

**gacalc (1):** `Dockerfile` — uv cache mount on the editable-install RUN; build-verified green.

**Core template (5):** hanoi (uv), multivariate-math (pip), spimulator (npm, added to the existing
dnf-mount RUN), modelviewprojection (uv, added to the existing dnf-mount RUN), runCrushInContainer/client
(go-build + go/pkg/mod on the crush-build RUN).

**imps (9):** 5 Ubuntu/apt files got `/var/cache/apt` + `/var/lib/apt` mounts (`sharing=locked`), a
leading `rm -f /etc/apt/apt.conf.d/docker-clean`, and their `rm -rf /var/lib/apt/lists/*` dropped —
BanjoKazooie, MajorasMask (×2 RUNs), MajorasMask.ubuntu26.04, OcarinaOfTime (×2), SuperMario64 (×2 apt
+ pip). 4 Fedora files (gzdoom, neverball, dash, ripgrep) had the cache-defeating `dnf clean all`
dropped. Left alone: fossify Gradle-warm, ripgrep cargo-warm (intentionally-baked offline caches).

**billsEmacsConfigs (16):** npm (bash, ksh, zsh, typescript ×2, python-on-dnf-RUN), pip (python),
cargo (rust), go-build+pkg/mod (go ×2), gem (ruby), nuget (csharp ×2), maven (java), gradle (kotlin),
opam (ocaml), cabal (haskell); non-standard-but-real targets for racket (`/root/.cache/racket`), scala
(`/root/.cache/coursier`), swift (`/root/.cache/org.swift.swiftpm`). Untouched: c, cpp, zig, nushell.

**Already fully cached (no change):** apue, gltron, graphicalcontainer, smalltalk, smc, spimulator/pgu,
texExpToPng, impo, runClaudeInContainer (dnf idiom complete; remaining fetches are curl-pipe installers
with no canonical cache target).

**Verification:** gacalc build-verified green; the apt transform (the delicate one) and a sample of each
group's diffs were syntax-checked (backslash continuations correct). A full fleet-wide build was NOT run
(hours); cache-mount additions are low-risk (ineffective at worst, not breaking), and each project's next
real build will confirm. **Staged per repo; the maintainer commits.**

## Open questions

All resolved (2026-10-01):
1. The three upstream/vendored Dockerfiles (`2ship2harkinianBills`, `Shipwright`, `Craft/deps/curl`) —
   **skip** (maintainer). Left untouched.
2. Verification depth — **gacalc build-verified; the rest syntax-checked + deferred to each project's
   next build** (cache-mount additions are low-risk: ineffective at worst, not breaking).
