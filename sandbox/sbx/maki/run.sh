#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)

state="${XDG_STATE_HOME:-$HOME/.local/state}/maki"
mkdir -p "$state"

case "$PWD" in
  "$REPO"|"$REPO"/*) paths=("$HOME/git" "$state") ;;
  *) paths=("$HOME/git" "$REPO/AGENTS.md:ro" "$REPO/skills:ro" "$state") ;;
esac

name="maki-$(basename "$PWD")"
env_args=(-e DOTAGENTS_REPO="$REPO" -e XDG_STATE_HOME="${state%/maki}")
mem_args=(-m "${MAKI_SBX_MEMORY:-4g}")

stamp="$state/maki-update-check"
check_maki_update() {
  local current latest
  if [ -n "$(find "$stamp" -mmin -1440 2>/dev/null)" ]; then
    return 0
  fi
  touch "$stamp"
  current=$(sbx exec "$name" -- maki --version 2>/dev/null | awk '{print $2}') || return 0
  [ -n "$current" ] || return 0
  latest=$(curl -fsSL https://api.github.com/repos/tontinton/maki/releases/latest \
    | jq -r '.tag_name' 2>/dev/null) || return 0
  [ -n "$latest" ] && [ "$latest" != "null" ] || return 0
  [ "${latest#v}" != "${current#v}" ] || return 0

  local answer=""
  if [ -r /dev/tty ]; then
    read -r -p "[sbx] maki $current -> $latest in $name. Update? [y/N] " answer </dev/tty || answer=""
  fi
  case "$answer" in
    y|Y|yes|YES) ;;
    *) return 0 ;;
  esac

  local out
  if out=$(sbx exec "$name" -- bash -c 'curl -fsSL https://maki.sh/install.sh | env -u GH_TOKEN -u GITHUB_TOKEN MAKI_INSTALL_DIR="$HOME/.local/bin" sh' 2>&1); then
    echo "[sbx] maki updated to $latest in $name"
  else
    echo "[sbx] maki update failed:" >&2
    printf '%s\n' "$out" >&2
  fi
}

if sbx ls | awk -v n="$name" '$1 == n { found = 1 } END { exit !found }'; then
  check_maki_update
  exec sbx run "${env_args[@]}" --name "$name"
fi

exec sbx run "${env_args[@]}" "${mem_args[@]}" "$HERE" "${paths[@]}"
