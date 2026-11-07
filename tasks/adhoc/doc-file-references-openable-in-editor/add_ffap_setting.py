#!/usr/bin/env python3
"""Add the helm-ff-guess-ffap-filenames setting to helm.el files (idempotent).

Inserts the comment + setq right after the line that remaps find-file to
helm-find-files. A file that already sets helm-ff-guess-ffap-filenames is left
alone; a file without the remap line is reported and left alone.

    python3 add_ffap_setting.py <helm.el> [<helm.el> ...]

Exit status 1 if any file lacked the anchor.
"""

import pathlib
import sys

ANCHOR: str = "(define-key global-map [remap find-file] #'helm-find-files)\n"
BLOCK: str = (
    ";; C-x C-f on a file name prefills it using Emacs's own find-file-at-point\n"
    ";; guesser, which also looks in parent folders.  Docs cite files relative to the\n"
    ";; repository root (tasks/reference/x.md written inside tasks/foo.md); without\n"
    ";; this, helm prefills tasks/tasks/reference/x.md, which does not exist.\n"
    "(setq helm-ff-guess-ffap-filenames t)\n"
)


def main(paths: list[str]) -> int:
    status: int = 0
    for name in paths:
        path: pathlib.Path = pathlib.Path(name)
        text: str = path.read_text()
        if "helm-ff-guess-ffap-filenames" in text:
            print(f"already set  {name}")
        elif text.count(ANCHOR) == 1:
            path.write_text(text.replace(ANCHOR, ANCHOR + BLOCK))
            print(f"added        {name}")
        else:
            print(f"NO ANCHOR    {name}")
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
