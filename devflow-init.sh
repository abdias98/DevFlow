#!/bin/bash
# devflow-init — Configure current workspace to use DevFlow skills & instructions
# Run this once per workspace: cd your-project && devflow-init

set -e

# Detect OS
if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu"* ]]; then
  DEVFLOW_STORE="$HOME/.devflow"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  DEVFLOW_STORE="$APPDATA/.devflow"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

if [ ! -d "$DEVFLOW_STORE" ]; then
  echo "❌ DevFlow is not installed. Run the global installer first:"
  echo "   bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)"
  exit 1
fi

WORKSPACE_DIR="$(pwd)"
echo "📂 Configuring DevFlow for: $WORKSPACE_DIR"
echo ""

# ── Copy skills → .agents/skills/ ──────────────────────────────────────────
if [ -d "$DEVFLOW_STORE/skills" ]; then
  mkdir -p "$WORKSPACE_DIR/.agents/skills"
  for skill_dir in "$DEVFLOW_STORE/skills"/devflow-*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      mkdir -p "$WORKSPACE_DIR/.agents/skills/$skill_name"
      cp -r "$skill_dir/." "$WORKSPACE_DIR/.agents/skills/$skill_name/"
      echo "  ✓ $skill_name"
    fi
  done
fi

# ── Copy instructions → .github/instructions/ ──────────────────────────────
if [ -d "$DEVFLOW_STORE/instructions" ]; then
  mkdir -p "$WORKSPACE_DIR/.github/instructions"
  for instr_file in "$DEVFLOW_STORE/instructions"/*.instructions.md; do
    if [ -f "$instr_file" ]; then
      cp "$instr_file" "$WORKSPACE_DIR/.github/instructions/"
      echo "  ✓ $(basename "$instr_file")"
    fi
  done
fi

# ── Exclude DevFlow files from git (local, never committed) ─────────────────
if [ -d "$WORKSPACE_DIR/.git" ]; then
  EXCLUDE_FILE="$WORKSPACE_DIR/.git/info/exclude"
  mkdir -p "$(dirname "$EXCLUDE_FILE")"
  for entry in ".agents/" ".github/instructions/devflow-*.instructions.md" ".github/prompts/devflow*.prompt.md"; do
    if ! grep -qxF "$entry" "$EXCLUDE_FILE" 2>/dev/null; then
      echo "$entry" >> "$EXCLUDE_FILE"
    fi
  done
  echo "  ✓ .git/info/exclude updated"
fi
echo ""
echo "✅ DevFlow skills configured for this workspace."
echo "   Reload VS Code (Ctrl+Shift+P → Developer: Reload Window)"
echo "   Then use: @devflow <feature>"
echo ""
