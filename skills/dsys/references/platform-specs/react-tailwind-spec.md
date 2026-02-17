# React/Tailwind Platform Output Specification

**Version:** 1.0
**Target:** React 18+ with Tailwind CSS v4
**Minimum Node:** 22.0.0 (required by Style Dictionary v5)

---

## 1. Overview

This spec defines every file the React/Tailwind generator must produce when given a validated `design-system.json`. The generator reads `.dsys/design-system.json` and writes files into the target project.

The generator must produce files that a developer can copy directly into a Tailwind v4 project and use immediately — no manual editing required. Every file in this manifest is required; none are optional.

**Input:** `.dsys/design-system.json` (validated against `design-system.schema.json`)
**Output root:** configurable, defaults to `./design-system/`

---

## 2. File Manifest

| File | Purpose | Required |
|------|---------|----------|
| `tokens.json` | W3C DTCG source tokens | Yes |
| `tokens.css` | CSS custom properties (light + dark) | Yes |
| `theme.css` | Tailwind v4 `@theme` block | Yes |
| `components/Button.tsx` | Button component template | Yes |
| `components/Card.tsx` | Card component template | Yes |
| `components/Input.tsx` | Input component template | Yes |
| `components/Badge.tsx` | Badge component template | Yes |
| `components/Heading.tsx` | Heading component template | Yes |
| `components/Text.tsx` | Text component template | Yes |

All 9 files must be present for the generator output to be considered complete.

---

## 3. `tokens.json` Spec

**Format:** W3C DTCG Format Module 2025.10

This is a direct transformation of `design-system.json` tokens into the DTCG file structure. It is the source of truth for Style Dictionary (if the user wants to run `npx style-dictionary build` later to generate additional platform outputs).

The file must contain both the primitive and semantic layers:

- **Primitive layer:** Raw hex values for every color in the palette, raw spacing values, raw font sizes. Tokens at this layer are never referenced directly in components.
- **Semantic layer:** Role-based tokens that reference primitives using `{group.token}` syntax. Semantic color tokens use the `{ "light": "...", "dark": "..." }` pattern for theme-aware values.

**Style Dictionary v5 note:** The `{ light, dark }` `$value` pattern requires a custom `preprocess` step in the Style Dictionary config to expand theme-aware values into mode-specific token files. The generator must include a `style-dictionary.config.json` alongside `tokens.json` if the user is expected to run Style Dictionary directly.

**Example structure:**

