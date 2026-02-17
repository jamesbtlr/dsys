# Phase 1: Schema Contracts - Research

**Researched:** 2026-02-17
**Domain:** JSON schema design, W3C DTCG token format, Style Dictionary v5, theme-aware token architecture
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Token taxonomy
- Full visual system extraction: colors, typography, spacing, shadows, border radii, opacity, and effects
- Not limited to core essentials — capture everything that makes a UI feel polished
- Schema must be universal: handle SaaS dashboards, consumer apps, marketing sites equally

#### Color naming strategy
- Semantic role naming: tokens named by purpose (primary, secondary, destructive, surface, muted, accent, etc.)
- Not appearance-based (no blue-500, gray-100 naming)
- Analysis agent must infer design intent from visual context, not just sample pixel values

#### Input flexibility
- Variable number of input images per run (1 to many)
- Inputs may include non-UI images: mood photos, brand assets, style references, visual inspiration
- Schema must distinguish between "extracted from UI screenshot" and "inspired by visual reference"
- Analysis findings schema needs an image-type classification (UI screen vs visual reference)

#### Non-UI image handling
- Non-UI images produce: dominant color palette + aesthetic vibe description
- Vibe description captures mood/feel: warm, minimal, bold, playful, corporate, etc.
- These findings feed into the synthesizer to influence the overall design system's aesthetic identity

#### Theming
- Light/dark mode support built into the schema from the start
- Tokens have theme-aware values (a color token can resolve differently per theme)
- Schema structure must accommodate theme variants without duplication of the entire token set

### Claude's Discretion

- Quantization rules: how raw values snap to standard scales (4px grid, type scales, etc.)
- Schema strictness: required vs optional fields, how to represent "not found"
- design-system.json internal structure: nesting, grouping, relationships between tokens
- Platform output specifications: what files each generator must produce, naming conventions
- Extraction rubric detail level: how prescriptive the rubric is about what to look for

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ORCH-04 | All agents share a strict JSON schema contract for input/output | JSON Schema 2020-12 as the validation standard; analysis findings schema + design-system.json schema as the two primary contracts; schema templates embedded in agent prompts as fill-in templates rather than prose descriptions to guarantee structural conformance |
</phase_requirements>

---

## Summary

Phase 1 is a pure writing task — no executable code, no libraries to install. Its sole output is a set of stable schema and rubric documents that every downstream agent will depend on. The prior project research has already established the architecture and stack clearly; what this phase needs is precise knowledge of the token format specifications, naming conventions, theming patterns, and platform output contracts to actually write those documents correctly.

The W3C Design Tokens Community Group (DTCG) format is the correct canonical token format. It uses `$value`, `$type`, and `$description` as the reserved field names for tokens, with arbitrary nesting for grouping. Style Dictionary v5 (currently at 5.3.1, not 4.x as prior research assumed) has first-class DTCG support and will be invoked via `npx` for CSS/JS transformation. The tool is **not** used during Phase 1 — it is the target that Phase 1's schemas must be compatible with.

Theme-aware tokens (light/dark mode) are best expressed using a two-layer token architecture: primitive tokens hold raw values (never used directly in components), and semantic tokens hold references to primitives with per-theme resolution. The `design-system.json` must represent both layers and carry theme-variant values without duplicating the entire token set. The cleanest pattern — verified from both the DTCG spec and Style Dictionary practice — is a `$value` object with `light` and `dark` keys for any color token that needs to vary by theme.

**Primary recommendation:** Write schema documents as both human-readable Markdown specifications and machine-readable JSON Schema 2020-12 files. Agent prompts embed the JSON template directly as a fill-in form (not a description), which is the single most important pitfall-prevention measure from prior research.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| JSON Schema 2020-12 | N/A (spec) | Validation schema for agent output contracts | Industry standard; DTCG spec itself references it; supported by all major validators |
| W3C DTCG format | 2025.10 (first stable) | Canonical token file format (`$value`, `$type`) | Cross-tool standard; Style Dictionary v5 auto-detects it; future-proof |
| Style Dictionary | 5.3.1 (latest) | Token transformation pipeline for CSS/JS outputs | Only dependency; invoked via `npx`; native DTCG support |

**Critical correction from prior research:** Style Dictionary is at **v5.3.1**, not v4.x. Prior research documented v4. The schemas in Phase 1 must be compatible with v5's DTCG handling and its requirement that Node.js >= 22.0.0 is installed.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ajv | 8.x | JSON Schema validation (if adding a validation step) | Only relevant if the orchestrator adds a Node.js-based validation step between agents; not required for Phase 1 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| W3C DTCG format | Custom JSON schema | DTCG is the industry-converging standard; custom format means reimplementing all the toolchain integration that Style Dictionary and other tools already provide |
| JSON Schema 2020-12 | TypeScript types | TS types cannot be embedded in Markdown prompts and are harder to use as agent fill-in templates; JSON Schema is language-agnostic and embeddable |
| Two-layer primitive + semantic | Single-layer with all values inline | Single-layer cannot support theming (light/dark), aliasing, or semantic abstraction; two-layer is the industry standard for any non-trivial system |

