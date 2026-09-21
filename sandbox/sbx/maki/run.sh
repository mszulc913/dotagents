#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)

case "$PWD" in
  "$REPO"|"$REPO"/*) paths=("$PWD") ;;
  *) paths=("$PWD" "$REPO/AGENTS.md:ro" "$REPO/skills:ro") ;;
esac

name="maki-$(basename "$PWD")"

launch() {
  exec sbx run -e DOTAGENTS_REPO="$REPO" "$HERE" "${paths[@]}"
}

output="$(launch 2>&1)" || status=$?

case "${status:-0}" in
  0) printf '%s\n' "$output" ;;
  1)
    if ! printf '%s' "$output" | grep -q "already exists and can't be given new workspaces"; then
      printf '%s\n' "$output" >&2
      exit 1
    fi
    printf '[sbx] %s has a stale mount set or spec; recreating it.\n' "$name" >&2
    sbx stop "$name" >/dev/null 2>&1 || true
    sbx rm --force "$name" || exit 1
    launch
    ;;
  *) printf '%s\n' "$output" >&2; exit "$status" ;;
esac