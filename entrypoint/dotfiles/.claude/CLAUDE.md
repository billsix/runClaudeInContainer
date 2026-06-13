# Cross-project conventions

## Confirm before acting

When I ask you to **list, identify, find, plan, or investigate** something, that's a request for the information — **not** authorization to make changes. Produce the list / plan / findings and **stop**. Wait for my explicit go-ahead ("do it", "apply them", "go ahead") before editing files or running mutating commands. When a request is ambiguous between "tell me" and "do it," treat it as "tell me" and ask.

## Git: I commit, you don't

Committing is **my** job and I do it **outside** the container, on my own schedule, as I see fit. This is my normal workflow — don't read an absence of commits as work being lost or incomplete.

- **You may stage** (`git add`) when it's helpful to group your changes, but **do not `git commit`** (and never `git push`) unless I explicitly ask in that moment. Editing the working tree is your normal mode; turning those edits into commits is mine.
- **Don't keep asking "want me to commit?"** after finishing work. Just leave the changes staged or unstaged and tell me what changed — assume I'll commit it myself.
- **If you're curious about what was done** — earlier in this session, in a prior session, or by me between sessions — **read the git history** (`git log`, `git show`, `git diff`) rather than asking or assuming. The working tree lives on a host bind mount, so my out-of-container commits show up there; the history is the source of truth for "what happened."

## Task documents

For non-trivial work — multi-step features, refactors, investigations, anything worth resuming in a later session — keep a spec/notes doc at `tasks/<short-kebab-slug>.md` in the **repo root** of whichever project is currently mounted. One file per task. Update it as work progresses (status, decisions, open questions).

When a task is complete, **move** the file to `tasks/archive/<YYYY>/<MM>/<DD>/<slug>.md` (zero-padded, based on the archive date) rather than deleting it. The date-bucketed layout keeps any one directory from accumulating too many entries. The history is useful.

Older flat archives (`tasks/archive/<slug>.md`) from before this convention are not migrated automatically; the `/archive-task` command will detect them on each run and offer to port them into the date hierarchy using the file's last-touched date from git history.

At the start of a session in a project, check `tasks/` (top-level, **not** `tasks/archive/`) for in-flight work and surface what's there so we can pick up where we left off. Don't trawl `tasks/archive/` unless I ask about prior work.

Don't create a task file for one-off questions, trivial edits, or anything resolvable in a single response. Task files are for work that spans turns or sessions.

If `tasks/` doesn't exist in a repo yet, create it the first time it's needed. By default these docs are committable — only add `tasks/` to `.gitignore` if I explicitly ask.

Helper commands: `/new-task <slug>` to scaffold, `/archive-task <slug>` to archive.

## Repo audits

For getting (re)acquainted with a project, or checking whether its docs still match its code:

- `/audit-repo` — full read of the current repo, cross-referencing the docs (CLAUDE.md, README, task docs) against the actual source to surface stale claims, undocumented features, and internal inconsistencies. **Read-only** — it reports findings and stops.
- `/findings-to-tasks` — turn those findings (or any list of discussion items) into in-depth task docs under `tasks/`, one per item, each `proposed — needs go-ahead`.

## Open-issues sections in project docs

When a project's `CLAUDE.md` or `README` keeps an "open issues" / "known issues" list, it should contain only **genuinely open** items. When an issue is resolved, **remove it** — don't leave it struck-through or annotated "resolved/fixed". A new developer reading an open-issues list shouldn't have to wade through things that are no longer issues; the resolution history already lives in git and in archived task docs, not in the live list. (This applies specifically to *open-issues* lists; a curated changelog or "resolved" section that exists on purpose is fine.)

## Multi-repo sessions

This container often has more than one repo bind-mounted at top-level paths like `/foo`, `/bar`. Claude Code only auto-loads the `CLAUDE.md` of the current working directory's repo, so to be aware of the others:

