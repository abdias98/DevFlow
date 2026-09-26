#!/usr/bin/env bats
#
# Behavioral suite for the framework memory (shared/framework-memory.md):
# `devflow-ctl memory ...`, the cross-project store that lives outside every
# project and every editor install.
#
# Run: npm test   (or: ./node_modules/.bin/bats tests/devflow-memory.bats)
#
# Every test isolates the store with DEVFLOW_HOME and pins the project id, so
# nothing ever touches the real ~/.local/share/devflow.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  CTL="$REPO/.agents/skills/shared/bin/devflow-ctl"
  export DEVFLOW_HOME="$BATS_TEST_TMPDIR/home"
  export DEVFLOW_SESSION_ROOT="$BATS_TEST_TMPDIR/session"
  export DEVFLOW_PROJECT_ID="p-aaaa0001"
  export DEVFLOW_TODAY="2026-09-01"
  ENTRIES="$DEVFLOW_HOME/memory/entries"
  INDEX="$DEVFLOW_HOME/memory/INDEX.md"
}

# add_entry <key> [extra args...] — a valid entry with a unique key.
add_entry() {
  local key="$1"; shift
  "$CTL" memory add --type escape --key "$key" --title "Lesson $key" \
    --rule "Check the cache key includes every parameter of the cached call." "$@"
}

# ── Store location ────────────────────────────────────────────────────────────

@test "memory path: honors DEVFLOW_HOME" {
  run "$CTL" memory path
  [ "$status" -eq 0 ]
  [ "$output" = "$DEVFLOW_HOME/memory" ]
}

@test "memory path: falls back to XDG_DATA_HOME, never ~/.devflow" {
  unset DEVFLOW_HOME
  export XDG_DATA_HOME="$BATS_TEST_TMPDIR/xdg"
  run "$CTL" memory path
  [ "$output" = "$BATS_TEST_TMPDIR/xdg/devflow/memory" ]
  unset XDG_DATA_HOME
  export HOME="$BATS_TEST_TMPDIR/fakehome"
  run "$CTL" memory path
  [ "$output" = "$BATS_TEST_TMPDIR/fakehome/.local/share/devflow/memory" ]
}

@test "memory add: an unwritable store warns and exits 0 (memory never blocks a cycle)" {
  : > "$BATS_TEST_TMPDIR/not-a-dir"
  export DEVFLOW_HOME="$BATS_TEST_TMPDIR/not-a-dir"
  run add_entry k:unwritable
  [ "$status" -eq 0 ]
  [[ "$output" == *"not writable"* ]]
}

# ── add ───────────────────────────────────────────────────────────────────────

@test "memory add: writes one entry file with frontmatter and a candidate status" {
  run add_entry escape:cache-key --agent devflow-review --stack node,react \
    --class state-transitions --layer reviewer:correctness-behavior \
    --target devflow-review/correctness-guide.md --why "Two escapes." --apply "Correctness dimension, S2."
  [ "$status" -eq 0 ]
  [[ "$output" == *"M0001 recorded (candidate, escape)"* ]]
  f="$(ls "$ENTRIES"/M0001-*.md)"
  grep -qx 'status: candidate' "$f"
  grep -qx 'agents: \[devflow-review\]' "$f"
  grep -qx 'stack: \[node, react\]' "$f"
  grep -qx 'layer: reviewer:correctness-behavior' "$f"
  grep -qx '  - p-aaaa0001 2026-09-01' "$f"
  grep -q '^\*\*How to apply:\*\* Correctness dimension' "$f"
}

@test "memory add: ids increase and the index lists every entry" {
  add_entry k:one >/dev/null
  add_entry k:two >/dev/null
  [ -f "$ENTRIES/M0002-lesson-k-two.md" ]
  grep -q '^- M0001 \[candidate ×1\] escape' "$INDEX"
  grep -q '^- M0002 \[candidate ×1\] escape' "$INDEX"
}

@test "memory add: a duplicate key exits 1 and points to 'memory seen'" {
  add_entry k:dup >/dev/null
  run add_entry k:dup
  [ "$status" -eq 1 ]
  [[ "$output" == *"already recorded as M0001"* ]]
  [[ "$output" == *"memory seen M0001"* ]]
  [ "$(ls "$ENTRIES" | wc -l)" -eq 1 ]
}

@test "memory add: rejects an unknown type, a bad key and a non-escape class (exit 2)" {
  run "$CTL" memory add --type nope --key k:a --title t --rule r
  [ "$status" -eq 2 ]
  run "$CTL" memory add --type friction --key "Bad Key" --title t --rule r
  [ "$status" -eq 2 ]
  run "$CTL" memory add --type escape --key k:a --title t --rule r --class wrong
  [ "$status" -eq 2 ]
  run "$CTL" memory add --type escape --key k:a --title t --rule r --target ../../etc/passwd
  [ "$status" -eq 2 ]
  run "$CTL" memory add --type escape --title t --rule r
  [ "$status" -eq 2 ]
}

