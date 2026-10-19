#!/usr/bin/env bats
#
# Behavioral suite for scripts/merge-settings.py — how install.sh writes DevFlow's
# permission rules into each editor's settings — and for the shipped snippets
# under the rules each editor actually applies.
#
# Run: npm test   (or: ./node_modules/.bin/bats tests/permissions.bats)

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  MERGE="$REPO/scripts/merge-settings.py"
  SNIPPETS="$REPO/editor-profiles/permissions"
  TARGET="$BATS_TEST_TMPDIR/settings.json"
  SKILLS="$BATS_TEST_TMPDIR/skills"
}

# install_snippet <name> — substitute placeholders exactly as install.sh does,
# then merge into $TARGET. install.sh substitutes $SKILLS_DIR, $USER_DIR and
# $HOME (in that order); this helper must mirror it or it goes blind the day a
# snippet uses $USER_DIR.
install_snippet() {
  local _ud="$BATS_TEST_TMPDIR/userdir"
  mkdir -p "$_ud"
  sed -e "s|\$SKILLS_DIR|$SKILLS|g" -e "s|\$USER_DIR|$_ud|g" -e "s|\$HOME|$HOME|g" "$SNIPPETS/$1" | python3 "$MERGE" "$TARGET"
}

# opencode_verdict <command> — the verdict opencode applies to a command:
# permission.bash patterns, '*' = any run of characters, LAST match wins.
opencode_verdict() {
  python3 - "$TARGET" "$1" <<'PY'
import json, re, sys
rules = json.load(open(sys.argv[1]))["permission"]["bash"]
verdict = "allow (default)"
for pattern, v in rules.items():
    if re.fullmatch(".*".join(map(re.escape, pattern.split("*"))), sys.argv[2]):
        verdict = v
print(verdict)
PY
}

# ── Claude Code ───────────────────────────────────────────────────────────────

@test "claude-code: retires the rules older versions installed and keeps the user's own" {
  cat > "$TARGET" <<JSON
{"model": "opus", "permissions": {"allow": [
  "Bash(my-tool *)", "Write(docs/devflow/**)", "Read($SKILLS/**)", "Edit(docs/devflow/**)"
]}}
JSON
  run install_snippet claude-code.json
  [ "$status" -eq 0 ]
  run python3 -c "import json; a=json.load(open('$TARGET'))['permissions']['allow']; print('\n'.join(a))"
  [[ "$output" != *"Write(docs/devflow/**)"* ]]
  [[ "$output" != *"Read($SKILLS/**)"* ]]
  [[ "$output" == *"Bash(my-tool *)"* ]]
  [ "$(grep -c '^Edit(docs/devflow/\*\*)$' <<< "$output")" -eq 1 ]
  grep -q '"model": "opus"' "$TARGET"
  ! grep -q '_devflow_retired' "$TARGET"
}

@test "claude-code: the shipped snippet has no rule Claude Code ignores" {
  install_snippet claude-code.json
  run python3 -c "
import json, re
p = json.load(open('$TARGET'))['permissions']
for tier in ('allow', 'ask', 'deny'):
    for e in p.get(tier, []):
        m = re.match(r'^(Write|NotebookEdit|MultiEdit|Glob)\(', e) or re.match(r'^(Read|Edit)\(/(?!/)', e)
        if m: print(e)"
  [ -z "$output" ]
}

# ── opencode ──────────────────────────────────────────────────────────────────

@test "opencode: a fresh install denies what DevFlow forbids (last match wins)" {
  install_snippet opencode.json
  [ "$(opencode_verdict 'git commit --no-verify -m x')" = "deny" ]
  [ "$(opencode_verdict 'git push --force origin main')" = "deny" ]
  [ "$(opencode_verdict 'git commit --amend')" = "ask" ]
  [ "$(opencode_verdict 'git push origin main')" = "ask" ]
  [ "$(opencode_verdict 'rm -rf build')" = "ask" ]
  [ "$(opencode_verdict 'git commit -m x')" = "allow" ]
}

@test "opencode: re-installing over a mis-ordered config restores the precedence" {
  # What earlier versions left behind: allow rules after the deny/ask ones.
  cat > "$TARGET" <<'JSON'
{"permission": {"bash": {
  "git push --force*": "deny", "git commit --no-verify*": "deny", "git commit --amend*": "ask",
  "mkdir -p docs/devflow*": "allow", "my-script *": "allow", "git commit *": "allow"
}}}
JSON
  [ "$(opencode_verdict 'git commit --no-verify -m x')" = "allow" ]   # the bug
  install_snippet opencode.json
  [ "$(opencode_verdict 'git commit --no-verify -m x')" = "deny" ]
  [ "$(opencode_verdict 'git commit --amend')" = "ask" ]
  run python3 -c "import json; b=json.load(open('$TARGET'))['permission']['bash']; print(list(b)[0]); print('mkdir -p docs/devflow*' in b)"
  [ "${lines[0]}" = "my-script *" ]     # the user's own rule is kept, first
  [ "${lines[1]}" = "False" ]           # the retired rule is gone
}

@test "opencode: the user's own verdict for a DevFlow pattern wins" {
  echo '{"permission": {"bash": {"git commit *": "ask"}}}' > "$TARGET"
  install_snippet opencode.json
  [ "$(opencode_verdict 'git commit -m x')" = "ask" ]
}

