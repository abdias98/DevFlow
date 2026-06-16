# AGENTS.md — DevFlow

> This file enables DevFlow's own agents (Architect, Planner, etc.) to skip redundant codebase exploration when DevFlow is used to improve itself.

## Tech Stack

| Key | Value |
|-----|-------|
| **Language** | Markdown (skills, templates), Bash (install scripts), YAML (editor profiles) |
| **Runtime** | Any Unix shell (bash) or PowerShell (Windows) |
| **Package Manager** | npm (package.json for metadata only) |
| **Test Runner** | None — manual verification + framework self-validation |
| **Test Command** | N/A |
| **Validate Command** | `npm run validate` (`scripts/validate-framework.sh`) — checks cross-references, required sections, version headers, version sync, `devflow-ctl` integrity, etc. |
| **Lint Command** | N/A |
| **Source Root** | `.agents/skills/` |
| **Test Root** | N/A |

## Folder Structure

```
DevFlow/
├── .agents/skills/              # AI Agent skills (Markdown)
│   ├── devflow/                 # Orchestrator (lifecycle manager; runs the Validation Gate = Phase 2)
│   ├── devflow-brainstorm/      # Phase 1: Problem understanding
│   ├── devflow-architect/       # Phase 3: Architecture design
│   ├── devflow-plan/            # Phase 4: Implementation planning
│   ├── devflow-implement/       # Phase 5: TDD implementation
│   ├── devflow-review/          # Phase 6: Code review
│   ├── devflow-debug/           # Phase 7: Debugging (conditional)
│   ├── devflow-finalize/        # Phase 8: Finalization + cleanup
│   ├── devflow-test/            # Manual helper (test file creation)
│   ├── devflow-refactor/        # Standalone: refactoring
│   ├── devflow-bug-fix/         # Standalone: bug fixing
│   ├── devflow-feature/         # Standalone: lightweight features
│   ├── devflow-perf/            # Standalone: performance analysis
│   ├── devflow-migrate/         # Standalone: database migrations
│   ├── devflow-contract/        # Standalone: API contract validation
│   ├── devflow-docs/            # Standalone: documentation generation
│   ├── devflow-templates/       # Standalone: project architecture templates
│   ├── devflow-tutorial/        # Standalone: interactive onboarding
│   ├── devflow-reverse/         # Standalone: reverse-engineer a project
│   └── shared/                  # Shared rules, memory conventions, templates, standards
├── .github/prompts/             # Slash command prompt files
├── .github/instructions/        # Global editor instructions
├── editor-profiles/             # Editor-specific YAML configs
├── docs/                        # Framework documentation
└── *.sh / *.ps1                 # Install/uninstall scripts
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Agent skill dir | `devflow-{name}` | `devflow-brainstorm` |
| Skill entry point | `SKILL.md` | Every agent dir has one |
| Shared rules | `rules.md`, `memory-conventions.md`, etc. | `.agents/skills/shared/` |
| Templates | `{name}-template.md` | `plan-template.md`, `spec-template.md` |
| Standards | `{topic}.md` | `solid.md`, `security.md` |
| Prompt files | `devflow[-{phase}].prompt.md` | `devflow.prompt.md` |
| Editor profiles | `{editor-id}.yaml` | `vscode.yaml`, `opencode.yaml` |
| Persistent artifacts | `YYYY-MM-DD-{slug}-{type}.md` | `2026-05-22-user-auth-design.md` |
| Session memory | `docs/devflow/session/{slug}/` | `context.md`, `phase-state.md` |

## Architecture Patterns

- **Multi-agent orchestration**: Orchestrator manages an 8-phase lifecycle + 10 standalone agents
- **Skill-based**: Each agent is a self-contained SKILL.md with frontmatter, rules, and procedure
- **TDD by default**: Red→Green cycle mandatory for all implementation
- **Auto-execution modes**: Standard mode and CI mode auto-execute tests and git commands (never auto-push or auto-create PRs). Pair mode and standalone agents require user interaction.
- **Scope-locking**: Agents only touch explicitly approved files
- **Persistent memory**: Session memory (`context.md`, `phase-state.md`, `test-registry.md`, `traceability.md`) + persistent artifacts (`docs/devflow/`)
- **Technology-agnostic**: All standards and guides use abstract examples, adapt to detected stack
- **Private standards library**: 14 engineering standards loaded exclusively by DevFlow agents (SOLID, Clean Architecture, Security, Performance, REST API, Project Design, UI Design, Testing, Git Conventions, Logging, Error Handling, Concurrency, Dependencies, Accessibility)

## Agent Inventory

| Agent | Phase | Invocation |
|-------|:-----:|------------|
| Orchestrator | — | `/devflow` |
| Brainstormer | 1 | `/devflow-brainstorm` |
| Validation Gate | 2 | *(run by Orchestrator — no skill)* |
| Architect | 3 | `/devflow-architect` |
| Planner | 4 | `/devflow-plan` |
| Implementer | 5 | `/devflow-implement` |
| Reviewer | 6 | `/devflow-review` |
| Debugger | 7 | `/devflow-debug` |
| Finalizer | 8 | `/devflow-finalize` |
| Tester | Manual | `/devflow-test` |
| Refactorer | Standalone | `/devflow-refactor` |
| Bug-Fixer | Standalone | `/devflow-bug-fix` |
| Feature Agent | Standalone | `/devflow-feature` |
| Performance Agent | Standalone | `/devflow-perf` |
| Migration Agent | Standalone | `/devflow-migrate` |
| Contract Agent | Standalone | `/devflow-contract` |
| Documentation Agent | Standalone | `/devflow-docs` |
| Template Agent | Standalone | `/devflow-templates` |
| Tutorial Agent | Standalone | `/devflow-tutorial` |
| Reverse Agent | Standalone | `/devflow-reverse` |

## Cross-References

- All agents read `shared/rules.md` for common rules
- Standards in `shared/standards/` are conditionally loaded based on feature type
- `shared/memory-conventions.md` is the canonical source for paths and formats
- `shared/output-format.md` defines response structure for all agents
- `shared/stack-detection.md` provides quick stack detection for standalone agents
- `shared/traceability-matrix.md` defines the traceability template
- `shared/metrics-template.md` defines the metrics format
- Editor profiles map tool names for different platforms (`editor-profiles/*.yaml`)

## Key Rules for DevFlow-on-DevFlow

When using DevFlow to modify DevFlow itself:
1. Skills are Markdown files — no compilation needed. Edit and test by invoking the agent.
2. There are no unit tests, but run `npm run validate` (`scripts/validate-framework.sh`) after any change — it catches broken cross-references, missing sections, version-sync drift, and `devflow-ctl` issues. Then verify behavior by invoking the modified agent.
3. Adding a new agent requires: SKILL.md + templates + prompt file + updates to orchestrator, memory-conventions, output-format, lifecycle, ARCHITECTURE.md, and reviewer.
4. Tool names vary by platform. Use `{{SKILLS_DIR}}` for cross-platform path references.
5. The `install.sh` script handles tool name substitution at install time via editor profiles.
