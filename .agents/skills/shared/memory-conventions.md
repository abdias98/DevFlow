# DevFlow — Memory Conventions

> **Note on examples:** All paths, file names, and technology examples in this document are illustrative. Replace them with the actual stack, conventions, and tools detected for the project.

These conventions define where and how DevFlow agents persist state and artifacts. Every SKILL.md and `rules.md` references this file.

---

## Session Memory (Transient)

These files live only for the duration of a DevFlow session. They are not versioned and may be cleaned up after the feature is complete.

**Primary path:** `/memories/session/devflow/{slug}/`
**Fallback path:** `docs/devflow/session/{slug}/`

> **Agents MUST ensure the target directory exists** before writing session files. Use available tools to create the directory if missing.

| File | Purpose | Written by |
|------|---------|------------|
| `context.md` | Problem statement, constraints, DoD, tech stack, Stack Mode | Brainstormer, Architect, Planner |
| `phase-state.md` | Current phase, checklist, iteration counter/log | All agents |
| `test-registry.md` | Test names, status (FAIL/PASS), files created | Implementer, Tester |
| `traceability.md` | Cross-reference: requirements → spec → tasks → tests → files | Planner, Implementer |

### `context.md` format

```markdown
# DevFlow Context

**Request:** {user's original request}
**Slug:** {feature-slug}
**Feature Type:** {web frontend | backend | fullstack | mobile | CLI | library}
**Stack Mode:** {yes | no}   <!-- "yes" to split work into stacked branches/PRs per architectural layer (set by the Planner); "no" for a single-branch PR -->
**Selected Mockup:** {filename, if applicable}

## Stack Profile

| Key | Value |
|-----|-------|
| **Language** | {TypeScript \| Python \| Go \| C# \| Java \| PHP \| Ruby \| Kotlin \| ...} |
| **Runtime** | {Node.js 20 \| Python 3.12 \| .NET 8 \| Go 1.22 \| ...} |
| **Framework** | {Next.js 14 \| Django 5 \| ASP.NET Core \| Spring Boot 3 \| Laravel 11 \| ...} |
| **Database** | {PostgreSQL \| MySQL \| SQLite \| MongoDB \| DynamoDB \| Redis \| ...} |
| **Package Manager** | {npm \| pnpm \| yarn \| pip \| poetry \| go mod \| nuget \| composer \| bundler \| ...} |
| **Test Runner** | {Jest \| Vitest \| pytest \| go test \| xUnit \| JUnit \| PHPUnit \| RSpec \| ...} |
| **Test Command** | {npm test \| pnpm test \| pytest \| go test ./... \| dotnet test \| mvn test \| ...} |
| **Test Command (single file)** | {npm exec jest {file} \| pytest {file} \| go test {package} \| dotnet test --filter {name} \| ...} |
| **Unit Test Command** | {npm exec jest {file} \| pytest {file} -m unit \| go test {package} \| ...} *(optional — same as single file if not differentiated)* |
| **Integration Test Command** | {npm exec jest --testPathPattern integration \| pytest -m integration \| ...} *(optional)* |
| **E2E Test Command** | {npx cypress run \| npx playwright test \| ...} *(optional — omit if no E2E tests)* |
| **Build Command** | {npm run build \| go build \| dotnet build \| mvn package \| ...} |
| **Lint Command** | {npm run lint \| eslint . \| flake8 \| golangci-lint run \| ...} |
| **Audit Command** | {npm audit \| pnpm audit \| pip-audit \| safety check \| owasp dependency-check \| cargo audit \| ...} *(optional — omit if no audit tool configured)* |
| **Watch Command** | {npm run dev \| next dev \| vite \| python manage.py runserver \| go run . \| air \| ...} |
| **Source Root** | {src/ \| app/ \| lib/ \| cmd/ \| ...} |
| **Test Root** | {tests/ \| __tests__/ \| test/ \| spec/ \| ...} |
| **Test Utilities** | {e.g., factories in tests/factories/, fixtures in tests/fixtures/} |

> **Monorepo:** When the workspace contains multiple packages (e.g., Nx, Turborepo, Lerna, pnpm workspaces), replace `## Stack Profile` with `## Stack Profiles` below. Each package gets its own profile entry. Downstream agents select the relevant profile based on the feature scope.
> 
> **Multi-language:** `## Stack Profiles` supports different languages per package (e.g., TypeScript frontend + Python backend in the same cycle). Each profile entry defines its own Language, Framework, Test Command, etc. A fullstack feature simply references both profiles.

