# DevFlow Architecture

Internal design documentation for contributors and advanced users.

## Directory Structure

```
DevFlow/
├── .agents/skills/              # AI Sub-agents (Copilot skills)
│   ├── devflow/                 # Main orchestrator agent (also runs the Validation Gate = Phase 2)
│   ├── devflow-brainstorm/
│   ├── devflow-architect/
│   ├── devflow-plan/
│   ├── devflow-test/            # Manual helper only (not an automatic phase)
│   ├── devflow-implement/
│   ├── devflow-review/
│   ├── devflow-debug/
│   ├── devflow-finalize/
│   ├── devflow-bug-fix/         # Standalone bug fixing agent
│   ├── devflow-feature/         # Standalone feature agent
│   ├── devflow-refactor/        # Standalone refactoring agent
│   ├── devflow-perf/            # Standalone performance agent
│   ├── devflow-migrate/         # Standalone migration agent
│   ├── devflow-contract/        # Standalone contract testing agent
│   ├── devflow-docs/            # Standalone documentation agent
│   ├── devflow-templates/       # Standalone template agent
│   ├── devflow-reverse/         # Standalone reverse engineering agent
│   ├── devflow-tutorial/        # Standalone tutorial agent
│   └── shared/                  # Common rules, conventions, and standards
│       ├── rules.md
│       ├── memory-conventions.md
│       ├── output-format.md
│       ├── stack-detection.md
│       ├── bin/
│       │   └── devflow-ctl      # Deterministic enforcement CLI (gates, scope, iterations, locks)
│       └── standards/           # Engineering standards (Private Library)
│           ├── solid.md
│           ├── clean-architecture.md
│           ├── security.md
│           ├── performance.md
│           ├── rest-api.md
│           ├── project-design.md
│           └── ui-design.md
├── .github/
│   ├── prompts/                 # Slash command prompts
│   │   ├── devflow.prompt.md   # Full lifecycle
│   │   └── devflow-*.prompt.md # Phase-specific and standalone
│   └── instructions/
│       └── devflow-conventions.instructions.md
├── docs/
│   └── ARCHITECTURE.md          # This file
├── editor-profiles/             # Editor-specific installation configs
│   └── vscode.yaml
├── install.sh / install.ps1     # Installation scripts
├── uninstall.sh / uninstall.ps1 # Uninstallation scripts
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Agent Responsibilities

### Orchestrator (`devflow` skill)
- Entry point for full lifecycle
- Manages state and iteration logic
- Coordinates sub-agents (including the Validation Gate for Phase 2)
- Enforces strict phase ordering
- Reads `rules.md` and `lifecycle.md`
- Enforces the **Critical Friend Principle** — ensures all agents challenge assumptions before proceeding

### Brainstormer (`devflow-brainstorm`)
- **Input:** User request
- **Output:** Problem Statement saved to session memory (`context.md`)
- **Actions:**
  - Clarifying questions (Goal, Scope, Constraints, Feature Type, Definition of Done)
  - Goal/constraints/edge cases identification
  - Problem restatement
  - Initialize `phase-state.md`
- **Restriction:** NEVER writes code, schema, or architecture

### Validation Gate (Phase 2 — Handled by Orchestrator)
- **Input:** Problem Statement from session memory + engineering standards
- **Output:** Validation report at `docs/devflow/session/{slug}/validation-report.md`
- **Actions (performed by Orchestrator directly):**
  - **Challenge every assumption** — question feasibility, necessity, and correctness
  - **Scan against standards** — SOLID, Security, Clean Architecture, Performance, etc.
  - **Flag contradictions** — surface internal inconsistencies in requirements
  - **Propose alternatives** — suggest better approaches with reasoning
  - **Security audit** — identify potential vulnerabilities before architecture
- **Critical:** This gate exists specifically to prevent the AI from blindly implementing bad requirements. BE HONEST. BE CRITICAL. Do NOT rubber-stamp.

### Architect (`devflow-architect`)
- **Input:** Problem Statement from session memory + workspace files
- **Output:** `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md`
- **Actions:**
  - Read `AGENTS.md` if present (skip general exploration sub-steps)
  - Full codebase exploration if no `AGENTS.md`
  - Define architecture: components, data structures, data flow
  - Save spec after user confirmation
  - Update `context.md` with Stack Profile and Architect Findings
- **Restriction:** NEVER writes implementation code

### Planner (`devflow-plan`)
- **Input:** Architecture Spec + Validation Report
- **Output:** `docs/devflow/plans/YYYY-MM-DD-{slug}.md`
- **Actions:**
  - **Challenge spec assumptions** — verify feasibility before planning
  - Stack Mode gate (conditional — only for large features spanning multiple layers)
  - Explore existing patterns and test conventions
  - Generate HTML mockups (UI features only)
  - Decompose into atomic tasks with complete code snippets and test code
  - Save plan before asking for approval
  - Include Additional Recommendations section

### Tester (`devflow-test`) — Manual Helper Only
- **NOT an automatic phase** — the Implementer handles Red→Green TDD internally
- **Input:** Plan document (specific task)
- **Output:** A specific failing test file
- **Trigger:** Manual only via `/devflow-test` (e.g., resume after context loss, recreate lost test)
- **Constraint:** NEVER writes production code, NEVER runs tests

### Implementer (`devflow-implement`)
- **Input:** Plan document
- **Output:** Production code + test files in workspace
- **Constraint:** Minimal code, follow plan strictly, NEVER run tests. **BUT allowed to suggest justified deviations.**
- **Actions:**
  - **Red Phase per task:** Create test file from plan, inform user how to run it
  - **Green Phase per task:** Write minimal production code, inform user how to verify
  - **Challenge & suggest:** If a better implementation exists, document in Additional Recommendations and flag user
  - Commit at task checkpoints with pre-written messages
  - Auto-invoke Reviewer when all tasks complete

### Reviewer (`devflow-review`)
- **Input:** Changed files + spec + plan
- **Output:** `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md`
- **Actions:**
  - Detect mode: Cycle Mode (full lifecycle) or Standalone Mode (invoked by Feature, Refactor, Bug-Fix, Performance, Migration, Contract, Documentation, Template, Tutorial, or Reverse agents)
  - Apply review checklist: code quality, security, architecture alignment, plan compliance, performance, test coverage
  - Classify findings (BLOCK/WARN/INFO)
  - Route back to invoking agent if blockers
- **Constraint:** NEVER executes commands, NEVER fixes code

### Debugger (`devflow-debug`)
- **Input:** Error / failing test / reviewer finding
- **Output:** `docs/devflow/debug-logs/YYYY-MM-DD-{slug}-debug.md`
- **Constraint:** Never guess, always root cause, NEVER execute tests
- **Actions:**
  - Ask user to reproduce the error and provide output
  - Isolate root cause
  - Apply minimal fix
  - Ask user to verify

### Finalizer (`devflow-finalize`)
- **Input:** Completed cycle (all tests passing, no BLOCK findings)
- **Output:** Final summary saved to `docs/devflow/summaries/YYYY-MM-DD-{slug}-summary.md` + session memory cleaned
- **Actions:**
  - Ask user to run full test suite — if failures, route to Debugger
  - Verify all BLOCK review findings resolved
  - Collect all files created/modified
  - Generate summary (files changed, tests added, architecture decisions, next steps)
  - Provide exact How to Run / Test instructions
  - Clean session memory after user confirmation
- **Constraint:** NEVER execute tests or commands

## Standalone Agents (Outside Lifecycle)

All standalone agents follow the **Critical Friend Principle**: challenge the user's assumptions, suggest better approaches, be honest.

| Agent | Command | Use Case |
|-------|---------|----------|
| Refactorer | `/devflow-refactor` | Improve existing code without changing behavior |
| Bug-Fixer | `/devflow-bug-fix` | Fix a reported bug with reproduction test |
| Feature Agent | `/devflow-feature` | Implement a small-medium feature without full planning overhead |
| Performance Agent | `/devflow-perf` | Analyze performance bottlenecks and recommend optimizations |
| Migration Agent | `/devflow-migrate` | Generate database migrations with forward/backward compatibility checks |
| Contract Agent | `/devflow-contract` | Validate API endpoints against spec contract |
| Documentation Agent | `/devflow-docs` | Generate README, API docs, CHANGELOG from DevFlow artifacts |
| Template Agent | `/devflow-templates` | Generate/maintain project-specific architecture templates |
| Tutorial Agent | `/devflow-tutorial` | Interactive onboarding guide |
| Reverse Agent | `/devflow-reverse` | Analyze undocumented project — generate AGENTS.md + specs |

See each agent's `SKILL.md` for detailed procedures.

## Deterministic Enforcement (`devflow-ctl`)

Agents do not self-verify session state. A CLI at `shared/bin/devflow-ctl` performs all gate verifications, scope checks, iteration counting, lock management, and artifact completeness checks as binary operations (exit codes). Session state lives in the YAML frontmatter of `phase-state.md` and changes only through validated CLI transitions — e.g., the Confirmation Gate cannot be approved while the Validation Gate is `blocked`, and `accepted-risks` can only be set from `blocked`.

Because the CLI only reads and writes session-state files (never code, tests, or git history), agents auto-execute it in **all modes including Pair mode**. It is editor-agnostic: every editor profile maps a terminal tool, so the same enforcement works in VS Code, Claude Code, opencode, Antigravity, and headless environments. See `rules.md` → "Deterministic Enforcement" for the command table.

Standalone agents (Feature, Refactorer, Bug-Fixer) initialize their own lightweight sessions (`devflow-ctl init --mode {mode}`) with a `plan_approval` gate, so they get the same guarantees without commits or branches.

## Memory System

### Session Memory (`/memories/session/devflow/`)
**Fallback:** `docs/devflow/session/` (when `/memories/` is unavailable)

Transient state for active development cycle:
- `context.md` — Request, tech stack (Stack Profile), constraints, DoD
- `phase-state.md` — Completion tracking, iteration counter, iteration log
- `test-registry.md` — Test names, FAIL/PASS status

See [Memory Conventions](.agents/skills/shared/memory-conventions.md) for canonical file formats, rules, and Quick Reference.

### Persistent Artifacts (`docs/devflow/`)
Versioned with git, survive across conversations:
- `specs/` — Architecture specifications
- `plans/` — Implementation plans
- `mockups/` — HTML wireframe mockups
- `reviews/` — Code review findings
- `debug-logs/` — Debug sessions
- `refactors/` — Refactoring summaries
- `bug-fixes/` — Bug fix reports
- `features/` — Feature reports (Feature Agent standalone)
- `performance/` — Performance analysis reports (Performance Agent)
- `migrations/` — Migration reports + files (Migration Agent)
- `contracts/` — API contract validation reports (Contract Agent)
- `documentation/` — Documentation generation reports (Documentation Agent)
- `templates/` — Project-specific architecture templates
- `tutorial/` — Onboarding tutorial + cheat sheet
- `reverse/` — Reverse engineering analysis reports
- `summaries/` — Cycle completion summaries (Finalizer)

## Iteration Logic

```
┌─────────────────────┐
│ Phase Execution     │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐      ┌──────────────────────┐
│ Validation BLOCK?   │──YES─│→ Brainstormer Revise  │
└─────────┬───────────┘      └──────────────────────┘
          │ NO
          ▼
