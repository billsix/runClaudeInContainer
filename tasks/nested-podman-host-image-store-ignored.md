# Nested podman ignored the host image store (podman 6 drop-in reset)

**Done:** 2026-11-13. **Started:** 2026-11-12.
**Sibling:** runCrushInContainer `tasks/nested-podman-host-image-store-ignored.md` (same bug in the
Crush client image, fixed the same way).

## Outcome

In the sandbox, nested podman stopped using the read-only host image store at
`/var/lib/shared-images`, even though the store was mounted and `/etc/containers/storage.conf` named
it. So every nested `make image` rebuilt from scratch. A gacalc image took about 40 minutes, most of
it the Lean/Mathlib layer.

- **Cause.** podman 6.1.3 / containers-common 0.69.2-1.fc45 loads one main `storage.conf`, then every
  drop-in by file name. containers-common's
  `/usr/share/containers/storage.rootful.conf.d/00-vendor-rootful.conf` resets
  `additionalimagestores`, so the main file's setting was lost. This was confirmed with `strace` of
  `podman info` and containers-config(5) "Load Order". It is recorded in
  `tasks/reference/nested-podman-design.md` ("Which storage config the nested podman reads").
- **Fix.** The `Dockerfile` also installs our `storage.conf` as
  `/etc/containers/storage.conf.d/50-runclaude-nested.conf`, which sorts after the vendor drop-in.
  The main `/etc/containers/storage.conf` stays for older podman. The fix sits in the `Dockerfile`,
  not in `exampleRunClaude.sh` (William Emerison Six <billsix@gmail.com>, 2026-11-12), for these
  reasons:
  - every launch path gets it, including `make shell`, `make shell-exec` and a fork's launcher;
  - it sits beside the config that broke;
  - a drop-in adds one setting, while `CONTAINERS_STORAGE_CONF` replaces podman's whole config
    search and has to reach every subprocess;
  - runCrush can apply the same `Dockerfile` lines.
- **Regression check.** `entrypoint/shell.sh` warns once at interactive start when
  `/var/lib/shared-images` is mounted but `podman info` does not list it as an additional store.
- **Docs.** `README.md` has a host-image-reuse subsection. `exampleRunClaude.sh` shows
  `NESTED_PODMAN_HOST_IMAGESTORE`. `CLAUDE.md`, `tasks/reference/nested-podman-design.md`,
  `tasks/reference/image-build-and-storage-pipeline.md` and `tasks/reference/nested-run-and-gates.md`
  were updated. The last now names the two real causes of a missed host build cache: the store being
  ignored, and an inner base image (such as `fedora:45`) shadowing the host's copy.

## Verification

- **2026-11-12, drop-in installed by hand in a running sandbox:**
  - `podman images` listed 85 read-only host images.
  - A `FROM localhost/claudecontainer:latest` build used the host layers without pulling.
  - A nested spimulator `make image` hit the cache on 42 of 43 steps, after an inner `fedora:45`
    that shadowed the host's base was untagged.
  - The `shell.sh` warning printed with the drop-in removed and stayed silent with it present.
- **2026-11-13, after the maintainer rebuilt the image on the host and relaunched with
  `NESTED_PODMAN=1`.** This tested the image's own copy of the drop-in:
  - `/etc/containers/storage.conf.d/` contains `50-runclaude-nested.conf`.
  - `podman info --format '{{json .Store.GraphOptions.additionalImageStores}}'` printed
    `["/var/lib/shared-images"]`.
  - `podman images` listed 87 images, all read-only, including `localhost/claudecontainer`,
    `localhost/spimulator` and a single `registry.fedoraproject.org/fedora:45`, so no inner copy
    shadowed the base.
  - The `shell.sh` check takes its silent branch for that `podman info` output.
  - A nested spimulator `make image` reported `Using cache` on 42 of 43 steps (the remaining step is
    the `FROM`), exited 0 and took 22 s.
