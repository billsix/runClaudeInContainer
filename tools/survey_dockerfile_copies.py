"""Classify every COPY of a single file or script in the fleet's Dockerfiles.

For each git-tracked ``Dockerfile*`` / ``Containerfile*`` in the repos given on the
command line, list each file a ``COPY`` brings in from the build context and say
how the image uses it:

- ``build-only``: a later ``RUN`` in the same Dockerfile names the copied path,
  and nothing else tracked in the repo (Makefile, entrypoint scripts, workflows)
  names it. A candidate for ``RUN --mount=type=bind``.
- ``build+runtime``: a ``RUN`` names it and so does something outside the Dockerfile.
- ``runtime``: no ``RUN`` names it (dotfiles, baked source, an entrypoint).

Directory copies and ``COPY --from`` are reported as ``directory`` / ``from-stage``
and need reading by hand. Output is tab-separated, one copied file per line.

Usage: python3 survey_dockerfile_copies.py <repo-dir>...  > copies.tsv
"""

import pathlib
import re
import subprocess
import sys

DOCKERFILE_NAME: re.Pattern[str] = re.compile(r"(^|/)(Dockerfile|Containerfile)[^/]*$")
OUTSIDE_USERS: tuple[str, ...] = ("Makefile", "*.sh", "*.yml", "*.yaml", "*.mk")


def joined_instructions(text: str) -> list[str]:
    """Return the Dockerfile's instructions with continuations joined and comments dropped."""
    lines: list[str] = [
        line for line in text.splitlines() if not line.lstrip().startswith("#")
    ]
    return re.sub(r"\\\n", " ", "\n".join(lines)).splitlines()


def tracked(repo: pathlib.Path, *patterns: str) -> list[str]:
    """List the repo's git-tracked files, optionally limited to pathspecs."""
    result: subprocess.CompletedProcess[str] = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "--", *patterns],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.stdout.splitlines()


def committed(repo: pathlib.Path, path: str) -> str:
    """Return a tracked file's content as of HEAD."""
    result: subprocess.CompletedProcess[str] = subprocess.run(
        ["git", "-C", str(repo), "show", f"HEAD:{path}"],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.stdout


def named_outside(repo: pathlib.Path, dockerfile: str, needle: str) -> bool:
    """Say whether a tracked build or script file other than the Dockerfile names the path."""
    result: subprocess.CompletedProcess[str] = subprocess.run(
        ["git", "-C", str(repo), "grep", "-l", "-F", needle, "--", *OUTSIDE_USERS],
        capture_output=True,
        text=True,
        check=False,
    )
    return any(
        hit != dockerfile and not hit.startswith("tasks/")
        for hit in result.stdout.splitlines()
    )


def classify(
    repo: pathlib.Path, dockerfile: str, source: str, target: str, runs: str
) -> str:
    """Classify one copied file by where its in-image path is named."""
    context: pathlib.Path = (repo / dockerfile).parent
    if (context / source).is_dir() or source.endswith("/") or source == ".":
        return "directory"
    name: str = source.rsplit("/", 1)[-1]
    # A target with no file extension that is not the file's own name is a directory.
    into_directory: bool = target.endswith("/") or (
        "." not in target.rsplit("/", 1)[-1] and not target.endswith("/" + name)
    )
    in_image: str = target.rstrip("/") + "/" + name if into_directory else target
    in_run: bool = in_image in runs
    match (in_run, named_outside(repo, dockerfile, in_image)):
        case (True, False):
            return "build-only"
        case (True, True):
            return "build+runtime"
        case _:
            return "runtime"


def survey(repo: pathlib.Path) -> list[str]:
    """Return one tab-separated row per copied file in the repo's Dockerfiles."""
    rows: list[str] = []
    for dockerfile in filter(DOCKERFILE_NAME.search, tracked(repo)):
        instructions: list[str] = joined_instructions(committed(repo, dockerfile))
        runs: str = "\n".join(line for line in instructions if line.startswith("RUN"))
        for instruction in instructions:
            words: list[str] = instruction.split()
            if not words or words[0] != "COPY":
                continue
            if any(word.startswith("--from") for word in words):
                rows.append(f"{repo.name}\t{dockerfile}\tfrom-stage\t{instruction}")
                continue
            arguments: list[str] = [
                word for word in words[1:] if not word.startswith("--")
            ]
            rows.extend(
                f"{repo.name}\t{dockerfile}\t"
                f"{classify(repo, dockerfile, source, arguments[-1], runs)}\t"
                f"{source}\t{arguments[-1]}"
                for source in arguments[:-1]
            )
    return rows


def main() -> None:
    """Print the survey rows for every repo named on the command line."""
    for argument in sys.argv[1:]:
        print("\n".join(survey(pathlib.Path(argument))))


if __name__ == "__main__":
    main()
