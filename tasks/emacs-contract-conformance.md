# Bring every vendored Emacs config into line with the Emacs contract

**Status:** in progress — items 1, 2 (smalltalk), 5, 7 and 8 done 2026-11-08; the rest
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
   the sandbox differs (`USE_EMACS_CONFIG`) in the contract, if it is deliberate. **Found 2026-11-08:**
   the sandbox's Emacs config fails at startup (`Error: void-function (helm-mode)`, exit 255, with the
   committed `init.el`): `entrypoint/dotfiles/.emacs.d/elpa/` holds only `.keep` and nothing installs the
   packages, so `helm.el` finds no helm. This predates the 2026-11-08 compile-block change.
3. **One statement of the one-client rule:** in geometricalgebra, modelviewprojection,
   multivariate-math, and runClaudeInContainer, change `preferences.el`'s eglot hook to `emacs-lisp-mode`
   (matching the shared `preferences.el`) and drop `init.el`'s `remove-hook`. Check that Python buffers
   still get exactly one client.
4. spimulator's `preferences.el`: add the shared eglot-for-emacs-lisp block.
5. **Run-time compile in every `init.el`** — **done 2026-11-08** for all 33 container configs (every
   `entrypoint/dotfiles/.emacs.d/init.el` under the project root): the per-package `package-recompile`
   compile block (the contract's "Container side"), which replaced the first form,
   `(byte-recompile-directory package-user-dir 0)`, in 29 configs and was added to the 4 that had no
   compile (multivariate-math, hanoi `cpp/`, `python/`, `rust/`). One codemod:
   `tasks/adhoc/emacs-no-build-time-compile/codemod-package-recompile.py` (list: `configs.txt`; check:
   `verify-configs.sh`).
6. Re-run the hash check (`md5sum */.emacs.d/{helm,preferences}.el`) and update the snapshot section.
7. **compat backport compile errors on every start** — **done 2026-11-08.** The vendored `compat`
   package's `compat-26.el`…`compat-30.el` never compile on Emacs 31 (`Cannot open load file …
   compat-macs.el`, under package.el's own compile too), and `byte-recompile-directory` retried them on
   every start. The maintainer chose package.el's compile (option b, 2026-11-08); `package-recompile-all`
   itself deletes and rebuilds every `.elc` on each call, so the block calls `package-recompile` only for
   packages with no `.elc`. The errors now appear once per fresh `elpa/`, not on every start.
8. **`clang-format` binding before cc-mode** — **done 2026-11-08** by the same codemod: the six configs
   whose `use-package clang-format` bound into `c-mode-base-map` without `:after cc-mode` (gltron,
   smalltalk, spimulator, texExpToPng, billsEmacsConfigs `c/` and `cpp/`) now have it, matching Craft.

## Open questions

1. **Theme:** is the active theme a per-project choice (`material` in the Python projects,
   `modus-vivendi` in the C ones), or should one be the standard? *Recommend: per-project choice, recorded
   as a variant.*

## Decisions

- **Run-time byte-compile is the standard** (William Emerison Six <billsix@gmail.com>, 2026-11-08):
  packages are never installed or compiled in a `Dockerfile`; `init.el` compiles them into the
  bind-mounted `elpa/` on Emacs's first start in `make shell`. This answered the former open question 2
  (the recommendation there had been to drop it). Recorded in `tasks/reference/emacs-container-contract.md`.
- **The run-time compile uses package.el's compile, once per package** (William Emerison Six
  <billsix@gmail.com> chose package.el's compile path, 2026-11-08): the compile block calls
  `package-recompile` on each package with no `.elc`, replacing `byte-recompile-directory`, which retried
  compat's uncompilable backport files on every start. `package-recompile-all` was rejected because it
  rebuilds every `.elc` on every call.
