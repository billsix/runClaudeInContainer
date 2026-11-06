# Fan-out: helpful preflight guards on feature-flag-gated make targets (DONE 2026-11-06)

Done-record. Added a preflight guard to each Tier-1 run target whose tool is only in the image when
a build-time feature flag was on — so instead of a cryptic `command not found`, the target prints
the capability, the flag, and the rebuild command, then `exit 2`. Pattern + the autoconf comparison:
`tasks/reference/makefile-feature-flag-guards.md`.

## What was done

Mechanism decision (maintainer, 2026-11-06, via AskUserQuestion): **flag-echo** guard
(`@[ "$(FLAG)" = 1 ] || { … exit 2; }`), **Tier 1 only**. This is correct for these targets because
each has an `: image` (phony) prerequisite, so `make <target>` rebuilds the image to the current
flags first — the make variable honestly reflects what the image will contain.

Message format (updated 2026-11-06 at the maintainer's request): walk the user through
`echo 'export FLAG=1' >> ~/.bashrc && source ~/.bashrc` → `make image` → `make <target>`. An
exported env var overrides a `?=` default in GNU Make — verified, even the `$(if MINIMAL_IMAGE…)`
form — so `make image` then builds the feature in; `make image FLAG=1` is the one-shot equivalent.
The maintainer's original `make spyder` example was right to use an export; it only omitted the
`make image` rebuild before re-running.

Implemented (one guard per gated target):

- **geometricalgebra** — `jupyter` (`USE_JUPYTER`), `docs` (`BUILD_DOCS` **and** `USE_EPIX` in one
  combined guard so both get set at once — docs.sh renders ePiX figures), `lean` (`USE_LEAN`).
- **spimulator** — `html`/`pdf`/`epub` (`BUILD_DOCS`; plain `?= 1` here, so no `MINIMAL_IMAGE`
  mention). `docs` just depends on the three, so it is covered.
- **hanoi** — `docs` (`BUILD_DOCS`).

Verified: all three Makefiles parse clean (`make -n docs BUILD_DOCS=1`), and the guard shell fires
with the right message + `exit 2` when the flag is 0.

## What was NOT done, and why

- **epix-mirror — left untouched (already compliant, better).** Its `examples`/`examples-anim`/
  `jupyter`/`notebooks` entrypoint scripts already guard with a **runtime capability probe**
  (`command -v latex|jupyter|jupytext`) + the flag-named rebuild message + `exit 2`. That is the
  right mechanism there because those targets run against a pre-built image without an `: image`
  rebuild, so a flag-echo could not reflect reality. epix-mirror is the existing model that informed
  the reference doc. A make-level flag-echo was briefly added and reverted as redundant.
- **Tier 2 (graphics `run`/`shell` targets: smc, Craft, gltron, `USE_GRAPHICS`)** — excluded per the
  maintainer's choice. No single sentinel binary; `USE_GRAPHICS` is default-on; lower value.
- **multivariate-math, duckgamevst, apue, texExpToPng, smalltalk, graphicalcontainer** — no gated
  target (tools always installed, or only `USE_EMACS` with no editor target).

## Durable artifacts

- Pattern + two mechanisms + the autoconf/automake comparison → `tasks/reference/makefile-feature-flag-guards.md`.
- Makefile contract rule added to the personal overlay (`ai-coding-conventions.personal.md`,
  Feature-flags section), pointing at the reference doc.
