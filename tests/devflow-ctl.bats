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

@test "scope: 'src/*' accepts a file directly inside the segment" {
  "$CTL" init --mode feature --slug s --scope 'src/*' >/dev/null
  run "$CTL" scope check src/a.ts --slug s
  [ "$status" -eq 0 ]
}

@test "scope: 'src/*' rejects a file in a nested subdirectory (no crossing '/')" {
  "$CTL" init --mode feature --slug s --scope 'src/*' >/dev/null
  run "$CTL" scope check src/a/b.ts --slug s
  [ "$status" -eq 1 ]
  [[ "$output" == *"OUTSIDE"* ]]
}

@test "scope: 'src/**' accepts both a direct file and a nested one" {
  "$CTL" init --mode feature --slug s --scope 'src/**' >/dev/null
  run "$CTL" scope check src/a.ts --slug s
  [ "$status" -eq 0 ]
  run "$CTL" scope check src/a/b.ts --slug s
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

# ── Lock check (F02: "no session" is success, not exit 2) ─────────────────────

@test "lock check: empty repo (no sessions) exits 0, not 2" {
  run "$CTL" lock check
  [ "$status" -eq 0 ]
  [[ "$output" == *"no active session"* ]]
}

@test "lock check: own session with no holder exits 0" {
  "$CTL" init --mode feature --slug mine >/dev/null
  "$CTL" lock release --slug mine >/dev/null
  run "$CTL" lock check --slug mine
  [ "$status" -eq 0 ]
  [[ "$output" == *"no active lock"* ]]
}

@test "lock check: session held by another agent (not stale) exits 1" {
  "$CTL" init --mode feature --slug theirs >/dev/null
  run "$CTL" lock check --slug theirs
  [ "$status" -eq 1 ]
  [[ "$output" == *"locked by Orchestrator"* ]]
}

@test "lock check: stale lock is a WARN, not a failure" {
  "$CTL" init --mode feature --slug stale >/dev/null
  local state="$DEVFLOW_SESSION_ROOT/stale/phase-state.md"
  sed -i 's/^locked_since:.*/locked_since: 2020-01-01T00:00:00Z/' "$state"
  run "$CTL" lock check --slug stale
  [ "$status" -eq 0 ]
  [[ "$output" == *"STALE"* ]]
}

# ── Multi-session resolution (F03) ─────────────────────────────────────────────

@test "resolve_session: 2 sessions, exactly one with an active lock, resolves without --slug" {
  "$CTL" init --mode feature --slug locked >/dev/null
  "$CTL" init --mode lifecycle --slug abandoned >/dev/null
  "$CTL" lock release --slug abandoned >/dev/null
  run "$CTL" gate check plan_approval
  [ "$status" -eq 1 ]
  [[ "$output" == *"resolved to 'locked'"* ]]
  [[ "$output" == *"gate 'plan_approval' is CLOSED"* ]]
}

@test "resolve_session: 2 sessions both actively locked still requires --slug" {
  "$CTL" init --mode feature --slug a >/dev/null
  "$CTL" init --mode feature --slug b >/dev/null
  run "$CTL" gate check plan_approval
  [ "$status" -eq 2 ]
  [[ "$output" == *"disambiguate with --slug"* ]]
}

@test "resolve_session: 2 sessions, only stale locks, still requires --slug" {
  "$CTL" init --mode feature --slug old1 >/dev/null
  "$CTL" init --mode feature --slug old2 >/dev/null
  sed -i 's/^locked_since:.*/locked_since: 2020-01-01T00:00:00Z/' "$DEVFLOW_SESSION_ROOT/old1/phase-state.md"
  sed -i 's/^locked_since:.*/locked_since: 2020-01-01T00:00:00Z/' "$DEVFLOW_SESSION_ROOT/old2/phase-state.md"
  run "$CTL" gate check plan_approval
  [ "$status" -eq 2 ]
  [[ "$output" == *"disambiguate with --slug"* ]]
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

# ── Deterministic security scan ───────────────────────────────────────────────

setup_scan() { SCANDIR="$BATS_TEST_TMPDIR/scan"; mkdir -p "$SCANDIR"; }

@test "scan secrets: detects a hardcoded AWS access key" {
  setup_scan
  printf 'const k = "AKIAIOSFODNN7EXAMPLE";\n' > "$SCANDIR/config.js"
  run bash -c "cd '$SCANDIR' && '$CTL' scan secrets"
  [ "$status" -eq 1 ]
  [[ "$output" == *"AWS access key"* ]]
  [[ "$output" == *"config.js:1"* ]]
}

@test "scan secrets: detects a private key block" {
  setup_scan
  printf -- '-----BEGIN RSA PRIVATE KEY-----\nMIIabc\n-----END RSA PRIVATE KEY-----\n' > "$SCANDIR/id_rsa"
  run bash -c "cd '$SCANDIR' && '$CTL' scan secrets"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Private key block"* ]]
}

@test "scan secrets: clean tree passes" {
  setup_scan
  printf 'export const greet = () => "hello world";\n' > "$SCANDIR/app.js"
  run bash -c "cd '$SCANDIR' && '$CTL' scan secrets"
  [ "$status" -eq 0 ]
  [[ "$output" == *"clean"* ]]
}

@test "scan sca: skips gracefully without a manifest" {
  setup_scan
  printf 'just text\n' > "$SCANDIR/notes.txt"
  run bash -c "cd '$SCANDIR' && '$CTL' scan sca"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped"* ]]
}

@test "scan all: clean tree with no manifest passes" {
  setup_scan
  printf 'ok\n' > "$SCANDIR/readme.md"
  run bash -c "cd '$SCANDIR' && '$CTL' scan all"
  [ "$status" -eq 0 ]
  [[ "$output" == *"scan: clean"* ]]
}

@test "scan: unknown kind is a usage error" {
  run "$CTL" scan bogus
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage"* ]]
}

@test "scan: re-scan is a clean oracle for the remediation loop" {
  setup_scan
  # Red: a committed secret -> scan FAILS (exit 1).
  printf 'const k = "AKIAIOSFODNN7EXAMPLE";\n' > "$SCANDIR/config.js"
  run bash -c "cd '$SCANDIR' && '$CTL' scan secrets"
  [ "$status" -eq 1 ]
  # Fix: move the secret to env. Re-scan -> clean (exit 0). BLOCK is cleared.
  printf 'const k = process.env.AWS_KEY;\n' > "$SCANDIR/config.js"
  run bash -c "cd '$SCANDIR' && '$CTL' scan secrets"
  [ "$status" -eq 0 ]
}

@test "scan sast: skips gracefully when semgrep is absent" {
  if command -v semgrep >/dev/null 2>&1; then skip "semgrep is installed"; fi
  setup_scan
  printf 'const x = 1;\n' > "$SCANDIR/app.js"
  run bash -c "cd '$SCANDIR' && '$CTL' scan sast"
  [ "$status" -eq 0 ]
  [[ "$output" == *"semgrep not installed"* ]]
}

@test "scan all: includes the SAST dimension" {
  setup_scan
  printf 'ok\n' > "$SCANDIR/readme.md"
  run bash -c "cd '$SCANDIR' && '$CTL' scan all"
  [[ "$output" == *"code patterns (SAST)"* ]]
}

# ── Artifacts check — standalone types (F28) ───────────────────────────────────

@test "artifacts check: feature — a complete report passes" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Summary\n## Definition of Done\n## Files Changed\n## Tasks Completed\n## Tests\n## Self-Review\n' > "$f"
  run "$CTL" artifacts check feature "$f"
  [ "$status" -eq 0 ]
}

@test "artifacts check: feature — a missing section fails" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Summary\n' > "$f"
  run "$CTL" artifacts check feature "$f"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing required section"* ]]
}

