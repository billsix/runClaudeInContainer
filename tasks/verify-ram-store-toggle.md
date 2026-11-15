# Verify the RAM store (NESTED_PODMAN_STORE=tmpfs) in a launched sandbox

**Status:** blocked
**Blocked on:** a `[HOST]` relaunch of the sandbox with the RAM-store line in `exampleRunClaude.sh` (the commented-out `make shell … NESTED_PODMAN_STORE=tmpfs NESTED_PODMAN_TMPFS_SIZE=16g …` line, uncommented in place of the disk-store line).
**Recheck:** `[CONTAINER] df -h /var/lib/containers` shows `tmpfs`, and `podman info --format '{{index .Store.GraphStatus "Native Overlay Diff"}}'` prints `true`. Cleared → run the timing build below.
**Priority:** 5
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/archive/2026/11/15/nested-native-overlay.md ("Verification", the items left to the maintainer)

## BLUF

The disk store is verified in a launched sandbox. The RAM store is verified only by `make -n` (it generates the right tmpfs mount), not by a real launch. Done means a sandbox launched with `NESTED_PODMAN_STORE=tmpfs` shows a tmpfs store with native overlay diff, and the timing build takes about 9 s. This only matters if the RAM store will actually be used.

## Context

- The disk-store results and the method are in `tasks/archive/2026/11/15/nested-native-overlay.md`; the measurements are in `tasks/reference/nested-run-and-gates.md` ("Storage speed").
- Check list `[CONTAINER]`, after the relaunch:
  1. `df -h /var/lib/containers` → `tmpfs`, size 16G.
  2. `podman info --format '{{.Store.GraphDriverName}} {{index .Store.GraphStatus "Native Overlay Diff"}} {{json .Store.GraphOptions}}'` → `overlay true`, `overlay.mountopt` = `nodev`, `/var/lib/shared-images` in additionalImageStores.
  3. Timing build in a scratch dir: a Containerfile with `FROM localhost/spimulator:latest`, `RUN echo t > /etc/t`, `RUN dnf install -y cowsay`; time `podman build --no-cache -t nestedtiming:test .` (there is no `/usr/bin/time`; use `date +%s.%N` before and after). Expect about 9 s (disk store in a launched sandbox: 14.3 s). Remove the image afterwards.
- Record the result in `tasks/reference/nested-run-and-gates.md` ("Storage speed"), then done-record + archive this task.
