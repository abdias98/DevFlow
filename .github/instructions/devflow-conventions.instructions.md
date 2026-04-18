---
applyTo: "docs/devflow/**"
---

# DevFlow Conventions

## Artifact Naming

All generated artifacts follow the conventions defined in [../../.agents/skills/shared/memory-conventions.md](../../.agents/skills/shared/memory-conventions.md).

| Type | Directory | Naming Pattern |
|------|-----------|----------------|
| Design spec | `docs/devflow/specs/` | `YYYY-MM-DD-{slug}-design.md` |
| Implementation plan | `docs/devflow/plans/` | `YYYY-MM-DD-{slug}.md` |
| Code review | `docs/devflow/reviews/` | `YYYY-MM-DD-{slug}-review.md` |
| Debug log | `docs/devflow/debug-logs/` | `YYYY-MM-DD-{slug}-debug.md` |
| HTML mockup | `docs/devflow/mockups/` | `YYYY-MM-DD-{slug}-mockup[-A\|-B\|-C].html` |

### Slug rules
- Lowercase, kebab-case
- Max 5 words
- Descriptive of the feature (e.g., `client-address-validation`, `cart-discount-engine`)

---

## Session Memory Structure

During an active DevFlow cycle, session memory lives in `/memories/session/devflow/` (fallback: `docs/devflow/session/`).

### context.md format
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

### phase-state.md format
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

### test-registry.md format
```markdown
# DevFlow Test Registry

| Test File | Test Name | Initial | Current | Notes |
|-----------|-----------|---------|---------|-------|
| `path/to/test.ts` | should {behavior} | FAIL | PASS | {note} |
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

> **For agentic workers:** Use devflow-implementer (Red→Green per task) → devflow-reviewer to execute this plan task-by-task.

**Goal:** {One-sentence summary}
**Architecture:** {Brief reference to spec}
**Tech Stack:** {Detected from workspace}

---

<!-- Include the Stack Plan section ONLY when Stack Mode = yes -->
## Stack Plan *(Stack Mode = yes only)*

| Stack | Title | Branch | Base | PR Title |
|-------|-------|--------|------|----------|
| 1/N | {Data layer title} | `feat/{slug}/stack-1` | `main` | `[1/N] feat({scope}): {title}` |
| 2/N | {API layer title} | `feat/{slug}/stack-2` | `feat/{slug}/stack-1` | `[2/N] feat({scope}): {title}` |
| N/N | {Frontend title} | `feat/{slug}/stack-N` | `feat/{slug}/stack-{N-1}` | `[N/N] feat({scope}): {title}` |

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
| `pom.xml` / `build.gradle` | Java / Android |
| `AndroidManifest.xml` | Android (native) |
| `gradle/libs.versions.toml` | Android (version catalog) |
| `composer.json` | PHP |
| `artisan` | Laravel (PHP framework) |
| `phpunit.xml` / `phpunit.xml.dist` | PHP unit tests (PHPUnit) |
| `Gemfile` | Ruby / Rails |
| `pubspec.yaml` | Dart / Flutter |
| `Package.swift` | Swift / iOS |
| `vite.config.*` | Vite frontend |
| `tsconfig.json` | TypeScript |
| `vitest.config.*` | Vitest test runner |
| `jest.config.*` | Jest test runner |
| `docker-compose*.yml` | Dockerized services |

The agent reads these files to determine:
- Language and framework conventions
- Test runner and assertion library
- Build and run commands

---

## PR Stacking Conventions

### Branch naming
| Purpose | Pattern | Example |
|---------|---------|---------|
| Spec review | `feat/{slug}/spec-review` | `feat/user-auth/spec-review` |
| Stack N | `feat/{slug}/stack-{N}` | `feat/user-auth/stack-1` |

### PR title format
| Type | Format | Example |
|------|--------|---------|
| Spec PR | `spec: {feature title}` | `spec: user authentication` |
| Stack PR | `[N/M] feat({scope}): {stack title}` | `[1/3] feat(auth): data layer + migrations` |

### Sizing guidelines (soft limits)
- ~400 lines of diff per Stack
- ~8 files modified per Stack
- Cohesion takes priority over size — never split a logical layer just to hit the limit

### Stack base branches
- Stack 1 → base: `main` / `develop`
- Stack N (N > 1) → base: `feat/{slug}/stack-{N-1}`
- Spec PR → base: `main` / `develop`
- Project structure patterns

---

## AGENTS.md Structure

An `AGENTS.md` file in the project root (or `docs/AGENTS.md`) is the primary source of project metadata for DevFlow. When present, the Architect reads it at the start of Phase 2 and skips general codebase exploration. The Planner reads the extracted data from session memory in Phase 3 to avoid re-discovering test conventions.

### Valid locations (searched automatically)
- `AGENTS.md` — project root (preferred)
- `docs/AGENTS.md`
- Any subdirectory discoverable via `grep_search`

### Recommended sections

```markdown
# AGENTS.md — Project metadata for AI agents

## Tech Stack
- Runtime / Language: {e.g., Node.js 20 / TypeScript 5}
- Framework: {e.g., Next.js 14 App Router}
- Database + ORM: {e.g., PostgreSQL + Prisma}
- Test runner: {e.g., Vitest + React Testing Library}
- Package manager: {e.g., pnpm}

## Folder Structure
{Brief directory tree with purpose annotations}

## Naming Conventions
- Components: {e.g., PascalCase}
- Services: {e.g., camelCase with .service.ts suffix}
- DB models: {e.g., PascalCase singular}

## Architecture Patterns
{Key patterns in use — MVC, CQRS, layered, feature-based, etc.}

## Test Conventions
- Test file location: {e.g., alongside source as *.test.ts}
- Test utilities: {e.g., factories in tests/factories/}
- Run commands: {e.g., pnpm test | pnpm test:coverage}

## Key Third-Party Abstractions
{Critical shared utilities that agents must NOT reinvent}
```

### What DevFlow skips when AGENTS.md is present

| Architect sub-step skipped | What it covers |
|---|---|
| 1 — Full project structure | Folder hierarchy, module boundaries |
| 2 — Naming conventions | File, class, function, route naming |
| 4 — Tech stack details | Frameworks, ORMs, build tools, test runners |
| 5 — Architecture patterns | MVC, CQRS, layered, feature-based, etc. |
| 6 — Conventions for similar features | Reference templates |

Sub-steps 3, 7, and 8 still run — scoped to the feature using AGENTS.md context.
