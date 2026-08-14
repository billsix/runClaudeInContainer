# Separate general-purpose from personal/project-specific content, so others can fork it

**Status:** implemented 2026-08-14 — pending review. The maintainer still seeds
`~/.ai-coding-conventions.personal.md` from the repo-root stopgap `ai-coding-conventions.personal.md`. Rebuild-
verifying the Dockerfile Emacs flag is split out to `verify-emacs-config-build-flag.md`.
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
- **A personal overlay (e.g. `ai-coding-conventions.personal.md`, `@`-imported at the bottom of the portable
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

**Wiring (decided 2026-08-14):**

- The portable `CLAUDE.md` ends with `@~/.claude/ai-coding-conventions.personal.md`, so a user's personal layer
  is inlined every session without editing the tracked file.
- The repo ships a **blank** `entrypoint/dotfiles/.claude/ai-coding-conventions.personal.md`, baked into the image
  by the existing `COPY entrypoint/dotfiles/ /root/`. This is the default so that a bare
  `podman run` **without** the Makefile still resolves the `@`-import instead of dangling.
  (An empty `@`-imported file inlines nothing — that's the correct no-op default.)
- The **Makefile mounts the host's `~/.ai-coding-conventions.personal.md`** over
  `/root/.claude/ai-coding-conventions.personal.md`, shadowing the blank baked default in normal `make shell` use.
  The mount is built at parse time exactly like `CLAUDE_CONFIG_MOUNT`'s `mkdir -p`, so the
  Makefile **creates the host file if it doesn't exist**:

  ```make
  CLAUDE_PERSONAL_MOUNT := $(shell touch $(HOME)/.ai-coding-conventions.personal.md; \
      echo "-v $(HOME)/.ai-coding-conventions.personal.md:/root/.claude/ai-coding-conventions.personal.md:Z")
  ```

  Add `$(CLAUDE_PERSONAL_MOUNT)` to `FILES_TO_MOUNT`. Two details that mirror the
  `~/.claude` mount and must not be "cleaned up": the `touch` lives **inside** `$(shell …)`
  (the var is `:=`-expanded at parse time, and `make` runs on the host, so this creates the
  host file itself — no manual step); and the mount is **unconditional** (always present),
  because the `@`-import target must always exist.
- A `ai-coding-conventions.personal.example.md` with placeholders (name/email, GitHub user, repo mapping, mount
  layout) documents what to put in `~/.ai-coding-conventions.personal.md`. The in-repo
  `ai-coding-conventions.personal.md` stays **blank** and tracked; the real content lives only on the host file.

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
change: (a) copy `ai-coding-conventions.personal.example.md` → `ai-coding-conventions.personal.md`, fill in identity + repos + mounts;
(b) swap the dotfiles (`.extrabashrc`, `.emacs.d/`); (c) edit `exampleRunClaude.example.sh`
paths; (d) note that a host `~/.claude` supplies their own auth. Without this, a forker
can't tell the portable parts from the parts they must overwrite.

## Verification

- A fresh clone with a *different* `ai-coding-conventions.personal.md` (or none) still `make image` + `make
  shell`s and loads a coherent, non-contradictory convention set (no dangling references to
  the maintainer's repos).
- The portable `CLAUDE.md` contains no proper-noun repo/host/identity references; grep for
  `billsix`, `192.168.0.186`, `/foo/opt`, `wsix`, `mvp`, `gacalc` should hit only the
  personal overlay + examples.
- `@`-import chain still resolves in-container (the mount maps `tasks/reference/` and, if
  used, `ai-coding-conventions.personal.md`).

## Open questions

1. **Overlay file + tracking — DECIDED (2026-08-14):** `@~/.claude/ai-coding-conventions.personal.md` imported
   from the portable `CLAUDE.md`; a **blank tracked** `ai-coding-conventions.personal.md` baked as the default;
   the Makefile mounts the host's `~/.ai-coding-conventions.personal.md` over it (auto-`touch`ed
   if absent). Real personal content lives only on the host file, never committed. See
   Wiring above.
2. **Worked examples:** generalize-in-place (strip project name, keep lesson) as the default,
   moving to the personal overlay only when the lesson can't survive without the repo?
   Recommend **yes** — most rules are portable; only the citation is personal.
3. **Emacs tree:** leave vendored but documented as "replace me", or gate it behind a
   build flag (`USE_EMACS_CONFIG=0`) so a forker gets a clean box? Recommend the **build
   flag** — it's ~big and nobody wants someone else's package set.
