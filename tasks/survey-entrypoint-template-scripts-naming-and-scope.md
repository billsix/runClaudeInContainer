# Apply the bash naming and scope rules to the container template's `entrypoint/*.sh`, once for the fleet

**Status:** proposed — needs go-ahead
**Priority:** 7 (a readability sweep with no deadline)
**Difficulty:** 4 (few distinct scripts, many copies; the work is keeping the copies in step)
**Created:** 2026-11-25 (William Emerison Six <billsix@gmail.com>, asked whether the template's near-identical `entrypoint/*.sh` scripts should be surveyed once in this repository or per repository: "fleet wide").
**Source:** github.com/billsix/towersofhanoi `tasks/archive/2026/11/25/apply-naming-and-scope-rules-per-language-across-repositories.md` ("Not decided", now decided).

## BLUF

Every project that follows the container-per-project template carries `entrypoint/*.sh` scripts (install scripts, `shell.sh`, `format.sh`, `lint.sh`, `entrypoint.sh`) that began as copies of one another. This task applies the bash rules ("Names and scope in bash" in `tasks/reference/shell-and-gate-scripts.md`) to them once: survey every repository's copies together, decide each change once, and make it in every copy. Done means the template scripts in every project repository are surveyed, changed or recorded as left alone, and each repository's own gate still passes; and each repository's `tasks/apply-naming-and-scope-rules-per-language.md` says its `entrypoint/` scripts are covered here.

## Context

**The rules** (this repository, `tasks/reference/shell-and-gate-scripts.md`, "Names and scope in bash"): inline a variable assigned once and used once, unless its command's failure must stop the script, or it is a regular expression, a table or a setting; `${VAR:-default}` and its relatives absorb a second use; assign at the point of use, with `local` on the first assignment inside a function; a helper is never nested (functions are global); declare every function variable `local`.

**The scripts.** List them with `ls /mnt/sda1/*/entrypoint/*.sh /mnt/sda1/*/*/entrypoint/*.sh` in the sandbox (the project checkouts sit side by side; skip upstream-only checkouts, whose remotes are all third-party). Group identical and near-identical files first (`md5sum`, then `diff` within a name), so that one decision covers a group. The template itself is described in the personal overlay's template document (`ai-coding-conventions.personal.template.md`, read on demand).

**The survey tool.** `python3 ~/.claude/reference/survey_names_and_scope.py --language bash`, run in each repository, lists variables named exactly twice in a script. In github.com/billsix/towersofhanoi and github.com/billsix/spimulator (done 2026-11-25) the `entrypoint/` scripts produced no leads that were real assignments, so expect few changes; the value of this task is confirming that across the fleet and fixing the handful that exist in every copy at once.

**Each repository already has a task** `tasks/apply-naming-and-scope-rules-per-language.md` (proposed, written 2026-11-25) whose bash row counts its `entrypoint/` scripts. Those tasks keep their other shell scripts (tools, tests, gates); this task takes the template scripts out of them.

**Gate scripts must keep their shape.** A `format.sh` or `lint.sh` runs every step and fails if any failed (`status=0; cmd || status=1; … exit $status`); do not restructure that. After editing a script, check its mode (`git ls-files -s`) and restore `+x` if a rewrite dropped it.

## Plan

- [ ] List and group the scripts across the project repositories.
- [ ] Survey; read the leads once per group.
- [ ] Apply each change to every copy in the group; stage by path in each repository.
- [ ] In each repository's `tasks/apply-naming-and-scope-rules-per-language.md`, add one line saying the `entrypoint/` scripts were done here.
- [ ] Run each touched repository's format gate, or record why it was not run.

## Open questions

None.
