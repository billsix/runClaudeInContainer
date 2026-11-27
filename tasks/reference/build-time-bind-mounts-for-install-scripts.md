# Build-time bind mounts for install scripts (`RUN --mount=type=bind` instead of `COPY`)

**Reference document.** What is known about supplying a build-only script to the one `RUN` that
needs it with a bind mount, instead of copying it into the image first. Measured 2026-11-26 with
podman 6.2.0 / buildah 1.46.1 nested in the sandbox (William Emerison Six <billsix@gmail.com>). The
research task is `tasks/archive/2026/11/27/install-scripts-bind-mount-at-build-instead-of-copy.md`.

## Verdict

**The `COPY` is not required: build-only scripts are bind-mounted.** A per-script bind mount does
everything the `COPY` did for a build-only script and leaves nothing behind in the image. It works
nested in the sandbox and on the SELinux-enforcing host with no relabel option. The Dockerfile
contract (github.com/billsix/dotfiles `.ai-coding-conventions.personal.template.md`, "Dockerfile
contract") states the rule; this repo's `Dockerfile`, github.com/billsix/runCrushInContainer
`client/Dockerfile` and github.com/billsix/geometricalgebra `Dockerfile` are converted; each other
project has a `tasks/install-scripts-bind-mount-at-build.md`.

**Docker builds the same form.** Some projects build their Dockerfile with Docker in GitHub Actions
(geometricalgebra's `checks.yml` and `lean.yml`). Measured on the maintainer's host with Docker
29.9.3, SELinux enforcing: the plain mount builds, an unchanged script reuses its layer, and an edited
script re-runs it. Docker **rejects** `z` and `Z` on the mount (`invalid field 'z' must be a
key=value pair`), which is why the contract forbids a relabel option.

## The shape

```dockerfile
RUN --mount=type=bind,source=entrypoint/01-install-base.sh,target=/usr/local/bin/01-install-base.sh \
    --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    /usr/local/bin/01-install-base.sh
```

- **One mount per script, on the `RUN` that invokes it.** `source` is relative to the build context.
- **Keep the target path the script had under `COPY`**, so the `RUN` body does not change.
- The mount is read-only by default, which is what an install script needs.

## What was measured (podman 6.2.0)

Throwaway two-script Dockerfile, then a full build of geometricalgebra.

| Question | Result |
| --- | --- |
| Edit the mounted script: does its `RUN` re-run? | Yes. The mounted file's content is part of the layer's cache key. |
| Edit script B: does script A's layer re-run? | No, with one mount per script. |
| Mount the whole `entrypoint/` directory into each `RUN`, edit script B | Script A's layer re-runs too. A directory mount keys every such layer on every file in it, so mount single files. |
| `touch` the script (modification time only) | Cache hit. |
| `chmod` the script (mode only) | Cache miss: the mode is part of the key. |
| Script is mode 644, invoked by path | Fails, `Permission denied`: a mount keeps the host mode (`COPY` does too). Committed install scripts stay executable; `bash <script>` also works. |
| Is the script left in the image? | No. `/usr/local/bin` holds no install scripts afterwards. |
| `.dockerignore` excludes `entrypoint/` | The mount still works. A `COPY` of the same file fails (`filtered out using .dockerignore`). So a context that excludes `entrypoint/` no longer needs `!` re-includes for mounted scripts. |
| Write through an `rw` mount | Succeeds inside the `RUN`, does not reach the host context. |
| `z`, `Z`, `relabel=shared`, `relabel=private`, `ro`, `rw` on the mount | All accepted by podman. |
| Mount with no `source` | Mounts the whole build context at the target. |

**Full-project trial, github.com/billsix/geometricalgebra.** Its 5 `COPY` instructions for 12 install
scripts became 12 mounts on 7 `RUN` instructions (conversion script:
`tools/convert_install_copy_to_bind_mount.py`). A
default-flag `make image` built all 31 steps nested in 16 minutes, with Lean, ePiX and texExpToPng
installed; the image has 7 `COPY` layers where the previous one had 12. `make test` against that image: 1412 passed, 3 skipped.

**The two sandbox images.** This repo's `Dockerfile` (3 scripts) and github.com/billsix/runCrushInContainer `client/Dockerfile` (6 scripts) were converted with the same tool and built nested with default flags: 42 and 18 minutes, both exit 0, `make format` green against each, and neither image holds an install script in `/usr/local/bin`.

## SELinux — a plain mount passes on an enforcing host

The worry: every project Makefile mounts its repo with `:Z`, so after `make shell` or `make test`
the repo's files carry one container's private MCS categories (geometricalgebra's install scripts
were `container_file_t:s0:c273,c749` when surveyed), and a `RUN` step is a confined process with
different categories. imps `n64/SuperMario64/Dockerfile` records a denial of exactly this kind as its
reason for using `COPY` (in the comment above `COPY libultraship/requirements.txt`).

**Measured on the maintainer's host, 2026-11-26 (podman 6.2.0, `getenforce` = Enforcing):** a context
directory was relabelled by a `podman run -v …:Z`, giving its script `container_file_t:s0:c563,c592`,
and then built five ways. All five passed:

The same script was then run with Docker 29.9.3 on that host (as root; the context got
`container_file_t:s0:c704,c819`).

| Build | podman 6.2.0 | Docker 29.9.3 |
| --- | --- | --- |
| plain bind mount | PASS | PASS |
| bind mount with `,z` | PASS | FAIL: `invalid field 'z' must be a key=value pair` |
| bind mount with `,Z` | PASS | FAIL: `invalid field 'Z' must be a key=value pair` |
| plain bind mount, build with `--security-opt label=disable` | PASS | PASS |
| `COPY` then `RUN` | PASS | PASS |
| unchanged script reuses the layer | PASS (sandbox) | PASS |
| edited script re-runs the layer | PASS (sandbox) | PASS |

So no relabel option is needed, and none may be used: `z`/`Z` are podman-only (Containerfile(5)
lists them; Docker's Dockerfile reference lists only `target`, `source`, `from` and `rw` for a bind
mount, and Docker refuses the others). Under podman the mount options also left the file's on-disk
label as the `:Z` run had set it. Why the plain mount is readable was not investigated; podman builds through an overlay mounted
over the build context (visible in its error messages as `buildah-context-…/overlay/…/merge`), which
is the likely reason. The imps denial was not reproduced; its Dockerfile's context is an upstream
checkout on a different filesystem path, so re-test there before converting it.

The check is `tools/check_build_bind_mount.sh`
(`[HOST] bash check_build_bind_mount.sh`; pass `docker` as its argument to test Docker where installed).
Its context lives under `/tmp`; a real repo on the data disk is confirmed by a host `make image` of a
converted project.

## Which files are candidates

`tools/survey_dockerfile_copies.py` classifies every
copied file in the repos named on its command line (376 rows across the maintainer's repos on 2026-11-26).
It is a list of leads from a text match, to be read per project:

- **build-only (113 files, 24 repos):** a `RUN` names the copied path and nothing else in the repo
  does. Install and build scripts, plus build inputs such as `requirements.txt`, `constraints.txt`
  and `apt-deps.txt`. These are the candidates.
- **runtime (199) and directory copies (60):** dotfiles, baked source, `shell.sh`/`format.sh`
  fallbacks, entrypoints. They stay `COPY`.
- **build+runtime (4):** named by a `RUN` and by the Makefile or another script (Craft
  `buildDebug.sh`, smc `build.sh`, Programming3DComputerGraphics `jupyter.sh` and
  `requirements.txt`). They stay `COPY`.

A script whose path only appears inside a string the `RUN` writes (geometricalgebra echoes
`/usr/local/bin/jupyter.sh` into `~/.bash_history`) is a runtime file, not a candidate.

## What a switch would cost and buy

- **Buys:** one fewer layer per `COPY` instruction; no build-only scripts in the image; an edit to one
  script re-runs only the layers that mount it (a multi-script `COPY` re-runs everything below it);
  `.dockerignore` no longer needs re-includes for them.
- **Costs:** the scripts are no longer inside an exported image, so a bare-host install from them
  needs the repo (which the conventions already assume travels with the image); a longer `RUN`
  header; and whatever the SELinux answer requires.
