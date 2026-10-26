#!/usr/bin/env bats
#
# PR review intake (F124): which PR came from which cycle, and its review
# comments collected into a local inbox. GitHub is a fake `gh` answering from
# fixtures; it fails the test if anything tries to write.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  CTL="$REPO/.agents/skills/shared/bin/devflow-ctl"
  unset CI DEVFLOW_AUTONOMOUS
  export DEVFLOW_HOME="$BATS_TEST_TMPDIR/home"
  export DEVFLOW_SESSION_ROOT="docs/devflow/session"
  export DEVFLOW_MEMORY_VIEW="$BATS_TEST_TMPDIR/view.md"
  export DEVFLOW_KNOWLEDGE_FILE="$BATS_TEST_TMPDIR/learnings.md"
  export DEVFLOW_TODAY="2026-10-20"
  export GH_FIXTURES="$BATS_TEST_TMPDIR/gh"
  export GH_LOG="$BATS_TEST_TMPDIR/gh.log"
  export PATH="$REPO/tests/fixtures/gh:$PATH"
  mkdir -p "$GH_FIXTURES"
  PROJ="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$PROJ" && cd "$PROJ"
  git init -q -b main
  git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  git remote add origin git@github.com:acme/shop.git
  INBOX="$DEVFLOW_HOME/memory/registry/inbox/acme__shop"
}

fixture() { cat > "$GH_FIXTURES/$(printf '%s' "$1" | tr '/?&=' '____').json"; }

write_pr_fixtures() {
  fixture "repos/acme/shop/pulls?state=open&per_page=100" << 'EOF'
[ {"number": 12, "head": {"ref": "feat/quote-pdf/stack-1"}, "state": "open"},
  {"number": 13, "head": {"ref": "fix/unrelated"}, "state": "open"} ]
EOF
  fixture "repos/acme/shop/pulls/12/comments" << 'EOF'
[ {"id": 100, "in_reply_to_id": null, "user": {"login": "reviewer-bot"}, "created_at": "2026-10-20T10:00:00Z",
   "path": "src/Quote.cs", "line": 90, "html_url": "https://x/100", "body": "Any seller can read the tax id?\nScenario: ..."},
  {"id": 101, "in_reply_to_id": 100, "user": {"login": "author"}, "created_at": "2026-10-20T11:00:00Z",
   "path": "src/Quote.cs", "line": 90, "html_url": "https://x/101", "body": "We accept the risk."},
  {"id": 110, "in_reply_to_id": null, "user": {"login": "reviewer-bot"}, "created_at": "2026-10-20T10:01:00Z",
   "path": "src/Quote.cs", "line": null, "original_line": 127, "html_url": "https://x/110", "body": "404 means two things\twith a tab \\d"} ]
EOF
  fixture "repos/acme/shop/pulls/12/reviews" << 'EOF'
[ {"id": 200, "user": {"login": "reviewer-bot"}, "submitted_at": "2026-10-20T10:00:00Z", "html_url": "https://x/r200", "body": "## Review\n2 findings"},
  {"id": 201, "user": {"login": "reviewer-bot"}, "submitted_at": "2026-10-20T10:00:00Z", "html_url": "https://x/r201", "body": ""} ]
EOF
  fixture "repos/acme/shop/issues/12/comments" << 'EOF'
[ {"id": 300, "user": {"login": "author"}, "created_at": "2026-10-20T12:00:00Z", "html_url": "https://x/c300", "body": "@bot /fix-comments"} ]
EOF
}

@test "pr register: records the cycle's branch against the origin repo (ssh or https remote)" {
  run "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1
  [ "$status" -eq 0 ]
  grep -qP '^acme/shop\t-\tp-[0-9a-f]+\tquote-pdf\tfeat/quote-pdf/stack-1\t' "$DEVFLOW_HOME/memory/registry/prs.tsv"
  git remote set-url origin https://github.com/acme/other.git
  run "$CTL" pr register --slug quote-pdf --branch b2
  grep -q "^acme/other" "$DEVFLOW_HOME/memory/registry/prs.tsv"
  run "$CTL" pr register --branch b3
  [ "$status" -eq 2 ]
  git remote set-url origin /some/local/path
  run "$CTL" pr register --slug x --branch b4
  [ "$status" -eq 2 ]
  [[ "$output" == *"--repo"* ]]
}

