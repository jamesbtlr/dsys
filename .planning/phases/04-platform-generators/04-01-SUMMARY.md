---
phase: 04-platform-generators
plan: 01
subsystem: ui
tags: [react, tailwindcss, typescript, design-tokens, css-custom-properties, dtcg]

requires:
  - phase: 03-synthesizer-agent
    provides: "design-system.json (Luxora forest-green system) — generator input"
  - phase: 01-schema-contracts
    provides: "react-tailwind-spec.md — complete output specification for React/Tailwind"

provides:
  - "skills/dsys/agents/react-generator.md — self-contained 990-line agent prompt"
  - "src/design-system/tokens/tokens.json — W3C DTCG token reference file"
  - "src/design-system/tokens/tokens.css — CSS custom properties with dual dark mode"
  - "src/design-system/tokens/theme.css — Tailwind v4 @theme configuration"
  - "src/design-system/components/{Button,Card,Input,Badge,Heading,Text}.tsx — 6 production-ready components"
  - "src/design-system/types/design-tokens.d.ts — TypeScript token type unions"
  - "src/design-system/index.ts — barrel export file"

affects:
  - 04-02-swiftui-generator
  - 05-orchestrator

tech-stack:
  added: []
  patterns:
    - "Generator agent anatomy: frontmatter → role → input → numbered steps → embedded spec (matches Phase 2/3 pattern)"
    - "Token resolution: resolve {light,dark} $value objects before emitting CSS; handle null font roles with system fallbacks"
    - "Tailwind v4 theme: --color-*: initial; resets all defaults; @theme references var(--ds-*) for runtime theme switching"
    - "Dual dark mode: @media (prefers-color-scheme: dark) + .dark class via @custom-variant dark"
    - "Component pattern: forwardRef on all 6 components for consistency; raw string concatenation for className (no cn() dependency)"
    - "Overwrite-with-backup: Read → Write .bak → Write new; skip backup if file not found"

key-files:
  created:
    - skills/dsys/agents/react-generator.md
    - src/design-system/tokens/tokens.json
    - src/design-system/tokens/tokens.css
    - src/design-system/tokens/theme.css
    - src/design-system/components/Button.tsx
    - src/design-system/components/Card.tsx
    - src/design-system/components/Input.tsx
    - src/design-system/components/Badge.tsx
    - src/design-system/components/Heading.tsx
    - src/design-system/components/Text.tsx
    - src/design-system/types/design-tokens.d.ts
    - src/design-system/index.ts
  modified: []

key-decisions:
  - "forwardRef applied to all 6 components for consistency — not just DOM element wrappers — avoids maintenance inconsistency"
  - "Raw string concatenation (${className ?? ''}) over cn() utility — keeps generated components dependency-free"
  - "Button ghost variant: transparent bg, text-text, hover:bg-surface-inset (not text-primary like primary button)"
  - "Button outline variant: transparent bg + border border-border, hover:bg-surface-inset — distinct from ghost by border"
  - "Input size variants added (sm/md/lg) — spec showed size-less Input but CONTEXT.md locked sizes for Input"
  - "Agent prompt is self-contained — @import/@theme/@custom-variant are CSS at-rules, not runtime file references"

patterns-established:
  - "Platform generator anatomy: same structure as analyzer.md and synthesizer.md — proven pattern for runtime self-containment"
  - "DSColorToken union type generated from semantic token vocabulary — enables type-safe downstream usage"
  - "tokens.css separation from theme.css: runtime values in tokens.css, Tailwind mapping in theme.css — enables theme switching without rebuild"

requirements-completed:
  - OUT-01
  - OUT-02
  - OUT-04
  - OUT-06
  - COMP-01
  - COMP-02

duration: 6min
completed: 2026-02-18
---

# Phase 4 Plan 01: React/Tailwind Generator Summary

**Self-contained 990-line React/Tailwind generator agent prompt + 11 drop-in files generated from Luxora design-system.json (forest-green brand system with Satoshi typography)**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-18T09:51:27Z
- **Completed:** 2026-02-18T09:57:39Z
- **Tasks:** 2
- **Files modified:** 12 (1 agent prompt + 11 generated)

## Accomplishments

- Wrote `skills/dsys/agents/react-generator.md`: 990-line self-contained agent prompt with 11 generation steps, full token resolution algorithm, backup logic, 6 embedded component templates, and verbatim spec reference
- Generated all 11 React/Tailwind files from the Luxora design-system.json: CSS custom properties with dual dark mode, Tailwind v4 theme resetting defaults, 6 production-ready TypeScript components, type declarations, and barrel export
- All components use only semantic Tailwind class names (bg-primary, text-text-muted) — no raw hex, no Tailwind defaults; verified with grep

## Task Commits

Each task was committed atomically:

1. **Task 1: Write React/Tailwind generator agent prompt** - `915c718` (feat)
2. **Task 2: Validate React generator by running against design-system.json** - `c8cd5f5` (feat)

**Plan metadata:** (docs commit — see final commit below)

## Files Created/Modified

