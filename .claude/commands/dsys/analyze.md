---
name: dsys:analyze
description: "Step 1 of 3: Extract design tokens from screenshots (start here for split workflow)"
argument-hint: "path/to/screenshots/"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
---

Analyze screenshot benchmarks and extract design findings (Stage 1 of 3).
Takes screenshot paths or a directory, runs parallel analysis agents,
and writes validated findings to .dsys/{name}/findings/.

@skills/dsys/orchestrator/analyze.md

Arguments: $ARGUMENTS
