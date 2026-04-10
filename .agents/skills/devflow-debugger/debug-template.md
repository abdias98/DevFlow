# Debug Log Template

Save to `docs/devflow/debug-logs/YYYY-MM-DD-{slug}-debug.md`:

```markdown
# Debug Log: {Feature Title}

**Date:** YYYY-MM-DD
**Triggered by:** {test failure | build error | reviewer finding}
**Attempt:** {1-3}

## Error
\`\`\`
{Exact error message / stack trace}
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
\`\`\`
{Test output showing PASS}
\`\`\`

## Lessons Learned
{What pattern caused this? How to prevent it?}
```

## Debug Patterns by Stack

| Stack | Common pitfalls |
|-------|-----------------|
| **React** | Missing dependency array in `useEffect`; calling hooks conditionally; stale closure; state mutation |
| **Next.js** | Browser APIs in SSR; missing `"use client"`; incorrect dynamic import |
| **Node/Express** | Missing `next()` in middleware; unhandled promise rejection; blocking event loop |
| **.NET** | Service not registered in DI; `async void` instead of `async Task`; EF tracking mismatch |
| **Python** | Missing `await`; mutable default argument; circular imports; pytest fixture scope |
| **Go** | Nil pointer dereference; goroutine leak; unclosed file/response body |
| **SQL/ORM** | N+1 queries; missing index; transaction not committed; wrong isolation level |

## Escalation Rules

| Situation | Action |
|-----------|--------|
| Trivial fix (typo, import) | Fix directly and document |
| Code restructuring needed | Route to Implementer with analysis |
| Architecture flaw revealed | Route to Architect for redesign |
| 3 attempts failed | Present structured triage to user |
| External dependency issue | Document workaround |

## Structured Triage (after 3 attempts)

Present these options:
- **A) Architectural change** → Route to Architect
- **B) Plan revision** → Route to Planner
- **C) Simplify scope** → Update plan, skip test
- **D) Manual fix** → User fixes, continue from next task
- **E) Abandon cycle** → Stop
