# AGENTS.md — DevFlow

> This file enables DevFlow's own agents (Architect, Planner, etc.) to skip redundant codebase exploration when DevFlow is used to improve itself.

## Tech Stack

| Key | Value |
|-----|-------|
| **Language** | Markdown (skills, templates), Bash (install scripts), YAML (editor profiles) |
| **Runtime** | Any Unix shell (bash) or PowerShell (Windows) |
| **Package Manager** | npm (package.json for metadata only) |
| **Test Runner** | None — manual verification |
| **Test Command** | N/A |
| **Lint Command** | N/A |
| **Source Root** | `.agents/skills/` |
| **Test Root** | N/A |

## Folder Structure

```
DevFlow/
├── .agents/skills/              # AI Agent skills (Markdown)
│   ├── devflow/                 # Orchestrator (lifecycle manager)
│   ├── devflow-brainstorm/      # Phase 1: Problem understanding
│   ├── devflow-architect/       # Phase 2: Architecture design
│   ├── devflow-plan/            # Phase 3: Implementation planning
│   ├── devflow-implement/       # Phase 4: TDD implementation
│   ├── devflow-review/          # Phase 5: Code review
│   ├── devflow-debug/           # Phase 6: Debugging (conditional)
│   ├── devflow-finalize/        # Phase 7: Finalization + cleanup
│   ├── devflow-test/            # Manual helper (test file creation)
│   ├── devflow-refactor/        # Standalone: refactoring
│   ├── devflow-bug-fix/         # Standalone: bug fixing
│   ├── devflow-feature/         # Standalone: lightweight features
│   ├── devflow-perf/            # Standalone: performance analysis
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

- **Multi-agent orchestration**: Orchestrator manages 7-phase lifecycle + 10 standalone agents
- **Skill-based**: Each agent is a self-contained SKILL.md with frontmatter, rules, and procedure
- **TDD by default**: Red→Green cycle mandatory for all implementation
- **Auto-execution modes**: Standard mode and CI mode auto-execute tests and git commands (never auto-push or auto-create PRs). Pair mode and standalone agents require user interaction.
- **Scope-locking**: Agents only touch explicitly approved files
- **Persistent memory**: Session memory (`context.md`, `phase-state.md`, `test-registry.md`, `traceability.md`) + persistent artifacts (`docs/devflow/`)
- **Technology-agnostic**: All standards and guides use abstract examples, adapt to detected stack
- **Private standards library**: 7 engineering standards loaded exclusively by DevFlow agents

## Agent Inventory

| Agent | Phase | Invocation |
|-------|:-----:|------------|
| Orchestrator | 0 | `/devflow` |
| Brainstormer | 1 | `/devflow-brainstorm` |
| Architect | 2 | `/devflow-architect` |
| Planner | 3 | `/devflow-plan` |
| Implementer | 4 | `/devflow-implement` |
| Reviewer | 5 | `/devflow-review` |
| Debugger | 6 | `/devflow-debug` |
| Finalizer | 7 | `/devflow-finalize` |
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
2. There are no automated tests. Verify changes by invoking the modified agent and checking its behavior.
3. Adding a new agent requires: SKILL.md + templates + prompt file + updates to orchestrator, memory-conventions, output-format, lifecycle, ARCHITECTURE.md, and reviewer.
4. Tool names vary by platform. Use `{{SKILLS_DIR}}` for cross-platform path references.
5. The `install.sh` script handles tool name substitution at install time via editor profiles.
