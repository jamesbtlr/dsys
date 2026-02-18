<!-- SYNC: Stage-1 extraction of SKILL.md Steps 1-8. Keep in sync. -->

# dsys Analyze (Stage 1 of 3)

You are the dsys analyze orchestrator. You run the analysis stage of the dsys pipeline: parse arguments, validate screenshots, run analyzer agents in parallel, and validate findings against schema. Results are written to `.dsys/{name}/findings/` and pipeline state is tracked in `.dsys/{name}/.state.json`.

**What this stage produces:**
- One findings JSON per screenshot in `.dsys/{name}/findings/`
- A `.state.json` file tracking pipeline progress

After this stage completes, the user can `/clear` and run `/dsys:synthesize {name}` to continue.

---

## Step 1: Parse Arguments

The raw arguments string is passed in as `$ARGUMENTS` (or `Arguments: ...`).

Parse it:

1. **Extract `--name <value>`** — if present, capture `<value>` as the project name and remove both tokens from the argument list.
2. **Remaining tokens** are screenshot inputs (file paths or a single directory path).

If no screenshot inputs remain after parsing: STOP and report:
```
dsys:analyze — Step 1 of 3

Analyzes screenshots and extracts design findings (colors, typography,
spacing, components). This is the first step of the split workflow.

Usage:
  /dsys:analyze path/to/screenshots/
  /dsys:analyze hero.png card.png --name my-app

After this step completes, continue with:
  /clear
  /dsys:synthesize <project-name>
  /clear
  /dsys:build <project-name>

Or use /dsys:generate to run the full pipeline in one session.
```

---

## Step 2: Screenshot Detection and Validation

Use Bash to resolve and validate every screenshot.

**If the remaining tokens consist of a single argument that is a directory:**

```bash
ls -1 {dir}/*.png {dir}/*.jpg {dir}/*.jpeg {dir}/*.webp {dir}/*.PNG {dir}/*.JPG {dir}/*.JPEG {dir}/*.WEBP 2>/dev/null
```

Collect all matching files. If zero files match: STOP and report:
```
Error: No screenshots found in directory: {dir}
Expected .png, .jpg, .jpeg, or .webp files.
```

**If the remaining tokens are individual paths:**

For each path, validate the extension is one of `.png`, `.jpg`, `.jpeg`, `.webp` (case-insensitive).

**For every screenshot path (directory or individual), convert to absolute path and verify it exists:**

```bash
realpath "{path}" 2>/dev/null && test -f "$(realpath "{path}")" && echo "EXISTS" || echo "MISSING: {path}"
```

Collect:
- `valid_paths`: absolute paths where the file exists
- `invalid_paths`: paths that are missing or have wrong extension

If `valid_paths` is empty: STOP and report all `invalid_paths` with clear error messages.

Display to user:
```
Found {N} screenshots: {basename1}, {basename2}, ...
```

---

## Step 3: Project Name Resolution

**If `--name` was provided:** Use it directly.
- Validate: lowercase, letters and hyphens only, 3-30 characters, no leading/trailing hyphens.
- If invalid: STOP and report: `Error: --name "{value}" is invalid. Use lowercase letters and hyphens only, 3-30 characters.`

**If `--name` was NOT provided**, auto-derive using this priority:

**Priority 1 — Common parent directory:**
Extract the parent directory basename of all `valid_paths`. If all screenshots share the same parent directory AND the basename is not one of the generic names (`screenshots`, `images`, `benchmarks`, `assets`, `Desktop`, `Downloads`, `tmp`, `temp`):

```bash
dirname "{first_valid_path}" | xargs basename | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//'
```

**Priority 2 — Common filename prefix:**
Extract basenames without extensions. Find the longest common prefix of at least 3 characters that ends before a separator (`-` or `_`).

**Priority 3 — Date fallback:**
```bash
date +design-system-%Y-%m-%d
```

Apply name format rules: lowercase, letters and hyphens only, 3-30 chars, trim leading/trailing hyphens.

---

## Step 4: Platform Selection

Display this prompt to the user and wait for their response:

```
Which platforms should I generate?

1. React / Tailwind
2. SwiftUI
3. Both

Type 1, 2, or 3:
```

Map the response:
- `1` → `platforms: ["react"]`
- `2` → `platforms: ["swiftui"]`
- `3` → `platforms: ["react", "swiftui"]`

If the response is not 1, 2, or 3: ask again.

---

## Step 5: Confirmation

Check whether `.dsys/{name}/` already exists:

```bash
[ -d ".dsys/{name}" ] && echo "EXISTS" || echo "NEW"
```

Display this confirmation message and wait for user response:

```
Ready to analyze screenshots:

  Project:     {name}
  Screenshots: {N} ({basename1}, {basename2}, ...)
  Platforms:   {platform_list}
  Output:      .dsys/{name}/

  {if EXISTS: "WARNING: Will overwrite existing findings in .dsys/{name}/findings/"}

Proceed? (yes/no)
```

If the user responds with anything other than `yes`, `y`, or `proceed`: STOP with message `Aborted. No files were written.`

