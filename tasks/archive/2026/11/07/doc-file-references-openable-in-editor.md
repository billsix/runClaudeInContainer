# Open root-relative doc references from Emacs: a project-root fallback for `C-x C-f`

**Status:** in progress — pilot passed its automated tests in geometricalgebra (2026-11-07); waiting on
the maintainer's interactive check, then the rollout needs a go-ahead. **When done, mirror to runCrushInContainer.**
**Priority:** 5
**Difficulty:** 4
Created 2026-11-07 (William Emerison Six <billsix@gmail.com>).

## BLUF

Docs across the fleet cite files **repo-root-relative** (`tasks/reference/galgebra-comparison.md` inside
`tasks/foo.md`). In Emacs, `C-x C-f` with the cursor on such a name prefills it relative to the current
file's folder (`tasks/tasks/reference/…`, which doesn't exist). Fix it in the editor, not the docs: turn on helm's use
of Emacs's own find-file-at-point guesser, which already looks in parent folders
(`(setq helm-ff-guess-ffap-filenames t)`, one line per config). Pilot it in **geometricalgebra**. If it works, add the line to every vendored `helm.el` and the host
`dotfiles` Emacs, promote the test to `tools/`, and record the convention. Done = the setting is tested and in every Emacs config the
maintainer uses, and the conventions say doc paths are root-relative and why that is enough.

## Decision (William Emerison Six <billsix@gmail.com>, 2026-11-07)

**Keep doc references root-relative; teach Emacs to resolve them.** The alternative, rewriting every
reference to be relative to the file containing it (`../tasks/reference/x.md` from `tasks/`), was
rejected:
- An agent opens a path written in prose relative to its working directory (the repo root), not
  relative to the doc. Claude Code resolves `@`-imports relative to the containing file, but prose paths
  relative to the working directory (claudeissues.com issue 51305). File-relative paths would be misread,
  worst in archived tasks five levels deep.
- Archiving changes a doc's depth by four, so every reference *inside* a moved doc would need rewriting
  on every archive.
- Commit messages, chat, and code comments have no containing file, so there would be two conventions.
- Scale: ~6,300+ backticked root-relative references fleet-wide (geometricalgebra ~2,194, imps ~1,010,
  runCrushInContainer ~735, spimulator ~614, runClaudeInContainer ~449, hanoi ~437, …; `git grep`,
  2026-11-07).

Root-relative paths are also depth-independent, so the fallback makes archived tasks work with no
changes, and the editor and the agent read every path the same way.

## Context

- **How the maintainer opens a path:** cursor on the file name, `C-x C-f`, and the name is prefilled.
  Every config remaps `find-file` to helm's `helm-find-files` (`.emacs.d/helm.el`:
  `[remap find-file] #'helm-find-files`). Helm builds the prefill in `helm-find-files-initial-input`,
  which calls `helm-ffap-guesser`, Emacs's built-in "find file at point" guesser (ffap) with a few
  features removed. Read in the vendored `elpa/helm-20261025.1539/helm-files.el`.
- **Repository root** = the nearest folder above the file that contains `.git`, from Emacs's built-in
  `project.el` (`(project-root (project-current))`). Inside a repo that holds another checkout with its
  own `.git` (e.g. imps' `games/gzdoom/checkout/`), the root is that checkout.
- **Emacs configs that would carry it** (git-tracked `.emacs.d/*.el`, 2026-11-07): billsEmacsConfigs
  (20 language folders, each standalone by design), Craft, apue, dotfiles (the host Emacs:
  `.emacs.d/init.el` loads `helm.el`), geometricalgebra, gltron, hanoi, multivariate-math,
  runClaudeInContainer, smalltalk, spimulator, texExpToPng. Each project's `init.el` does
  `(load-file "~/.emacs.d/helm.el")`.

## The fix: one helm setting (found and tested 2026-11-07)

Emacs's own find-file-at-point guesser (ffap) **already** resolves a root-relative name: when the name
doesn't exist next to the current file, it looks in the parent folders, so from `tasks/foo.md` (and from
`tasks/archive/2026/11/07/old.md`) it finds `<root>/tasks/reference/x.md`. Helm switches that guesser
off by default (`helm-ff-guess-ffap-filenames` is nil) and builds its prefill from the raw name instead,
which is the whole bug. So the fix is one line in each config's `helm.el`, no custom code:

```elisp
;; C-x C-f on a file name prefills it using Emacs's own find-file-at-point
;; guesser, which also looks in parent folders.  Docs cite files relative to the
;; repository root (tasks/reference/x.md written inside tasks/foo.md); without
;; this, helm prefills tasks/tasks/reference/x.md, which does not exist.
(setq helm-ff-guess-ffap-filenames t)
```

