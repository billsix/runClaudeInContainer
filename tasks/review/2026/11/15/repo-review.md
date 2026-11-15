# Repository review — 2026-11-15

**What this is:** a deep, read-only audit of runClaudeInContainer, requested by William Emerison Six
<billsix@gmail.com> on 2026-11-15. The request added a focus item: research whether nested podman
builds have an inner storage setup that avoids fuse-overlayfs's slow per-layer diff (§11).
**Snapshot warning:** this record is frozen. Re-check a finding against the tree before acting on it.
**Baseline:** none; this is the first review.

## Coverage

| # | Dimension | What was read | By |
|---|---|---|---|
| 1 | Docs ↔ docs | `CLAUDE.md`, `README.md`, `FORKING.md`, all 44 `tasks/reference/*.md`, read in full, except `llm-overused-phrases.md` and `recursive-design.md` (header, index and examples only) and the rust/haskell/javascript/cpp standards (sampled: headers, cited paths, code blocks, stamps) | three readers |
| 2 | Docs ↔ code | every path, target, flag and gate claim in the docs above, checked against `Makefile`, `Dockerfile`, `entrypoint/`; 327 backticked cites resolved mechanically | readers; HIGHs re-checked by main thread |
| 3 | Product content | the shared conventions `entrypoint/dotfiles/.claude/CLAUDE.md` (in full) and `README.md` (in full) | main thread |
| 4 | Code quality | the five shared tools in `tasks/reference/` (`*.py`, `update_dep_common.sh`), `tools/check_helm_file_at_point.*`, `entrypoint/*.sh`; ruff, ty, shellcheck, shfmt, `check_local_annotations.py` run on each; each tool exercised on scratch inputs | reader |
| 5 | Generators and tools | same tools, as gates: vacuous-pass and exit-status paths exercised | reader; vacuous passes re-run by main thread |
| 6 | Tests | doctests of the tools run; untested paths listed | reader |
| 7 | Proofs | N/A (no proofs in this repo) | — |
| 8 | Build, container, CI | `Makefile`, `Dockerfile`, `.gitignore`, `exampleRunClaude.sh`, `entrypoint/`, `storage.conf`, `.emacs.d/*.el` (not the vendored `elpa/`, which holds only `.keep`), against the personal overlay's container-template contract; `make -n shell`; `emacs --batch -l init.el`; `strace podman info`. No CI workflow exists. | reader |
| 9 | Open-task backlog | all 12 `tasks/*.md` in full | reader |
| 10 | Archive hygiene | all 40 archive docs (4,232 lines; older ones by headings, Status lines and greps), `tasks/adhoc/`; every SHA via `git cat-file`, every in-repo path via `test -e` | reader |
| 11 | Focus: nested storage | local capability probes, timed scratch-store builds, web sources | reader; native-overlay mount re-run by main thread |

## 1. Docs ↔ docs

### 1.1 The shared Python-deps rule contradicts the personal overlay

VERIFIED.
- `entrypoint/dotfiles/.claude/CLAUDE.md:251` ("the venv copy wins": `uv pip install` every package into `/venv`, never reuse distro copies) and `tasks/reference/python-coding-standard.md:478-506` say one thing.
- The personal overlay (github.com/billsix/dotfiles `.ai-coding-conventions.personal.md`, section "Python deps — prefer distro `python3-*` …", stamped 2026-11-06) says the opposite: prefer distro `python3-*`, `--system-site-packages`, and distro-matching pins that pip skips.
- An agent gets both every session.

### 1.2 `:Z` guidance contradicts itself

VERIFIED.
- The project `CLAUDE.md` ("Conventions for changing this repo": "Use `:Z` on bind mounts") and `tasks/reference/nested-run-and-gates.md:57` say `:Z` is this repo's convention.
- `README.md:140-145`, `Makefile:11` and `nested-run-and-gates.md:42` say never `:Z`.
- The `Makefile` itself puts `:Z` on the repo, `~/.claude`, `.gitconfig`, `.gnupg` and the nested store (e.g. `Makefile:109,113,117,162`), all under `label=disable`. Whether those relabels cause harm here is a LEAD.

### 1.3 Three Dockerfile summaries have drifted

VERIFIED.
- The three are `CLAUDE.md` "What the pieces do", `README.md:93-105` and `tasks/reference/image-build-and-storage-pipeline.md:213-226`.
- All three leave out `entrypoint/01b-install-binary-tools.sh` (`Dockerfile:42-43`) and `entrypoint/install-lean.sh` (`Dockerfile:55-56`). The README also leaves out the `storage.conf` COPYs (`Dockerfile:19-21`).
- "~430 packages" appears in seven places, but the list has 459 entries.

### 1.4 Nested-podman section of the project `CLAUDE.md` is stale and narrates history

