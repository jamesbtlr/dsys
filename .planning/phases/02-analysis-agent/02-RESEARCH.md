# Phase 2: Analysis Agent - Research

**Researched:** 2026-02-17
**Domain:** Claude Code agent prompt engineering, vision extraction, Markdown agent file architecture
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Extraction boldness
- Preserve exact observed color values — do NOT snap to nearest standard. Let the synthesizer (Phase 3) decide on quantization
- Spacing and typography quantization: strict adherence to extraction rubric rules (4px grid, standard font weights). Colors are the exception
- Surface ambiguity when encountered — include alternative interpretations and reasoning so the synthesizer can make an informed choice
- Only extract colors that map to defined token categories in the schema. Ignore decorative/illustrative colors (gradients, illustration accents)
- When a screenshot shows mixed light/dark areas (e.g., dark sidebar + light content), treat as one theme with varied surface colors — not multiple themes

#### Screenshot expectations
- Accept any visual screenshot: app screens, marketing pages, landing pages, design mockups (Figma exports, etc.)
- Local file paths only — no URL fetching
- Automatically detect and exclude browser chrome, device frames, and OS status bars. Only analyze the app/site content
- Light/dark mode pair awareness: when two screenshots appear to be the same UI in different modes, recognize them as a pair and output combined findings

#### Partial results & errors
- Return partial results when some categories succeed but others fail. Better than nothing
- Omit missing categories from output JSON entirely — do not include null markers or reason strings for failed extractions
- Actionable one-liner error messages for input validation failures (e.g., "Unsupported format: .bmp (use PNG, JPG, or WebP)")
- When batch-analyzing multiple screenshots, continue with valid ones if some fail. Report failures separately

#### Findings detail
- Include brief rationale strings with major extractions (e.g., "Identified as primary action color: appears on all CTA buttons")
- Include a 1-2 sentence aesthetic summary per screenshot describing the overall visual style
- Do NOT include source screenshot metadata (dimensions, detected platform, device type)

### Claude's Discretion

- Semantic role assignment approach (bold assertions vs. conservative suggestions)
- Font identification strategy when typeface is unrecognizable (guess closest match vs. report unknown with traits)
- Whether to extract component-level patterns (button padding, card radius) as annotations alongside tokens
- Output file path strategy (write to .dsys/ directly vs. caller-controlled path)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INPUT-01 | User can feed one or more benchmark screenshots to the tool | Agent accepts a list of file paths; orchestrator calls one Task per image in parallel; each agent validates its own path before running vision |
| INPUT-02 | Tool validates image inputs and reports errors for unsupported or corrupt files | Agent prompt instructs validation of file path, extension check (PNG/JPG/WebP), and actionable one-liner error on failure; errors returned to orchestrator, not swallowed |
| INPUT-03 | Tool handles variable benchmark count (1 to ~7 images) | Fan-out Task pattern: orchestrator issues N Task calls in one response; Claude Code runtime handles parallelism automatically; no special handling needed for variable count |
| EXTRACT-01 | Tool extracts color palette with named primitive tokens from each benchmark | Rubric and schema from Phase 1 define exact structure; agent embeds fill-in JSON template from analysis-findings-schema.md; vision analysis fills values |
| EXTRACT-02 | Tool extracts typography tokens (font family, weight, size scale, line-height) from each benchmark | Rubric defines font_families, type_scale (snapped to standard scale), weight_usage, line_height_pattern; agent fills schema template |
| EXTRACT-03 | Tool extracts spacing scale from observed whitespace in each benchmark | Rubric defines spacing.scale (snapped to 4px grid), base_unit, density; quantization table in rubric section 4 is authoritative |
| EXTRACT-04 | Tool generates semantic aliases (primary, secondary, danger, success, muted) mapped to primitive tokens | 21 semantic color keys in analysis-findings.schema.json; agent assigns hex to each key or null; rationale strings required per locked decision |
| EXTRACT-05 | Tool reasons about design intent, not raw pixel values (quantizes colors to standard values, snaps spacing to grid) | Rubric section 4 quantization tables cover spacing (4px grid), type scale, border radius; colors: preserve exact hex, infer design-intent palette (not pixel rounding) |
| ORCH-02 | Parallel sub-agents analyze benchmarks independently (one agent per image) | Fan-out Task pattern; orchestrator issues all Task(analyzer, image_N) calls in the same response turn; Claude Code runtime executes in parallel |
</phase_requirements>

