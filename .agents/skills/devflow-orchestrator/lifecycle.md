# Lifecycle Phase Details

## PHASE 1: BRAINSTORMER (`devflow-brainstormer`)

1. Read user's request carefully
2. Ask clarifying questions (Feature Type, scope, constraints, Definition of Done)
3. Identify: Goal, Constraints, Edge Cases, Assumptions
4. Restate the problem in your own words
5. **Output:** Problem Statement saved to session memory
6. **Restriction:** NEVER write code, design, or architecture
7. **Auto-trigger:** Invoke `devflow-architect` when understanding is complete

## PHASE 2: ARCHITECT (`devflow-architect`)

1. Read Problem Statement from session memory
2. Check for `AGENTS.md` — if present, skip general exploration
3. Check repo memory for known pitfalls and project knowledge
4. Full codebase exploration (if no AGENTS.md)
5. Define architecture: components, data structures, interfaces, data flow
6. **Output:** Spec document saved to `docs/devflow/specs/`
7. **Update memory:** Save tech stack and architecture decisions

## PHASE 3: PLANNING (`devflow-planner`)

1. Read the spec from Phase 2
2. Ask Stack Mode question (FIRST ACTION — STOP and wait)
3. Explore the codebase — including test framework, conventions, run commands
4. **Generate HTML mockup(s)** for UI features — save with `create_file` + show inline
5. Break down into atomic, ordered tasks with complete code snippets + test code
6. **Output:** Plan saved to `docs/devflow/plans/` using `create_file`

## ⏸️ CONFIRMATION GATE — After Phase 3

After Planning completes, you MUST ask for confirmation:

| header | question | type |
|--------|----------|------|
| `plan_confirmation` | Plan + Test Cases + Mockups complete. Review the plan — proceed to Implementation? | options: ✅ Yes, start Implementation, ✏️ Request changes, ❌ Cancel |

If multiple mockups were generated, include mockup selection:

| header | question | type |
|--------|----------|------|
| `mockup_selection` | Multiple mockup proposals generated. Which one to use? | options: {list each mockup file} |

- **✅ Yes** → Invoke `devflow-implementer`
- **✏️ Request changes** → Revise plan, re-ask
- **❌ Cancel** → Stop

**Do NOT invoke Implementer or write code until user confirms.**

## PHASE 4: IMPLEMENTER (`devflow-implementer`)

For each task: **🔴 Red** (create failing test) → **🟢 Green** (write minimal code to pass).
1. Follow the plan strictly — no speculative refactoring
2. Commit after each task
3. **Auto-trigger:** Invoke `devflow-reviewer` after completing implementation

## PHASE 5: REVIEWER (`devflow-reviewer`)

1. Read the diff of implemented code
2. Compare against spec and plan
3. Check: code quality, security (OWASP), performance, test coverage
4. Classify: 🔴 BLOCK / 🟡 WARN / 🟢 INFO
5. **Output:** Review saved to `docs/devflow/reviews/`
6. **If BLOCK findings** → Route back to PHASE 4

## PHASE 6: DEBUGGER (`devflow-debugger`) — Conditional

Only if tests fail or reviewer detects runtime issues.
1. Reproduce → Isolate → Explain → Fix → Verify
2. **Output:** Debug log saved to `docs/devflow/debug-logs/`

## PHASE 7: FINALIZER (`devflow-finalizer`)

1. Run full test suite — route to Debugger if failures
2. Verify all BLOCK findings are resolved
3. Generate final summary: files changed, tests added, improvements
4. Clean session memory

## Iteration Rules

```
Tests FAIL after implementation  → PHASE 6 (Debugger) → PHASE 4 (retry)
Reviewer finds BLOCK issues      → PHASE 4 (fix findings)
Architecture flaw discovered     → PHASE 2 (redesign)
Plan incomplete or ambiguous     → PHASE 3 (revise)
Finalizer finds failing tests    → PHASE 6 (Debugger)
NEVER proceed past Confirmation Gate without explicit user approval
Maximum 3 iteration loops per phase before escalating to user
```