┌─────────────────────┐
│ Tests FAIL?         │
└─────────┬───────────┘
          │
    YES ──┼─── NO
          │        │
          ▼        ▼
      DEBUGGER  NEXT PHASE
          │
          ▼
      Fix + Retry (max 3 attempts)
```

### Stack Mode

When `Stack Mode: yes` is set (by the Planner, conditional on feature size), the iteration logic applies **within each Stack**:

- The Planner groups tasks into Stacks with branches assigned.
- The user creates a branch per Stack (`feat/{slug}/stack-{N}`) with commands provided by the Planner. The Implementer then executes Red→Green per task.
- The Reviewer diffs each Stack against its base branch.
- BLOCK → fix → re-review loops apply within the current Stack branch.
- The Finalizer includes a summary table of all Stack branches.
- **PRs are never created automatically.** The user decides if and when to push branches and open PRs.

See [stack-planning.md](<{{SKILLS_DIR}}/devflow-plan/stack-planning.md>) and [stack-mode.md](<{{SKILLS_DIR}}/devflow/stack-mode.md>) for details.

## Naming Conventions

All artifacts follow [Memory Conventions](<{{SKILLS_DIR}}/shared/memory-conventions.md>).

| Type | Pattern | Example |
|------|---------|---------|
| Validation Report | `validation-report.md` (session memory) | `validation-report.md` |
| Spec | `YYYY-MM-DD-{slug}-design.md` | `2026-03-28-user-auth-design.md` |
| Plan | `YYYY-MM-DD-{slug}.md` | `2026-03-28-user-auth.md` |
| Review | `YYYY-MM-DD-{slug}-review.md` | `2026-03-28-user-auth-review.md` |
| Debug Log | `YYYY-MM-DD-{slug}-debug.md` | `2026-03-28-user-auth-debug.md` |
| Mockup | `YYYY-MM-DD-{slug}-mockup[-A|-B].html` | `2026-03-28-user-auth-mockup-A.html` |
| Refactor | `YYYY-MM-DD-{slug}-refactor.md` | `2026-03-28-user-auth-refactor.md` |
| Bug-Fix | `YYYY-MM-DD-{slug}-bugfix.md` | `2026-03-28-user-auth-bugfix.md` |
| Feature Report | `YYYY-MM-DD-{slug}-feature.md` | `2026-03-28-user-auth-feature.md` |
| Performance | `YYYY-MM-DD-{slug}-perf.md` | `2026-03-28-user-auth-perf.md` |
| Migration | `YYYY-MM-DD-{slug}-migration.md` | `2026-03-28-user-auth-migration.md` |
| Contract | `YYYY-MM-DD-{slug}-contract.md` | `2026-03-28-user-auth-contract.md` |
| Documentation | `YYYY-MM-DD-{slug}-docs.md` | `2026-03-28-user-auth-docs.md` |
| Template | `project-architecture.md` | `project-architecture.md` |
| Tutorial | `YYYY-MM-DD-{slug}-tutorial.md` | `demo-tutorial.md` |
| Reverse | `YYYY-MM-DD-{slug}-reverse-design.md` | `legacy-reverse-design.md` |
| Summary | `YYYY-MM-DD-{slug}-summary.md` | `2026-03-28-user-auth-summary.md` |

## Standard Engineering System

DevFlow uses a **Private Library** approach to enforce engineering standards exclusively through its agents.

### Architecture
Standards live in `shared/standards/` and are read directly by each agent via explicit rules in their `SKILL.md`.

### Standards

| Standard | Applied by | Condition |
|----------|------------|-----------|
| SOLID Principles | All agents | Always |
| Clean Architecture | All agents | Always |
| Security | All agents | Always |
| Performance | All agents | Always |
| Project Design Patterns | Architect, Planner, Reviewer | Always |
| REST API Design | Architect, Planner, Implementer, Reviewer, Debugger | Only if API endpoints are involved |
| UI Design | Architect, Planner, Implementer, Reviewer, Debugger | Only if the feature has a UI |

## AGENTS.md Skip Optimization

When a project has an `AGENTS.md` file, the Architect reads it at the start of Phase 3 and skips general exploration sub-steps (folder structure, naming conventions, tech stack details, architecture patterns, conventions for similar features). Sub-steps for reference implementation, reusability inventory, and deep test architecture analysis still run.

The Architect stores extracted AGENTS.md data in session memory so the Planner can reuse it without re-discovering conventions.

## Tech Stack Detection

DevFlow agents detect the project's technology stack **dynamically** by reading workspace configuration files. See [stack-detection.md](<{{SKILLS_DIR}}/shared/stack-detection.md>) for the complete detection reference. Detected values are stored in the `## Stack Profile` table in `context.md` and reused by all downstream agents.

## Extensibility

### Adding a Custom Agent

1. Create `devflow-custom/SKILL.md` in the skills directory.
2. Define YAML frontmatter (`name`, `description`, `argument-hint`).
3. Implement the procedure following the pattern of existing agents.
4. Create `custom.prompt.md` in the prompts directory if needed.
5. Reference the new skill in the orchestrator.

### Custom Rules per Repo *(Planned — Not Yet Implemented)*

> ⚠️ This feature is planned for a future release.

---

**DevFlow is designed to be extended. Contribute new agents and integrations!**