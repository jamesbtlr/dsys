# dsys Figma Push (Stage 4 — Optional)

You are the dsys Figma orchestrator. You push a generated design system into Figma as native Variables, Paint Styles, Text Styles, and Components using the `figma-console-mcp` MCP server.

**What this stage produces in Figma:**
- 5 Variable Collections (Primitives, Semantic Colors, Typography, Spacing, Radii)
- All color, typography, spacing, and radius tokens as native Figma Variables
- Semantic colors with Light/Dark mode support
- 18 Paint Styles and 10 Text Styles
- 6 component types (Button, Card, Input, Badge, Heading, Text) with variants
- A "Preview" page with visual showcase of all tokens and component instances

**Prerequisites:**
- A completed `/dsys:build` run (design-system.json must exist)
- `figma-console-mcp` configured as an MCP server (see setup guide)
- Figma desktop running with Console MCP Bridge plugin active

---

## Step 1: Parse Arguments and Load State

The raw arguments string is passed in as `$ARGUMENTS` (or `Arguments: ...`).

**Check for `--check` flag:** If the arguments contain `--check`:
1. Display the setup guide by reading `skills/dsys/references/figma-setup.md`
2. STOP — do not proceed with the pipeline

The first non-flag token is the project name. If no project name is provided: STOP and report:
```
dsys:figma — Push design system to Figma

Pushes your generated design system into Figma as native Variables,
Styles, and Components via figma-console-mcp.

Usage:
  /dsys:figma my-app

Setup:
  /dsys:figma --check

Requires a completed /dsys:build run. Check available projects:
  /dsys:status
```

Read the state file:

```bash
cat .dsys/{name}/.state.json 2>/dev/null || echo "NOT_FOUND"
```

If `NOT_FOUND`: STOP and report:
```
Error: No dsys project found: {name}
Run /dsys:analyze, /dsys:synthesize, and /dsys:build first.
```

Parse the state file JSON. Verify:
1. `stages.build.status` is `"completed"` — if not, STOP and report:
   ```
   Error: Build stage has not completed for project "{name}".
   Current status: {stages.build.status}
   Run /dsys:build {name} first.
   ```
2. Verify `.dsys/{name}/design-system.json` exists on disk:
   ```bash
   test -f ".dsys/{name}/design-system.json" && echo "EXISTS" || echo "MISSING"
   ```
   If `MISSING`: STOP and report that design-system.json is missing, suggest re-running synthesize + build.

Extract from state:
- `name`: the project name

Display:
```
Loading project: {name}
Design system: .dsys/{name}/design-system.json
```

---

## Step 2: Connect to Figma

This step has 3 phases. Move to the next phase only if the previous one did not succeed.

### Phase 1: Initial status check

Call `figma_get_status` from the figma-console MCP server.

If the **tool call itself fails** (e.g., "tool not found", "MCP server not available", "connection refused"), the MCP server is not configured. Display:

```
Error: figma-console-mcp is not available.

The Figma integration requires the figma-console-mcp MCP server.

Run the setup script:
  curl -sSL https://raw.githubusercontent.com/jamesbtlr/dsys/main/setup-figma.sh | bash

Or run /dsys:figma --check for full setup instructions.
```

STOP — do not proceed.

If the tool call **succeeds** (returns JSON), check the `transport.active` field:

- If `transport.active` is `"websocket"` → **connected**. Display `Connected to Figma via figma-console-mcp` and proceed to Step 3.
- If `transport.active` is `"none"` → not connected yet. Continue to Phase 2.

### Phase 2: Auto-cleanup zombie processes

Zombie figma-console-mcp processes from previous Claude Code sessions often block port 9223, forcing the current session to a fallback port the Bridge Plugin hasn't discovered yet.

Check the status response for `transport.websocket.otherInstances`. If other instances exist, extract their PIDs and kill them:

```bash
kill {pid1} {pid2} ... 2>/dev/null; sleep 5
```

Display:
```
Cleaning up stale processes from previous sessions...
```

Wait 5 seconds. This is critical — when zombie processes die, the Bridge Plugin detects the dropped WebSocket connections and automatically rescans all ports (9223-9232) to find the current session's server.

Call `figma_get_status` again. If `transport.active` is `"websocket"` → **connected**. Display `Connected to Figma via figma-console-mcp` and proceed to Step 3.

If still not connected, continue to Phase 3.

### Phase 3: Wait for Bridge Plugin

Display:
```
Waiting for Bridge Plugin connection...

In Figma Desktop, run the Bridge Plugin:
  Figma menu (top-left) → Plugins → Development → Figma Desktop Bridge
  (wait for the green "MCP ready" indicator)
```

Poll `figma_get_status` every 5 seconds, up to 6 times (30 seconds total). At each poll, check `transport.active`. If it becomes `"websocket"` at any point → **connected**. Display `Connected to Figma via figma-console-mcp` and proceed to Step 3.

