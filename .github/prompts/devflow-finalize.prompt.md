---
description: "Finalization phase — verify all tests pass, produce clean final summary, explain how to run/test, list possible improvements, and clean session memory. Phase 7 of the DevFlow lifecycle."
agent: workspace
---

# DevFlow — Finalize Phase

Run ONLY the Finalizer phase of the DevFlow lifecycle.

## Instructions

Invoke the `devflow-finalize` skill to:

1. Run the full test suite — STOP and route to Debugger if any test fails
2. Check the review document — STOP and route to Implementer if BLOCK findings remain
3. Collect all files created/modified during this cycle
4. Generate the final clean solution summary
5. Provide "How to Run / Test" instructions (exact commands)
6. List possible future improvements
7. Clean session memory (`/memories/session/devflow/`)

Read session memory first (`/memories/session/devflow/`) for full cycle context.

## Feature or Context

${input}
