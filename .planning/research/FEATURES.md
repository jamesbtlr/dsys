# Features Research — Design System Generation Tools

**Research type:** Project Research — Features dimension
**Milestone:** Greenfield
**Question:** What features do design system generation tools have? What's table stakes vs differentiating?
**Date:** 2026-02-17

---

## Scope

Tools surveyed (by category):

- **Token management / transformation:** Style Dictionary, Theo (Salesforce), Token Transformer
- **Figma-integrated extraction:** Tokens Studio (Figma), Figma Variables + REST API, Specify, Supernova
- **Design-to-code platforms:** Anima, Locofy, Builder.io, Zeplin, Relativity, DhiWise
- **AI-powered generation:** Galileo AI, Uizard, v0 (Vercel), Amplify (Figma), Creatie
- **Screenshot/visual-to-design:** Vercel v0 screenshot mode, Gemini visual analysis tools, Framer AI
- **CLI/config-driven systems:** nx (Nx design system generator), Storybook, Backlight.dev

---

## Table Stakes (must-have or users leave)

These are features every tool in this category provides. Absence is disqualifying.

### TS-1: Color token extraction and output
**What it is:** Extract a color palette from input (visual or config) and output named tokens. At minimum: brand colors, semantic aliases (primary, secondary, danger, success, warning, muted), and raw hex/rgb values.

**Why table stakes:** Color is the most visible, most-asked-about output. Every existing tool does this. Omitting it means users cannot start building.

**Complexity:** Low-medium. The extraction step is the hard part; serialization to CSS custom properties, JSON, or Swift constants is straightforward.

**Dependencies:** None. This is the atomic unit. Everything else depends on it.

---

### TS-2: Typography token extraction and output
**What it is:** Identify font families, weights, sizes, line-heights, and letter-spacing from input. Output as named tokens. At minimum: a type scale (xs through 3xl or similar), heading vs body distinction.

**Why table stakes:** Typography is the second most-asked-about design system primitive. All surveyed tools include it.

**Complexity:** Medium. Visual extraction requires inferring scale from size relationships rather than reading a font manifest. Naming conventions differ (Tailwind uses `text-sm/base/lg`; Swift uses `UIFont.TextStyle`).

**Dependencies:** TS-1 (text color tokens). Platform targets (TS-6) affect output format.

---

### TS-3: Spacing / sizing token extraction
**What it is:** A named spacing scale — padding, margin, gap, and sometimes sizing values — derived from observed whitespace in the input. At minimum: a numeric scale (4, 8, 12, 16, 24, 32, 48, 64) or T-shirt sizes.

**Why table stakes:** Without spacing tokens, generated components produce visually inconsistent layouts. All design-to-code tools address spacing.

**Complexity:** Medium-high. Extracting spacing from screenshots requires identifying recurring gaps. Ambiguity between padding, margin, and gap is high when only a screenshot is available.

**Dependencies:** TS-1 (surface colors affect perceived spacing).

---

### TS-4: Token output in at least one standard format
**What it is:** Export tokens as at least one of: CSS custom properties, JSON (W3C Design Token Community Group format), or platform-native constants.

**Why table stakes:** Tokens with no output format are useless. The W3C DTCG JSON format (`$value`, `$type`) has become the de facto interchange format. Style Dictionary consumes it. Tokens Studio exports it.

**Complexity:** Low. This is pure serialization once tokens are resolved.

**Dependencies:** All token extraction features (TS-1 through TS-3).

---

### TS-5: Named semantic aliases (not just raw values)
**What it is:** Two-layer token architecture: primitive tokens (`color.blue.500 = #3B82F6`) and semantic aliases (`color.primary = {color.blue.500}`). Semantic aliases are what components consume.

**Why table stakes:** Raw value tokens force downstream consumers to hard-code decisions. Every mature design system tool — Style Dictionary, Tokens Studio, Supernova — enforces this separation. Without it, theming is impossible.

**Complexity:** Medium. Inferring semantic intent (which blue is "primary"? which red is "danger"?) from a screenshot requires heuristic or model-based interpretation.