VERIFIED.
- It lists "a tmpfs `/var/lib/containers`" among the default flags.
- A dated "Store backend changed 2026-09-27" blockquote follows, ending "The paragraph below still describes the tmpfs mode". That is history narration in an always-read doc.
- The default is the dir store.

### 1.5 `CLAUDE.md` and `README.md:109-110` say `~/.claude` is mounted "only if it exists"

VERIFIED.
- `Makefile:138` creates it with `mkdir -p` and mounts it unconditionally.
- `tasks/reference/claude-config-layering.md:97-123` explains why it must never be conditional.
- The README list also omits `~/.vimrc`.

### 1.6 Stale Fedora and package facts

VERIFIED.
- `image-build-and-storage-pipeline.md:194,215,285` and `sandbox-capability-map.md:139` say Fedora 44.
- `sandbox-capability-map.md:156` says ".NET SDK 8" (the list installs `dotnet-sdk-10.0`).
- `:133-135` says "~300 package names" and "the Dockerfile is the authority".
- `:245` still describes the lean-image-when-nested standard, which is now the opt-in `MINIMAL_IMAGE`.

### 1.7 `tasks/reference/rust-gui-tui-and-ecosystem.md:23-27` says clippy is not installed

VERIFIED.
- `entrypoint/01-install-base.sh:69` installs `clippy`, and so does the runCrush client list.
- An agent reading the doc would skip the clippy gate.

### 1.8 Mirror drift despite "byte-identical" banners

(`cmp` against runCrushInContainer). VERIFIED.
- `token-and-context-economy.md` differs by 7 lines. The canonical is staged-modified, so a re-copy is in flight.
- The runCrush client's baked `recursive-design.md` differs by 84 lines (the Gram–Schmidt example).
- The runCrush client's `rust-coding-standard.md` lacks the `doctests-by-default.md` cross-link.
- Every other claimed mirror matches.

### 1.9 Contradictions between topic docs and the shared `CLAUDE.md`

VERIFIED.
- `diversion-stack-and-scope.md:110-114` says to move stale work to a "paused/deferred section" of the stack, but the session-end sweep says paused/deferred work is a task doc, not stack content.
- `reference-doc-conventions.md:208-256` is the "Full checklist" for the session-end sweep, but it lacks the stack-trim and token-waste-review steps the shared `CLAUDE.md` requires.
- `shell-and-gate-scripts.md:51-54` and `:239-248` describe the same `pkill -f` trap twice, with different exit codes.

### 1.10 Orphan reference docs

(no trigger entry in the shared `CLAUDE.md`, no inbound link): `lean-proof-methodology.md`; `makefile-feature-flag-guards.md` (cited only by the personal overlay); `shell-exec-and-container-template.md` (cited only by an open task). VERIFIED with `git grep -l`.

### 1.11 Bare first-name stamps, against the shared `CLAUDE.md`'s own rule

VERIFIED.
- Shared `CLAUDE.md:629,638,647` (section headings).
- `task-doc-conventions.md:61,72`; `reference-doc-conventions.md:27,130,170,208,214,234`; `git-workflow-conventions.md:14`; `diversion-stack-and-scope.md:50,93`; `llm-overused-phrases.md:10,11,72,79`.
- `python-coding-standard.md:61`; `nested-run-and-gates.md:34`; `shell-and-gate-scripts.md:21,132`.

### 1.12 Shared concept defined only in the personal overlay

VERIFIED.
- "Upstream-only checkout" is used by `commands/audit-repo.md:16`, `commands/findings-to-tasks.md:23` and `repo-review-conventions.md:100`.
- Only the maintainer's personal overlay defines it. The fork template `ai-coding-conventions.personal.example.md` has no such section.

### 1.13 Low: history narration and residue

VERIFIED.
- Ten docs carry "(Relocated verbatim from `CLAUDE.md`, 2026-09-14)", no longer true after later edits.
- `print-debugging.md:113` "Last updated 2026-08-13".
- `image-build-and-storage-pipeline.md:241` "your mental model is exactly right".
- `README.md:27-28,34-36` narrate the auth fix's history.

### 1.14 Low: labels and duplicated sections

VERIFIED.
- The shared `CLAUDE.md:221` heading says "Python, C++, and C"; line 247 says "all five languages", and six standards exist.
- `doctests-by-default.md:1` is titled "(Python and Rust)" but has a C++ section.
- Three near-verbatim duplicates: the `.git-blame-ignore-revs` text (`code-style-conventions.md:276-287` / `cpp-build-modernization.md:312-321`); "Generated files: edit the source" (`codegen-conventions.md:57-68` / `cpp-build-modernization.md:323-329`); the `modernize-loop-convert` lesson (`code-style-conventions.md:145-173` / `cpp-ownership-migration.md:139-154`).

### 1.15 Low: cross-repo cites by nickname, not URL

VERIFIED. `script-language-choice.md:153-171` (imps, runCrush, gltron, smc), `versioning-and-changelogs.md:96` (gacalc), and the shared `CLAUDE.md:431` `tools/check_changelog.py` (which lives in github.com/billsix/geometricalgebra).

