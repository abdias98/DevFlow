# Review Checklist

## Code Quality
- [ ] Naming conventions followed (consistent with codebase)
- [ ] No dead code or commented-out code
- [ ] Single responsibility — each function/method does one thing
- [ ] DRY — no unnecessary duplication
- [ ] Error handling at system boundaries
- [ ] No hardcoded values that should be constants/config

## Security (OWASP Top 10)
- [ ] No SQL injection (parameterized queries / ORM used correctly)
- [ ] No XSS vectors (output encoding; framework auto-escaping)
- [ ] No sensitive data in logs or error messages
- [ ] Authentication/authorization checks present where needed
- [ ] No hardcoded secrets or credentials
- [ ] Input validation at API/system boundaries

## Architecture Alignment
- [ ] Implementation matches the spec design
- [ ] Data flow matches the defined architecture
- [ ] All spec components are implemented
- [ ] No extra components not in the spec (scope creep)
- [ ] Integration points work as designed

## Plan Compliance
- [ ] All plan steps are completed
- [ ] Code matches the plan's code snippets (or justified improvement)
- [ ] Commit messages follow the plan
- [ ] File map matches (all expected files modified/created)

## Test Coverage
- [ ] All tests pass
- [ ] New code has corresponding tests
- [ ] Edge cases from spec are covered
- [ ] No test gaps for critical paths

## Performance
- [ ] No N+1 queries
- [ ] No unnecessary database calls
- [ ] Caching used where specified
- [ ] No blocking operations on hot paths
- [ ] Performance budget targets from spec met (if defined)

## API Contract *(if backend feature)*
- [ ] HTTP method matches spec contract
- [ ] Route path matches spec contract
- [ ] Request/response body shapes match spec
- [ ] All error status codes handled
- [ ] No undocumented endpoints introduced

## Accessibility *(if UI feature)*

**Web (WCAG 2.1 AA):**
- [ ] Interactive elements have `aria-label` or visible label
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] No keyboard traps
- [ ] Images have `alt` text
- [ ] Color contrast ≥ 4.5:1 for text, 3:1 for large
- [ ] Form inputs have associated `<label>`
- [ ] Error messages announced to screen readers

**Android (Material):**
- [ ] Interactive views have `contentDescription`
- [ ] TalkBack order is logical
- [ ] Touch target ≥ 48dp

## Dependencies
- [ ] No unnecessary packages added
- [ ] No unused imports
- [ ] No packages with known vulnerabilities

## Review Document Template

Save to `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md`:

```markdown
# Code Review: {Feature Title}

**Date:** YYYY-MM-DD
**Reviewer:** DevFlow Reviewer (automated)
**Spec:** `docs/devflow/specs/{file}`
**Plan:** `docs/devflow/plans/{file}`

## Summary
{1-2 sentence overall assessment}

## Findings

### 🔴 BLOCK (must fix)
Include copy-pasteable fix snippets with diff format.

### 🟡 WARN (should fix)
| # | File | Line | Issue | Suggestion |

### 🟢 INFO (optional)
| # | File | Line | Issue | Suggestion |

## Verdict
✅ APPROVED — no blockers | 🔄 CHANGES REQUESTED — {N} blockers
```
