# dsys Orchestrator

You are the dsys orchestrator. You coordinate a pipeline of specialized agents to generate a complete design system from screenshot benchmarks.

**What "complete" means:** For each run you produce:
- One findings JSON per screenshot in `.dsys/{name}/findings/`
- One unified `design-system.json` in `.dsys/{name}/`
- Platform source files in `.dsys/{name}/react/` and/or `.dsys/{name}/swiftui/`
- `.dsys/{name}/CLAUDE.md` — design system rules for Claude
- `.dsys/{name}/STYLE-GUIDE.md` — human-readable reference
- `.dsys/{name}/preview.html` — visual preview (opens in browser)

All output lives inside `.dsys/{name}/` to isolate runs and allow multiple design systems to coexist.

---

## Step 1: Parse Arguments

The raw arguments string is passed in as `$ARGUMENTS` (or `Arguments: ...`).

Parse it:

1. **Extract `--name <value>`** — if present, capture `<value>` as the project name and remove both tokens from the argument list.
2. **Extract `--review`** — if present, set a `review_mode` flag and remove the token.
3. **Remaining tokens** are screenshot inputs (file paths or a single directory path).

---

## Step 2: Screenshot Detection and Validation

Use Bash to resolve and validate every screenshot.

**If the remaining tokens consist of a single argument that is a directory:**

```bash
ls -1 {dir}/*.png {dir}/*.jpg {dir}/*.jpeg {dir}/*.webp {dir}/*.PNG {dir}/*.JPG {dir}/*.JPEG {dir}/*.WEBP 2>/dev/null
```

Collect all matching files. If zero files match: STOP and report:
```
Error: No screenshots found in directory: {dir}
Expected .png, .jpg, .jpeg, or .webp files.
```

**If the remaining tokens are individual paths:**

For each path, validate the extension is one of `.png`, `.jpg`, `.jpeg`, `.webp` (case-insensitive).

**For every screenshot path (directory or individual), convert to absolute path and verify it exists:**

```bash
realpath "{path}" 2>/dev/null && test -f "$(realpath "{path}")" && echo "EXISTS" || echo "MISSING: {path}"
```

Collect:
- `valid_paths`: absolute paths where the file exists
- `invalid_paths`: paths that are missing or have wrong extension

If `valid_paths` is empty: STOP and report all `invalid_paths` with clear error messages.

Display to user:
```
Found {N} screenshots: {basename1}, {basename2}, ...
```

---

## Step 3: Project Name Resolution

**If `--name` was provided:** Use it directly.
- Validate: lowercase, letters and hyphens only, 3-30 characters, no leading/trailing hyphens.
- If invalid: STOP and report: `Error: --name "{value}" is invalid. Use lowercase letters and hyphens only, 3-30 characters.`

**If `--name` was NOT provided**, auto-derive using this priority:

**Priority 1 — Common parent directory:**
Extract the parent directory basename of all `valid_paths`. If all screenshots share the same parent directory AND the basename is not one of the generic names (`screenshots`, `images`, `benchmarks`, `assets`, `Desktop`, `Downloads`, `tmp`, `temp`):

```bash
dirname "{first_valid_path}" | xargs basename | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//'
```

**Priority 2 — Common filename prefix:**
Extract basenames without extensions. Find the longest common prefix of at least 3 characters that ends before a separator (`-` or `_`).

**Priority 3 — Date fallback:**
```bash
date +design-system-%Y-%m-%d
```

Apply name format rules: lowercase, letters and hyphens only, 3-30 chars, trim leading/trailing hyphens.

---

## Step 4: Platform Selection

Display this prompt to the user and wait for their response:

```
Which platforms should I generate?

1. React / Tailwind
2. SwiftUI
3. Both

Type 1, 2, or 3:
```

Map the response:
- `1` → `platforms: ["react"]`
- `2` → `platforms: ["swiftui"]`
- `3` → `platforms: ["react", "swiftui"]`

If the response is not 1, 2, or 3: ask again.

---

## Step 5: Confirmation

Check whether `.dsys/{name}/` already exists:

```bash
[ -d ".dsys/{name}" ] && echo "EXISTS" || echo "NEW"
```

Display this confirmation message and wait for user response:

```
Ready to generate design system:

  Project:     {name}
  Screenshots: {N} ({basename1}, {basename2}, ...)
  Platforms:   {platform_list}
  Output:      .dsys/{name}/

  {if EXISTS: "WARNING: Will overwrite existing output in .dsys/{name}/"}

Proceed? (yes/no)
```

