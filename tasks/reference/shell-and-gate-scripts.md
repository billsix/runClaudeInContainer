# Shell, gate, and format scripts — full rules, incidents, and code shapes

**Reference document** — the full detail, incidents, and required code shapes behind the
terse shell/gate/format-script rules in the cross-project `CLAUDE.md`: "A multi-step check
script must propagate every step's failure", "Rewriting a script's contents drops its
executable bit", "Write format/check scripts to run BOTH in the container AND on the host",
and "The Bash tool runs commands through the user's login shell (here: zsh)". Read on demand
when writing/reviewing a gate or format script, editing a committed script, or a Bash tool
command fails with zsh-flavoured errors. (Relocated verbatim from `CLAUDE.md`, 2026-09-14.)

## The Bash tool runs commands through the user's login shell (here: zsh) — wrap patterns in `bash -c`

**In this sandbox my Bash tool executes each command through the user's interactive
login shell, which is `zsh`, not `bash`** — a wrong assumption I keep making, then
watching commands fail with `zsh`-flavoured errors (`parse error near 'head'`,
`(eval):N: ...`, `zsh: no matches found: *.md`). The symptom set (Bill flagged it
2026-08-14: "why do you keep running zsh instead of bash?"):

- **Unquoted globs error instead of passing through.** `ls *.md` with no match is a
  hard `no matches found` error under zsh's default `nomatch`, where bash would pass
  the literal `*.md` on. Same for `grep [^a-z]` / `foo|bar` in an unquoted arg — zsh
  parses the `[...]`/`|` as glob/pipe syntax before the tool sees them.
- **`(eval):N:` and `parse error near '<word>'` in the output** are the tell that
  zsh, not bash, parsed the line — so a heredoc/process-substitution/`[[ ]]` construct
  written for bash tripped a zsh parsing difference.

**The fix — wrap any command that uses shell patterns, bashisms, or multi-line
constructs in `bash -c '…'`:**

```sh
bash -c 'grep -rnE "foo|bar" src --include="*.md" | head'
```

The single-quoted `bash -c` body is handed to bash verbatim, so globs, `[...]`,
`|`, `[[ ]]`, `for`/`done`, and heredocs all behave as written. **A bare, simple
command (`git status`, `ls`, a single tool with quoted args) is fine as-is** — reach
for `bash -c` specifically when the line contains a glob, a character class, a pipe
inside an argument, or bash-only syntax. (This is about the *interactive login shell
the tool wraps*, which is host-configurable; don't assume it's bash on any machine.)

## A multi-step check script must propagate every step's failure

**The design intent of `format.sh` (and any `make format` / `lint` / `check` target
that chains tools) is "run EVERY step, so one pass reports ALL the red" — deliberately
not fail-fast.** But a plain command sequence in a shell script exits with the **last
command's status alone**, so `make` reports green whenever the final step passes,
silently masking every earlier failure. This is not hypothetical; it has bitten twice:

- **mvp, 2026-07-09:** 79 `ty` diagnostics in `src/` hid for weeks behind a green
  format gate (the final `ty check` in the sequence happened to pass).
- **gacalc, 2026-07-29:** 3 `ty` errors were printed mid-output, then the last step
  (`ty check tools`) printed its own "All checks passed!" and `make format` exited 0 —
  the error report and the green verdict in the same scroll, and the gate was trusted
  over the scroll.

**The required shape — both properties at once** (every step still runs; any failure
fails the script):

```bash
status=0
ruff check . --fix       || status=1
ruff format              || status=1
ty check src             || status=1
ty check tests           || status=1
exit $status
```

