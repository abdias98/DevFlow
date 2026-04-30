---
description: "Finalization phase — verifies all tests pass and BLOCK findings are resolved, produces clean final summary, explains how to run/test, lists possible improvements, and cleans session memory. Phase 7 of the DevFlow lifecycle. Never executes tests."
agent: workspace
---

# DevFlow — Finalize Phase

Run the Finalizer phase of the DevFlow lifecycle.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-finalizer/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Ask the user to run the full test suite — if any test fails, route to Debugger.
2. Verify all BLOCK review findings are resolved and DoD criteria are met.
3. Collect all artifacts (files changed, tests added, documents created).
4. Generate and save the final summary to `docs/devflow/features/YYYY-MM-DD-{slug}-feature.md`.
5. Ask for user confirmation, then clean session memory.

**NEVER execute tests.** Ask the user to run them and report results.

## Feature or Context

${input}