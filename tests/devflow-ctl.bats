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

# ── Deferred backlog (F43, F44, F45) ────────────────────────────────────────────

setup_backlog() { export DEVFLOW_BACKLOG_FILE="$BATS_TEST_TMPDIR/deferred.md"; }

@test "backlog add: creates the file with a header and one row" {
  setup_backlog
  run "$CTL" backlog add src/foo.ts "needs a coherence fix" --severity incomplete --slug demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"D1"* ]]
  [ -f "$DEVFLOW_BACKLOG_FILE" ]
  grep -q "🟠 INCOMPLETE" "$DEVFLOW_BACKLOG_FILE"
  grep -q "demo" "$DEVFLOW_BACKLOG_FILE"
}

@test "backlog add: IDs increment across entries" {
  setup_backlog
  "$CTL" backlog add a.ts "r1" --severity info
  "$CTL" backlog add b.ts "r2" --severity block
  run "$CTL" backlog add c.ts "r3" --severity incomplete
  [[ "$output" == *"D3"* ]]
}

@test "backlog add: rejects an invalid severity" {
  setup_backlog
  run "$CTL" backlog add a.ts "r" --severity bogus
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be 'block', 'incomplete', or 'info'"* ]]
}

@test "backlog list --area: filters by a glob against the File column" {
  setup_backlog
  "$CTL" backlog add src/auth/session.ts "r1" --severity incomplete
  "$CTL" backlog add src/db/pool.ts "r2" --severity block
  run "$CTL" backlog list --area 'src/auth/*'
  [ "$status" -eq 0 ]
  [[ "$output" == *"session.ts"* ]]
  [[ "$output" != *"pool.ts"* ]]
}

@test "backlog list: with no backlog file, reports none found instead of erroring" {
  setup_backlog
  run "$CTL" backlog list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No deferred backlog found"* ]]
}

# ── Scope impact / justify / audit — three-zone model (F39) ───────────────────

setup_impact_repo() {
  IMPACTDIR="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$IMPACTDIR/src"
  printf 'export function formatDate(d) { return d.toISOString(); }\n' > "$IMPACTDIR/src/formatDate.ts"
  printf "import { formatDate } from './formatDate';\nexport function render(d) { return formatDate(d); }\n" > "$IMPACTDIR/src/userCard.ts"
  printf 'export const x = 1;\n' > "$IMPACTDIR/src/unrelated.ts"
}

@test "scope impact: finds a dependent by basename in import statements" {
  setup_impact_repo
  "$CTL" init --mode feature --slug im --scope 'src/formatDate.ts'
  run bash -c "cd '$IMPACTDIR' && '$CTL' scope impact src/formatDate.ts --slug im"
  [ "$status" -eq 0 ]
  [[ "$output" == *"src/userCard.ts"$'\t'"dependent"* ]]
  [[ "$output" != *"unrelated.ts"* ]]
}

@test "scope check: distinguishes Core, Impact Zone, and Outside" {
  setup_impact_repo
  "$CTL" init --mode feature --slug im --scope 'src/formatDate.ts'
  bash -c "cd '$IMPACTDIR' && '$CTL' scope impact src/formatDate.ts --record --slug im" >/dev/null

  run "$CTL" scope check src/formatDate.ts --slug im
  [ "$status" -eq 0 ]
  [[ "$output" == *"(Core)"* ]]

  run "$CTL" scope check src/userCard.ts --slug im
  [ "$status" -eq 0 ]
  [[ "$output" == *"Impact Zone"* ]]

  run "$CTL" scope check src/unrelated.ts --slug im
  [ "$status" -eq 1 ]
  [[ "$output" == *"OUTSIDE"* ]]
}

@test "scope impact --record (no file): scans every file already in the declared scope" {
  setup_impact_repo
  "$CTL" init --mode feature --slug im --scope 'src/formatDate.ts'
  run bash -c "cd '$IMPACTDIR' && '$CTL' scope impact --record --slug im"
  [ "$status" -eq 0 ]
  run "$CTL" scope check src/userCard.ts --slug im
  [ "$status" -eq 0 ]
  [[ "$output" == *"Impact Zone"* ]]
}

