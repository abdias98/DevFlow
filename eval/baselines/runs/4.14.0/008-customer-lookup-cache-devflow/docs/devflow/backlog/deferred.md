# Deferred Backlog

Persistent record of scope-adjacent findings not fixed because they fell outside the Core or Impact Zone of the cycle that found them (rules.md → Scope-Locking — Three Zones). Read by the Brainstormer and Architect at the start of a cycle touching the same area, so what was skipped once doesn't stay skipped forever.

| ID | File | Reason | Severity | Cycle | Date | Status |
|----|------|--------|----------|-------|------|--------|
| D1 | src/customers.js | customer cache has no TTL and only this service instance invalidates it: out-of-band writes (other process, second service instance over the same store) stay invisible until restart; add a TTL or event-driven invalidation if other writers exist (performance.md section 3, state-lifecycle.md section 3) | 🟢 INFO | customer-cache | 2026-09-21T04:45:09Z | open |
