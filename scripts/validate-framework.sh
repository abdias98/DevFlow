#!/usr/bin/env bash
# DevFlow Framework Self-Validation Script
# Verifies internal consistency of all skill files:
#   1. Unresolved {{...}} template variables
#   2. Broken cross-references between skill files
#   3. Missing required sections in SKILL.md files
#   4. Unreferenced files in shared/
#   5. Version header presence in standards
#
# Usage:
#   bash scripts/validate-framework.sh           # from repo root
#   bash scripts/validate-framework.sh --fix     # print fix hints
#
# Exit codes: 0 = OK, 1 = errors found

set -euo pipefail

SKILLS_DIR=".agents/skills"
ERRORS=0
WARNINGS=0
FIX_MODE=false

[[ "${1:-}" == "--fix" ]] && FIX_MODE=true

red()    { echo -e "\033[0;31m[ERROR]\033[0m $*"; }
yellow() { echo -e "\033[0;33m[WARN]\033[0m  $*"; }
green()  { echo -e "\033[0;32m[OK]\033[0m    $*"; }
header() { echo -e "\n\033[1m== $* ==\033[0m"; }

fail() { red "$@"; ((ERRORS++)) || true; }
warn() { yellow "$@"; ((WARNINGS++)) || true; }

# ── 1. Unknown / typo'd template variables ───────────────────────────────────
header "1. Template variable integrity"

# Known valid template variables (substituted by install.sh)
KNOWN_VARS=("SKILLS_DIR" "AGENTS_DIR" "PROMPTS_DIR" "INSTR_DIR")

while IFS= read -r file; do
  # Find all {{...}} usages
  while IFS= read -r match; do
    var_name=$(echo "$match" | grep -oP '(?<=\{\{)[A-Z_]+(?=\}\})')
    known=false
    for kv in "${KNOWN_VARS[@]}"; do
      [[ "$var_name" == "$kv" ]] && known=true && break
    done
    if ! $known; then
      fail "$file — unknown/typo template variable: {{${var_name}}}"
      $FIX_MODE && echo "       FIX: Valid variables are: $(printf '{{%s}} ' "${KNOWN_VARS[@]}")"
    fi
  done < <(grep -on "{{[A-Z_]*}}" "$file" 2>/dev/null | sed 's/^/Line /' || true)
done < <(find "$SKILLS_DIR" -name "*.md" -type f)

[[ $ERRORS -eq 0 ]] && green "All template variables use known names ({{SKILLS_DIR}}, etc.)"

# ── 2. Broken cross-references ───────────────────────────────────────────────
header "2. Broken cross-references (<{{SKILLS_DIR}}/...> links)"

# Use fd 3 for the outer file list to avoid stdin conflict with inner pipe
broken_refs=0
while IFS= read -r file <&3; do
  while IFS= read -r ref; do
    target="$SKILLS_DIR/$ref"
    if [[ ! -f "$target" ]]; then
      fail "$file → broken reference: <{{SKILLS_DIR}}/$ref> (file not found)"
      $FIX_MODE && echo "       FIX: create '$target' or update the reference path"
      ((broken_refs++)) || true
    fi
  done < <(grep -oP '(?<=<\{\{SKILLS_DIR\}\}/)([^>]+)(?=>)' "$file" 2>/dev/null || true)
done 3< <(find "$SKILLS_DIR" -name "*.md" -type f)

[[ $broken_refs -eq 0 ]] && green "All cross-references resolve to existing files"

# ── 3. Required sections in SKILL.md files ───────────────────────────────────
header "3. Required sections in SKILL.md files"

REQUIRED_SECTIONS=("## Rules" "## Procedure")

while IFS= read -r skill_file; do
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^${section}" "$skill_file" 2>/dev/null; then
      fail "$skill_file — missing required section: '$section'"
    fi
  done
done < <(find "$SKILLS_DIR" -name "SKILL.md" -not -path "*/shared/*" -type f)

# Check all SKILL.md files reference common rules
while IFS= read -r skill_file; do
  if ! grep -q "shared/rules.md" "$skill_file" 2>/dev/null; then
    warn "$skill_file — does not reference shared/rules.md"
  fi
done < <(find "$SKILLS_DIR" -name "SKILL.md" -not -path "*/shared/*" -type f)

[[ $ERRORS -eq 0 ]] && green "All SKILL.md files have required sections"

# ── 4. Unreferenced shared files ─────────────────────────────────────────────
header "4. Unreferenced files in shared/"

