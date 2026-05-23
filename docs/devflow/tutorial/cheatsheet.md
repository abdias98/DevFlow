# DevFlow Cheat Sheet

## Quick Commands

| Command | What it does |
|---------|-------------|
| `/devflow` | Full 7-phase lifecycle |
| `/devflow-brainstorm` | Problem understanding only |
| `/devflow-architect` | Architecture design only |
| `/devflow-plan` | Implementation planning only |
| `/devflow-implement` | TDD implementation only |
| `/devflow-review` | Code review only |
| `/devflow-debug` | Debugging only |
| `/devflow-finalize` | Finalization + cleanup |
| `/devflow-test` | Create test files from plan |
| `/devflow-refactor` | Refactor existing code |
| `/devflow-bug-fix` | Fix a bug with reproduction test |
| `/devflow-feature` | Lightweight feature (no Architect/Planner) |
| `/devflow-perf` | Performance analysis |
| `/devflow-migrate` | Database migration generation |
| `/devflow-contract` | API contract validation |
| `/devflow-docs` | Generate project documentation |
| `/devflow-templates` | Generate architecture templates |
| `/devflow-tutorial` | Interactive onboarding guide |

## Lifecycle Flow

```
Phase 1: Brainstormer → Phase 2: Architect → Phase 3: Planner
                                                    ↓
                                              ⏸️ Confirmation Gate
                                                    ↓
Phase 4: Implementer → Phase 5: Reviewer → Phase 6: Debugger (conditional) → Phase 7: Finalizer
```

## Key Artifacts

| Artifact | Location | Created by |
|----------|----------|------------|
| Problem Statement | `docs/devflow/session/{slug}/context.md` | Brainstormer |
| Architecture Spec | `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md` | Architect |
| Implementation Plan | `docs/devflow/plans/YYYY-MM-DD-{slug}.md` | Planner |
| Code Review | `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md` | Reviewer |
| Debug Log | `docs/devflow/debug-logs/YYYY-MM-DD-{slug}-debug.md` | Debugger |
| Final Summary | `docs/devflow/summaries/YYYY-MM-DD-{slug}-summary.md` | Finalizer |
| Quality Metrics | `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md` | Finalizer |
| Knowledge Base | `docs/devflow/knowledge-base/learnings.md` | Finalizer |
| Project Template | `docs/devflow/templates/project-architecture.md` | Template Agent |

## Key Principles

1. **TDD always** — Tests before production code
2. **Never skip phases** — Each depends on the previous
3. **Confirmation Gate** — User must approve plan before implementation
4. **Never auto-run tests** — Agents tell you the command, you run it
5. **Scope-locked** — Agents only touch approved files
6. **3-iteration max** — After 3 failed loops, escalate to user

## Modes

| Mode | How to activate | Effect |
|------|----------------|--------|
| Standard | Default | Auto-complete all tasks |
| Pair | Confirmation Gate option | Review each task before continuing |
| CI/CD | `CI=true` env var | Auto-approve, fail fast, auto-run tests |
| Stacked | Planner option (>5 tasks) | Split into stacked PR branches |

## Engineering Standards

| Standard | Applied by | When |
|----------|-----------|------|
| SOLID | All agents | Always |
| Clean Architecture | All agents | Always |
| Security | All agents | Always |
| Performance | All agents | Always |
| REST API | Architect, Planner, Implementer, Reviewer | API features only |
| UI Design | Architect, Planner, Implementer, Reviewer | UI features only |
| Project Design | All agents | Always |
