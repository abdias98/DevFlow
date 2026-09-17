#!/usr/bin/env bats
#
# Behavioral test suite for scripts/validate-framework.sh.
#
# Scope: §15 (multi-agent contract integrity) — the first check in the script
# that verifies behaviour rather than structure, so it is the first that can be
# wrong in a way inspection won't reveal — plus §16 (finding evidence contract)
# §17 (review dimension load), §18 (standards loading & skip signals) and §19
# (review checklist single source).
#
# Run: npm test   (or: ./node_modules/.bin/bats tests/validate-framework.bats)
#
# Each test builds a throwaway framework tree under $BATS_TEST_TMPDIR and runs
# the real script from inside it. The script resolves SKILLS_DIR relative to the
# working directory and guards every section with a directory check, so the
# fixture drives §15 with no production seam.
#
# Assertions match §15's own output lines, never the process exit code: the
# other 14 sections legitimately complain about the fixture's missing
# directories, and coupling to the exit code would let unrelated noise decide
# whether the test passes.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  VALIDATE="$REPO/scripts/validate-framework.sh"
  FIXTURE="$BATS_TEST_TMPDIR/fixture"
  SHARED="$FIXTURE/.agents/skills/shared"
  mkdir -p "$SHARED"
}

# Creates $SHARED/<name>.md declaring a contract over <artifact> with the
# given "<Verb> by:<Agent>" participants.
mk_contract() {
  local name="$1" artifact="$2"; shift 2
  {
    echo "# ${name}"
    echo ""
    echo "**Contract artifact:** \`${artifact}\`"
    local p
    for p in "$@"; do
      echo "**${p%%:*} by:** ${p##*:}"
    done
  } > "$SHARED/${name}.md"
}

# Creates a SKILL.md for <agent>; any extra args are lines written into it.
mk_skill() {
  local agent="$1"; shift
  mkdir -p "$FIXTURE/.agents/skills/$agent"
  {
    echo "# ${agent}"
    local l
    for l in "$@"; do echo "$l"; done
  } > "$FIXTURE/.agents/skills/$agent/SKILL.md"
}

# Runs the validator inside the fixture and keeps only §15's block, so an
# assertion can never accidentally match another section's output. The range
# stops at the next section's header (§16) or the summary rule: the final "Validation FAILED" line is itself
# printed through red(), so letting it in would make every fixture with an
# unrelated error look like a §15 failure.
run_section_15() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/15\\. Multi-agent contract integrity/,/16\\. Finding evidence contract|════/p'"
}

# ── Positive: a fully honoured contract ───────────────────────────────────────

@test "§15: contract whose participants all reference the artifact passes" {
  mk_contract "traceability-matrix" 'docs/devflow/session/{slug}/traceability.md' \
    "Written:Planner" "Updated:Implementer"
  mk_skill devflow-plan      "The Planner generates traceability.md from the plan."
  mk_skill devflow-implement "The Implementer updates traceability.md per wave."

  run_section_15
  [[ "$output" == *"honour"* || "$output" == *"[OK]"* ]]
  [[ "$output" != *"does not reference"* ]]
}

# ── Negative: the F60 shape ───────────────────────────────────────────────────
#
# This is the test that justifies the check. F60 was exactly this: the contract
# named the Implementer and the Reviewer, and neither SKILL.md mentioned the
# artifact. If this test can be deleted without anything going red, §15 is
# decoration.

@test "§15: declared participant that never references the artifact is an ERROR" {
  mk_contract "traceability-matrix" 'docs/devflow/session/{slug}/traceability.md' \
    "Written:Planner" "Updated:Implementer"
  mk_skill devflow-plan      "The Planner generates traceability.md from the plan."
  mk_skill devflow-implement "The Implementer commits each task."   # no mention

  run_section_15
  [[ "$output" == *"[ERROR]"* ]]
  [[ "$output" == *"devflow-implement"* ]]
  [[ "$output" == *"traceability.md"* ]]
}

@test "§15: reports every unhonoured participant, not just the first" {
  mk_contract "traceability-matrix" 'docs/devflow/session/{slug}/traceability.md' \
    "Written:Planner" "Updated:Implementer" "Validated:Reviewer"
  mk_skill devflow-plan      "The Planner generates traceability.md from the plan."
  mk_skill devflow-implement "The Implementer commits each task."
  mk_skill devflow-review    "The Reviewer reads the diff."

  run_section_15
  [[ "$output" == *"devflow-implement"* ]]
  [[ "$output" == *"devflow-review"* ]]
}

