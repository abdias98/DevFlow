#!/usr/bin/env bats
#
# Behavioral suite for `devflow-ctl evidence` — the ledger that turns "the
# tests pass" from a claim into a record (F106): the Stack Profile command that
# ran, its exit code, its output and the working tree it ran against.
#
# Run: npm test   (or: ./node_modules/.bin/bats tests/devflow-evidence.bats)
#
# Each test works in its own git repo under $BATS_TEST_TMPDIR, with the session
# root inside it (docs/devflow/session) so the tree-hash exclusion is exercised
# the way a real project lays it out.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  CTL="$REPO/.agents/skills/shared/bin/devflow-ctl"
  PROJ="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$PROJ/bin"
  cd "$PROJ"
  export DEVFLOW_SESSION_ROOT="docs/devflow/session"
  export DEVFLOW_HOME="$BATS_TEST_TMPDIR/devflow-home"
  export DEVFLOW_MEMORY_VIEW="$BATS_TEST_TMPDIR/framework-memory-view.md"
  printf '#!/bin/sh\necho "all 3 tests passed"\n' > bin/pass.sh
  printf '#!/bin/sh\necho "1 test failed" >&2\nexit 3\n' > bin/fail.sh
  printf '#!/bin/sh\necho "args:$*"\necho "FOO=$FOO"\n' > bin/echo.sh
  chmod +x bin/*.sh
  git init -q .
  git config user.email t@example.com
  git config user.name t
  echo "code" > app.txt
  git add -A && git commit -q -m init
  "$CTL" init --mode feature --slug demo >/dev/null
}

CONTEXT() { echo "$DEVFLOW_SESSION_ROOT/demo/context.md"; }

# profile <key> <value> [<key> <value>...] — a single-project Stack Profile.
profile() {
  {
    echo "# Context"
    echo ""
    echo "## Stack Profile"
    echo ""
    echo "| Key | Value |"
    echo "|-----|-------|"
    while [[ $# -gt 0 ]]; do echo "| **$1** | $2 |"; shift 2; done
    echo ""
    echo "## Notes"
    echo "| **Test Command** | not-this-one |"
  } > "$(CONTEXT)"
}

# ── Input boundary ────────────────────────────────────────────────────────────

@test "evidence run: no Stack Profile is a state error (2), not a failure" {
  echo "# Context" > "$(CONTEXT)"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"no Stack Profile"* ]]
  [[ "$output" == *"stack-detection.md"* ]]
}

@test "evidence run: no context.md at all is the same state error" {
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"no Stack Profile"* ]]
}

@test "evidence run: an 'unknown' key is a state error naming the key" {
  profile "Test Command" "unknown — ask user"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"no command configured for kind 'test'"* ]]
  [[ "$output" == *"Test Command"* ]]
}

@test "evidence run: a template placeholder and a missing row are unconfigured too" {
  profile "Test Command" "{npm test \| pytest}"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"no command configured"* ]]
  profile "Test Command" "./bin/pass.sh"
  run "$CTL" evidence run --kind lint
  [ "$status" -eq 2 ]
  [[ "$output" == *"Lint Command"* ]]
}

@test "evidence run: rejects an unknown kind" {
  profile "Test Command" "./bin/pass.sh"
  run "$CTL" evidence run --kind deploy
  [ "$status" -eq 2 ]
  [[ "$output" == *"--kind must be one of"* ]]
}

@test "evidence run: shell syntax in the profile is refused and nothing runs" {
  profile "Test Command" "./bin/pass.sh; touch pwned"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"shell syntax"* ]]
  [ ! -e pwned ]
  for bad in './bin/pass.sh && touch pwned' './bin/pass.sh > out' 'touch $(echo pwned)' "./bin/echo.sh 'a b'"; do
    profile "Test Command" "$bad"
    run "$CTL" evidence run --kind test
    [ "$status" -eq 2 ]
  done
  [ ! -e pwned ]
  [ ! -e out ]
}

@test "evidence run: a pipe in the value is refused, not truncated before it" {
  # A naive cell split would run './bin/pass.sh' and drop the rest.
  profile "Test Command" "./bin/pass.sh | tee pwned"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [ ! -f "$DEVFLOW_SESSION_ROOT/demo/evidence.md" ]
}

@test "evidence run: must start the command line (--slug before it is refused)" {
  profile "Test Command" "./bin/pass.sh"
  run "$CTL" --slug demo evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"must start the command line"* ]]
  run "$CTL" evidence run --kind test --slug demo
  [ "$status" -eq 0 ]
}

# ── Running and recording ─────────────────────────────────────────────────────

@test "evidence run: a passing command exits 0 and records run / 0 / tree / log" {
  profile "Test Command" "\`./bin/pass.sh\`"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 0 ]
  [[ "$output" == *"all 3 tests passed"* ]]
  [[ "$output" == *"evidence EV001 recorded — test passed"* ]]
  run grep '^| EV001 | test | run | 0 | ' "$DEVFLOW_SESSION_ROOT/demo/evidence.md"
  [ "$status" -eq 0 ]
  [[ "$output" =~ \|\ [0-9a-f]{40}\ \| ]]
  grep -q "all 3 tests passed" "$DEVFLOW_SESSION_ROOT/demo/evidence/001-test.log"
}

@test "evidence run: a failing command exits 1 and records its real exit code" {
  profile "Test Command" "./bin/fail.sh"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 1 ]
  [[ "$output" == *"1 test failed"* ]]
  [[ "$output" == *"test failed (exit 3)"* ]]
  grep -q '^| EV001 | test | run | 3 | ' "$DEVFLOW_SESSION_ROOT/demo/evidence.md"
}

@test "evidence run: ids increment and each run keeps its own log" {
  profile "Test Command" "./bin/pass.sh" "Lint Command" "./bin/fail.sh"
  "$CTL" evidence run --kind test
  run "$CTL" evidence run --kind lint
  [ "$status" -eq 1 ]
  grep -q '^| EV002 | lint | run | 3 | ' "$DEVFLOW_SESSION_ROOT/demo/evidence.md"
  [ -f "$DEVFLOW_SESSION_ROOT/demo/evidence/001-test.log" ]
  [ -f "$DEVFLOW_SESSION_ROOT/demo/evidence/002-lint.log" ]
}

@test "evidence run: arguments and a leading VAR=value reach the command without a shell" {
  profile "Test Command" "FOO=bar ./bin/echo.sh --ci src/**/*.ts"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 0 ]
  [[ "$output" == *"args:--ci src/**/*.ts"* ]]
  [[ "$output" == *"FOO=bar"* ]]
}

