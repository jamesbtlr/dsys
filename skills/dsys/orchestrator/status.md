<!-- SYNC: Independent status command for dsys pipeline. -->

# dsys Status

You display the current pipeline status for dsys projects.

---

## Parse Arguments

The raw arguments string is passed in as `$ARGUMENTS` (or `Arguments: ...`).

If arguments are provided, treat the first token as the project name.

---

## Display Status

**If a project name was provided:**

Check if the state file exists:

```bash
cat .dsys/{name}/.state.json 2>/dev/null || echo "NOT_FOUND"
```

If `NOT_FOUND`: report `No dsys project found: {name}`. STOP.

Otherwise, read the state file and display:

```
dsys project: {name}
Created:      {created_at}
Screenshots:  {count} ({basenames from screenshots array})
Platforms:    {platforms}

Pipeline:
  analyze:    {status} {completed_at or ""} {if stages.analyze.component_manifest is not null: — read the manifest file and append "({N} detected components)" where N is the length of detected_components array}
  synthesize: {status} {completed_at or ""}
  build:      {status} {completed_at or ""}
  figma:      {status or "—"} {completed_at or ""}

{Next action suggestion}
```

If `stages.analyze.component_manifest` is a non-null path, check if the file exists on disk:
```bash
test -f "{component_manifest_path}" && echo "EXISTS" || echo "MISSING"
```
If `EXISTS`, read the manifest and count `detected_components`. Display count after the analyze line. If the manifest file is missing, ignore (do not error).

Next action suggestions based on the first non-completed stage:
- If analyze is not completed: `Next: /dsys:analyze {screenshots_dir_or_paths} --name {name}`
- If analyze is completed but synthesize is not: `Next: /dsys:synthesize {name}`
- If synthesize is completed but build is not: `Next: /dsys:build {name}`
- If build is completed but figma is not completed: `All stages complete. Output in .dsys/{name}/\n  Optional: /dsys:figma {name} (push to Figma)`
- If all completed (including figma): `All stages complete. Output in .dsys/{name}/ + Figma`

---

**If no project name was provided:**

List all state files:

```bash
ls .dsys/*/.state.json 2>/dev/null || echo "NONE"
```

If `NONE`: report `No dsys projects found. Run /dsys:analyze to start.` STOP.

For each state file found, read it and display a one-line summary:

```
dsys projects:
  {name}  analyze:{status}  synthesize:{status}  build:{status}  figma:{status or "—"}
  ...
```
