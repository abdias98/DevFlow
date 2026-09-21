# shellcheck shell=bash
# (sourced by eval/bin/devflow-eval, not executed directly -- no shebang)
# Checks for 007-notes-import-cli. CWD is the result workspace, which must have
# started as a copy of fixture/ (`devflow-eval init`).
#
# The prompt asks for a bulk import. Most outcome weight sits on what a bulk
# operation implies but the prompt does not spell out: it can fail halfway. A
# run that loops over the existing single-note operation leaves the notes before
# the bad one in the store. They measure whether the run DISCOVERED that.

# Process — reported, never gates.
check_process 1 "Spec or feature plan produced"  devflow_artifact_any spec plan
check_process 1 "Review artifact produced"       devflow_artifact review

# probe.js lives next to this file, outside the result workspace, so a run can
# neither read nor edit it.
EVAL_TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

probe() { # probe <scenario>
  node "$EVAL_TASK_DIR/probe.js" "$1"
}

# Negative scenarios ("a bad file is rejected") pass vacuously when the command
# does not exist at all — an unknown command also exits non-zero. Gate them on
# the happy path so an untouched fixture earns nothing for them.
probe_if_implemented() { # probe_if_implemented <scenario>
  probe import-valid && probe "$1"
}

check 2 "import adds every note in the file"                                probe import-valid
check 3 "[partial failure] an invalid note leaves the store unchanged"       probe_if_implemented atomic-import
check 1 "[partial failure] the error names the offending note"               probe_if_implemented names-offender
check 2 "[data limits] a malformed file is a usage error, not a stack trace" probe_if_implemented malformed-file
check 1 "[data limits] an empty file is valid and changes nothing"           probe_if_implemented empty-array
check 1 "Existing add and list behave as before"                             probe existing-intact

check 1 "Tests reference the import command" \
  bash -c 'grep -rqi "import" test/ 2>/dev/null'
check 2 "Project test suite passes" \
  bash -c 'npm test --silent >/dev/null 2>&1'
