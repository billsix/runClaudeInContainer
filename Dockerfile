FROM registry.fedoraproject.org/fedora:45

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    echo "keepcache=True" >> /etc/dnf/dnf.conf && \
    dnf upgrade -y

COPY entrypoint/dotfiles/ /root/

# Store config for the nested podman (fuse-overlayfs, plus the read-only host image store at
# /var/lib/shared-images). podman loads ONE main storage.conf, the highest-precedence one that
# exists (~/.config, then /etc, then /usr/share), and then every storage.conf.d/ and
# storage.rootful.conf.d/ drop-in, sorted by file name, each overriding what came before.
# containers-common ships /usr/share/containers/storage.rootful.conf.d/00-vendor-rootful.conf,
# which sets additionalimagestores to /usr/lib/containers/storage, so a main file alone loses
# the host store. The same file is therefore also installed as a drop-in whose name sorts after
# the vendor's. The /etc main-file copy serves an older podman without the vendor drop-in.
# Detail: tasks/reference/nested-podman-design.md ("Which storage config the nested podman reads").
COPY entrypoint/dotfiles/.config/containers/storage.conf /etc/containers/storage.conf
COPY entrypoint/dotfiles/.config/containers/storage.conf \
     /etc/containers/storage.conf.d/50-runclaude-nested.conf

# The vendored ~/.emacs.d/ tree is the maintainer's personal Emacs setup. Opt-out:
# ARG defaults 0 (a bare `podman build` is a clean box), and `make image` passes 1.
# When off, drop the tree so a fork isn't carrying someone else's package set.
ARG USE_EMACS_CONFIG=0
RUN if [ "$USE_EMACS_CONFIG" != "1" ]; then rm -rf /root/.emacs.d; fi

# Package installation lives in entrypoint/01-install-base.sh so the same ~430-package
# toolchain can be installed on a bare Fedora host/guest (no container runtime), not
# only during this build. The dnf cache mount + keepcache stay in the Dockerfile (build
# plumbing); `dnf upgrade` ran in the earlier layer above; the script is purely install.
COPY entrypoint/01-install-base.sh /usr/local/bin/

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    /usr/local/bin/01-install-base.sh && \
    echo "source ~/.extrabashrc" >> ~/.bashrc

# shfmt and procs were dnf packages under Fedora 44 but were dropped in Fedora 45;
# install them from upstream release binaries (own layer, own host-runnable script).
COPY entrypoint/01b-install-binary-tools.sh /usr/local/bin/
RUN /usr/local/bin/01b-install-binary-tools.sh


RUN echo 'export PATH=~/.local/bin:$PATH' >> ~/.bashrc

# Install Claude Code (native binary, no Node.js required)
RUN curl -fsSL https://claude.ai/install.sh | bash

RUN source ~/.bashrc && claude update

# Lean 4 (theorem prover) via elan — host-runnable script, curl-installed like Claude
# Code above; bakes the stable toolchain so an exported image has Lean offline.
COPY entrypoint/install-lean.sh /usr/local/bin/
RUN /usr/local/bin/install-lean.sh
ENV PATH="/root/.elan/bin:${PATH}"

ENTRYPOINT ["/entrypoint.sh"]
