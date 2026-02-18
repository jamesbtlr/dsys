---
phase: 05-rules-and-style-guide
plan: 01
subsystem: ui
tags: [agent-prompt, rules, style-guide, claude-md, design-system, markdown]

# Dependency graph
requires:
  - phase: 04-platform-generators
    provides: "react-generator.md and swiftui-generator.md establish agent anatomy; token name conventions (Color.dsActionPrimary, --color-primary, DSSpacing, DSRadius) confirmed from those agents"
  - phase: 03-synthesizer-agent
    provides: "design-system.json schema and aesthetic/tokens structure that rules agent reads at runtime"
provides:
  - "rules.md agent prompt that reads design-system.json and writes CLAUDE.md rules block and .dsys/STYLE-GUIDE.md"
  - "Section-marker algorithm for idempotent CLAUDE.md management"
  - "Platform-conditional rule sections gated on platforms input parameter"
  - "52 NEVER prohibitions and 56 VIOLATION test patterns (binary yes/no testable)"
  - "Aesthetic guard section template with anti-example derivation rules"
  - "Vibe narrative template drawing from aesthetic.summary, personality_tags, tone, density"
  - "Embedded token name reference tables (React CSS vars, SwiftUI Color.ds*, DSSpacing, DSRadius, component names)"
  - "STYLE-GUIDE.md section templates (color tables, typography scale, spacing scale, border radius, shadows, component API reference)"
affects:
  - "05-02 (validation plan — runs this agent against Luxora design-system.json)"
  - "All future projects using dsys tool (this agent is the rules generation endpoint)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Agent anatomy: frontmatter, role, input, 11 numbered steps, self-check, return summary — identical to react-generator.md and swiftui-generator.md"
    - "Section-marker strategy: <!-- dsys:rules:start --> / <!-- dsys:rules:end --> for idempotent CLAUDE.md management"
    - "Rule anatomy: imperative + token name + NEVER prohibition + VIOLATION test (grep-able, binary yes/no)"
    - "Aesthetic guard: WARNING prefix (not VIOLATION) for aesthetic rules requiring human judgment"
    - "Platform conditional: platforms input gates which rule sections and table columns are emitted"
    - "Vibe narrative: 5-8 sentences for AI audience, must include typeface name + 2+ anti-examples, no generic adjectives"

key-files:
  created:
    - skills/dsys/agents/rules.md
  modified: []

key-decisions:
  - "Aesthetic guard uses WARNING prefix (not VIOLATION) — aesthetic violations require human judgment; token rules use VIOLATION"
  - "Vibe narrative must NOT use generic descriptors (clean, modern, professional) — must use specific personality_tags verbatim"
  - "Section-marker algorithm embedded verbatim as pseudocode — agent can reconstruct CLAUDE.md correctly without external references"
  - "Both React CSS var column and SwiftUI Swift property column in style guide tables — each conditional on platforms parameter"
  - "Component rule includes import path guidance: import from @/design-system — prevents component usage without correct import"

patterns-established:
  - "Rule anatomy: '- Use [token name] for [purpose]. NEVER [prohibited alternative]. Does this code contain [pattern]? VIOLATION.'"
  - "Aesthetic guard anti-examples: invert personality_tags + target rounded/pill/AI-default patterns + target non-brand colors"
  - "Style guide table structure: primitive palette first (overview), then semantic colors (usage guide) — both useful"
  - "Platform-conditional table columns: emit only if platform is in platforms array — no irrelevant columns"

requirements-completed: [RULES-01, RULES-02, RULES-03, DOCS-01, DOCS-02]

# Metrics
duration: 4min
completed: 2026-02-18
---

# Phase 5 Plan 01: Rules and Style Guide Agent Summary

**Self-contained rules agent prompt (928 lines) with 52 NEVER prohibitions, 56 VIOLATION tests, section-marker CLAUDE.md management, and complete STYLE-GUIDE.md table templates**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-18T10:48:49Z
- **Completed:** 2026-02-18T10:53:01Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Wrote `skills/dsys/agents/rules.md` (928 lines) following the exact agent anatomy established by `react-generator.md` and `swiftui-generator.md`
- Embedded all 5 token categories with platform-conditional rule sections: colors, typography, spacing, border radius, shadows, component usage, dark mode
- Embedded complete token name reference tables: 18 React/Tailwind CSS var → Tailwind utility mappings, 18 SwiftUI `Color.ds*` property names, DSSpacing properties, DSRadius constants, component names for both platforms
- Included section-marker algorithm as pseudocode for idempotent CLAUDE.md management
- Built aesthetic guard section template with anti-example derivation rules and vibe narrative template

## Task Commits

1. **Task 1: Write rules.md agent prompt** - `ea89450` (feat)

## Files Created/Modified

- `skills/dsys/agents/rules.md` — Complete rules and style guide generation agent prompt (928 lines)

## Decisions Made

- Aesthetic guard uses "WARNING" prefix (not "VIOLATION") — aesthetic violations require design team judgment; mechanical token rules use "VIOLATION" for binary testability (per RESEARCH.md open question resolution)
- Vibe narrative hard rules embedded: must NOT use "clean and modern", "professional", "user-friendly"; MUST name the typeface; MUST use 2+ personality_tags verbatim; MUST include 2+ anti-examples
- Section-marker algorithm written as explicit pseudocode with CASE 1/2/3 — makes the replacement logic unambiguous for the executing agent
- Component usage rules include import path guidance (`import from "@/design-system"`) — prevents the common mistake of using components without correct import
- Style guide uses two color tables: primitive palette (overview) then semantic colors (usage guide) — both useful per RESEARCH.md Pattern 5 recommendation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `skills/dsys/agents/rules.md` is ready for validation in Phase 5 Plan 02
- Validation plan (05-02) will run this agent against the Luxora `design-system.json` and inspect both output files
- The agent is self-contained — no external references at runtime

## Self-Check: PASSED

Files verified:
- `skills/dsys/agents/rules.md`: FOUND (928 lines)
- Commit `ea89450`: FOUND

Checks passed:
- Frontmatter present (---markers, name, description, tools)
- `## Role`, `## Input`, `## Step 1` through `## Step 11`, `## Step 10: Self-Check` all present
- `<!-- dsys:rules:start -->` section marker embedded
- `Color.dsActionPrimary` Swift property referenced
- `--color-primary` CSS variable referenced
- 52 NEVER prohibitions (target: 15+)
- 56 VIOLATION test patterns (target: 10+)
- `Aesthetic Guard` section present
- `personality_tags` referenced 10 times
- `platforms` referenced 30 times

---
*Phase: 05-rules-and-style-guide*
*Completed: 2026-02-18*
