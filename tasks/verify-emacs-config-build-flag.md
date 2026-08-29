# Rebuild-verify the USE_EMACS_CONFIG build flag

**Status:** proposed — needs go-ahead
**Priority:** 6
**Difficulty:** 2

## Goal

The `USE_EMACS_CONFIG` opt-out flag was added in
`tasks/separate-general-and-personal-conventions.md` (Makefile default `1`, Dockerfile
`ARG USE_EMACS_CONFIG=0`, gating a `RUN if [ "$USE_EMACS_CONFIG" != "1" ]; then rm -rf
/root/.emacs.d; fi` right after `COPY entrypoint/dotfiles/ /root/`). The logic is a
trivial conditional and can't affect the package install, so it was **not** rebuild-tested
when added (a full ~430-package `make image` is slow). Confirm it actually behaves before
trusting it.

## Verify

Build both flag values and check the sentinel — `/root/.emacs.d` present **iff** the flag
is on. The raw `podman run` checks below pass `--cgroups=disabled` explicitly — harmless
belt-and-braces for nested runs (see the nested-podman reference doc); a plain host
`make image` is simplest if not nested.

- **Default / on:** `make image` (flag defaults to `1`) → the built image **has**
  `/root/.emacs.d`.
  - Check: `podman run --rm --cgroups=disabled claudecontainer test -d /root/.emacs.d && echo present`
- **Off:** `make image USE_EMACS_CONFIG=0` → the built image **lacks** `/root/.emacs.d`
  (the `rm -rf` fired).
  - Check: `podman run --rm --cgroups=disabled claudecontainer test -d /root/.emacs.d || echo absent`
- **Bare build (no Makefile) is lean by default:** `podman build -t emacstest .` (ARG
  defaults `0`) → **lacks** `/root/.emacs.d`, confirming the fleet convention (bare build
  off, `make` opts in).

Both images should still launch a working `make shell` (the flag only touches the Emacs
tree, nothing else). Manage the RAM-backed nested store between builds (`podman rmi` under
pressure).

## Done when

Sentinel present-iff-on confirmed across all three builds, and `make shell` still works
with the flag off.
