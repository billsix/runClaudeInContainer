# Make doc file references openable from the editor (file-relative paths, or an Emacs root fallback)

**Status:** proposed — needs a decision (open questions below)
**Priority:** 5
**Difficulty:** 4 for the Emacs-side option; 7 for the full rewrite (fleet-wide, ~6,300+ references)
Created 2026-11-07 (William Emerison Six <billsix@gmail.com>). **When done, mirror to
runCrushInContainer** (its conventions copy and its task docs).

## BLUF

Docs across the fleet cite files **root-relative**: `tasks/reference/galgebra-comparison.md` inside
`tasks/foo.md`. In Emacs, find-file-at-point resolves that against the *buffer's* directory and looks
for `tasks/tasks/reference/…`, which doesn't exist. The maintainer wants references to open from the
editor. Two ways to get there: **(a)** rewrite every reference as a path relative to the file that
contains it, climbing to the repo root first (`../tasks/reference/galgebra-comparison.md` from
`tasks/foo.md`), make that the convention, and sweep every repo including archived tasks; or **(b)**
leave the docs alone and teach Emacs to fall back to the project root when the buffer-relative path
doesn't exist. Done = the chosen option is in place, the cross-project conventions say what a doc path
means, and (for (a)) every repo's references are rewritten and verified to resolve.

## Context

- The maintainer's request (2026-11-07): references should be "relative to the pwd" of the file, e.g.
  from `tasks/` either `../tasks/reference/galgebra-comparison.md` or a path that resolves from there,
  "for the purpose of use in a text editor like emacs".
- Conventions that would change under (a): `entrypoint/dotfiles/.claude/CLAUDE.md` ("Never cite an
  artifact you have not verified exists", "A bare label is not a reference", the archiving rule that
  says to fix inbound pointers when a doc moves) and `tasks/reference/task-doc-conventions.md`,
  `tasks/reference/communication-conventions.md`; the runCrush mirrors of each.
- Emacs config for (b): github.com/billsix/billsEmacsConfigs (per-language
  `<lang>/entrypoint/dotfiles/.emacs.d/preferences.el`), plus each project's vendored `.emacs.d`.
  None of them configure `ffap`, `project.el` file-at-point, or projectile today (checked 2026-11-07).
- Upstream-only checkouts (e.g. `galgebra`) are read-only per the personal overlay and are excluded
  from any sweep.

## Research (2026-11-07)

**Scale.** Backticked root-relative references (`tasks/…`, `src/…`, `tools/…`, `entrypoint/…`,
`proofs/…`, `book/…`) via `git grep` per repo: geometricalgebra ~2,194, imps ~1,010,
runCrushInContainer ~735, spimulator ~614, runClaudeInContainer ~449, hanoi ~437, smc ~215, impo ~189,
gltron ~159, Craft ~141, epix-mirror ~100, billsEmacsConfigs ~73. That is ~6,300+ before counting other
prefixes and plain-prose paths.

**How an agent resolves a path in a doc.** Claude Code resolves `@`-imports relative to the file that
contains them, but a path written in prose is opened relative to the agent's **working directory**
(the repo root). A filed Claude Code issue describes exactly that split causing silent load failures
(claudeissues.com issue 51305, "@ imports and prose paths resolve against different roots"). So under
(a), an agent reading `../tasks/reference/x.md` in `tasks/foo.md` will by default open
`<root>/../tasks/reference/x.md`, outside the repo. A conventions rule ("a path in a doc is relative to
the doc's own directory") prevents most such misreads, but it is a standing source of mistakes, and
worse in deep files: an archived task at `tasks/archive/2026/11/07/` needs `../../../../../`.

**Other costs of (a).**
- **A moved file's outgoing references all break.** Archiving (`tasks/x.md` →
  `tasks/archive/<Y>/<M>/<D>/x.md`) changes the depth by four, so every reference *inside* the moved
  doc must be rewritten, on top of today's "fix inbound pointers". This needs a tool run on every
  archive, or it rots.
- **Locations that have no "file" stay root-relative:** commit messages, chat/terminal output, and
  reports. Code comments would need `../../tasks/...` from `src/pkg/x.py`. So it becomes two
  conventions.
- **Mitigated by the maintainer's form:** climbing to the root and then writing the root-relative tail
  (`../tasks/reference/x.md`, not the shortest `reference/x.md`) keeps the tail constant, so
  `git grep tasks/reference/x.md` still finds every reference. If (a) is chosen, use this form.
