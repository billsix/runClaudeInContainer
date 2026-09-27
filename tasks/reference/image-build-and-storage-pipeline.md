# Image build & storage pipeline — where every layer actually lives

**What this answers:** when you run `make image`, what happens, and *where do the image layers
get written*? And separately, when you run `podman` **inside** the sandbox (nested), where do
*those* layers go? These are two different podman engines writing to two different places, and
conflating them is the usual source of confusion.

**The one-sentence answer.** `make image` (on the host) is an ordinary rootless build and its
layers land in the **standard host store** `~/.local/share/containers/storage` — nothing special,
nothing ephemeral. The "base-image-from-the-host, own-layers-written-elsewhere, not-the-standard-
place, not-RAM" behavior is the **nested** podman *inside* the sandbox (`make shell
NESTED_PODMAN=1`), which is a separate engine with a separate, ephemeral, disk-backed writable
store plus read-only reuse of the host store.

---

## Two levels of podman — keep them separate

```
[LEVEL 1 — HOST]  make image                          [LEVEL 2 — INSIDE THE SANDBOX]  podman build (nested)
  host rootless podman                                  inner rootful-in-userns podman
  FROM fedora:44 → dnf → COPY → install                 FROM <base> → RUN … → COMMIT
        │                                                     │  writable layers ↓        base images ↑ (read-only)
        ▼                                                     ▼                           │
  ~/.local/share/containers/storage   ◄────reused read-only────┐                          │
  (STANDARD host store, persistent,                            │                          │
   tagged `claudecontainer`)                    /var/lib/shared-images  ◄── bind ro ───────┘
                                                (= the host store, mounted read-only)
                                               /var/lib/containers  ◄── bind ── ~/.cache/runclaude-nested.XXXXXX
                                                (inner writable graphroot)          (ephemeral disk dir, rm'd on exit)
```

Level 1 builds the *sandbox image you run Claude in*. Level 2 is you building/running *other*
containers from inside that sandbox. The disk-dir + reuse machinery is **only** Level 2.

---

## Level 1 — building the sandbox image (`make image`, on the host)

`make image` (Makefile target `image`) runs `podman build -t claudecontainer` with the host's
**rootless** podman. Pipeline (see the `Dockerfile`):

1. `FROM registry.fedoraproject.org/fedora:44`.
2. `RUN --mount=type=cache …; dnf upgrade -y` — the dnf cache is a **build-time cache mount**,
   discarded after the build (it is *not* a layer, not in the image).
3. `COPY entrypoint/dotfiles/ /root/` — dotfiles, incl. `.config/containers/storage.conf`.
4. `COPY entrypoint/dotfiles/.config/containers/storage.conf /etc/containers/storage.conf` — the
   *same* store config, delivered to the rootful path the **nested** podman reads (see Level 2 and
   `tasks/dir-backed-nested-podman-storage.md`; this line was added 2026-09-27 and needs a rebuild
   to take effect).
5. `RUN /usr/local/bin/01-install-base.sh` — the ~430-package toolchain (a host-runnable script
   the Dockerfile sources, not an inline `dnf install`).
6. `RUN curl …/install.sh | bash` + `claude update` — install Claude Code.
7. `ENTRYPOINT ["/entrypoint.sh"]` (which just `exec bash`).

**Where the layers go:** the finished image and all its layers are committed to the host's rootless
containers/storage — by default `~/.local/share/containers/storage` — under the tag
`claudecontainer`. This is a normal, persistent overlay store. It is **the** place disk fills up;
manage it with `podman images` / `podman rmi claudecontainer` / `podman system prune -a`, or delete
the directory (podman recreates it). See `README.md` → "Where images are stored".

`make image` does **not** touch `/var/lib/containers`, does not use a temp dir, and does not use a
tmpfs. Those are Level-2 concerns.

## Level 2 — nested podman *inside* the sandbox (`make shell NESTED_PODMAN=1`)

When you launch with `NESTED_PODMAN=1`, the sandbox can run its own `podman` (podman-in-podman).
That inner podman is a **separate engine** with a **separate** store, and this is where your mental
model is exactly right: it reuses host base images read-only and writes its own layers to a place
that is neither the host's standard store nor RAM.

Three storage-related mounts are added (all in `NESTED_PODMAN_FLAGS`, Makefile):

### (a) The inner writable store — an ephemeral disk directory, not RAM, not the host store

The inner podman's graphroot is `/var/lib/containers`. The `shell`/`shell-exec` recipes, in the
default `NESTED_PODMAN_STORE=dir` mode, do:

```
mkdir -p ~/.cache
STORE=$(mktemp -d ~/.cache/runclaude-nested.XXXXXX)   # a fresh dir on the host's real disk fs
trap 'rm -rf "$STORE"' EXIT INT TERM                  # removed when the run exits
podman run … -v "$STORE":/var/lib/containers:Z …
```

So every nested layer the inner podman **writes** lands in that per-session temp dir under
`~/.cache/`, and it is deleted on exit. It is **not** `~/.local/share/containers/storage` (the host
store), and it is **not** a tmpfs. A hard-killed session can leak the dir — sweep with
`rm -rf ~/.cache/runclaude-nested.*`.

**Why a dedicated real-fs dir instead of just using a normal directory?** The sandbox's own
rootfs is an **overlay** mount (the image layers). Layering the inner podman's `fuse-overlayfs` on
top of that is **overlay-on-overlay under a nested user namespace, which the kernel rejects**. A
tmpfs is a *real* (non-overlay) filesystem, which is the historical reason the store was a tmpfs. A
**host directory on the real disk fs (ext4/xfs/btrfs), bind-mounted in, is equally a real fs** — so
it sidesteps the overlay-on-overlay problem exactly like tmpfs did, but with no RAM ceiling. That
is the whole point of the 2026-09-27 change (`tasks/dir-backed-nested-podman-storage.md`): big
inner builds used to OOM/`no space left` in the RAM tmpfs at layer-commit.

Opt back into the RAM store with `make shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=tmpfs` (sized by
`NESTED_PODMAN_TMPFS_SIZE`, default 8g) — then the recipe adds `--tmpfs /var/lib/containers` instead
and creates no temp dir.

### (b) Read-only reuse of the host store — so a nested build doesn't re-pull

`NESTED_PODMAN_IMAGESTORE_MOUNT` bind-mounts the host store
(`NESTED_PODMAN_HOST_IMAGESTORE`, default `~/.local/share/containers/storage`) **read-only** at
`/var/lib/shared-images` (emitted only if that path exists). The inner `storage.conf`'s
`additionalimagestores = [ "/var/lib/shared-images" ]` then lets the inner podman **read** the
host's already-built images (e.g. a `fedora:44` base, or `claudecontainer` itself) as **read-only
lower layers**, without copying them. The writable container/layer still goes to the temp dir in
(a). This is why "base image from the host, own layers elsewhere" is the accurate description.

**Rootful gotcha (fixed 2026-09-27, needs a rebuild):** the inner podman runs **rootful** (uid 0
inside the userns), so it reads `/etc/containers/storage.conf`, **not** the rootless
`~/.config/containers/storage.conf`. Delivering `storage.conf` only to the rootless path left
`additionalimagestores` silently ignored (empty `podman images`, effective store fell back to the
default `/usr/lib/containers/storage`). The Dockerfile now also `COPY`s it to `/etc/containers/` —
this takes effect after the next `make image`. Detail + verification log:
`tasks/dir-backed-nested-podman-storage.md`.

### (c) A tmpfs over the host runtime dir's `libpod` state

`NESTED_PODMAN_RUNTIME_TMPFS` shadows `$XDG_RUNTIME_DIR/libpod` with an empty tmpfs so the inner
podman doesn't trip over the *host* podman's leftover runtime state (a host PID in
`libpod/tmp/pause.pid` would cause "cannot re-exec process to join the existing user namespace").
This is runtime state, not image storage.

## Disk-management cheat-sheet

| Place | What's there | Lifetime | Reclaim it with |
|---|---|---|---|
| `~/.local/share/containers/storage` (host) | `claudecontainer` + anything you build/pull on the host | Persistent | `podman rmi` / `podman system prune -a` / delete the dir |
| `~/.cache/runclaude-nested.XXXXXX` | the nested session's *writable* layers | Ephemeral (rm'd on exit) | auto; leaked dirs → `rm -rf ~/.cache/runclaude-nested.*` |
| `/var/lib/shared-images` (in-sandbox) | a read-only *view* of the host store | Mount only (writes nothing) | n/a — it's the host store above, read-only |
| `claudecontainer-*.tar` (repo root) | `make image-export` archives | Persistent, gitignored | delete the tar |

## See also

- `tasks/dir-backed-nested-podman-storage.md` — the disk-store change, the rootful-config fix, and
  the host/in-session verification.
- `tasks/reference/nested-podman-design.md` — every nested flag and why it exists (fuse-overlayfs,
  `--cgroups=disabled`, netavark/`net_admin`, the `libpod` tmpfs), plus the store-backend section.
- `README.md` → "Building containers inside the sandbox" and "Where images are stored".
