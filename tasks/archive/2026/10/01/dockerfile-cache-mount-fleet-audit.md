# Fleet audit: ensure `--mount=type=cache` on package/dep-install RUNs in every project Dockerfile

**Status:** complete
**Completed:** 2026-10-01 (William Emerison Six <billsix@gmail.com>)

## What this did

Swept every project's Dockerfile(s) and made sure each package-install / dependency-fetch `RUN`
carried a `--mount=type=cache`, so rebuilds reuse downloaded packages and wheels. 31 Dockerfiles
were edited and staged per repo for the maintainer to commit.

**Trigger:** geometricalgebra's `make format` / `make test` did a slow partial rebuild on every
source edit because its editable-install `RUN` lacked a uv cache mount, so JupyterLab and others
re-downloaded each time. Fixed there (`/root/.cache/uv`) and build-verified; the maintainer then
asked for the fleet sweep.

## Scope

Workable repos only (billsix or local-IP remotes, per "Upstream-only checkouts are READ-ONLY"):
geometricalgebra, apue, gltron, graphicalcontainer, hanoi, multivariate-math, smalltalk, smc,
spimulator (+ `pgu/`), texExpToPng, modelviewprojection, impo, runClaudeInContainer,
runCrushInContainer (`client/`), billsEmacsConfigs, and imps.

**Skipped by maintainer decision (2026-10-01)** to avoid upstream merge conflicts:
`n64/mm/2ship2harkinianBills` (a fork with an upstream-authored Dockerfile),
`n64/ocarina/Shipwright` (a mirror of HarbourMasters Shipwright), and `Craft/deps/curl` (curl's
own vendored Dockerfile).

## Cache targets used

- **dnf:** `/var/cache/libdnf5` + `/var/lib/dnf`, effective only with `keepcache=True`.
- **apt:** `/var/cache/apt` + `/var/lib/apt` with `sharing=locked`; Ubuntu's
  `/etc/apt/apt.conf.d/docker-clean` must be removed or the mount is ineffective.
- pip `/root/.cache/pip`; uv `/root/.cache/uv`; cargo `/root/.cargo/registry` (+ `git`); go
  `/root/.cache/go-build` + `/root/go/pkg/mod`; npm `/root/.npm`; gem `/root/.gem`; cabal
  `/root/.cabal`; opam `/root/.opam/download-cache`; nuget `/root/.nuget/packages`; gradle
  `/root/.gradle/caches`; maven `/root/.m2`.

A cache mount is discarded after the build, so for a self-contained image the deps must still
land in a committed path; the mount only speeds rebuilds.

## Results (31 Dockerfiles)

- **geometricalgebra (1):** uv mount on the editable install.
- **Core template (5):** hanoi (uv), multivariate-math (pip), spimulator (npm),
  modelviewprojection (uv), runCrushInContainer/client (go-build + go/pkg/mod).
- **imps (9):** 5 Ubuntu files (BanjoKazooie, MajorasMask ×2 RUNs, MajorasMask.ubuntu26.04,
  OcarinaOfTime ×2, SuperMario64 ×2 apt + pip) got apt mounts, `rm -f` of `docker-clean`, and their
  `rm -rf /var/lib/apt/lists/*` dropped; 4 Fedora files (gzdoom, neverball, dash, ripgrep) had the
  cache-defeating `dnf clean all` dropped. The intentionally baked offline caches (fossify Gradle,
  ripgrep cargo) were preserved.
- **billsEmacsConfigs (16):** npm (bash, ksh, zsh, typescript ×2, python), pip (python), cargo
  (rust), go (×2), gem (ruby), nuget (csharp ×2), maven (java), gradle (kotlin), opam (ocaml), cabal
  (haskell), plus real but non-standard targets for racket (`/root/.cache/racket`), scala
  (`/root/.cache/coursier`) and swift (`/root/.cache/org.swift.swiftpm`). c, cpp, zig and nushell
  needed nothing.
- **Already cached, unchanged:** apue, gltron, graphicalcontainer, smalltalk, smc, spimulator/pgu,
  texExpToPng, impo, runClaudeInContainer (its remaining fetches are curl-pipe installers with no
  cache target).

## Verification (depth agreed with the maintainer, 2026-10-01)

geometricalgebra was build-verified green. The apt transform and a sample of each group's diffs
were syntax-checked. No fleet-wide build was run (hours); a cache-mount addition is ineffective at
worst, not breaking, so each project's next real build confirms it.
