---
applyTo: "docs/devflow/**"
---

# DevFlow Conventions

## Artifact Naming

All generated artifacts follow: `YYYY-MM-DD-{slug}-{type}.md`

| Type | Directory | Example |
|------|-----------|---------|
| Design spec | `docs/devflow/specs/` | `2026-03-28-user-auth-design.md` |
| Implementation plan | `docs/devflow/plans/` | `2026-03-28-user-auth.md` |
| Code review | `docs/devflow/reviews/` | `2026-03-28-user-auth-review.md` |
| Debug log | `docs/devflow/debug-logs/` | `2026-03-28-user-auth-debug.md` |

### Slug rules
- Lowercase, kebab-case
- Max 5 words
- Descriptive of the feature (e.g., `client-address-validation`, `cart-discount-engine`)

---

## Session Memory Structure

During an active DevFlow cycle, session memory lives in `/memories/session/devflow/`:

```
/memories/session/devflow/
├── context.md        ← Original request, constraints, assumptions, tech stack detected
├── phase-state.md    ← Current phase, completed phases, artifact paths, blockers
└── test-registry.md  ← Test files created, test names, status (FAIL→PASS tracking)
```

### context.md format
```markdown
# DevFlow Context
**Request:** {original user request}
**Date:** YYYY-MM-DD
**Slug:** {feature-slug}
**Tech Stack:** {auto-detected from workspace}
**Constraints:** {any limitations}
**Assumptions:** {inferred requirements}
```

### phase-state.md format
```markdown
# DevFlow Phase State
**Current Phase:** {1-7}
**Feature:** {slug}

## Completed Phases
- [x] Phase 1: Architect — `docs/devflow/specs/{file}`
- [x] Phase 2: Planner — `docs/devflow/plans/{file}`
- [ ] Phase 3: Tester
- [ ] Phase 4: Implementer
- [ ] Phase 5: Reviewer
- [ ] Phase 6: Debugger (conditional)
- [ ] Phase 7: Finalization

## Iteration Log
| # | From | To | Reason |
|---|------|----|--------|
| 1 | Reviewer | Implementer | BLOCK: missing null check in service layer |
```

### test-registry.md format
```markdown
# DevFlow Test Registry

| Test File | Test Name | Initial | Current | Notes |
|-----------|-----------|---------|---------|-------|
| `src/__tests__/auth.test.ts` | should validate token | FAIL | PASS | Fixed in Phase 4 Step 2 |
| `src/__tests__/auth.test.ts` | should reject expired | FAIL | FAIL | Pending implementation |
```

---

## Spec Document Template

```markdown
# Design: {Feature Title}

**Date:** YYYY-MM-DD
**Status:** Draft | Approved
**DevFlow Phase:** Architect

## Context
{Why this feature exists, business problem it solves}

## Architecture
{System design, components, data flow}

## Components
| Component | Type | Location | Purpose |
|-----------|------|----------|---------|
| ... | ... | ... | ... |

## Data Structures
{Models, DTOs, interfaces — with code snippets}

## Design Decisions
| Decision | Alternatives | Reasoning |
|----------|--------------|-----------|
| ... | ... | ... |

## Constraints
{Technical or business limitations}
```

---

## Plan Document Template

```markdown
# {Feature Title} Implementation Plan

> **For agentic workers:** Use devflow-tester → devflow-implementer → devflow-reviewer to execute this plan task-by-task.

**Goal:** {One-sentence summary}
**Architecture:** {Brief reference to spec}
**Tech Stack:** {Detected from workspace}

---

## File Map

**Modify:**
- `path/to/file.ext` — description of change

**Create:**
- `path/to/new-file.ext` — purpose

---

### Task N: {Task Title}

**Files:**
- Modify: `path/to/file.ext`
- Create: `path/to/new-file.ext`

- [ ] **Step 1: {Description}**
{Instructions + complete code snippet}

- [ ] **Step 2: {Description}**
{Instructions + complete code snippet}

- [ ] **Step N: Commit**
\`\`\`bash
git add {files}
git commit -m "{conventional commit message}"
\`\`\`
```

---

## Review Document Template

```markdown
# Code Review: {Feature Title}

**Date:** YYYY-MM-DD
**Reviewer:** DevFlow Reviewer (automated)
**Spec:** `docs/devflow/specs/{file}`
**Plan:** `docs/devflow/plans/{file}`

## Summary
{Overall assessment}

## Findings

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Suggestion |
|---|------|------|-------|------------|

### 🟡 WARN (should fix)
| # | File | Line | Issue | Suggestion |
|---|------|------|-------|------------|

### 🟢 INFO (optional)
| # | File | Line | Issue | Suggestion |
|---|------|------|-------|------------|

## Verdict
- [ ] ✅ APPROVED — no blockers
- [ ] 🔄 CHANGES REQUESTED — see BLOCK findings above
```

---

## Debug Log Template

```markdown
# Debug Log: {Feature Title}

**Date:** YYYY-MM-DD
**Triggered by:** {test failure | reviewer finding | runtime error}

## Error
\`\`\`
{Error message / stack trace}
\`\`\`

## Root Cause Analysis
{Systematic explanation of WHY the error occurred}

## Fix Applied
**File:** `path/to/file`
**Change:** {description}
\`\`\`diff
- old code
+ new code
\`\`\`

## Verification
{Test re-run result confirming the fix}
```

---

## Tech Stack Detection

DevFlow is **portable** — it detects the workspace's tech stack dynamically:

| File | Indicates |
|------|-----------|
| `package.json` | Node.js / JavaScript / TypeScript |
| `*.csproj` / `*.sln` | .NET / C# |
| `requirements.txt` / `pyproject.toml` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml` / `build.gradle` | Java |
| `vite.config.*` | Vite frontend |
| `tsconfig.json` | TypeScript |
| `vitest.config.*` | Vitest test runner |
| `jest.config.*` | Jest test runner |
| `docker-compose*.yml` | Dockerized services |

The agent reads these files to determine:
- Language and framework conventions
- Test runner and assertion library
- Build and run commands
- Project structure patterns
