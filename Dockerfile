FROM registry.fedoraproject.org/fedora:45

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    echo "keepcache=True" >> /etc/dnf/dnf.conf && \
    dnf upgrade -y

# Package installation lives in entrypoint/01-install-base.sh so the same ~460-package
# toolchain can be installed on a bare Fedora host/guest (no container runtime), not
# only during this build. The dnf cache mount + keepcache stay in the Dockerfile (build
# plumbing); `dnf upgrade` ran in the earlier layer above; the script is purely install.
#
# Each install script is bind-mounted into the one RUN that executes it: the script's
# content is part of that layer's cache key, and no copy of it stays in the image. One
# mount per script, with no relabel option. See
# tasks/reference/build-time-bind-mounts-for-install-scripts.md.
RUN --mount=type=bind,source=entrypoint/01-install-base.sh,target=/usr/local/bin/01-install-base.sh \
    --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    /usr/local/bin/01-install-base.sh && \
    echo "source ~/.extrabashrc" >> ~/.bashrc

# shfmt and procs were dnf packages under Fedora 44 but were dropped in Fedora 45;
# install them from upstream release binaries (own layer, own host-runnable script).
RUN --mount=type=bind,source=entrypoint/01b-install-binary-tools.sh,target=/usr/local/bin/01b-install-binary-tools.sh \
    /usr/local/bin/01b-install-binary-tools.sh


RUN echo 'export PATH=~/.local/bin:$PATH' >> ~/.bashrc

# Install Claude Code (native binary, no Node.js required)
RUN curl -fsSL https://claude.ai/install.sh | bash

# PATH set here, not by sourcing ~/.bashrc: that sources ~/.extrabashrc, which the dotfiles COPY
# below only adds later.
RUN PATH="$HOME/.local/bin:$PATH" claude update

# Lean 4 (theorem prover) via elan — host-runnable script, curl-installed like Claude
# Code above; bakes the stable toolchain so an exported image has Lean offline.
RUN --mount=type=bind,source=entrypoint/install-lean.sh,target=/usr/local/bin/install-lean.sh \
    /usr/local/bin/install-lean.sh
ENV PATH="/root/.elan/bin:${PATH}"

# The dotfiles, the nested-podman config and the Emacs-config opt-out change more often than the
# toolchain, so they come after the slow layers above: editing them rebuilds only these.
COPY entrypoint/dotfiles/ /root/

# Store config for the nested podman (native kernel overlay, plus the read-only host image store at
# /var/lib/shared-images). podman loads ONE main storage.conf, the highest-precedence one that
# exists (~/.config, then /etc, then /usr/share), and then every storage.conf.d/ and
# storage.rootful.conf.d/ drop-in, sorted by file name, each overriding what came before.
# containers-common ships /usr/share/containers/storage.rootful.conf.d/00-vendor-rootful.conf,
# which sets additionalimagestores to /usr/lib/containers/storage, so a main file alone loses
# the host store. The same file is therefore also installed as a drop-in whose name sorts after
# the vendor's; the main file is the ~/.config copy the dotfiles COPY brings in.
# Detail: tasks/reference/nested-podman-design.md ("Which storage config the nested podman reads").
COPY entrypoint/dotfiles/.config/containers/storage.conf \
     /etc/containers/storage.conf.d/50-runclaude-nested.conf
# buildah's temp dir on the store volume, so native overlay can mount build contexts; see
# the file's header.
COPY entrypoint/dotfiles/.config/containers/containers.conf \
     /etc/containers/containers.conf.d/50-runclaude-nested.conf

# The vendored ~/.emacs.d/ tree is the maintainer's personal Emacs setup. Opt-out:
# ARG defaults 0 (a bare `podman build` is a clean box), and `make image` passes 1.
# When off, drop the tree so a fork isn't carrying someone else's package set.
ARG USE_EMACS_CONFIG=0
RUN if [ "$USE_EMACS_CONFIG" != "1" ]; then rm -rf /root/.emacs.d; fi

ENTRYPOINT ["/entrypoint.sh"]
