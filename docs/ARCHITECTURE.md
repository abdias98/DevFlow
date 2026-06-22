# DevFlow Architecture

Internal design documentation for contributors and advanced users.

## Directory Structure

```
DevFlow/
├── .agents/skills/              # AI Sub-agents (skills)
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
│   ├── devflow-templates/       # Standalone template agent (also bootstraps knowledge base)
│   ├── devflow-reverse/         # Standalone reverse engineering agent
│   ├── devflow-tutorial/        # Standalone tutorial agent
│   └── shared/                  # Common rules, conventions, patterns, and standards
│       ├── rules.md             # Framework-wide rules (modes, scope-lock, progress honesty, etc.)
│       ├── memory-conventions.md
│       ├── output-format.md
│       ├── stack-detection.md
│       ├── parallel-subagents.md       # Canonical pattern for parallel subagent dispatch
│       ├── verifier-subagent.md        # Canonical pattern for pre-review verification
│       ├── environment-probe.md        # Canonical pattern for environment capability detection
│       ├── autonomous-mode.md          # Canonical pattern for non-presential long-duration cycles
│       ├── vision-verification.md      # Canonical pattern for visual diff and screenshot debugging
│       ├── adaptive-skills.md          # Canonical pattern for rigor-adaptive prescriptiveness
│       ├── artifact-checklist.md
│       ├── critical-friend.md
│       ├── dod-template.md
│       ├── metrics-template.md
│       ├── standards-quick-card.md
│       ├── traceability-matrix.md
│       ├── i18n-es.md
│       ├── bin/
│       │   └── devflow-ctl      # Deterministic enforcement CLI (gates, scope, iterations, locks, capabilities, knowledge)
│       ├── standards/           # Engineering standards (Private Library)
│       │   ├── solid.md
│       │   ├── clean-architecture.md
│       │   ├── security.md
│       │   ├── performance.md
│       │   ├── rest-api.md
│       │   ├── project-design.md
│       │   ├── ui-design.md
│       │   ├── testing.md
│       │   ├── git-conventions.md
│       │   ├── logging.md
│       │   ├── error-handling.md
│       │   ├── concurrency.md
│       │   ├── dependencies.md
│       │   └── accessibility.md
│       └── templates/           # Pre-defined reference templates per project type
├── .github/
│   ├── prompts/                 # Slash command prompts
│   │   ├── devflow.prompt.md   # Full lifecycle
│   │   └── devflow-*.prompt.md # Phase-specific and standalone
│   └── instructions/
│       └── devflow-conventions.instructions.md
├── docs/
│   ├── ARCHITECTURE.md          # This file
│   ├── improvement-roadmap.md   # Framework improvement tracking
│   └── devflow-mythos-analysis.md  # Mythos-class analysis and roadmap
├── editor-profiles/             # Editor-specific installation configs
│   ├── vscode.yaml
│   ├── claude-code.yaml
│   ├── opencode.yaml
│   ├── antigravity.yaml
│   ├── generic.yaml
│   └── permissions/             # 3-tier permission snippets (allow/ask/deny)
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
- **Environment capability probe** — at Step 0, runs `devflow-ctl capabilities` to detect what primitives the environment supports (subagents, vision, terminal, filesystem). Records in `context.md` → `## Environment Capabilities`. Degrades gracefully when primitives are missing. See [environment-probe.md](.agents/skills/shared/environment-probe.md).
- **Autonomous mode** — detects `DEVFLOW_AUTONOMOUS=true` at Step 0. Auto-approves gates, uses normal iteration limits, writes async checkpoints to `autonomous-log.md`, writes to `send-to-user.md` on genuine BLOCKs, resumes from last incomplete phase. See [autonomous-mode.md](.agents/skills/shared/autonomous-mode.md).
- **Adaptive rigor** — reads the rigor level (`light`/`standard`/`deep`/`maximum`) set by the Planner and includes it in the plan summary at the Confirmation Gate.

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
  - **Parallel codebase exploration** — dispatches 4 exploration subagents (Structure & Patterns, Tech Stack & Dependencies, Test Architecture, Reusability & Reference) or 2 when AGENTS.md is present. Falls back to sequential when subagents are unavailable. See [parallel-subagents.md](.agents/skills/shared/parallel-subagents.md).
  - **Vision (optional)** — reads existing architecture diagrams with vision tools when `vision: yes`. See [vision-verification.md](.agents/skills/shared/vision-verification.md).
  - Define architecture: components, data structures, data flow
  - Save spec after user confirmation (auto-accept in CI/Autonomous mode)
  - Update `context.md` with Stack Profile and Architect Findings
