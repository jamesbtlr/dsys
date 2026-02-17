# Stack Research — Design System Generation Tool

**Research type:** Project Research — Stack dimension
**Date:** 2026-02-17
**Milestone:** Greenfield — Claude Code skill for design system generation
**Confidence notation:** HIGH = verified from official docs/source; MEDIUM = well-established but verify version; LOW = directional only, must verify before committing

---

## Research Scope

This document recommends a specific, prescriptive stack for a Claude Code skill that:

1. Accepts benchmark screenshots from the user
2. Spawns parallel sub-agents that analyze each screenshot using Claude's vision API
3. A synthesizer agent merges findings into a coherent design system
4. Outputs: W3C design tokens (JSON), Tailwind v4 CSS config, SwiftUI style extensions, component templates, CLAUDE.md rules, style guide

The tool is a **Claude Code skill** (slash command backed by a Markdown prompt file), not a standalone CLI, not an MCP server.

---

## Layer 1: Claude Code Skill Architecture

### What a Claude Code Skill Is

A Claude Code skill is a Markdown file placed in `.claude/commands/` (project) or `~/.claude/commands/` (global). When the user types `/skill-name`, Claude Code reads the Markdown file and executes it as a prompt in the current session context. The skill itself is a natural language specification that instructs Claude how to behave — it is not a compiled binary or Node module.

**Confidence: HIGH** — This is the established Claude Code slash command pattern as of the Claude Code GA release.

### Sub-Agent Orchestration

Claude Code supports spawning sub-agents via the `Task` tool, which is a built-in tool available inside Claude Code sessions. A skill file can instruct the orchestrating agent to use `Task` to fan out work to parallel sub-agents. Each sub-task runs in its own context window and can use all of Claude's tools (Read, Write, Bash, WebFetch, etc.).

**Recommended pattern:**

```markdown
# /skill-name invocation flow

1. Orchestrator reads all *.png / *.jpg files in the provided directory
2. For each image: spawn a Task sub-agent with the image path and analysis prompt
3. Sub-agents write structured JSON findings to .planning/analysis/<image-name>.json
4. Orchestrator reads all JSON findings and synthesizes into unified design system
5. Orchestrator writes output files to ./design-system/
```

**Key constraints:**
- Sub-agents cannot directly return values to the parent — they communicate via the filesystem (Write/Read pattern)
- Sub-agents run sequentially by default unless the skill explicitly instructs parallel Task dispatch
- Each sub-agent inherits the parent session's tool permissions
- Image analysis uses Claude's vision: pass the image file path to a sub-agent and instruct it to Read the image

**Confidence: HIGH** — Task tool with filesystem-mediated communication is the established pattern for Claude Code multi-agent workflows.

### Skill File Location and Format

```
~/.claude/commands/dsys.md          # global, available in all projects
# OR
.claude/commands/dsys.md            # project-local
```

The skill file is pure Markdown. It uses `$ARGUMENTS` to receive user input. Example skeleton:

```markdown
# Design System Generator

Generate a complete design system from benchmark screenshots.

**Usage:** `/dsys <path-to-screenshots-directory>`

## Steps

1. List all image files in `$ARGUMENTS`
2. For each image, spawn a Task to analyze it...
```

**Confidence: HIGH**

---

## Layer 2: Image Analysis (Vision)

### Claude Vision API

Claude's vision capability is invoked by passing image file paths to the Read tool inside a Claude Code session. Claude natively understands PNG, JPEG, WebP, and GIF. No external vision library is needed.

**How sub-agents analyze images:**

```markdown
# Sub-agent prompt (written by orchestrator into the Task call)

Read the image at {{IMAGE_PATH}}. Extract:
- Color palette (hex values, semantic roles)
- Typography (font families, sizes, weights, line heights)
- Spacing system (base unit, scale)
- Border radius patterns
- Shadow/elevation system
- Component patterns visible
Output as JSON matching the schema at .planning/schemas/benchmark-analysis.schema.json
```

**Model recommendation:** `claude-opus-4-6` for analysis quality (vision tasks benefit from the most capable model). Use `claude-sonnet-4-5` for the synthesis step to balance cost and quality.

