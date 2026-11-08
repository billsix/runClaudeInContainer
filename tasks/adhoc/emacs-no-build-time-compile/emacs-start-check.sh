#!/usr/bin/env bash
#
# emacs-start-check.sh IMAGE MOUNT_FLAG... -- start Emacs in batch inside IMAGE with
# the project's own Emacs mount(s) and report: Emacs's exit status, how many .elc the
# run-time compile (init.el compile block) left in the mounted elpa/,
# and any error lines Emacs printed. Used to verify the "no build-time MELPA install"
# change in each project (runClaudeInContainer tasks/emacs-contract-conformance.md).
#
# Example: emacs-start-check.sh localhost/gltron \
#            -v "$PWD"/entrypoint/dotfiles/.emacs.d/:/root/.emacs.d/:U,z   # run from the gltron checkout
set -uo pipefail

image="$1"; shift
podman run --rm --cgroups=disabled --network=none --entrypoint /bin/bash "$@" "$image" -c '
  emacs --batch -l /root/.emacs.d/init.el -f kill-emacs >/tmp/e.log 2>&1
  echo "emacs-exit=$?"
  echo "elc=$(find /root/.emacs.d/elpa -name "*.elc" | wc -l)"
  echo "error-lines=$(grep -c -i -E "^error|error:|cannot open load file" /tmp/e.log)"
  grep -i -E "^error|error:|cannot open load file" /tmp/e.log | head -5
'
