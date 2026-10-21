#!/usr/bin/env bats
#
# Behavioral test suite for scripts/validate-framework.sh.
#
# Scope: §15 (multi-agent contract integrity) — the first check in the script
# that verifies behaviour rather than structure, so it is the first that can be
# wrong in a way inspection won't reveal — plus §16 (finding evidence contract)
# §17 (review dimension load), §18 (standards loading & skip signals) and §19
# (review checklist single source), §20 (framework memory contract) and §22
# (evidence & verification contracts).
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

# ── §9b: editor profile capabilities must declare `runtime` (F76, PR25) ───────

# Writes $FIXTURE/editor-profiles/<name>.yaml with a permissions.strategy of
# "none" (so §9a never fires) and a capabilities block built from the given
# "key:value" pairs.
mk_profile() { # mk_profile <name> [key:value...]
  mkdir -p "$FIXTURE/editor-profiles"
  {
    echo "id: $1"
    echo "permissions:"
    echo "  strategy: none"
    echo "capabilities:"
    local kv
    for kv in "${@:2}"; do
      echo "  ${kv%%:*}: ${kv##*:}"
    done
  } > "$FIXTURE/editor-profiles/$1.yaml"
}

@test "§9b: a profile missing capabilities.runtime is an ERROR" {
  mk_profile sample subagents:true vision:true terminal:true filesystem:true

  run_section 9 10
  [[ "$output" == *"ERROR"*"sample.yaml — capabilities.runtime is missing"* ]]
}

@test "§9b: a profile declaring capabilities.runtime raises no runtime error" {
  mk_profile sample subagents:true vision:true terminal:true filesystem:true runtime:true

  run_section 9 10
  [[ "$output" != *"capabilities.runtime"* ]]
  [[ "$output" != *"ERROR"* ]]
}

# ── §20: framework memory contract (F97–F104) ─────────────────────────────────

run_section_20() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/20\\. Framework memory contract/,/════/p'"
}

# A framework-memory.md and a devflow-ctl whose types and statuses agree.
mk_memory_contract() {
  mkdir -p "$SHARED/bin"
  # A real (if tiny) CLI: §8 parses its dispatcher, so it must have one.
  cat > "$SHARED/bin/devflow-ctl" <<'CTL'
#!/usr/bin/env bash
MEMORY_TYPES="escape friction"
MEMORY_STATUSES="candidate retired"
CMD="${1:-}"
case "$CMD" in
  memory) : ;;
esac
CTL
  chmod +x "$SHARED/bin/devflow-ctl"
  cat > "$SHARED/framework-memory.md" <<'DOC'
# Framework Memory

type: escape | friction
status: candidate | retired   # comment

## Capture

| Type | Trigger | Recorded by |
|---|---|---|
| `friction` | x | y |
| `escape` | x | y |
DOC
}

LOAD='Then **Load Memory** ([framework-memory.md](x) → Load Memory): `devflow-ctl memory query --agent a`.'

