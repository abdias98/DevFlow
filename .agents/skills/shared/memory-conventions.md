# DevFlow — Memory Conventions

## Session Memory (Transient)

**Primary path:** `/memories/session/devflow/`
**Fallback path:** `docs/devflow/session/`

| File | Purpose | Written by |
|------|---------|------------|
| `context.md` | Original request, constraints, Feature Type, Stack Mode, selected mockup | Brainstormer, Planner |
| `phase-state.md` | Current phase, completed phases, blocking issues | All agents |
| `test-registry.md` | Test names, status (FAIL/PASS), files created | Implementer, Tester |

### `context.md` format

```markdown
# DevFlow Context

**Request:** {user's original request}
**Feature Type:** {web frontend | backend | fullstack | mobile | CLI | library}
**Stack Mode:** {yes | no}
**Selected Mockup:** {filename, if applicable}

## Constraints
- {constraint 1}
- {constraint 2}

## AGENTS.md Context
{Extracted data from AGENTS.md, if found}

## Architect Findings
{Key discoveries from codebase exploration}
```

### `phase-state.md` format

```markdown
# DevFlow Phase State

- [x] Phase 1: Brainstormer — context saved
- [x] Phase 2: Architect — `docs/devflow/specs/{filename}`
- [x] Phase 3: Planner — `docs/devflow/plans/{filename}`
- [ ] Phase 4: Implementer
- [ ] Phase 5: Reviewer
- [ ] Phase 6: Debugger (conditional)
- [ ] Phase 7: Finalizer
```

## Persistent Artifacts (Versioned)

**Path:** `docs/devflow/`

| Directory | Content | Naming |
|-----------|---------|--------|
| `specs/` | Architecture specs | `YYYY-MM-DD-{slug}-design.md` |
| `plans/` | Implementation plans | `YYYY-MM-DD-{slug}.md` |
| `mockups/` | HTML wireframe mockups | `YYYY-MM-DD-{slug}-mockup[-A\|-B\|-C].html` |
| `reviews/` | Code review findings | `YYYY-MM-DD-{slug}-review.md` |
| `debug-logs/` | Root cause analysis | `YYYY-MM-DD-{slug}-debug.md` |

## Memory Rules

1. **Before starting any phase**, read all relevant session memory files
2. **After completing any phase**, update `phase-state.md` with phase completed + timestamp
3. **At cycle end**, clean session memory and ensure persistent artifacts are saved
4. All sub-agents read from and write to the SAME memory — this is how they communicate
