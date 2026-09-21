# shellcheck shell=bash
# (sourced by eval/bin/devflow-eval, not executed directly -- no shebang)
# Checks for 004-project-panel-tab. CWD is the result workspace, which must have
# started as a copy of fixture/ (`devflow-eval init`).
#
# The prompt asks for a new tab "following the conventions of the Overview tab".
# Most outcome weight sits on behaviour that request implies but does not spell
# out — switching selection, responses arriving out of order, failures after a
# switch. They measure whether the run DISCOVERED those cases.

# Process — reported, never gates.
check_process 1 "Spec or feature plan produced"  devflow_artifact_any spec plan feature
check_process 1 "Review artifact produced"       devflow_artifact review

# probe.js lives next to this file, outside the result workspace, so a run can
# neither read nor edit it.
EVAL_TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

probe() { # probe <scenario>
  node "$EVAL_TASK_DIR/probe.js" "$1"
}

# Negative scenarios pass vacuously if the tab does not exist; gate them on the
# happy path so an untouched fixture earns nothing for them.
probe_if_implemented() { # probe_if_implemented <scenario>
  probe loads-tasks && probe "$1"
}

check 2 "Tasks tab loads the selected project's tasks"                  probe loads-tasks
check 1 "Tasks tab surfaces a failed request as an error state"         probe_if_implemented error-state
check 1 "Existing Overview tab behaviour unchanged"                     probe overview-intact
check 2 "[side effects] A tab loads only while it is the active tab"    probe_if_implemented loads-only-when-active
check 3 "[transitions] Switching project never shows previous tasks"    probe_if_implemented no-stale-data-on-switch
check 3 "[ordering] A late response for an old selection is ignored"    probe_if_implemented out-of-order-responses
check 2 "[partial failure] An error after a switch shows no stale data" probe_if_implemented error-after-switch

check 1 "Tests reference the new Tasks tab" \
  bash -c 'grep -rqiE "tasks" test/ 2>/dev/null'
check 2 "Project test suite passes" \
  bash -c 'npm test --silent >/dev/null 2>&1'
