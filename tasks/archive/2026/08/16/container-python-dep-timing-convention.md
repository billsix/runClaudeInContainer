# Convention: self-contained images + live source — build every dependency in at image-build, rebuild only the project's own source at runtime

**Status:** DONE 2026-08-16 — convention written to the **personal overlay**
(`~/.ai-coding-conventions.personal.md`, container-per-project template section, "Self-contained images + live
source"), plus a line in that spec's "Quick conformance check". Decisions (Bill, 2026-08-16): (1) lives
in the personal file, not the shared `CLAUDE.md` or a repo tool; (2) it's an **informational suggested
default**, not a gate; (3) **no conformance script** — instead the agent must **remind Bill when a
project deviates**. **Generalized beyond Python** (Bill's follow-up): the rule is **language-agnostic**
(pip/cargo/maven/gradle/go/npm/cabal/bundler/dnf), and its primary driver is that an **exported image
(`make image-export`) stays self-contained and offline years later** — every third-party dep fetched +
compiled into committed image layers (NOT a discarded `--mount=type=cache`), with only the project's own
source (re)built from the bind-mount at runtime so host edits propagate. No repo artifact beyond this
record (the convention is host-side, uncommitted). Created 2026-08-16 (William Emerison Six
<billsix@gmail.com>).
**Priority:** 3
**Difficulty:** 4

## The goal behind this (the maintainer's actual concern)

**When the code is edited *outside* the container (on the host), those changes must show up *inside*
the container without an image rebuild** (Bill, 2026-08-16). That is the property we are protecting.
The Python dependency-install timing is just the *mechanism* that makes it hold, and this task writes
that mechanism down as a convention and adds a check so no project silently breaks it.

## The design that already delivers it (two layers)

Verified across every containerized Python project in the stack (2026-08-16). Each splits its Python
setup into two layers, and the split is exactly what makes host edits propagate:

1. **Heavy third-party dependencies → installed at IMAGE-BUILD time**, in the `Dockerfile`, flag-gated
   (`BUILD_DOCS`, `USE_JUPYTER`, …). These don't change between runs, so baking them means a `make
   shell` / `make docs` never has to fetch anything. Examples: gacalc installs `numpy sympy pyright`,
   `sphinx furo nbsphinx myst-nb`, and `.[dev,notebooks,jupyter]` at build; multivariate-math installs
   `.[dev,notebooks,jupyter]`; hanoi installs `-r requirements.txt`.
2. **The project's OWN package → editable self-install at RUN time**, against the **bind-mounted**
   source: `uv pip install --no-deps --no-index --no-build-isolation -e .` in the entrypoint
   (`shell.sh` / `docs.sh` / `jupyter.sh`). `--no-index --no-deps` makes it **offline** (no network, no
   dependency resolution) — it only re-registers the project as *editable* so Python imports resolve to
   the **live, mounted host tree**. This is the line that propagates host edits: change a `.py` on the
   host, and the next `import` in the container sees it, no rebuild.

For gacalc there's a third runtime step for the same reason — it regenerates its **gitignored**
`g1/g2/g3` modules (`python tools/gen_specialized.py`) before the editable install, so those too track
the live source.

**Why the runtime editable install must NOT move to build time** (this was investigated and dropped):
a build-time *non-editable* install freezes a snapshot into `site-packages`, so host edits would be
ignored — the exact opposite of the goal. Even a build-time *editable* install is fragile here (its
package-discovery metadata is computed at install time, and the source it points at is replaced by the
bind-mount at runtime). The offline runtime `-e .` is the robust guarantee; keep it.

## Current state (snapshot from the 2026-08-16 research — all conformant)

Referenced by canonical repo, not container path (paths are sandbox-only):

| Project | deps at build? | runtime install |
|---|---|---|
| `github.com/billsix/geometricalgebra` | yes (numpy/sympy/pyright, sphinx set, `.[…]`) | offline `-e .` (+ regen) |
| `github.com/billsix/multivariate-math` | yes (`.[dev,notebooks,jupyter]`) | offline `-e .` |
| `github.com/billsix/towersofhanoi` (dir `hanoi`) | yes (`-r requirements.txt` + docs) | offline `-e .` |
| `github.com/billsix/spimulator` | yes (`BUILD_DOCS`-gated Sphinx) | none (C + book) |
| `github.com/billsix/modelviewprojection` | (not mounted this session — verify when it is) | — |

Not in scope: pure C projects (`tex-expression-to-png`, `gltron-mirror`) have no Python deps;
`methodfinder` has **no Dockerfile** (not containerized).

## What this task did (resolved 2026-08-16)

1. **Wrote the convention** into the personal overlay's container-per-project template section — the
   "Python dependency-install timing — deps at build, editable self-install at runtime" subsection,
   stating the invariant below and *why* (host-edit propagation), and adding a matching line to that
   spec's "Quick conformance check for a new project".
2. **No conformance script** (Bill's call): rather than a `tools/` check, the personal convention
   instructs the agent to **remind Bill when a project deviates** from the pattern. Informational, a
   default to prefer unless there's a reason otherwise — not a gate.

### The invariant the agent flags on deviation

For a containerized Python project:

- **(a)** third-party deps are installed in the `Dockerfile` (build time) — not in an entrypoint;
- **(b)** the repo source is **bind-mounted** at runtime (the `Makefile`'s `-v $(pwd):/<name>/:Z`);
- **(c)** the project installs **itself** at runtime as **editable** (`-e .`) with **`--no-index
  --no-deps`** (offline) — so host edits propagate and nothing is fetched;
- **(d)** **NO entrypoint runs a networked pip** (a `pip install` *without* `--no-index`, or that
  installs dependencies) — that would mean a run can hit PyPI, or that a dep was wrongly deferred to
  runtime. This is the actual regression the check exists to catch.

## Open questions — RESOLVED 2026-08-16

1. **Where does the written convention live?** → The **personal overlay** template section (not the
   shared `CLAUDE.md`, not a repo reference doc). Done.
2. **Gate or informational?** → **Informational** — a suggested default to prefer unless there's a
   reason otherwise. No failing `make` target.
3. **A conformance script / its scope?** → **No script.** Bill doesn't want a tool; he wants the agent
   to **remind him if he goes against the pattern on a project**. That reminder instruction is written
   into the personal convention itself.
