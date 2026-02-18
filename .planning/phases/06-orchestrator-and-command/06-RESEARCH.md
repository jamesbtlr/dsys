# Phase 6: Orchestrator and Command - Research

**Researched:** 2026-02-18
**Domain:** Claude Code slash command anatomy, orchestrator prompt engineering, parallel Task fan-out, interactive user prompting, schema validation between stages, failure recovery
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Command interface
- Command name: `/dsys:generate` (namespaced to leave room for future `/dsys:*` commands)
- Screenshot input: accepts inline paths OR a directory path — auto-detect which was passed
- Platform selection: interactive prompt after screenshots are validated ("Which platforms? React/Tailwind, SwiftUI, or both")
- Project name: optional — if user doesn't provide one, auto-generate a name from the benchmark content/context
- Confirmation step: always show a confirmation before starting ("Found 3 screenshots, generating React + SwiftUI for 'luxora'. Proceed?")

#### Progress & checkpoints
- Stage banners as each pipeline stage starts/ends ("Analyzing 3 screenshots..." "Synthesizing..." "Generating React..." etc.)
- No automatic review checkpoint — runs straight through by default
- `--review` flag available to pause after analysis stage for user inspection of findings before synthesis
- Analysis runs in parallel via Task agents — one agent per screenshot simultaneously

#### Failure & recovery
- If one screenshot fails analysis: pause and ask user "1 of 3 screenshots failed. Continue with 2, or abort?"
- Schema validation between every stage boundary (findings schema after analysis, design-system schema after synthesis) — fail fast on bad output
- On failure after analysis: keep findings on disk in `.dsys/<name>/findings/` — user can re-run from synthesis stage
- Intermediate output persists for debugging; not cleaned up on failure

#### Output organization
- Named project directories: `.dsys/<name>/` (e.g., `.dsys/luxora/`)
- Each project contains: `design-system.json`, `findings/`, platform output dirs (`react/`, `swiftui/`), `CLAUDE.md`, `STYLE-GUIDE.md`
- CLAUDE.md rules generated inside `.dsys/<name>/CLAUDE.md` — user copies/integrates when ready (not auto-injected into project root)
- Re-running for same name overwrites that project's output (confirmation step covers this)

#### End-of-run summary
- File manifest listing every generated file with paths
- Visual preview: color palette, font stack, component count
- No auto-injection into the user's project — output stays in `.dsys/<name>/`

### Claude's Discretion
- Exact auto-generated project name heuristic (from screenshot filenames, detected brand, etc.)
- Internal pipeline orchestration mechanics (how agents are spawned and coordinated)
- Schema validation error message format
- Stage banner formatting and exact wording

### Deferred Ideas (OUT OF SCOPE)
- Web-based interface for configuring or viewing design systems — new capability, belongs in its own phase
- Additional `/dsys:*` subcommands (inspect, validate, etc.) — future phases once the generator is stable
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ORCH-01 | Tool runs as a Claude Code skill invoked via slash command | Confirmed: slash commands live as `.md` files in `skills/<namespace>/` or `commands/<namespace>/` dirs; frontmatter declares `name`, `description`, `allowed-tools`, `argument-hint` |
| ORCH-05 | Tool reports progress to user as stages complete | Confirmed: orchestrator writes prose banners between Task spawns; Claude Code streams output to the user as the orchestrator runs |
</phase_requirements>

---

## Summary

Phase 6 produces two Markdown files: `skills/dsys/dsys/SKILL.md` (the orchestrator prompt) and `skills/dsys/dsys/generate.md` (the slash command entry point that becomes `/dsys:generate`). The architecture research from early in the project already specified both files and their content structure. Every agent this orchestrator needs (analyzer, synthesizer, react-generator, swiftui-generator, rules) is already built and on disk. Phase 6's only job is to wire them together with correct sequencing, parallel fan-out, interactive prompting, schema validation gates, partial failure handling, and a coherent end-of-run summary.

The orchestrator pattern for this project is well-established by the GSD system: spawn Task agents in the same response turn for parallelism, collect their one-line result strings, validate, then proceed. The orchestrator stays lean (15-20% of context) by delegating all work to agents and passing file paths rather than file content. This is especially important for analysis parallelism: all N analyzer Tasks are issued in a single response turn so Claude Code's runtime executes them concurrently.

