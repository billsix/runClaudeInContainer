# Bring every vendored Emacs config into line with the Emacs contract

**Status:** in progress — items 1 and 2 (smalltalk) done and item 5 mostly done 2026-11-08; the rest
not started (scaffolded 2026-11-07 from the survey that produced
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

1. **Drop the build-time MELPA install** — **done 2026-11-08** for every project that had one: Craft,
   then apue, gltron, smalltalk, spimulator, texExpToPng, and all 20 billsEmacsConfigs folders, one task
   each (each repo's `tasks/archive/2026/11/08/emacs-packages-not-built-in-dockerfile.md`). Discovery:
   `tasks/adhoc/emacs-no-build-time-compile/discover.sh` (snapshot in `hits.txt`); the per-project
   Emacs check: `emacs-start-check.sh` beside it. Per-project choices recorded in those tasks: gltron
   gained `03-install-emacs.sh`; apue and smalltalk install inline (they have no `0N-install-*.sh` group
   scripts at all, a separate gap); gltron, apue, texExpToPng and billsEmacsConfigs keep the
   whole-`.emacs.d` mount because they bake no Emacs config (gltron additionally because baking would
   re-run its cmake build).
2. **`ELPA_MOUNT` + `update-emacs-packages`** — smalltalk **done 2026-11-08** (it now vendors `elpa/`,
   mounts only `elpa/`, and has the refresh target). Still open: for runClaudeInContainer, document why
   the sandbox differs (`USE_EMACS_CONFIG`) in the contract, if it is deliberate.
3. **One statement of the one-client rule:** in geometricalgebra, modelviewprojection,
   multivariate-math, and runClaudeInContainer, change `preferences.el`'s eglot hook to `emacs-lisp-mode`
   (matching the shared `preferences.el`) and drop `init.el`'s `remove-hook`. Check that Python buffers
   still get exactly one client.
4. spimulator's `preferences.el`: add the shared eglot-for-emacs-lisp block.
5. Add `(byte-recompile-directory package-user-dir 0)` after `(package-initialize)` in every `init.el`
   that lacks it (decided 2026-11-08, see Decisions). Done 2026-11-08 for Craft and the 25 configs of
   item 1. **Still lacking it** (a grep of every `entrypoint/dotfiles/.emacs.d/init.el` under the
   project root, 2026-11-08): multivariate-math, and hanoi `cpp/`, `python/`, `rust/`. None of them
   compiles packages at build; they load the vendored packages uncompiled.
7. **compat backport files fail the run-time compile.** On every Emacs start,
   `byte-recompile-directory` logs `Cannot open load file … compat-macs.el` for the vendored `compat`
   package's `compat-26.el`…`compat-30.el`: those files load `compat-macs.el` by a relative path that
   only resolves when package.el compiles them. Emacs 31 never loads them, so nothing breaks and a repeat
   start takes under a second, but no `.elc` is written, so every start retries them (seen in gltron,
   apue, texExpToPng, spimulator, billsEmacsConfigs; smalltalk's package set has no `compat`). Options:
   skip `compat-2*.el`/`compat-30.el` in the compile, or compile with package.el's own
   `package-recompile-all`. Needs a decision.
8. **`clang-format` binding before cc-mode:** texExpToPng's and smalltalk's `init.el`
   `use-package clang-format` binds into `c-mode-base-map` at load (`Error (use-package):
   clang-format/:catch: … c-mode-base-map`); the contract's form is `:after cc-mode`.
6. Re-run the hash check (`md5sum */.emacs.d/{helm,preferences}.el`) and update the snapshot section.

## Open questions

1. **Theme:** is the active theme a per-project choice (`material` in the Python projects,
   `modus-vivendi` in the C ones), or should one be the standard? *Recommend: per-project choice, recorded
   as a variant.*

## Decisions

- **Run-time byte-compile is the standard** (William Emerison Six <billsix@gmail.com>, 2026-11-08):
  packages are never installed or compiled in a `Dockerfile`; `init.el`'s
  `(byte-recompile-directory package-user-dir 0)` compiles them into the bind-mounted `elpa/` on Emacs's
  first start in `make shell`, as geometricalgebra and modelviewprojection do. This answered the former
  open question 2 (the recommendation there had been to drop it). Recorded in
  `tasks/reference/emacs-container-contract.md`.
