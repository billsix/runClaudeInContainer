# Give vim users a complete setup in the sandbox image (vim is already there)

**Status:** **implemented and staged 2026-09-10; pending the maintainer's host `make image`** (the image
is too large for the sandbox's nested store) — then archive. Proven in a throwaway `fedora:44`: the six
rpms install, `$EDITOR` is `/usr/bin/vim` in a login shell, and with the baked `.vimrc` all five plugin
commands exist (`:Git`, `:NERDTreeToggle`, `:Commentary`, `:ALEInfo`, `:GitGutterToggle`) with
`shiftwidth=4` and the space leader in effect. Created 2026-09-10 at the maintainer's request (William
Emerison Six <billsix@gmail.com>: "add vim, and whatever normally vim users want installed, to the base
install script"). Twin of runCrushInContainer's task of the same slug — its list should mirror this one
(runCrush's `01-install-base.sh` is a copy of this repo's, plus its two language-server rpms).
**Priority:** 6
**Difficulty:** 2

## BLUF

`entrypoint/01-install-base.sh` **already installs `vim-enhanced` and `neovim`**, plus `ctags`,
`ripgrep`, `fd-find`, `fzf`, `bat`, `tmux`. Missing for a vim user: vim as the default `$EDITOR`,
a baked `.vimrc`, a conditional mount of the host's `~/.vimrc`, and the Fedora-packaged plugins.
Done means those are in place and `make image` builds.

## Context — read first

- `entrypoint/01-install-base.sh` — the alphabetical dnf list; `CLAUDE.md`: add alphabetically,
  never prune, preserve the dnf cache mounts (those stay in the `Dockerfile`).
- `entrypoint/dotfiles/` — `.claude/`, `.config/`, `.emacs.d/`, `.extrabashrc`; no `.vimrc`.
- `Makefile` — the conditional host mounts (`~/.tmux.conf`, `~/.gitconfig`, `~/.gnupg`) are the
  idiom to copy for `~/.vimrc`; `tasks/reference/claude-config-layering.md` explains why some
  mounts are conditional and one is not.
- `tasks/reference/sandbox-capability-map.md` — gets one line under a new "Editors" bullet.

## Plan (Fedora rpms; verify names with `dnf search vim-` in the image)

1. **`vim-default-editor`** — makes `vim` the alternatives default so `git commit`, `crontab -e`
   etc. open vim. The single most-noticed gap.
2. **Plugins as rpms** (no plugin manager, no network at run time): `vim-fugitive`,
   `vim-airline` (+ `-themes`), `vim-commentary`, `vim-surround`, `vim-nerdtree`, and one linter
   integration (`vim-ale` if packaged) — keep to what Fedora ships.
3. **`entrypoint/dotfiles/.vimrc`** — ≤ 40 lines of defaults (`syntax on`, `filetype plugin
   indent on`, `number relativenumber`, `hlsearch incsearch ignorecase smartcase`, 4-space
   `expandtab`, `mouse=a`, a leader). Baked by the Dockerfile's `COPY entrypoint/dotfiles/ /root/`.
4. **Conditional mount of host `~/.vimrc`** in the `Makefile`, same shape as `TMUX_MOUNT`.
5. `vim-X11`/clipboard: skip — headless image; document that `"+y` is unavailable.
6. Doc deltas with the unit: `sandbox-capability-map.md` (editors line), `README.md` if it lists
   editors, `CLAUDE.md` only if the mount list there changes.

## Work record (2026-09-10)

- **Plugins — Fedora 44 ships six, not the eight drafted:** `vim-default-editor`, `vim-fugitive`,
  `vim-commentary`, `vim-nerdtree`, `vim-ale`, `vim-gitgutter` (2.9 MB installed, ale is 2 MB of it).
  **Not packaged:** `vim-airline`(-themes) and `vim-surround` — dropped rather than pulled from the
  network (the rpm-only decision); `vim-gitgutter` took the slot. All six added to
  `entrypoint/01-install-base.sh` alphabetically around the existing `vim-enhanced`.
- **`entrypoint/dotfiles/.vimrc`** (35 lines): syntax/filetype on, hybrid line numbers, incremental
  case-smart search, 4-space expandtab, mouse, no swap/backup files (the tree is a bind mount), space
  leader with `<leader>n` NERDTree / `<leader>g` fugitive / `<leader>/` clear search, ale set to
  lint-on-save only and never auto-fix (the repos' own format gates are the fixers). Baked by the
  existing `COPY entrypoint/dotfiles/ /root/`.
- **`Makefile`:** `VIMRC_MOUNT`, the same conditional idiom as `TMUX_MOUNT`, appended to
  `FILES_TO_MOUNT`; verified `make -n shell` emits no mount line when the host has no `~/.vimrc`.
- **Docs:** `README.md` (dotfiles table row), `CLAUDE.md` (the host-mount list), `tasks/reference/
  sandbox-capability-map.md` (new "Editors" line under Base, incl. the no-clipboard caveat).
- **Proof** (throwaway `fedora:44`, nested): `dnf install` of the six + `vim-enhanced`; `bash -lc
  'echo $EDITOR'` → `/usr/bin/vim` (vim-default-editor's profile.d snippet); `vim -N -u /root/.vimrc
  -es -S check.vim` → `Git:2 NERDTree:2 Commentary:2 ALE:2 GitGutter:2 vimrc:1`. (First attempt
  without `-u` showed `Commentary:0 vimrc:0` — `-es` silent mode skips the vimrc unless `-u` names it;
  not a plugin problem.)

## Verification / done-state

- [ ] **[HOST]** `make image` builds; in `make shell`: `git commit` opens vim, `:scriptnames` shows the
      baked `.vimrc` (or the mounted host one), `:Git` / `:NERDTreeToggle` work. Image-size delta
      (expected ~3 MB) recorded here.
- [x] Throwaway proof (2026-09-10, above).

## Open questions

All three resolved 2026-09-10 by the maintainer's "can you do the vim task" + the task's own
recommendations: (1) rpm-only plugin set — the six Fedora ships; (2) host `~/.vimrc` mounted,
conditional; (3) neovim left unconfigured.