The two key new mechanics for Phase 6 are: (1) interactive user prompting mid-run (platform selection, partial failure handling, project name confirmation), which the orchestrator handles via conversational turns between Task executions; and (2) per-project output directories (`.dsys/<name>/`) that isolate each generation run. Schema validation between stages uses `npx ajv-cli --spec=draft2020` — already confirmed working against the Phase 1 schemas — and the orchestrator runs it as a Bash command, failing fast if output is invalid before passing to the next agent.

**Primary recommendation:** Write one SKILL.md orchestrator prompt and one slash command entry file. The SKILL.md contains all orchestration logic inline (no external workflow file). The slash command entry file is thin — it sets frontmatter metadata and passes `$ARGUMENTS` directly to the SKILL.md content.

---

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|---|---|---|---|
| Claude Code Task tool | Native | Spawn sub-agents in parallel (analysis fan-out) and sequentially (synthesis, generation) | Established pattern from Phases 2-5; all existing agents are designed to be called via Task |
| Claude Code Bash tool | Native | Run `npx ajv-cli --spec=draft2020` for schema validation between stages | Already confirmed working in Phase 1; no installation needed |
| Claude Code Read tool | Native | Load screenshot files for path validation; read generated JSON for summary display | Used in all prior agents |
| Claude Code Write tool | Native | Write nothing directly — orchestrator delegates writes to agents | Agents handle their own writes |
| `npx ajv-cli` | 8.x (via npx) | Validate analysis-findings.json files against `skills/dsys/schemas/analysis-findings.schema.json`; validate design-system.json against `skills/dsys/schemas/design-system.schema.json` | Phase 1 confirmed this command works with `--spec=draft2020` flag; schemas already on disk |
| `skills/dsys/schemas/analysis-findings.schema.json` | Phase 1 artifact | Schema for validating analyzer output before synthesizer runs | Already on disk; tested against conformant and non-conformant fixtures |
| `skills/dsys/schemas/design-system.schema.json` | Phase 1 artifact | Schema for validating synthesizer output before generators run | Already on disk |

### Supporting
| Tool | Version | Purpose | When to Use |
|---|---|---|---|
| Bash `ls`, `stat`, `find` | System | Directory detection (is input a dir or a list of paths?) and screenshot enumeration | Used in screenshot input auto-detection logic |
| Bash `basename` | System | Extract filename for display in banners and auto-generated project names | Used in project name heuristic and stage banners |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|---|---|---|
| Inline orchestrator (SKILL.md) | External workflow file loaded via @-reference | External workflow file requires the file to exist at a known absolute path. Inline is self-contained at agent runtime — the same pattern all 5 existing agents use. |
| `npx ajv-cli` for validation | Agent-internal JSON parsing validation | ajv-cli provides schema-level validation (required fields, types, enum values, additionalProperties). Agent-internal validation would be partial and hard to maintain. ajv-cli is already on disk and confirmed working. |
| Ask for project name upfront | Derive from screenshot directory or filenames | Upfront ask adds a required interaction step before the user sees any value. Auto-derivation with confirmation is smoother UX and was the user's explicit preference (confirmed in CONTEXT.md). |

---

## Architecture Patterns

### Recommended File Structure

The architecture research established this layout early in the project. Phase 6 creates the two missing files:

```
skills/dsys/
├── agents/
│   ├── analyzer.md          # Phase 2 — COMPLETE
│   ├── synthesizer.md       # Phase 3 — COMPLETE
│   ├── react-generator.md   # Phase 4 — COMPLETE
│   ├── swiftui-generator.md # Phase 4 — COMPLETE
│   └── rules.md             # Phase 5 — COMPLETE
├── references/
│   ├── analysis-rubric.md        # Phase 1 — COMPLETE
│   ├── analysis-findings-schema.md # Phase 1 — COMPLETE
│   ├── token-schema.md           # Phase 1 — COMPLETE
│   └── platform-specs/
│       ├── react-tailwind-spec.md # Phase 1 — COMPLETE
│       └── swiftui-spec.md        # Phase 1 — COMPLETE
├── schemas/
│   ├── analysis-findings.schema.json # Phase 1 — COMPLETE
│   └── design-system.schema.json     # Phase 1 — COMPLETE
└── dsys/                     # PHASE 6 DELIVERABLE: namespace directory
    ├── SKILL.md              # PHASE 6 DELIVERABLE: orchestrator prompt
    └── generate.md           # PHASE 6 DELIVERABLE: /dsys:generate slash command

.dsys/                        # Per-project output (not in skills/)
└── <name>/
    ├── design-system.json
    ├── findings/
    │   ├── screenshot-1.json
    │   └── screenshot-N.json
    ├── react/                # if react selected
    ├── swiftui/              # if swiftui selected
    ├── CLAUDE.md
    └── STYLE-GUIDE.md
```