### 1.16 `/archive-task` contradicts the archive lifecycle

VERIFIED by text comparison.
- `entrypoint/dotfiles/.claude/commands/archive-task.md:25-32` does the done-record rewrite (step 8), `git mv` (step 9) and the one-shot `git rm` (step 10) in one run, and never checks that the work commit exists.
- `task-doc-conventions.md:71-90` and the shared `CLAUDE.md` "Archiving" require three commits: the rewrite ships with the work, then the move and the `git rm` go in their own commit after it.
- Step 11 ("Do not commit — leave staging to me") contradicts "staging is your half" (`git-workflow-conventions.md:9-12`).
- `commands/stack-pop.md:16-18` archives right away via `/archive-task`, so it inherits the problem.

### 1.17 Low: other command-vs-doc mismatches

VERIFIED.
- `commands/stack-push.md:9-31` creates and pushes into an unsectioned stack, while the live layout has "Active diversion chain" and other sections.
- `commands/new-task.md:21` uses `in-progress` + `**Started:**`; `findings-to-tasks.md:44` and the batch workflow use `proposed` + `**Created:**`.
- `diversion-stack-and-scope.md:77` says `/stack` shows top-first; `commands/stack.md:13` says root first.
- `commands/audit-repo.md:27-29` (quick mode) names only the C checkers; dimension 4 also names `check_local_annotations.py`.

## 2. Docs ↔ code

### 2.1 `tasks/reference/image-build-and-storage-pipeline.md:82,89,138` gives a sweep command that fails

VERIFIED.
- It shows the cleanup trap as `rm -rf "$STORE"` on `EXIT INT TERM`, and tells readers to sweep leaked stores with a bare `rm -rf ~/.cache/runclaude-nested.*`.
- The `Makefile` (~:292) uses `podman unshare rm -rf` on `EXIT INT TERM HUP`. `nested-podman-design.md:297-309` and `README.md:177` say a bare `rm` fails with Permission denied.

### 2.2 Dangling pointers to tasks that were archived

VERIFIED with `test -e` and `find`.
- `Makefile:246` and `entrypoint/shell.sh:6` → `tasks/add-shell-exec-target.md` (now `tasks/archive/2026/08/29/`).
- `Makefile:283` → `tasks/nested-store-cleanup-permission-denied.md` (now `tasks/archive/2026/11/08/`).
- `nested-podman-design.md:178` and `minimal-nested-images.md:21` → `tasks/decouple-minimal-image-from-nested-podman.md` (now `tasks/archive/2026/09/27/`).
- `nested-run-and-gates.md:61` → an elided `tasks/archive/.../nested-podman.md`.

### 2.3 `tauri-desktop-apps.md` has bad pointers

VERIFIED for the first two.
- `:333,343` say `rust-gui-tui-and-ecosystem.md` holds the `CARGO_HOME`/`CARGO_TARGET_DIR` pattern; it does not (grep returns nothing).
- `:298` cites a towersofhanoi `entrypoint/04-install-rust.sh` that does not exist (the deps are in `rust/entrypoint/01-install-rust-base.sh`).
- `:328`'s `make rust-tauri` target is not in any towersofhanoi Makefile (LEAD).

### 2.4 The `/etc/containers/storage.conf` main-file COPY (`Dockerfile:19`) is never read

by the current podman. VERIFIED by `strace podman info`: podman opened `/root/.config/containers/storage.conf` (baked by the dotfiles COPY) and the drop-ins, never `/etc/containers/storage.conf`. `nested-podman-design.md:286` ("podman info reads /etc/…") is wrong; `:273` agrees with strace.

### 2.5 Low: smaller stale claims

VERIFIED.
- `claude-config-layering.md:44` says "those five reference docs" (there are 44).
- `CLAUDE.md` says "runCrush mirrors all three" after listing four vendored tools.
- `nested-run-and-gates.md:34` says Xvfb is "explicit in … Dockerfile" (it is in `01-install-base.sh`).
- `nested-podman-design.md:222` calls the disk-backed store an open thread (it is done).
- `README.md:58` calls the five-line auth hint "a one-line reminder".
- `README.md:111-115` names four mounted reference docs; the whole `tasks/reference/` is mounted (`Makefile:162`).
- `README.md` "Layout" omits `tools/`, `entrypoint/01b-install-binary-tools.sh`, `install-lean.sh`, `format.sh` and `.config/containers/storage.conf`.

## 3. Product content (the shared conventions and the README)

The main thread read the shared `CLAUDE.md` (11,869 words, about 16K tokens, paid every turn by every session and every fork) and the README. Findings not already in §1–§2:

### 3.1 The always-loaded file restates its topic docs at length

