# dsys

A Claude Code slash command that transforms screenshot benchmarks into a complete, immediately usable design system.

Feed it screenshots of UI you admire. It extracts colors, typography, spacing, and component patterns, then generates platform-ready code with enforcement rules so every future Claude session produces cohesive results.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/jamesbtlr/dsys/main/install.sh | bash
```

Start a new Claude Code session, then:

```
/dsys:generate path/to/screenshots/
```

To update: run the same command again. To uninstall: `rm -rf ~/.dsys-tool ~/.claude/commands/dsys`.

## What it generates

From one or more screenshots, dsys produces:

```
.dsys/<project-name>/
  findings/             # Per-screenshot analysis JSON
  design-system.json    # Unified design tokens
  react/                # Tailwind v4 CSS + React components (if selected)
  swiftui/              # SwiftUI extensions + components (if selected)
  CLAUDE.md             # Enforcement rules for Claude sessions
  STYLE-GUIDE.md        # Human-readable design reference
  preview.html          # Visual preview (opens in browser)
```

**React/Tailwind output:** `tokens.css` with CSS custom properties, `theme.css` with Tailwind v4 `@theme` block, typed components (Button, Card, Input, Badge, Heading, Text) with variant props and `forwardRef`.

**SwiftUI output:** Color asset catalog with automatic dark mode, `@ScaledMetric` spacing, DS-prefixed components (DSButton, DSCard, etc.) targeting iOS 16+.

**CLAUDE.md rules:** Binary-testable enforcement rules that prevent design drift. Every rule is answerable with yes/no: "does this code violate this rule?" Covers token usage, component usage, aesthetic guard.

## Usage

```
/dsys:generate <screenshots> [--name <project-name>] [--review]
```

**Screenshots:** Pass individual file paths or a directory containing `.png`, `.jpg`, `.jpeg`, or `.webp` files.

```bash
# Single screenshot
/dsys:generate ~/Desktop/hero.png

# Multiple screenshots
/dsys:generate ~/benchmarks/hero.png ~/benchmarks/card.png ~/benchmarks/nav.png

# Directory of screenshots
/dsys:generate ~/benchmarks/

# With explicit project name
/dsys:generate ~/benchmarks/ --name my-app

# Pause after analysis to review findings before synthesis
/dsys:generate ~/benchmarks/ --review
```

The command will:
1. Validate screenshots and resolve paths
2. Ask which platforms to generate (React/Tailwind, SwiftUI, or both)
3. Show confirmation with project name and screenshot count
4. Run analysis agents in parallel (one per screenshot)
5. Validate findings against JSON Schema
6. Synthesize findings into a unified design system
7. Generate platform-specific code
8. Generate enforcement rules and style guide
9. Open a visual preview in your browser
10. Display a file manifest and design system summary

## Integrating the output

After generation, copy the enforcement rules into your project's CLAUDE.md:

```bash
cat .dsys/<project-name>/CLAUDE.md >> CLAUDE.md
```

For React/Tailwind projects, copy the generated files:
```bash
cp -r .dsys/<project-name>/react/src/design-system/ src/design-system/
```

For SwiftUI projects:
```bash
cp -r .dsys/<project-name>/swiftui/Sources/DesignSystem/ Sources/DesignSystem/
```

## How it works

dsys is a pipeline of 5 specialized Claude agents coordinated by an orchestrator prompt:

1. **Analyzer** (1 per screenshot, parallel) - Vision-based extraction of colors, typography, spacing, and component patterns. Snaps values to standard scales (4px grid, standard font sizes, quantized hex values).

2. **Synthesizer** - Merges N analysis findings into one canonical `design-system.json`. Resolves conflicts with explicit logged choices ("pick dominant, don't blend"). Produces aesthetic summary and personality tags.

3. **React Generator** - Transforms design tokens into Tailwind v4 CSS, CSS custom properties, and typed React components with variant props.

4. **SwiftUI Generator** - Transforms design tokens into Color asset catalog, Typography/Spacing/Radius extensions, and DS-prefixed SwiftUI components.

5. **Rules Agent** - Generates binary-testable CLAUDE.md rules and a human-readable STYLE-GUIDE.md with color swatches, typography specimens, and spacing scale.

Schema validation runs between every stage boundary. If any stage fails, intermediate files persist on disk for debugging.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Node.js (for `npx ajv-cli` schema validation between pipeline stages)
