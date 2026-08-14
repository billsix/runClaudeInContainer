# Separate general-purpose from personal/project-specific content, so others can fork it

**Status:** proposed — needs go-ahead
**Priority:** 4
**Difficulty:** 6

## Goal

Right now the sandbox is genuinely reusable *machinery* wrapped around **one person's**
conventions, identity, projects, and machine. A stranger who `git clone`s it inherits
William Emerison Six's GitHub-repo mapping, his self-hosted Pi remote, his project
template (mvp/gacalc/spimulator worked examples), his Emacs packages, his home-directory
paths, and standing pre-authorization arrangements addressed to him by name. Separate the
**portable layer** (advice any developer/agent benefits from) from the **personal layer**
(this maintainer's identity/projects/host), so a new user swaps in their own personal
layer and keeps the general one untouched — and can pull upstream improvements to the
general layer without merge conflicts against their customizations.

## The split (see the classification below; this is the work-list)

### 1. The mounted conventions doc is the hard part — split it in two

`entrypoint/dotfiles/.claude/CLAUDE.md` (1296 lines) interleaves both kinds. Split into:

- **`CLAUDE.md` (portable):** confirm-before-acting, use-your-discretion, comment
  reflow / line-length, caveats-inline, the overused-phrases guidance, externally-defined
  names, extract-a-function rules, total dispatch, keep-the-goal-in-sight, the
  question-handling family, version-sorting, multi-step-check-script exit codes,
  instrumentation-driven debugging, source-code generation, changelogs/versioning, the
  git *staging* discipline, and the task/reference/adhoc/stack **methodology** (the method
  is general even though this maintainer designed it).
- **A personal overlay (e.g. `personal.md`, `@`-imported at the bottom of the portable
  `CLAUDE.md`):** the GitHub-URL convention + the confirmed dir→repo mapping + the Pi
  remote (`pi@192.168.0.186`); "My project layout (the container-per-project template)"
  with its mvp/gacalc/spimulator/texExpToPng/hanoi/gltron examples; "Multi-repo sessions"
  (`/foo`, `/bar` mounts); the standing pre-authorization arrangements stamped "(Bill,
  <date>)"; and the identity anchor ("who the user is") — keep the *mechanism* (identify
  by `git config`) in the portable layer, move the maintainer's own name/email examples
  to personal.
- **Worked examples stamped with a specific project** ("(mvp, 2026-07-18)", "(gacalc,
  …)"): for each, decide keep-and-generalize (strip the project name, keep the lesson, in
  the portable layer) vs move-to-personal (the lesson is inseparable from the maintainer's
  repo). Most can be generalized — the *rule* is portable; only the citation is personal.

Ship a `personal.example.md` (placeholders: your name/email, your GitHub user, your repo
mapping, your mount layout) so a forker copies it to `personal.md` and fills it in. Add an
`@`-import at the end of the portable `CLAUDE.md` (`@~/.claude/personal.md`) so a user's
own conventions layer in without editing the tracked file. Decide whether `personal.md` is
gitignored (a fork keeps it out of git) or tracked-as-template.

### 2. The `@`-imported reference docs — sort by audience

- **Portable (keep `@`-imported for everyone):** `llm-overused-phrases.md`,
  `print-debugging.md` — pure general advice.
- **About THIS sandbox (portable to anyone using this sandbox):** `nested-podman-design.md`,
  `sandbox-capability-map.md`, `claude-config-layering.md` — keep, they describe the image
  itself, not the maintainer.
- **Personal:** anything project-specific (the GitHub mapping lives in the convention text,
  not a reference doc today — keep it that way, in the personal overlay).

### 3. De-personalize the container machinery (small, mechanical)

- `exampleRunClaude.sh` — hardcodes `/home/wsix/opt/`, `openstax`, `n64`. Rename to
  `exampleRunClaude.example.sh` (or keep as-is but comment it as "edit these paths"), and
  make the README example generic.
- `entrypoint/dotfiles/.emacs.d/elpa/` (the large vendored Emacs tree) and `.extrabashrc`
  — this maintainer's editor/prompt. Document them as "replace with your own dotfiles";
  consider a build flag so a forker can opt out of the Emacs tree entirely.
- README "openstax and N64 trees" → a generic example.
- LICENSE/copyright stays the maintainer's; add a short "forking / attribution" note.

### 4. A new-user on-ramp (this is the missing piece)

Add a `FORKING.md` (or a README section) that lists **exactly** what a new user must
change: (a) copy `personal.example.md` → `personal.md`, fill in identity + repos + mounts;
(b) swap the dotfiles (`.extrabashrc`, `.emacs.d/`); (c) edit `exampleRunClaude.example.sh`
paths; (d) note that a host `~/.claude` supplies their own auth. Without this, a forker
can't tell the portable parts from the parts they must overwrite.

## Verification

- A fresh clone with a *different* `personal.md` (or none) still `make image` + `make
  shell`s and loads a coherent, non-contradictory convention set (no dangling references to
  the maintainer's repos).
- The portable `CLAUDE.md` contains no proper-noun repo/host/identity references; grep for
  `billsix`, `192.168.0.186`, `/foo/opt`, `wsix`, `mvp`, `gacalc` should hit only the
  personal overlay + examples.
- `@`-import chain still resolves in-container (the mount maps `tasks/reference/` and, if
  used, `personal.md`).

## Open questions

1. **Overlay file name + tracking:** `personal.md` `@`-imported and **gitignored** (cleanest
   for forks — your customization never conflicts with upstream), or tracked as
   `personal.example.md` + a gitignored real `personal.md`? Recommend: **both** — track
   `personal.example.md`, gitignore `personal.md`, `@`-import `personal.md`.
2. **Worked examples:** generalize-in-place (strip project name, keep lesson) as the default,
   moving to the personal overlay only when the lesson can't survive without the repo?
   Recommend **yes** — most rules are portable; only the citation is personal.
3. **Emacs tree:** leave vendored but documented as "replace me", or gate it behind a
   build flag (`USE_EMACS_CONFIG=0`) so a forker gets a clean box? Recommend the **build
   flag** — it's ~big and nobody wants someone else's package set.
