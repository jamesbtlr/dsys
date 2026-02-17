# Analysis Findings Schema

## Overview

This document specifies the output contract for the dsys analysis agent. Every input image produces exactly one analysis findings document conforming to this schema. The findings document is a JSON object that the synthesizer agent reads to build the unified design system.

The machine-readable counterpart to this document is `skills/dsys/schemas/analysis-findings.schema.json` (JSON Schema 2020-12). Both must remain in sync — when this spec changes, the JSON Schema changes too.

**Key design principle:** Every field is always present. Fields that cannot be determined are set to `null`, not omitted. Absent keys cause inconsistent behavior in the synthesizer; explicit `null` is always safe.

---

## Field Reference

### Root Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image_type` | `"ui_screenshot" \| "visual_reference"` | Yes | Classification of the input image. `ui_screenshot` enables full extraction; `visual_reference` limits output to colors and aesthetic. |
| `source_path` | `string` | Yes | The file path or URL of the input image as provided by the orchestrator. |
| `confidence` | `"high" \| "medium" \| "low"` | Yes | Overall confidence in the extraction quality. See the rubric for classification criteria. |
| `colors` | `object` | Yes | Always present for both image types. Visual references produce a palette and null semantic assignments; UI screenshots produce the full semantic assignment map. |
| `typography` | `object \| null` | Yes | Typography extraction. `null` for `visual_reference`; required object for `ui_screenshot`. |
| `spacing` | `object \| null` | Yes | Spacing extraction. `null` for `visual_reference`; required object for `ui_screenshot`. |
| `shadows` | `array \| null` | Yes | Shadow tiers. `null` if no shadows are visible or image is a visual reference. |
| `border_radius` | `object \| null` | Yes | Corner radius tiers. `null` if not determinable or image is a visual reference. |
| `opacity_scale` | `array \| null` | Yes | Observed opacity values. `null` if no opacity effects are visible or image is a visual reference. |
| `aesthetic` | `object` | Yes | Always present for both image types. Captures vibe, personality, density, and tone. |

---

### Colors Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `colors.primitive_palette` | `array` | Yes | 3–10 distinct colors extracted from the image. Each entry is `{ hex, role, frequency }`. |
| `colors.primitive_palette[].hex` | `string` | Yes | Six-digit hex color with `#` prefix. Pattern: `^#[0-9A-Fa-f]{6}$`. |
| `colors.primitive_palette[].role` | enum | Yes | Visual role: `dominant`, `accent`, `surface`, `text`, `neutral`, `feedback`. |
| `colors.primitive_palette[].frequency` | enum | Yes | Relative use frequency: `primary`, `secondary`, `tertiary`. |
| `colors.semantic_assignments` | `object` | Yes | Maps the 21 semantic color keys to hex values or `null`. All 21 keys must be present. For `visual_reference` images, all values are `null`. |
| `colors.background_style` | enum | Yes | Whether the UI presents in `light`, `dark`, or `unknown` theme. |

#### Semantic Assignment Keys (all 21 required)

| Key | Semantic Role |
|-----|---------------|
| `action_primary` | Primary interactive color in light theme |
| `action_primary_dark` | Primary interactive color in dark theme |
| `action_secondary` | Secondary/ghost action color in light theme |
| `action_secondary_dark` | Secondary/ghost action color in dark theme |
| `action_destructive` | Destructive action color in light theme |
| `action_destructive_dark` | Destructive action color in dark theme |
| `surface_default` | Default page background in light theme |
| `surface_default_dark` | Default page background in dark theme |
| `surface_raised` | Elevated surface (cards, panels) in light theme |
| `surface_raised_dark` | Elevated surface in dark theme |
| `text_primary` | Primary text color in light theme |
| `text_primary_dark` | Primary text color in dark theme |
| `text_muted` | Subdued/secondary text in light theme |
| `text_muted_dark` | Subdued/secondary text in dark theme |
| `text_inverse` | Text on colored backgrounds |
| `border_default` | Standard border and divider color |
| `border_focus` | Focus ring color |
| `feedback_success` | Success state color |
| `feedback_error` | Error/danger state color |
| `feedback_warning` | Warning/caution state color |
| `feedback_info` | Informational state color |

---

### Typography Object (ui_screenshot only)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `typography.font_families` | `object` | Yes | Font family names by category. |
| `typography.font_families.sans` | `string \| null` | Yes | Primary sans-serif typeface, or `null` if not identifiable. |
| `typography.font_families.mono` | `string \| null` | Yes | Monospace typeface, or `null` if not present. |
| `typography.font_families.display` | `string \| null` | Yes | Distinct display/heading font if different from sans, or `null`. |
| `typography.type_scale` | `number[]` | Yes | Distinct font sizes observed, snapped to the standard scale. Sorted ascending. |
| `typography.weight_usage` | `object` | Yes | Maps usage contexts (string keys) to weight descriptions (string values). E.g., `{ "heading": "700 (Bold)", "body": "400 (Regular)" }`. |
| `typography.line_height_pattern` | enum | Yes | Overall line-height character: `tight`, `normal`, `relaxed`, `loose`. |

