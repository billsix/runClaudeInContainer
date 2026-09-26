#!/usr/bin/env bash
# Install Lean 4 (https://lean-lang.org) — the open-source theorem prover / proof
# assistant — via elan, its official toolchain manager. Lean is not a Fedora dnf
# package; elan is fetched with the official curl installer (the same
# network-at-build style this image already uses for other tools, e.g. Claude Code).
# elan installs into $HOME/.elan and this pulls the default *stable* toolchain
# (lean + lake), baking it into the image layer so an exported image has Lean
# offline. The Dockerfile adds $HOME/.elan/bin to PATH (ENV) after running this.
#
# Host-runnable: on a bare Fedora host, run this, then add ~/.elan/bin to PATH.
set -e
curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
export PATH="$HOME/.elan/bin:$PATH"
elan default stable
lean --version
