#!/usr/bin/env bash
# Format this repo's shell scripts in place with shfmt.
#
# Scoped to entrypoint/*.sh ONLY.  The vendored entrypoint/dotfiles/.emacs.d/ tree is
# off-limits (see CLAUDE.md) and must never be reformatted, so it is not matched here.
#
# Indent: 4 spaces (`-i 4`) -- matches the dominant style already in these scripts
# (01-install-base.sh, the ~430-package list, uses 4-space), so churn stays minimal.
#
# Portable: run from the repo root -- in-container via `make format` (which cd's to the
# mounted repo so fixes land on the host), or on the host directly (shfmt is in the
# image and commonly on dev hosts).  Relative paths only, so a single
# `cd <repo-root> && bash entrypoint/format.sh` works in both.
#
# One command, so its exit status IS the gate (safe by shape -- no accumulation needed).
shfmt -w -i 4 entrypoint/*.sh
