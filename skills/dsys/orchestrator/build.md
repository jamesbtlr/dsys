<!-- SYNC: Stage-3 extraction of SKILL.md Steps 12-15. Keep in sync. -->

# dsys Build (Stage 3 of 3)

You are the dsys build orchestrator. You run the build stage of the dsys pipeline: generate platform-specific code, enforcement rules, style guide, and visual preview from an already-synthesized `design-system.json`.

**What this stage produces:**
- Platform source files in `.dsys/{name}/react/` and/or `.dsys/{name}/swiftui/`
- `.dsys/{name}/CLAUDE.md` — design system rules for Claude
- `.dsys/{name}/STYLE-GUIDE.md` — human-readable reference
- `.dsys/{name}/preview.html` — visual preview (opens in browser)

---

## Step 1: Parse Arguments and Load State

The raw arguments string is passed in as `$ARGUMENTS` (or `Arguments: ...`).

The first token is the project name. If no project name is provided: STOP and report:
```
dsys:build — Step 3 of 3

Generates platform code (React/Tailwind, SwiftUI), enforcement rules,
style guide, and visual preview from a design-system.json.

Usage:
  /dsys:build my-app

Requires a completed /dsys:synthesize run. Check available projects:
  /dsys:status
```

Read the state file:

```bash
cat .dsys/{name}/.state.json 2>/dev/null || echo "NOT_FOUND"
```

If `NOT_FOUND`: STOP and report:
```
Error: No dsys project found: {name}
Run /dsys:analyze and /dsys:synthesize first.
```

Parse the state file JSON. Verify:
1. `stages.synthesize.status` is `"completed"` — if not, STOP and report:
   ```
   Error: Synthesis stage has not completed for project "{name}".
   Current status: {stages.synthesize.status}
   Run /dsys:synthesize {name} first.
   ```
2. Verify `.dsys/{name}/design-system.json` exists on disk:
   ```bash
   test -f ".dsys/{name}/design-system.json" && echo "EXISTS" || echo "MISSING"
   ```
   If `MISSING`: STOP and report that design-system.json is missing, suggest re-running synthesize.

Extract from state:
- `platforms`: the `platforms` array
- `name`: the project name

Display:
```
Loading project: {name}
Platforms: {platforms}
Design system: .dsys/{name}/design-system.json
```

---

## Step 2: Update State — Build In Progress

Read `.dsys/{name}/.state.json`, update `stages.build`:

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

## Step 3: Platform Generation

Display banner:
```
---
## Generating {platform_list} files...
---
```

**CRITICAL: If BOTH platforms are selected, issue BOTH generator Task calls in a SINGLE response turn for parallel execution.**

**React Task (if "react" in platforms):**
```
Task(
  agent: "skills/dsys/agents/react-generator.md",
  prompt: "design_system_path: .dsys/{name}/design-system.json
output_root: .dsys/{name}/react/src/design-system/
platforms: [\"react\"]"
)
```

**SwiftUI Task (if "swiftui" in platforms):**
```
Task(
  agent: "skills/dsys/agents/swiftui-generator.md",
  prompt: "design_system_path: .dsys/{name}/design-system.json
output_root: .dsys/{name}/swiftui/Sources/DesignSystem/
platforms: [\"swiftui\"]"
)
```

Check each result for `Error:` prefix. If any generator fails: update state with `build.status: "failed"` and `build.errors: ["{error}"]`. STOP and report which platform failed.

---

## Step 4: Rules and Style Guide

Display banner:
```
---
## Generating rules and style guide...
---
```

Issue Task:
```
Task(
  agent: "skills/dsys/agents/rules.md",
  prompt: "design_system_path: .dsys/{name}/design-system.json
claude_md_path: .dsys/{name}/CLAUDE.md
output_dir: .dsys/{name}/
platforms: {platforms_json_array}"
)
```

**CRITICAL: `claude_md_path` is `.dsys/{name}/CLAUDE.md` — NOT the project root `CLAUDE.md`. The user copies this file manually into their project when ready. Do NOT write to the project root CLAUDE.md.**

If the result starts with `Error:`: update state with `build.status: "failed"`. STOP and report — platform files are preserved.

---

## Step 5: Visual Preview