---

## Architecture Patterns

### Recommended Document Structure

```
skills/dsys/
├── references/
│   ├── analysis-rubric.md           # Extraction rubric for analyzer agent
│   ├── token-schema.md              # design-system.json human-readable spec
│   ├── analysis-findings-schema.md  # analyzer output schema (human-readable)
│   └── platform-specs/
│       ├── react-tailwind-spec.md   # React/Tailwind output file manifest
│       └── swiftui-spec.md          # SwiftUI output file manifest
└── schemas/
    ├── analysis-findings.schema.json   # JSON Schema 2020-12 for analyzer output
    └── design-system.schema.json       # JSON Schema 2020-12 for design-system.json
```

The `references/` documents are loaded into agent prompts as prose context. The `schemas/` files are the machine-readable contracts embedded as fill-in templates in agent prompts.

### Pattern 1: Two-Layer Token Architecture

**What:** Primitive tokens define raw values. Semantic tokens reference primitives using `{group.token}` syntax. Components consume only semantic tokens. Every token has a `$description` explaining its intended use.

**When to use:** Always, for every token category. This is the only structure that supports theming, aliasing, and semantic abstraction simultaneously.

**Example (DTCG format):**
```json
{
  "primitive": {
    "color": {
      "blue": {
        "500": { "$value": "#3B82F6", "$type": "color" },
        "700": { "$value": "#1D4ED8", "$type": "color" }
      },
      "gray": {
        "50":  { "$value": "#F9FAFB", "$type": "color" },
        "900": { "$value": "#111827", "$type": "color" }
      }
    }
  },
  "semantic": {
    "color": {
      "action": {
        "primary": {
          "$value": {
            "light": "{primitive.color.blue.500}",
            "dark":  "{primitive.color.blue.700}"
          },
          "$type": "color",
          "$description": "Primary interactive elements: buttons, links, selected states"
        }
      },
      "surface": {
        "default": {
          "$value": {
            "light": "{primitive.color.gray.50}",
            "dark":  "{primitive.color.gray.900}"
          },
          "$type": "color",
          "$description": "Default page background surface"
        }
      }
    }
  }
}
```

Source: W3C DTCG spec (reference syntax) + Style Dictionary v5 theming patterns (verified via StyleDictionary docs and community examples)

### Pattern 2: Theme-Aware Token Values

**What:** A semantic color token's `$value` is an object with `light` and `dark` keys rather than a single hex string. This is the recommended approach from both the DTCG spec and Style Dictionary community practice. It avoids duplicating the entire token set into separate light/dark files.

**When to use:** For all color tokens in the semantic layer that need to vary between themes. Non-color tokens (spacing, radius, type sizes) typically do not need theme variants and can use a flat `$value` string.

**Example:**
```json
"text": {
  "primary": {
    "$value": { "light": "{primitive.color.gray.900}", "dark": "{primitive.color.gray.50}" },
    "$type": "color",
    "$description": "Primary body text. Use for headings and paragraph copy."
  },
  "muted": {
    "$value": { "light": "{primitive.color.gray.500}", "dark": "{primitive.color.gray.400}" },
    "$type": "color",
    "$description": "Secondary/subdued text. Labels, captions, supporting copy."
  }
}
```

### Pattern 3: Analysis Findings Schema as Fill-In Template

**What:** The analyzer agent prompt includes the exact JSON structure it must fill in, with placeholder values and inline comments explaining each field. The agent fills values into the template rather than designing the structure itself.

**When to use:** Always for agent-to-agent contracts. This is the single most important pitfall-prevention measure (Pitfall 7 from prior research: parallel agents producing incompatible schemas).

**Example (what the agent prompt contains):**
```json
{
  "image_type": "ui_screenshot | visual_reference",
  "source_path": "path/to/image.png",
  "confidence": "high | medium | low",
  "colors": {
    "primitive_palette": [
      { "hex": "#RRGGBB", "role": "dominant | accent | surface | neutral" }
    ],
    "semantic_assignments": {
      "action_primary": "#RRGGBB",
      "action_primary_dark": "#RRGGBB",
      "surface_default": "#RRGGBB",
      "surface_default_dark": "#RRGGBB",
      "text_primary": "#RRGGBB",
      "text_muted": "#RRGGBB",
      "border_default": "#RRGGBB",
      "feedback_success": "#RRGGBB",
      "feedback_error": "#RRGGBB",
      "feedback_warning": "#RRGGBB"
    }
  },
  "typography": { ... },
  "spacing": { ... },
  "aesthetic": { ... }
}
```

### Pattern 4: Semantic Token Naming Convention

**What:** Tokens follow `{category}-{role}-{modifier}` with dot notation in the JSON hierarchy. The name describes what the token does, not what it looks like.

**The locked decision is semantic naming.** The specific taxonomy recommended here is the Claude's Discretion area:

