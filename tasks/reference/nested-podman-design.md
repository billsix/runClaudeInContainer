# Nested Podman — design rationale, declined alternatives, and operating lore

**What this is:** the standing record of *why* the `NESTED_PODMAN=1` flag set looks
the way it does, what was tried and rejected, and what running containers nested
actually requires in practice. The operational summary lives in the root
`CLAUDE.md` ("Nested Podman") and `README.md`; this doc is the depth behind them.
Harvested 2026-07-30 from the archived design/debugging task
(`tasks/archive/2026/06/07/nested-podman.md`, five sessions of live diagnosis).

## The goal and the hard constraint

Run `podman` *inside* the sandbox (build/run project containers, CI-style nested
builds) while **never running podman as root on the host**. The host podman is
rootless — `/proc/self/uid_map` shows `0 1000 1`, i.e. container-root is host UID
1000 — and every design choice preserves that. The security ceiling of the whole
stack, with all flags on and even with `--privileged`, is host UID 1000, never
host root.

## The chosen shape: rootful-in-container (Approach B)

The inner podman runs as the container's root, which is only the namespace-mapped
host user. Opt-in via `make shell NESTED_PODMAN=1`; a plain `make shell` stays
minimal. Flag by flag, with the failure each one answers:

| Flag | Why it exists (observed failure without it) |
| --- | --- |
| `--device /dev/fuse` | Inner storage must be fuse-overlayfs; no fuse device, no storage. |
| `--security-opt label=disable` | SELinux confinement blocks the nested mount/storage dance. |
| `--cap-add=sys_admin,mknod` | Baseline for the inner runtime's mount/device work. |
| `--cap-add=...,net_admin` | The rootful inner podman uses **netavark** (bridge + veth over netlink), which needs `CAP_NET_ADMIN`. Without: `netavark: Netlink error: Operation not permitted`. (pasta/slirp4netns are rootless-only paths — irrelevant here.) |
| `--security-opt unmask=ALL` | netavark also *writes per-interface sysctls* (`net/ipv4/conf/eth0/arp_notify`) bringing the bridge up, and the sandbox's `/proc/sys` is read-only. `CAP_NET_ADMIN` alone does not help — the mount itself is ro. Unmasking makes bridged (default) networking work end-to-end; host-verified 2026-06-07 (`apt update` in a nested `ubuntu` with no `--network` flag). |
| `--device /dev/net/tun` | Retained for the rootless/pasta path only; the rootful netavark path never opens it. Harmless, kept for future flexibility. |
| `--tmpfs /var/lib/containers:rw,size=$(NESTED_PODMAN_TMPFS_SIZE)` | The inner image store. tmpfs (not overlay) because overlay-on-overlay under nested userns is rejected by the kernel; RAM-backed, default 8g (see "Operating it", below). |
| `--tmpfs $(XDG_RUNTIME_DIR)/libpod:rw` | The host's `$XDG_RUNTIME_DIR` is bind-mounted in for Wayland/Pulse, and it carries the **host** podman's `libpod/tmp/pause.pid` — a host PID that doesn't exist in the container's PID namespace. The inner podman tries to `setns()`-join that PID's userns and dies: `cannot re-exec process to join the existing user namespace`. Shadowing *just* `libpod/` with an empty tmpfs fixes it while leaving the Wayland/Pulse sockets intact. |

Plus `entrypoint/dotfiles/.config/containers/storage.conf`, which points the inner
podman at `mount_program = /usr/bin/fuse-overlayfs`.

### The two read-only walls, and the one requirement that remains

Both walls are read-only mounts in the *outer* container; `CAP_SYS_ADMIN` does
not override a ro mount:

1. **`/proc/sys` ro** → broke bridged networking. **Solved** by `unmask=ALL`
   (above).
2. **`/sys/fs/cgroup` ro** → breaks *every* inner run: crun cannot write
   `cgroup.subtree_control`. **Not solved — worked around**: every inner
   `podman run` must pass **`--cgroups=disabled`**. Acceptable on a dev box that
   enforces no resource limits. Real cgroup-v2 delegation was considered and
   declined.

## Findings that were disproven (don't re-try these)

- **`--cgroupns=private` does NOT make `/sys/fs/cgroup` writable.** It was added
  on a medium-confidence guess and removed after testing showed cgroup2 stayed
  `ro`. `--cgroups=disabled` on the inner run is the supported path.
