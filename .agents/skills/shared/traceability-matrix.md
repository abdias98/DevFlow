# Traceability Matrix Template

This session memory file (`docs/devflow/session/{slug}/traceability.md`) cross-references requirements through the full development pipeline: Problem Statement → Architecture Spec → Plan Tasks → Tests → Implementation.

**Written by:** Planner (initial generation from spec + plan)
**Updated by:** Implementer (file paths + status per task)
**Validated by:** Reviewer (coverage check)
**Reported by:** Finalizer (coverage summary in final report)
**Cleaned by:** Finalizer (with other session memory)

## Matrix Format

```markdown
# Traceability Matrix — {slug}

**Generated:** YYYY-MM-DD
**Plan:** `docs/devflow/plans/YYYY-MM-DD-{slug}.md`
**Spec:** `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md`

## Requirement → Task → Test → Implementation

| # | Source | Requirement | Task | Test File | Test Scenario | Impl File | Status |
|---|--------|-------------|------|-----------|---------------|-----------|--------|
| R1 | DoD | {criterion} | Task N | `path` | {scenario} | `path` | ⬜ PENDING |
| R2 | Edge Case | {case} | Task N | `path` | {scenario} | `path` | ⬜ PENDING |
| R3 | Spec Section | {section} | Task N | `path` | {scenario} | `path` | ⬜ PENDING |
| R4 | API Contract | {endpoint} | Task N | `path` | {scenario} | `path` | ⬜ PENDING |
| R5 | Risk | {risk mitigation} | Task N | `path` | {scenario} | `path` | ⬜ PENDING |

**Status legend:** ⬜ PENDING → 🟡 IN PROGRESS → ✅ DONE

## Coverage Summary

| Source | Total | Covered | % |
|--------|:-----:|:-------:|:--:|
| Definition of Done | {N} | {N} | {N}% |
| Edge Cases | {N} | {N} | {N}% |
| Spec Architecture Sections | {N} | {N} | {N}% |
| API Contracts | {N} | {N} | {N}% |
| Risk Mitigations | {N} | {N} | {N}% |
| Plan Tasks | {N} | {N} | {N}% |
| **TOTAL** | **{N}** | **{N}** | **{N}%** |

## Uncovered Items

> Items with 0% coverage after implementation complete require justification or escalation.

| # | Source | Requirement | Reason |
|---|--------|-------------|--------|
| - | - | - | - |
```

## Generation Rules

### Planner (Phase 3 — initial generation)

The Planner MUST generate this matrix from the plan and spec after writing the plan document. For each requirement source:

1. **From `context.md` Definition of Done:** each criterion → at least one row. The test scenario is found in the corresponding task's `🧪 Tests for this Task` section.
2. **From `context.md` Edge Cases:** each edge case → at least one row. Map to the task that handles it.
3. **From spec Architecture sections:** each major section (Component, Data Structure, Data Flow, Integration Point) → at least one row.
4. **From spec API Contracts:** each endpoint → at least one row (happy path test).
5. **From spec Risk Assessment:** each HIGH/MEDIUM risk mitigation → at least one row.

All rows start with `⬜ PENDING`. The Impl File column is left empty (filled by Implementer).

### Implementer (Phase 5 — updates per task)

After each task's Green Phase completes successfully:
1. Find all rows in the matrix belonging to this task.
2. Fill in the `Impl File` column with the actual file path.
3. Update `Status` to `✅ DONE`.

### Reviewer (Phase 5 — validation)

1. Check: every requirement row has Status `✅ DONE`.
2. Any `⬜ PENDING` or `🟡 IN PROGRESS` rows → WARN or BLOCK (if critical requirement).
3. Flag requirements with no test coverage as BLOCK.

### Finalizer (Phase 7 — reporting)

1. Read the matrix and include the Coverage Summary in the final report.
2. List any uncovered items with justification.
3. Delete `traceability.md` with other session memory files.
