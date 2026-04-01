# Justt MCP Installation

One-time setup for Justt's Claude plugins. Requires the Justt VPN and the Claude desktop app.

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

After running, **restart Claude** for the changes to take effect.

### Troubleshooting

- **"Claude directory not found"** — make sure the Claude desktop app is installed
- **Tools not available after restart** — confirm you are connected to the Justt VPN
- **Node.js install failed (Mac)** — install Homebrew first: https://brew.sh, then re-run
- **Node.js install failed (Windows)** — download from https://nodejs.org, then re-run
- **Questions?** — ask Dor on Slack
