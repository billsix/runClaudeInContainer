# Give vim users a complete setup in the sandbox image (vim is already there)

**Status:** complete
**Completed:** 2026-09-10

## What this did

At the maintainer's request (William Emerison Six <billsix@gmail.com>: "add vim, and whatever
normally vim users want installed, to the base install script"). `entrypoint/01-install-base.sh`
already installed `vim-enhanced` and `neovim` plus `ctags`, `ripgrep`, `fd-find`, `fzf`, `bat`
and `tmux`; this task added vim as the default `$EDITOR`, Fedora-packaged plugins, a baked
`.vimrc`, and a conditional mount of the host's `~/.vimrc`. Durable facts live in
`tasks/reference/sandbox-capability-map.md` ("Editors"). Archived together with its
runCrushInContainer twin.

## Decisions (the maintainer, 2026-09-10, accepting the task's recommendations)

1. **rpm-only plugins**, no plugin manager and no network at run time.
2. **Host `~/.vimrc` mounted conditionally.**
3. **neovim left unconfigured.**
4. No `vim-X11`/clipboard: the image is headless, so `"+y` is unavailable (documented).

## What was built

- **Plugins:** Fedora 44 ships six of those wanted: `vim-default-editor`, `vim-fugitive`,
  `vim-commentary`, `vim-nerdtree`, `vim-ale`, `vim-gitgutter` (2.9 MB installed, 2 MB of it ale).
  `vim-airline`(-themes) and `vim-surround` are not packaged and were dropped; `vim-gitgutter`
  took the slot. Added alphabetically to `entrypoint/01-install-base.sh`.
- **`entrypoint/dotfiles/.vimrc`** (35 lines): syntax/filetype on, hybrid line numbers,
  incremental case-smart search, 4-space expandtab, mouse, no swap/backup files (the tree is a
  bind mount), space leader with `<leader>n` NERDTree / `<leader>g` fugitive / `<leader>/` clear
  search, ale linting on save only and never auto-fixing (the repos' format gates do that).
  Baked by the existing `COPY entrypoint/dotfiles/ /root/`.
- **`Makefile`:** `VIMRC_MOUNT`, the same conditional idiom as `TMUX_MOUNT`, in `FILES_TO_MOUNT`;
  `make -n shell` emits no mount when the host has no `~/.vimrc`.
- **Docs:** `README.md` (dotfiles table), `CLAUDE.md` (host-mount list),
  `tasks/reference/sandbox-capability-map.md` (Editors line with the no-clipboard caveat).

## Verification

- Throwaway nested `fedora:44`: installed the six plus `vim-enhanced`; `bash -lc 'echo $EDITOR'`
  printed `/usr/bin/vim`; `vim -N -u /root/.vimrc -es -S check.vim` reported
  `Git:2 NERDTree:2 Commentary:2 ALE:2 GitGutter:2 vimrc:1`. (A first run without `-u` showed
  `Commentary:0 vimrc:0` because `-es` skips the vimrc unless `-u` names it.)
- The full `[HOST] make image` plus an in-shell check (`git commit` opens vim, `:Git`,
  `:NERDTreeToggle`, image-size delta) was left to the maintainer; no result was recorded here.
