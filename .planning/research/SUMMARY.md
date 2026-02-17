# Project Research Summary

**Project:** dsys-tool — Design System Generation Claude Code Skill
**Domain:** AI-powered developer tooling / design system automation
**Researched:** 2026-02-17
**Confidence:** HIGH

## Executive Summary

dsys-tool is a Claude Code skill (slash command backed by Markdown prompt files) that accepts benchmark screenshots, uses Claude's vision capability to extract design tokens, and produces a complete, immediately usable design system across multiple platforms. The tool occupies a specific underserved niche: no existing tool combines visual screenshot input with multi-platform output (React/Tailwind + SwiftUI) targeted at developers who build with AI coding assistants. Figma-integrated tools (Tokens Studio, Supernova) require a Figma file. Style Dictionary requires manual configuration. AI tools like v0 generate UI, not design systems. This tool generates the design system foundation that those tools assume you already have.

The recommended approach is a fan-out/fan-in multi-agent pipeline: an orchestrator spawns parallel analysis agents (one per screenshot) that write structured findings to disk, a synthesizer merges those findings into a canonical `design-system.json`, and separate platform generator agents then produce Tailwind config, SwiftUI extensions, and a CLAUDE.md rules document in parallel. The entire stack requires no runtime beyond Claude Code itself — Claude's native vision reads images, the skill writes files, and an optional `npx style-dictionary build` call handles token transformation. No external vision libraries, no CLI framework, no GUI.

The dominant risk cluster is schema integrity: analysis agents running in parallel will produce incompatible output if the extraction schema is not defined and enforced before any prompt is written. A second major risk is aesthetic coherence — multi-benchmark synthesis tends to produce averaged, identity-free outputs unless the synthesizer is explicitly instructed to establish a dominant aesthetic voice rather than reconcile values numerically. Both risks must be front-loaded into the design phase before implementation begins.

---

## Key Findings

### Recommended Stack

The skill architecture is pure Markdown prompt files placed in `.claude/commands/` and `skills/dsys/`. Sub-agents are spawned via Claude Code's `Task` tool; filesystem-mediated communication (writing JSON to `.dsys/`) is the established pattern for inter-agent data transfer. No compiled code, no package manager, no bundler is required for the skill itself.

The only external dependency worth adding is `style-dictionary@^4.0.0` (invoked via `npx`) for token pipeline transformation — CSS custom properties, JS ES6 constants from W3C DTCG JSON. SwiftUI extensions are simple enough to generate directly via Claude without Style Dictionary. Tailwind v4 output is a plain CSS file with an `@theme` block (not `tailwind.config.js`), making it trivial string generation.

**Core technologies:**

- **Claude Code slash commands** — skill entry point, no other CLI framework needed
- **Claude Task tool** — fan-out parallelism for per-image analysis, fan-in for synthesis
- **Claude vision (Read tool)** — native PNG/JPEG/WebP/GIF support, no external image libraries
- **W3C DTCG token format** — industry-standard JSON schema (`$value`, `$type`, `$description`)
- **Style Dictionary v4** — token pipeline for CSS/JS outputs (MEDIUM confidence: verify version via `npm info style-dictionary version`)
- **Tailwind v4 `@theme` CSS** — replaces `tailwind.config.js`; generated as plain string, no library needed
- **Direct Claude generation for SwiftUI** — `Color`, `Font`, `CGFloat` extensions templated by agent, no codegen library needed
- **`claude-opus-4-6`** — vision analysis agents (highest quality for extraction tasks)
- **`claude-sonnet-4-5`** — synthesis and generation agents (cost/quality balance)

### Expected Features

**Must have (table stakes) — all required for v1:**

- Color token extraction (semantic roles: primary, secondary, surface, text hierarchy, feedback states)
- Typography token extraction (families, scale, weights, line-heights)
- Spacing/sizing token extraction (snapped to 4px grid)
- W3C DTCG JSON as canonical token format
- Two-layer token architecture (primitive → semantic aliases); semantic names, not raw values
- Platform-specific outputs: Tailwind v4 CSS config + SwiftUI Color/Font/Spacing extensions
- Human-readable style guide (Markdown with swatches, type specimens, spacing scale)

**Should have (differentiators) — v1 scope:**

- Screenshot-based visual input (the core differentiator — no other tool does this)
- Multi-platform output in a single pass (React/Tailwind + SwiftUI simultaneously)
- Aesthetic vibe/narrative extraction (written characterization of design personality)
- CLAUDE.md design enforcement rules output (AI-native output format, no competitor has this)
- Per-project platform target selection (`--target react|swift|both`)
- Component template stubs for React and SwiftUI (start with Button, Card, Input, Heading)

**Defer to v2+:**

