#!/usr/bin/env python3
"""Add a `make shell-exec` target to the two uniform bulk project families.

Ad-hoc codemod for tasks/fan-out-shell-exec-to-projects.md (runClaudeInContainer).
The `billsEmacsConfigs/*` language dirs and the `openstax/osbooks-*` book repos each
share ONE Makefile+shell.sh template (verified md5-identical modulo CONTAINER_NAME),
so this applies the same edit the core repos got by hand:

  * bundle the `shell` mount/flag block into a shared `SHELL_RUN_FLAGS` variable,
  * add `REPO_MOUNT` (each family's real in-container mount path),
  * add a `shell-exec` target (= `shell` minus `-it`, plus an empty-invocation guard),
    routing `SCRIPT=`/`CMD=` through the payload `-c 'cd $(REPO_MOUNT) && ...'`,
  * make `entrypoint/shell.sh` fail-fast (`set -e`) and forward args (`exec bash "$@"`).

IDEMPOTENT: a Makefile that already contains `SHELL_RUN_FLAGS`, or a shell.sh that
already ends `exec bash "$@"`, is left untouched. Run it twice: the second run must
report every file as "skip (already done)". It matches the EXACT known template block
per family and refuses (reports) any file that does not match, so a drifted repo is
flagged for manual handling rather than silently mangled.

Usage (from anywhere):  python3 apply_bulk.py [--check]
  --check : dry-run; report what would change, write nothing.
"""

import sys
import pathlib

CHECK = "--check" in sys.argv

# --- family definitions -----------------------------------------------------
# Each: the glob of Makefiles, the EXACT old shell-target block, the replacement,
# and (for the combined-.PHONY osbooks) a .PHONY line edit.

BILLS_OLD = (
    ".PHONY: shell\n"
    "shell: format ## Get Shell into a ephermeral container made from the image\n"
    "\t$(CONTAINER_CMD) run -it --rm $(PODMAN_RUN_FLAGS) \\\n"
    "\t\t--entrypoint /bin/bash \\\n"
    "\t\t$(FILES_TO_MOUNT) \\\n"
    "                $(ELPA_MOUNT) \\\n"
    "                $(TMUX_MOUNT) \\\n"
    "\t\t$(CONTAINER_NAME) \\\n"
    "\t\t/usr/local/bin/shell.sh"
)
BILLS_NEW = (
    "# --- shell / shell-exec share ONE container invocation, defined here so the\n"
    "# two targets can never drift. Scoped to this pair ONLY. See runClaudeInContainer\n"
    "# tasks/add-shell-exec-target.md. Selective mount (SOURCE_FILES_TO_MOUNT at\n"
    "# REPO_MOUNT) -> CMD='...' always works; SCRIPT=path only for a mounted path.\n"
    "SHELL_RUN_FLAGS = \\\n"
    "\t\t--entrypoint /bin/bash \\\n"
    "\t\t$(FILES_TO_MOUNT) \\\n"
    "\t\t$(ELPA_MOUNT) \\\n"
    "\t\t$(TMUX_MOUNT)\n"
    "\n"
    "# In-container mount root (shell.sh cd's here; SOURCE_FILES_TO_MOUNT under it).\n"
    "REPO_MOUNT = /root/texExpToPng\n"
    "\n"
    "SHELL_EXEC_ARGS = -c 'cd $(REPO_MOUNT) && $(if $(CMD),$(CMD),exec bash $(SCRIPT))'\n"
    "\n"
    ".PHONY: shell\n"
    "shell: format ## Get Shell into a ephermeral container made from the image\n"
    "\t$(CONTAINER_CMD) run -it --rm $(PODMAN_RUN_FLAGS) $(SHELL_RUN_FLAGS) $(CONTAINER_NAME) /usr/local/bin/shell.sh\n"
    "\n"
    ".PHONY: shell-exec\n"
    "# shell-exec depends on `image` (NOT `format`) so a batch run does not reformat\n"
    "# the source as a side effect -- a runner must not mutate the tree.\n"
    "shell-exec: image ## Run a script/command in the container env (no TTY): make shell-exec SCRIPT=path | CMD='...'\n"
    "\t@[ -n \"$(SCRIPT)$(CMD)\" ] || { echo 'usage: make shell-exec SCRIPT=<mounted path> | CMD=\"...\"'; exit 2; }\n"
    "\t$(CONTAINER_CMD) run --rm $(PODMAN_RUN_FLAGS) $(SHELL_RUN_FLAGS) $(CONTAINER_NAME) /usr/local/bin/shell.sh $(SHELL_EXEC_ARGS)"
)

