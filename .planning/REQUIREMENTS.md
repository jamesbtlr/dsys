# Requirements: dsys-tool

**Defined:** 2026-02-17
**Core Value:** AI-generated UI should look intentional, not generic. Front-load design decisions from real-world references so every subsequent build session produces cohesive results.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Input

- [ ] **INPUT-01**: User can feed one or more benchmark screenshots to the tool
- [ ] **INPUT-02**: Tool validates image inputs and reports errors for unsupported or corrupt files
- [ ] **INPUT-03**: Tool handles variable benchmark count (1 to ~7 images)

### Extraction

- [ ] **EXTRACT-01**: Tool extracts color palette with named primitive tokens from each benchmark
- [ ] **EXTRACT-02**: Tool extracts typography tokens (font family, weight, size scale, line-height) from each benchmark
- [ ] **EXTRACT-03**: Tool extracts spacing scale from observed whitespace in each benchmark
- [ ] **EXTRACT-04**: Tool generates semantic aliases (primary, secondary, danger, success, muted) mapped to primitive tokens
- [ ] **EXTRACT-05**: Tool reasons about design intent, not raw pixel values (quantizes colors to standard values, snaps spacing to grid)

### Synthesis

- [ ] **SYNTH-01**: Tool synthesizes findings across multiple benchmarks into a coherent design system
- [ ] **SYNTH-02**: Tool establishes a dominant aesthetic rather than averaging values across benchmarks
- [ ] **SYNTH-03**: Tool resolves conflicts between benchmarks (e.g. slightly different blues) with deliberate choices

### Output

- [ ] **OUT-01**: Tool outputs platform-agnostic design tokens in W3C DTCG JSON format
- [ ] **OUT-02**: Tool generates React/Tailwind artifacts (Tailwind v4 CSS `@theme` config, utility classes)
- [ ] **OUT-03**: Tool generates SwiftUI artifacts (Color/Font/Spacing extensions with idiomatic Swift patterns)
- [ ] **OUT-04**: User can select which platform target(s) to generate per project
- [ ] **OUT-05**: SwiftUI output uses `@ScaledMetric`, asset catalog references, and `#Preview` blocks
- [ ] **OUT-06**: Tailwind output constrains the theme (replaces defaults, not extends) to enforce the design system

### Components

- [ ] **COMP-01**: Tool generates starter component templates (Button, Card, Input, Badge, Heading, Text) using the design tokens
- [ ] **COMP-02**: React/Tailwind component templates use idiomatic JSX + Tailwind class patterns
- [ ] **COMP-03**: SwiftUI component templates use idiomatic View composition and modifiers

### Rules

- [ ] **RULES-01**: Tool generates CLAUDE.md rules that enforce the design system in future coding sessions
- [ ] **RULES-02**: Rules are testable (a future Claude session can answer "does this code violate this rule?" yes/no)
- [ ] **RULES-03**: Rules reference token names (not values), include explicit prohibitions, and cover all token categories

### Documentation

- [ ] **DOCS-01**: Tool produces a human-readable style guide (color swatches, type specimens, spacing scale)
- [ ] **DOCS-02**: Tool produces a vibe narrative describing the overall aesthetic in plain language

### Orchestration

- [ ] **ORCH-01**: Tool runs as a Claude Code skill invoked via slash command
- [ ] **ORCH-02**: Parallel sub-agents analyze benchmarks independently (one agent per image)
- [ ] **ORCH-03**: Intermediate design-system.json written to disk between analysis and generation (inspectable, decouples stages)
- [ ] **ORCH-04**: All agents share a strict JSON schema contract for input/output
- [ ] **ORCH-05**: Tool reports progress to user as stages complete

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Resilience

- **RESIL-01**: Confidence scores and ambiguity reporting for extracted values
- **RESIL-02**: Incremental/additive mode — update tokens without overwriting user modifications

### Platform Expansion

- **PLAT-01**: Android/Kotlin output target (Material Theme tokens, Compose, XML resources)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full component library (50+ components) | Multi-year effort; Shadcn/Radix exist. Starter templates are sufficient. |
| Figma sync / two-way integration | Different product; requires OAuth, webhooks, API infra. Screenshot input is the differentiator. |
| Visual design editor / GUI | Wrong distribution model for a Claude Code skill. Developers expect CLI and files. |
| Real-time / streaming analysis | Requires polling/webhook infrastructure, removes human validation loop. |
| Code-based input (stylesheets/components) | Visual-first approach for v1. Code input is a v2+ consideration. |
| URL fetching / live site analysis | Screenshots are the input format for v1. URL-to-screenshot is a v2 convenience feature. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ORCH-04 | Phase 1 | Pending |
| INPUT-01 | Phase 2 | Pending |
| INPUT-02 | Phase 2 | Pending |
| INPUT-03 | Phase 2 | Pending |
| EXTRACT-01 | Phase 2 | Pending |
| EXTRACT-02 | Phase 2 | Pending |
| EXTRACT-03 | Phase 2 | Pending |
| EXTRACT-04 | Phase 2 | Pending |
| EXTRACT-05 | Phase 2 | Pending |
| ORCH-02 | Phase 2 | Pending |
| SYNTH-01 | Phase 3 | Pending |
| SYNTH-02 | Phase 3 | Pending |
| SYNTH-03 | Phase 3 | Pending |
| ORCH-03 | Phase 3 | Pending |
| OUT-01 | Phase 4 | Pending |
| OUT-02 | Phase 4 | Pending |
| OUT-03 | Phase 4 | Pending |
| OUT-04 | Phase 4 | Pending |
| OUT-05 | Phase 4 | Pending |
| OUT-06 | Phase 4 | Pending |
| COMP-01 | Phase 4 | Pending |
| COMP-02 | Phase 4 | Pending |
| COMP-03 | Phase 4 | Pending |
| RULES-01 | Phase 5 | Pending |
| RULES-02 | Phase 5 | Pending |
| RULES-03 | Phase 5 | Pending |
| DOCS-01 | Phase 5 | Pending |
| DOCS-02 | Phase 5 | Pending |
| ORCH-01 | Phase 6 | Pending |
| ORCH-05 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 30 total
- Mapped to phases: 30
- Unmapped: 0

---
*Requirements defined: 2026-02-17*
*Last updated: 2026-02-17 after roadmap creation*
