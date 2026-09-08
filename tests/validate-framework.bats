#!/usr/bin/env bats
#
# Behavioral test suite for scripts/validate-framework.sh.
#
# Scope: §15 (multi-agent contract integrity) — the first check in the script
# that verifies behaviour rather than structure, so it is the first that can be
# wrong in a way inspection won't reveal.
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
# stops at the summary rule: the final "Validation FAILED" line is itself
# printed through red(), so letting it in would make every fixture with an
# unrelated error look like a §15 failure.
run_section_15() {
  cd "$FIXTURE" || return 1
  run bash -c "bash '$VALIDATE' 2>&1 | sed -n '/15. Multi-agent contract integrity/,/════/p'"
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
