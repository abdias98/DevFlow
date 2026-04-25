---
description: "Manually trigger the red phase of a specific task: create the failing test from the plan and verify it FAILs. Use only when resuming mid-implementation or debugging a specific test."
agent: workspace
---

# DevFlow — Test Phase (Red Phase Only)

> ⚠️ Normally the red→green cycle runs automatically inside the Implementer. Use this prompt only to manually create and verify a failing test for a specific task.

## 🧩 Active Instructions

To perform this task, you MUST first read and follow the full instructions in your skill file:

1. **Read Skill:** `{{SKILLS_DIR}}/devflow-tester/SKILL.md`
2. **Follow Procedure:** Load Plan → Create Failing Test → Instruct User

## Instructions

1. Read the plan from `docs/devflow/plans/` or session memory
2. Locate the task's `🧪 Tests for this Task` section
3. Copy the complete test code exactly as written in the plan — do NOT redesign it
4. Create the test file using `create_file` or add to existing with `replace_string_in_file`
5. Run the exact command from the plan's test section and verify the test **FAILs**
6. Register the test in `/memories/session/devflow/test-registry.md` (status: FAIL)

**Critical:** NEVER write production code here — only the test file.

## Task to Test

${input}