- Multi-image synthesis conflict reporting with confidence scores (complex; v1 synthesizer should still accept multiple images but without explicit confidence UI)
- Incremental/additive mode (update without overwriting user modifications)
- Android/Kotlin output target
- URL-as-benchmark input (screenshots are v1 path; URLs require WebFetch complexity)

**Key insight from features research:** The v1 tight scope recommendation is tokens + style guide + CLAUDE.md rules as the firm core, with component templates as v1.1. If schedule pressure hits, drop component templates first, not CLAUDE.md rules — the AI-native output is the strongest differentiator.

### Architecture Approach

The pipeline follows a strict fan-out/fan-in pattern with file-based intermediate representation. The orchestrator (`SKILL.md`) reads arguments, spawns N parallel analyzer agents (one per screenshot), collects their structured findings, calls the synthesizer which writes `.dsys/design-system.json`, then dispatches platform generator agents in parallel, and finally runs the rules agent. Every component has a single defined input schema and output schema. Components communicate only through the orchestrator or through shared files on disk — never directly.

**Major components:**

1. **Command entry point** (`commands/dsys.md`) — argument parsing, validation, user-facing error messages
2. **Orchestrator** (`skills/dsys/SKILL.md`) — sequencing, fan-out/fan-in, error aggregation, progress reporting
3. **Analysis agent** (`agents/analyzer.md`) — per-benchmark visual extraction against a fixed rubric; writes structured findings JSON
4. **Synthesizer agent** (`agents/synthesizer.md`) — merges N findings, resolves conflicts, writes `design-system.json`
5. **React/Tailwind generator** (`agents/generator-react.md`) — platform-specific output for web; Tailwind `@theme`, CSS vars, component stubs
6. **SwiftUI generator** (`agents/generator-swiftui.md`) — Swift Color/Font/Spacing extensions, View templates, Xcode-ready
7. **Rules agent** (`agents/rules.md`) — CLAUDE.md enforcement rules referencing canonical token names
8. **Reference files** — `analysis-rubric.md`, `token-schema.md`, `platform-specs/` — stable contracts loaded into agent prompts

**Build order (strict dependency sequence):** Schema and rubric definitions → Analyzer agent → Synthesizer agent → Platform generators (parallel with each other) → Rules agent → Orchestrator wiring → Command entry point

### Critical Pitfalls

1. **Schema-less parallel agents** — Analysis agents running in parallel will produce incompatible JSON structure if no schema is enforced. Prevention: define the analysis output schema as a JSON template before writing any prompts; each agent fills in values, does not design structure; add a validation step between analysis and synthesis that hard-fails on schema violations.

2. **Pixel measurement instead of design intent** — Vision extraction treats compression artifacts and rendering noise as canonical values, producing near-duplicate colors and non-round font sizes. Prevention: prompt for "design intent" not "pixel values"; snap extracted values to standard grids (4px spacing, standard type scale) post-extraction; test against a known design system (e.g., Material Design screenshots vs. published token values).

3. **Synthesis averaging that loses aesthetic identity** — Multi-benchmark synthesis produces averaged, identity-free outputs by treating tokens as numbers rather than aesthetic expressions. Prevention: synthesizer must first establish `aesthetic_summary` and `dominant_approach` before merging values; spacing/type scales must snap to a single grid, not blend across grids; allow user to weight a primary benchmark.

4. **Tailwind config that doesn't constrain** — Using `theme.extend` instead of `theme` for color replacement means the design system coexists with the full Tailwind default palette, giving it no enforcement teeth. Prevention: generated config must use `theme.colors` (full replacement); use CSS custom properties throughout so config references `var(--color-...)`.

5. **SwiftUI output that compiles but isn't idiomatic** — Generated Swift code may use raw hex `Color(hex:)` initializers instead of asset catalog references, omit `@ScaledMetric` for accessibility, miss `#Preview` blocks, or use APIs not available on the minimum iOS target. Prevention: specify minimum iOS version (default iOS 16) in generator prompt; generate asset catalog `Contents.json` alongside Swift extensions; require `#Preview` blocks; integration test in a real Xcode project.

6. **CLAUDE.md rules with no enforcement teeth** — Rules like "use the design system" are aspirational, not enforceable. Prevention: each rule must be testable (yes/no answer to "does this code violate it?"); rules reference token names, not hex values; include a "do not use" section (raw hex, hardcoded font sizes, off-grid spacing).

---

## Implications for Roadmap

Based on combined research, the dependency structure is clear and the phase order follows directly from the architecture build sequence with features grouped by what each phase enables.

### Phase 1: Schema and Contract Definitions

**Rationale:** Every other component depends on these definitions. The analysis output schema is the contract between analyzer and synthesizer. The `design-system.json` schema is the contract between synthesizer and generators. Writing them first is non-negotiable — the PITFALLS research identifies ad-hoc schema design as the single highest-severity cross-cutting risk.

