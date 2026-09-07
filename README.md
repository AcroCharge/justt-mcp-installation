# Justt MCP Installation

One-time setup for Justt's Claude plugins. There are two flavors: **Claude Desktop / Cowork / chat** (the desktop app) and **Claude Code** (the CLI) — install whichever you use; both is fine too.

## Prerequisites

1. **Install Claude** — the desktop app from https://claude.ai/download, and/or Claude Code from https://claude.com/claude-code.
2. **Connect to the Justt VPN** — make sure the VPN is active before running the install command.
3. **Enable VPN DNS** — in the VPN client, go to **Settings → "Use VPN Interface DNS"** and toggle it **on**.

## Install — Claude Desktop / Cowork

### Mac

Open Terminal and run:

```bash
curl -fsSL https://plugins-api.justt.ai/init/mac | bash
```

### Windows

Open PowerShell — press **Win + R**, type `powershell`, and press Enter (or click the Start menu, search for "PowerShell", and open it). Then run:

```powershell
irm https://plugins-api.justt.ai/init/windows | iex
```

> **Run this command twice on Windows.** The first run installs Node.js and then exits — the newly installed `npx` is not yet available in that PowerShell session. **Close the PowerShell window, open a fresh one, and run the same command again.** The second run is the one that actually wires `justt-mcp` into Claude. (If Node.js was already installed on your machine, a single run is enough — but running it again is harmless.)

Skills for these surfaces are managed org-wide by the admins — nothing extra to install.

## Install — Claude Code (CLI)

Mac / Linux / WSL. Open a terminal and run:

```bash
curl -fsSL https://plugins-api.justt.ai/init/code | bash
```

This registers the `justt-mcp` server, stores your work email in `~/.claude/CLAUDE.md` (so tools know who's calling), and installs all of Justt's skills. The skills come from a private GitHub repo, so you need GitHub access to the AcroCharge org — if you don't have it, use the skill-less variant:

```bash
curl -fsSL https://plugins-api.justt.ai/init/code | bash -s -- --no-skills
```

Skill updates arrive automatically at session start; re-running the command also works (and is how you pick up newly added skills — automatic updates refresh the skills you already have, but never install brand-new ones).

> **Installed before July 26, 2026? Re-run the command once.** Older installs have a bug where automatic skill updates silently never arrive (the updater couldn't authenticate to the private skills repo). The current installer fixes this as part of the run — one re-run and you're up to date and auto-updating from then on.

## After Installation

**Restart Claude** for the changes to take effect:

- **Mac** — Quit Claude completely (right-click the dock icon → Quit, or Cmd+Q)
- **Windows** — Close Claude and end the process in Task Manager to make sure it fully stops
- **Claude Code** — just start a new `claude` session

## Test That It Works

Once Claude has restarted, ask it a question that requires one of the Justt MCP tools. For example:

> Who is that guy Dor, who is bothering me about AI?

This will exercise the HiBob integration.

## Troubleshooting

- **"Claude directory not found"** — make sure the Claude desktop app is installed before running the command
- **Tools not available / justt-mcp not connected** — the VPN must be connected *before* Claude starts. Connect the VPN (with "Use VPN Interface DNS" enabled), quit Claude completely (on Windows, also end it in Task Manager), reopen it, and start a **new** conversation — an existing one will not pick the tools up
- **Node.js install failed (Mac)** — install Homebrew first: https://brew.sh, then re-run
- **Node.js install failed (Windows)** — download from https://nodejs.org, then re-run
- **"Could not add the plugin marketplace" (Claude Code)** — you don't have GitHub access to the AcroCharge org from this machine; ask Dor, or re-run with `--no-skills`
- **Questions?** — ask Dor on Slack