```
color.action.primary           — primary interactive elements
color.action.secondary         — secondary/ghost interactive elements
color.action.destructive       — danger actions (delete, remove)
color.surface.default          — page background
color.surface.raised           — card/elevated surface (above default)
color.surface.overlay          — modal/drawer overlay background
color.surface.inset            — input/recessed surfaces (below default)
color.text.primary             — primary body and heading text
color.text.secondary           — secondary/supporting text
color.text.muted               — disabled, placeholder, caption text
color.text.inverse             — text on colored backgrounds (e.g. button labels)
color.text.link                — hyperlinks
color.border.default           — standard borders and dividers
color.border.focus             — focus ring color
color.feedback.success         — success states
color.feedback.error           — error/destructive states
color.feedback.warning         — warning states
color.feedback.info            — informational states
```

This taxonomy covers all token roles needed for SaaS dashboards, consumer apps, and marketing sites equally (the locked universality requirement).

### Anti-Patterns to Avoid

- **Appearance-based names:** Never `blue-500`, `gray-100`, `red`. The locked decision prohibits this. Every semantic token must communicate purpose, not appearance.
- **Single-layer tokens:** Never put hex values directly in semantic tokens. Always reference a primitive. This is what enables theming.
- **Optional-everything schemas:** Every field the synthesizer or generator depends on must be required in the agent output schema. "Not found" must be represented as an explicit value (e.g., `null`) not an absent field — absent fields produce inconsistent behavior in downstream agents.
- **Prose schema descriptions in prompts:** Never describe the output schema in prose. Always embed the actual JSON template with placeholders.
- **Merging `theme.extend` in Tailwind output:** The Tailwind v4 `@theme` spec must use `--color-*: initial;` to reset defaults before defining the design system palette. Without this, the full Tailwind default palette coexists with the custom tokens, removing enforcement.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token format transformation (JSON → CSS → Swift) | Custom templating code | Style Dictionary v5 via `npx` | Handles aliasing, math transforms, composite type expansion, color format conversions; years of edge cases baked in |
| JSON Schema validation | Custom validation logic | Ajv 8.x (if needed) or rely on Claude's structured output adherence | Schema validation is well-solved; custom validators introduce bugs at the format boundary |
| Token naming taxonomy | Inventing a new naming system | The `{category}.{role}.{modifier}` taxonomy documented above | Established industry pattern; matches how Primer, Polaris, Material Design all work |

**Key insight:** Phase 1 is a documentation phase. The only thing to "build" is a set of well-designed JSON and Markdown files. The risk is not under-engineering but under-specifying: schemas that are too loose will cause every downstream agent to drift.

---

## Common Pitfalls

### Pitfall 1: Schema That Cannot Represent "Not Found"

**What goes wrong:** A benchmark screenshot has no visible shadow. The analysis schema doesn't have a way to express "shadows are absent." The analyzer agent omits the `shadows` field entirely. The synthesizer receives an object with no `shadows` key and either throws or silently skips it.

**Why it happens:** Schema designers assume all fields will be present. Real-world inputs are incomplete.

**How to avoid:** Every required field must have an explicit "not found" representation. Recommended: use `null` for absent values. The JSON Schema should use `"type": ["array", "null"]` or `"type": ["string", "null"]` for fields that might not be found, with a required constraint so the field must always be present (even if `null`).

**Warning signs:** Any field in the schema spec described as "optional" without a defined null representation.

### Pitfall 2: Theming Added as an Afterthought

**What goes wrong:** The schema is designed for flat single-value tokens. Light/dark mode is added later as a separate set of tokens or a parallel file. The result is schema duplication and generators that need two separate passes.

**Why it happens:** It's easier to design flat schemas; theming feels like a special case.

**How to avoid:** The locked decision requires theming built in from the start. Every `$value` field for semantic color tokens must be defined as either a string (for non-themed tokens) or an object with `{ "light": "...", "dark": "..." }` keys. The JSON Schema must use `oneOf` to allow either form.

**Warning signs:** A separate `design-system-dark.json` file in the output spec; color token `$value` fields defined as only `"type": "string"` in the schema.

### Pitfall 3: Non-UI Image Findings Mixed With UI Screenshot Findings

**What goes wrong:** The synthesizer receives analysis findings from both a UI screenshot and a mood board photo. The synthesizer tries to extract typography tokens from the mood board (which has none), and the token values from the mood board's color analysis contaminate the semantic token assignments.

**Why it happens:** The locked decision requires distinguishing image types, but if the schema doesn't enforce this at the field level, agents can ignore the distinction.

**How to avoid:** The analysis findings schema must have `image_type` as a required enum field (`"ui_screenshot" | "visual_reference"`). The schema must specify that `visual_reference` inputs produce only `dominant_palette` and `aesthetic_vibe` fields, and the typography/spacing/component-density fields must be `null` for visual references. The JSON Schema `if/then` keyword enforces this.

**Warning signs:** The analysis findings schema has the same required fields regardless of `image_type`.

### Pitfall 4: Platform Specs That Underspecify the "Done" Condition

