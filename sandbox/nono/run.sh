#!/usr/bin/env bash
# Landlock silently drops grants for paths that do not exist yet, so create them on the host first.
set -euo pipefail

agent="${0##*/}"
agent="${agent%-nono}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"

profile="$agent-nono"
gpu_args=()
if [ "${1:-}" = --gpu ]; then
  profile="$agent-nono-gpu"
  gpu_args=(--allow-gpu)
  shift
fi

case "$agent" in
  claude)
    mkdir -p "$HOME/.cache/claude" "$state/claude/locks"
    mkdir -m 700 -p "/tmp/claude-$(id -u)"
    [ -z "${XDG_RUNTIME_DIR:-}" ] || mkdir -m 700 -p "$XDG_RUNTIME_DIR/cc-socks"
    ;;
  maki)
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/maki"
    if [ "$profile" = maki-nono-gpu ]; then
      mkdir -p "$state/maki"
    fi
    ;;
  *)
    echo "unknown agent '$agent': install this script as claude-nono or maki-nono" >&2
    exit 2
    ;;
esac
mkdir -p "$state/$profile"

cwd_args=(--allow-cwd)
if ! preflight="$(nono run -s --profile "$profile" "${gpu_args[@]}" --allow-cwd --dry-run -- true 2>&1)"; then
  case "$preflight" in
    *"deny-overlap is not enforceable"*)
      echo "warning: not granting '$PWD': it contains paths denied by the profile; run from a project directory to grant cwd access" >&2
      cwd_args=()
      ;;
    *)
      printf '%s\n' "$preflight" >&2
      exit 1
      ;;
  esac
fi

exec nono run --profile "$profile" "${gpu_args[@]}" "${cwd_args[@]}" -- "$agent" "$@"
