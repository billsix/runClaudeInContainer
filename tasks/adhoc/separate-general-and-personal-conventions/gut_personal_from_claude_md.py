#!/usr/bin/env python3
"""Move maintainer-specific content out of the tracked cross-project CLAUDE.md.

Part of tasks/separate-general-and-personal-conventions.md. Replaces three
personal blocks with generalized, maintainer-agnostic stubs that point at the
personal overlay (`ai-coding-conventions.personal.md`), and appends the `@~/.claude/ai-coding-conventions.personal.md`
import. The removed specifics (repo mapping, project template, standing
authorizations) live in the host's ~/.ai-coding-conventions.personal.md instead.

Idempotent: it splices between fixed anchor strings and bails out if an anchor is
missing (already applied), so re-running is a no-op rather than a double edit.
Run from the repo root:  python tasks/adhoc/.../gut_personal_from_claude_md.py
"""
import sys
from pathlib import Path

CLAUDE = Path("entrypoint/dotfiles/.claude/CLAUDE.md")


def splice(text: str, start_anchor: str, end_anchor: str, replacement: str) -> str:
    """Replace text from start_anchor up to (not including) end_anchor.

    Returns text unchanged if start_anchor is absent (already gutted).
    """
    start = text.find(start_anchor)
    if start == -1:
        print(f"  (anchor already gone, skipping): {start_anchor[:50]!r}")
        return text
    end = text.find(end_anchor, start)
    if end == -1:
        sys.exit(f"END anchor not found after start: {end_anchor[:50]!r}")
    return text[:start] + replacement + text[end:]


# --- Edit A: the GitHub-URL subsection -> a general "canonical URL" rule ---------------
GITHUB_GENERAL = """\
### Reference projects by their canonical URL in committed docs, not the container path

My projects are **local git checkouts** bind-mounted at container paths
(`/foo/opt/<name>`, `/mnt/sda1/<name>`, etc.); those paths exist **only inside this
sandbox** and are meaningless to anyone reading the docs elsewhere. Referring to a
project by its local path in conversation is fine.

But **in anything committed or shared** — a `README.md`, `CLAUDE.md`, a task or
`tasks/reference/` doc, a code comment, a commit/PR body — **use the project's canonical
remote URL, not the container-absolute path**, so a reader knows where the source lives.
**Read the URL from the appropriate git remote rather than guessing it from the directory
name** (a mount's directory name can differ from the repo name), and **if you can't
confirm it, ask rather than inventing one.** Which remote to read, and the specific
project → URL mapping, are personal — see `ai-coding-conventions.personal.md`.

"""

# --- Edit B: the container-per-project template -> a short general pointer -------------
LAYOUT_GENERAL = """\
## My project layout (the container-per-project template)

Most of my projects share one container-per-project template (a Fedora + Podman
ephemeral-container dev environment: a `Dockerfile`, a `Makefile` of `podman run --rm`
targets, and `entrypoint/` scripts). When a new project is mounted, use that template as
a **conformance reference** — flag accidental drift (stale copy-paste, wrong paths,
missing targets), while deliberate variation is fine. The detailed tier-by-tier spec and
the per-project examples are personal — see `ai-coding-conventions.personal.md`; per-project specifics also
belong in that project's own `CLAUDE.md`.

"""

# --- Edit C: the two personal standing-authorization paragraphs -> a pointer -----------
STANDING_GENERAL = """\
**Any standing authorizations for nested runs are personal — see `ai-coding-conventions.personal.md`** (e.g. a
blanket pre-approval to add `--cgroups=disabled` transiently, or to make temporary
build-file additions a task needs). Absent such a grant, the default holds: propose the
edit and wait for the go-ahead, per point 2 above.
"""


def main() -> None:
    if not CLAUDE.exists():
        sys.exit(f"run from the repo root; {CLAUDE} not found")
    text = original = CLAUDE.read_text()

    text = splice(
        text,
        "### Reference my projects by their GitHub URL in documentation, not the local path",
        "## My project layout (the container-per-project template)",
        GITHUB_GENERAL,
    )
    text = splice(
        text,
        "## My project layout (the container-per-project template)",
        "## Running projects in a nested container",
        LAYOUT_GENERAL,
    )
    # The two standing-arrangement paragraphs are contiguous; replace from the first up
    # to the closing "## " section header that follows them.
    text = splice(
        text,
        "**Standing arrangement (Bill, 2026-06-08):**",
        "**Other specifics:**",
        STANDING_GENERAL + "\n",
    )

    # --- Edit D: append the personal-overlay @-import -------------------------------------
    import_line = "@~/.claude/ai-coding-conventions.personal.md"
    if import_line not in text:
        anchor = "@~/.claude/reference/print-debugging.md"
        note = (
            "\nFinally, `@~/.claude/ai-coding-conventions.personal.md` imports the **personal overlay** — the "
            "maintainer-specific\nlayer (identity, project→URL mapping, project "
            "template, standing authorizations). The tracked\ndefault is blank; `make "
            "shell` mounts the host's `~/.ai-coding-conventions.personal.md` over it, so the\n"
            "conventions above stay portable while personal specifics layer in per-user. "
            "See\n`ai-coding-conventions.personal.example.md` and `FORKING.md`.\n"
        )
        # insert the note just before the @-import block, and the import at the very end.
        block_start = text.find("@~/.claude/reference/llm-overused-phrases.md")
        text = text[:block_start] + note + "\n" + text[block_start:]
        text = text.rstrip("\n") + "\n" + import_line + "\n"

    if text == original:
        print("no changes (already applied)")
        return
    CLAUDE.write_text(text)
    print(f"rewrote {CLAUDE}: {len(original.splitlines())} -> {len(text.splitlines())} lines")


if __name__ == "__main__":
    main()