VERIFIED by comparison.
- "Archiving" (shared `CLAUDE.md:527-547`) nearly restates `task-doc-conventions.md:57-104`.
- The session-end sweep block (`:647-682`) is about 35 lines.
- The personal overlay's template contract, imported every session, adds about 61 KB more.
- Each cut to rule + pointer is paid back every turn.

### 3.2 The rule "Before building a large image nested, ask me to build it on the host" rests on the fuse-overlayfs premise that §11 overturns

Same for `README.md:252-258` ("No launch flag avoids this"), the project `CLAUDE.md` "Nested layer commits are slow", and `nested-run-and-gates.md` ("Build big images on the host"). If §11's fix is adopted, all four need rewriting. VERIFIED that the premise is false here (§11).

## 4. Code quality

### 4.1 The canonical `check_local_annotations.py` fails its own rule and ruff

VERIFIED.
- `--include-module` on itself reports 11 un-annotated bindings (lines 48, 102, 107, 108, 165, 166, 180, 181, 199, 208, 216).
- `ruff check` reports EXE001 (shebang, mode 644) and PERF402 (`:80`, `:140`), and `ruff format --check` would reformat the file.
- `check_file`, `iter_py` and `main` have no docstrings.
- The other three `.py` tools are clean, and `ty` passes on all four.

### 4.2 `check_local_annotations.py:216` crashes on a file outside the vendoring repo

: `relative_to(root)` raises `ValueError`, giving rc=1 with a traceback. VERIFIED.

### 4.3 The C standard contradicts itself

VERIFIED by running clang-tidy on a conforming chain (`warning: do not use 'else' after 'return'`).
- `c-coding-standard.md:48-49` lists `readability-else-after-return` as a tier-(a) authority. The Dispatch rule (`:279-322`) requires exactly the `if`/`else if`/`else` return chains that check flags.
- `cpp-coding-standard.md:49` lists the same check.
- `python-coding-standard.md:332` resolves the Python analogue (RET505/RET506) explicitly.

### 4.4 Emacs config

VERIFIED.
- The vendored config does not load: `entrypoint/dotfiles/.emacs.d/elpa/` holds only `.keep`, and no build step installs packages. `emacs --batch -l init.el` stops with `void-function (helm-mode)`, so the theme, LSP and preferences never load.
- `init.el:55-56` hard-codes the LSP root to `"/geometricalgebra/"` (copied from another project). `init.el:3-4` describes a bind-mounted `elpa/` that this Makefile does not mount.
- `emacs-container-contract.md:295` ("the sandbox installs its packages differently") is not true.
- The open task `tasks/emacs-contract-conformance.md:39-42` records the load failure.

### 4.5 Low: smaller tool issues

- `c-coding-standard.md:137` has an unbraced `if` while `readability-braces-around-statements` is a listed authority. VERIFIED.
- `c_designated_init_check.py` misses positional initializers that come from a macro (`#define PINIT {1,2}`). VERIFIED.
- `update_dep_common.sh:54-56` runs `rm -rf` on the vendored dep before `git archive`, so a bad ref empties the tree and the temp clone leaks. VERIFIED by reading.
- `show_version`'s `|| echo` fallback works only under `pipefail`. VERIFIED by reading.
- `tools/check_helm_file_at_point.el:30` leaves a `prfap-*` temp repo on every run, and the `.sh` splices a path into `--eval` unquoted. VERIFIED.
- shellcheck SC2155 at `entrypoint/dotfiles/.extrabashrc:2,7,8`. VERIFIED.
- `entrypoint/entrypoint.sh` uses `#!/bin/env bash`. VERIFIED.
- The shell recipe traps `INT` without exiting, so cleanup may run twice. LEAD.

## 5. Generators and tools (as gates)

### 5.1 `check_local_annotations.py` passes vacuously

VERIFIED by the main thread: `python3 check_local_annotations.py /nonexistent_dir_xyz` → rc=0.
- A path that is neither a directory nor a `.py` file is skipped silently, and so is a missing default `src`.
- A typo in a project's `make type-check` turns the gate green.
- Vendored in github.com/billsix/spimulator, github.com/billsix/methodfinder and others.

### 5.2 `c_designated_init_check.py` passes vacuously, and cannot report errors

VERIFIED by the main thread.
- With sources matching nothing, it gives rc=0, while `c_dispatch_check.py` correctly gives rc=2 for the same input.
- One unparseable TU raises `CalledProcessError` and exits 1, which looks the same as "sites found".
- Vendored in github.com/billsix/spimulator, whose `designated_init_check` meson test depends on it.

### 5.3 `c_dispatch_check.py:712,825` exits 1 on setup failures, which reads as "sites flagged"

VERIFIED for a missing `compile_commands.json` (traceback, rc=1; the docstring promises 2). A missing `clang` would do the same (LEAD).

### 5.4 `review_status.py` bugs

