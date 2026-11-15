# Fixed the stale and contradictory infra docs

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 3
**Difficulty:** 3
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §1.2, §1.4, §1.5, §1.6, §1.7, §1.13, §1.15, §2.1, §2.2, §2.5, §8.5 F10 F11 F21

## What this did

- **`:Z`** (maintainer decision: never on host trees): the project `CLAUDE.md` convention says
  "never `:Z`" with the reason; `nested-run-and-gates.md` separates an inner run's `:Z` (fine)
  from a host tree's. The Makefile's own `:Z` mounts are in `tasks/dockerfile-and-makefile-hygiene.md`.
- **Facts:** "~430" → "~460" packages (seven places); Fedora 44 → 45 in the pipeline doc and the
  capability map; .NET SDK 10; the capability map names the install scripts as the authority,
  including `01b-install-binary-tools.sh` and `install-lean.sh`; `MINIMAL_IMAGE` instead of the
  lean-image-when-nested standard; `~/.claude` and `~/.claude.json` are mounted always (created if
  missing), and the README lists `~/.vimrc`; "runCrush mirrors all four" shared tools.
- **The leaked-store sweep** in `image-build-and-storage-pipeline.md` uses `podman unshare rm -rf`
  and shows the trap as the Makefile has it (a bare `rm` fails on the layers' read-only dirs).
- **Dangling pointers:** `Makefile` and `entrypoint/shell.sh` point at the archived
  `add-shell-exec-target.md` and `nested-store-cleanup-permission-denied.md`;
  `minimal-nested-images.md` and `nested-podman-design.md` at the archived
  `decouple-minimal-image-from-nested-podman.md`; `nested-run-and-gates.md` spells out
  `tasks/archive/2026/06/07/nested-podman.md`.
- **Small claims:** Xvfb is in `01-install-base.sh`; the disk store is no longer an open thread;
  `claude-config-layering.md` no longer counts five reference docs; README's "one-line reminder"
  and its mounted-docs list; README layout table lists `01b`, `install-lean.sh`, `format.sh`,
  `.config/containers/` and `tools/`.
- **Narration and residue:** the nine "(Relocated verbatim from `CLAUDE.md`, 2026-09-14.)" notes,
  `print-debugging.md`'s relocation note and "Last updated" date, and the README auth section's
  history were rewritten as current fact. (The pipeline doc's "your mental model is exactly right"
  line had already gone.)
- **Cites:** `tools/check_changelog.py` names github.com/billsix/geometricalgebra;
  `script-language-choice.md` maps its short repo names to URLs; `minimal-nested-images.md` and the
  README no longer carry container-absolute paths (`/foo/opt`, `/mnt/sda1`).

Not here: the Dockerfile summaries (§1.3) change with the layer reorder in
`tasks/dockerfile-and-makefile-hygiene.md`; the nested section of the project `CLAUDE.md` (§1.4) was
rewritten by `tasks/archive/2026/11/15/nested-native-overlay.md`'s work; `tauri-desktop-apps.md`'s
pointers (§2.3) need the hanoi repo checked and are left for the archive-and-refs task.

## Verification

Re-grep outside the archive and review records: no "~430", no `fedora:44` step, no "Use `:Z`"
convention, no `tasks/add-shell-exec-target.md` or `tasks/decouple-minimal…` pointer, no elided
`archive/.../` path. Every repointed path exists (`ls`).