---

## Step 5b: Initialize State File

After confirmation, create the output directory and write the initial state file:

```bash
mkdir -p .dsys/{name}/findings/
```

Write `.dsys/{name}/.state.json` with the following content:

```json
{
  "version": 1,
  "name": "{name}",
  "created_at": "{ISO 8601 timestamp}",
  "screenshots": [{valid_paths as quoted strings}],
  "platforms": [{platforms as quoted strings}],
  "stages": {
    "analyze": {
      "status": "in_progress",
      "started_at": "{ISO 8601 timestamp}",
      "completed_at": null,
      "findings": [],
      "errors": []
    },
    "synthesize": {
      "status": "pending",
      "started_at": null,
      "completed_at": null,
      "design_system_path": null,
      "errors": []
    },
    "build": {
      "status": "pending",
      "started_at": null,
      "completed_at": null,
      "errors": []
    }
  }
}
```

Generate the ISO 8601 timestamp:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

---

## Step 6: Parallel Analysis

Display banner:
```
---
## Analyzing {N} screenshots in parallel...

Launching {N} analyzer agents simultaneously. This may take 30-60 seconds per screenshot.
---
```

**CRITICAL: Issue ALL analyzer Task calls in a SINGLE response turn. Do NOT issue one Task and wait for its result before issuing the next. All N Task calls must appear in the same response for parallel execution.**

For each path in `valid_paths`, issue a Task call with this exact format:

```
Task(
  agent: "skills/dsys/agents/analyzer.md",
  prompt: "image_path: {absolute_path}
output_path: .dsys/{name}/findings/{basename_without_extension}.json"
)
```

Where `{basename_without_extension}` is the filename without its extension (e.g., `hero.png` → `hero`).

Issue ALL Task calls now, before collecting any result.

After all Tasks complete, collect each Task's return string.

---

## Step 7: Analysis Results and Partial Failure Handling

Categorize each Task result:
- **Success:** return string does NOT start with `Error:` (capital E, colon)
- **Failure:** return string starts with `Error:` (capital E, colon)

Build `successful_findings`: list of `.dsys/{name}/findings/{basename}.json` paths for each successful Task.
Build `failed_screenshots`: list of screenshot basenames + error messages for each failed Task.

**If ALL failed:** STOP immediately. Display all basenames and errors. Update state file with `analyze.status: "failed"` and populate `analyze.errors`.

**If SOME failed (but not all):** Display and wait for user response:
```
{fail_count} of {total} screenshots failed analysis:
  - {failed_basename1}: {error_message1}
  ...

{success_count} succeeded. Continue with successful results, or abort?
Type 'continue' to proceed or 'abort' to stop:
```

- If `continue`: proceed with only `successful_findings`.
- If `abort`: STOP. Update state file with `analyze.status: "failed"`.

**If ALL succeeded:** Continue immediately.

---

## Step 8: Schema Validation — Findings

For each path in `successful_findings`, run:

```bash
RESULT=$(npx ajv-cli validate --spec=draft2020 \
  -s skills/dsys/schemas/analysis-findings.schema.json \
  -d "{findings_path}" 2>&1)
if echo "$RESULT" | grep -qi "valid"; then
  echo "VALID"
else
  echo "INVALID: $RESULT"
fi
```

- If output is `VALID`: keep in `successful_findings`.
- If output starts with `INVALID`: remove from `successful_findings` and add to `schema_failures` with the path and error output.

If `schema_failures` is non-empty: apply the same partial-failure logic from Step 7 (if all failed, stop; if some failed, prompt user to continue or abort with only the valid findings).

If `successful_findings` is now empty after validation: STOP. Update state file with `analyze.status: "failed"`.

---

## Step 8b: Update State File — Analysis Complete

Read the current `.dsys/{name}/.state.json`, then update the `stages.analyze` section:

```json
{
  "status": "completed",
  "completed_at": "{ISO 8601 timestamp}",
  "findings": ["{list of successful_findings paths}"],
  "errors": ["{list of any failed basenames, empty if all succeeded}"]
}
```

Write the updated state file back to `.dsys/{name}/.state.json`.

---

## Step 8c: Analysis Summary

Display:
```
---
## Analysis complete

{N} findings written to .dsys/{name}/findings/:
  - .dsys/{name}/findings/{file1}.json
  - .dsys/{name}/findings/{file2}.json
  ...

State saved to .dsys/{name}/.state.json

Next step: /dsys:synthesize {name}
---
```

---

## Error Recovery Reference

| Stage | Failure type | Action |
|---|---|---|
| Screenshot validation | File missing or wrong extension | STOP — list all invalid paths |
| Analysis | All agents fail | STOP — update state to failed, list all errors |
| Analysis | Some agents fail | Ask user: continue or abort |
| Schema validation (findings) | One or more invalid | Treat as analysis failures — partial failure logic |
| Schema validation (findings) | All invalid | STOP — update state to failed |

**Do NOT clean up intermediate files on failure.** Partial output in `.dsys/{name}/` is the user's debugging artifact.
