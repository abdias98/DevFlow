# Deferred Backlog

Persistent record of scope-adjacent findings not fixed because they fell outside the Core or Impact Zone of the cycle that found them (rules.md → Scope-Locking — Three Zones). Read by the Brainstormer and Architect at the start of a cycle touching the same area, so what was skipped once doesn't stay skipped forever.

| ID | File | Reason | Severity | Cycle | Date | Status |
|----|------|--------|----------|-------|------|--------|
| D1 | src/server.js | Pay/cancel (and the whole service) have no authentication or order-ownership check (security.md §2); needs a user decision and an auth design, out of the requested scope | 🟢 INFO | order-pay-cancel | 2026-09-21T05:13:20Z | open |
| D2 | src/orders.js | payOrder: no idempotency key / unknown-outcome handling / timeout for charge; a real provider could be double-charged on a client retry (integration-consumption.md §1,§3; concurrency.md §5) | 🟢 INFO | order-pay-cancel | 2026-09-21T05:13:20Z | open |