- **Restriction:** NEVER writes implementation code

### Planner (`devflow-plan`)
- **Input:** Architecture Spec + Validation Report
- **Output:** `docs/devflow/plans/YYYY-MM-DD-{slug}.md`
- **Actions:**
  - **Challenge spec assumptions** — verify feasibility before planning
  - **Adaptive rigor** — classifies the feature into `light`/`standard`/`deep`/`maximum` based on complexity, records via `devflow-ctl config set rigor {level}`. Controls verification intervals, review depth, and skill prescriptiveness for downstream agents.
  - Stack Mode gate (conditional — only for large features spanning multiple layers)
  - Explore existing patterns and test conventions
  - Generate HTML mockups (UI features only)
  - **Work packet format** — each task is structured as a work packet (Goal, Context, Constraints, Acceptance criteria, Deliverables, Implementation guide) instead of micro-steps. Lets capable models operate with more autonomy while providing structure for less capable ones.
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
  - **Parallel independent task dispatch** — analyzes tasks for independence, groups into waves, dispatches independent tasks as parallel subagents. Falls back to sequential TDD when tasks have dependencies or share files. See [parallel-subagents.md](.agents/skills/shared/parallel-subagents.md).
  - **Red Phase per task:** Create test file from plan, inform user how to run it
  - **Green Phase per task:** Write minimal production code, inform user how to verify
  - **Challenge & suggest:** If a better implementation exists, document in Additional Recommendations and flag user
  - Commit at task checkpoints with pre-written messages
  - **Pre-review verification** — dispatches a fresh-context verifier subagent before invoking the Reviewer (for non-trivial implementations). Catches missing files, scope drift, plan deviations. See [verifier-subagent.md](.agents/skills/shared/verifier-subagent.md).
  - Auto-invoke Reviewer when all tasks complete

### Reviewer (`devflow-review`)
- **Input:** Changed files + spec + plan
- **Output:** `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md`
- **Actions:**
  - Detect mode: Cycle Mode (full lifecycle) or Standalone Mode (invoked by Feature, Refactor, Bug-Fix, Performance, Migration, Contract, Documentation, Template, Tutorial, or Reverse agents)
  - **Parallel multi-dimension review** — dispatches 3 subagents (Security & Safety, Performance & Concurrency, Architecture/Quality/Plan Compliance) following [parallel-subagents.md](.agents/skills/shared/parallel-subagents.md). Falls back to inline sequential review for trivial changes.
  - **Visual diff (optional)** — when `vision: yes` and the feature has a UI, compares the approved mockup against a screenshot of the implemented UI. Reports layout/color/typography discrepancies. See [vision-verification.md](.agents/skills/shared/vision-verification.md).
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
  - **Screenshot analysis (optional)** — when `vision: yes` and a screenshot is provided, reads it with vision tools as supplementary context. See [vision-verification.md](.agents/skills/shared/vision-verification.md).
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
| Template Agent | `/devflow-templates` | Generate/maintain project-specific architecture templates. Also bootstraps the knowledge base from historical artifacts (`bootstrap-knowledge` argument). |
| Tutorial Agent | `/devflow-tutorial` | Interactive onboarding guide |
| Reverse Agent | `/devflow-reverse` | Analyze undocumented project — generate AGENTS.md + specs |

See each agent's `SKILL.md` for detailed procedures.

## Deterministic Enforcement (`devflow-ctl`)

Agents do not self-verify session state. A CLI at `shared/bin/devflow-ctl` performs all gate verifications, scope checks, iteration counting, lock management, artifact completeness checks, environment capability detection, and knowledge base listing as binary operations (exit codes). Session state lives in the YAML frontmatter of `phase-state.md` and changes only through validated CLI transitions — e.g., the Confirmation Gate cannot be approved while the Validation Gate is `blocked`, and `accepted-risks` can only be set from `blocked`.

**Commands:**

