# Analysis Extraction Rubric

This rubric is embedded in the analyzer agent's prompt. Follow it exactly when analyzing any input image. It defines what to extract, how to classify the image, how to quantize values, and what level of confidence to assign.

---

## 1. Image Classification

Before extracting any values, classify the image as one of two types:

### `ui_screenshot`

The image contains recognizable UI elements, including any of:
- Buttons, toggles, checkboxes, radio buttons, sliders
- Text input fields, dropdowns, selects
- Navigation bars, sidebars, breadcrumbs, tabs
- Cards, panels, tables, data grids
- Modal dialogs, drawers, tooltips, popovers
- Content layouts with text blocks, headings, and visual hierarchy
- Dashboard widgets, charts within a UI shell
- Mobile app screens, web app interfaces

The image must show actual product interface, not a graphic depiction of a UI element in isolation (e.g., a marketing illustration of a laptop showing a blurry UI is **not** a ui_screenshot — classify it as `visual_reference`).

### `visual_reference`

Classify as `visual_reference` if the image is:
- A mood board photo, lifestyle image, or brand photography
- A product shot (physical product, not software)
- An illustration, abstract art, or graphic design piece
- A nature photo, texture, or pattern
- A marketing illustration depicting software UI (not an actual screenshot)
- A color swatch board or brand identity document
- Anything without recognizable, functional UI structure

**When ambiguous, classify as `visual_reference`.** It is better to conservatively decline to extract UI tokens from a non-UI image than to fabricate structural tokens from irrelevant visual content.

---

## 2. What to Extract — UI Screenshots

When `image_type` is `ui_screenshot`, extract all of the following:

### Colors

Extract the dominant color palette. Aim for 4–10 colors covering the visible UI.

**Semantic role inference:** Do not just sample pixels. Infer the design intent:
- What color appears on primary action buttons? → `action.primary`
- What is the main page/background surface? → `surface.default`
- What color is the primary body text? → `text.primary`
- Are there elevated surfaces (cards, panels above the page background)? → `surface.raised`
- Is there a recessed area (search input field, sidebar, code block)? → `surface.inset`
- Are there destructive actions (delete, remove, danger)? → `action.destructive`
- Are there success/error/warning states visible? → `feedback.success`, `feedback.error`, `feedback.warning`

**Color intent inference:** Do not round hex values to the nearest web-safe color. Instead, infer the designer's intended palette color. If a button appears to be approximately `#3B82F6` (Tailwind Blue 500), report `#3B82F6`. If a background is approximately `#F9FAFB` (Tailwind Gray 50), report `#F9FAFB`. Use your knowledge of common design system palettes to identify the likely intended value. Acknowledge ambiguity in your confidence rating.

**Theme inference:** Determine whether the screenshot shows a light-themed or dark-themed UI. For the detected theme, extract observed semantic color values. For the opposite theme, infer plausible equivalents based on common light/dark design patterns. Mark inferred opposite-theme values with awareness that they are inferred, not observed — this affects your overall confidence rating.

**Primitive palette:** Identify 4–10 distinct colors used in the UI. For each, record:
- `hex`: The exact hex value (inferred to nearest intended palette color)
- `role`: The visual role in the UI. One of: `dominant` (most visually prominent — usually the brand or primary action color), `accent` (secondary distinctive color), `surface` (background-level color), `text` (used for text rendering), `neutral` (grays used for borders, dividers, subtle backgrounds), `feedback` (success/error/warning/info colors)
- `frequency`: `primary` (used most), `secondary`, or `tertiary`

### Typography

Identify font usage across the UI:

**Font families:**
- `sans`: The primary sans-serif typeface used for body text and UI labels (e.g., "Inter", "Geist", "SF Pro Display", "Helvetica Neue"). If a system font stack is in use, report the likely system font for the platform (e.g., "system-ui" or "SF Pro"). If unidentifiable, set to `null`.
- `mono`: Monospace font used for code, numbers, or data (e.g., "JetBrains Mono", "Fira Code", "SF Mono"). If not present, set to `null`.
- `display`: A distinct display or heading font if different from the body sans (e.g., "Fraunces", "Playfair Display"). If the heading font matches the body font, set to `null`.

