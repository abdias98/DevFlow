#!/usr/bin/env bats
#
# Tests for the eval scoring engine. We don't run a model here — we feed the
# engine a synthetic task with known pass/fail weights and assert the math,
# the exit code (pass/fail vs threshold), the JSON scorecard, and the helper
# checks. Same dogfooding discipline as devflow-ctl.
#
# Run: ./node_modules/.bin/bats tests/devflow-eval.bats

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  EVAL="$REPO/eval/bin/devflow-eval"
  TASK="$BATS_TEST_TMPDIR/task"
  RESULT="$BATS_TEST_TMPDIR/result"
  mkdir -p "$TASK" "$RESULT"
}

# Build a synthetic task with a given threshold and checks body.
make_task() { # make_task <threshold> <checks-body>
  cat > "$TASK/task.md" <<EOF
---
id: synthetic
title: Synthetic scoring task
complexity: routine
threshold: $1
---
EOF
  printf '%s\n' "$2" > "$TASK/checks.sh"
}

@test "score: computes weighted percentage (3 of 5 = 60%)" {
  make_task 50 'check 3 "passes" true
check 2 "fails" false'
  run "$EVAL" score "$TASK" "$RESULT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"3/5 = **60%**"* ]]
  [[ "$output" == *"1 passed, 1 failed"* ]]
}

@test "score: exits 0 when at or above threshold" {
  make_task 60 'check 3 "passes" true
check 2 "fails" false'
  run "$EVAL" score "$TASK" "$RESULT"
  [ "$status" -eq 0 ]
}

@test "score: exits 1 when below threshold" {
  make_task 80 'check 3 "passes" true
check 2 "fails" false'
  run "$EVAL" score "$TASK" "$RESULT"
  [ "$status" -eq 1 ]
}

@test "score: writes a machine-readable scorecard.json" {
  make_task 50 'check 3 "passes" true
check 2 "fails" false'
  run "$EVAL" score "$TASK" "$RESULT"
  [ -f "$RESULT/scorecard.json" ]
  run jq -r '.percent' "$RESULT/scorecard.json"
  [ "$output" = "60" ]
  run jq -r '.passed' "$RESULT/scorecard.json"
  [ "$output" = "true" ]
}

@test "score: a fully-passing task scores 100%" {
  make_task 100 'check 1 "a" true
check 4 "b" true'
  run "$EVAL" score "$TASK" "$RESULT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"5/5 = **100%**"* ]]
}

@test "helper: devflow_artifact detects a produced spec" {
  mkdir -p "$RESULT/docs/devflow/specs"
  echo "# spec" > "$RESULT/docs/devflow/specs/2026-06-24-x-design.md"
  make_task 50 'check 1 "spec exists" devflow_artifact spec
check 1 "review missing" devflow_artifact review'
  run "$EVAL" score "$TASK" "$RESULT"
  [[ "$output" == *"1/2 = **50%**"* ]]
}

@test "helper: file_matches checks content with a regex" {
  printf 'name: tool\nflags: --json --verbose\n' > "$RESULT/help.txt"
  make_task 50 'check 1 "has --json" file_matches help.txt --json
check 1 "has --xml" file_matches help.txt --xml'
  run "$EVAL" score "$TASK" "$RESULT"
  [[ "$output" == *"1/2 = **50%**"* ]]
}

@test "list: shows the seed golden tasks" {
  run "$EVAL" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"001-cli-json-flag"* ]]
  [[ "$output" == *"002-rest-health-endpoint"* ]]
}

@test "score: usage error when arguments are missing" {
  run "$EVAL" score
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage"* ]]
}

@test "score: errors on a nonexistent task" {
  run "$EVAL" score "$BATS_TEST_TMPDIR/nope" "$RESULT"
  [ "$status" -eq 2 ]
}
