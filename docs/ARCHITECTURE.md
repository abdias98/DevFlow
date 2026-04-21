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
│   ├── devflow-finalizer/
│   ├── devflow-bug-fixer/       # Standalone bug fixing agent
│   ├── devflow-feature/         # Standalone feature agent
│   ├── devflow-refactor/        # Standalone refactoring agent
│   └── shared/                  # Common rules, conventions, and standards
│       ├── rules.md
│       ├── memory-conventions.md
│       ├── output-format.md
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
│   │   └── devflow-*.prompt.md # Phase-specific
│   └── instructions/
│       └── devflow-conventions.instructions.md
├── docs/
│   └── ARCHITECTURE.md          # This file
├── editor-profiles/             # Editor-specific installation configs
│   └── vscode.yaml
├── install.sh / install.ps1     # Installation scripts (Linux/macOS and Windows)
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
- Coordinates sub-agents
- Enforces strict phase ordering

### Brainstormer (`devflow-brainstorm`)
- **Input:** User request
- **Output:** Problem Statement saved to `/memories/session/devflow/context.md`
- **Actions:**
  - Clarifying questions (`vscode_askQuestions`)
  - Goal/constraints/edge cases identification
  - Problem restatement
  - Hand-off to Architect
- **Restriction:** NEVER writes code, schema, or architecture

### Architect (`devflow-architect`)
- **Input:** User requirements + workspace files
- **Output:** `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md`
- **Actions:**
  - Clarifying questions (`vscode_askQuestions`)
  - Codebase exploration (Explore subagent)
  - Design document generation
  - Preview + confirmation loop

### Planner (`devflow-plan`)
- **Input:** Spec document
- **Output:** `docs/devflow/plans/YYYY-MM-DD-{slug}.md`
- **Actions:**
  - Decompose into atomic tasks
  - Map files to modify/create
  - Generate complete code snippets
  - Pre-write commit messages

### Tester (`devflow-test`) — Manual Helper Only
- **NOT an automatic phase** — the Implementer handles Red→Green TDD internally
- **Input:** Plan document (specific task)
- **Output:** A specific failing test file
- **Trigger:** Manual only via `/devflow-test` (e.g., resume after context loss, recreate lost test)
- **Constraint:** NEVER writes production code

### Implementer (`devflow-implement`)
- **Input:** Plan document
- **Output:** Production code + passing tests in workspace
- **Constraint:** Minimal code, follow plan strictly
- **Actions:**
  - **🔴 Red Phase per task:** Create test file from plan's `🧪 Tests for this Task` section, run and verify FAIL
  - **🟢 Green Phase per task:** Write minimal production code, run and verify PASS
  - Commit at task checkpoints with pre-written messages
  - Auto-invoke Reviewer when all tasks complete

### Reviewer (`devflow-review`)
- **Input:** Git diff + spec + plan
- **Output:** `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md`
- **Actions:**
  - Code quality checks
  - Security validation (OWASP)
  - Architecture alignment
  - Classify findings (BLOCK/WARN/INFO)
  - Route back to Implementer if blockers

### Debugger (`devflow-debug`)
- **Input:** Error / failing test / reviewer finding
- **Output:** `docs/devflow/debug-logs/YYYY-MM-DD-{slug}-debug.md`
- **Constraint:** Never guess, always root cause
- **Actions:**
  - Reproduce error
  - Isolate root cause
  - Apply fix
  - Re-verify

### Finalizer (`devflow-finalize`)
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
**Fallback:** `docs/devflow/session/` (when `/memories/` is unavailable)

Transient state for active development cycle:
- `context.md` — Request, tech stack, constraints
- `phase-state.md` — Completion tracking, iteration log
- `test-registry.md` — Test names, FAIL/PASS status

See [Memory Conventions](../.agents/skills/shared/memory-conventions.md) for file formats and rules.

### Persistent Artifacts (`docs/devflow/`)
Versioned with git, survive across conversations:
- `specs/` — Architecture specifications
- `plans/` — Implementation plans
- `mockups/` — HTML wireframe mockups
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

## Standard Engineering System