---

### Spacing Object (ui_screenshot only)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `spacing.base_unit` | `4 \| 8` | Yes | The foundational grid unit. `4` if the UI uses 4px increments; `8` if it skips to 8px multiples. |
| `spacing.scale` | `number[]` | Yes | All distinct spacing values observed, snapped to the 4px grid. Sorted ascending. |
| `spacing.density` | enum | Yes | Overall information density: `compact`, `comfortable`, `spacious`. |

---

### Shadows Array

Each entry in the `shadows` array represents one elevation tier observed in the UI.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `shadows[].elevation` | enum | Yes | Tier name: `sm`, `md`, `lg`, `xl`. |
| `shadows[].offset_x` | `number` | Yes | Horizontal shadow offset in pixels. |
| `shadows[].offset_y` | `number` | Yes | Vertical shadow offset in pixels. |
| `shadows[].blur` | `number` | Yes | Blur radius in pixels. |
| `shadows[].spread` | `number` | Yes | Spread radius in pixels. |
| `shadows[].color` | `string` | Yes | Shadow color as hex string (e.g., `#000000`). |
| `shadows[].opacity` | `number` | Yes | Shadow opacity, 0.0–1.0. |

---

### Border Radius Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `border_radius.sm` | `number \| null` | No | Radius for small elements (badges, chips, tags). |
| `border_radius.md` | `number \| null` | No | Radius for medium elements (buttons, inputs, small cards). |
| `border_radius.lg` | `number \| null` | No | Radius for large elements (modals, large panels). |
| `border_radius.full` | `boolean \| null` | No | `true` if pill/fully-rounded shapes are used prominently; `false` if not; `null` if uncertain. |

---

### Aesthetic Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `aesthetic.vibe_description` | `string` | Yes | 2–3 sentence description of the design's mood and character. Present tense. |
| `aesthetic.personality_tags` | `string[]` | Yes | 4–8 single-word descriptors. |
| `aesthetic.density` | enum | Yes | `compact`, `comfortable`, `spacious`. |
| `aesthetic.tone` | enum | Yes | `minimal`, `expressive`, `corporate`, `playful`, `bold`, `elegant`. |

---

## Image Type Conditional Fields

The `image_type` field determines which fields contain meaningful values:

### For `ui_screenshot`

All fields must contain extracted values. No top-level field may be absent (but individual values may be `null` if not observable in the image):

```
image_type:     "ui_screenshot"
colors:         full object (palette + semantic assignments + background_style)
typography:     full object (font_families + type_scale + weight_usage + line_height_pattern)
spacing:        full object (base_unit + scale + density)
shadows:        array of shadow tiers, or null if no shadows visible
border_radius:  object with sm/md/lg/full, or null if not determinable
opacity_scale:  array of opacity values, or null if no opacity effects visible
aesthetic:      full object (required)
```

### For `visual_reference`

Typography and spacing must be explicitly `null`. Colors produce only a primitive palette (semantic assignments are all `null`). Other structural fields are also `null`:

```
image_type:     "visual_reference"
colors:         object (primitive_palette populated; all semantic_assignments are null; background_style set)
typography:     null  ← REQUIRED to be null
spacing:        null  ← REQUIRED to be null
shadows:        null
border_radius:  null
opacity_scale:  null
aesthetic:      full object (required — this is the primary value of visual references)
```

The synthesizer uses the `image_type` field to route findings correctly. Setting `typography` and `spacing` to `null` for visual references (rather than omitting them) ensures the synthesizer can always access these fields without null-checks on key existence.

---

## Fill-In Template

The analyzer agent fills in the following template. All placeholder values must be replaced with actual extracted values. Fields marked `// null for visual_reference` must be set to `null` (the JSON literal, not a string) when `image_type` is `visual_reference`.

