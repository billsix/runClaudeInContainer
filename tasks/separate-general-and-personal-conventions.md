# Separate general-purpose from personal/project-specific content, so others can fork it

Done: implemented 2026-08-14, reviewed and archived 2026-11-08 (William Emerison Six
<billsix@gmail.com>). The design is recorded in `tasks/reference/claude-config-layering.md` (mount 5,
the personal overlay); the fork on-ramp is `FORKING.md`.

## What was wrong

The sandbox was reusable machinery wrapped around one maintainer's conventions: the mounted
`entrypoint/dotfiles/.claude/CLAUDE.md` mixed portable advice with that maintainer's identity, GitHub
repo mapping, self-hosted Pi remote, project template, host paths and standing authorizations, and the
image baked their Emacs setup. A fork inherited all of it and could not tell the parts it must replace
from the parts it should keep.

## What changed

- **Two layers.** The mounted `CLAUDE.md` holds only portable conventions and ends with
  `@~/.claude/ai-coding-conventions.personal.md`. The repo ships a blank (comment-only)
  `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.md`, baked by the dotfiles `COPY`, so a
  bare `podman run` still resolves the import.
- **Makefile `CLAUDE_PERSONAL_MOUNT`** mounts the host's `~/.ai-coding-conventions.personal.md` over the
  blank default. It `touch`es the host file at parse time and is unconditional, like
  `CLAUDE_CONFIG_MOUNT`.
- `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.example.md` shows what to put in the
  overlay; `FORKING.md` lists what a new user changes (overlay, dotfiles, `exampleRunClaude.sh` paths,
  their own `~/.claude` auth).
- **`USE_EMACS_CONFIG`** build flag (Makefile `1`, Dockerfile `0`) drops the vendored `.emacs.d/` for a
  clean box. Its rebuild verification was split out to `tasks/verify-emacs-config-build-flag.md`.
- `exampleRunClaude.sh` kept its name and says at the top that its paths are the maintainer's and must
  be edited; the README no longer cites the maintainer's own trees.
- The mounted `CLAUDE.md` opens with "This is the SHARED layer", telling the agent to route
  maintainer-specific content to the overlay, so the split maintains itself.
- One-shot script `tasks/adhoc/separate-general-and-personal-conventions/gut_personal_from_claude_md.py`
  moved the personal sections out of `CLAUDE.md`; removed at archive.

## Decisions

- The personal overlay is a host file, mounted, never committed; the tracked copy stays blank
  (2026-08-14).
- Worked examples were generalized in place; an example moves to the overlay only when its lesson needs
  the specific repo (2026-08-14).
- The Emacs tree is gated by a build flag rather than only documented as "replace me" (2026-08-14).

## Verification (2026-11-08 review)

- `FORKING.md`, the blank and example overlay files, `CLAUDE_PERSONAL_MOUNT` (Makefile) and
  `USE_EMACS_CONFIG` (Dockerfile) are all present.
- The portable `CLAUDE.md` has no repo-mapping, host or Pi-remote content; its only mentions of the
  maintainer are `Name <email>` decision stamps, which the stamp convention requires.
