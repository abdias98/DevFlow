# Refactor Plan Template

Save to `docs/devflow/refactors/plan-YYYY-MM-DD-{slug}.md`:

```markdown
# Refactor Plan: {Title}

**Date:** YYYY-MM-DD
**Agent:** DevFlow Refactorer 🔧

## 📋 Proposed Scope

**Files to be modified:**
- `{path/to/file}` — {what will change}

**Files explicitly excluded:**
- `{path/to/file}` — {reason for exclusion}

## 🔧 Proposed Changes

| File | Change Type | Description | Principle/Pattern |
|------|-------------|-------------|-------------------|
| `{file}` | Extract function | Extract `{name}` from `{parent}` | SRP |
| `{file}` | Rename | `{old}` → `{new}` for clarity | Clean Code |
| `{file}` | Simplify | Reduce cyclomatic complexity | Readability |

## 🧪 Verification & Regression Plan

### Existing Tests
- {List existing tests or "None detected - checking if project supports tests"}

### Regression Guard
- [ ] **If project has tests:** Create/Update regression test at `{path}`.
- [ ] **If no tests:** Manual verification plan: {steps}.

**Verification Command:** `{Test Command}`

## ⚠️ Risks & Considerations
- {Risk 1}
- {Risk 2}

---

## 🚦 Confirmation
- Review the plan above.
- If approved, the agent will proceed with the implementation.
```
