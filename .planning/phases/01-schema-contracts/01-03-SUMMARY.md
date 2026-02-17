---
phase: 01-schema-contracts
plan: 03
subsystem: schema
tags: [react, tailwind, swiftui, design-tokens, platform-specs, dtcg, css-custom-properties]

requires:
  - plan: "01-02"
    provides: "design-system.schema.json and token-schema.md — the contract the generator reads"

provides:
  - File manifest and content spec for React/Tailwind generator (9 output files)
  - File manifest and content spec for SwiftUI generator (12 output files)
  - Tailwind v4 @theme pattern with --color-*: initial; reset
  - CSS custom property structure with --ds- prefix and light/dark theme blocks
  - SwiftUI Color(named:bundle:.module) pattern enforced over raw hex
  - @ScaledMetric spacing struct pattern for Dynamic Type support
  - xcassets colorset Contents.json structure (sRGB decimal, light + luminosity/dark)
  - Component templates for Button, Card, Input, Badge, Heading, Text on both platforms
  - Done checklists for both platforms with objectively-verifiable pass/fail criteria

affects:
  - phase 4 (generator agents): these specs are the exact contract each generator must satisfy
  - phase 3 (synthesizer agent): synthesizer must produce design-system.json that maps to both platform specs

tech-stack:
  added: []
  patterns:
    - "Tailwind v4 @theme block with --color-*: initial; as the first declaration — replaces tailwind.config.js"
    - "CSS --ds- prefix namespace for design system variables — avoids collision with Tailwind-generated variables"
    - "React.forwardRef pattern for all DOM-wrapping components with className composition"
    - "Color(named:bundle:.module) in SwiftUI — never Color(hex:) — enables asset catalog dark mode adaptation"
    - "@ScaledMetric instance properties in DSSpacing struct (not static) for Dynamic Type support"
    - "DS prefix on all SwiftUI components to avoid collision with SwiftUI built-in views"
    - "xcassets colorset: sRGB decimal strings, luminosity/dark appearance key for dark mode"
    - "#Preview macro on every SwiftUI component for Xcode canvas preview"

key-files:
  created:
    - skills/dsys/references/platform-specs/react-tailwind-spec.md
    - skills/dsys/references/platform-specs/swiftui-spec.md
  modified: []

key-decisions:
  - "React/Tailwind generator must reset Tailwind default palette via --color-*: initial; inside @theme — without this all 100+ default Tailwind colors coexist with design system tokens, defeating enforcement"
  - "tokens.css uses --ds- prefix for CSS variables; theme.css maps Tailwind @theme names to --ds- vars — separation allows runtime theme-switching without Tailwind rebuild"
  - "SwiftUI colors MUST use Color(name:bundle:.module) referencing asset catalog — not Color(hex:); asset catalog provides automatic OS-managed dark mode"
  - "DSSpacing uses @ScaledMetric instance properties (not static) — @ScaledMetric is a property wrapper requiring instance scope"
  - "SwiftUI components prefixed DS (DSButton, DSCard) to avoid collision with SwiftUI built-in view names"
  - "iOS 16 set as minimum target — provides NavigationStack, @ScaledMetric, Color(name:bundle:) without requiring iOS 17+ APIs"

patterns-established:
  - "Platform spec as file manifest: lists every output file with purpose and Required flag"
  - "Done checklist pattern: objectively verifiable pass/fail criteria (not subjective 'production-ready')"
  - "Component template pattern: design system token names only, no raw values, className/foregroundStyle composition"

requirements-completed:
  - ORCH-04

duration: 4min
completed: 2026-02-17
---

# Phase 1 Plan 03: Platform Output Specifications Summary

**Precise file manifests and code templates for React/Tailwind (9 files, Tailwind v4 @theme with --color-*: initial; reset) and SwiftUI (12 files, Color(named:bundle:.module) + @ScaledMetric spacing) generators**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-02-17T18:38:39Z
- **Completed:** 2026-02-17T18:43:14Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- React/Tailwind spec covering all 8 required sections: overview, 9-file manifest, tokens.json DTCG spec, tokens.css with :root + @media + .dark blocks, theme.css with @theme reset, 6 component templates, naming conventions, Done checklist
- SwiftUI spec covering all 11 required sections: overview, 12-entry manifest, Colors+DesignSystem.swift with Color(named:bundle:.module) pattern, Colors.xcassets colorset Contents.json structure, Typography/Spacing/Radius/Shadows specs, 6 component templates with #Preview blocks, naming conventions, Done checklist
- Both specs include concrete, generator-executable code examples for every output file — not prose descriptions of intent
- Both specs reference `design-system.json` as the generator input and include objectively-verifiable Done checklists

