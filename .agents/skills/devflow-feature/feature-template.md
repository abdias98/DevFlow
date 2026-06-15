# Feature Report Template

Save to `docs/devflow/features/YYYY-MM-DD-{slug}-feature.md`:

```markdown
# Feature Report: {Title}

**Date:** YYYY-MM-DD
**Agent:** DevFlow Feature Agent ⚡
**Stack:** {Language} · {Framework}

## Summary

**Goal:** {one sentence}

## Definition of Done

Verify each criterion captured during understanding (Step 1). Mark **Met** only when evidenced by a test, file, or observed behavior.

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | {criterion 1} | ✅ / ❌ | {test name · file:line · manual check} |
| 2 | {criterion 2} | ✅ / ❌ | {evidence} |

**Result:** {N}/{M} criteria met. {If any ❌ → list what remains and why.}

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `{path}` | Created / Modified | {what was done} |

## Tasks Completed

- [x] Task 1: {description}
- [x] Task 2: {description}

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `{path}` | `{name}` | ✅ Created |

**Verify with:**
- Single file: `{Test Command (single file)} {test path}`
- Full suite: `{Test Command}`

## Self-Review

| Check | Result |
|-------|--------|
| Security | ✅ / ⚠️ {note} |
| Naming conventions | ✅ / ⚠️ {note} |
| SOLID principles | ✅ / ⚠️ {note} |
| Test coverage | ✅ / ⚠️ {note} |

## Notes

{Any context, trade-offs, or follow-up recommendations}
```