---

## Summary

Phase 2 builds one Markdown file: `skills/dsys/agents/analyzer.md`. This is the per-image vision extraction agent that produces a schema-conformant `analysis-findings.json` for each input screenshot. Phase 1 already defined every contract this agent must satisfy — the extraction rubric, the fill-in JSON template, and the JSON Schema 2020-12 file. Phase 2's job is to write a prompt that uses those contracts correctly.

The agent architecture is pure Markdown: the agent file embeds the rubric and fill-in template from Phase 1 directly as prompt context, instructs Claude to analyze the provided image using the Read tool, fills in the template, and writes the result to disk. No compiled code, no library installation, no build step. The orchestrator (Phase 6) issues parallel Task calls — one per image — and Claude Code's runtime handles fan-out automatically.

The primary risk is prompt quality for vision extraction. Two concrete failure modes are well-documented from Phase 1 project research: (1) pixel-measurement mode — reporting raw observed values instead of inferring design intent; and (2) fabrication mode — hallucinating values when the image is low-resolution or ambiguous. Both are mitigated by rubric structure (explicit quantization tables, explicit confidence levels, explicit null instructions for unobservable values) and by test validation against known design systems with expected output defined in advance.

**Primary recommendation:** Write the analyzer agent prompt so it embeds the Phase 1 rubric and fill-in template verbatim, adds a structured validation pass after filling the template, and writes the output file before returning. Test against three fixture types: a high-resolution UI screenshot of a known design system (e.g., Linear or Vercel), a low-resolution/blurry screenshot, and a non-UI visual reference (mood board photo).

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code Read tool | Native | Image input: loads PNG/JPG/WebP from local paths into vision context | The only supported mechanism for local file vision in Claude Code; no external image processing needed |
| Claude Code Write tool | Native | Output: writes findings JSON to .dsys/findings/ | File-based intermediate representation for inspectability and downstream agent consumption |
| Claude Code Task tool | Native | Parallelism: orchestrator spawns one Task per image | Fan-out parallelism is automatic when multiple Tasks are issued in one response turn |
| analysis-rubric.md | Phase 1 | Extraction instructions embedded in agent prompt | Already written, reviewed, and tested in Phase 1; do not rewrite — embed directly |
| analysis-findings-schema.md | Phase 1 | Fill-in JSON template embedded in agent prompt | Already written with worked examples; agent fills values into the template |
| analysis-findings.schema.json | Phase 1 | Validation: ajv can verify output before synthesizer reads it | JSON Schema 2020-12; validated in Phase 1 against conformant and non-conformant fixtures |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ajv-cli (via npx) | 8.x | Optional: validate agent output against schema before synthesizer reads it | Use in a validation step between Phase 2 and Phase 3 if schema conformance errors surface during testing; Phase 1 confirmed it works via npx |
| Node.js | 23.x (installed) | Required by ajv-cli validation step | Already present; exceeds Style Dictionary v5's 22+ requirement |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Embedded rubric in prompt | Separate file loaded at runtime | Loading from disk adds complexity; rubric is stable (Phase 1 locked it), embedding avoids file-not-found failure modes |
| Write findings to .dsys/ directly | Return JSON string to orchestrator | String return loses the intermediate artifact; file write enables inspection and re-runs; file is the locked architecture pattern |
| One combined prompt for all images | One Task per image | Combined prompt grows with image count, risks context saturation; parallel Tasks scale independently |

**No installation required for Phase 2.** All dependencies are either Claude Code native tools or Phase 1 artifacts already on disk.

---

## Architecture Patterns

### Recommended File Structure

```
skills/dsys/
├── agents/
│   └── analyzer.md          # PHASE 2 DELIVERABLE — per-image vision extraction agent
├── references/
│   ├── analysis-rubric.md   # Phase 1 — embedded in analyzer.md prompt
│   ├── analysis-findings-schema.md  # Phase 1 — fill-in template embedded in analyzer.md
│   └── platform-specs/      # Phase 1 — not used by analysis agent
└── schemas/
    ├── analysis-findings.schema.json  # Phase 1 — used for optional validation step
    └── design-system.schema.json      # Phase 1 — not used by analysis agent

.dsys/
└── findings/
    ├── screenshot-1.json    # One findings file per image (written by analyzer)
    ├── screenshot-2.json
    └── screenshot-N.json
```