```json
{
  "$schema": "https://json.schemastore.org/base.json",
  "primitive": {
    "color": {
      "$type": "color",
      "blue": {
        "500": { "$value": "#3B82F6", "$description": "Base blue 500" },
        "700": { "$value": "#1D4ED8", "$description": "Base blue 700" }
      },
      "gray": {
        "50":  { "$value": "#F9FAFB", "$description": "Base gray 50" },
        "900": { "$value": "#111827", "$description": "Base gray 900" }
      }
    },
    "spacing": {
      "$type": "dimension",
      "1": { "$value": "4px" },
      "2": { "$value": "8px" },
      "3": { "$value": "12px" },
      "4": { "$value": "16px" },
      "6": { "$value": "24px" },
      "8": { "$value": "32px" }
    }
  },
  "semantic": {
    "color": {
      "$type": "color",
      "action": {
        "primary": {
          "$value": { "light": "{primitive.color.blue.500}", "dark": "{primitive.color.blue.700}" },
          "$description": "Primary interactive color for buttons, links, selected states"
        },
        "secondary": {
          "$value": { "light": "{primitive.color.gray.50}", "dark": "{primitive.color.gray.900}" },
          "$description": "Secondary/ghost interactive elements"
        },
        "destructive": {
          "$value": { "light": "#EF4444", "dark": "#DC2626" },
          "$description": "Danger actions: delete, remove, irreversible operations"
        }
      },
      "surface": {
        "default": {
          "$value": { "light": "{primitive.color.gray.50}", "dark": "{primitive.color.gray.900}" },
          "$description": "Default page background surface"
        },
        "raised": {
          "$value": { "light": "#FFFFFF", "dark": "#1F2937" },
          "$description": "Card/elevated surface above the default background"
        }
      },
      "text": {
        "primary": {
          "$value": { "light": "{primitive.color.gray.900}", "dark": "{primitive.color.gray.50}" },
          "$description": "Primary body text. Use for headings and paragraph copy."
        },
        "muted": {
          "$value": { "light": "#6B7280", "dark": "#9CA3AF" },
          "$description": "Secondary/subdued text. Labels, captions, supporting copy."
        },
        "inverse": {
          "$value": { "light": "#FFFFFF", "dark": "#FFFFFF" },
          "$description": "Text on colored backgrounds (e.g. button labels on primary background)"
        }
      },
      "border": {
        "default": {
          "$value": { "light": "#E5E7EB", "dark": "#374151" },
          "$description": "Standard borders and dividers"
        },
        "focus": {
          "$value": { "light": "{primitive.color.blue.500}", "dark": "{primitive.color.blue.700}" },
          "$description": "Focus ring color for keyboard navigation"
        }
      },
      "feedback": {
        "success": { "$value": "#10B981", "$description": "Success states and positive feedback" },
        "error":   { "$value": "#EF4444", "$description": "Error states and destructive feedback" },
        "warning": { "$value": "#F59E0B", "$description": "Warning states requiring attention" },
        "info":    { "$value": "#3B82F6", "$description": "Informational states" }
      }
    }
  }
}
```

---

## 4. `tokens.css` Spec

**Purpose:** CSS custom properties file providing runtime-switchable design tokens for both light and dark themes.

The file must contain:

1. A `:root` block with all **light-theme** CSS variables using the `--ds-` prefix
2. A `@media (prefers-color-scheme: dark) { :root { ... } }` block with all **dark-theme** CSS variables (for automatic OS-level dark mode)
3. A `.dark` class selector block with the same dark-theme variables (for manual class-based theme switching, e.g. `<html class="dark">`)

**Variable naming:** All variables use the `--ds-` prefix to namespace them away from Tailwind's generated variables.

**Required variable groups:**

- **Color:** `--ds-color-{group}-{role}` (e.g., `--ds-color-action-primary`, `--ds-color-text-muted`)
- **Typography — font family:** `--ds-font-family-sans`, `--ds-font-family-mono`, `--ds-font-family-display` (value is `null` or a quoted font stack)
- **Typography — font size:** `--ds-font-size-xs`, `--ds-font-size-sm`, `--ds-font-size-base`, `--ds-font-size-lg`, `--ds-font-size-xl`, `--ds-font-size-2xl`
- **Spacing:** `--ds-spacing-1` through `--ds-spacing-16` (values in px, matching the 4px grid)
- **Border radius:** `--ds-radius-sm`, `--ds-radius-md`, `--ds-radius-lg`, `--ds-radius-full`
- **Shadow:** `--ds-shadow-sm`, `--ds-shadow-md`, `--ds-shadow-lg`

**Complete example:**