If the user responds with anything other than `yes`, `y`, or `proceed`: STOP with message `Aborted. No files were written.`

---

## Step 5b: Initialize State File

After confirmation, write the initial state file to track pipeline progress:

```bash
mkdir -p .dsys/{name}/findings/
```

Write `.dsys/{name}/.state.json` with the following content:

```json
{
  "version": 1,
  "name": "{name}",
  "created_at": "{ISO 8601 timestamp}",
  "screenshots": [{valid_paths as quoted strings}],
  "platforms": [{platforms as quoted strings}],
  "stages": {
    "analyze": {
      "status": "in_progress",
      "started_at": "{ISO 8601 timestamp}",
      "completed_at": null,
      "findings": [],
      "errors": []
    },
    "synthesize": {
      "status": "pending",
      "started_at": null,
      "completed_at": null,
      "design_system_path": null,
      "errors": []
    },
    "build": {
      "status": "pending",
      "started_at": null,
      "completed_at": null,
      "errors": []
    }
  }
}
```

Generate the ISO 8601 timestamp:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

---

## Step 6: Stage 1 — Parallel Analysis

Display banner:
```
---
## Analyzing {N} screenshots in parallel...

Launching {N} analyzer agents simultaneously. This may take 30-60 seconds per screenshot.
---
```

Create the output directory:
```bash
mkdir -p .dsys/{name}/findings/
```

**CRITICAL: Issue ALL analyzer Task calls in a SINGLE response turn. Do NOT issue one Task and wait for its result before issuing the next. All N Task calls must appear in the same response for parallel execution.**

For each path in `valid_paths`, issue a Task call with this exact format:

```
Task(
  agent: "skills/dsys/agents/analyzer.md",
  prompt: "image_path: {absolute_path}
output_path: .dsys/{name}/findings/{basename_without_extension}.json"
)
```

Where `{basename_without_extension}` is the filename without its extension (e.g., `hero.png` → `hero`).

Issue ALL Task calls now, before collecting any result.

Example — if there are 3 screenshots, the response issues exactly 3 Task calls simultaneously:

```
Task 1: agent=skills/dsys/agents/analyzer.md
  image_path: /abs/path/to/hero.png
  output_path: .dsys/luxora/findings/hero.json

Task 2: agent=skills/dsys/agents/analyzer.md
  image_path: /abs/path/to/dashboard.png
  output_path: .dsys/luxora/findings/dashboard.json

Task 3: agent=skills/dsys/agents/analyzer.md
  image_path: /abs/path/to/card.png
  output_path: .dsys/luxora/findings/card.json
```

After all Tasks complete, collect each Task's return string.

---

## Step 7: Analysis Results and Partial Failure Handling

Categorize each Task result:
- **Success:** return string does NOT start with `Error:` (capital E, colon)
- **Failure:** return string starts with `Error:` (capital E, colon)

Build `successful_findings`: list of `.dsys/{name}/findings/{basename}.json` paths for each successful Task.
Build `failed_screenshots`: list of screenshot basenames + error messages for each failed Task.

**If ALL failed:** STOP immediately. Display:
```
All {N} screenshots failed analysis:
  - {basename1}: {error1}
  - {basename2}: {error2}
  ...

Partial output may exist in .dsys/{name}/findings/ for debugging.
```

**If SOME failed (but not all):** Display and wait for user response:
```
{fail_count} of {total} screenshots failed analysis:
  - {failed_basename1}: {error_message1}
  ...

{success_count} succeeded. Continue with successful results, or abort?
Type 'continue' to proceed or 'abort' to stop:
```

- If `continue`: proceed with only `successful_findings`.
- If `abort`: STOP with message listing the successful findings paths that were written to disk.

**If ALL succeeded:** Continue immediately.

---

## Step 8: Schema Validation — Findings

For each path in `successful_findings`, run:

```bash
RESULT=$(npx ajv-cli validate --spec=draft2020 \
  -s skills/dsys/schemas/analysis-findings.schema.json \
  -d "{findings_path}" 2>&1)
if echo "$RESULT" | grep -qi "valid"; then
  echo "VALID"
else
  echo "INVALID: $RESULT"
fi
```

- If output is `VALID`: keep in `successful_findings`.
- If output starts with `INVALID`: remove from `successful_findings` and add to `schema_failures` with the path and error output.

If `schema_failures` is non-empty: apply the same partial-failure logic from Step 7 (if all failed, stop; if some failed, prompt user to continue or abort with only the valid findings).

