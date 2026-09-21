# Deferred Backlog

Persistent record of scope-adjacent findings not fixed because they fell outside the Core or Impact Zone of the cycle that found them (rules.md → Scope-Locking — Three Zones). Read by the Brainstormer and Architect at the start of a cycle touching the same area, so what was skipped once doesn't stay skipped forever.

| ID | File | Reason | Severity | Cycle | Date | Status |
|----|------|--------|----------|-------|------|--------|
| D1 | src/config.js | File-sourced host/port/debug values are not validated inside loadConfig (only createServer checks them); the header comment promises the shape. Validate file values with the same parsers in a separate change. Found by review of env-config-overrides. | 🟢 INFO | env-config-overrides | 2026-09-21T04:42:23Z | open |