- **subuid/subgid wiring is NOT the fix** for the userns re-exec error. The inner
  podman is rootful-in-userns (identity mapping, no subordinate ranges needed);
  populating `root:1:65536` changed nothing. The clean `libpod` runtime dir was
  the fix.
- **netavark/aardvark-dns "missing"** was a false alarm: they live in
  `/usr/libexec/podman/`, not on `$PATH`, so `command -v` misses them.
  `slirp4netns` genuinely is absent (pasta supersedes it) — and isn't needed.

## Alternatives considered and declined

- **Approach A — `--privileged`:** works, and under a rootless host still grants
  nothing beyond the userns — but broader than needed; the explicit narrow flag
  set is preferable.
- **Approach C — rootless-in-container** (a dedicated non-root `podman` user with
  subuid/subgid ranges): most secure, but significant churn against the
  root-centric image, and Approach B already satisfies the only hard constraint.
  Revisit if the sandbox itself should ever become unprivileged.
- **Daemon socket / `podman --remote`** (mount the host socket): declined
  outright — the socket "can totally take over the host machine".
- **vfs storage driver:** avoids `/dev/fuse` but slow and disk-hungry; kept only
  as a diagnostic fallback if fuse-overlayfs misbehaves.
- **Default-on (`NESTED_PODMAN ?= 1`):** declined. It would weaken every normal
  session's isolation (SELinux off, broad caps), break `make shell` on hosts
  lacking `/dev/fuse`/`/dev/net/tun`, and reserve the tmpfs each session. The
  personal launcher (`exampleRunClaude.sh`) opts in instead.

## Operating it in practice (lore from real sessions, 2026-06 → 2026-07)

- **Every inner `podman run` needs `--cgroups=disabled`.** Project Makefiles
  don't carry it; the cleanest no-edit pattern is `make -n <target>` to print the
  expanded `podman run`, then re-run it by hand with the flag added (and `-it`
  dropped — no TTY in agent sessions).
- **Short names fail without a TTY** (`short-name resolution enforced but cannot
  prompt`). Run images as `localhost/<tag>` — and note tags don't always match
  repo dir names (e.g. texExpToPng builds `tex-expression-to-png`).
- **Parallel nested image builds serialize anyway**: the project Dockerfiles
  share dnf cache mounts, so concurrent builds queue on the cache lock
  ("Waiting for a lock on the system repository"). Expect sum-of-dnf-steps wall
  time, not parallel speedup.
- **The store is RAM.** `/var/lib/containers` is a tmpfs sized by
  `NESTED_PODMAN_TMPFS_SIZE` (default 8g). Budget before pulling/building; evict
  with `podman rmi` / `podman image prune -f` only under pressure — a kept image
  saves a rebuild. Images do not survive the session.
- **Gate runs write through the bind mount.** An inner `ruff --fix`,
  `clang-format -i`, or even an image build that touches a mounted tree (elpa
  refreshes) lands in the host repo. Check `git status` after any nested run and
  triage what appeared.
- **Timeouts skew nested.** Sanitizer-instrumented test suites in particular can
  trip fixed per-test timeouts under fuse-overlayfs (seen: a UBSan regression
  test killed at its 30s limit while 24/25 passed). A nested timeout with zero
  real failures is evidence of slowness, not breakage — prefer the project's
  documented opt-out (e.g. `RUN_SANITIZERS=0`) over raising limits.
- **`:Z` on `EXTRA_MOUNTS` poisons repos for host-side use.** The sandbox runs
  `label=disable`, so `:Z` relabels the whole mounted repo to a container type
  that the project's own *confined* `make shell` then can't read
  (`cd: Permission denied`). Use `:z` or no label flag on `EXTRA_MOUNTS`; fix
  damage on the host with `restorecon -R`.

## Open thread

`tasks/dir-backed-nested-podman-storage.md` (proposed) investigates swapping the
RAM tmpfs for a host-directory store — motivated by a ~6 GB TeX Live inner image
overflowing even a 16g tmpfs. If implemented, its findings belong in this doc.

## Sources

- Red Hat — [How to use Podman inside of a container](https://www.redhat.com/en/blog/podman-inside-container)
- Red Hat — [Podman is gaining rootless overlay support](https://www.redhat.com/sysadmin/podman-rootless-overlay)
- OneUptime — [How to Run Podman Inside Podman](https://oneuptime.com/blog/post/2026-03-18-run-podman-inside-podman-nested-containers/view)
- containers/podman issue [#15419 — nested rootless containers](https://github.com/containers/podman/issues/15419)