@test "§20: readers that load the framework memory and a consistent doc pass" {
  mk_memory_contract
  mk_skill devflow-plan "3. **Read the knowledge base** (\`docs/devflow/knowledge-base/learnings.md\`) — patterns. $LOAD"

  run_section_20
  [[ "$output" == *"[OK]"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "§20: a knowledge-base reader without the Load Memory step is an ERROR naming file and line" {
  mk_memory_contract
  mk_skill devflow-plan "Intro" "3. **Read the knowledge base** (\`docs/devflow/knowledge-base/learnings.md\`) — patterns."

  run_section_20
  [[ "$output" == *"devflow-plan/SKILL.md:3 — reads the knowledge base without the Load Memory step"* ]]
}

@test "§20: a skill naming the store's internals is an ERROR; framework-memory.md itself may" {
  mk_memory_contract
  echo 'Stored at ~/.local/share/devflow/memory/entries.' >> "$SHARED/framework-memory.md"
  mk_skill devflow-review "Append to friction.log directly."

  run_section_20
  [[ "$output" == *"devflow-review/SKILL.md:2 — names the framework memory store's internals"* ]]
  [[ "$output" != *"framework-memory.md:"*"internals"* ]]
}

@test "§20: documented types that drift from devflow-ctl are an ERROR" {
  mk_memory_contract
  sed -i 's/^type: escape | friction$/type: escape | friction | correction/' "$SHARED/framework-memory.md"

  run_section_20
  [[ "$output" == *"entry types 'correction escape friction' differ from devflow-ctl's MEMORY_TYPES 'escape friction'"* ]]
}

@test "§20: a type with no Capture row is an ERROR" {
  mk_memory_contract
  sed -i '/^| `escape` |/d' "$SHARED/framework-memory.md"

  run_section_20
  [[ "$output" == *"entry type 'escape' has no row in the Capture table"* ]]
}

# ── §9a: permission rules written the way each editor evaluates them ──────────

# mk_json_profile <name> <snippet-json> — a json-merge profile and its snippet.
mk_json_profile() {
  mkdir -p "$FIXTURE/editor-profiles/permissions"
  printf 'id: %s\npermissions:\n  strategy: json-merge\n  config_file: "$HOME/x.json"\n  snippet: %s.json\ncapabilities:\n  subagents: true\n  vision: true\n  terminal: true\n  filesystem: true\n  runtime: true\n' "$1" "$1" \
    > "$FIXTURE/editor-profiles/$1.yaml"
  printf '%s\n' "$2" > "$FIXTURE/editor-profiles/permissions/$1.json"
}

@test "§9a: a Write(path) rule for Claude Code is an ERROR (Claude Code never consults it)" {
  mk_json_profile claude '{"permissions": {"allow": ["Edit(docs/**)", "Write(docs/**)"]}}'
  run_section 9 10
  [[ "$output" == *"claude.json — allow: Write(docs/**) — Claude Code never consults Write(path) rules"* ]]
  [[ "$output" != *"Edit(docs/**) —"* ]]
}

@test "§9a: a single-slash or \$VAR path in a Read/Edit rule is an ERROR; // and ~/ pass" {
  mk_json_profile claude '{"permissions": {"allow": ["Read($SKILLS_DIR/**)", "Read(/abs/**)", "Read(//abs/**)", "Read(~/x/**)"]}}'
  run_section 9 10
  [[ "$output" == *'Read($SKILLS_DIR/**) — a path starting with one'* ]]
  [[ "$output" == *'Read(/abs/**) — a path starting with one'* ]]
  [[ "$output" != *'Read(//abs/**) —'* ]]
  [[ "$output" != *'Read(~/x/**) —'* ]]
}

@test "§9a: an opencode allow after a deny is an ERROR (the last matching rule wins)" {
  mk_json_profile oc '{"permission": {"bash": {"git commit --no-verify*": "deny", "git commit *": "allow"}}}'
  run_section 9 10
  [[ "$output" == *"oc.json — permission.bash: 1 rule(s) follow a stricter one"* ]]
}

@test "§9a: rules being retired are not checked as installed rules" {
  mk_json_profile claude '{"_devflow_retired": {"permissions": {"allow": ["Write(docs/**)"]}}, "permissions": {"allow": ["Edit(docs/**)"]}}'
  run_section 9 10
  [[ "$output" != *"ERROR"* ]]
}

# ── §22: evidence & verification contracts (F106–F112) ────────────────────────

run_section_22() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/22\\. Evidence & verification contracts/,/23\\. Review intake|════/p'"
}

# A devflow-ctl with the evidence command, the Stack Profile table it reads,
# gate files that call `evidence check` and snippets with the ask rule.
mk_evidence_contract() {
  mkdir -p "$SHARED/bin" "$SHARED/standards" "$FIXTURE/editor-profiles/permissions"
  cat > "$SHARED/bin/devflow-ctl" <<'CTL'
#!/usr/bin/env bash
_evidence_key() {
  case "$1" in
    test)   echo "Test Command" ;;
    format) echo "Format Command" ;;
  esac
}
cmd_evidence() { :; }
CMD="${1:-}"
case "$CMD" in
  evidence) cmd_evidence ;;
