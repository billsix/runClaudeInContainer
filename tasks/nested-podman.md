# Nested Podman — run Podman inside the `claudecontainer`

**Status:** implemented — pending acceptance test on a host rebuild
**Created:** 2026-06-07
**Owner:** (unassigned)

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