**Type scale:** List all distinct font sizes observed, snapped to the standard type scale (see Section 4: Quantization Rules). Report as a sorted array of numbers.

**Weight usage:** Describe which font weights appear for which purposes. Use descriptive keys and string values, e.g.:
```json
{
  "heading": "700 (Bold)",
  "subheading": "600 (SemiBold)",
  "body": "400 (Regular)",
  "label": "500 (Medium)",
  "caption": "400 (Regular)"
}
```

**Line-height pattern:** Classify the dominant line-height style as one of:
- `tight`: Dense, compact line spacing (common in data-dense UIs, dashboards)
- `normal`: Standard browser/OS default spacing (1.5 for body text)
- `relaxed`: Slightly open line spacing (1.6–1.75, common in editorial or documentation UIs)
- `loose`: Very open line spacing (> 1.75, common in marketing sites or onboarding flows)

### Spacing

Observe gaps between elements, padding inside components, and margins between sections. Snap all observed values to the 4px grid (see Section 4: Quantization Rules).

**Base unit:** Identify whether the UI is built on a 4px or 8px base grid.
- A 4px base produces values like 4, 8, 12, 16, 20, 24...
- An 8px base skips odd multiples and produces values like 8, 16, 24, 32, 48...
- If both appear, use `4`.

**Scale:** List all distinct spacing values observed, snapped to the grid. Report as a sorted array of numbers.

**Density:** Classify overall UI density as:
- `compact`: Tight padding, dense information, small gaps between elements (common in data tables, admin tools)
- `comfortable`: Balanced whitespace — neither too tight nor too generous (common in SaaS dashboards, productivity tools)
- `spacious`: Generous padding, ample whitespace, breathing room between elements (common in marketing sites, portfolios, consumer apps)

### Shadows

Extract any box shadows or drop shadows visible on elevated elements (cards, modals, dropdowns, tooltips). For each distinct shadow tier, record:

```json
{
  "elevation": "sm | md | lg | xl",
  "offset_x": 0,
  "offset_y": 2,
  "blur": 4,
  "spread": 0,
  "color": "#000000",
  "opacity": 0.1
}
```

**Elevation tiers:**
- `sm`: Subtle shadow for cards and small elevated elements
- `md`: Medium shadow for panels, popovers, and inline dialogs
- `lg`: Strong shadow for modals, drawers
- `xl`: Very strong shadow for overlay elements that float high above the page

Do **not** quantize shadow values. Preserve offset, blur, spread, and opacity as observed. If no shadows are visible, set `shadows` to `null`.

### Border Radius

Observe the corner rounding applied to interactive and container elements. Snap to standard values (see Section 4: Quantization Rules). Identify the radius applied at each size tier:

- `sm`: Small elements — badges, chips, tags, small pills, icon buttons
- `md`: Medium elements — input fields, buttons, dropdowns, small cards
- `lg`: Large elements — modal dialogs, full-page panels, large containers

Also record:
- `full`: Set to `true` if fully-rounded pill shapes appear prominently (e.g., 9999px radius tags or toggle buttons). Set to `false` if no fully-rounded elements appear. Set to `null` if uncertain.

If border radius is not determinable (very blurry or mostly square UI), set `border_radius` to `null`.

### Opacity

List any distinct opacity values used in the UI for overlays, disabled states, ghost elements, or decorative effects. Common values: 0.05, 0.1, 0.15, 0.2, 0.25, 0.5, 0.75, 0.9, 0.95. Report as a sorted array of numbers, e.g., `[0.1, 0.25, 0.5]`.

If no opacity effects are visible, set `opacity_scale` to `null`.

### Aesthetic

Write a description of the overall design aesthetic:

**Vibe description:** 2–3 sentences in present tense describing the overall mood, feel, and aesthetic identity of the UI. Be specific about what creates the impression (whitespace, typography weight, color palette contrast, roundness, etc.).

Example: *"Clean and professional with generous whitespace and a strong single-color accent system. The typography leans toward precision with tight tracking on headings. The overall effect is confident and trustworthy without being cold."*

**Personality tags:** 4–8 single-word descriptors that capture the aesthetic character. Choose from: minimal, bold, playful, corporate, elegant, technical, warm, cold, editorial, youthful, authoritative, friendly, luxurious, utilitarian, modern, classic, experimental, calm, energetic. Add unlisted words if they better capture the character.

**Density:** `compact`, `comfortable`, or `spacious` (should match the spacing density assessment).

**Tone:** One of: `minimal`, `expressive`, `corporate`, `playful`, `bold`, `elegant`.

---

## 3. What to Extract — Visual References

When `image_type` is `visual_reference`, extract only the following:

### Colors (Reduced)

Extract the dominant color palette: 3–7 colors that best represent the image's visual character.

For each color:
- `hex`: The observed hex value
- `role`: Based on area coverage. `dominant` (largest area), `accent` (most distinctive/vibrant), `surface` (background-level neutral), `neutral` (mid-range neutral), `feedback` (not applicable to visual references — omit)
- `frequency`: `primary`, `secondary`, or `tertiary`

Do **not** assign semantic UI roles (action.primary, etc.) to visual reference colors. Visual references influence the design system's aesthetic identity, not its functional token assignments directly.

**Semantic assignments:** For visual references, all semantic color assignments must be `null`. The synthesizer will use the aesthetic and palette data to influence UI token decisions — the analyzer does not make UI role inferences from non-UI images.

### Aesthetic

