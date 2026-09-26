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

# ── query ─────────────────────────────────────────────────────────────────────

seed_three() {
  "$CTL" memory add --type escape --key k:review --title "Review lesson" --rule "Rule R" \
    --agent devflow-review --stack node --apply "Correctness, S2" >/dev/null
  "$CTL" memory add --type friction --key k:any --title "Any lesson" --rule "Rule A" >/dev/null
  "$CTL" memory add --type stack-pattern --key k:py --title "Python lesson" --rule "Rule P" \
    --agent devflow-implement --stack python >/dev/null
}

@test "memory query: filters by agent and stack; [any] always matches" {
  seed_three
  run "$CTL" memory query --agent devflow-review --stack Node,react
  [ "$status" -eq 0 ]
  [[ "$output" == *"M0001"* ]]
  [[ "$output" == *"M0002"* ]]
  [[ "$output" != *"M0003"* ]]
  [[ "$output" == *"Apply: Correctness, S2"* ]]
}

@test "memory query: confirmed ranks above candidate, and candidates are marked unconfirmed" {
  seed_three
  DEVFLOW_PROJECT_ID=p-bbbb0002 "$CTL" memory seen M0003 >/dev/null
  run "$CTL" memory query
  first="$(sed -n 3p <<< "$output")"
  [[ "$first" == "M0003 [confirmed ×2]"* ]]
  [[ "$output" == *"M0001 [candidate ×1 — unconfirmed, treat as a hint]"* ]]
}

@test "memory query: --limit bounds the output and the header reports the total" {
  seed_three
  run "$CTL" memory query --limit 1
  [[ "$output" == *"3 active entries match; showing up to 1"* ]]
  [ "$(grep -c '^M000' <<< "$output")" -eq 1 ]
}

@test "memory query: retired and promoted entries never reach an agent" {
  seed_three
  "$CTL" memory retire M0002 --reason "no longer applies" >/dev/null
  run "$CTL" memory query
  [[ "$output" != *"M0002"* ]]
}

@test "memory query: an empty store is not an error" {
  run "$CTL" memory query --agent devflow-review
  [ "$status" -eq 0 ]
  [[ "$output" == *"no active entries match"* ]]
}

@test "memory query: proposes stale candidates for retirement, never retires them" {
  seed_three
  DEVFLOW_TODAY=2027-06-01 run "$CTL" memory query
  [[ "$output" == *"Stale candidates (unseen ≥ 180 days): M0001 M0002 M0003"* ]]
  grep -qx 'status: candidate' "$ENTRIES"/M0001-*.md
}

# ── seen / confirm / retire ───────────────────────────────────────────────────

@test "memory seen: a second distinct project confirms a candidate" {
  seed_three
  run "$CTL" memory seen M0001
  [[ "$output" == *"1 distinct project(s) — status: candidate"* ]]
  DEVFLOW_PROJECT_ID=p-bbbb0002 DEVFLOW_TODAY=2026-09-10 run "$CTL" memory seen M0001
  [[ "$output" == *"2 distinct project(s) — status: confirmed"* ]]
  f="$(ls "$ENTRIES"/M0001-*.md)"
  [ "$(grep -c '^  - p-' "$f")" -eq 2 ]
  grep -qx 'updated: 2026-09-10' "$f"
  grep -q '^- M0001 \[confirmed ×2\]' "$INDEX"
}

@test "memory seen: the same project twice refreshes its date, not its count" {
  seed_three
  DEVFLOW_TODAY=2026-09-20 "$CTL" memory seen M0001 >/dev/null
  f="$(ls "$ENTRIES"/M0001-*.md)"
  [ "$(grep -c '^  - p-' "$f")" -eq 1 ]
  grep -qx '  - p-aaaa0001 2026-09-20' "$f"
}

@test "memory confirm/retire: only legal transitions are accepted" {
  seed_three
  run "$CTL" memory confirm M0001
  [ "$status" -eq 0 ]
  run "$CTL" memory confirm M0001
  [ "$status" -eq 1 ]
  run "$CTL" memory retire M0002
  [ "$status" -eq 2 ]
  run "$CTL" memory retire M0002 --reason "superseded"
  [ "$status" -eq 0 ]
  grep -q '^\*\*Retired (2026-09-01):\*\* superseded' "$ENTRIES"/M0002-*.md
  run "$CTL" memory confirm M0002
  [ "$status" -eq 1 ]
}

