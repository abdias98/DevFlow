# shellcheck shell=bash
# (sourced by eval/bin/devflow-eval, not executed directly -- no shebang)
# Checks for 006-config-env-overrides. CWD is the result workspace, which must
# have started as a copy of fixture/ (`devflow-eval init`).
#
# The prompt asks for environment overrides. Most outcome weight sits on what
# the loader's CONSUMER needs: environment values arrive as strings, while the
# server setup demands a number and a boolean. They measure whether the run
# DISCOVERED the contract the change had to keep.

# Process — reported, never gates.
check_process 1 "Spec or feature plan produced"  devflow_artifact_any spec plan
check_process 1 "Review artifact produced"       devflow_artifact review

# probe.js lives next to this file, outside the result workspace, so a run can
# neither read nor edit it.
EVAL_TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

probe() { # probe <scenario>
  node "$EVAL_TASK_DIR/probe.js" "$1"
}

# Negative scenarios ("an invalid port is rejected") pass vacuously when no
# override exists at all. Gate them on the happy path.
probe_if_implemented() { # probe_if_implemented <scenario>
  probe host-override && probe "$1"
}

check 1 "File values still apply when no variable is set"                    probe file-values
check 2 "HOST overrides the host in the file"                                probe host-override
check 2 "[caller contract] PORT override is a number the server accepts"     probe_if_implemented port-override
check 1 "DEBUG=true turns verbose logging on"                                probe_if_implemented debug-true
check 3 "[caller contract] DEBUG=false turns it off (a real boolean)"        probe_if_implemented debug-false
check 2 "[data limits] A PORT that is not a number is rejected"              probe_if_implemented invalid-port

check 1 "Tests reference the environment overrides" \
  bash -c 'grep -rqE "PORT|HOST|DEBUG" test/ 2>/dev/null'
check 2 "Project test suite passes" \
  bash -c 'npm test --silent >/dev/null 2>&1'