esac
CTL
  chmod +x "$SHARED/bin/devflow-ctl"
  printf '## Stack Profile\n| Key | Value |\n|---|---|\n| **Test Command** | {npm test} |\n| **Format Command** | {prettier --write {files}} |\n' > "$SHARED/memory-conventions.md"
  printf '# Standalone\nRun devflow-ctl evidence check --kind test.\n' > "$SHARED/standalone-execution.md"
  local a
  for a in devflow-implement devflow-finalize devflow-review; do mk_skill "$a" "Run \`devflow-ctl evidence check --kind test\`."; done
  printf '# REST\n## 1. Naming\n## 17. Contract Test Coverage\n' > "$SHARED/standards/rest-api.md"
  echo '{"permissions": {"allow": ["Bash(devflow-ctl *)"], "ask": ["Bash(devflow-ctl evidence run*)"]}}' > "$FIXTURE/editor-profiles/permissions/claude-code.json"
}

@test "§22: a consistent evidence contract passes" {
  mk_evidence_contract
  run_section_22
  [[ "$output" == *"[OK]"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "§22: a gate phase that never calls evidence check is an ERROR naming it" {
  mk_evidence_contract
  mk_skill devflow-finalize "Run {Test Command} and read the result."
  run_section_22
  [[ "$output" == *"devflow-finalize/SKILL.md — never calls 'devflow-ctl evidence check'"* ]]
}

@test "§22: a key devflow-ctl reads but the Stack Profile lacks is an ERROR; so is Format without {files}" {
  mk_evidence_contract
  printf '## Stack Profile\n| Key | Value |\n|---|---|\n| **Format Command** | {prettier --write .} |\n' > "$SHARED/memory-conventions.md"
  run_section_22
  [[ "$output" == *"Stack Profile has no 'Test Command' row"* ]]
  [[ "$output" == *"Format Command row does not mention the {files} placeholder"* ]]
}

@test "§22: a questions template whose DoD lacks → verify: is an ERROR" {
  mk_evidence_contract
  mkdir -p "$FIXTURE/.agents/skills/devflow-feature"
  printf '## Summary\n### Definition of Done\n- {criterion 1}\n### Scope\n' > "$FIXTURE/.agents/skills/devflow-feature/questions-template.md"
  run_section_22
  [[ "$output" == *"devflow-feature/questions-template.md — Definition of Done criteria without"* ]]
  printf '### Definition of Done\n- {criterion} → verify: {test} — {observable}\n' > "$FIXTURE/.agents/skills/devflow-feature/questions-template.md"
  run_section_22
  [[ "$output" != *"questions-template.md"* ]]
}

@test "§22: a citation of a section the standard does not have is an ERROR with file and line" {
  mk_evidence_contract
  mk_skill devflow-plan "Derive contract tests per rest-api.md §17." "Status codes per rest-api.md §3."
  run_section_22
  [[ "$output" == *"devflow-plan/SKILL.md:3 — cites 'rest-api.md §3', but rest-api.md has no section 3"* ]]
  [[ "$output" != *"§17'"* ]]
}

@test "§22: a snippet that allows devflow-ctl without asking for evidence run is an ERROR" {
  mk_evidence_contract
  echo '{"permissions": {"allow": ["Bash(devflow-ctl *)"], "ask": []}}' > "$FIXTURE/editor-profiles/permissions/claude-code.json"
  echo '{"permission": {"bash": {"devflow-ctl *": "allow"}}}' > "$FIXTURE/editor-profiles/permissions/opencode.json"
  echo '{"chat.tools.terminal.autoApprove": {"/devflow-ctl/": true}}' > "$FIXTURE/editor-profiles/permissions/vscode.json"
  run_section_22
  [[ "$output" == *"claude-code.json — permissions.ask has no 'devflow-ctl evidence run' rule"* ]]
  [[ "$output" == *"opencode.json — permission.bash has no 'devflow-ctl evidence run': ask rule"* ]]
  [[ "$output" == *"vscode.json — autoApprove has no false rule"* ]]
}

@test "§22: without the evidence command in devflow-ctl, only the citation and DoD checks apply" {
  mkdir -p "$SHARED/standards"
  printf '# REST\n## 1. Naming\n' > "$SHARED/standards/rest-api.md"
  mk_skill devflow-finalize "Run {Test Command} and read the result."
  run_section_22
  [[ "$output" != *"never calls"* ]]
  [[ "$output" == *"[OK]"* ]]
}

# ── §10: pinned-install examples follow the release version ──────────────────

run_section_10() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/10\\. Version sync/,/== 11\\./p'"
}

mk_release() { # mk_release <package-version> <pinned-version>
  printf '{"name": "x", "version": "%s"}\n' "$1" > "$FIXTURE/package.json"
  printf '{"name": "x", "version": "%s", "lockfileVersion": 1}\n' "$1" > "$FIXTURE/package-lock.json"
  printf '# Changelog\n\n## [%s] — 2026-10-19\n' "$1" > "$FIXTURE/CHANGELOG.md"
  printf 'git verify-tag v%s\ngit checkout v%s\nDEVFLOW_REF=v%s bash install.sh\n' "$2" "$2" "$2" > "$FIXTURE/README.md"
  printf '#!/usr/bin/env bash\n# set DEVFLOW_REF to a signed tag (e.g. v%s);\n' "$2" > "$FIXTURE/install.sh"
}

@test "§10: pinned-install examples that name the release version pass" {
  mk_release 4.18.0 4.18.0
  run_section_10
  [[ "$output" == *"pinned-install examples are in sync"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "§10: a pinned-install example left at the previous release is an ERROR with file and line" {
  mk_release 4.18.0 4.17.0
  run_section_10
  [[ "$output" == *"README.md:1 — pinned-install example names v4.17.0, but the release is v4.18.0"* ]]
  [[ "$output" == *"README.md:3 —"* ]]
  [[ "$output" == *"install.sh:2 —"* ]]
}

# ── §12.6: the documented standard count matches the library (F118) ───────────

run_section_12() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/12\\. Standards integrity/,/== 13\\./p'"
}

@test "§12.6: a documented standard count that differs from the library is an ERROR with file and line" {
  mkdir -p "$SHARED/standards"
  printf '# A\n' > "$SHARED/standards/a.md"
  printf '# B\n' > "$SHARED/standards/b.md"
  printf '# Changelog\n' > "$SHARED/standards/CHANGELOG.md"
  printf 'Intro\nApplies 3 standards (A, B, C).\n' > "$FIXTURE/README.md"
  printf -- '- 2 engineering standards loaded by agents\n' > "$FIXTURE/AGENTS.md"
  run_section_12
  [[ "$output" == *"README.md:2 — documents 3 standards, but the library has 2"* ]]
  [[ "$output" != *"AGENTS.md:1 — documents"* ]]
}


# ── §23: review intake & knowledge contracts (F119–F126) ─────────────────────

run_section_23() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -nE '/23\\. Review intake/,/════/p'"
}

# A devflow-ctl with the knowledge store and pr watch, closing write-backs
# that sync and check, and snippets that ask for pr watch start/stop.
mk_intake_contract() {
  mkdir -p "$SHARED/bin" "$FIXTURE/editor-profiles/permissions"
  cat > "$SHARED/bin/devflow-ctl" <<'CTL'
#!/usr/bin/env bash
_kn_sync() { :; }
_pr_watch() { :; }
CMD="${1:-}"
case "$CMD" in
  knowledge) _kn_sync ;;
esac
CTL
  chmod +x "$SHARED/bin/devflow-ctl"
  local close='Run `devflow-ctl knowledge sync`, then `devflow-ctl artifacts check learnings docs/x.md --slug {slug}`.'
  mk_skill devflow-finalize "$close" 'Record it: `devflow-ctl escape add --class c --layer l --ref "r" --note "n" --slug <that cycle'"'"'s slug>`.'
  mk_skill devflow-review "$close" '`gh pr view --comments` is not enough: it omits inline threads.'
  printf '# Standalone\n%s\n' "$close" > "$SHARED/standalone-execution.md"
  cat > "$FIXTURE/editor-profiles/permissions/claude-code.json" <<'JSON'
{"permissions": {"allow": ["Bash(devflow-ctl *)"],
  "ask": ["Bash(devflow-ctl evidence run*)", "Bash(devflow-ctl pr watch start*)", "Bash(devflow-ctl pr watch stop*)"]}}
JSON
}

@test "§23: a consistent intake contract passes (the line explaining why gh pr view is not enough is allowed)" {
  mk_intake_contract
  run_section_23
  [[ "$output" == *"[OK]"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "§23: telling the agent to read a PR with gh pr view --comments is an ERROR with file and line" {
  mk_intake_contract
  printf '# Escape\n\nRead it with `gh pr view {n} --comments` and classify.\n' > "$SHARED/escape-analysis.md"
  run_section_23
  [[ "$output" == *"shared/escape-analysis.md:3 — reads a PR with 'gh pr view --comments'"* ]]
}

@test "§23: an escape add without --slug in a closing or intake step is an ERROR" {
  mk_intake_contract
  mk_skill devflow-finalize 'Run `devflow-ctl knowledge sync` and `devflow-ctl artifacts check learnings x --slug s`.' 'Then `devflow-ctl escape add --class c --layer l --ref "r" --note "n"`.'
  run_section_23
  [[ "$output" == *"devflow-finalize/SKILL.md:3 — 'devflow-ctl escape add' without --slug"* ]]
}

@test "§23: a closing write-back that never syncs the knowledge store is an ERROR — only once devflow-ctl has it" {
  mk_intake_contract
  printf '# Standalone\nWrite learnings.md.\n' > "$SHARED/standalone-execution.md"
  run_section_23
  [[ "$output" == *"shared/standalone-execution.md — never runs 'devflow-ctl knowledge sync'"* ]]
  [[ "$output" == *"shared/standalone-execution.md — never runs 'devflow-ctl artifacts check learnings'"* ]]
  sed -i '/_kn_sync/d' "$SHARED/bin/devflow-ctl"
  run_section_23
  [[ "$output" != *"never runs"* ]]
}

@test "§23: a snippet that allows devflow-ctl without asking for pr watch start/stop is an ERROR" {
  mk_intake_contract
  echo '{"permissions": {"allow": ["Bash(devflow-ctl *)"], "ask": ["Bash(devflow-ctl evidence run*)"]}}' > "$FIXTURE/editor-profiles/permissions/claude-code.json"
  echo '{"chat.tools.terminal.autoApprove": {"/devflow-ctl/": true, "/devflow-ctl\\b.*\\bpr\\s+watch\\s+(start|stop)\\b/": false}}' > "$FIXTURE/editor-profiles/permissions/vscode.json"
  run_section_23
  [[ "$output" == *"claude-code.json — permissions.ask has no 'devflow-ctl pr watch start' rule"* ]]
  [[ "$output" == *"claude-code.json — permissions.ask has no 'devflow-ctl pr watch stop' rule"* ]]
  [[ "$output" != *"vscode.json"* ]]
}
