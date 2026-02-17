# Phase 3: Synthesizer Agent - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Merge N analysis findings (per-image JSON outputs from Phase 2) into a single canonical design-system.json with a clear aesthetic identity. The synthesizer resolves conflicts between benchmarks, establishes a dominant visual direction, and writes a human-inspectable output file. Platform-specific generation (React/Tailwind, SwiftUI) is Phase 4.

</domain>

<decisions>
## Implementation Decisions

### Conflict Resolution
- Frequency-weighted: the value that appears in the most benchmarks wins
- Tiebreaker: most prominent usage (the value used for more elements/surface area in its benchmark)
- Quantize near-identical values before comparing (e.g., treat #1a73e8 and #1b74e9 as the same blue) to avoid false conflicts from rendering differences
- Conflict log: decision only (what was chosen, what was rejected) — no detailed reasoning

### Aesthetic Identity
- Factual description tone, not opinionated narrative — neutral characterization of observed patterns
- Dominant approach captures both visual character traits (color temperature, contrast, density, roundness, whitespace) and design philosophy (minimalist vs rich, corporate vs playful, information-dense vs spacious)
- Structured fields in JSON for key aesthetic traits — machine-parseable, not free-text prose
- When benchmarks have mixed aesthetics: pick the dominant direction, don't blend

### Token Merging
- Dominant set + extras: use the dominant benchmark's token set as the base, add distinctive tokens from others
- Spacing scale: enforce 4px grid — snap all spacing values to nearest 4px increment
- Semantic roles: include if found in any benchmark — completeness over consensus
- If a role like feedback_warning is only in one benchmark, it's still included

### Claude's Discretion
- Font family merging strategy (pick one vs preserve alternatives as fallbacks)
- Output file location (.dsys/ vs caller-specified path)
- Schema self-validation vs caller validation
- Exact quantization thresholds for near-identical value grouping

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

*Phase: 03-synthesizer-agent*
*Context gathered: 2026-02-17*