**Dependencies:** TS-1 through TS-3.

---

### TS-6: At least one platform-specific output target
**What it is:** Generate tokens in a format consumable by a specific platform: CSS/SCSS for web, Swift/Objective-C for iOS, Kotlin/XML for Android. Style Dictionary's primary value proposition is multi-platform transformation.

**Why table stakes:** A design system that only lives in JSON is not a design system anyone ships. Every tool in the category targets at least one platform.

**Complexity:** Low for CSS (trivial). Medium for Swift (requires understanding of `Color`, `Font`, `UIColor`). Low-medium for Tailwind config (JS object).

**Dependencies:** TS-4.

---

### TS-7: Human-readable output (not just machine-readable)
**What it is:** A style guide or documentation artifact that a designer or non-engineer can read. At minimum: a visual swatch display of colors, type specimens, and spacing scale.

**Why table stakes:** Design systems serve designers and engineers. If output is only machine-readable JSON, designers cannot validate correctness. All Figma plugins produce visual previews; Supernova generates documentation sites.

**Complexity:** Low-medium. A markdown or HTML file with inline styles covers this adequately.

**Dependencies:** All token extraction features.

---

## Differentiators (competitive advantage)

These features separate tools that are merely functional from tools users prefer and pay for.

### D-1: Visual reference input (screenshot analysis)
**What it is:** Accept one or more screenshots or images as input and infer design tokens from them, rather than requiring a Figma file, design spec, or manual config.

**Why differentiating:** Almost no existing CLI tool does this. Figma plugins require a Figma file. Style Dictionary requires manual config. Tools like v0 accept screenshots but produce UI, not a design system. This is the core capability of the target tool and currently has minimal direct competition.

**Complexity:** High. Requires vision model integration, prompt engineering for extraction, and heuristic reasoning about recurring values vs one-offs.

**Dependencies:** All token extraction features depend on this as input source. Quality of TS-1 through TS-3 directly depends on model quality here.

---

### D-2: Multi-platform output in a single pass
**What it is:** Generate CSS tokens, Tailwind config, SwiftUI assets, and Android resources simultaneously from a single input, with correct naming conventions for each platform.

**Why differentiating:** Style Dictionary does this but requires manual configuration of transforms and platforms. Tokens Studio requires Figma as source. No tool generates multi-platform output from a screenshot.