**What goes wrong:** The platform output spec says "generate SwiftUI color tokens." The generator produces a `Colors.swift` file with raw hex initializers. This is technically correct but violates the requirement for asset catalog integration and `@ScaledMetric` spacing. The generator had no way to know because the spec didn't specify.

**Why it happens:** Platform specs written at a high level feel complete but leave too much to interpretation.

**How to avoid:** Platform specs must be file-manifest specs: they list exactly which files to produce, what goes in each file, what naming conventions to follow, what minimum iOS target to assume (iOS 16), what APIs are required (`Color(named:)` not `Color(hex:)`), and what a "done" file looks like with an example.

**Warning signs:** Platform spec uses adjectives like "idiomatic" or "production-ready" without defining what that means operationally.

### Pitfall 5: Quantization Rules Undefined in the Rubric

**What goes wrong:** The extraction rubric says "extract the spacing scale." The analyzer agent extracts values like 13px, 17px, 22px because those are the pixel measurements it observes in the screenshot. The synthesizer receives non-standard values that don't snap to a 4px grid. Every downstream generator produces spacing that looks slightly wrong.

**Why it happens:** Quantization rules are a Claude's Discretion item — they feel like implementation details but are actually schema-critical.

**How to avoid:** The extraction rubric must define explicit quantization rules. Recommended:
- **Spacing:** Snap all observed spacing to the nearest 4px grid value. Values < 2px → 0px (ignore). Values 2-6px → 4px. Values 7-10px → 8px. Values 11-14px → 12px. Values 15-18px → 16px. Etc.
- **Type sizes:** Snap to the standard type scale: 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 24, 28, 32, 36, 40, 48, 56, 64, 72, 80, 96. Use nearest value.
- **Border radius:** Snap to: 0, 2, 4, 6, 8, 12, 16, 24, 32, 9999 (full).
- **Shadows:** Define as `{ offsetX, offsetY, blur, spread, color, opacity }` tuples. No quantization — preserve as extracted.

---

## Code Examples

Verified patterns from official sources:

### DTCG Token File Structure (W3C DTCG Spec + Style Dictionary v5)

```json
{
  "$schema": "https://json.schemastore.org/base.json",
  "primitive": {
    "color": {
      "$type": "color",
      "blue": {
        "500": { "$value": "#3B82F6", "$description": "Base blue 500" },
        "700": { "$value": "#1D4ED8", "$description": "Base blue 700" }
      }
    },
    "spacing": {
      "$type": "dimension",
      "1": { "$value": "4px" },
      "2": { "$value": "8px" },
      "3": { "$value": "12px" },
      "4": { "$value": "16px" },
      "6": { "$value": "24px" },
      "8": { "$value": "32px" },
      "12": { "$value": "48px" },
      "16": { "$value": "64px" }
    }
  },
  "semantic": {
    "color": {
      "action": {
        "$type": "color",
        "primary": {
          "$value": { "light": "{primitive.color.blue.500}", "dark": "{primitive.color.blue.700}" },
          "$description": "Primary interactive color for buttons, links, selected states"
        }
      }
    },
    "spacing": {
      "$type": "dimension",
      "component-gap":    { "$value": "{primitive.spacing.3}", "$description": "Gap between components in a layout" },
      "section-padding":  { "$value": "{primitive.spacing.6}", "$description": "Padding around major content sections" },
      "page-margin":      { "$value": "{primitive.spacing.8}", "$description": "Outer page margin / container padding" }
    }
  }
}
```

Source: W3C DTCG spec `$type` inheritance (parent group `$type` propagates to children), Style Dictionary v5 reference resolution

### Tailwind v4 @theme Output (Verified from Tailwind Docs)

```css
@import "tailwindcss";

@theme {
  /* Reset all default Tailwind colors — this is REQUIRED for enforcement */
  --color-*: initial;

  /* Semantic color tokens — reference CSS vars for runtime theme switching */
  --color-primary:          var(--ds-color-action-primary);
  --color-primary-hover:    var(--ds-color-action-primary-hover);
  --color-secondary:        var(--ds-color-action-secondary);
  --color-destructive:      var(--ds-color-action-destructive);
  --color-surface:          var(--ds-color-surface-default);
  --color-surface-raised:   var(--ds-color-surface-raised);
  --color-text:             var(--ds-color-text-primary);
  --color-text-muted:       var(--ds-color-text-muted);
  --color-border:           var(--ds-color-border-default);

  /* Typography */
  --font-sans: var(--ds-font-family-sans);
  --font-mono: var(--ds-font-family-mono);

  /* Type scale */
  --text-xs: var(--ds-font-size-xs);
  --text-sm: var(--ds-font-size-sm);
  --text-base: var(--ds-font-size-base);
  --text-lg: var(--ds-font-size-lg);
  --text-xl: var(--ds-font-size-xl);
  --text-2xl: var(--ds-font-size-2xl);

  /* Spacing — use a single spacing scale value to generate all spacing utilities */
  --spacing: 4px;

  /* Border radius */
  --radius-sm: var(--ds-radius-sm);
  --radius-md: var(--ds-radius-md);
  --radius-lg: var(--ds-radius-lg);
  --radius-full: 9999px;
}

/* Light mode variables */
:root {
  --ds-color-action-primary: #3B82F6;
  --ds-color-surface-default: #F9FAFB;
  --ds-color-text-primary: #111827;
}

/* Dark mode variables */
@media (prefers-color-scheme: dark) {
  :root {
    --ds-color-action-primary: #1D4ED8;
    --ds-color-surface-default: #111827;
    --ds-color-text-primary: #F9FAFB;
  }
}
```

