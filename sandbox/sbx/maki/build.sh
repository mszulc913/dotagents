#!/usr/bin/env bash
# Rebuild the maki sandbox template and load it into the sbx runtime.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tmp=$(mktemp /tmp/maki-sbx.XXXXXX.tar)
trap 'rm -f "$tmp"' EXIT

docker build -t maki-sbx:latest "$HERE"
docker image save maki-sbx:latest -o "$tmp"
sbx template load "$tmp"
