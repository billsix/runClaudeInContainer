# Research: must build-time install scripts be COPY'd into the image, or can they be bind-mounted during the build?

**Status:** proposed — needs go-ahead
**Priority:** 5
**Difficulty:** 4 (the research; a "yes, mount them" verdict spawns a fleet rollout that is larger)
**Created:** 2026-11-26 (William Emerison Six <billsix@gmail.com>)

**Touches:** this repo, github.com/billsix/runCrushInContainer, and the personal overlay template in
github.com/billsix/dotfiles; under verdict (2) also one new task doc in each affected project.

## BLUF

Every project's `Dockerfile` does `COPY entrypoint/0N-install-*.sh /usr/local/bin/` and then
`RUN /usr/local/bin/0N-install-*.sh`. This task decides, by experiment, whether that `COPY` is required
or whether the script can be supplied with `RUN --mount=type=bind` for the duration of the one `RUN`
that needs it (the build-time twin of how `shell.sh` is bind-mounted into `/usr/local/bin` at run time).
Done means one of two recorded verdicts: **(1) COPY is required**, with the measured reason written
into the Dockerfile contract so the question is not reopened; or **(2) the scripts can be mounted**, in
which case the contract and both sandbox repos are updated and one task per affected project exists.

## Context

Read first:

- **The contract.** The maintainer's personal overlay template, `.ai-coding-conventions.personal.template.md`
  in github.com/billsix/dotfiles (mounted into the sandbox next to the overlay). Sections:
  "Dockerfile contract" (the line "COPY the entrypoint scripts to `/usr/local/bin`"), "Host-agnostic
  setup belongs in a script the Dockerfile sources" (why the install scripts exist and what stays in
  the Dockerfile), "entrypoint contract" (`shell.sh` is bind-mounted, never baked), the `.dockerignore`
  bullet, and "Quick conformance check for a new project". The sandbox copy and the dotfiles copy were
  the same size but had different dates on 2026-11-26; diff them before editing and edit the canonical one.
- **The two sandbox repos.** This repo's `Dockerfile` (three script COPYs: `01-install-base.sh`,
  `01b-install-binary-tools.sh`, `install-lean.sh`) and `Makefile`; github.com/billsix/runCrushInContainer
  `client/Dockerfile` (`00-install-minimal.sh`, `01-install-base.sh`, `01b-install-binary-tools.sh`,
  `install-lean.sh`, `03-build-crush.sh`, `02-install-vendor-tools.sh`, plus `patches/` and
  `entrypoint/vendor/`). Related docs here: `tasks/reference/image-build-and-storage-pipeline.md`,
  `tasks/reference/shell-exec-and-container-template.md`, `tasks/reference/nested-run-and-gates.md`.
- **Related open task:** `tasks/standardize-project-container-template.md` (the same contract, other
  drift). A verdict here feeds its "Proposed standard".

Current state, surveyed 2026-11-26 (git-tracked `Dockerfile*`/`Containerfile*` under `/mnt/sda1`, 64
files; 52 have a `COPY` line naming `entrypoint` or `install`). The pattern also matches COPYs that are
not candidates (the `entrypoint/dotfiles/` tree, baked source), so each file needs reading:

| Repo (local directory) | Dockerfiles with such COPY lines |
| --- | --- |
| billsEmacsConfigs | 20 (one per language directory) |
| hanoi | 4 (root, `cpp/`, `python/`, `rust/`) |
| imps | 4 (`android/fossify`, `games/gzdoom/book`, `n64/SuperMario64/book`, `unixutils/ripgrep`) |
| impo | 2 (`openstax/tooling`, `study/notebooks`) |
| one each | CodeTheClassics, Craft, McNopperOpenGL, OpenGLSuperBibleV4Code, Programming3DComputerGraphics, apue, buildLineageOS, duckgamevst, epix-mirror, geometricalgebra, gltron, graphicalcontainer, methodfinder, multivariate-math, openglredbook9examples, runClaudeInContainer, runCrushInContainer (`client/`), sb7code, smalltalk, smc, spimulator, texExpToPng |

Skip upstream-only checkouts (no remote on a private-range host or `github.com/billsix/`): read them,
but create no task in them.

Two facts already in the tree that the research must account for:

- **A build-time bind mount is already in use.** github.com/billsix/Programming3DComputerGraphics
  `Dockerfile` mounts `constraints.txt` with `RUN --mount=type=bind,source=constraints.txt,target=/constraints.txt`.
  The three imps N64 Dockerfiles (`n64/MajorasMask`, `n64/OcarinaOfTime`, `n64/SuperMario64`) mention it too.