At session start, scan top-level directories at `/`. A directory is a project mount if it contains either `.git/` or `CLAUDE.md`. Skip these system paths: `/bin`, `/boot`, `/dev`, `/etc`, `/home`, `/lib`, `/lib64`, `/media`, `/mnt`, `/opt`, `/proc`, `/root`, `/run`, `/sbin`, `/srv`, `/sys`, `/tmp`, `/usr`, `/var`.

For each mount found, read its `CLAUDE.md` if present and apply those rules when working in that repo. Also check each for in-flight items under `tasks/` (per the convention above). Don't announce the scan unless I ask — just internalize each repo's conventions so you behave correctly when I reference paths in any of them.

If a `CLAUDE.md` in one repo contradicts the rules here or in another mounted repo, the repo-local file wins **for work inside that repo only**.

## My project layout (the container-per-project template)

Almost all my projects follow one template: a **Fedora-44 + Podman, ephemeral-container dev environment**, driven by a `Makefile` whose targets each `podman run --rm` the project's image and hand it a script from `entrypoint/`. Use this as a **conformance reference**: when I mount a new project (often via `EXTRA_MOUNTS`), compare it against the tiers below and tell me where it diverges — a deliberate variation is fine, an *accidental* drift (stale copy-paste, wrong path, missing target) is what I want flagged. The tiers are **invariant** (true of every project), **common** (most), and **variant** (legitimately differs).

### Directory layout

```
<project>/
├── Dockerfile              # invariant
├── Makefile                # invariant (rare exception: a Dockerfile-only project)
├── entrypoint/             # invariant
│   ├── shell.sh            #   invariant — cd into the project dir, exec bash
│   ├── format.sh           #   common   — clang-format (C/C++) or ruff (Python)
│   ├── entrypoint.sh       #   common   — the image's ENTRYPOINT target
│   ├── <task>.sh           #   variant  — lint.sh, html/pdf/epub.sh, buildDebug.sh, jupyter.sh, …
│   └── dotfiles/           #   optional — .extrabashrc, .emacs.d/, .tmux.conf, .lldbinit
├── .clang-format / .clang-tidy   # C/C++ projects
├── requirements.txt              # Python projects
├── output/                       # docs/book projects — bind target for built artifacts
└── tasks/                        # the task-doc convention above
```

### Makefile contract

- **Header (invariant):** `.DEFAULT_GOAL := shell` (or `help`); `CONTAINER_CMD = podman`; `CONTAINER_NAME = <project>`.
- **`FILES_TO_MOUNT`** aggregates `-v $(shell pwd):/<name>/:Z`, the entrypoint-script mounts, and conditional host-config mounts built with the `readlink -f` + `if [ -f … ]` idiom (`TMUX_MOUNT`, sometimes `GITCONFIG_MOUNT` / `GNUPG_MOUNT`).
- **Targets:** `all` → `image` → `shell`, plus `format`, optional `docs`/`html`/`pdf`/`epub`, and a `help` target using the standard `grep --extended-regexp '^[a-zA-Z0-9_-]+:.*?## .*$$' … awk '{printf "\033[36m%-30s\033[0m %s\n", …}'` one-liner. Every real target carries a `## description` for that help output.
- **`run`-style targets** all share the shape `podman run -it --rm --entrypoint /bin/bash $(FILES_TO_MOUNT) … $(CONTAINER_NAME) /usr/local/bin/<script>.sh` — one image, many entrypoint scripts.
- **`image-export` / `image-import`** (standard pair, being rolled out across projects): archive a built image to a tar and reload it without rebuilding — `image-export` does `$(CONTAINER_CMD) save $(CONTAINER_NAME) -o $(CONTAINER_NAME)-$(shell date +%m-%d-%Y_%H-%M-%S).tar` (timestamped tar in the repo root), `image-import` does `$(CONTAINER_CMD) load -i $(FILE)` (call as `make image-import FILE=foo.tar`). Both `.PHONY`, both `## `-documented. Use `$(CONTAINER_CMD)`/`$(CONTAINER_NAME)`, not hardcoded `podman`. **Gitignore the artifacts** (`$(CONTAINER_NAME)-*.tar` or `*.tar`) — they're large and must never be committed. `save`/`load` start no container, so they need no `--cgroups=disabled` and run fine nested. As of 2026-06-13 only `modelviewprojection` had this pair (its copy hardcodes `podman`, lacks `.PHONY`, and doesn't gitignore the tar — the rollout fixes all three); task docs to add it exist in `geometricalgebra`, `spimulator`, `texExpToPng`.
- **Feature flags** are passed as `--build-arg` (`BUILD_DOCS`, `USE_EMACS`, `USE_GRAPHICS`, `USE_JUPYTER`/`SPYDER`/`IMGUI`/`X_WINDOWS`, `BUILD_TREE_SITTER`) and **default to `1` in the Makefile**.
- **GUI:** an `USE_X` / X11 block and a `WAYLAND_FLAGS_FOR_CONTAINER` block for display passthrough. Every bind mount uses **`:Z`** (`U,z` only where ownership matters, e.g. the emacs `elpa` mount).