```json
{
  "image_type": "ui_screenshot | visual_reference",
  "source_path": "/path/to/image.png",
  "confidence": "high | medium | low",

  "colors": {
    "primitive_palette": [
      { "hex": "#RRGGBB", "role": "dominant | accent | surface | text | neutral | feedback", "frequency": "primary | secondary | tertiary" },
      { "hex": "#RRGGBB", "role": "dominant | accent | surface | text | neutral | feedback", "frequency": "primary | secondary | tertiary" }
    ],
    "semantic_assignments": {
      "action_primary":          "#RRGGBB or null",
      "action_primary_dark":     "#RRGGBB or null",
      "action_secondary":        "#RRGGBB or null",
      "action_secondary_dark":   "#RRGGBB or null",
      "action_destructive":      "#RRGGBB or null",
      "action_destructive_dark": "#RRGGBB or null",
      "surface_default":         "#RRGGBB or null",
      "surface_default_dark":    "#RRGGBB or null",
      "surface_raised":          "#RRGGBB or null",
      "surface_raised_dark":     "#RRGGBB or null",
      "text_primary":            "#RRGGBB or null",
      "text_primary_dark":       "#RRGGBB or null",
      "text_muted":              "#RRGGBB or null",
      "text_muted_dark":         "#RRGGBB or null",
      "text_inverse":            "#RRGGBB or null",
      "border_default":          "#RRGGBB or null",
      "border_focus":            "#RRGGBB or null",
      "feedback_success":        "#RRGGBB or null",
      "feedback_error":          "#RRGGBB or null",
      "feedback_warning":        "#RRGGBB or null",
      "feedback_info":           "#RRGGBB or null"
    },
    "background_style": "light | dark | unknown"
  },

  "typography": {
    "font_families": {
      "sans":    "FontName or null",
      "mono":    "FontName or null",
      "display": "FontName or null"
    },
    "type_scale": [12, 14, 16, 20, 24, 32],
    "weight_usage": {
      "heading":    "700 (Bold)",
      "subheading": "600 (SemiBold)",
      "body":       "400 (Regular)",
      "label":      "500 (Medium)",
      "caption":    "400 (Regular)"
    },
    "line_height_pattern": "tight | normal | relaxed | loose"
  },

  "spacing": {
    "base_unit": 4,
    "scale": [4, 8, 12, 16, 24, 32, 48],
    "density": "compact | comfortable | spacious"
  },

  "shadows": [
    {
      "elevation": "sm | md | lg | xl",
      "offset_x": 0,
      "offset_y": 2,
      "blur": 4,
      "spread": 0,
      "color": "#000000",
      "opacity": 0.08
    }
  ],

  "border_radius": {
    "sm": 4,
    "md": 8,
    "lg": 16,
    "full": false
  },

  "opacity_scale": [0.1, 0.25, 0.5, 0.75],

  "aesthetic": {
    "vibe_description": "2-3 sentence description of the overall design mood and aesthetic identity. Present tense. Be specific about what creates the impression.",
    "personality_tags": ["minimal", "trustworthy", "precise", "corporate"],
    "density": "compact | comfortable | spacious",
    "tone": "minimal | expressive | corporate | playful | bold | elegant"
  }
}
```

**For `visual_reference` images**, use this reduced template:

```json
{
  "image_type": "visual_reference",
  "source_path": "/path/to/image.png",
  "confidence": "high | medium | low",

  "colors": {
    "primitive_palette": [
      { "hex": "#RRGGBB", "role": "dominant | accent | surface | neutral", "frequency": "primary | secondary | tertiary" }
    ],
    "semantic_assignments": {
      "action_primary":          null,
      "action_primary_dark":     null,
      "action_secondary":        null,
      "action_secondary_dark":   null,
      "action_destructive":      null,
      "action_destructive_dark": null,
      "surface_default":         null,
      "surface_default_dark":    null,
      "surface_raised":          null,
      "surface_raised_dark":     null,
      "text_primary":            null,
      "text_primary_dark":       null,
      "text_muted":              null,
      "text_muted_dark":         null,
      "text_inverse":            null,
      "border_default":          null,
      "border_focus":            null,
      "feedback_success":        null,
      "feedback_error":          null,
      "feedback_warning":        null,
      "feedback_info":           null
    },
    "background_style": "light | dark | unknown"
  },

  "typography":    null,
  "spacing":       null,
  "shadows":       null,
  "border_radius": null,
  "opacity_scale": null,

  "aesthetic": {
    "vibe_description": "2-3 sentence description of the image's mood and aesthetic feel. Present tense.",
    "personality_tags": ["warm", "organic", "bold", "editorial"],
    "density": "compact | comfortable | spacious",
    "tone": "minimal | expressive | corporate | playful | bold | elegant"
  }
}
```

---

## Example Outputs

### Example 1: UI Screenshot (SaaS Dashboard)

