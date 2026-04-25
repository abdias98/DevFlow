---
description: "Write minimal production code to make failing tests pass, following the plan step-by-step. Auto-invokes Reviewer when done. Phase 4 of the DevFlow lifecycle."
agent: workspace
---

# DevFlow — Implement Phase

Run ONLY the Implementer phase of the DevFlow lifecycle.

## 🧩 Active Instructions

To perform this task, you MUST first read and follow the full instructions in your skill file:

1. **Read Skill:** `{{SKILLS_DIR}}/devflow-implementer/SKILL.md`
2. **Follow Procedure:** Red-Green-Refactor → Mini-Review → Commit

## Summary of Workflow (Ref: SKILL.md)

1. Load context from session memory (plan path, test registry, phase state)
2. Read the plan document
3. Execute each step in order: modify/create files as specified
4. Run the associated failing tests and verify your changes make them PASS
5. Commit at each task checkpoint with the pre-written message
6. After ALL steps complete, **auto-invoke devflow-review**

**Critical:** Write MINIMAL code to pass tests. Do NOT add features, refactor, or "improve" beyond the plan.

Read session memory first (`/memories/session/devflow/`).

## Plan or Task to Implement

${input}
