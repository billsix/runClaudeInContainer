#!/bin/bash
# discover.sh PROJECT_ROOT -- list every Dockerfile / entrypoint script under
# PROJECT_ROOT (the directory holding the maintainer's project checkouts) that
# compiles Emacs packages at image build (emacs --batch / install-melpa-packages /
# package-install). Paths print relative to PROJECT_ROOT. Snapshot: hits.txt.
root="${1:?usage: discover.sh PROJECT_ROOT}"
cd "$root" || exit 1
find . -maxdepth 4 \( -name SteamLibrary -o -name steam -o -name gog -o -name lineageos -o -name OSes -o -name Movies -o -name iso -o -name wads -o -name elpa -o -name .git -o -name node_modules -o -name archive \) -prune -o \( -name "Dockerfile*" -o -path "*/entrypoint/*.sh" \) -type f -print0 \
  | xargs -0 grep -l -E "emacs +(--batch|-batch)|install-melpa-packages\.el|package-install" 2>/dev/null | sed 's|^\./||' | sort
