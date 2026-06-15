# Refactor Report Template

Save to `docs/devflow/refactors/YYYY-MM-DD-{slug}-refactor.md`:

```markdown
# Refactor Report: {Title}

**Date:** YYYY-MM-DD
**Requested by:** User
**Agent:** DevFlow Refactorer 🔧

## Scope

**Files modified:**
- `{path/to/file}` — {what changed}

**Files explicitly excluded (not touched):**
- `{path/to/file}` — {why excluded}

## Changes Applied

| File | Change Type | Description | Principle Applied |
|------|-------------|-------------|-------------------|
| `{file}` | Extract function | Extracted `{name}` from `{parent}` | SRP |
| `{file}` | Rename | `{old}` → `{new}` for clarity | Naming convention |
| `{file}` | Reduce complexity | Replaced nested conditionals with early returns | Readability |

## Regression Guard

- **Tests used:** `{path/to/test}` — {existing | newly created}
- **Verify with:** `{Test Command}`
- **Single file:** `{Test Command (single file)}`

## Definition of Done

Verify each criterion captured during understanding (Step 1). For a refactor, the central criterion is **observable behavior unchanged**. Mark **Met** only when evidenced.

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | External behavior unchanged | ✅ / ❌ | {regression test · manual check} |
| 2 | {target improvement, e.g., duplication removed} | ✅ / ❌ | {file:line} |

**Result:** {N}/{M} criteria met. {If any ❌ → list what remains and why.}

## Observations (Out of Scope)

> These items were noticed but NOT changed. They may be addressed in a separate refactoring request.

- `{file}:{line}` — {description of potential improvement}

## Notes

{Any relevant context, trade-offs, or follow-up recommendations}
```
