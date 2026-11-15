#!/bin/sh
# Example launcher — EDIT THE PATHS BELOW to your own before using.
#
# The -v paths in EXTRA_PODMAN_FLAGS below are the maintainer's host directories; a fork must
# replace them with its own (see FORKING.md). Everything else is generic:
#   NESTED_PODMAN=1            run podman inside the sandbox (see README)
#   NESTED_PODMAN_STORE        inner image store: dir (default, on disk) or tmpfs (RAM)
#   NESTED_PODMAN_TMPFS_SIZE   the RAM store's size (only with NESTED_PODMAN_STORE=tmpfs)
#   NESTED_PODMAN_STORE_BASE   disk directory for the throwaway inner image store (dir mode)
#   NESTED_PODMAN_HOST_IMAGESTORE
#                              the host's podman image store, mounted read-only so nested
#                              builds reuse images already built on the host (no re-pull, no
#                              rebuild). The value below is the default, shown so a fork sees
#                              the knob; set it empty to turn reuse off.
#   USE_CONTROLLER=1           pass host gamepads through
#
# EXTRA_PODMAN_FLAGS is passed straight into `podman run`: host:container bind mounts
# (":z" for SELinux shared relabel), and
#   -e BUILDAH_ISOLATION=chroot   nested `podman build` RUN steps use the sandbox's own
#                                 network. Without it, Fedora 45's buildah (1.45) takes the
#                                 rootless pasta path inside the sandbox's user namespace
#                                 and every networked RUN fails ("pasta failed ... Couldn't
#                                 open network namespace"). See
#                                 tasks/reference/nested-run-and-gates.md.

# RAM store instead of the disk store: comment out the last line and use this one.
#make shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=tmpfs NESTED_PODMAN_TMPFS_SIZE=16g NESTED_PODMAN_HOST_IMAGESTORE="$HOME/.local/share/containers/storage" EXTRA_PODMAN_FLAGS="-v /mnt/sda1/:/mnt/sda1/:z -e BUILDAH_ISOLATION=chroot" USE_CONTROLLER=1
# Disk store (the default; NESTED_PODMAN_STORE=dir keeps RAM off).
make shell NESTED_PODMAN=1 NESTED_PODMAN_STORE=dir NESTED_PODMAN_STORE_BASE=/mnt/sda1/tmpContainerStorage NESTED_PODMAN_HOST_IMAGESTORE="$HOME/.local/share/containers/storage" EXTRA_PODMAN_FLAGS="-v /mnt/sda1/:/mnt/sda1/:z -e BUILDAH_ISOLATION=chroot" USE_CONTROLLER=1
