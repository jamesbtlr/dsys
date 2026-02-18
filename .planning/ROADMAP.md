# Roadmap: dsys-tool

## Overview

Build a Claude Code skill that transforms screenshot benchmarks into a complete, immediately usable design system. The pipeline flows in strict dependency order: schema contracts are defined first (everything else depends on them), then the visual analysis agent, then the synthesizer that merges findings into a canonical design-system.json, then the platform-specific generators and enforcement rules, and finally the orchestrator that wires it all into a slash command. Each phase delivers a testable component in isolation before the next is built.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Schema Contracts** - Define the JSON schemas and extraction rubric that all agents share (completed 2026-02-17)
- [x] **Phase 2: Analysis Agent** - Build and test the per-image vision extraction agent (completed 2026-02-17)
- [x] **Phase 3: Synthesizer Agent** - Merge N analysis findings into a canonical design-system.json (completed 2026-02-18)
- [x] **Phase 4: Platform Generators** - Generate React/Tailwind and SwiftUI artifacts from design-system.json (completed 2026-02-18)
- [ ] **Phase 5: Rules and Style Guide** - Generate CLAUDE.md enforcement rules and human-readable style guide
- [ ] **Phase 6: Orchestrator and Command** - Wire all agents into a working slash command

## Phase Details

### Phase 1: Schema Contracts
**Goal**: Every agent has a stable, shared contract before any agent is written
**Depends on**: Nothing (first phase)
**Requirements**: ORCH-04
**Success Criteria** (what must be TRUE):
  1. A JSON schema document exists that defines the exact structure every analysis agent must output
  2. A JSON schema document exists that defines the exact structure of design-system.json
  3. An extraction rubric exists that specifies what to extract from a screenshot, in what format, and how to quantize values
  4. Platform output specifications exist for React/Tailwind and SwiftUI, defining what files each generator must produce
  5. Any two agents using these contracts produce output that can be consumed by the next stage without structure negotiation
**Plans**: 3 plans
- [x] 01-01-PLAN.md — Analysis agent contracts (extraction rubric + findings schema + JSON Schema)
- [x] 01-02-PLAN.md — Design system contracts (token schema spec + JSON Schema)
- [x] 01-03-PLAN.md — Platform output specifications (React/Tailwind + SwiftUI file manifests)

### Phase 2: Analysis Agent
**Goal**: A single screenshot produces a schema-conformant structured findings JSON through Claude's vision
**Depends on**: Phase 1
**Requirements**: INPUT-01, INPUT-02, INPUT-03, EXTRACT-01, EXTRACT-02, EXTRACT-03, EXTRACT-04, EXTRACT-05, ORCH-02
**Success Criteria** (what must be TRUE):
  1. User can pass one or more screenshot paths to the analysis agent and receive a findings JSON file per image
  2. Tool reports a clear error message when an image is unsupported, missing, or corrupt — not a silent failure
  3. Extracted color palette reflects design intent (named semantic roles, quantized to standard values) not raw pixel samples
  4. Extracted typography tokens (family, weight, size scale, line-height) are snapped to standard values, not raw rendered measurements
  5. Extracted spacing tokens are snapped to a 4px grid with semantic tier labels, not raw pixel distances
**Plans**: 2 plans
Plans:
- [x] 02-01-PLAN.md — Schema extension (rationale + partial failure fields) and analyzer agent prompt
- [x] 02-02-PLAN.md — Schema validation, agent testing, and user review checkpoint

### Phase 3: Synthesizer Agent
**Goal**: N analysis findings are merged into one canonical design-system.json with a clear aesthetic identity
**Depends on**: Phase 2
**Requirements**: SYNTH-01, SYNTH-02, SYNTH-03, ORCH-03
**Success Criteria** (what must be TRUE):
  1. Given multiple analysis findings files, the synthesizer produces a single design-system.json that passes schema validation
  2. The design-system.json contains an aesthetic summary and dominant approach declaration — not an average of inputs
  3. Conflicts between benchmarks (e.g. two different blues) are resolved with an explicit logged choice, not silently blended
  4. The intermediate design-system.json is written to disk and is human-inspectable before generators run
**Plans**: 2 plans
Plans:
- [x] 03-01-PLAN.md — Synthesizer agent prompt (merge algorithm, conflict resolution, output template)
- [x] 03-02-PLAN.md — E2E validation (run synthesizer on test finding, schema validation, output inspection)

### Phase 4: Platform Generators
**Goal**: design-system.json is transformed into drop-in project files for React/Tailwind and SwiftUI
**Depends on**: Phase 3
**Requirements**: OUT-01, OUT-02, OUT-03, OUT-04, OUT-05, OUT-06, COMP-01, COMP-02, COMP-03
**Success Criteria** (what must be TRUE):
  1. User can select which platform target(s) to generate (React/Tailwind, SwiftUI, or both) and only the selected outputs are produced
  2. React/Tailwind output includes a Tailwind v4 CSS file with an @theme block that replaces defaults (not extends), plus CSS custom properties
  3. SwiftUI output includes Color, Font, and Spacing extensions with @ScaledMetric, asset catalog references, and #Preview blocks — compiling against iOS 16+
  4. Starter component templates (Button, Card, Input, Badge, Heading, Text) are generated using the design tokens for each selected platform
  5. Generated platform files can be copied into a project and used immediately without manual edits to make them work
**Plans**: 2 plans
Plans:
- [x] 04-01-PLAN.md — React/Tailwind generator agent prompt and E2E validation (completed 2026-02-18)
- [x] 04-02-PLAN.md — SwiftUI generator agent prompt and E2E validation (completed 2026-02-18)

### Phase 5: Rules and Style Guide
**Goal**: The design system is self-enforcing in future Claude sessions and documented for human readers
**Depends on**: Phase 4
**Requirements**: RULES-01, RULES-02, RULES-03, DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):
  1. A CLAUDE.md rules block is generated that references token names (not hex values) and includes explicit prohibitions
  2. Every rule in the generated CLAUDE.md is answerable with yes/no: "does this code violate this rule?"
  3. A human-readable style guide is generated with color swatches, type specimens, and spacing scale
  4. A vibe narrative is generated that describes the overall aesthetic of the design system in plain language
**Plans**: 2 plans
Plans:
- [x] 05-01-PLAN.md — Rules agent prompt (rules.md with section-marker CLAUDE.md management and STYLE-GUIDE.md generation) (completed 2026-02-18)
- [ ] 05-02-PLAN.md — Validate rules agent against Luxora design-system.json and verify idempotent re-generation

### Phase 6: Orchestrator and Command
**Goal**: All agents are wired into a single slash command that a user can run from Claude Code
**Depends on**: Phase 5
**Requirements**: ORCH-01, ORCH-05
**Success Criteria** (what must be TRUE):
  1. User can invoke the tool via a Claude Code slash command, passing screenshot paths and a target platform flag
  2. Parallel analysis agents run for each benchmark image simultaneously, not sequentially
  3. User sees progress updates as each stage completes (analysis, synthesis, generation, rules)
  4. On partial failure, the tool reports which stage failed and what output was successfully written — it does not silently continue
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Schema Contracts | 3/3 | Complete    | 2026-02-17 |
| 2. Analysis Agent | 2/2 | Complete    | 2026-02-17 |
| 3. Synthesizer Agent | 2/2 | Complete    | 2026-02-18 |
| 4. Platform Generators | 2/2 | Complete    | 2026-02-18 |
| 5. Rules and Style Guide | 1/2 | In progress | - |
| 6. Orchestrator and Command | 0/TBD | Not started | - |
