# =============================================================================
# Justt MCP Setup — Windows
# Writes personal MCP server entries into claude_desktop_config.json so that
# Justt's Claude plugins can connect to the internal API over VPN.
#
# Usage (PowerShell):
#   irm https://raw.githubusercontent.com/AcroCharge/justt-mcp-installation/main/setup.ps1 | iex
#
# Safe to re-run: adds new connectors, updates existing ones, never deletes.
# =============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Justt MCP Setup" -ForegroundColor White
Write-Host "================================"

# --- 1. Find npx ------------------------------------------------------------

$npxCmd = Get-Command npx -ErrorAction SilentlyContinue

if (-not $npxCmd) {
    Write-Host "Node.js not found. Attempting to install..." -ForegroundColor Yellow
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        winget install --id OpenJS.NodeJS -e --accept-source-agreements --accept-package-agreements
        # Refresh PATH for current session
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $npxCmd = Get-Command npx -ErrorAction SilentlyContinue
    }
    if (-not $npxCmd) {
        Write-Host "Could not find or install Node.js." -ForegroundColor Red
        Write-Host "Please install it manually: https://nodejs.org"
        Write-Host "Then re-run this script."
        exit 1
    }
}

$npxPath = $npxCmd.Source
Write-Host "✓ npx: $npxPath" -ForegroundColor Green

# --- 2. Locate Claude config ------------------------------------------------

$configDir  = "$env:APPDATA\Claude"
$configPath = "$configDir\claude_desktop_config.json"

if (-not (Test-Path $configDir)) {
    Write-Host "Claude directory not found at: $configDir" -ForegroundColor Red
    Write-Host "Is the Claude desktop app installed?"
    exit 1
}

Write-Host "✓ Claude config: $configPath" -ForegroundColor Green

# --- 3. Read existing config ------------------------------------------------

if (Test-Path $configPath) {
    try {
        $raw    = Get-Content $configPath -Raw -Encoding UTF8
        $config = $raw | ConvertFrom-Json -AsHashtable
    } catch {
        $backup = "$configPath.bak"
        Write-Host "  Warning: existing config has invalid JSON — backing up to $backup" -ForegroundColor Yellow
        Copy-Item $configPath $backup
        $config = @{}
    }
} else {
    $config = @{}
}

if (-not $config.ContainsKey("mcpServers")) {
    $config["mcpServers"] = @{}
}

# --- 4. Connector definitions — add new integrations here ------------------

$connectors = [ordered]@{
    "justt-salesforce-mcp"           = "https://plugins-api.justt.ai/mcp/salesforce/"
    "justt-gong-mcp"                 = "https://plugins-api.justt.ai/mcp/gong/"
    "justt-commercial-snowflake-mcp" = "https://plugins-api.justt.ai/mcp/snowflake/"
    "justt-freshdesk-mcp"            = "https://plugins-api.justt.ai/mcp/freshdesk/"
    "justt-fullstory-mcp"            = "https://plugins-api.justt.ai/mcp/fullstory/"
    "justt-hubspot-mcp"              = "https://plugins-api.justt.ai/mcp/hubspot/"
}

# ---------------------------------------------------------------------------

foreach ($name in $connectors.Keys) {
    $entry = @{
        command = $npxPath
        args    = @("-y", "mcp-remote", $connectors[$name])
    }
    if ($config["mcpServers"].ContainsKey($name)) {
        Write-Host "  ↺ updated: $name"
    } else {
        Write-Host "  + added:   $name"
    }
    $config["mcpServers"][$name] = $entry
}

# --- 5. Write back ----------------------------------------------------------

$config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8

Write-Host ""
Write-Host "Done! Restart Claude for changes to take effect." -ForegroundColor Green
Write-Host ""