@test "evidence run: only the Stack Profile section is read, not lookalike rows elsewhere" {
  profile "Lint Command" "./bin/pass.sh"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"no command configured"* ]]
}

@test "evidence run: a command that hangs is stopped by the timeout and fails" {
  command -v timeout >/dev/null || skip "no timeout(1) on this system"
  printf '#!/bin/sh\nsleep 10\n' > bin/hang.sh; chmod +x bin/hang.sh
  profile "Test Command" "./bin/hang.sh"
  DEVFLOW_EVIDENCE_TIMEOUT=1 run "$CTL" evidence run --kind test
  [ "$status" -eq 1 ]
  [[ "$output" == *"timed out after 1s"* ]]
  grep -q '^| EV001 | test | run | 124 | ' "$DEVFLOW_SESSION_ROOT/demo/evidence.md"
}

@test "evidence run: works under a hostile locale" {
  locale -a 2>/dev/null | grep -qi '^es_ES.utf' || skip "es_ES.UTF-8 not installed"
  profile "Test Command" "./bin/pass.sh"
  LC_ALL=es_ES.UTF-8 run "$CTL" evidence run --kind test
  [ "$status" -eq 0 ]
  grep -q '^| EV001 | test | run | 0 | ' "$DEVFLOW_SESSION_ROOT/demo/evidence.md"
}

# ── Monorepo profiles ─────────────────────────────────────────────────────────

monorepo() { # monorepo <n-packages>
  {
    echo "## Stack Profiles"
    echo ""
    echo "### Workspace root"
    echo "| Key | Value |"
    echo "|-----|-------|"
    echo "| **Lint Command** | ./bin/pass.sh |"
    echo ""
    echo "### {packages/api}"
    echo "| Key | Value |"
    echo "|-----|-------|"
    echo "| **Test Command** | ./bin/echo.sh api |"
    if [[ "$1" -ge 2 ]]; then
      echo ""
      echo "### {packages/web}"
      echo "| Key | Value |"
      echo "|-----|-------|"
      echo "| **Test Command** | ./bin/echo.sh web |"
    fi
  } > "$(CONTEXT)"
}

@test "evidence run (monorepo): one package is picked without --profile" {
  monorepo 1
  run "$CTL" evidence run --kind test
  [ "$status" -eq 0 ]
  [[ "$output" == *"args:api"* ]]
}