OSBOOK_OLD = (
    "shell: image ## Interactive shell in the build container\n"
    "\t$(CONTAINER_CMD) run -it --rm $(PODMAN_RUN_FLAGS) $(FILES_TO_MOUNT) \\\n"
    "\t\t--entrypoint /bin/bash $(CONTAINER_NAME) /usr/local/bin/shell.sh"
)
OSBOOK_NEW = (
    "# --- shell / shell-exec share ONE container invocation, defined here so the\n"
    "# two targets can never drift. Scoped to this pair ONLY. See runClaudeInContainer\n"
    "# tasks/add-shell-exec-target.md. Whole repo mounted at REPO_MOUNT, so SCRIPT= works.\n"
    "SHELL_RUN_FLAGS = $(FILES_TO_MOUNT) --entrypoint /bin/bash\n"
    "\n"
    "REPO_MOUNT = /$(CONTAINER_NAME)\n"
    "\n"
    "SHELL_EXEC_ARGS = -c 'cd $(REPO_MOUNT) && $(if $(CMD),$(CMD),exec bash $(SCRIPT))'\n"
    "\n"
    "shell: image ## Interactive shell in the build container\n"
    "\t$(CONTAINER_CMD) run -it --rm $(PODMAN_RUN_FLAGS) $(SHELL_RUN_FLAGS) $(CONTAINER_NAME) /usr/local/bin/shell.sh\n"
    "\n"
    "shell-exec: image ## Run a script/command in the container env (no TTY): make shell-exec SCRIPT=path | CMD='...'\n"
    "\t@[ -n \"$(SCRIPT)$(CMD)\" ] || { echo 'usage: make shell-exec SCRIPT=<repo-relative path> | CMD=\"...\"'; exit 2; }\n"
    "\t$(CONTAINER_CMD) run --rm $(PODMAN_RUN_FLAGS) $(SHELL_RUN_FLAGS) $(CONTAINER_NAME) /usr/local/bin/shell.sh $(SHELL_EXEC_ARGS)"
)
def _add_phony_shellexec(text: str):
    """osbooks keep `shell` in a combined `.PHONY: ... shell ...` line whose target
    list varies per book. Append ` shell-exec` to whichever .PHONY line lists shell
    (as a whole word) and doesn't already list shell-exec. Returns (text, status)."""
    if "shell-exec" in text and any(
        ln.startswith(".PHONY:") and "shell-exec" in ln for ln in text.splitlines()
    ):
        return text, "ok (already)"
    out = []
    done = False
    for ln in text.splitlines(keepends=True):
        if (not done and ln.startswith(".PHONY:")
                and " shell " in f" {ln.strip()} " and "shell-exec" not in ln):
            ln = ln.rstrip("\n") + " shell-exec\n"
            done = True
        out.append(ln)
    if not done:
        return text, "no .PHONY-shell line"
    return "".join(out), "ok"


def edit_makefile(mk: pathlib.Path, old: str, new: str, add_phony=False):
    text = mk.read_text()
    if "SHELL_RUN_FLAGS" in text:
        return "skip (already done)"
    if old not in text:
        return "MISMATCH (template drift -> handle by hand)"
    text = text.replace(old, new, 1)
    if add_phony:
        text, st = _add_phony_shellexec(text)
        if st.startswith("no "):
            return "MISMATCH (.PHONY-shell line not found -> handle by hand)"
    if not CHECK:
        mk.write_text(text)
    return "edited"


def edit_shellsh(ss: pathlib.Path):
    if not ss.exists():
        return "no shell.sh"
    lines = ss.read_text().splitlines(keepends=True)
    joined = "".join(lines)
    if 'exec bash "$@"' in joined:
        return "skip (already done)"
    out, inserted_sete = [], False
    for ln in lines:
        # fail-fast: set -e just before the first `cd ` command
        if not inserted_sete and ln.lstrip().startswith("cd "):
            out.append("set -e\n")
            inserted_sete = True
        # forward args from the final interactive exec
        if ln.rstrip("\n") == "exec bash":
            out.append('exec bash "$@"\n')
        else:
            out.append(ln)
    if not inserted_sete:
        return "MISMATCH (no `cd ` line -> handle by hand)"
    if not CHECK:
        ss.write_text("".join(out))
    return "edited"


def run():
    root = pathlib.Path("/foo/opt")
    report = []
    # billsEmacsConfigs language dirs (single git repo, many subdirs)
    for mk in sorted(root.glob("billsEmacsConfigs/*/Makefile")):
        d = mk.parent
        r1 = edit_makefile(mk, BILLS_OLD, BILLS_NEW)
        r2 = edit_shellsh(d / "entrypoint" / "shell.sh")
        report.append(("billsEmacs", d.name, r1, r2))
    # openstax osbooks (each its own git repo)
    for mk in sorted(root.glob("openstax/osbooks-*/Makefile")):
        d = mk.parent
        r1 = edit_makefile(mk, OSBOOK_OLD, OSBOOK_NEW, add_phony=True)
        r2 = edit_shellsh(d / "entrypoint" / "shell.sh")
        report.append(("osbook", d.name, r1, r2))

    print(f"{'family':12} {'project':40} {'Makefile':30} shell.sh")
    for fam, name, r1, r2 in report:
        print(f"{fam:12} {name:40} {r1:30} {r2}")
    bad = [r for r in report if "MISMATCH" in r[2] or "MISMATCH" in r[3]]
    print(f"\n{len(report)} projects; {len(bad)} mismatches "
          f"({'CHECK mode, nothing written' if CHECK else 'writes applied'})")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(run())
