# Upgrade the container base from Fedora 44 to Fedora 45 (done)

Bumped `Dockerfile` to `fedora:45` and rebuilt this sandbox's image. Done LAST in
the fleet (it is the container this session runs in; the rebuild only affects
future launches, not the running session). Fleet-wide Fedora 44 → 45 bump
(William Emerison Six <billsix@gmail.com>, 2026-11-05).

## What broke and how it was fixed
This image's `01-install-base.sh` is the canonical ~430-package list the other
sandboxes mirror. Five packages failed to resolve on F45:

- **`dotnet-sdk-8.0`** → **`dotnet-sdk-10.0`** (F45 dropped 8.0; ships 10.0 LTS /
  11.0 preview).
- **`libgit2-devel`** → **`libgit2_1.9-devel`** (versioned package name in F45).
- **`pcre-devel`** → **dropped** (PCRE1 removed from F45; `pcre2-devel` already in
  the list).
- **`shfmt`** + **`procs`** → **dropped from the dnf list**; installed from upstream
  release binaries by the new `entrypoint/01b-install-binary-tools.sh` (shfmt
  mvdan/sh v3.14.1; procs dalance/procs v0.14.12; pinned, x86_64), keeping
  `01-install-base.sh` a single pure `dnf install`. Reconsider this fetch:
  `tasks/consider-dropping-shfmt-procs.md`.

Also updated the stale "Fedora 44" references in `CLAUDE.md` and `README.md`.

## Verification
`make image` nested: **EXIT=0**, tagged `claudecontainer:latest`. All 17 steps
passed — the dnf step resolved, the `01b` binary fetch installed shfmt + procs,
Claude Code installed, and the Lean/elan layer completed. (The maintainer's first
host build attempt failed only because it ran against the pre-edit base script via
a cached COPY layer; the nested build with all edits in place resolved cleanly.)

## Mirror
These base-list edits are canonical; the identical fixes were applied and verified
in `runCrushInContainer` (whose client reuses this list).
