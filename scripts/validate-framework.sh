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

# ── 8. devflow-ctl integrity ─────────────────────────────────────────────────
header "8. devflow-ctl integrity"

CTL="$SKILLS_DIR/shared/bin/devflow-ctl"

if [[ ! -f "$CTL" ]]; then
  fail "shared/bin/devflow-ctl — script not found"
elif [[ ! -x "$CTL" ]]; then
  fail "shared/bin/devflow-ctl — not executable (run: chmod +x $CTL)"
  $FIX_MODE && echo "       FIX: chmod +x $CTL"
elif ! bash -n "$CTL" 2>/dev/null; then
  fail "shared/bin/devflow-ctl — bash syntax check failed (bash -n)"
else
  green "devflow-ctl exists, is executable, and passes bash -n"
fi

# Every `devflow-ctl <subcommand>` referenced in skill files must exist in the CLI dispatcher.
if [[ -f "$CTL" ]]; then
  VALID_SUBCOMMANDS=$(awk '/^case "\$CMD" in/,/^esac/' "$CTL" | grep -oP '^\s+\K[a-z|-]+(?=\))' | tr '|' '\n')
  bad_refs=0
  while IFS= read -r file <&3; do
    while IFS= read -r sub; do
      if ! grep -qx "$sub" <<<"$VALID_SUBCOMMANDS"; then
        fail "$file — references unknown devflow-ctl subcommand: '$sub'"
        ((bad_refs++)) || true
      fi
    done < <(grep -oP 'devflow-ctl \K[a-z-]+' "$file" 2>/dev/null | sort -u || true)
  done 3< <(find "$SKILLS_DIR" -name "*.md" -type f)
  [[ $bad_refs -eq 0 ]] && green "All devflow-ctl subcommand references in skills are valid"
fi

# ── 9. Editor profile permissions ────────────────────────────────────────────
header "9. Editor profile permissions"

PROFILES_DIR="editor-profiles"

