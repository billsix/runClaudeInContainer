# Write the shared C coding standard (sibling of the C++ and Python ones)

**Status:** done 2026-10-15 (William Emerison Six <billsix@gmail.com>) — staged in both repos,
awaiting the maintainer's commit; archive is owed after the work commit (commit 3 of the lifecycle).
**Priority:** 4
**Difficulty:** 4

## BLUF

The fleet had shared read-on-demand Python and C++ coding standards but nothing for **C**, even
though several mounted projects are C or mixed C/C++. This task wrote
`tasks/reference/c-coding-standard.md` in the same shape as the C++ doc (tier (a): what
clang-format / clang-tidy / Cppcheck / the warning level + sanitizers enforce; tier (b): the
judgment calls they can't check), mirrored it byte-identically to the two runCrushInContainer
copies, and wired the read-on-demand pointers into both sandboxes' conventions files plus the Crush
file-layout mapping. Done = the three copies are byte-identical, both `CLAUDE.md`s point at it next
to the Python/C++ pointers, and the Crush layout table lists it.

## Context

- Model: `tasks/reference/cpp-coding-standard.md` (the shape, the three-copies banner, the (a)/(b)
  split) and `tasks/cpp-coding-standard.md` (that task's record).
- Inputs: the maintainer's own modern-C notes (supplied 2026-10-15 in-session: narrow scope,
  fixed-width + `size_t` types, const correctness, immediate initialization, designated
  initializers, `<stdbool.h>`, safer string/memory handling, static analysis; plus a C23 list —
  `auto`, `nullptr`, standard `[[...]]` attributes, `_Generic`, `arr[static N]`, empty
  initializers, `static_assert`, variably-modified array parameters) **plus** online research:
  the SEI CERT C Coding Standard (rule IDs cited inline), MISRA C:2023, Jens Gustedt's *Modern C*,
  the cppreference C23 feature list, WG14 N1967 on Annex K, and the clang-tidy / Cppcheck catalogs.
- **Three corrections made to the input notes, inline where a reader acts on them** (the "look
  online besides what I said" part earned these):
  1. `strncpy`/`strncat` are **not** the safe versions — `strncpy` doesn't null-terminate on
     truncation (SEI STR31-C). Prefer `snprintf` (check its return) and `memcpy` + explicit length.
  2. Annex K `_s` functions are an **optional, largely-unimplemented** annex (glibc never shipped
     them; even Microsoft doesn't conform; WG14 N1967 proposed removal) — don't rely on them.
  3. Stack-allocated **VLAs** are optional since C11 (`__STDC_NO_VLA__`) and a stack-overflow risk;
     keep the *variably-modified parameter* form (`m[rows][cols]`, `arr[static N]`) which is just a
     pointer and allocates nothing.
- Decisions: portable (no project files named); error strategy is "one per project, stated in its
  `CLAUDE.md`" (the `goto cleanup` idiom endorsed); the `auto`/`const` rules reuse the C++ doc's
  wording where C23 matches; MISRA is cited for its UB/essential-type guidance, **not** adopted as
  a full compliance regime (non-safety projects don't).

## Files touched (2 repos)

- **runClaudeInContainer:** `tasks/reference/c-coding-standard.md` (new, canonical, 316 lines);
  `entrypoint/dotfiles/.claude/CLAUDE.md` (section heading → "Python, C++, and C"; a C pointer in
  the standards section and a C bullet in the read-on-demand index).
- **runCrushInContainer:** `tasks/reference/c-coding-standard.md` and
  `client/entrypoint/dotfiles/.config/crush/reference/c-coding-standard.md` (both copies of the
  canonical, byte-identical — `md5sum` equal); `client/entrypoint/dotfiles/.config/crush/CLAUDE.md`
  (a C bullet under Code conventions); `tasks/reference/container-file-layout.md` (a
  `c-coding-standard.md` row in the repo↔baked mapping); `CLAUDE.md` (the stale enumerated
  baked-subset list → a pointer to the mapping table, which also fixed pre-existing drift: the list
  had never been updated for the 2026-10 C++ doc bakes).

## Verification

- `md5sum` of the three `c-coding-standard.md` copies is equal.
- Both sandboxes' conventions files point at the doc next to the Python/C++ pointers; the Crush
  layout mapping lists it as baked.

## Open questions

None.
