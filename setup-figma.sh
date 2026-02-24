#!/bin/bash
set -e

echo ""
echo "  dsys — Figma integration setup"
echo ""

# ── Step 1: Check prerequisites ──

# Check claude CLI exists
if ! command -v claude &> /dev/null; then
  echo "  Error: 'claude' CLI not found."
  echo "  Install Claude Code first: https://claude.ai/code"
  echo ""
  exit 1
fi

# Check dsys is installed
if [ ! -d "$HOME/.dsys-tool" ]; then
  echo "  Error: dsys is not installed."
  echo "  Run this first:"
  echo "    curl -sSL https://raw.githubusercontent.com/jamesbtlr/dsys/main/install.sh | bash"
  echo ""
  exit 1
fi

# ── Step 2: Get Figma PAT ──

echo "  This script configures figma-console-mcp so /dsys:figma can push"
echo "  design systems into Figma as native Variables, Styles, and Components."
echo ""

if [ -n "$1" ]; then
  FIGMA_TOKEN="$1"
else
  echo "  You need a Figma Personal Access Token (PAT)."
  echo "  Generate one at: https://www.figma.com/developers/api#access-tokens"
  echo ""
  printf "  Paste your Figma PAT: "
  read -r FIGMA_TOKEN < /dev/tty
  echo ""
fi

if [ -z "$FIGMA_TOKEN" ]; then
  echo "  Error: No token provided."
  exit 1
fi

# Basic format check
if [[ ! "$FIGMA_TOKEN" == figd_* ]]; then
  echo "  Warning: Token doesn't start with 'figd_'. Figma PATs usually do."
  echo "  Continuing anyway..."
  echo ""
fi

# ── Step 3: Configure MCP server ──

echo "  Configuring figma-console-mcp..."

# Check if already configured
if claude mcp get figma-console &> /dev/null; then
  echo "  figma-console is already configured. Removing old config..."
  claude mcp remove figma-console -s user 2>/dev/null || true
fi

claude mcp add -s user \
  -e FIGMA_ACCESS_TOKEN="$FIGMA_TOKEN" \
  -e ENABLE_MCP_APPS=true \
  figma-console \
  -- npx -y figma-console-mcp@latest

echo "  MCP server configured."
echo ""

# ── Step 4: Locate Bridge Plugin ──

echo "  Locating Desktop Bridge plugin..."

# Pre-download the package so --print-path works
BRIDGE_PATH=$(npx -y figma-console-mcp@latest --print-path 2>/dev/null || true)

if [ -n "$BRIDGE_PATH" ] && [ -f "$BRIDGE_PATH/figma-desktop-bridge/manifest.json" ]; then
  MANIFEST="$BRIDGE_PATH/figma-desktop-bridge/manifest.json"
else
  # Fallback: find it in the npm cache
  MANIFEST=$(find "$HOME/.npm/_npx" -path "*/figma-console-mcp/figma-desktop-bridge/manifest.json" -print -quit 2>/dev/null || true)
fi

echo ""
echo "  ────────────────────────────────────────────────────"
echo "  Done! Two steps remain (must be done in Figma):"
echo "  ────────────────────────────────────────────────────"
echo ""
echo "  1. Import the Bridge Plugin into Figma:"
echo "     Open Figma desktop → Plugins → Development → Import plugin from manifest..."
echo ""

if [ -n "$MANIFEST" ]; then
  echo "     Select this file:"
  echo "     $MANIFEST"
else
  echo "     Run this to find the manifest path:"
  echo "       npx figma-console-mcp@latest --print-path"
  echo "     Then select: <that-path>/figma-desktop-bridge/manifest.json"
fi

echo ""
echo "  2. Run the Bridge Plugin in your Figma file:"
echo "     Plugins → Development → Figma Desktop Bridge"
echo "     You should see a 'Connected' indicator."
echo ""
echo "  Then start a new Claude Code session and run:"
echo "     /dsys:figma my-project"
echo ""