Source: Tailwind CSS v4 official docs (tailwindcss.com/docs/theme) — `--color-*: initial;` verified as the correct pattern for full palette replacement

### SwiftUI Output (Direct Claude Generation — No Style Dictionary Required)

```swift
// Colors+DesignSystem.swift
// Generated by dsys — do not edit manually

import SwiftUI

public extension Color {
    // Action tokens
    static let dsActionPrimary     = Color("dsActionPrimary",     bundle: .module)
    static let dsActionSecondary   = Color("dsActionSecondary",   bundle: .module)
    static let dsActionDestructive = Color("dsActionDestructive", bundle: .module)

    // Surface tokens
    static let dsSurface           = Color("dsSurface",           bundle: .module)
    static let dsSurfaceRaised     = Color("dsSurfaceRaised",     bundle: .module)

    // Text tokens
    static let dsTextPrimary       = Color("dsTextPrimary",       bundle: .module)
    static let dsTextMuted         = Color("dsTextMuted",         bundle: .module)

    // Border tokens
    static let dsBorderDefault     = Color("dsBorderDefault",     bundle: .module)
    static let dsBorderFocus       = Color("dsBorderFocus",       bundle: .module)
}
```

```swift
// Spacing+DesignSystem.swift
import SwiftUI

public struct DSSpacing {
    @ScaledMetric(relativeTo: .body) public static var xs:  CGFloat = 4
    @ScaledMetric(relativeTo: .body) public static var sm:  CGFloat = 8
    @ScaledMetric(relativeTo: .body) public static var md:  CGFloat = 16
    @ScaledMetric(relativeTo: .body) public static var lg:  CGFloat = 24
    @ScaledMetric(relativeTo: .body) public static var xl:  CGFloat = 32
    @ScaledMetric(relativeTo: .body) public static var xxl: CGFloat = 48
}
```

Asset catalog entry (`Colors.xcassets/dsActionPrimary.colorset/Contents.json`) required alongside Swift file:
```json
{
  "colors": [
    {
      "color": { "color-space": "srgb", "components": { "red": "0.231", "green": "0.510", "blue": "0.965", "alpha": "1.000" }},
      "idiom": "universal"
    },
    {
      "appearances": [{ "appearance": "luminosity", "value": "dark" }],
      "color": { "color-space": "srgb", "components": { "red": "0.114", "green": "0.306", "blue": "0.847", "alpha": "1.000" }},
      "idiom": "universal"
    }
  ],
  "info": { "version": 1, "author": "xcode" }
}
```

Source: Apple SwiftUI documentation + samwize.com asset catalog dark mode article (verified 2022, pattern unchanged through iOS 17)

### Analysis Findings Schema (JSON Schema 2020-12)

