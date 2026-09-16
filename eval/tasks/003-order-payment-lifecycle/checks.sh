# shellcheck shell=bash
# (sourced by eval/bin/devflow-eval, not executed directly -- no shebang)
# Checks for 003-order-payment-lifecycle. CWD is the result workspace, which
# must have started as a copy of fixture/ (`devflow-eval init`).
#
# The prompt states only the functional requirement. Most outcome checks below
# probe behaviour that requirement implies but does not spell out — repetition,
# invalid transitions, a declined charge, concurrent requests. They measure
# whether the run DISCOVERED those cases, which is the point of the task.

# Process — reported, never gates.
check_process 1 "Spec or feature plan produced"  devflow_artifact_any spec plan
check_process 1 "Review artifact produced"       devflow_artifact review

# ── Helpers ──────────────────────────────────────────────────────────────────

# api <METHOD> <path> [json-body] -> prints "<status> <compact-json-body>"
api() {
  local method="$1" path="$2" body="${3:-}" out code
  out="$(mktemp)"
  if [[ -n "$body" ]]; then
    code="$(curl -s -o "$out" -w '%{http_code}' --max-time 5 -X "$method" \
      -H 'Content-Type: application/json' -d "$body" "http://127.0.0.1:$EVAL_PORT$path")"
  else
    code="$(curl -s -o "$out" -w '%{http_code}' --max-time 5 -X "$method" \
      "http://127.0.0.1:$EVAL_PORT$path")"
  fi
  printf '%s %s\n' "$code" "$(jq -c . "$out" 2>/dev/null || echo null)"
  rm -f "$out"
}

is_2xx() { [[ "$1" =~ ^2[0-9][0-9]$ ]]; }

# Negative scenarios ("X is rejected") pass vacuously when the route does not
# exist at all — the fixture's catch-all answers 404. Each one first proves the
# operation is implemented by exercising it on a fresh pending order.
implemented() { # implemented pay|cancel
  local id; id="$(new_order 1)"
  is_2xx "$(api POST "/orders/$id/$1" | cut -d' ' -f1)"
}

# new_order <amount> -> prints the new order id
new_order() {
  api POST /orders "{\"amount\":$1}" | cut -d' ' -f2- | jq -r '.id'
}

order_status() { api GET "/orders/$1" | cut -d' ' -f2- | jq -r '.status'; }

charges_for() { api GET /ledger | cut -d' ' -f2- | jq --arg id "$1" '[.[] | select(.orderId == $id)] | length'; }

# ── Scenarios ────────────────────────────────────────────────────────────────

pay_pending() {
  local id resp; id="$(new_order 300)"
  resp="$(api POST "/orders/$id/pay")"
  is_2xx "${resp%% *}" && [[ "$(order_status "$id")" == "paid" ]] && [[ "$(charges_for "$id")" == 1 ]]
}

cancel_pending() {
  local id resp; id="$(new_order 120)"
  resp="$(api POST "/orders/$id/cancel")"
  is_2xx "${resp%% *}" && [[ "$(order_status "$id")" == "cancelled" ]]
}

unknown_order() {
  implemented pay && implemented cancel || return 1
  local pay cancel
  pay="$(api POST /orders/no-such-order/pay)"; cancel="$(api POST /orders/no-such-order/cancel)"
  [[ "${pay%% *}" == 404 && "${cancel%% *}" == 404 ]]
}

pay_twice() {
  implemented pay || return 1
  local id second; id="$(new_order 410)"
  api POST "/orders/$id/pay" >/dev/null
  second="$(api POST "/orders/$id/pay")"
  ! is_2xx "${second%% *}" && [[ "$(charges_for "$id")" == 1 ]]
}

invalid_transitions() {
  implemented pay && implemented cancel || return 1
  local a b pay_cancelled cancel_paid
  a="$(new_order 50)"; api POST "/orders/$a/cancel" >/dev/null
  pay_cancelled="$(api POST "/orders/$a/pay")"
  b="$(new_order 60)"; api POST "/orders/$b/pay" >/dev/null
  cancel_paid="$(api POST "/orders/$b/cancel")"
  ! is_2xx "${pay_cancelled%% *}" && [[ "$(charges_for "$a")" == 0 && "$(order_status "$a")" == "cancelled" ]] \
    && ! is_2xx "${cancel_paid%% *}" && [[ "$(order_status "$b")" == "paid" ]]
}

declined_charge() {
  # The payments module declines any charge above its provider limit.
  implemented pay || return 1
  local id resp; id="$(new_order 20000)"
  resp="$(api POST "/orders/$id/pay")"
  ! is_2xx "${resp%% *}" && [[ "${resp%% *}" != 000 ]] \
    && [[ "$(order_status "$id")" == "pending" && "$(charges_for "$id")" == 0 ]]
}

declined_then_cancellable() {
  local id resp; id="$(new_order 20001)"
  api POST "/orders/$id/pay" >/dev/null
  resp="$(api POST "/orders/$id/cancel")"
  is_2xx "${resp%% *}"
}

concurrent_pay() {
  local id f1 f2 p1 p2 c1 c2 ok=0
  id="$(new_order 700)"
  f1="$(mktemp)"; f2="$(mktemp)"
  api POST "/orders/$id/pay" >"$f1" & p1=$!
  api POST "/orders/$id/pay" >"$f2" & p2=$!
  # Wait for these two requests only — a bare `wait` would also block on the
  # managed service, which is a background job of this same shell.
  wait "$p1" "$p2"
  c1="$(cut -d' ' -f1 "$f1")"; c2="$(cut -d' ' -f1 "$f2")"
  rm -f "$f1" "$f2"
  is_2xx "$c1" && ok=$((ok + 1)); is_2xx "$c2" && ok=$((ok + 1))
  [[ $ok == 1 && "$(charges_for "$id")" == 1 && "$(order_status "$id")" == "paid" ]]
}

existing_routes_intact() {
  local created id got
  created="$(api POST /orders '{"amount":5}')"
  id="$(cut -d' ' -f2- <<<"$created" | jq -r '.id')"
  got="$(api GET "/orders/$id")"
  [[ "${created%% *}" == 201 && "${got%% *}" == 200 ]] \
    && [[ "$(api POST /orders '{"amount":-1}' | cut -d' ' -f1)" == 400 ]]
}

# ── Outcome ──────────────────────────────────────────────────────────────────

if eval_serve_start "${EVAL_SERVE:-npm start --silent}" /; then
  check 2 "Pays a pending order: 2xx, status paid, one ledger charge"          pay_pending
  check 1 "Cancels a pending order: 2xx, status cancelled"                     cancel_pending
  check 1 "Unknown order: pay and cancel return 404"                           unknown_order
  check 1 "Existing create/read behaviour unchanged"                           existing_routes_intact
  check 2 "[repetition] Paying twice is rejected and charges only once"        pay_twice
  check 2 "[transitions] Cancelled cannot be paid; paid cannot be cancelled"   invalid_transitions
  check 2 "[partial failure] Declined charge leaves order pending, no charge"  declined_charge
  check 1 "[partial failure] Order stays cancellable after a declined charge"  declined_then_cancellable
  check 3 "[concurrency] Two simultaneous payments charge exactly once"        concurrent_pay
else
  check 15 "Service starts and answers HTTP"                                   false
fi
eval_serve_stop

check 1 "Tests reference the new pay/cancel operations" \
  bash -c 'grep -rqE "pay|cancel" test/ 2>/dev/null'
check 2 "Project test suite passes" \
  bash -c 'npm test --silent >/dev/null 2>&1'
