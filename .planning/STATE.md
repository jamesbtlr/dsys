# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core value:** AI-generated UI should look intentional, not generic. Front-load design decisions from real-world references so every subsequent build session produces cohesive results.
**Current focus:** Phase 1 — Schema Contracts

## Current Position

Phase: 1 of 6 (Schema Contracts)
Plan: 3 of TBD in current phase
Status: In progress
Last activity: 2026-02-17 — Completed 01-03 (platform output specs: React/Tailwind + SwiftUI)

Progress: [███░░░░░░░] ~8%

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: ~5 min
- Total execution time: ~16 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-schema-contracts | 3 | ~16 min | ~5 min |

**Recent Trend:**
- Last 5 plans: 01-01 (research, ~6 min), 01-02 (schema, ~6 min), 01-03 (platform specs, ~4 min)
- Trend: Steady

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Architecture is pure Markdown prompt files; no compiled code or package manager required
- Schema contracts must be defined before any agent is written (highest-severity risk)
- Schemas communicate through disk files (.dsys/), not direct agent-to-agent calls
- Style Dictionary v5.3.1 (via npx) is the only external dependency; SwiftUI output generated directly by Claude
- Semantic color taxonomy: 21 semantic_assignments keys (action: primary/secondary/destructive each with light+dark variant; surface: default/raised each with light+dark variant; text: primary/muted each with light+dark, plus text_inverse; border: default/focus; feedback: success/error/warning/info) — light+dark pairs flattened into the semantic_assignments map, not nested objects
- Theme-aware $value pattern: {light, dark} object for semantic color tokens — keeps values co-located, avoids separate file sync bugs
- conflict_log always required in meta (may be empty []) — makes synthesis auditable without checking for key existence
- font_family roles (sans/mono/display) are always present keys; value is null if not observed in benchmarks
- shadow and opacity use type ["array","null"] / ["object","null"] — explicit null for "not found", never absent key
- dimensionToken $value uses px suffix string (e.g. "16px") not bare number — matches DTCG spec and Style Dictionary v5
- semanticColorToken requires $description — documents intent on every role-based token
- React/Tailwind theme.css must have --color-*: initial; as first @theme declaration — resets full Tailwind default palette, makes design system enforceable
- tokens.css uses --ds- prefix; theme.css maps @theme names to --ds- vars — separation enables runtime theme-switching without Tailwind rebuild
- SwiftUI colors must use Color(name:bundle:.module) referencing asset catalog — never Color(hex:); asset catalog provides automatic OS-managed dark mode
- DSSpacing uses @ScaledMetric instance properties (not static) for Dynamic Type support
- SwiftUI components prefixed DS (DSButton, DSCard) to avoid collision with SwiftUI built-in view names
- iOS 16 minimum target chosen for SwiftUI generator (NavigationStack, complete @ScaledMetric, Color(named:) support)

### Pending Todos

None.

### Blockers/Concerns

- Phase 2 (Analyzer): Prompt engineering for design-intent extraction vs. pixel measurement needs empirical testing — cannot be fully designed in the abstract
- Style Dictionary v5 {light, dark} $value handling: LOW confidence on exact behavior; requires empirical testing before Phase 4 React generator is finalized; custom preprocess step is likely required
- Phase 4 (SwiftUI generator) iOS target concern RESOLVED: iOS 16 chosen and documented in swiftui-spec.md

## Session Continuity

Last session: 2026-02-17
Stopped at: Completed 01-03-PLAN.md (platform output specs: React/Tailwind + SwiftUI)
Resume file: None