- **A recorded reason against it.** imps `n64/SuperMario64/Dockerfile`, in the comment above
  `COPY libultraship/requirements.txt`, says it uses COPY on purpose: the `RUN` process is confined
  (`container_t`) and reads a bind-mounted file with its on-disk SELinux label, so a checkout that the
  sandbox has relabelled with `:Z` categories is denied on a host-side `podman build`; `COPY` is read by
  buildah unconfined and works with any label. This is the strongest known candidate for verdict (1).
  It has not been re-measured here: reproduce it before relying on it, and test whether a relabel
  option on the mount (`z`, `relabel=shared`) or `--security-opt label=disable` on the build removes it.

## Goal

A measured answer, per class of build-only file, to "COPY or bind mount", and the follow-through that
answer implies.

## Plan

- [ ] **Classify every COPY** in the 64 Dockerfiles: (a) install/build script that runs once in a `RUN`
      and is never used again; (b) build-only input (`constraints.txt`, `patches/`, vendored tarballs);
      (c) file the running container uses (dotfiles, baked source, a fallback `shell.sh`, config);
      (d) script that looks build-only but is called later (by another script, by an entrypoint, or
      from a bare-host run of the image). Only (a) and (b) are candidates. Save the discovery command
      and its output under `tasks/adhoc/install-scripts-bind-mount-at-build-instead-of-copy/`.
- [ ] **Measure, with the sandbox's podman (6.2.0 on 2026-11-26), on a small throwaway Dockerfile:**
  - [ ] **Cache invalidation — the crux.** Build, edit the mounted script, build again: does the `RUN`
        re-run? If a mounted file's content is not part of the `RUN` layer's cache key, an edited
        install script silently yields a stale image, and that alone gives verdict (1). Also check the
        reverse: with one mount per script, an edit to script B must not re-run script A's layer (so
        mounting the whole `entrypoint/` directory into every `RUN` is the wrong shape).
  - [ ] **SELinux**, the imps case above: a host-side build of a checkout carrying sandbox `:Z` labels
        (needs the maintainer, `[HOST]`), and a nested build in the sandbox.
  - [ ] **`.dockerignore`:** is a mount source filtered by it, the way a COPY source is (gltron and
        towersofhanoi exclude `entrypoint/` and re-include named files)?
  - [ ] **Executable bit:** a mount keeps the host mode, so a 644 script needs `bash <script>`; pick one
        invocation form for the contract.
  - [ ] **Other builders:** which projects build in GitHub Actions or with Docker/BuildKit
        (`rg -l "docker build|buildx|podman build" -g "*.yml"` per repo), and does the same Dockerfile
        behave the same there?
  - [ ] **What the image loses:** the scripts are no longer in `/usr/local/bin` of the built image.
        Find anything that relies on them being there (an exported/airgap image, a `make` target, a doc).
  - [ ] **What is gained**, in numbers: layers removed per image, rebuild behaviour, size.
- [ ] **Write the verdict** into a reference doc in this repo (extend
      `tasks/reference/image-build-and-storage-pipeline.md`, or a new one if it outgrows that).
- [ ] **Verdict (1), COPY required:** add the measured reason to the contract's "Dockerfile contract"
      section and a one-line pointer in both sandbox repos' docs. No project tasks.
- [ ] **Verdict (2), mount them:** update the contract (the COPY line, the script section's "Keep in the
      Dockerfile" list, the conformance check), convert this repo's `Dockerfile` and
      runCrushInContainer's `client/Dockerfile` as the worked examples, run each one's image build and
      gate, then create `tasks/install-scripts-bind-mount-at-build.md` in every affected project
      (`proposed — needs go-ahead`, citing the reference doc and listing that project's COPY lines by
      class). A mixed verdict (mount class (a), keep COPY for (b), or the reverse) is allowed; state it
      per class.

## Notes / decisions

- The research and the rollout are separate go-aheads. Creating the per-project tasks is part of this
  task under verdict (2); executing them is not.
- Run-time delivery of `shell.sh` and `format.sh` (bind-mounted by the Makefile) is settled and out of
  scope; it is the model the question is drawn from.

## Open questions

None blocking. The plan treats build-only inputs (`constraints.txt`, `patches/`) as in scope alongside
the install scripts, reported per class.