@test "opencode: the installed skills directory is an allowed external directory" {
  install_snippet opencode.json
  run python3 -c "import json; print(json.load(open('$TARGET'))['permission']['external_directory']['$SKILLS/**'])"
  [ "$output" = "allow" ]
}

@test "opencode: supply-chain commands require approval (no silent install/execute)" {
  install_snippet opencode.json
  [ "$(opencode_verdict 'npx some-package')" = "ask" ]
  [ "$(opencode_verdict 'pnpm add lodash')" = "ask" ]
  [ "$(opencode_verdict 'yarn add lodash')" = "ask" ]
  [ "$(opencode_verdict 'python -m pip install requests')" = "ask" ]
  [ "$(opencode_verdict 'python3 -m pip install requests')" = "ask" ]
  [ "$(opencode_verdict 'make deploy')" = "ask" ]
  [ "$(opencode_verdict 'go build ./...')" = "ask" ]
  [ "$(opencode_verdict 'cargo build')" = "ask" ]
  # Legitimate read-only / test commands stay allowed:
  [ "$(opencode_verdict 'grep foo bar')" = "allow" ]
  [ "$(opencode_verdict 'go test ./...')" = "allow" ]
  [ "$(opencode_verdict 'python script.py')" = "allow" ]
}

# ── Any editor ────────────────────────────────────────────────────────────────

@test "merge: a JSONC settings file is left untouched (exit 1)" {
  printf '{\n  // my comment\n  "a": 1,\n}\n' > "$TARGET"
  cp "$TARGET" "$BATS_TEST_TMPDIR/before"
  run install_snippet vscode.json
  [ "$status" -eq 1 ]
  cmp -s "$TARGET" "$BATS_TEST_TMPDIR/before"
}

@test "merge: a missing settings file is created" {
  run install_snippet vscode.json
  [ "$status" -eq 0 ]
  grep -q '"/devflow-ctl/": true' "$TARGET"
}

@test "merge: installing twice changes nothing the second time" {
  install_snippet opencode.json
  cp "$TARGET" "$BATS_TEST_TMPDIR/first"
  install_snippet opencode.json
  cmp -s "$TARGET" "$BATS_TEST_TMPDIR/first"
}

# ── devflow-ctl evidence run (F106) ───────────────────────────────────────────
# `devflow-ctl *` is auto-approved everywhere, and `evidence run` executes the
# command written in the session's Stack Profile — so it alone must ask, in
# every form the agent may call it in. devflow-ctl itself refuses `evidence
# run` unless it starts the command line, which is what makes a prefix rule
# enough.

# claude_verdict <command> — Claude Code: deny > ask > allow, '*' = any run.
claude_verdict() {
  python3 - "$TARGET" "$1" <<'PY'
import json, re, sys
perms = json.load(open(sys.argv[1]))["permissions"]
def hit(rule):
    m = re.match(r"^Bash\((.*)\)$", rule)
    return m and re.fullmatch(".*".join(map(re.escape, m.group(1).split("*"))), sys.argv[2])
for tier in ("deny", "ask", "allow"):
    if any(hit(r) for r in perms.get(tier, [])):
        print(tier); break
else:
    print("default")
PY
}

@test "evidence run: asks in Claude Code, in every invocation form; the rest of devflow-ctl stays allowed" {
  install_snippet claude-code.json
  [ "$(claude_verdict 'devflow-ctl evidence run --kind test')" = "ask" ]
  [ "$(claude_verdict "$SKILLS/shared/bin/devflow-ctl evidence run --kind lint --slug x")" = "ask" ]
  [ "$(claude_verdict "bash $SKILLS/shared/bin/devflow-ctl evidence run --kind test")" = "ask" ]
  [ "$(claude_verdict 'devflow-ctl evidence list')" = "allow" ]
  [ "$(claude_verdict 'devflow-ctl gate check confirmation')" = "allow" ]
}

@test "evidence run: asks in opencode (last match wins), the rest of devflow-ctl stays allowed" {
  install_snippet opencode.json
  [ "$(opencode_verdict 'devflow-ctl evidence run --kind test')" = "ask" ]
  [ "$(opencode_verdict "$SKILLS/shared/bin/devflow-ctl evidence run --kind test")" = "ask" ]
  [ "$(opencode_verdict "bash $SKILLS/shared/bin/devflow-ctl evidence run --kind test")" = "ask" ]
  [ "$(opencode_verdict 'devflow-ctl evidence attest --kind test --file p.txt')" = "allow" ]
}

@test "evidence run: VS Code has a false rule for it, which overrides the devflow-ctl true rule" {
  install_snippet vscode.json
  run python3 - "$TARGET" <<'PY'
import json, re, sys
rules = json.load(open(sys.argv[1]))["chat.tools.terminal.autoApprove"]
def approved(cmd):
    hits = [v for p, v in rules.items() if re.search(p.strip("/"), cmd)]
    return bool(hits) and False not in hits
assert not approved("devflow-ctl evidence run --kind test")
assert not approved("bash /x/shared/bin/devflow-ctl evidence run --kind test")
assert approved("devflow-ctl evidence list")
assert approved("devflow-ctl gate check confirmation")
PY
  [ "$status" -eq 0 ]
}
