#!/usr/bin/env bash
# Cached layers never refresh the maki install; --no-cache is the only upgrade path.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

NO_CACHE=()
case "${1:-}" in
  --no-cache) NO_CACHE=(--no-cache) ;;
  "") ;;
  *) echo "usage: build.sh [--no-cache]" >&2; exit 2 ;;
esac

image_id() {
  docker image inspect -f '{{.Id}}' maki-sbx:latest 2>/dev/null || true
}

before=$(image_id)

tmp=$(mktemp /tmp/maki-sbx.XXXXXX.tar)
trap 'rm -f "$tmp"' EXIT

docker build "${NO_CACHE[@]}" -t maki-sbx:latest "$HERE"

if [ "$(image_id)" = "$before" ]; then
  echo "maki-sbx:latest unchanged; template reload skipped."
  exit 0
fi

docker image save maki-sbx:latest -o "$tmp"
sbx template load "$tmp"