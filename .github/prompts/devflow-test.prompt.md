---
description: "Write failing test cases before implementation (TDD red phase). Covers happy paths, edge cases, and failures. Phase 3 of the DevFlow lifecycle."
agent: agent
---

# DevFlow — Test Phase (TDD)

Run ONLY the Tester phase of the DevFlow lifecycle.

## Instructions

Invoke the `devflow-tester` skill to:

1. Locate and read the plan document (from session memory or `docs/devflow/plans/`)
2. Explore test conventions in the workspace (framework, structure, helpers)
3. Design test cases: happy path, edge cases, failure scenarios
4. Create test files in the workspace
5. Execute tests and verify they **all FAIL** (red phase)
6. Register tests in session memory (`/memories/session/devflow/test-registry.md`)

**Critical:** NEVER write production code — only test files.

Read session memory first if prior context exists (`/memories/session/devflow/`).

## Plan or Feature to Test

${input}