VERIFIED on scratch inputs.
- `latest_record` sorts every `*.md` under `tasks/review/`, so a `tasks/review/README.md` would be chosen over dated records.
- `citations` gives one record credit for another record's §refs when a Source line names two records.
- The tier regex `[A-Za-z]+` misreads multi-word tiers ("Nice to have"), gluing lines onto the previous bullet.

## 6. Tests

### 6.1 Tests for the shared tools

- `review_status.py`'s doctests pass. `c_dispatch_check.py` has a doctest only for `flagged()`. `check_local_annotations.py`, `c_designated_init_check.py` and `update_dep_common.sh` have none.
- Every exit-status and error path in §5 is untested, which is how the vacuous passes went unnoticed. These are good doctest candidates (`doctests-by-default.md`).
- `tools/check_helm_file_at_point.sh` passes 7/7 against the geometricalgebra `.emacs.d`. VERIFIED.

## 7. Proofs

N/A.

## 8. Build, container, CI

### 8.1 Dockerfile layer order breaks least-volatile-first

VERIFIED by reading.
- `COPY entrypoint/dotfiles/ /root/` (`Dockerfile:8`) and the `USE_EMACS_CONFIG` ARG/RUN (`:26-27`) sit before the slow package layer (`:35`).
- So any edit to `.extrabashrc`, `storage.conf`, `.claude/` or the Emacs files, or a flag flip, re-runs the whole ~459-package install.

### 8.2 The Makefile has no `PODMAN_RUN_FLAGS`

VERIFIED (`grep -c PODMAN_RUN_FLAGS Makefile` = 0).
- The contract says every project Makefile carries it. So `make format`'s `podman run` does not get `--cgroups=disabled` when run nested.
- `shell-exec` has no `image` prerequisite.
- No doc records the sandbox as exempt.

### 8.3 `make format` is not clean, and `format.sh` lost its executable bit

VERIFIED.
- `shfmt -d -i 4 entrypoint/*.sh` shows a diff in `01b-install-binary-tools.sh`.
- `entrypoint/format.sh` is mode 100644, while every other entrypoint script is 100755.

### 8.4 Low: ignore files

VERIFIED.
- `.gitignore:6` `#*#` is read as a comment, so Emacs autosave files are not ignored (`git check-ignore '#foo#'` exits 1).
- `tasks/reference/__pycache__/` is untracked, not ignored, and mounted into `~/.claude/reference`.
- No `.dockerignore`, although the Dockerfile COPYs a directory (low impact: 208 KB).

### 8.5 Low: container-absolute paths in committed text

VERIFIED. `minimal-nested-images.md:89,126` (`/foo/opt/…`) and `README.md:188` (`/mnt/sda1/tmpContainerStorage`).

## 9. Open-task backlog

### 9.1 `tasks/minimal-image-for-nested-podman-standard.md` rests on an overturned premise

VERIFIED.
- It is the backlog's top item (P3), yet it still rolls out `FLAG ?= $(if $(filter 1,$(NESTED_PODMAN)),0,1)` (`:23`, `:94`) and never mentions `MINIMAL_IMAGE`.
- The idiom was renamed and inverted to the opt-in `MINIMAL_IMAGE` on 2026-09-27 (`tasks/archive/2026/09/27/decouple-minimal-image-from-nested-podman.md`; shared `CLAUDE.md` "Running projects in a nested container").

### 9.2 `tasks/container-cmd-podman-docker-fallback.md:3` says "proposed — needs go-ahead", but the rollout is done

VERIFIED.
- `:71-80` records the 47-Makefile rollout as done 2026-09-03, and `Makefile:18` auto-detects.
- Still open: the personal overlay's Makefile contract still lists `CONTAINER_CMD = podman` as invariant, and the new-project scaffolding is unchanged.

### 9.3 Tasks that should be archived

VERIFIED.
- `tasks/minimal-sandbox-image.md` is "dropped (2026-09-12)" but still in `tasks/` at P6.
- `tasks/adhoc-scripts-repo-relative-paths.md` is resolved (its remaining re-grep is clean), but still carries its Plan and its answered questions.

### 9.4 Overlapping tasks

VERIFIED.
- `tasks/default-allow-file-rw-in-sandbox.md:42` ("There is no `settings.json` today") ignores the host `~/.claude/settings.json` that `CLAUDE_CONFIG_MOUNT` brings in.
- Its baked-file plan would shadow that file, the same layering question `tasks/suppress-claude-session-trailer.md:56-70` analyses. One should own the design and the other depend on it.
- `tasks/emacs-contract-conformance.md` and `tasks/verify-emacs-config-build-flag.md:158` should cross-link (§4.4).

### 9.5 Low: missing BLUF/Context and stale text