### Pattern 1: Agent Prompt Structure

**What:** The analyzer.md agent prompt is structured in five ordered sections: role declaration, input description, embedded rubric, embedded fill-in template, output instructions.

**When to use:** Always for agent files in this system. The Phase 1 architecture research established this as the canonical agent file anatomy.

**Structure:**

```markdown
# Analysis Agent

## Role
You are the dsys vision extraction agent. Your job is to analyze a single screenshot
and produce a schema-conformant findings JSON file.

## Input
You will receive:
- A file path to the screenshot to analyze
- The output path where you must write the findings JSON

## Extraction Rubric
[Paste analysis-rubric.md verbatim here]

## Output Template
Fill in the following JSON template with values extracted from the image.
Replace all placeholder values. Use null (not the string "null") for
unobservable fields. Do not add fields not in the template.

[Paste the ui_screenshot fill-in template from analysis-findings-schema.md here]
[Paste the visual_reference fill-in template from analysis-findings-schema.md here]

## Output Instructions
1. Classify the image as ui_screenshot or visual_reference (Rubric Section 1)
2. Fill the appropriate template with extracted values
3. Validate that all required fields are present and no placeholder values remain
4. Write the completed JSON to the output path using the Write tool
5. Return a one-line summary: "Analyzed [filename]: [image_type], confidence=[level]"
```

**Why this order matters:** Rubric before template means the agent has the extraction rules in working memory when it encounters the template to fill in. Output instructions after the template means the agent fills before it is told to write — preventing premature writes with incomplete data.

### Pattern 2: Fan-Out Parallelism (Orchestrator Side)

**What:** The orchestrator issues all analyzer Task calls in a single response turn. Claude Code's runtime executes them in parallel automatically.

**When to use:** Always for independent per-image analysis (ORCH-02 requirement).

**How the orchestrator invokes the analyzer:**

```
For each image path in the input list:
  Issue Task(
    agent: "skills/dsys/agents/analyzer.md",
    prompt: "Analyze this image:\n\nInput path: {image_path}\nOutput path: .dsys/findings/{basename}.json"
  )

Issue ALL Task calls in the same response. Do not wait between them.
```

**Critical rule:** All Task calls for the fan-out must be issued in the same response turn to run in parallel. If the orchestrator issues them one at a time across multiple turns, they run sequentially. Phase 6 (orchestrator) will handle this; Phase 2 only needs to produce a correct analyzer agent that works when called this way.

### Pattern 3: Input Validation Before Vision

**What:** The agent validates the file path before invoking vision. Validation is fast and cheap; vision is expensive. Catching bad inputs early produces better error messages.

**When to use:** Always, as the first step in the agent before reading the image.

**Validation sequence in the agent prompt:**

```
Before analyzing the image, verify the input:
1. Check that the file path is not empty
2. Check that the file extension is .png, .jpg, .jpeg, or .webp (case-insensitive)
   - If not: return error "Unsupported format: {ext} (use PNG, JPG, or WebP)" and stop
3. Use the Read tool to load the file
   - If the Read tool returns an error: return "File not found or unreadable: {path}" and stop
4. Proceed with analysis only if all checks pass
```

**Error format (locked decision):** Actionable one-liner. No stack traces, no multi-line explanations. The orchestrator collects these and reports them to the user after processing all images.

### Pattern 4: Partial Results on Category Failure

**What:** When extraction succeeds for some token categories but fails for others (e.g., colors extracted successfully but typography is unreadable), the agent returns partial results by omitting failed categories from the output JSON.

**When to use:** Always. The locked decision prohibits null markers for failed extractions.

**Locked decision implementation:**

The Phase 1 schema requires all root fields to be present, with null as the explicit "not found" representation. However, the locked decision for Phase 2 says to omit missing categories from output JSON. This creates a conflict with the Phase 1 schema.

**Resolution:** The agent should write null for fields it could not extract (which is the Phase 1 schema behavior). The locked decision's "omit" instruction applies at the user-facing level: the orchestrator should not report null-filled categories as successful extractions. The JSON itself follows the Phase 1 schema (all required fields present, null for not-found). Do not deviate from the Phase 1 schema — downstream agents (Phase 3 synthesizer) depend on it.

