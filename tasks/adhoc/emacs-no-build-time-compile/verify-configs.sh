#!/usr/bin/env bash
#
# verify-configs.sh IMAGE PROJECT_ROOT SCRATCH -- for each init.el listed in configs.txt
# (paths relative to PROJECT_ROOT), copy its .emacs.d to SCRATCH, strip every .elc/.eln
# (a fresh `make update-emacs-packages` state), then start Emacs in batch twice inside
# IMAGE (offline) with that copy mounted. Prints one line per config: each start's exit
# status, .elc count, error-line count and wall time. Does not touch the repos.
set -uo pipefail

image="$1"; root="$2"; scratch="$3"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0
while read -r init; do
  src="$root/$(dirname "$init")"
  dst="$scratch/$(dirname "$init" | tr / _)"
  rm -rf "$dst"; mkdir -p "$dst"; cp -a "$src" "$dst/.emacs.d"
  find "$dst/.emacs.d/elpa" \( -name '*.elc' -o -name '*.eln' \) -delete 2>/dev/null
  line="${init%/entrypoint/dotfiles/.emacs.d/init.el}:"
  for run in 1 2; do
    start=$(date +%s)
    out=$(podman run --rm --cgroups=disabled --network=none --entrypoint /bin/bash \
            -v "$dst/.emacs.d/:/root/.emacs.d/:U,z" "$image" -c '
      emacs --batch -l /root/.emacs.d/init.el -f kill-emacs >/tmp/e.log 2>&1
      echo "exit=$? elc=$(find /root/.emacs.d/elpa -name "*.elc" | wc -l) err=$(grep -c -i -E "^error|error:|cannot open load file" /tmp/e.log)"
      grep -i -E "^error|error:|cannot open load file" /tmp/e.log | grep -v compat-macs | head -2 | sed "s/^/    /"')
    first=$(printf '%s\n' "$out" | head -1)
    case "$first" in exit=0*) ;; *) status=1 ;; esac
    line="$line run$run[$first $(( $(date +%s) - start ))s]"
    extra=$(printf '%s\n' "$out" | tail -n +2)
    [ -n "$extra" ] && line="$line"$'\n'"$extra"
  done
  echo "$line"
done < "$here/configs.txt"
exit $status
