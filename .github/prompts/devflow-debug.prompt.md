---
description: "Systematic debugging with root cause analysis. Reproduces errors, isolates causes, applies fixes, and documents everything. Never executes tests — asks the user to run them. Phase 6 of the DevFlow lifecycle."
agent: workspace
---

# DevFlow — Debug Phase

Run the Debugger phase of the DevFlow lifecycle.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-debug/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Identify the failure from session memory or user input.
2. Ask the user to reproduce the error and provide the full output.
3. Isolate the root cause systematically — NEVER guess.
4. Apply the minimal fix and ask the user to verify.
5. Save the debug log to `docs/devflow/debug-logs/YYYY-MM-DD-{slug}-debug.md`.
6. If invoked as part of the full lifecycle, route back to the Orchestrator. If invoked standalone, present the debug log and STOP.

**NEVER execute tests.** Provide the exact command and let the user run it.

Max 3 fix attempts before escalating to the user.

## Error or Failing Test

${input}