- **Benefit beyond Emacs:** GitHub resolves Markdown *links* (`[text](path)`) relative to the file, so
  real links become clickable on GitHub. Backticked paths are not links on GitHub either way.

**How the maintainer opens a path today (2026-11-07):** cursor on the file name, `C-x C-f`, and the
name is prefilled. In billsEmacsConfigs that key is remapped to helm's `helm-find-files`
(`<lang>/entrypoint/dotfiles/.emacs.d/helm.el`: `[remap find-file] #'helm-find-files`). Helm builds the
prefill in `helm-find-files-initial-input`, which calls `helm-ffap-guesser`, which is Emacs's `ffap`
("find file at point") guesser with a few features removed (read in the vendored
`elpa/helm-20261025.1539/helm-files.el`). The guess is resolved against the buffer's directory, so in
`tasks/foo.md` the name `tasks/reference/x.md` prefills as the nonexistent `tasks/tasks/reference/x.md`.

**Option (b), the Emacs side.** `ffap` resolves a relative name against `default-directory`, and
an advice on helm's guesser can add a fallback. About ten lines in each `helm.el`: when the name at
point doesn't exist relative to the buffer, try it relative to `(project-root (project-current))` (the
git root via the built-in `project.el`). Sketch (to be tested, not final):

```elisp
(defun bill/helm-guess-from-project-root (guess)
  "If the file name at point doesn't exist here, try it from the project root."
  (let ((name (thing-at-point 'filename t))
        (project (project-current)))
    (or (and guess (file-exists-p guess) guess)
        (and name project
             (let ((from-root (expand-file-name name (project-root project))))
               (and (file-exists-p from-root) from-root)))
        guess)))
(advice-add 'helm-ffap-guesser :filter-return #'bill/helm-guess-from-project-root)
``` Every existing reference then opens, nothing in the docs
changes, and there is no agent-resolution risk. Limitation: it fixes Emacs only (not another editor or
GitHub), and it has to reach every vendored `.emacs.d` (the same fan-out the `update-emacs-packages`
targets already do).

**Agent recommendation:** (b). If GitHub clickability matters too, add a narrow (a′): convert only
real Markdown links to file-relative, and leave backticked paths root-relative.

## Plan

**If (b):**
1. Write the fallback (the sketch above) in billsEmacsConfigs `helm.el` (one copy per language
   config), keeping buffer-relative as the first try. No new key: it rides on `C-x C-f`.
2. Test in the sandbox's Emacs: from `tasks/foo.md`, `ffap` on `tasks/reference/x.md` opens the file;
   a genuinely buffer-relative path still wins.
3. Propagate to every project's vendored `.emacs.d` (list the repos; each is its own commit).
4. Add a line to the cross-project conventions: "doc paths are repo-root-relative; Emacs resolves them
   via the project-root fallback".

**If (a):**
1. Decide the exact rules (open questions 2–3) and write them into
   `entrypoint/dotfiles/.claude/CLAUDE.md` + `task-doc-conventions.md` (and the runCrush mirrors):
   doc paths are file-relative via the root (`../…/<root-relative tail>`); the archiving step rewrites
   the moved doc's outgoing references.
2. Write `tools/relativize_doc_refs.py`: per repo, `git grep` the candidate references, keep only those
   that resolve from the repo root (so prose that merely looks like a path is untouched), rewrite each
   to the file-relative form, and report anything ambiguous. Idempotent: a second run changes nothing.
   Also a `--check` mode that fails on any reference that does not resolve from its file (the gate,
   and the tool the archive step runs).
3. Run it repo by repo over every maintainer-owned repo under the parent directory, **including
   `tasks/archive/`**; one commit per repo; `--check` clean after each.
4. Mirror the tool and the conventions to runCrushInContainer.

## Open questions

1. **Which approach:** (a) rewrite every doc reference to be file-relative (your proposal), (b) keep
   root-relative references and add an Emacs project-root fallback (my recommendation), or (c) (b) plus
   converting only real Markdown links to file-relative for GitHub?
2. **If (a), which contexts convert?** My suggestion: task docs, reference docs, `CLAUDE.md`, and
   READMEs convert; commit messages, chat, and code comments stay root-relative. Do you want code
   comments converted too?
3. ~~If (b), which key?~~ **Answered (William Emerison Six <billsix@gmail.com>, 2026-11-07):** cursor
   on the name, `C-x C-f`, which is helm's `helm-find-files` prefilling from `helm-ffap-guesser`. The
   fallback attaches there.
