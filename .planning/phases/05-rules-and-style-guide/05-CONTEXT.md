# Phase 5: Rules and Style Guide - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Generate CLAUDE.md enforcement rules and a human-readable style guide from design-system.json. Rules make the design system self-enforcing in future Claude sessions. Style guide documents the system for human reference. No new extraction, synthesis, or generation capabilities.

</domain>

<decisions>
## Implementation Decisions

### Rule content and prohibitions
- Rules enforce both token usage AND component patterns (use DSButton not raw `<button>`, use `--color-primary` not `#1F3A1F`)
- Platform-specific rule sections: separate React/Tailwind rules and SwiftUI rules, not a unified block
- Include an aesthetic guard section alongside mechanical token rules — warns against choices that break the design vibe (e.g., "don't use neon accents in a luxury brand")
- Every rule must be yes/no answerable: "does this code violate this rule?"
- Only generate rules for platforms the user actually selected during generation

### Style guide format
- Markdown (.md) format
- Lives at `.dsys/STYLE-GUIDE.md` alongside tokens and components

### Vibe narrative
- Primary audience: AI (Claude) — optimized for giving future Claude sessions aesthetic context
- Length: paragraph (5-8 sentences) — enough to convey mood, influences, and anti-patterns
- Include concrete anti-examples ("this is NOT a playful SaaS brand, don't use rounded pill buttons")
- Abstract description only — don't reference source benchmark names, the design system stands on its own

### Output placement
- CLAUDE.md rules: append directly to the project's existing CLAUDE.md (or create it) for immediate enforcement
- Platform-conditional: only generate rules/docs for platforms the user actually selected in Phase 4
- Style guide: `.dsys/STYLE-GUIDE.md`

### Claude's Discretion
- Deviation handling strategy (hard prohibit vs. annotated override vs. soft warning) — Claude picks best practice
- Color swatch representation in Markdown (table structure, grouping by category)
- Typography detail level in style guide (scale table only vs. scale + usage guidance)
- Whether style guide includes component gallery or just tokens
- How to handle replacing existing design system rules in CLAUDE.md (section markers vs. append)

</decisions>

<specifics>
## Specific Ideas

- Vibe narrative should help Claude avoid common AI-generated aesthetic defaults — the anti-examples are specifically for this purpose
- Rules should be the kind of thing you can grep for in a code review: mechanical, concrete, enforceable
- The aesthetic guard bridges the gap between "use this token" (mechanical) and "this brand feels like X" (vibe) — it's the enforcement layer for aesthetic intent

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-rules-and-style-guide*
*Context gathered: 2026-02-18*
