# shellcheck shell=bash
# (sourced by eval/bin/devflow-eval, not executed directly -- no shebang)
# Checks for 008-customer-lookup-cache. CWD is the result workspace, which must
# have started as a copy of fixture/ (`devflow-eval init`).
#
# The prompt asks for caching. Most outcome weight sits on what a cache implies
# but the prompt does not spell out: it serves stale data unless changes
# invalidate it, it must be keyed by everything the answer depends on, and a
# failure must not be remembered. They measure whether the run DISCOVERED those.

# Process — reported, never gates.
check_process 1 "Spec or feature plan produced"  devflow_artifact_any spec plan
check_process 1 "Review artifact produced"       devflow_artifact review

# probe.js lives next to this file, outside the result workspace, so a run can
# neither read nor edit it.
EVAL_TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

probe() { # probe <scenario>
  node "$EVAL_TASK_DIR/probe.js" "$1"
}

# "A change is visible" and "a failure is not cached" both hold trivially when
# nothing is cached at all. Gate them on the cache existing, so an untouched
# fixture earns nothing for them.
probe_if_cached() { # probe_if_cached <scenario>
  probe cache-hit && probe "$1"
}

check 2 "[side effects] A repeated lookup does not hit the store again"      probe cache-hit
check 3 "[state transitions] An update is visible to the next lookup"        probe_if_cached update-invalidates
check 1 "[state transitions] Archiving is visible to the next lookup"        probe_if_cached archive-invalidates
check 3 "[state transitions] Lookups with different options never share a result" probe_if_cached options-are-part-of-the-key
check 2 "[partial failure] A failed read is not remembered"                  probe_if_cached failure-not-cached
check 1 "Existing lookup behaviour is unchanged"                             probe existing-intact

check 1 "Tests reference the cache" \
  bash -c 'grep -rqiE "cache|finds|hit" test/ 2>/dev/null'
check 2 "Project test suite passes" \
  bash -c 'npm test --silent >/dev/null 2>&1'
