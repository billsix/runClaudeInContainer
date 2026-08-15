#!/bin/sh
# Example launcher — EDIT THE PATHS BELOW to your own before using.
#
# The EXTRA_MOUNTS paths here are the maintainer's host directories; a fork must
# replace them with its own (see FORKING.md). Everything else is generic:
#   NESTED_PODMAN=1            run podman inside the sandbox (see README)
#   NESTED_PODMAN_TMPFS_SIZE   RAM-backed inner image store size
#   USE_CONTROLLER=1           pass host gamepads through
#
# EXTRA_MOUNTS mounts host:container dir pairs (":z" for SELinux shared relabel).

make shell NESTED_PODMAN=1 NESTED_PODMAN_TMPFS_SIZE=16g EXTRA_MOUNTS="-v /home/wsix/opt/:/foo/opt/:z -v /mnt/sda1/:/mnt/sda1/:z" USE_CONTROLLER=1
