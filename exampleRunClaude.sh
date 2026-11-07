#!/bin/sh
# Example launcher — EDIT THE PATHS BELOW to your own before using.
#
# The -v paths in EXTRA_PODMAN_FLAGS below are the maintainer's host directories; a fork must
# replace them with its own (see FORKING.md). Everything else is generic:
#   NESTED_PODMAN=1            run podman inside the sandbox (see README)
#   NESTED_PODMAN_TMPFS_SIZE   RAM-backed inner image store size
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

#make shell NESTED_PODMAN=1 NESTED_PODMAN_TMPFS_SIZE=16g EXTRA_PODMAN_FLAGS="-v /home/wsix/opt/:/foo/opt/:z -v /mnt/sda1/:/mnt/sda1/:z" USE_CONTROLLER=1
make shell NESTED_PODMAN=1 NESTED_PODMAN_STORE_BASE=/mnt/sda1/tmpContainerStorage EXTRA_PODMAN_FLAGS="-v /home/wsix/opt/:/foo/opt/:z -v /mnt/sda1/:/mnt/sda1/:z -e BUILDAH_ISOLATION=chroot" USE_CONTROLLER=1
