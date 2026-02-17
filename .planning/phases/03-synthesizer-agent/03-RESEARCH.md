# Phase 3: Synthesizer Agent - Research

**Researched:** 2026-02-17
**Domain:** Claude Code agent prompt engineering, multi-source merge algorithms, conflict resolution, DTCG token construction
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Conflict Resolution
- Frequency-weighted: the value that appears in the most benchmarks wins
- Tiebreaker: most prominent usage (the value used for more elements/surface area in its benchmark)
- Quantize near-identical values before comparing (e.g., treat #1a73e8 and #1b74e9 as the same blue) to avoid false conflicts from rendering differences
- Conflict log: decision only (what was chosen, what was rejected) — no detailed reasoning

#### Aesthetic Identity
- Factual description tone, not opinionated narrative — neutral characterization of observed patterns
- Dominant approach captures both visual character traits (color temperature, contrast, density, roundness, whitespace) and design philosophy (minimalist vs rich, corporate vs playful, information-dense vs spacious)
- Structured fields in JSON for key aesthetic traits — machine-parseable, not free-text prose
- When benchmarks have mixed aesthetics: pick the dominant direction, don't blend

#### Token Merging
- Dominant set + extras: use the dominant benchmark's token set as the base, add distinctive tokens from others
- Spacing scale: enforce 4px grid — snap all spacing values to nearest 4px increment
- Semantic roles: include if found in any benchmark — completeness over consensus
- If a role like feedback_warning is only in one benchmark, it's still included

### Claude's Discretion
- Font family merging strategy (pick one vs preserve alternatives as fallbacks)
- Output file location (.dsys/ vs caller-specified path)
- Schema self-validation vs caller validation
- Exact quantization thresholds for near-identical value grouping

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SYNTH-01 | Tool synthesizes findings across multiple benchmarks into a coherent design system | Agent reads all `.dsys/findings/*.json` files, applies the merge algorithm documented in this research, and produces a single `design-system.json` conformant to `design-system.schema.json` |
| SYNTH-02 | Tool establishes a dominant aesthetic rather than averaging values across benchmarks | "Pick dominant, don't blend" is implemented by selecting the benchmark with the most ui_screenshot entries (or highest confidence) as the base, then augmenting — never interpolating colors or averaging enum values |
| SYNTH-03 | Tool resolves conflicts between benchmarks with deliberate choices | Frequency-weighted voting on quantized values, with explicit conflict_log entries for every resolved conflict. Quantization happens before comparison so rendering noise doesn't create false conflicts |
| ORCH-03 | Intermediate design-system.json written to disk between analysis and generation | Agent writes to caller-specified path (default: `.dsys/design-system.json`) using Write tool before returning |
</phase_requirements>

---

## Summary

Phase 3 builds one Markdown file: `skills/dsys/agents/synthesizer.md`. Like the analyzer agent, this is a pure prompt-engineering task — no compiled code, no installed libraries. The synthesizer reads N analysis findings JSON files (written by Phase 2 analyzers) and produces a single `design-system.json` conformant to the Phase 1 `design-system.schema.json`.

The primary algorithmic challenge is the merge and conflict-resolution logic, which must be embedded in the agent prompt as explicit, step-by-step instructions. The locked decisions establish a clear algorithm: quantize → vote → tiebreak → log. What makes this harder than the analyzer is that the synthesizer operates on structured data (JSON inputs) rather than visual input, so there is no vision step — the agent reads, reasons, and writes. The quality risk is not extraction accuracy but reasoning drift: the agent must follow the merge rules mechanically while also exercising judgment for aesthetic identity (SYNTH-02), which requires a different mode of reasoning.

The Phase 1 `design-system.schema.json` is complete and validated. The synthesizer's output template is fully defined. The synthesizer's job is to correctly fill the output template using values derived from N input findings files. The embedded fill-in template approach that proved effective in Phase 2 applies here too — the synthesizer prompt embeds the `token-schema.md` spec and the `design-system.schema.json` template, then instructs the agent to fill it following the merge algorithm.

**Primary recommendation:** Structure the synthesizer prompt as a sequence of numbered merge passes — one per token category — each with explicit rules. This prevents the agent from conflating merge decisions across categories and makes the conflict_log instructions concrete. Embed the merge algorithm as a decision table, not as prose.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code Read tool | Native | Load each `.dsys/findings/*.json` file into context | Same mechanism as analyzer agent; no external JSON parsing library needed |
| Claude Code Write tool | Native | Write `design-system.json` to disk | File-based intermediate representation for inspectability and downstream agent consumption (ORCH-03) |
| `design-system.schema.json` | Phase 1 artifact | Validation schema for output; embedded fill-in template | Already written, reviewed, and validated in Phase 1; do not rewrite |
| `token-schema.md` | Phase 1 artifact | Human-readable spec embedded in synthesizer prompt | Already written; defines every field in design-system.json with examples |
| `analysis-findings-schema.md` | Phase 1 artifact | Reference for input field structure | Already written; synthesizer needs to know the input shape to read it correctly |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ajv-cli (via npx) | 8.x | Optional: validate synthesizer output against `design-system.schema.json` before generators run | Use if schema conformance errors surface during testing; Phase 1 confirmed it works |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Embedded algorithm in agent prompt | External algorithm script (Node.js) | Script would require code, add complexity, break the "no compiled code" architecture decision. Agent prompt is sufficient because the merge algorithm is deterministic and the input count is bounded (~1-7 files) |
| Embedded fill-in template | Prose description of output | Phase 2 demonstrated prose descriptions produce structural drift; fill-in templates are the established pattern |
| Caller-specified output path | Hardcoded `.dsys/design-system.json` | Orchestrator-controlled path enables testing redirection and is consistent with the analyzer agent pattern |

**No installation required for Phase 3.** All dependencies are either Claude Code native tools or Phase 1/2 artifacts already on disk.

---

## Architecture Patterns

### Recommended File Structure

```
skills/dsys/
├── agents/
│   ├── analyzer.md       # Phase 2 — complete
│   └── synthesizer.md    # PHASE 3 DELIVERABLE
├── references/
│   ├── analysis-rubric.md          # Phase 1 — NOT needed in synthesizer
│   ├── analysis-findings-schema.md # Phase 1 — reference only (input shape)
│   ├── token-schema.md             # Phase 1 — EMBED in synthesizer prompt
│   └── platform-specs/             # Phase 1 — NOT needed in synthesizer
└── schemas/
    ├── analysis-findings.schema.json  # Phase 1 — input validation reference
    └── design-system.schema.json      # Phase 1 — output fill-in template

.dsys/
├── findings/
│   ├── screenshot-1.json   # Phase 2 outputs (synthesizer reads these)
│   └── screenshot-N.json
└── design-system.json      # PHASE 3 OUTPUT (synthesizer writes this)
```

### Pattern 1: Agent Prompt Structure (Established in Phase 2)

**What:** The synthesizer.md prompt follows the same anatomy as analyzer.md: role declaration, input description, embedded specs, algorithm (instead of rubric), output template, output instructions.

**When to use:** Always. Phase 2 established this as the canonical agent file anatomy for this system.

**Structure:**

```markdown
# dsys Synthesizer Agent

## Role
[What the agent is and what it produces]

## Input
[What files are read, what parameters are accepted]

## Merge Algorithm
[Step-by-step numbered passes — one per token category]
[Decision tables for conflict resolution]
[Quantization rules for color comparison]

## Output Template
[Embed design-system.json fill-in template from token-schema.md]

## Output Instructions
[Step-by-step: read, merge, fill, validate, write, return]
```

**Why this order matters:** Algorithm before template means the agent has the merge rules in working memory when it fills the template. This prevents the agent from reasoning about a token's value and the rules for deriving it at the same time.

### Pattern 2: Multi-Pass Merge Algorithm

**What:** Each token category is handled by a discrete, ordered pass. The agent completes each pass independently before moving to the next. This prevents reasoning contamination between categories (e.g., color decisions bleeding into spacing decisions).

**When to use:** Always. The merge algorithm has distinct rules per category — color uses frequency-weighted voting on quantized values, spacing enforces 4px grid, typography has a font-family merging decision.

**The seven passes:**

1. **Source validation pass** — Load and validate all findings files. Count `ui_screenshot` vs `visual_reference` sources. Identify the dominant benchmark (most `ui_screenshot` entries with highest confidence; if tie, use the one with the most non-null semantic assignments).
2. **Color primitive pass** — Collect all hex values from all findings `primitive_palette` arrays. Group by perceptual similarity (quantized to nearest 8 in hex space — see Quantization section below). Build the primitive palette from the dominant benchmark's palette, supplemented by distinct hues from others.
3. **Semantic color pass** — For each of the 21 semantic assignment keys, collect all non-null values across findings. Quantize hex values. Vote by frequency. Apply tiebreaker (analyzer prominence / rationale). Log conflicts where values differ after quantization. Build the semantic layer with `{light, dark}` $value objects.
4. **Typography pass** — Apply font family merge strategy (see Claude's Discretion section). Build `font_family`, `scale`, `weight`, `line_height` tokens from dominant benchmark, snapping type scale values to the standard type scale.
5. **Spacing pass** — Build spacing scale from dominant benchmark. Enforce 4px grid: snap all values to `ceil(value / 4) * 4`. Always produce the full required scale (steps 1–32).
6. **Non-color tokens pass** — Merge shadows, border_radius, opacity_scale using frequency-weighted voting. If any benchmark found a value, include it (completeness over consensus for semantic roles).
7. **Aesthetic pass** — Select the dominant benchmark's aesthetic as the base. Supplement personality_tags from others that contribute new terms. Select `density` and `tone` by frequency vote.

**Critical insight:** Passes 1-6 are mechanical (rules-driven). Pass 7 requires judgment. Structure the prompt so the agent completes all mechanical passes first and treats the aesthetic pass as a distinct reasoning step with explicit instructions.

### Pattern 3: Conflict Resolution Decision Table

**What:** Embed the conflict resolution algorithm as a decision table, not prose. Tables are more reliably followed by LLMs than prose paragraphs for algorithmic tasks.

**Decision table for any conflicting token:**

```
Given: K candidates (hex values) for a single semantic token, after quantization

Step 1: Group candidates by quantized value.
Step 2: Count group sizes.
Step 3: If one group is largest → that group's modal value wins.
Step 4: If tie → apply tiebreaker:
         - For each tied group, find the source benchmark it came from.
         - The group from the benchmark with the most semantic assignments wins.
           ("Most assignments" = fewest null values in semantic_assignments.)
         - If still tied → use the value from the dominant benchmark (Pass 1 result).
Step 5: Log in conflict_log:
         { "token": "{path}", "candidates": [all K values], "chosen": "{winner}", "rationale": "{N}/{K} benchmarks — majority vote" }
```

**When to log:** Log every token where quantized values differ across benchmarks. Do not log tokens where all values agree (after quantization).

### Pattern 4: Hex Quantization for Color Comparison

**What:** Before comparing hex values from different benchmarks, quantize them to a shared resolution. This prevents rendering differences (screen gamma, screenshot compression artifacts) from creating false conflicts.

**When to use:** During semantic color pass and primitive color pass, before any voting.

**Quantization rule (Claude's Discretion — recommendation):**

Round each R, G, B channel independently to the nearest multiple of 16 (one hex digit). This reduces the 256-step per-channel space to a 16-step space, collapsing values within ±8 of each other into the same bucket.

```
Quantize(hex) → nearest multiple of 16 per channel

Examples:
  #1a73e8 → R=0x1a≈16=0x10, G=0x73≈80=0x50, B=0xe8≈240=0xf0 → #1050f0 (bucket)
  #1b74e9 → R=0x1b≈16=0x10, G=0x74≈80=0x50, B=0xe9≈240=0xf0 → #1050f0 (same bucket)
  → These are treated as the same color.

  #3B82F6 → R=0x3b≈48=0x30, G=0x82≈80=0x50, B=0xf6≈240=0xf0 → #3050f0 (bucket)
  #2563EB → R=0x25≈32=0x20, G=0x63≈96=0x60, B=0xeb≈240=0xf0 → #2060f0 (different bucket)
  → These are treated as DIFFERENT colors. (They are genuinely different blues.)
```

**Recommendation:** 16-step quantization (±8 per channel) is the right threshold. It's tight enough to distinguish Tailwind blue-500 from blue-600 (which are real design decisions) but loose enough to merge rendering noise.

**Important:** Quantization is only used for comparison/grouping. The actual token value written to design-system.json is the modal raw hex from the winning group, not the quantized value.

### Pattern 5: Dominant Benchmark Identification

**What:** The synthesizer needs to identify the "dominant benchmark" — the single source that serves as the base for the token set when there are no conflicts (Pass 1 result).

**Selection rule:**

```
1. Filter to ui_screenshot findings only.
2. Among ui_screenshot findings, rank by:
   a. confidence: "high" > "medium" > "low"
   b. Tiebreak by: count of non-null values in semantic_assignments
3. The top-ranked finding is the dominant benchmark.
4. If all findings are visual_reference (no ui_screenshots):
   - Use the visual_reference with the most primitive_palette entries as dominant.
```

**Why this matters:** The dominant benchmark's complete token set is used as the starting point. Tokens in other benchmarks that are compatible (same quantized value) reinforce the dominant benchmark's choices. Tokens in other benchmarks that differ create conflicts to resolve.

### Pattern 6: Semantic Color → DTCG Token Conversion

**What:** The findings schema stores semantic colors as flat hex strings in a flat 21-key object. The design-system.json stores them as DTCG token objects with `{light, dark}` `$value`, organized in a 5-group hierarchy. The synthesizer must perform this transformation.

**Mapping table — findings keys to design-system.json paths:**

```
findings.semantic_assignments key     → design-system.json path
action_primary                        → tokens.color.semantic.action.primary.$value.light
action_primary_dark                   → tokens.color.semantic.action.primary.$value.dark
action_secondary                      → tokens.color.semantic.action.secondary.$value.light
action_secondary_dark                 → tokens.color.semantic.action.secondary.$value.dark
action_destructive                    → tokens.color.semantic.action.destructive.$value.light
action_destructive_dark               → tokens.color.semantic.action.destructive.$value.dark
surface_default                       → tokens.color.semantic.surface.default.$value.light
surface_default_dark                  → tokens.color.semantic.surface.default.$value.dark
surface_raised                        → tokens.color.semantic.surface.raised.$value.light
surface_raised_dark                   → tokens.color.semantic.surface.raised.$value.dark
text_primary                          → tokens.color.semantic.text.primary.$value.light
text_primary_dark                     → tokens.color.semantic.text.primary.$value.dark
text_muted                            → tokens.color.semantic.text.muted.$value.light
text_muted_dark                       → tokens.color.semantic.text.muted.$value.dark
text_inverse                          → tokens.color.semantic.text.inverse.$value (flat — rarely changes by theme)
border_default                        → tokens.color.semantic.border.default.$value.light (dark = same or lighter)
border_focus                          → tokens.color.semantic.border.focus.$value.light  (dark = same)
feedback_success                      → tokens.color.semantic.feedback.success.$value.light
feedback_error                        → tokens.color.semantic.feedback.error.$value.light
feedback_warning                      → tokens.color.semantic.feedback.warning.$value.light
feedback_info                         → tokens.color.semantic.feedback.info.$value.light
```

**Notes on this mapping:**
- `text_inverse`, `border_default`, and `border_focus` do not have `_dark` counterparts in the findings schema (21 keys, not 28). The synthesizer must infer reasonable dark values or use the same hex.
- `surface.overlay` and `surface.inset` are in the design-system.json schema as required fields but have no corresponding keys in the findings schema. The synthesizer must derive these: `overlay` = surface.default with 0.8 opacity (derive hex blend with black); `inset` = surface.default darkened slightly.
- `text.secondary` and `text.link` are in the design-system.json schema but not in the 21 findings keys. Derive: `text.secondary` = interpolated between `text.primary` and `text.muted`; `text.link` = `action.primary`.
- This derivation logic must be explicitly encoded in the synthesizer prompt to prevent improvisation.

### Pattern 7: Font Family Merge Strategy (Claude's Discretion)

**What:** Multiple benchmarks may report different sans-serif font families. The synthesizer must resolve this.

**Recommendation:** Pick one, preserve alternatives as fallbacks.

- Use the dominant benchmark's font as `$value` (primary).
- Collect other unique font names from other benchmarks.
- Add them as the first entries in `fallback_stack`, followed by system font stack.

**Example:**
- Benchmark 1 (dominant): `sans = "Inter"`
- Benchmark 2: `sans = "Geist"`
- Benchmark 3: `sans = null`

Result:
```json
"sans": {
  "$value": "Inter",
  "$type": "fontFamily",
  "fallback_stack": ["Geist", "-apple-system", "BlinkMacSystemFont", "Segoe UI", "sans-serif"],
  "$description": "Primary UI sans-serif. Inter from dominant benchmark; Geist as secondary option."
}
```

**Rationale:** Using only one font loses information that the user gave the system by providing multiple benchmarks. Preserving alternatives as fallbacks serves the generator phase (Phase 4) by giving it options if the primary font is unavailable.

**System font stacks by category:**
- Geometric sans: `-apple-system, BlinkMacSystemFont, "Segoe UI", "Helvetica Neue", sans-serif`
- Humanist sans: `system-ui, -apple-system, sans-serif`
- Mono: `ui-monospace, "JetBrains Mono", "Fira Code", "Cascadia Code", monospace`
- Display: (no standard fallback; fall through to sans-serif)

### Pattern 8: Output File Location (Claude's Discretion)

**Recommendation:** Caller-specified path with default `.dsys/design-system.json`.

Consistent with the analyzer agent pattern (Phase 2 research established orchestrator-controlled paths). The synthesizer accepts an optional `output_path` parameter. If not provided, defaults to `.dsys/design-system.json`.

**Why:** Hardcoding `.dsys/design-system.json` limits testing (cannot redirect to a temp path) and limits future multi-project use. The default satisfies ORCH-03 without sacrificing flexibility.

### Pattern 9: Schema Validation (Claude's Discretion)

**Recommendation:** Self-validation by the agent, not caller validation.

The synthesizer should include a self-validation step before writing: after filling the output template, check that:
1. All required fields are present (non-null where required by schema)
2. All hex values match `^#[0-9A-Fa-f]{6}$`
3. All dimension values match the `^-?[0-9]+(\\.[0-9]+)?px$` pattern
4. The `conflict_log` array is present (may be empty)
5. The `aesthetic` object has all 4 required fields

This is not full JSON Schema validation (that would require ajv-cli), but it catches the most common failures before the file is written. The agent self-check catches structure errors; the caller can run `npx ajv-cli validate` for full schema validation if needed.

### Anti-Patterns to Avoid

- **Averaging color values:** Never arithmetically average hex values (e.g., mix `#FF0000` and `#0000FF` to get `#7F007F`). Always vote — pick one winner. Averaged colors look wrong and lose semantic meaning.
- **Blending aesthetic profiles:** When benchmarks have different tones (one "minimal", one "bold"), do not output "expressive" as a compromise. Pick the dominant direction. The locked decision is explicit: "pick the dominant direction, don't blend."
- **Null propagation without fallback:** If all benchmarks returned null for a required semantic role (e.g., `feedback_warning` null in all findings), the synthesizer still must produce a value for `feedback.warning` in design-system.json. Derive a sensible default: amber/yellow for warning, green for success, red for error. Document this derivation in the conflict_log as a generation decision.
- **Primitive palette from all sources:** Do not dump all primitive colors from all benchmarks into the primitive layer. The primitive palette becomes unusable if it has 40 colors. Limit to colors that appear in the semantic layer plus adjacent shades for hover/active states.
- **Losing the conflict_log:** The conflict_log is the audit trail of every non-obvious synthesis decision. It must be populated for any token where values differed across benchmarks. An empty conflict_log when N > 1 sources is almost certainly wrong.
- **Missing semantic assignments in output:** The design-system.json schema requires `action`, `surface`, `text`, `border`, and `feedback` groups in `tokens.color.semantic`, each with specific required keys. All of them must be present, even if derived from context rather than directly observed. Null is not permitted in the output schema for these required semantic tokens.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON merge logic | Custom JavaScript | Agent prompt with explicit algorithm | Merge algorithm fits in ~200 tokens of decision table; building a script adds code that must be maintained, tested, and invoked |
| Output schema | New JSON structure | Phase 1 `design-system.schema.json` and `token-schema.md` | Schema is complete, validated, and on disk; the synthesizer prompt embeds the fill-in template from it |
| JSON Schema validation | Custom validation | `npx ajv-cli validate` (optional) | Already tested in Phase 1; invoke only if conformance errors surface |
| Hex color math | Custom HSL distance functions | 16-step quantization rule | Quantization to nearest-16 per channel is simple, reliable, and sufficient for the ±8 error band from rendering noise |

**Key insight:** Phase 3 is a prompt-writing phase. The synthesizer agent is a Markdown file, not a script. All "algorithmic" logic lives in the prompt as decision tables and numbered steps. The risk is not implementation complexity but prompt precision: vague merge instructions produce drift.

---

## Common Pitfalls

### Pitfall 1: The "Missing Required Tokens" Failure

**What goes wrong:** The findings schema has 21 semantic color keys. The design-system.json schema requires 18 semantic role tokens. But the mapping is not 1:1 — the design-system requires `surface.overlay`, `surface.inset`, `text.secondary`, and `text.link` which have no corresponding keys in the findings. If the synthesizer prompt doesn't explain this derivation, the agent will leave these tokens empty or filled with incorrect values, failing schema validation.

**Why it happens:** The schema mismatch was identified in Phase 1 research but not called out explicitly as a synthesizer task. It was assumed the synthesizer would figure it out.

**How to avoid:** The synthesizer prompt must include an explicit derivation table (Pattern 6 above) that maps every required output token to either a findings key or a derivation rule. No token in the output template can be left without a derivation path.

**Warning signs:** `design-system.json` fails ajv-cli validation with "required property missing" for `surface/overlay`, `surface/inset`, `text/secondary`, or `text/link`.

### Pitfall 2: Conflict_Log Present But Empty When N > 1

**What goes wrong:** The synthesizer produces a `design-system.json` with `"conflict_log": []` even though it received 3 benchmark findings with some differing values. The schema accepts an empty array (correct). But an empty log when conflicts existed means the synthesizer silently resolved them without logging — destroying the audit trail.

**Why it happens:** The agent fills the conflict_log as an afterthought, after it has already made resolution decisions during the merge pass. It may not remember which tokens had conflicts.

**How to avoid:** The synthesizer prompt must instruct the agent to append to a running conflict_log buffer as it makes each merge decision, not to construct the log at the end. Explicitly: "For each token where quantized values differ, immediately add a conflict_log entry before moving to the next token."

**Warning signs:** `conflict_log` is `[]` for a run with 2+ source benchmarks that have different color schemes.

### Pitfall 3: Primitive Palette Bloat

**What goes wrong:** The synthesizer collects all colors from all findings primitive_palettes and dumps them into `tokens.color.primitive`. With 4 benchmarks each providing 8 colors, this produces a 32-color primitive palette where many entries are similar blues or grays from different sources. The generator then produces CSS with 32 `--color-*` variables, which defeats the purpose of a design system.

**Why it happens:** "Dominant set + extras" is ambiguous. The agent interprets "extras" as "everything from other benchmarks."

**How to avoid:** "Extras" means colors that are perceptually distinct from everything already in the dominant benchmark's palette AND that appear in the semantic layer of at least one findings document. Colors from non-dominant benchmarks that are perceptually similar to a dominant benchmark color are not extras — they are the same color in a different hue-family bucket. Specify this explicitly in the prompt.

**Practical rule:** After quantization, if a non-dominant benchmark's color maps to a quantization bucket already occupied by the dominant benchmark's palette, discard the non-dominant color. Only add colors from non-dominant benchmarks that occupy new quantization buckets AND are referenced in semantic_assignments.

### Pitfall 4: Spacing Scale Incompleteness

**What goes wrong:** The synthesizer collects spacing values from findings (`spacing.scale` arrays, which may be like `[4, 8, 12, 16, 24, 32]`) and emits only those observed values into `tokens.spacing.scale`. The design-system.json schema requires keys `1` through `32` (13 specific steps). Many of these steps have no observed value.

**Why it happens:** The agent fills only observed values. Required schema keys are not filled.

**How to avoid:** The spacing pass must always produce all 13 required scale steps. Unobserved values are computed from the base_unit: step N = N × base_unit. The observed values from findings validate that the base_unit choice is correct; missing scale values are derived, not observed. This must be explicit in the prompt.

### Pitfall 5: Aesthetic Blending Despite "Pick, Don't Blend" Rule

**What goes wrong:** Three benchmarks have `tone: "minimal"`, one has `tone: "bold"`. The synthesizer averages them and writes `tone: "expressive"` as a compromise. Or it writes `personality_tags: ["minimal", "clean", "bold", "dynamic"]` mixing both directions.

**Why it happens:** The agent tries to be comprehensive and include signals from all sources. The "pick the dominant direction" rule requires actively discarding minority signals.

**How to avoid:** The aesthetic pass must have an explicit rule: "Count votes for each enum value. The highest-vote value wins. If tie, use the dominant benchmark's value. Do not mix or interpolate enum values. Remove personality_tags from minority sources that contradict the dominant tone."

**Warning signs:** `personality_tags` contains both "minimal" and "bold" when the `tone` is "minimal" — contradictory terms indicate blending.

### Pitfall 6: Dark-Mode Value Derivation Is Wrong

**What goes wrong:** Many findings return null for `_dark` color keys (e.g., `action_primary_dark: null`) because the analyzed benchmarks were all light-mode UIs. The synthesizer must derive dark-mode values. Without explicit guidance, the agent may invert the hue, produce very dark colors with poor contrast, or simply copy the light value.

**Why it happens:** Dark mode color derivation requires understanding of perceptual lightness, contrast ratios, and how dark themes work. The agent has knowledge of this but needs to be pointed at it.

**How to avoid:** Provide explicit dark-mode derivation heuristics in the synthesizer prompt:
- `action_primary_dark`: If light value is dark (L* < 50 in HSL), use a lighter version of the same hue. If light value is bright, darken it slightly.
- `surface_default_dark`: Invert the surface lightness. Light (#F9FAFB) → dark (#0F172A or similar near-black matching the palette's hue undertone.
- `text_primary_dark`: Invert relative to surface — if light text is near-black, dark text is near-white.
- `feedback_*_dark`: Slightly lighter or more saturated version of the light feedback color for dark backgrounds.

### Pitfall 7: String "null" Instead of JSON null (Inherited from Phase 2)

**What goes wrong:** The fill-in template uses placeholder text for optional fields. The agent writes the string `"null"` instead of the JSON literal `null`.

**Why it happens:** Same failure mode as the analyzer agent (Phase 2 Pitfall 4).

**How to avoid:** Include the same explicit instruction from analyzer.md: "Use the JSON literal null (no quotes) for absent or unobservable values. Never write the string "null"." With a worked example.

### Pitfall 8: Missing Write Call (Inherited from Phase 2)

**What goes wrong:** Agent fills and validates the template, returns a summary string to the orchestrator, but never calls the Write tool. No `design-system.json` on disk.

**How to avoid:** Same instruction as analyzer.md: "Write the completed JSON to output_path. Return the summary only after Write succeeds."

---

## Code Examples

Verified patterns from Phase 1 artifacts and established design:

### Complete Synthesizer Agent Prompt Skeleton

```markdown
# dsys Synthesizer Agent

## Role

You are the dsys synthesizer agent. You read N analysis findings JSON files (one per
benchmark image from Phase 2) and produce a single design-system.json conformant to
the design-system schema. You apply the merge algorithm below mechanically — do not
improvise merge decisions.

## Input

You receive:
- `findings_paths`: List of paths to analysis findings JSON files
  (e.g., [".dsys/findings/bench-1.json", ".dsys/findings/bench-2.json"])
- `output_path`: Where to write design-system.json
  (default: ".dsys/design-system.json" if not provided)

## Step 1: Load All Findings

For each path in findings_paths:
1. Use the Read tool to load the file.
2. If Read fails: skip this file and note it as a load failure.
3. Parse the JSON content.
Continue only if at least one findings file loaded successfully.

## Step 2: Source Validation Pass

Count findings by image_type:
- ui_screenshots: count of image_type == "ui_screenshot"
- visual_references: count of image_type == "visual_reference"

Identify the DOMINANT BENCHMARK:
1. Among ui_screenshot findings, rank by confidence ("high" > "medium" > "low").
2. Tiebreak: count non-null values in semantic_assignments. Higher count wins.
3. If no ui_screenshots: use the visual_reference with the most primitive_palette entries.

The dominant benchmark is the base for all token categories.

## Step 3: Color Quantization (apply before any comparison)

Before comparing ANY hex values from different findings, quantize them:
Round each R, G, B channel to the nearest multiple of 16.
Use quantized values ONLY for grouping. Write raw hex values to output.

Examples:
  #1a73e8 → same bucket as #1b74e9 (both quantize to same group)
  #3B82F6 → DIFFERENT bucket from #2563EB (distinct blues)

## Step 4: Semantic Color Merge Pass

For each of the 21 semantic assignment keys:
1. Collect all non-null values from all findings.
2. Quantize all values.
3. Group by quantized bucket. Count each group.
4. If all non-null values quantize to the same bucket: no conflict. Use modal raw hex.
5. If groups differ: CONFLICT.
   a. The largest group's modal raw hex wins.
   b. Tie: use the value from the dominant benchmark. If dominant is null, use the
      next-largest group's modal raw hex.
   c. IMMEDIATELY add a conflict_log entry:
      { "token": "tokens.color.semantic.{path}", "candidates": [all raw values],
        "chosen": "{winner}", "rationale": "{N}/{total} benchmarks" }
6. If all values are null: derive a default (see Derivation Table below).

DERIVATION TABLE for tokens missing from findings:
- surface.overlay: surface.default + 85% opacity tint (use nearest hex blend with #000000)
- surface.inset: surface.default darkened by ~5% lightness
- text.secondary: midpoint between text.primary and text.muted
- text.link: same as action.primary

## Step 5: Primitive Color Build Pass

Start with the dominant benchmark's primitive_palette.
For each other finding's primitive_palette:
  - Quantize each color.
  - If the quantized value is NOT already in the dominant palette's bucket set:
    - AND if the color appears in that finding's semantic_assignments:
    - Add it as a new hue-family group in the primitive layer.

Group colors into hue families: blue, gray, red, green, yellow, purple, orange, white, black.
Produce at minimum: 2-4 shades per hue family (e.g., 400, 500, 600, 700 for the primary hue).

## Step 6: Typography Merge Pass

Font families:
- Use dominant benchmark's sans/mono/display as $value.
- Collect unique font names from other findings that differ from dominant.
- Add them to fallback_stack, in order of their source's confidence.
- Append standard system font stack for the category.

Type scale: Use standard type scale keys xs/sm/base/lg/xl/2xl/3xl/4xl/5xl.
- Map observed sizes from findings to nearest standard key.
- Prefer dominant benchmark for the assignment.
- Snap all values to the standard type scale: 10, 11, 12, 13, 14, 15, 16, 18, 20, 24, 28, 32, 36, 40, 48, 56, 64, 72, 80, 96.

Weights: Use 400/500/600/700 as standard values unless dominantly different.
Line heights: Use dominant benchmark's line_height_pattern. Map to:
  tight=1.25, normal=1.5, relaxed=1.625, loose=2.0.

## Step 7: Spacing Merge Pass

base_unit: Use 4 if any findings used base_unit=4. Use 8 only if ALL findings used 8.
Always produce all 13 required scale steps: 1 through 32.
Step N value = N × base_unit. Snap to 4px grid.
Semantic spacing: assign from the dominant benchmark's observed density:
  compact  → component-gap=8px, card-padding=12px, page-margin=16px, section-padding=24px, input-padding=8px, stack-gap=4px
  comfortable → component-gap=12px, card-padding=16px, page-margin=24px, section-padding=32px, input-padding=12px, stack-gap=8px
  spacious → component-gap=16px, card-padding=24px, page-margin=32px, section-padding=48px, input-padding=16px, stack-gap=12px

## Step 8: Non-Color Tokens Pass

Shadows: Collect all non-null shadow arrays. Merge by elevation tier (sm/md/lg/xl).
  If multiple sources have a "sm" shadow: take the dominant benchmark's. Log if values differ.
  Include a shadow tier if ANY source has it (completeness over consensus).

Border radius: Merge by tier (sm/md/lg/full).
  Frequency vote per tier. "full" = true if majority have full=true.

Opacity: Merge all non-null opacity_scale arrays. Include a value if seen in any source.
  Map to named levels: subtle≈0.05–0.1, disabled≈0.3–0.5, overlay≈0.8–0.9, heavy≈0.95.

## Step 9: Aesthetic Pass

density: Frequency vote. Ties go to dominant benchmark.
tone: Frequency vote. Ties go to dominant benchmark.
personality_tags: Start with dominant benchmark's tags. Add tags from other findings
  that appear in 2+ sources AND are consistent with the winning tone. Remove tags that
  contradict the dominant tone. Result: 4-8 tags.
summary: 2-3 factual sentences characterizing the dominant aesthetic. Use the structured
  fields (tone, density, color temperature, roundness) — not opinion or aspiration.
dominant_approach: One line: "{tone} {surface} with {primary color description}".
  Example: "Clean minimal SaaS with blue accent and generous whitespace."

## Step 10: Fill and Validate

Fill the output template below with all merge pass results.
Self-check before writing:
  □ All required tokens are present (non-null)
  □ All hex values match #RRGGBB pattern (6 hex digits)
  □ All dimension values end in "px"
  □ conflict_log is present (may be empty [] for N=1 source)
  □ aesthetic.summary is at least 20 characters
  □ personality_tags has 4-8 entries

IMPORTANT: Use JSON literal null (no quotes) for absent values.
           Never write the string "null".

## Step 11: Write Output

Write the completed JSON to output_path using the Write tool.
Do not return until Write succeeds.

## Step 12: Return Summary

Return exactly:
"Synthesized {N} findings → design-system.json: {dominant_approach}, {conflict_count} conflicts resolved"

## Output Template

[EMBED token-schema.md FILL-IN TEMPLATE HERE]
```

### Conflict Log Entries — Examples

```json
"conflict_log": [
  {
    "token": "tokens.color.semantic.action.primary",
    "candidates": ["#3B82F6", "#2563EB", "#3B82F6"],
    "chosen": "#3B82F6",
    "rationale": "2/3 benchmarks — majority vote"
  },
  {
    "token": "tokens.color.semantic.feedback.warning",
    "candidates": [],
    "chosen": "#F59E0B",
    "rationale": "Derived — no benchmark contained this role; standard amber warning hue assigned"
  }
]
```

### Primitive Color Layer — Example Output

```json
"primitive": {
  "$type": "color",
  "blue": {
    "400": { "$value": "#60A5FA", "$description": "Blue 400 — hover/active state" },
    "500": { "$value": "#3B82F6", "$description": "Blue 500 — primary brand hue" },
    "600": { "$value": "#2563EB", "$description": "Blue 600 — pressed state" }
  },
  "gray": {
    "50":  { "$value": "#F9FAFB" },
    "100": { "$value": "#F3F4F6" },
    "200": { "$value": "#E5E7EB" },
    "400": { "$value": "#9CA3AF" },
    "600": { "$value": "#4B5563" },
    "900": { "$value": "#111827" }
  },
  "red":   { "500": { "$value": "#EF4444" }, "700": { "$value": "#B91C1C" } },
  "green": { "500": { "$value": "#22C55E" }, "700": { "$value": "#15803D" } },
  "amber": { "500": { "$value": "#F59E0B" } },
  "white": { "$value": "#FFFFFF" },
  "black": { "$value": "#000000" }
}
```

### Dark-Mode Derivation When _dark Is Null

When the findings provide no dark-mode counterpart for a semantic color:

```
action_primary light = #1F3A1F (dark forest green)
→ L* is very low (~15), so dark-mode version should be a LIGHTER green
→ Inferred: #4ADE80 (Tailwind green-400, bright for dark surface contrast)

surface_default light = #F7F9F4 (near-white with green tint)
→ Invert lightness, preserve hue undertone
→ Derived: #0F1A0F (near-black with same green undertone)

text_primary light = #1A2B1A (dark green-tinted near-black)
→ Must be near-white on dark surface
→ Derived: #F0F4F0 (near-white with same green undertone)
```

This is the logic from the test-validation.json (the real Phase 2 output). The synthesizer should apply the same reasoning pattern when _dark values are absent.

### Spacing Semantic Tokens — Derivation from Density

```json
// For "comfortable" density (most common):
"semantic": {
  "$type": "dimension",
  "component-gap":   { "$value": "{tokens.spacing.scale.3}", "$description": "Gap between sibling components in a layout" },
  "section-padding": { "$value": "{tokens.spacing.scale.6}", "$description": "Padding around a major content section" },
  "page-margin":     { "$value": "{tokens.spacing.scale.8}", "$description": "Outer page margin / container padding" },
  "input-padding":   { "$value": "{tokens.spacing.scale.3}", "$description": "Internal padding inside form inputs" },
  "card-padding":    { "$value": "{tokens.spacing.scale.4}", "$description": "Internal padding inside card/panel surfaces" },
  "stack-gap":       { "$value": "{tokens.spacing.scale.2}", "$description": "Gap in vertical/horizontal stack layouts" }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate light/dark token files | Single token file with `{light, dark}` $value objects | DTCG spec + Phase 1 decision | Synthesizer writes one file; no separate dark-mode findings needed |
| Collecting all source colors in primitive layer | Dominant palette + distinct extras only | Phase 3 decision | Keeps primitive layer usable; prevents token explosion |
| Majority vote without quantization | Quantize first, then vote | Phase 3 decision | Prevents rendering noise from creating false conflicts |
| No derivation for missing tokens | Explicit derivation table for 5 missing semantic roles | Phase 3 (this phase) | Guarantees all required output tokens are populated |

---

## Open Questions

1. **Conflict_log detail level vs. "decision only" locked decision**
   - What we know: The locked decision says "conflict log: decision only (what was chosen, what was rejected) — no detailed reasoning." The design-system.schema.json conflict_log items require `token`, `candidates`, `chosen`, and `rationale` (all required).
   - What's unclear: "No detailed reasoning" in CONTEXT.md appears to conflict with the `rationale` field in the schema. The schema's `rationale` string (e.g., "2/3 benchmarks — majority vote") is minimal — is that acceptable as "decision only"?
   - Recommendation: Yes, the short rationale string `"{N}/{total} benchmarks"` or `"Derived — no benchmark contained this role"` satisfies both constraints. "No detailed reasoning" means no multi-sentence explanation; a brief formula-style rationale is acceptable and required by the schema. The planner should confirm this interpretation.

2. **What to do when ALL N findings have partial_failure=true**
   - What we know: If every benchmark returned `typography: null` and `spacing: null` (all partial failures), the synthesizer cannot derive these token categories from observations. But the output schema requires non-null `typography` and `spacing`.
   - What's unclear: Should the synthesizer produce generic fallback values (Inter 16px/4px grid) or fail with an error?
   - Recommendation: Produce sensible defaults for all required fields (Inter/system-ui for font, 16px base for type, 4px grid for spacing) and log each as a "generated default" in the conflict_log. This keeps the pipeline runnable. Failure would block the user with no actionable path forward.

3. **Findings with significantly different design directions (multi-domain input)**
   - What we know: The "pick dominant, don't blend" rule handles mixed aesthetics. But what if 2 of 4 inputs are corporate SaaS and 2 are playful consumer apps — a 50/50 split?
   - What's unclear: The tiebreaker (dominant benchmark identification) resolves this algorithmically, but the resulting design-system.json may not serve either direction well.
   - Recommendation: This is a user problem, not a synthesizer problem. The synthesizer follows the algorithm; the aesthetic summary should factually note the mixed inputs. Add to the prompt: "If the source count is evenly split between conflicting aesthetic directions, note this in aesthetic.summary: 'Sources represent two distinct aesthetic directions; synthesis based on dominant benchmark.'". No planning action required.

4. **primitive_palette role field in findings vs. design-system.json hue-family grouping**
   - What we know: The findings `primitive_palette` entries have `role: "dominant"|"accent"|"surface"|"text"|"neutral"|"feedback"`. The design-system.json primitive layer groups by hue family (blue, gray, red, etc.), not by role.
   - What's unclear: How does the synthesizer map from role-based to hue-family-based grouping?
   - Recommendation: Use the semantic layer to determine hue family. `action_primary` hex → blue family. `surface_default` → gray/white family. `feedback_error` → red family. The role field in primitive_palette is a secondary signal; use hue detection (HSL hue angle) as the primary grouping key. Document this mapping in the synthesizer prompt.

---

## Sources

### Primary (HIGH confidence)

- `skills/dsys/schemas/design-system.schema.json` — Complete Phase 1 output schema with all required fields, $defs, and constraints. The synthesizer's output must conform to this exactly.
- `skills/dsys/schemas/analysis-findings.schema.json` — Complete Phase 2-extended input schema. Defines all 21 semantic keys, rationale structure, and partial_failure fields the synthesizer reads.
- `skills/dsys/references/token-schema.md` — Human-readable spec of design-system.json. The fill-in template for the synthesizer prompt is derived from this document.
- `.dsys/findings/test-validation.json` — Real Phase 2 output from Luxora mobile app screenshot. Demonstrates the exact JSON structure the synthesizer will receive as input.
- `.planning/phases/01-schema-contracts/01-RESEARCH.md` — Phase 1 research: schema design rationale, token taxonomy, DTCG format.
- `.planning/phases/02-analysis-agent/02-RESEARCH.md` — Phase 2 research: agent prompt architecture, fan-out pattern, anti-patterns.
- `.planning/phases/02-analysis-agent/02-VERIFICATION.md` — Phase 2 verification: confirmed deliverables, known gaps, Phase 6 deferral.

### Secondary (MEDIUM confidence)

- `.planning/phases/03-synthesizer-agent/03-CONTEXT.md` — User decisions for conflict resolution algorithm, aesthetic identity, token merging, and Claude's Discretion areas.
- `.planning/research/ARCHITECTURE.md` — Project-level architecture decisions: agent file anatomy, file-based intermediate representation, no compiled code.

### Tertiary (LOW confidence, validate during planning)

- Hex quantization threshold: 16-step (±8 per channel) is a recommendation based on reasoning about rendering noise. Validate empirically during testing by running 2 findings with the same known design system captured at different zoom levels and confirming quantization groups them correctly.
- Dark-mode derivation heuristics: derived from the test-validation.json rationale strings, which show the analyzer's approach to inferring dark-mode colors. Validate against a real dark-mode test case during Phase 3 verification.

---

## Metadata

**Confidence breakdown:**
- Agent file architecture: HIGH — established by Phase 2; same anatomy applies
- Merge algorithm (conflict resolution): HIGH — locked decisions define the algorithm; research documents the implementation
- Hex quantization threshold: MEDIUM — 16-step is reasoned from first principles; empirical validation needed
- Dark-mode derivation heuristics: MEDIUM — derived from test-validation.json patterns; needs broader testing
- Missing token derivation table (overlay, inset, secondary, link): HIGH — derived from schema requirements vs. findings schema; logic is definitive

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (schema artifacts are stable; Phase 2 deliverables are complete and will not change)

---

## Planning Guidance

### What Phase 3 Actually Produces

One file: `skills/dsys/agents/synthesizer.md`

The synthesizer agent prompt. It:
- Accepts `findings_paths` (list of paths) and `output_path` (string)
- Loads all findings using the Read tool
- Applies the 9-pass merge algorithm
- Fills the design-system.json output template
- Writes to `output_path` using the Write tool
- Returns a one-line summary

### Critical Decisions for the Planner

**1. The token-schema.md fill-in template**

The synthesizer prompt needs an embedded fill-in template derived from `token-schema.md`. This is the same approach as Phase 2 (embedding the fill-in template from `analysis-findings-schema.md`). The planner must include a task that:
- Produces a synthesizer-specific fill-in version of the design-system.json template
- (This can be embedded directly in synthesizer.md without a separate document)

**2. Missing tokens in the findings → output mapping**

Pattern 6 (Semantic Color → DTCG Token Conversion) is the most critical correctness risk. The planner must ensure the synthesizer prompt explicitly includes the derivation table for `surface.overlay`, `surface.inset`, `text.secondary`, and `text.link` — these have no corresponding findings keys and must be derived.

**3. Conflict_log confirmation before writing**

The synthesizer should build the conflict_log incrementally during merge passes (not reconstruct it at the end). The planner's task for "output instructions" must specify this ordering.

**4. Testing approach**

Phase 3 verification requires at minimum:
- Single-findings test: 1 input file → design-system.json. Validates the schema conformance path.
- Multi-findings test: 2-3 input files with known conflicts (different blues, different spacings). Validates the merge algorithm and conflict_log.
- Partial-null test: 1 input with partial_failure=true (typography=null). Validates the default-derivation path.

Use `npx ajv-cli validate -s skills/dsys/schemas/design-system.schema.json -d .dsys/design-system.json` as the primary pass/fail gate.

**5. Schema gap: conflict_log `rationale` field**

The `design-system.schema.json` conflict_log items require a `rationale` field (string, required). The CONTEXT.md says "conflict log: decision only (what was chosen, what was rejected) — no detailed reasoning." These are compatible: the `rationale` field contains a short formula string, not prose. The synthesizer prompt must produce rationale strings of the form `"{N}/{total} benchmarks"` or `"Derived — no observation"` — short, machine-readable, satisfying both the schema requirement and the locked decision.
