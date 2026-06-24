#!/usr/bin/env bats
#
# Behavioral test suite for devflow-ctl — the deterministic enforcement engine.
# Covers the state machine and the input boundary, not just file structure.
#
# Run: npm test   (or: ./node_modules/.bin/bats tests/devflow-ctl.bats)
#
# Each test gets a unique $BATS_TEST_TMPDIR, so sessions are fully isolated
# via DEVFLOW_SESSION_ROOT and never touch the repo's docs/devflow/.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  CTL="$REPO/.agents/skills/shared/bin/devflow-ctl"
  export DEVFLOW_SESSION_ROOT="$BATS_TEST_TMPDIR/session"
}

# ── Slug validation (input boundary / path-traversal defense) ─────────────────

@test "slug: rejects path traversal (..)" {
  run "$CTL" init --mode lifecycle --slug "../evil"
  [ "$status" -eq 2 ]
  [[ "$output" == *"path traversal"* ]]
}

@test "slug: rejects path separator (/)" {
  run "$CTL" init --mode lifecycle --slug "a/b"
  [ "$status" -eq 2 ]
  [[ "$output" == *"path traversal"* ]]
}

@test "slug: rejects shell metacharacters" {
  run "$CTL" init --mode lifecycle --slug 'x;rm -rf y'
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid slug"* ]]
}

@test "slug: rejects leading dot" {
  run "$CTL" init --mode lifecycle --slug ".hidden"
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid slug"* ]]
}

@test "slug: accepts a clean kebab slug" {
  run "$CTL" init --mode lifecycle --slug valid-feature-123
  [ "$status" -eq 0 ]
}

# ── init ──────────────────────────────────────────────────────────────────────

@test "init: creates phase-state.md with frontmatter and gates" {
  run "$CTL" init --mode lifecycle --slug demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"initialized"* ]]
  [ -f "$DEVFLOW_SESSION_ROOT/demo/phase-state.md" ]
  run head -1 "$DEVFLOW_SESSION_ROOT/demo/phase-state.md"
  [ "$output" = "---" ]
}

@test "init: refuses to overwrite an existing session" {
  "$CTL" init --mode lifecycle --slug dup >/dev/null
  run "$CTL" init --mode lifecycle --slug dup
  [ "$status" -eq 2 ]
  [[ "$output" == *"already exists"* ]]
}

@test "init: requires --mode" {
  run "$CTL" init --slug nomode
  [ "$status" -eq 2 ]
  [[ "$output" == *"--mode is required"* ]]
}

# ── Gate state machine ────────────────────────────────────────────────────────

@test "gate: validation starts CLOSED" {
  "$CTL" init --mode lifecycle --slug g >/dev/null
  run "$CTL" gate check validation --slug g
  [ "$status" -eq 1 ]
  [[ "$output" == *"CLOSED"* ]]
}

@test "gate: validation opens once passed" {
  "$CTL" init --mode lifecycle --slug g >/dev/null
  "$CTL" gate set validation passed --slug g
  run "$CTL" gate check validation --slug g
  [ "$status" -eq 0 ]
  [[ "$output" == *"open"* ]]
}

@test "gate: accepted-risks is rejected from pending" {
  "$CTL" init --mode lifecycle --slug g >/dev/null
  run "$CTL" gate set validation accepted-risks --slug g
  [ "$status" -eq 2 ]
  [[ "$output" == *"from 'blocked'"* ]]
}

@test "gate: accepted-risks is allowed from blocked" {
  "$CTL" init --mode lifecycle --slug g >/dev/null
  "$CTL" gate set validation blocked --slug g
  run "$CTL" gate set validation accepted-risks --slug g
  [ "$status" -eq 0 ]
}

@test "gate: confirmation cannot be approved while validation unresolved" {
  "$CTL" init --mode lifecycle --slug g >/dev/null
  run "$CTL" gate set confirmation approved --slug g
  [ "$status" -eq 2 ]
  [[ "$output" == *"Validation Gate"* ]]
}

@test "gate: confirmation approves after validation passes" {
  "$CTL" init --mode lifecycle --slug g >/dev/null
  "$CTL" gate set validation passed --slug g
  run "$CTL" gate set confirmation approved --slug g
  [ "$status" -eq 0 ]
}

@test "gate: rejects an invalid value" {
  "$CTL" init --mode lifecycle --slug g >/dev/null
  run "$CTL" gate set validation bogus --slug g
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid value"* ]]
}

# ── Scope enforcement ─────────────────────────────────────────────────────────

@test "scope: DevFlow artifacts are always in scope" {
  "$CTL" init --mode feature --slug s --scope 'src/**' >/dev/null
  run "$CTL" scope check docs/devflow/specs/x.md --slug s
  [ "$status" -eq 0 ]
}

@test "scope: a file outside the declared globs is rejected" {
  "$CTL" init --mode feature --slug s --scope 'src/**' >/dev/null
  run "$CTL" scope check lib/util.js --slug s
  [ "$status" -eq 1 ]
  [[ "$output" == *"OUTSIDE"* ]]
}

@test "scope: a file inside the declared globs passes" {
  "$CTL" init --mode feature --slug s --scope 'src/**' >/dev/null
  run "$CTL" scope check src/app/main.js --slug s
  [ "$status" -eq 0 ]
}

# ── Iteration limits ──────────────────────────────────────────────────────────

@test "iterate: fails once the limit is exceeded" {
  "$CTL" init --mode lifecycle --slug it >/dev/null
  run "$CTL" iterate plan_revision --max 1 --slug it
  [ "$status" -eq 0 ]
  [[ "$output" == *"iteration 1 of 1"* ]]
  run "$CTL" iterate plan_revision --max 1 --slug it
  [ "$status" -eq 1 ]
  [[ "$output" == *"exceeded its limit"* ]]
}

# ── Capabilities (regression for the marker-parse double-space fix) ───────────

@test "capabilities: defaults to unknown with no marker" {
  run "$CTL" capabilities
  [ "$status" -eq 0 ]
  [[ "$output" == *"subagents: unknown"* ]]
}

@test "capabilities: prints a single space when reading a marker" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cp "$CTL" "$BATS_TEST_TMPDIR/bin/devflow-ctl"
  printf 'profile: claude-code\nsubagents: true\nvision: true\n' \
    > "$BATS_TEST_TMPDIR/.devflow-environment"
  run "$BATS_TEST_TMPDIR/bin/devflow-ctl" capabilities
  [ "$status" -eq 0 ]
  [[ "$output" == *"subagents: true"* ]]
  # The bug this guards against rendered "subagents:  true" (two spaces).
  [[ "$output" != *"subagents:  true"* ]]
}

@test "capabilities get: returns a single value from the marker" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cp "$CTL" "$BATS_TEST_TMPDIR/bin/devflow-ctl"
  printf 'profile: claude-code\nsubagents: true\n' \
    > "$BATS_TEST_TMPDIR/.devflow-environment"
  run "$BATS_TEST_TMPDIR/bin/devflow-ctl" capabilities get subagents
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}
