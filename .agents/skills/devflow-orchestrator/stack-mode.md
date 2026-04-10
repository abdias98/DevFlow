# Stack Mode Awareness

When `Stack Mode: yes` is set in session memory (saved by the Planner), the lifecycle adapts:

| Phase | Standard (no stack) | Stacked |
|-------|--------------------|---------| 
| Phase 3 (Planner) | Single task list | Tasks grouped into Stacks with branches and PR titles |
| Phase 4 (Implementer) | Linear Red→Green | Per-Stack: branch setup → Red→Green per task → push + PR → next Stack |
| Phase 5 (Reviewer) | `git diff HEAD~N..HEAD` | `git diff "$STACK_BASE"..HEAD` per Stack |
| Phase 6 (Debugger) | Fix on current branch | Fix on current Stack branch — stack-agnostic internally |
| Phase 7 (Finalizer) | Single summary | Summary includes table of all Stack PRs |

## Iteration Loops with Stacking

- **BLOCK → fix → re-review** applies **within the current Stack branch**.
- **Stacks are NOT blocked on prior Stack reviews.** The Implementer continues to the next Stack immediately after pushing the PR.
- **If a failure affects prior Stacks,** escalate to the user — cross-stack fixes require manual coordination.