```css
/* tokens.css — generated by dsys */
/* Do not edit manually — re-run dsys to regenerate */

:root {
  /* ── Colors: Action ── */
  --ds-color-action-primary:     #3B82F6;
  --ds-color-action-secondary:   #F9FAFB;
  --ds-color-action-destructive: #EF4444;

  /* ── Colors: Surface ── */
  --ds-color-surface-default:    #F9FAFB;
  --ds-color-surface-raised:     #FFFFFF;
  --ds-color-surface-overlay:    rgba(0, 0, 0, 0.4);
  --ds-color-surface-inset:      #F3F4F6;

  /* ── Colors: Text ── */
  --ds-color-text-primary:       #111827;
  --ds-color-text-secondary:     #374151;
  --ds-color-text-muted:         #6B7280;
  --ds-color-text-inverse:       #FFFFFF;
  --ds-color-text-link:          #3B82F6;

  /* ── Colors: Border ── */
  --ds-color-border-default:     #E5E7EB;
  --ds-color-border-focus:       #3B82F6;

  /* ── Colors: Feedback ── */
  --ds-color-feedback-success:   #10B981;
  --ds-color-feedback-error:     #EF4444;
  --ds-color-feedback-warning:   #F59E0B;
  --ds-color-feedback-info:      #3B82F6;

  /* ── Typography ── */
  --ds-font-family-sans:         "Inter", system-ui, -apple-system, sans-serif;
  --ds-font-family-mono:         "JetBrains Mono", "Fira Code", monospace;
  --ds-font-family-display:      "Inter", system-ui, sans-serif;

  --ds-font-size-xs:   0.75rem;   /* 12px */
  --ds-font-size-sm:   0.875rem;  /* 14px */
  --ds-font-size-base: 1rem;      /* 16px */
  --ds-font-size-lg:   1.125rem;  /* 18px */
  --ds-font-size-xl:   1.25rem;   /* 20px */
  --ds-font-size-2xl:  1.5rem;    /* 24px */
  --ds-font-size-3xl:  1.875rem;  /* 30px */
  --ds-font-size-4xl:  2.25rem;   /* 36px */

  /* ── Spacing (4px grid) ── */
  --ds-spacing-1:   4px;
  --ds-spacing-2:   8px;
  --ds-spacing-3:   12px;
  --ds-spacing-4:   16px;
  --ds-spacing-5:   20px;
  --ds-spacing-6:   24px;
  --ds-spacing-8:   32px;
  --ds-spacing-10:  40px;
  --ds-spacing-12:  48px;
  --ds-spacing-16:  64px;

  /* ── Border Radius ── */
  --ds-radius-sm:   4px;
  --ds-radius-md:   8px;
  --ds-radius-lg:   12px;
  --ds-radius-full: 9999px;

  /* ── Shadows ── */
  --ds-shadow-sm:  0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --ds-shadow-md:  0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --ds-shadow-lg:  0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

/* ── Dark mode: OS-level (automatic) ── */
@media (prefers-color-scheme: dark) {
  :root {
    --ds-color-action-primary:     #1D4ED8;
    --ds-color-action-secondary:   #111827;
    --ds-color-action-destructive: #DC2626;

    --ds-color-surface-default:    #111827;
    --ds-color-surface-raised:     #1F2937;
    --ds-color-surface-overlay:    rgba(0, 0, 0, 0.6);
    --ds-color-surface-inset:      #0F172A;

    --ds-color-text-primary:       #F9FAFB;
    --ds-color-text-secondary:     #E5E7EB;
    --ds-color-text-muted:         #9CA3AF;
    --ds-color-text-inverse:       #FFFFFF;
    --ds-color-text-link:          #60A5FA;

    --ds-color-border-default:     #374151;
    --ds-color-border-focus:       #60A5FA;
  }
}

/* ── Dark mode: manual class-based (for <html class="dark">) ── */
.dark {
  --ds-color-action-primary:     #1D4ED8;
  --ds-color-action-secondary:   #111827;
  --ds-color-action-destructive: #DC2626;

  --ds-color-surface-default:    #111827;
  --ds-color-surface-raised:     #1F2937;
  --ds-color-surface-overlay:    rgba(0, 0, 0, 0.6);
  --ds-color-surface-inset:      #0F172A;

  --ds-color-text-primary:       #F9FAFB;
  --ds-color-text-secondary:     #E5E7EB;
  --ds-color-text-muted:         #9CA3AF;
  --ds-color-text-inverse:       #FFFFFF;
  --ds-color-text-link:          #60A5FA;

  --ds-color-border-default:     #374151;
  --ds-color-border-focus:       #60A5FA;
}
```

---

## 5. `theme.css` Spec

