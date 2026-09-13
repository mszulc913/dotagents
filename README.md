# Coding agents configuration

Skills and other configurations I use for coding agents.

Supports:
- claude
- codex
- pi
- maki
- opencode

## Install

```bash
./install.sh
```

Links `AGENTS.md` (as `CLAUDE.md` for claude) and `skills/` into each tool's
config folder. Every existing file/dir asks for confirmation; an empty answer,
or no terminal to ask on, keeps it.

```bash
./install.sh -f            # override everything, no prompts
./install.sh --home <dir>  # targets under <dir> instead of $HOME
```

Existing real files/dirs are moved to `<dest>.bak.<timestamp>` before
linking; stale symlinks are just replaced.