@test "memory add: concurrent writers never reuse an id" {
  for i in 1 2 3 4 5 6; do add_entry "k:c$i" >/dev/null & done
  wait
  [ "$(ls "$ENTRIES" | wc -l)" -eq 6 ]
  [ "$(ls "$ENTRIES" | cut -c1-5 | sort -u | wc -l)" -eq 6 ]
}

# ── Privacy guard ─────────────────────────────────────────────────────────────

@test "privacy: refuses absolute paths, emails, foreign URLs, secrets and long text" {
  run add_entry k:p1 --why "Seen in /home/dev/acme/app.ts"
  [ "$status" -eq 1 ]; [[ "$output" == *"absolute path"* ]]
  run add_entry k:p2 --why "Reported by dev@acme.io"
  [ "$status" -eq 1 ]; [[ "$output" == *"email"* ]]
  run add_entry k:p3 --why "See https://jira.acme.io/browse/X-1"
  [ "$status" -eq 1 ]; [[ "$output" == *"URL"* ]]
  run add_entry k:p4 --why "token: sk_live_0123456789abcdef"
  [ "$status" -eq 1 ]; [[ "$output" == *"secret"* ]]
  run add_entry k:p5 --why "$(printf 'l1\nl2\nl3\nl4\nl5\nl6')"
  [ "$status" -eq 1 ]; [[ "$output" == *"more than 5 lines"* ]]
  [ ! -d "$ENTRIES" ] || [ "$(ls "$ENTRIES" | wc -l)" -eq 0 ]
}

@test "privacy: allows links into the DevFlow repository" {
  run add_entry k:ok --why "Tracked in https://github.com/abdias98/DevFlow/issues/1"
  [ "$status" -eq 0 ]
}

@test "privacy: outside the framework repo, refuses the project's name and its paths" {
  proj="$BATS_TEST_TMPDIR/acme-billing"
  mkdir -p "$proj/src/invoices"
  : > "$proj/src/invoices/total.ts"
  git -C "$proj" init -q
  git -C "$proj" remote add origin git@example.com:acme/acme-billing.git
  cd "$proj"
  run add_entry k:name --why "Found while working on acme-billing"
  [ "$status" -eq 1 ]; [[ "$output" == *"project's name"* ]]
  run add_entry k:path --why "The bug was in src/invoices/total.ts"
  [ "$status" -eq 1 ]; [[ "$output" == *"path from this project"* ]]
  run add_entry k:generic --why "A rounding helper summed floats before rounding."
  [ "$status" -eq 0 ]
}

@test "project id: without an override it is a stable hash of the origin remote" {
  unset DEVFLOW_PROJECT_ID
  proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$proj"
  git -C "$proj" init -q
  git -C "$proj" remote add origin git@example.com:acme/secret-name.git
  cd "$proj"
  add_entry k:h1 >/dev/null
  add_entry k:h2 >/dev/null
  id1="$(awk '/^  - p-/{print $2; exit}' "$ENTRIES"/M0001-*.md)"
  id2="$(awk '/^  - p-/{print $2; exit}' "$ENTRIES"/M0002-*.md)"
  [[ "$id1" =~ ^p-[0-9a-f]{8}$ ]]
  [ "$id1" = "$id2" ]
  ! grep -rq 'secret-name' "$DEVFLOW_HOME"
}

# ── list / show / index ───────────────────────────────────────────────────────

@test "memory list: filters by type and says so when empty" {
  run "$CTL" memory list
  [[ "$output" == *"No framework memory entries"* ]]
  add_entry k:a >/dev/null
  "$CTL" memory add --type friction --key k:f --title "Friction lesson" --rule "r" >/dev/null
  run "$CTL" memory list --type friction
  [[ "$output" == *"M0002"* ]]
  [[ "$output" != *"M0001"* ]]
}

@test "memory show: prints the entry, and exits 2 for an unknown id" {
  add_entry k:a >/dev/null
  run "$CTL" memory show M0001
  [ "$status" -eq 0 ]
  [[ "$output" == *"key: k:a"* ]]
  run "$CTL" memory show M9999
  [ "$status" -eq 2 ]
  run "$CTL" memory show '../x'
  [ "$status" -eq 2 ]
}

@test "memory index: rebuilds INDEX.md from the entry files" {
  add_entry k:a >/dev/null
  rm "$INDEX"
  run "$CTL" memory index
  [ "$status" -eq 0 ]
  grep -q '^- M0001 ' "$INDEX"
}
