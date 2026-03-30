#!/bin/bash
# DevFlow Uninstallation Script
# Removes the DevFlow framework from VS Code

set -e

echo "🗑️  Uninstalling DevFlow Framework..."
echo ""

# Detect OS and set paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  COPILOT_DIR="$HOME/Library/Application Support/Code/User/globalStorage/github.copilot-dev"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  COPILOT_DIR="$HOME/.config/Code/User/globalStorage/github.copilot-dev"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  COPILOT_DIR="$APPDATA/Code/User/globalStorage/github.copilot-dev"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

# Remove DevFlow skills
if [ -d "$COPILOT_DIR/skills" ]; then
  for skill_dir in "$COPILOT_DIR"/skills/devflow-*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      rm -rf "$skill_dir"
      echo "  ✓ Removed skill: $skill_name"
    fi
  done
fi

# Remove DevFlow prompts
if [ -d "$COPILOT_DIR/prompts" ]; then
  for prompt_file in "$COPILOT_DIR"/prompts/devflow*.prompt.md; do
    if [ -f "$prompt_file" ]; then
      filename=$(basename "$prompt_file")
      rm -f "$prompt_file"
      echo "  ✓ Removed prompt: $filename"
    fi
  done
fi

echo ""
echo "✅ DevFlow Framework uninstalled successfully!"
echo ""
echo "📝 To reinstall, run:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)"
echo ""