**Confidence: HIGH** — Claude's vision capabilities are well-established. Model IDs are per the system context provided.

### No External Vision Libraries Needed

Do **not** introduce external image processing libraries (Sharp, Jimp, PIL). Claude reads images natively. The only pre-processing that might be needed is resizing very large screenshots, which can be done with the macOS built-in `sips` command via Bash if screenshots exceed ~5MB.

---

## Layer 3: Design Token Generation

### W3C Design Tokens Community Group Format

The output format for tokens should be the W3C DTCG format (`.json` with `$value`, `$type`, `$description` keys). This is the emerging standard as of 2024-2025 and is supported by Style Dictionary v4.

**Reference spec:** https://design-tokens.github.io/community-group/format/

**Confidence: HIGH** — DTCG format is now the industry standard.

### Style Dictionary v4

**Package:** `style-dictionary`
**Version:** `4.x` (v4.0.0 released late 2023, actively maintained through 2024-2025)
**Confidence: MEDIUM** — verify exact current version via `npm info style-dictionary version`

Style Dictionary transforms a source token JSON into platform-specific outputs (CSS custom properties, Swift, Android XML, JS constants, etc.). It is the industry-standard token pipeline tool.

**Why Style Dictionary:**
- Native DTCG format support in v4
- Built-in transforms for CSS, Swift, Android, JavaScript
- Configurable output formats — can generate Tailwind config, SwiftUI extensions, CSS vars in one pass
- Actively maintained by the design token community
- No runtime dependency; it is a build tool

**Why not Theo:** Theo (by Salesforce) has not been actively maintained since ~2022. Style Dictionary v4 has superseded it for all practical purposes.

**Why not custom codegen:** Reinventing token transformation is high-effort, low-value. Style Dictionary handles all edge cases (aliasing, math transforms, composite types).

**Configuration pattern (JavaScript):**

```javascript
// style-dictionary.config.js
import StyleDictionary from 'style-dictionary';

const sd = new StyleDictionary({
  source: ['tokens/**/*.json'],
  platforms: {
    css: {
      transformGroup: 'css',
      prefix: 'ds',
      buildPath: 'dist/css/',
      files: [{ destination: 'tokens.css', format: 'css/variables' }]
    },
    ios_swift: {
      transformGroup: 'ios-swift',
      buildPath: 'dist/swift/',
      files: [{ destination: 'Tokens.swift', format: 'ios-swift/class.swift' }]
    },
    js: {
      transformGroup: 'js',
      buildPath: 'dist/js/',
      files: [{ destination: 'tokens.js', format: 'javascript/es6' }]
    }
  }
});

await sd.buildAllPlatforms();
```

The Claude skill generates the token JSON, then calls `npx style-dictionary build` via Bash to produce all output formats.

**Dependency install:** `npm install --save-dev style-dictionary@4`

---

## Layer 4: Tailwind CSS Config Generation

### Tailwind v4 Architecture Change

**Critical context:** Tailwind CSS v4 (released early 2025) fundamentally changed how configuration works. There is **no more `tailwind.config.js`**. Configuration is now done entirely in CSS via `@theme` directive.

**Tailwind v4 CSS config format:**

```css
/* app.css */
@import "tailwindcss";

@theme {
  --color-primary: #6366f1;
  --color-primary-50: #eef2ff;
  --color-secondary: #f59e0b;
  --font-sans: "Inter", sans-serif;
  --font-mono: "JetBrains Mono", monospace;
  --spacing-xs: 0.25rem;
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1);
}
```

**Implication for this tool:** The synthesizer agent should generate a CSS file with `@theme` block, not a `tailwind.config.js`. This is straightforward string generation — no build tool needed, just Write.

**For projects that still use Tailwind v3:** Generate `tailwind.config.js` with a `theme.extend` block. The skill should detect which version the target project uses (check `package.json`) and generate the appropriate format. Default to v4 for new projects.

**Confidence: HIGH** — Tailwind v4's CSS-first config is confirmed from official Tailwind docs and release notes.

### No Tailwind Config Generation Library Needed