# ── Edge: an agent name the validator cannot map ──────────────────────────────
#
# A typo must not silently disable enforcement for that participant — that is
# the failure mode the whole check exists to close.

@test "§15: unmapped agent name is an ERROR, not a silent skip" {
  mk_contract "traceability-matrix" 'docs/devflow/session/{slug}/traceability.md' \
    "Written:Planner" "Validated:Reviewr"
  mk_skill devflow-plan "The Planner generates traceability.md from the plan."

  run_section_15
  [[ "$output" == *"[ERROR]"* ]]
  [[ "$output" == *"Reviewr"* ]]
}

# ── Edge: a declared participant with no SKILL.md at all ─────────────────────

@test "§15: participant whose SKILL.md is missing is an ERROR" {
  mk_contract "traceability-matrix" 'docs/devflow/session/{slug}/traceability.md' \
    "Written:Planner"
  # devflow-plan/SKILL.md deliberately not created

  run_section_15
  [[ "$output" == *"[ERROR]"* ]]
  [[ "$output" == *"devflow-plan"* ]]
}

# ── Edge: nothing to check ───────────────────────────────────────────────────

@test "§15: shared tree with no contract declarations reports none, without error" {
  printf '# Just a shared doc\n\nNo contract here.\n' > "$SHARED/rules.md"

  run_section_15
  [[ "$output" == *"No multi-agent contract"* ]]
  [[ "$output" != *"[ERROR]"* ]]
}

# ── Token derivation: the date/slug placeholders must not leak into the grep ──

@test "§15: token strips YYYY-MM-DD and {slug} from the artifact basename" {
  mk_contract "metrics-template" 'docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md' \
    "Initialized:Orchestrator"
  mk_skill devflow "The Orchestrator creates the metrics.md stub at Step 0."

  run_section_15
  # Asserting only the absence of an error would pass vacuously while §15 does
  # not exist, so require the section's own success line as well.
  [[ "$output" == *"[OK]"* ]]
  [[ "$output" != *"[ERROR]"* ]]
}

@test "§15: token shorter than the floor is rejected rather than matching prose" {
  mk_contract "tiny-contract" 'docs/devflow/{slug}.md' "Written:Planner"
  mk_skill devflow-plan "The Planner writes things."

  run_section_15
  [[ "$output" == *"[ERROR]"* ]]
  [[ "$output" == *"too short"* ]]
}

# ── Multiple contracts in one tree ───────────────────────────────────────────

@test "§15: checks every declared contract independently" {
  mk_contract "traceability-matrix" 'docs/devflow/session/{slug}/traceability.md' \
    "Written:Planner"
  mk_contract "metrics-template" 'docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md' \
    "Finalized:Finalizer"
  mk_skill devflow-plan     "The Planner generates traceability.md from the plan."
  mk_skill devflow-finalize "The Finalizer closes the cycle."   # no metrics mention

  run_section_15
  [[ "$output" == *"[ERROR]"* ]]
  [[ "$output" == *"devflow-finalize"* ]]
  [[ "$output" != *"devflow-plan"* ]]
}

# ── §16: finding evidence contract (F66/F67) ─────────────────────────────────

run_section_16() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/16\\. Finding evidence contract/,/17\\. Review dimension load|════/p'"
}

# rules.md with both canonical sections.
mk_rules_with_evidence() {
  cat > "$SHARED/rules.md" <<'RULES'
# Rules

## Finding Evidence

A finding carries a standard citation or a reproducible scenario.

### Behavioral Impact Severity

| Severity | Observable impact |
|---|---|
RULES
}

