#!/bin/bash
# DevFlow Installation Script
# Installs the DevFlow multi-agent framework globally in VS Code

set -e

echo "🚀 Installing DevFlow Framework..."
echo ""

# Detect OS and set paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  COPILOT_DIR="$HOME/Library/Application Support/Code/User/globalStorage/github.copilot-dev"
  OS_NAME="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux
  COPILOT_DIR="$HOME/.config/Code/User/globalStorage/github.copilot-dev"
  OS_NAME="Linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  # Windows (Git Bash, Git for Windows, or WSL)
  COPILOT_DIR="$APPDATA/Code/User/globalStorage/github.copilot-dev"
  OS_NAME="Windows"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

echo "📍 Detected OS: $OS_NAME"
echo "📍 Installation path: $COPILOT_DIR"
echo ""

# Create directories if they don't exist
mkdir -p "$COPILOT_DIR/skills"
mkdir -p "$COPILOT_DIR/prompts"

echo "📦 Downloading DevFlow repository..."

# Determine where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If running from a cloned repo, copy local files
if [ -d "$SCRIPT_DIR/.agents/skills" ]; then
  echo "📂 Installing from local repository..."
  
  # Copy skills
  for skill_dir in "$SCRIPT_DIR"/.agents/skills/devflow-*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      mkdir -p "$COPILOT_DIR/skills/$skill_name"
      cp "$skill_dir"* "$COPILOT_DIR/skills/$skill_name/"
      echo "  ✓ Installed skill: $skill_name"
    fi
  done
  
  # Copy prompts
  for prompt_file in "$SCRIPT_DIR"/.github/prompts/devflow*.prompt.md; do
    if [ -f "$prompt_file" ]; then
      filename=$(basename "$prompt_file")
      cp "$prompt_file" "$COPILOT_DIR/prompts/"
      echo "  ✓ Installed prompt: $filename"
    fi
  done
  
else
  echo "📥 Downloading from GitHub..."
  
  TEMP_DIR=$(mktemp -d)
  trap "rm -rf $TEMP_DIR" EXIT
  
  # Clone with depth 1 for speed
  if ! git clone --depth 1 https://github.com/abdias98/DevFlow.git "$TEMP_DIR" 2>/dev/null; then
    echo "❌ Failed to clone repository. Check your internet connection or GitHub access."
    exit 1
  fi
  
  # Copy skills
  for skill_dir in "$TEMP_DIR"/.agents/skills/devflow-*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      mkdir -p "$COPILOT_DIR/skills/$skill_name"
      cp "$skill_dir"* "$COPILOT_DIR/skills/$skill_name/"
      echo "  ✓ Installed skill: $skill_name"
    fi
  done
  
  # Copy prompts
  for prompt_file in "$TEMP_DIR"/.github/prompts/devflow*.prompt.md; do
    if [ -f "$prompt_file" ]; then
      filename=$(basename "$prompt_file")
      cp "$prompt_file" "$COPILOT_DIR/prompts/"
      echo "  ✓ Installed prompt: $filename"
    fi
  done
fi

echo ""
echo "✅ DevFlow Framework installed successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 Available Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Full Lifecycle:"
echo "    /devflow <feature description>"
echo ""
echo "  Individual Phases:"
echo "    /devflow-architect   - Phase 1: Architecture & Design"
echo "    /devflow-plan        - Phase 2: Implementation Planning"
echo "    /devflow-test        - Phase 3: TDD Test Writing"
echo "    /devflow-implement   - Phase 4: Code Implementation"
echo "    /devflow-review      - Phase 5: Code Review"
echo "    /devflow-debug       - Phase 6: Debugging"
echo ""
echo "  Agent Mode:"
echo "    @devflow Build a REST API"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔄 Next Steps:"
echo "  1. Reload VS Code (Ctrl+Shift+P → Developer: Reload Window)"
echo "  2. Try a command: /devflow Implement user authentication"
echo "  3. Read docs: https://github.com/abdias98/DevFlow/wiki"
echo ""
