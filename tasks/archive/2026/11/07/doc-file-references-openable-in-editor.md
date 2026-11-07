# Opened root-relative doc references from Emacs (`C-x C-f`), fleet-wide

**Done 2026-11-07.** Decision and pilot check by William Emerison Six <billsix@gmail.com>; the rollout was
committed by the agent under the maintainer's go-ahead ("turn gpg signing off temporarily, do the commit
… do the same for the others as you fan it out"), on branch `helm-ffap-root-relative` in each repo.

## What was done

Docs across the fleet cite files repo-root-relative (`tasks/reference/x.md` written inside
`tasks/foo.md`). With the cursor on such a name, `C-x C-f` (helm's `helm-find-files`, which every config
remaps it to) prefilled `tasks/tasks/reference/x.md`, which does not exist. Every vendored `helm.el` now
sets:

```elisp
(setq helm-ff-guess-ffap-filenames t)
```

with a comment, right after the `[remap find-file] #'helm-find-files` line. That makes helm build the
prefill with Emacs's own find-file-at-point guesser (ffap), which looks in parent folders when the name
doesn't exist next to the current file. A root-relative name then resolves from any depth, including
`tasks/archive/<Y>/<M>/<D>/`.

The convention is recorded in three places:
- the shared `CLAUDE.md` (`entrypoint/dotfiles/.claude/CLAUDE.md`, "Doc file paths are
  repo-root-relative"), and runCrushInContainer's copy (`client/entrypoint/dotfiles/.config/crush/CLAUDE.md`);
- the personal overlay (github.com/billsix/dotfiles `.ai-coding-conventions.personal.md`, the
  emacs-vendoring rule): every vendored `helm.el` carries the setting;
- the check `tools/check_helm_file_at_point.sh <.emacs.d>` + `tools/check_helm_file_at_point.el` (an ERT
  suite run headless against a config's vendored helm and its `helm.el`), mirrored in
  runCrushInContainer `tools/`.

## Decisions

- **Fix the editor, not the docs.** Rewriting every reference to be relative to its containing file
  (`../tasks/reference/x.md`) was considered and rejected: an agent opens a prose path relative to its
  working directory, the repo root (Claude Code resolves `@`-imports relative to the file but prose paths
  relative to the working directory; claudeissues.com issue 51305), so file-relative paths would be
  misread, worst in archived tasks five folders deep; archiving would have to rewrite every reference
  inside the moved doc; commit messages and code comments have no containing file; and there were
  ~6,300+ backticked root-relative references fleet-wide. Root-relative paths are depth-independent, so
  archived tasks needed no change.
- **The built-in setting, not custom code.** A custom advice (resolve from the `project.el` root, strip
  `:<line>` and trailing punctuation) was written first and passed the same tests. It was dropped once
  testing showed plain ffap already finds these names and helm only had it switched off: same results,
  nothing to vendor or maintain.
- Things to watch: ffap's parent-folder search is not limited to the repo, so a same-named file in a
  folder above the repo could win (none existed); with the option on, ffap's mode-specific guessing
  (e.g. library names in Lisp buffers) also feeds helm's prefill.
- **hanoi is out of scope** here: its three configs (`cpp/`, `python/`, `rust/`) don't use helm at all,
  so `C-x C-f` prefills nothing. Bringing hanoi onto the same Emacs setup as geometricalgebra and
  modelviewprojection is its own task, in hanoi (maintainer's request, 2026-11-07).

## Verification

- The check's seven cases: a root-relative name resolves; `x.md:42` and a sentence-ending `x.md.`
  resolve; a file-relative name that exists next to the doc still wins; a name in a deep archived doc
  resolves; a nonexistent name is not turned into another file; plain `ffap-file-at-point` resolves.
- **Negative control:** against geometricalgebra's `helm.el` from before the change, the 4 root-relative
  cases fail and the other 3 pass.
- **Maintainer check:** `C-x C-f` in geometricalgebra's rebuilt container opened the real file
  (2026-11-07).
- **All 31 configs pass 7/7** with their own vendored helm: billsEmacsConfigs' 20 language folders
  (`bash c cpp csharp go haskell java kotlin ksh nushell ocaml python racket ruby rust scala swift
  typescript zig zsh`), geometricalgebra, modelviewprojection, Craft, apue, dotfiles (host Emacs), gltron,
  multivariate-math, spimulator, texExpToPng. runClaudeInContainer and smalltalk vendor no helm, so their
  `helm.el` was tested against geometricalgebra's helm (7/7).
- The insertion codemod (`add_ffap_setting.py`, committed in the work commit and removed at archive) was
  idempotent: a second run over all 29 fan-out files changed nothing.