## Task Commits

Each task was committed atomically:

1. **Task 1: Create React/Tailwind platform output spec** - `4a67ff7` (docs)
2. **Task 2: Create SwiftUI platform output spec** - `df8a9fb` (docs)

**Plan metadata:** (committed with this SUMMARY.md)

## Files Created/Modified

- `skills/dsys/references/platform-specs/react-tailwind-spec.md` - React/Tailwind generator spec: 9-file manifest, tokens.json DTCG example, tokens.css with :root/dark blocks, theme.css with @theme reset, Button/Card/Input/Badge/Heading/Text component templates, naming conventions, Done checklist
- `skills/dsys/references/platform-specs/swiftui-spec.md` - SwiftUI generator spec: 12-entry manifest, Colors+DesignSystem.swift with Color(named:) pattern, xcassets colorset Contents.json structure, Typography/Spacing/Radius/Shadows Swift examples, DSButton/DSCard/DSInput/DSBadge/DSHeading/DSText templates with #Preview, naming conventions, Done checklist

## Decisions Made

- **`--color-*: initial;` is non-negotiable in theme.css:** Without this reset, the full Tailwind default palette (100+ colors) coexists with the design system palette. The reset is what makes the design system enforceable — components using `bg-blue-500` break, forcing developers to use `bg-primary`.
- **`--ds-` CSS variable prefix separation:** `tokens.css` defines `--ds-color-action-primary` (raw value), `theme.css` maps `--color-primary: var(--ds-color-action-primary)`. This separation allows runtime theme-switching by swapping `--ds-*` values without regenerating the Tailwind build.
- **SwiftUI asset catalog over raw hex is enforced (not suggested):** The Done checklist explicitly forbids `Color(hex:)`, `UIColor(red:green:blue:alpha:)`, and `Color(.sRGB, red:green:blue:opacity:)`. Only `Color("name", bundle: .module)` is permitted — this is the mechanism that gives automatic OS-managed dark mode.
- **`@ScaledMetric` requires instance scope:** Documented explicitly because this is a common Swift mistake. The spec shows both `DSSpacing` (instance, scales with Dynamic Type) and `DSSpacingFixed` (static enum, does not scale) for cases where fixed layout values are needed.
- **iOS 16 as minimum target:** Provides `NavigationStack`, modern `@FocusState` APIs, and full `@ScaledMetric` support. iOS 14 would be the technical minimum for Color(named:) and @ScaledMetric, but iOS 16 gives more complete SwiftUI API coverage for component templates.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Both platform specs define exact file manifests — Phase 4 generator agents have unambiguous output targets
- React/Tailwind spec enforces Tailwind v4 @theme reset pattern and design-system token names in all component templates
- SwiftUI spec enforces asset catalog colors, @ScaledMetric spacing, and #Preview blocks
- Style Dictionary v5 `{ light, dark }` $value handling still requires empirical testing (documented in RESEARCH.md as LOW confidence) — must be verified before Phase 4 React generator is finalized
- Phase 1 has one remaining concern: analysis-findings.schema.json `semantic_assignments` keys must be verified against the 18 color roles defined in 01-02 — this may be a task in a subsequent Phase 1 plan or the overlap is already correct

---
*Phase: 01-schema-contracts*
*Completed: 2026-02-17*

## Self-Check: PASSED

- FOUND: skills/dsys/references/platform-specs/react-tailwind-spec.md
- FOUND: skills/dsys/references/platform-specs/swiftui-spec.md
- FOUND: .planning/phases/01-schema-contracts/01-03-SUMMARY.md
- FOUND commit 4a67ff7 (docs(01-03): create React/Tailwind platform output spec)
- FOUND commit df8a9fb (docs(01-03): create SwiftUI platform output spec)