Same format as UI screenshots: vibe description, personality tags, density (of the image's visual composition), and tone.

**These are the primary value of a visual reference.** The aesthetic extraction captures what the image evokes so the synthesizer can incorporate that feeling into the overall design system identity.

### Everything Else — Must Be Null

For visual references:
- `typography`: `null`
- `spacing`: `null`
- `shadows`: `null`
- `border_radius`: `null`
- `opacity_scale`: `null`

Do not attempt to extract UI structural tokens from non-UI images. Setting these to `null` explicitly tells the synthesizer to ignore them for token generation from this source.

---

## 4. Quantization Rules

Apply these rules when converting raw observed values to reported values.

### Spacing — Snap to 4px Grid

Allowed values: **4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96, 128**

| Observed range | Snaps to |
|---------------|---------|
| < 2px | Ignore (too small to be meaningful) |
| 2–6px | 4 |
| 7–10px | 8 |
| 11–14px | 12 |
| 15–18px | 16 |
| 19–22px | 20 |
| 23–28px | 24 |
| 29–36px | 32 |
| 37–44px | 40 |
| 45–56px | 48 |
| 57–72px | 64 |
| 73–88px | 80 |
| 89–112px | 96 |
| 113–144px | 128 |
| > 144px | Round to nearest 16px increment |

### Type Scale — Snap to Standard Scale

Allowed values: **10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 24, 28, 32, 36, 40, 48, 56, 64, 72, 80, 96**

Map observed size to the nearest value in this list. For example:
- Observed 15px → 15
- Observed 17px → 17
- Observed 19px → 18 (closest)
- Observed 22px → 20 (closest)
- Observed 23px → 24 (closest)
- Observed 26px → 28 (closest)

### Border Radius — Snap to Standard Scale

Allowed values: **0, 2, 4, 6, 8, 12, 16, 24, 32, 9999**

| Observed range | Snaps to |
|---------------|---------|
| 0–1px | 0 |
| 2–3px | 2 |
| 4–5px | 4 |
| 6–7px | 6 |
| 8–10px | 8 |
| 11–14px | 12 |
| 15–20px | 16 |
| 21–28px | 24 |
| 29–40px | 32 |
| Fully round (pill) | 9999 |

### Shadows — No Quantization

Report shadow values as observed. Do not snap offset, blur, spread, or opacity values to a grid.

### Colors — No Hex Rounding

Do not round hex values. Instead, **infer intent**: if the pixel values suggest a commonly used palette color (Tailwind, Material, Apple HIG), report the likely intended hex. If you cannot infer the intent with confidence, report the observed hex value directly.

---

## 5. Confidence Assessment

Assign an overall confidence level based on image quality and clarity:

### `high`

- High-resolution screenshot (retina or standard screen resolution) with clearly visible UI elements
- Vivid visual reference with clearly discernible color palette and aesthetic character
- Most token values can be extracted with strong confidence

### `medium`

- Partially obscured UI (scroll cropping, watermark, heavy drop shadow eating the edges)
- Low resolution but still recognizable UI elements
- Small viewport showing only a portion of the interface
- Visual reference with mixed or subtle palette

### `low`

- Very small image with minimal visible detail
- Heavily blurry or compressed image
- Mostly decorative or abstract image where UI token extraction is speculative
- Findings should be treated as directional hints, not authoritative values

---

## 6. Semantic Color Assignment

When analyzing a `ui_screenshot`, assign hex values to all semantic color roles below. For any role where no color is visible or inferable, assign `null`. For the opposite theme (if screenshot is light, infer dark equivalents), mark your confidence appropriately.

### Full Semantic Taxonomy

| Semantic Key | Meaning | Light Theme | Dark Theme |
|---|---|---|---|
| `action_primary` | Primary interactive elements: main buttons, links, selected tabs | Observed value | Inferred |
| `action_primary_dark` | Primary action in dark theme | Inferred | Observed value |
| `action_secondary` | Secondary/ghost actions, outlined buttons | Observed or null | Inferred or null |
| `action_secondary_dark` | Secondary action in dark theme | Inferred or null | Observed or null |
| `action_destructive` | Destructive actions: delete, remove, danger | Observed or null | Inferred or null |
| `action_destructive_dark` | Destructive action in dark theme | Inferred or null | Observed or null |
| `surface_default` | Default page background | Observed value | Inferred |
| `surface_default_dark` | Default background in dark theme | Inferred | Observed value |
| `surface_raised` | Cards, panels elevated above the page | Observed or null | Inferred or null |
| `surface_raised_dark` | Raised surface in dark theme | Inferred or null | Observed or null |
| `text_primary` | Primary body text and headings | Observed value | Inferred |
| `text_primary_dark` | Primary text in dark theme | Inferred | Observed value |
| `text_muted` | Subdued text: captions, labels, placeholders | Observed or null | Inferred or null |
| `text_muted_dark` | Muted text in dark theme | Inferred or null | Observed or null |
| `text_inverse` | Text on colored backgrounds (e.g., button labels) | Observed or null | Inferred or null |
| `border_default` | Standard borders, dividers, outlines | Observed or null | Inferred or null |
| `border_focus` | Focus ring color (keyboard/accessibility focus) | Observed or null | Inferred or null |
| `feedback_success` | Success states (confirmation, completed, healthy) | Observed or null | Observed or null |
| `feedback_error` | Error states (failure, danger, invalid) | Observed or null | Observed or null |
| `feedback_warning` | Warning states (caution, pending, degraded) | Observed or null | Observed or null |
| `feedback_info` | Informational states (neutral notification, hint) | Observed or null | Observed or null |

**Rules:**
- "Observed value" = you saw this color used for this purpose in the screenshot. Report the inferred-intent hex.
- "Inferred" = you did not observe this in the screenshot but can reasonably infer the value based on common light/dark design patterns and the observed palette.
- "Observed or null" = report if visible, otherwise `null`.
- "Inferred or null" = infer if possible, otherwise `null`.
- Feedback colors often follow universal conventions: success → green family, error → red family, warning → amber/orange family, info → blue family. If these colors appear in the screenshot, assign them. If not observed, infer plausible values from the palette if a green/red/amber is present, otherwise `null`.