**Purpose:** Tailwind v4 theme configuration. This file replaces `tailwind.config.js` — in Tailwind v4, theme configuration is done in CSS using `@theme`.

**Critical requirements:**

1. `@import "tailwindcss";` must be the **first line**
2. The `@theme { ... }` block must have `--color-*: initial;` as its **first declaration** — this resets all Tailwind default colors. Without this reset, the full Tailwind default palette (slate, gray, zinc, red, orange, etc.) coexists with the design system palette, which defeats the purpose of token enforcement
3. Tailwind `@theme` variables reference `--ds-` CSS custom properties for runtime theme-switching. Hardcoding hex values in `@theme` would break dark mode

**Complete example:**

```css
/* theme.css — generated by dsys */
/* Do not edit manually — re-run dsys to regenerate */

@import "tailwindcss";

@theme {
  /* ── Reset all default Tailwind colors — REQUIRED for design system enforcement ── */
  --color-*: initial;

  /* ── Semantic color tokens ── */
  --color-primary:          var(--ds-color-action-primary);
  --color-primary-hover:    color-mix(in srgb, var(--ds-color-action-primary) 90%, black);
  --color-secondary:        var(--ds-color-action-secondary);
  --color-destructive:      var(--ds-color-action-destructive);

  --color-surface:          var(--ds-color-surface-default);
  --color-surface-raised:   var(--ds-color-surface-raised);
  --color-surface-overlay:  var(--ds-color-surface-overlay);
  --color-surface-inset:    var(--ds-color-surface-inset);

  --color-text:             var(--ds-color-text-primary);
  --color-text-secondary:   var(--ds-color-text-secondary);
  --color-text-muted:       var(--ds-color-text-muted);
  --color-inverse:          var(--ds-color-text-inverse);
  --color-link:             var(--ds-color-text-link);

  --color-border:           var(--ds-color-border-default);
  --color-focus:            var(--ds-color-border-focus);

  --color-success:          var(--ds-color-feedback-success);
  --color-error:            var(--ds-color-feedback-error);
  --color-warning:          var(--ds-color-feedback-warning);
  --color-info:             var(--ds-color-feedback-info);

  /* ── Typography ── */
  --font-sans:    var(--ds-font-family-sans);
  --font-mono:    var(--ds-font-family-mono);
  --font-display: var(--ds-font-family-display);

  /* ── Type scale ── */
  --text-xs:   var(--ds-font-size-xs);
  --text-sm:   var(--ds-font-size-sm);
  --text-base: var(--ds-font-size-base);
  --text-lg:   var(--ds-font-size-lg);
  --text-xl:   var(--ds-font-size-xl);
  --text-2xl:  var(--ds-font-size-2xl);
  --text-3xl:  var(--ds-font-size-3xl);
  --text-4xl:  var(--ds-font-size-4xl);

  /* ── Spacing — single value drives all spacing utilities ── */
  /* Tailwind v4 generates p-1 = 4px, p-2 = 8px, p-4 = 16px, etc. */
  --spacing: 4px;

  /* ── Border radius ── */
  --radius-sm:   var(--ds-radius-sm);
  --radius-md:   var(--ds-radius-md);
  --radius-lg:   var(--ds-radius-lg);
  --radius-full: var(--ds-radius-full);

  /* ── Shadows ── */
  --shadow-sm:  var(--ds-shadow-sm);
  --shadow-md:  var(--ds-shadow-md);
  --shadow-lg:  var(--ds-shadow-lg);
}
```

**Usage in a Tailwind v4 project:** Replace (or import from) the project's main CSS entry point. The `tokens.css` file must also be imported so the `--ds-*` custom properties are available:

```css
/* main.css */
@import "./tokens.css";
@import "./theme.css";
```

---

## 6. Component Template Spec

All component files must:

