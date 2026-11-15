# Cleaned up the open-task backlog the review found stale

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 3
**Difficulty:** 2
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §9.1, §9.2, §9.3, §9.4, §9.5 F7

## What this did

- Closed four tasks with done-records and archived them: `minimal-image-for-nested-podman-standard`
  (superseded by `MINIMAL_IMAGE`; a fleet sweep found no project on the old idiom),
  `container-cmd-podman-docker-fallback` (rollout done 2026-09-03; the personal overlay's contract
  now states the line, in github.com/billsix/dotfiles; its one-shot codemod `git rm`'d),
  `minimal-sandbox-image` (dropped 2026-09-12) and `adhoc-scripts-repo-relative-paths` (resolved;
  re-grep clean).
- `default-allow-file-rw-in-sandbox.md` depends on `suppress-claude-session-trailer.md` for the
  settings-layering decision, and its "no `settings.json`" claim now accounts for the host file
  that `CLAUDE_CONFIG_MOUNT` brings in. `emacs-contract-conformance.md` and
  `verify-emacs-config-build-flag.md` link `emacs-config-elpa.md`.
- Headers: BLUF and Context in `license-family-alignment.md`, `standardize-project-container-template.md`
  and `verify-emacs-config-build-flag.md` (which also got a Created stamp and lost its stale
  "RAM-backed nested store" text); Priority and Difficulty on separate lines; the deleted
  regardingBritt noted; the odd "2026-01" date fixed; the elided archive path in
  `consider-dropping-shfmt-procs.md` spelled out.
- `.keep` files in `tasks/adhoc/`, `tasks/reference/` and `tasks/archive/`.
