# design-system.json Token Schema

Human-readable specification of the `design-system.json` intermediate artifact.

---

## 1. Overview

`design-system.json` is the intermediate artifact that decouples analysis from generation. The synthesizer agent reads N analysis findings documents (one per benchmark image) and writes a single `design-system.json` to `.dsys/design-system.json`. Generator agents then read this file to produce platform-specific output (React/Tailwind CSS or SwiftUI). The file is human-inspectable between synthesis and generation.

**Format:** All tokens follow [W3C Design Tokens Community Group (DTCG) Format Module 2025.10](https://designtokens.org/). DTCG tokens use three reserved fields:

- `$value` — The resolved value of the token. For semantic color tokens, this is an object with `light` and `dark` keys. For all other tokens, this is a string or number.
- `$type` — The token type (`color`, `dimension`, `fontFamily`, `fontWeight`, `number`, `shadow`). May be declared on a parent group and inherited by children.
- `$description` — Human-readable explanation of the token's intended use.

**Storage path:** `.dsys/design-system.json` (relative to the project root where `dsys` is invoked).

**Purpose in the pipeline:**

```
N benchmark images
    → N analysis findings (analysis-findings.schema.json)
        → design-system.json  ← this document
            → platform artifacts (React/Tailwind, SwiftUI)
```

---

## 2. Top-Level Structure

The document has four required top-level keys:

| Key | Type | Purpose |
|-----|------|---------|
| `meta` | object | Generation metadata: sources, aesthetic summary, synthesis conflict log |
| `tokens` | object | All design tokens in DTCG format |
| `aesthetic` | object | Synthesized aesthetic identity |
| `platform_notes` | object | Per-platform hints for generator agents |

```json
{
  "meta": { ... },
  "tokens": { ... },
  "aesthetic": { ... },
  "platform_notes": { ... }
}
```

---

## 3. `meta` Object

Records how the design system was generated, what sources were used, and any synthesis decisions made when conflicting values were found.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `generated_at` | string (ISO 8601) | yes | UTC datetime when synthesis completed. Example: `"2026-02-17T18:00:00Z"` |
| `source_count` | integer (>= 1) | yes | Total number of benchmark images analyzed |
| `source_types` | object | yes | Breakdown of source types (see below) |
| `aesthetic_summary` | string (>= 20 chars) | yes | 2–3 sentences summarizing the dominant aesthetic across all benchmarks |
| `dominant_approach` | string (>= 10 chars) | yes | One-line label for the design approach. Example: `"Clean SaaS with blue accent"` or `"Bold editorial with dramatic contrast"` |
| `conflict_log` | array | yes | Records all cases where benchmark images produced conflicting values and how the conflict was resolved. **Always present. Empty array `[]` if no conflicts.** |

**`source_types` sub-object:**

| Field | Type | Description |
|-------|------|-------------|
| `ui_screenshots` | integer (>= 0) | Count of benchmark images classified as `ui_screenshot` |
| `visual_references` | integer (>= 0) | Count of benchmark images classified as `visual_reference` |

**`conflict_log` item structure:**

Each item records one synthesis decision where multiple benchmarks produced different values for the same token:

| Field | Type | Description |
|-------|------|-------------|
| `token` | string | Dot-notation token path, e.g. `"tokens.color.semantic.action.primary"` |
| `candidates` | array of strings | All candidate values from the source images (>= 2 values) |
| `chosen` | string | The value the synthesizer selected |
| `rationale` | string | Why this value was chosen (e.g., `"Majority vote: 3/4 sources used #3B82F6"`) |

**Example `meta`:**

```json
{
  "generated_at": "2026-02-17T18:00:00Z",
  "source_count": 4,
  "source_types": {
    "ui_screenshots": 3,
    "visual_references": 1
  },
  "aesthetic_summary": "Clean and professional with generous whitespace. Monochromatic palette anchored by a single strong blue accent. Conveys trust and precision — appropriate for productivity and data-heavy SaaS applications.",
  "dominant_approach": "Clean SaaS with blue accent",
  "conflict_log": [
    {
      "token": "tokens.color.semantic.action.primary",
      "candidates": ["#3B82F6", "#2563EB", "#3B82F6", "#3B82F6"],
      "chosen": "#3B82F6",
      "rationale": "Majority vote: 3/4 sources used #3B82F6; one source used a darker shade likely from a pressed state."
    }
  ]
}
```

---

## 4. `tokens` Object

All design tokens. Six required categories: `color`, `typography`, `spacing`, `shadow`, `border_radius`, `opacity`.

### 4.1 `tokens.color` — Two-Layer Color Architecture

Colors use a two-layer architecture to support semantic naming and light/dark theming without duplicating the token set:

- **Primitive layer** (`tokens.color.primitive`): Raw color values grouped by hue family. Used only to define the palette — never referenced directly by components.
- **Semantic layer** (`tokens.color.semantic`): Role-based tokens that reference primitives. These are what components use. Semantic tokens support theme-aware values via a `{ light, dark }` `$value` object.

#### `tokens.color.primitive`

Groups colors by hue family. The `$type: "color"` may be declared at group level and inherited by children.

Structure: `tokens.color.primitive.{hue_family}.{shade}` where shade is a numeric step (e.g., `50`, `100`, `200`, ..., `900`, `950`).

Each primitive token:

```json
{
  "$value": "#3B82F6",
  "$type": "color",
  "$description": "Blue 500 — mid-range blue, primary brand hue"
}
```

`$description` is optional on primitive tokens. `$type` may be omitted if set on the parent group.

**Example primitive group:**

```json
"primitive": {
  "color": {
    "$type": "color",
    "blue": {
      "400": { "$value": "#60A5FA", "$description": "Blue 400 — lighter blue for hover states" },
      "500": { "$value": "#3B82F6", "$description": "Blue 500 — primary brand blue" },
      "600": { "$value": "#2563EB", "$description": "Blue 600 — pressed/active blue" },
      "700": { "$value": "#1D4ED8", "$description": "Blue 700 — dark mode primary blue" }
    },
    "gray": {
      "50":  { "$value": "#F9FAFB" },
      "100": { "$value": "#F3F4F6" },
      "200": { "$value": "#E5E7EB" },
      "400": { "$value": "#9CA3AF" },
      "500": { "$value": "#6B7280" },
      "700": { "$value": "#374151" },
      "900": { "$value": "#111827" },
      "950": { "$value": "#030712" }
    },
    "red": {
      "500": { "$value": "#EF4444" },
      "700": { "$value": "#B91C1C" }
    },
    "green": {
      "500": { "$value": "#22C55E" },
      "700": { "$value": "#15803D" }
    },
    "yellow": {
      "500": { "$value": "#EAB308" }
    },
    "white": { "$value": "#FFFFFF" },
    "black": { "$value": "#000000" }
  }
}
```

#### `tokens.color.semantic` — Theme-Aware Color Tokens

Semantic tokens describe purpose, not appearance. The complete required taxonomy is 18 roles across 5 groups:

| Group | Role | Token path | Purpose |
|-------|------|-----------|---------|
| action | primary | `action.primary` | Primary interactive elements: buttons, links, selected states |
| action | secondary | `action.secondary` | Secondary/ghost interactive elements |
| action | destructive | `action.destructive` | Danger actions: delete, remove, irreversible operations |
| surface | default | `surface.default` | Default page background |
| surface | raised | `surface.raised` | Card/elevated surface, above default |
| surface | overlay | `surface.overlay` | Modal, drawer, or popover background |
| surface | inset | `surface.inset` | Input fields, recessed surfaces, below default |
| text | primary | `text.primary` | Primary body text and headings |
| text | secondary | `text.secondary` | Supporting/secondary text |
| text | muted | `text.muted` | Disabled, placeholder, caption text |
| text | inverse | `text.inverse` | Text rendered on colored backgrounds (e.g., button labels) |
| text | link | `text.link` | Hyperlinks |
| border | default | `border.default` | Standard borders and dividers |
| border | focus | `border.focus` | Focus ring color (accessibility) |
| feedback | success | `feedback.success` | Success states and confirmations |
| feedback | error | `feedback.error` | Error and destructive states |
| feedback | warning | `feedback.warning` | Warning states |
| feedback | info | `feedback.info` | Informational states |

**Theme-aware `$value` pattern:**

Semantic color `$value` is an object with `light` and `dark` keys. Values may be DTCG reference syntax (`{group.token}`) pointing to a primitive, or raw hex strings for direct values.

```json
"action": {
  "primary": {
    "$value": {
      "light": "{primitive.color.blue.500}",
      "dark": "{primitive.color.blue.400}"
    },
    "$type": "color",
    "$description": "Primary interactive elements: buttons, links, selected states"
  },
  "destructive": {
    "$value": {
      "light": "{primitive.color.red.500}",
      "dark": "{primitive.color.red.400}"
    },
    "$type": "color",
    "$description": "Danger actions: delete, remove, irreversible operations"
  }
}
```

Tokens that do not need per-theme variation (rare) may use a flat string `$value`:

```json
"text": {
  "inverse": {
    "$value": "#FFFFFF",
    "$type": "color",
    "$description": "Text on colored surfaces — always white regardless of theme"
  }
}
```

---

### 4.2 `tokens.typography`

Four required sub-objects: `font_family`, `scale`, `weight`, `line_height`.

#### `tokens.typography.font_family`

Three optional font roles. Each is either a token object or `null` if not observed in the benchmarks.

| Key | `$type` | Purpose |
|-----|---------|---------|
| `sans` | `fontFamily` | Primary UI sans-serif font |
| `mono` | `fontFamily` | Monospace font for code/data |
| `display` | `fontFamily` | Display/heading font (if distinct from sans) |

Each font token includes an optional `fallback_stack` array for degraded environments:

```json
"font_family": {
  "sans": {
    "$value": "Inter",
    "$type": "fontFamily",
    "fallback_stack": ["-apple-system", "BlinkMacSystemFont", "Segoe UI", "sans-serif"]
  },
  "mono": {
    "$value": "JetBrains Mono",
    "$type": "fontFamily",
    "fallback_stack": ["Fira Code", "Cascadia Code", "monospace"]
  },
  "display": null
}
```

#### `tokens.typography.scale`

Type size steps. Standard type scale keys: `xs`, `sm`, `base`, `lg`, `xl`, `2xl`, `3xl`, `4xl`, `5xl`.

```json
"scale": {
  "$type": "dimension",
  "xs":   { "$value": "12px" },
  "sm":   { "$value": "14px" },
  "base": { "$value": "16px" },
  "lg":   { "$value": "18px" },
  "xl":   { "$value": "20px" },
  "2xl":  { "$value": "24px" },
  "3xl":  { "$value": "30px" },
  "4xl":  { "$value": "36px" },
  "5xl":  { "$value": "48px" }
}
```

#### `tokens.typography.weight`

Font weight steps: `regular`, `medium`, `semibold`, `bold`.

```json
"weight": {
  "$type": "fontWeight",
  "regular":  { "$value": 400 },
  "medium":   { "$value": 500 },
  "semibold": { "$value": 600 },
  "bold":     { "$value": 700 }
}
```

#### `tokens.typography.line_height`

Unitless line-height multipliers: `tight`, `normal`, `relaxed`, `loose`.

```json
"line_height": {
  "$type": "number",
  "tight":   { "$value": 1.25 },
  "normal":  { "$value": 1.5  },
  "relaxed": { "$value": 1.625 },
  "loose":   { "$value": 2.0  }
}
```

---

### 4.3 `tokens.spacing`

Three sub-objects: `base_unit` (required), `scale` (required), `semantic` (optional).

#### `tokens.spacing.base_unit`

The grid base unit. Must be `4` or `8`.

```json
"base_unit": 4
```

#### `tokens.spacing.scale`

Numeric step scale. Keys are integers (`1`, `2`, `3`, ...) representing multiples of the base unit.

Required steps: `1`, `2`, `3`, `4`, `5`, `6`, `8`, `10`, `12`, `16`, `20`, `24`, `32`.

```json
"scale": {
  "$type": "dimension",
  "1":  { "$value": "4px"   },
  "2":  { "$value": "8px"   },
  "3":  { "$value": "12px"  },
  "4":  { "$value": "16px"  },
  "5":  { "$value": "20px"  },
  "6":  { "$value": "24px"  },
  "8":  { "$value": "32px"  },
  "10": { "$value": "40px"  },
  "12": { "$value": "48px"  },
  "16": { "$value": "64px"  },
  "20": { "$value": "80px"  },
  "24": { "$value": "96px"  },
  "32": { "$value": "128px" }
}
```

#### `tokens.spacing.semantic`

Named spacing tokens for common layout patterns. Each references a scale step using DTCG reference syntax. `$description` is required on semantic tokens.

Required semantic tokens:

| Key | Purpose |
|-----|---------|
| `component-gap` | Gap between sibling components in a layout |
| `section-padding` | Padding around a major content section |
| `page-margin` | Outer page margin / container padding |
| `input-padding` | Internal padding inside form inputs |
| `card-padding` | Internal padding inside card/panel surfaces |
| `stack-gap` | Gap in vertical/horizontal stack layouts |

```json
"semantic": {
  "$type": "dimension",
  "component-gap":   { "$value": "{tokens.spacing.scale.3}", "$description": "Gap between components in a layout" },
  "section-padding": { "$value": "{tokens.spacing.scale.6}", "$description": "Padding around major content sections" },
  "page-margin":     { "$value": "{tokens.spacing.scale.8}", "$description": "Outer page margin / container padding" },
  "input-padding":   { "$value": "{tokens.spacing.scale.3}", "$description": "Internal padding inside form inputs" },
  "card-padding":    { "$value": "{tokens.spacing.scale.6}", "$description": "Internal padding inside card/panel surfaces" },
  "stack-gap":       { "$value": "{tokens.spacing.scale.4}", "$description": "Gap in vertical/horizontal stack layouts" }
}
```

---

### 4.4 `tokens.shadow`

`type: ["array", "null"]` — `null` if no shadows were observed in the benchmarks.

Each shadow token in the array:

| Field | Type | Description |
|-------|------|-------------|
| `$value` | object | Shadow definition (see below) |
| `$type` | `"shadow"` | DTCG type constant |
| `elevation` | enum | `sm`, `md`, `lg`, or `xl` — semantic elevation label |

**`$value` sub-object:**

| Field | Type | Example | Notes |
|-------|------|---------|-------|
| `offsetX` | string | `"0px"` | Horizontal offset |
| `offsetY` | string | `"1px"` | Vertical offset (positive = downward) |
| `blur` | string | `"3px"` | Blur radius |
| `spread` | string | `"0px"` | Spread radius |
| `color` | string | `"#00000026"` | Hex with alpha (8-digit hex) |

```json
"shadow": [
  {
    "$value": { "offsetX": "0px", "offsetY": "1px", "blur": "3px", "spread": "0px", "color": "#00000014" },
    "$type": "shadow",
    "elevation": "sm"
  },
  {
    "$value": { "offsetX": "0px", "offsetY": "4px", "blur": "12px", "spread": "0px", "color": "#00000026" },
    "$type": "shadow",
    "elevation": "md"
  },
  {
    "$value": { "offsetX": "0px", "offsetY": "8px", "blur": "24px", "spread": "-4px", "color": "#0000003D" },
    "$type": "shadow",
    "elevation": "lg"
  },
  {
    "$value": { "offsetX": "0px", "offsetY": "16px", "blur": "48px", "spread": "-8px", "color": "#00000052" },
    "$type": "shadow",
    "elevation": "xl"
  }
]
```

---

### 4.5 `tokens.border_radius`

Four named steps: `sm`, `md`, `lg`, `full`.

`full` always uses `"9999px"` to produce fully-rounded (pill) shapes.

```json
"border_radius": {
  "$type": "dimension",
  "sm":   { "$value": "4px"    },
  "md":   { "$value": "8px"    },
  "lg":   { "$value": "12px"   },
  "full": { "$value": "9999px" }
}
```

---

### 4.6 `tokens.opacity`

`type: ["object", "null"]` — `null` if no distinct opacity values were observed.

Named opacity levels for common use cases:

| Key | Typical value | Purpose |
|-----|---------------|---------|
| `subtle` | `0.05`–`0.08` | Very light overlays, hover tints |
| `disabled` | `0.4`–`0.5` | Disabled element appearance |
| `overlay` | `0.5`–`0.6` | Modal backdrop |
| `heavy` | `0.8`–`0.9` | Strong overlays |

```json
"opacity": {
  "$type": "number",
  "subtle":   { "$value": 0.06, "$description": "Very light overlay or hover tint" },
  "disabled": { "$value": 0.4,  "$description": "Disabled element opacity" },
  "overlay":  { "$value": 0.5,  "$description": "Modal backdrop opacity" },
  "heavy":    { "$value": 0.85, "$description": "Strong overlay opacity" }
}
```

---

## 5. `aesthetic` Object

Synthesized aesthetic identity derived from all benchmark sources.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `summary` | string | yes | 2–3 sentence aesthetic description |
| `personality_tags` | array of strings | yes | 4–8 single-word descriptors |
| `density` | enum | yes | `compact`, `comfortable`, or `spacious` |
| `tone` | enum | yes | `minimal`, `expressive`, `corporate`, `playful`, `bold`, or `elegant` |

```json
"aesthetic": {
  "summary": "Clean and professional with generous whitespace. A single strong blue accent anchors the palette against a near-white surface. The system conveys trust and precision without feeling sterile.",
  "personality_tags": ["clean", "trustworthy", "precise", "minimal", "professional"],
  "density": "comfortable",
  "tone": "minimal"
}
```

---

## 6. `platform_notes` Object

Hints for generator agents. Plain text strings — no structured format requirement.

| Field | Type | Purpose |
|-------|------|---------|
| `react` | string | Hints for React/Tailwind CSS generation |
| `swiftui` | string | Hints for SwiftUI generation |

```json
"platform_notes": {
  "react": "Use CSS custom properties for color tokens to enable runtime theme switching. Apply --color-*: initial; in @theme to suppress Tailwind defaults. Font fallback stacks should be included in the CSS font-family declarations.",
  "swiftui": "Reference colors via asset catalog (Color(\"name\", bundle: .module)) for automatic dark mode. Use @ScaledMetric for spacing constants. Minimum deployment target is iOS 16."
}
```

---

## 7. Complete Example

The following is a complete, realistic `design-system.json` for a clean SaaS application. This example is valid JSON and conforms to `design-system.schema.json`. It can be used as a fill-in template for the synthesizer agent.

```json
{
  "meta": {
    "generated_at": "2026-02-17T18:00:00Z",
    "source_count": 4,
    "source_types": {
      "ui_screenshots": 3,
      "visual_references": 1
    },
    "aesthetic_summary": "Clean and professional with generous whitespace. Monochromatic palette anchored by a single strong blue accent. Conveys trust and precision — appropriate for productivity and data-heavy SaaS applications.",
    "dominant_approach": "Clean SaaS with blue accent",
    "conflict_log": [
      {
        "token": "tokens.color.semantic.action.primary",
        "candidates": ["#3B82F6", "#2563EB", "#3B82F6", "#3B82F6"],
        "chosen": "#3B82F6",
        "rationale": "Majority vote: 3/4 sources used #3B82F6; one source used a darker shade likely from a pressed state."
      }
    ]
  },
  "tokens": {
    "color": {
      "primitive": {
        "$type": "color",
        "blue": {
          "400": { "$value": "#60A5FA", "$description": "Blue 400 — hover and focus blue" },
          "500": { "$value": "#3B82F6", "$description": "Blue 500 — primary brand blue" },
          "600": { "$value": "#2563EB", "$description": "Blue 600 — pressed/active blue" },
          "700": { "$value": "#1D4ED8", "$description": "Blue 700 — dark mode primary" }
        },
        "gray": {
          "50":  { "$value": "#F9FAFB" },
          "100": { "$value": "#F3F4F6" },
          "200": { "$value": "#E5E7EB" },
          "300": { "$value": "#D1D5DB" },
          "400": { "$value": "#9CA3AF" },
          "500": { "$value": "#6B7280" },
          "700": { "$value": "#374151" },
          "800": { "$value": "#1F2937" },
          "900": { "$value": "#111827" },
          "950": { "$value": "#030712" }
        },
        "red": {
          "500": { "$value": "#EF4444" },
          "400": { "$value": "#F87171" }
        },
        "green": {
          "500": { "$value": "#22C55E" },
          "400": { "$value": "#4ADE80" }
        },
        "yellow": {
          "500": { "$value": "#EAB308" },
          "400": { "$value": "#FACC15" }
        },
        "white": { "$value": "#FFFFFF" },
        "black": { "$value": "#000000" }
      },
      "semantic": {
        "$type": "color",
        "action": {
          "primary": {
            "$value": { "light": "{tokens.color.primitive.blue.500}", "dark": "{tokens.color.primitive.blue.400}" },
            "$description": "Primary interactive elements: buttons, links, selected states"
          },
          "secondary": {
            "$value": { "light": "{tokens.color.primitive.gray.200}", "dark": "{tokens.color.primitive.gray.700}" },
            "$description": "Secondary/ghost interactive elements"
          },
          "destructive": {
            "$value": { "light": "{tokens.color.primitive.red.500}", "dark": "{tokens.color.primitive.red.400}" },
            "$description": "Danger actions: delete, remove, irreversible operations"
          }
        },
        "surface": {
          "default": {
            "$value": { "light": "{tokens.color.primitive.gray.50}", "dark": "{tokens.color.primitive.gray.950}" },
            "$description": "Default page background"
          },
          "raised": {
            "$value": { "light": "{tokens.color.primitive.white}", "dark": "{tokens.color.primitive.gray.900}" },
            "$description": "Card/elevated surface, above default"
          },
          "overlay": {
            "$value": { "light": "{tokens.color.primitive.white}", "dark": "{tokens.color.primitive.gray.800}" },
            "$description": "Modal, drawer, or popover background"
          },
          "inset": {
            "$value": { "light": "{tokens.color.primitive.gray.100}", "dark": "{tokens.color.primitive.gray.800}" },
            "$description": "Input fields and recessed surfaces, below default"
          }
        },
        "text": {
          "primary": {
            "$value": { "light": "{tokens.color.primitive.gray.900}", "dark": "{tokens.color.primitive.gray.50}" },
            "$description": "Primary body text and headings"
          },
          "secondary": {
            "$value": { "light": "{tokens.color.primitive.gray.700}", "dark": "{tokens.color.primitive.gray.300}" },
            "$description": "Supporting/secondary text"
          },
          "muted": {
            "$value": { "light": "{tokens.color.primitive.gray.500}", "dark": "{tokens.color.primitive.gray.400}" },
            "$description": "Disabled, placeholder, and caption text"
          },
          "inverse": {
            "$value": "#FFFFFF",
            "$description": "Text on colored surfaces (e.g., white text on blue button)"
          },
          "link": {
            "$value": { "light": "{tokens.color.primitive.blue.500}", "dark": "{tokens.color.primitive.blue.400}" },
            "$description": "Hyperlinks"
          }
        },
        "border": {
          "default": {
            "$value": { "light": "{tokens.color.primitive.gray.200}", "dark": "{tokens.color.primitive.gray.700}" },
            "$description": "Standard borders and dividers"
          },
          "focus": {
            "$value": { "light": "{tokens.color.primitive.blue.500}", "dark": "{tokens.color.primitive.blue.400}" },
            "$description": "Focus ring color (accessibility)"
          }
        },
        "feedback": {
          "success": {
            "$value": { "light": "{tokens.color.primitive.green.500}", "dark": "{tokens.color.primitive.green.400}" },
            "$description": "Success states and confirmations"
          },
          "error": {
            "$value": { "light": "{tokens.color.primitive.red.500}", "dark": "{tokens.color.primitive.red.400}" },
            "$description": "Error and destructive states"
          },
          "warning": {
            "$value": { "light": "{tokens.color.primitive.yellow.500}", "dark": "{tokens.color.primitive.yellow.400}" },
            "$description": "Warning states"
          },
          "info": {
            "$value": { "light": "{tokens.color.primitive.blue.500}", "dark": "{tokens.color.primitive.blue.400}" },
            "$description": "Informational states"
          }
        }
      }
    },
    "typography": {
      "font_family": {
        "sans": {
          "$value": "Inter",
          "$type": "fontFamily",
          "fallback_stack": ["-apple-system", "BlinkMacSystemFont", "Segoe UI", "sans-serif"]
        },
        "mono": {
          "$value": "JetBrains Mono",
          "$type": "fontFamily",
          "fallback_stack": ["Fira Code", "Cascadia Code", "monospace"]
        },
        "display": null
      },
      "scale": {
        "$type": "dimension",
        "xs":   { "$value": "12px" },
        "sm":   { "$value": "14px" },
        "base": { "$value": "16px" },
        "lg":   { "$value": "18px" },
        "xl":   { "$value": "20px" },
        "2xl":  { "$value": "24px" },
        "3xl":  { "$value": "30px" },
        "4xl":  { "$value": "36px" },
        "5xl":  { "$value": "48px" }
      },
      "weight": {
        "$type": "fontWeight",
        "regular":  { "$value": 400 },
        "medium":   { "$value": 500 },
        "semibold": { "$value": 600 },
        "bold":     { "$value": 700 }
      },
      "line_height": {
        "$type": "number",
        "tight":   { "$value": 1.25  },
        "normal":  { "$value": 1.5   },
        "relaxed": { "$value": 1.625 },
        "loose":   { "$value": 2.0   }
      }
    },
    "spacing": {
      "base_unit": 4,
      "scale": {
        "$type": "dimension",
        "1":  { "$value": "4px"   },
        "2":  { "$value": "8px"   },
        "3":  { "$value": "12px"  },
        "4":  { "$value": "16px"  },
        "5":  { "$value": "20px"  },
        "6":  { "$value": "24px"  },
        "8":  { "$value": "32px"  },
        "10": { "$value": "40px"  },
        "12": { "$value": "48px"  },
        "16": { "$value": "64px"  },
        "20": { "$value": "80px"  },
        "24": { "$value": "96px"  },
        "32": { "$value": "128px" }
      },
      "semantic": {
        "$type": "dimension",
        "component-gap":   { "$value": "{tokens.spacing.scale.3}", "$description": "Gap between components in a layout" },
        "section-padding": { "$value": "{tokens.spacing.scale.6}", "$description": "Padding around major content sections" },
        "page-margin":     { "$value": "{tokens.spacing.scale.8}", "$description": "Outer page margin / container padding" },
        "input-padding":   { "$value": "{tokens.spacing.scale.3}", "$description": "Internal padding inside form inputs" },
        "card-padding":    { "$value": "{tokens.spacing.scale.6}", "$description": "Internal padding inside card/panel surfaces" },
        "stack-gap":       { "$value": "{tokens.spacing.scale.4}", "$description": "Gap in vertical/horizontal stack layouts" }
      }
    },
    "shadow": [
      {
        "$value": { "offsetX": "0px", "offsetY": "1px", "blur": "3px", "spread": "0px", "color": "#00000014" },
        "$type": "shadow",
        "elevation": "sm"
      },
      {
        "$value": { "offsetX": "0px", "offsetY": "4px", "blur": "12px", "spread": "0px", "color": "#00000026" },
        "$type": "shadow",
        "elevation": "md"
      },
      {
        "$value": { "offsetX": "0px", "offsetY": "8px", "blur": "24px", "spread": "-4px", "color": "#0000003D" },
        "$type": "shadow",
        "elevation": "lg"
      },
      {
        "$value": { "offsetX": "0px", "offsetY": "16px", "blur": "48px", "spread": "-8px", "color": "#00000052" },
        "$type": "shadow",
        "elevation": "xl"
      }
    ],
    "border_radius": {
      "$type": "dimension",
      "sm":   { "$value": "4px"    },
      "md":   { "$value": "8px"    },
      "lg":   { "$value": "12px"   },
      "full": { "$value": "9999px" }
    },
    "opacity": {
      "$type": "number",
      "subtle":   { "$value": 0.06, "$description": "Very light overlay or hover tint" },
      "disabled": { "$value": 0.4,  "$description": "Disabled element opacity" },
      "overlay":  { "$value": 0.5,  "$description": "Modal backdrop opacity" },
      "heavy":    { "$value": 0.85, "$description": "Strong overlay opacity" }
    }
  },
  "aesthetic": {
    "summary": "Clean and professional with generous whitespace. A single strong blue accent anchors the palette against a near-white surface. The system conveys trust and precision without feeling sterile.",
    "personality_tags": ["clean", "trustworthy", "precise", "minimal", "professional"],
    "density": "comfortable",
    "tone": "minimal"
  },
  "platform_notes": {
    "react": "Use CSS custom properties for color tokens to enable runtime theme switching. Apply --color-*: initial; in @theme to suppress Tailwind defaults. Font fallback stacks should be included in the CSS font-family declarations.",
    "swiftui": "Reference colors via asset catalog (Color(\"name\", bundle: .module)) for automatic dark mode. Use @ScaledMetric for spacing constants. Minimum deployment target is iOS 16."
  }
}
```

---

## 8. Design Rationale

### Why two-layer (primitive + semantic) for colors

A single-layer approach (e.g., `color.primary: "#3B82F6"`) cannot support theming — you cannot change `primary` to a different value for dark mode without duplicating the entire token set. The primitive layer acts as a named palette. The semantic layer expresses role and intent while referencing primitives by name. This means light/dark theming is just a matter of which primitive a semantic token points to, not a parallel file.

This is the pattern used by Primer (GitHub), Polaris (Shopify), and Material Design 3 (Google). It is the DTCG-recommended approach and what Style Dictionary v5 is designed to transform.

### Why theme-aware `$value` as an object instead of separate files

The `{ "light": "...", "dark": "..." }` pattern keeps both theme values co-located with the token definition. A developer reading `border.focus` can see both its light and dark values in one place — no file-switching. Separate light/dark files double the file count, create synchronization bugs when one file is updated and the other is not, and complicate the generator prompts (which must now merge two files to reason about a single token).

The tradeoff: this `$value` format is not natively understood by all Style Dictionary v5 transforms. The generator agent's Style Dictionary configuration will require a custom `preprocess` step to expand `{ light, dark }` values into mode-specific token files. This is documented explicitly in `platform-specs/react-tailwind-spec.md`.

### Why `conflict_log` is required

When multiple benchmarks disagree on a token value, the synthesizer makes a judgment call. Without logging this decision, the design system is a black box — if the chosen value looks wrong, there is no way to see what alternatives were considered. The `conflict_log` makes the synthesis process auditable and reversible. It is always present (even as `[]`) so consumers never need to check for its existence before iterating.

### Why DTCG format

The W3C Design Tokens Community Group format reached its first stable specification in October 2025. Using `$value`, `$type`, and `$description` means:

1. **Tooling compatibility:** Style Dictionary v5 auto-detects DTCG format and applies the correct transforms. Third-party tools (Tokens Studio, etc.) also support it natively.
2. **Future-proofing:** The spec is now stable and versioned. It will not introduce breaking changes without a new version number.
3. **Clarity:** The `$`-prefix convention clearly separates DTCG reserved fields from user-defined group keys, making schemas easier to parse both for humans and for the agents that must fill them in.
4. **Embeddable as agent template:** JSON with placeholders is the most effective format for agent fill-in templates (see Pattern 3 in RESEARCH.md). DTCG's consistent structure makes the template predictable.
