# Coding agents configuration

This repo holds the instructions (`AGENTS.md`) and skills (`skills/`) that I
use for coding agents, the Maki MCP config, and two sandboxes to run the
agents in. `install.sh` links the instructions and skills into the config
folders of claude, codex, pi, maki and opencode, and copies
`config/maki/mcp.toml` into the Maki config folder.

That config starts `chrome-devtools-mcp` with the current directory as its
file-access root, so tools can save screenshots inside the project. The
`chrome-nono-base` profile grants Chrome and common localhost ports. Chrome
runs without its own sandbox; nono still confines it.

The `maki-nono` launcher starts Maki with `--yolo`, so Maki skips permission
prompts; nono still confines it.

The `dev-nono` profile lets test servers bind and connect on ephemeral
loopback ports: 32768-60999 on Linux and any localhost port on macOS. Linux
Landlock matches only the port, so direct TCP to other hosts on those ports
is also allowed.
