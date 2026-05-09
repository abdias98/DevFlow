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

---

## UI-Specific Checks *(apply only if Feature Type is UI/frontend)*

- [ ] Interactive elements are keyboard-navigable and have accessibility labels.
- [ ] Color contrast meets WCAG AA (4.5:1 for text).
- [ ] No keyboard traps.
- [ ] Components are self-contained and reusable. 🔴 **BLOCK** if a modal/dialog/overlay is inlined inside the component that triggers it.
- [ ] No hardcoded visual values — design tokens used for spacing, colors, typography.
- [ ] Layout uses relative units, not fixed pixels.

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

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Suggestion |

### 🟡 WARN (should fix)
| # | File | Line | Issue | Suggestion |

### 🟢 INFO (optional)
| # | File | Line | Issue | Suggestion |

## Verdict
✅ APPROVED — no blockers | 🔄 CHANGES REQUESTED — {N} blockers
```