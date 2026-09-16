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
  [[ "$output" == *"003-order-payment-lifecycle"* ]]
  [[ "$output" == *"004-project-panel-tab"* ]]
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

# ── Outcome / process split ───────────────────────────────────────────────────

@test "split: reports outcome and process subscores separately" {
  make_task 50 'check_outcome 4 "works" true
check_process 1 "spec produced" false'
  run "$EVAL" score "$TASK" "$RESULT"
  [[ "$output" == *"Outcome:** 4/4 = **100%**"* ]]
  [[ "$output" == *"Process:** 0/1 = **0%**"* ]]
}

@test "split: pass is decided by outcome, not by process paperwork" {
  # Deliverable works, zero process artifacts — must still PASS.
  make_task 50 'check_outcome 4 "works" true
check_process 1 "spec produced" false'
  run "$EVAL" score "$TASK" "$RESULT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"✅ PASS"* ]]
}

@test "split: perfect process cannot rescue a failing outcome" {
  make_task 80 'check_outcome 1 "works" false
check_outcome 1 "other" true
check_process 5 "spec produced" true'
  run "$EVAL" score "$TASK" "$RESULT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"❌ FAIL"* ]]
}

@test "split: JSON carries outcome_percent and process_percent" {
  make_task 50 'check_outcome 3 "works" true
check_process 2 "spec produced" false'
  run "$EVAL" score "$TASK" "$RESULT"
  run jq -r '.outcome_percent' "$RESULT/scorecard.json"
  [ "$output" = "100" ]
  run jq -r '.process_percent' "$RESULT/scorecard.json"
  [ "$output" = "0" ]
  run jq -r '.passed' "$RESULT/scorecard.json"
  [ "$output" = "true" ]
}

@test "split: a plain check counts as outcome (back-compat)" {
  make_task 50 'check 1 "a" true
check 1 "b" false'
  run "$EVAL" score "$TASK" "$RESULT"
  [[ "$output" == *"Process:** 0/0 = **n/a**"* ]]
  [[ "$output" == *"Outcome:** 1/2 = **50%**"* ]]
}

# ── Helpers: artifact-any and managed server lifecycle ────────────────────────

@test "helper: devflow_artifact_any passes if any named type exists" {
  mkdir -p "$RESULT/docs/devflow/reviews"
  echo x > "$RESULT/docs/devflow/reviews/r.md"
  make_task 50 'check_process 1 "validation or review" devflow_artifact_any validation review
check_process 1 "summary only" devflow_artifact_any summary'
  run "$EVAL" score "$TASK" "$RESULT"
  [[ "$output" == *"Process:** 1/2 = **50%**"* ]]
}

@test "helper: eval_serve manages a server and leaves no leaked process" {
  printf 'require("http").createServer((q,s)=>{s.writeHead(200);s.end("ok");}).listen(process.env.PORT);\n' \
    > "$RESULT/server.js"
  make_task 50 'eval_serve_start "node server.js evalbats-leakcheck" /
check 1 "server answers 200" test "$(eval_http GET /)" = 200
eval_serve_stop'
  run "$EVAL" score "$TASK" "$RESULT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1/1 = **100%**"* ]]
  # The managed server must be torn down — its whole process group killed.
  sleep 1
  run pgrep -f evalbats-leakcheck
  [ "$status" -ne 0 ]
}

# ── init: seeding a workspace from a task fixture ─────────────────────────────

make_fixture_task() {
  make_task 50 'check 1 "seeded" test -f app.txt'
  mkdir -p "$TASK/fixture" "$TASK/reference/good"
  echo "fixture" > "$TASK/fixture/app.txt"
  echo "base" > "$TASK/fixture/keep.txt"
  echo "reference" > "$TASK/reference/good/app.txt"
}

@test "init: copies the fixture into a new workspace" {
  make_fixture_task
  run "$EVAL" init "$TASK" "$BATS_TEST_TMPDIR/ws"
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/ws/app.txt")" = "fixture" ]
  [ -f "$BATS_TEST_TMPDIR/ws/keep.txt" ]
}

