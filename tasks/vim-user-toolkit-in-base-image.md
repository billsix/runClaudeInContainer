# Give vim users a complete setup in the sandbox image (vim is already there)

**Status:** proposed — needs go-ahead; small. Created 2026-09-10 at the maintainer's request
(William Emerison Six <billsix@gmail.com>: "add vim, and whatever normally vim users want
installed, to the base install script"). Twin of runCrushInContainer's task of the same slug —
keep the two package lists identical.
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

## Verification / done-state

`make image` builds; in `make shell`: `git commit` opens vim, `:scriptnames` shows the baked
`.vimrc` (or the mounted host one), `:Git` and `:AirlineToggle` work. Image-size delta recorded.

## Open questions

1. **Plugin set** — recommend the six above, rpm-only.
2. **Mount host `~/.vimrc`** — recommend yes, conditional.
3. **Neovim config too?** `neovim` is installed but unconfigured; recommend leave it — one
   opinionated editor config is enough, and nvim users bring their own.