This is the schema that analyzer agents must conform to. It must be embedded as a fill-in template in the analyzer agent prompt.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "AnalysisFindings",
  "description": "Output schema for the dsys analysis agent — one document per input image",
  "type": "object",
  "required": ["image_type", "source_path", "confidence", "colors", "typography", "spacing", "shadows", "border_radius", "opacity_scale", "aesthetic"],
  "properties": {
    "image_type": {
      "type": "string",
      "enum": ["ui_screenshot", "visual_reference"],
      "description": "ui_screenshot: a real product UI. visual_reference: mood board, brand photo, illustration, or non-UI inspiration image."
    },
    "source_path": { "type": "string" },
    "confidence": { "type": "string", "enum": ["high", "medium", "low"] },

    "colors": {
      "type": "object",
      "required": ["primitive_palette", "semantic_assignments", "background_style"],
      "properties": {
        "primitive_palette": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["hex", "role", "frequency"],
            "properties": {
              "hex": { "type": "string", "pattern": "^#[0-9A-Fa-f]{6}$" },
              "role": { "type": "string", "enum": ["dominant", "accent", "surface", "text", "neutral", "feedback"] },
              "frequency": { "type": "string", "enum": ["primary", "secondary", "tertiary"] }
            }
          }
        },
        "semantic_assignments": {
          "type": "object",
          "required": ["action_primary", "action_primary_dark", "surface_default", "surface_default_dark", "text_primary", "text_primary_dark", "text_muted", "text_muted_dark", "border_default", "feedback_success", "feedback_error", "feedback_warning"],
          "additionalProperties": { "type": ["string", "null"], "pattern": "^#[0-9A-Fa-f]{6}$|^null$" }
        },
        "background_style": { "type": "string", "enum": ["light", "dark", "unknown"] }
      }
    },

    "typography": {
      "if": { "properties": { "image_type": { "const": "ui_screenshot" } }, "required": ["image_type"] },
      "then": {
        "type": "object",
        "required": ["font_families", "type_scale", "weight_usage", "line_height_pattern"],
        "properties": {
          "font_families": {
            "type": "object",
            "properties": {
              "sans": { "type": ["string", "null"] },
              "mono": { "type": ["string", "null"] },
              "display": { "type": ["string", "null"] }
            }
          },
          "type_scale": { "type": "array", "items": { "type": "number" } },
          "weight_usage": { "type": "object" },
          "line_height_pattern": { "type": "string", "enum": ["tight", "normal", "relaxed", "loose"] }
        }
      },
      "else": { "type": "null" }
    },

    "spacing": {
      "if": { "properties": { "image_type": { "const": "ui_screenshot" } }, "required": ["image_type"] },
      "then": {
        "type": "object",
        "required": ["base_unit", "scale", "density"],
        "properties": {
          "base_unit": { "type": "number", "enum": [4, 8] },
          "scale": { "type": "array", "items": { "type": "number" } },
          "density": { "type": "string", "enum": ["compact", "comfortable", "spacious"] }
        }
      },
      "else": { "type": "null" }
    },

    "shadows": {
      "type": ["array", "null"],
      "items": {
        "type": "object",
        "required": ["elevation", "offset_x", "offset_y", "blur", "spread", "color", "opacity"],
        "properties": {
          "elevation": { "type": "string", "enum": ["sm", "md", "lg", "xl"] },
          "offset_x": { "type": "number" },
          "offset_y": { "type": "number" },
          "blur": { "type": "number" },
          "spread": { "type": "number" },
          "color": { "type": "string" },
          "opacity": { "type": "number", "minimum": 0, "maximum": 1 }
        }
      }
    },

    "border_radius": {
      "type": ["object", "null"],
      "properties": {
        "sm":   { "type": ["number", "null"] },
        "md":   { "type": ["number", "null"] },
        "lg":   { "type": ["number", "null"] },
        "full": { "type": ["boolean", "null"] }
      }
    },

    "opacity_scale": {
      "type": ["array", "null"],
      "items": { "type": "number", "minimum": 0, "maximum": 1 }
    },

    "aesthetic": {
      "type": "object",
      "required": ["vibe_description", "personality_tags", "density", "tone"],
      "properties": {
        "vibe_description": {
          "type": "string",
          "description": "2-3 sentences describing the overall mood, feel, and aesthetic identity. Present tense. Example: 'Clean and professional with generous whitespace. Monochromatic with a single strong blue accent. Conveys trust and clarity.'"
        },
        "personality_tags": {
          "type": "array",
          "items": { "type": "string" },
          "description": "4-8 single-word descriptors. Example: ['minimal', 'trustworthy', 'precise', 'corporate']"
        },
        "density": { "type": "string", "enum": ["compact", "comfortable", "spacious"] },
        "tone": { "type": "string", "enum": ["minimal", "expressive", "corporate", "playful", "bold", "elegant"] }
      }
    }
  }
}
```

### design-system.json Schema (Excerpt)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "DesignSystem",
  "type": "object",
  "required": ["meta", "tokens", "aesthetic", "platform_notes"],
  "properties": {
    "meta": {
      "type": "object",
      "required": ["generated_at", "source_count", "source_types", "aesthetic_summary", "dominant_approach"],
      "properties": {
        "generated_at": { "type": "string", "format": "date-time" },
        "source_count": { "type": "integer" },
        "source_types": {
          "type": "object",
          "properties": {
            "ui_screenshots": { "type": "integer" },
            "visual_references": { "type": "integer" }
          }
        },
        "aesthetic_summary": { "type": "string" },
        "dominant_approach": { "type": "string" },
        "conflict_log": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["token", "candidates", "resolution"],
            "properties": {
              "token": { "type": "string" },
              "candidates": { "type": "array", "items": { "type": "string" } },
              "resolution": { "type": "string" }
            }
          }
        }
      }
    },
    "tokens": {
      "type": "object",
      "required": ["color", "typography", "spacing", "shadow", "border_radius"],
      "properties": {
        "color": {
          "type": "object",
          "description": "W3C DTCG color tokens. Semantic layer with theme-aware $value objects."
        },
        "typography": {
          "type": "object",
          "required": ["font_family", "scale", "weights", "line_heights"],
          "properties": {
            "font_family": {
              "type": "object",
              "properties": {
                "sans": { "type": ["string", "null"] },
                "mono": { "type": ["string", "null"] },
                "display": { "type": ["string", "null"] }
              }
            },
            "scale": { "type": "array", "items": { "type": "number" } },
            "weights": { "type": "array", "items": { "type": "number" } },
            "line_heights": { "type": "object" }
          }
        },
        "spacing": {
          "type": "object",
          "required": ["base_unit", "scale"],
          "properties": {
            "base_unit": { "type": "number", "enum": [4, 8] },
            "scale": { "type": "array", "items": { "type": "number" } },
            "semantic": {
              "type": "object",
              "description": "Named spacing values for common layout patterns"
            }
          }
        },
        "shadow": { "type": ["array", "null"] },
        "border_radius": { "type": "object" },
        "opacity_scale": { "type": ["array", "null"] }
      }
    },
    "aesthetic": {
      "type": "object",
      "required": ["summary", "personality_tags", "density", "tone"],
      "properties": {
        "summary": { "type": "string" },
        "personality_tags": { "type": "array", "items": { "type": "string" } },
        "density": { "type": "string", "enum": ["compact", "comfortable", "spacious"] },
        "tone": { "type": "string" }
      }
    },
    "platform_notes": {
      "type": "object",
      "properties": {
        "react": { "type": "string" },
        "swiftui": { "type": "string" }
      }
    }
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `tailwind.config.js` with `theme.extend` | CSS `@theme` directive with `--color-*: initial;` reset | Tailwind v4 (Jan 2025) | Config is now CSS; no JS file needed; `initial` reset is how you enforce the design system |
| Style Dictionary v4 with CTI (category/type/item) structure | Style Dictionary v5 with DTCG `$type` on tokens directly | v5 release 2024-2025 (latest: 5.3.1) | No more CTI naming required; `$type` drives transforms; node >= 22 required |
| Separate light/dark token files | Single token file with `$value: { light: ..., dark: ... }` | DTCG spec + Style Dictionary v5 | Keeps tokens co-located; avoids file-level duplication |
| `Color(hex:)` custom initializer in SwiftUI | `Color("name", bundle: .module)` referencing asset catalog | Best practice, always true | Asset catalog enables dark mode automatically; raw hex cannot adapt to themes |
| W3C DTCG draft spec | DTCG Format Module 2025.10 (first stable version) | October 2025 | The spec is now stable; tooling can safely depend on it; `$extensions` is the sanctioned escape hatch for vendor-specific data |

**Deprecated/outdated:**

- `tailwind.config.js` for new v4 projects: use `@theme` CSS instead
- Style Dictionary v3 CTI structure: `$type` on tokens is the current pattern
- `theo` (Salesforce): unmaintained, superseded by Style Dictionary

---

## Open Questions

1. **Style Dictionary v5 node >= 22 requirement**
   - What we know: Style Dictionary 5.x requires Node.js >= 22.0.0 LTS
   - What's unclear: What percentage of target users will have Node >= 22 installed? Many corporate environments pin to LTS (Node 20 is still in LTS through April 2026)
   - Recommendation: Document the Node >= 22 requirement clearly in platform specs. Provide a fallback note: if Node < 22, users can invoke Style Dictionary v4.x (`npx style-dictionary@4`) for CSS output; the DTCG token format itself doesn't change between v4 and v5.

2. **Theme-aware `$value` and Style Dictionary v5 compatibility**
   - What we know: The `{ "light": "...", "dark": "..." }` pattern in `$value` is a community convention, not part of the DTCG spec's `$value` definition. The DTCG spec defines `$value` as the computed value for a single mode.
   - What's unclear: How does Style Dictionary v5 handle `{ light, dark }` values? It may require a custom transform to expand them into two separate outputs.
   - Recommendation: In the design-system.json schema, use the `{ light, dark }` pattern for the intermediate representation (it's human-readable and captures the intent). Document that the Style Dictionary build step will require a custom `preprocess` or `transform` to expand these into mode-specific token files for CSS variable output. The platform specs must specify this explicitly.

3. **Font family availability on target platforms**
   - What we know: Extracted font families from benchmarks may be custom fonts (Inter, Geist, SF Pro) not available in the consuming project.
   - What's unclear: Should the schema capture a fallback stack alongside the primary font?
   - Recommendation: Typography tokens should carry both a `preferred` and `fallback_stack` field. The rubric should instruct the analyzer to infer the font category (geometric sans, humanist sans, mono, serif, display) and provide a fallback stack of web-safe or system fonts for that category.

---

## Sources

### Primary (HIGH confidence)

- W3C DTCG Format Module 2025.10 — first stable specification release, fetched via designtokens.org; `$value`, `$type`, `$description`, reference syntax, composite types
- Tailwind CSS v4 official docs (tailwindcss.com/docs/theme) — `@theme` directive, namespace mapping, `--color-*: initial` reset pattern, dark mode CSS variable approach
- npm registry — `style-dictionary@5.3.1` confirmed as latest; `npm info style-dictionary` verified live
- W3C DTCG `$extensions` and `$deprecated` fields — fetched from spec document

### Secondary (MEDIUM confidence)

- styledictionary.com — v5 config format, DTCG auto-detection, predefined transforms; WebFetch verified; exact transform group compositions not available from the docs pages reached
- alwaystwisted.com — `$mods` pattern for single-file theming with Style Dictionary; WebSearch verified; not an official source but pattern is consistent with Style Dictionary docs
- WebSearch findings on Style Dictionary v5 breaking changes — node >= 22 requirement, references-only-to-token-leaf-nodes restriction; single search result, needs verification against GitHub releases

### Tertiary (LOW confidence, verify before committing)

- Style Dictionary v5 handling of `{ light, dark }` `$value` objects: behavior not confirmed from official docs; requires empirical testing during Phase 2 or Phase 4 planning

---

## Metadata

**Confidence breakdown:**

- DTCG token format: HIGH — spec is stable (2025.10), fetched directly from designtokens.org
- Tailwind v4 @theme: HIGH — official Tailwind docs, verified live
- Style Dictionary version: HIGH — verified live via npm info (5.3.1)
- Style Dictionary v5 `{ light, dark }` $value handling: LOW — not confirmed from official docs; community convention only
- JSON Schema 2020-12 for agent contracts: HIGH — established standard, DTCG spec itself references it
- SwiftUI asset catalog pattern: HIGH — consistent across multiple Apple documentation sources
- Semantic naming taxonomy: MEDIUM — matches industry patterns (Primer, Polaris, Material) but the specific token names proposed here are recommendations, not specifications

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 for Style Dictionary version (actively maintained); 2027-01-01 for DTCG spec (just reached stable)

---

## Planning Guidance

This section summarizes what the planner needs to know to write task plans for Phase 1.

### What Phase 1 Actually Produces

Five documents:

1. **`analysis-findings-schema.md`** — Human-readable spec of the analysis findings structure, with field-by-field descriptions and the embedded JSON fill-in template
2. **`analysis-findings.schema.json`** — Machine-readable JSON Schema 2020-12 file for the analysis findings
3. **`token-schema.md`** — Human-readable spec of design-system.json, with rationale for each section
4. **`design-system.schema.json`** — Machine-readable JSON Schema 2020-12 file for design-system.json
5. **`analysis-rubric.md`** — The extraction rubric: what to look for in a screenshot, quantization rules, how to classify image types, how to handle ambiguity
6. **`platform-specs/react-tailwind-spec.md`** — File manifest for the React/Tailwind generator
7. **`platform-specs/swiftui-spec.md`** — File manifest for the SwiftUI generator

### Critical Design Decisions for the Planner

These are the Claude's Discretion items that the plans must resolve before the documents can be written:

**Quantization rules (plan must include specific rules):**
- Spacing: 4px grid snap (4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96, 128)
- Type sizes: Standard scale snap (10, 12, 13, 14, 15, 16, 18, 20, 24, 28, 32, 36, 48, 64, 72, 96)
- Border radius: Snap to (0, 2, 4, 6, 8, 12, 16, 24, 32, 9999)
- Shadows: No quantization — preserve as observed
- Color: No rounding of hex values; infer the "intended" palette color from context, not pixel measurement

**Schema strictness:**
- All required fields use `"required"` array in JSON Schema
- "Not found" = `null`, never absent key
- Use `if/then/else` for fields that differ based on `image_type`
- Minimum schema strictness: any output that passes JSON.parse but fails schema validation should be treated as a hard error (not a soft warning) in downstream agents

**design-system.json internal structure:**
- Two-layer (primitive + semantic) for colors
- Flat for non-color tokens (spacing, typography, radius — these rarely need aliasing)
- DTCG `$value`/`$type` format throughout
- Theme-aware `{ light, dark }` for semantic color `$value`
- `meta.conflict_log` as required array (may be empty but must be present)

### Tokens Not in the Prior Architecture Sketch

The CONTEXT.md specifies a full extraction including: **opacity** and **effects**. The earlier architecture research's minimal schema did not include these. The Phase 1 schemas must add:

- `opacity_scale`: an array of opacity values (0.05, 0.1, 0.15, 0.2, 0.25, 0.5, 0.75, 0.9, 0.95, 1.0) observed in the UI
- `effects`: blur effects, backdrop filters, other visual effects — structured as an array of effect objects

### Platform Spec Minimum Requirements

**React/Tailwind generator must produce:**
- `tokens.json` (W3C DTCG source)
- `theme.css` (Tailwind v4 `@theme` block with `--color-*: initial;` reset)
- `tokens.css` (CSS custom properties for both light and dark mode)
- `components/Button.tsx`, `components/Card.tsx`, `components/Input.tsx`, `components/Badge.tsx` (starter templates)
- `STYLEGUIDE.md`

**SwiftUI generator must produce:**
- `Colors+DesignSystem.swift`
- `Typography+DesignSystem.swift`
- `Spacing+DesignSystem.swift`
- `Colors.xcassets/` directory with `Contents.json` per color token (light + dark variants)
- `Components/Button.swift`, `Components/Card.swift`, `Components/Input.swift`, `Components/Badge.swift`
- `STYLEGUIDE.md`

Minimum iOS target: **iOS 16** — `@ScaledMetric` is iOS 14+, `Color("name", bundle: .module)` is iOS 14+; iOS 16 gives access to `NavigationStack` and more modern APIs for component templates.
