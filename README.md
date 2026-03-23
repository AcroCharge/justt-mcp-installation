# Justt MCP Installation

Sets up personal MCP server entries in Claude's desktop config so Justt's Claude plugins can connect to the internal API.

## Why this exists

Justt's Claude plugins (Salesforce, Gong, Snowflake, Freshdesk, Fullstory) connect to an internal API server that is protected by the Justt VPN. Claude for Work distributes these plugins org-wide, but the built-in connector mechanism routes through Anthropic's cloud — which cannot reach the VPN.

The fix is to configure the connectors as **personal MCP servers** in your local Claude config instead. These run on your machine, where VPN is active. This script does that automatically.

## Prerequisites

- Claude desktop app installed
- Connected to the Justt VPN

## Install

### Mac

Open Terminal (`Cmd + Space` → type `Terminal` → Enter) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/AcroCharge/justt-mcp-installation/main/setup.sh | bash
```

**No curl?** Use this instead:
```bash
python3 -c "import urllib.request; exec(urllib.request.urlopen('https://raw.githubusercontent.com/AcroCharge/justt-mcp-installation/main/setup.sh').read().decode())"
```

### Windows

Open PowerShell (`Win + R` → type `powershell` → Enter) and run:

```powershell
irm https://raw.githubusercontent.com/AcroCharge/justt-mcp-installation/main/setup.ps1 | iex
```

## What the script does

1. Finds `npx` on your machine — installs Node.js automatically if missing (`brew install node` on Mac, `winget install OpenJS.NodeJS` on Windows)
2. Locates your `claude_desktop_config.json`
3. Adds an entry for each Justt integration — safe to re-run, existing entries are updated not duplicated

After running, **restart Claude** for the changes to take effect.

## Connectors installed

| Name | Integration |
|---|---|
| `justt-salesforce-mcp` | Salesforce CRM |
| `justt-gong-mcp` | Gong call recordings |
| `justt-commercial-snowflake-mcp` | Snowflake analytics |
| `justt-freshdesk-mcp` | Freshdesk support tickets |
| `justt-fullstory-mcp` | Fullstory session replays |

## Adding a new integration

1. Add the new connector to the `connectors` dict in `setup.sh` (and `setup.ps1`)
2. Push to `main`
3. Users re-run the install command — new connector is added, existing ones untouched

## Troubleshooting

**"Claude directory not found"** → make sure the Claude desktop app is installed

**Tools still not available after restart** → confirm you are connected to the Justt VPN

**Node.js install failed on Mac** → install Homebrew first: https://brew.sh, then re-run

**Node.js install failed on Windows** → download the installer directly from https://nodejs.org, then re-run

**Questions?** → ask Dor on Slack
