# Tutorial Summary Template

Save to `docs/devflow/tutorial/YYYY-MM-DD-{slug}-tutorial.md`:

```markdown
# DevFlow Tutorial — {Demo Feature Name}

**Date:** YYYY-MM-DD
**Tutorial Agent:** DevFlow Tutorial Agent 🎓
**Stack:** {Language} · {Framework}

## What We Built

{One-line description of the demo feature}

## Cycle Summary

### Phase 1: Brainstormer 🧠
- **What happened:** Identified goal, constraints, DoD
- **Output:** `context.md` with problem statement
- **Key takeaway:** Understand BEFORE building

### Phase 2: Architect 🧩
- **What happened:** Explored codebase, designed architecture
- **Output:** `docs/devflow/specs/{filename}`
- **Key takeaway:** Reuse existing components, document decisions

### Phase 3: Planner 📋
- **What happened:** Broke architecture into atomic tasks
- **Output:** `docs/devflow/plans/{filename}`
- **Key takeaway:** Every task has test code + production code + commit message

### Confirmation Gate ⏸️
- **What happened:** Plan reviewed and approved
- **Key takeaway:** NEVER proceed without explicit approval

### Phase 4: Implementer ⚙️
- **What happened:** Red→Green TDD per task
- **Output:** Test files + production code
- **Key takeaway:** Tests first, minimal code, commit at checkpoints

### Phase 5: Reviewer 🔍
- **What happened:** Code reviewed against 7 standards
- **Output:** `docs/devflow/reviews/{filename}`
- **Key takeaway:** Security issues are ALWAYS blockers

### Phase 7: Finalizer 🚀
- **What happened:** Full suite verified, metrics computed, docs generated
- **Output:** `docs/devflow/summaries/{filename}`
- **Key takeaway:** Every cycle leaves the project better

## Files Created During Tutorial

| File | Type | Phase |
|------|------|-------|
| `context.md` | Session memory | 1 |
| `docs/devflow/specs/{filename}` | Spec | 2 |
| `docs/devflow/plans/{filename}` | Plan | 3 |
| `src/{demo files}` | Production code | 4 |
| `tests/{demo tests}` | Test code | 4 |
| `docs/devflow/reviews/{filename}` | Review | 5 |
| `docs/devflow/summaries/{filename}` | Summary | 7 |

## Next Steps

1. Start a real cycle: `/devflow <your feature request>`
2. Use standalone agents: `/devflow-refactor`, `/devflow-bug-fix`
3. Read the cheat sheet: `docs/devflow/tutorial/cheatsheet.md`
4. Explore the docs: `docs/devflow/`
```
