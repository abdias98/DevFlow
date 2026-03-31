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

DEVFLOW_STORE="$HOME/.devflow"

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

# Remove DevFlow store (skills + instructions)
if [ -d "$DEVFLOW_STORE" ]; then
  rm -rf "$DEVFLOW_STORE"
  echo "  ✓ Removed DevFlow store: $DEVFLOW_STORE"
fi

# Remove devflow-init command
for bin_dir in "$HOME/.local/bin" "/usr/local/bin"; do
  if [ -f "$bin_dir/devflow-init" ]; then
    rm -f "$bin_dir/devflow-init"
    echo "  ✓ Removed command: $bin_dir/devflow-init"
  fi
done

echo ""
echo "✅ DevFlow Framework uninstalled successfully!"
echo ""
echo "📝 To reinstall, run:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)"
echo ""