- Be TypeScript (`.tsx`)
- Use `React.forwardRef` where the component wraps a native DOM element (Button, Input)
- Accept a `className` prop for composition (merged as trailing classes)
- Use only Tailwind utility classes that reference design system tokens (e.g., `bg-primary`, `text-text-muted`) — **never raw color values** (`bg-blue-500`, `text-[#111827]`)
- Use only design system spacing utilities (`p-4`, `gap-2`) — never raw pixel values (`p-[13px]`)
- Include a `displayName` assignment after the component declaration for React DevTools

### Button (`components/Button.tsx`)

Purpose: Primary interactive action element. Three variants (primary, secondary, destructive) × three sizes (sm, md, lg).

```tsx
// Button.tsx — generated by dsys
// Do not edit manually — re-run dsys to regenerate

import { forwardRef } from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "destructive";
  size?: "sm" | "md" | "lg";
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", size = "md", className, children, ...props }, ref) => {
    const variants = {
      primary:     "bg-primary text-inverse hover:bg-primary/90 focus-visible:outline-focus",
      secondary:   "bg-surface-raised text-text border border-border hover:bg-surface-inset focus-visible:outline-focus",
      destructive: "bg-destructive text-inverse hover:bg-destructive/90 focus-visible:outline-focus",
    };
    const sizes = {
      sm: "px-3 py-1.5 text-sm rounded-sm",
      md: "px-4 py-2 text-base rounded-md",
      lg: "px-6 py-3 text-lg rounded-lg",
    };
    return (
      <button
        ref={ref}
        className={`inline-flex items-center justify-center font-medium transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:pointer-events-none disabled:opacity-50 ${variants[variant]} ${sizes[size]} ${className ?? ""}`}
        {...props}
      >
        {children}
      </button>
    );
  }
);
Button.displayName = "Button";
export default Button;
```

### Card (`components/Card.tsx`)

Purpose: Elevated surface container for grouping related content.

```tsx
// Card.tsx — generated by dsys

import { forwardRef } from "react";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {}

const Card = forwardRef<HTMLDivElement, CardProps>(
  ({ className, children, ...props }, ref) => (
    <div
      ref={ref}
      className={`bg-surface-raised rounded-lg border border-border shadow-sm ${className ?? ""}`}
      {...props}
    >
      {children}
    </div>
  )
);
Card.displayName = "Card";
export default Card;
```

### Input (`components/Input.tsx`)

Purpose: Text input field with consistent focus ring and error state.

```tsx
// Input.tsx — generated by dsys

import { forwardRef } from "react";

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean;
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ error, className, ...props }, ref) => (
    <input
      ref={ref}
      className={`w-full rounded-md border bg-surface-inset px-3 py-2 text-base text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-focus focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 ${
        error ? "border-error" : "border-border"
      } ${className ?? ""}`}
      {...props}
    />
  )
);
Input.displayName = "Input";
export default Input;
```

### Badge (`components/Badge.tsx`)

Purpose: Inline status label for categories, tags, and state indicators.

```tsx
// Badge.tsx — generated by dsys

import { forwardRef } from "react";

interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: "default" | "success" | "error" | "warning" | "info";
}

const Badge = forwardRef<HTMLSpanElement, BadgeProps>(
  ({ variant = "default", className, children, ...props }, ref) => {
    const variants = {
      default: "bg-surface-inset text-text-muted border-border",
      success: "bg-success/10 text-success border-success/20",
      error:   "bg-error/10 text-error border-error/20",
      warning: "bg-warning/10 text-warning border-warning/20",
      info:    "bg-info/10 text-info border-info/20",
    };
    return (
      <span
        ref={ref}
        className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${variants[variant]} ${className ?? ""}`}
        {...props}
      >
        {children}
      </span>
    );
  }
);
Badge.displayName = "Badge";
export default Badge;
```

### Heading (`components/Heading.tsx`)

Purpose: Semantic heading text component mapping heading levels to type scale tokens.

```tsx
// Heading.tsx — generated by dsys

import { forwardRef } from "react";

type HeadingLevel = 1 | 2 | 3 | 4;

interface HeadingProps extends React.HTMLAttributes<HTMLHeadingElement> {
  level?: HeadingLevel;
}

