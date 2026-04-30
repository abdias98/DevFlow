# DevFlow — Memory Conventions

> **Note on examples:** All paths, file names, and technology examples in this document are illustrative. Replace them with the actual stack, conventions, and tools detected for the project.

These conventions define where and how DevFlow agents persist state and artifacts. Every SKILL.md and `rules.md` references this file.

---

## Session Memory (Transient)

These files live only for the duration of a DevFlow session. They are not versioned and may be cleaned up after the feature is complete.

**Primary path:** `/memories/session/devflow/`
**Fallback path:** `docs/devflow/session/`

> **Agents MUST ensure the target directory exists** before writing session files. Use available tools to create the directory if missing.

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
**Feature Type:** {web frontend | backend | fullstack | mobile | CLI | library}
**Stack Mode:** {yes | no}   <!-- "yes" if the project already has a stack detected; "no" if this is a new project with no existing codebase -->
**Selected Mockup:** {filename, if applicable}

## Stack Profile

| Key | Value |
|-----|-------|
| **Language** | {TypeScript \| Python \| Go \| C# \| Java \| PHP \| Ruby \| Kotlin \| ...} |
| **Runtime** | {Node.js 20 \| Python 3.12 \| .NET 8 \| Go 1.22 \| ...} |
| **Framework** | {Next.js 14 \| Django 5 \| ASP.NET Core \| Spring Boot 3 \| Laravel 11 \| ...} |
| **Package Manager** | {npm \| pnpm \| yarn \| pip \| poetry \| go mod \| nuget \| composer \| bundler \| ...} |
| **Test Runner** | {Jest \| Vitest \| pytest \| go test \| xUnit \| JUnit \| PHPUnit \| RSpec \| ...} |
| **Test Command** | {npm test \| pnpm test \| pytest \| go test ./... \| dotnet test \| mvn test \| ...} |
| **Test Command (single file)** | {npm exec jest {file} \| pytest {file} \| go test {package} \| dotnet test --filter {name} \| ...} |
| **Build Command** | {npm run build \| go build \| dotnet build \| mvn package \| ...} |
| **Lint Command** | {npm run lint \| eslint . \| flake8 \| golangci-lint run \| ...} |
| **Source Root** | {src/ \| app/ \| lib/ \| cmd/ \| ...} |
| **Test Root** | {tests/ \| __tests__/ \| test/ \| spec/ \| ...} |
| **Test Utilities** | {e.g., factories in tests/factories/, fixtures in tests/fixtures/} |

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
| `refactors/` | Refactoring summaries | `YYYY-MM-DD-{slug}-refactor.md` |
| `bug-fixes/` | Bug fix reports | `YYYY-MM-DD-{slug}-bugfix.md` |
| `features/` | Lightweight feature docs | `YYYY-MM-DD-{slug}-feature.md` |

## Memory Rules

1. **Before starting any phase**, read all relevant session memory files (`context.md`, `phase-state.md`, `test-registry.md`).
2. **After completing any phase**, update `phase-state.md`:
   - Mark the completed phase with `[x]`.
   - Update `Current Phase` to the next number.
   - Add a `Last Updated` timestamp.
3. **At cycle end** (Finalizer completes):
   - Clean session memory by deleting all files in the session memory path (`/memories/session/devflow/` or `docs/devflow/session/`).
   - Confirm all persistent artifacts are saved.
4. **All sub-agents read from and write to the SAME memory** — this is how they communicate. Do not create separate session files for different agents.