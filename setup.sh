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

# If only an NVM-managed npx is available, prefer installing via Homebrew instead.
# Claude Desktop launches without a shell environment, so NVM paths don't work reliably.
if [ -z "$NPX" ] && command -v npx &>/dev/null; then
  FOUND_NPX=$(command -v npx)
  if [[ "$FOUND_NPX" == *".nvm"* ]] && command -v brew &>/dev/null; then
    echo -e "${YELLOW}Found npx via nvm ($FOUND_NPX) — installing Node via Homebrew for Claude Desktop compatibility...${NC}"
    brew install node || true
    for candidate in /opt/homebrew/bin/npx /usr/local/bin/npx; do
      if [ -x "$candidate" ]; then NPX="$candidate"; break; fi
    done
  fi
  # Use whatever was found if Homebrew install didn't help
  if [ -z "$NPX" ]; then
    NPX="$FOUND_NPX"
  fi
fi

if [ -z "$NPX" ]; then
  echo -e "${YELLOW}Node.js not found. Attempting to install...${NC}"

  # Try Homebrew first — gives a stable path that Claude Desktop can use
  if command -v brew &>/dev/null; then
    brew install node || true
    for candidate in /opt/homebrew/bin/npx /usr/local/bin/npx; do
      if [ -x "$candidate" ]; then NPX="$candidate"; break; fi
    done
  fi

  # Fall back to nvm only if Homebrew is not available
  if [ -z "$NPX" ]; then
    echo "  Homebrew not available — trying nvm (note: may not work with Claude Desktop on some machines)..."
    export NVM_DIR="$HOME/.nvm"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts 2>/dev/null || true
    if command -v npx &>/dev/null; then
      NPX=$(command -v npx)
    elif [ -d "$NVM_DIR/versions/node" ]; then
      NODE_VER=$(ls "$NVM_DIR/versions/node" | sort -V | tail -1)
      [ -x "$NVM_DIR/versions/node/$NODE_VER/bin/npx" ] && NPX="$NVM_DIR/versions/node/$NODE_VER/bin/npx"
    fi
  fi

  if [ -z "$NPX" ]; then
    echo -e "${RED}Could not install Node.js automatically.${NC}"
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

# --- 3. Clear stale npx cache if config previously used NVM ---------------
# If any existing connector used an NVM-managed npx and we're now switching
# to a Homebrew npx, the old cached mcp-remote modules will be incompatible
# (different node version hash) and crash with MODULE_NOT_FOUND.
if [[ "$NPX" != *".nvm"* ]] && [ -f "$CONFIG" ] && [ -d "$HOME/.npm/_npx" ]; then
  if grep -q "\.nvm" "$CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}  Detected stale NVM npx cache — clearing to avoid module errors...${NC}"
    rm -rf "$HOME/.npm/_npx"
    echo -e "${GREEN}✓${NC} npx cache cleared"
  fi
fi

# --- 4. Write MCP entries (via python3, always available on Mac) ----------

python3 - "$CONFIG" "$NPX" <<'PYTHON'
import json, sys, os, pathlib

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
    "justt-hubspot-mcp":              "https://plugins-api.justt.ai/mcp/hubspot/",
}
# -------------------------------------------------------------------------

added, updated = [], []

for name, url in connectors.items():
    entry = {
        "command": npx_path,
        "args": ["-y", "mcp-remote", url],
    }
    # When npx lives inside an nvm directory, Claude Desktop won't have node
    # on its PATH (no shell init runs).  Inject the nvm bin dir into PATH so
    # the #!/usr/bin/env node shebang in npx can resolve.
    if ".nvm" in npx_path:
        nvm_bin = str(pathlib.Path(npx_path).parent)
        entry["env"] = {"PATH": nvm_bin + ":/usr/bin:/bin"}
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
