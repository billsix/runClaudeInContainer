FROM registry.fedoraproject.org/fedora:44

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    echo "keepcache=True" >> /etc/dnf/dnf.conf && \
    dnf upgrade -y

COPY entrypoint/dotfiles/ /root/

# Package installation lives in entrypoint/01-install-base.sh so the same ~430-package
# toolchain can be installed on a bare Fedora host/guest (no container runtime), not
# only during this build. The dnf cache mount + keepcache stay in the Dockerfile (build
# plumbing); `dnf upgrade` ran in the earlier layer above; the script is purely install.
COPY entrypoint/01-install-base.sh /usr/local/bin/

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    /usr/local/bin/01-install-base.sh && \
    echo "source ~/.extrabashrc" >> ~/.bashrc


RUN echo 'export PATH=~/.local/bin:$PATH' >> ~/.bashrc

# Install Claude Code (native binary, no Node.js required)
RUN curl -fsSL https://claude.ai/install.sh | bash

RUN source ~/.bashrc && claude update

ENTRYPOINT ["/entrypoint.sh"]
