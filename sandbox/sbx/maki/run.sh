#!/usr/bin/env bash
# The repo mount is read-only; the sandbox links its maki config from it.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)

case "$PWD" in
  "$REPO"|"$REPO"/*) paths=("$PWD") ;;
  *) paths=("$PWD" "$REPO/AGENTS.md:ro" "$REPO/skills:ro") ;;
esac

exec sbx run -e DOTAGENTS_REPO="$REPO" "$HERE" "${paths[@]}"