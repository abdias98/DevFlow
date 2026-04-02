#!/bin/bash
# DevFlow Installation Script
# Installs the DevFlow multi-agent framework globally in VS Code

set -e

echo "🚀 Installing DevFlow Framework..."
echo ""

# Detect OS and set paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  USER_DIR="$HOME/Library/Application Support/Code/User"
  OS_NAME="macOS"
  BIN_DIR="/usr/local/bin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  USER_DIR="$HOME/.config/Code/User"
  OS_NAME="Linux"
  BIN_DIR="$HOME/.local/bin"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  USER_DIR="$APPDATA/Code/User"
  OS_NAME="Windows"
  BIN_DIR="/usr/local/bin"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

# DevFlow store: where skills and instructions are kept for workspace init
DEVFLOW_STORE="$HOME/.devflow"

echo "📍 Detected OS: $OS_NAME"
echo "📍 VS Code User dir: $USER_DIR"
echo ""

# ── Detect and cleanup previous installation (v1.2.x) ──────────────────────
if [ -d "$DEVFLOW_STORE" ] || [ -f "$USER_DIR/.agents/skills" ] 2>/dev/null || [ -f "$USER_DIR/.github/prompts" ] 2>/dev/null; then
  echo "📦 Previous DevFlow installation detected (v1.2.x or earlier)"
  echo "🧹 Cleaning up old files..."
  
  if [ -d "$DEVFLOW_STORE" ]; then
    rm -rf "$DEVFLOW_STORE"
    echo "  ✓ Removed DevFlow store: $DEVFLOW_STORE"
  fi
  
  # Remove old devflow-init command
  for bin_dir in "$HOME/.local/bin" "/usr/local/bin"; do
    if [ -f "$bin_dir/devflow-init" ]; then
      rm -f "$bin_dir/devflow-init"
      echo "  ✓ Removed command: $bin_dir/devflow-init"
    fi
  done
  
  echo "✅ Cleanup complete. Installing v2.0.0..."
  echo ""
fi

# Create required directories
mkdir -p "$USER_DIR/prompts"
mkdir -p "$USER_DIR/.agents/skills"
mkdir -p "$USER_DIR/.github/instructions"
mkdir -p "$BIN_DIR"

echo "📦 Downloading DevFlow repository..."

# Determine where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If running from a cloned repo, copy local files
if [ -d "$SCRIPT_DIR/.agents/skills" ]; then
  echo "📂 Installing from local repository..."
  SOURCE_DIR="$SCRIPT_DIR"
else
  echo "📥 Downloading from GitHub..."
  TEMP_DIR=$(mktemp -d)
  trap "rm -rf $TEMP_DIR" EXIT
  if ! git clone --depth 1 https://github.com/abdias98/DevFlow.git "$TEMP_DIR" 2>/dev/null; then
    echo "❌ Failed to clone repository. Check your internet connection or GitHub access."
    exit 1
  fi
  SOURCE_DIR="$TEMP_DIR"
fi

# ── Global: agent file → VS Code User dir (works in ALL workspaces) ──────────
for agent_file in "$SOURCE_DIR"/.github/agents/*.agent.md; do
  if [ -f "$agent_file" ]; then
    filename=$(basename "$agent_file")
    cp "$agent_file" "$USER_DIR/$filename"
    echo "  ✓ Installed agent (global): $filename"
  fi
done

# ── Global: prompts → VS Code User prompts dir ───────────────────────────────
for prompt_file in "$SOURCE_DIR"/.github/prompts/devflow*.prompt.md; do
  if [ -f "$prompt_file" ]; then
    filename=$(basename "$prompt_file")
    cp "$prompt_file" "$USER_DIR/prompts/$filename"
    echo "  ✓ Installed prompt (global): $filename"
  fi
done

# ── Global: skills → VS Code User .agents/skills dir ──────────────────────
for skill_dir in "$SOURCE_DIR"/.agents/skills/devflow-*/; do
  if [ -d "$skill_dir" ]; then
    skill_name=$(basename "$skill_dir")
    mkdir -p "$USER_DIR/.agents/skills/$skill_name"
    cp -r "$skill_dir". "$USER_DIR/.agents/skills/$skill_name/"
    echo "  ✓ Installed skill (global): $skill_name"
  fi
done

# ── Global: instructions → VS Code User .github/instructions dir ────────────
for instr_file in "$SOURCE_DIR"/.github/instructions/*.instructions.md; do
  if [ -f "$instr_file" ]; then
    filename=$(basename "$instr_file")
    cp "$instr_file" "$USER_DIR/.github/instructions/$filename"
    echo "  ✓ Installed instructions (global): $filename"
  fi
done

echo ""
echo "✅ DevFlow Framework installed successfully!"
echo ""

echo ""
# ── Configure global gitignore (Opción A: zero impact on projects) ──────────
GLOBAL_GITIGNORE="$HOME/.gitignore_global"
git config --global core.excludesFile "$GLOBAL_GITIGNORE" 2>/dev/null || true
for entry in ".agents/" ".github/instructions/devflow-*.instructions.md" ".github/prompts/devflow*.prompt.md"; do
  if ! grep -qxF "$entry" "$GLOBAL_GITIGNORE" 2>/dev/null; then
    echo "$entry" >> "$GLOBAL_GITIGNORE"
  fi
done
echo "🔒 Global gitignore configured: $GLOBAL_GITIGNORE"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 How to Use DevFlow"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Reload VS Code (Ctrl+Shift+P → Developer: Reload Window)"
echo "  2. Open Copilot Chat and use:  @devflow <feature request>"
echo ""
echo "  DevFlow is now available in all your workspaces!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