**Complexity:** Medium. The transformation layer is well-understood (Style Dictionary's transform model is the blueprint). The differentiator is automation of the configuration step.

**Dependencies:** D-1, TS-4, TS-6.

---

### D-3: Immediately usable component templates
**What it is:** Beyond tokens, output scaffolded component files — React/Tailwind `.tsx` files, SwiftUI `View` files — that use the generated tokens. Not a full component library, but a starting-point template set: Button, Card, Input, Badge, Heading, Text.

**Why differentiating:** Tokens alone require significant developer effort to translate into components. v0 generates components but from a prompt, not a design system. Locofy generates components from Figma. No tool generates token-grounded component templates from a screenshot.

**Complexity:** High. Requires both good token extraction (inputs) and opinionated component API design (outputs). The output must be idiomatic for each platform (Tailwind class patterns differ substantially from SwiftUI modifiers).

**Dependencies:** D-1, D-2, TS-5.

---

### D-4: Aesthetic vibe / style narrative extraction
**What it is:** Produce a written characterization of the visual aesthetic — e.g., "minimalist SaaS with generous whitespace, neutral grays, a single blue accent, and geometric sans-serif type" — that gives the team shared language for design decisions not captured by tokens.

**Why differentiating:** No existing tool does this. Style Dictionary is purely mechanical. Figma plugins do not generate prose. This addresses the common problem where tokens are correct but the team still disagrees on what feels "right."

**Complexity:** Medium. A vision model can produce this as a secondary output alongside token extraction. Prompt design is the main effort.

**Dependencies:** D-1.

---

### D-5: CLAUDE.md design rules output
**What it is:** Generate a `CLAUDE.md` (or equivalent AI assistant context file) that encodes design system constraints as natural-language rules for an AI coding assistant. Example: "Always use `text-primary` not hardcoded hex. Buttons must use `rounded-md`. Spacing must be a multiple of 4px."

**Why differentiating:** No existing design system tool targets AI coding assistants as a consumer. This is a novel output format that leverages the AI-native context of the tool.

**Complexity:** Low-medium. Content is derived from already-extracted tokens. The effort is in structuring the rules clearly and keeping them machine-parseable.

**Dependencies:** TS-5, D-3.

---

### D-6: Multiple visual benchmark inputs with synthesis
**What it is:** Accept more than one screenshot and synthesize a coherent design system across them, resolving conflicts (e.g., two screens use slightly different blues) and flagging ambiguities.

**Why differentiating:** All existing visual analysis tools handle a single input. Multi-input synthesis mimics how a designer audits a product — looking across screens, identifying the "intended" system vs. drift.

**Complexity:** High. Requires cross-image reasoning, conflict detection, and a merging strategy. The conflict-flagging output is especially complex to make useful.

**Dependencies:** D-1.

---

### D-7: Incremental / additive mode (update, don't replace)
**What it is:** When re-run against an existing output directory, detect what changed, update only the affected tokens and files, and preserve user modifications. Like a smart merge rather than a destructive overwrite.

**Why differentiating:** Style Dictionary regenerates all output on every run (destructive). Tokens Studio syncs but overwrites. For a CLI tool that produces files users will modify, destructive re-runs are a dealbreaker after the first iteration.

**Complexity:** High. Requires tracking which files/sections were generated vs user-modified, a merge strategy, and a clear schema for "generated zones" vs "user zones."

**Dependencies:** All output features. Requires stable token naming across runs.

---

### D-8: Confidence scores and explicit ambiguity reporting
**What it is:** When a token value is inferred from a screenshot, report how confident the model is. Flag values that are ambiguous (e.g., "this blue appears in 3 slightly different shades — which is canonical?") and present the decision made with rationale.

**Why differentiating:** Existing tools either produce output silently or fail. Reporting uncertainty lets users make informed corrections rather than debugging wrong outputs later.

**Complexity:** Medium. Requires structured output from the vision model, post-processing to detect near-duplicate values, and a readable reporting format.

**Dependencies:** D-1, D-6.

---

### D-9: Per-project platform target selection
**What it is:** Users choose which output targets they want — web-only, iOS-only, both, all three — and the tool generates only what is needed. The config is project-scoped, not global.

**Why differentiating:** Style Dictionary supports this but requires manual config. No visual-analysis tool offers it. For a "drop in and build" tool, forcing iOS output on a web-only project creates noise and confusion.

**Complexity:** Low. This is a config/CLI design decision. The output transforms already need to exist (D-2); this is just the selection layer.

**Dependencies:** D-2.

---

## Anti-Features (deliberately NOT build)

These are things the tool should explicitly avoid, even though related tools do them.

### AF-1: Full component library generation
**What it is:** Generating a complete, production-ready component library (50+ components, accessibility-compliant, tested, documented).

**Why not:** This is a multi-year effort. Tools like Radix, Shadcn, and MUI exist. The target tool's value is tokens + templates that guide how users extend those libraries, not replace them. Building a full library would take years, be immediately outdated, and compete with established open-source work.

**Risk of building it:** Massive scope creep. The "drop in and build" promise requires fast output; a full component library cannot be fast.

---

### AF-2: Live Figma sync / two-way Figma integration
**What it is:** Bidirectional sync with Figma — reading variables from Figma, pushing token changes back to Figma, keeping both in sync.

**Why not:** This requires Figma API access, OAuth, webhook infrastructure, and a fundamentally different distribution model. It also recreates Tokens Studio and Supernova on their home turf. The target tool's differentiator is working from screenshots, not from a Figma file. Users who want Figma sync should use Tokens Studio.

**Risk of building it:** Platform dependency, API rate limits, credential management, and a support burden that has nothing to do with the core value proposition.

---

### AF-3: Visual design editor / GUI
**What it is:** A web UI or desktop app for editing tokens visually, with live preview of changes.

**Why not:** The target tool is a Claude Code skill — a CLI/programmatic tool for developers. A GUI is a different product with different distribution, hosting, and maintenance costs. The developer audience expects CLI and files.

**Risk of building it:** Scope explosion. Maintaining a UI product while also maintaining a generation engine splits focus fatally.

---

### AF-4: Android/Kotlin as a launch target
**What it is:** Generating Android-specific token output (XML color resources, `dimens.xml`, Compose `MaterialTheme` tokens).

**Why not:** The stated output targets are React/Tailwind and SwiftUI. Android adds a third platform with substantially different conventions, testing requirements, and a different primary audience. It can be added later but should not be a launch scope item.

**Risk of building it at launch:** Android token conventions differ enough from iOS that the transformation layer needs to be rebuilt, not adapted. Launch delay for marginal initial audience expansion.

---

### AF-5: Real-time / streaming design analysis
**What it is:** Continuous monitoring of a design file or URL, updating tokens automatically when the source changes.

**Why not:** This requires infrastructure (polling or webhooks), introduces drift/conflict risks, and removes human validation from the loop. The "drop in and build" workflow is intentionally manual: run it when you want a new baseline. Continuous sync is a different — and harder — product.

---

## Feature Dependency Map

```
Screenshot input (D-1)
  └─► Color extraction (TS-1)
  │     └─► Semantic aliases (TS-5)
  │           └─► Component templates (D-3)
  │           └─► CLAUDE.md rules (D-5)
  └─► Typography extraction (TS-2)
  │     └─► Semantic aliases (TS-5)
  └─► Spacing extraction (TS-3)
  │     └─► Semantic aliases (TS-5)
  └─► Vibe narrative (D-4)
  └─► Confidence reporting (D-8)
  │
Multi-image synthesis (D-6)
  └─► Conflict detection (D-8)

Token extraction (TS-1 + TS-2 + TS-3)
  └─► Standard format output (TS-4)
  └─► Platform targets (TS-6)
        └─► Multi-platform (D-2)
              └─► Per-project target selection (D-9)

Human-readable output (TS-7)
  └─► (standalone, consumes all tokens)

Incremental mode (D-7)
  └─► Depends on stable token naming + all output features
```

---

## Complexity Summary

| Feature | Complexity | Launch? |
|---|---|---|
| TS-1 Color tokens | Low-Medium | Yes |
| TS-2 Typography tokens | Medium | Yes |
| TS-3 Spacing tokens | Medium-High | Yes |
| TS-4 Standard format output | Low | Yes |
| TS-5 Semantic aliases | Medium | Yes |
| TS-6 Platform target output | Low-Medium | Yes |
| TS-7 Human-readable style guide | Low-Medium | Yes |
| D-1 Screenshot analysis | High | Yes (core) |
| D-2 Multi-platform output | Medium | Yes |
| D-3 Component templates | High | Yes |
| D-4 Vibe narrative | Medium | Yes |
| D-5 CLAUDE.md rules output | Low-Medium | Yes |
| D-6 Multi-image synthesis | High | V2 |
| D-7 Incremental mode | High | V2 |
| D-8 Confidence / ambiguity reporting | Medium | V2 |
| D-9 Per-project platform selection | Low | Yes |

---

## Key Insight

The most significant gap in the market is the combination of (D-1) visual input + (D-2) multi-platform output + (D-3) component templates + (D-5) CLAUDE.md rules. No existing tool connects all four. Style Dictionary is powerful but requires manual config. Tokens Studio requires Figma. AI tools like v0 generate UI but not design systems. The target tool occupies a specific, underserved niche: **screenshot in, immediately-usable design system out, for developers who build with AI coding assistants.**

The risk to track: D-3 (component templates) is the highest-complexity feature and most likely to be "good enough" at launch but require significant iteration. Consider shipping tokens + style guide (TS-1 through TS-7) + CLAUDE.md (D-5) as the v1 tight scope, with component templates as v1.1.