### Dockerfile contract

- **Invariant:** `FROM registry.fedoraproject.org/fedora:44`, then the dnf-cache idiom — `RUN --mount=type=cache,target=/var/cache/libdnf5 --mount=type=cache,target=/var/lib/dnf`, `keepcache=True` appended to `dnf.conf`, `dnf upgrade -y`, then `dnf install`.
- **`ARG` feature flags default to `0`** — the mirror of the Makefile's `1`, so a bare `podman build` is lean and `make` opts features in.
- COPY the entrypoint scripts to `/usr/local/bin` (or the whole `entrypoint/dotfiles/` to `/root/`); `echo "source ~/.extrabashrc" >> ~/.bashrc`.
- **Variant:** `ENTRYPOINT ["/entrypoint.sh"]` *or* no entrypoint at all (then every Makefile target supplies `--entrypoint /bin/bash`). Some images build + test the project at image-build time and gate the build on tests (`ctest`, `meson test`).

### entrypoint contract

- **`shell.sh`** — cd into the project dir and `exec bash`. Python projects first install themselves editable: `uv pip install --no-deps --no-index --no-build-isolation -e .`.
- **`format.sh`** — clang-format over `*.{c,cpp,h,hpp}`, or `ruff check --fix` + `ruff format --line-length=80`.
- **Docs/book projects** — build HTML/PDF/EPUB and copy artifacts into a bind-mounted `/output/<proj>/`, with `touch /output/<proj>/.nojekyll` for GitHub Pages.
- **C/C++ projects** — an `exit()` trap in `~/.bashrc` that runs `format.sh` (and `lint.sh`) on shell exit.

### Two families

- **Toolchain / source** (e.g. apue, spimulator, texExpToPng, gltron): a meson or cmake build, often performed at image-build time with tests gating the image.
- **Book / docs** (e.g. programmingFromTheGroundUp, hanoi, modelviewprojection): a Sphinx pipeline → html/pdf/epub, artifacts to `/output`, heavy `BUILD_DOCS` TeX Live install.

### Quick conformance check for a new project

`Dockerfile` + `Makefile` + `entrypoint/shell.sh` present? Fedora-44 base with the dnf-cache idiom? `CONTAINER_NAME` matches the dir? `FILES_TO_MOUNT` mounts the repo at `/<name>/:Z`? `help` target with `##`-documented targets? Build-arg defaults `1` (Makefile) / `0` (Dockerfile)? Entrypoint scripts and the image's `ENTRYPOINT`/`--entrypoint` story consistent? Each `entrypoint/*.sh` references the *right* project's paths (a frequent copy-paste drift) — flag any that point at another project.

## Running projects in a nested container

I run inside a Podman sandbox (the `runClaudeInContainer` / `claudecontainer` image). Most of my projects build and run *themselves* in a container — usually via a `Makefile` target (`make run`, `make shell`, `make test`, `make image`) wrapping a `podman run` / `docker run`. I can run those **nested** inside this sandbox, but there are two things to get right. Don't assume a project's container command works as-is; apply these.

**1. The sandbox must have been launched with nested support.** Nested podman only works if `make shell NESTED_PODMAN=1` was used to start this sandbox. Check before trying:

```sh
test -e /dev/fuse && podman info >/dev/null 2>&1 && echo "nested OK" || echo "no nested — relaunch with NESTED_PODMAN=1"
```

`/dev/fuse` is the tell: absent ⇒ plain `make shell`, nested won't work. If it's not available, tell the user to relaunch the sandbox from the `runClaudeInContainer` repo with **`make shell NESTED_PODMAN=1`** — I can't add those flags from inside an already-running container.

**2. Every inner `podman run` / `docker run` needs `--cgroups=disabled`.** The sandbox's `/sys/fs/cgroup` is read-only, so without it *every* inner run dies with `/sys/fs/cgroup/cgroup.subtree_control: Read-only file system`. A project's Makefile won't have this flag, so its container target will fail until it's added. Running their containers nested is the whole point of the setup, but **don't silently edit a project's Makefile / run script — explain that the container target needs `--cgroups=disabled` to work nested, propose how I'd add it (a Makefile variable if one already threads extra flags through, otherwise the flag inline), and wait for the go-ahead** before changing it. A one-off run I can do directly by appending the flag to the `podman run` on the command line; persistent edits to their build files need a yes first.

**Standing arrangement (Bill, 2026-06-08):** for the *specific* case of adding `--cgroups=disabled` so a containerized `make` target (`make dist` / `test` / `image`) runs nested, I'm **pre-authorized to add it as a transient edit and revert it in the same turn** — add the flag to the relevant `podman run`, run the target, then restore the Makefile so the committed version is never left changed. No need to ask each time. On subsequent runs I just repeat the add-run-revert cycle. I always revert in the same turn I add it; if I can't finish a run I still restore before ending, and I call out explicitly whenever I touch the Makefile so an interrupted run shows up as an obvious uncommitted diff rather than a surprise. (This covers *only* the `--cgroups=disabled` nested-podman flag; substantive or persistent build-file changes still need a yes first.)

**Standing arrangement — temporary build-file additions (Bill, 2026-06-09):** generalizing the above beyond the cgroups flag. When a task genuinely needs a tool or dependency that the project's image/build doesn't ship — a sanitizer runtime (`libasan`), a debugger, a profiler, an extra dev package, a one-off build flag — I'm **pre-authorized to add it to the `Dockerfile` / build files (and rebuild the image) without asking each time, *as long as it's temporary*.** The contract: by the time the task is **done**, I've removed those additions so the committed build files are back to only what the project actually ships. While the task is in flight the addition can stay (image rebuilds are expensive, so I don't add-and-revert every turn the way I do for the cgroups flag) — but I **track what I added** so cleanup isn't forgotten: a note in the task doc *and* a comment in the Dockerfile marking the line dev-only / to-be-removed, and I call it out when I add it. **Exception — keep, don't remove:** anything whose only purpose is making *nested* podman runs work (the `--cgroups=disabled` flag, a `PODMAN_RUN_FLAGS`-style passthrough variable threaded through a Makefile, etc.) is fine to leave in permanently — it's harmless to a normal host build and saves re-adding it each session. What still needs a yes: a **permanent** change to what the image ships (a real runtime dependency the project should carry going forward), as opposed to a temporary dev/debug aid.

**Other specifics:**
- **Networking just works** — default bridged/netavark networking is verified (an inner `apt update` / package pull reaches the network). No `--network` flag needed. If a run ever dies on `netavark: set sysctl ... Read-only file system`, `--network=host` is a working fallback.
- **Bind mounts use `:Z`** (SELinux relabel), e.g. `-v "$(pwd)":/workspace:Z`, matching this repo's convention.
- **Inner image store is ephemeral** (tmpfs) — pulled/built images don't survive the session; expect re-pulls.
- **Storage is fuse-overlayfs**; `podman info --format '{{.Store.GraphDriverName}}'` reports `overlay` driven by it.
- The host Podman stays **rootless** — nested runs never gain privilege on the real host. Full rationale lives in the `runClaudeInContainer` repo's `CLAUDE.md` / `README.md` and `tasks/archive/.../nested-podman.md`.