### `## Stack Profiles` (monorepo only)

```markdown
## Stack Profiles

**Monorepo Tool:** {Nx \| Turborepo \| Lerna \| pnpm workspaces \| yarn workspaces \| Rush \| none}
**Package Manager:** {pnpm \| yarn \| npm \| ...}
**Workspace Root:** {./}

### Workspace root
{Common config: workspace scripts, lint, format, shared tooling}

### {packages/frontend}
| Key | Value |
|-----|-------|
| **Language** | TypeScript |
| **Framework** | Next.js 14 |
| **Test Command** | pnpm --filter frontend test |
| **Test Command (single file)** | pnpm --filter frontend exec jest {file} |
| **Source Root** | packages/frontend/src/ |
| **Test Root** | packages/frontend/__tests__/ |

### {packages/api}
| Key | Value |
|-----|-------|
| **Language** | TypeScript |
| **Runtime** | Node.js 20 |
| **Framework** | Express |
| **Test Command** | pnpm --filter api test |
| **Test Command (single file)** | pnpm --filter api exec jest {file} |
| **Source Root** | packages/api/src/ |
| **Test Root** | packages/api/__tests__/ |

{Repeat for each package affected by the feature}
```

## Goal
{One-sentence summary}

## Definition of Done
> Universal criteria (lint, build, tests, no BLOCKs) from [dod-template.md](./dod-template.md) apply automatically.
- {feature-specific criterion 1}
- {feature-specific criterion 2}

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

## DESIGN.md Guidelines
{Extracted project-specific design guidelines from DESIGN.md, if found}

## Architect Findings
{Key discoveries from codebase exploration}
```

### `phase-state.md` format

The file has two parts: a **machine-readable YAML frontmatter** managed exclusively through `devflow-ctl` (see [rules.md](./rules.md) → Deterministic Enforcement), and a **human-readable markdown body** that agents update as a session log.

```yaml
---
devflow: 1                      # schema version
slug: {feature-slug}
mode: lifecycle                 # lifecycle | feature | refactor | bug-fix | ...
phase: 1                        # current phase (lifecycle: 1, 1.5, 2, 3, 5-8)
pair_mode: false
branch: none                    # set at the Confirmation Gate
locked_by: Orchestrator         # agent name | none
locked_since: 2026-06-11T10:30:00Z
gates:                          # lifecycle: validation + confirmation; standalone: plan_approval
  validation: pending           # pending | passed | blocked | accepted-risks
  confirmation: pending         # pending | approved | rejected
