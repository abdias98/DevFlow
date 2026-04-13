#!/bin/bash
# DevFlow Uninstallation Script
# Removes the DevFlow framework from the selected editor.
# Uses editor-profiles/*.yaml for paths — no hardcoded editor directories.

set -e

echo "🗑️  Uninstalling DevFlow Framework..."
echo ""

# Allow overriding the source repository
DEVFLOW_REPO="${DEVFLOW_REPO:-https://github.com/abdias98/DevFlow.git}"

# ── Detect OS ────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS_NAME="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS_NAME="Linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  OS_NAME="Windows"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

echo "📍 Detected OS: $OS_NAME"
echo ""

# ── YAML helpers ───────────────────────────────────────────────────────────────

parse_yaml_value() {
  local file="$1" section="$2" key="$3"
  if [[ -z "$section" ]]; then
    awk "
      /^${key}:/ {
        sub(/^${key}: */, \"\")
        gsub(/^['\"]|['\"]$/, \"\")
        print
        exit
      }
    " "$file"
  else
    awk "
      /^${section}:/ { in_section=1; next }
      in_section && /^[^ ]/ && !/^  / { in_section=0 }
      in_section && /^  ${key}:/ {
        sub(/^  ${key}: */, \"\")
        gsub(/^['\"]|['\"]$/, \"\")
        print
        exit
      }
    " "$file"
  fi
}

# ── Locate profiles directory ─────────────────────────────────────────────────
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -d "$SCRIPT_DIR/editor-profiles" ]; then
  SOURCE_DIR="$SCRIPT_DIR"
else
  echo "📥 Downloading profiles from GitHub: $DEVFLOW_REPO"
  TEMP_DIR=$(mktemp -d)
  trap "rm -rf '$TEMP_DIR'" EXIT
  if ! command -v git >/dev/null 2>&1; then
    echo "❌ Git is required to download editor profiles, but it is not installed or not in PATH."
    exit 1
  fi
  if ! git clone --depth 1 "$DEVFLOW_REPO" "$TEMP_DIR" 2>/dev/null; then
    echo "❌ Failed to clone repository. Check your internet connection or GitHub access."
    exit 1
  fi
  SOURCE_DIR="$TEMP_DIR"
fi

# ── Interactive editor selection ──────────────────────────────────────────────
ALL_PROFILES=()
for profile_yaml in "$SOURCE_DIR"/editor-profiles/*.yaml; do
  [ -f "$profile_yaml" ] || continue
  profile_id="$(parse_yaml_value "$profile_yaml" "" "id")"
  [[ -z "$profile_id" ]] && continue
  ALL_PROFILES+=("$profile_yaml")
done

if [ ${#ALL_PROFILES[@]} -eq 0 ]; then
  echo "❌ No editor profiles found."
  exit 1
fi

echo "📍 Select editor to uninstall from:"
echo ""
idx=1
for p in "${ALL_PROFILES[@]}"; do
  name="$(parse_yaml_value "$p" "" "display_name")"
  printf "  %d) %s\n" "$idx" "$name"
  idx=$((idx + 1))
done
echo ""

while true; do
  read -rp "Enter number [1-${#ALL_PROFILES[@]}]: " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#ALL_PROFILES[@]}" ]; then
    SELECTED_PROFILE="${ALL_PROFILES[$((choice - 1))]}"
    break
  else
    echo "  ❌ Invalid choice. Please enter a number between 1 and ${#ALL_PROFILES[@]}."
  fi
done

# ── Resolve USER_DIR from the selected profile YAML ──────────────────────────
EDITOR_NAME="$(parse_yaml_value "$SELECTED_PROFILE" "" "display_name")"
raw_user_dir="$(parse_yaml_value "$SELECTED_PROFILE" "user_dir" "$OS_NAME")"
if [[ -z "$raw_user_dir" ]]; then
  echo "❌ Profile '$(basename "$SELECTED_PROFILE")' does not define user_dir for OS '$OS_NAME'."
  exit 1
fi
USER_DIR="${raw_user_dir//\$HOME/$HOME}"
USER_DIR="${USER_DIR//\$APPDATA/${APPDATA:-}}"

raw_skills="$(parse_yaml_value "$SELECTED_PROFILE" "paths" "skills")"
raw_prompts="$(parse_yaml_value "$SELECTED_PROFILE" "paths" "prompts")"
raw_instr="$(parse_yaml_value "$SELECTED_PROFILE" "paths" "instructions")"
raw_agents="$(parse_yaml_value "$SELECTED_PROFILE" "paths" "agents")"

SKILLS_DIR="${raw_skills//\$HOME/$HOME}"
SKILLS_DIR="${SKILLS_DIR//\$APPDATA/${APPDATA:-}}"
SKILLS_DIR="${SKILLS_DIR//\$USER_DIR/$USER_DIR}"

PROMPTS_DIR="${raw_prompts//\$HOME/$HOME}"
PROMPTS_DIR="${PROMPTS_DIR//\$APPDATA/${APPDATA:-}}"
PROMPTS_DIR="${PROMPTS_DIR//\$USER_DIR/$USER_DIR}"

INSTR_DIR="${raw_instr//\$HOME/$HOME}"
INSTR_DIR="${INSTR_DIR//\$APPDATA/${APPDATA:-}}"
INSTR_DIR="${INSTR_DIR//\$USER_DIR/$USER_DIR}"

AGENTS_DIR="${raw_agents//\$HOME/$HOME}"
AGENTS_DIR="${AGENTS_DIR//\$APPDATA/${APPDATA:-}}"
AGENTS_DIR="${AGENTS_DIR//\$USER_DIR/$USER_DIR}"

# Safety: abort if any resolved path is empty or is a filesystem root.
for _var in USER_DIR SKILLS_DIR PROMPTS_DIR INSTR_DIR AGENTS_DIR; do
  _val="${!_var}"
  if [[ -z "$_val" || "$_val" == "/" || "$_val" == "//" ]]; then
    echo "❌ Resolved path for $_var is empty or unsafe ('$_val'). Aborting."
    exit 1
  fi
done

echo "📍 Uninstalling from: $EDITOR_NAME"
echo "📍 Skills    → $SKILLS_DIR"
echo "📍 Prompts   → $PROMPTS_DIR"
echo ""

# ── Remove agents ─────────────────────────────────────────────────────────────
for agent_file in "$AGENTS_DIR"/devflow*.agent.md; do
  if [ -f "$agent_file" ]; then
    rm -f "$agent_file"
    echo "  ✓ Removed agent: $(basename "$agent_file")"
  fi
done

# ── Remove prompts ────────────────────────────────────────────────────────────
for prompt_file in "$PROMPTS_DIR"/devflow*.prompt.md; do
  if [ -f "$prompt_file" ]; then
    rm -f "$prompt_file"
    echo "  ✓ Removed prompt: $(basename "$prompt_file")"
  fi
done

# ── Remove skills (only devflow-* and shared) ─────────────────────────────────
for skill_dir in "$SKILLS_DIR"/devflow-*/; do
  if [ -d "$skill_dir" ]; then
    rm -rf "$skill_dir"
    echo "  ✓ Removed skill: $(basename "$skill_dir")"
  fi
done

if [ -d "$SKILLS_DIR/shared" ]; then
  rm -rf "$SKILLS_DIR/shared"
  echo "  ✓ Removed shared rules: shared/"
fi

# ── Remove instructions (only devflow-*) ──────────────────────────────────────
for instr_file in "$INSTR_DIR"/devflow-*.instructions.md; do
  if [ -f "$instr_file" ]; then
    rm -f "$instr_file"
    echo "  ✓ Removed instructions: $(basename "$instr_file")"
  fi
done

echo ""
echo "✅ DevFlow Framework uninstalled successfully from $EDITOR_NAME!"
echo ""
echo "📝 To reinstall, run:"
echo "   curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh -o install.sh && bash install.sh && rm install.sh"
echo ""
