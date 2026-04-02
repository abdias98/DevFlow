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

# Remove global skills
if [ -d "$USER_DIR/.agents/skills" ]; then
  rm -rf "$USER_DIR/.agents/skills"
  echo "  ✓ Removed global skills directory"
fi

# Remove global instructions
if [ -d "$USER_DIR/.github/instructions" ]; then
  rm -rf "$USER_DIR/.github/instructions"
  echo "  ✓ Removed global instructions directory"
fi

echo ""
echo "✅ DevFlow Framework uninstalled successfully!"
echo ""
echo "📝 To reinstall, run:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)"
echo ""
