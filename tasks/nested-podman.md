# Nested Podman — run Podman inside the `claudecontainer`

**Status:** fix implemented — pending re-run of acceptance test on a host rebuild
**Created:** 2026-06-07
**Owner:** (unassigned)

## Acceptance test FAILED + root cause (2026-06-07, second session)

User rebuilt the image on the host and ran inside the new container:

```
podman run --rm -it -v $(pwd):/workspace:Z ubuntu:latest bash
WARN[0000] Using rootless single mapping into the namespace. ...
Error: cannot re-exec process to join the existing user namespace
```

**Diagnosed live inside the container. Root cause = a bug the original plan never
accounted for, plus the test being run without the opt-in flag.**

### Primary root cause — host `$XDG_RUNTIME_DIR` bind mount shadows podman's rootless state

`make shell` bind-mounts the host's `/run/user/1000` into the container (for
Wayland/PulseAudio passthrough). That tmpfs carries the **host's** rootless-podman
state, including `libpod/tmp/pause.pid`:

- `/run/user/1000` is confirmed a mountpoint (host tmpfs, `uid=1000`), full of host
  runtime artifacts (`wayland-0`, `gnupg`, `KSMserver__0`, `speech-dispatcher`, …).
- `/run/user/1000/libpod/tmp/pause.pid` contains **`10503`** — a *host* PID that does
  **not exist** in the container's PID namespace (`/proc/10503` is absent).

Inner podman runs rootless (it's in a userns → non-identity `uid_map`), reads that
pause.pid, and tries to `setns()`-join the user namespace of PID 10503. That process
isn't visible here → **"cannot re-exec process to join the existing user namespace."**

**Proven fix:** give the inner podman a *container-local* runtime dir. With
`XDG_RUNTIME_DIR=/tmp/nested-xdg` (clean, empty) the re-exec error vanished and podman
ran end-to-end far enough to **pull and create a container** — failing only on later
infra layers (below). This fix is **orthogonal to the `NESTED_PODMAN=1` flags**; the
flag set as designed would NOT have fixed this on its own.

Do **not** delete the host's pause.pid — it lives on the host bind mount and is the
host podman's live state.

Recommended implementation (Makefile-only, preserves Wayland):
- **Shadow just the stale state dir with a tmpfs:** add `--tmpfs /run/user/1000/libpod`
  to the `NESTED_PODMAN=1` flag set. Gives podman a clean pause dir while keeping the
  Wayland/Pulse sockets in `/run/user/1000` intact. *(Verify a tmpfs over a subpath of
  an existing bind mount mounts cleanly — it should.)*
- Alternative: export a container-local `XDG_RUNTIME_DIR` for podman only (wrapper/
  alias), leaving the global one pointed at `/run/user/1000` for the GUI stack.

### Secondary gap — the test was run WITHOUT `NESTED_PODMAN=1`

The feature is opt-in and the user's `podman run` was a plain `make shell`. Confirmed
inside the container:
- `/dev/fuse` is **absent** (the `--device /dev/fuse` flag was not applied).
- `CapEff = 0x800405fb` → **CAP_SYS_ADMIN (0x200000) and CAP_MKNOD (0x8000000) both
  absent** (the `--cap-add` was not applied).

So even after the pause.pid fix, the user must launch with `make shell NESTED_PODMAN=1`
for storage/devices. But note the ordering: the flag alone wouldn't have helped because
the pause.pid bug bites first.

### Further gaps uncovered while proving the fix (test was sys_admin-less, so these are
a lower bound — re-verify on a real `NESTED_PODMAN=1` run):

1. **Networking needs `/dev/net/tun`.** With a clean runtime dir the run got to
   networking and failed: `pasta failed ... Failed to open() /dev/net/tun`. The current
   flag set adds `/dev/fuse` only. → **Add `--device /dev/net/tun`** to the
   `NESTED_PODMAN` flags (or document `--network=none` / `--network=host` as the
   constraint without it).
2. **cgroup v2 delegation.** `--network=none` then failed with
   `/sys/fs/cgroup/cgroup.subtree_control: Read-only file system`. Expected to be
   covered by the `sys_admin` cap (absent in this test session); confirm on a flagged
   run. Fallbacks: `--cgroups=disabled`, or proper cgroup delegation.
3. **`/proc/sys` read-only** (`ping_group_range`) — same story: likely resolved by
   `sys_admin` on a real flagged run; verify.

### subuid/subgid — NOT the fix

The "single mapping" warning is benign here: inner podman runs as container-root
(rootful-*in-userns*), which uses the identity mapping within the existing namespace
(uids 0 + 1..65536 are already available) and does not need `/etc/subuid`/`/etc/subgid`.
Populating `root:1:65536` was tested and did **not** clear the re-exec error (the clean
runtime dir did). Leave subuid/subgid wiring out unless we move to Approach C.

### Revised next steps

