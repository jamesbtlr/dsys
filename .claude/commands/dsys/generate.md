---
name: dsys:generate
description: "Full pipeline: screenshots → design system → code (all stages, one session)"
argument-hint: "path/to/screenshots/"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
---

Generate a complete design system from visual benchmark screenshots.
Takes screenshot paths or a directory, analyzes them in parallel,
synthesizes design tokens, and generates platform-specific code.

@skills/dsys/orchestrator/SKILL.md

Arguments: $ARGUMENTS
