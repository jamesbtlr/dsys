# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core value:** AI-generated UI should look intentional, not generic. Front-load design decisions from real-world references so every subsequent build session produces cohesive results.
**Current focus:** Phase 6 — Orchestrator

## Current Position

Phase: 5 of 6 complete (Rules and Style Guide — DONE)
Plan: 2 of 2 complete (05-02 complete — rules agent validated, CLAUDE.md + STYLE-GUIDE.md generated)
Status: Phase 5 complete — ready for Phase 6 (orchestrator)
Last activity: 2026-02-18 — Completed 05-02 (CLAUDE.md: 45 NEVER, 47 VIOLATION; STYLE-GUIDE.md: all sections)

Progress: [█████████░] ~92%

## Performance Metrics

**Velocity:**
- Total plans completed: 9
- Average duration: ~5 min
- Total execution time: ~54 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-schema-contracts | 3 | ~16 min | ~5 min |
| 02-analysis-agent | 2 | ~19 min | ~9 min |
| 03-synthesizer-agent | 2 | ~11 min | ~5 min |
| 04-platform-generators | 2 | ~14 min | ~7 min |
| 05-rules-and-style-guide | 2 | ~8 min | ~4 min |

**Recent Trend:**
- Last 5 plans: 04-01 (React generator + validation, ~6 min), 04-02 (SwiftUI generator + validation, ~8 min), 05-01 (rules agent prompt, ~4 min), 05-02 (rules agent validation, ~4 min)
- Trend: Steady, accelerating on execution-heavy plans

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
- Analyzer agent rationale field is open object keyed by semantic assignment key — mirrors semantic_assignments shape without a separate key list
- partial_failure=true + third allOf entry widens typography/spacing to ["object","null"] — enables partial extraction without breaking required-field constraints
- Analyzer writes to caller-specified output_path — orchestrator controls output location
- Analyzer asserts bold semantic role assignments with rationale; synthesizer can override — null discards observations, rationale-qualified guess is better
- Analyzer embedded rubric pattern: Phase 1 rubric copied verbatim into agent prompt — zero external references at agent runtime
- ajv-cli requires --spec=draft2020 flag for JSON Schema 2020-12 $schema URI — without it, validation fails with 'no schema with key or ref' error
- Analyzer E2E confirmed: produces plausible schema-conformant output; pink accent (#E0446E) assigned feedback_error with rationale documenting alternative interpretation; font identified as Satoshi with alternatives noted
- Synthesizer hex quantization: nearest multiple of 16 per RGB channel (±8) — collapses rendering noise, preserves intentional differences like Tailwind blue-500 vs blue-600
- Synthesizer conflict log built incrementally (IMMEDIATELY on conflict detection, not reconstructed at end) — prevents agent from losing track of conflicts
- Derivation vs. conflict distinction: missing tokens use $description, multi-source conflicts use conflict_log — satisfies schema minItems:2 on candidates
- "Pick dominant, don't blend" is enforced by listing specific contradicting tags to remove per tone value in the aesthetic pass
- design-system.schema.json must not use format:date-time — ajv-cli cannot validate it without ajv-formats package; string type with description is sufficient
- Synthesizer E2E confirmed: produces schema-conformant, human-inspectable design-system.json from a single real finding; forest-green Luxora brand system with Satoshi typography
- feedback.info uses brand green (#1F3A1F) not blue in Luxora system — palette has no blue; generator agents must account for this
- React generator forwardRef applied to all 6 components (not just DOM wrappers) — consistency beats selective application, avoids maintenance burden
- Raw className concatenation (${className ?? ''}) over cn() utility — keeps generated design system files dependency-free
- Button ghost variant: transparent bg, text-text color, hover:bg-surface-inset; Outline variant adds border border-border — distinct by presence of border
- Input size variants (sm/md/lg) included despite Phase 1 spec showing size-less Input — CONTEXT.md locked sizes for Input
- Style Dictionary v5 {light,dark} $value concern RESOLVED: tokens.css is authoritative CSS output; tokens.json includes $comment documenting SD limitation; no custom preprocessor needed for Phase 4 scope
- SwiftUI generator Luxora radius values from design-system.json used over swiftui-spec.md defaults (sm=8, md=16, lg=24 vs. spec's 4/8/12) — JSON values are the actual design system decisions
- Shadow alpha computed from 8-digit hex #0000000F exactly (0.059) rather than rounding to spec default 0.05 — exact JSON value honored
- Aesthetic guard uses WARNING prefix (not VIOLATION) — aesthetic violations require human judgment; token rules use VIOLATION for binary testability
- Vibe narrative must NOT use generic descriptors; MUST name typeface; MUST use 2+ personality_tags verbatim; MUST include 2+ anti-examples — enforced by hard rules in agent prompt
- Section-marker algorithm written as explicit pseudocode (CASE 1/2/3) — makes CLAUDE.md replacement logic unambiguous for executing agent
- Component usage rules include import path guidance (import from "@/design-system") — prevents usage without correct import
- CLAUDE.md created via CASE 3 (new file) — section markers correct, idempotency confirmed via CASE 1 re-run analysis
- CSS variable names (--color-primary) included in React section explanatory note — Tailwind utility names used as rule subjects per agent design intent

### Pending Todos

None.

### Blockers/Concerns

- Phase 2 (Analyzer): Prompt engineering empirical test COMPLETE — extraction quality confirmed acceptable on Luxora mobile e-commerce screenshot
- Style Dictionary v5 {light, dark} $value handling: RESOLVED — tokens.css is authoritative; tokens.json includes $comment documenting SD limitation; no custom preprocessor needed
- Phase 4 (SwiftUI generator) iOS target concern RESOLVED: iOS 16 chosen and documented in swiftui-spec.md

## Session Continuity

Last session: 2026-02-18
Stopped at: Completed 05-02-PLAN.md (rules agent validation — CLAUDE.md 45 NEVER/47 VIOLATION, STYLE-GUIDE.md all sections, idempotency confirmed)
Resume file: None