if [[ -d "$PROFILES_DIR" ]]; then
  for profile in "$PROFILES_DIR"/*.yaml; do
    [[ -f "$profile" ]] || continue
    strategy=$(awk '/^permissions:/{f=1;next} f&&/^[^ ]/{f=0} f&&/^  strategy:/{sub(/^  strategy: */,"");gsub(/["'"'"']/,"");print;exit}' "$profile")
    if [[ -z "$strategy" ]]; then
      fail "$profile — missing permissions.strategy (none|manual|json-merge)"
      $FIX_MODE && echo "       FIX: add a 'permissions:' section with 'strategy: none|manual|json-merge'"
      continue
    fi
    case "$strategy" in
      none) ;;
      manual)
        note=$(awk '/^permissions:/{f=1;next} f&&/^[^ ]/{f=0} f&&/^  manual_note:/{print "x";exit}' "$profile")
        [[ -z "$note" ]] && warn "$profile — strategy 'manual' without manual_note (nothing will be shown to the user)"
        ;;
      json-merge)
        snippet=$(awk '/^permissions:/{f=1;next} f&&/^[^ ]/{f=0} f&&/^  snippet:/{sub(/^  snippet: */,"");gsub(/["'"'"']/,"");print;exit}' "$profile")
        config=$(awk '/^permissions:/{f=1;next} f&&/^[^ ]/{f=0} f&&/^  config_file:/{print "x";exit}' "$profile")
        if [[ -z "$snippet" || -z "$config" ]]; then
          fail "$profile — strategy 'json-merge' requires both snippet and config_file"
        elif [[ ! -f "$PROFILES_DIR/permissions/$snippet" ]]; then
          fail "$profile — permission snippet not found: $PROFILES_DIR/permissions/$snippet"
        elif command -v python3 >/dev/null 2>&1 && ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$PROFILES_DIR/permissions/$snippet" 2>/dev/null; then
          fail "$PROFILES_DIR/permissions/$snippet — invalid JSON"
        elif command -v python3 >/dev/null 2>&1; then
          # Guardrail: no destructive/sensitive patterns in the allow tier.
          # See editor-profiles/permissions/README.md for the tier model.
          guardrail_out=$(python3 - "$PROFILES_DIR/permissions/$snippet" <<'GUARDEOF'
import json, sys

FORBIDDEN = ["rm ", "rmdir", "git push", "--force", "--no-verify",
             "--amend", "sudo ", "chmod ", "chown ", "kill ", "pkill ",
             "npm install", "yarn add", "pip install"]

with open(sys.argv[1]) as fh:
    data = json.load(fh)

violations = []

# Claude Code: permissions.allow is a list of "Bash(...)" / "Read(...)" patterns
for entry in data.get("permissions", {}).get("allow", []):
    low = entry.lower()
    violations.extend(entry for bad in FORBIDDEN if bad in low)

# opencode: permission.bash is a map of pattern -> "allow"|"ask"|"deny"
for pattern, verdict in data.get("permission", {}).get("bash", {}).items():
    if verdict == "allow":
        low = pattern.lower()
        violations.extend(pattern for bad in FORBIDDEN if bad in low)

# VS Code: chat.tools.terminal.autoApprove is a map of regex -> true
node = data
for key in ("chat", "tools", "terminal", "autoApprove"):
    node = node.get(key, {}) if isinstance(node, dict) else {}
if isinstance(node, dict):
    for regex in node:
        low = regex.lower()
        violations.extend(regex for bad in FORBIDDEN if bad in low)

print("\n".join(violations))
GUARDEOF
          )
          if [[ -n "$guardrail_out" ]]; then
            fail "$PROFILES_DIR/permissions/$snippet — destructive patterns in allow tier (move to ask/deny):"
            while IFS= read -r line; do
              [[ -n "$line" ]] && echo "         • $line"
            done <<< "$guardrail_out"
          fi
        fi
        ;;
      *)
        fail "$profile — unknown permissions.strategy: '$strategy' (expected none|manual|json-merge)"
        ;;
    esac
  done
  # Every snippet must belong to a profile
  if [[ -d "$PROFILES_DIR/permissions" ]]; then
    for snip in "$PROFILES_DIR/permissions"/*.json; do
      [[ -f "$snip" ]] || continue
      if ! grep -q "snippet: *[\"']*$(basename "$snip")" "$PROFILES_DIR"/*.yaml 2>/dev/null; then
        warn "$snip — not referenced by any editor profile"
      fi
    done
  fi
  [[ $ERRORS -eq 0 ]] && green "All editor profiles declare a valid permissions strategy"

  # ── 9b. Editor profile capabilities ──────────────────────────────────────
  for profile in "$PROFILES_DIR"/*.yaml; do
    [[ -f "$profile" ]] || continue
    has_caps=$(awk '/^capabilities:/{print "x";exit}' "$profile")
    if [[ -z "$has_caps" ]]; then
      fail "$profile — missing capabilities section (see shared/environment-probe.md)"
      $FIX_MODE && echo "       FIX: add a 'capabilities:' section with subagents, vision, terminal, filesystem"
      continue
    fi
    for cap in subagents vision terminal filesystem; do
      val=$(awk '/^capabilities:/{f=1;next} f&&/^[^ ]/{f=0} f&&/^  '"$cap"':/{sub(/^  '"$cap"': */,"");gsub(/["'"'"']/,"");print;exit}' "$profile")
      if [[ -z "$val" ]]; then
        fail "$profile — capabilities.$cap is missing (must be true or false)"
      elif [[ "$val" != "true" && "$val" != "false" ]]; then
        fail "$profile — capabilities.$cap must be 'true' or 'false' (got '$val')"
      fi
    done
  done
  [[ $ERRORS -eq 0 ]] && green "All editor profiles declare valid capabilities"
else
  warn "$PROFILES_DIR/ not found — skipping permissions check (run from the repo root)"
fi

# ── 10. Version sync (package.json ↔ package-lock.json ↔ CHANGELOG.md) ────────
header "10. Version sync"

if [[ -f package.json ]]; then
  PKG_VERSION=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' package.json | head -1)
  if [[ -z "$PKG_VERSION" ]]; then
    fail "package.json — could not extract version"
  else
    # package-lock.json must carry the same version (top-level and root package entry)
    if [[ -f package-lock.json ]]; then
      LOCK_VERSION=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' package-lock.json | head -1)
      if [[ "$LOCK_VERSION" != "$PKG_VERSION" ]]; then
        fail "package-lock.json version ($LOCK_VERSION) does not match package.json ($PKG_VERSION)"
        $FIX_MODE && echo "       FIX: update package-lock.json (npm install --package-lock-only)"
      fi
    fi
    # The released version must have a CHANGELOG entry
    if ! grep -q "^## \[$PKG_VERSION\]" CHANGELOG.md 2>/dev/null; then
      fail "CHANGELOG.md — no entry found for version $PKG_VERSION (package.json)"
      $FIX_MODE && echo "       FIX: add '## [$PKG_VERSION] — YYYY-MM-DD' to CHANGELOG.md or fix the package version"
    fi
    # Hardcoded versions in install.sh drift silently — forbid them
    if grep -qE "Installing v[0-9]+\.[0-9]+\.[0-9]+" install.sh 2>/dev/null; then
      fail "install.sh — hardcoded version string found (read it from package.json instead)"
    fi
    [[ $ERRORS -eq 0 ]] && green "package.json ($PKG_VERSION), package-lock.json, and CHANGELOG.md are in sync"
  fi
else
  warn "package.json not found — skipping version sync check (run from the repo root)"
fi

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
