#!/usr/bin/env python3
"""Switch vendored Emacs configs to the guarded package-recompile block.

For each init.el given on the command line:

* Replace ``(byte-recompile-directory package-user-dir 0)`` with BLOCK, or insert
  BLOCK after the first ``(package-initialize)`` line when the config has no
  run-time compile yet.
* Add ``:after cc-mode`` to a ``(use-package clang-format`` whose next line binds
  into ``c-mode-base-map`` without it.

Idempotent: a config that already has BLOCK and the ``:after`` line is left as is.
Prints one line per file saying what changed. Exit status 1 if a file has no
``(package-initialize)`` line to anchor on.

Usage: codemod-package-recompile.py PATH/TO/init.el ...
"""

import pathlib
import sys

OLD_LINE: str = "(byte-recompile-directory package-user-dir 0)\n"
ANCHOR: str = "(package-initialize)\n"
MARKER: str = ";; Byte-compile each vendored package that has no .elc yet"
BLOCK: str = (
    ";; Byte-compile each vendored package that has no .elc yet, through package.el's own\n"
    ";; compile (package-recompile), the same path package-install uses. The .elc land in\n"
    ";; the bind-mounted elpa/ and persist, so later starts find them and compile nothing;\n"
    ";; a package whose files cannot all compile (compat's compat-2x.el backports on a\n"
    ";; newer Emacs) still gets its other .elc and is not retried on every start.\n"
    "(dolist (entry package-alist)\n"
    "  (let ((desc (cadr entry)))\n"
    '    (unless (directory-files-recursively (package-desc-dir desc) "\\\\.elc\\\\\'")\n'
    '      (with-demoted-errors "Error while compiling: %S"\n'
    "        (package-recompile desc)))))\n"
)
CLANG_USE: str = "(use-package clang-format\n"
CLANG_BIND: str = "  :bind (:map c-mode-base-map\n"
CLANG_AFTER: str = (
    "  :after cc-mode               ; c-mode-base-map is defined by cc-mode; wait for it\n"
)


def convert(path: pathlib.Path) -> str:
    """Rewrite one init.el in place and return a short description of the change."""
    text: str = path.read_text()
    changes: list[str] = []
    if MARKER not in text:
        if OLD_LINE in text:
            text = text.replace(OLD_LINE, BLOCK, 1)
            changes.append("replaced byte-recompile-directory")
        elif ANCHOR in text:
            text = text.replace(ANCHOR, ANCHOR + BLOCK, 1)
            changes.append("added compile block")
        else:
            raise SystemExit(f"{path}: no (package-initialize) line")
    if CLANG_USE + CLANG_BIND in text:
        text = text.replace(CLANG_USE + CLANG_BIND, CLANG_USE + CLANG_AFTER + CLANG_BIND)
        changes.append("added :after cc-mode")
    path.write_text(text)
    return ", ".join(changes) if changes else "unchanged"


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        print(f"{arg}: {convert(pathlib.Path(arg))}")