@test "pr poll: reads only open PRs of DevFlow cycles, all three kinds of comment, and never writes" {
  write_pr_fixtures
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1
  run "$CTL" pr poll --repo acme/shop
  [ "$status" -eq 0 ]
  [[ "$output" == *"acme/shop: 1 PR(s) read, 5 new comment(s)"* ]]
  [ -f "$INBOX/12.tsv" ]
  [ ! -f "$INBOX/13.tsv" ]
  grep -qP '^inline\t101\t100\tauthor\t' "$INBOX/12.tsv"
  grep -qP '^inline\t110\t-\treviewer-bot\t.*\t127\t' "$INBOX/12.tsv"
  grep -qP '^review\t200\t' "$INBOX/12.tsv"
  ! grep -qP '^review\t201\t' "$INBOX/12.tsv"
  grep -qP '^comment\t300\t' "$INBOX/12.tsv"
  grep -qP '^acme/shop\t12\t.*\tquote-pdf\tfeat/quote-pdf/stack-1\topen\t' "$DEVFLOW_HOME/memory/registry/prs.tsv"
  ! grep -qE -- '(-X|--method|-f |--field)' "$GH_LOG"
}

@test "pr poll: a second pass adds only what is new" {
  write_pr_fixtures
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1
  "$CTL" pr poll --repo acme/shop
  run "$CTL" pr poll --repo acme/shop
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 new comment(s)"* ]]
  [ "$(grep -c . "$INBOX/12.tsv")" -eq 5 ]
}

@test "pr poll: a cycle recorded by init is found by its slug in the branch name, with no register" {
  write_pr_fixtures
  "$CTL" init --mode lifecycle --slug quote-pdf >/dev/null
  run "$CTL" pr poll --repo acme/shop
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 PR(s) read"* ]]
  grep -qP '\t12\t.*\tquote-pdf\t' "$DEVFLOW_HOME/memory/registry/prs.tsv"
}

@test "pr poll --pr: a merged PR is read only when named, whatever its state" {
  write_pr_fixtures
  fixture "repos/acme/shop/pulls/9" << 'EOF'
{"number": 9, "head": {"ref": "feat/old"}, "state": "closed", "merged_at": "2026-10-01T00:00:00Z"}
EOF
  echo '[]' | fixture "repos/acme/shop/pulls/9/comments"
  echo '[]' | fixture "repos/acme/shop/pulls/9/reviews"
  echo '[{"id": 900, "user": {"login": "qa"}, "created_at": "2026-10-02T00:00:00Z", "html_url": "u", "body": "bug"}]' | fixture "repos/acme/shop/issues/9/comments"
  run "$CTL" pr poll --repo acme/shop
  [[ "$output" == *"0 PR(s) read"* ]]
  run "$CTL" pr poll --repo acme/shop --pr 9
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 PR(s) read, 1 new comment(s)"* ]]
  grep -qP '^acme/shop\t9\t-\t-\tfeat/old\tmerged\t' "$DEVFLOW_HOME/memory/registry/prs.tsv"
}

@test "pr poll: a network failure warns and exits 0; no repository is not an error" {
  run "$CTL" pr poll
  [ "$status" -eq 0 ]
  [[ "$output" == *"No repository is watched"* ]]
  GH_FAIL=1 run "$CTL" pr poll --repo acme/shop
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN"*"next pass retries"* ]]
  run "$CTL" pr poll --repo 'bad repo'
  [ "$status" -eq 2 ]
}

@test "pr poll: with no --repo, polls the watched repositories and logs scheduled passes" {
  write_pr_fixtures
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1
  mkdir -p "$DEVFLOW_HOME/memory/registry"
  printf 'acme/shop\t30m\n' > "$DEVFLOW_HOME/memory/registry/watch.tsv"
  run "$CTL" pr poll --scheduled
  [ "$status" -eq 0 ]
  grep -q "acme/shop: 1 PR(s) read, 5 new comment(s)" "$DEVFLOW_HOME/memory/registry/pr-watch.log"
}

@test "pr inbox/done: threads are printed with their replies, bodies unescaped; done clears them" {
  write_pr_fixtures
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1
  "$CTL" pr poll --repo acme/shop
  run "$CTL" pr inbox
  [ "$status" -eq 0 ]
  [[ "$output" == *"PR #12 (acme/shop) — cycle: quote-pdf"*"5 pending"* ]]
  [[ "$output" == *"Any seller can read the tax id?"$'\n'"   Scenario: ..."* ]]
  [[ "$output" == *"── inline:100"*"↳ reply inline:101 to 100"*"We accept the risk."* ]]
  [[ "$output" == *$'with a tab \\d'* ]]
  run "$CTL" pr done 12 inline:100 101
  [ "$status" -eq 0 ]
  run "$CTL" pr list
  [[ "$output" == *"acme/shop"*"12"*"quote-pdf"*"open"*"3"* ]]
  run "$CTL" pr done 12 --all
  run "$CTL" pr inbox
  [[ "$output" == *"No review comment is pending intake."* ]]
}

