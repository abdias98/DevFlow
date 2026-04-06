---
description: "Systematic debugging with root cause analysis. Reproduces errors, isolates causes, applies fixes, and documents everything. Phase 6 of the DevFlow lifecycle."
agent: devflow
---

# DevFlow — Debug Phase

Run ONLY the Debugger phase of the DevFlow lifecycle.

## Instructions

Invoke the `devflow-debugger` skill to:

1. Identify the failure (test failure, build error, runtime error, reviewer finding)
2. Reproduce the error with verbose output
3. Isolate the root cause systematically — NEVER guess
4. Explain WHY the error occurred (causal chain)
5. Apply the minimal fix
6. Re-run tests to verify the fix
7. Save debug log to `docs/devflow/debug-logs/YYYY-MM-DD-{slug}-debug.md`
8. Route to appropriate next phase (Implementer to continue, or Architect if design flaw)

Max 3 fix attempts before escalating to user.

Read session memory first (`/memories/session/devflow/`).

## Error or Failing Test

${input}
