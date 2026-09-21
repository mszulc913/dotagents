#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTRUCTIONS_SRC="$REPO_DIR/AGENTS.md"
SKILLS_SRC="$REPO_DIR/skills"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<'USAGE'
Usage: install.sh [target] [-f|--force] [-H|--home <dir>] [-h|--help]

Targets:
  skills   AGENTS.md + skills/ into the config folders of claude, codex,
           pi, maki and opencode (default when no target is given)
  sbx      builds the maki sandbox image, sets the openrouter secret from
           $OPENROUTER_API_KEY, installs a 'maki-sbx' zsh alias and sources
           it from .zshrc

For skills, the target skills folder is kept as-is. Only entries that
collide with a skill from this repo are replaced. An empty folder is
created if missing.

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
TARGET=all
while [ $# -gt 0 ]; do
  case "$1" in
    skills|sbx|all)
      [ "$TARGET" = all ] || die_usage "target given twice"
      TARGET=$1
      ;;
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
[ "$TARGET" != sbx ] || [ -d "$REPO_DIR/sandbox/sbx/maki" ] || die "$REPO_DIR/sandbox/sbx/maki not found"

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

install_tool() {
  local tool="$1" instructions_dest="$2" skills_dest="$3"
  install_link "$tool" instructions "$INSTRUCTIONS_SRC" "$instructions_dest" || record $?
  install_skills "$tool" "$skills_dest" || record $?
}

install_all_tools() {
  install_tool claude   "$DEST_HOME/.claude/CLAUDE.md"           "$DEST_HOME/.claude/skills"
  install_tool codex    "$DEST_HOME/.codex/AGENTS.md"            "$DEST_HOME/.codex/skills"
  install_tool pi       "$DEST_HOME/.pi/AGENTS.md"               "$DEST_HOME/.pi/agent/skills"
  install_tool maki     "$DEST_HOME/.config/maki/AGENTS.md"      "$DEST_HOME/.config/maki/skills"
  install_tool opencode "$DEST_HOME/.config/opencode/AGENTS.md"  "$DEST_HOME/.config/opencode/skills"
}

build_sbx() {
  command -v docker >/dev/null || {
    report sbx build "skipped: docker not found"
    return 0
  }
  command -v sbx >/dev/null || {
    report sbx build "skipped: sbx not found"
    return 0
  }
  "$REPO_DIR/sandbox/sbx/maki/build.sh" || {
    report sbx build "failed"
    return 1
  }
}

set_sbx_secret() {
  command -v sbx >/dev/null || {
    report sbx secret "skipped: sbx not found"
    return 0
  }
  if sbx secret ls --global --service openrouter --json 2>/dev/null | grep -q '"scope": "global"'; then
    report sbx secret "already set"
    return 0
  fi
  if [ -z "${OPENROUTER_API_KEY:-}" ]; then
    report sbx secret "skipped: OPENROUTER_API_KEY not set"
    return 0
  fi
  printf '%s' "$OPENROUTER_API_KEY" | sbx secret set openrouter || {
    report sbx secret "failed"
    return 1
  }
  report sbx secret "set from OPENROUTER_API_KEY"
}

install_sbx() {
  build_sbx || record $?
  set_sbx_secret || record $?

  local kit_src="$REPO_DIR/sandbox/sbx/maki"
  local alias_dest="$DEST_HOME/.config/dotagents/maki-sbx.zsh"
  local line="alias maki-sbx='$kit_src/run.sh'"

  if [ -f "$alias_dest" ] && ! [ -L "$alias_dest" ] && [ "$(cat "$alias_dest")" = "$line" ]; then
    report sbx alias "already installed ($alias_dest)"
  else
    if path_exists "$alias_dest"; then
      confirm_replace sbx alias "$alias_dest" || record 2
      clear_dest sbx alias "$alias_dest" || {
        report sbx alias "failed to replace $alias_dest"
        record 1
      }
    fi
    if ! path_exists "$alias_dest"; then
      mkdir -p "$(dirname "$alias_dest")" && printf '%s\n' "$line" > "$alias_dest" || {
        report sbx alias "failed to write $alias_dest"
        record 1
      }
      report sbx alias "installed $alias_dest"
    fi
  fi

  install_sbx_rc "$alias_dest"
}

install_sbx_rc() {
  local alias_dest="$1" rc="$DEST_HOME/.zshrc"
  local source_line="source $alias_dest"

  if [ -f "$rc" ] && grep -qF "$source_line" "$rc"; then
    report sbx zshrc "already sources the alias"
    return 0
  fi

  if [ -f "$rc" ]; then
    printf '\n# maki sandbox alias\n%s\n' "$source_line" >> "$rc" || {
      report sbx zshrc "failed to update $rc"
      return 1
    }
  else
    printf '%s\n' "$source_line" > "$rc" || {
      report sbx zshrc "failed to write $rc"
      return 1
    }
  fi
  report sbx zshrc "added source line to $rc"
}

case "$TARGET" in
  skills) install_all_tools ;;
  sbx)    install_sbx ;;
  all)    install_all_tools; install_sbx ;;
esac

[ "$FAILED" != true ] || exit 1
[ "$DECLINED" != true ] || exit 2
exit 0
