#!/bin/bash
set -e

INSTALL_DIR="$HOME/.dsys-tool"
COMMANDS_DIR="$HOME/.claude/commands/dsys"

echo ""
echo "  dsys — design system generator for Claude Code"
echo ""

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "  Updating..."
  git -C "$INSTALL_DIR" pull --ff-only --quiet
else
  echo "  Installing..."
  git clone --quiet https://github.com/jamesbtlr/dsys.git "$INSTALL_DIR"
fi

# Restore all orchestrator files from git (in case of prior install rewriting paths)
git -C "$INSTALL_DIR" checkout -- skills/dsys/orchestrator/ 2>/dev/null || true

# Rewrite relative paths to absolute in all orchestrator .md files
# so the tool works from any project directory
for md_file in "$INSTALL_DIR"/skills/dsys/orchestrator/*.md; do
  tmp_file="${md_file}.tmp"
  sed "s|skills/dsys/agents/|$INSTALL_DIR/skills/dsys/agents/|g; s|skills/dsys/schemas/|$INSTALL_DIR/skills/dsys/schemas/|g" "$md_file" > "$tmp_file"
  mv "$tmp_file" "$md_file"
done

# Write command entries with absolute orchestrator references
mkdir -p "$COMMANDS_DIR"

cat > "$COMMANDS_DIR/generate.md" << CMDEOF
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

@$INSTALL_DIR/skills/dsys/orchestrator/SKILL.md

Arguments: \$ARGUMENTS
CMDEOF

cat > "$COMMANDS_DIR/analyze.md" << CMDEOF
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

Analyze screenshot benchmarks and extract design findings (Step 1 of 3).
Takes screenshot paths or a directory, runs parallel analysis agents,
and writes validated findings to .dsys/{name}/findings/.

@$INSTALL_DIR/skills/dsys/orchestrator/analyze.md

Arguments: \$ARGUMENTS
CMDEOF

cat > "$COMMANDS_DIR/synthesize.md" << CMDEOF
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

Synthesize analysis findings into a unified design-system.json (Step 2 of 3).
Reads findings from a previous /dsys:analyze run and merges them into
a single design system with resolved tokens and aesthetic summary.

@$INSTALL_DIR/skills/dsys/orchestrator/synthesize.md

Arguments: \$ARGUMENTS
CMDEOF

cat > "$COMMANDS_DIR/build.md" << CMDEOF
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

Generate platform-specific code, enforcement rules, and visual preview (Step 3 of 3).
Reads design-system.json from a previous /dsys:synthesize run and generates
React/Tailwind and/or SwiftUI code, CLAUDE.md rules, STYLE-GUIDE.md, and preview.html.

@$INSTALL_DIR/skills/dsys/orchestrator/build.md

Arguments: \$ARGUMENTS
CMDEOF

cat > "$COMMANDS_DIR/status.md" << CMDEOF
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

@$INSTALL_DIR/skills/dsys/orchestrator/status.md

Arguments: \$ARGUMENTS
CMDEOF

echo ""
echo "  Done! Start a new Claude Code session, then:"
echo ""
echo "  Quickstart (everything in one session):"
echo "    /dsys:generate path/to/screenshots/"
echo ""
echo "  Or run in stages (use /clear between each to save context):"
echo "    /dsys:analyze path/to/screenshots/   → extracts design findings"
echo "    /dsys:synthesize my-app              → merges into design-system.json"
echo "    /dsys:build my-app                   → generates platform code + preview"
echo ""
echo "  Check progress anytime:"
echo "    /dsys:status"
echo ""
