# DevFlow Architecture

Internal design documentation for contributors and advanced users.

## Directory Structure

```
DevFlow/
├── .agents/skills/              # AI Sub-agents (Copilot skills)
│   ├── devflow-architect/
│   ├── devflow-planner/
│   ├── devflow-tester/
│   ├── devflow-implementer/
│   ├── devflow-reviewer/
│   └── devflow-debugger/
├── .github/
│   ├── agents/
│   │   └── devflow.agent.md     # Main orchestrator agent
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

### Orchestrator (`devflow.agent.md`)
- Entry point for full lifecycle
- Manages state and iteration logic
- Coordinates sub-agents
- Enforces strict phase ordering

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

### Tester (`devflow-tester`)
- **Input:** Plan document
- **Output:** Test files in workspace
- **Constraint:** NEVER writes production code
- **Actions:**
  - Write failing tests (TDD red phase)
  - Execute tests to verify FAIL
  - Register in session memory

### Implementer (`devflow-implementer`)
- **Input:** Plan + failing tests
- **Output:** Production code in workspace
- **Constraint:** Minimal code, follow plan strictly
- **Actions:**
  - Implement step-by-step (Green phase)
  - Verify tests PASS after each step
  - Commit at checkpoints
  - Auto-invoke Reviewer when done

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