**Clarification to surface in planning:** Confirm with user whether "omit from output JSON" is literal (break schema conformance) or user-facing only (schema-conformant JSON with null, but null categories not reported as successes). Recommend: schema-conformant JSON with null; surface this distinction explicitly.

### Pattern 5: Rationale Strings

**What:** Major extractions include a brief rationale string explaining why a value was assigned. This is a locked decision from CONTEXT.md.

**When to use:** For semantic color assignments and any value where role inference required judgment.

**Schema impact:** The Phase 1 `analysis-findings.schema.json` does not have a rationale field. Rationale strings must be added to the schema or stored as a parallel structure.

**Implementation options:**

Option A — Extend the schema: Add an optional `rationale` object at the root level, keyed by semantic assignment key. This is the cleanest approach and keeps the JSON self-contained.

```json
{
  "image_type": "ui_screenshot",
  "colors": { ... },
  "rationale": {
    "action_primary": "Identified as primary action color: appears on all CTA buttons",
    "surface_default": "Page background: lightest surface visible in most of the UI"
  }
}
```

Option B — Inline rationale in each semantic assignment: Change the semantic assignment values from hex strings to `{value, rationale}` objects. This breaks the Phase 1 schema more significantly.

**Recommendation:** Option A. Add a top-level `rationale` optional object to the schema. The synthesizer can read it for context during conflict resolution. This requires a minor schema update (Phase 1 artifact modification) — document this as a deviation.

### Pattern 6: Light/Dark Pair Detection

**What:** When batch-analyzing multiple screenshots, if two images appear to be the same UI in light and dark mode, the agent recognizes them as a pair and notes this in its output.

**When to use:** When the orchestrator provides multiple screenshots (INPUT-03) and two of them share the same structural layout with inverted color schemes.

**Implementation:** The pair detection happens in the orchestrator (Phase 6), not in the per-image analyzer. Each analyzer independently reports `background_style: "light"` or `"dark"` and reports the semantic color assignments it observes. The orchestrator or synthesizer detects that two findings share structural similarity and marks them as a pair.

**Phase 2 scope:** The analyzer agent must accurately report `background_style` and must extract both observed colors and inferred opposite-theme colors. The pairing logic is not Phase 2's responsibility.

### Anti-Patterns to Avoid

- **Pixel-measurement mode:** Never report raw rendered pixel values. The rubric is explicit: infer design intent, not measured pixels. If spacing looks like 13px, snap to 12px. If a font looks like 15.4px, report 16px. The quantization tables in rubric section 4 are the authority.
- **Fabrication on ambiguous images:** When image quality is low, report confidence: "low" and set ambiguous fields to null. Do not invent plausible values. The schema permits null; fabrication is worse than absence.
- **String "null" instead of JSON null:** The fill-in template uses placeholder text like `"#RRGGBB or null"`. When filling in, use the JSON literal `null`, not the string `"null"`. This is a common LLM failure mode that will cause schema validation to fail.
- **Extra fields not in template:** The schema uses `additionalProperties: false` on all objects. Any field the agent adds that is not in the template will fail validation. The agent must fill in only what the template defines.
- **Analyzing browser chrome:** The rubric defines that browser toolbars, OS status bars, and device bezels must be excluded. The agent must identify and ignore these regions before extracting tokens.
- **Returning without writing:** The agent must write the JSON file to disk using the Write tool before returning its summary. If the agent returns a summary string but forgets to call Write, the orchestrator receives no findings file and the synthesizer has nothing to read.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Extraction rubric | New extraction instructions | Embed analysis-rubric.md verbatim | Phase 1 rubric is tested, complete, and locked; re-inventing it introduces drift |
| Output schema | New JSON structure | Embed analysis-findings-schema.md template verbatim | Phase 1 schema is validated; downstream agents depend on it exactly as defined |
| JSON Schema validation | Custom validation code | npx ajv-cli (already tested in Phase 1) | ajv-cli works against the Phase 1 schema files; Phase 1 confirmed it via live test |
| Parallelism | Thread management or polling | Claude Code Task tool fan-out | Task-level parallelism is built-in to Claude Code runtime; no code needed |
| Image loading | Base64 encoding or external libraries | Claude Code Read tool | Read tool supports PNG/JPG/WebP natively; no external vision library needed |

