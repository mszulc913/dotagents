# Coding agents configuration

Skills and other configurations I use for coding agents.

Supports:
- claude
- codex
- pi
- maki
- opencode

## Maki sandbox

Run maki isolated in a Docker Sandboxes microVM: `sandbox/sbx/maki/`. 

Set up in one go:

```bash
./install.sh sbx        # builds image, sets secret, installs 'maki-sbx' alias
```

Needs `$OPENROUTER_API_KEY` in the environment for the secret (stays on the
host). Then, from a project:

```bash
maki-sbx                # same as: sbx run ~/git/dotagents/sandbox/sbx/maki .
```

## Install

```bash
./install.sh            # AGENTS.md + skills + sbx
./install.sh skills     # AGENTS.md + skills
./install.sh sbx        # maki sbx only
```

Links `AGENTS.md` (as `CLAUDE.md` for claude) and `skills/` into each tool's
config folder, and installs a `maki-sbx` zsh alias (source it from `.zshrc`:
`source ~/.config/dotagents/maki-sbx.zsh`). Every existing file/dir asks for
confirmation; an empty answer, or no terminal to ask on, keeps it.

```bash
./install.sh -f            # override everything, no prompts
./install.sh --home <dir>  # targets under <dir> instead of $HOME
```

Existing real files/dirs are moved to `<dest>.bak.<timestamp>` before
linking; stale symlinks are just replaced.