@test "pr inbox: with no --repo, lists every repo's pending PRs, whatever checkout it runs from" {
  write_pr_fixtures
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1
  "$CTL" pr poll --repo acme/shop >/dev/null
  git remote set-url origin git@github.com:acme/other.git
  run "$CTL" pr inbox
  [ "$status" -eq 0 ]
  [[ "$output" == *"PR #12 (acme/shop)"*"5 pending"* ]]
  cd "$BATS_TEST_TMPDIR"
  run "$CTL" pr inbox
  [[ "$output" == *"PR #12 (acme/shop)"* ]]
  run "$CTL" pr inbox --repo acme/other
  [[ "$output" == *"No review comment is pending intake."* ]]
}

@test "status and capabilities name the PRs with comments pending intake" {
  write_pr_fixtures
  "$CTL" init --mode lifecycle --slug quote-pdf >/dev/null
  "$CTL" pr poll --repo acme/shop >/dev/null
  run "$CTL" status --slug quote-pdf
  [ "$status" -eq 0 ]
  [[ "$output" == *"Review intake: PR #12 (acme/shop) has 5 comment(s) pending — /devflow-review intake --pending"* ]]
  run "$CTL" capabilities
  [[ "$output" == *"PR #12 (acme/shop) has 5 comment(s) pending"* ]]
  "$CTL" pr done 12 --all >/dev/null
  run "$CTL" status --slug quote-pdf
  [[ "$output" != *"Review intake"* ]]
}

@test "pr poll: stable under a hostile locale" {
  write_pr_fixtures
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1
  LC_ALL=es_ES.UTF-8 run "$CTL" pr poll --repo acme/shop
  [ "$status" -eq 0 ]
  [[ "$output" == *"5 new comment(s)"* ]]
}


# ── pr watch (F125) ───────────────────────────────────────────────────────────
# The schedulers are fakes on PATH; HOME and XDG_CONFIG_HOME point into the
# test directory, so nothing on the real machine is ever scheduled.

setup_watch() {
  export PATH="$REPO/tests/fixtures/sched:$PATH"
  export HOME="$BATS_TEST_TMPDIR/userhome"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export SCHED_LOG="$BATS_TEST_TMPDIR/sched.log"
  export CRONTAB_FILE="$BATS_TEST_TMPDIR/crontab"
  mkdir -p "$HOME"
  echo '{"full_name": "acme/shop"}' | fixture "repos/acme/shop"
  echo '[]' | fixture "repos/acme/shop/pulls?state=open&per_page=100"
  STATE="$DEVFLOW_HOME/memory/registry/watch.state"
}

@test "pr watch start: systemd --user timer with the interval, the absolute ctl path, DEVFLOW_HOME and PATH" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=systemd
  run "$CTL" pr watch start --repo acme/shop --every 30m
  [ "$status" -eq 0 ]
  [[ "$output" == *"watching 1 repo(s) every 30m"* ]]
  [[ "$output" == *"First pass now:"*"acme/shop: 0 PR(s) read"* ]]
  unit="$XDG_CONFIG_HOME/systemd/user/devflow-pr-watch"
  grep -q "OnUnitActiveSec=30min" "$unit.timer"
  grep -q "ExecStart=\"$CTL\" pr poll --scheduled" "$unit.service"
  grep -q "DEVFLOW_HOME=$DEVFLOW_HOME" "$unit.service"
  grep -q "enable --now devflow-pr-watch.timer" "$SCHED_LOG"
  grep -qx "scheduler=systemd" "$STATE"
  grep -qx "acme/shop" "$DEVFLOW_HOME/memory/registry/watch.tsv"
}

