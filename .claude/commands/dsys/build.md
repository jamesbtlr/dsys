---
name: dsys:build
description: "Step 3 of 3: Generate platform code, rules, and preview (after synthesize)"
argument-hint: "project-name"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
---

Generate platform-specific code, enforcement rules, and visual preview (Stage 3 of 3).
Reads design-system.json from a previous /dsys:synthesize run and generates
React/Tailwind and/or SwiftUI code, CLAUDE.md rules, STYLE-GUIDE.md, and preview.html.

@skills/dsys/orchestrator/build.md

Arguments: $ARGUMENTS