**Key insight:** Phase 2 is a prompt-writing phase, not a code-writing phase. The temptation to add validation code, a CLI wrapper, or a test harness is over-engineering. The only deliverable is `analyzer.md` — a Markdown file that is a well-structured agent prompt.

---

## Common Pitfalls

### Pitfall 1: Schema Template Drift

**What goes wrong:** The developer writes the analyzer agent prompt with an embedded JSON template that differs slightly from the Phase 1 `analysis-findings-schema.md` template. The agent produces output that is structurally different from what the Phase 1 schema validates. The synthesizer receives non-conformant JSON and fails.

**Why it happens:** Copy-paste errors, creative paraphrasing of field descriptions, or adding "helpful" fields.

**How to avoid:** Copy the fill-in template from `analysis-findings-schema.md` verbatim. Do not paraphrase, reorder, or extend it. The schema file at `skills/dsys/schemas/analysis-findings.schema.json` uses `additionalProperties: false` — any addition causes validation failure.

**Warning signs:** The agent prompt says "fill in JSON with the following structure" followed by a template that does not exactly match the one in `analysis-findings-schema.md`.

### Pitfall 2: Rationale Strings Conflict with Phase 1 Schema

**What goes wrong:** The locked decision requires rationale strings in the output. The Phase 1 schema has `additionalProperties: false` throughout. Adding a rationale field to the root object will fail JSON Schema validation.

**Why it happens:** The rationale requirement was decided after Phase 1's schema was written.

**How to avoid:** Add a top-level `rationale` field to the schema in `analysis-findings.schema.json` (Option A from Pattern 5 above). This is a minor, non-breaking addition — it is an optional object. Update both `analysis-findings.schema.json` and `analysis-findings-schema.md` in the same task to keep them in sync.

**Scope impact:** This task must modify Phase 1 schema artifacts. This is expected and acceptable — schemas are living documents. Document the change in the plan.

### Pitfall 3: Partial Results Break Schema Conformance

**What goes wrong:** The locked decision says to "omit missing categories from output JSON entirely." If taken literally, this produces JSON missing required root fields (`typography`, `spacing`, etc.), which fails the Phase 1 schema validation with `required` array violations. The synthesizer cannot read non-conformant findings.

**Why it happens:** The CONTEXT.md uses "omit" to mean "don't expose failures as successes to the user," but the JSON schema requires all root fields.

