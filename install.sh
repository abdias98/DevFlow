#!/bin/bash
# DevFlow Installation Script
# Installs the DevFlow multi-agent framework globally.
# Editor-specific paths, tool mappings, and messages are driven by
# editor-profiles/*.yaml — zero hardcoded editor logic beyond OS detection.

set -e

# Allow overriding the source repository (security: configurable, not hardcoded)
DEVFLOW_REPO="${DEVFLOW_REPO:-https://github.com/abdias98/DevFlow.git}"

echo "🚀 Installing DevFlow Framework..."
echo ""

# ── Detect OS and resolve env vars used by editor profiles ───────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
  OS_NAME="macOS"
  BIN_DIR="/usr/local/bin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  VSCODE_USER_DIR="$HOME/.config/Code/User"
  OS_NAME="Linux"
  BIN_DIR="$HOME/.local/bin"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  VSCODE_USER_DIR="$APPDATA/Code/User"
  OS_NAME="Windows"
  BIN_DIR="/usr/local/bin"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

echo "📍 Detected OS: $OS_NAME"
echo ""

# ── YAML helpers ──────────────────────────────────────────────────────────────

# parse_yaml_value <file> <section> <key>
# Returns the value of <key> under <section> in a flat YAML file.
# If section is empty, reads top-level keys. If section is set, reads indented keys under that section.
# Strips surrounding quotes and leading/trailing whitespace.
parse_yaml_value() {
  local file="$1" section="$2" key="$3"
  
  if [[ -z "$section" ]]; then
    # Top-level key: just look for "key: value"
    awk "
      /^${key}:/ {
        sub(/^${key}: */, \"\")
        gsub(/^['\"]|['\"]$/, \"\")
        print
        exit
      }
    " "$file"
  else
    # Sectioned key: look for "section:" then indented "  key: value"
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

# parse_yaml_section <file> <section>
# Prints all key: value lines under <section> as "key=value" pairs (with = replacing :).
# Used to iterate tool_mappings and path_mappings dynamically.
parse_yaml_section() {
  local file="$1" section="$2"
  awk "
    /^${section}:/ { in_section=1; next }
    in_section && /^[^ ]/ && !/^  / { in_section=0 }
    in_section && /^  [a-zA-Z]/ {
      sub(/^  /, \"\")
      gsub(/['\"]/, \"\")
      sub(/:/, \"=\")
      print
    }
  " "$file"
}

# load_editor_profile <yaml_file>
# Reads an editor profile YAML and sets global variables:
#   EDITOR_ID, EDITOR_NAME, SKILLS_DIR, PROMPTS_DIR, INSTR_DIR, AGENTS_DIR,
#   TOOL_SUBSTITUTION, RELOAD_MSG, USAGE_CMD, PROFILE_FILE
# Resolves paths by substituting known variables ($HOME, $VSCODE_USER_DIR) only.
load_editor_profile() {
  local yaml="$1"
  PROFILE_FILE="$yaml"

  EDITOR_ID="$(parse_yaml_value "$yaml" "" "id")"
  EDITOR_NAME="$(parse_yaml_value "$yaml" "" "display_name")"

  # Read raw paths and substitute only known variables for security.
  local raw_skills raw_prompts raw_instr raw_agents
  raw_skills="$(parse_yaml_value "$yaml" "paths" "skills")"
  raw_prompts="$(parse_yaml_value "$yaml" "paths" "prompts")"
  raw_instr="$(parse_yaml_value "$yaml" "paths" "instructions")"
  raw_agents="$(parse_yaml_value "$yaml" "paths" "agents")"

  # Explicit substitution of known variables (no eval to prevent RCE).
  # Only $HOME and $VSCODE_USER_DIR are expanded.
  SKILLS_DIR="${raw_skills//\$HOME/$HOME}"
  SKILLS_DIR="${SKILLS_DIR//\$VSCODE_USER_DIR/$VSCODE_USER_DIR}"
  
  PROMPTS_DIR="${raw_prompts//\$HOME/$HOME}"
  PROMPTS_DIR="${PROMPTS_DIR//\$VSCODE_USER_DIR/$VSCODE_USER_DIR}"
  
  INSTR_DIR="${raw_instr//\$HOME/$HOME}"
  INSTR_DIR="${INSTR_DIR//\$VSCODE_USER_DIR/$VSCODE_USER_DIR}"
  
  AGENTS_DIR="${raw_agents//\$HOME/$HOME}"
  AGENTS_DIR="${AGENTS_DIR//\$VSCODE_USER_DIR/$VSCODE_USER_DIR}"

  TOOL_SUBSTITUTION="$(parse_yaml_value "$yaml" "install" "tool_substitution")"
  RELOAD_MSG="$(parse_yaml_value "$yaml" "post_install" "reload_message")"
  USAGE_CMD="$(parse_yaml_value "$yaml" "post_install" "usage_command")"
}

# copy_devflow_file <src> <dst>
# Copies a skill or prompt file to the destination, applying substitutions from
# tool_mappings and path_mappings in the loaded editor profile.
# When tool_substitution is false, copies as-is (fast path for VS Code).
copy_devflow_file() {
  local src="$1"
  local dst="$2"

  local base_sed_expr="-e 's|{{AGENTS_DIR}}|${AGENTS_DIR}|g'"

  if [[ "$TOOL_SUBSTITUTION" != "true" ]]; then
    eval "sed $base_sed_expr \"$src\"" > "$dst"
    return
  fi

  # Build a combined sed expression from both tool_mappings and path_mappings.
  # This avoids multiple passes over the file.
  local sed_expr="$base_sed_expr"

  # Tool mappings: from_tool -> to_tool (or REMOVE)
  # Match the exact markdown token format (`tool`) instead of using \b,
  # which is not a portable word-boundary operator in sed.
  while IFS=": " read -r from to; do
    [[ -z "$from" || -z "$to" ]] && continue
    from_esc=$(sed 's/[&|/\]/\\&/g' <<<"$from")
    to_esc=$(sed 's/[&|/\]/\\&/g' <<<"$to")
    if [[ "$to" == "REMOVE" ]]; then
      sed_expr="${sed_expr} -e '/\`${from_esc}\`/d'"
    elif [[ "$from" != "$to" ]]; then
      sed_expr="${sed_expr} -e 's|\`${from_esc}\`|\`${to_esc}\`|g'"
    fi
  done < <(parse_yaml_section "$PROFILE_FILE" "tool_mappings")

  # Path mappings: memory_root, docs_root, etc. (or REMOVE)
  while IFS=": " read -r from to; do
    [[ -z "$from" || -z "$to" ]] && continue
    # Escape forward slashes in paths for sed
    from_esc=$(sed 's/[&/\]/\\&/g' <<<"$from")
    to_esc=$(sed 's/[&/\]/\\&/g' <<<"$to")
    if [[ "$to" == "REMOVE" ]]; then
      # Remove any line that contains this path
      sed_expr="${sed_expr} -e '/${from_esc}/d'"
    elif [[ "$from" != "$to" ]]; then
      sed_expr="${sed_expr} -e 's|${from_esc}|${to_esc}|g'"
    fi
  done < <(parse_yaml_section "$PROFILE_FILE" "path_mappings")

  if [[ -z "$sed_expr" ]]; then
    cp "$src" "$dst"
  else
    eval "sed $sed_expr \"$src\"" > "$dst"
  fi
}

# ── Discover supported editors from editor-profiles/*.yaml ──────────────────
# Each YAML defines paths.base — if that directory exists, the editor is present.
# Detection (directory check) stays in install.sh; paths come entirely from YAML.
# To add a new editor: create editor-profiles/{id}.yaml — no other changes needed.

# SOURCE_DIR must be known before we can iterate profiles
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -d "$SCRIPT_DIR/.agents/skills" ]; then
  SOURCE_DIR="$SCRIPT_DIR"
else
  echo "📥 Downloading from GitHub: $DEVFLOW_REPO"
  TEMP_DIR=$(mktemp -d)
  trap "rm -rf '$TEMP_DIR'" EXIT
  if ! git clone --depth 1 "$DEVFLOW_REPO" "$TEMP_DIR" 2>/dev/null; then
    echo "❌ Failed to clone repository. Check your internet connection or GitHub access."
    exit 1
  fi
  SOURCE_DIR="$TEMP_DIR"
fi

# Scan all profiles (installed or not)
ALL_PROFILES=()
INSTALLED_PROFILES=()
for profile_yaml in "$SOURCE_DIR"/editor-profiles/*.yaml; do
  [ -f "$profile_yaml" ] || continue
  profile_id="$(parse_yaml_value "$profile_yaml" "" "id")"
  [[ -z "$profile_id" ]] && continue

  # Resolve paths.base to check if the editor is installed on this machine
  raw_base="$(parse_yaml_value "$profile_yaml" "paths" "base")"
  eval "resolved_base=\"$raw_base\""

  ALL_PROFILES+=("$profile_yaml")
  
  # generic is always usable; others require the directory to exist
  if [[ "$profile_id" == "generic" ]] || [ -d "$resolved_base" ]; then
    INSTALLED_PROFILES+=("$profile_yaml")
  fi
done

if [ ${#ALL_PROFILES[@]} -eq 0 ]; then
  echo "❌ No editor profiles found in the installation package."
  exit 1
fi

# ── Interactive editor selection ─────────────────────────────────────────────
# Always prompt the user to choose, even if only one editor is detected.
# Show installation status (installed / not detected) for each profile.
echo "📍 Select installation target:"
echo ""
idx=1
for p in "${ALL_PROFILES[@]}"; do
  profile_id="$(parse_yaml_value "$p" "" "id")"
  name="$(parse_yaml_value "$p" "" "display_name")"
  raw_base="$(parse_yaml_value "$p" "paths" "base")"
  eval "resolved_base=\"$raw_base\""
  
  # Determine status
  if [[ "$profile_id" == "generic" ]]; then
    status="always available"
  elif [ -d "$resolved_base" ]; then
    status="installed"
  else
    status="not detected"
  fi
  
  printf "  %d) %-20s [%s]\n" "$idx" "$name" "$status"
  idx=$((idx + 1))
done
echo ""

# Validate user input
while true; do
  read -rp "Enter number [1-${#ALL_PROFILES[@]}]: " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#ALL_PROFILES[@]}" ]; then
    SELECTED_PROFILE="${ALL_PROFILES[$((choice - 1))]}"
    break
  else
    echo "  ❌ Invalid choice. Please enter a number between 1 and ${#ALL_PROFILES[@]}."
  fi
done

# Load and validate the selected profile
load_editor_profile "$SELECTED_PROFILE"
if ! grep -q "^id:" "$SELECTED_PROFILE" 2>/dev/null; then
  echo "❌ Selected profile is invalid or corrupted."
  exit 1
fi
selected_id="$(parse_yaml_value "$SELECTED_PROFILE" "" "id")"
echo "📍 Selected: $EDITOR_NAME"

echo "📍 Skills   → $SKILLS_DIR"
echo "📍 Prompts  → $PROMPTS_DIR"
echo ""

# DevFlow store: where skills and instructions are kept for workspace init
DEVFLOW_STORE="$HOME/.devflow"

# ── Detect and cleanup previous installation (v1.2.x) ──────────────────────
if [ -d "$DEVFLOW_STORE" ] || [ -d "$VSCODE_USER_DIR/.agents/skills" ] 2>/dev/null || [ -d "$VSCODE_USER_DIR/.github/prompts" ] 2>/dev/null; then
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
  
  echo "✅ Cleanup complete. Installing v2.3.0..."
  echo ""
fi

# Create required directories
mkdir -p "$SKILLS_DIR"
mkdir -p "$PROMPTS_DIR"
mkdir -p "$INSTR_DIR"
mkdir -p "$AGENTS_DIR"
mkdir -p "$BIN_DIR"

echo "📦 Installing from: $SOURCE_DIR"
if [ "$SOURCE_DIR" = "$SCRIPT_DIR" ]; then
  echo "📂 Installing from local repository..."
fi


# ── Global: prompts → editor prompts dir (with tool-name substitutions) ──────
for prompt_file in "$SOURCE_DIR"/.github/prompts/devflow*.prompt.md; do
  if [ -f "$prompt_file" ]; then
    filename=$(basename "$prompt_file")
    copy_devflow_file "$prompt_file" "$PROMPTS_DIR/$filename"
    echo "  ✓ Installed prompt (global): $filename"
  fi
done

# ── Global: skills → editor skills dir (with tool-name substitutions) ────────
for skill_dir in "$SOURCE_DIR"/.agents/skills/devflow-*/; do
  if [ -d "$skill_dir" ]; then
    skill_name=$(basename "$skill_dir")
    mkdir -p "$SKILLS_DIR/$skill_name"
    for skill_file in "$skill_dir"/*; do
      if [ -f "$skill_file" ]; then
        copy_devflow_file "$skill_file" "$SKILLS_DIR/$skill_name/$(basename "$skill_file")"
      fi
    done
    echo "  ✓ Installed skill (global): $skill_name"
  fi
done

# ── Global: instructions → editor instructions dir (with tool/path substitutions) ──
  for instr_file in "$SOURCE_DIR"/.github/instructions/*.instructions.md; do
    if [ -f "$instr_file" ]; then
      filename=$(basename "$instr_file")
      copy_devflow_file "$instr_file" "$INSTR_DIR/$filename"
      echo "  ✓ Installed instructions (global): $filename"
    fi
  done
echo ""
# ── Configure global gitignore (zero impact on projects) ────────────────────
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
echo "  1. $RELOAD_MSG"
echo "  2. Open your AI chat and use:  $USAGE_CMD"
echo ""
echo "  DevFlow is now available in all your $EDITOR_NAME workspaces!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
