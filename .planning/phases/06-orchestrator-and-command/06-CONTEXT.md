# Phase 6: Orchestrator and Command - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the 5 existing agents (analyzer, synthesizer, react-generator, swiftui-generator, rules) into a single Claude Code slash command `/dsys:generate` that takes screenshot benchmarks and a target platform, then produces a complete design system in a named project directory under `.dsys/`. The command handles parallel analysis, schema validation between stages, progress reporting, and partial failure gracefully.

</domain>

<decisions>
## Implementation Decisions

### Command interface
- Command name: `/dsys:generate` (namespaced to leave room for future `/dsys:*` commands)
- Screenshot input: accepts inline paths OR a directory path — auto-detect which was passed
- Platform selection: interactive prompt after screenshots are validated ("Which platforms? React/Tailwind, SwiftUI, or both")
- Project name: optional — if user doesn't provide one, auto-generate a name from the benchmark content/context
- Confirmation step: always show a confirmation before starting ("Found 3 screenshots, generating React + SwiftUI for 'luxora'. Proceed?")

### Progress & checkpoints
- Stage banners as each pipeline stage starts/ends ("Analyzing 3 screenshots..." "Synthesizing..." "Generating React..." etc.)
- No automatic review checkpoint — runs straight through by default
- `--review` flag available to pause after analysis stage for user inspection of findings before synthesis
- Analysis runs in parallel via Task agents — one agent per screenshot simultaneously

### Failure & recovery
- If one screenshot fails analysis: pause and ask user "1 of 3 screenshots failed. Continue with 2, or abort?"
- Schema validation between every stage boundary (findings schema after analysis, design-system schema after synthesis) — fail fast on bad output
- On failure after analysis: keep findings on disk in `.dsys/<name>/findings/` — user can re-run from synthesis stage
- Intermediate output persists for debugging; not cleaned up on failure

### Output organization
- Named project directories: `.dsys/<name>/` (e.g., `.dsys/luxora/`)
- Each project contains: `design-system.json`, `findings/`, platform output dirs (`react/`, `swiftui/`), `CLAUDE.md`, `STYLE-GUIDE.md`
- CLAUDE.md rules generated inside `.dsys/<name>/CLAUDE.md` — user copies/integrates when ready (not auto-injected into project root)
- Re-running for same name overwrites that project's output (confirmation step covers this)

### End-of-run summary
- File manifest listing every generated file with paths
- Visual preview: color palette, font stack, component count
- No auto-injection into the user's project — output stays in `.dsys/<name>/`

### Claude's Discretion
- Exact auto-generated project name heuristic (from screenshot filenames, detected brand, etc.)
- Internal pipeline orchestration mechanics (how agents are spawned and coordinated)
- Schema validation error message format
- Stage banner formatting and exact wording

</decisions>

<specifics>
## Specific Ideas

- Namespaced command (`/dsys:generate`) explicitly chosen to support future commands like `/dsys:inspect`, `/dsys:validate`
- Named projects (`.dsys/luxora/`) so the tool can be used multiple times for different design systems without conflict
- User expressed interest in a web-based interface for the tool — deferred (see below)

</specifics>

<deferred>
## Deferred Ideas

- Web-based interface for configuring or viewing design systems — new capability, belongs in its own phase
- Additional `/dsys:*` subcommands (inspect, validate, etc.) — future phases once the generator is stable

</deferred>

---

*Phase: 06-orchestrator-and-command*
*Context gathered: 2026-02-18*
