# Versioning & changelogs — full rules, breaking-change list, and rationale

**Reference document** — the full detail behind the terse "Version numbers don't sort like
strings" and "Versioning & changelogs" rules in the cross-project `CLAUDE.md`. Read on demand
when comparing/listing versions, bumping a version, or maintaining a `CHANGELOG.md` for a
project others pin/consume. (Relocated verbatim from `CLAUDE.md`, 2026-09-14.)

## Version numbers don't sort like strings

**Anything that lists or compares versions must sort them as versions, not as text.**
`0.0.10` is *greater* than `0.0.7` but sorts *before* it lexically (`1` < `7`), so the
newest release silently vanishes from the end of an alphabetical list. This produced a
false "the `v0.0.10` tag is missing" report (2026-07-18) — the tag listing was simply
hiding it:

```sh
git tag | tail -3                      # WRONG: v0.0.7  v0.0.8  v0.0.9
git tag --sort=v:refname | tail -3      # RIGHT: v0.0.8  v0.0.9  v0.0.10
```

Applies well beyond git tags — `sort` vs `sort -V` on release names, picking the "latest"
directory or artifact by name, `ls *.tar | tail -1` for a timestamped/versioned archive,
comparing a pinned dependency against what's published. **Before reporting that a version
is missing, absent, or older than expected, re-check with a version-aware sort** (`git
tag --sort=v:refname`, `sort -V`, `packaging.version.Version` in Python) — and prefer
asking the authoritative source directly (the PyPI JSON API, `git show <tag>`, the
package metadata) over eyeballing a sorted list.

The double-digit boundary is where this bites: it is invisible through `0.0.9` and starts
lying at `0.0.10`.

## Changelogs, versioning, and communicating breaking changes

**The problem this solves:** when someone who depends on my project bumps their pinned
version, they need to know — *without reading the git log* — what changed and, above all,
what will **break**. Any project with external consumers that ships versioned releases (a
library on a registry — PyPI / npm / crates.io / …, or a tool other people pin) needs this;
a private app nobody else pins does not. The failure mode it prevents is **silent breakage**:
a consumer bumps the pin, their build or tests break, and they only find out by running them.
(This bit me in gacalc — an `is_close`→`isclose` rename with no changelog silently broke a
downstream consumer's 36 call sites, found only when its tests failed.) Two artifacts do the
job: a **version number** (so they can pin and compare) and a **changelog** (so they can read
what a bump will cost them).

### Versioning (SemVer), and the pre-1.0 reality

`MAJOR.MINOR.PATCH`. Post-1.0: a **breaking** change bumps MAJOR, a backward-compatible
feature bumps MINOR, a bug fix bumps PATCH. **Pre-1.0 (`0.y.z`)** SemVer permits breaking
anything at any time — but *permission to break is not permission to break silently*. Still
bump for it (treat a breaking change as a MINOR bump — `0.Y.0`; a compatible one as a PATCH),
and **always changelog it**. At `0.0.z` (very early) treat the whole surface as unstable but
keep the same discipline: changelog every break, bump the version every release.

**Bump the version BEFORE publishing** — package registries permanently reject a re-used
version number, so a botched release can't be overwritten, only superseded. The release
splits along the usual line (see "Git: I commit, you don't"): *you* (agent) stage the version
bump and the changelog entry; *I* (the user) tag and publish. List/compare existing versions
with a version-aware sort (see "Version numbers don't sort like strings").

### What counts as "breaking" (the things a consumer must be told)

- a public name **renamed or removed** — function, method, class, module, constant, CLI flag,
  config key, env var;
- a **default value or default behavior changed** (e.g. a tolerance that defaulted to `1e-5`
  now defaults to `0.0`);
- a **return type or accepted-input type changed**, or **validation tightened** so
  previously-accepted input now errors;
- a **new required parameter**, or a value type made **immutable / unhashable**;
- **dropped support** for a platform, language version, or dependency;
- a **license change** — not code-breaking, but consumers must know.

The test when unsure: *would a consumer who bumps the pin have to change their code, or be
surprised?* If yes, it is breaking — flag it as such.

### The changelog: what goes in, and WHEN

- **A `CHANGELOG.md` at the repo root**, newest-first: an **`[Unreleased]`** section at the
  top, then `## [version] — date` per release. Group entries with the *Keep a Changelog*
  categories (Added / Changed / Deprecated / Removed / Fixed / Security), and **call out
  breaking items explicitly** — a `### Breaking` subsection or a **BREAKING** marker, because
  that is the part consumers scan for. Lean is right; the bar is "would this break or surprise
  someone who imports or pins this?" — *not* internal refactors, generated-file churn, or
  task-tracking. Prefer a one-line entry that **links** the reference doc / task explaining the
  *why* over re-explaining it inline.
- **Write the entry WHEN you make the change**, into `[Unreleased]` — not reconstructed at
  release time, which is exactly how changes get forgotten. It is one of a finished unit's doc
  deltas (see "Git: I commit, you don't"), so it ships with the unit's staging.
- **Reconcile at the three moments that already look back — the pre-squash harvest, the session-end
  sweep, and any release (2026-09-06).** For a repo with a changelog, diff the public surface since the
  last tag (`git diff $(git describe --tags --abbrev=0)..HEAD -- src/` or the equivalent) against
  `[Unreleased]` and write whatever is missing. This is the net under the mid-task reflex, run a few
  times a session rather than per commit; per-commit changelogging was considered and declined — I
  don't commit, and re-deriving entries from diffs logs churn without the why. Promoting `[Unreleased]`
  to `## [version] — date` is **part of the version bump**, whoever performs it. A project with a
  changelog carries a cheap version↔changelog consistency check in its gate (gacalc:
  `tools/check_changelog.py` — fails when `pyproject.toml`'s version has no changelog heading); it
  catches an unlogged *release*, not an unlogged change — the reconciliation does that. **On release**, rename
  `[Unreleased]` to `## [version] — date` and open a fresh empty `[Unreleased]`. The version
  bump, the changelog promotion, and the tag belong to the **same** release commit.
- **Retro-filling a project that never had one:** create the file, document *at least* the
  recent releases a consumer would actually hit (verify which version each change shipped in
  against the tags — don't guess), and say plainly that history before some cutoff predates the
  changelog rather than inventing entries.