**How to avoid:** Keep the JSON schema-conformant: use null for unextractable fields (which is the Phase 1 schema's `"type": ["object", "null"]` pattern). Surface partial failure status through a separate field or through the agent's text return string (not in the JSON structure itself). The orchestrator collects the text returns and reports partial failures to the user.

**Recommendation:** Add a `partial_failure` optional boolean or a `failed_categories` optional string array to the schema. This communicates partial results without omitting required fields.

### Pitfall 4: String "null" Instead of JSON null

**What goes wrong:** The fill-in template uses placeholder text like `"FontName or null"` for font family values. When the agent cannot identify a font, it writes the string `"null"` (a valid JSON string) instead of the JSON literal `null`. The schema allows `"type": ["string", "null"]` — the string `"null"` passes type validation but is semantically incorrect and will cause downstream agents to see `"null"` as a font name.

**Why it happens:** LLMs frequently confuse JSON null with the string "null" when filling templates.

**How to avoid:** Add an explicit instruction in the agent prompt: "Use the JSON literal null (no quotes) for absent values. Never write the string \"null\"." Include a worked example showing both wrong and right representations.

**Warning signs:** The output JSON contains values like `"sans": "null"` or `"display": "null"`.

### Pitfall 5: Missing Write Call

**What goes wrong:** The agent successfully extracts and fills the template, returns a summary string to the orchestrator, but never calls the Write tool to write the JSON file to disk. The orchestrator receives a success summary but the findings file does not exist. The synthesizer reads no input.

**Why it happens:** The agent may treat returning a summary as task completion without recognizing that the Write call is also required.

**How to avoid:** Structure the output instructions to make Write the explicit penultimate step: "4. Write the completed JSON to the output path. 5. Return the summary string only after Write succeeds." Verify in testing by checking that the `.dsys/findings/` file exists after the agent runs.

**Warning signs:** The agent returns "Analyzed screenshot-1.png: ui_screenshot, confidence=high" but no `screenshot-1.json` appears in `.dsys/findings/`.

### Pitfall 6: Browser Chrome Included in Extraction

**What goes wrong:** A screenshot of a web app includes browser navigation (address bar, tabs, bookmarks bar). The agent extracts the browser's gray address bar as a surface color, the browser's blue URL text as a link color, and the tab strip as a navigation element. All of these values are browser chrome, not the app's design system.

**Why it happens:** The rubric says to exclude browser chrome, but without an explicit first-pass step to identify and mentally crop the chrome region, LLMs may extract from the full image.

**How to avoid:** Add an explicit first instruction in the agent prompt: "Before extracting any values, identify and exclude: (1) browser toolbars, address bars, or bookmarks bars at the top or bottom; (2) OS status bars (time, battery, signal) at the top or bottom of mobile screenshots; (3) device bezels or frames around the screen content. Only analyze the app/site content within these boundaries."

### Pitfall 7: Decorative Color Contamination

**What goes wrong:** A marketing landing page has hero illustrations with a rich gradient of colors (purples, pinks, oranges). The agent includes these illustration accent colors in the primitive palette and assigns them to semantic roles (`action_primary`, `accent`). The downstream design system includes garish illustration palette colors as interactive element colors.

**Why it happens:** The rubric says to "infer design intent," but illustrations are easy to confuse with intentional design system colors.

**How to avoid:** The locked decision is clear: "Only extract colors that map to defined token categories in the schema. Ignore decorative/illustrative colors (gradients, illustration accents)." Add an explicit instruction in the agent prompt: "Do not extract colors that appear only in illustrations, hero images, gradient backgrounds, or decorative graphical elements. Extract only colors used in functional UI elements: buttons, text, backgrounds, borders, icons."

---

## Code Examples

### Analyzer Agent Prompt Skeleton

```markdown
# dsys Analysis Agent

## Role

You are the dsys visual extraction agent. You analyze one screenshot and produce
a schema-conformant analysis findings JSON file. You are one of N agents running
in parallel — each handles a single image.

## Input

You will receive two values in your task prompt:
- `image_path`: The local file path to the screenshot
- `output_path`: Where to write the findings JSON

## Step 1: Validate Input

Before doing anything else:
1. Check that `image_path` ends in .png, .jpg, .jpeg, or .webp (case-insensitive).
   If not: STOP and return: "Error: Unsupported format: {ext} (use PNG, JPG, or WebP)"
2. Use the Read tool to load the file at `image_path`.
   If Read fails: STOP and return: "Error: File not found or unreadable: {image_path}"

## Step 2: Pre-Analysis — Identify Content Boundary

Before extracting tokens, identify what to exclude:
- Browser toolbars, address bars, bookmarks bars (top/bottom of browser screenshots)
- OS status bars showing time/battery/signal (top of mobile screenshots)
- Device bezels, frames, or mock-up overlays around the screen content
Only analyze the app or site content within these boundaries.

## Step 3: Classify the Image

Classify the image as `ui_screenshot` or `visual_reference` using the rules in the
Extraction Rubric Section 1 below. When ambiguous, classify as `visual_reference`.

## Step 4: Extract Values

Follow the Extraction Rubric for your image type. Apply quantization rules exactly
as specified in Rubric Section 4.

Color-specific rules:
- Do NOT snap hex values to nearest standard. Preserve exact observed color values.
- Only extract colors that appear on functional UI elements (buttons, text, backgrounds,
  borders). Ignore colors in illustrations, gradients, or decorative graphics.
- When the screenshot shows mixed light/dark areas (dark sidebar + light content),
  treat as one theme with varied surface colors — not multiple themes.

Rationale requirement:
- For each semantic color assignment, include a brief rationale string explaining
  why you assigned this role (e.g., "Appears on all CTA buttons and primary links").
- Store rationales in a top-level `rationale` object keyed by semantic key name.

## Step 5: Fill the Output Template

Fill the appropriate template below with your extracted values.

IMPORTANT RULES:
- Use the JSON literal null (no quotes) for absent or unobservable values.
  WRONG: "sans": "null"    RIGHT: "sans": null
- Do not add fields not in the template (additionalProperties: false is enforced).
- Do not leave placeholder text (no #RRGGBB, no "FontName or null").

[EMBED ANALYSIS-FINDINGS-SCHEMA.MD FILL-IN TEMPLATE HERE — ui_screenshot template]

[EMBED ANALYSIS-FINDINGS-SCHEMA.MD FILL-IN TEMPLATE HERE — visual_reference template]

## Step 6: Write Output

Write the completed JSON to `output_path` using the Write tool.
Do not return until Write has completed successfully.

## Step 7: Return Summary

Return exactly one line:
"Analyzed {filename}: {image_type}, confidence={level}, {N} colors extracted"

## Extraction Rubric

[EMBED ANALYSIS-RUBRIC.MD VERBATIM HERE]
```

### Output Path Convention

The orchestrator determines output paths and passes them to each analyzer:

```
Output path pattern: .dsys/findings/{input_basename_without_ext}.json

Examples:
  Input:  benchmarks/linear-dashboard.png
  Output: .dsys/findings/linear-dashboard.json

  Input:  /Users/james/Desktop/vercel-screenshot.jpg
  Output: .dsys/findings/vercel-screenshot.json
```

### Schema Extension for Rationale (Option A)

Add to `analysis-findings.schema.json`:

```json
"rationale": {
  "type": "object",
  "description": "Optional: brief rationale strings for major semantic assignments, keyed by semantic key name.",
  "additionalProperties": { "type": "string" }
}
```

This is an optional field (not added to `required`), so existing schema-conformant documents without it remain valid.

### Partial Results Field

Add to `analysis-findings.schema.json`:

```json
"partial_failure": {
  "type": "boolean",
  "description": "true if some token categories could not be extracted and were set to null. false or absent if all categories were successfully extracted."
},
"failed_categories": {
  "type": "array",
  "items": { "type": "string" },
  "description": "Names of token categories that could not be extracted (e.g., ['typography', 'shadows'])."
}
```

### ajv Validation Step (Optional, Post-Agent)

If schema conformance errors surface during testing:

```bash
# Validate a single findings file
npx ajv-cli validate \
  -s skills/dsys/schemas/analysis-findings.schema.json \
  -d .dsys/findings/screenshot-1.json

# Validate all findings files
npx ajv-cli validate \
  -s skills/dsys/schemas/analysis-findings.schema.json \
  -d ".dsys/findings/*.json"
```

Phase 1 confirmed this works with ajv 8.x via npx.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate agent file per image type | Single agent with image_type conditional behavior | Phase 1 schema design | One agent file handles both ui_screenshot and visual_reference; image_type branch is internal |
| Prose description of output schema | Embedded fill-in JSON template | Phase 1 architectural decision | LLMs fill templates more reliably than they construct schemas from prose; structural conformance rate is higher |
| Custom validation logic | Phase 1 JSON Schema + ajv-cli via npx | Phase 1 validation testing | Schema is authoritative; no custom validation code; schema and validator are independently maintained |
| analysis-findings.schema.json with 21 semantic keys | Same schema, but with optional `rationale` and `partial_failure` fields added in Phase 2 | Phase 2 (this phase) | Rationale required by locked decision; partial failure required for clean error reporting |

**Deprecated/outdated:**

- Using the Phase 1 `analysis-findings.schema.json` without modification: Phase 2 must add `rationale` and `partial_failure` optional fields to satisfy locked decisions.

---

## Open Questions

1. **"Omit vs. null" for partial results**
   - What we know: CONTEXT.md says "omit missing categories from output JSON entirely." Phase 1 schema requires all root fields (with null as the not-found representation). These conflict.
   - What's unclear: Was "omit" intended literally (break schema) or figuratively (don't count null-filled categories as successes)?
   - Recommendation: Surface this in the plan. Propose schema-conformant null + new `failed_categories` array to report partial failure without breaking schema conformance. Get explicit confirmation before schema modification.

