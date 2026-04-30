---
description: "Manually trigger the red phase of a specific task: create the failing test from the plan. Use only when resuming mid-implementation or debugging a specific test. Never executes tests."
agent: workspace
---

# DevFlow — Test Phase (Red Phase Only)

> Normally the Red→Green cycle runs inside the Implementer. Use this prompt only to manually create a failing test for a specific task.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-tester/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Read the plan and locate the task's `🧪 Tests for this Task` section.
2. Create the test file exactly as written in the plan.
3. Inform the user of the exact command to run the test — **do NOT run it**.
4. Register the test in session memory.

**Critical:** NEVER write production code. NEVER run tests. This is a helper for creating test files only.

## Task to Test

${input}