const sizeMap: Record<HeadingLevel, string> = {
  1: "text-4xl font-bold",
  2: "text-3xl font-bold",
  3: "text-2xl font-semibold",
  4: "text-xl font-semibold",
};

const Heading = forwardRef<HTMLHeadingElement, HeadingProps>(
  ({ level = 1, className, children, ...props }, ref) => {
    const Tag = `h${level}` as "h1" | "h2" | "h3" | "h4";
    return (
      <Tag
        ref={ref}
        className={`text-text leading-tight tracking-tight ${sizeMap[level]} ${className ?? ""}`}
        {...props}
      >
        {children}
      </Tag>
    );
  }
);
Heading.displayName = "Heading";
export default Heading;
```

### Text (`components/Text.tsx`)

Purpose: Body text and inline content using the type scale and semantic text colors.

```tsx
// Text.tsx — generated by dsys

import { forwardRef } from "react";

interface TextProps extends React.HTMLAttributes<HTMLParagraphElement> {
  variant?: "primary" | "secondary" | "muted";
  size?: "sm" | "base" | "lg";
  as?: "p" | "span" | "div";
}

const Text = forwardRef<HTMLParagraphElement, TextProps>(
  ({ variant = "primary", size = "base", as: Tag = "p", className, children, ...props }, ref) => {
    const variants = {
      primary:   "text-text",
      secondary: "text-text-secondary",
      muted:     "text-text-muted",
    };
    const sizes = {
      sm:   "text-sm",
      base: "text-base",
      lg:   "text-lg",
    };
    return (
      <Tag
        ref={ref as React.Ref<HTMLParagraphElement>}
        className={`leading-relaxed ${variants[variant]} ${sizes[size]} ${className ?? ""}`}
        {...props}
      >
        {children}
      </Tag>
    );
  }
);
Text.displayName = "Text";
export default Text;
```

---

## 7. Naming Conventions

| Concern | Convention | Example |
|---------|-----------|---------|
| CSS variable prefix | `--ds-` | `--ds-color-action-primary` |
| CSS variable structure | `--ds-{category}-{group}-{role}` | `--ds-color-surface-raised` |
| Tailwind token names | kebab-case, semantic role | `primary`, `surface-raised`, `text-muted` |
| Component files | PascalCase, `.tsx` extension | `Button.tsx`, `Card.tsx` |
| No barrel exports | No `index.ts` in v1 | Import directly: `import Button from "./Button"` |
| Token categories in CSS | Grouped with comment headers | `/* ── Colors: Action ── */` |

**Tailwind utility naming:** Tailwind generates utilities from `@theme` variables by stripping the `--` prefix and the namespace prefix (e.g., `--color-primary` → `bg-primary`, `text-primary`). Components must use these semantic names — never Tailwind's default color names (`blue-500`, `gray-100`) even if the default palette were available.

---

## 8. "Done" Checklist

The generator output is complete when all of the following are true:

- [ ] `tokens.json` is valid DTCG JSON with both `primitive` and `semantic` layers
- [ ] `tokens.css` has a `:root` block (light), a `@media (prefers-color-scheme: dark) { :root }` block, and a `.dark` class block
- [ ] `theme.css` starts with `@import "tailwindcss"` and has `--color-*: initial;` as the first declaration in `@theme`
- [ ] All 6 component files exist in `components/` and use only design system Tailwind classes — no raw color values (`#hex`, `rgb()`), no raw pixel values (`p-[13px]`), no Tailwind default color names (`blue-500`, `gray-100`)
- [ ] Components accept `className` for composition and have `displayName` set
- [ ] A developer can copy the output directory into a Tailwind v4 project, add `@import "./tokens.css"; @import "./theme.css";` to their main CSS file, and immediately use `Button`, `Card`, `Input`, and `Badge` without any additional configuration
- [ ] No TypeScript errors in component files (generator must run a type check if Node is available)