A custom advice (resolve from the `project.el` root, strip `:<line>` and trailing punctuation) was
written first and also passed the tests below. It was dropped in favour of the built-in behaviour: same
results, nothing to vendor or maintain. Things to watch: ffap's parent search is not bounded by the
repo, so a same-named file in a folder *above* the repo could win (none exists today); and with the
option on, ffap's mode-specific guessing (e.g. library names in Lisp buffers) also feeds helm's prefill.

## Pilot results (geometricalgebra, 2026-11-07)

- Change: the five lines above added to `geometricalgebra/entrypoint/dotfiles/.emacs.d/helm.el`.
- Automated test: `tasks/adhoc/doc-file-references-openable-in-editor/run-tests.sh [<.emacs.d>]`
  (default: the sibling geometricalgebra checkout) runs `test-project-root-file-at-point.el` with ERT
  headless (`emacs --batch -Q`), loading helm from that config's vendored `elpa/` and then its
  `helm.el`. It builds a throwaway git repo and checks helm's prefill (`helm-ffap-guesser`) with the
  cursor on a name: a root-relative name resolves; `x.md:42` and `x.md.` resolve; a file-relative name
  that exists next to the doc still wins; a name in a deep archived doc resolves; a nonexistent name is
  not turned into some other file; plain `ffap-file-at-point` resolves too.
- Result: **7/7 pass** with the new `helm.el` (Emacs 31.1 in the sandbox, helm 20261013.553).
  **Negative control:** against `helm.el` from git `HEAD` (no setting), the 4 root-relative cases fail
  and the other 3 pass, so the tests do exercise the fix.
- Remaining: the **maintainer's check** in the real container. gacalc's Makefile bind-mounts only
  `.emacs.d/elpa/`, and the Dockerfile delivers the rest with `COPY entrypoint/dotfiles/ /root/`, so
  run `make image`, then `make shell`, open `tasks/reciprocal-frame-hestenes.md`, put the cursor on
  `tasks/reference/frames-qr-and-reciprocal-frames.md`, and press `C-x C-f`.

## Plan

1. ~~Pilot in geometricalgebra~~ (automated part done, above); the maintainer's interactive check.
2. **Roll out** (after the maintainer's go-ahead): add the setting to every `helm.el`. Re-check the
   list with `git ls-files` for `.emacs.d/helm.el` first. As of 2026-11-07:
   - **billsEmacsConfigs, every language folder** (the maintainer asked for all of them explicitly,
     2026-11-07): `bash c cpp csharp go haskell java kotlin ksh nushell ocaml python racket ruby rust
     scala swift typescript zig zsh` (20 folders, each with its own
     `<lang>/entrypoint/dotfiles/.emacs.d/helm.el` and vendored `elpa/`). The folders are standalone by
     design, so each gets its own copy of the line. One commit for the repo is fine.
   - Craft, apue, dotfiles (host Emacs), gltron, hanoi, multivariate-math, runClaudeInContainer,
     smalltalk, spimulator, texExpToPng: one commit per repo.
   - Run `run-tests.sh <that .emacs.d>` for every config that vendors `elpa/` (all 20 billsEmacsConfigs
     folders do). Report any config whose helm version lacks `helm-ff-guess-ffap-filenames`.
3. **Promote the test** from `tasks/adhoc/` to `tools/check-helm-file-at-point.sh` (+ the `.el`) here,
   mirrored in runCrushInContainer, so a new or conformed project can be checked.
4. **Record the convention** (wording below), in both repos.

## Where the advice lives (agent's recommendation, revised for the one-line fix)

- **The rule "doc paths are repo-root-relative; don't write `../`-relative paths in docs" → the shared
  cross-project `CLAUDE.md`** (`entrypoint/dotfiles/.claude/CLAUDE.md`, and runCrushInContainer's
  mirror), next to "Never cite an artifact you have not verified exists". It applies to anyone using
  these conventions and keeps agents and editors reading paths the same way.
- **"Every vendored `helm.el` sets `helm-ff-guess-ffap-filenames`" → the personal overlay**
  (`dotfiles/.ai-coding-conventions.personal.md`), in its container-template section, next to the
  existing emacs-vendoring rule. The helm-based Emacs setup is the maintainer's own template, and the
  overlay is where the agent looks when making a new project conform.
- **The check tool → runClaudeInContainer `tools/` (mirrored in runCrushInContainer).** With the fix
  down to one built-in setting, there is no shared `.el` to vendor.

## Open questions

None for the pilot. The rollout in steps 2–3 needs the maintainer's go-ahead after the step-1 check.
