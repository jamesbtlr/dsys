# Architecture Research — dsys-tool

**Research type:** Architecture
**Question:** How are Claude Code skills structured? How do multi-agent orchestration patterns work within Claude Code? How should the pipeline from visual analysis → token extraction → multi-platform code generation be architected?
**Date:** 2026-02-17

---

## 1. How Claude Code Skills Are Structured

### Plugin and skill directory layout

A Claude Code skill lives inside a plugin. The canonical layout is:

```
my-plugin/
  commands/
    my-command.md        # Slash command entry point (/my-command)
  skills/
    my-skill/
      SKILL.md           # Skill definition and instructions
      agents/            # Sub-agent definitions invoked by this skill
        analyzer.md
        synthesizer.md
      references/        # Supplemental context files the skill loads
        patterns.md
  README.md
```

At the global level (`~/.claude/plugins/`) or project level (`.claude/plugins/`), Claude Code discovers plugins and exposes their commands as `/command-name` slash commands.

### SKILL.md anatomy

A `SKILL.md` is a Markdown file that serves as a structured prompt loaded into context when the skill is invoked. It typically contains:

- **Purpose/role**: What this skill does and what "done" means.
- **Inputs**: What the skill expects (arguments, file paths, user context).
- **Workflow steps**: Ordered instructions the orchestrating Claude instance follows.
- **Agent invocation instructions**: How to call sub-agents using the `Task` tool with their agent definition files.
- **Output specification**: What files to write and where.
- **References**: Which reference files to consult.

### Command file anatomy

A command `.md` file (e.g., `commands/dsys.md`) is the slash-command entry point. It contains frontmatter that configures the command (name, description, allowed tools) and a body that is the prompt Claude receives when the command fires. The command file typically loads the SKILL.md and passes user arguments into it.

**Key frontmatter fields:**
- `description`: Shown in the command picker.
- `allowed-tools`: Which Claude tools this command can use (e.g., `Read`, `Write`, `Task`, `Bash`).
- `argument-hint`: Shown in the UI as a placeholder for user input.

### Agent definition files

Files in `agents/` or `skills/my-skill/agents/` are sub-agent definitions. They are plain Markdown files containing a focused system prompt for a specific sub-agent role. The orchestrator invokes them via the `Task` tool:

```
Task(prompt="...", agent="path/to/agent.md")
```

The sub-agent runs with its own context window, executes its specific job, and returns a result string to the orchestrator.

---

## 2. Multi-Agent Orchestration Patterns in Claude Code

### The Task tool as the orchestration primitive

