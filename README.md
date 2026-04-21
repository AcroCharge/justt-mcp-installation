# Justt MCP Installation

One-time setup for Justt's Claude plugins.

## Prerequisites

1. **Install the Claude desktop app** — download from https://claude.ai/download if you haven't already.
2. **Connect to the Justt VPN** — make sure the VPN is active before running the install command.
3. **Enable VPN DNS** — in the VPN client, go to **Settings → "Use VPN Interface DNS"** and toggle it **on**.

## Install

### Mac

Open Terminal and run:

```bash
curl -fsSL https://plugins-api.justt.ai/init/mac | bash
```

### Windows

Open PowerShell and run:

```powershell
irm https://plugins-api.justt.ai/init/windows | iex
```

## After Installation

**Restart Claude** for the changes to take effect:

- **Mac** — Quit Claude completely (right-click the dock icon → Quit, or Cmd+Q)
- **Windows** — Close Claude and end the process in Task Manager to make sure it fully stops

## Troubleshooting

- **"Claude directory not found"** — make sure the Claude desktop app is installed before running the command
- **Tools not available after restart** — confirm you are connected to the Justt VPN with "Use VPN Interface DNS" enabled
- **Node.js install failed (Mac)** — install Homebrew first: https://brew.sh, then re-run
- **Node.js install failed (Windows)** — download from https://nodejs.org, then re-run
- **Questions?** — ask Dor on Slack