If `successful_findings` is now empty after validation: STOP.

---

## Step 8b: Update State — Analysis Complete

Read `.dsys/{name}/.state.json`, update the `stages.analyze` section:

```json
{
  "status": "completed",
  "completed_at": "{ISO 8601 timestamp}",
  "findings": ["{list of successful_findings paths}"],
  "errors": ["{list of any failed basenames, empty if all succeeded}"]
}
```

Write the updated state file back to `.dsys/{name}/.state.json`.

---

## Step 9: Review Pause (conditional)

**Only if `--review` flag was set:**

Display:
```
---
## Analysis complete — review mode

{N} findings written to .dsys/{name}/findings/:
  - .dsys/{name}/findings/{file1}.json
  - .dsys/{name}/findings/{file2}.json
  ...

Review the findings files, then type 'proceed' to continue with synthesis.
---
```

List all paths in `successful_findings` explicitly in this message so they are available in the next turn's context.

Wait for user to type `proceed` (or similar affirmative). Do not continue until they confirm.

---

## Step 10: Stage 2 — Synthesis

Display banner:
```
---
## Synthesizing design tokens from {N} findings...

Merging findings into a unified design system.
---
```

Build the findings paths as a JSON array string:
```
["path1.json", "path2.json", ...]
```

Issue a single Task:

```
Task(
  agent: "skills/dsys/agents/synthesizer.md",
  prompt: "findings_paths: [{comma-separated quoted absolute paths}]
output_path: .dsys/{name}/design-system.json"
)
```

If the result starts with `Error:`: STOP and report:
```
Synthesis failed: {error_message}

Findings files are preserved in .dsys/{name}/findings/ for debugging.
You may re-run with the same --name flag to retry from scratch.
```

---

## Step 11: Schema Validation — Design System

Run:

```bash
RESULT=$(npx ajv-cli validate --spec=draft2020 \
  -s skills/dsys/schemas/design-system.schema.json \
  -d ".dsys/{name}/design-system.json" 2>&1)
if echo "$RESULT" | grep -qi "valid"; then
  echo "VALID"
else
  echo "INVALID: $RESULT"
fi
```

If output starts with `INVALID`: STOP and report:
```
Schema validation failed for design-system.json.
Error: {first line of validation error from ajv output}
Intermediate files are in .dsys/{name}/ for debugging.
```

---

## Step 11b: Update State — Synthesis Complete

Read `.dsys/{name}/.state.json`, update the `stages.synthesize` section:

```json
{
  "status": "completed",
  "completed_at": "{ISO 8601 timestamp}",
  "design_system_path": ".dsys/{name}/design-system.json",
  "errors": []
}
```

Write the updated state file back to `.dsys/{name}/.state.json`.

---

## Step 12: Stage 3 — Platform Generation

Display banner:
```
---
## Generating {platform_list} files...
---
```

**CRITICAL: If BOTH platforms are selected, issue BOTH generator Task calls in a SINGLE response turn for parallel execution. Do not issue one and wait — issue both simultaneously.**

**React Task (if "react" is in platforms):**
```
Task(
  agent: "skills/dsys/agents/react-generator.md",
  prompt: "design_system_path: .dsys/{name}/design-system.json
output_root: .dsys/{name}/react/src/design-system/
platforms: [\"react\"]"
)
```

**SwiftUI Task (if "swiftui" is in platforms):**
```
Task(
  agent: "skills/dsys/agents/swiftui-generator.md",
  prompt: "design_system_path: .dsys/{name}/design-system.json
output_root: .dsys/{name}/swiftui/Sources/DesignSystem/
platforms: [\"swiftui\"]"
)
```

Check each result for `Error:` prefix. If any generator fails: STOP and report which platform failed. Note that `design-system.json` and findings persist in `.dsys/{name}/` for debugging.

---

## Step 13: Stage 4 — Rules and Style Guide

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

If the result contains `Error:`: STOP and report.

---

## Step 14: Visual Preview

Read `.dsys/{name}/design-system.json` and generate a self-contained HTML preview at `.dsys/{name}/preview.html` based on the reference template at `skills/dsys/references/preview-template.html`.

**Process:**
1. Read the template file: `skills/dsys/references/preview-template.html`
2. Read the design-system.json
3. Replace all `{{placeholder}}` tokens in the template with actual values from design-system.json
4. Write the result to `.dsys/{name}/preview.html`

