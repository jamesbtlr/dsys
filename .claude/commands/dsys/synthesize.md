---
name: dsys:synthesize
description: "Step 2 of 3: Merge findings into design-system.json (after analyze)"
argument-hint: "project-name"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
---

Synthesize analysis findings into a unified design-system.json (Stage 2 of 3).
Reads findings from a previous /dsys:analyze run and merges them into
a single design system with resolved tokens and aesthetic summary.

@skills/dsys/orchestrator/synthesize.md

Arguments: $ARGUMENTS
