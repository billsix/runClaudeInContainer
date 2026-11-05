# Upgrade the container base from Fedora 44 to Fedora 45

**Status:** in progress
**Priority:** 5
**Difficulty:** 5

## BLUF
Bump `Dockerfile` to `fedora:45` and build THIS sandbox's image nested. Done
LAST in the fleet (it is the container this session runs in; a nested rebuild
tests the new base without affecting the running session). "Done" = the sandbox
image builds on 45.

## Context
Fleet-wide Fedora 44 → 45 bump (William Emerison Six <billsix@gmail.com>,
2026-11-05). Fedora 45: GCC 16.2 / clang LLVM 23, Python 3.15, glibc 2.44, and
**Podman 6** (drops cgroups v1 — the nested `--cgroups=disabled` flag stays
valid). This image bakes the full dev toolchain + Claude Code; risk is a base
package renamed/dropped in F45. The running session stays on the F44 image; the
rebuild only affects future launches.

## Plan
1. `Dockerfile`: `fedora:44` → `fedora:45`. 2. `make image` nested (LAST).
3. Fix breakage minimally (discretion; log here). 4. Stage by path; archive.

## Notes / findings
(appended as the build runs)