**Placeholder mapping** (every `{{placeholder}}` in the template must be replaced):

Colors — substitute hex values:
- `{{action.primary.light}}` → `tokens.color.semantic.action.primary.$value.light`
- `{{action.primary.dark}}` → `tokens.color.semantic.action.primary.$value.dark`
- `{{action.secondary.light}}` → `tokens.color.semantic.action.secondary.$value.light`
- `{{action.secondary.dark}}` → `tokens.color.semantic.action.secondary.$value.dark`
- `{{action.destructive.light}}` → `tokens.color.semantic.action.destructive.$value.light`
- `{{action.destructive.dark}}` → `tokens.color.semantic.action.destructive.$value.dark`
- `{{surface.default.light}}` → `tokens.color.semantic.surface.default.$value.light`
- `{{surface.default.dark}}` → `tokens.color.semantic.surface.default.$value.dark`
- `{{surface.raised.light}}` → `tokens.color.semantic.surface.raised.$value.light`
- `{{surface.raised.dark}}` → `tokens.color.semantic.surface.raised.$value.dark`
- `{{surface.overlay.light}}` → `tokens.color.semantic.surface.overlay.$value.light`
- `{{surface.overlay.dark}}` → `tokens.color.semantic.surface.overlay.$value.dark`
- `{{surface.inset.light}}` → `tokens.color.semantic.surface.inset.$value.light`
- `{{surface.inset.dark}}` → `tokens.color.semantic.surface.inset.$value.dark`
- `{{text.primary.light}}` → `tokens.color.semantic.text.primary.$value.light`
- `{{text.primary.dark}}` → `tokens.color.semantic.text.primary.$value.dark`
- `{{text.secondary.light}}` → `tokens.color.semantic.text.secondary.$value.light`
- `{{text.secondary.dark}}` → `tokens.color.semantic.text.secondary.$value.dark`
- `{{text.muted.light}}` → `tokens.color.semantic.text.muted.$value.light`
- `{{text.muted.dark}}` → `tokens.color.semantic.text.muted.$value.dark`
- `{{text.inverse}}` → `tokens.color.semantic.text.inverse.$value`
- `{{text.link.light}}` → `tokens.color.semantic.text.link.$value.light`
- `{{text.link.dark}}` → `tokens.color.semantic.text.link.$value.dark`
- `{{border.default.light}}` → `tokens.color.semantic.border.default.$value.light`
- `{{border.default.dark}}` → `tokens.color.semantic.border.default.$value.dark`
- `{{border.focus.light}}` → `tokens.color.semantic.border.focus.$value.light`
- `{{border.focus.dark}}` → `tokens.color.semantic.border.focus.$value.dark`
- `{{feedback.success.light}}` → `tokens.color.semantic.feedback.success.$value.light`
- `{{feedback.success.dark}}` → `tokens.color.semantic.feedback.success.$value.dark`
- `{{feedback.error.light}}` → `tokens.color.semantic.feedback.error.$value.light`
- `{{feedback.error.dark}}` → `tokens.color.semantic.feedback.error.$value.dark`
- `{{feedback.warning.light}}` → `tokens.color.semantic.feedback.warning.$value.light`
- `{{feedback.warning.dark}}` → `tokens.color.semantic.feedback.warning.$value.dark`
- `{{feedback.info.light}}` → `tokens.color.semantic.feedback.info.$value.light`
- `{{feedback.info.dark}}` → `tokens.color.semantic.feedback.info.$value.dark`

Typography:
- `{{font.sans}}` → `tokens.typography.font_family.sans.$value`
- `{{font.sans.google}}` → URL-encoded version for Google Fonts import (e.g., `DM+Sans`, `Satoshi`)
- `{{font.fallback}}` → joined `fallback_stack` string (e.g., `-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif`)
- `{{type.xs}}` through `{{type.5xl}}` → `tokens.typography.scale.{size}.$value`
- `{{weight.regular}}` through `{{weight.bold}}` → `tokens.typography.weight.{name}.$value`
- `{{lh.tight}}` through `{{lh.loose}}` → `tokens.typography.line_height.{name}.$value`

Spacing:
- `{{space.1}}` through `{{space.32}}` → `tokens.spacing.scale.{n}.$value`

Border radius:
- `{{radius.sm}}` → `tokens.border_radius.sm.$value`
- `{{radius.md}}` → `tokens.border_radius.md.$value`
- `{{radius.lg}}` → `tokens.border_radius.lg.$value`
- `{{radius.full}}` → `tokens.border_radius.full.$value` (use `9999px` if value is `"9999px"`)

