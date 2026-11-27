"""Write one task doc per project from the COPY survey.

Reads ``data/copies.tsv`` (written by ``survey_dockerfile_copies.py``) and, for every repo
with at least one ``build-only`` row, writes
``<repo>/tasks/install-scripts-bind-mount-at-build.md`` listing that repo's
candidate files per Dockerfile. Repos named in ``SKIP`` are handled by the
research task itself. An existing task file is left alone.

Usage: python3 write_project_tasks.py <directory holding the repos>
"""

import collections
import pathlib
import sys

SLUG: str = "install-scripts-bind-mount-at-build"
SKIP: frozenset[str] = frozenset({"runClaudeInContainer", "runCrushInContainer"})
STAMP: str = "2026-11-26 (William Emerison Six <billsix@gmail.com>)"
REFERENCE: str = (
    "github.com/billsix/runClaudeInContainer "
    "`tasks/reference/build-time-bind-mounts-for-install-scripts.md`"
)

TEMPLATE: str = """# Bind-mount build-only install scripts into their RUN instead of COPYing them

**Status:** {status}
**Priority:** 6
**Difficulty:** {difficulty}
**Created:** {stamp}
**Source:** {reference} (the research and its measurements)

## BLUF

Replace each `COPY` of a build-only script (and, where nothing later needs it, a build-only input
file) in this repo's Dockerfile(s) with a `RUN --mount=type=bind` on the `RUN` that uses it. Done
means the candidates below are each converted or explicitly kept with a reason, `make image` builds,
and the repo's gate passes against the new image.

## Context

Read first: {reference}, and the "Dockerfile contract" section of the maintainer's personal overlay
template (github.com/billsix/dotfiles `.ai-coding-conventions.personal.template.md`), which states the
rule. Worked example: github.com/billsix/geometricalgebra `Dockerfile`.

The shape, one mount per script, target path unchanged so the `RUN` body stays as it is:

```dockerfile
RUN --mount=type=bind,source=entrypoint/01-install-base.sh,target=/usr/local/bin/01-install-base.sh \\
    --mount=type=cache,target=/var/cache/libdnf5 \\
    --mount=type=cache,target=/var/lib/dnf \\
    /usr/local/bin/01-install-base.sh
```

Rules that came out of the research:

- Never mount the whole `entrypoint/` directory: every layer that mounts it re-runs when any file in
  it changes.
- No `z`, `Z` or `relabel` option on the mount. They are podman-only (Docker rejects them), and a
  plain mount passed on an SELinux-enforcing host with a `:Z`-labelled context under both podman
  and Docker.
- The script must be committed executable (a mount keeps the host mode), or be run as `bash <script>`.
- `source` is relative to the build context, which for a Dockerfile in a subdirectory is whatever
  directory its `make image` passes to the build.
- Keep `COPY` for anything the running container uses: dotfiles, an entrypoint or `shell.sh` baked
  as a fallback, baked source, and any file the Makefile or another script names by its in-image path.

## Candidates (surveyed 2026-11-26, a text match: read each before converting)

A row is listed when a `RUN` in the same Dockerfile names the copied file's in-image path and no
Makefile, script or workflow in the repo does. A script that is only *mentioned* inside a string the
`RUN` writes is a false lead.

{tables}

## Plan

- [ ] Read each candidate's `RUN` and confirm the file is not needed in the finished image.
- [ ] Convert (the conversion script used for the worked example handles the
      `COPY entrypoint/<script>.sh /usr/local/bin/` case:
      github.com/billsix/runClaudeInContainer
      `tools/convert_install_copy_to_bind_mount.py`).
- [ ] Update the Dockerfile comments that describe the removed `COPY` lines, and any `.dockerignore`
      `!` re-include that existed only for a now-mounted file.
- [ ] `make image`, then the repo's gate. If a workflow under `.github/` builds the image with
      Docker, check its first run after the change (Docker 29.9.3 built the plain mount form and
      keyed its cache on the script's content in the research).

## Notes / decisions
{notes}
## Open questions
"""


def table(dockerfile: str, rows: list[tuple[str, str]]) -> str:
    """Render one Dockerfile's candidate rows as a Markdown table."""
    body: str = "\n".join(f"| `{source}` | `{target}` |" for source, target in rows)
    return f"**`{dockerfile}`**\n\n| Copied file | Destination |\n| --- | --- |\n{body}"


def main() -> None:
    """Write the task docs and report what was written or skipped."""
    root: pathlib.Path = pathlib.Path(sys.argv[1])
    data: pathlib.Path = pathlib.Path(__file__).resolve().parent / "data" / "copies.tsv"
    candidates: collections.defaultdict[str, dict[str, list[tuple[str, str]]]] = (
        collections.defaultdict(dict)
    )
    for line in data.read_text().splitlines():
        fields: list[str] = line.split("\t")
        if len(fields) == 5 and fields[2] == "build-only" and fields[0] not in SKIP:
            candidates[fields[0]].setdefault(fields[1], []).append(
                (fields[3], fields[4])
            )
    for repo, by_dockerfile in sorted(candidates.items()):
        path: pathlib.Path = root / repo / "tasks" / f"{SLUG}.md"
        if path.exists():
            print(f"exists, left alone: {path}")
            continue
        trial: bool = repo == "geometricalgebra"
        count: int = sum(len(rows) for rows in by_dockerfile.values())
        path.parent.mkdir(exist_ok=True)
        path.write_text(
            TEMPLATE.format(
                status=(
                    "in progress — the 12 install scripts are converted in the working tree "
                    "(the research trial); the other candidates are undecided"
                    if trial
                    else "proposed — needs go-ahead"
                ),
                difficulty=2 if len(by_dockerfile) == 1 and count <= 6 else 3,
                stamp=STAMP,
                reference=REFERENCE,
                tables="\n\n".join(
                    table(dockerfile, rows)
                    for dockerfile, rows in sorted(by_dockerfile.items())
                ),
                notes=(
                    "\n- The trial conversion built with default flags nested in the sandbox "
                    "(all 31 steps, 16 minutes) and `make test` gave 1412 passed, 3 skipped. The "
                    "table above is from the committed Dockerfile, before the trial.\n\n"
                    if trial
                    else "\n"
                ),
            )
        )
        print(f"wrote {path} ({count} candidates, {len(by_dockerfile)} Dockerfiles)")


if __name__ == "__main__":
    main()