| Command | Purpose |
|---------|---------|
| `init --mode <m> --slug <s>` | Create session + acquire lock |
| `status` | Print session summary (phase, mode, rigor, gates, lock) |
| `phase get \| set <N>` | Read / record current phase |
| `gate check \| set <name> <value>` | Validate gate state transitions |
| `scope check <file> \| add <glob>` | Enforce scope-locking |
| `iterate <loop>` | Increment loop counter; exit 1 over limit |
| `lock check \| acquire \| release` | Manage the session lock |
| `config set \| get <key>` | Session settings (branch, pair_mode, mode, phase, rigor) |
| `checkpoint set \| get <name>` | Record / read rollback SHAs |
| `artifacts check <type> <path>` | Validate required sections in artifacts |
| `capabilities [get <key>]` | Print environment capabilities (from `.devflow-environment` marker) |
| `knowledge list` | List entries in the knowledge base |

Because the CLI only reads and writes session-state files (never code, tests, or git history), agents auto-execute it in **all modes including Pair mode**. It is editor-agnostic: every editor profile maps a terminal tool, so the same enforcement works in VS Code, Claude Code, opencode, Antigravity, and headless environments. See `rules.md` → "Deterministic Enforcement" for the command table.

Standalone agents (Feature, Refactorer, Bug-Fixer) initialize their own lightweight sessions (`devflow-ctl init --mode {mode}`) with a `plan_approval` gate, so they get the same guarantees without commits or branches.

## Memory System

### Session Memory (`docs/devflow/session/{slug}/`)

Transient state for active development cycle:
- `context.md` — Request, tech stack (Stack Profile), constraints, DoD, Environment Capabilities, Architect Findings
- `phase-state.md` — Completion tracking, iteration counter, iteration log, rigor level, pair mode, branch
- `test-registry.md` — Test names, FAIL/PASS status
- `traceability.md` — Cross-reference: requirements → spec → tasks → tests → files
- `validation-report.md` — Validation Gate findings (Phase 2)
- `autonomous-log.md` — Async checkpoints (Autonomous mode only — append-only, per-phase progress)
- `send-to-user.md` — Messages requiring user action (Autonomous mode only — BLOCKs, iteration limits, deliverable-ready)

See [Memory Conventions](.agents/skills/shared/memory-conventions.md) for canonical file formats, rules, and Quick Reference.

### Knowledge Base (`docs/devflow/knowledge-base/`)

Versioned with git, survives across conversations. Accumulated learnings from all cycles:
- `learnings.md` — Patterns discovered, anti-patterns to avoid, key architectural decisions. Read by all mid-cycle agents (Brainstormer, Architect, Planner, Implementer, Reviewer, Debugger). Updated by the Finalizer at cycle end. Can be bootstrapped from historical artifacts via `/devflow-templates bootstrap-knowledge`.

### Persistent Artifacts (`docs/devflow/`)
Versioned with git, survive across conversations:
- `specs/` — Architecture specifications
- `plans/` — Implementation plans (work packet format)
- `mockups/` — HTML wireframe mockups
- `reviews/` — Code review findings
- `debug-logs/` — Debug sessions
- `validations/` — Validation Gate reports (archived)
- `metrics/` — Cycle metrics (timing, findings, quality stats)
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

## Implementation Modes

DevFlow supports four execution modes, detected at Orchestrator Step 0:

| Mode | Activation | User presence | Confirmation Gate | Iteration limits | On failure |
|------|-----------|---------------|-------------------|------------------|------------|
| **Standard** | Default (Pair Mode: no) | Present (convenient) | User approves | Normal (3) | Auto-retry → Debugger |
| **Pair** | User selects at Confirmation Gate | Present (interactive) | User approves | Normal (3) | User decides |
| **CI** | `CI=true` env var | None (pipeline) | Auto-approved | 1 (fail-fast) | Exit immediately |
| **Autonomous** | `DEVFLOW_AUTONOMOUS=true` | None (non-presential) | Auto-approved | Normal (3) | Auto-retry → Debugger → escalate to user via `send-to-user.md` |

**Standard mode** auto-executes branches, tests, commits, and git SHAs. **Pair mode** tells the user each command and waits for confirmation. **CI mode** fails fast with max 1 iteration. **Autonomous mode** persists via async checkpoints, resumes from the last incomplete phase, and escalates only on genuine human-required BLOCKs.

`git push` and `gh pr create` are NEVER auto-executed in any mode.

