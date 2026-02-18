# Phase 5: Rules and Style Guide - Research

**Researched:** 2026-02-18
**Domain:** Agent prompt authoring — CLAUDE.md rule generation, Markdown style guide generation from design-system.json
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Rules enforce both token usage AND component patterns (use DSButton not raw `<button>`, use `--color-primary` not `#1F3A1F`)
- Platform-specific rule sections: separate React/Tailwind rules and SwiftUI rules, not a unified block
- Include an aesthetic guard section alongside mechanical token rules — warns against choices that break the design vibe (e.g., "don't use neon accents in a luxury brand")
- Every rule must be yes/no answerable: "does this code violate this rule?"
- Only generate rules for platforms the user actually selected during generation
- Style guide format: Markdown (.md)
- Style guide lives at `.dsys/STYLE-GUIDE.md`
- Vibe narrative primary audience: AI (Claude) — optimized for giving future Claude sessions aesthetic context
- Vibe narrative length: paragraph (5-8 sentences)
- Vibe narrative includes concrete anti-examples ("this is NOT a playful SaaS brand, don't use rounded pill buttons")
- Vibe narrative uses abstract description only — no source benchmark names
- CLAUDE.md rules: append directly to the project's existing CLAUDE.md (or create it) for immediate enforcement
- Platform-conditional: only generate rules/docs for platforms the user actually selected in Phase 4
- Style guide: `.dsys/STYLE-GUIDE.md`

### Claude's Discretion

- Deviation handling strategy (hard prohibit vs. annotated override vs. soft warning) — Claude picks best practice
- Color swatch representation in Markdown (table structure, grouping by category)
- Typography detail level in style guide (scale table only vs. scale + usage guidance)
- Whether style guide includes component gallery or just tokens
- How to handle replacing existing design system rules in CLAUDE.md (section markers vs. append)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RULES-01 | Tool generates CLAUDE.md rules that enforce the design system in future coding sessions | Agent prompt pattern from Phase 3/4; section-marker strategy for CLAUDE.md management |
| RULES-02 | Rules are testable (a future Claude session can answer "does this code violate this rule?" yes/no) | Rule anatomy research: imperative + concrete token reference + binary violation test |
| RULES-03 | Rules reference token names (not values), include explicit prohibitions, and cover all token categories | Full semantic token taxonomy from design-system.json; CSS var names, Swift property names, Tailwind class names |
| DOCS-01 | Tool produces a human-readable style guide (color swatches, type specimens, spacing scale) | Markdown rendering techniques for color tables, type scale tables, spacing tables |
| DOCS-02 | Tool produces a vibe narrative describing the overall aesthetic in plain language | Source: `aesthetic.summary`, `aesthetic.personality_tags`, `aesthetic.tone`, `aesthetic.density` from design-system.json |
</phase_requirements>

---

## Summary

