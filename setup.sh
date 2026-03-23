#!/bin/bash
set -e

# =============================================================================
# Justt MCP Setup — Mac
# Writes personal MCP server entries into claude_desktop_config.json so that
# Justt's Claude plugins can connect to the internal API over VPN.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AcroCharge/justt-mcp-installation/main/setup.sh | bash
#
# Safe to re-run: adds new connectors, updates existing ones, never deletes.
# =============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Justt MCP Setup${NC}"
echo "================================"

# --- 1. Find npx ----------------------------------------------------------

NPX=""
for candidate in /opt/homebrew/bin/npx /usr/local/bin/npx; do
  if [ -x "$candidate" ]; then
    NPX="$candidate"
    break
  fi
done
if [ -z "$NPX" ] && command -v npx &>/dev/null; then
  NPX=$(command -v npx)
fi

if [ -z "$NPX" ]; then
  echo -e "${YELLOW}Node.js not found. Attempting to install...${NC}"
  if command -v brew &>/dev/null; then
    brew install node
    for candidate in /opt/homebrew/bin/npx /usr/local/bin/npx; do
      if [ -x "$candidate" ]; then NPX="$candidate"; break; fi
    done
  fi
  if [ -z "$NPX" ]; then
    echo -e "${RED}Could not find or install Node.js.${NC}"
    echo "Please install it manually: https://nodejs.org"
    echo "Then re-run this script."
    exit 1
  fi
fi

echo -e "${GREEN}✓${NC} npx: $NPX"

# --- 2. Locate Claude config ----------------------------------------------

CONFIG_DIR="$HOME/Library/Application Support/Claude"
CONFIG="$CONFIG_DIR/claude_desktop_config.json"

if [ ! -d "$CONFIG_DIR" ]; then
  echo -e "${RED}Claude directory not found at:${NC} $CONFIG_DIR"
  echo "Is the Claude desktop app installed?"
  exit 1
fi

echo -e "${GREEN}✓${NC} Claude config: $CONFIG"

# --- 3. Write MCP entries (via python3, always available on Mac) ----------

python3 - "$CONFIG" "$NPX" <<'PYTHON'
import json, sys, os

config_path = sys.argv[1]
npx_path    = sys.argv[2]

# Read existing config or start fresh
if os.path.exists(config_path):
    try:
        with open(config_path) as f:
            config = json.load(f)
    except (json.JSONDecodeError, ValueError):
        backup = config_path + ".bak"
        print(f"  Warning: existing config has invalid JSON — backing up to {backup}")
        os.rename(config_path, backup)
        config = {}
else:
    config = {}

if "mcpServers" not in config:
    config["mcpServers"] = {}

# -------------------------------------------------------------------------
# Connector definitions — add new integrations here
# -------------------------------------------------------------------------
connectors = {
    "justt-salesforce-mcp":           "https://plugins-api.justt.ai/mcp/salesforce/",
    "justt-gong-mcp":                 "https://plugins-api.justt.ai/mcp/gong/",
    "justt-commercial-snowflake-mcp": "https://plugins-api.justt.ai/mcp/snowflake/",
    "justt-freshdesk-mcp":            "https://plugins-api.justt.ai/mcp/freshdesk/",
    "justt-fullstory-mcp":            "https://plugins-api.justt.ai/mcp/fullstory/",
}
# -------------------------------------------------------------------------

added, updated = [], []

for name, url in connectors.items():
    entry = {
        "command": npx_path,
        "args": ["-y", "@modelcontextprotocol/mcp-remote", url],
    }
    if name in config["mcpServers"]:
        updated.append(name)
    else:
        added.append(name)
    config["mcpServers"][name] = entry

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")

for name in added:
    print(f"  + added:   {name}")
for name in updated:
    print(f"  ↺ updated: {name}")
PYTHON

echo ""
echo -e "${GREEN}Done!${NC} Restart Claude for changes to take effect."
echo ""