1. ~~Implement the primary fix + `--device /dev/net/tun` in the `Makefile`.~~ **Done
   (2026-06-07).** `Makefile` `NESTED_PODMAN` block now appends `--device /dev/net/tun`
   and `--tmpfs $(XDG_RUNTIME_DIR)/libpod:rw` (the latter guarded by `$(if
   $(XDG_RUNTIME_DIR),...)` so it's omitted when there's no runtime-dir mount). Verified
   with `make -n shell NESTED_PODMAN=1` (resolves to `--tmpfs /run/user/1000/libpod:rw`)
   and `make -n shell` (nested flags absent). `README.md` and root `CLAUDE.md` updated
   with the two new flags, the rationale, and an in-container test command.
2. **TODO (host):** re-run `make image && make shell NESTED_PODMAN=1`, then inside:
   `podman run --rm docker.io/library/alpine echo "nested podman works"`.
3. Resolve any residual cgroup/proc issues surfaced in step 2 (expected to be covered by
   the `sys_admin` cap, which was absent in the diagnosis session — so unverified).
4. Then archive.

---

## Implementation log (2026-06-07)

Approach B implemented:

- `Makefile` — added opt-in `NESTED_PODMAN ?= 0`; when `=1`, the `shell` target
  appends `--device /dev/fuse --security-opt label=disable --cap-add=sys_admin,mknod
  --tmpfs /var/lib/containers:rw,size=8g`. Verified with `make -n shell NESTED_PODMAN=1`
  (flags present) and `make -n shell` (absent). Host stays rootless.
- `entrypoint/dotfiles/.config/containers/storage.conf` — new; sets the inner podman
  to overlay via `mount_program = /usr/bin/fuse-overlayfs` (copied to
  `/root/.config/...` by the Dockerfile's `COPY entrypoint/dotfiles/ /root/`).
- `Dockerfile` — made `fuse-overlayfs` an explicit dependency (it was already pulled
  in transitively by podman).
- `README.md` / root `CLAUDE.md` — documented the `NESTED_PODMAN=1` flag and the
  security trade-off.

**Not yet verified live.** The acceptance test needs `make image` + `make shell
NESTED_PODMAN=1` run *on the host* — the current session's container predates these
changes and was launched without the flags, so nested podman can't be exercised from
inside it. Run the acceptance test below on the host, then archive this task.

## Goal

Make it possible to run `podman` *inside* the container that `make shell` launches,
so Claude Code (and the user) can build/run containers from within the sandbox —
e.g. building this very image, or CI-style nested builds.

## Hard constraint (user decision)

**Never run podman as root on the original host.** The host podman must stay
rootless. This is already the case (see "Confirmed host posture" below), and the
chosen approach preserves it.

---

## ✅ DECISION — Approach B: rootful-in-container, host stays rootless

Run the inner podman as the container's root (which is *only* host UID 1000 — a
mapped, unprivileged user, never host root). Add the required flags as an **opt-in**
Make variable so normal sessions stay minimal.

### What to change

1. **`Makefile`** — add `NESTED_PODMAN ?= 0`; when `=1`, append to the `shell`
   target's `podman run`:
   ```
   --device /dev/fuse \
   --security-opt label=disable \
   --cap-add=sys_admin,mknod \
   --tmpfs /var/lib/containers:rw,size=8g
   ```
   Keep it conditional, matching the existing `*_MOUNT` shell-detected vars.
   (Swap the `--tmpfs` for `-v podman-store:/var/lib/containers` later if we want the
   inner image cache to persist across sessions.)

2. **Image storage config** — bake a `storage.conf` into `entrypoint/dotfiles/` so the
   inner podman picks fuse-overlayfs automatically:
   ```ini
   # /root/.config/containers/storage.conf
   [storage]
   driver = "overlay"
   [storage.options.overlay]
   mount_program = "/usr/bin/fuse-overlayfs"
   ```

3. **Docs** — note the `NESTED_PODMAN=1` flag in `README.md` and the security
   trade-off in root `CLAUDE.md`.

### Why this approach

- Host stays **rootless** — satisfies the hard constraint. Breakout ceiling is host
  UID 1000, never host root, even with these flags or `--privileged`.
- `podman` is **already installed** in the image (`Dockerfile:267`) — no new packages.
- Minimal churn: fits the current "everything is root inside the container" image; no
  new users or subuid/subgid wiring needed.
- No daemon, no socket exposed.

### Costs we accept

- Storage: overlay-on-overlay under double user-namespaces → must use
  `fuse-overlayfs` (`/dev/fuse`); slower and more disk than native overlay.
- `--security-opt label=disable` drops SELinux isolation for that container.
- `--cap-add=sys_admin` is broad (still confined to the user namespace, but broad).
- Inner image store is ephemeral with `--tmpfs` — images re-pulled each session
  unless we switch to a named volume.

### Acceptance test (inside `make shell NESTED_PODMAN=1`)

```sh
podman info --format '{{.Store.GraphDriverName}}'   # -> fuse-overlayfs
podman pull docker.io/library/alpine
podman run --rm alpine echo "nested ok"
podman build -t selftest .                          # build THIS repo's image, nested
```

---

## Alternatives considered and declined

