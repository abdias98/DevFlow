# Checks for 002-rest-health-endpoint. CWD is the result workspace.

# Process — reported, but does not gate pass/fail (a bare baseline won't earn it).
check_process 1 "Spec artifact produced"   devflow_artifact spec
check_process 1 "Plan artifact produced"   devflow_artifact plan

# Outcome — start the service (isolated port, process-group cleanup), probe /health.
probe_health() {
  eval_serve_start "${EVAL_SERVE:-npm start}" / || { eval_serve_stop; return 1; }
  local code body
  code="$(eval_http GET /health)"
  body="$(curl -s --max-time 5 "http://127.0.0.1:$EVAL_PORT/health" 2>/dev/null)"
  eval_serve_stop
  [[ "$code" == "200" ]] && echo "$body" | jq -e '.status=="ok"' >/dev/null 2>&1
}

check 5 "GET /health returns 200 with status:ok"  probe_health
check 5 "Project test suite passes"               bash -c 'npm test --silent 2>/dev/null || npm test'
