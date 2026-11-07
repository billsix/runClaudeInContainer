# Bring every vendored Emacs config into line with the Emacs contract

**Status:** proposed — needs go-ahead (scaffolded 2026-11-07 from the survey that produced
`tasks/reference/emacs-container-contract.md`)
**Priority:** 6
**Difficulty:** 4
Created 2026-11-07 (William Emerison Six <billsix@gmail.com>).

## BLUF

The 2026-11-07 survey of all 34 vendored Emacs configs wrote down the contract
(`tasks/reference/emacs-container-contract.md`) and found drift. Fix it, one repo per commit, so every
config matches the contract or is a documented variant. Done = the doc's "Conformance snapshot" section
is empty (or each remaining item is recorded as a deliberate variant), each changed config passes
`tools/check_helm_file_at_point.sh`, and each changed image still builds.

## Context

- Read first: `tasks/reference/emacs-container-contract.md` (the contract + the drift list) and the
  personal overlay's emacs-vendoring rule (dotfiles `.ai-coding-conventions.personal.md`).
- hanoi was conformed by its own task (hanoi `tasks/archive/2026/11/07/emacs-config-match-geometricalgebra.md`).
- Also from the snapshot: make the shared `preferences.el` eglot comment language-neutral (it names
  C/C++ in every language's copy), then re-copy it byte-identically to every config.

## Work (from the snapshot)

1. **Install via a `0N-install-emacs.sh` group script** where emacs is still in the base list or
   installed some other way: Craft, gltron, apue, billsEmacsConfigs (20 folders), smalltalk. Check each
   project's actual install path first.
2. **`ELPA_MOUNT` + `update-emacs-packages`** for smalltalk; for runClaudeInContainer, document why the
   sandbox differs (`USE_EMACS_CONFIG`) in the contract instead, if it is deliberate.
3. **One statement of the one-client rule:** in geometricalgebra, modelviewprojection,
   multivariate-math, and runClaudeInContainer, change `preferences.el`'s eglot hook to `emacs-lisp-mode`
   (matching the shared `preferences.el`) and drop `init.el`'s `remove-hook`. Check that Python buffers
   still get exactly one client.
4. spimulator's `preferences.el`: add the shared eglot-for-emacs-lisp block.
5. Decide `byte-recompile-directory` (open question 2) and apply it everywhere.
6. Re-run the hash check (`md5sum */.emacs.d/{helm,preferences}.el`) and update the snapshot section.

## Open questions

1. **Theme:** is the active theme a per-project choice (`material` in the Python projects,
   `modus-vivendi` in the C ones), or should one be the standard? *Recommend: per-project choice, recorded
   as a variant.*
2. **`(byte-recompile-directory package-user-dir 0)` at startup** (3 configs have it, 31 don't): keep it
   in all, or drop it from the three? It writes `.elc` into the bind-mounted `elpa/` (gitignored) on
   first start. *Recommend: drop it, matching the 31.*