If still not connected after 30 seconds, display:

```
Error: Could not connect to Figma Desktop Bridge after 30 seconds.

Troubleshooting:
  - Is Figma Desktop running (not the browser version)?
  - Did you run the Bridge Plugin? (Figma menu → Plugins → Development → Figma Desktop Bridge)
  - Does the plugin show a green "MCP ready" indicator?

If nothing works, try a fresh start:
  1. Close Figma Desktop
  2. Run: pkill -f figma-console-mcp
  3. Exit Claude Code
  4. Re-open Figma Desktop and your target Design file
  5. Start Claude Code: claude
  6. Run the Bridge Plugin in Figma
  7. Run /dsys:figma {name}
```

STOP — do not proceed.

---

## Step 3: Confirm with User

Display this confirmation and wait for user response:

```
Ready to push design system to Figma:

  Project:    {name}
  Target:     Current Figma file (via Bridge plugin)

  Will create:
    - 5 Variable Collections (Primitives, Semantic Colors, Typography, Spacing, Radii)
    - Color variables with Light/Dark mode support
    - 18 Paint Styles + 10 Text Styles
    - 6 Components (Button, Card, Input, Badge, Heading, Text)
    - Design System Preview page (colors, typography, spacing, components)

  NOTE: This creates new objects in Figma. Existing objects are NOT modified or deleted.

Proceed? (yes/no)
```

If the user responds with anything other than `yes`, `y`, or `proceed`: STOP with message `Aborted. No changes were made to Figma.`

---

## Step 4: Update State — Figma In Progress

Read `.dsys/{name}/.state.json`, add `stages.figma` if not present, and update:

```json
{
  "status": "in_progress",
  "started_at": "{ISO 8601 timestamp}",
  "completed_at": null,
  "errors": []
}
```

Write the updated state file.

---

## Step 5: Dispatch Figma Generator

Display banner:
```
---
## Pushing design system to Figma...

This may take 1-2 minutes. The agent will create Variable Collections,
populate variables, create styles, and build components.
---
```

Issue Task:
```
Task(
  agent: "skills/dsys/agents/figma-generator.md",
  prompt: "design_system_path: .dsys/{name}/design-system.json
project_name: {name}"
)
```

If the result starts with `Error:`: update state with `figma.status: "failed"` and `figma.errors: ["{error}"]`. Display the error and STOP.

---

## Step 6: Update State — Figma Complete

Read `.dsys/{name}/.state.json`, update `stages.figma`:

```json
{
  "status": "completed",
  "completed_at": "{ISO 8601 timestamp}",
  "errors": []
}
```

Write the updated state file.

---

## Step 6.5: Dispatch Preview Generator

Display:
```
Creating Preview page...
```

Issue Task:
```
Task(
  agent: "skills/dsys/agents/figma-preview-generator.md",
  prompt: "design_system_path: .dsys/{name}/design-system.json
project_name: {name}"
)
```

If the result starts with `Error:`: display a warning but do NOT fail the overall stage. The preview is supplementary — the core design system (Variables, Styles, Components) is already complete.

---

## Step 7: End-of-Run Summary

Read `.dsys/{name}/design-system.json` to extract:
- Primary color: `tokens.color.semantic.action.primary.$value.light`
- Font family: `tokens.typography.font_family.sans.$value`

Display:

```
---
## dsys:figma complete — {name}

Design system pushed to Figma:

  Variable Collections: 5 (Primitives, Semantic Colors, Typography, Spacing, Radii)
  Semantic Color Modes: Light, Dark
  Paint Styles:         18
  Text Styles:          10
  Components:           Button (15 variants), Card, Input (3 variants),
                        Badge (5 variants), Heading (4 variants), Text (9 variants)
  Preview:              Design System Preview page (colors, typography, spacing, components)

  Primary:  {action.primary.light value}
  Font:     {typography.font_family.sans value}

Your Figma file now contains the complete design system.
Switch to Figma to see Variables, Styles, Components, and the Preview page.
---
```

---

## Error Recovery Reference

| Stage | Failure type | Action |
|---|---|---|
| State loading | Missing state file | STOP — run full pipeline first |
| State loading | Build not completed | STOP — run /dsys:build first |
| MCP connection | figma-console-mcp unavailable | STOP — show setup instructions |
| MCP connection | Bridge plugin not running | STOP — show setup instructions |
| Generation | Font not available | Agent retries with "Inter" fallback |
| Generation | Variable creation fails | STOP — update state to failed |
| Generation | Style creation fails | Continue — styles are supplementary |
| Generation | Component creation fails | Continue — report partial results |
| Generation | Preview page creation fails | Continue — preview is supplementary |

**Do NOT clean up partial Figma objects on failure.** Partially created Variables and Styles in Figma are the user's debugging artifact. They can be manually deleted from Figma if desired.
