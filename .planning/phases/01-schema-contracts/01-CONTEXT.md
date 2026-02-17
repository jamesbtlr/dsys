# Phase 1: Schema Contracts - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the JSON schemas and extraction rubric that all downstream agents share. This includes the analysis findings schema (per-image output), the canonical design-system.json schema, platform output specifications, and the extraction rubric. Every agent depends on these contracts being stable before it is written.

</domain>

<decisions>
## Implementation Decisions

### Token taxonomy
- Full visual system extraction: colors, typography, spacing, shadows, border radii, opacity, and effects
- Not limited to core essentials — capture everything that makes a UI feel polished
- Schema must be universal: handle SaaS dashboards, consumer apps, marketing sites equally

### Color naming strategy
- Semantic role naming: tokens named by purpose (primary, secondary, destructive, surface, muted, accent, etc.)
- Not appearance-based (no blue-500, gray-100 naming)
- Analysis agent must infer design intent from visual context, not just sample pixel values

### Input flexibility
- Variable number of input images per run (1 to many)
- Inputs may include non-UI images: mood photos, brand assets, style references, visual inspiration
- Schema must distinguish between "extracted from UI screenshot" and "inspired by visual reference"
- Analysis findings schema needs an image-type classification (UI screen vs visual reference)

### Non-UI image handling
- Non-UI images produce: dominant color palette + aesthetic vibe description
- Vibe description captures mood/feel: warm, minimal, bold, playful, corporate, etc.
- These findings feed into the synthesizer to influence the overall design system's aesthetic identity

### Theming
- Light/dark mode support built into the schema from the start
- Tokens have theme-aware values (a color token can resolve differently per theme)
- Schema structure must accommodate theme variants without duplication of the entire token set

### Claude's Discretion
- Quantization rules: how raw values snap to standard scales (4px grid, type scales, etc.)
- Schema strictness: required vs optional fields, how to represent "not found"
- design-system.json internal structure: nesting, grouping, relationships between tokens
- Platform output specifications: what files each generator must produce, naming conventions
- Extraction rubric detail level: how prescriptive the rubric is about what to look for

</decisions>

<specifics>
## Specific Ideas

- The tool's core value proposition is that AI-generated UI should look intentional, not generic — schemas should front-load design decisions from real-world references
- Non-UI visual references (mood boards, brand photos) are first-class inputs, not edge cases
- Semantic naming matters because downstream generators need role-based tokens, not arbitrary color names

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-schema-contracts*
*Context gathered: 2026-02-17*
