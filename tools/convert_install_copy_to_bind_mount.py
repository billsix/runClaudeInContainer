"""Convert a Dockerfile's install-script COPYs to build-time bind mounts.

Rewrites the Dockerfile named on the command line: every ``COPY`` whose sources
are all ``entrypoint/*.sh`` install scripts and whose destination is
``/usr/local/bin/`` is removed, and each ``RUN`` that names an install or build
script (``0N-install-*.sh``, ``install-*.sh``, ``0N-build-*.sh``) under
``/usr/local/bin/`` gains one
``--mount=type=bind,source=entrypoint/<script>,target=/usr/local/bin/<script>``
line per script it invokes. The ``RUN`` bodies are left as they are.

Idempotent: a second run finds no such ``COPY`` and no unmounted script use.
Read the diff afterwards: comments that described a removed ``COPY`` are left
for a person to reword. The rule and its measurements are in
``tasks/reference/build-time-bind-mounts-for-install-scripts.md``.

Usage: python3 convert_install_copy_to_bind_mount.py <path/to/Dockerfile>
"""

import pathlib
import re
import sys

COPY_START: re.Pattern[str] = re.compile(r"^COPY\s+entrypoint/[\w.-]+\.sh\b")
SCRIPT_USE: re.Pattern[str] = re.compile(
    r"/usr/local/bin/((?:\d+\w?-)?(?:install|build)-[\w.-]+\.sh)"
)
RUNTIME_SCRIPTS: frozenset[str] = frozenset({"entrypoint.sh", "shell.sh"})


def instructions(lines: list[str]) -> list[list[str]]:
    """Group lines into instructions, joining backslash continuations."""
    groups: list[list[str]] = []
    continuing: bool = False
    for line in lines:
        if continuing:
            groups[-1].append(line)
        else:
            groups.append([line])
        continuing = line.rstrip().endswith("\\") and not line.lstrip().startswith("#")
    return groups


def is_install_copy(group: list[str]) -> bool:
    """Say whether an instruction is a COPY of install scripts into /usr/local/bin/."""
    text: str = " ".join(line.rstrip("\\\n ") for line in group)
    words: list[str] = text.split()
    return (
        bool(COPY_START.match(group[0]))
        and words[-1] == "/usr/local/bin/"
        and all(
            word.startswith("entrypoint/") and word.endswith(".sh")
            for word in words[1:-1]
        )
        and not any(word.split("/")[-1] in RUNTIME_SCRIPTS for word in words[1:-1])
    )


def with_mounts(group: list[str]) -> list[str]:
    """Add one bind mount per install script a RUN instruction invokes."""
    if not group[0].startswith("RUN"):
        return group
    text: str = "".join(group)
    scripts: list[str] = [
        name
        for name in dict.fromkeys(SCRIPT_USE.findall(text))
        if f"source=entrypoint/{name}," not in text
    ]
    if not scripts:
        return group
    mounts: list[str] = [
        f"--mount=type=bind,source=entrypoint/{name},target=/usr/local/bin/{name} \\\n"
        for name in scripts
    ]
    rest: str = group[0][len("RUN") :].lstrip()
    return [
        "RUN " + mounts[0],
        *("    " + mount for mount in mounts[1:]),
        "    " + rest,
        *group[1:],
    ]


def main() -> None:
    """Rewrite the Dockerfile in place and report the counts."""
    path: pathlib.Path = pathlib.Path(sys.argv[1])
    groups: list[list[str]] = instructions(path.read_text().splitlines(keepends=True))
    kept: list[list[str]] = [group for group in groups if not is_install_copy(group)]
    converted: list[list[str]] = [with_mounts(group) for group in kept]
    path.write_text("".join(line for group in converted for line in group))
    print(
        f"removed {len(groups) - len(kept)} COPY instructions, "
        f"added mounts to {sum(a != b for a, b in zip(kept, converted, strict=True))} RUN instructions"
    )


if __name__ == "__main__":
    main()
