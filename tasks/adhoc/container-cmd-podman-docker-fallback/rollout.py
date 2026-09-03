#!/usr/bin/env python3
"""Roll out the podman/docker auto-detect CONTAINER_CMD across the fleet.

Replaces a hardcoded `CONTAINER_CMD = podman` (any run of spaces) with
    CONTAINER_CMD ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)
in every workable container-per-project Makefile, so the runtime auto-detects
(podman preferred, docker fallback) and stays overridable (`make CONTAINER_CMD=docker`).

EXCLUDES the upstream OpenStax source checkouts: each `/mnt/sda1/openstax/osbooks-*`
is its own git repo (root ends in /openstax/osbooks-<name>) pinned by impo, which
carries its own copies under impo/openstax/ (those ARE included). Read-only per the
upstream-only rule.

Idempotent: skips a Makefile already using the `?=` auto-detect. Prints each action.
Does NOT git-add or commit -- the caller stages/commits per repo.

Run from anywhere:  python3 rollout.py
"""
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

TARGET = (
    "CONTAINER_CMD ?= $(shell command -v podman >/dev/null 2>&1 "
    "&& echo podman || echo docker)"
)
# a whole-line `CONTAINER_CMD = podman` (1+ spaces/tabs around the =)
PAT = re.compile(r"^CONTAINER_CMD[ \t]*=[ \t]*podman[ \t]*$", re.M)
# a source osbooks repo: its own git repo whose root is .../openstax/osbooks-<name>
UPSTREAM_ROOT = re.compile(r"/openstax/osbooks-[^/]+$")


def git_root(path: str) -> str:
    r = subprocess.run(
        ["git", "-C", os.path.dirname(path), "rev-parse", "--show-toplevel"],
        capture_output=True, text=True,
    )
    return r.stdout.strip()


def find_makefiles() -> list[str]:
    out = subprocess.run(
        ["find", "-L", "/foo/opt", "-maxdepth", "4", "-name", "Makefile"],
        capture_output=True, text=True,
    ).stdout.split()
    return sorted(set(m for m in out if "/.git/" not in m))


def main() -> None:
    for mk in find_makefiles():
        text = Path(mk).read_text(encoding="utf-8")
        if "command -v podman" in text:
            continue  # already auto-detect
        if not PAT.search(text):
            continue
        root = git_root(mk)
        if UPSTREAM_ROOT.search(root):
            print(f"SKIP (upstream openstax source): {mk}")
            continue
        Path(mk).write_text(PAT.sub(TARGET, text, count=1), encoding="utf-8")
        print(f"wired [{os.path.basename(root)}]: {mk}")


if __name__ == "__main__":
    main()
