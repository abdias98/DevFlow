# Bug-Fix Report Template

Save to `docs/devflow/bug-fixes/YYYY-MM-DD-{slug}-bugfix.md`:

```markdown
# Bug-Fix Report: {Title}

**Date:** YYYY-MM-DD
**Agent:** DevFlow Bug-Fixer 🩹
**Severity:** {Critical | High | Medium | Low}

## Bug Report

**Error:** `{error message or description}`
**Stack Trace:**

{paste stack trace}

**Steps to reproduce:** {description}

## Root Cause

**Affected file:** `{path/to/file}:{line}`
**Affected function:** `{functionName}`

**Causal chain:**
1. {Input / trigger condition}
2. {Processing step that fails}
3. {Result / observable error}

**Root cause (one sentence):** {The bug is caused by X in file:line because Y.}

## Reproduction Test

- **Test file:** `{path/to/test}`
- **Test name:** `{test name}`
- **Verify reproduction:** `{Test Command (single file)} {path}`

## Fix Applied

| File | Line | Change | Before | After |
|------|------|--------|--------|-------|
| `{file}` | {line} | {description} | `{old code}` | `{new code}` |

**Commit:** `fix({scope}): {description}`

## Verification

- **Reproduction test passes:** `{Test Command (single file)} {test path}`
- **Full suite:** `{Test Command}`

## Pattern (for debug-patterns.md)

| Stack | Error Type | Root Cause Pattern | Fix Strategy |
|-------|------------|-------------------|--------------|
| {stack} | {error} | {pattern} | {strategy} |

## Notes

{Any context, trade-offs, or follow-up recommendations}
```
