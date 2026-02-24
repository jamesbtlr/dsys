# Figma Integration Setup

`/dsys:figma` pushes your generated design system into Figma as native Variables, Paint Styles, Text Styles, and Components. It requires the `figma-console-mcp` server (a third-party MCP by Southleft).

---

## Quick Setup

**1. Get a Figma Personal Access Token:**
Go to [figma.com/developers/api](https://www.figma.com/developers/api#access-tokens) and generate a token.

**2. Run the setup script:**

```bash
curl -sSL https://raw.githubusercontent.com/jamesbtlr/dsys/main/setup-figma.sh | bash -s -- figd_YOUR_TOKEN_HERE
```

Or interactively (it will prompt for your token):

```bash
curl -sSL https://raw.githubusercontent.com/jamesbtlr/dsys/main/setup-figma.sh | bash
```

The script:
- Kills stale figma-console-mcp processes from previous sessions
- Configures `figma-console-mcp` as a Claude Code MCP server (user-scoped, pinned to port 9223)
- Prints the exact path to the Bridge Plugin manifest you need to import

**3. Import the Bridge Plugin into Figma Desktop** (one-time, ~30 seconds):
- Open (or create) any Design file in Figma Desktop — you must be inside a file, not the home screen
- Click the **Figma menu** (top-left) → **Plugins** → **Development** → **Import plugin from manifest...**
- Select the `manifest.json` path the script printed
- Click **Open**

**4. Each time you use `/dsys:figma`** (order matters):
1. Start Claude Code: `claude`
2. Open your target Design file in Figma Desktop
3. Run the Bridge Plugin: **Figma menu** (top-left) → **Plugins** → **Development** → **Figma Desktop Bridge**
4. Wait for the green "MCP ready" indicator
5. In Claude Code, run: `/dsys:figma my-project`

The orchestrator auto-detects connection issues and will guide you if something isn't right.

---

## Prerequisites

- **dsys installed** — `curl -sSL https://raw.githubusercontent.com/jamesbtlr/dsys/main/install.sh | bash`
- **Figma desktop app** — must be running during the push
- **Figma Dev or Full seat** — free/viewer seats cannot create Variables
- **A completed `/dsys:build` run** — design-system.json must exist

---

## Verify Connection

```
/dsys:figma --check
```

If the connection fails, check:
- Is Figma desktop running?
- Is the Bridge Plugin running? (Figma menu → Plugins → Development → Figma Desktop Bridge)
- Is your PAT valid and not expired?
- Did you start a **new** Claude Code session after running setup?

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "figma-console-mcp not found" | MCP server not configured | Re-run setup-figma.sh, restart Claude Code |
| "Bridge not connected" | Plugin not running | Run Bridge Plugin in Figma (see step 4 above) |
| "Cleaning up stale processes" | Zombie processes from previous sessions | Automatic — wait 5 seconds, orchestrator handles it |
| "Could not connect after 30s" | Bridge Plugin not responding | Try the Fresh Start procedure below |
| "Unauthorized" | Invalid or expired PAT | Generate a new PAT and re-run setup-figma.sh |
| "Cannot create variables" | Free/viewer seat | Upgrade to Dev or Full seat |
| Font loading error | Font not available in Figma | Agent auto-retries with "Inter" fallback |
| Tools timeout | Large batch operation | Ensure stable connection, retry |

### Fresh Start

If nothing else works, this resets everything:

1. Close Figma Desktop
2. Kill all processes: `pkill -f figma-console-mcp`
3. Exit Claude Code
4. Open Figma Desktop and your target Design file
5. Start Claude Code: `claude`
6. Run the Bridge Plugin in Figma
7. Run `/dsys:figma my-project`

---

## Manual Setup (if you prefer not to use the script)

**1. Configure MCP server:**
```bash
claude mcp add figma-console \
  -s user \
  -e FIGMA_ACCESS_TOKEN=figd_YOUR_TOKEN_HERE \
  -e ENABLE_MCP_APPS=true \
  -e FIGMA_WS_PORT=9223 \
  -- npx -y figma-console-mcp@latest
```

**2. Find the Bridge Plugin:**
```bash
find ~/.npm/_npx -path '*/figma-console-mcp/figma-desktop-bridge/manifest.json' 2>/dev/null
```

**3. Import in Figma Desktop:**
Open any Design file → Figma menu (top-left) → Plugins → Development → Import plugin from manifest... → select the manifest.json

---

## What It Creates

`/dsys:figma` reads your `design-system.json` and creates:

1. **Variable Collections** — Primitives, Semantic Colors (Light/Dark modes), Typography, Spacing, Radii
2. **Color Variables** — every primitive and semantic color as a native Figma Variable
3. **Paint Styles** — 18 semantic colors as reusable Figma Paint Styles
4. **Text Styles** — 10 typography presets (Heading 1-4, Body, Caption, etc.) as Figma Text Styles
5. **Components** — Button (15 variants), Card, Input (3 variants), Badge (5 variants), Heading (4 variants), Text (9 variants)
6. **Preview Page** — Visual showcase of the complete design system with color palette, semantic colors (Light/Dark), typography scale, spacing, radius, and component instances