@test "artifacts check: bugfix — a complete report passes" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Bug Report\n## Root Cause\n## Reproduction Test\n## Fix Applied\n## Verification\n## Definition of Done\n' > "$f"
  run "$CTL" artifacts check bugfix "$f"
  [ "$status" -eq 0 ]
}

@test "artifacts check: refactor — a complete report passes" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Scope\n## Changes Applied\n## Regression Guard\n## Definition of Done\n' > "$f"
  run "$CTL" artifacts check refactor "$f"
  [ "$status" -eq 0 ]
}

@test "artifacts check: perf — a complete report passes" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Summary\n## Static Analysis Findings\n## Benchmark Results\n## Recommendations\n' > "$f"
  run "$CTL" artifacts check perf "$f"
  [ "$status" -eq 0 ]
}

@test "artifacts check: migration — a complete report passes" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Schema Changes\n## Migration Files Generated\n## Compatibility Analysis\n## Rollback Plan\n' > "$f"
  run "$CTL" artifacts check migration "$f"
  [ "$status" -eq 0 ]
}

@test "artifacts check: contract — a complete report passes" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Endpoints Validated\n## Contract Definition\n## Discrepancies\n## Coverage Summary\n' > "$f"
  run "$CTL" artifacts check contract "$f"
  [ "$status" -eq 0 ]
}

