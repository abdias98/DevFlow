# Bug-Fix Plan Template

Save to `docs/devflow/bug-fixes/YYYY-MM-DD-{slug}-bugfix.md`:

## 🐛 Bug-Fix Plan: {slug}

**Bug:** {one-line description}
**Error type:** {TypeError | NullReferenceException | 404 | timeout | wrong output | ...}
**Root cause hypothesis:** {one sentence}

**Stack:** {Language} · {Framework} · {Test Runner}

### Affected Files
- `{file1}` — {reason}
- `{file2}` — {reason}

### Reproduction Test
- **Path:** `{test path}`
- **Command:** `{Test Command (single file)} {test path}`

### Fix Strategy
- [ ] Task 1: {description} — `{file to modify}`
  - Change: {minimal description of the fix}

**Test command:** `{Test Command}`