- `skills/dsys/agents/react-generator.md` — Self-contained agent prompt (990 lines): 11-step generation process, token resolution algorithm, component templates, embedded spec
- `src/design-system/tokens/tokens.json` — W3C DTCG format; primitive + semantic layers; {light,dark} $value for semantic color tokens
- `src/design-system/tokens/tokens.css` — CSS custom properties: :root (light), @media dark :root (auto), .dark class (manual); all --ds- prefixed
- `src/design-system/tokens/theme.css` — Tailwind v4: @import tailwindcss → @custom-variant dark → @theme with --color-*: initial; first
- `src/design-system/components/Button.tsx` — 5 variants (primary/secondary/destructive/ghost/outline), 3 sizes (sm/md/lg), isLoading with animate-spin spinner, aria-busy
- `src/design-system/components/Card.tsx` — bg-surface-raised, rounded-lg, border, shadow-sm
- `src/design-system/components/Input.tsx` — 3 sizes (sm/md/lg), error prop switching border-error, bg-surface-inset
- `src/design-system/components/Badge.tsx` — 5 variants with opacity-based backgrounds (bg-success/10), pill shape
- `src/design-system/components/Heading.tsx` — 4 levels → text-4xl/3xl/2xl/xl; renders as h1-h4 HTML
- `src/design-system/components/Text.tsx` — 3 color variants, 3 sizes, polymorphic `as` prop
- `src/design-system/types/design-tokens.d.ts` — DSColorToken (19 values), DSSpacingStep (13 steps), DSRadiusStep, DSFontSize unions
- `src/design-system/index.ts` — Barrel: tokens.json, 6 components + Props types, design-token types

## Decisions Made

- Applied `forwardRef` to all 6 components (not just DOM wrappers) — per research Pattern 5 recommendation; consistency beats selective application
- Used raw string concatenation `${className ?? ""}` rather than `cn()` — keeps generated files dependency-free as per research recommendation
- Ghost variant: transparent background, `text-text` color (not `text-inverse`), `hover:bg-surface-inset` — surface tint on hover, no border
- Outline variant: transparent background, `border border-border`, `text-text` color, `hover:bg-surface-inset` — distinguished from ghost by border
- Input size variants included despite Phase 1 spec showing size-less Input — CONTEXT.md locked sm/md/lg sizes for Input

## Deviations from Plan

None - plan executed exactly as written. The Luxora design-system.json uses raw hex values for all semantic tokens (no DTCG references to resolve), making token resolution straightforward.

## Issues Encountered

None. The agent prompt's grep pattern count for "@-references" returned 26 hits, but all were CSS at-rules (@theme, @import, @media, @custom-variant) — not Claude runtime file references. Agent prompt is genuinely self-contained.

## User Setup Required

None - no external service configuration required. The generated files require no manual editing. To use them in a Tailwind v4 project, add to your main CSS entry point:

```css
@import "./src/design-system/tokens/tokens.css";
@import "./src/design-system/tokens/theme.css";
```

## Next Phase Readiness

- React generator agent and validation artifacts complete — ready for Phase 4 Plan 02 (SwiftUI generator)
- All locked decisions from CONTEXT.md implemented and verified:
  - Output in `src/design-system/` with `tokens/`, `components/`, `types/` subdirectories ✓
  - Production-ready components with all specified variants and states ✓
  - Both dark mode strategies ✓
  - `--color-*: initial;` reset in theme.css ✓
  - `--ds-` prefix in tokens.css ✓
  - Overwrite-with-backup logic in agent ✓

---

## Self-Check: PASSED

**Files verified:**
- `skills/dsys/agents/react-generator.md` — FOUND (990 lines, 37327 bytes)
- `src/design-system/tokens/tokens.json` — FOUND (valid JSON, primitive + semantic layers)
- `src/design-system/tokens/tokens.css` — FOUND (:root, @media dark, .dark blocks)
- `src/design-system/tokens/theme.css` — FOUND (@import first, @custom-variant, --color-*: initial;)
- `src/design-system/components/Button.tsx` — FOUND (5 variants, isLoading, aria-busy, forwardRef)
- `src/design-system/components/Card.tsx` — FOUND (forwardRef, displayName)
- `src/design-system/components/Input.tsx` — FOUND (3 sizes, error prop, forwardRef)
- `src/design-system/components/Badge.tsx` — FOUND (5 variants, forwardRef)
- `src/design-system/components/Heading.tsx` — FOUND (4 levels, forwardRef)
- `src/design-system/components/Text.tsx` — FOUND (3 variants, polymorphic as, forwardRef)
- `src/design-system/types/design-tokens.d.ts` — FOUND (4 type exports)
- `src/design-system/index.ts` — FOUND (6 components + Props + types)

**Content verified:**
- No raw hex in components: PASS (grep found 0 matches)
- --color-*: initial; present as first @theme declaration: PASS
- @custom-variant dark present in theme.css: PASS
- 3 dark mode blocks in tokens.css: PASS (1 @media + 1 .dark = 2 occurrences of block openers, correct)
- Luxora #1F3A1F forest green in tokens.css: PASS
- Button has 5 variants: PASS (8 occurrences of variant names)
- tokens.json valid JSON: PASS

**Commits verified:**
- `915c718` — feat(04-01): write React/Tailwind generator agent prompt — FOUND
- `c8cd5f5` — feat(04-01): generate React/Tailwind design system from Luxora design-system.json — FOUND

---
*Phase: 04-platform-generators*
*Completed: 2026-02-18*
