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
**Review Mode:** {Cycle | Standalone}
**Invoking Agent:** {Implementer | Feature Agent | Refactorer | Bug-Fixer}
**Reference:** `docs/devflow/{specs|plans|features|refactors|bug-fixes}/{file}`

## Summary
{1-2 sentence overall assessment}

## Findings

### 🔴 BLOCK (must fix)
Include concrete, actionable fix guidance (affected file/line, required change, and rationale), but do not provide full patch/diff snippets.

### 🟡 WARN (should fix)
| # | File | Line | Issue | Suggestion |

### 🟢 INFO (optional)
| # | File | Line | Issue | Suggestion |

## Verdict
✅ APPROVED — no blockers | 🔄 CHANGES REQUESTED — {N} blockers
```

---

## Standalone Standards Checklist

Used in **Standalone Mode** (Feature Agent, Refactorer, Bug-Fixer). Apply these checks to every changed file.

### SOLID Principles

#### S — Single Responsibility
- [ ] Each class/component has exactly ONE reason to change.
- [ ] 🔴 **BLOCK:** A UI component that BOTH renders AND manages dialog/modal open state inline.
- [ ] 🔴 **BLOCK:** A function that performs two or more distinct operations (e.g., validates AND persists AND notifies).
- [ ] 🔴 **BLOCK:** A component that mixes presentation logic with business/domain logic.

#### O — Open/Closed
- [ ] New behavior is added by creating new classes/functions, not by adding `if/else` to existing ones.
- [ ] 🟡 **WARN:** Adding a new `case` to an existing large `switch` that should be extensible.

#### L — Liskov Substitution
- [ ] Subclasses/implementations honor the full contract of their base type.
- [ ] 🔴 **BLOCK:** `NotImplementedException` thrown in a subclass method.

#### I — Interface Segregation
- [ ] Interfaces/props are small and focused — no "god interfaces".
- [ ] 🟡 **WARN:** Component receiving 10+ props when decomposition would reduce coupling.

#### D — Dependency Inversion
- [ ] High-level modules depend on abstractions, not concrete implementations.
- [ ] 🟡 **WARN:** Business logic directly instantiating infrastructure classes.

### Clean Architecture

#### Layer Separation
- [ ] 🔴 **BLOCK:** Business/domain logic inside a UI component (rule, calculation, validation that doesn't belong in the view layer).
- [ ] 🔴 **BLOCK:** Presentation/formatting logic inside a service or repository.
- [ ] 🔴 **BLOCK:** Direct database/API call from a UI component without going through a service layer.

#### Component Decomposition (UI features)
- [ ] 🔴 **BLOCK:** A modal, dialog, drawer, or overlay defined inline inside the component that opens it — it MUST be a separate component.
- [ ] 🔴 **BLOCK:** A form with complex validation logic inlined in the page/view component.
- [ ] 🟡 **WARN:** Repeated UI pattern (button+icon, label+value) not extracted into a shared component when used 3+ times.

#### Reusability
- [ ] 🟡 **WARN:** New component created that duplicates an existing one — should reuse or extend.
- [ ] 🟢 **INFO:** Component could be generalized for reuse in the future.

### Security

- [ ] 🔴 **BLOCK:** User input used without validation at system boundaries.
- [ ] 🔴 **BLOCK:** Hardcoded secret, token, password, or API key.
- [ ] 🔴 **BLOCK:** Missing authentication/authorization check where required.
- [ ] 🟡 **WARN:** Sensitive data (email, ID) logged to console or error messages.

### Performance

- [ ] 🔴 **BLOCK:** N+1 query pattern introduced.
- [ ] 🟡 **WARN:** Unnecessary re-render trigger (missing memoization, missing dependency array).
- [ ] 🟡 **WARN:** Synchronous blocking operation on a hot path.

### Test Quality (Standalone)

- [ ] 🔴 **BLOCK:** Test created but it tests implementation details instead of behavior.
- [ ] 🔴 **BLOCK:** Test always passes regardless of behavior (false positive).
- [ ] 🟡 **WARN:** Missing edge case coverage for the fixed/added behavior.

