#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTRUCTIONS_SRC="$REPO_DIR/AGENTS.md"
SKILLS_SRC="$REPO_DIR/skills"
SBX_SRC="$REPO_DIR/sandbox/sbx/maki"
NONO_SRC="$REPO_DIR/sandbox/nono"
TARGET_NAMES=(skills sbx nono)
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<'USAGE'
Usage: install.sh [target...] [-f|--force] [-v|--verbose] [-H|--home <dir>] [-h|--help]

Targets:
  skills   AGENTS.md + skills/ into the config folders of claude, codex,
           pi, maki and opencode
  sbx      builds the maki sandbox image, sets the openrouter secret, installs
           a 'maki-sbx' zsh alias and sources it from .zshrc. Set SBX_NO_CACHE
           to rebuild the image layers and upgrade the bundled maki.
  nono     copies the nono profiles into nono's profile folder and the
           claude-nono and maki-nono launchers to ~/.local/bin, and links
           AGENTS.md + skills/ into the sandboxed Claude config folders. These
           are copies, not links: the sandbox can write ~/git, so it must not
           edit its policy.
  all      all of the above

Without a target, install.sh asks about each target. An empty answer, or no
terminal to ask on, installs it.

For skills, the target skills folder is kept as-is. Only entries that
collide with a skill from this repo are replaced. An empty folder is
created if missing.

  -f, --force         Replace existing files and dirs without asking. A real
                      file or dir moves to <dest>.bak.<timestamp>; a symlink
                      is removed.
  -v, --verbose       Also list items that are already up to date
  -H, --home <dir>    Base the targets on <dir> instead of $HOME
  -h, --help          Show this help

Each target prints a summary line such as 'nono: 2 changed, 16 unchanged'.
Changed items print below the summary. Unchanged items print only with --verbose.

Without --force, every existing file or dir asks for confirmation. An empty
answer, or no terminal to ask on, keeps the existing file.

Exit status: 0 all targets are installed, 1 a target failed, 2 a target was kept.
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

GROUP=""
DETAILS=""
BACKUP=""
CHANGED=0
UNCHANGED=0
KEPT=0
SKIPPED=0
FAILS=0

begin_group() {
  GROUP="$1"
  DETAILS=""
  BACKUP=""
  CHANGED=0
  UNCHANGED=0
  KEPT=0
  SKIPPED=0
  FAILS=0
}

end_group() {
  local summary=""

  if [ "$CHANGED" -eq 0 ] && [ "$KEPT" -eq 0 ] && [ "$SKIPPED" -eq 0 ] && [ "$FAILS" -eq 0 ]; then
    echo "$GROUP: up to date"
  else
    [ "$CHANGED" -eq 0 ] || summary="$CHANGED changed"
    [ "$UNCHANGED" -eq 0 ] || summary="${summary:+$summary, }$UNCHANGED unchanged"
    [ "$KEPT" -eq 0 ] || summary="${summary:+$summary, }$KEPT kept"
    [ "$SKIPPED" -eq 0 ] || summary="${summary:+$summary, }$SKIPPED skipped"
    [ "$FAILS" -eq 0 ] || summary="${summary:+$summary, }$FAILS failed"
    echo "$GROUP: $summary"
  fi
  [ -z "$DETAILS" ] || printf '%s' "$DETAILS"
}