# ── discoverability ───────────────────────────────────────────────────────────

@test "capabilities and status announce the framework memory" {
  seed_three
  "$CTL" memory confirm M0001 >/dev/null
  run "$CTL" capabilities
  [[ "$output" == *"memory: 1 confirmed · 2 candidate"* ]]
  "$CTL" init --mode feature --slug mem-demo >/dev/null
  run "$CTL" status
  [[ "$output" == *"Framework memory: 1 confirmed · 2 candidate"* ]]
}

# ── Friction log (logged by devflow-ctl itself) ───────────────────────────────

FRICTION() { cat "$DEVFLOW_HOME/memory/friction.log"; }

# logged <mode> <rigor> <event> <detail> | logged <event> <detail> — exact TSV fields.
logged() {
  if [ $# -eq 4 ]; then FRICTION | cut -f4-7 | grep -qxF "$1"$'\t'"$2"$'\t'"$3"$'\t'"$4"
  else FRICTION | cut -f6-7 | grep -qxF "$1"$'\t'"$2"; fi
}

@test "friction: a scope violation logs one line with the extension, never the path" {
  "$CTL" init --mode feature --slug client-secret-feature --scope 'src/*' >/dev/null
  run "$CTL" scope check billing/acme/invoice.ts
  [ "$status" -eq 1 ]
  [ "$(FRICTION | wc -l)" -eq 1 ]
  logged feature standard scope-outside .ts
  ! FRICTION | grep -q 'billing\|acme\|invoice\|client-secret'
}

@test "friction: gate closed, iteration limit and incomplete artifact are each logged" {
  "$CTL" init --mode feature --slug f1 >/dev/null
  run "$CTL" gate check plan_approval
  [ "$status" -eq 1 ]
  "$CTL" iterate implement_review --max 1 >/dev/null
  run "$CTL" iterate implement_review --max 1
  [ "$status" -eq 1 ]
  printf '# Spec\n' > "$BATS_TEST_TMPDIR/spec.md"
  run "$CTL" artifacts check spec "$BATS_TEST_TMPDIR/spec.md"
  [ "$status" -eq 1 ]
  logged gate-closed plan_approval:pending
  logged iterate-limit implement_review
  logged artifact-incomplete spec
  [ "$(FRICTION | wc -l)" -eq 3 ]
}

@test "friction: passing checks and usage errors log nothing" {
  "$CTL" init --mode feature --slug ok1 --scope 'src/*' >/dev/null
  "$CTL" scope check src/a.ts >/dev/null
  "$CTL" iterate implement_review >/dev/null
  run "$CTL" gate check nope
  [ "$status" -eq 2 ]
  [ ! -s "$DEVFLOW_HOME/memory/friction.log" ]
}

@test "friction: breaking a stale lock is logged" {
  "$CTL" init --mode feature --slug stale >/dev/null
  sed -i 's/^locked_since: .*/locked_since: 2020-01-01T00:00:00Z/' "$DEVFLOW_SESSION_ROOT/stale/phase-state.md"
  "$CTL" lock acquire Implementer >/dev/null
  logged lock-stale-broken Orchestrator
}

@test "friction report: proposes a pattern only across enough sessions and projects" {
  for p in p-aaaa0001 p-bbbb0002; do
    for s in one two; do
      DEVFLOW_PROJECT_ID=$p "$CTL" init --mode feature --slug "$p-$s" --scope 'src/*' >/dev/null
      DEVFLOW_PROJECT_ID=$p "$CTL" scope check lib/x.py --slug "$p-$s" >/dev/null 2>&1 || true
    done
  done
  run "$CTL" memory friction report
  [ "$status" -eq 0 ]
  [[ "$output" == *"scope-outside"*".py"*"4"*"4"*"2"* ]]
  [[ "$output" == *"--key friction:scope-outside:feature-py"* ]]
  run "$CTL" memory friction report --projects 3
  [[ "$output" == *"No pattern reaches the threshold yet."* ]]
}

@test "friction report: an existing entry is pointed to with 'memory seen', under a hostile locale" {
  for p in p-aaaa0001 p-bbbb0002 p-cccc0003; do
    DEVFLOW_PROJECT_ID=$p "$CTL" init --mode feature --slug "s-$p" >/dev/null
    DEVFLOW_PROJECT_ID=$p "$CTL" gate check plan_approval --slug "s-$p" >/dev/null 2>&1 || true
  done
  "$CTL" memory add --type friction --key friction:gate-closed:feature-plan-approval-pending \
    --title "Agents check the plan gate before asking" --rule "Ask for approval before checking the gate." >/dev/null
  LC_ALL=es_ES.UTF-8 run "$CTL" memory friction report
  [[ "$output" == *"M0001 already records feature/gate-closed/plan_approval:pending"* ]]
}

@test "friction report: says so when nothing was logged" {
  run "$CTL" memory friction report
  [ "$status" -eq 0 ]
  [[ "$output" == *"No friction recorded yet"* ]]
}

# ── Escapes reach the framework (F98) ─────────────────────────────────────────

@test "escape add: counts class × layer in the framework memory, without ref or note" {
  cd "$BATS_TEST_TMPDIR"
  "$CTL" escape add --class logic --layer implementer --ref "PR#12 acme" --note "total rounding in invoices" >/dev/null
  f="$DEVFLOW_HOME/memory/escape-counts.tsv"
  [ "$(wc -l < "$f")" -eq 1 ]
  [ "$(cut -f2- "$f")" = "p-aaaa0001"$'\t'"logic"$'\t'"implementer" ]
  ! grep -q 'acme\|rounding\|PR#12' "$f"
}

@test "escape add: a framework layer prints the memory add to run; a cycle layer does not" {
  cd "$BATS_TEST_TMPDIR"
  run "$CTL" escape add --class state-transitions --layer reviewer:correctness-behavior --ref r --note n
  [[ "$output" == *"is a framework layer"* ]]
  [[ "$output" == *"--key escape:state-transitions:reviewer-correctness-behavior:"* ]]
  run "$CTL" escape add --class logic --layer implementer --ref r --note n
  [[ "$output" != *"framework layer"* ]]
}

@test "memory escapes: aggregates by layer × class across projects" {
  cd "$BATS_TEST_TMPDIR"
  "$CTL" escape add --class logic --layer standard-missing --ref r --note n >/dev/null
  DEVFLOW_PROJECT_ID=p-bbbb0002 "$CTL" escape add --class logic --layer standard-missing --ref r --note n >/dev/null
  "$CTL" escape add --class data-limits --layer verifier --ref r --note n >/dev/null
  run "$CTL" memory escapes
  [[ "$output" == *"Total: 3 escape(s) across 2 project(s)"* ]]
  line="$(grep '^standard-missing' <<< "$output")"
  [[ "$line" =~ logic[[:space:]]+2[[:space:]]+2$ ]]
}

# ── Promotion (F104) ──────────────────────────────────────────────────────────

@test "memory promote-list: groups confirmed entries by target and names the clone" {
  mkdir -p "$DEVFLOW_HOME"
  printf 'source_dir=/opt/devflow\nsource_repo=https://github.com/abdias98/DevFlow.git\n' > "$DEVFLOW_HOME/config"
  add_entry k:a --target devflow-review/correctness-guide.md >/dev/null
  add_entry k:b --target devflow-review/correctness-guide.md >/dev/null
  add_entry k:c >/dev/null
  "$CTL" memory confirm M0001 >/dev/null
  "$CTL" memory confirm M0002 >/dev/null
  run "$CTL" memory promote-list
  [ "$status" -eq 0 ]
  [[ "$output" == *"DevFlow clone: /opt/devflow"* ]]
  [ "$(grep -c '^devflow-review/correctness-guide.md$' <<< "$output")" -eq 1 ]
  [[ "$output" == *"M0001"* && "$output" == *"M0002"* ]]
  [[ "$output" != *"M0003"* ]]
}

@test "memory promote-list: says so when nothing is confirmed" {
  add_entry k:a >/dev/null
  run "$CTL" memory promote-list
  [[ "$output" == *"No confirmed entries waiting for promotion"* ]]
}

@test "memory promote: only a confirmed entry is promoted; it then leaves every query" {
  add_entry k:a >/dev/null
  run "$CTL" memory promote M0001 --ref "#190"
  [ "$status" -eq 1 ]
  "$CTL" memory confirm M0001 >/dev/null
  run "$CTL" memory promote M0001 --ref "#190"
  [ "$status" -eq 0 ]
  grep -qx 'promoted_ref: #190' "$ENTRIES"/M0001-*.md
  run "$CTL" memory query
  [[ "$output" != *"M0001"* ]]
  run "$CTL" memory promote M0001 --ref 'x; rm -rf /'
  [ "$status" -eq 2 ]
}
