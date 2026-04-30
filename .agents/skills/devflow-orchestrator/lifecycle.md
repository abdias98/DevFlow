# Lifecycle Phase Details

This document provides a quick reference for the DevFlow lifecycle phases. For the complete step‑by‑step procedures, refer to each agent's `SKILL.md`.

## Phase Flow

```
Phase 1: Brainstormer → Phase 2: Architect → Phase 3: Planner → ⏸️ Confirmation Gate → Phase 4: Implementer → Phase 5: Reviewer → Phase 6: Debugger (conditional) → Phase 7: Finalizer
```

---

## Phase Summary

| Phase | Agent | Input | Output | Key Rule |
|-------|-------|-------|--------|----------|
| 1 | Brainstormer | User request | `context.md` (session memory) | NEVER write code or design |
| 2 | Architect | `context.md`, codebase | Spec at `docs/devflow/specs/` | Explore before designing |
| 3 | Planner | Spec, codebase | Plan at `docs/devflow/plans/` + mockups (UI) | Stack Mode gate (conditional) |
| ⏸️ | **Confirmation Gate** | Plan + mockups | User approval | NEVER proceed without explicit approval |
| 4 | Implementer | Plan | Code + tests (committed) | Red→Green TDD per task |
| 5 | Reviewer | Diff, spec, plan | Review at `docs/devflow/reviews/` | BLOCK findings → back to Phase 4 |
| 6 | Debugger | Test failures, review findings | Debug log at `docs/devflow/debug-logs/` | Only if tests fail or runtime errors |
| 7 | Finalizer | All artifacts, session memory | Final summary, cleanup | Verify no regressions, clean session |

---

## Confirmation Gate

After Phase 3 (Planner), the Orchestrator MUST:

1. Present the plan summary and mockup paths.
2. If multiple mockups exist → ask the user to select one.
3. Ask for explicit approval.

| header | question | type |
|--------|----------|------|
| `plan_confirmation` | Plan + Test Cases + Mockups complete. Review the plan — proceed to Implementation? | options: ✅ Yes, ✏️ Request changes, ❌ Cancel |

**Do NOT proceed to Phase 4 until the user approves.**

---

## Iteration Rules

```
Tests FAIL after implementation  → Phase 6 (Debugger) → Phase 4 (retry)
Reviewer finds BLOCK issues      → Phase 4 (fix findings)
Architecture flaw discovered     → Phase 2 (redesign)
Plan incomplete or ambiguous     → Phase 3 (revise)
Finalizer finds failing tests    → Phase 6 (Debugger)
```

- Maximum **3 iteration loops** per phase before escalating to the user.
- NEVER proceed past the Confirmation Gate without explicit user approval.

---

## Standalone Agents

The following agents operate **independently** of the Phase 1–7 lifecycle. They are invoked directly by the user.

| Agent | Command | Use Case |
|-------|---------|----------|
| Refactorer | `devflow-refactor` | Improve code structure/readability without changing behavior |
| Bug-Fixer | `devflow-bug-fix` | Fix a reported bug with reproduction test |
| Feature Agent | `devflow-feature` | Implement a small-medium feature without full planning overhead |
| Reviewer | `devflow-review` | Review existing code against standards |
| Debugger | `devflow-debug` | Diagnose and fix issues (standalone) |

### Standalone vs Full Lifecycle

| Criterion | Standalone Agent | Full `/devflow` Lifecycle |
|-----------|-----------------|--------------------------|
| Scope | Narrow and known | Broad or exploratory |
| Files affected | ≤5 (Refactorer, Bug-Fixer, Feature) | Any |
| Architectural impact | None / minimal | Any |
| Requires spec/plan | No (mini-plan for Feature) | Yes |
| User approval | Before applying changes | At Confirmation Gate |

---

## Stack Mode Awareness

When the Planner sets `Stack Mode: yes`, the lifecycle adapts. See `stack-mode.md` for details.
