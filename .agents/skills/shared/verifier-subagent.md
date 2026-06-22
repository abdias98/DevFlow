# Verifier Subagent — Canonical Pattern

> **Framework-centric principle:** verification before review is a fresh-context sanity check, not a deep quality analysis. The verifier catches low-hanging fruit (missing files, scope drift, plan deviations) so the Reviewer can spend its budget on deeper analysis. The verifier does NOT replace the Reviewer — it precedes it.

This document defines the canonical pattern for dispatching a verifier subagent between implementation and review. The Implementer (Phase 5) references this file and dispatches a verifier when the implementation is non-trivial.

---

## When to Dispatch a Verifier

**Dispatch a verifier when ANY of these hold:**
- The plan has **3 or more tasks** — enough surface area that something is likely missed.
- The implementation **modified more than 2 files** — cross-file consistency needs a fresh look.
- The plan included **inter-task dependencies** — verify the dependency chain was respected.
- The implementation **deviated from the plan** (even with justification) — verify the deviation is safe.

**Skip the verifier when ALL of these hold:**
- The plan has **1-2 tasks** and modified ≤ 2 files.
- No deviations from the plan.
- The implementation is mechanical (e.g., a single utility function with a test).

In the skip case, the Implementer goes directly to the Reviewer (Step 5 in the Implementer procedure).

---

## The Pattern

### 1. Compose the verifier brief

The verifier is a **fresh-context** subagent. It does NOT inherit the Implementer's working context — it reads the spec, plan, and modified files from scratch. This eliminates confirmation bias (the Implementer's "I just wrote this, it must be right" blind spot).

| Field | Content |
|-------|---------|
| **Goal** | Verify the implementation matches the plan structurally and stays in scope, before formal review. |
| **Context** | The plan document, the spec document (if architecture-relevant), the list of modified files, and `devflow-ctl scope list` output. **No access to the Implementer's reasoning or intermediate state.** |
| **Constraints** | Read-only. Do NOT run tests (test execution is the user's responsibility in Pair mode, or auto-run in Standard mode). Do NOT edit files. Do NOT do deep quality/security analysis — that is the Reviewer's job. |
| **Output format** | A findings list (see below). |

### 2. Verification axes

The verifier checks four axes, in order:

1. **Structural completeness**
   - Do all files in the plan's File Map (Create + Modify lists) exist?
   - Are all tasks in the plan checked off?
   - Do the test files referenced in the plan exist?

2. **Scope compliance**
   - Run `devflow-ctl scope check {file}` for each modified file.
   - Flag any file modified outside the declared scope (BLOCK).

3. **Plan compliance**
   - For each task in the plan, does the implementation include the stated deliverables?
   - Are there missing pieces (functions, types, config entries) that the plan required?
   - Were any plan-specified patterns or standards not applied?

4. **Obvious issues** (static, no test execution)
   - Syntax errors visible in the diff (unbalanced braces, missing imports referenced in the same file).
   - Files referenced in code that don't exist (broken imports).
   - TODO/FIXME markers left in production code (WARN).

### 3. Output format

The verifier reports back with a findings list:

```markdown
## Verifier Findings

**Verdict:** PASS | PASS_WITH_WARNINGS | FAIL

### Findings

| # | Severity | Axis | File | Finding |
|---|----------|------|------|---------|
| 1 | BLOCK | Scope | src/foo.ts | Modified outside declared scope. |
| 2 | WARN | Plan | src/bar.ts | Missing JSDoc for exported function `baz()`. |
| 3 | INFO | Structural | — | All 8 plan tasks checked off. |

### Summary
{One-sentence summary: what passed, what needs attention.}
```

**Severity scale:**
- **BLOCK** — the implementation is broken or violates scope. The Implementer MUST fix before invoking the Reviewer.
- **WARN** — a non-blocking issue the Reviewer should examine. The Implementer notes it and proceeds to Reviewer.
- **INFO** — observation for the Reviewer's awareness. No action needed from the Implementer.

### 4. Implementer's response to findings

- **Any BLOCK:** the Implementer fixes the issue(s), re-dispatches the verifier (fresh context again) to confirm the fix, then proceeds to Reviewer. If a BLOCK cannot be fixed without plan amendment, the Implementer stops and asks the user.
- **Only WARN/INFO:** the Implementer notes them in `### Additional Recommendations` for the Reviewer, then proceeds to Reviewer.
- **PASS:** the Implementer proceeds directly to Reviewer.

---

## Fallback: Sequential Execution

If the editor does not support subagent invocation, the Implementer performs the verification **inline** with a deliberate context reset:

1. Set aside the implementation reasoning.
2. Re-read the plan's File Map and task list.
3. Walk through the four verification axes against the actual files on disk.
4. Produce the findings list.

The inline fallback is identical in substance — the key is the **context reset**, not the dispatch mechanism. The verifier's value comes from looking at the implementation with fresh eyes, not from being a separate process.

---

## Anti-Patterns

- ❌ **Verifier inherits Implementer context** — confirmation bias defeats the purpose. The verifier MUST have fresh context (or a deliberate inline reset).
- ❌ **Verifier runs tests** — test execution is the user's responsibility (Pair mode) or auto-run (Standard mode). The verifier is static analysis only.
- ❌ **Verifier does deep quality review** — that is the Reviewer's job. The verifier catches structural/scope/plan-compliance issues, not SOLID violations or security vulnerabilities.
- ❌ **Skip the verifier for non-trivial implementations** — the Reviewer's budget is better spent on deeper analysis when low-hanging fruit is already caught.
- ❌ **Dispatch a verifier for trivial implementations** — the dispatch overhead exceeds the benefit. Use the skip criteria above.

---

## Relationship to the Reviewer

The verifier and the Reviewer are complementary, not redundant:

| Aspect | Verifier | Reviewer |
|--------|----------|----------|
| **When** | After implementation, before review | After verifier passes |
| **Context** | Fresh (no Implementer bias) | Fresh (reads spec/plan/code) |
| **Depth** | Structural, scope, plan compliance | Quality, security, performance, standards |
| **Output** | Findings list (BLOCK/WARN/INFO) | Review verdict (BLOCK/WARN/INFO) |
| **Action on BLOCK** | Implementer fixes, re-verifies | Routes back to Implementer via Debugger |

The verifier's WARN/INFO findings are forwarded to the Reviewer as inputs, so the Reviewer doesn't re-discover them.

---

## Agents That Apply This Pattern

| Agent | Application |
|-------|-------------|
| **Implementer** (Phase 5) | Dispatches a verifier subagent after all tasks complete, before invoking the Reviewer. |

See the Implementer's `SKILL.md` for the exact step in the procedure.
