# Review Checklist

This checklist guides the Reviewer in both Cycle Mode and Standalone Mode. Apply the relevant sections based on the feature type (UI, API, backend, etc.) and the standards loaded.

## Universal Checks (All Reviews)

### Code Quality
- [ ] Naming conventions followed (consistent with codebase).
- [ ] No dead code or commented-out code.
- [ ] Single responsibility — each function/method/component does one thing. 🔴 **BLOCK** if a component mixes rendering, business logic, and state management inline.
- [ ] No unnecessary duplication (DRY).
- [ ] Error handling present at system boundaries.
- [ ] No hardcoded values that should be constants or design tokens.

### Security (OWASP Top 10)
- [ ] No injection vectors (parameterized queries, output encoding).
- [ ] No sensitive data in logs or error messages.
- [ ] Authentication/authorization checks present where required. 🔴 **BLOCK** if missing.
- [ ] No hardcoded secrets or credentials. 🔴 **BLOCK** if found.
- [ ] Input validation at system boundaries. 🔴 **BLOCK** if missing.

### Architecture Alignment
- [ ] Implementation matches the spec/plan design.
- [ ] Data flow matches the defined architecture.
- [ ] No extra components not in the spec/plan (scope creep).
- [ ] Dependencies point inward (Clean Architecture). 🔴 **BLOCK** if domain code imports infrastructure.

### Performance
- [ ] No N+1 queries. 🔴 **BLOCK** if introduced.
- [ ] No unnecessary database calls or blocking operations on hot paths.
- [ ] No missing memoization or lazy loading where the plan requires it.

### Test Coverage
- [ ] All tasks have corresponding tests.
- [ ] Edge cases from spec/plan are covered.
- [ ] No test gaps for critical paths.

### Correctness & Behavior
Performed by subagent 4 following [correctness-guide.md](./correctness-guide.md) — blind pass (no spec/plan), then contrast pass. Findings are scenario-backed and classified with `rules.md` → Behavioral Impact Severity.
- [ ] Every changed unit's inputs, state, side effects, outputs and **consumers** were inventoried — consumers read, not assumed.
- [ ] Logic: conditions, boundaries, unhandled cases, masking defaults.
- [ ] State transitions: behavior under changed input/context with work in flight, repetition, reordering; derived state reset or recomputed when its source changes.
- [ ] Side effects: performed exactly as many times as intended; no work whose result nothing consumes; everything started is released.
- [ ] Contract with consumers: shape, nullability, ordering, error type and timing each consumer relies on still hold.
- [ ] Data limits and partial failure: what the inputs can actually produce, and what is left behind when a step fails halfway.
- [ ] Test adequacy: no plausible single mutation on a behavior-relevant path survives every test (`testing.md §4`).
- [ ] Each finding classified as implementation defect, plan gap or deliberate decision; untraceable suspicions listed as Open Questions, not findings.

### Error Handling
- [ ] No empty catch blocks or catch-and-continue that discards the error. 🔴 **BLOCK** if found (`error-handling.md §2`).
- [ ] Caught errors are narrowly typed and the original cause is chained when wrapped/translated (`error-handling.md §3`).
- [ ] No raw stack trace, exception message, or internal detail returned to an external caller. 🔴 **BLOCK** if found (`error-handling.md §5`).
- [ ] Resources are released and multi-step state changes are atomic on every failure path (`error-handling.md §6`).

### Concurrency *(apply only if concurrent/async code is present)*
- [ ] No non-atomic check-then-act / read-modify-write on shared state. 🔴 **BLOCK** if found (`concurrency.md §2`).
- [ ] No fire-and-forget async task where failure means data loss. 🔴 **BLOCK** if found (`concurrency.md §4`).
- [ ] Locks are held for the shortest critical section and always released (`concurrency.md §3`).
- [ ] Operations that may be retried or redelivered are idempotent (`concurrency.md §5`).

### Logging *(apply only if the change emits logs/traces/metrics)*
- [ ] No secret, credential, token, or PII written to a log at any level. 🔴 **BLOCK** if found (`logging.md §3`).
- [ ] No exception caught and silently swallowed — neither logged nor rethrown. 🔴 **BLOCK** if found (`logging.md §6`).
- [ ] Logs are structured (named fields), not string-concatenated messages (`logging.md §1`).

### Dependencies *(apply only if manifests/lockfiles changed)*
- [ ] No known critical/high vulnerability introduced with no documented mitigation. 🔴 **BLOCK** if found (`dependencies.md §3`).
- [ ] Lockfile is committed and consistent with the manifest (`dependencies.md §2`).
- [ ] No dependency installed from an untrusted source or with integrity verification disabled (`dependencies.md §4`).

---

## UI-Specific Checks *(apply only if Feature Type is UI/frontend)*

- [ ] Interactive elements are keyboard-navigable and have accessibility labels.
- [ ] Color contrast meets WCAG AA (4.5:1 for text).
- [ ] No keyboard traps.
- [ ] Components are self-contained and reusable. 🔴 **BLOCK** if a modal/dialog/overlay is inlined inside the component that triggers it.
- [ ] No hardcoded visual values — design tokens used for spacing, colors, typography.
- [ ] Layout uses relative units, not fixed pixels.

### Accessibility
- [ ] Every interactive element is reachable and operable by keyboard, with no keyboard trap. 🔴 **BLOCK** if found (`accessibility.md §3`).
- [ ] `aria-hidden="true"` is never present on a focusable element. 🔴 **BLOCK** if found (`accessibility.md §5`).
- [ ] Every control has an accessible name; native semantic elements are used before ARIA (`accessibility.md §5`).
- [ ] Every form input has a programmatic label; errors are identified in text, not color alone (`accessibility.md §6`).

---

## API-Specific Checks *(apply only if Feature Type is backend/API)*

- [ ] HTTP method matches spec contract.
- [ ] Route path matches spec contract.
- [ ] Request/response body shapes match spec.
- [ ] Appropriate status codes used (not 200 for errors).
- [ ] No undocumented endpoints introduced.

---

## Review Document Template

Save to `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md`:

```markdown
# Code Review: {Feature Title}

**Date:** YYYY-MM-DD
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** {Cycle | Standalone}
**Invoking Agent:** {Implementer | Feature Agent | Refactorer | Bug-Fixer}
**Reference:** `docs/devflow/{specs|plans|features|refactors|bug-fixes}/{file}`

## Summary
{1-2 sentence overall assessment}

## Findings

> **Evidence** is `{standard}.md §{N}` or `scenario: {precondition} → {sequence} → observed {X}, expected {Y} per {source}` — see rules.md → Finding Evidence.

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Evidence | Suggestion |

### 🟡 WARN (should fix)
| # | File | Line | Issue | Evidence | Suggestion |

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |

### ❓ Open Questions *(optional — not findings, never affect the verdict)*
- {file:line} — {what would have to be true for this to be a defect; what to check}

## Verdict
✅ APPROVED — no blockers | 🔄 CHANGES REQUESTED — {N} blockers
```