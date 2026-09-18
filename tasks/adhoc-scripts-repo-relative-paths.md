# Ad-hoc scripts must use repo-relative paths, never container-absolute

**Status:** ready — needs go-ahead to apply fixes (audit findings below are done)
**Priority:** 4
**Difficulty:** 3
Created 2026-09-18 (William Emerison Six <billsix@gmail.com>).

## BLUF

Audit every committed ad-hoc script (and any promoted `tools/` script) in this repo to make
sure none hard-codes a container-absolute mount path (`/foo/opt/...`, the scratchpad, etc.);
where one does, root it in a variable computed at the top of the script so it survives a re-run
from another machine, another user, or a differently-mounted sandbox. "Done" = every script's
paths are derived from a computed root (or an argument), the offender below is fixed, and each
fixed codemod still reproduces its diff run once on clean input. The convention itself is
**already canonical** — do not restate it, point at it.

## Context (cold-start)

The rule this task enforces already lives, verbatim, in
`tasks/reference/task-doc-conventions.md:108` ("## Ad-hoc scripts", the "**Write them relative
… NEVER to a container-absolute path**" paragraph, with both the Python
`pathlib.Path(__file__).resolve().parents[3]` and shell `git rev-parse --show-toplevel` /
`BASH_SOURCE` idioms, and the reads-**and**-writes point). This task is not to re-document the
rule — it is a one-time **audit + fix** pass over the scripts already in the tree, because the
convention post-dates some of them. A sibling convention for *format/gate* scripts (caller
`cd`s to the root, or a guarded self-`cd`) is in `shell-and-gate-scripts.md:104` — that is a
separate rule; don't merge the two.

Why it matters (the maintainer's framing): the mount path exists **only** because *this*
`make shell` was launched with that `EXTRA_MOUNTS`; `/foo/opt` here is ephemeral to this
session. A script that bakes it in is dead on arrival for the next launch, another machine, or
another contributor who mounted things elsewhere.

## Audit findings (as of 2026-09-18)

Committed ad-hoc scripts in this repo:

1. `tasks/adhoc/container-cmd-podman-docker-fallback/rollout.py:46` — **offender, but a
   subtle one.** It does `find -L /foo/opt -maxdepth 4 -name Makefile`. The `/foo/opt` here is
   **not this repo's root** — the script is a deliberately **fleet-wide** rollout that scans
   *every* project mounted under `/foo/opt` (see its docstring). So the plain repo-root idiom
   does **not** apply: rooting it in *this* repo would break its purpose. The right fix is to
   take the **fleet root** as an argument/env with a sensible derivation, not a hard-coded
   `/foo/opt`. See open question 1 — this is a judgment call, not a mechanical rewrite.
   - Note: this script is already committed as an archived task's audit trail. Confirm whether
     touching it is worthwhile at all vs. leaving a one-line comment (open question 2).

2. `tasks/adhoc/separate-general-and-personal-conventions/gut_personal_from_claude_md.py:40` —
   the `/foo/opt/<name>` at that line is **inside a string literal being processed** (prose the
   script edits out of `CLAUDE.md`), not a filesystem path the script opens. Verify this during
   execution and, if confirmed, leave it — an explicit in-code note is the correct opt-out per
   the "use your discretion" convention, not a mangle.

No other `tasks/adhoc/` scripts exist. Check for a `tools/` dir at execution time (promoted
scripts inherit the same rule — `task-doc-conventions.md:133` "make it repo-relative").

## Plan (on go-ahead)

1. Re-grep the tree for host-absolute paths in scripts (`grep -rnE '/foo/opt|/mnt/sda1|scratchpad'`
   under `tasks/adhoc/` and `tools/`), distinguishing **host mount paths** (must be rooted) from
   **in-image fixed paths** (`/venv`, `/wheels`, `/usr/local/bin`, an image's own layout — those
   are legitimate and stay).
2. Fix `rollout.py` per the decision on open question 1.
3. For any file-mutating codemod changed, prove re-runnability: revert its inputs by path to the
   pre-script SHA, run the final script once, confirm `git diff` on those files is empty
   (`task-doc-conventions.md` "Git lifecycle" paragraph).
4. Stage the touched scripts by path.

## Open questions

1. For `rollout.py`'s fleet-wide scan, how should the fleet root be supplied — (a) a positional
   arg defaulting to the current value, (b) an env var (`FLEET_ROOT`), or (c) derive it as the
   parent-of-parent of *this* repo's root (`git rev-parse --show-toplevel` then `../..`)? My
   recommendation: (a) — an explicit optional arg is the clearest and needs no assumption about
   where the fleet is mounted; the default can be `os.environ.get("FLEET_ROOT", <derived>)`.
2. Is `rollout.py` worth editing at all, given it is a finished archived-task artifact that already
   ran and won't be re-run in practice — or is a one-line comment marking the `/foo/opt` as a
   fleet-scan (not a repo path) enough? My recommendation: fix it, since the whole point of this
   task is that a saved script must survive a cold re-run.