There is no widely-adopted library for programmatically generating Tailwind configs. The tool should generate this as a plain text artifact — the synthesizer agent writes the CSS/JS string directly. This is appropriate because:

1. Tailwind v4 config is CSS, which is trivial to generate as a template string
2. Tailwind v3 config is a simple JS object literal
3. No library would add value over direct string generation

---

## Layer 5: SwiftUI Style Generation

### Target Output Format

SwiftUI style generation produces two artifacts:

1. **`Color+DesignSystem.swift`** — A `Color` extension with semantic color names
2. **`Typography+DesignSystem.swift`** — A `Font` extension or `TextStyle` enum
3. **`Spacing+DesignSystem.swift`** — A `CGFloat` extension with spacing constants

**Example output (Color extension):**

```swift
import SwiftUI

public extension Color {
    static let dsPrimary = Color(hex: "#6366F1")
    static let dsSecondary = Color(hex: "#F59E0B")
    static let dsBackground = Color(hex: "#FFFFFF")
    static let dsSurface = Color(hex: "#F9FAFB")
    static let dsTextPrimary = Color(hex: "#111827")
}

// Hex initializer (bundled in Utilities/Color+Hex.swift)
extension Color {
    init(hex: String) { /* ... */ }
}
```

### Style Dictionary for SwiftUI

Style Dictionary v4's `ios-swift` transform group handles this. The Claude skill should configure Style Dictionary to output Swift files, then the synthesizer can post-process or directly write them.

**Alternative — Direct generation by Claude:** Because SwiftUI extensions are simple, boilerplate-heavy, and templatable, having the Claude synthesizer agent write them directly (without Style Dictionary) is a valid and simpler approach. The agent knows the token values and can template the Swift code. This avoids needing a Node.js runtime dependency in the skill.

**Recommendation:** Generate Swift files directly via Claude (no Style Dictionary dependency for Swift output). Use Style Dictionary only for CSS/JS token outputs where the transform logic is more complex (color space conversions, rem calculations, aliasing resolution).

**Confidence: HIGH** — No special Swift codegen library is needed or standard; direct templating is the norm.

---

## Layer 6: Output File Structure

The tool should produce a structured output directory:

```
design-system/
├── tokens/
│   ├── tokens.json          # W3C DTCG source tokens
│   ├── tokens.css           # CSS custom properties (generated by Style Dictionary)
│   └── tokens.js            # JS ES6 constants (generated by Style Dictionary)
├── tailwind/
│   └── theme.css            # Tailwind v4 @theme block (or tailwind.config.js for v3)
├── swift/
│   ├── Color+DesignSystem.swift
│   ├── Typography+DesignSystem.swift
│   └── Spacing+DesignSystem.swift
├── components/
│   └── Button.tsx           # Example component templates
├── docs/
│   ├── style-guide.md       # Human-readable style guide
│   └── CLAUDE.md            # Rules for Claude to follow this design system
└── README.md
```

---

## Layer 7: Orchestration Runtime

### No Build System Required

Because this is a Claude Code skill, it runs inside the Claude Code runtime. The skill does not need:

- A bundler (no webpack, vite, esbuild)
- A test runner (no jest, vitest) — though the generated output can be tested by downstream projects
- A package.json (unless calling npm tools via Bash)

The only runtime dependency is optionally calling `npx style-dictionary build` via Bash from within a Task. This requires Node.js to be available on the user's machine, which is standard for any web developer.

### Schema Validation

The benchmark analysis JSON (output of vision sub-agents) should conform to a schema. Place the schema in `.planning/schemas/benchmark-analysis.schema.json` and instruct each sub-agent to validate against it.

Use **Ajv** for validation if running in Node context, or simply define the schema as documentation and rely on Claude's structured output adherence. For a personal tool, the latter is sufficient initially.

**Confidence: HIGH**

---

## Layer 8: What NOT to Use

