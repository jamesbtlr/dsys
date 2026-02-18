<!-- SYNC: Stage-2 extraction of SKILL.md Steps 10-11. Keep in sync. -->

# dsys Synthesize (Stage 2 of 3)

You are the dsys synthesize orchestrator. You run the synthesis stage of the dsys pipeline: load analysis findings, run the synthesizer agent to merge them into a unified design system, and validate the output against schema. The result is `.dsys/{name}/design-system.json`.

**What this stage produces:**
- A unified `design-system.json` in `.dsys/{name}/`
- Updated `.state.json` with synthesize stage completed

After this stage completes, the user can `/clear` and run `/dsys:build {name}` to continue.

---

## Step 1: Parse Arguments and Load State

The raw arguments string is passed in as `$ARGUMENTS` (or `Arguments: ...`).

The first token is the project name. If no project name is provided: STOP and report:
```
dsys:synthesize — Step 2 of 3

Merges analysis findings into a unified design-system.json with
resolved tokens and aesthetic summary.

Usage:
  /dsys:synthesize my-app

Requires a completed /dsys:analyze run. Check available projects:
  /dsys:status
```

Read the state file:

```bash
cat .dsys/{name}/.state.json 2>/dev/null || echo "NOT_FOUND"
```

If `NOT_FOUND`: STOP and report:
```
Error: No dsys project found: {name}
Run /dsys:analyze first to create the project.
```

Parse the state file JSON. Verify:
1. `stages.analyze.status` is `"completed"` — if not, STOP and report:
   ```
   Error: Analysis stage has not completed for project "{name}".
   Current status: {stages.analyze.status}
   Run /dsys:analyze first.
   ```
2. `stages.analyze.findings` is a non-empty array.

Extract from state:
- `findings_paths`: the `stages.analyze.findings` array
- `platforms`: the `platforms` array

Display:
```
Loading project: {name}
Findings: {count} ({basenames})
Platforms: {platforms}
```

---

## Step 2: Update State — Synthesize In Progress

Read `.dsys/{name}/.state.json`, update `stages.synthesize`:

```json
{
  "status": "in_progress",
  "started_at": "{ISO 8601 timestamp}",
  "completed_at": null,
  "design_system_path": null,
  "errors": []
}
```

Write the updated state file.

---

## Step 3: Synthesis

Display banner:
```
---
## Synthesizing design tokens from {N} findings...

Merging findings into a unified design system.
---
```

Issue a single Task:

```
Task(
  agent: "skills/dsys/agents/synthesizer.md",
  prompt: "findings_paths: [{comma-separated quoted absolute paths from findings_paths}]
output_path: .dsys/{name}/design-system.json"
)
```

If the result starts with `Error:`: update state with `synthesize.status: "failed"` and `synthesize.errors: ["{error}"]`. STOP and report with note that findings persist for debugging.

---

## Step 4: Schema Validation — Design System

```bash
RESULT=$(npx ajv-cli validate --spec=draft2020 \
  -s skills/dsys/schemas/design-system.schema.json \
  -d ".dsys/{name}/design-system.json" 2>&1)
if echo "$RESULT" | grep -qi "valid"; then
  echo "VALID"
else
  echo "INVALID: $RESULT"
fi
```

If `INVALID`: update state with `synthesize.status: "failed"` and `synthesize.errors: ["{validation error}"]`. STOP and report the first line of the validation error.

---

## Step 5: Update State — Synthesize Complete

Read `.dsys/{name}/.state.json`, update `stages.synthesize`:

```json
{
  "status": "completed",
  "completed_at": "{ISO 8601 timestamp}",
  "design_system_path": ".dsys/{name}/design-system.json",
  "errors": []
}
```

Write the updated state file.

---

## Step 6: Synthesis Summary

Display:
```
---
## Synthesis complete

Design system written to .dsys/{name}/design-system.json

State saved to .dsys/{name}/.state.json

Next step: /dsys:build {name}
---
```

---

## Error Recovery Reference

| Stage | Failure type | Action |
|---|---|---|
| State loading | Missing state file | STOP — tell user to run analyze first |
| State loading | Analyze not completed | STOP — tell user to run analyze first |
| Synthesis | Agent error | STOP — update state to failed, findings preserved |
| Schema validation | Invalid design-system.json | STOP — update state to failed, intermediate files preserved |

**Do NOT clean up intermediate files on failure.** Partial output in `.dsys/{name}/` is the user's debugging artifact.
