# Phase 4: Platform Generators - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Transform design-system.json into drop-in project files for React/Tailwind and SwiftUI. Users select which platform(s) to generate. Output includes design tokens, starter components (Button, Card, Input, Badge, Heading, Text), and barrel/index files. Enforcement rules and the orchestrator slash command are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Component depth
- Production-ready components: fully styled with multiple variants, states, and accessibility attributes
- Button variants: full set — primary, secondary, destructive, ghost, outline
- Size variants only where natural: Button and Input get sm/md/lg; Card, Badge, Heading, Text do not
- Full interactive states: disabled, loading (with spinner), focus-visible, hover — production behavior out of the box

### Output organization
- Output written to project root directories: `src/design-system/` for React, `Sources/DesignSystem/` for SwiftUI
- Nested by concern: `tokens/`, `components/`, `types/` — clear separation within each platform directory
- Barrel/index files: `index.ts` (React) and `DesignSystem.swift` (SwiftUI) re-exporting all tokens and components
- Overwrite with backup: regeneration overwrites existing files but saves previous version as `.bak`

### Tailwind patterns
- Components use Tailwind utility classes internally; CSS custom properties also exported for non-Tailwind usage
- Dark mode: both prefers-color-scheme (automatic) and class-based toggle (manual override) — Tailwind v4's darkMode selector strategy
- React component pattern: Claude's discretion (forwardRef + slots vs simple function components — pick per component complexity)
- className merging approach: Claude's discretion (cn() utility vs raw concat — pick based on component complexity)

### SwiftUI component API
- Variant selection pattern: Claude's discretion (enum-based init vs view modifiers — pick most idiomatic)
- Minimal #Preview blocks: single preview with default configuration per component, user builds their own for more
- Built-in accessibility: components apply sensible default accessibilityLabel and traits — VoiceOver works out of the box
- Asset catalog JSON: generate .colorset folders with Contents.json for full Xcode integration and OS-managed dark mode switching (no Swift Color extensions as alternative)

### Claude's Discretion
- React component pattern (forwardRef + slots vs simple function components)
- className merging approach (cn() utility vs raw string concat)
- SwiftUI variant selection pattern (enum-based init vs view modifiers)

</decisions>

<specifics>
## Specific Ideas

No specific references — open to standard approaches. The existing project decisions (from STATE.md) already lock many patterns:
- tokens.css uses `--ds-` prefix; theme.css maps `@theme` names to `--ds-` vars
- `--color-*: initial;` as first @theme declaration to reset Tailwind defaults
- SwiftUI colors via `Color(name:bundle:.module)` referencing asset catalog
- DSSpacing uses `@ScaledMetric` instance properties
- SwiftUI components prefixed `DS` (DSButton, DSCard)
- iOS 16 minimum target

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-platform-generators*
*Context gathered: 2026-02-18*
