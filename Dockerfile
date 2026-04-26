FROM registry.fedoraproject.org/fedora:44

ARG USE_EMACS=0

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    echo "keepcache=True" >> /etc/dnf/dnf.conf && \
    dnf upgrade -y

COPY entrypoint/dotfiles/ /root/

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    dnf install -y \
                   emacs \
                   python3 \
                   python3-setuptools \
                   python3-sympy \
                   python3-pytest \
                   python3-wheel \
                   ruff \
                   emacs-gtk+x11 \
                   emacs-pgtk \
                   tmux \
                   uv \
                   ty ;  \
    dnf install -y \
                   pinentry; \
    emacs --batch --load /root/.emacs.d/install-melpa-packages.el && \
    echo "source ~/.extrabashrc" >> ~/.bashrc && \


ENTRYPOINT ["/entrypoint.sh"]