See `rules.md` → Implementation Modes and [autonomous-mode.md](.agents/skills/shared/autonomous-mode.md).

## Environment Capability Probe

DevFlow detects what primitives the environment (editor + tools) supports at cycle start. This is **environment** detection, not model detection — DevFlow never classifies, routes, or recommends models.

**Four primitives:**

| Primitive | What it means | Features that depend on it | Fallback when absent |
|-----------|---------------|---------------------------|---------------------|
| `subagents` | Editor can dispatch subagents | Parallel exploration, review, task dispatch, verifier | Sequential execution |
| `vision` | Editor has image-reading tools | Visual diff (Reviewer), screenshot analysis (Debugger) | Code-only review |
| `terminal` | Editor can execute bash commands | Standard/CI/Autonomous modes | Pair mode forced |
| `filesystem` | Persistent writable filesystem | Knowledge base, session memory, artifacts | Hard stop |

Each editor profile declares a `capabilities:` section. `install.sh` writes a `.devflow-environment` marker file at install time. `devflow-ctl capabilities` reads it at runtime. The Orchestrator records results in `context.md` → `## Environment Capabilities` at Step 0.

See [environment-probe.md](.agents/skills/shared/environment-probe.md).

## Parallelism

DevFlow orchestrates parallel subagent dispatch for independent subtasks. The framework decomposes work, dispatches subagents, and synthesizes their outputs — the model operates within the pattern.

**Agents that use parallelism:**

| Agent | Application | Subtasks |
|-------|-------------|----------|
| Architect (Phase 3) | Parallel codebase exploration | Structure & Patterns, Tech Stack, Test Architecture, Reusability |
| Implementer (Phase 5) | Parallel independent tasks | Tasks with no inter-task dependency (grouped into waves) |
| Reviewer (Phase 6) | Parallel multi-dimension review | Security & Safety, Performance & Concurrency, Architecture/Quality/Plan |

**Pre-review verification:** The Implementer dispatches a fresh-context verifier subagent between implementation and review to catch low-hanging fruit (missing files, scope drift, plan deviations) before the Reviewer spends its budget on deeper analysis.

When the editor doesn't support parallel subagent invocation, execution falls back to sequential automatically — the synthesis step is identical, only the execution order changes.

See [parallel-subagents.md](.agents/skills/shared/parallel-subagents.md) and [verifier-subagent.md](.agents/skills/shared/verifier-subagent.md).

## Adaptive Rigor

The Planner classifies each feature into one of four rigor levels based on complexity:

| Level | Feature type | Prescriptiveness | Checkpoints |
|-------|-------------|-----------------|-------------|
| `light` | Trivial (rename, typo) | Objectives only — agent navigates autonomously | Phase boundaries |
| `standard` | Routine (CRUD, simple component) | Guides — agent adapts when context is rich | Phase boundaries + on deviation |
| `deep` | Complex (new feature, integration) | Literal steps — agent follows procedure | Per-task + on deviation |
| `maximum` | Frontier (migration, architecture change) | Literal + extra verification + conservative escalation | Per-task + per-checkpoint |

Non-negotiable invariants (TDD, scope-lock, gates, artifact validation, progress grounding) are always enforced regardless of rigor level — they are the floor, not the ceiling. The rigor level adjusts the ceiling (how much scaffolding surrounds the invariants).

See [adaptive-skills.md](.agents/skills/shared/adaptive-skills.md).

## Vision Verification

When the environment supports vision (`vision: yes`), DevFlow adds visual verification:

- **Reviewer visual diff** — compares the approved mockup against a screenshot of the implemented UI. Reports layout, color, typography, and component structure discrepancies.
- **Debugger screenshot analysis** — reads screenshots of error states (broken UI, crash screens) as supplementary context for root cause analysis.
- **Architect diagram reading** — reads existing architecture diagrams as supplementary context for codebase exploration.

When vision is unavailable, the review is code-only (design tokens, accessibility attributes, layout code — but no rendered-output comparison). The cycle never breaks.

See [vision-verification.md](.agents/skills/shared/vision-verification.md).

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

**DevFlow 4.0.0 — Mythos-class.** Framework-orchestrated parallelism, environment-aware degradation, autonomous long-duration cycles, vision-based verification, adaptive prescriptiveness, and cross-cycle learning. Model-agnostic by design.