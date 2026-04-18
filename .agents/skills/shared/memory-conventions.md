# DevFlow — Memory Conventions

## Session Memory (Transient)

**Primary path:** `/memories/session/devflow/`
**Fallback path:** `docs/devflow/session/`

| File | Purpose | Written by |
|------|---------|------------|
| `context.md` | Problem statement, constraints, DoD, tech stack, Stack Mode | Brainstormer, Architect, Planner |
| `phase-state.md` | Current phase, checklist, iteration counter/log | All agents |
| `test-registry.md` | Test names, status (FAIL/PASS), files created | Implementer, Tester |

### `context.md` format

```markdown
# DevFlow Context

**Request:** {user's original request}
**Slug:** {feature-slug}
**Tech Stack:** {detected by Architect}
**Feature Type:** {web frontend | backend | fullstack | mobile | CLI | library}
**Stack Mode:** {yes | no}
**Selected Mockup:** {filename, if applicable}

## Goal
{One-sentence summary}

## Definition of Done
- {verifiable criterion 1}
- {verifiable criterion 2}

## Constraints
- {constraint 1}

## Edge Cases
- {edge case 1}

## Assumptions
- {assumption 1}

## Impact
- **Modifies existing behavior:** {yes | no}
- **Affected features:** {list}

## AGENTS.md Context
{Extracted data from AGENTS.md, if found}

## Architect Findings
{Key discoveries from codebase exploration}
```

### `phase-state.md` format

```markdown
# DevFlow Phase State

**Current Phase:** {1-7}
**Feature:** {slug}

## Completed Phases
- [x] Phase 1: Brainstormer — context saved
- [x] Phase 2: Architect — `docs/devflow/specs/{filename}`
- [x] Phase 3: Planner — `docs/devflow/plans/{filename}`
- [ ] Phase 4: Implementer
- [ ] Phase 5: Reviewer
- [ ] Phase 6: Debugger (conditional)
- [ ] Phase 7: Finalizer

## Iteration Counter
| Phase | Count | Max |
|-------|-------|-----|
| Phase 4 (Implementer) | 0 | 3 |
| Phase 5 (Reviewer) | 0 | 3 |
| Phase 6 (Debugger) | 0 | 3 |

## Iteration Log
| # | From | To | Reason |
|---|------|----|--------|
| 1 | Reviewer | Implementer | BLOCK: {reason} |
```

### `test-registry.md` format

```markdown
# DevFlow Test Registry

| Test File | Test Name | Initial | Current | Notes |
|-----------|-----------|---------|---------|-------|
| `path/to/test.ts` | should {behavior} | FAIL | PASS | {note} |
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

1. **Before starting any phase**, read all relevant session memory files.
2. **After completing any phase**, update `phase-state.md` with phase completed + timestamp.
3. **At cycle end**, clean session memory and ensure persistent artifacts are saved.
4. All sub-agents read from and write to the SAME memory — this is how they communicate.