@test "§16: canonical sections defined once and no citation-only rule passes" {
  mk_rules_with_evidence
  mk_skill devflow-review "Ground every finding per rules.md → Finding Evidence."

  run_section_16
  [[ "$output" == *"[OK]"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "§16: rules.md without the Finding Evidence section is an ERROR" {
  printf '# Rules\n\n### Behavioral Impact Severity\n' > "$SHARED/rules.md"

  run_section_16
  [[ "$output" == *"expected exactly one '## Finding Evidence' heading, found 0"* ]]
}

@test "§16: a skill reinstating the citation-only rule is an ERROR naming file and line" {
  mk_rules_with_evidence
  mk_skill devflow-feature "Intro" \
    '  - Cite the specific section in every finding: `{standard}.md §{N}`.'

  run_section_16
  [[ "$output" == *"devflow-feature/SKILL.md:3"* ]]
  [[ "$output" == *"citation-only finding rule"* ]]
}

@test "§16: restating the severity table under a heading outside rules.md is an ERROR" {
  mk_rules_with_evidence
  printf '# Review\n\n## Behavioral Impact Severity\n' > "$SHARED/review-notes.md"

  run_section_16
  [[ "$output" == *"review-notes.md — restates the Behavioral Impact Severity table"* ]]
}

@test "§16: prose that merely references the severity table is not an ERROR" {
  mk_rules_with_evidence
  mk_skill devflow-review "Classify it with Behavioral Impact Severity (rules.md)."

  run_section_16
  [[ "$output" != *"restates"* ]]
  [[ "$output" == *"[OK]"* ]]
}

# ── §17: review dimension load (F70) ─────────────────────────────────────────

run_section_17() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/17\\. Review dimension load/,/18\\. Standards loading|════/p'"
}

REVIEW_DIR() { echo "$FIXTURE/.agents/skills/devflow-review"; }

# SKILL.md with one dispatch row per argument: "<name>:<n standards>".
mk_review_skill() {
  mkdir -p "$(REVIEW_DIR)"
  {
    echo "# Reviewer"
    echo "| Subagent | Dimension | Standards |"
    echo "|---|---|---|"
    # Standard names are letters-only, like the real ones — the check's
    # pattern does not match digits, so "std-1.md" would count as zero.
    local names=(alpha beta gamma delta epsilon zeta eta theta iota)
    local spec name n i links
    for spec in "$@"; do
      name="${spec%%:*}"; n="${spec##*:}"; links=""
      for ((i = 0; i < n; i++)); do links+="[s](<{{SKILLS_DIR}}/shared/standards/${names[$i]}.md>) "; done
      echo "| **${name}** | dim | ${links}|"
    done
  } > "$(REVIEW_DIR)/SKILL.md"
}

# review-checklist.md: sections as args; ownership rows from $OWNERS ("Section=Owner;...").
mk_review_checklist() {
  mkdir -p "$(REVIEW_DIR)"
  {
    echo "# Review Checklist"
    echo ""
    echo "## Section Ownership"
    echo ""
    echo "| Section | Subagent |"
    echo "|---------|----------|"
    local pair
    IFS=';' read -ra pairs <<< "$OWNERS"
    for pair in "${pairs[@]}"; do echo "| ${pair%%=*} | ${pair##*=} |"; done
    echo ""
    echo "## Universal Checks (All Reviews)"
    local sec
    for sec in "$@"; do echo ""; echo "### ${sec}"; echo "- [ ] item"; done
    echo ""
    echo "## Review Document Template"
    echo "### 🔴 BLOCK (must fix)"
  } > "$(REVIEW_DIR)/review-checklist.md"
}

@test "§17: subagents within the standards cap and fully owned sections pass" {
  mk_review_skill "1 — Security:2" "3 — Design:5"
  OWNERS="Security=1 — Security;Code Quality=3 — Design" mk_review_checklist "Security" "Code Quality"

  run_section_17
  [[ "$output" == *"[OK]"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "§17: a subagent loading more than 5 standards is an ERROR" {
  mk_review_skill "3 — Architecture, Quality & Plan Compliance:9"
  OWNERS="Code Quality=3 — Architecture, Quality & Plan Compliance" mk_review_checklist "Code Quality"

  run_section_17
  [[ "$output" == *"loads 9 standards (max 5)"* ]]
}

@test "§17: a checklist section with no owner is an ERROR" {
  mk_review_skill "1 — Security:2"
  OWNERS="Security=1 — Security" mk_review_checklist "Security" "Logging"

  run_section_17
  [[ "$output" == *"section 'Logging' has 0 owners"* ]]
}

@test "§17: the cap is exclusive — 6 standards is an ERROR, 5 is not" {
  mk_review_skill "3 — Design:6" "1 — Security:5"
  OWNERS="Security=1 — Security" mk_review_checklist "Security"

  run_section_17
  [[ "$output" == *"'3 — Design' loads 6 standards"* ]]
  [[ "$output" != *"'1 — Security' loads"* ]]
}

@test "§17: a section owned twice is an ERROR" {
  mk_review_skill "1 — Security:2" "2 — Perf:2"
  OWNERS="Security=1 — Security;Security=2 — Perf" mk_review_checklist "Security"

  run_section_17
  [[ "$output" == *"section 'Security' has 2 owners"* ]]
}

@test "§17: an owner that is not a subagent in SKILL.md is an ERROR" {
  mk_review_skill "1 — Security:2"
  OWNERS="Security=9 — Ghost" mk_review_checklist "Security"

  run_section_17
  [[ "$output" == *"owned by '9 — Ghost', which is not a subagent"* ]]
}

@test "§17: a dispatch row with no standard links does not abort the validator" {
  mk_review_skill "1 — Security:2" "4 — Behavior:0"
  OWNERS="Security=1 — Security" mk_review_checklist "Security"

  run_section_17
  [[ "$output" == *"[OK]"* ]]
  # Reaching the next section's header proves the script did not abort.
  [[ "$output" == *"18. Standards loading"* ]]
}

# ── §18: standards loading & skip signals (F78/F83) ──────────────────────────

run_section_18() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/18\\. Standards loading/,/19\\. Review checklist single source|════/p'"
}

mk_loading_baseline() {
  echo "# Standards Loading" > "$SHARED/standards-loading.md"
  printf '# Adaptive\n\n### Objective Diff Signals\n' > "$SHARED/adaptive-skills.md"
  mkdir -p "$(REVIEW_DIR)"
  echo "Load standards per standards-loading.md." > "$(REVIEW_DIR)/SKILL.md"
}

@test "§18: loading policy, diff signals and a referencing Reviewer pass" {
  mk_loading_baseline

  run_section_18
  [[ "$output" == *"[OK]"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "§18: an agent still loading standards only on a red flag is an ERROR" {
  mk_loading_baseline
  mk_skill devflow-plan "Intro" "- **Standards — scan first, load on demand.** Load a full standard only when a quick-card red flag matches or the design clearly applies."

  run_section_18
  [[ "$output" == *"devflow-plan/SKILL.md:3 — legacy loading/skip rule ('scan first, load on demand')"* ]]
  [[ "$output" == *"('red flag matches or')"* ]]
}

@test "§18: a standard with no domain-signal row is an ERROR" {
  mk_loading_baseline
  mkdir -p "$SHARED/standards"
  echo "# Std" > "$SHARED/standards/alpha.md"
  echo "# Std" > "$SHARED/standards/beta.md"
  printf '| Standard | Load when |\n|---|---|\n| [alpha.md](./standards/alpha.md) | always |\n' >> "$SHARED/standards-loading.md"

  run_section_18
  [[ "$output" == *"no domain-signal row for beta.md"* ]]
  [[ "$output" != *"no domain-signal row for alpha.md"* ]]
}

@test "§18: missing standards-loading.md is an ERROR" {
  mk_loading_baseline
  rm "$SHARED/standards-loading.md"

  run_section_18
  [[ "$output" == *"standards-loading.md — missing"* ]]
}

@test "§18: a Reviewer that does not reference the loading policy is an ERROR" {
  mk_loading_baseline
  echo "Scan the quick card." > "$(REVIEW_DIR)/SKILL.md"

  run_section_18
  [[ "$output" == *"does not reference shared/standards-loading.md"* ]]
}

@test "§18: a quick-card gate or a self-assessed mechanical skip criterion is an ERROR" {
  mk_loading_baseline
  mk_skill devflow-implement "Intro" "- The implementation is mechanical (single utility)."
  printf 'Standards loading per subagent (quick-card gate): only on red flag.\n' >> "$(REVIEW_DIR)/SKILL.md"

  run_section_18
  [[ "$output" == *"devflow-implement/SKILL.md:3 — legacy loading/skip rule ('The implementation is mechanical')"* ]]
  [[ "$output" == *"devflow-review/SKILL.md:2 — legacy loading/skip rule ('quick-card gate')"* ]]
}

@test "§18: missing Objective Diff Signals section is an ERROR" {
  mk_loading_baseline
  echo "# Adaptive" > "$SHARED/adaptive-skills.md"

  run_section_18
  [[ "$output" == *"missing '### Objective Diff Signals'"* ]]
}

# ── §19: review checklist single source (F82) ────────────────────────────────

run_section_19() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -n '/19. Review checklist single source/,/════/p'"
}

# Checklist whose check region is the given lines, plus a template that is
# allowed to carry severity headings.
mk_checklist_region() {
  mkdir -p "$(REVIEW_DIR)" "$SHARED/standards"
  printf '# Std\n\n## 1. Rule One\n\n## 2. Rule Two\n' > "$SHARED/standards/sample.md"
  {
    echo "# Review Checklist"
    echo ""
    echo "## Universal Checks (All Reviews)"
    local l; for l in "$@"; do echo "$l"; done
    echo ""
    echo "## Review Document Template"
    echo "### 🔴 BLOCK (must fix)"
  } > "$(REVIEW_DIR)/review-checklist.md"
}

@test "§19: sourced items and no severities pass; template severity headings are ignored" {
  mk_checklist_region "### Code" \
    '- [ ] Rule one holds (`sample.md §1`).' \
    '- [ ] Matches the plan *(plan)*.' \
    '- [ ] Scope respected (`rules.md` → Scope-Locking).'

  run_section_19
  [[ "$output" == *"[OK]"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "§19: a severity marker in a check item is an ERROR" {
  mk_checklist_region "### Code" '- [ ] No secrets. 🔴 **BLOCK** if found (`sample.md §1`).'

  run_section_19
  [[ "$output" == *"review-checklist.md:5 — declares a severity"* ]]
}

@test "§19: an item with no source is an ERROR" {
  mk_checklist_region "### Code" '- [ ] Naming is consistent.'

  run_section_19
  [[ "$output" == *"review-checklist.md:5 — check item names no source"* ]]
}

@test "§19: a section intro line can source its items" {
  mk_checklist_region "### Behavior" \
    'Performed following correctness-guide.md.' \
    '- [ ] Logic: conditions and boundaries.'

  run_section_19
  [[ "$output" != *"names no source"* ]]
}

@test "§19: citing a section that does not exist is an ERROR" {
  mk_checklist_region "### Code" '- [ ] Rule nine holds (`sample.md §9`).'

  run_section_19
  [[ "$output" == *"cites 'sample.md §9' but sample.md has no section §9"* ]]
}

# ── §12.3 phase sections and §14 duplication after Limited Scope (F79) ────────

run_section() { # run_section <N> <next N> — only section N's output
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/== $1\\. /,/== $2\\. |════/p'"
}

# A standard with the three mandatory sections; extra args are appended lines.
mk_standard() { # mk_standard <name> [line...]
  mkdir -p "$SHARED/standards"
  local f="$SHARED/standards/$1.md"; shift
  {
    echo "# Std"
    echo "> **Version:** 1.0.0 | **Last Updated:** 2026-09-16"
    echo "## 1. Rule"
    echo "Body about a rule."
    echo "## 2. Code Review Checklist"
    echo "## 3. Severity Classification"
    echo "## 4. Applying This Standard with a Limited Scope"
    echo "This closing paragraph is intentionally identical in every standard file of the framework template."
    local l; for l in "$@"; do echo "$l"; done
  } > "$f"
}

@test "§12.3: a standard without the phase sections is an ERROR" {
  mk_standard alpha

  run_section 12 13
  grep -q "ERROR.*alpha.md — missing phase section: 'Design-Time Decisions'" <<< "$output"
  grep -q "ERROR.*alpha.md — missing phase section: 'Implementation Self-Check'" <<< "$output"
}

@test "§12.3: a standard with both phase sections raises no phase warning" {
  mk_standard alpha "## 5. Design-Time Decisions" "- decide" "## 6. Implementation Self-Check" "- [ ] check"

  run_section 12 13
  [[ "$output" != *"missing phase section"* ]]
}

@test "§14: bullet lines are compared, and sections after Limited Scope are checked" {
  local dup="- [ ] A deliberately long self-check line that two standards should never share word for word, ever."
  mk_standard alpha "## 5. Implementation Self-Check" "$dup"
  mk_standard beta "## 5. Implementation Self-Check" "$dup"

  run_section 14 15
  [[ "$output" == *"share a near-identical line"*"deliberately long self-check line"* ]]
  [[ "$output" != *"intentionally identical in every standard"* ]]
}
