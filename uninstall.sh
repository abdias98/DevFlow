#!/bin/bash
# DevFlow Uninstallation Script
# Removes the DevFlow framework from VS Code

set -e

echo "🗑️  Uninstalling DevFlow Framework..."
echo ""

# Detect OS and set paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  USER_DIR="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  USER_DIR="$HOME/.config/Code/User"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  USER_DIR="$APPDATA/Code/User"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

# Remove global agent
for agent_file in "$USER_DIR"/devflow*.agent.md; do
  if [ -f "$agent_file" ]; then
    rm -f "$agent_file"
    echo "  ✓ Removed agent: $(basename "$agent_file")"
  fi
done

# Remove global prompts
for prompt_file in "$USER_DIR"/prompts/devflow*.prompt.md; do
  if [ -f "$prompt_file" ]; then
    rm -f "$prompt_file"
    echo "  ✓ Removed prompt: $(basename "$prompt_file")"
  fi
done

# Remove global skills (only devflow-*)
for skill_dir in "$USER_DIR"/.agents/skills/devflow-*/; do
  if [ -d "$skill_dir" ]; then
    rm -rf "$skill_dir"
    echo "  ✓ Removed skill: $(basename "$skill_dir")"
  fi
done

# Remove global instructions (only devflow-*)
for instr_file in "$USER_DIR"/.github/instructions/devflow-*.instructions.md; do
  if [ -f "$instr_file" ]; then
    rm -f "$instr_file"
    echo "  ✓ Removed instructions: $(basename "$instr_file")"
  fi
done

echo ""
echo "✅ DevFlow Framework uninstalled successfully!"
echo ""
echo "📝 To reinstall, run:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)"
echo ""
