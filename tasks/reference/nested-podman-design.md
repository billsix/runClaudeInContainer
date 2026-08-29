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
2. **`/sys/fs/cgroup` ro** → historically broke *every* inner run: crun could not
   write `cgroup.subtree_control`, so every inner `podman run` had to pass
   **`--cgroups=disabled`** (acceptable on a dev box that enforces no resource
   limits; real cgroup-v2 delegation was considered and declined).
   **UPDATE 2026-08-29: this wall is GONE on the current host stack** — inside a
   `NESTED_PODMAN=1` sandbox, `/proc/mounts` shows cgroup2 mounted **rw**
   (`nsdelegate`) and a plain inner `podman run` with no flag succeeds
   (empirically verified: fedora-minimal run + a full 37-step image build, both
   flagless). The flag remains **harmless** when passed, so the
   `PODMAN_RUN_FLAGS` convention below still applies it as belt-and-braces for
   older/other stacks. Host podman version at the time of the change was not
   recorded from inside the sandbox — if inner runs ever fail with the
   `cgroup.subtree_control: Read-only file system` error again, the wall is back
   and the flag is the fix.

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

## The `PODMAN_RUN_FLAGS` convention (2026-08-29) — no more hand-edited runs

The old workflow (hand-append `--cgroups=disabled` via `make -n` + re-run, or
transient Makefile edits reverted per turn) is replaced by a standing two-part
convention:

1. **The sandbox exports the signal.** A `NESTED_PODMAN=1` launch adds
   `-e NESTED_PODMAN=1` to the session (in `NESTED_PODMAN_FLAGS`, this repo's
   `Makefile`); a plain `make shell` exports nothing. runCrushInContainer's
   client already exported it; now both sandboxes do.
2. **Project Makefiles carry a `PODMAN_RUN_FLAGS` variable that defaults itself
   from that signal** and is threaded into every `$(CONTAINER_CMD) run`
   invocation (NEVER `build` — `podman build` rejects `--cgroups` and does not
   need it):

   ```make
   # Extra flags for every container `run`. Auto-set when running nested inside a
   # runClaudeInContainer/runCrushInContainer sandbox (which exports NESTED_PODMAN=1);
   # empty — and byte-identical behavior — on a normal host. Overridable:
   #   make test PODMAN_RUN_FLAGS='--cgroups=disabled --network=host'
   PODMAN_RUN_FLAGS ?= $(if $(filter 1,$(NESTED_PODMAN)),--cgroups=disabled)
   ```

   So `make test` inside a nested sandbox Just Works, and on the maintainer's
   host nothing changes (the env var is absent → the variable is empty).
   Deliberate side effect: launching one sandbox from inside another inherits
   `NESTED_PODMAN=1` through the environment (`?=`), carrying nested capability
   inward — coherent for the three-deep runCrush-client case.

   Rolled out fleet-wide 2026-08-29 (pilot: geometricalgebra, then apue,
   graphicalcontainer, hanoi, multivariate-math, modelviewprojection, regardingBritt —
   which had the manual-`?=`-empty prototype, upgraded; repo deleted by the maintainer
   later that day — spimulator, texExpToPng, the runCrushInContainer client, and the
   16 openstax `osbooks-*` repos, which had a hardcoded `PODMAN_RUN_FLAGS =
   --cgroups=disabled` — flag always on, host included — replaced with the conditional
   auto-default, deliberately changing host runs to flagless — except
   **osbooks-anatomy-physiology**, whose conversion the maintainer discarded the same
   day, keeping the hardcoded always-on flag: nested runs still work there, host runs
   keep the harmless flag). Work record:
   runClaudeInContainer `tasks/archive/2026/08/29/nested-podman-run-flags-passthrough.md`.
   A deeper symlink-following scan the same day found four more groups on older
   variants; all converted with maintainer approval (also 2026-08-29): the 20
   billsEmacsConfigs per-language Makefiles and smalltalk (manual empty `?=` →
   auto-default), epix-mirror (same; its separate `PODMAN_BUILD_FLAGS` untouched — the
   run flag was verified absent from its `build` line), and spimulator/pgu (full
   insert + threading). Every mounted Makefile+Dockerfile project now carries the
   convention, with the single deliberate exception of osbooks-anatomy-physiology
   (above).

## Operating it in practice (lore from real sessions, 2026-06 → 2026-07)

- **Inner `podman run`s and `--cgroups=disabled`:** superseded — see the wall-2
  update and the `PODMAN_RUN_FLAGS` convention above. For a project not yet
  converted, the old pattern still applies: `make -n <target>` to print the
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
- **A large image can overflow the RAM store at *commit*, not just at install.**
  Building a big image completes the `dnf install`, then dies at the layer commit
  with `no space left on device` — the commit needs base+diff+temp resident at
  once, so peak use exceeds the final image size. Seen 2026-08-19 building the
  runCrushInContainer client (a 22.3 GB full-toolchain rootfs): it failed to commit
  in a 32g store even though the install itself finished. Fixes: relaunch with a
  bigger `NESTED_PODMAN_TMPFS_SIZE`, or — mid-session, if RAM allows — grow the live
  tmpfs: `mount -o remount,size=50g /var/lib/containers` let the 22.3 GB image
  commit. The durable fix is the disk-backed store (Open thread).

## Open thread

`tasks/dir-backed-nested-podman-storage.md` (proposed) investigates swapping the
RAM tmpfs for a host-directory store — motivated by large inner images overflowing
the RAM store: a ~6 GB TeX Live image overflowing even a 16g tmpfs, and (2026-08-19)
a 22.3 GB runCrushInContainer client image that failed to *commit* in a 32g tmpfs
(a `remount,size=50g` unblocked it). If implemented, its findings belong in this doc.

## Sources

- Red Hat — [How to use Podman inside of a container](https://www.redhat.com/en/blog/podman-inside-container)
- Red Hat — [Podman is gaining rootless overlay support](https://www.redhat.com/sysadmin/podman-rootless-overlay)
- OneUptime — [How to Run Podman Inside Podman](https://oneuptime.com/blog/post/2026-03-18-run-podman-inside-podman-nested-containers/view)
- containers/podman issue [#15419 — nested rootless containers](https://github.com/containers/podman/issues/15419)
