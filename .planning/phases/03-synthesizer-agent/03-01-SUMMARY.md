---
phase: 03-synthesizer-agent
plan: 01
subsystem: ai-agent
tags: [prompt-engineering, design-tokens, dtcg, json-merge, conflict-resolution]

# Dependency graph
requires:
  - phase: 01-schema-contracts
    provides: design-system.schema.json, token-schema.md, analysis-findings.schema.json
  - phase: 02-analysis-agent
    provides: analyzer agent anatomy pattern, analysis findings JSON format
provides:
  - skills/dsys/agents/synthesizer.md — multi-finding synthesis agent prompt with embedded merge algorithm
  - Frequency-weighted voting algorithm with hex quantization for conflict resolution
  - Derivation table for 4 missing semantic tokens (surface.overlay/inset, text.secondary/link)
  - Dark-mode inference heuristics for all _dark semantic color roles
  - Complete findings-to-output mapping (21 findings keys → design-system.json paths)
affects:
  - 04-react-generator — reads design-system.json produced by synthesizer
  - 05-swiftui-generator — reads design-system.json produced by synthesizer
  - orchestrator — invokes synthesizer via Task with findings_paths and output_path

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Multi-pass merge algorithm: one numbered pass per token category prevents reasoning contamination"
    - "Quantize-before-compare: nearest-16 per RGB channel collapses rendering noise, preserves intentional differences"
    - "Incremental conflict logging: conflict_log entries added IMMEDIATELY during merge pass, not reconstructed at end"
    - "Pick dominant, don't blend: aesthetic enum values voted, minority signals discarded, no interpolation"
    - "Derivation vs. conflict distinction: missing tokens use $description, multi-source conflicts use conflict_log"

key-files:
  created:
    - skills/dsys/agents/synthesizer.md
  modified: []

key-decisions:
  - "Hex quantization threshold: nearest multiple of 16 per channel (±8 range) — tight enough to distinguish Tailwind blue-500 from blue-600, loose enough to merge rendering noise"
  - "Conflict log built incrementally during merge passes — agent appends IMMEDIATELY on conflict, not at end of synthesis"
  - "Derivations documented via $description, not conflict_log — preserves schema constraint (candidates requires >=2 entries)"
  - "Caller-specified output_path with .dsys/design-system.json default — consistent with analyzer agent pattern"
  - "Pick dominant aesthetic direction, remove contradicting personality_tags — no blending across mixed aesthetic inputs"

patterns-established:
  - "Agent anatomy: frontmatter + role + input + numbered steps + embedded template (established in Phase 2, confirmed here)"
  - "Derivation table pattern: explicit table mapping required output tokens to derivation rules prevents agent improvisation"
  - "Dark-mode heuristic table: explicit per-token rules for inferring dark values when _dark keys are null"

requirements-completed:
  - SYNTH-01
  - SYNTH-02
  - SYNTH-03
  - ORCH-03

# Metrics
duration: 3min
completed: 2026-02-18
---

# Phase 3 Plan 1: Synthesizer Agent Summary

**655-line synthesizer agent prompt with 13-pass merge algorithm, hex quantization, conflict logging, and complete design-system.json fill-in template**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T00:26:30Z
- **Completed:** 2026-02-18T00:29:55Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Wrote `skills/dsys/agents/synthesizer.md` — 655-line agent prompt that merges N analysis findings into design-system.json
- Embedded complete 13-step merge algorithm with hex quantization (nearest-16 per channel), frequency-weighted voting, tiebreaker rules, and incremental conflict_log building
- Included complete 21-key findings-to-output mapping table plus derivation table for 4 missing semantic tokens
- Embedded verbatim design-system.json fill-in template from token-schema.md Section 7
- Self-validation checklist (Step 11) covers all schema requirements before write

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the synthesizer agent prompt** - `0b8c19d` (feat)

**Plan metadata:** (docs commit to follow)

## Files Created/Modified

- `skills/dsys/agents/synthesizer.md` - Complete synthesizer agent prompt with 13 merge passes, conflict resolution algorithm, and embedded output template

## Decisions Made

- **Quantization threshold:** Nearest multiple of 16 per RGB channel (±8 per channel). This collapses rendering noise (#1a73e8 and #1b74e9 → same bucket) while preserving genuine design differences (Tailwind blue-500 vs blue-600 map to different buckets).
- **Incremental conflict logging:** The prompt explicitly instructs IMMEDIATELY adding a conflict_log entry at the moment of conflict detection, not at the end. This prevents the agent from forgetting which tokens conflicted.
- **Derivation vs. conflict distinction:** Derived tokens (surface.overlay, surface.inset, text.secondary, text.link) use `$description` to document the derivation rule. Only multi-source conflicts go in `conflict_log` — this satisfies the schema's `minItems: 2` constraint on `candidates`.
- **Partial failure handling:** If ALL findings have null typography or spacing, produce sensible defaults and document them in `$description`. Do NOT add defaults to conflict_log (they are not conflicts). This keeps the pipeline runnable.
- **"Pick dominant, don't blend":** Aesthetic pass explicitly lists which personality_tags to remove for each tone value. Prevents aesthetic blending from mixed-input benchmarks.

## Deviations from Plan

None — plan executed exactly as written.

The quantization formula description in Step 3 includes worked examples showing the math explicitly. The plan said to include concrete examples; the executed file includes more detailed math than the skeleton showed, which is additive (makes the agent more reliable) rather than a deviation.

## Issues Encountered

None.

## Next Phase Readiness

- `skills/dsys/agents/synthesizer.md` is complete and ready to be invoked by the orchestrator via `Task(agent: "skills/dsys/agents/synthesizer.md", prompt: "...")`
- The orchestrator must pass `findings_paths` (list of paths) and optionally `output_path`
- Phase 4 (React generator) and Phase 5 (SwiftUI generator) both depend on `design-system.json` produced by the synthesizer

---
*Phase: 03-synthesizer-agent*
*Completed: 2026-02-18*

## Self-Check: PASSED

- `skills/dsys/agents/synthesizer.md`: FOUND
- `.planning/phases/03-synthesizer-agent/03-01-SUMMARY.md`: FOUND
- Commit `0b8c19d`: FOUND