```json
{
  "image_type": "ui_screenshot",
  "source_path": "benchmarks/linear-dashboard.png",
  "confidence": "high",

  "colors": {
    "primitive_palette": [
      { "hex": "#5E6AD2", "role": "accent", "frequency": "primary" },
      { "hex": "#F7F8FA", "role": "surface", "frequency": "primary" },
      { "hex": "#FFFFFF", "role": "surface", "frequency": "secondary" },
      { "hex": "#1A1A1A", "role": "text", "frequency": "primary" },
      { "hex": "#6B7280", "role": "neutral", "frequency": "secondary" },
      { "hex": "#E5E7EB", "role": "neutral", "frequency": "tertiary" },
      { "hex": "#10B981", "role": "feedback", "frequency": "tertiary" }
    ],
    "semantic_assignments": {
      "action_primary":          "#5E6AD2",
      "action_primary_dark":     "#818CF8",
      "action_secondary":        null,
      "action_secondary_dark":   null,
      "action_destructive":      "#EF4444",
      "action_destructive_dark": "#F87171",
      "surface_default":         "#F7F8FA",
      "surface_default_dark":    "#0F0F10",
      "surface_raised":          "#FFFFFF",
      "surface_raised_dark":     "#1C1C1E",
      "text_primary":            "#1A1A1A",
      "text_primary_dark":       "#F5F5F5",
      "text_muted":              "#6B7280",
      "text_muted_dark":         "#9CA3AF",
      "text_inverse":            "#FFFFFF",
      "border_default":          "#E5E7EB",
      "border_focus":            "#5E6AD2",
      "feedback_success":        "#10B981",
      "feedback_error":          "#EF4444",
      "feedback_warning":        "#F59E0B",
      "feedback_info":           "#3B82F6"
    },
    "background_style": "light"
  },

  "typography": {
    "font_families": {
      "sans":    "Inter",
      "mono":    "JetBrains Mono",
      "display": null
    },
    "type_scale": [11, 12, 13, 14, 16, 20, 24],
    "weight_usage": {
      "heading":    "600 (SemiBold)",
      "subheading": "500 (Medium)",
      "body":       "400 (Regular)",
      "label":      "500 (Medium)",
      "caption":    "400 (Regular)"
    },
    "line_height_pattern": "normal"
  },

  "spacing": {
    "base_unit": 4,
    "scale": [4, 8, 12, 16, 24, 32, 48],
    "density": "comfortable"
  },

  "shadows": [
    {
      "elevation": "sm",
      "offset_x": 0,
      "offset_y": 1,
      "blur": 3,
      "spread": 0,
      "color": "#000000",
      "opacity": 0.08
    },
    {
      "elevation": "md",
      "offset_x": 0,
      "offset_y": 4,
      "blur": 8,
      "spread": -2,
      "color": "#000000",
      "opacity": 0.12
    }
  ],

  "border_radius": {
    "sm": 4,
    "md": 6,
    "lg": 12,
    "full": false
  },

  "opacity_scale": [0.1, 0.5, 0.9],

  "aesthetic": {
    "vibe_description": "Clean and precise with a strong single-accent color system built on a near-white canvas. Typography is tight and purposeful with no decorative flourishes. The overall impression is of a tool built by engineers for engineers — functional, trustworthy, and efficient.",
    "personality_tags": ["minimal", "technical", "precise", "trustworthy", "corporate"],
    "density": "comfortable",
    "tone": "minimal"
  }
}
```

### Example 2: Visual Reference (Brand Mood Board)

```json
{
  "image_type": "visual_reference",
  "source_path": "benchmarks/brand-mood-forest.jpg",
  "confidence": "high",

  "colors": {
    "primitive_palette": [
      { "hex": "#2D4A3E", "role": "dominant", "frequency": "primary" },
      { "hex": "#8FBC8B", "role": "accent", "frequency": "secondary" },
      { "hex": "#F5F0E8", "role": "surface", "frequency": "secondary" },
      { "hex": "#C4A882", "role": "neutral", "frequency": "tertiary" },
      { "hex": "#1A2E28", "role": "dominant", "frequency": "tertiary" }
    ],
    "semantic_assignments": {
      "action_primary":          null,
      "action_primary_dark":     null,
      "action_secondary":        null,
      "action_secondary_dark":   null,
      "action_destructive":      null,
      "action_destructive_dark": null,
      "surface_default":         null,
      "surface_default_dark":    null,
      "surface_raised":          null,
      "surface_raised_dark":     null,
      "text_primary":            null,
      "text_primary_dark":       null,
      "text_muted":              null,
      "text_muted_dark":         null,
      "text_inverse":            null,
      "border_default":          null,
      "border_focus":            null,
      "feedback_success":        null,
      "feedback_error":          null,
      "feedback_warning":        null,
      "feedback_info":           null
    },
    "background_style": "dark"
  },

  "typography":    null,
  "spacing":       null,
  "shadows":       null,
  "border_radius": null,
  "opacity_scale": null,

  "aesthetic": {
    "vibe_description": "Deep forest greens dominate with warm sand and cream accents creating an organic, grounded palette. The tonal depth suggests sophistication without coldness — earthy but elevated. There is a sense of slowness and intentionality, evoking premium natural products or environmental brands.",
    "personality_tags": ["organic", "warm", "earthy", "elegant", "calm", "natural"],
    "density": "spacious",
    "tone": "elegant"
  }
}
```
