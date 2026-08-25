# Family license alignment — relicense to Apache-2.0, or keep GPLv2?

**Status:** proposed — needs a **decision** (yours). Not started.
**Priority:** 5
**Difficulty:** 2
**Created:** 2026-08-25 (William Emerison Six <billsix@gmail.com>)

## Context / why this exists

`runCrushInContainer` (`github.com/billsix/runCrushInContainer`) was relicensed **Apache-2.0** on
2026-08-25 — its model (Muse Glimmer) is Apache-2.0 and it's a fork-friendly template. **This** repo,
`runClaudeInContainer`, is currently **GPL-2.0** ("Source code under the GNU General Public License v2",
`README.md:211`, with a `LICENSE` file). So the family is now mixed: runClaudeInContainer = GPLv2,
runCrushInContainer = Apache-2.0 (and the unrelated `geometricalgebra` is LGPL-2.1). runCrushInContainer's
README still says it "follows the runClaudeInContainer family," which is no longer literally true on
license.

**The tie that makes this worth resolving:** runCrushInContainer **reuses this repo's toolchain** — its
`client/entrypoint/01-install-base.sh` and the container-per-project scaffolding are lifted from here.
Because **William Emerison Six is the sole author/copyright holder of both**, he can license his own code
under different terms per repo with no third-party consent — so there is **no legal conflict** — but the
same scripts living under GPLv2 in one repo and Apache-2.0 in another is confusing and should be a
deliberate choice, not an accident.

## The decision (yours)

1. **Relicense this repo GPLv2 → Apache-2.0** to match runCrushInContainer, making "the family" mean
   Apache-2.0. Permissive, consistent, maximally fork-friendly; **gives up GPL copyleft** (forks would no
   longer be required to stay open). Sole-author consent is all that's needed.
2. **Keep GPLv2 here** — accept the family is intentionally mixed (a copyleft Claude sandbox + a
   permissive Crush template) and **fix runCrushInContainer's "follows the family" wording** so it doesn't
   imply a shared license.
3. (Unlikely) Relicense runCrushInContainer *back* to GPLv2 — but it was chosen Apache-2.0 on purpose to
   mirror the model, so probably not.

## If option 1 (relicense to Apache-2.0) — the mechanical work

Mirror exactly what was done in runCrushInContainer (see its archived task
`tasks/archive/2026/08/25/license-project-apache-2.0.md`):

- Replace `LICENSE` with the **verbatim Apache-2.0** text (fetch from `apache.org`, don't transcribe);
  keep the existing copyright line (© 2025 William Emerison Six).
- Update `README.md` `## License` (currently GPLv2) to **Apache-2.0 (see `LICENSE`)** + a vendored-deps
  caveat.
- Add `# SPDX-License-Identifier: Apache-2.0` + copyright headers to this repo's **own** scripts /
  Dockerfile / Makefile (none carry SPDX today), after the shebang where present.
- **Scope caveat, before any sweep:** relicense **only this repo's own files**. The vendored **Emacs
  `entrypoint/.../elpa/` tree** is third-party (mostly GPL) and is *off-limits* — leave it untouched;
  mere aggregation doesn't make the repo GPL, and the Apache grant covers only the maintainer's own glue.
  Same carve-out spirit as runCrush's (skip vendored trees, patches, `.md` docs, ignore files).

## Open questions

1. **Which option — relicense this repo to Apache-2.0 (option 1), or keep GPLv2 and reword runCrush
   (option 2)?** This is the whole task; nothing proceeds until you pick. **Recommend:** if the goal is a
   permissive, widely-forkable template family, **option 1**; if you want the Claude sandbox to stay
   copyleft on purpose, **option 2** (then I just fix runCrush's "follows the family" line).

## Cross-links

- This repo: `README.md` `## License` (GPLv2) · `LICENSE`.
- Sibling (the Apache-2.0 relicense to mirror): runCrushInContainer
  `tasks/archive/2026/08/25/license-project-apache-2.0.md`, and its README "License" caveat pattern.