**Note on namespace directory:** The slash command name `/dsys:generate` requires a `dsys` namespace directory. Claude Code discovers commands by looking for `.md` files under `skills/<namespace>/` or `commands/<namespace>/` directories. The `generate.md` file in `skills/dsys/dsys/` becomes `/dsys:generate`. The `SKILL.md` in the same directory is the orchestrator that `generate.md` invokes.

### Pattern 1: Slash Command Entry File (generate.md)

**What:** A thin entry file that declares the slash command's metadata and passes `$ARGUMENTS` to the orchestrator.

**When to use:** Always. The slash command file stays minimal to preserve context budget. All logic lives in SKILL.md.

**Structure:**
```markdown
---
name: dsys:generate
description: Generate a complete design system from screenshot benchmarks
argument-hint: "[screenshot paths or dir] [--name <name>] [--review]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
---

<objective>
Generate a complete design system from visual benchmark screenshots.
Analyze screenshots, synthesize design tokens, and generate platform-specific code.
</objective>

<execution_context>
@skills/dsys/dsys/SKILL.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the orchestration workflow from SKILL.md end-to-end.
</process>
```

**Key insight:** The `@skills/dsys/dsys/SKILL.md` reference loads the orchestrator prompt via the `@` file-include mechanism. This keeps the command file under 30 lines and puts all logic in SKILL.md where it can be read and edited independently.

### Pattern 2: Parallel Analysis Fan-Out

**What:** Issue all analyzer Task calls in a single response turn. Claude Code's runtime executes them concurrently.

**When to use:** For analysis stage only. Synthesis, generation, and rules are sequential (each depends on the previous).

**How to implement in SKILL.md:**

The orchestrator must issue ALL analyzer Task calls before awaiting any result. The key constraint is that Task calls issued in the same response turn run in parallel; Task calls issued across separate turns run sequentially.

```
For each screenshot path in validated_paths:
  Issue Task(
    agent: "skills/dsys/agents/analyzer.md",
    prompt: "Analyze this image:

image_path: {path}
output_path: .dsys/{project_name}/findings/{basename}.json"
  )

Issue ALL Task calls above in a single response before collecting results.
```

**Result collection:** After the parallel Tasks complete, the orchestrator collects each Task's one-line return string. A return string starting with "Error:" indicates failure. A return string matching the `Analyzed {filename}: ...` pattern indicates success.

### Pattern 3: Sequential Pipeline Stages

**What:** After analysis completes (all Tasks done), the orchestrator runs the remaining stages one at a time, passing outputs from each stage to the next.

**Stage sequence:**
1. Parallel analysis → collect results → validate findings JSONs → handle partial failure
2. (Optional: `--review` flag pause point)
3. Task(synthesizer, findings_paths + output_path) → validate design-system.json
4. Task(react-generator, ...) and/or Task(swiftui-generator, ...) — parallel if both platforms selected
5. Task(rules-agent, ...) — always sequential after generators (needs design-system.json)
6. End-of-run summary

**Generator parallelism:** If the user selected both platforms, react-generator and swiftui-generator can be issued in parallel (they read the same input and write to different output dirs). Issue both Tasks in one response turn.

### Pattern 4: Interactive Prompting Mid-Orchestration

**What:** The orchestrator pauses at defined points to ask the user a question, collects their answer in the next turn, then continues.

**When to use:** Platform selection, project name confirmation, partial failure decision, `--review` pause.

**Implementation:** The orchestrator asks its question as a prose statement to the user ("Which platforms? Type 1 for React/Tailwind, 2 for SwiftUI, 3 for both"), then the user responds in a new turn, and the orchestrator continues with the next step. No special tool is needed — this is a natural conversational turn.

**Critical:** The orchestrator must clearly indicate it is waiting for input. After the user responds, the orchestrator resumes from the correct point in the pipeline. The SKILL.md prompt must be structured as labeled sections so the orchestrator knows exactly where to resume.

### Pattern 5: Argument Parsing and Screenshot Detection

**What:** The slash command accepts: inline screenshot paths (space-separated), a directory path, optional `--name <name>`, optional `--review` flag.