VERIFIED.
- `license-family-alignment.md`, `standardize-project-container-template.md` and `verify-emacs-config-build-flag.md` lack BLUF/Context. The last also has no Created stamp, and `:159` "RAM-backed nested store" is stale.
- `standardize-project-container-template.md:59,67` have bare "Bill" stamps, and `:108,170` name the deleted regardingBritt.
- `default-allow-file-rw-in-sandbox.md:47` "2026-01 understanding".
- `consider-dropping-shfmt-procs.md:19` cites an elided archive path (the real one is `tasks/archive/2026/11/06/upgrade-to-fedora-45.md`).
- No `.keep` anywhere under `tasks/`, against `task-doc-conventions.md:163`.

### 9.6 Backlog as the docs currently read

(lowest Priority, then Difficulty). No task is `blocked`.

| Task | Status as written | P | D |
|---|---|---|---|
| minimal-image-for-nested-podman-standard | proposed (premise stale, §9.1) | 3 | 3 |
| default-allow-file-rw-in-sandbox | proposed, decided | 4 | 2 |
| adhoc-scripts-repo-relative-paths | resolved, not archived (§9.3) | 4 | 3 |
| suppress-claude-session-trailer | proposed, 1 open question | 4 | 3 |
| container-cmd-podman-docker-fallback | "proposed" but rollout done (§9.2) | 4 | 4 |
| license-family-alignment | needs maintainer decision | 5 | 2 |
| standardize-project-container-template | proposed | 5 | 5 |
| verify-emacs-config-build-flag | proposed | 6 | 2 |
| sandbox-commands-in-tools-bin | proposed | 6 | 3 |
| emacs-contract-conformance | in progress, 1 open question | 6 | 4 |
| consider-dropping-shfmt-procs | proposed (decision) | 7 | 2 |
| minimal-sandbox-image | dropped, not archived | 6 | 4 |

## 10. Archive hygiene

### 10.1 `tasks/archive/2026/09/11/nested-podman-signal-inherited-doc-cleanup.md:3` was archived as "proposed — needs go-ahead"

VERIFIED.
- It still has a forward-looking BLUF and a Work list, though the work is done.
- It cites `FULL_TOOLCHAIN` and the tmpfs store with no superseded note.

### 10.2 Dangling SHAs

VERIFIED with `git cat-file -e`: all four are MISSING. `9cbba23`, `eccac33`, `3606c06` and `1319adb` in `tasks/archive/2026/11/13/nested-podman-host-image-store-ignored.md:50,54,72,74` were squashed into `05a7ce0` "nested storage works" / `6f1bed1` "archived".

### 10.3 Archive docs never rewritten into done-records

(all predate the 2026-11-02 done-record rule). VERIFIED by heading and Status grep.
- Still carrying Plan / Open questions / Context: `2026/06/02/organize-archived-tasks` (an unchecked `- [ ]`), `07/29/llm-overused-phrases`, `08/13/extract-dockerfile…`, `08/29/nested-podman-run-flags-passthrough`, `08/31/doc-deltas…`, `09/03/squash-harvest…`, `09/10/vim-user-toolkit`, `09/14/trim-claude-md`, `09/18/bulk-ops…`, `09/18/fix-rollout-py…`, `10/01/dockerfile-cache-mount…`, `10/15/c-coding-standard`.
- Status lines that no longer match what happened: `08/29/fan-out-shell-exec-to-projects.md:72-76` has unchecked items duplicated as done; `09/18/fix-rollout-py-fleet-root-arg.md:3` says "awaiting maintainer review (may be reverted)"; `09/18/bulk-ops…:3` and `11/09/review-status-tool.md:4` say "archive owed".

### 10.4 Archive paths that point at tasks since archived

VERIFIED with `test -e`.
- `08/13/extract-dockerfile-steps-into-host-scripts.md:173`, `08/13/print-debugging-guidance-multilang.md:91`, `08/13/sphinx-human-readable-reference-docs.md:59,87,88`, `08/29/fan-out-shell-exec-to-projects.md:173`, `10/15/c-coding-standard.md:22`, `10/15/cpp-coding-standard.md:21`, `09/27/dir-backed-nested-podman-storage.md:23`, `11/13/nested-podman-host-image-store-ignored.md:4,68`.
- `07/29/llm-overused-phrases.md:34,70` points at `entrypoint/dotfiles/.claude/reference/` (gone; the doc is now `tasks/reference/llm-overused-phrases.md`).

### 10.5 Harvest of pre-September decisions not deep-checked

LEAD. The 11/06–11/13 archives' decisions do appear in reference docs.

## 11. Focus: nested podman storage without the slow diff

**Result: a viable option exists. Native kernel overlay, with `mount_program` dropped, removes the slow per-layer diff in this sandbox.**

### 11.1 Local capability

VERIFIED.
- The sandbox is root in a user namespace under a rootless host (`uid_map` `0 1000 1`), with `cap_sys_admin`, on kernel 7.3.3-300.fc45. `overlay` is in `/proc/filesystems`.
- The inner store uses `mount_program=/usr/bin/fuse-overlayfs`, and `podman info` GraphStatus reports `"Native Overlay Diff":"false"`.
- The graphroot is a bind of an ext4 directory on the host (the `NESTED_PODMAN_STORE=dir` default).
- A native overlay mount fails on the sandbox's overlay rootfs ("filesystem on u not supported as upperdir"). It **succeeds on the ext4 store volume and on tmpfs**. The main thread re-ran the store-volume mount: `NATIVE-OK`.