**Delivers:** `token-schema.md` (design-system.json spec), `analysis-rubric.md` (extraction rubric with JSON template), `platform-specs/` (React and SwiftUI output specs). No executable code — pure definitions.

**Addresses:** TS-1 through TS-6 foundations, TS-5 (semantic alias architecture), all of Pitfall 7

**Avoids:** Schema mismatch between parallel agents (Pitfall 7), platform name drift (Pitfall 4)

**Research flag:** SKIP — patterns are well-defined in research. Schema design is a writing task, not a discovery task.

---

### Phase 2: Analysis Agent

**Rationale:** The analysis agent is the most isolated component (only depends on Phase 1 artifacts) and also the highest-risk (vision extraction quality determines everything downstream). Build it first, test it thoroughly against known design systems before proceeding.

**Delivers:** `agents/analyzer.md` — functional per-image vision extraction agent that produces schema-conformant structured findings. Tested against at least one known design system with expected output defined.

**Addresses:** D-1 (screenshot analysis), TS-1 (color), TS-2 (typography), TS-3 (spacing), TS-5 (semantic roles extracted in context)

**Avoids:** Pixel-measurement trap (Pitfall 1), extracting colors without semantics (Pitfall 2)

**Research flag:** NEEDS RESEARCH during planning — prompt engineering for design intent extraction vs. pixel measurement is nuanced; the analysis rubric's quantization approach (snap to 4px grid, standard type scales) needs to be tested empirically.

---

### Phase 3: Synthesizer Agent

**Rationale:** Depends on Phase 2 output format. Can be developed and tested against pre-baked Phase 2 outputs before any orchestration exists. Aesthetic coherence must be solved here — the synthesizer either establishes design intent or loses it forever.

**Delivers:** `agents/synthesizer.md` — merges N findings into `.dsys/design-system.json`. Includes aesthetic summary, dominant approach declaration, conflict resolution log.

**Addresses:** D-6 (multi-image synthesis, at least basic form), D-4 (vibe/aesthetic narrative), D-8 (conflict detection in basic form)

**Avoids:** Aesthetic averaging trap (Pitfall 3), context overflow for large benchmark counts (Pitfall 8)

**Research flag:** SKIP — synthesizer logic follows directly from schema design. If schemas are clean, the synthesizer is a structured reasoning task, not a novel pattern.

---

### Phase 4: Platform Generators

**Rationale:** React and SwiftUI generators share only the `design-system.json` input and can be built in parallel. Both depend on Phase 3 but not on each other. This phase delivers the first end-to-end output that a user can actually import into a project.

**Delivers:** `agents/generator-react.md` (Tailwind `@theme` CSS, CSS custom properties, component stubs), `agents/generator-swiftui.md` (Color/Font/Spacing Swift extensions, asset catalog, View templates)

**Addresses:** TS-6 (platform output), D-2 (multi-platform), D-3 (component templates), D-9 (platform target selection)

**Avoids:** Tailwind extend-not-replace trap (Pitfall 6), SwiftUI idiom failures (Pitfall 5), "drop-in ready" definition gap (Pitfall 10)

**Research flag:** SwiftUI generator NEEDS RESEARCH — minimum iOS version, asset catalog structure, `@ScaledMetric` usage, `#Preview` macro syntax. React generator SKIP — Tailwind v4 `@theme` is well-documented.

---

### Phase 5: Rules Agent and Style Guide

**Rationale:** Depends on `design-system.json` (Phase 3) but not on platform generators. Can logically follow Phase 4 (benefits from seeing what tokens the generators consumed) but has no hard dependency. This is the phase that makes the output AI-native.

**Delivers:** `agents/rules.md` — CLAUDE.md enforcement rules block with token name references, explicit prohibitions, and "how to look up" guidance. Generated alongside `STYLEGUIDE.md` for human readers.

**Addresses:** D-5 (CLAUDE.md rules output), TS-7 (human-readable style guide), TS-4 (standard format output with description fields)

**Avoids:** Vague rules trap (Pitfall 9), rules that reference hex values instead of token names

**Research flag:** SKIP — content is derived from token schema; writing good enforcement rules is a prompt design task, well within established patterns.

---

### Phase 6: Orchestrator and Command Entry Point

**Rationale:** Last to build because it depends on all agents existing. Wiring, argument parsing, error handling, retry logic, and user-facing reporting all live here. This is also where the parallel fan-out is implemented.

**Delivers:** `SKILL.md` (orchestrator), `commands/dsys.md` (slash command entry), retry logic with content validation (not just structure), `WARNINGS.md` on partial failures, `SETUP.md` alongside generated artifacts, output directory collision handling.

