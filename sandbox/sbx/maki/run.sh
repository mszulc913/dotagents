#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)

state="${XDG_STATE_HOME:-$HOME/.local/state}/maki"
mkdir -p "$state"

case "$PWD" in
  "$REPO"|"$REPO"/*) paths=("$PWD" "$state") ;;
  *) paths=("$PWD" "$REPO/AGENTS.md:ro" "$REPO/skills:ro" "$state") ;;
esac

name="maki-$(basename "$PWD")"
env_args=(-e DOTAGENTS_REPO="$REPO" -e XDG_STATE_HOME="${state%/maki}")

if sbx ls | awk -v n="$name" '$1 == n { found = 1 } END { exit !found }'; then
  exec sbx run "${env_args[@]}" --name "$name"
fi

exec sbx run "${env_args[@]}" "$HERE" "${paths[@]}"
