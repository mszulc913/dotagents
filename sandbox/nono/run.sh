#!/usr/bin/env bash
# Landlock silently drops grants for paths that do not exist yet, so create them on the host first.
set -euo pipefail

agent="${0##*/}"
agent="${agent%-nono}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"

profile="$agent-nono"
gpu_args=()
push_args=()
agent_args=()
gpu=false
push=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --gpu) gpu=true; shift ;;
    --push) push=true; shift ;;
    *) break ;;
  esac
done
if [ "$gpu" = true ]; then
  profile="$agent-nono-gpu"
  gpu_args=(--allow-gpu)
fi
if [ "$push" = true ]; then
  push_args=(--extends push-nono-base)
fi

case "$agent" in
  claude)
    mkdir -p "$HOME/.cache/claude" "$state/claude/locks"
    mkdir -m 700 -p "/tmp/claude-$(id -u)"
    [ -z "${XDG_RUNTIME_DIR:-}" ] || mkdir -m 700 -p "$XDG_RUNTIME_DIR/cc-socks"
    agent_args=(--dangerously-skip-permissions)
    ;;
  maki)
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/maki"
    if [ "$profile" = maki-nono-gpu ]; then
      mkdir -p "$state/maki"
    fi
    agent_args=(--yolo)
    ;;
  *)
    echo "unknown agent '$agent': install this script as claude-nono or maki-nono" >&2
    exit 2
    ;;
esac

stamp="$state/nono/maki-update-check"
check_maki_update() {
  local current latest answer out
  if [ -n "$(find "$stamp" -mmin -1440 2>/dev/null)" ]; then
    return 0
  fi
  mkdir -p "$(dirname "$stamp")"
  touch "$stamp"
  current=$(maki --version 2>/dev/null | awk '{print $2}') || return 0
  [ -n "$current" ] || return 0
  latest=$(curl -fsSL https://api.github.com/repos/tontinton/maki/releases/latest \
    | jq -r '.tag_name' 2>/dev/null) || return 0
  [ -n "$latest" ] && [ "$latest" != "null" ] || return 0
  [ "${latest#v}" != "${current#v}" ] || return 0

  answer=""
  if [ -r /dev/tty ]; then
    read -r -p "[nono] maki $current -> $latest on host. Update? [y/N] " answer </dev/tty || answer=""
  fi
  case "$answer" in
    y|Y|yes|YES) ;;
    *) return 0 ;;
  esac

  if out=$(curl -fsSL https://maki.sh/install.sh \
    | env -u GH_TOKEN -u GITHUB_TOKEN MAKI_INSTALL_DIR="$HOME/.local/bin" sh 2>&1); then
    echo "[nono] maki updated to $latest on host"
  else
    echo "[nono] maki update failed:" >&2
    printf '%s\n' "$out" >&2
  fi
}

[ "$agent" != maki ] || check_maki_update

chrome_tmp="$state/nono-chrome-tmp"
mkdir -p "$state/$profile" "$HOME/.cache/chrome-devtools-mcp/chrome-profile" "$chrome_tmp"
export TMPDIR="$chrome_tmp"

if [ "$push" = true ]; then
  if [ -z "${SSH_AUTH_SOCK:-}" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
    echo "error: --push requires a running ssh-agent in SSH_AUTH_SOCK" >&2
    exit 1
  fi
  ssh_dir="$HOME/.local/state/nono-ssh"
  mkdir -p "$ssh_dir"
  known_hosts="$ssh_dir/known_hosts"
  if [ ! -e "$known_hosts" ] && [ -f "$HOME/.ssh/known_hosts" ]; then
    cp "$HOME/.ssh/known_hosts" "$known_hosts"
  fi
  touch "$known_hosts"
  export GIT_SSH_KNOWN_HOSTS="$known_hosts"
fi

cwd_args=(--allow-cwd)
if ! preflight="$(nono run -s --profile "$profile" "${gpu_args[@]}" "${push_args[@]}" --allow-cwd --dry-run -- true 2>&1)"; then
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

exec nono run --profile "$profile" "${gpu_args[@]}" "${push_args[@]}" "${cwd_args[@]}" -- "$agent" "${agent_args[@]}" "$@"
