# Stop Claude Code appending `Claude-Session:` URLs to commit messages

**Status:** proposed — needs go-ahead
**Priority:** 4
**Difficulty:** 3
**Started:** 2026-09-08

## BLUF

Claude Code appends two trailers to commits it writes: `Co-Authored-By: Claude
…` and `Claude-Session: https://claude.ai/code/session_<id>`. The maintainer
wants the **first kept and the second gone** — the session id is useless to any
reader of the repo and needlessly publishes an identifier (William Emerison Six
<billsix@gmail.com>, 2026-09-08). The setting that does exactly this is
**`attribution.sessionUrl: false`**. Done = that setting is in effect for every
sandbox session, and a fresh commit shows `Co-Authored-By` with no
`Claude-Session` line.

## Context

### What triggered it

A 488-patch series in imps (`n64/OcarinaOfTime/patches/personal/`) was generated
with both trailers, putting the same session URL into 488 files destined for
possible upstream submission. The immediate instance was fixed by dropping the
line from that generator, but nothing stops the next session doing it again —
hence this task.

### The setting, verified — not guessed

Read out of the Claude Code binary's own settings schema
(`/root/.local/share/claude/versions/2.1.263`, version 2.1.263, 2026-09-08), so
these are its literal descriptions:

| key | type | binary's own description |
| --- | --- | --- |
| `attribution.commit` | string | "Attribution text for commits. Empty string hides attribution." |
| `attribution.pr` | string | "Attribution text for pull request descriptions. Empty string hides attribution." |
| **`attribution.sessionUrl`** | bool | **"Whether to append the claude.ai session link to commits and PRs created from web or Remote Control sessions (default: true). Set to false to omit the `Claude-Session` trailer and PR-body link."** |
| `includeCoAuthoredBy` | bool | "**Deprecated: Use `attribution` instead.**" |

So the wanted change is one line:

```json
{ "attribution": { "sessionUrl": false } }
```

**Do NOT reach for `includeCoAuthoredBy: false`** — it is deprecated, and the
decompiled `QJo()` shows it returns `{commit:"", pr:""}`, i.e. it removes the
`Co-Authored-By` attribution too. The maintainer explicitly wants that kept.

There is also a `commitTrailers` key referenced nearby in the same code path
(`Ei(e,t){let o=e?.commitTrailers; …}`); its exact semantics were not
established and are worth a look while implementing.

### Where the setting has to live — this is the actual design question

Per `tasks/reference/claude-config-layering.md`, `/root/.claude` is assembled
from several mounts. That makes "just add a settings.json" less obvious than it
sounds:

- The **host's `~/.claude/settings.json`** is bind-mounted in as part of
  `CLAUDE_CONFIG_MOUNT` (the whole `~/.claude` directory). It already exists and
  carries personal state — permissions, `theme`, `tui`, `enabledPlugins`.
- The repo's tracked layer (`entrypoint/dotfiles/.claude/`) currently mounts
  only `CLAUDE.md` and `commands/`, each as its own bind mount. **There is no
  tracked `settings.json` anywhere in this repo** (verified by `find`).
- A tracked `settings.json` bind-mounted over `/root/.claude/settings.json`
  would **shadow the host file wholesale**, destroying the user's permissions
  and theme. That is why this is not a one-liner.

Three ways to land it, for the maintainer to choose:

1. **Host-only (smallest).** Add `"attribution": {"sessionUrl": false}` to the
   host `~/.claude/settings.json`. One line, effective immediately, but
   untracked, per-user, and lost on a new machine — the exact class of thing the
   sandbox exists to make reproducible.
2. **Tracked + merged (best if it works).** Ship
   `entrypoint/dotfiles/.claude/settings.json` and have the entrypoint **merge**
   it into the mounted host settings at container start rather than bind-mounting
   over it. Needs a check of Claude Code's own settings precedence first —
   if it already layers managed/user/project settings, a lower-precedence file
   may do the job with no merging at all.
3. **Per-project.** A `.claude/settings.json` in each repo. Rejected as the
   primary answer: this is a sandbox-wide preference, and it would need
   repeating in every project.

Recommendation: **investigate 2, fall back to 1.** Whatever is chosen, document
it in `tasks/reference/claude-config-layering.md`, which is the standing record
of how `/root/.claude` is assembled and currently says nothing about settings
precedence.

## Goal

Every commit Claude writes in a sandbox session carries `Co-Authored-By` and no
`Claude-Session` trailer, by configuration rather than by remembering.

## Plan

- [ ] Confirm `attribution.sessionUrl` behaves as its schema description says —
      set it, make a throwaway commit, inspect the message.
- [ ] Establish Claude Code's settings precedence (managed / user / project /
      local) and whether a tracked lower-precedence file can supply this key
      without shadowing the host file.
- [ ] Implement the chosen option; if it needs a mount or an entrypoint step,
      wire it in `Makefile` / `entrypoint/`.
- [ ] Check whether `commitTrailers` is a better or complementary lever.
- [ ] Update `tasks/reference/claude-config-layering.md` with the settings layer.
- [ ] Verify from a *fresh* `make shell` that a new commit has no session line.

## Notes / decisions

- Verified against Claude Code **2.1.263**. The key is read from the binary's
  embedded schema, so re-check after a version bump — the `includeCoAuthoredBy`
  deprecation shows this surface does move.
- The maintainer is explicit that AI co-authorship attribution is **wanted**;
  only the session identifier is unwanted. Any fix that drops both is wrong.

## Open questions

1. Which of the three placements — host-only, tracked-and-merged, or
   per-project — do you want? My recommendation is to investigate the tracked
   option and fall back to host-only if Claude Code's precedence rules make
   merging awkward.
