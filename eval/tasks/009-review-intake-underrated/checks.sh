# shellcheck shell=bash
# (sourced by eval/bin/devflow-eval, not executed directly -- no shebang)
# Checks for 009-review-intake-underrated. CWD is the result workspace, seeded
# from fixture/ and run with DEVFLOW_HOME="$PWD/.devflow-home" so the framework
# memory the run writes is scored here too.
#
# The prompt only asks to bring an external review back into DevFlow. The
# weight sits on what the intake must get right without being told:
# a finding the internal review excused on a false premise is an escape; a
# finding the author chose not to fix is still one; every escape names its
# cycle; a wrong comment records nothing; and the lesson reaches the cycle's
# metrics, learnings.md and the framework memory.

check_process 1 "Intake report saved"  bash -c 'ls docs/devflow/reviews/*-intake.md >/dev/null 2>&1'

ESC="docs/devflow/knowledge-base/escapes.md"
SLUG="quote-header"

escape_rows() { # escape_rows <note-ere> — rows of escapes.md recorded against the cycle whose note matches
  [[ -f "$ESC" ]] || return 1
  awk -F'|' -v s="$SLUG" -v re="$1" '
    /^\| E[0-9]/ { c = $7; gsub(/^ +| +$/, "", c); n = tolower($5 " " $6); if (c == s && n ~ re) print }
  ' "$ESC" | grep -q .
}

underrated() { # the excused finding: an escape, layer reviewer:*, against the cycle
  [[ -f "$ESC" ]] || return 1
  awk -F'|' -v s="$SLUG" '
    /^\| E[0-9]/ { c = $7; l = $4; gsub(/^ +| +$/, "", c); gsub(/^ +| +$/, "", l); n = tolower($5 " " $6)
      if (c == s && l ~ /^reviewer:/ && n ~ /tax|deliberate|premise|scope|sensitive|i1/) ok = 1 }
    END { exit !ok }
  ' "$ESC"
}

all_rows_named() { # at least the three real escapes, and every row names the cycle
  [[ -f "$ESC" ]] || return 1
  awk -F'|' -v s="$SLUG" '
    /^\| E[0-9]/ { n++; c = $7; gsub(/^ +| +$/, "", c); if (c != s) bad = 1 }
    END { exit !(n >= 3 && !bad) }
  ' "$ESC"
}

no_disagreement() { # the wrong comment (caller undefined) leaves no escape and no false positive
  escape_rows '.' || return 1   # gated: an intake that recorded nothing earns nothing here
  escape_rows 'caller|undefined' && return 1
  ! grep -rlqE '^type: false-positive' .devflow-home/memory/entries 2>/dev/null
}

metrics_match() { # Escapes after APPROVED == escapes recorded for the cycle
  local m n
  m="$(grep -hE '^\| *Escapes after APPROVED' docs/devflow/metrics/*-quote-header-metrics.md 2>/dev/null | grep -oE '[0-9]+' | head -1)"
  n="$(awk -F'|' -v s="$SLUG" '/^\| E[0-9]/ { c = $7; gsub(/^ +| +$/, "", c); if (c == s) k++ } END { print k + 0 }' "$ESC" 2>/dev/null)"
  [[ -n "$m" && "$m" -ge 3 && "$m" == "$n" ]]
}

learnings_found_after() { # the cycle's entry carries what was found after review, marked with its escapes
  local e
  e="$(awk '/^### quote-header/ { on = 1; print; next } on && /^(##|###) / { exit } on' docs/devflow/knowledge-base/learnings.md 2>/dev/null)"
  grep -qi 'found after review' <<< "$e" && grep -qE '(→|->) *E[0-9]+' <<< "$e"
}

memory_escape_abstract() { # a framework escape entry for a reviewer layer, naming no project file
  local f ok=1
  for f in .devflow-home/memory/entries/*.md; do
    [[ -f "$f" ]] || continue
    grep -q '^type: escape' "$f" && grep -q '^layer: reviewer:' "$f" && ! grep -qE 'src/quotes\.js|quote-header' "$f" && ok=0
  done
  return $ok
}

check 3 "[underrated] The finding excused as a deliberate decision on a false premise is an escape of the cycle" underrated
check 2 "[accepted risk] The 404 finding the author will not fix is still an escape"  escape_rows '404|not found|contract'
check 1 "[defect] The missing createdAt assertion is an escape"                         escape_rows 'createdat|assert'
check 2 "Every escape names the cycle — none recorded against 'unknown'"               all_rows_named
check 1 "[disagreement] The wrong comment records nothing"                              no_disagreement
check 2 "The cycle's metrics count its escapes"                                         metrics_match
check 1 "The accepted risks are in the backlog" \
  bash -c 'grep -qiE "tax|scope" docs/devflow/backlog/deferred.md 2>/dev/null && grep -qiE "404|not found|company" docs/devflow/backlog/deferred.md'
check 2 "learnings.md: what was found after review, under the cycle, marked with its escapes" learnings_found_after
check 2 "Framework memory: the reviewer's miss as an escape entry, in the abstract"   memory_escape_abstract
