# DevFlow Architecture

Internal design documentation for contributors and advanced users.

## Directory Structure

```
DevFlow/
├── .agents/skills/              # AI Sub-agents (Copilot skills)
│   ├── devflow-orchestrator/    # Main orchestrator agent
│   ├── devflow-brainstormer/
│   ├── devflow-architect/
│   ├── devflow-planner/
│   ├── devflow-tester/          # Manual helper only (not an automatic phase)
│   ├── devflow-implementer/
│   ├── devflow-reviewer/
│   ├── devflow-debugger/
│   └── devflow-finalizer/
├── .github/
│   ├── prompts/                  # Slash command prompts
│   │   ├── devflow.prompt.md    # Full lifecycle
│   │   └── devflow-*.prompt.md  # Phase-specific
│   └── instructions/
│       └── devflow-conventions.instructions.md
├── install.sh                    # Installation script
├── uninstall.sh                  # Uninstallation script
└── README.md
```

## Agent Responsibilities

### Orchestrator (`devflow-orchestrator` skill)
- Entry point for full lifecycle
- Manages state and iteration logic
- Coordinates sub-agents
- Enforces strict phase ordering

### Brainstormer (`devflow-brainstormer`)
- **Input:** User request
- **Output:** Problem Statement saved to `/memories/session/devflow/context.md`
- **Actions:**
  - Clarifying questions (`vscode_askQuestions`)
  - Goal/constraints/edge cases identification
  - Problem restatement
  - Hand-off to Architect
- **Restriction:** NEVER writes code, schema, or architecture

### Architect (`devflow-architect` skill)
- **Input:** User requirements + workspace files
- **Output:**  `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md`
- **Actions:**
  - Clarifying questions (vscode_askQuestions)
  - Codebase exploration (Explore subagent)
  - Design document generation
  - Preview + confirmation loop

### Planner (`devflow-planner`)
- **Input:** Spec document
- **Output:** `docs/devflow/plans/YYYY-MM-DD-{slug}.md`
- **Actions:**
  - Decompose into atomic tasks
  - Map files to modify/create
  - Generate complete code snippets
  - Pre-write commit messages

### Tester (`devflow-tester`) — Manual Helper Only
- **NOT an automatic phase** — the Implementer handles Red→Green TDD internally
- **Input:** Plan document (specific task)
- **Output:** A specific failing test file
- **Trigger:** Manual only via `/devflow-tester` (e.g., resume after context loss, recreate lost test)
- **Constraint:** NEVER writes production code

### Implementer (`devflow-implementer`)
- **Input:** Plan document
- **Output:** Production code + passing tests in workspace
- **Constraint:** Minimal code, follow plan strictly
- **Actions:**
  - **🔴 Red Phase per task:** Create test file from plan's `🧪 Tests for this Task` section, run and verify FAIL
  - **🟢 Green Phase per task:** Write minimal production code, run and verify PASS
  - Commit at task checkpoints with pre-written messages
  - Auto-invoke Reviewer when all tasks complete

### Reviewer (`devflow-reviewer`)
- **Input:** Git diff + spec + plan
- **Output:** `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md`
- **Actions:**
  - Code quality checks
  - Security validation (OWASP)
  - Architecture alignment
  - Classify findings (BLOCK/WARN/INFO)
  - Route back to Implementer if blockers

### Debugger (`devflow-debugger`)
- **Input:** Error / failing test / reviewer finding
- **Output:** `docs/devflow/debug-logs/YYYY-MM-DD-{slug}-debug.md`
- **Constraint:** Never guess, always root cause
- **Actions:**
  - Reproduce error
  - Isolate root cause
  - Apply fix
  - Re-verify

### Finalizer (`devflow-finalizer`)
- **Input:** Completed cycle (all tests passing, no BLOCK findings)
- **Output:** Final summary presented to user + session memory cleaned
- **Actions:**
  - Run full test suite and verify GREEN
  - Verify all BLOCK review findings resolved
  - Collect all files created/modified
  - Generate summary (files changed, tests added, architecture decisions, next steps)
  - Provide exact How to Run / Test instructions
  - Clean `/memories/session/devflow/`