@test "scope justify: a file outside the Impact Zone is a usage error" {
  setup_impact_repo
  "$CTL" init --mode feature --slug im --scope 'src/formatDate.ts'
  run "$CTL" scope justify src/unrelated.ts "reason" --slug im
  [ "$status" -eq 2 ]
  [[ "$output" == *"not in the recorded Impact Zone"* ]]
}

@test "scope audit: fails on a modified, unjustified Impact Zone file; passes once justified" {
  setup_impact_repo
  "$CTL" init --mode feature --slug im --scope 'src/formatDate.ts'
  bash -c "cd '$IMPACTDIR' && '$CTL' scope impact --record --slug im" >/dev/null

  run "$CTL" scope audit src/userCard.ts --slug im
  [ "$status" -eq 1 ]
  [[ "$output" == *"src/userCard.ts"* ]]

  "$CTL" scope justify src/userCard.ts "updated caller after signature change" --slug im
  run "$CTL" scope audit src/userCard.ts --slug im
  [ "$status" -eq 0 ]
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

# ── Lock: acquire / release / --force / stale (F22) ─────────────────────────────

@test "lock acquire: acquires an unlocked session for the named agent" {
  "$CTL" init --mode feature --slug la1 >/dev/null
  "$CTL" lock release --slug la1 >/dev/null
  run "$CTL" lock acquire Implementer --slug la1
  [ "$status" -eq 0 ]
  [[ "$output" == *"lock acquired by Implementer"* ]]
  run "$CTL" config get branch --slug la1
  [ "$status" -eq 0 ]
}

@test "lock acquire: fails when held by a different, non-stale agent without --force" {
  "$CTL" init --mode feature --slug la2 >/dev/null
  run "$CTL" lock acquire Implementer --slug la2
  [ "$status" -eq 1 ]
  [[ "$output" == *"lock held by Orchestrator"* ]]
  [[ "$output" == *"--force"* ]]
}

@test "lock acquire: --force breaks a non-stale lock held by another agent" {
  "$CTL" init --mode feature --slug la3 >/dev/null
  run "$CTL" lock acquire Implementer --force --slug la3
  [ "$status" -eq 0 ]
  [[ "$output" == *"lock acquired by Implementer"* ]]
}

@test "lock acquire: a stale lock is acquirable without --force" {
  "$CTL" init --mode feature --slug la4 >/dev/null
  local state="$DEVFLOW_SESSION_ROOT/la4/phase-state.md"
  sed -i 's/^locked_since:.*/locked_since: 2020-01-01T00:00:00Z/' "$state"
  run "$CTL" lock acquire Implementer --slug la4
  [ "$status" -eq 0 ]
  [[ "$output" == *"lock acquired by Implementer"* ]]
}

@test "lock acquire: requires an agent name" {
  "$CTL" init --mode feature --slug la5 >/dev/null
  run "$CTL" lock acquire --slug la5
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: devflow-ctl lock acquire"* ]]
}

@test "lock release: sets locked_by to none and stamps locked_since" {
  "$CTL" init --mode feature --slug lr1 >/dev/null
  run "$CTL" lock release --slug lr1
  [ "$status" -eq 0 ]
  [[ "$output" == *"lock released"* ]]
  grep -q "^locked_by: none" "$DEVFLOW_SESSION_ROOT/lr1/phase-state.md"
  ! grep -q "^locked_since: —" "$DEVFLOW_SESSION_ROOT/lr1/phase-state.md"
}

@test "lock: unknown action is a usage error" {
  "$CTL" init --mode feature --slug lu1 >/dev/null
  run "$CTL" lock bogus --slug lu1
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: devflow-ctl lock"* ]]
}

# ── Config: pair_mode / rigor validation (F22) ──────────────────────────────────

@test "config set: pair_mode accepts true and false" {
  "$CTL" init --mode feature --slug cfg1 >/dev/null
  run "$CTL" config set pair_mode true --slug cfg1
  [ "$status" -eq 0 ]
  run "$CTL" config get pair_mode --slug cfg1
  [ "$output" = "true" ]
  run "$CTL" config set pair_mode false --slug cfg1
  [ "$status" -eq 0 ]
  run "$CTL" config get pair_mode --slug cfg1
  [ "$output" = "false" ]
}

@test "config set: pair_mode rejects a non-boolean value" {
  "$CTL" init --mode feature --slug cfg2 >/dev/null
  run "$CTL" config set pair_mode maybe --slug cfg2
  [ "$status" -eq 2 ]
  [[ "$output" == *"pair_mode must be 'true' or 'false'"* ]]
}

@test "config set: rigor accepts each of the 4 valid levels" {
  "$CTL" init --mode feature --slug cfg3 >/dev/null
  for level in light standard deep maximum; do
    run "$CTL" config set rigor "$level" --slug cfg3
    [ "$status" -eq 0 ]
    run "$CTL" config get rigor --slug cfg3
    [ "$output" = "$level" ]
  done
}

@test "config set: rigor rejects an invalid level" {
  "$CTL" init --mode feature --slug cfg4 >/dev/null
  run "$CTL" config set rigor extreme --slug cfg4
  [ "$status" -eq 2 ]
  [[ "$output" == *"rigor must be 'light', 'standard', 'deep', or 'maximum'"* ]]
}

@test "config set: unknown key is a usage error" {
  "$CTL" init --mode feature --slug cfg5 >/dev/null
  run "$CTL" config set bogus_key x --slug cfg5
  [ "$status" -eq 2 ]
  [[ "$output" == *"key must be one of"* ]]
}

# ── Checkpoint: set / get / missing (F22) ───────────────────────────────────────

@test "checkpoint set/get: round-trips a named checkpoint SHA" {
  "$CTL" init --mode feature --slug cp1 >/dev/null
  run "$CTL" checkpoint set pre-impl abc1234 --slug cp1
  [ "$status" -eq 0 ]
  [[ "$output" == *"checkpoint 'pre-impl' = abc1234"* ]]
  run "$CTL" checkpoint get pre-impl --slug cp1
  [ "$status" -eq 0 ]
  [ "$output" = "abc1234" ]
}

@test "checkpoint get: a checkpoint that was never set fails clearly" {
  "$CTL" init --mode feature --slug cp2 >/dev/null
  run "$CTL" checkpoint get never-set --slug cp2
  [ "$status" -eq 2 ]
  [[ "$output" == *"not recorded"* ]]
}

@test "checkpoint set: requires both a name and a sha" {
  "$CTL" init --mode feature --slug cp3 >/dev/null
  run "$CTL" checkpoint set pre-impl --slug cp3
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: devflow-ctl checkpoint set"* ]]
}

# ── Knowledge base: list / add (F22) ────────────────────────────────────────────

setup_knowledge() { export DEVFLOW_KNOWLEDGE_FILE="$BATS_TEST_TMPDIR/learnings.md"; }

@test "knowledge list: reports 'not found' when the KB doesn't exist yet" {
  setup_knowledge
  run "$CTL" knowledge list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Knowledge base not found"* ]]
}

@test "knowledge add: creates the KB with header + Cycle History when missing" {
  setup_knowledge
  echo "### demo-cycle — 2026-01-01" > "$BATS_TEST_TMPDIR/entry.md"
  run "$CTL" knowledge add "$BATS_TEST_TMPDIR/entry.md"
  [ "$status" -eq 0 ]
  [ -f "$DEVFLOW_KNOWLEDGE_FILE" ]
  grep -q "^## Cycle History" "$DEVFLOW_KNOWLEDGE_FILE"
  grep -q "demo-cycle" "$DEVFLOW_KNOWLEDGE_FILE"
}

@test "knowledge list: counts entries correctly with no double-zero bug" {
  setup_knowledge
  echo "# KB" > "$DEVFLOW_KNOWLEDGE_FILE"
  run "$CTL" knowledge list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Entries: 0"* ]]
  [[ "$output" != *$'Entries: 0\n0'* ]]
}

@test "knowledge add: fails when the entry file does not exist" {
  setup_knowledge
  run "$CTL" knowledge add "$BATS_TEST_TMPDIR/missing.md"
  [ "$status" -eq 2 ]
  [[ "$output" == *"file not found"* ]]
}

# ── Sessions listing (F22) ───────────────────────────────────────────────────────

@test "sessions: reports no sessions found on an empty root" {
  run "$CTL" sessions
  [ "$status" -eq 0 ]
  [[ "$output" == *"No sessions found"* ]] || [[ "$output" == *"No active sessions found"* ]]
}

@test "sessions: lists an active session with phase, mode, and lock state" {
  "$CTL" init --mode feature --slug se1 >/dev/null
  run "$CTL" sessions
  [ "$status" -eq 0 ]
  [[ "$output" == *"se1"* ]]
  [[ "$output" == *"locked by Orchestrator"* ]]
}

@test "sessions: an unlocked session is reported as unlocked" {
  "$CTL" init --mode feature --slug se2 >/dev/null
  "$CTL" lock release --slug se2 >/dev/null
  run "$CTL" sessions
  [ "$status" -eq 0 ]
  [[ "$output" == *"se2"* ]]
  [[ "$output" == *"unlocked"* ]]
}

@test "sessions: lists multiple concurrent sessions" {
  "$CTL" init --mode feature --slug se3 >/dev/null
  "$CTL" init --mode bugfix --slug se4 >/dev/null
  run "$CTL" sessions
  [ "$status" -eq 0 ]
  [[ "$output" == *"se3"* ]]
  [[ "$output" == *"se4"* ]]
}

# ── Multi-session disambiguation for more commands (F03) ────────────────────────

@test "config get: 2 sessions, exactly one actively locked, resolves without --slug" {
  "$CTL" init --mode feature --slug msa >/dev/null
  "$CTL" init --mode feature --slug msb >/dev/null
  "$CTL" lock release --slug msb >/dev/null
  run "$CTL" config get branch
  [ "$status" -eq 0 ]
}

@test "checkpoint set: 2 sessions both unlocked still requires --slug" {
  "$CTL" init --mode feature --slug msc >/dev/null
  "$CTL" init --mode feature --slug msd >/dev/null
  "$CTL" lock release --slug msc >/dev/null
  "$CTL" lock release --slug msd >/dev/null
  run "$CTL" checkpoint set pre-impl abc123
  [ "$status" -eq 2 ]
  [[ "$output" == *"--slug"* ]]
}

# ── Status and phase (F22, completes 17/17 subcommand coverage) ────────────────

@test "status: prints session summary with mode, phase, lock, and scope" {
  "$CTL" init --mode feature --slug st1 --scope "src/*" >/dev/null
  run "$CTL" status --slug st1
  [ "$status" -eq 0 ]
  [[ "$output" == *"Session:   st1"* ]]
  [[ "$output" == *"Mode:      feature"* ]]
  [[ "$output" == *"Lock:      Orchestrator"* ]]
  [[ "$output" == *"src/*"* ]]
}

@test "status: reports scope as not declared when none was set" {
  "$CTL" init --mode feature --slug st2 >/dev/null
  run "$CTL" status --slug st2
  [ "$status" -eq 0 ]
  [[ "$output" == *"Scope:     (not declared)"* ]]
}

@test "phase get/set: round-trips a numeric phase" {
  "$CTL" init --mode feature --slug ph1 >/dev/null
  run "$CTL" phase set 4 --slug ph1
  [ "$status" -eq 0 ]
  [[ "$output" == *"phase set to 4"* ]]
  run "$CTL" phase get --slug ph1
  [ "$output" = "4" ]
}

@test "phase set: rejects a non-numeric phase" {
  "$CTL" init --mode feature --slug ph2 >/dev/null
  run "$CTL" phase set implement --slug ph2
  [ "$status" -eq 2 ]
  [[ "$output" == *"numeric phase required"* ]]
}