| Tool/Library | Reason to Avoid |
|---|---|
| `theo` (Salesforce) | Unmaintained since ~2022; Style Dictionary v4 supersedes it |
| `tailwind.config.js` (for new projects) | Deprecated in Tailwind v4; use CSS `@theme` |
| `amazon-style-dictionary` fork | Use the official `style-dictionary` package |
| `figma-api` or Figma SDK | Out of scope; this tool works from screenshots, not Figma files |
| MCP server architecture | Over-engineered for a personal tool; plain skill is sufficient |
| Standalone CLI (commander, yargs) | Unnecessary; Claude Code provides the CLI surface |
| Image processing libs (Sharp, PIL) | Claude reads images natively; no pre-processing needed |
| GPT-4o or other vision models | Claude is the runtime; no external vision API calls needed |
| Hardcoded model IDs in skill files | Use `claude-opus-4-6` by default; let users override via CLAUDE.md |

---

## Layer 9: Dependency Summary

### Required (install in project for Style Dictionary pipeline)

```json
{
  "devDependencies": {
    "style-dictionary": "^4.0.0"
  }
}
```

**Verify current version:** `npm info style-dictionary version`

### Optional (if adding schema validation)

```json
{
  "devDependencies": {
    "ajv": "^8.0.0"
  }
}
```

### No runtime dependencies needed

The Claude Code skill itself has no `package.json`. The Style Dictionary invocation is done via `npx` or a local `node_modules/.bin/style-dictionary` call from within a Bash tool invocation inside the skill.

---

## Confidence Summary

| Decision | Confidence | Verification Needed |
|---|---|---|
| Claude Code skill as slash command in `.claude/commands/` | HIGH | None |
| Task tool for sub-agent spawning | HIGH | None |
| Filesystem-mediated inter-agent communication | HIGH | None |
| Claude vision via Read tool (no external lib) | HIGH | None |
| W3C DTCG token format | HIGH | None |
| Style Dictionary v4 for token pipeline | MEDIUM | Verify: `npm info style-dictionary version` |
| Tailwind v4 CSS-first `@theme` config | HIGH | Confirm target project Tailwind version |
| Direct Claude generation for SwiftUI extensions | HIGH | None |
| `claude-opus-4-6` for vision tasks | HIGH | Per system context |
| `claude-sonnet-4-5` for synthesis | HIGH | Per system context |
| No CLI framework needed | HIGH | None |
| No image processing library needed | HIGH | None |

---

## Open Questions for Roadmap

1. **Token aliasing depth:** Will the generated token set use aliasing (primitive → semantic → component)? Style Dictionary handles this but it adds schema complexity.
2. **Tailwind v3 support:** Should the tool support both v3 and v4? Adds branching logic.
3. **SwiftUI target version:** Swift 5.9+ supports macros; minimum iOS target affects which Swift APIs are available for color/font definition.
4. **Output validation:** Should the skill validate that generated Swift compiles? Would require `swiftc` availability on the user's machine.
5. **Style Dictionary invocation:** Is the user's machine guaranteed to have Node.js? If not, the tool should generate raw token JSON only and document the Style Dictionary step as manual.
6. **Multi-model cost control:** With many benchmark images, multiple `claude-opus-4-6` vision calls can be expensive. Consider whether `claude-sonnet-4-5` is sufficient for the analysis step.

---

## Recommended Implementation Order

1. **Skill scaffold** — Create the `.claude/commands/dsys.md` file with the orchestration prompt
2. **Analysis schema** — Define `benchmark-analysis.schema.json` for structured vision output
3. **Single-image analysis** — Implement and test single-image sub-agent with one benchmark
4. **Token generation** — Synthesizer writes W3C DTCG JSON from analysis output
5. **Style Dictionary pipeline** — Add `npx style-dictionary build` step for CSS/JS outputs
6. **Tailwind output** — Synthesizer generates `@theme` CSS block
7. **SwiftUI output** — Synthesizer generates Swift extension files
8. **Docs/CLAUDE.md output** — Generate style guide and design system rules
9. **Multi-image parallel fanout** — Extend to N images with parallel Task dispatch
10. **Polish** — Error handling, progress reporting, output validation

---

*Research conducted from training knowledge (cutoff January 2025) + document date February 2026. Items marked MEDIUM confidence must be verified against current package registries before implementation. No external web search was available during this research session.*