### 11.2 Timing

Measured by the reader on scratch stores: a one-line `RUN` on a 2.37 GB base committed in **1.06 s with native overlay, against 51.0 s with fuse-overlayfs**.
- The scratch store with no `mount_program` logged `useNativeDiff=true` and read its base from the read-only `/var/lib/shared-images` store.
- Not yet tested: a real dnf-heavy build, a rootful-host launch, or the `NESTED_PODMAN_STORE=tmpfs` path end to end.

### 11.3 What the fix needs

- Drop `mount_program` from `entrypoint/dotfiles/.config/containers/storage.conf` and from the drop-in.
- Override the vendor `metacopy=on` mountopt to `nodev`; `metacopy` is rejected with `userxattr` in a user namespace.
- Point `TMPDIR` (buildah mounts the build context there) at a real filesystem. The default `/var/tmp` on the rootfs overlay made the native build fail with `mounting an overlay over build context directory … invalid argument`.
- Use a fresh store, because an existing store's `.has-mount-program` flag pins fuse until reset (https://www.redhat.com/en/blog/podman-rootless-overlay). The per-session store already is fresh.
- Unprivileged overlay with SELinux needs kernel ≥ 5.13 (https://bugs.archlinux.org/task/71358).
- `--device /dev/fuse` may no longer be needed (INFERRED).

### 11.4 Why the docs say otherwise

The "must drive overlay through fuse-overlayfs" rationale (`storage.conf` comment, `README.md:153-155`, `nested-podman-design.md`, `image-build-and-storage-pipeline.md`) was true while the inner store sat on the overlay rootfs (or another overlay). It stopped being true when the store moved to a real filesystem on 2026-09-27. VERIFIED by the mount test.

### 11.5 Options considered and not recommended

- `--layers=false` / `--squash` (one walk instead of one per step, losing the layer cache; a stopgap): https://github.com/containers/buildah/blob/main/docs/buildah-build.1.md.
- vfs (full copy per layer).
- btrfs/zfs drivers (need the volume to be that filesystem plus privileges).
- composefs / zstd:chunked (change pull and mount, not commit; composefs is "experimental"): https://github.com/containers/storage/blob/main/docs/containers-storage.conf.5.md.
- `force_mask` / `ignore_chown_errors` (UID handling, not diff speed), same source.
- A newer fuse-overlayfs: no evidence any release adds a native diff (LEAD, not deeply researched).

## Suggested follow-ups

- **Required:**
  - [F1] Validate native overlay for the nested store (no `mount_program`, `mountopt = "nodev"`, `TMPDIR` on the store volume), time a large real build, check the tmpfs mode and `/dev/fuse` need, then adopt it in `storage.conf` + drop-in + `Makefile` (§11).
  - [F2] Once F1 lands, rewrite the "build big images on the host" rule and its four copies (shared `CLAUDE.md`, project `CLAUDE.md`, `README.md`, `nested-run-and-gates.md`) and the fuse-overlayfs rationale in `nested-podman-design.md`, `image-build-and-storage-pipeline.md`, the `storage.conf` comment (§3.2, §11.4).
  - [F3] Make `check_local_annotations.py` and `c_designated_init_check.py` fail (exit 2) when no file matches or a path is missing; make `c_designated_init_check.py` report unparseable TUs; make `c_dispatch_check.py` exit 2 on setup failures; re-copy into every vendored copy (§5.1, §5.2, §5.3).
  - [F4] Resolve the Python-deps contradiction between the shared `CLAUDE.md` / `python-coding-standard.md` and the personal overlay (§1.1).

- **Recommended:**
  - [F5] Fix the Emacs config: vendor or install `elpa/` packages, set the LSP root to this repo's mount, correct `emacs-container-contract.md:295` (§4.4, §9.4).
  - [F6] Rewrite `/archive-task` and `/stack-pop` to the three-commit lifecycle: done-record rewrite staged with the work; `git mv` + one-shot `git rm` only after the work commit; stage by path (§1.16).
  - [F7] Rewrite or close `tasks/minimal-image-for-nested-podman-standard.md` around `MINIMAL_IMAGE`; fix `container-cmd-podman-docker-fallback.md`'s Status and split its leftovers; archive `minimal-sandbox-image.md` and `adhoc-scripts-repo-relative-paths.md`; merge the settings-placement design of the two settings tasks (§9.1–§9.4).
  - [F8] Bring `check_local_annotations.py` to its own standard (annotations, ruff, docstrings, `+x`) and fix its `relative_to` crash (§4.1, §4.2).
  - [F9] Fix the `review_status.py` bugs (`latest_record`, multi-record `citations`, tier regex) and add doctests for every tool's exit paths (§5.4, §6.1).
  - [F10] Fix the stale and contradictory infra docs: `:Z` guidance, Dockerfile summaries + package count, nested-podman section of the project `CLAUDE.md`, the `~/.claude` "only if it exists" claim, Fedora 44 / .NET 8 / clippy claims, the bare-`rm` sweep command (§1.2–§1.7, §2.1).
  - [F11] Repoint dangling task pointers in `Makefile`, `shell.sh`, reference docs and the archive, and the four missing SHAs (§2.2, §10.2, §10.4).
  - [F12] Resolve the C standard's `readability-else-after-return` vs Dispatch contradiction (C and C++) (§4.3).
  - [F13] Reorder the Dockerfile least-volatile-first (dotfiles COPY and the Emacs-config step after the package, Claude Code and Lean layers) (§8.1).
  - [F14] Re-copy the drifted mirrors into runCrushInContainer (`token-and-context-economy.md`, the client's `recursive-design.md` and `rust-coding-standard.md`) (§1.8).

- **Optional:**
  - [F15] Replace bare first-name stamps with `William Emerison Six <billsix@gmail.com>` and prose mentions with "the maintainer" across the shared `CLAUDE.md` and reference docs (§1.11, §9.5).
  - [F16] Trim the always-loaded shared `CLAUDE.md`: cut "Archiving" and the session-end block to rule + pointer; dedupe the three duplicated sections (§3.1, §1.14).
  - [F17] Index or link the three orphan reference docs; add an "upstream-only checkout" stub to the fork template (§1.10, §1.12).
  - [F18] Fix `diversion-stack-and-scope.md` and `/stack-push` to the sectioned stack layout; add the stack-trim and token-review steps to the session-end checklist doc (§1.9, §1.17).
  - [F19] Rewrite the pre-2026-11-02 archive docs into done-records, and `nested-podman-signal-inherited-doc-cleanup.md` first (§10.1, §10.3).
  - [F20] Small build fixes: `PODMAN_RUN_FLAGS` (or a documented exemption), `shell-exec: image`, `format.sh` `+x`, shfmt diff, `.gitignore` `\#*\#` and `__pycache__/`, a `.dockerignore`, the unused `/etc/containers/storage.conf` COPY, SC2155, the `entrypoint.sh` shebang (§2.4, §8.2–§8.4, §4.5).
  - [F21] Small doc fixes: `tauri-desktop-apps.md` pointers, `claude-config-layering.md` counts, history-narration residue, labels, nickname cites, container-absolute paths, README layout table, `.keep` files, BLUF/Context in three open tasks (§1.13–§1.15, §2.3, §2.5, §8.5, §9.5).

## Open questions for the maintainer

1. Should F1 (native overlay for the nested store) be validated and adopted? Recommended: yes, it is the largest payoff in this review (51 s → 1 s per commit measured).
2. Which Python-deps rule is current, the shared "venv copy wins" or the overlay's "prefer distro `python3-*` with `--system-site-packages`" (§1.1)? Recommended: decide once and delete the other.
3. Is the sandbox's own Makefile meant to be exempt from `PODMAN_RUN_FLAGS` (§8.2)? Recommended: add it (it costs one variable), unless there is a reason.
4. Which `:Z` rule is current for this repo's own mounts (§1.2)? Recommended: the README's "never `:Z`" for host trees, since the sandbox runs `label=disable`.

## Answers to the open questions (William Emerison Six <billsix@gmail.com>, 2026-11-15)

Dated note added after the review; the findings above are unchanged.

1. **Yes**: validate and adopt native overlay for the nested store (F1).
2. **(b)**, the personal overlay's newer rule: prefer distro `python3-*` with `--system-site-packages`
   and distro-matching pins. The shared `CLAUDE.md` section and `python-coding-standard.md`
   ("venv copy wins") change to match (F4).
3. **Yes**: add `PODMAN_RUN_FLAGS` to this repo's Makefile, with whatever that implies (thread it
   into every `podman run`, never `build`, and drop any doc text calling the sandbox exempt) (F20).
4. **(a)**, "never `:Z`" for host trees: change the project `CLAUDE.md` and
   `nested-run-and-gates.md:57`, and the `:Z` mounts in the `Makefile` (F10).

Also decided, for turning these findings into tasks: the RAM (tmpfs) nested store stays, behind the
existing `NESTED_PODMAN_STORE=tmpfs` toggle. `README.md` and `CLAUDE.md` say how to use it, and
`exampleRunClaude.sh` keeps the current command uncommented (plus any flag it needs to keep RAM
off) and a fixed commented-out variant that turns the RAM store on (the current commented line
sets `NESTED_PODMAN_TMPFS_SIZE` without `NESTED_PODMAN_STORE=tmpfs`, so it does not). The same
applies to runCrushInContainer.
