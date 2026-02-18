---
name: dsys:generate
description: Generate a complete design system from screenshot benchmarks
argument-hint: "[screenshots...] [--name project-name] [--review]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
---

Generate a complete design system from visual benchmark screenshots.
Takes screenshot paths or a directory, analyzes them in parallel,
synthesizes design tokens, and generates platform-specific code.

@skills/dsys/dsys/SKILL.md

Arguments: $ARGUMENTS