@test "artifacts check: docs — a complete report passes" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Documentation Generated\n## Artifact Sources Used\n' > "$f"
  run "$CTL" artifacts check docs "$f"
  [ "$status" -eq 0 ]
}

@test "artifacts check: reverse — a complete report passes" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Project Overview\n## Generated Artifacts\n## Stack Profile\n## Known Unknowns\n' > "$f"
  run "$CTL" artifacts check reverse "$f"
  [ "$status" -eq 0 ]
}

@test "artifacts check: unknown type is a usage error" {
  local f="$BATS_TEST_TMPDIR/r.md"
  printf '## Anything\n' > "$f"
  run "$CTL" artifacts check bogus "$f"
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown artifact type"* ]]
}

# ── Clean safety (F27) ──────────────────────────────────────────────────────────

@test "clean: a freshly-released session survives (grace period, not stale yet)" {
  "$CTL" init --mode feature --slug fresh >/dev/null
  "$CTL" lock release --slug fresh >/dev/null
  run "$CTL" clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"no stale sessions"* ]]
  [ -d "$DEVFLOW_SESSION_ROOT/fresh" ]
}

@test "clean: an unlocked session past the stale window is removed" {
  "$CTL" init --mode feature --slug old >/dev/null
  "$CTL" lock release --slug old >/dev/null
  sed -i 's/^locked_since:.*/locked_since: 2020-01-01T00:00:00Z/' "$DEVFLOW_SESSION_ROOT/old/phase-state.md"
  run "$CTL" clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"removed: old"* ]]
  [ ! -d "$DEVFLOW_SESSION_ROOT/old" ]
}

@test "clean: a session marked cancelled is never removed, even if stale" {
  "$CTL" init --mode feature --slug cancelled >/dev/null
  "$CTL" config set status cancelled --slug cancelled >/dev/null
  "$CTL" lock release --slug cancelled >/dev/null
  sed -i 's/^locked_since:.*/locked_since: 2020-01-01T00:00:00Z/' "$DEVFLOW_SESSION_ROOT/cancelled/phase-state.md"
  run "$CTL" clean
  [ "$status" -eq 0 ]
  [ -d "$DEVFLOW_SESSION_ROOT/cancelled" ]
}

@test "clean --force: removes everything, including a cancelled session" {
  "$CTL" init --mode feature --slug cancelled >/dev/null
  "$CTL" config set status cancelled --slug cancelled >/dev/null
  run "$CTL" clean --force
  [ "$status" -eq 0 ]
  [ ! -d "$DEVFLOW_SESSION_ROOT/cancelled" ]
}

@test "config: status only accepts active or cancelled" {
  "$CTL" init --mode feature --slug s >/dev/null
  run "$CTL" config set status bogus --slug s
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be 'active' or 'cancelled'"* ]]
}

# ── Doctor (install / session diagnostics) ────────────────────────────────────

@test "doctor: clean environment reports no failures" {
  run "$CTL" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary: 0 failure(s)"* ]]
}

@test "doctor: a healthy session is reported healthy" {
  "$CTL" init --mode feature --slug ok >/dev/null
  run "$CTL" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"session 'ok': healthy"* ]]
}

@test "doctor: a phase-state with no frontmatter is a FAIL" {
  mkdir -p "$DEVFLOW_SESSION_ROOT/bad"
  printf 'garbage, no frontmatter\n' > "$DEVFLOW_SESSION_ROOT/bad/phase-state.md"
  run "$CTL" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"[FAIL]"* ]]
  [[ "$output" == *"no YAML frontmatter"* ]]
}

@test "doctor: a session missing required keys is a FAIL" {
  mkdir -p "$DEVFLOW_SESSION_ROOT/incomplete"
  printf -- '---\ndevflow: 1\nslug: incomplete\n---\n' > "$DEVFLOW_SESSION_ROOT/incomplete/phase-state.md"
  run "$CTL" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing frontmatter key"* ]]
}

@test "doctor: a stale lock is a warning, not a failure" {
  mkdir -p "$DEVFLOW_SESSION_ROOT/stuck"
  printf -- '---\ndevflow: 1\nslug: stuck\nmode: feature\nphase: 3\nlocked_by: Architect\nlocked_since: 2020-01-01T00:00:00Z\n---\n' \
    > "$DEVFLOW_SESSION_ROOT/stuck/phase-state.md"
  run "$CTL" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"STALE lock"* ]]
}
