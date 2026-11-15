# Drop procs; keep shfmt (the Fedora 44 leftovers in /usr/local/bin)

**Status:** proposed — decided 2026-11-15 (drop procs, keep shfmt); ready to implement
**Priority:** 6
**Difficulty:** 2
**Created:** 2026-11-06 (William Emerison Six <billsix@gmail.com>); investigated 2026-11-15
**Spans:** this repo and github.com/billsix/runCrushInContainer (its client reuses the same
`01b-install-binary-tools.sh`; the twin task there points here). Decide once, apply in both.

## BLUF

The only Fedora 44 leftovers either sandbox installs outside dnf are **shfmt** and **procs**, fetched as
pinned, checksum-verified upstream binaries into `/usr/local/bin` by
`entrypoint/01b-install-binary-tools.sh`. Fedora retired both from Fedora 45: shfmt because its package
failed to build, procs because it was orphaned. **Recommendation: drop procs** (nothing uses it, and
Fedora 45's `htop`, `btop`, `ps` and `pstree` cover it), and **keep shfmt**, because no Fedora 45
package formats shell and both sandboxes' `make format` gates run it. Done means procs is gone from both
images and every doc, and shfmt's status is recorded as a deliberate keep.

## Decision (William Emerison Six <billsix@gmail.com>, 2026-11-15)

**Drop procs and keep shfmt**, in both runClaudeInContainer and runCrushInContainer, as recommended
below: procs is unused and covered by the packaged `htop`, `btop`, `ps` and `pstree`; shfmt has no
Fedora 45 replacement and runs both sandboxes' `make format` gates (and, in runCrush, the bash language
server's formatting). shfmt stays a pinned, checksum-verified upstream binary.

## Context

### What is in /usr/local/bin (checked 2026-11-15)

`01-install-base.sh`, `01b-install-binary-tools.sh`, `install-lean.sh` (this repo's own scripts),
`shfmt` and `procs`. The other Fedora 45 changes in the upgrade
(`tasks/archive/2026/11/06/upgrade-to-fedora-45.md`) were swaps to other dnf packages
(`dotnet-sdk-8.0` → `dotnet-sdk-10.0`, PCRE1's `pcre-devel` dropped for the already-present
`pcre2-devel`), not vendored binaries.

### Why Fedora dropped them (from Fedora's dist-git, 2026-11-15)

- **shfmt** — source package `golang-mvdan-sh-3`. Its rawhide `dead.package` reads "Retired: Fails to
  build" (releng ticket https://forge.fedoraproject.org/releng/tickets/issues/13259). It has no `f45`
  branch. The package page lists the maintainer as orphan and the last build as 3.7.0 for Fedora 42–44,
  well behind upstream's v3.14.1. Sources: https://src.fedoraproject.org/rpms/golang-mvdan-sh-3,
  https://packages.fedoraproject.org/pkgs/golang-mvdan-sh-3/shfmt/. Other projects hit the same break
  and switched to the pinned upstream binary, e.g. https://github.com/openhpc/ohpc/pull/2855.
- **procs** — source package `rust-procs`. Its rawhide `dead.package` reads "Orphaned for 6+ weeks". Fedora
  retires a package that stays orphaned for six weeks
  (https://docs.fedoraproject.org/en-US/fesco/Policy_for_orphan_and_retired_packages/). Its maintainer
  had orphaned it in 2022 as a leaf package nothing else depends on
  (https://www.spinics.net/lists/fedora-devel/msg305988.html). No `f45` branch. Source:
  https://src.fedoraproject.org/rpms/rust-procs.

### What each provides, who uses it, and the Fedora 45 replacements

| Tool | What it does | Used by | Fedora 45 replacement |
|---|---|---|---|
| **shfmt** (mvdan/sh) | Formats (and parses) POSIX/bash/mksh shell scripts; `-d` diffs, `-w` rewrites | `make format` in both sandboxes (`entrypoint/format.sh`, `client/entrypoint/format.sh`); `nodejs-bash-language-server` formats through it when it is on `PATH` (runCrush declares that LSP); billsEmacsConfigs' `bash`/`ksh`/`zsh` format gates | **None that formats.** `ShellCheck` (packaged) lints only. The alternatives are building it from source with the image's Go (`go install mvdan.cc/sh/v3/cmd/shfmt@v3.14.1`, golang 1.27.4 is packaged), which fetches Go modules at build and so needs vendoring for the airgap rebuild, or no shell formatting at all. |
| **procs** (dalance/procs) | A `ps` replacement: coloured, searchable process list with ports, Docker names, tree view | Nothing in either repo or the fleet (`git grep -w procs` in every mounted repo's scripts and Makefiles: none) | `htop` 3.5.3 and `btop` 1.4.7 (interactive), `ps` from `procps-ng` 4.0.6, `pstree` from `psmisc` 23.7. All packaged; `htop` and `btop` are already in `01-install-base.sh`, and `ps` is always present. |

### The recommendation and why

- **Drop procs.** Nothing uses it; it costs a GitHub download, a version pin and a checksum to maintain;
  the packaged tools above do the same job.
- **Keep shfmt — a strong reason not to drop it.** It is the formatter behind both sandboxes'
  `make format` gates (and so behind the session-end "run the format gate" rule), and no Fedora 45
  package replaces it. The binary fetch is now pinned and checksum-verified (2026-11-15). Building it from
  source instead would trade one download for a Go module fetch plus vendoring, for no gain.
- If shfmt is ever dropped anyway, `format.sh` in both sandboxes must change too, or `make format` fails.

### Side finding (other repo, not this task's scope)

billsEmacsConfigs' `bash/entrypoint/format.sh` (and its `ksh`/`zsh` siblings) runs shfmt only
`if command -v shfmt`, on a Fedora 45 image without shfmt, so its format gate silently does nothing.
It also formats `src/texExpToPng`, which looks copied from another project. Its own task, if wanted.

## Plan (on go-ahead)

1. `entrypoint/01b-install-binary-tools.sh`: remove the procs block, `PROCS_VERSION`, `PROCS_SHA256`
   and `unzip` from its tool check (if nothing else needs it); keep shfmt. Re-copy the script into
   runCrushInContainer's `client/entrypoint/` (the two are identical).
2. Docs: drop procs from `CLAUDE.md`, `README.md`, the Dockerfile comment,
   `tasks/reference/sandbox-capability-map.md` (and runCrush's baked copy), and say shfmt is a
   deliberate keep with the reason.
3. Verify: `make image` in both (nested is fine); `command -v procs` fails, `shfmt --version` prints
   v3.14.1, `make format` passes.