DevFlow uses a **Private Library** approach to enforce engineering standards exclusively through its agents. This ensures the framework provides measurable added value over standard AI chat.

### Architecture
Standards live in `.agents/skills/shared/standards/` and are read directly by each agent via explicit rules in their `SKILL.md`. This makes the standards a core competency of DevFlow — not a global editor preference.

### Standards Available (Phase 1)

| File | Standard | Applied by |
|------|----------|------------|
| `standards/solid.md` | SOLID Principles | Architect, Planner, Implementer, Reviewer, Debugger |
| `standards/clean-architecture.md` | Clean Architecture | Architect, Planner, Implementer, Reviewer, Debugger |
| `standards/security.md` | Security | Architect, Planner, Implementer, Reviewer, Debugger |
| `standards/performance.md` | Performance | Architect, Planner, Implementer, Reviewer, Debugger |
| `standards/rest-api.md` | REST API Design *(conditional — skipped for non-API projects)* | Architect, Planner, Implementer, Reviewer |
| `standards/project-design.md` | Project Design Patterns | Architect, Planner, Reviewer |
| `standards/ui-design.md` | UI Design *(conditional — skipped for non-UI projects)* | Architect, Planner, Implementer, Reviewer |

> **Why not global editor instructions?** Standards are intentionally kept private to DevFlow. When a user invokes a DevFlow agent, they receive architecture-grade output guided by these standards. This creates a clear quality gap versus plain AI chat, demonstrating the framework's value.

### Adding a New Standard
1. Create `standards/{name}.md` following the `DO/DON'T` format used by existing standards.
2. Add `- Read [{Name}](../shared/standards/{name}.md)` to the `## Rules` of agents that benefit from it (typically Architect, Planner, Implementer, Reviewer, Debugger).
3. Document the new standard in this table.

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

DevFlow agents detect the project's technology stack **dynamically** by reading the **content** of workspace configuration files — not through a hardcoded lookup table. This allows the framework to work with any language, framework, or toolchain without requiring updates.

### Detection Strategy

1. **Scan** the workspace root for known config files.
2. **Read** their contents to extract: language, framework, ORM, test runner, linter, and build tools.
3. **Store** findings in session memory so all downstream agents reuse them without re-discovering.

### Common Config Files (non-exhaustive)

| File | What it reveals |
|------|-----------------|
| `package.json` | Node.js ecosystem — framework, test runner, linter, build tools (from `dependencies` and `scripts`) |
| `*.csproj` / `*.sln` | .NET ecosystem — target framework, NuGet packages, test SDK |
| `pyproject.toml` / `requirements.txt` | Python ecosystem — framework (Django, FastAPI), test runner (pytest), linter |
| `go.mod` | Go ecosystem — module path, dependencies |
| `composer.json` | PHP ecosystem — framework (Laravel, Symfony), test runner (PHPUnit) |
| `Cargo.toml` | Rust ecosystem — crate dependencies, edition |
| `build.gradle` / `pom.xml` | Java/Kotlin ecosystem — framework (Spring), build tool, test runner |
| `Gemfile` | Ruby ecosystem — framework (Rails), test runner (RSpec) |
| `pubspec.yaml` | Dart/Flutter ecosystem |

> **Note:** This list is a starting point, not a constraint. Agents should read any config file they encounter and extract the full technology profile from its contents.

All agents use this information to generate stack-appropriate designs, code, tests, and commands.

## Extensibility

### Adding a Custom Agent

1. Create `devflow-custom/SKILL.md` in the editor's skills directory
   (path resolved dynamically by `editor-profiles/vscode.yaml` — varies by OS)
2. Define YAML frontmatter (`name`, `description`, `argument-hint`)
3. Implement the procedure following the pattern of existing agents
4. Create `custom.prompt.md` in the editor's prompts directory if needed
5. Reference the new skill in the orchestrator

### Custom Rules per Repo *(Planned — Not Yet Implemented)*

> ⚠️ This feature is planned for a future release. The configuration format below is a design proposal and is not currently supported.

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

---

**DevFlow is designed to be extended. Contribute new agents and integrations!**