**Auto-detection algorithm:**
```
Parse $ARGUMENTS:
  Extract flags: --name <value>, --review
  Remaining tokens after flag extraction: positional args

If positional args is a single path AND that path is a directory:
  screenshots = files in directory matching *.png, *.jpg, *.jpeg, *.webp (case-insensitive)
  If screenshots is empty: Error "No screenshots found in directory: {dir}"
Else:
  screenshots = each positional arg treated as a file path
  Validate each: must end in .png, .jpg, .jpeg, or .webp
  Any invalid extension: collect error, report at end
```

**Validation before prompting:** All screenshots are validated for existence (Read tool attempt) before the orchestrator asks for platform selection. Show the user what was found ("Found 3 screenshots: hero.png, dashboard.png, card.png") before asking anything.

### Pattern 6: Project Name Auto-Generation Heuristic

**What:** When `--name` is not provided, derive a project name from the screenshot inputs.

**Recommended heuristic (Claude's Discretion area):**

Priority order:
1. Common directory name: if all screenshots are in the same directory, use the directory's basename, lowercased, with non-alphanumeric chars replaced by hyphens. (`/Users/james/luxora/screenshots/` → `luxora`)
2. Common filename prefix: if all screenshots share a prefix (e.g., `linear-dashboard.png`, `linear-component.png`), use the prefix. (`linear-`)
3. Longest common substring of all filenames, trimmed of non-alphanumeric chars
4. If nothing useful derives: `design-system-{YYYY-MM-DD}` using today's date

Show the derived name in the confirmation step so the user can abort and re-run with `--name` if they prefer a different name.

**Name format rules:** lowercase, letters and hyphens only, 3-30 characters.

### Pattern 7: Schema Validation Between Stages

**What:** After each pipeline stage, validate the output file against its JSON Schema before proceeding.

**Analysis findings validation:**
```bash
npx ajv-cli validate \
  --spec=draft2020 \
  -s skills/dsys/schemas/analysis-findings.schema.json \
  -d ".dsys/{name}/findings/{basename}.json"
```

Run for each findings file. If validation fails, treat that file as a failed analysis (same as an agent error return).

**Design system validation:**
```bash
npx ajv-cli validate \
  --spec=draft2020 \
  -s skills/dsys/schemas/design-system.schema.json \
  -d ".dsys/{name}/design-system.json"
```

If this fails, the pipeline stops immediately and reports the schema error to the user with the exact ajv output. No generation runs.

**Error message format (Claude's Discretion area — recommended):**
```
Schema validation failed for design-system.json.
Error: {ajv output, first error only}
Intermediate files are in .dsys/{name}/ for debugging.
```

### Pattern 8: Partial Failure Handling

**What:** When 1 or more (but not all) analyzer agents fail, pause and ask the user whether to continue.

**Decision point prompt:**
```
{N} of {total} screenshots failed analysis:
  - {failed_path}: {error_message}

Proceed with {N - failures} successful results, or abort?
Type 'continue' to proceed or 'abort' to stop.
```

**If user says continue:** Pass only the successful findings paths to the synthesizer.
**If user says abort:** Report which files succeeded (list their paths in `.dsys/{name}/findings/`) and exit. Do not clean up — files persist for debugging.
**If all fail:** Abort immediately without prompting. Report all errors.

### Pattern 9: Output Directory Path Customization for Existing Agents

**What:** All five existing agents accept configurable output paths via parameters in their task prompts. The orchestrator controls all paths. This is the established architecture (set in early project decisions).

**Orchestrator-controlled paths for each agent:**

| Agent | Controlled Parameter | Path Pattern |
|---|---|---|
| analyzer | `output_path` | `.dsys/{name}/findings/{basename}.json` |
| synthesizer | `output_path` | `.dsys/{name}/design-system.json` |
| synthesizer | `findings_paths` | `[".dsys/{name}/findings/*.json"]` |
| react-generator | `output_root` | `.dsys/{name}/react/` |
| swiftui-generator | `output_root` | `.dsys/{name}/swiftui/` |
| rules-agent | `design_system_path` | `.dsys/{name}/design-system.json` |
| rules-agent | `claude_md_path` | `.dsys/{name}/CLAUDE.md` |
| rules-agent | `output_dir` | `.dsys/{name}/` |
| rules-agent | `platforms` | `["react"]` or `["swiftui"]` or `["react", "swiftui"]` |

**Critical:** The rules-agent writes CLAUDE.md to `.dsys/{name}/CLAUDE.md`, NOT to the project root CLAUDE.md. The user copies this file manually when ready to integrate the design system. This is a locked decision.

### Pattern 10: End-of-Run Summary

**What:** After all agents complete, display a file manifest and a visual preview.

**File manifest:** List every file written, grouped by category:
```
## dsys:generate complete — {name}

### Findings
  .dsys/{name}/findings/screenshot-1.json
  .dsys/{name}/findings/screenshot-2.json

### Design System
  .dsys/{name}/design-system.json

### React/Tailwind (if selected)
  .dsys/{name}/react/tokens/tokens.css
  .dsys/{name}/react/tokens/tokens.json
  .dsys/{name}/react/tokens/theme.css
  ... (all 12 files)

### SwiftUI (if selected)
  .dsys/{name}/swiftui/Colors.xcassets/
  ... (all 13+ files)

### Documentation
  .dsys/{name}/CLAUDE.md
  .dsys/{name}/STYLE-GUIDE.md
```

**Visual preview (read from design-system.json):**
```
### Design System Preview — {name}

Primary color: {action.primary.light}  ■
Surface: {surface.default.light}  ■
Font: {typography.font_family.sans.$value}
Components: Button (5 variants), Card, Input, Badge, Heading, Text

To use: copy .dsys/{name}/CLAUDE.md rules into your project CLAUDE.md
```

The orchestrator reads `.dsys/{name}/design-system.json` to extract these values for display.

### Anti-Patterns to Avoid

- **Issuing analyzer Tasks sequentially:** If Task calls are issued one at a time (wait for each before issuing the next), analysis is N times slower. ALL analyzer Task calls must be issued in a single response turn.
- **Passing file content between agents:** Pass file paths only. Agents read their own inputs. Passing JSON content inflates the orchestrator's context and risks truncation.
- **Auto-injecting into project CLAUDE.md:** The locked decision is that CLAUDE.md goes into `.dsys/<name>/CLAUDE.md`. The orchestrator must NOT write to the project root CLAUDE.md.
- **Cleaning up on failure:** Failed runs keep intermediate files in `.dsys/<name>/findings/` for debugging. The orchestrator must NOT delete files on failure.
- **Running generators without validating design-system.json:** Schema validation is mandatory between synthesis and generation. Unvalidated JSON that fails partway through generation leaves the project in a half-generated state.
- **Hardcoding `.dsys/` as the root:** The project directory is always `.dsys/<name>/` with the project name. This allows multiple design systems to coexist.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Schema validation | Custom JSON parser | `npx ajv-cli --spec=draft2020` | ajv-cli validated against Phase 1 schemas; handles all JSON Schema 2020-12 constraints including `additionalProperties: false` and `if/then` conditionals |
| Parallel execution | Manual sequencing with polling | Task tool fan-out (issue all calls in one turn) | Claude Code runtime handles parallelism automatically; no queuing code needed |
| Screenshot enumeration | Recursive directory walker | Bash `ls` + glob | Simple Bash commands are sufficient for one-level directory listing; recursive enumeration is unnecessary for the expected 1-7 screenshot use case |
| Progress display | Progress bar or spinner | Prose stage banners between Task calls | The orchestrator already runs in Claude Code's streaming output; banners appear as the orchestrator progresses |
| Project name slugification | String manipulation library | Bash `tr`, `sed` | One-line Bash transforms for lowercase + hyphen conversion; no library needed |

**Key insight:** The orchestrator is a pure prompt-writing problem, not a coding problem. The only "code" it issues is Bash commands for validation and directory listing. Everything else is orchestration prose in a Markdown prompt file.

---

## Common Pitfalls

### Pitfall 1: All Analyzer Tasks Not Issued in One Turn

**What goes wrong:** The orchestrator issues one Task call, waits for the result, then issues the next. Analysis runs sequentially: N screenshots × ~30 seconds = several minutes. For 5 screenshots this is a serious UX regression.

**Why it happens:** The orchestrator template naturally expresses "for each screenshot, do X" as sequential iteration.

**How to avoid:** The SKILL.md must explicitly instruct: "Issue ALL analyzer Task calls in a single response. Do not await any result before issuing the remaining calls." Include a concrete example in the prompt showing all N Task calls side-by-side.

**Warning signs:** Analysis completes one screenshot at a time with visible sequential delay.

### Pitfall 2: Findings Paths Glob Fails When All Analysis Errored

**What goes wrong:** The orchestrator uses `".dsys/{name}/findings/*.json"` as the `findings_paths` for the synthesizer. If all analyzer agents failed (all screenshots errored), no JSON files exist in that directory. The glob expands to nothing and the synthesizer receives an empty list, which it reports as "Error: No findings files could be loaded: []" — a confusing error.

**Why it happens:** The orchestrator doesn't check whether any files exist before invoking the synthesizer.

**How to avoid:** After collecting Task results, count the number of successful analyses before proceeding. If zero succeeded, abort with a clear message before spawning the synthesizer Task. Only invoke the synthesizer when at least one findings file exists.

### Pitfall 3: Screenshot Input Validation Fails on Relative Paths

**What goes wrong:** The user passes a relative path like `./screenshots/hero.png`. The Bash `ls` or Read tool interprets this relative to a different working directory than expected. The orchestrator reports "file not found" even though the file exists.

**Why it happens:** Working directory assumptions differ between the user's shell and the Bash tool context.

**How to avoid:** Convert all input paths to absolute paths at the start of the orchestrator using `realpath` or `$(pwd)/{relative_path}`. Pass only absolute paths to agents. Document this normalization in the SKILL.md.

### Pitfall 4: Project Name Collision with Existing Directory

**What goes wrong:** The user already has `.dsys/luxora/` from a previous run. The orchestrator runs and overwrites all files without warning. The user loses their previous output unexpectedly.

**Why it happens:** The confirmation step covers intentional re-runs, but the user might not realize the auto-derived name matches their previous project.

**How to avoid:** In the confirmation step, check whether `.dsys/{name}/` already exists. If it does, add "(will overwrite existing output)" to the confirmation message. The existing confirmation gate is sufficient — the key is making the overwrite visible to the user.

**Implementation:**
```bash
if [ -d ".dsys/{name}" ]; then
  echo "(will overwrite existing output in .dsys/{name}/)"
fi
```

### Pitfall 5: `--review` Flag Pause Point State

**What goes wrong:** When `--review` is set, the orchestrator pauses after analysis and waits for user input. In the next turn, the orchestrator has no memory of which findings files were collected (they were in a previous turn's context). It re-derives the file list from disk instead.

**Why it happens:** The orchestrator's context does not persist variable bindings across conversational turns.

**How to avoid:** Before the review pause point, write the list of successful findings paths to a file (`.dsys/{name}/.state.json`) so the orchestrator can read it back in the next turn. This is the same file-as-checkpoint pattern used throughout the project.

Alternatively, structure the review pause to include the file list explicitly in the pause message so the next turn's context includes it: "Found 3 findings at: path1, path2, path3. Running with --review. Reply 'proceed' when ready."

### Pitfall 6: ajv-cli Returns Exit Code 1 on Validation Failure — Bash Error Handling

**What goes wrong:** The orchestrator runs `npx ajv-cli validate ... -d findings.json`. If validation fails, ajv-cli exits with code 1. If the orchestrator's Bash command is run without checking the exit code, it silently continues and passes an invalid file to the synthesizer.

**Why it happens:** Bash commands in Claude Code don't automatically stop the orchestrator on non-zero exit codes.

**How to avoid:** Run validation as:
```bash
if npx ajv-cli validate --spec=draft2020 -s schema.json -d data.json; then
  echo "Valid"
else
  echo "VALIDATION_FAILED: $(npx ajv-cli validate --spec=draft2020 -s schema.json -d data.json 2>&1)"
fi
```

Then check the output in the orchestrator's prose logic. If the output contains "VALIDATION_FAILED", stop and report to user.

### Pitfall 7: Agent Returns "Error:" But Orchestrator Treats It as Success

**What goes wrong:** The analyzer agent returns "Error: File not found: hero.png". The orchestrator's partial-failure logic checks for `"Error:"` prefix, but the pattern match is case-sensitive or too loose. The orchestrator treats the error result as a success summary and counts it toward the successful findings list.

**Why it happens:** All five existing agents have a defined return format. The orchestrator must reliably distinguish success from failure.

**How to avoid:** The established return patterns are:
- Analyzer success: `Analyzed {filename}: ui_screenshot, ...`
- Analyzer failure: `Error: {message}`
- Synthesizer success: `Synthesized {N} findings → design-system.json: ...`
- Synthesizer failure: `Error: {message}`
- Generator success: defined in each agent's return summary section
- Rules agent success: `## dsys rules agent — complete` header

The orchestrator must check for the exact error prefix `Error:` (capital E, colon). Document this check explicitly.

---

## Code Examples

### generate.md Slash Command Entry File

```markdown
---
name: dsys:generate
description: Generate a complete design system from screenshot benchmarks
argument-hint: "[screenshots...] [--name <project-name>] [--review]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
---

Generate a complete design system from visual benchmark screenshots.
Takes screenshot paths or a directory, analyzes them in parallel,
synthesizes design tokens, and generates platform-specific code.

@skills/dsys/dsys/SKILL.md

Arguments: $ARGUMENTS
```

### Orchestrator Stage Banner Format

```
---
## Analyzing {N} screenshots in parallel...

Launching {N} analyzer agents simultaneously. This may take 30-60 seconds.
---
```

```
---
## Synthesizing design tokens...

Merging findings from {N} screenshots into a unified design system.
---
```

```
---
## Generating {platform} files...
---
```

### Parallel Analyzer Invocation Pattern

```
Issue ALL of the following Task calls simultaneously in this response:

Task 1: Analyze hero.png
  agent: skills/dsys/agents/analyzer.md
  prompt: |
    image_path: /abs/path/to/hero.png
    output_path: .dsys/luxora/findings/hero.json

Task 2: Analyze dashboard.png
  agent: skills/dsys/agents/analyzer.md
  prompt: |
    image_path: /abs/path/to/dashboard.png
    output_path: .dsys/luxora/findings/dashboard.json

Task 3: Analyze card.png
  agent: skills/dsys/agents/analyzer.md
  prompt: |
    image_path: /abs/path/to/card.png
    output_path: .dsys/luxora/findings/card.json

Issue all three now. Do not issue one and wait — issue all three in the same response.
```

### Schema Validation Bash Pattern

```bash
# Validate a single findings file
RESULT=$(npx ajv-cli validate --spec=draft2020 \
  -s skills/dsys/schemas/analysis-findings.schema.json \
  -d .dsys/luxora/findings/hero.json 2>&1)
if echo "$RESULT" | grep -q "valid"; then
  echo "VALID: hero.json"
else
  echo "INVALID: hero.json — $RESULT"
fi
```

### Project Name Heuristic (Bash)

```bash
# From directory path
SCREENSHOTS_DIR="/Users/james/luxora/benchmarks"
PROJECT_NAME=$(basename "$SCREENSHOTS_DIR" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-$//')
# Result: "benchmarks" — falls back to date suffix if too generic

# From filename prefix
FILES="linear-dashboard.png linear-modal.png linear-sidebar.png"
# Extract basename of first file, strip extension and trailing digits/hyphens
PROJECT_NAME=$(echo "$FILES" | awk '{print $1}' | sed 's/\.[^.]*$//' | sed 's/[-_][0-9]*$//')
# Result: "linear"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Single monolithic prompt for all pipeline stages | Orchestrator + specialized sub-agents via Task tool | Phase 1 architecture decision | Sub-agents have full 200k context per stage; no context exhaustion across stages |
| Sequential per-image analysis | Parallel fan-out via Task tool | Phase 2 architecture decision | N-fold speedup for analysis stage (bottleneck in prior designs) |
| Output to project root directly | Named project directories under `.dsys/<name>/` | Phase 6 context decision | Multiple design systems can coexist; re-runs are isolated |

---

## Open Questions

1. **`@` file-include vs. prose instruction for SKILL.md loading**
   - What we know: The `@file` include mechanism in command files loads the referenced file's content into context. This is how `gsd:execute-phase` loads its workflow. The `review-plan.md` command uses `@/Users/james/.claude/rules/architecture-review.md` at runtime.
   - What's unclear: Whether `@skills/dsys/dsys/SKILL.md` works as a relative path in the command file, or requires an absolute path.
   - Recommendation: Use an absolute path in the `@` reference (e.g., `@/path/to/skills/dsys/dsys/SKILL.md`) or embed the SKILL.md content directly in `generate.md` to avoid path resolution ambiguity. HIGH priority to validate during implementation.

2. **ajv-cli output format for structured error extraction**
   - What we know: `npx ajv-cli validate --spec=draft2020 -s schema.json -d data.json` prints `data.json valid` on success and a JSON error report on failure. Exit code 0 on success, 1 on failure.
   - What's unclear: Exact format of the error output (single-line vs. multi-line JSON, whether it includes the file path).
   - Recommendation: Run ajv-cli and capture stderr+stdout. Check exit code via `$?` or `if` conditional. For the error message to the user, include the first error's `message` and `instancePath` fields. LOW risk — format is consistent enough to display directly.

3. **Absolute path requirement for agent `image_path`**
   - What we know: The analyzer agent receives `image_path` and uses the Claude Code Read tool to load the file. The Read tool documentation says it accepts absolute paths.
   - What's unclear: Whether the Read tool also accepts relative paths (relative to CWD).
   - Recommendation: Always resolve to absolute paths in the orchestrator before passing to agents. Use `realpath` or `$(pwd)/relative/path`. This eliminates any ambiguity and is consistent with how the analyzer agent was designed.

4. **Task tool prompt length limits**
   - What we know: Task tool accepts a prompt string. For analyzer agents, the prompt is 3-4 lines (image_path + output_path). For synthesizer, the prompt includes N file paths.
   - What's unclear: Whether there is a practical limit on the Task prompt string length for synthesizers receiving many findings paths.
   - Recommendation: No known limit on prompt string length. For up to 7 screenshots (the expected max), listing 7 file paths in the prompt is well within any reasonable limit. LOW risk.

---

## Sources

### Primary (HIGH confidence)
- `/Users/james/Code/dsys-tool/.planning/research/ARCHITECTURE.md` — Project architecture research: skill anatomy, SKILL.md structure, Task tool fan-out pattern, command entry file format, pipeline stage sequencing. This is the authoritative source for the overall design.
- `/Users/james/Code/dsys-tool/skills/dsys/agents/analyzer.md` — Existing analyzer agent: input parameters (`image_path`, `output_path`), return string format, error format.
- `/Users/james/Code/dsys-tool/skills/dsys/agents/synthesizer.md` — Existing synthesizer agent: input parameters (`findings_paths`, `output_path`), return string format.
- `/Users/james/Code/dsys-tool/skills/dsys/agents/react-generator.md` — Existing React generator: input parameters (`design_system_path`, `output_root`, `platforms`), return summary format.
- `/Users/james/Code/dsys-tool/skills/dsys/agents/swiftui-generator.md` — Existing SwiftUI generator: same parameter pattern as React generator.
- `/Users/james/Code/dsys-tool/skills/dsys/agents/rules.md` — Existing rules agent: input parameters (`design_system_path`, `claude_md_path`, `output_dir`, `platforms`), return format.
- `/Users/james/.claude/commands/gsd/execute-phase.md` — Reference implementation of orchestrator pattern: how to spawn Task agents, how to collect results, how to use banners between stages.
- `/Users/james/.claude/commands/review-plan.md` — Reference implementation of thin command entry file: frontmatter + @-include pattern.
- `/Users/james/Code/dsys-tool/.planning/phases/02-analysis-agent/02-RESEARCH.md` — Phase 2 research: confirmed fan-out Task pattern, ajv-cli validation, orchestrator-controlled output paths.
- `/Users/james/Code/dsys-tool/.planning/phases/04-platform-generators/04-RESEARCH.md` — Phase 4 research: confirmed agent parameter contracts for generators.

### Secondary (MEDIUM confidence)
- `/Users/james/.claude/agents/gsd-executor.md` — Agent definition anatomy: YAML frontmatter with `name`, `description`, `tools`, `color`; shows that agents are sub-agents with their own tool access list.
- `/Users/james/.claude/plugins/cache/claude-plugins-official/frontend-design/2cd88e7947b7/skills/frontend-design/SKILL.md` — Example SKILL.md from a real installed plugin: confirms structure and anatomy.

### Tertiary (LOW confidence, validate during implementation)
- Open Question 1: `@`-include relative path resolution — LOW confidence, needs empirical test during implementation.
- Open Question 3: Read tool absolute path requirement — LOW confidence, likely works with relative but absolute is safer.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools are either native Claude Code (Task, Bash, Read) or already-confirmed Phase 1 tools (ajv-cli, schemas). No new dependencies.
- Architecture: HIGH — fully specified in Phase 1 architecture research; all five agents are complete with known parameter contracts; orchestrator pattern proven by GSD system.
- Agent parameter contracts: HIGH — verified directly from agent source files; each agent's input parameters are explicitly documented in their ## Input sections.
- Interactive prompting mechanics: HIGH — natural conversational turns; no special tool needed; pattern established by conversational Claude Code usage.
- Slash command registration: MEDIUM — command anatomy verified from installed plugin and GSD commands; @-include relative path resolution is an open question (LOW confidence, see Open Questions).
- Pitfalls: HIGH — most pitfalls are derived from the established architecture constraints and confirmed from Phase 2 research documentation.

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (30 days; Claude Code Task tool and Bash tool behavior are stable; Phase 1-5 agent contracts will not change)