`Task` is the primary mechanism for spawning sub-agents. Each `Task` call:
- Starts a new Claude session with the sub-agent's system prompt.
- Receives a task-specific prompt as input.
- Has its own tool access (controlled by the agent's definition).
- Returns a single text result to the caller.
- Is **synchronous from the caller's perspective** — multiple `Task` calls in a single turn execute in parallel automatically when they are issued together in the same response.

Claude Code's runtime handles the parallelism; the orchestrator does not manage threads. The pattern is: issue all independent `Task` calls in one turn, collect results, then proceed.

### Fan-out / fan-in pattern (the relevant pattern for this tool)

```
Orchestrator
  ├─ Task(agent: analyzer, input: screenshot_1) ─┐
  ├─ Task(agent: analyzer, input: screenshot_2) ─┤ (parallel)
  └─ Task(agent: analyzer, input: screenshot_N) ─┘
         ↓ (all results arrive)
  Task(agent: synthesizer, input: [findings_1..N])
         ↓
  Task(agent: generator, input: synthesized_system + platform_target)
```

The fan-out tier runs N analysis agents in parallel. The fan-in tier runs one synthesizer that receives all N results as a combined input. This is the canonical pattern for variable-count parallel processing in Claude Code.

### Passing data between agents

Sub-agents cannot communicate directly. Data flows only through the orchestrator:

1. Orchestrator calls N analysis agents in parallel via `Task`.
2. Orchestrator collects all N result strings.
3. Orchestrator calls synthesizer with all N results concatenated into a single prompt.
4. Synthesizer returns a structured intermediate representation.
5. Orchestrator calls generator(s) with the intermediate representation.

For structured data exchange, the intermediate representation should be a defined schema (e.g., JSON or structured Markdown) that all agents in the pipeline write and read consistently. Using a file on disk (e.g., `.dsys/intermediate.json`) is an alternative for large payloads that exceed prompt length limits, and is preferable for anything that needs to persist or be inspected.

### Agent granularity recommendation

Each agent should have **one clear job** with a defined input schema and output schema. This keeps agents replaceable and testable in isolation. For this tool:

- **Analysis agent**: Input = one image/URL + analysis rubric. Output = structured findings for that benchmark.
- **Synthesizer agent**: Input = N sets of findings. Output = one coherent design system definition.
- **Generator agent**: Input = design system definition + platform target. Output = platform-specific files.
- **Rules agent**: Input = design system definition. Output = CLAUDE.md rules text.

Do not merge synthesizer + generator into one agent. They have different inputs, different expertise domains, and separating them makes it possible to re-run generation against a cached synthesis.

---

## 3. Recommended Pipeline Architecture

### Component map

```
┌─────────────────────────────────────────────────────────────┐
│  Claude Code Session                                         │
│                                                              │
│  /dsys [screenshot1] [screenshot2] ... [--target react|swift]│
│         │                                                    │
│  commands/dsys.md                                            │
│         │ (loads)                                            │
│  skills/dsys/SKILL.md  ←─── references/analysis-rubric.md   │
│         │              ←─── references/token-schema.md       │
│         │              ←─── references/platform-specs.md     │
│         │                                                    │
│  [ORCHESTRATOR LOGIC]                                        │
│         │                                                    │
│  ┌──────┴──────────────────────────────┐                     │
│  │  Fan-out: one Task per input image  │                     │
│  ├─────────┬─────────┬─────────────── ┤                     │
│  │Analyzer │Analyzer │Analyzer (N)    │                     │
│  │agent.md │agent.md │agent.md        │                     │
│  └────┬────┴────┬────┴────────────────┘                     │
│       │         │  (results collected)                       │
│       └────┬────┘                                            │
│            │                                                 │
│  Task: synthesizer/agent.md                                  │
│            │                                                 │
│  .dsys/design-system.json  (intermediate artifact)           │
│            │                                                 │
│  ┌─────────┴──────────────┐                                  │
│  │  Platform generators   │                                  │
│  ├────────────┬───────────┤                                  │
│  │React/Tailwind│SwiftUI  │                                  │
│  │generator.md │generator │                                  │
│  └────────────┴───────────┘                                  │
│            │                                                 │
│  Task: rules/agent.md                                        │
│            │                                                 │
│  [Output files written]                                      │
└─────────────────────────────────────────────────────────────┘
```

### Component definitions and boundaries

| Component | File | Inputs | Outputs | Owns |
|-----------|------|--------|---------|------|
| Command entry point | `commands/dsys.md` | User args (images, `--target`) | Triggers skill | Argument parsing, validation, user-facing error messages |
| Orchestrator | `skills/dsys/SKILL.md` | Parsed args from command | All file outputs | Sequencing, fan-out/fan-in, error aggregation |
| Analysis agent | `agents/analyzer.md` | One image + rubric | Structured findings JSON | Visual analysis, token extraction per benchmark |
| Synthesis agent | `agents/synthesizer.md` | N findings JSONs | `design-system.json` | Conflict resolution, normalization, coherence |
| React/Tailwind generator | `agents/generator-react.md` | `design-system.json` | Tailwind config, component stubs, style guide | React-specific idioms, Tailwind v4 config format |
| SwiftUI generator | `agents/generator-swiftui.md` | `design-system.json` | Color/Font extensions, spacing constants, view templates | SwiftUI-specific idioms, Swift naming conventions |
| Rules agent | `agents/rules.md` | `design-system.json` | `CLAUDE.md` rules block | Translating system constraints into enforcement prose |

### Intermediate representation: design-system.json

The synthesizer writes and the generators read a shared intermediate artifact. Using a file (not just a string return) is important because:

1. It survives context limits when the design system is large.
2. It can be inspected and edited by the user before generation.
3. It allows re-running generators without re-running analysis and synthesis.
4. It is the natural checkpoint for a two-phase workflow (analyze → generate).

Minimum schema for `design-system.json`:

```json
{
  "meta": {
    "generated_at": "ISO timestamp",
    "benchmark_count": 3,
    "aesthetic_summary": "..."
  },
  "tokens": {
    "colors": {
      "primary": "#...",
      "secondary": "#...",
      "surface": "#...",
      "text_primary": "#...",
      "text_secondary": "#..."
    },
    "typography": {
      "font_family_sans": "...",
      "font_family_mono": "...",
      "scale": [12, 14, 16, 20, 24, 32, 48]
    },
    "spacing": {
      "base_unit": 4,
      "scale": [4, 8, 12, 16, 24, 32, 48, 64, 96]
    },
    "radius": { "sm": 4, "md": 8, "lg": 16, "full": 9999 },
    "shadows": [],
    "motion": {}
  },
  "components": {
    "button": { "variants": [...], "anatomy": "..." },
    "card": { "variants": [...], "anatomy": "..." }
  },
  "aesthetic": {
    "personality": "...",
    "density": "compact|comfortable|spacious",
    "tone": "minimal|expressive|corporate"
  },
  "platform_notes": {
    "react": "...",
    "swiftui": "..."
  }
}
```

### Analysis rubric (reference file)

The analyzer agent needs a consistent extraction rubric so all N agents produce comparable output. A `references/analysis-rubric.md` file should define exactly what properties to extract and the output format, so the synthesizer receives normalized input regardless of benchmark count.

Key rubric dimensions:
- Color palette (dominant, accent, surface, text hierarchy)
- Typography (families, scale, weight usage patterns)
- Spacing rhythm (base unit, density)
- Border/radius treatment
- Shadow/depth treatment
- Motion/animation presence
- Component density and padding conventions
- Aesthetic personality descriptors

---

## 4. Data Flow (Explicit)

```
[User] /dsys screenshot1.png screenshot2.png --target react

          │
          ▼
[commands/dsys.md]
  - Parse arguments
  - Validate: images exist, target is valid
  - Error-exit with message if invalid

          │
          ▼
[SKILL.md — Orchestrator]
  - Load reference files (rubric, schema, platform specs)
  - Determine output directory (project root or --output arg)

          │
          ▼  (parallel Task calls, one per image)
[agents/analyzer.md] × N
  - Receives: image bytes (via Read or user-provided path) + rubric
  - Vision analysis of the image
  - Returns: findings JSON (one per benchmark)

          │  (all N results collected)
          ▼
[agents/synthesizer.md]
  - Receives: concatenated findings from all N analyzers
  - Resolves conflicts (e.g., two benchmarks have different primary colors → decide)
  - Writes: .dsys/design-system.json to disk

          │
          ▼  (conditional on --target; generators run in parallel if both targets requested)
[agents/generator-react.md]          [agents/generator-swiftui.md]
  - Reads: .dsys/design-system.json    - Reads: .dsys/design-system.json
  - Writes to: ./dsys/react/           - Writes to: ./dsys/swiftui/
    - tailwind.config.js                 - Colors+Fonts.swift
    - tokens.css                         - Spacing.swift
    - components/*.tsx stubs             - Components/*.swift stubs
    - STYLEGUIDE.md                      - STYLEGUIDE.md

          │  (both generators complete)
          ▼
[agents/rules.md]
  - Reads: .dsys/design-system.json
  - Writes: .dsys/CLAUDE.md-rules.md
  - (User manually incorporates into project CLAUDE.md)

          │
          ▼
[Orchestrator — final summary]
  - Reports all written files to the user
  - Notes any conflicts resolved during synthesis
  - Suggests next steps
```

---

## 5. Build Order (Dependencies)

The components have clear dependency ordering. Build in this sequence:

### Phase 1 — Foundation (no dependencies)
1. **Intermediate schema** (`design-system.json` spec): Define this first. Everything else depends on it. Write it as a reference document at `skills/dsys/references/token-schema.md`.
2. **Analysis rubric**: The extraction rubric the analyzer uses. Write as `skills/dsys/references/analysis-rubric.md`.
3. **Platform specs**: Per-platform output format specs (Tailwind config structure, SwiftUI extension patterns). Write as `skills/dsys/references/platform-specs.md`.

### Phase 2 — Analysis agent (depends on: rubric, schema)
4. **Analyzer agent** (`agents/analyzer.md`): The most isolated agent. Takes an image, applies the rubric, returns structured findings. Can be tested in isolation by feeding it a single screenshot and inspecting the JSON output.

### Phase 3 — Synthesis agent (depends on: schema, Phase 2 output format)
5. **Synthesizer agent** (`agents/synthesizer.md`): Takes N analyzer outputs, merges into `design-system.json`. Can be tested with pre-baked analyzer outputs from Phase 2 testing.

### Phase 4 — Generator agents (depend on: schema, Phase 3 output, platform specs)
6. **React/Tailwind generator** (`agents/generator-react.md`): Takes `design-system.json`, writes platform files. Can be tested with a pre-baked `design-system.json` from Phase 3 testing.
7. **SwiftUI generator** (`agents/generator-swiftui.md`): Same as above but for Swift/SwiftUI conventions. Can be developed in parallel with the React generator since they share only the input schema.

### Phase 5 — Rules agent (depends on: schema, Phase 3 output)
8. **Rules agent** (`agents/rules.md`): Takes `design-system.json`, produces CLAUDE.md rules. Can be tested with a pre-baked design system. Lowest risk, most straightforward.

### Phase 6 — Orchestrator and command (depends on: all agents)
9. **SKILL.md orchestrator**: Wire all agents together in the correct sequence with fan-out/fan-in logic.
10. **Command entry point** (`commands/dsys.md`): Argument parsing, validation, user-facing presentation.

**Key insight**: Agents 6 and 7 (React generator, SwiftUI generator) can be built and tested in parallel since they share only the input schema. All other dependencies are strictly sequential.

---

## 6. Key Architecture Decisions

### Decision: File-based intermediate representation vs. string-only

**Options:**
1. String-only: Synthesizer returns JSON as a string → orchestrator passes it directly to generators.
2. File-based: Synthesizer writes `.dsys/design-system.json` to disk → generators read from disk.

**Recommendation: File-based.** String-only works for small design systems but breaks at scale (large token sets, component inventories). The file approach also gives the user a checkpoint — they can inspect and edit the design system before generation. This is critical UX for a design tool. The file also persists across re-runs, enabling "re-generate just SwiftUI" without re-analyzing benchmarks.

### Decision: One generator agent per platform vs. single multi-platform generator

**Options:**
1. Single generator with platform switch: One agent, conditional logic for React vs. SwiftUI.
2. Separate agents per platform: One agent per target.

**Recommendation: Separate agents per platform.** React/Tailwind and SwiftUI have fundamentally different conventions (CSS variables vs. Swift extensions, Tailwind config vs. SPM package, JSX templates vs. ViewModifiers). A single agent would require complex branching and would produce a muddled, less expert prompt. Separate agents can each be experts in their platform. They also run in parallel when both targets are requested.

### Decision: Rules agent separate from generators vs. embedded in generators

**Options:**
1. Each generator also emits its own CLAUDE.md rules block.
2. Separate rules agent that reads the design system and produces unified rules.

**Recommendation: Separate rules agent.** CLAUDE.md rules are platform-agnostic (they describe the design system's principles, not how to implement them in a specific language). A single rules agent produces one coherent enforcement document rather than two fragmented blocks that may contradict each other.

### Decision: Analysis rubric format

**Options:**
1. Free-form: Let the analyzer agent discover whatever it finds relevant.
2. Structured rubric: Define exactly what to extract and the output schema.

**Recommendation: Structured rubric.** Free-form analysis produces results that are incompatible across benchmark runs, making synthesis error-prone. A structured rubric ensures the synthesizer receives N identical-schema objects, reducing the synthesis task to conflict resolution rather than schema reconciliation. The rubric is stored as a reference file so it can be tuned without modifying the agent.

---

## 7. Edge Cases and Constraints

### Variable input count (1 to N)
- Single benchmark (N=1): Synthesizer is still called, but performs normalization only (no conflict resolution needed). Do not skip synthesis — it ensures the intermediate representation is always produced consistently.
- Large N (mood board, 10+ images): Each analysis agent runs in parallel, so wall-clock time scales with the slowest image, not with N. However, the synthesizer prompt grows linearly with N. For N > 10, consider having the synthesizer do two-pass merging (merge pairs, then merge pairs of pairs) to avoid context saturation.

### Image input formats
- Claude's vision supports PNG, JPEG, GIF, WebP. The command should validate file extensions and provide a clear error for unsupported formats.
- URLs as benchmarks: Can be passed to agents as text, letting the agent use `WebFetch`. Add to scope explicitly if desired, but mark as an edge case — screenshot files are the primary v1 path.

### Platform target selection
- Default: Prompt user to choose if `--target` is not provided. Do not silently default to one platform.
- Both targets: Run both generator agents in parallel. Make this explicit in the command help.

### Output directory collision
- If `.dsys/` already exists, the tool should not silently overwrite. Either prompt or use `--overwrite` flag. Design system re-generation is a deliberate action.

### Long-running context
- The orchestrator runs multiple Task calls sequentially. Each Task is a fresh context, but the orchestrator itself accumulates context across turns. For very large design systems, summarize intermediate results before passing to the next agent.

---

## 8. File Structure for the Skill

```
dsys-tool/
  commands/
    dsys.md                          # /dsys entry point
  skills/
    dsys/
      SKILL.md                       # Orchestrator instructions
      agents/
        analyzer.md                  # Per-benchmark visual analysis
        synthesizer.md               # Merge N findings → design-system.json
        generator-react.md           # React/Tailwind output
        generator-swiftui.md         # SwiftUI output
        rules.md                     # CLAUDE.md rules generation
      references/
        analysis-rubric.md           # Extraction rubric for the analyzer
        token-schema.md              # design-system.json schema spec
        platform-specs/
          react-tailwind-spec.md     # What to produce for React target
          swiftui-spec.md            # What to produce for SwiftUI target
  .dsys/                             # Generated output (gitignored or committed)
    design-system.json               # Intermediate artifact
    react/
      tailwind.config.js
      tokens.css
      STYLEGUIDE.md
      components/
    swiftui/
      Colors.swift
      Typography.swift
      Spacing.swift
      STYLEGUIDE.md
      Components/
    CLAUDE.md-rules.md               # Rules block for user's CLAUDE.md
```

---

## Summary

| Concern | Answer |
|---------|--------|
| Skill entry point | `commands/dsys.md` — slash command that parses args and loads SKILL.md |
| Orchestration mechanism | `Task` tool calls in SKILL.md; parallel calls for fan-out, sequential for fan-in |
| Analysis parallelism | One analyzer agent per benchmark, all issued in the same Task batch |
| Data handoff between agents | File-based (`.dsys/design-system.json`) for persistence and inspectability |
| Generator strategy | One agent per platform (React, SwiftUI), run in parallel when both requested |
| Rules generation | Separate agent from generators; produces unified platform-agnostic enforcement doc |
| Build order | Schema → Rubric → Analyzer → Synthesizer → Generators (parallel) → Rules → Orchestrator → Command |
| Key constraint | Analyzers produce normalized schema; synthesizer does conflict resolution, not schema discovery |
