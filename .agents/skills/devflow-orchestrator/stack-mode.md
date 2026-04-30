# Stack Mode Awareness

When `Stack Mode: yes` is set in session memory (saved by the Planner), the lifecycle adapts as described below. **The Planner and Implementer never create PRs automatically.** The user decides if and when to push branches and open PRs.

| Phase | Standard (no stack) | Stacked |
|-------|--------------------|---------| 
| Phase 3 (Planner) | Single task list | Tasks grouped into Stacks with branches assigned |
| Phase 4 (Implementer) | Linear Red→Green | Per-Stack: branch checkout → Red→Green per task → commit → next Stack |
| Phase 5 (Reviewer) | `git diff HEAD~N..HEAD` | `git diff {stack-base}..HEAD` per Stack |
| Phase 6 (Debugger) | Fix on current branch | Fix on current Stack branch — stack-agnostic internally |
| Phase 7 (Finalizer) | Single summary | Summary includes table of all Stack branches created |

## Branch Creation

The Planner provides the git commands for the user to create branches locally. The user may also choose to let the Implementer create them automatically during Phase 4. Example:

```bash
git checkout -b feat/{slug}/stack-1 main
git checkout -b feat/{slug}/stack-2 feat/{slug}/stack-1
```

## PR Creation

**NEVER create pull requests automatically.** The Planner and Implementer never run `gh pr create` or any equivalent. If the user wants PRs, they must do it manually after reviewing each Stack.

## Iteration Loops with Stacking

- **BLOCK → fix → re-review** applies **within the current Stack branch**.
- **Stacks are NOT blocked on prior Stack reviews.** The Implementer continues to the next Stack immediately after committing the current one.
- **If a failure affects prior Stacks,** escalate to the user — cross-stack fixes require manual coordination.