@test "pr watch start again: adds a repository and changes the interval without a second job" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=cron
  echo '{"full_name": "acme/api"}' | fixture "repos/acme/api"
  echo '[]' | fixture "repos/acme/api/pulls?state=open&per_page=100"
  echo "0 3 * * * backup.sh" > "$CRONTAB_FILE"
  run "$CTL" pr watch start --repo acme/shop --every 30m
  [ "$status" -eq 0 ]
  run "$CTL" pr watch start --repo acme/api --every 2h
  [ "$status" -eq 0 ]
  [ "$(grep -c 'devflow-pr-watch' "$CRONTAB_FILE")" -eq 1 ]
  grep -q '^0 \*/2 \* \* \* .* pr poll --scheduled .*# devflow-pr-watch$' "$CRONTAB_FILE"
  grep -q "backup.sh" "$CRONTAB_FILE"
  [ "$(grep -c . "$DEVFLOW_HOME/memory/registry/watch.tsv")" -eq 2 ]
}

@test "pr watch stop: removes exactly what start installed and keeps repos and inbox" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=cron
  echo "0 3 * * * backup.sh" > "$CRONTAB_FILE"
  "$CTL" pr watch start --repo acme/shop --every 15m >/dev/null
  run "$CTL" pr watch stop
  [ "$status" -eq 0 ]
  ! grep -q "devflow-pr-watch" "$CRONTAB_FILE"
  grep -q "backup.sh" "$CRONTAB_FILE"
  [ ! -f "$STATE" ]
  grep -qx "acme/shop" "$DEVFLOW_HOME/memory/registry/watch.tsv"
  run "$CTL" pr watch stop
  [[ "$output" == *"not running"* ]]
}

@test "pr watch: launchd agent on macOS; stop unloads and deletes it" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=launchd
  run "$CTL" pr watch start --repo acme/shop --every 1h
  [ "$status" -eq 0 ]
  plist="$HOME/Library/LaunchAgents/dev.devflow.pr-watch.plist"
  grep -q "<integer>3600</integer>" "$plist"
  grep -q "launchctl load -w $plist" "$SCHED_LOG"
  run "$CTL" pr watch stop
  [ ! -f "$plist" ]
}

@test "pr watch start: refuses without a repository when no one can choose, in CI, with a bad interval or an unreadable repo" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=cron
  run "$CTL" pr watch start < /dev/null
  [ "$status" -eq 2 ]
  [[ "$output" == *"no repository"* ]]
  CI=true run "$CTL" pr watch start --repo acme/shop
  [ "$status" -eq 2 ]
  DEVFLOW_AUTONOMOUS=true run "$CTL" pr watch start --repo acme/shop
  [ "$status" -eq 2 ]
  run "$CTL" pr watch start --repo acme/shop --every 2m
  [ "$status" -eq 2 ]
  run "$CTL" pr watch start --repo acme/missing
  [ "$status" -eq 1 ]
  DEVFLOW_PR_SCHEDULER=none run "$CTL" pr watch start --repo acme/shop
  [ "$status" -eq 2 ]
  [[ "$output" == *"no scheduler available"* ]]
  [ ! -f "$STATE" ]
  [ ! -f "$CRONTAB_FILE" ]
}

@test "pr watch start --dry-run: says what it would install and changes nothing" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=systemd
  run "$CTL" pr watch start --repo acme/shop --every 30m --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would watch: acme/shop"* ]]
  [[ "$output" == *"Would install: systemd --user timer"* ]]
  [ ! -f "$STATE" ]
  [ ! -e "$XDG_CONFIG_HOME/systemd" ]
  [ ! -s "$SCHED_LOG" ]
}

@test "pr watch status, add, remove, candidates" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=cron
  run "$CTL" pr watch status
  [[ "$output" == *"PR watch: off"*"Repositories: (none)"* ]]
  "$CTL" pr watch start --repo acme/shop --every 30m >/dev/null
  run "$CTL" pr watch status
  [[ "$output" == *"PR watch: on — crontab line"*"every 30m"* ]]
  [[ "$output" == *"Last pass:"*"acme/shop"* ]]
  "$CTL" pr watch add --repo acme/api >/dev/null
  "$CTL" pr watch remove --repo acme/shop >/dev/null
  run "$CTL" pr watch list
  [ "$output" = "acme/api" ]
  "$CTL" init --mode lifecycle --slug quote-pdf >/dev/null
  echo '[{"full_name": "acme/shop"}, {"full_name": "other/lib"}]' | fixture "user/repos?per_page=100&affiliation=owner,collaborator,organization_member&sort=pushed"
  run "$CTL" pr watch candidates
  [ "${lines[0]}" = "★ acme/shop" ]
  [ "${lines[1]}" = "  other/lib" ]
  run "$CTL" pr watch candidates --filter LIB
  [ "$output" = "  other/lib" ]
}

