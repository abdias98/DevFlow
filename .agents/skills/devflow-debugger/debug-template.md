# Debug Log Template

Save to `docs/devflow/debug-logs/YYYY-MM-DD-{slug}-debug.md`:

```markdown
# Debug Log: {Feature Title}

**Date:** YYYY-MM-DD
**Triggered by:** {test failure | build error | reviewer finding}
**Attempt:** {1-3}

## Error
\`\`\`
{Exact error message / stack trace — provided by user}
\`\`\`

## Root Cause
{Clear explanation of WHY the error occurred — trace the causal chain}

## Fix Applied
**File:** `path/to/file`
**Change:** {description}
\`\`\`diff
- old code
+ new code
\`\`\`

## Verification
{User confirmed: test PASS / full suite PASS}

## Lessons Learned
{What pattern caused this? How to prevent it in the future?}
```

## Common Pitfalls by Area

| Area | Common pitfalls |
|------|-----------------|
| **UI / Frontend** | Missing dependency array in reactive hooks; browser APIs called during server rendering; stale closures; state mutation |
| **Backend / API** | Unhandled promise rejection; missing middleware; blocking event loop; service not registered in DI; incorrect async/await usage |
| **Database / ORM** | N+1 queries; missing index; transaction not committed; incorrect isolation level; entity tracking mismatch |
| **General** | Null/undefined reference; type mismatch; circular imports; incorrect import path; fixture/seed data mismatch |

> Adapt these patterns to the detected stack. Always check the project's own `debug-patterns.md` first if it exists.

## Escalation Rules

| Situation | Action |
|-----------|--------|
| Trivial fix (typo, import) | Fix directly and document |
| Code restructuring needed | Route to Implementer with analysis |
| Architecture flaw revealed | Route to Architect for redesign |
| 3 attempts failed | Present structured triage to user |
| External dependency issue | Document workaround |

## Structured Triage (after 3 attempts)

Present these options to the user:
- **A) Architectural change** → Route to Architect
- **B) Plan revision** → Route to Planner
- **C) Simplify scope** → Update plan, skip test
- **D) Manual fix** → User fixes, continue from next task
- **E) Abandon cycle** → Stop