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

# ── Step 3: Clean up and configure MCP server ──

# Kill stale figma-console-mcp processes from previous sessions.
# These zombies occupy ports and prevent new sessions from connecting.
if pgrep -f figma-console-mcp > /dev/null 2>&1; then
  echo "  Cleaning up stale figma-console-mcp processes..."
  pkill -f figma-console-mcp 2>/dev/null || true
  rm -f /tmp/figma-console-mcp-*.json 2>/dev/null || true
  sleep 1
fi

echo "  Configuring figma-console-mcp..."

# Check if already configured
if claude mcp get figma-console &> /dev/null; then
  echo "  figma-console is already configured. Removing old config..."
  claude mcp remove figma-console -s user 2>/dev/null || true
fi

claude mcp add figma-console \
  -s user \
  -e FIGMA_ACCESS_TOKEN="$FIGMA_TOKEN" \
  -e ENABLE_MCP_APPS=true \
  -e FIGMA_WS_PORT=9223 \
  -- npx -y figma-console-mcp@latest

echo "  MCP server configured."
echo ""

# ── Step 4: Locate Bridge Plugin ──

echo "  Locating Desktop Bridge plugin..."

# npx caches the package under ~/.npm/_npx when claude mcp add runs it
MANIFEST=$(find "$HOME/.npm/_npx" -path "*/figma-console-mcp/figma-desktop-bridge/manifest.json" -print -quit 2>/dev/null || true)

echo ""
echo "  ────────────────────────────────────────────────────"
echo "  Done! One-time setup: import the Bridge Plugin"
echo "  ────────────────────────────────────────────────────"
echo ""
echo "  In Figma Desktop (one-time):"
echo ""
echo "     a) Open (or create) any Design file"
echo "        (you must be inside a file — the home screen won't work)"
echo ""
echo "     b) Click the Figma menu (top-left) → Plugins → Development"
echo "        → Import plugin from manifest..."
echo ""

if [ -n "$MANIFEST" ]; then
  echo "     c) Select this file:"
  echo "        $MANIFEST"
else
  echo "     c) Run this to find the manifest path, then select it:"
  echo "        find ~/.npm/_npx -path '*/figma-console-mcp/figma-desktop-bridge/manifest.json' 2>/dev/null"
fi

echo ""
echo "  ────────────────────────────────────────────────────"
echo "  Each time you use /dsys:figma:"
echo "  ────────────────────────────────────────────────────"
echo ""
echo "  1. Start Claude Code:  claude"
echo "  2. Open your Figma Design file"
echo "  3. Run the Bridge Plugin:"
echo "     Figma menu → Plugins → Development → Figma Desktop Bridge"
echo "     (wait for green 'MCP ready' indicator)"
echo "  4. In Claude Code, run:  /dsys:figma my-project"
echo ""