@test "evidence run (monorepo): several packages need --profile, and the error lists them" {
  monorepo 2
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"packages/api, packages/web"* ]]
  run "$CTL" evidence run --kind test --profile packages/web
  [ "$status" -eq 0 ]
  [[ "$output" == *"args:web"* ]]
  run "$CTL" evidence run --kind test --profile packages/nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown profile 'packages/nope'"* ]]
}

@test "evidence run (monorepo): a key missing in the package falls back to Workspace root" {
  monorepo 2
  run "$CTL" evidence run --kind lint --profile packages/api
  [ "$status" -eq 0 ]
  [[ "$output" == *"all 3 tests passed"* ]]
}

# ── Working-tree identity ─────────────────────────────────────────────────────

tree_of() { awk -F'|' -v id="$1" '$2 ~ " "id" " {gsub(/ /,"",$6); print $6}' "$DEVFLOW_SESSION_ROOT/demo/evidence.md"; }

@test "evidence tree: unchanged by writes under docs/devflow/ (session, reviews)" {
  profile "Test Command" "./bin/pass.sh"
  "$CTL" evidence run --kind test
  mkdir -p docs/devflow/reviews && echo "review" > docs/devflow/reviews/r1.md
  "$CTL" evidence run --kind test
  [ -n "$(tree_of EV001)" ]
  [ "$(tree_of EV001)" = "$(tree_of EV002)" ]
}

@test "evidence tree: changes when code changes, staged or not, tracked or new" {
  profile "Test Command" "./bin/pass.sh"
  "$CTL" evidence run --kind test
  echo "edit" >> app.txt
  "$CTL" evidence run --kind test
  echo "new" > new.txt
  "$CTL" evidence run --kind test
  [ "$(tree_of EV001)" != "$(tree_of EV002)" ]
  [ "$(tree_of EV002)" != "$(tree_of EV003)" ]
}

@test "evidence tree: honours .gitignore" {
  profile "Test Command" "./bin/pass.sh"
  echo "build/" > .gitignore && git add .gitignore && git commit -q -m ignore
  "$CTL" evidence run --kind test
  mkdir -p build && echo "artifact" > build/out.js
  "$CTL" evidence run --kind test
  [ "$(tree_of EV001)" = "$(tree_of EV002)" ]
}

@test "evidence tree: the user's index is left exactly as it was" {
  profile "Test Command" "./bin/pass.sh"
  echo "staged" > staged.txt && git add staged.txt
  echo "unstaged" >> app.txt
  before="$(git diff --cached --name-only; echo ---; git diff --name-only)"
  "$CTL" evidence run --kind test
  after="$(git diff --cached --name-only; echo ---; git diff --name-only)"
  [ "$before" = "$after" ]
}

@test "evidence tree: outside a git repo it is recorded as 'none'" {
  rm -rf .git
  profile "Test Command" "./bin/pass.sh"
  run "$CTL" evidence run --kind test
  [ "$status" -eq 0 ]
  grep -q '^| EV001 | test | run | 0 | none | ' "$DEVFLOW_SESSION_ROOT/demo/evidence.md"
}

# ── attest / list ─────────────────────────────────────────────────────────────

@test "evidence attest: records pasted output as attested, exit unknown" {
  echo "Tests: 12 passed" > pasted.txt
  run "$CTL" evidence attest --kind test --file pasted.txt
  [ "$status" -eq 0 ]
  [[ "$output" == *"attested by the user (not verified"* ]]
  grep -q '^| EV001 | test | attested | ? | ' "$DEVFLOW_SESSION_ROOT/demo/evidence.md"
  grep -q "12 passed" "$DEVFLOW_SESSION_ROOT/demo/evidence/001-test.log"
}

@test "evidence attest: a missing or empty file is refused" {
  run "$CTL" evidence attest --kind test --file nope.txt
  [ "$status" -eq 2 ]
  : > empty.txt
  run "$CTL" evidence attest --kind test --file empty.txt
  [ "$status" -eq 2 ]
}

@test "evidence list: says so when nothing is recorded, prints the ledger otherwise" {
  run "$CTL" evidence list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No evidence recorded"* ]]
  profile "Test Command" "./bin/pass.sh"
  "$CTL" evidence run --kind test
  run "$CTL" evidence list
  [[ "$output" == *"| EV001 | test | run | 0 |"* ]]
}

@test "evidence run: needs a session" {
  rm -rf docs/devflow/session
  run "$CTL" evidence run --kind test
  [ "$status" -eq 2 ]
  [[ "$output" == *"no active session"* ]]
}
