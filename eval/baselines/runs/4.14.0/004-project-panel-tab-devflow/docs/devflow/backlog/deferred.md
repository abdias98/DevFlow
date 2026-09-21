# Deferred Backlog

Persistent record of scope-adjacent findings not fixed because they fell outside the Core or Impact Zone of the cycle that found them (rules.md → Scope-Locking — Three Zones). Read by the Brainstormer and Architect at the start of a cycle touching the same area, so what was skipped once doesn't stay skipped forever.

| ID | File | Reason | Severity | Cycle | Date | Status |
|----|------|--------|----------|-------|------|--------|
| D1 | src/panel.js | loadOverview has no superseded-result guard: select p1 then p2 with Overview active, p1 resolves last -> p1 data shown under p2 (state-lifecycle.md section 6). Pre-existing, outside the Tasks request. | 🟢 INFO | unknown | 2026-09-21T05:02:34Z | open |
