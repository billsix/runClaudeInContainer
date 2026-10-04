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

## Bulk find → log → iterate → fix (a discovery command, a worklog, then edits)

When a task is *find every instance of X across the tree, then fix each*, lead with a **shell
discovery command**, not a Python file-walk — one `rg` call returns just the matches, so a local
model (small context window) is not reading every file front-to-back to decide what to fix next. The
shape is four phases; the ad-hoc-script rules apply (`~/.claude/reference/task-doc-conventions.md`,
"Bulk operations"): save the discovery command as `tasks/adhoc/<slug>/discover.sh` and its output as
a committed *snapshot* worklog under `tasks/adhoc/<slug>/data/`.

**1. Discover (machine-readable).** Prefer `rg` (fast; skips binaries and `.gitignore`; present in
this image):
- `rg -n --column 'PAT' src/` → `file:line:col:text`. Use `rg --vimgrep 'PAT' src/` when you need
  exactly one row per match (multi-match lines otherwise collapse). `rg -l 'PAT'` = filenames only;
  `rg --json 'PAT'` = structured (per-match `line_number`, byte `start`/`end`).
- `git grep -n 'PAT' -- '*.py'` when the scope is *every tracked file* (respects the git index — no
  `.gitignore` blind spot, which rg has for a tracked-but-ignored file).
- Filenames with spaces/newlines: NUL-delimit — `rg -0 -l 'PAT'`, `grep -rlZ 'PAT' . | xargs -0 …`,
  `find . -name '*.py' -print0 | xargs -0 …`.
- A *reusable* script (rg not guaranteed on other machines) guards:
  `command -v rg >/dev/null 2>&1 || { …grep -R fallback… }`.

**2. Log** the matches to `tasks/adhoc/<slug>/data/matches.txt` — the audit record and the worklist,
**not** a replay driver; treat its line numbers as a snapshot (see phase 3).

**3. Iterate & fix — never trust the saved line numbers.** They rot the instant an edit shifts a
line, so:
- **Preferred — match by content, re-derived live**: `sed -i 's/exact_old/new/' f`, or context-scoped
  `sed -i '/anchor/s/old/new/' f`. No saved offset to go stale, and re-running is naturally a no-op.
- **When you must use offsets** (match text alone is ambiguous) or the edit changes a file's line
  count, process each file **bottom-up** so earlier edits don't shift the not-yet-applied lines:
  `grep -n 'PAT' f | sort -t: -k1,1 -rn | while IFS=: read -r n _; do sed -i "${n}s/old/new/" f; done`
  (`tac` is the base primitive).
- **In-place tools**: `sed -i` (GNU here — BSD needs `-i ''`; moot on these Linux boxes, noted for
  copy-paste into mixed environments). Multi-line / lookaround → `perl -0777 -pi -e 's/old/new/gs' f`
  (slurps the file so `.` spans newlines). Field/column edits → `gawk -i inplace '{…}' f`.
- **Greedy trap**: `sed`/ERE have no `.*?`; use a negated class `[^>]*` (not `.*`) to stop at the
  first delimiter, or you silently eat to the last one.
- **Idempotent when it's cheap** (welcome, not required): anchor to a field that stops matching once
  fixed (`sed -i 's/^\(version:\).*/\1 2/' f`); guard with `grep -q 'PAT' f && sed -i …` so a
  no-longer-present pattern fails loud, not silently; beware `s/foo/foobar/g` re-matching on re-run.

**4. Iterate the worklist safely, and verify.**
- Read loop: `while IFS= read -r line; do …; done < matches.txt` — `IFS=` keeps leading whitespace,
  `-r` keeps backslashes, and **redirect from the file** (not `cat … | while`), or a counter set
  inside the loop vanishes in the pipeline subshell; use `< <(cmd)` to consume a command instead. Add
  `|| [ -n "$line" ]` to also catch a final unterminated line. Resumable: move done rows into
  `matches.done.txt`, compute remaining with `grep -vFf matches.done.txt matches.txt`.
- **Verify by re-discovery**: the phase-1 command must now report zero matches — `rg -l 'PAT' src/`
  empty = clean; or `rg -c 'PAT' src/` before/after + `diff` to catch a partial fix. `git diff -U0`
  reviews many one-line changes tightly and makes a greedy over-match visually obvious.

**Gotchas**: `grep -r` prints "Binary file … matches" — use `grep -I` to skip binaries (rg does by
default); prefer plain `find` over `find -L` for a source sweep (`-L` follows symlinks and is slow /
loops on symlink farms); `LC_ALL=C` makes grep/sed byte-wise (faster and safe on pure-ASCII source,
but *wrong* for a Unicode-sensitive substitution — `.` then matches a byte, not a character); and
never edit a file you are reading in the same pipeline (`grep … f | sed -i … f`) — the two-phase
discover-to-file-then-edit shape above exists to avoid exactly that. (Idioms verified against the
tool docs, 2026-09-18.)


## `pkill -f <pattern>` inside `bash -c '…'` kills the invoking shell (2026-10-04)

`bash -c 'pkill -9 -f "podman run …"; <more commands>'` matched its *own* command line (which contains the
pattern) and killed itself before `<more commands>` ran — the tool reported exit 1 with no output and the
rest of the batch silently never happened. Kill by PID (`ps -eo pid,args | grep …` first), or put the
pattern in a variable the shell's own argv does not contain, and never chain cleanup-then-work in the
same `bash -c` string as a `pkill -f`. A background `podman build` also ignores plain `kill`; use `kill -9`
and re-check `ps`.