2. **Rationale strings: which extractions require them**
   - What we know: Locked decision says "include brief rationale strings with major extractions." Semantic color assignments are the primary case.
   - What's unclear: Does "major" include typography font identification? Spacing density classification? All fields, or just colors?
   - Recommendation: Require rationale for semantic color assignments (the highest-judgment step). Make rationale optional for other token categories. Document this scope decision in the plan.

3. **Semantic role assignment: bold vs. conservative**
   - What we know: This is a Claude's Discretion area. The rubric instructs bold inference ("Infer the design intent").
   - What's unclear: For ambiguous cases (e.g., a color that appears on both outline buttons and some text elements — is it action_secondary or border_default?), should the agent assert one role confidently or include both possibilities?
   - Recommendation: Assert boldly with rationale. The rationale string makes the choice auditable; the synthesizer can override. Conservative suggestions that leave key assignments null are less useful to the synthesizer.

4. **Font identification: unrecognizable typefaces**
   - What we know: This is a Claude's Discretion area. The rubric says to report the font family name or null if not identifiable.
   - What's unclear: Should the agent guess the closest known typeface ("looks like Inter but with slightly wider tracking — possibly Geist") or report null with descriptive traits ("geometric sans-serif, tight letter-spacing, similar to Inter")?
   - Recommendation: Report the best guess with a qualifier in the rationale string: `"sans": "Inter"` with rationale `"Strong resemblance to Inter; geometric sans, consistent weight, tight tracking. Could be Geist or Neue Haas Grotesk."` This gives the synthesizer more to work with than null.

