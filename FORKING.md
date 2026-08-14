# Forking this sandbox for your own use

This project is a reusable dev sandbox (the machinery: `Dockerfile`, `Makefile`,
`entrypoint/`, the nested-podman flag set, X11/Wayland passthrough) wrapped around
**the maintainer's** personal conventions, identity, and project layout. The two are
kept separate so you can adopt the machinery and the portable agent conventions while
swapping in your own personal layer — and pull upstream improvements without conflicts.

## What's portable vs personal

- **Portable (use as-is):** everything in `entrypoint/dotfiles/.claude/CLAUDE.md`
  (cross-project agent conventions), the reference docs in `tasks/reference/`, and the
  whole container build/run stack.
- **Personal (swap for your own):** the `@`-imported `~/.claude/ai-coding-conventions.personal.md` overlay,
  the dotfiles (`.extrabashrc`, the vendored `.emacs.d/`), and the example launcher.

## What you must change

1. **Your personal conventions.** Copy
   `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md` to `~/.ai-coding-conventions.personal.md`
   on your host (a hidden dotfile, so it tucks in with your other dotfiles) and fill in your
   identity, your project→URL mapping, and your mount
   layout. `make shell` mounts that file over `~/.claude/ai-coding-conventions.personal.md` (which the tracked
   `CLAUDE.md` `@`-imports), creating it empty if it doesn't exist yet. Leaving it empty
   is fine — you just get the portable conventions with nothing added.

2. **Your dotfiles.** Replace `entrypoint/dotfiles/.extrabashrc` (prompt/aliases) with
   your own. The vendored `entrypoint/dotfiles/.emacs.d/` is the maintainer's Emacs
   setup — it is **opt-out**: build with `make image USE_EMACS_CONFIG=0` for a clean box
   without it, or replace it with your own.

3. **The example launcher.** `exampleRunClaude.sh` hardcodes the maintainer's host paths
   (`EXTRA_MOUNTS=...`). Edit those to your own directories, or write your own launcher.

4. **Auth is yours automatically.** Your host `~/.claude` (Claude auth/sessions) is
   mounted in as-is — nothing to change; just sign in once on the host.

## What you should NOT need to touch

The portable `CLAUDE.md` and the `tasks/reference/` docs are written to be
maintainer-agnostic. If you find a proper-noun reference to the maintainer's repos,
host, or identity leaking into those (rather than into the personal overlay), that's a
bug in the separation — please report it.