short_path() {
  case "$1" in
    "$DEST_HOME") echo "~" ;;
    "$DEST_HOME"/*) echo "~${1#"$DEST_HOME"}" ;;
    *) echo "$1" ;;
  esac
}

detail_label() {
  if [ "$1" = "$GROUP" ]; then
    printf '%s' "$2"
  else
    printf '%s %s' "$1" "$2"
  fi
}

add_detail() {
  DETAILS="${DETAILS}  $(detail_label "$1" "$2"): $3"$'\n'
}

report_changed() {
  CHANGED=$((CHANGED + 1))
  add_detail "$1" "$2" "$3${BACKUP:+ (backup: $BACKUP)}"
  BACKUP=""
}

report_unchanged() {
  UNCHANGED=$((UNCHANGED + 1))
  [ "$VERBOSE" != true ] || add_detail "$1" "$2" "$3"
}

report_kept() {
  KEPT=$((KEPT + 1))
  add_detail "$1" "$2" "$3"
}

report_skipped() {
  SKIPPED=$((SKIPPED + 1))
  add_detail "$1" "$2" "$3"
}

report_note() {
  add_detail "$1" "$2" "$3"
}

report_failed() {
  FAILS=$((FAILS + 1))
  BACKUP=""
  echo "[$GROUP] $(detail_label "$1" "$2"): $3" >&2
}

ask() {
  local prompt="$1" default="$2" answer=""

  if [ -r /dev/tty ]; then
    read -r -p "$prompt " answer </dev/tty 2>/dev/null || answer=""
  fi
  case "${answer:-$default}" in
    y|Y|yes|YES) return 0 ;;
  esac
  return 1
}

describe_target() {
  case "$1" in
    skills) echo "AGENTS.md + skills for claude, codex, pi, maki and opencode" ;;
    sbx)    echo "maki-sbx, maki in a Docker Sandboxes microVM" ;;
    nono)   echo "claude-nono and maki-nono, agents in a nono sandbox" ;;
  esac
}

TARGETS=()
add_target() {
  local target
  for target in "${TARGETS[@]}"; do
    [ "$target" != "$1" ] || return 0
  done
  TARGETS+=("$1")
}

FORCE=false
VERBOSE=false
DEST_HOME="$HOME"
while [ $# -gt 0 ]; do
  case "$1" in
    skills|sbx|nono) add_target "$1" ;;
    all)
      for target in "${TARGET_NAMES[@]}"; do
        add_target "$target"
      done
      ;;
    -f|--force) FORCE=true ;;
    -v|--verbose) VERBOSE=true ;;
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

if [ ${#TARGETS[@]} -eq 0 ]; then
  for target in "${TARGET_NAMES[@]}"; do
    if ask "Install $target ($(describe_target "$target"))? [Y/n]" y; then
      add_target "$target"
    fi
  done
fi
[ ${#TARGETS[@]} -gt 0 ] || { echo "nothing to install"; exit 0; }

for target in "${TARGETS[@]}"; do
  case "$target" in
    sbx)  [ -d "$SBX_SRC" ] || die "$SBX_SRC not found" ;;
    nono) [ -d "$NONO_SRC" ] || die "$NONO_SRC not found" ;;
  esac
done

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
  ask "[$GROUP] $(detail_label "$tool" "$label"): $(short_path "$dest") exists. Replace? [y/N]" n && return 0

  report_kept "$tool" "$label" "kept existing"
  return 1
}

clear_dest() {
  local tool="$1" label="$2" dest="$3"

  BACKUP=""

  if [ -L "$dest" ]; then
    rm -f "$dest" || return 1
    return 0
  fi

  local backup="$dest.bak.$TIMESTAMP" attempt=1
  while path_exists "$backup"; do
    backup="$dest.bak.$TIMESTAMP-$attempt"
    attempt=$((attempt + 1))
  done

  mv "$dest" "$backup" || return 1
  BACKUP="$(basename "$backup")"
}

install_link() {
  local tool="$1" label="$2" src="$3" dest="$4" action="linked"

  if is_current_link "$dest" "$src"; then
    report_unchanged "$tool" "$label" "already linked ($(short_path "$dest"))"
    return 0
  fi

  if path_exists "$dest"; then
    action="replaced"
    confirm_replace "$tool" "$label" "$dest" || return 2
    clear_dest "$tool" "$label" "$dest" || {
      report_failed "$tool" "$label" "failed to replace $(short_path "$dest")"
      return 1
    }
  fi

  mkdir -p "$(dirname "$dest")" && ln -s "$src" "$dest" || {
    report_failed "$tool" "$label" "failed to link $(short_path "$dest")"
    return 1
  }
  report_changed "$tool" "$label" "$action"
}

install_copy() {
  local tool="$1" label="$2" src="$3" dest="$4" mode="$5" action="installed"

  if [ -f "$dest" ] && ! [ -L "$dest" ] && cmp -s "$src" "$dest"; then
    report_unchanged "$tool" "$label" "already installed ($(short_path "$dest"))"
    return 0
  fi

  if path_exists "$dest"; then
    action="replaced"
    confirm_replace "$tool" "$label" "$dest" || return 2
    clear_dest "$tool" "$label" "$dest" || {
      report_failed "$tool" "$label" "failed to replace $(short_path "$dest")"
      return 1
    }
  fi

  mkdir -p "$(dirname "$dest")" && install -m "$mode" "$src" "$dest" || {
    report_failed "$tool" "$label" "failed to copy $(short_path "$dest")"
    return 1
  }
  report_changed "$tool" "$label" "$action"
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
    report_unchanged "$tool" skills "already linked ($(short_path "$dest"))"
    return 0
  fi

  if path_exists "$dest" && { [ ! -d "$dest" ] || [ -L "$dest" ]; }; then
    confirm_replace "$tool" skills "$dest" || return 2
    clear_dest "$tool" skills "$dest" || {
      report_failed "$tool" skills "failed to replace $(short_path "$dest")"
      return 1
    }
  fi

  mkdir -p "$dest" || {
    report_failed "$tool" skills "failed to create $(short_path "$dest")"
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

install_all_tools() {
  install_tool claude   "$DEST_HOME/.claude/CLAUDE.md"           "$DEST_HOME/.claude/skills"
  install_tool codex    "$DEST_HOME/.codex/AGENTS.md"            "$DEST_HOME/.codex/skills"
  install_tool pi       "$DEST_HOME/.pi/AGENTS.md"               "$DEST_HOME/.pi/agent/skills"
  install_tool maki     "$DEST_HOME/.config/maki/AGENTS.md"      "$DEST_HOME/.config/maki/skills"
  install_tool opencode "$DEST_HOME/.config/opencode/AGENTS.md"  "$DEST_HOME/.config/opencode/skills"
}

build_sbx() {
  command -v docker >/dev/null || {
    report_skipped sbx build "skipped: docker not found"
    return 0
  }
  command -v sbx >/dev/null || {
    report_skipped sbx build "skipped: sbx not found"
    return 0
  }

  local args=()
  [ -z "${SBX_NO_CACHE:-}" ] || args=(--no-cache)
  "$SBX_SRC/build.sh" "${args[@]}" || {
    report_failed sbx build "failed"
    return 1
  }
}

set_sbx_secret() {
  command -v sbx >/dev/null || {
    report_skipped sbx secret "skipped: sbx not found"
    return 0
  }
  if sbx secret ls --global --service openrouter --json 2>/dev/null | grep -q '"scope": "global"'; then
    report_unchanged sbx secret "already set"
    return 0
  fi
  if [ -z "${OPENROUTER_API_KEY:-}" ]; then
    report_skipped sbx secret "skipped: OPENROUTER_API_KEY not set"
    return 0
  fi
  printf '%s' "$OPENROUTER_API_KEY" | sbx secret set openrouter || {
    report_failed sbx secret "failed"
    return 1
  }
  report_changed sbx secret "set"
}

report_stale_sandboxes() {
  command -v sbx >/dev/null || return 0

  local stale
  stale="$(sbx ls 2>/dev/null | awk '$2 == "maki" { print $1 }')"
  [ -n "$stale" ] || return 0

  local names
  names="$(printf '%s' "$stale" | tr '\n' ' ')"
  report_note sbx sandboxes "stale spec: $names"
  if [ "$FORCE" = true ] || confirm_replace sbx sandboxes "maki sandboxes"; then
    printf '%s\n' "$stale" | xargs -r sbx rm --force >/dev/null || report_failed sbx sandboxes "some removals failed"
    report_changed sbx sandboxes "removed"
  else
    record 2
  fi
}

install_sbx() {
  build_sbx || record $?
  set_sbx_secret || record $?

  local alias_dest="$DEST_HOME/.config/dotagents/maki-sbx.zsh"
  local line="alias maki-sbx='$SBX_SRC/run.sh'"

  if [ -f "$alias_dest" ] && ! [ -L "$alias_dest" ] && [ "$(cat "$alias_dest")" = "$line" ]; then
    report_unchanged sbx alias "already installed ($(short_path "$alias_dest"))"
  elif path_exists "$alias_dest" && ! confirm_replace sbx alias "$alias_dest"; then
    record 2
  else
    if path_exists "$alias_dest"; then
      clear_dest sbx alias "$alias_dest" || {
        report_failed sbx alias "failed to replace $(short_path "$alias_dest")"
        record 1
      }
    fi
    if ! path_exists "$alias_dest"; then
      mkdir -p "$(dirname "$alias_dest")" && printf '%s\n' "$line" > "$alias_dest" || {
        report_failed sbx alias "failed to write $(short_path "$alias_dest")"
        record 1
      }
      report_changed sbx alias "installed"
    fi
  fi

  install_sbx_rc "$alias_dest"
  report_stale_sandboxes
}

install_sbx_rc() {
  local alias_dest="$1" rc="$DEST_HOME/.zshrc"
  local source_line="source $alias_dest"

  if [ -f "$rc" ] && grep -qF "$source_line" "$rc"; then
    report_unchanged sbx zshrc "already sources the alias"
    return 0
  fi

  if [ -f "$rc" ]; then
    printf '\n# maki sandbox alias\n%s\n' "$source_line" >> "$rc" || {
      report_failed sbx zshrc "failed to update $(short_path "$rc")"
      return 1
    }
  else
    printf '%s\n' "$source_line" > "$rc" || {
      report_failed sbx zshrc "failed to write $(short_path "$rc")"
      return 1
    }
  fi
  report_changed sbx zshrc "source line added"
}

install_nono() {
  local state="$DEST_HOME/.local/state" file dir name

  for file in "$NONO_SRC"/*.json "$NONO_SRC"/*/*.json; do
    name="$(basename "$file" .json)"
    install_copy nono "profile $name" "$file" \
      "$DEST_HOME/.config/nono/profiles/$name.json" 644 || record $?
  done
  for dir in "$NONO_SRC"/*/; do
    name="$(basename "$dir")-nono"
    install_copy nono "launcher $name" "$NONO_SRC/run.sh" "$DEST_HOME/.local/bin/$name" 755 || record $?
  done

  install_tool claude-nono     "$state/claude-nono/CLAUDE.md"     "$state/claude-nono/skills"
  install_tool claude-nono-gpu "$state/claude-nono-gpu/CLAUDE.md" "$state/claude-nono-gpu/skills"
}

for target in "${TARGETS[@]}"; do
  begin_group "$target"
  case "$target" in
    skills) install_all_tools ;;
    sbx)    install_sbx ;;
    nono)   install_nono ;;
  esac
  end_group
done

[ "$FAILED" != true ] || exit 1
[ "$DECLINED" != true ] || exit 2
exit 0