5. **Component-level pattern extraction**
   - What we know: This is a Claude's Discretion area — "whether to extract component-level patterns (button padding, card radius) as annotations alongside tokens."
   - What's unclear: Component patterns would be valuable for Phase 4 generator quality but are not in the Phase 1 schema.
   - Recommendation: Defer component-level extraction to Phase 3 or Phase 4. The Phase 1 schema defines the contract; adding component patterns now would require schema modification and increase Phase 2 complexity without a Phase 3 consumer defined yet.

6. **Output file path strategy**
   - What we know: This is a Claude's Discretion area. Options: (A) agent writes directly to `.dsys/findings/`; (B) orchestrator passes the full output path to the agent.
   - Recommendation: Orchestrator-controlled path (Option B). The orchestrator knows the output directory; hardcoding `.dsys/` in the agent limits configurability and makes testing harder (test invocations cannot easily redirect output). The path is passed as a simple string parameter.

---

## Sources

### Primary (HIGH confidence)

- `skills/dsys/references/analysis-rubric.md` — Phase 1 deliverable: extraction instructions, quantization tables, image classification rules, semantic color taxonomy (21 keys). This is the authoritative extraction spec.
- `skills/dsys/references/analysis-findings-schema.md` — Phase 1 deliverable: field reference, fill-in templates for both image types, conditional field rules, two worked examples.
- `skills/dsys/schemas/analysis-findings.schema.json` — Phase 1 deliverable: JSON Schema 2020-12 with `additionalProperties: false`, hex pattern validation, allOf if/then conditional enforcement. Validated against conformant and non-conformant fixtures.
- `.planning/research/ARCHITECTURE.md` — Claude Code skill/agent architecture: Task tool fan-out, file-based intermediate representation, agent file anatomy.
- `.planning/phases/01-schema-contracts/01-01-SUMMARY.md` — Phase 1 execution record: decisions made, schema design rationale, 21 vs. 18 key count explanation.
- `.planning/phases/01-schema-contracts/01-VERIFICATION.md` — All 12 Phase 1 truths verified; schema validated against 4 fixture cases.

### Secondary (MEDIUM confidence)

- `.planning/research/SUMMARY.md` — Project-level research synthesis: stack decisions, architecture pattern, pitfall analysis for all phases.
- `.planning/research/PITFALLS.md` — Concrete failure modes: pixel measurement vs. design intent, fabrication on ambiguous images, schema drift across parallel agents.

### Tertiary (LOW confidence, validate during planning)

- CONTEXT.md "omit missing categories" interpretation — see Open Question 1 above.

---

## Metadata

**Confidence breakdown:**

- Agent file architecture: HIGH — established by Phase 1 and project architecture research; Task tool fan-out is a confirmed Claude Code pattern
- Phase 1 schema contracts: HIGH — validated artifacts on disk; schema tested with ajv-cli
- Prompt engineering for vision extraction: MEDIUM — rubric is well-specified, but LLM adherence to complex fill-in templates with null semantics requires empirical testing
- Rationale/partial-result schema extensions: MEDIUM — approach is sound but requires user confirmation on "omit" vs. "null" interpretation before implementing

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (schema artifacts are stable; Claude Code Task tool behavior is stable)