### ✗ Approach A — `--privileged`
```sh
podman run --privileged ... claudecontainer
```
**Declined:** broader than needed. Works, and under our rootless host it only grants
privilege *within* the user namespace (not host root), but Approach B's explicit,
narrow flags are preferable to a blanket `--privileged`.

### ✗ Approach C — rootless-in-container (no root even inside the container)
```sh
podman run --user podman --security-opt label=disable \
  --security-opt unmask=ALL --device /dev/fuse ... <image-with-podman-user>
```
**Declined for now:** most secure (nobody is root even inside the container), but
requires adding a dedicated non-root `podman` user to the image with `/etc/subuid` +
`/etc/subgid` ranges — significant churn against our root-centric image. Approach B
already satisfies the "never root on host" constraint, so C's extra isolation isn't
worth the rework yet. Revisit if we later want the sandbox itself to be unprivileged.

### ✗ Daemon-socket / `podman --remote`
```sh
podman run -v /run:/run ... podman --remote ...
```
**Declined:** leaks the host podman socket into the container ("can totally take over
the host machine"). Contradicts the security goal outright.

### vfs storage driver (fallback, not primary)
`-e STORAGE_DRIVER=vfs` avoids `/dev/fuse` entirely but is much slower and disk-heavy.
Keep only as a diagnostic if fuse-overlayfs misbehaves.

---

## Confirmed host posture (probed 2026-06-07)

The host podman launching this container is **rootless**:

- `/proc/self/uid_map` → `0 1000 1` : container-root (UID 0) maps to **host UID 1000**,
  a normal user. A rootful host would show an identity map (`0 0 …`).
- The bind-mounted `Makefile`, owned by host UID 1000, appears as `root` (0) inside —
  the classic rootless mapping.
- `container=oci`; subordinate range `524288` is the standard `/etc/subuid` allocation.

Implication: the security ceiling is host UID 1000, not host root — and it stays that
way through the nesting.

## Should `NESTED_PODMAN` default to `1`? (trade-offs)

Asked 2026-06-07. **Current decision: keep it opt-in (`?= 0`).** It's a one-character
change to flip (`NESTED_PODMAN ?= 0` → `?= 1`) if we later decide otherwise. The flag
gates `--device /dev/fuse`, `--device /dev/net/tun`, `--security-opt label=disable`,
`--cap-add=sys_admin,mknod`, `--tmpfs /var/lib/containers:rw,size=8g`, and the
`--tmpfs $(XDG_RUNTIME_DIR)/libpod` shadow.

### Reasons to keep it OFF by default (why we didn't flip it)

- **Unverified.** The feature has not yet passed its acceptance test even once.
  Defaulting the unproven config means a failure degrades *every* `make shell`, not
  just nested sessions. Flip only after the test passes.
- **Weakens every normal session's isolation.** `--security-opt label=disable` turns
  off SELinux confinement and `--cap-add=sys_admin` is a broad capability. On at all
  times means paying that isolation cost even for dev work that never touches podman.
  (Still namespace-confined — ceiling stays host UID 1000 — so it's a posture cost, not
  a host-root risk.) The opt-in design exists precisely to keep normal sessions minimal.
- **Hurts portability of the base command.** `--device /dev/fuse` / `--device
  /dev/net/tun` require those devices to exist on the host; on a host lacking them
  (minimal/CI boxes) `podman run --device ...` fails outright, so default-on would break
  plain `make shell` where it currently works. Today `make shell` is the always-works path.
- **Minor:** the 8g `/var/lib/containers` tmpfs reservation and the
  `$XDG_RUNTIME_DIR/libpod` shadow would apply to every session.

### Reasons it could reasonably default to ON

- This is explicitly a "deliberately maximal dev box"; if the owner essentially always
  wants nested podman and accepts SELinux-off + a broad (confined) cap on every session,
  default-on is consistent with that philosophy.
- The host stays rootless regardless, so the security ceiling does not change.

### Lighter-weight middle ground

- Add `NESTED_PODMAN=1` to a personal `run.sh` (or shell alias) instead of changing the
  repo default — gets the convenience without degrading the default for everyone / on
  every host.

**Revisit after the acceptance test passes.** If it's solid and the owner wants it
always-on, flipping the default + a note in README/CLAUDE.md is the follow-up.

## Open questions

- Persist the inner image store (named volume) or keep ephemeral (`--tmpfs`)? Volume
  saves re-pulling but accumulates disk.
- Worth wiring "build this image from inside itself" as a permanent smoke test, or is
  the acceptance test above enough?

## Sources

- Red Hat — [How to use Podman inside of a container](https://www.redhat.com/en/blog/podman-inside-container)
- OneUptime — [How to Run Podman Inside Podman (Nested Containers)](https://oneuptime.com/blog/post/2026-03-18-run-podman-inside-podman-nested-containers/view)
- Red Hat — [Podman is gaining rootless overlay support](https://www.redhat.com/sysadmin/podman-rootless-overlay)
- containers/podman issue [#15419 — nested rootless containers](https://github.com/containers/podman/issues/15419)
