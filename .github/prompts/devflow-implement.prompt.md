---
description: "Write minimal production code to make failing tests pass, following the plan step-by-step. Never executes tests — informs the user with the exact command. Auto-invokes Reviewer when done. Phase 4 of the DevFlow lifecycle."
agent: workspace
---

# DevFlow — Implement Phase

Run the Implementer phase of the DevFlow lifecycle.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-implement/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Load context from session memory (plan path, Stack Mode, test registry).
2. For each task in the plan: Red Phase (create test file, inform user) → Green Phase (write production code, inform user).
3. **NEVER run tests.** Provide the exact command and let the user execute it.
4. Commit at each task checkpoint with the pre-written message.
5. After ALL tasks complete, auto-invoke the Reviewer.

**Critical:** Write MINIMAL code to pass tests. Do NOT add features, refactor, or "improve" beyond the plan.

## Plan or Task to Implement

${input}