#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTRUCTIONS_SRC="$REPO_DIR/AGENTS.md"
SKILLS_SRC="$REPO_DIR/skills"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<'USAGE'
Usage: install.sh [-f|--force] [-H|--home <dir>] [-h|--help]

Symlinks this repo's AGENTS.md and each skill in skills/ into the config
folders of claude, codex, pi, maki and opencode.

The target skills folder is kept as-is. Only entries that collide with a
skill from this repo are replaced. An empty folder is created if missing.

  -f, --force         Replace existing files and dirs without asking. A real
                      file or dir moves to <dest>.bak.<timestamp>; a symlink
                      is removed.
  -H, --home <dir>    Base the targets on <dir> instead of $HOME
  -h, --help          Show this help

Without --force, every existing file or dir asks for confirmation. An empty
answer, or no terminal to ask on, keeps the existing file.

Exit status: 0 all targets are linked, 1 a target failed, 2 a target was kept.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

die_usage() {
  echo "error: $*" >&2
  usage >&2
  exit 1
}

report() {
  echo "[$1] $2: $3"
}

FORCE=false
DEST_HOME="$HOME"
while [ $# -gt 0 ]; do
  case "$1" in
    -f|--force) FORCE=true ;;
    -H|--home)
      [ $# -ge 2 ] || die_usage "missing value for $1"
      DEST_HOME="$2"
      shift
      ;;
    --home=*) DEST_HOME="${1#--home=}" ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die_usage "unknown option: $1" ;;
    *) die_usage "unexpected argument: $1" ;;
  esac
  shift
done
[ $# -eq 0 ] || die_usage "unexpected argument: $1"

[ -n "$DEST_HOME" ] || die_usage "--home needs a non-empty value"
[ -f "$INSTRUCTIONS_SRC" ] || die "$INSTRUCTIONS_SRC not found"
[ -d "$SKILLS_SRC" ] || die "$SKILLS_SRC not found"

mkdir -p "$DEST_HOME" || die "cannot create $DEST_HOME"
DEST_HOME="$(cd "$DEST_HOME" && pwd)" || die "cannot resolve $DEST_HOME"

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

is_current_link() {
  [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]
}

confirm_replace() {
  local tool="$1" label="$2" dest="$3"

  [ "$FORCE" != true ] || return 0

  local answer=""
  if [ -r /dev/tty ]; then
    read -r -p "[$tool] $label: $dest exists. Replace? [y/N] " answer </dev/tty || answer=""
  fi
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
  esac

  report "$tool" "$label" "kept existing ($dest)"
  return 1
}

clear_dest() {
  local tool="$1" label="$2" dest="$3"

  if [ -L "$dest" ]; then
    rm -f "$dest" || return 1
    report "$tool" "$label" "removed existing symlink"
    return 0
  fi

  local backup="$dest.bak.$TIMESTAMP" attempt=1
  while path_exists "$backup"; do
    backup="$dest.bak.$TIMESTAMP-$attempt"
    attempt=$((attempt + 1))
  done

  mv "$dest" "$backup" || return 1
  report "$tool" "$label" "moved existing to $backup"
}

install_link() {
  local tool="$1" label="$2" src="$3" dest="$4"

  if is_current_link "$dest" "$src"; then
    report "$tool" "$label" "already linked ($dest)"
    return 0
  fi

  if path_exists "$dest"; then
    confirm_replace "$tool" "$label" "$dest" || return 2
    clear_dest "$tool" "$label" "$dest" || {
      report "$tool" "$label" "failed to replace $dest"
      return 1
    }
  fi

  mkdir -p "$(dirname "$dest")" && ln -s "$src" "$dest" || {
    report "$tool" "$label" "failed to link $dest"
    return 1
  }
  report "$tool" "$label" "linked $dest -> $src"
}

FAILED=false
DECLINED=false
record() {
  case "$1" in
    2) DECLINED=true ;;
    *) FAILED=true ;;
  esac
}

install_skills() {
  local tool="$1" dest="$2" entry name status=0

  if is_current_link "$dest" "$SKILLS_SRC"; then
    report "$tool" skills "already linked ($dest)"
    return 0
  fi

  if path_exists "$dest" && { [ ! -d "$dest" ] || [ -L "$dest" ]; }; then
    confirm_replace "$tool" skills "$dest" || return 2
    clear_dest "$tool" skills "$dest" || {
      report "$tool" skills "failed to replace $dest"
      return 1
    }
  fi

  mkdir -p "$dest" || {
    report "$tool" skills "failed to create $dest"
    return 1
  }

  for entry in "$SKILLS_SRC"/*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    install_link "$tool" "skills/$name" "$entry" "$dest/$name" || status=$?
  done

  return "$status"
}

install_tool() {
  local tool="$1" instructions_dest="$2" skills_dest="$3"
  install_link "$tool" instructions "$INSTRUCTIONS_SRC" "$instructions_dest" || record $?
  install_skills "$tool" "$skills_dest" || record $?
}

install_tool claude   "$DEST_HOME/.claude/CLAUDE.md"           "$DEST_HOME/.claude/skills"
install_tool codex    "$DEST_HOME/.codex/AGENTS.md"            "$DEST_HOME/.codex/skills"
install_tool pi       "$DEST_HOME/.pi/AGENTS.md"               "$DEST_HOME/.pi/agent/skills"
install_tool maki     "$DEST_HOME/.config/maki/AGENTS.md"      "$DEST_HOME/.config/maki/skills"
install_tool opencode "$DEST_HOME/.config/opencode/AGENTS.md"  "$DEST_HOME/.config/opencode/skills"

[ "$FAILED" != true ] || exit 1
[ "$DECLINED" != true ] || exit 2
exit 0
