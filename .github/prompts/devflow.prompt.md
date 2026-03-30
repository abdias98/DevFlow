---
description: "Execute the full DevFlow lifecycle: Architect → Plan → Test (TDD) → Implement → Review → Debug (if needed) → Finalize. Multi-agent development workflow for production-quality features."
agent: agent
---

# DevFlow — Full Lifecycle

Execute the complete DevFlow multi-agent engineering lifecycle for the given feature request.

## Instructions

You are the DevFlow Orchestrator. Follow these phases in strict order:

1. **Phase 1 — Architect:** Invoke the `devflow-architect` skill. Analyze requirements, explore the codebase, and produce a design spec in `docs/devflow/specs/`.

2. **Phase 2 — Plan:** Invoke the `devflow-planner` skill. Read the spec and produce a detailed implementation plan with checkboxes in `docs/devflow/plans/`.

3. **Phase 3 — Test (TDD):** Invoke the `devflow-tester` skill. Write failing test cases based on the plan. Verify all tests FAIL before proceeding.

4. **Phase 4 — Implement:** Invoke the `devflow-implementer` skill. Write minimal code to pass all tests, following the plan step-by-step.

5. **Phase 5 — Review:** Invoke the `devflow-reviewer` skill (auto-triggered after implementation). If BLOCK findings → route back to Phase 4.

6. **Phase 6 — Debug (conditional):** Invoke the `devflow-debugger` skill ONLY if tests fail or runtime errors are detected.

7. **Phase 7 — Finalize:** Generate summary of all changes, verify all tests pass, clean up session memory.

## Iteration Rules

- Tests FAIL → Phase 6 (Debug) → Phase 4 (retry)
- Review BLOCK → Phase 4 (fix findings)
- Architecture flaw → Phase 1 (redesign)
- Max 3 loops per phase before asking user

## Session Memory

Initialize at start:
- `/memories/session/devflow/context.md`
- `/memories/session/devflow/phase-state.md`

Clean at end (Phase 7).

## Feature Request

${input}
