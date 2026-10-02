#!/usr/bin/env bats
#
# Installs DevFlow for real, once per editor profile, into a throwaway HOME, and
# checks that what the editor receives uses that editor's tool names.
#
# From v2.2.0 until 4.16.0 install.sh never applied a single tool_mapping (the
# mapping reader split "key= value" on ': ', so the key kept its '='), and no
# test noticed: every editor got VS Code's tool names, and Claude Code asked
# every question as plain text because `vscode_askQuestions` does not exist there.
#
# Run: npm test   (or: ./node_modules/.bin/bats tests/install.bats)

setup_file() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export REPO
}

# install_profile <profile-id> — install into a fresh HOME; echoes the skills dir.
install_profile() {
  local idx home
  idx="$(ls "$REPO"/editor-profiles/*.yaml | grep -n "/$1.yaml$" | cut -d: -f1)"
  home="$BATS_TEST_TMPDIR/home-$1"
  mkdir -p "$home"
  printf '%s\n' "$idx" | env -u DEVFLOW_HOME -u XDG_DATA_HOME HOME="$home" bash "$REPO/install.sh" >"$BATS_TEST_TMPDIR/install-$1.log" 2>&1
  dirname "$(dirname "$(find "$home" -path '*/shared/rules.md' | head -1)")"
}

# mapped_tokens <profile-id> — the backticked source names this profile renames or removes.
mapped_tokens() {
  awk '/^tool_mappings:/{f=1;next} f&&/^[^ ]/{f=0} f&&/^  [a-zA-Z]/{k=$1; sub(/:$/,"",k); v=$2; if (k!=v) print k}' \
    "$REPO/editor-profiles/$1.yaml"
}

assert_no_source_names() { # <profile-id> <skills-dir>
  local t left=""
  for t in $(mapped_tokens "$1"); do
    if grep -rlq "\`$t\`" "$2" --include='*.md'; then left+=" $t"; fi
  done
  [ -z "$left" ] || { echo "unmapped in $1:$left"; return 1; }
}

@test "install: Claude Code receives its own tool names and asks through AskUserQuestion" {
  dir="$(install_profile claude-code)"
  assert_no_source_names claude-code "$dir"
  grep -q 'structured question tool:\*\* `AskUserQuestion`' "$dir/shared/rules.md"
  grep -rq 'Use `Write` to save' "$dir"
}

@test "install: opencode receives its own tool names and asks through question" {
  dir="$(install_profile opencode)"
  assert_no_source_names opencode "$dir"
  grep -q 'structured question tool:\*\* `question`' "$dir/shared/rules.md"
}

@test "install: generic (no question tool) keeps the numbered-options fallback" {
  dir="$(install_profile generic)"
  assert_no_source_names generic "$dir"
  ! grep -rq 'vscode_askQuestions' "$dir"
  grep -q 'Only if the editor has no such tool' "$dir/shared/rules.md"
  grep -q 'NEVER skip a question' "$dir/shared/rules.md"
}

@test "install: antigravity renames create_file and keeps the names it shares with VS Code" {
  dir="$(install_profile antigravity)"
  assert_no_source_names antigravity "$dir"
  grep -q 'structured question tool:\*\* `vscode_askQuestions`' "$dir/shared/rules.md"
}
