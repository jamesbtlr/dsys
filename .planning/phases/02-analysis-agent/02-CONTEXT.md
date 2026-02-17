# Phase 2: Analysis Agent - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Build and test the per-image vision extraction agent. Takes screenshot benchmarks as input, uses Claude's vision to extract structured design tokens (colors, typography, spacing), and outputs schema-conformant findings JSON. Input validation, error handling, and parallel multi-image analysis are in scope. Synthesis across images is Phase 3.

</domain>

<decisions>
## Implementation Decisions

### Extraction boldness
- Preserve exact observed color values — do NOT snap to nearest standard. Let the synthesizer (Phase 3) decide on quantization
- Spacing and typography quantization: strict adherence to extraction rubric rules (4px grid, standard font weights). Colors are the exception
- Surface ambiguity when encountered — include alternative interpretations and reasoning so the synthesizer can make an informed choice
- Only extract colors that map to defined token categories in the schema. Ignore decorative/illustrative colors (gradients, illustration accents)
- When a screenshot shows mixed light/dark areas (e.g., dark sidebar + light content), treat as one theme with varied surface colors — not multiple themes

### Screenshot expectations
- Accept any visual screenshot: app screens, marketing pages, landing pages, design mockups (Figma exports, etc.)
- Local file paths only — no URL fetching
- Automatically detect and exclude browser chrome, device frames, and OS status bars. Only analyze the app/site content
- Light/dark mode pair awareness: when two screenshots appear to be the same UI in different modes, recognize them as a pair and output combined findings

### Partial results & errors
- Return partial results when some categories succeed but others fail. Better than nothing
- Omit missing categories from output JSON entirely — do not include null markers or reason strings for failed extractions
- Actionable one-liner error messages for input validation failures (e.g., "Unsupported format: .bmp (use PNG, JPG, or WebP)")
- When batch-analyzing multiple screenshots, continue with valid ones if some fail. Report failures separately

### Findings detail
- Include brief rationale strings with major extractions (e.g., "Identified as primary action color: appears on all CTA buttons")
- Include a 1-2 sentence aesthetic summary per screenshot describing the overall visual style
- Do NOT include source screenshot metadata (dimensions, detected platform, device type)

### Claude's Discretion
- Semantic role assignment approach (bold assertions vs. conservative suggestions)
- Font identification strategy when typeface is unrecognizable (guess closest match vs. report unknown with traits)
- Whether to extract component-level patterns (button padding, card radius) as annotations alongside tokens
- Output file path strategy (write to .dsys/ directly vs. caller-controlled path)

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-analysis-agent*
*Context gathered: 2026-02-17*
