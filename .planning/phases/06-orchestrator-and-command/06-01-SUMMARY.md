---
phase: 06-orchestrator-and-command
plan: "01"
subsystem: orchestrator
tags: [slash-command, orchestrator, pipeline, parallel-execution, schema-validation]
dependency_graph:
  requires:
    - skills/dsys/agents/analyzer.md
    - skills/dsys/agents/synthesizer.md
    - skills/dsys/agents/react-generator.md
    - skills/dsys/agents/swiftui-generator.md
    - skills/dsys/agents/rules.md
    - skills/dsys/schemas/analysis-findings.schema.json
    - skills/dsys/schemas/design-system.schema.json
  provides:
    - skills/dsys/dsys/generate.md
    - skills/dsys/dsys/SKILL.md
  affects:
    - All end-to-end user invocations of /dsys:generate
tech_stack:
  added: []
  patterns:
    - Thin slash command entry file referencing SKILL.md via @-include
    - Orchestrator prompt with parallel Task fan-out for analysis
    - Parallel Task fan-out for dual-platform generation
    - Interactive mid-pipeline user prompting (platform selection, confirmation, partial failure)
    - Schema validation gates between pipeline stages using npx ajv-cli
    - Named project output directories (.dsys/{name}/)
key_files:
  created:
    - skills/dsys/dsys/generate.md
    - skills/dsys/dsys/SKILL.md
  modified: []
decisions:
  - "@-include relative path used in generate.md (not absolute) — consistent with plugin pattern from research; empirical test needed at first real invocation"
  - "14 numbered steps (vs. plan's 15) — steps 7 and 8 cover both the agent result collection and schema validation for findings; functionally equivalent, just organized as analysis-results then schema-validation"
  - "Review pause (Step 9) explicitly lists all successful_findings paths in the pause message — solves Pitfall 5 (context loss across turns) without writing a state file"
metrics:
  duration: "~3 min"
  completed: "2026-02-18"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 6 Plan 01: Orchestrator and Command Summary

`/dsys:generate` slash command and full orchestrator prompt wiring all five existing agents into an end-to-end pipeline with parallel analysis, schema validation gates, interactive user prompts, and per-project output directories.

## What Was Built

Two files were created in `skills/dsys/dsys/`:

**`generate.md`** — A thin slash command entry file (18 lines) that:
- Declares `name: dsys:generate` with correct frontmatter
- Loads the orchestrator via `@skills/dsys/dsys/SKILL.md`
- Passes `$ARGUMENTS` through to the orchestrator
- Contains no pipeline logic itself

**`SKILL.md`** — The full orchestrator prompt (480 lines, 14 steps) that:
- Parses `$ARGUMENTS` into screenshot inputs, `--name`, and `--review` flag
- Detects whether inputs are a directory or individual file paths
- Converts all paths to absolute using `realpath` (Pitfall 3 prevention)
- Auto-derives project name from directory basename or filename prefix (with date fallback)
- Prompts user interactively for platform selection (React/SwiftUI/Both)
- Shows confirmation with overwrite warning if `.dsys/{name}/` already exists
- Issues ALL analyzer Task calls in a single response turn (parallel fan-out)
- Handles partial analysis failure: prompts user to continue or abort
- Validates each findings JSON against `analysis-findings.schema.json`
- Pauses at review point if `--review` was set (lists all finding paths in pause message to prevent context loss)
- Issues synthesizer Task with all successful findings paths
- Validates `design-system.json` against `design-system.schema.json`
- Issues both generator Tasks in a single response turn when both platforms selected
- Issues rules agent Task with `claude_md_path: .dsys/{name}/CLAUDE.md` (never project root)
- Reads actual `ls -R` output for file manifest in end-of-run summary
- Extracts preview values from design-system.json (primary color, surface, font)

## Pipeline Architecture

```
$ARGUMENTS
    │
    ▼
[Step 1-3] Parse args + validate screenshots (absolute paths via realpath)
    │
    ▼
[Step 4-5] Platform selection (interactive) + confirmation
    │
    ▼
[Step 6] Parallel analysis: N × Task(analyzer) in ONE response turn
    │
    ▼
[Step 7-8] Collect results + schema validation (partial failure handling)
    │
    ▼
[Step 9] Optional --review pause
    │
    ▼
[Step 10-11] Task(synthesizer) + design-system.json schema validation
    │
    ▼
[Step 12] Parallel generation: Task(react) + Task(swiftui) in ONE turn (if both)
    │
    ▼
[Step 13] Task(rules) → .dsys/{name}/CLAUDE.md + STYLE-GUIDE.md
    │
    ▼
[Step 14] End-of-run summary: ls -R manifest + JSON preview values
```

## Deviations from Plan

None - plan executed exactly as written.

The plan described "15 numbered sections" but the SKILL.md organizes as 14 steps — Steps 7 and 8 together cover what the plan described as "Analysis Results and Partial Failure Handling" plus "Schema Validation — Findings" as two distinct steps. The functional scope is identical; the section numbering collapsed by one to keep related analysis logic adjacent. All 11 verification criteria in the plan pass.

## Self-Check

Files created:
- `skills/dsys/dsys/generate.md` — EXISTS
- `skills/dsys/dsys/SKILL.md` — EXISTS

Commits:
- `7a23a27` — feat(06-01): add /dsys:generate slash command entry file
- `bbc4b26` — feat(06-01): add SKILL.md orchestrator prompt for /dsys:generate pipeline