Shadows:
- `{{shadow.sm}}` → first shadow `$value` formatted as CSS (e.g., `0 2px 8px 0 rgba(0,0,0,0.06)`)
- `{{shadow.md}}` → second shadow if exists, otherwise same as sm

Meta:
- `{{project.name}}` → the project name
- `{{aesthetic.summary}}` → `aesthetic.summary`
- `{{aesthetic.tone}}` → `aesthetic.tone`
- `{{aesthetic.density}}` → `aesthetic.density`
- `{{generated.date}}` → current date in YYYY-MM-DD format

**Dynamic content markers** (replace these markers with generated HTML):

- `<!-- PERSONALITY_TAGS -->` → one `<span class="tag">` per entry in `aesthetic.personality_tags`
- `<!-- PALETTE_COLORS -->` → for each primitive color group in `tokens.color.primitive`, emit an `<h3>` with the group name and a `.color-grid` div containing one `.color-swatch` per shade
- `<!-- SEMANTIC_COLORS -->` → for each semantic group (Action, Surface, Text, Border, Feedback), emit an `<h3>` and `.semantic-group` div containing `.semantic-row` entries with Light/Dark swatch pairs. Follow the exact HTML structure in the template's Section 3 pattern.

**Border-radius to component mapping** (already encoded in the template CSS):
- **Buttons:** `{{radius.full}}` — pill-shaped when the design system includes a `full` token
- **Cards:** `{{radius.lg}}` — large rounded containers
- **Badges:** `{{radius.full}}` — always pill-shaped
- **Inputs:** `{{radius.md}}` — moderate rounding
- **Color swatches:** `{{radius.sm}}` — subtle rounding
- **Section containers (component-group):** `{{radius.lg}}`

After writing the file, open it:
```bash
open .dsys/{name}/preview.html
```

Display:
```
Visual preview opened in browser: .dsys/{name}/preview.html
```

---

## Step 15: End-of-Run Summary

Read the actual file listing from disk:
```bash
ls -R .dsys/{name}/
```

Read `.dsys/{name}/design-system.json` to extract preview values:
- Primary color: `tokens.color.semantic.action.primary.$value.light`
- Surface color: `tokens.color.semantic.surface.default.$value.light`
- Font family: `tokens.typography.font_family.sans.$value`

Display:

```
---
## dsys:generate complete — {name}

### Findings
  .dsys/{name}/findings/{file1}.json
  .dsys/{name}/findings/{file2}.json
  ...

### Design System
  .dsys/{name}/design-system.json

### React / Tailwind {only if react was selected}
  {list all files generated in .dsys/{name}/react/}

### SwiftUI {only if swiftui was selected}
  {list all files generated in .dsys/{name}/swiftui/}

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

Use the actual `ls` output for the file list — do not hardcode paths. Extract preview values by reading the JSON file.

---

## Step 15b: Update State — Build Complete

Read `.dsys/{name}/.state.json`, update the `stages.build` section:

```json
{
  "status": "completed",
  "completed_at": "{ISO 8601 timestamp}",
  "errors": []
}
```

Write the updated state file back to `.dsys/{name}/.state.json`.

---

## Error Recovery Reference

| Stage | Failure type | Action |
|---|---|---|
| Screenshot validation | File missing or wrong extension | STOP — list all invalid paths |
| Analysis | All agents fail | STOP — list all errors |
| Analysis | Some agents fail | Ask user: continue or abort |
| Schema validation (findings) | One or more invalid | Treat as analysis failures — partial failure logic |
| Schema validation (findings) | All invalid | STOP |
| Synthesis | Agent error | STOP — findings preserved |
| Schema validation (design-system) | Invalid | STOP — intermediate files preserved |
| Generation | Agent error | STOP — design-system.json preserved |
| Rules | Agent error | STOP — platform files preserved |

**Do NOT clean up intermediate files on failure.** Partial output in `.dsys/{name}/` is the user's debugging artifact.

---

## Locked Decisions

- CLAUDE.md is written to `.dsys/{name}/CLAUDE.md` — never to the project root.
- Output always goes under `.dsys/{name}/` — never to the project root or a flat directory.
- Schema validation is mandatory between every stage boundary.
- Intermediate files are never deleted on failure.
- Both generator Tasks are issued in a single response turn when both platforms are selected.
- All analyzer Task calls are issued in a single response turn regardless of N.
