# Write the shared C++ coding standard (sibling of the Python one)

**Status:** done 2026-10-15 (William Emerison Six <billsix@gmail.com>) — staged, awaiting the
maintainer's commit; archive is owed after the work commit (commit 3 of the lifecycle).
**Priority:** 4
**Difficulty:** 4

## BLUF

The fleet had a shared, read-on-demand Python coding standard but no C++ equivalent — the C++
advice was spread over four modernization docs and per-project `.clang-format` files. This task
wrote `tasks/reference/cpp-coding-standard.md` in the same shape as the Python doc (tier (a): what
clang-format / clang-tidy / the warning level enforce; tier (b): the judgment calls they can't
check), mirrored it to the two runCrushInContainer copies, and wired the read-on-demand pointers
into both sandboxes' conventions files. Done = the three copies are byte-identical, both
`CLAUDE.md`s point at it next to the Python pointer, and the Crush file-layout tables list it.

## Context

- Model: `tasks/reference/python-coding-standard.md` (the shape, the three-copies banner, the
  (a)/(b) split) and `tasks/split-python-standard-project-specifics.md` (why the shared doc names
  no project's files).
- Inputs: the maintainer's own `auto` guidelines (supplied 2026-10-15 in-session: `auto` is not
  overrated but is easily overused; use it freely when the type is obvious/redundant/long, spell
  the type when a primitive or domain type carries meaning; the `const auto&` / accidental-copy /
  qualifier-stripping pitfalls); the C++ Core Guidelines; Herb Sutter's GotW #94 (`auto x =
  Type{init}` and its three exceptions); Abseil Tips of the Week #77, #126, #161, #165, #171,
  #176, #187, #232, #234; the Google C++ Style Guide (the fleet's `BasedOnStyle: google`); the
  clang-tidy check list.
- Fleet facts the standard reflects: every C/C++ repo formats with `BasedOnStyle: google` +
  `SortIncludes: Never`; smc pins `-std=c++23 -Wall -Wextra`, epix-mirror `cpp_std=c++20` at
  `warning_level=3`; spimulator/epix-mirror carry a `.clang-tidy`; the existing
  `cpp-ownership-migration.md` / `cpp-build-modernization.md` / `cpp-python-bindings.md` docs
  stay as the *method* docs the standard links to.
- Decisions: the standard is portable (no project files named), takes the maintainer's `auto`
  rule of thumb as the base rather than Sutter's "always auto" or Google's "mostly avoid auto";
  error strategy is "one per project, stated in its `CLAUDE.md`" rather than mandating exceptions
  or `std::expected`; Google's no-exceptions rule is explicitly *not* adopted.

## Files touched (2 repos)

- `runClaudeInContainer`: new `tasks/reference/cpp-coding-standard.md` (canonical);
  `entrypoint/dotfiles/.claude/CLAUDE.md` (the "Python: the shared coding standard" section
  became "Python and C++…" and the read-on-demand index gained a line); this task doc.
- `runCrushInContainer`: the two byte-identical mirrors `tasks/reference/cpp-coding-standard.md`
  and `client/entrypoint/dotfiles/.config/crush/reference/cpp-coding-standard.md`;
  `client/entrypoint/dotfiles/.config/crush/CLAUDE.md` (a C++ bullet under "Code conventions");
  both copies of `container-file-layout.md` (new row; baked-file count 13 → 14).

## Follow-ups

- **Optional:** each C++ project's `CLAUDE.md` (smc, epix-mirror, gltron, Craft) could gain a
  one-line pointer at the shared doc plus its chosen error strategy — the standard says a project
  states that; none does yet. Not done here (out of the two-repo scope).
- **Recommended, when it next matters:** the Crush client image bakes the reference set, so the
  new baked copy reaches a Crush session only after the maintainer's next `make -C client image`.
- **Recommended at next launch:** the tracked `CLAUDE.md` edit is staged and correct in the repo,
  but the single-file bind mount at `/root/.claude/CLAUDE.md` in the session that made it still
  shows the pre-edit inode (the Edit tool saves by rename) — the new "Python and C++" section is
  in context only from the next `make shell`. Recorded as a gotcha in
  `tasks/reference/claude-config-layering.md` ("Editing workflow").
- The byte-identical rule stands: edit the canonical, re-copy over the two mirrors, `diff` to check.