@test "init: --reference overlays a reference on top of the fixture" {
  make_fixture_task
  run "$EVAL" init "$TASK" "$BATS_TEST_TMPDIR/ws" --reference good
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/ws/app.txt")" = "reference" ]
  [ -f "$BATS_TEST_TMPDIR/ws/keep.txt" ]
}

@test "init: refuses to seed a non-empty destination" {
  make_fixture_task
  mkdir -p "$BATS_TEST_TMPDIR/ws"; echo work > "$BATS_TEST_TMPDIR/ws/existing.txt"
  run "$EVAL" init "$TASK" "$BATS_TEST_TMPDIR/ws"
  [ "$status" -eq 2 ]
  [[ "$output" == *"not empty"* ]]
  [ ! -f "$BATS_TEST_TMPDIR/ws/app.txt" ]
}

@test "init: errors on a task without a fixture or an unknown reference" {
  make_task 50 'check 1 "x" true'
  run "$EVAL" init "$TASK" "$BATS_TEST_TMPDIR/ws"
  [ "$status" -eq 2 ]
  [[ "$output" == *"no fixture"* ]]
  make_fixture_task
  run "$EVAL" init "$TASK" "$BATS_TEST_TMPDIR/ws2" --reference missing
  [ "$status" -eq 2 ]
  [[ "$output" == *"no reference"* ]]
}

# ── Calibration of the behavioural golden tasks ───────────────────────────────
# A behavioural task is only useful if its checks tell implementations apart.
# Each one ships an untouched fixture, a naive reference that misses a defect
# class, and a correct reference. The fixture and the naive reference must FAIL,
# the correct one must PASS, and the naive one must fail on the behavioural
# check it was written to miss — not on something incidental.

calibrate() { # calibrate <task-id> <fixture|naive|correct>
  local ws="$BATS_TEST_TMPDIR/cal-$2"
  if [ "$2" = fixture ]; then
    "$EVAL" init "$1" "$ws" >/dev/null
  else
    "$EVAL" init "$1" "$ws" --reference "$2" >/dev/null
  fi
  run "$EVAL" score "$1" "$ws"
}

requires_node() {
  command -v node >/dev/null 2>&1 || skip "node not installed"
  command -v npm  >/dev/null 2>&1 || skip "npm not installed"
}

@test "calibration 003: untouched fixture fails" {
  requires_node
  calibrate 003-order-payment-lifecycle fixture
  [ "$status" -eq 1 ]
}

@test "calibration 003: naive reference fails on the concurrency check only" {
  requires_node
  calibrate 003-order-payment-lifecycle naive
  [ "$status" -eq 1 ]
  [[ "$output" == *"| ❌ | outcome | 3 | [concurrency]"* ]]
  [ "$(grep -c '| ❌ | outcome' <<<"$output")" -eq 1 ]
}

@test "calibration 003: correct reference passes every outcome check" {
  requires_node
  calibrate 003-order-payment-lifecycle correct
  [ "$status" -eq 0 ]
  [[ "$output" == *"Outcome:** 18/18 = **100%**"* ]]
}

@test "calibration 004: untouched fixture fails" {
  requires_node
  calibrate 004-project-panel-tab fixture
  [ "$status" -eq 1 ]
}

@test "calibration 004: naive reference fails on the ordering check only" {
  requires_node
  calibrate 004-project-panel-tab naive
  [ "$status" -eq 1 ]
  [[ "$output" == *"| ❌ | outcome | 3 | [ordering]"* ]]
  [ "$(grep -c '| ❌ | outcome' <<<"$output")" -eq 1 ]
}

@test "calibration 004: correct reference passes every outcome check" {
  requires_node
  calibrate 004-project-panel-tab correct
  [ "$status" -eq 0 ]
  [[ "$output" == *"Outcome:** 17/17 = **100%**"* ]]
}
