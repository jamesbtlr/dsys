---
name: dsys:status
description: "Check pipeline progress and see what to run next"
argument-hint: ""
allowed-tools:
  - Read
  - Bash
---

Show the current pipeline status for dsys projects.
Without arguments, lists all projects. With a project name,
shows detailed stage status and next action.

@skills/dsys/orchestrator/status.md

Arguments: $ARGUMENTS
