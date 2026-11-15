# Fix the sandbox's own Emacs config (empty elpa, wrong LSP root)

**Status:** proposed — needs go-ahead (follow-up; not in the 2026-11-15 batch)
**Priority:** 6
**Difficulty:** 4
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §4.4 F5

## BLUF

The vendored `.emacs.d` does not load: `elpa/` holds only `.keep`, so `init.el` stops at `void-function (helm-mode)`, and `init.el` pins the LSP root to `/geometricalgebra/`. Not part of the 2026-11-15 batch (maintainer decision); a follow-up.

## Context

- Options from the review: (a) follow the Emacs contract (vendor `elpa/`, `make update-emacs-packages`, bind-mount it, LSP root = this repo); (b) drop the vendored config (`USE_EMACS_CONFIG=0` default); (c) install at build (breaks the contract). The reviewer recommended (a).
- Related: `tasks/emacs-contract-conformance.md` (records the load failure), `tasks/verify-emacs-config-build-flag.md`.
- Contract: `tasks/reference/emacs-container-contract.md` (its `:295` claim about the sandbox is false).

## Plan

1. Get the maintainer's choice of (a)/(b)/(c).
2. Implement it; `emacs --batch -l init.el` loads cleanly; correct the contract doc.
