# shellcheck shell=bash
# (sourced by eval/bin/devflow-eval, not executed directly -- no shebang)
# Checks for 005-stats-median-cli. CWD is the result workspace, which must have
# started as a copy of fixture/ (`devflow-eval init`).
#
# The prompt asks for one new command. Most outcome weight sits on what a
# median implies but the prompt does not spell out: numbers must compare as
# numbers, an even count has no middle value, and the module's own convention
# for empty and invalid input applies. They measure whether the run DISCOVERED
# those cases.

# Process — reported, never gates.
check_process 1 "Spec or feature plan produced"  devflow_artifact_any spec plan feature
check_process 1 "Review artifact produced"       devflow_artifact review

# probe.js lives next to this file, outside the result workspace, so a run can
# neither read nor edit it.
EVAL_TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

probe() { # probe <scenario>
  node "$EVAL_TASK_DIR/probe.js" "$1"
}

# Negative scenarios ("empty input is rejected") pass vacuously when the command
# does not exist at all — an unknown command also exits 1. Gate them on the
# happy path so an untouched fixture earns nothing for them.
probe_if_implemented() { # probe_if_implemented <scenario>
  probe basic && probe "$1"
}

check 2 "median of an odd count is the middle value"                       probe basic
check 2 "[logic] median of an even count is the mean of the two middle"    probe_if_implemented even-count
check 3 "[logic] numbers are ordered as numbers, not as text"              probe_if_implemented numeric-sort
check 1 "median of a single number is that number"                         probe_if_implemented single
check 2 "[data limits] no numbers is a usage error, not NaN or a crash"    probe_if_implemented empty
check 1 "[data limits] a non-numeric argument is rejected and named"       probe_if_implemented invalid
check 1 "Existing commands behave as before"                               probe existing-intact
check 1 "Usage text lists the new command"                                 probe_if_implemented usage-lists-median

check 1 "Tests reference the median command" \
  bash -c 'grep -rqi "median" test/ 2>/dev/null'
check 2 "Project test suite passes" \
  bash -c 'npm test --silent >/dev/null 2>&1'
