# Resolved the C/C++ standards' else-after-return contradiction

**Status:** complete
**Completed:** 2026-11-15
**Priority:** 4
**Difficulty:** 1
**Created:** 2026-11-15 (William Emerison Six <billsix@gmail.com>)
**Source:** tasks/review/2026/11/15/repo-review.md §4.3, §4.5 F12

## What this did

`tasks/reference/c-coding-standard.md` and `cpp-coding-standard.md` listed clang-tidy's
`readability-else-after-return` among the checks whose clean run is authority, while the C
"Dispatch" rule (and the shared total-dispatch rule for C++) requires the `if`/`else if`/`else`
return chains that check flags. Both standards now leave it off and say why, pointing at the Python
standard's RET505/RET506 precedent (maintainer decision, 2026-11-15). The C standard's
`make_temp` example also braces its `if (fd < 0)` body, which `readability-braces-around-statements`
(still listed) requires.

Documentation only; no project's `.clang-tidy` changed. runCrushInContainer re-copies both
standards in its batch (`tasks/mirrors-and-baked-docs.md` there).

## Verification

The review's reader ran `clang-tidy -checks='-*,readability-else-after-return'` on a
Dispatch-conforming chain and got `warning: do not use 'else' after 'return'`; neither standard
lists the check now (`grep -n else-after-return` shows only the explanatory notes).
