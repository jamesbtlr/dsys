# dsys-tool

## What This Is

A Claude Code skill that generates complete design systems from visual benchmarks. You feed it screenshots or URLs of sites you admire, and it analyzes them to produce tokens, components, documentation, and enforcement rules — so every piece of UI you build with AI afterwards is cohesive and on-brand. Supports React/Tailwind and SwiftUI output targets.

## Core Value

AI-generated UI should look intentional, not generic. This tool front-loads design decisions from real-world references so that every subsequent build session produces cohesive results.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User can feed benchmark screenshots to the tool for visual analysis
- [ ] Tool extracts design patterns, colors, typography, spacing, and aesthetic from benchmarks
- [ ] Tool synthesizes findings across multiple benchmarks into a coherent design system
- [ ] Tool outputs platform-agnostic design tokens (colors, spacing, typography scales)
- [ ] Tool outputs React/Tailwind artifacts (Tailwind config, utility classes, component templates)
- [ ] Tool outputs SwiftUI artifacts (Color/Font extensions, spacing constants, view templates)
- [ ] User can choose which platform target(s) to generate for their project
- [ ] Tool generates CLAUDE.md rules that enforce the design system in future coding sessions
- [ ] Tool produces a style guide document describing the system's rules and patterns
- [ ] Output is drop-in ready — user can immediately build UI using the generated system

### Out of Scope

- Figma/Sketch file import — screenshots are the input format for v1
- Real-time design system evolution (iterating as you build) — v1 is upfront generation
- MCP server packaging — skill-only delivery for v1, MCP considered for productization
- Code-based benchmark input (existing stylesheets/components) — visual-first approach
- Design system hosting or CDN distribution — local project files only

## Context

- Built as a Claude Code skill, orchestrating sub-agents for parallel benchmark analysis
- Architecture: skill entry point → N parallel analysis agents (one per benchmark) → synthesizer agent → generator → rules output
- Claude's multimodal vision capabilities are used to analyze screenshot inputs
- The enforcement layer (generated CLAUDE.md rules) is what makes this sticky — once created, the design system is automatically applied in all future Claude Code sessions for that project
- SwiftUI support is non-negotiable; the tool must treat native iOS as a first-class target alongside web
- Variable number of benchmark inputs (1 to many) — the tool should handle both a single hero reference and a broader mood board

## Constraints

- **Platform**: Claude Code skill — must work within Claude Code's skill/agent framework
- **Input format**: Screenshots (images) analyzed via Claude's vision — no external OCR or style extraction APIs for v1
- **Output targets**: React + Tailwind CSS and SwiftUI — both must be supported, user chooses per project
- **Personal first**: Architecture should be clean enough to productize later, but don't over-engineer for that now

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Claude Code skill (not CLI or MCP) | Leverages Claude's vision for analysis, natural UX for developers already in Claude Code | — Pending |
| Parallel sub-agents for analysis | Each benchmark analyzed independently, then synthesized — scales with variable input count | — Pending |
| Rules as enforcement output | Generated CLAUDE.md rules make the design system self-enforcing in future sessions | — Pending |
| Screenshots over code/Figma input | Visual-first approach matches how designers think about references; simpler input pipeline | — Pending |
| Both platforms from v1 | User chooses target(s) per project; SwiftUI is non-negotiable so can't defer it | — Pending |

---
*Last updated: 2026-02-17 after initialization*
