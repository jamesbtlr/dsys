---
phase: 01-schema-contracts
plan: 02
subsystem: schema
tags: [json-schema, dtcg, design-tokens, w3c, style-dictionary]

requires: []
provides:
  - Human-readable token schema spec (token-schema.md) covering all 6 token categories
  - Machine-readable JSON Schema 2020-12 (design-system.schema.json) validating design-system.json
  - Two-layer color architecture spec (primitive + semantic) with all 18 semantic roles
  - Theme-aware color token pattern using {light, dark} $value objects
  - Required conflict_log field in meta for synthesis transparency
affects:
  - phase 2 (analyzer agent): analysis findings schema must map to these token categories
  - phase 3 (synthesizer agent): must produce output conforming to design-system.schema.json
  - phase 4 (generator agents): consume design-system.json to produce platform artifacts

tech-stack:
  added: []
  patterns:
    - "Two-layer token architecture: primitive (raw values) + semantic (role-based, theme-aware references)"
    - "Theme-aware $value pattern: {light, dark} object for semantic color tokens"
    - "W3C DTCG Format Module 2025.10: $value, $type, $description reserved fields throughout"
    - "Agent fill-in template pattern: complete JSON example doubles as synthesizer template"
    - "Required-not-absent pattern: conflict_log always present (may be empty [])"

key-files:
  created:
    - skills/dsys/references/token-schema.md
    - skills/dsys/schemas/design-system.schema.json
  modified: []

key-decisions:
  - "Semantic color taxonomy fixed to 18 roles: action (primary/secondary/destructive), surface (default/raised/overlay/inset), text (primary/secondary/muted/inverse/link), border (default/focus), feedback (success/error/warning/info)"
  - "Theme-aware $value is an object {light, dark} not separate files — keeps tokens co-located, avoids synchronization bugs"
  - "conflict_log is always required in meta (never optional, may be empty []) — makes synthesis auditable"
  - "font_family allows null for roles not observed in benchmarks — required field, never absent"
  - "tokens.shadow and tokens.opacity are type ['array','null'] and ['object','null'] — explicit null for absence"
  - "dimensionToken $value uses px suffix pattern (e.g. '16px') — string not number"
  - "semanticColorToken requires $description — documents intent on every role-based token"

patterns-established:
  - "JSON Schema 2020-12 with $defs for reusable token fragments (colorToken, semanticColorToken, dimensionToken, etc.)"
  - "additionalProperties: false on all defined objects for strict validation"
  - "oneOf pattern for semanticColorToken $value: either flat string or {light, dark} object"

requirements-completed:
  - ORCH-04

duration: 6min
completed: 2026-02-17
---

# Phase 1 Plan 02: Design System Token Schema Summary

**W3C DTCG-format JSON Schema 2020-12 and human-readable spec for design-system.json, with two-layer color architecture, 18 semantic roles, and theme-aware {light, dark} $value pattern**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-02-17T18:29:43Z
- **Completed:** 2026-02-17T18:35:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Complete human-readable spec (`token-schema.md`) covering all 8 required sections: overview, top-level structure, meta, tokens (all 6 categories), aesthetic, platform_notes, complete example, design rationale
- Machine-readable JSON Schema 2020-12 (`design-system.schema.json`) with 7 reusable `$defs` fragments and strict validation (additionalProperties: false throughout)
- All 18 semantic color roles enumerated and required in schema: action (3), surface (4), text (5), border (2), feedback (4)
- Complete example JSON in token-schema.md validated as both parseable and structurally conformant with the schema (56 structural checks pass)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create design-system.json human-readable spec** - `a45a948` (docs)
2. **Task 2: Create design-system.json JSON Schema 2020-12** - `be81865` (feat)

**Plan metadata:** (committed with this SUMMARY.md)

## Files Created/Modified

- `skills/dsys/references/token-schema.md` - Human-readable spec with 8 sections, field-by-field documentation, and a complete valid JSON example usable as a synthesizer fill-in template
- `skills/dsys/schemas/design-system.schema.json` - JSON Schema 2020-12 with strict validation; 7 reusable $defs fragments; supports theme-aware {light,dark} $value via oneOf

## Decisions Made

- **Semantic taxonomy locked to 18 roles** across 5 groups (action/surface/text/border/feedback). Chosen to cover SaaS dashboards, consumer apps, and marketing sites — the universality requirement from CONTEXT.md.
- **conflict_log required (never optional)**: Always present in meta, may be empty array. Ensures synthesis decisions are auditable without consumers needing to check for key existence.
- **font_family roles always required, may be null**: `sans`, `mono`, `display` are always present keys; value is null if not observed. Prevents absent-key inconsistency in downstream agents.
- **shadow and opacity use type ["array","null"] / ["object","null"]**: Explicit null representation for "not found" — the plan's anti-pattern note (Pitfall 1 from RESEARCH.md) enforced in schema.
- **dimensionToken $value as string with px suffix**: `"16px"` not `16` — matches DTCG dimension type spec and Style Dictionary v5 expectations.
- **semanticColorToken $description required**: Every semantic token must document its intended use — prevents role ambiguity in downstream generators.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- design-system.json contract is fully specified; synthesizer agent (Phase 3) can be written to produce conformant output
- analysis-findings.schema.json (from Plan 01-01 or adjacent plan) must be checked for semantic_assignments field alignment with the 18 color roles defined here
- Style Dictionary v5 `{light, dark}` $value handling requires a custom preprocess step — document this in platform-specs (Phase 1, subsequent plans)

---
*Phase: 01-schema-contracts*
*Completed: 2026-02-17*

## Self-Check: PASSED

- FOUND: skills/dsys/references/token-schema.md
- FOUND: skills/dsys/schemas/design-system.schema.json
- FOUND: .planning/phases/01-schema-contracts/01-02-SUMMARY.md
- FOUND commit a45a948 (docs(01-02): create design-system.json human-readable token spec)
- FOUND commit be81865 (feat(01-02): create design-system.json JSON Schema 2020-12)
