# Phase 4: Platform Generators - Research

**Researched:** 2026-02-18
**Domain:** Prompt engineering — React/Tailwind CSS v4 generator agent and SwiftUI generator agent
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Component depth
- Production-ready components: fully styled with multiple variants, states, and accessibility attributes
- Button variants: full set — primary, secondary, destructive, ghost, outline
- Size variants only where natural: Button and Input get sm/md/lg; Card, Badge, Heading, Text do not
- Full interactive states: disabled, loading (with spinner), focus-visible, hover — production behavior out of the box

#### Output organization
- Output written to project root directories: `src/design-system/` for React, `Sources/DesignSystem/` for SwiftUI
- Nested by concern: `tokens/`, `components/`, `types/` — clear separation within each platform directory
- Barrel/index files: `index.ts` (React) and `DesignSystem.swift` (SwiftUI) re-exporting all tokens and components
- Overwrite with backup: regeneration overwrites existing files but saves previous version as `.bak`

#### Tailwind patterns
- Components use Tailwind utility classes internally; CSS custom properties also exported for non-Tailwind usage
- Dark mode: both prefers-color-scheme (automatic) and class-based toggle (manual override) — Tailwind v4's darkMode selector strategy
- React component pattern: Claude's discretion (forwardRef + slots vs simple function components — pick per component complexity)
- className merging approach: Claude's discretion (cn() utility vs raw concat — pick based on component complexity)

#### SwiftUI component API
- Variant selection pattern: Claude's discretion (enum-based init vs view modifiers — pick most idiomatic)
- Minimal #Preview blocks: single preview with default configuration per component, user builds their own for more
- Built-in accessibility: components apply sensible default accessibilityLabel and traits — VoiceOver works out of the box
- Asset catalog JSON: generate .colorset folders with Contents.json for full Xcode integration and OS-managed dark mode switching (no Swift Color extensions as alternative)

### Claude's Discretion
- React component pattern (forwardRef + slots vs simple function components)
- className merging approach (cn() utility vs raw string concat)
- SwiftUI variant selection pattern (enum-based init vs view modifiers)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| OUT-01 | Tool outputs platform-agnostic design tokens in W3C DTCG JSON format | Generator reads design-system.json (already DTCG-conformant) and writes tokens.json — direct structural transformation |
| OUT-02 | Tool generates React/Tailwind artifacts (Tailwind v4 CSS @theme config, utility classes) | react-tailwind-spec.md (Phase 1 artifact) fully specifies every file; generator embeds the spec as fill-in template |
| OUT-03 | Tool generates SwiftUI artifacts (Color/Font/Spacing extensions with idiomatic Swift patterns) | swiftui-spec.md (Phase 1 artifact) fully specifies every file with complete code examples |
| OUT-04 | User can select which platform target(s) to generate per project | Generator agent accepts `platforms` parameter: "react", "swiftui", or "both" |
| OUT-05 | SwiftUI output uses @ScaledMetric, asset catalog references, and #Preview blocks | swiftui-spec.md provides the exact patterns; confirmed in prior phases |
| OUT-06 | Tailwind output constrains the theme (replaces defaults, not extends) to enforce the design system | `--color-*: initial;` as first @theme declaration is documented in react-tailwind-spec.md and locked in STATE.md |
| COMP-01 | Tool generates starter component templates (Button, Card, Input, Badge, Heading, Text) using the design tokens | Both specs include complete code examples for all 6 components |
| COMP-02 | React/Tailwind component templates use idiomatic JSX + Tailwind class patterns | Spec enforces forwardRef + Tailwind semantic class names; no raw hex or pixel values |
| COMP-03 | SwiftUI component templates use idiomatic View composition and modifiers | Spec enforces DS-prefixed struct views, Color.dsX extensions, DSFont/DSSpacing/DSRadius tokens |
</phase_requirements>

---

## Summary

Phase 4 is a prompt-writing phase — identical in nature to Phases 2 and 3. It produces two Markdown agent prompts: `skills/dsys/agents/react-generator.md` and `skills/dsys/agents/swiftui-generator.md`. Both agents read `.dsys/design-system.json` and write platform files directly (no external tools, no compiled code). The React generator writes CSS and TSX files. The SwiftUI generator writes Swift source files and asset catalog JSON directories.

The critical insight is that the Platform Specifications (`react-tailwind-spec.md` and `swiftui-spec.md`) were already written in Phase 1 and contain every file, every code pattern, every naming convention, and every "done" checklist needed. These specs are the fill-in templates for the generator prompts — the same approach proven by Phase 2 (embedded rubric) and Phase 3 (embedded fill-in template). The generator agents embed these specs verbatim and follow them step by step.

The locked decision from CONTEXT.md expands Phase 4's component scope beyond what the Phase 1 specs showed. The specs define primary/secondary/destructive variants, but the user wants the full set: primary, secondary, destructive, ghost, outline. The loading-with-spinner state is also new. These additions must be incorporated into the component templates the agents generate, and the spec sections in the prompts must be updated accordingly. This is the primary authoring task — the CSS token transformation is mechanical; the component template expansion requires careful authoring.