(mvp's variant wraps this in a `run() { "$@" || status=1; }` helper — same thing.)

- **`set -e` is the WRONG fix** — it makes the script fail-*fast*, losing the
  report-everything property the multi-step design exists for. Accumulate, don't abort.
- **Loops need it per-iteration**: `for f in …; do clang-format -i "$f" || status=1;
  done` — a bare loop's exit is its last iteration's (this was gltron's flaw).
- **Safe by shape, no change needed:** a single-command script (its exit *is* the
  gate), and `find … -print0 | xargs -0 tool` (xargs exits 123 if any invocation
  failed — spimulator/texExpToPng's shape).
- **When writing or reviewing ANY gate script, check the exit-code story first:**
  "if step 1 fails and the last step passes, what does `make` see?" And don't trust a
  green gate over an error-bearing scroll — the 2026-07-29 case printed both.
- Audit of all mounted repos (2026-07-29): mvp was already correct; **gacalc, hanoi,
  multivariate-math, gltron fixed**; spimulator/texExpToPng safe by shape; the rest
  have no format script.

## Rewriting a script's contents drops its executable bit — restore it

`Write` (and any full-file rewrite) creates the file at mode 644, so **rewriting a committed
script silently strips its `+x`** — even a content-only pass like adding a license/SPDX header
or reflowing comments. A script **invoked directly** then fails at the point of use, not at edit
time: a Dockerfile `RUN /usr/local/bin/foo.sh`, a `./script.sh`, a Makefile recipe naming the
file by path — all die with `Permission denied`. Scripts invoked as `bash foo.sh` survive, which
is exactly why this is easy to miss: some callers keep working while the build-critical one
breaks, often several commits later.

- **After editing any script — especially a bulk header/format pass over several — check the
  modes and restore the bit in the same change.** `git diff --stat` shows a `mode change 100755
  => 100644` line; `git ls-files -s -- '*.sh'` prints each tracked mode. Restore with `chmod +x
  <paths> && git add --chmod=+x <paths>` (the `--chmod=+x` fixes git's mode even when the
  working-tree bit is already correct).
- **This bit me (runCrushInContainer, 2026-08-25):** an "add Apache SPDX headers" pass rewrote
  six entrypoint scripts `100755 → 100644`; the Dockerfile invokes two directly
  (`01-install-base.sh`, `02-install-vendor-tools.sh`), so the next `make image` failed with
  `Permission denied` — the header edit and the build break were four commits apart.

## Write format/check scripts to run BOTH in the container AND on the host from the repo root

**A `format.sh` (or `lint.sh` / any `make format` gate script) should be PORTABLE — runnable
inside the container *and* on the host from the repo root — so I can format without spinning a
container (Bill, 2026-08-14).** Exactly two things make a format script container-only; avoid
both:

1. **An unguarded `source /venv/bin/activate`.** On the host there is no `/venv`, so the bare
   `source` errors. **Guard it:** `[ -f /venv/bin/activate ] && source /venv/bin/activate` —
   activates the container venv when present, otherwise uses the caller's active env.
2. **Absolute container tool paths** (`ty check /<proj>/src`, `/venv/bin/...`) — they only
   resolve at the container mount path. **Use RELATIVE paths for every step** (`ruff check src`,
   `ty check src`, `ty check tests`) and let the CALLER `cd` to the repo root. Then the script
   runs identically from `cd /<proj> && format.sh` (in-container) and `cd <repo> && format.sh`
   (host). **Trap the mvp exit hook hit:** a per-subdir `cd /<proj>/src && format.sh` makes the
   script's own relative `ruff check src` resolve to `src/src` and fail — the shell-exit hook
   must be a SINGLE `cd /<proj>/ && format.sh` from the root, not one call per subdir.
3. **A hardcoded `cd /<proj>` INSIDE the script** — some scripts self-`cd` (needed in-container,
   e.g. a C/C++ `find . … | xargs clang-format` that must run from the repo root). **Guard it** so
   it no-ops on the host: `[ -d /<proj> ] && cd /<proj>` — replacing `cd /<proj> || exit 1` (which
   hard-*exits* on the host, dir absent) or a bare `cd /<proj>` (which silently runs in the WRONG
   directory on the host). In-container it `cd`s correctly; on the host it stays at the repo root
   you invoked from. This is the alternative to rule 2's "no `cd`, caller `cd`s": a portable script
   either has **no `cd`** (mvp/gacalc — the caller/exit-hook `cd`s) **or guards its `cd`** (the C/C++
   repos, whose `find .` needs the root).

The host run still needs the package importable in the caller's env for the type-checker step
(editable install + deps); a portable script does not *set that up*, it just does not hardcode
container paths that *fight* it. Worked example + the 2026-08-14 cross-repo sweep that applied all
three rules: mvp `entrypoint/format.sh` (guarded venv + all-relative `ty check` paths, was absolute
`/mvp/...`) and gltron were already portable; **gacalc** got rules 1+2 (guard venv, relative `ty
check src/tests/tools`); **hanoi / multivariate-math / spimulator / texExpToPng** got rule 3 (`[ -d
/<proj> ] && cd /<proj>`), and mvm also needed the venv guard. Pairs with the exit-status rule
above: a good gate script both propagates every step's failure AND runs anywhere from the root.