@test "pr watch remove warns on a repo not watched and points to stop when none is left" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=cron
  run "$CTL" pr watch add --repo not-a-repo
  [ "$status" -eq 2 ]
  "$CTL" pr watch start --repo acme/shop --every 30m >/dev/null
  run "$CTL" pr watch remove --repo acme/nope
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN: acme/nope was not watched"* ]]
  [[ "$output" == *"watching: acme/shop"* ]]
  run "$CTL" pr watch remove --repo acme/shop
  [[ "$output" == *"watching: (none)"* ]]
  [[ "$output" == *"pr watch stop"* ]]
  run "$CTL" pr watch status
  [[ "$output" == *"PR watch: on"*"Repositories: (none)"* ]]
}


@test "pr watch start/stop must start the command line, so a prefix permission rule sees them" {
  setup_watch
  export DEVFLOW_PR_SCHEDULER=cron
  run "$CTL" pr watch --repo acme/shop start
  [ "$status" -eq 2 ]
  [[ "$output" == *"must start the command line"* ]]
  run "$CTL" --slug x pr watch stop
  [ "$status" -eq 2 ]
  [ ! -f "$CRONTAB_FILE" ]
}


# ── pr poll skips PRs with nothing new since the last read ───────────────────

write_timed_pulls() { # write_timed_pulls <updated_at> <sha>
  fixture "repos/acme/shop/pulls?state=open&per_page=100" << EOF
[ {"number": 12, "head": {"ref": "feat/quote-pdf/stack-1", "sha": "$2"}, "state": "open", "updated_at": "$1"} ]
EOF
}

reads_of_12() { grep -c 'repos/acme/shop/pulls/12/comments' "$GH_LOG" || true; }

@test "pr poll: a PR unchanged since the last complete read is skipped; any change reads it again" {
  write_pr_fixtures
  write_timed_pulls 2026-10-20T10:00:00Z aaa111
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1 >/dev/null
  "$CTL" pr poll --repo acme/shop >/dev/null
  [ "$(reads_of_12)" -eq 1 ]
  run "$CTL" pr poll --repo acme/shop
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 PR(s) read, 0 new comment(s), 1 unchanged since the last read"* ]]
  [ "$(reads_of_12)" -eq 1 ]
  write_timed_pulls 2026-10-20T11:00:00Z aaa111        # a new comment or reply
  "$CTL" pr poll --repo acme/shop >/dev/null
  [ "$(reads_of_12)" -eq 2 ]
  write_timed_pulls 2026-10-20T11:00:00Z bbb222        # a push
  "$CTL" pr poll --repo acme/shop >/dev/null
  [ "$(reads_of_12)" -eq 3 ]
}

@test "pr poll: a read that failed is not recorded, so the next pass reads the PR again" {
  write_pr_fixtures
  write_timed_pulls 2026-10-20T10:00:00Z aaa111
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1 >/dev/null
  mv "$GH_FIXTURES/repos_acme_shop_issues_12_comments.json" "$BATS_TEST_TMPDIR/saved.json"
  run "$CTL" pr poll --repo acme/shop
  [[ "$output" == *"could not read its comments"* ]]
  mv "$BATS_TEST_TMPDIR/saved.json" "$GH_FIXTURES/repos_acme_shop_issues_12_comments.json"
  run "$CTL" pr poll --repo acme/shop
  [[ "$output" == *"1 PR(s) read, 5 new comment(s)"* ]]
}

@test "pr poll: --pr always reads; a PR without updated_at is never skipped" {
  write_pr_fixtures
  write_timed_pulls 2026-10-20T10:00:00Z aaa111
  fixture "repos/acme/shop/pulls/12" << 'EOF'
{"number": 12, "head": {"ref": "feat/quote-pdf/stack-1", "sha": "aaa111"}, "state": "open", "merged_at": null, "updated_at": "2026-10-20T10:00:00Z"}
EOF
  "$CTL" pr register --slug quote-pdf --branch feat/quote-pdf/stack-1 >/dev/null
  "$CTL" pr poll --repo acme/shop >/dev/null
  "$CTL" pr poll --repo acme/shop --pr 12 >/dev/null
  [ "$(reads_of_12)" -eq 2 ]
  write_pr_fixtures                                      # the list again, without updated_at
  "$CTL" pr poll --repo acme/shop >/dev/null
  "$CTL" pr poll --repo acme/shop >/dev/null
  [ "$(reads_of_12)" -eq 4 ]
}
