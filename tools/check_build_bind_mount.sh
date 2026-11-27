#!/bin/bash
# [HOST] Does SELinux let a build-time bind mount read a script that an earlier
# `podman run -v …:Z` relabelled with a private category?
#
# Every project Makefile mounts its repo with `:Z`, so after `make shell` or
# `make test` the repo's files carry one container's private MCS categories. A
# `RUN --mount=type=bind` step reads the mounted file as a confined process with
# different categories; a COPY is read by the builder itself, unconfined. This
# script reproduces that in a throwaway directory and tries each way out.
#
# Run it on an SELinux-enforcing host (it is meaningless inside the sandbox,
# where SELinux is off). It touches nothing outside its own temp directory and
# removes the images it builds. Paste the whole output back.
#
# Usage: bash check_build_bind_mount.sh [container-command]    (default: podman)
# RUN_FLAGS adds flags to its `run` lines (the sandbox dry run needs --cgroups=disabled).

engine="${1:-podman}"
base=registry.fedoraproject.org/fedora:45
work="$(mktemp -d "${TMPDIR:-/tmp}/bind-mount-check.XXXXXX")"
trap 'rm -rf "$work"' EXIT

echo "engine: $("$engine" --version)"
echo "selinux: $(getenforce 2>/dev/null || echo unknown)"

if ! "$engine" info > /dev/null 2>&1; then
    echo "cannot talk to $engine (daemon not running, or this user may not use it; try sudo)" >&2
    exit 1
fi

mkdir -p "$work/entrypoint"
printf '#!/bin/bash\necho script-ran\n' > "$work/entrypoint/a.sh"
chmod +x "$work/entrypoint/a.sh"

# Give the context the label a project repo has after `make shell`.
# RUN_FLAGS is a flag list, so it is split on purpose.
# shellcheck disable=SC2086
relabel() { "$engine" run --rm $RUN_FLAGS -v "$work:/x:Z" "$base" true; }
relabel
echo "label after a :Z run: $(ls -Z "$work/entrypoint/a.sh")"

# try <label> <mount-suffix> [build flags...]
try() {
    local label="$1" suffix="$2"
    shift 2
    cat > "$work/Dockerfile" <<EOF
FROM $base
RUN --mount=type=bind,source=entrypoint/a.sh,target=/usr/local/bin/a.sh$suffix /usr/local/bin/a.sh
EOF
    if "$engine" build --no-cache "$@" -t bind-mount-check "$work" > "$work/log" 2>&1; then
        echo "PASS  $label"
    else
        echo "FAIL  $label"
        grep -i -E "denied|error" "$work/log" | head -3 | sed 's/^/        /'
    fi
    echo "        label now: $(ls -Z "$work/entrypoint/a.sh")"
}

try "plain bind mount" ""
relabel
try "bind mount with ,z (shared relabel)" ",z"
relabel
try "bind mount with ,Z (private relabel)" ",Z"
relabel
try "plain bind mount, build --security-opt label=disable" "" --security-opt label=disable
relabel

cat > "$work/Dockerfile" <<EOF
FROM $base
COPY entrypoint/a.sh /usr/local/bin/
RUN /usr/local/bin/a.sh
EOF
if "$engine" build --no-cache -t bind-mount-check "$work" > "$work/log" 2>&1; then
    echo "PASS  COPY then RUN (today's shape)"
else
    echo "FAIL  COPY then RUN (today's shape)"
fi

# Cache: is the mounted script's content part of the layer's cache key? The RUN
# records when it ran; a rebuild that reuses the layer keeps the old stamp.
cat > "$work/Dockerfile" <<EOF
FROM $base
RUN --mount=type=bind,source=entrypoint/a.sh,target=/usr/local/bin/a.sh /usr/local/bin/a.sh && date +%s%N > /stamp
EOF
stamp() {
    "$engine" build -t bind-mount-check "$work" > "$work/log" 2>&1 || { echo build-failed; return; }
    # shellcheck disable=SC2086
    "$engine" run --rm $RUN_FLAGS bind-mount-check cat /stamp
}
first="$(stamp)"
second="$(stamp)"
echo '# edited' >> "$work/entrypoint/a.sh"
third="$(stamp)"
if [ "$first" = build-failed ]; then
    echo "SKIP  cache check (the plain bind mount does not build)"
else
    [ "$first" = "$second" ] && echo "PASS  cache: unchanged script reuses the layer" ||
        echo "FAIL  cache: unchanged script re-ran the layer"
    [ "$second" != "$third" ] && echo "PASS  cache: edited script re-runs the layer" ||
        echo "FAIL  cache: edited script did NOT re-run the layer (stale image)"
fi

"$engine" rmi -f bind-mount-check > /dev/null 2>&1
exit 0