Phase 5 delivers one agent prompt (`skills/dsys/agents/rules.md`) that reads `design-system.json` and produces two output files: a CLAUDE.md rules block (appended to the project's existing CLAUDE.md using section markers) and `.dsys/STYLE-GUIDE.md`. The agent follows the exact same established anatomy as `react-generator.md` and `swiftui-generator.md`: YAML frontmatter, role section, input section, numbered steps, self-check, and return summary.

The domain is entirely prompt-engineering and Markdown generation — no new tools, libraries, or external dependencies are required. Everything the agent needs lives in the `design-system.json` it already reads. The rules agent is the simplest of the four agent types because its output format (Markdown prose) requires no algorithmic token resolution beyond what is already documented in the generator agents.

The two decisions left to Claude's discretion — how to handle CLAUDE.md section replacement, and how to represent color swatches in Markdown — both have clear best-practice answers. Section markers (HTML comments) are the standard approach for machine-managed sections in human-readable files. Markdown color swatches work best as tables with hex values shown alongside semantic names, grouped by the semantic category (action, surface, text, border, feedback).

**Primary recommendation:** One plan, one agent prompt (`rules.md`), validated by running it against the Luxora `design-system.json` and inspecting both output files for correctness.

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Markdown agent prompt | — | `skills/dsys/agents/rules.md` | Same pattern as all other dsys agents |
| `design-system.json` | — | Input to the agent | Already exists, fully specified |
| Read tool | — | Load design-system.json at runtime | Agent-only tool set (Read, Write) |
| Write tool | — | Write CLAUDE.md and STYLE-GUIDE.md | Agent-only tool set |

### Supporting

No additional libraries. This phase is pure Markdown generation from structured JSON.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Section markers in CLAUDE.md | Append-only (no replacement) | Append-only accumulates stale rules on re-run; section markers allow idempotent regeneration |
| Markdown color table | Unicode color blocks (e.g., `🟩`) | Unicode blocks are lossy (limited colors); Markdown table with hex column is complete and copy-pasteable |

---

## Architecture Patterns

### Recommended Project Structure

```
skills/dsys/agents/
  rules.md               # The new agent prompt (this phase's deliverable)

.dsys/                   # Agent writes to both of these:
  STYLE-GUIDE.md         # Human-readable style guide (DOCS-01)

Project root:
  CLAUDE.md              # Agent appends rules block here (RULES-01..03)
```

### Pattern 1: Section-Marker Strategy for CLAUDE.md

**What:** Wrap the generated rules block in HTML comment markers so a future re-run can locate and replace only the dsys-owned section.

**When to use:** Always. The user may have other content in CLAUDE.md that must be preserved.

**Algorithm:**
```
1. Attempt Read of CLAUDE.md
2. If file exists:
   a. Check if it contains <!-- dsys:rules:start --> marker
   b. If YES: Replace everything between <!-- dsys:rules:start --> and <!-- dsys:rules:end --> with new rules
   c. If NO: Append the entire block (markers included) to the end of the file
3. If file does not exist: Write the entire block as a new file
```

**Example wrapped block:**
```markdown
<!-- dsys:rules:start — generated by dsys, do not edit manually -->
## Design System Rules

...generated content...

<!-- dsys:rules:end -->
```

This is the standard approach used by tools like Renovate (which manages sections of config files), and is Claude's own convention for managing machine-generated sections in human-edited files.

### Pattern 2: Rule Anatomy for Yes/No Testability

**What:** Every rule must be answerable with yes/no to the question "does this code violate this rule?"

**Structure that achieves this:**
```
RULE: [IMPERATIVE VERB] [WHAT] [CONDITION/QUALIFIER]
VIOLATION: [concrete code example]
COMPLIANT: [concrete code example]
```

**Examples of yes/no testable rules:**

Good (binary, concrete):
```
- Use `--color-primary` (or `var(--ds-color-action-primary)`) for primary button backgrounds.
  NEVER hardcode `#1F3A1F` or any other hex value.
- Use the `DSButton` component for all interactive buttons.
  NEVER use raw HTML `<button>` elements in app code.
```

Bad (vague, not binary):
```
- Use design tokens where possible.
- Prefer design system colors.
```

The distinction: a bad rule requires judgment ("where possible," "prefer"). A good rule has a clear prohibition that can be checked mechanically.

### Pattern 3: Platform-Conditional Rule Sections

**What:** Rules are organized into platform-specific blocks so the file is not polluted with irrelevant rules.

**Recommended structure:**
```markdown
## Design System Rules

### Aesthetic Guard
[platform-agnostic vibe enforcement]

### Token Rules (all platforms)
[platform-agnostic: don't use raw hex values, use token names]

### React / Tailwind Rules
[only if react was in the selected platforms]

### SwiftUI Rules
[only if swiftui was in the selected platforms]
```

The agent must receive the `platforms` list from the orchestrator and only emit sections for selected platforms.

### Pattern 4: Vibe Narrative Structure

**What:** A 5-8 sentence paragraph that gives future Claude sessions aesthetic context.

**Sources in design-system.json:**
- `aesthetic.summary` — 2-3 sentence base narrative
- `aesthetic.personality_tags` — array of descriptors to weave in
- `aesthetic.tone` — tone label (minimal, expressive, bold, etc.)
- `aesthetic.density` — density label (compact, comfortable, spacious)
- `meta.aesthetic_summary` — alternate/additional summary from synthesis
- `meta.dominant_approach` — one-line label for the aesthetic direction

**Structure:**
1. Open with the dominant aesthetic identity (what this system IS)
2. Describe the palette character (colors and their emotional register)
3. Describe the typography character (typeface personality, weight usage)
4. Describe the spacing/density character
5. State explicit anti-examples (what this system is NOT — the critical AI guard)
6. Close with the intended user/context fit

**Anti-example importance:** Claude's default tendency is toward rounded, light, generic SaaS aesthetics. The anti-examples specifically counteract AI-generated visual defaults. For the Luxora system: "This is NOT a rounded, playful SaaS product. Do not use pill-shaped buttons, pastel backgrounds, or light sans-serif weights."

### Pattern 5: Color Swatch Table in Markdown

**What:** Render color swatches as a table with hex values, since Markdown cannot render colored blocks natively.

**Recommended approach — grouped semantic table:**
```markdown
### Colors

#### Action
| Role | Token (CSS) | Token (Swift) | Light | Dark |
|------|------------|---------------|-------|------|
| Primary | `--color-primary` | `.dsActionPrimary` | `#1F3A1F` | `#4ADE80` |
| Secondary | `--color-secondary` | `.dsActionSecondary` | `#E8EDE8` | `#2A3D2A` |
| Destructive | `--color-destructive` | `.dsActionDestructive` | `#EF4444` | `#F87171` |
```

**Why this structure:**
- Grouped by semantic category matches how developers think about using tokens
- Shows both platform names (CSS var name + Swift property name) — platform-conditional
- Shows both light and dark values in one row — avoids a separate dark-mode table
- Hex values are copy-pasteable for inspection

**Alternative considered:** A separate primitive palette table at the top, followed by semantic table. Both are useful. Since the style guide is for humans, show BOTH: primitives first (palette overview), then semantics (usage guide).

### Pattern 6: Typography Specimen in Markdown

**What:** Document the type scale with usage guidance, not just a table of values.

**Recommended approach:**
```markdown
### Typography

**Font family:** Satoshi (fallback: -apple-system, BlinkMacSystemFont, ...)

#### Type Scale

| Step | Size | Rem | Tailwind Class | Swift | Usage |
|------|------|-----|----------------|-------|-------|
| 5xl | 48px | 3rem | `text-5xl` | `.dsFont.size5xl` | Hero headlines |
| 4xl | 40px | 2.5rem | `text-4xl` | `.dsFont.size4xl` | Section titles |
| 3xl | 32px | 2rem | `text-3xl` | `.dsFont.size3xl` | Page headings |
| 2xl | 24px | 1.5rem | `text-2xl` | `.dsFont.size2xl` | Card titles |
| xl  | 20px | 1.25rem | `text-xl` | `.dsFont.sizeXl` | Subheadings |
| lg  | 16px | 1rem | `text-lg` | `.dsFont.sizeLg` | Body large |
| base| 14px | 0.875rem | `text-base` | `.dsFont.sizeBase` | Body default |
| sm  | 13px | 0.8125rem | `text-sm` | `.dsFont.sizeSm` | Captions |
| xs  | 12px | 0.75rem | `text-xs` | `.dsFont.sizeXs` | Labels |
```

The "Usage" column transforms a mechanical table into actionable guidance — that's the difference between DOCS-01 (reference) and something a developer will actually consult.

### Pattern 7: Spacing Scale in Markdown

**What:** Document the spacing scale with semantic aliases alongside numeric steps.

```markdown
### Spacing

**Base unit:** 4px grid

| Step | Value | Semantic Alias | Usage |
|------|-------|----------------|-------|
| 1 | 4px | — | Micro gap (icon to label) |
| 2 | 8px | `stack-gap` | Stack list items |
| 3 | 12px | `component-gap`, `input-padding` | Between components, input padding |
| 4 | 16px | `card-padding` | Card internal padding |
| 6 | 24px | `page-margin` | Page outer margin |
| 8 | 32px | `section-padding` | Section padding |
| 12 | 48px | — | Large section gaps |
| 16 | 64px | — | Hero spacing |
```

### Anti-Patterns to Avoid

- **Vague rules:** "Use design tokens when applicable" — not binary testable. Must be "NEVER use hex values directly; ALWAYS use token names."
- **Missing prohibitions:** Rules that only say what TO do miss the enforcement. The prohibition ("NEVER use raw `<button>`") is what makes rules enforceable in code review.
- **Single platform rules when both were selected:** If the user generated both React and SwiftUI, both sections must appear.
- **Referencing benchmark names in the vibe narrative:** The system should stand on its own without naming the specific inspiration sources.
- **Missing dark mode acknowledgment in React rules:** Developers must be told that dark mode is handled by CSS custom properties (not Tailwind's dark: modifier applied to hex).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Color swatch rendering | SVG/PNG generation | Markdown table with hex values | No tooling required; hex is copy-pasteable and sufficient for style guide use |
| Token lookup during rules generation | Custom resolver | Read from `design-system.json` directly | The token values are already fully resolved in the JSON; no re-resolution needed for rule text generation |
| CLAUDE.md parsing | Regex or AST | String search for section markers | Section markers are inserted by the agent on first run; subsequent runs can do simple string replacement |

---

## Common Pitfalls

### Pitfall 1: Rules Reference Values Instead of Token Names

**What goes wrong:** Agent generates rules like "don't use `#1F3A1F`" instead of "don't use hardcoded hex values."

**Why it happens:** The agent sees the hex value in design-system.json and incorporates it literally.

**How to avoid:** Rules must say "NEVER hardcode hex values; ALWAYS use `--color-primary` / `var(--ds-color-action-primary)`." The prohibition is on the pattern (raw hex), not on a specific value. RULES-03 explicitly requires this: "reference token names (not values)."

**Warning signs:** Any rule that contains a hex color `#xxxxxx` as a specific prohibition rather than as an example of the anti-pattern.

### Pitfall 2: Rules Are Too Abstract to Be Testable

**What goes wrong:** Rules say "use the design system" or "follow token conventions." These cannot be answered yes/no.

**Why it happens:** Writing mechanical rules for every specific token category is tedious; the agent takes shortcuts.

**How to avoid:** The agent prompt must include a complete list of rule categories to cover: colors (all 18 semantic roles), typography (font family, weight, size scale), spacing (scale steps and semantic aliases), border radius (sm/md/lg/full), shadows (sm/md/lg), and components (each DS-prefixed component with its prohibited raw alternative). For each category, the rule must name the token and forbid the raw alternative.

**Warning signs:** A rules section that takes fewer than 30-40 rules to cover everything is probably too sparse.

### Pitfall 3: Missing the Aesthetic Guard Section

**What goes wrong:** The rules block covers mechanical tokens but not aesthetic intent. A future Claude session can follow every token rule and still produce something that looks wrong for the brand — e.g., using valid tokens in combinations that violate the aesthetic (pill-shaped everything in a minimal luxury brand).

**Why it happens:** Mechanical rules are easier to write; aesthetic rules require judgment from the synthesizer output.

**How to avoid:** The agent prompt must include an explicit `### Aesthetic Guard` section that draws from `aesthetic.summary`, `aesthetic.personality_tags`, `aesthetic.tone`, and `meta.aesthetic_summary`. This section uses the same yes/no structure: "Does this UI use pill-shaped buttons universally? VIOLATION — this brand uses squared/slightly-rounded corners."

### Pitfall 4: CLAUDE.md Clobbers User Content on Re-run

**What goes wrong:** The agent appends the rules block each time, resulting in duplicate sections. Or it overwrites the entire CLAUDE.md, destroying user-written content.

**Why it happens:** Write-only approach doesn't check for existing content.

**How to avoid:** Section marker strategy (Pattern 1 above). The agent must:
1. Read CLAUDE.md if it exists
2. Search for `<!-- dsys:rules:start -->`
3. If found, replace the marked section; if not, append
4. If file doesn't exist, create it

**Warning signs:** Running the agent twice should produce identical CLAUDE.md content, not doubled content.

### Pitfall 5: Platform Rules Emitted for Non-Selected Platforms

**What goes wrong:** Agent always generates both React and SwiftUI rule sections regardless of which platforms were generated.

**Why it happens:** The agent prompt hardcodes both sections.

**How to avoid:** The orchestrator passes a `platforms` parameter (e.g., `["react"]` or `["react", "swiftui"]`). The agent must gate each platform section on presence in that list. If only React was generated, the SwiftUI section must be omitted.

### Pitfall 6: Vibe Narrative Sounds Generic

**What goes wrong:** Vibe narrative produces generic AI-aesthetic language ("clean and modern," "professional," "user-friendly").

**Why it happens:** The agent relies on generic descriptors without the concrete anti-examples that make the narrative actionable.

**How to avoid:** The vibe narrative MUST include:
1. At least two specific anti-examples (things this system is NOT)
2. Concrete aesthetic descriptors from `personality_tags` (not rephrased as generic adjectives)
3. At least one specific reference to the typography character (typeface name and its emotional register)

---

## Code Examples

Verified patterns from the established codebase:

### CLAUDE.md Section Marker Block

```markdown
<!-- dsys:rules:start — generated by dsys on 2026-02-18, do not edit manually -->

## Design System Rules

This project uses the Luxora design system generated by dsys. All code must conform to these rules.

### Aesthetic Guard
...

### Token Rules

**Colors — React/Tailwind**
- Use semantic Tailwind class names (`bg-primary`, `text-text-muted`) for all color styling.
- NEVER hardcode hex values (e.g., `#1F3A1F`). Use token names.
- NEVER use Tailwind default color utilities (`gray-100`, `blue-500`, `red-400`, etc.).
  Does this code contain `gray-`, `blue-`, `red-`, `slate-` etc. class names? VIOLATION.

...

<!-- dsys:rules:end -->
```

### Agent Frontmatter (consistent with prior agents)

```yaml
---
name: dsys-rules-agent
description: Reads design-system.json and writes CLAUDE.md enforcement rules and STYLE-GUIDE.md
tools: Read, Write
---
```

### React Rule Pattern (yes/no testable)

```markdown
**Component Usage**
- Use `<DSButton>` for all buttons. NEVER use raw `<button>` elements in app code.
  Does the code contain `<button` (not `<DSButton`)? VIOLATION.
- Use `<DSInput>` for all text inputs. NEVER use raw `<input>` elements.
  Does the code contain `<input` (not `<DSInput`)? VIOLATION.

**Color Tokens**
- Use `bg-primary` for primary action backgrounds. NEVER use `bg-[#1F3A1F]` or any arbitrary value.
  Does the code contain `bg-[#` or inline style color? VIOLATION.
- Use `text-text` for primary text color. NEVER use `text-[#...]` or hardcoded colors.

**Dark Mode**
- Dark mode is handled by CSS custom properties in tokens.css. NEVER use `dark:bg-[#...]` or `dark:text-[#...]`.
  Does the code contain `dark:bg-[` or `dark:text-[`? VIOLATION.
```

### SwiftUI Rule Pattern (yes/no testable)

```markdown
**Color Tokens**
- Use `Color.dsActionPrimary` for primary action color. NEVER use `Color(hex:)` or hardcoded RGB.
  Does the code contain `Color(hex:` or `Color(red:green:blue:`? VIOLATION.
- Use `Color.dsTextPrimary` for primary text. NEVER use `Color.black` or `Color.primary`.
  Does the code contain `Color.black` or `Color.primary` for text? VIOLATION.

**Component Usage**
- Use `DSButton` for all interactive buttons. NEVER use SwiftUI's built-in `Button { }` View directly.
  Does the code contain `Button {` outside of `DSButton.swift`? VIOLATION.
- Use `DSInput` for text fields. NEVER use `TextField` directly.
  Does the code contain `TextField(` outside of `DSInput.swift`? VIOLATION.

**Spacing**
- Use `DSSpacing` instance properties for all spacing values. NEVER hardcode numeric spacing values.
  Does the code contain `.padding(16)` or `.frame(height: 48)` with a hardcoded value? VIOLATION.
```

### Aesthetic Guard Pattern

```markdown
### Aesthetic Guard

This design system has a specific aesthetic identity. The following rules prevent AI-generated defaults from corrupting the visual character.

**This system is:** Bold, modern, premium retail. Deep forest-green brand identity. Editorial typography with tight leading. Restrained palette (forest green, near-white, vivid pink accent only).

**This system is NOT:**
- A playful SaaS product. Do NOT use pill-shaped buttons universally (`rounded-full` on buttons is a violation).
- A corporate blue enterprise app. Do NOT introduce blue, slate, or neutral gray as accent colors.
- A pastel/soft aesthetic. Do NOT use muted, desaturated, or low-contrast color combinations.
- A rounded, friendly consumer app. Headings use tight leading and bold weights — do NOT use `font-normal` on headings.

Does the code introduce colors outside the design system palette (forest greens, sage, near-white, pink accents, standard red/amber/green for feedback)? VIOLATION.
Does the code use rounded-full on non-pill UI elements (buttons, cards, inputs)? VIOLATION.
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CLAUDE.md rules as append-only | Section markers for idempotent re-generation | This phase | Enables re-running the agent without duplicating rules |
| Generic aesthetic description | Concrete anti-examples for AI guard | This phase | Prevents Claude's default aesthetic from overriding the design system |

---

## Implementation Plan Shape

This phase needs **two plans**:

**Plan 05-01:** Write the `rules.md` agent prompt. This is the sole deliverable for the rules functionality. The agent must embed all rule templates, the section-marker algorithm, the vibe narrative structure, and the color/typography/spacing table templates for the style guide.

**Plan 05-02:** Validate by running the agent against the Luxora `design-system.json`. Inspect both output files for correctness. This matches the validation approach used in every prior phase.

Both plans are sequential (01 must precede 02). No parallelism needed — there is only one agent to write.

### Agent Prompt Structure

The `rules.md` agent follows the same anatomy as all prior agents:

```
1. Frontmatter (name, description, tools: Read, Write)
2. Role section
3. Input section (design_system_path, output_dir, claude_md_path, platforms)
4. Step 1: Load and validate design-system.json
5. Step 2: Resolve token display values (not full hex resolution — just extract token names and descriptions)
6. Step 3: Load existing CLAUDE.md (section-marker check)
7. Step 4: Build the rules block content
   a. Aesthetic guard section
   b. Token rules (all platforms — token names, not values)
   c. React/Tailwind rules (if "react" in platforms)
   d. SwiftUI rules (if "swiftui" in platforms)
   e. Component usage rules (per platform)
8. Step 5: Write/update CLAUDE.md (section marker strategy)
9. Step 6: Build the STYLE-GUIDE.md content
   a. Vibe narrative
   b. Color table (primitives + semantics)
   c. Typography table + usage guidance
   d. Spacing scale table
   e. Border radius table
   f. Shadow reference
10. Step 7: Write .dsys/STYLE-GUIDE.md
11. Step 8: Self-check
12. Step 9: Return summary
```

### Token Name Reference Table (for the agent to embed)

The agent needs to know the token name mappings to generate correct rule text:

**React/Tailwind (CSS var → Tailwind class):**
- `--color-primary` → `bg-primary`, `text-primary`, `border-primary`
- `--color-secondary` → `bg-secondary`, etc.
- `--color-destructive` → `bg-destructive`
- `--color-surface` → `bg-surface`
- `--color-surface-raised` → `bg-surface-raised`
- `--color-surface-overlay` → `bg-surface-overlay`
- `--color-surface-inset` → `bg-surface-inset`
- `--color-text` → `text-text`
- `--color-text-secondary` → `text-text-secondary`
- `--color-text-muted` → `text-text-muted`
- `--color-inverse` → `text-inverse`
- `--color-link` → `text-link`
- `--color-border` → `border-border`
- `--color-focus` → `ring-focus` (focus ring)
- `--color-success` → `bg-success`, `text-success`, `border-success`
- `--color-error` → `bg-error`, `text-error`, `border-error`
- `--color-warning` → `bg-warning`, `text-warning`, `border-warning`
- `--color-info` → `bg-info`, `text-info`, `border-info`

**SwiftUI (Swift property names, confirmed from swiftui-generator.md):**
- `Color.dsActionPrimary`
- `Color.dsActionSecondary`
- `Color.dsActionDestructive`
- `Color.dsSurfaceDefault`
- `Color.dsSurfaceRaised`
- `Color.dsSurfaceOverlay`
- `Color.dsSurfaceInset`
- `Color.dsTextPrimary`
- `Color.dsTextSecondary`
- `Color.dsTextMuted`
- `Color.dsTextInverse`
- `Color.dsTextLink`
- `Color.dsBorderDefault`
- `Color.dsBorderFocus`
- `Color.dsFeedbackSuccess`
- `Color.dsFeedbackError`
- `Color.dsFeedbackWarning`
- `Color.dsFeedbackInfo`

SwiftUI spacing: `DSSpacing().componentGap`, `.cardPadding`, `.pageMargin`, `.sectionPadding`, `.inputPadding`, `.stackGap`

SwiftUI radius: `DSRadius.sm`, `.md`, `.lg`, `.full` (CGFloat constants)

SwiftUI components: `DSButton`, `DSCard`, `DSInput`, `DSBadge`, `DSHeading`, `DSText`

React components (exported from `index.ts`): `Button`, `Card`, `Input`, `Badge`, `Heading`, `Text`

---

## Open Questions

1. **Component rule precision for React**
   - What we know: Components are exported as `Button`, `Card`, etc. (not `DSButton`)
   - What's unclear: Should the rule say "never use `<button>`" or "always use `<Button>` from the design system"? The latter requires knowing the import path.
   - Recommendation: Include the import path in the rule: "Always import from `@/design-system` or the project's configured alias. Never use raw HTML interactive elements."

2. **Deviation handling strategy (left to Claude's discretion)**
   - What we know: User left this open; options are hard prohibit, annotated override, or soft warning
   - Recommendation: **Hard prohibit for mechanical rules** (tokens, component usage), **soft warning (comment) for aesthetic guard rules**. Rationale: Token rules have zero valid exceptions in generated code. Aesthetic violations require human judgment. Use "VIOLATION" for mechanical rules and "WARNING — verify with design team" for aesthetic guard.

3. **Whether style guide includes component gallery**
   - What we know: User left this to Claude's discretion
   - Recommendation: **Include a minimal component API reference** (props table) but not rendered examples (impossible in Markdown). A table listing each component, its variants, and key props is more useful than rendered screenshots. Rendered screenshots would require an image that doesn't exist yet.

---

## Sources

### Primary (HIGH confidence)

- `/Users/james/Code/dsys-tool/skills/dsys/agents/react-generator.md` — established agent anatomy pattern for this phase
- `/Users/james/Code/dsys-tool/skills/dsys/agents/swiftui-generator.md` — Swift token names (dsActionPrimary, etc.)
- `/Users/james/Code/dsys-tool/.dsys/design-system.json` — actual Luxora design system data for validation
- `/Users/james/Code/dsys-tool/skills/dsys/references/token-schema.md` — complete token taxonomy
- `/Users/james/Code/dsys-tool/.planning/phases/05-rules-and-style-guide/05-CONTEXT.md` — locked user decisions

### Secondary (MEDIUM confidence)

- Phase 3/4 PLAN files — task structure patterns (objective, tasks, verify, done format)
- Architecture research (`ARCHITECTURE.md`) — "Rules agent separate from generators; produces unified platform-agnostic enforcement doc"

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new tools; pure Markdown generation following established agent pattern
- Architecture: HIGH — section marker strategy is the obvious idempotent solution; agent anatomy is identical to prior phases
- Pitfalls: HIGH — all pitfalls derived from direct reading of requirements + prior agent implementations; no speculation

**Research date:** 2026-02-18
**Valid until:** Stable — this phase has no external dependencies that can change
