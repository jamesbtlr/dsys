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

# Restore SKILL.md from git (in case of prior install rewriting paths)
git -C "$INSTALL_DIR" checkout -- skills/dsys/orchestrator/SKILL.md 2>/dev/null || true

# Rewrite relative paths to absolute so the tool works from any project directory
SKILL_FILE="$INSTALL_DIR/skills/dsys/orchestrator/SKILL.md"
SKILL_TMP="${SKILL_FILE}.tmp"
sed "s|skills/dsys/agents/|$INSTALL_DIR/skills/dsys/agents/|g; s|skills/dsys/schemas/|$INSTALL_DIR/skills/dsys/schemas/|g" "$SKILL_FILE" > "$SKILL_TMP"
mv "$SKILL_TMP" "$SKILL_FILE"

# Write command entry with absolute SKILL.md reference
mkdir -p "$COMMANDS_DIR"
cat > "$COMMANDS_DIR/generate.md" << CMDEOF
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

@$INSTALL_DIR/skills/dsys/orchestrator/SKILL.md

Arguments: \$ARGUMENTS
CMDEOF

echo ""
echo "  Done! Start a new Claude Code session, then run:"
echo ""
echo "    /dsys:generate path/to/screenshots/"
echo ""