**Primary recommendation:** Write two generator prompts that embed the respective platform spec verbatim and extend the component templates beyond the spec's examples. Use the Phase 2/3 agent anatomy pattern (role → input → steps → embedded spec → embedded template → output instructions). Write React generator first, validate against the existing `design-system.json`, then write SwiftUI generator.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code Read tool | Native | Load `design-system.json` from disk | Proven in Phases 2 and 3; zero external dependencies |
| Claude Code Write tool | Native | Write all output files (CSS, TSX, Swift, JSON) | Same pattern; atomic file writes |
| `design-system.schema.json` | Phase 1 artifact | Validated structure of input (generator reads it to understand the schema) | Already on disk; agents reference this to know what fields are guaranteed |
| `react-tailwind-spec.md` | Phase 1 artifact | Complete output specification for React/Tailwind generator | Fully specifies every file format, naming convention, component API, and "done" checklist |
| `swiftui-spec.md` | Phase 1 artifact | Complete output specification for SwiftUI generator | Same; specifies Swift patterns, asset catalog JSON format, iOS 16 constraints |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `npx ajv-cli` | 8.x | Optional post-generation schema validation of tokens.json | Use in verification step to confirm tokens.json is valid DTCG |
| Style Dictionary v5.3.1 | via npx | Optional: user can run against generated tokens.json for additional platform outputs | Not run by the generator agent; tokens.json is provided as a starting point for users |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct Claude file generation | Style Dictionary v5 as generator | Style Dictionary requires config, custom transforms for the `{light, dark}` $value pattern (not natively supported by SD's `expand` for non-DTCG composite types), and Node invocation. Claude generates identical output with zero tooling setup. |
| Single combined generator agent | Two separate agents (React + SwiftUI) | One agent is simpler to invoke but would be 800+ lines of embedded specs. Two agents are cleaner, more maintainable, and can be invoked independently when user selects only one platform. |
| cn() utility for className merging | Raw string concatenation | cn() (clsx + tailwind-merge) is production-standard but adds a dependency. For generated components, raw `${className ?? ""}` suffix is sufficient and dependency-free. Recommend raw concat — generator produces standalone files. |

**No new installations required.** All dependencies are native Claude tools or Phase 1 artifacts already on disk.

---

## Architecture Patterns

### Recommended File Structure

```
skills/dsys/
├── agents/
│   ├── analyzer.md           # Phase 2 — complete
│   ├── synthesizer.md        # Phase 3 — complete
│   ├── react-generator.md    # PHASE 4 DELIVERABLE 1
│   └── swiftui-generator.md  # PHASE 4 DELIVERABLE 2
├── references/
│   ├── platform-specs/
│   │   ├── react-tailwind-spec.md  # Phase 1 — embed in react-generator.md
│   │   └── swiftui-spec.md         # Phase 1 — embed in swiftui-generator.md
│   └── token-schema.md             # Phase 1 — reference for input shape
└── schemas/
    └── design-system.schema.json   # Phase 1 — input validation reference

.dsys/
└── design-system.json              # Phase 3 output — generator input

# Generated outputs (NOT in skills/ — written to user's project root):
src/design-system/            # React generator output
├── tokens/
│   ├── tokens.json
│   ├── tokens.css
│   └── theme.css
├── components/
│   ├── Button.tsx
│   ├── Card.tsx
│   ├── Input.tsx
│   ├── Badge.tsx
│   ├── Heading.tsx
│   └── Text.tsx
├── types/
│   └── design-tokens.d.ts
└── index.ts

Sources/DesignSystem/         # SwiftUI generator output
├── Colors+DesignSystem.swift
├── Typography+DesignSystem.swift
├── Spacing+DesignSystem.swift
├── Radius+DesignSystem.swift
├── Shadows+DesignSystem.swift
├── Colors.xcassets/
│   ├── Contents.json
│   └── {tokenName}.colorset/
│       └── Contents.json     # (one per semantic color token)
├── Components/
│   ├── DSButton.swift
│   ├── DSCard.swift
│   ├── DSInput.swift
│   ├── DSBadge.swift
│   ├── DSHeading.swift
│   └── DSText.swift
└── DesignSystem.swift        # Barrel re-export
```

### Pattern 1: Generator Agent Anatomy (Established in Phases 2 and 3)

**What:** The generator follows the same agent file anatomy as analyzer.md and synthesizer.md: frontmatter → role → input → numbered steps → embedded spec → embedded component templates → output instructions.

**When to use:** Always. The anatomy is the project standard.

**Structure:**

```markdown
---
name: dsys-react-generator
description: Reads design-system.json and writes React/Tailwind design system files
tools: Read, Write
---

# dsys React/Tailwind Generator

## Role
[What it reads, what it writes, what "complete" means]

## Input
[Parameters: design_system_path, output_root, platforms]

## Step 1: Load and Validate Design System
[Read design-system.json, verify required fields]

## Step 2: Resolve All Token Values
[Expand {light, dark} $value objects; resolve {tokens.x.y} references]

## Step 3: Write tokens.json
[Direct DTCG transformation]

## Step 4: Write tokens.css
[CSS custom properties: :root, @media dark, .dark class]

## Step 5: Write theme.css
[Tailwind v4 @theme with --color-*: initial; first]

## Step 6: Write Component Files
[One step per component — 6 components × React or SwiftUI]

## Step 7: Write Barrel/Index File

## Step 8: Write types/design-tokens.d.ts (React only)

## Step 9: Self-Check
[Verify all required files written, no raw hex/pixel values in components]

## Step 10: Return Summary

## Reference: Output Specification
[EMBED react-tailwind-spec.md verbatim]

## Reference: Component Templates
[Embed full expanded component examples matching locked decisions]
```

**Why algorithm steps before embedded spec:** Agent has the step-by-step procedure in working memory when it fills the templates. Prevents the agent from reading the spec as a reference document and improvising.

### Pattern 2: Token Value Resolution (Critical)

**What:** `design-system.json` semantic color tokens use two `$value` formats:
1. `{light: "#hex", dark: "#hex"}` — theme-aware flat values
2. `{light: "{tokens.color.primitive.blue.500}", dark: "{tokens.color.primitive.blue.400}"}` — references to primitive tokens

The generator must resolve both formats before emitting CSS. The agent is responsible for reference expansion — it cannot rely on Style Dictionary for this.

**Resolution algorithm (embed in generator prompt):**

```
For each semantic color token $value:
  If $value is a string: use as-is (e.g., text.inverse = "#FFFFFF")
  If $value is {light, dark}: resolve each:
    If light/dark is a raw hex string: use as-is
    If light/dark is a DTCG reference "{tokens.color.primitive.X.Y}":
      Look up X.Y in tokens.color.primitive
      Replace with the $value of that primitive token
```

**Example resolution:**
```
action.primary.$value.light = "{tokens.color.primitive.blue.500}"
  → look up tokens.color.primitive.blue.500.$value
  → "#3B82F6"
  → emit: --ds-color-action-primary: #3B82F6;
```

**When to use:** Always, in Step 2 of the agent, before writing any output files.

### Pattern 3: Tailwind v4 Dark Mode — Both Strategies Simultaneously

**What:** The user decision locks "both prefers-color-scheme (automatic) and class-based toggle (manual override)." Tailwind v4 handles this via CSS custom properties, not via utility class duplication.

**The correct Tailwind v4 pattern (verified from official docs):**

The tokens.css file handles the actual color switching via CSS custom properties:
```css
:root { --ds-color-action-primary: #3B82F6; }                    /* light */
@media (prefers-color-scheme: dark) { :root { --ds-color-action-primary: #1D4ED8; } }  /* auto dark */
.dark { --ds-color-action-primary: #1D4ED8; }                    /* manual dark */
```

The theme.css uses `var(--ds-color-*)` references — not hardcoded hex — so dark mode is handled by whatever overrides the `--ds-*` variables:
```css
@theme {
  --color-*: initial;
  --color-primary: var(--ds-color-action-primary);  /* inherits from CSS var */
}
```

For the `@custom-variant` approach (adding `.dark` class override for Tailwind `dark:` utilities):
```css
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));
```

**This means:** The `theme.css` file must be accompanied by `@custom-variant dark` to allow `dark:` utilities to work with the `.dark` class approach. Include this in `theme.css` after the `@import`.

**Source:** https://tailwindcss.com/docs/dark-mode (verified February 2026)

### Pattern 4: SwiftUI Variant Selection (Claude's Discretion — Recommendation)

**Recommendation:** Enum-based init over view modifiers.

**Rationale:** Enum-based init is more SwiftUI-idiomatic for components with a fixed set of discrete variants (primary/secondary/destructive). View modifiers are better for cross-cutting concerns (shadows, accessibility labels, padding). For `DSButton(.primary)`, an enum init makes the relationship between the button and its variant obvious at the call site. A modifier approach like `DSButton(...).primary()` is less conventional and creates odd ergonomics for variants that affect internal styling.

The swiftui-spec.md uses enum-based init throughout (Phase 1 artifact). Follow it.

**Pattern:**
```swift
public struct DSButton: View {
    public enum Variant { case primary, secondary, destructive, ghost, outline }
    public enum Size { case sm, md, lg }

    let title: String
    let variant: Variant
    let size: Size
    let action: () -> Void

    public init(_ title: String, variant: Variant = .primary, size: Size = .md, action: @escaping () -> Void) { ... }
}
```

### Pattern 5: React Component Pattern (Claude's Discretion — Recommendation)

**Recommendation:** `forwardRef` for components that wrap native DOM elements (Button, Input); plain function components for layout/composition components (Card, Badge, Heading, Text).

**Rationale:** `forwardRef` is required when a parent needs to control focus/scroll on a native element. Button and Input are always used in forms/focus management contexts. Card, Badge, Heading, and Text are pure composition — no DOM ref usage exists in practice.

**The generated Button.tsx already in react-tailwind-spec.md demonstrates this:** Button uses `forwardRef<HTMLButtonElement, ButtonProps>`, Input uses `forwardRef<HTMLInputElement, InputProps>`, Card uses `forwardRef<HTMLDivElement, CardProps>` for convenience.

**Recommendation:** Apply `forwardRef` to all 6 components for consistency. The spec already does this. The inconsistency of "some forwardRef, some not" is a maintenance burden.

### Pattern 6: Asset Catalog JSON Generation (SwiftUI)

**What:** The SwiftUI generator must produce a directory tree of `.colorset/Contents.json` files — one per semantic color token. The Contents.json format is exact and non-negotiable for Xcode to recognize the colors.

**Exact Contents.json format (from swiftui-spec.md, verified):**

```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "red":   "0.231",
          "green": "0.510",
          "blue":  "0.965",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    },
    {
      "appearances": [
        { "appearance": "luminosity", "value": "dark" }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "red":   "0.114",
          "green": "0.306",
          "blue":  "0.847",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": { "version": 1, "author": "xcode" }
}
```

**Hex to sRGB conversion:** `decimal = hex_component / 255`, formatted to 3 decimal places.

**Critical:** First entry has no `appearances` key (universal/light). Second entry has `appearances: [{appearance: "luminosity", value: "dark"}]`. Order matters.

**Generator must produce:**
- `Colors.xcassets/Contents.json` — top-level catalog manifest
- `Colors.xcassets/{tokenName}.colorset/Contents.json` — one per semantic color token

Token names follow camelCase: `dsActionPrimary`, `dsSurfaceDefault`, etc. (matching the `Color("name", bundle: .module)` string in `Colors+DesignSystem.swift`).

### Pattern 7: Output Root Conflict (Spec vs. CONTEXT.md)

**What:** The Phase 1 `react-tailwind-spec.md` says the output root defaults to `./design-system/`. The CONTEXT.md locks the output root as `src/design-system/` for React and `Sources/DesignSystem/` for SwiftUI.

**Resolution:** CONTEXT.md overrides the Phase 1 spec for output root. The generator agents must accept an `output_root` parameter but default to:
- React: `src/design-system/`
- SwiftUI: `Sources/DesignSystem/`

The internal structure within the output root follows the CONTEXT.md: `tokens/`, `components/`, `types/` subdirectories.

**Note:** The Phase 1 spec shows `components/` at the root, but the CONTEXT.md says to nest by concern: `tokens/`, `components/`, `types/`. The CONTEXT.md wins. The generator must create these subdirectories.

### Pattern 8: types/design-tokens.d.ts (React — Claude's Discretion)

**What:** The CONTEXT.md adds a `types/` directory to the React output. The Phase 1 spec does not include a types file. This is a new addition that the generator must author.

**Recommendation:** Generate a TypeScript declaration file that exports the type-safe token names. This prevents typos when using tokens in downstream code.

```typescript
// types/design-tokens.d.ts — generated by dsys

export type DSColorToken =
  | 'action-primary' | 'action-secondary' | 'action-destructive'
  | 'surface-default' | 'surface-raised' | 'surface-overlay' | 'surface-inset'
  | 'text-primary' | 'text-secondary' | 'text-muted' | 'text-inverse' | 'text-link'
  | 'border-default' | 'border-focus'
  | 'feedback-success' | 'feedback-error' | 'feedback-warning' | 'feedback-info';

export type DSSpacingStep = 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 | 12 | 16 | 20 | 24 | 32;

export type DSRadiusStep = 'sm' | 'md' | 'lg' | 'full';

export type DSFontSize = 'xs' | 'sm' | 'base' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl';
```

This is a small file (< 30 lines) and can be authored by the generator agent directly from the token schema.

### Anti-Patterns to Avoid

- **Hardcoded hex values in component Tailwind classes:** Components must use semantic Tailwind class names (`bg-primary`, `text-text-muted`) — never raw hex (`text-[#1A2B1A]`) or default Tailwind colors (`text-gray-900`). This is enforced by the spec's "done" checklist.
- **Raw pixel values in components:** Use Tailwind spacing utilities (`p-4`, `gap-2`) not raw values (`p-[13px]`, `gap-[12px]`).
- **Using `display: none` instead of conditional returns for loading state:** The React loading state must render a spinner inline, not toggle visibility — better for screen readers.
- **Omitting the `--color-*: initial;` reset:** Without this, Tailwind's entire default palette is available alongside the design system palette, defeating enforcement. This is the most catastrophic omission.
- **Hardcoded Color values in SwiftUI components:** Never `Color.blue`, `Color(red: 0.2, green: 0.4, blue: 0.9)`, or `#colorLiteral`. Always `Color.dsActionPrimary` from the extension.
- **Static @ScaledMetric in DSSpacing:** The `@ScaledMetric` property wrapper only works on instance properties. `static var` with `@ScaledMetric` does not compile. The generator must produce instance properties in a struct, not static properties on an enum.
- **Missing `bundle: .module` in Color("name", bundle: .module):** Without `bundle: .module`, the color lookup fails when the DesignSystem is used as a Swift Package dependency. It only works if the consumer and the assets are in the same bundle.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| {light, dark} token resolution | Custom JavaScript resolver | Explicit resolution algorithm in agent prompt | Agent reads JSON and resolves references in context; a Node script adds complexity with no benefit |
| Tailwind v4 CSS generation | Style Dictionary with custom transforms | Direct CSS file generation by agent | SD requires custom preprocess for the {light, dark} pattern; direct generation is simpler and produces identical output |
| SwiftUI color generation | Color(hex:) Swift extension | Asset catalog (Contents.json) | Asset catalog is the idiomatic pattern, provides automatic OS dark mode switching, required by swiftui-spec.md |
| DTCG reference resolution (e.g. {tokens.color.primitive.blue.500}) | External JSON path library | Inline resolution in agent prompt | References are within one known JSON structure; the agent resolves them by reading the JSON it already holds in context |
| TypeScript types for tokens | Type generation library | Authored types file from known token schema | The token vocabulary is fixed and known at generation time; a static authored file is simpler and requires no build step |

**Key insight:** Phase 4 is a generation phase, not a transformation pipeline phase. The agent's task is to read structured data from `design-system.json` and write well-formed file content. All "infrastructure" problems (reference resolution, dark mode switching, color catalog format) are solved by the agent following explicit rules in its prompt — not by external tools.

---

## Common Pitfalls

### Pitfall 1: Ghost and Outline Button Variants Not in Spec

**What goes wrong:** The Phase 1 `react-tailwind-spec.md` and `swiftui-spec.md` show 3 button variants (primary, secondary, destructive). The CONTEXT.md locks the full set: primary, secondary, destructive, ghost, outline. If the generator prompts embed the spec's Button template verbatim without adding ghost and outline, generated Button components are incomplete.

**Why it happens:** The Phase 1 specs were written before the component depth decision was finalized. The specs are accurate for what they document but don't include the two additional variants.

**How to avoid:** The generator prompts must extend the embedded Button template with ghost and outline. These variants must be authored in the prompt:
- **ghost:** transparent background, no border, text in `text-text` color (React) / `Color.dsTextPrimary` (SwiftUI). Hover: subtle background tint.
- **outline:** transparent background, border in `border-border`, text in `text-text`. Hover: slight fill.

**Warning signs:** Generated `Button.tsx` or `DSButton.swift` has only 3 variants in the enum/object.

### Pitfall 2: Loading State Requires a Spinner — Not Just disabled

**What goes wrong:** "Loading with spinner" state is locked in CONTEXT.md. Generators that implement `isLoading` as just `disabled={true}` fail the requirement. A spinner element must be rendered.

**Why it happens:** Spec examples do not include a loading state. Generators follow the spec's Button template which has no loading state.

**How to avoid:** The generator prompt must include the loading state pattern:

React:
```tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "destructive" | "ghost" | "outline";
  size?: "sm" | "md" | "lg";
  isLoading?: boolean;
}

// In render:
disabled={isLoading || props.disabled}
// In children:
{isLoading ? <span className="animate-spin mr-2 h-4 w-4 rounded-full border-2 border-current border-t-transparent" aria-hidden="true" /> : null}
{children}
```

SwiftUI:
```swift
// In DSButton body:
if isLoading {
    ProgressView()
        .progressViewStyle(CircularProgressViewStyle())
        .scaleEffect(0.8)
        .frame(width: 16, height: 16)
} else {
    Text(title)
}
```

**Warning signs:** Button component has no `isLoading` prop/parameter.

### Pitfall 3: DTCG Reference Resolution Failure

**What goes wrong:** Some `design-system.json` semantic tokens use DTCG reference syntax: `{tokens.color.primitive.blue.500}`. If the generator agent emits these references literally into CSS (e.g., `--ds-color-action-primary: {tokens.color.primitive.blue.500};`), the CSS is invalid.

**Why it happens:** The agent may treat the JSON structure as pass-through data without checking whether values need resolution.

**How to avoid:** Step 2 of the generator prompt must explicitly resolve all DTCG references before any file writing. The resolution algorithm (Pattern 2 above) must be in the prompt with a worked example. Add a self-check: "Before writing tokens.css, verify all `--ds-*` values are hex strings or valid CSS values — no `{tokens.*}` syntax."

**Warning signs:** CSS file contains `{tokens.color.primitive.*}` as variable values.

### Pitfall 4: tokens.css Missing Non-Color Tokens

**What goes wrong:** The tokens.css `$value` for spacing uses DTCG format (`"16px"`). But tokens.css must emit `--ds-spacing-4: 16px;` — the `px` suffix is already in the `$value` string so no conversion is needed, but the generator must still output all spacing steps (1 through 32) not just the semantic ones.

**Also:** font-family in tokens.css must include the `fallback_stack` array, formatted as a comma-separated CSS font-family string: `"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`.

**Why it happens:** Agent focuses on color tokens (the most complex) and shortcuts the typography and spacing sections.

**How to avoid:** The generator prompt must have an explicit section for each token group with the exact CSS variable pattern. Embedding the react-tailwind-spec.md Section 4 (tokens.css spec) verbatim in the prompt is the primary defense.

**Warning signs:** Generated tokens.css is missing `--ds-spacing-*`, `--ds-font-*`, `--ds-radius-*`, or `--ds-shadow-*` sections.

### Pitfall 5: .colorset Directory Names Must Match Color() String Literals

**What goes wrong:** The SwiftUI generator writes `Colors+DesignSystem.swift` with `Color("dsActionPrimary", bundle: .module)` but names the colorset directory `ds-action-primary.colorset` (kebab-case). Xcode cannot find the color.

**Why it happens:** Generator uses different casing conventions for different output targets.

**How to avoid:** The generator prompt must state explicitly: "The colorset directory name must exactly match the string literal in `Color(\"name\", bundle: .module)`. Both use camelCase: `dsActionPrimary.colorset` corresponds to `Color(\"dsActionPrimary\", bundle: .module)`." Include a concordance table in the prompt.

**Warning signs:** Xcode shows blank/clear colors despite colorset files existing.

### Pitfall 6: Overwrite with Backup Is an OS-Level File Operation

**What goes wrong:** The CONTEXT.md locks "overwrite with backup: regeneration overwrites existing files but saves previous version as `.bak`". This requires checking if a file exists before writing it. The Claude Code Write tool overwrites without checking. A backup step requires: Read existing content → Write to `.bak` path → Write new content.

**Why it happens:** The generator agent follows the Write tool without implementing backup logic.

**How to avoid:** The generator prompt must include an explicit backup step:
```
For each output file:
  1. Attempt Read at output_path
  2. If Read succeeds (file exists): Write current content to output_path + ".bak"
  3. Write new content to output_path
  4. If Read fails (file doesn't exist): Write new content to output_path (no backup needed)
```

This adds N additional Write calls (where N = number of output files). For Phase 4's output (~12 React files + ~20 SwiftUI files), this is ~32 extra operations. Document this in the agent.

**Warning signs:** Previous file content is overwritten without backup; no `.bak` files exist after re-generation.

### Pitfall 7: SwiftUI @Preview Macro Requires Xcode 15+ Despite iOS 16 Target

**What goes wrong:** `#Preview { ... }` is an Xcode 15+ macro feature. It compiles successfully against an iOS 16 deployment target (the macro is a build tool, not a runtime API), but engineers using Xcode 14 cannot build the generated files. The spec documents this; the generator must include the comment.

**How to avoid:** The generator prompt must produce `#Preview` blocks exactly as shown in swiftui-spec.md. Add a comment header: `// #Preview requires Xcode 15 or later. Remove if using an older Xcode version.`

**Warning signs:** No comment on `#Preview` usage; users on Xcode 14 report build failures.

### Pitfall 8: font_family.mono null When Design System Has No Mono Font

**What goes wrong:** The Luxora `design-system.json` has `font_family.mono = null`. The generator must handle null font roles gracefully — emit a fallback system font rather than crashing on null.

**How to avoid:** Generator prompt must include null-handling for all font roles:
- `font_family.mono = null` → `--ds-font-family-mono: ui-monospace, "Cascadia Code", monospace;`
- `font_family.display = null` → `--ds-font-family-display: var(--ds-font-family-sans);` (inherit from sans)

Same for SwiftUI: if `font_family.mono = null`, `DSFont.code()` returns `.system(size: 14, design: .monospaced)`.

**Warning signs:** CSS contains `--ds-font-family-mono: null;` or Swift contains `nil` as font value.

---

## Code Examples

Verified patterns from Phase 1 specs and confirmed against existing project artifacts:

### tokens.css — Dark Mode Dual Strategy

```css
/* tokens.css — generated by dsys */
/* Do not edit manually — re-run dsys to regenerate */

:root {
  /* Colors: Action */
  --ds-color-action-primary:     #1F3A1F;   /* resolved from design-system.json */
  --ds-color-action-secondary:   #E8EDE8;
  --ds-color-action-destructive: #EF4444;

  /* Colors: Surface */
  --ds-color-surface-default:    #F7F9F4;
  --ds-color-surface-raised:     #FFFFFF;
  --ds-color-surface-overlay:    #FFFFFF;
  --ds-color-surface-inset:      #F0F4F0;

  /* ... all other semantic color groups ... */

  /* Typography */
  --ds-font-family-sans:         "Satoshi", -apple-system, BlinkMacSystemFont, "Segoe UI", "Helvetica Neue", sans-serif;
  --ds-font-family-mono:         ui-monospace, "Cascadia Code", monospace;  /* null → fallback */
  --ds-font-family-display:      var(--ds-font-family-sans);                /* null → inherit */

  --ds-font-size-xs:   0.75rem;
  --ds-font-size-sm:   0.8125rem;
  --ds-font-size-base: 0.875rem;   /* 14px base scale — from Luxora design-system.json */
  /* ... */

  /* Spacing */
  --ds-spacing-1:   4px;
  --ds-spacing-2:   8px;
  /* ... all 13 steps ... */

  /* Radius */
  --ds-radius-sm:   8px;
  --ds-radius-md:   16px;
  --ds-radius-lg:   24px;
  --ds-radius-full: 9999px;

  /* Shadows */
  --ds-shadow-sm:  0 2px 8px 0 rgba(0, 0, 0, 0.06);
}

/* Dark mode: OS-level automatic */
@media (prefers-color-scheme: dark) {
  :root {
    --ds-color-action-primary:  #4ADE80;
    /* ... dark values for all semantic color tokens ... */
  }
}

/* Dark mode: manual class-based */
.dark {
  --ds-color-action-primary:  #4ADE80;
  /* ... same dark values ... */
}
```

### theme.css — Tailwind v4 with dual dark mode support

```css
/* theme.css — generated by dsys */
/* Do not edit manually — re-run dsys to regenerate */

@import "tailwindcss";

/* Enable class-based dark mode (.dark) in addition to prefers-color-scheme */
@custom-variant dark (&:where(.dark, .dark *));

@theme {
  /* REQUIRED: Reset all Tailwind default colors */
  --color-*: initial;

  /* Semantic colors — reference CSS vars, not hex */
  --color-primary:         var(--ds-color-action-primary);
  --color-primary-hover:   color-mix(in srgb, var(--ds-color-action-primary) 90%, black);
  --color-secondary:       var(--ds-color-action-secondary);
  --color-destructive:     var(--ds-color-action-destructive);

  --color-surface:         var(--ds-color-surface-default);
  --color-surface-raised:  var(--ds-color-surface-raised);
  --color-surface-overlay: var(--ds-color-surface-overlay);
  --color-surface-inset:   var(--ds-color-surface-inset);

  --color-text:            var(--ds-color-text-primary);
  --color-text-secondary:  var(--ds-color-text-secondary);
  --color-text-muted:      var(--ds-color-text-muted);
  --color-inverse:         var(--ds-color-text-inverse);
  --color-link:            var(--ds-color-text-link);

  --color-border:          var(--ds-color-border-default);
  --color-focus:           var(--ds-color-border-focus);

  --color-success:         var(--ds-color-feedback-success);
  --color-error:           var(--ds-color-feedback-error);
  --color-warning:         var(--ds-color-feedback-warning);
  --color-info:            var(--ds-color-feedback-info);

  /* Typography */
  --font-sans:    var(--ds-font-family-sans);
  --font-mono:    var(--ds-font-family-mono);
  --font-display: var(--ds-font-family-display);

  --text-xs:   var(--ds-font-size-xs);
  --text-sm:   var(--ds-font-size-sm);
  --text-base: var(--ds-font-size-base);
  --text-lg:   var(--ds-font-size-lg);
  --text-xl:   var(--ds-font-size-xl);
  --text-2xl:  var(--ds-font-size-2xl);
  --text-3xl:  var(--ds-font-size-3xl);
  --text-4xl:  var(--ds-font-size-4xl);

  /* Spacing */
  --spacing: 4px;

  /* Radius */
  --radius-sm:   var(--ds-radius-sm);
  --radius-md:   var(--ds-radius-md);
  --radius-lg:   var(--ds-radius-lg);
  --radius-full: var(--ds-radius-full);

  /* Shadows */
  --shadow-sm:  var(--ds-shadow-sm);
}
```

### Button.tsx — Full 5-variant, 3-size, with loading state

```tsx
// Button.tsx — generated by dsys
// Do not edit manually — re-run dsys to regenerate

import { forwardRef } from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "destructive" | "ghost" | "outline";
  size?: "sm" | "md" | "lg";
  isLoading?: boolean;
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", size = "md", isLoading = false, className, children, ...props }, ref) => {
    const variants = {
      primary:     "bg-primary text-inverse hover:bg-primary/90 focus-visible:outline-focus",
      secondary:   "bg-surface-raised text-text border border-border hover:bg-surface-inset focus-visible:outline-focus",
      destructive: "bg-destructive text-inverse hover:bg-destructive/90 focus-visible:outline-focus",
      ghost:       "bg-transparent text-text hover:bg-surface-inset focus-visible:outline-focus",
      outline:     "bg-transparent text-text border border-border hover:bg-surface-inset focus-visible:outline-focus",
    };
    const sizes = {
      sm: "px-3 py-1.5 text-sm rounded-sm",
      md: "px-4 py-2 text-base rounded-md",
      lg: "px-6 py-3 text-lg rounded-lg",
    };
    return (
      <button
        ref={ref}
        disabled={isLoading || props.disabled}
        className={`inline-flex items-center justify-center gap-2 font-medium transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:pointer-events-none disabled:opacity-50 ${variants[variant]} ${sizes[size]} ${className ?? ""}`}
        aria-busy={isLoading}
        {...props}
      >
        {isLoading && (
          <span
            className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
            aria-hidden="true"
          />
        )}
        {children}
      </button>
    );
  }
);
Button.displayName = "Button";
export default Button;
```

### DSButton.swift — Full 5-variant with loading state

```swift
// DSButton.swift — generated by dsys

import SwiftUI

public struct DSButton: View {
    public enum Variant { case primary, secondary, destructive, ghost, outline }
    public enum Size { case sm, md, lg }

    let title: String
    let variant: Variant
    let size: Size
    let isLoading: Bool
    let action: () -> Void

    public init(
        _ title: String,
        variant: Variant = .primary,
        size: Size = .md,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    private var spacing = DSSpacing()

    public var body: some View {
        Button(action: isLoading ? {} : action) {
            HStack(spacing: DSSpacingFixed.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.75)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(foregroundColor)
                } else {
                    Text(title)
                        .font(labelFont)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(borderOverlay)
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .outline:
            RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.dsBorderDefault, lineWidth: 1)
        default:
            EmptyView()
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:     return .dsTextInverse
        case .secondary:   return .dsTextPrimary
        case .destructive: return .dsTextInverse
        case .ghost:       return .dsTextPrimary
        case .outline:     return .dsTextPrimary
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:     return .dsActionPrimary
        case .secondary:   return .dsSurfaceRaised
        case .destructive: return .dsActionDestructive
        case .ghost:       return .clear
        case .outline:     return .clear
        }
    }

    // ... labelFont, horizontalPadding, verticalPadding, cornerRadius computed properties
}
```

### index.ts — Barrel file for React output

```typescript
// index.ts — generated by dsys
// Do not edit manually — re-run dsys to regenerate

// Tokens
export { default as tokens } from "./tokens/tokens.json";

// Components
export { default as Button } from "./components/Button";
export type { ButtonProps } from "./components/Button";
export { default as Card } from "./components/Card";
export type { CardProps } from "./components/Card";
export { default as Input } from "./components/Input";
export type { InputProps } from "./components/Input";
export { default as Badge } from "./components/Badge";
export type { BadgeProps } from "./components/Badge";
export { default as Heading } from "./components/Heading";
export type { HeadingProps } from "./components/Heading";
export { default as Text } from "./components/Text";
export type { TextProps } from "./components/Text";

// Types
export type { DSColorToken, DSSpacingStep, DSRadiusStep, DSFontSize } from "./types/design-tokens";
```

### DesignSystem.swift — Barrel re-export for SwiftUI

```swift
// DesignSystem.swift — generated by dsys
// Do not edit manually — re-run dsys to regenerate

// Re-export all design system tokens and components
@_exported import struct Foundation.Bundle

// Token extensions (Colors+DesignSystem, Typography+DesignSystem, etc. are in the same module)
// Components (DSButton, DSCard, DSInput, DSBadge, DSHeading, DSText are in the same module)

// Public type aliases for discoverability
public typealias DesignSystemColors = Color
// Usage: Color.dsActionPrimary, Color.dsSurfaceDefault, etc.

public typealias DesignSystemFont = DSFont
// Usage: DSFont.body(), DSFont.heading1(), etc.

public typealias DesignSystemSpacing = DSSpacing
// Usage: var spacing = DSSpacing(); spacing.md
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `tailwind.config.js` for theme | `@theme { }` block in CSS | Tailwind v4 (2025) | Generator writes CSS, not JS config |
| `darkMode: 'class'` config option | `@custom-variant dark` in CSS | Tailwind v4 (2025) | Explicit CSS override, more composable |
| Style Dictionary for all platforms | Direct generation for SwiftUI | Project architecture decision (Phase 0) | No custom transforms needed; simpler pipeline |
| Separate light/dark token files | `{light, dark}` object in single file | DTCG spec + project decision | Generator resolves references at write time |
| `Color(red:green:blue:)` in SwiftUI | `Color("name", bundle: .module)` | iOS 14+ / SwiftUI idiomatic pattern | OS-managed dark mode without code |

**Deprecated/outdated:**
- `tailwind.config.js`: Not used in Tailwind v4 CSS-first configuration
- `Color(hex:)` Swift extension: Not generated; asset catalog is the correct approach
- `@import "tailwindcss/base"` etc.: Replaced by single `@import "tailwindcss"` in v4
- Hardcoded numeric `@theme { --spacing-4: 16px; }`: v4 uses `--spacing: 4px;` single variable that generates all scale steps

---

## Open Questions

1. **CONTEXT.md output paths vs. spec output paths**
   - What we know: CONTEXT.md says `src/design-system/` (React) and `Sources/DesignSystem/` (SwiftUI). Phase 1 specs say `./design-system/` and `./DesignSystem/`.
   - What's unclear: Whether the generator should hardcode these paths or accept them as parameters.
   - Recommendation: Accept `output_root` as a parameter with the CONTEXT.md paths as defaults. This is consistent with the analyzer and synthesizer pattern of caller-specified paths. Document the defaults clearly in the agent's Input section.

2. **Style Dictionary v5 `{light, dark}` $value handling**
   - What we know: The `{light, dark}` object pattern in design-system.json is NOT a standard DTCG composite type. Style Dictionary v5's `expand` feature handles DTCG composite types (border, typography, shadow, gradient) but NOT theme-mode objects. A custom preprocessor would be required for SD to handle this.
   - What's unclear: Whether users will want to run SD against the generated tokens.json as-is (they cannot without a custom config).
   - Recommendation: The generator writes tokens.json as a reference/documentation artifact. Include a comment in tokens.json header: "This file uses a non-standard {light, dark} $value pattern for theme-aware tokens. Running Style Dictionary against it requires a custom preprocessor to expand mode-aware values." Do not attempt to generate a Style Dictionary config — that is out of scope. The generator's CSS files are the authoritative platform output.
   - Status: LOW confidence on exact SD v5 behavior; verified from official docs that `expand` targets DTCG composites, not theme modes.

3. **`color-mix` support for hover states in theme.css**
   - What we know: `color-mix(in srgb, var(--ds-color-action-primary) 90%, black)` is used in theme.css for `--color-primary-hover`. `color-mix` is a CSS4 function supported in all modern browsers (Chrome 111+, Firefox 113+, Safari 16.2+).
   - What's unclear: Whether the project's intended browser support targets include these versions.
   - Recommendation: Include `color-mix` for hover states — the support level is adequate for any project using Tailwind v4 (which also requires modern browsers). Document the minimum browser requirement in the generated files.

4. **TypeScript `ButtonProps` export — forwardRef + interface separation**
   - What we know: The index.ts barrel file exports `ButtonProps` as a named type. The Component file must declare `interface ButtonProps` as `export interface ButtonProps`.
   - What's unclear: The Phase 1 spec's Button.tsx does not export the interface. The generator must add `export` to all prop interfaces.
   - Recommendation: The generator prompt must specify that all `interface XProps` declarations are exported (so barrel file can re-export them). This is a small but critical detail for the types to flow through correctly.

---

## Sources

### Primary (HIGH confidence)
- `/Users/james/Code/dsys-tool/skills/dsys/references/platform-specs/react-tailwind-spec.md` — Complete React output specification with file manifest, token.css/theme.css formats, all 6 component templates, naming conventions, done checklist
- `/Users/james/Code/dsys-tool/skills/dsys/references/platform-specs/swiftui-spec.md` — Complete SwiftUI output specification with file manifest, Swift extensions, asset catalog format, all 6 DS-prefixed component templates
- `/Users/james/Code/dsys-tool/.dsys/design-system.json` — Real Phase 3 output (Luxora design system); confirmed valid against schema; used as generator input for validation
- `/Users/james/Code/dsys-tool/skills/dsys/references/token-schema.md` — Full specification of design-system.json fields; defines all input token structures the generator reads
- `/Users/james/Code/dsys-tool/.planning/phases/03-synthesizer-agent/03-VERIFICATION.md` — Confirmed Phase 3 complete; design-system.json valid and ready for generator consumption
- https://tailwindcss.com/docs/dark-mode — Tailwind v4 dark mode configuration; confirmed `@custom-variant dark` syntax for class-based dark mode

### Secondary (MEDIUM confidence)
- https://styledictionary.com/reference/config/ — Style Dictionary v5 expand config; confirmed `expand` handles DTCG composite types but NOT the `{light, dark}` theme-mode pattern; direct generation is the correct approach
- https://styledictionary.com/reference/hooks/preprocessors/ — Style Dictionary v5 preprocessors; confirmed custom preprocessor would be needed for theme-mode expansion; not required for Phase 4 scope

### Tertiary (LOW confidence)
- Style Dictionary v5 `{light, dark}` exact behavior: LOW confidence. Official docs confirm it's not natively handled by `expand`, but the exact error or fallback behavior when running SD against the generated tokens.json is unverified. This is a user-facing concern (they may want to run SD), not a generator correctness concern.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — same agent-prompt architecture as Phases 2 and 3; no new dependencies; all output patterns defined in Phase 1 specs
- Architecture: HIGH — Phase 1 specs are complete, detailed, and accurate; generator anatomy follows established pattern; output structure is locked
- Component templates: HIGH — Phase 1 specs provide complete working examples for all 6 components; CONTEXT.md additions (ghost/outline variants, loading state) are well-understood patterns
- Dark mode dual strategy: HIGH — verified from official Tailwind v4 docs; `@custom-variant dark` + CSS vars is the correct approach
- Pitfalls: HIGH — most pitfalls are detected by comparing CONTEXT.md decisions against Phase 1 spec content; verified against existing design-system.json for concrete examples
- Style Dictionary integration: LOW — unverified edge cases; scope is limited (tokens.json is an optional artifact for users who want SD)

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (30 days; Tailwind v4 and SwiftUI patterns are stable; Phase 1 specs will not change)

---

## Planning Guidance

### What Phase 4 Actually Produces

Two files:
1. `skills/dsys/agents/react-generator.md` — Agent prompt that reads design-system.json and writes React/Tailwind files
2. `skills/dsys/agents/swiftui-generator.md` — Agent prompt that reads design-system.json and writes SwiftUI files

Each generator, when invoked, produces a complete platform-specific output tree. The generators are invoked independently (or together for "both" platform selection).

### Critical Decisions for the Planner

**1. Plan structure — 3 tasks, 2 agents**

Recommended plan structure:
- **Task 1:** Write `react-generator.md` agent prompt
- **Task 2:** Validate React generator by invoking it against `.dsys/design-system.json` (produces `src/design-system/`)
- **Task 3:** Write `swiftui-generator.md` agent prompt
- **Task 4:** Validate SwiftUI generator by invoking it against `.dsys/design-system.json` (produces `Sources/DesignSystem/`)

Or optionally split into two plans (Plan 01: React, Plan 02: SwiftUI) following the Phase 3 pattern.

**2. Output root is parameterized, not hardcoded**

Both generators must accept `output_root` as a parameter. The prompts must document the defaults (`src/design-system/` and `Sources/DesignSystem/`). Do not hardcode.

**3. Component templates must be in the agent prompts, not just referenced**

The Phase 3 synthesizer embedded the fill-in template verbatim. The generators must embed the complete component templates verbatim with the additions (ghost/outline variants, loading state). External references fail at agent runtime.

**4. E2E validation uses the existing design-system.json**

`.dsys/design-system.json` (Luxora forest-green system) is ready for use. The generator validation task invokes the generator agent against this file and verifies:
- All required files are produced
- CSS files are syntactically valid
- Swift files compile (mental verification — no Xcode in this environment)
- Component files use no raw hex values
- Backup behavior works

**5. CONTEXT.md additions not in Phase 1 specs**

The planner must ensure these additions are authored in the generator prompts:
- Button: `ghost` and `outline` variants (missing from spec)
- Button: `isLoading` with spinner render (missing from spec)
- Input: Size variants sm/md/lg (check spec — spec shows size-less Input; CONTEXT.md says Button and Input get sizes)
- All components: `disabled` state with `opacity-50` (spec shows this for Button; verify other components)
- All components: `focus-visible` state (spec shows on Button; verify Card/Input/Badge)

**6. Verification gates**

For React generation:
- All 9 files in react-tailwind-spec.md manifest are present (CONTEXT.md adds index.ts and types/design-tokens.d.ts = 11 files total)
- `theme.css` starts with `@import "tailwindcss"` and has `--color-*: initial;` as first @theme declaration
- No component file contains a raw hex value or Tailwind default color name
- `tokens.css` has `:root`, `@media (prefers-color-scheme: dark) { :root }`, and `.dark` blocks

For SwiftUI generation:
- All 12 entries in swiftui-spec.md manifest are present
- Each `Color.dsX` property matches a `.colorset` directory name exactly
- `@ScaledMetric` used as instance properties (not static) in DSSpacing
- All components include a `#Preview` block
- No component uses `Color.blue`, `Color.red`, or any system color