while IFS= read -r shared_file; do
  # rel is relative to SKILLS_DIR (e.g. "shared/critical-friend.md")
  rel="${shared_file#$SKILLS_DIR/}"
  basename_file=$(basename "$shared_file")
  # Search for any reference to this file across all skill files (exclude itself)
  if ! grep -rl "$basename_file" "$SKILLS_DIR" --include="*.md" 2>/dev/null | grep -qv "$(realpath "$shared_file" 2>/dev/null || echo "$shared_file")"; then
    warn "$rel — no other skill file references this file"
    $FIX_MODE && echo "       FIX: add a reference in the relevant SKILL.md or remove the file if unused"
  fi
done < <(find "$SKILLS_DIR/shared" -name "*.md" -not -path "*/standards/*" -not -name "CHANGELOG.md" -not -name "i18n-*.md" -type f)

# ── 5. Version headers in standards ──────────────────────────────────────────
header "5. Version headers in standards"

while IFS= read -r std_file; do
  if ! grep -q "^\*\*Version:\*\*\|^> \*\*Version:\*\*" "$std_file" 2>/dev/null; then
    fail "$std_file — missing version header (expected '> **Version:** X.Y.Z')"
  fi
  if ! grep -q "Severity Classification" "$std_file" 2>/dev/null; then
    warn "$std_file — missing '## Severity Classification' section"
    $FIX_MODE && echo "       FIX: add a Severity Classification section with BLOCK/WARN/INFO triggers"
  fi
done < <(find "$SKILLS_DIR/shared/standards" -name "*.md" -not -name "CHANGELOG.md" -type f)

[[ $ERRORS -eq 0 ]] && green "All standards have version headers"

# ── 6. Standalone skills with Critical Friend check ──────────────────────────
header "6. Standalone skills — Critical Friend check step"

# Standalone agents that handle user requests should have a critical friend check
STANDALONE_AGENTS=(
  "devflow-feature"
  "devflow-bug-fix"
  "devflow-refactor"
  "devflow-perf"
  "devflow-debug"
  "devflow-migrate"
)

for agent in "${STANDALONE_AGENTS[@]}"; do
  skill_file="$SKILLS_DIR/$agent/SKILL.md"
  if [[ -f "$skill_file" ]]; then
    if ! grep -qi "Critical Friend" "$skill_file" 2>/dev/null; then
      fail "$skill_file — missing Critical Friend check step"
      $FIX_MODE && echo "       FIX: add a Step 1.5 Critical Friend check referencing shared/critical-friend.md"
    fi
  else
    warn "Expected $skill_file — file not found (agent may have been removed)"
  fi
done

[[ $ERRORS -eq 0 ]] && green "All standalone agents have Critical Friend check"

# ── 7. Artifact paths consistency ────────────────────────────────────────────
header "7. Artifact path consistency"

# Each standalone agent should declare a canonical artifact path
ARTIFACT_PATTERNS=(
  "docs/devflow/features/"
  "docs/devflow/bug-fixes/"
  "docs/devflow/refactors/"
  "docs/devflow/specs/"
  "docs/devflow/plans/"
  "docs/devflow/reviews/"
)

declare -A SKILL_ARTIFACT_MAP=(
  ["devflow-feature"]="docs/devflow/features/"
  ["devflow-bug-fix"]="docs/devflow/bug-fixes/"
  ["devflow-refactor"]="docs/devflow/refactors/"
  ["devflow-architect"]="docs/devflow/specs/"
  ["devflow-plan"]="docs/devflow/plans/"
  ["devflow-review"]="docs/devflow/reviews/"
)

for agent in "${!SKILL_ARTIFACT_MAP[@]}"; do
  skill_file="$SKILLS_DIR/$agent/SKILL.md"
  expected_path="${SKILL_ARTIFACT_MAP[$agent]}"
  if [[ -f "$skill_file" ]]; then
    if ! grep -q "$expected_path" "$skill_file" 2>/dev/null; then
      warn "$skill_file — expected artifact path '$expected_path' not found in skill"
    fi
  fi
done

[[ $WARNINGS -eq 0 && $ERRORS -eq 0 ]] && green "Artifact paths look consistent"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
if [[ $ERRORS -gt 0 ]]; then
  red "Validation FAILED — $ERRORS error(s), $WARNINGS warning(s)"
  echo "Run with --fix for remediation hints"
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  yellow "Validation passed with $WARNINGS warning(s)"
  exit 0
else
  green "Validation passed — framework is consistent ✓"
  exit 0
fi