**Addresses:** All features as an integrated system, D-9 (per-project target selection), error recovery

**Avoids:** Retry logic masking systematic prompt failures (Pitfall 11), output directory collision, silent failures from synthesizer context overflow

**Research flag:** SKIP — Task tool orchestration patterns are well-documented. Error handling patterns are standard.

---

### Phase Ordering Rationale

- Schemas before agents is non-negotiable (Pitfall 7 is the highest-severity pitfall and is entirely preventable by ordering)
- Analyzer before synthesizer because synthesizer input format is defined by analyzer output
- Generators before orchestrator so each agent is testable in isolation with pre-baked inputs before wiring
- Rules agent last among agents because its content is most dependent on seeing the full token set
- Command entry point last because it is pure wiring — nothing can be validated until the agents underneath it exist
- React and SwiftUI generators in the same phase because they are parallel development tracks with no dependency on each other

### Research Flags

**Needs deeper research during planning:**

- **Phase 2 (Analyzer):** Prompt engineering for design-intent extraction vs. pixel measurement. Quantization heuristics (which standard type scale to use, how to cluster near-duplicate colors). Empirical testing required — cannot be designed in the abstract.
- **Phase 4 (SwiftUI generator):** Minimum iOS version API surface, asset catalog XML structure for color sets, `@ScaledMetric` usage patterns, `#Preview` macro syntax in Swift 5.9+.

**Standard patterns — skip research-phase:**

- **Phase 1 (Schemas):** Writing task; schema design approach is clear from architecture research.
- **Phase 3 (Synthesizer):** Structured reasoning over clean schemas; no novel patterns needed.
- **Phase 5 (Rules/Style Guide):** Content is token-schema-derived; enforcement rule patterns are well understood.
- **Phase 6 (Orchestrator):** Task tool fan-out/fan-in is an established Claude Code pattern.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All core decisions based on official Claude Code documentation and established tool ecosystems. One MEDIUM item: verify Style Dictionary exact version via `npm info style-dictionary version`. |
| Features | HIGH | Market survey of competitive tools is thorough; table stakes/differentiator distinction is well-reasoned from first principles. Feature complexity estimates are directional only. |
| Architecture | HIGH | Fan-out/fan-in with file-based intermediate representation is an established Claude Code pattern. Component boundaries are clean and well-motivated. |
| Pitfalls | HIGH | Pitfall analysis is domain-specific and grounded in the tool's specific failure modes. Prevention strategies are concrete and testable. |

**Overall confidence: HIGH**

### Gaps to Address

- **Style Dictionary version:** Verify current v4.x version before adding dependency. Command: `npm info style-dictionary version`. Directional recommendation (v4) is correct; exact version needs confirmation.
- **Tailwind v3 support:** Research assumes v4. If target users may have v3 projects, a version detection step (check `package.json`) and conditional config generation adds complexity. Decide scope before Phase 4.
- **SwiftUI minimum iOS version:** Research recommends iOS 16 as default. Verify which APIs this constrains before writing the SwiftUI generator prompt. This is the most significant gap — wrong minimum version will produce generated code that fails in target projects.
- **Benchmark count ceiling:** Research recommends 5-7 benchmarks max for v1 to avoid synthesizer context overflow. This should be a documented, enforced constraint from Phase 6 design, not discovered at runtime.
- **Model cost at scale:** Multiple `claude-opus-4-6` vision calls per run. For >3 benchmarks, evaluate whether `claude-sonnet-4-5` is sufficient for analysis step. This is a cost/quality tradeoff to make explicit before shipping.

---

## Sources

### Primary (HIGH confidence)

- Claude Code official documentation — slash command structure, Task tool behavior, filesystem-mediated agent communication, vision capabilities
- Tailwind CSS v4 official release notes — `@theme` CSS-first configuration, deprecation of `tailwind.config.js`
- W3C Design Tokens Community Group spec — `$value`, `$type`, `$description` format, aliasing
- Style Dictionary v4 official docs — platform transform groups, DTCG format support, build pipeline
- SwiftUI documentation — Color extensions, Font extensions, `@ScaledMetric`, asset catalog integration

### Secondary (MEDIUM confidence)

- npm registry data for `style-dictionary` — v4.x release timeline and maintenance status
- Style Dictionary GitHub — v4.0.0 release notes and migration guide
- Competitive tool analysis — Tokens Studio, Supernova, Theo (Salesforce), Figma Variables API, v0 (Vercel), Locofy, Anima

### Tertiary (LOW confidence, verify before committing)

- Style Dictionary current exact version — must verify with `npm info style-dictionary version`
- SwiftUI iOS 16 vs iOS 17 API boundary for asset catalog color references — verify before writing generator

---

*Research completed: 2026-02-17*
*Ready for roadmap: yes*
