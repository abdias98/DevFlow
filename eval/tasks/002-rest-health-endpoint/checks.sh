# Checks for 002-rest-health-endpoint. CWD is the result workspace.
PORT="${EVAL_PORT:-3000}"
SERVE="${EVAL_SERVE:-npm start}"

# Process — reported, but does not gate pass/fail (a bare baseline won't earn it).
check_process 1 "Spec artifact produced"   devflow_artifact spec
check_process 1 "Plan artifact produced"   devflow_artifact plan

# Outcome — start the service, probe /health, tear down.
probe_health() {
  $SERVE >/tmp/eval-serve.log 2>&1 &
  local pid=$!
  local code body ok=1
  for _ in $(seq 1 20); do
    code="$(curl -s -o /tmp/eval-health.body -w '%{http_code}' "http://127.0.0.1:$PORT/health" 2>/dev/null)"
    [[ "$code" == "200" ]] && { ok=0; break; }
    sleep 0.5
  done
  body="$(cat /tmp/eval-health.body 2>/dev/null)"
  kill "$pid" >/dev/null 2>&1
  [[ $ok -eq 0 ]] && echo "$body" | jq -e '.status=="ok"' >/dev/null 2>&1
}

check 5 "GET /health returns 200 with status:ok"  probe_health
check 5 "Project test suite passes"               sh -c 'npm test --silent 2>/dev/null || npm test'