Read `.dsys/{name}/design-system.json` and generate a self-contained HTML preview at `.dsys/{name}/preview.html` based on the reference template at `skills/dsys/references/preview-template.html`.

**Process:**
1. Read the template file: `skills/dsys/references/preview-template.html`
2. Read the design-system.json
3. Replace all `{{placeholder}}` tokens in the template with actual values from design-system.json
4. Write the result to `.dsys/{name}/preview.html`

**Placeholder mapping** — see the full mapping table in `skills/dsys/orchestrator/SKILL.md` Step 14. In summary:
- Color placeholders (`{{action.primary.light}}`, `{{surface.default.dark}}`, etc.) → semantic color hex values
- Typography (`{{font.sans}}`, `{{type.xl}}`, `{{weight.bold}}`, `{{lh.tight}}`) → font family, scale sizes, weights, line heights
- Spacing (`{{space.1}}` through `{{space.32}}`) → spacing scale values
- Border radius (`{{radius.sm}}` through `{{radius.full}}`) → border radius values
- Shadows (`{{shadow.sm}}`, `{{shadow.md}}`) → CSS shadow strings
- Meta (`{{project.name}}`, `{{aesthetic.summary}}`, `{{aesthetic.tone}}`, `{{aesthetic.density}}`, `{{generated.date}}`)

**Dynamic content markers** (replace with generated HTML):
- `<!-- PERSONALITY_TAGS -->` → one `<span class="tag">` per `aesthetic.personality_tags` entry
- `<!-- PALETTE_COLORS -->` → `<h3>` + `.color-grid` per primitive color group
- `<!-- SEMANTIC_COLORS -->` → `<h3>` + `.semantic-group` per semantic role (Action, Surface, Text, Border, Feedback)

**Border-radius to component mapping** (already encoded in the template CSS):
- **Buttons:** `{{radius.full}}` — pill-shaped
- **Cards:** `{{radius.lg}}` — large rounded containers
- **Badges:** `{{radius.full}}` — always pill-shaped
- **Inputs:** `{{radius.md}}` — moderate rounding
- **Color swatches:** `{{radius.sm}}` — subtle rounding

After writing the file:
```bash
open .dsys/{name}/preview.html
```

---

## Step 6: Update State — Build Complete

Read `.dsys/{name}/.state.json`, update `stages.build`:

```json
{
  "status": "completed",
  "completed_at": "{ISO 8601 timestamp}",
  "errors": []
}
```

Write the updated state file.

---

## Step 7: End-of-Run Summary

```bash
ls -R .dsys/{name}/
```

Read `.dsys/{name}/design-system.json` to extract:
- Primary color: `tokens.color.semantic.action.primary.$value.light`
- Surface color: `tokens.color.semantic.surface.default.$value.light`
- Font family: `tokens.typography.font_family.sans.$value`

Display:
```
---
## dsys:build complete — {name}

### Design System
  .dsys/{name}/design-system.json

### React / Tailwind   {only if selected}
  {list all files in .dsys/{name}/react/}

### SwiftUI            {only if selected}
  {list all files in .dsys/{name}/swiftui/}

### Documentation
  .dsys/{name}/CLAUDE.md
  .dsys/{name}/STYLE-GUIDE.md
  .dsys/{name}/preview.html

---

### Design System Preview — {name}

Primary:    {action.primary.light value}
Surface:    {surface.default.light value}
Font:       {typography.font_family.sans value}
Components: Button, Card, Input, Badge, Heading, Text

Preview:    open .dsys/{name}/preview.html

---

To integrate: copy `.dsys/{name}/CLAUDE.md` into your project's CLAUDE.md
```

Use the actual `ls` output for the file list — do not hardcode paths.

---

## Error Recovery Reference

| Stage | Failure type | Action |
|---|---|---|
| State loading | Missing state file | STOP — tell user to run analyze + synthesize first |
| State loading | Synthesize not completed | STOP — tell user to run synthesize first |
| Generation | Agent error | STOP — update state to failed, design-system.json preserved |
| Rules | Agent error | STOP — update state to failed, platform files preserved |

**Do NOT clean up intermediate files on failure.** Partial output in `.dsys/{name}/` is the user's debugging artifact.
