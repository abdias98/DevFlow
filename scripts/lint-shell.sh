#!/usr/bin/env bash
# DevFlow — shell lint gate.
#
# devflow-ctl and the validator are the framework's kernel: ~2,400 lines of bash
# that every editor profile runs. Bash's failure mode is not a crash, it is a
# wrong answer delivered confidently -- a `grep '\|'` that GNU BRE reads as
# alternation, a `set -e` pipeline that aborts silently on a first-command miss,
# an `rm -rf "$dir/$name"` where an empty $name eats the parent. Every one of
# those shipped to main at some point and was found by running, not reading.
# ShellCheck sees that class in milliseconds.
#
# Gate level is `warning`: the repository is clean at that level, so any new
# finding is genuinely new. `info` and `style` are reported for information and
# do not fail the build.
#
# Usage:
#   bash scripts/lint-shell.sh          # gate at warning level
#   bash scripts/lint-shell.sh --all    # also print info/style findings
#
# Exit codes: 0 = clean (or shellcheck unavailable outside CI), 1 = findings

set -euo pipefail

SEVERITY="warning"
SHOW_ALL=false
[[ "${1:-}" == "--all" ]] && SHOW_ALL=true

red()    { echo -e "\033[0;31m[ERROR]\033[0m $*"; }
yellow() { echo -e "\033[0;33m[WARN]\033[0m  $*"; }
green()  { echo -e "\033[0;32m[OK]\033[0m    $*"; }

if ! command -v shellcheck >/dev/null 2>&1; then
  # In CI a missing linter must fail loudly -- a silently skipped gate is worse
  # than no gate, because the build still reports green.
  if [[ -n "${CI:-}" ]]; then
    red "shellcheck is not installed, but CI is set — refusing to skip the gate"
    echo "       Install it in the workflow (ubuntu-latest ships it; otherwise: apt-get install -y shellcheck)"
    exit 1
  fi
  yellow "shellcheck not found — skipping (install: apt install shellcheck | brew install shellcheck)"
  exit 0
fi

# Files that are actually shell: by extension, or by shebang. Discovered rather
# than listed, so a new script is covered the moment it exists -- including one
# not yet committed, so a script can be linted before it is added.
FILES=()
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  if [[ "$f" == *.sh ]] || head -c 200 "$f" 2>/dev/null | head -1 | grep -qE '^#!.*\b(bash|sh)\b'; then
    FILES+=("$f")
  fi
done < <(git ls-files --cached --others --exclude-standard 2>/dev/null | sort -u || true)

if [[ ${#FILES[@]} -eq 0 ]]; then
  yellow "No shell files found — nothing to lint"
  exit 0
fi

echo "Linting ${#FILES[@]} shell file(s) at severity '$SEVERITY':"
printf '  %s\n' "${FILES[@]}"
echo ""

rc=0
shellcheck -S "$SEVERITY" -f gcc "${FILES[@]}" || rc=1

if [[ $rc -ne 0 ]]; then
  echo ""
  red "shellcheck reported findings at severity '$SEVERITY' or above"
  echo "       Fix them, or annotate a deliberate exception with a justified"
  echo "       '# shellcheck disable=SCxxxx' comment — never a blanket disable."
  exit 1
fi

green "No shellcheck findings at severity '$SEVERITY' or above"

if $SHOW_ALL; then
  echo ""
  echo "Informational (not gated):"
  shellcheck -S style -f gcc "${FILES[@]}" || true
fi