## Memory System

### Session Memory (`/memories/session/devflow/`)
Transient state for active development cycle:
- `context.md` — Request, tech stack, constraints
- `phase-state.md` — Completion tracking, iteration log
- `test-registry.md` — Test names, FAIL/PASS status

### Persistent Artifacts (`docs/devflow/`)
Versioned with git, survive across conversations:
- `specs/` — Architecture specifications
- `plans/` — Implementation plans
- `reviews/` — Code review findings
- `debug-logs/` — Debug sessions

## Iteration Logic

```
┌─────────────────────┐
│ Phase Execution     │
└─────────┬───────────┘
          │
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
      Fix + Retry
```

### Stack Mode

When `Stack Mode: yes` is set (by the Planner), the iteration logic applies **within each Stack**:

- The Implementer creates a branch per Stack (`feat/{slug}/stack-{N}`), executes Red→Green per task, then pushes and creates a PR before moving to the next Stack.
- The Reviewer diffs each Stack against its base branch (from the Stack Plan table).
- BLOCK → fix → re-review loops apply within the current Stack branch.
- The Finalizer includes a summary table of all Stack PRs.

See `devflow-conventions.instructions.md` § PR Stacking Conventions for naming and sizing rules.

## Naming Conventions

All artifacts use: `YYYY-MM-DD-{slug}-{type}.md`

Examples:
- `2026-03-28-user-auth-design.md` (spec)
- `2026-03-28-user-auth.md` (plan)
- `2026-03-28-user-auth-review.md` (review)
- `2026-03-28-user-auth-debug.md` (debug log)

## AGENTS.md Skip Optimization

When a project has an `AGENTS.md` file (in the project root or a subdirectory such as `docs/AGENTS.md`), the Architect reads it at the start of Phase 2 (Step 1.5) and skips the following general exploration sub-steps:

| Skipped sub-step | What it covers |
|---|---|
| 1 — Full project structure | Folder hierarchy, module boundaries |
| 2 — Naming conventions | File, class, function, route naming |
| 4 — Tech stack details | Frameworks, ORMs, build tools, test runners |
| 5 — Architecture patterns | MVC, CQRS, layered, feature-based, etc. |
| 6 — Conventions for similar features | Reference templates from existing features |

Sub-steps 3 (reference implementation), 7 (reusability inventory), and 8 (deep test architecture analysis) still run — scoped to the feature using the AGENTS.md context.

The Architect stores the extracted AGENTS.md data in `/memories/session/devflow/context.md` under a `## AGENTS.md Context` block so the Planner can read it in Phase 3 without re-discovering test conventions.

> **Tip for project maintainers:** Creating an `AGENTS.md` in your project root is the single most effective way to speed up every DevFlow cycle. See the README for the suggested format.

---

## Tech Stack Detection

DevFlow reads workspace config files to detect:

| File | Stack |
|------|-------|
| `package.json` | Node.js / JS / TS |
| `*.csproj` | .NET / C# |
| `requirements.txt` | Python |
| `go.mod` | Go |
| `vitest.config.*` | Vitest |
| `jest.config.*` | Jest |

The Tester and Implementer use this info to generate correct syntax and commands.

## Extensibility

### Adding a Custom Agent

1. Create `devflow-custom/SKILL.md` in `~/.config/Code/User/.agents/skills/`
2. Define YAML frontmatter (name, description, argument-hint)
3. Implement the procedure
4. Create `custom.prompt.md` in `~/.config/Code/User/prompts/` if needed
5. Reference in orchestrator

### Custom Rules per Repo

Create `.devflowrc.json` in project root:
```json
{
  "testFramework": "vitest",
  "linter": "eslint",
  "reviewRules": {
    "securityLevel": "strict",
    "performanceThreshold": "critical"
  }
}
```

(Future feature: config file support)

---

**DevFlow is designed to be extended. Contribute new agents and integrations!**