scope:                          # declared scope globs (standalone agents; optional in lifecycle)
  - src/auth/**
iterations:                     # loop counters, incremented via `devflow-ctl iterate`
  implement_review: 0
checkpoints:                    # rollback SHAs, recorded via `devflow-ctl checkpoint set`
  pre-phase-1: {sha}
---
```

**Rules for the frontmatter:**

1. Created by `devflow-ctl init` — never write it by hand.
2. State changes go through `devflow-ctl` subcommands (`gate set`, `config set`, `iterate`, `lock`, `checkpoint set`). The CLI rejects illegal transitions (e.g., approving the Confirmation Gate while the Validation Gate is blocked).
3. The markdown body below the frontmatter remains free-form for the human log (Completed Phases, Iteration Log, Escalation Log) and is still edited by agents directly.

```markdown
# DevFlow Phase State

## Completed Phases
- [x] Phase 1: Brainstormer — context saved
- [x] Phase 1.5: Validation Gate — validation-report.md
- [x] Phase 2: Architect — `docs/devflow/specs/{filename}`
- [x] Phase 3: Planner — `docs/devflow/plans/{filename}`
- [ ] Phase 5: Implementer
- [ ] Phase 6: Reviewer
- [ ] Phase 7: Debugger (conditional)
- [ ] Phase 8: Finalizer

## Iteration Log
| # | From | To | Reason |
|---|------|----|--------|
| 1 | Reviewer | Implementer | BLOCK: {reason} |

## Escalation Log
> Documented by the Orchestrator when iteration limits are exhausted and the user is asked to decide.

| # | Phases | Trigger | Attempts | Root Cause | User Decision |
|---|--------|---------|:--------:|------------|---------------|
| 1 | Implementer ↔ Debugger | Test still failing | 3 | NullReference at auth.ts:42 | Simplify scope |
| 2 | Planner revision | User requests changes | 2 | Ambiguous API contract | Redesign spec |
```

> **Iteration counters and rollback checkpoints** live in the frontmatter (`iterations:` and `checkpoints:`) and are managed via `devflow-ctl iterate` and `devflow-ctl checkpoint set` — they are no longer markdown tables. Rollback SHAs protect: Pre-Phase 1 (baseline), Pre-Phase 5 (before implementation), Pre-Phase 7 (before debug fixes). NEVER execute `git reset` — tell the user the command.

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
| `summaries/` | Cycle completion summaries (Finalizer) | `YYYY-MM-DD-{slug}-summary.md` |
| `debug-logs/` | Root cause analysis | `YYYY-MM-DD-{slug}-debug.md` |
| `refactors/` | Refactoring summaries | `YYYY-MM-DD-{slug}-refactor.md` |
| `bug-fixes/` | Bug fix reports | `YYYY-MM-DD-{slug}-bugfix.md` |
| `features/` | Lightweight feature docs | `YYYY-MM-DD-{slug}-feature.md` |
| `performance/` | Performance analysis reports | `YYYY-MM-DD-{slug}-perf.md` |
| `migrations/` | Database migration reports + files | `YYYY-MM-DD-{slug}-migration.md` |
| `contracts/` | API contract validation reports | `YYYY-MM-DD-{slug}-contract.md` |
| `documentation/` | Documentation generation reports | `YYYY-MM-DD-{slug}-docs.md` |
| `templates/` | Project-specific architecture templates (generated) | `project-architecture.md` |
| `tutorial/` | Tutorial + cheat sheet for new users | `YYYY-MM-DD-{slug}-tutorial.md` |
| `reverse/` | Reverse engineering analysis reports | `YYYY-MM-DD-{slug}-reverse-design.md` |
| `metrics/` | Cycle quality metrics + aggregate trends | `YYYY-MM-DD-{slug}-metrics.md` |
| `knowledge-base/` | Cross-cycle learnings, patterns, and anti-patterns | `learnings.md` (appended per cycle) |

## Memory Rules

1. **Before starting any phase**, read all relevant session memory files (`context.md`, `phase-state.md`, `test-registry.md`).
2. **After completing any phase**, update `phase-state.md`:
   - Mark the completed phase with `[x]`.
   - Update `Current Phase` to the next number.
   - Add a `Last Updated` timestamp.
3. **At cycle end** (Finalizer completes):
   - Clean session memory by deleting all files in the session memory path (`/memories/session/devflow/{slug}/` or `docs/devflow/session/{slug}/`).
   - Confirm all persistent artifacts are saved.
4. **All sub-agents read from and write to the SAME memory** — this is how they communicate. Do not create separate session files for different agents.

## Memory Locking

Session memory is shared across agents. A lightweight lock in `phase-state.md` prevents concurrent writes.

### Lock format (in `phase-state.md` frontmatter)
```yaml
locked_by: {agent name | none}
locked_since: {ISO timestamp | —}
```

> Manage the lock with `devflow-ctl lock check | acquire {agent} | release` — the CLI applies the rules below deterministically (including stale-lock detection).

### Lock rules
1. **Check before reading/writing:** Every agent MUST read `phase-state.md` first. If `Locked By` is set to a different agent **outside the current cycle**, STOP and inform the user: *"Session memory is locked by {agent}. A DevFlow cycle is active for '{feature}'. Wait for it to complete or start a new session."*
2. **Acquire lock:** The Orchestrator sets `Locked By` and `Locked Since` when starting a new cycle (Step 0). The lock stays active for the entire cycle duration.
3. **Lock scope — per cycle, not per agent:** The lock is owned by the Orchestrator on behalf of the entire lifecycle cycle. Sub-agents invoked by the Orchestrator (Brainstormer, Architect, Planner, Implementer, Reviewer, Debugger, Finalizer) may read and write session memory under the Orchestrator's lock — they are part of the same cycle and do not re-acquire it individually.
4. **Release lock:** The Orchestrator clears the lock (`Locked By: none`, `Locked Since: —`) when the cycle completes (Step 8) or is cancelled.
5. **Stale lock detection:** If `Locked Since` is more than 30 minutes old and no phase progress has been made, the lock is stale. Any agent may break it after informing the user: *"A stale lock from {agent} ({N} min ago) was detected. Breaking lock and proceeding."*
6. **Standalone agents:** Before writing to session memory, check the lock. If locked by a lifecycle agent (Orchestrator), do NOT write — report to user and suggest waiting or starting a new session.