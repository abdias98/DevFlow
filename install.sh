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
echo "📍 DevFlow store:    $DEVFLOW_STORE"
echo ""

# Create required directories
mkdir -p "$USER_DIR/prompts"
mkdir -p "$DEVFLOW_STORE/skills"
mkdir -p "$DEVFLOW_STORE/instructions"
mkdir -p "$DEVFLOW_STORE/prompts"
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

# ── DevFlow store: prompts (used by devflow-init per workspace) ─────────────
for prompt_file in "$SOURCE_DIR"/.github/prompts/devflow*.prompt.md; do
  if [ -f "$prompt_file" ]; then
    filename=$(basename "$prompt_file")
    cp "$prompt_file" "$DEVFLOW_STORE/prompts/$filename"
    echo "  ✓ Stored prompt: $filename"
  fi
done

# ── DevFlow store: skills (used by devflow-init per workspace) ───────────────
for skill_dir in "$SOURCE_DIR"/.agents/skills/devflow-*/; do
  if [ -d "$skill_dir" ]; then
    skill_name=$(basename "$skill_dir")
    mkdir -p "$DEVFLOW_STORE/skills/$skill_name"
    cp -r "$skill_dir". "$DEVFLOW_STORE/skills/$skill_name/"
    echo "  ✓ Stored skill: $skill_name"
  fi
done

# ── DevFlow store: instructions (used by devflow-init per workspace) ─────────
for instr_file in "$SOURCE_DIR"/.github/instructions/*.instructions.md; do
  if [ -f "$instr_file" ]; then
    filename=$(basename "$instr_file")
    cp "$instr_file" "$DEVFLOW_STORE/instructions/$filename"
    echo "  ✓ Stored instructions: $filename"
  fi
done

echo ""
echo "✅ DevFlow Framework installed successfully!"
echo ""

# ── Install devflow-init command ──────────────────────────────────────────────
INIT_SCRIPT_SRC="${SCRIPT_DIR:-$(pwd)}/devflow-init.sh"
if [ -f "$INIT_SCRIPT_SRC" ]; then
  cp "$INIT_SCRIPT_SRC" "$BIN_DIR/devflow-init"
  chmod +x "$BIN_DIR/devflow-init"
  echo "🔧 Command installed: devflow-init → $BIN_DIR/devflow-init"
fi

# Ensure BIN_DIR is in PATH (write to shell rc if missing)
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  SHELL_RC="$HOME/.bashrc"
  [[ "$SHELL" == */zsh ]] && SHELL_RC="$HOME/.zshrc"
  if ! grep -qF "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
    echo "📌 Added $BIN_DIR to PATH in $SHELL_RC — run: source $SHELL_RC"
  fi
fi

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
echo "  2. Open Copilot Chat and type:  @devflow <feature>"
echo ""
echo "  To enable skills in a specific project:"
echo "    cd ~/path/to/your/project"
echo "    devflow-init"
echo "    (then reload VS Code)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
