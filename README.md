# DevFlow — Multi-Agent AI Engineering Framework

A portable **framework for professional software development using multiple AI sub-agents** working as a coordinated team. Build production-quality features following the DevFlow lifecycle: Brainstorm → Architecture → Plan (with TDD test code) → Confirm → Implement (Red→Green TDD cycle) → Review → Debug → Finalize.

Designed for **any tech stack**, integrated directly into **VS Code Copilot** (no external tools needed).

![DevFlow Lifecycle](docs/flow.png)

## 🚀 Quick Start

### Step 1: Install globally (one-time)

**macOS / Linux**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)
```

**Windows (PowerShell)**
> **Prerequisite:** [Git for Windows](https://gitforwindows.org/) must be installed — the script uses Git Bash to run the installer. If you see "Git Bash not found", install Git for Windows first.
```powershell
irm https://raw.githubusercontent.com/abdias98/DevFlow/main/install.ps1 | iex
```

Installs the `@devflow` agent globally — available in **every workspace** without extra setup.

### Step 2: Reload VS Code

`Ctrl+Shift+P` → **Developer: Reload Window**

### Step 3: Use DevFlow in any workspace

```
@devflow Implement user authentication with JWT tokens
```

✅ Done. DevFlow orchestrates 8 specialized roles across **7 phases**: Brainstormer → Architect → Planner → Implementer (Red→Green TDD per task) → Reviewer → Debugger → Finalizer. A manual Tester helper is available on-demand for mid-implementation resume.

---

## � Upgrading from v1.2.x

If you have an older version installed, the installer automatically detects and cleans up:

**macOS / Linux**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)
```

**Windows (PowerShell)**
> **Prerequisite:** [Git for Windows](https://gitforwindows.org/) must be installed — the script uses Git Bash to run the installer. If you see "Git Bash not found", install Git for Windows first.
```powershell
irm https://raw.githubusercontent.com/abdias98/DevFlow/main/install.ps1 | iex
```

**What's new in v2.6.2:**
- ✅ Interactive editor selection with installation status
- ✅ Support for multiple editors (VS Code, CLI/generic, easily extensible)
- ✅ Always-prompt workflow (no auto-detection)
- ✅ YAML-driven editor profiles for zero-config new editor support
- ✅ Single global installation (no per-workspace setup)
- ✅ Automatic cleanup of old files
- ✅ Skills + instructions now globally managed
### Interactive Editor Selection

When you run the installer, you'll see a prompt listing all available editor profiles:

```
📍 Select installation target:

  1) Visual Studio Code      [installed]
  2) CLI (Headless)          [always available]

Enter number [1-2]: 1
📍 Selected: Visual Studio Code
```

The installer:
- **Lists all editors** (regardless of installation status)
- **Shows installation status** for each (if detected on your system)
- **Always prompts**, even if only one editor is available
- **Allows installation** for undetected editors (in case you install later)

Reload or restart your selected editor if needed, then follow the installer's post-install message.

See [CHANGELOG.md](CHANGELOG.md#breaking-changes) for detailed migration notes.

---

## 📋 What Is DevFlow?

DevFlow is a **multi-agent framework** that simulates a professional engineering team:

| Phase | Agent / Role | Responsibility | Output |
|-------|--------------|----------------|--------|
| 1 | 🧠 **Brainstormer** | Clarifying questions, goals, constraints, edge cases | Problem Statement |
| 2 | 🧩 **Architect** | Requirements analysis, system design, **Stack Profile** | Architecture spec |
| 3 | 📋 **Planner** | Task breakdown + **complete test code per task** | Plan with ready-to-paste tests |
| ⏸️ | — | **Confirmation Gate** — waits for `/devflow-implement` | — |
| 4 | ⚙️ **Implementer** | 🔴→🟢 Red→Green TDD cycle per task (create failing tests from plan → write production code → pass) | Production code + passing tests |
| 5 | 🔍 **Reviewer** | Code quality, security (OWASP), architecture validation | Code review findings |
| 6 | 🐞 **Debugger** | Root cause analysis (never guesses) | Debug logs + fixes |
| 7 | 🚀 **Finalizer** | Verify tests pass, generate summary, clean memory | Final report |
| — | 🧪 **Tester** *(manual helper)* | Creates a specific failing test from the plan on demand | Failing test file |
| — | 🔧 **Refactorer** *(standalone)* | Scope-locked code improvement without behavior change | Refactor report |
| — | 🩹 **Bug-Fixer** *(standalone)* | Reproduce → Isolate → Fix reported bugs | Bug-fix report |
| — | ⚡ **Feature Agent** *(standalone)* | Lightweight TDD cycle for small-medium features | Feature report |

Each role has **clear responsibilities**, **strict role separation**, and **persistent memory** between phases.

---

## 💻 Usage in Copilot Chat

### Full lifecycle (recommended)
```
@devflow Build a REST API for managing users
```
Runs all phases: Brainstorm → Architect → Plan+TDD → ⏸️ Confirm → Tester (Red Phase) → Implementer (Green Phase) → Review → Debug → Finalize

### Individual phases via slash commands
```
/devflow-brainstorm   Clarify requirements and define scope
/devflow-architect    Design a component or system
/devflow-plan         Break down a feature (includes test code)
/devflow-implement    Start implementation (Red→Green TDD cycle per task)
/devflow-test         Manual helper: create a specific failing test from the plan
/devflow-review       Review code quality & security
/devflow-debug        Debug a failing test
/devflow-finalize     Generate final summary and verify all tests pass
```

### Standalone agents (no full lifecycle needed)
```
/devflow-refactor     Scope-locked refactoring of existing code
/devflow-bug-fix      Reproduce → Isolate → Fix a reported bug
/devflow-feature      Implement a small-medium feature (lightweight TDD)
```

---

## 🔄 How It Works

```
Your Request
     │
     ▼
┌──────────────────┐
│ 🧠 Brainstormer   │ ──► Problem Statement
└──────┬───────────┘
       ▼
┌──────────────────┐
│ 🧩 Architect      │ ──► Design Spec
└──────┬───────────┘
       ▼
┌──────────────────────────────────────────┐
│ 📋 Planner                               │
│  • Task steps with complete code         │
│  • 🧪 Tests for this Task (per task):    │
│    - Complete test code (ready to paste) │
│    - All imports, mocks, assertions      │
│    - Exact run command                   │
└──────┬───────────────────────────────────┘
       ▼
  ⏸️  CONFIRMATION GATE
  ──────────────────────
  Run: @devflow implement
       │
       ▼
┌──────────────────────────────────────────┐
│ ⚙️ Implementer (per task)                 │
│  🔴 Red: create test file from plan →   │
│          run → verify FAIL               │
│  🟢 Green: write production code →       │
│            run → verify PASS             │
└──────┬─────────────────────┬─────────────┘
       │                     │
       ▼                     ▼
┌──────────────┐     ┌──────────────┐
│ 🔍 Reviewer   │────►│ 🐞 Debugger   │ (if FAIL)
└──────┬───────┘     └──────┬───────┘
       │ BLOCK               │ fix
       └────────────────────►┘
       │
       ▼
┌──────────────┐
│ 🚀 Finalizer  │ ──► Summary + cleanup
└──────┬───────┘
       ▼
   ✅ DONE
```

### Iteration Rules

- **Tests FAIL** → Debugger → Implementer (retry)
- **Review BLOCK** → Implementer (fix issues)
- **Architecture flaw** → Architect (redesign)
- **Plan needs adjustment** → Planner (revise)
- Max 3 retries per phase before escalating

---

## 📦 Installation Methods

### Method 1: Quick Install (Recommended)

**macOS / Linux**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)
```

**Windows (PowerShell)**
> **Prerequisite:** [Git for Windows](https://gitforwindows.org/) must be installed — the script uses Git Bash to run the installer. If you see "Git Bash not found", install Git for Windows first.
```powershell
irm https://raw.githubusercontent.com/abdias98/DevFlow/main/install.ps1 | iex
```

### Method 2: From Cloned Repo
```bash
git clone https://github.com/abdias98/DevFlow.git
cd DevFlow
bash install.sh
```

### Method 3: Uninstall

**macOS / Linux**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/uninstall.sh)
```

**Windows (PowerShell)**
> **Prerequisite:** [Git for Windows](https://gitforwindows.org/) must be installed — the script uses Git Bash to run the uninstaller. If you see "Git Bash not found", install Git for Windows first.
```powershell
irm https://raw.githubusercontent.com/abdias98/DevFlow/main/uninstall.ps1 | iex
```

---

## 📍 What Gets Installed

DevFlow is installed **globally** in VS Code, available in **all workspaces**:

| OS | Location |
|----|----------|
| macOS | `~/Library/Application Support/Code/User/` |
| Linux | `~/.config/Code/User/` |
| Windows | `%APPDATA%\Code\User\` |

**Installed items:**
- 12 specialized sub-agent skills total: 8 phase-based lifecycle roles (Brainstormer, Architect, Planner, Tester, Implementer, Reviewer, Debugger, Finalizer) + 1 orchestration role (Orchestrator) + 3 standalone agents (Refactorer, Bug-Fixer, Feature Agent)
- Prompt templates for all lifecycle phases and standalone workflows
- ~200 KB total (highly optimized)

---

## 📂 Project Structure

| Directory | Description |
|-----------|-------------|
| [`.agents/skills/`](.agents/skills/) | Core logic and workflows for each agent. Each agent has its own `SKILL.md`. |
| [`.agents/skills/shared/`](.agents/skills/shared/) | Shared rules, memory conventions, and stack detection logic. |
| [`.agents/skills/shared/standards/`](.agents/skills/shared/standards/) | Private engineering standards library (SOLID, Security, UI, etc.). |
| [`.github/prompts/`](.github/prompts/) | Prompt templates for the agents, used by the editor to trigger specific behaviors. |
| [`editor-profiles/`](editor-profiles/) | YAML definitions for supported editors, including path and tool mappings. |
| [`docs/`](docs/) | Architecture diagrams, flow definitions, and internal documentation. |
| [`install.sh` / `.ps1`](install.sh) | Cross-platform installation scripts. |
| [`uninstall.sh` / `.ps1`](uninstall.sh) | Cross-platform uninstallation scripts. |

---

## 🔧 Tech Stack Compatibility

DevFlow **detects your workspace's tech stack dynamically** by analyzing the content of your configuration files.

Rather than relying on hardcoded lists, agents read files like `package.json`, `*.csproj`, `pyproject.toml`, `go.mod`, or `build.gradle` to extract the full technology profile—including frameworks, ORMs, linters, and test runners.

Works with **any** language and framework out of the box.

---

## AGENTS.md — Skip the Stack Discovery

DevFlow can read an `AGENTS.md` file from your project to skip the exhaustive general codebase exploration during the Architect phase. When the file is found, the Architect agent reads it and uses its contents in place of automatically mapping your folder structure, naming conventions, tech stack, and architecture patterns.

**Valid locations** (searched automatically): project root (`AGENTS.md`) or any subdirectory (e.g., `docs/AGENTS.md`).

### What steps are skipped when AGENTS.md is present

| Step skipped | What it covers |
|---|---|
| Sub-step 1 — Full project structure | Folder hierarchy, module boundaries |
| Sub-step 2 — Naming conventions | File, class, function, route naming |
| Sub-step 4 — Tech stack details | Frameworks, ORMs, build tools, test runners |
| Sub-step 5 — Architecture patterns | MVC, CQRS, layered, feature-based, etc. |
| Sub-step 6 — Conventions for similar features | Reference templates from existing features |

Sub-steps 3 (reference implementation), 7 (reusability inventory), and 8 (test architecture analysis) are still run — scoped to the feature being built using the context from `AGENTS.md`.

### Suggested AGENTS.md format

```markdown
# AGENTS.md — Project metadata for AI agents

## Tech Stack
- Runtime / Language: {e.g., Node.js 20 / TypeScript 5}
- Framework: {e.g., Next.js 14 App Router}
- Styling: {e.g., Tailwind CSS + shadcn/ui}
- Database + ORM: {e.g., PostgreSQL + Prisma}
- Auth: {e.g., next-auth v5 with JWT}
- Test runner: {e.g., Vitest + React Testing Library}
- Package manager: {e.g., pnpm}

## Folder Structure
```
src/
  app/          # Next.js App Router pages and layouts
  components/   # Shared UI components
  lib/          # Utilities and helpers
  server/       # Server-side logic (services, repositories)
  types/        # Shared TypeScript types
prisma/         # Schema and migrations
tests/          # Integration and e2e tests
```

## Naming Conventions
- Components: PascalCase (`UserCard.tsx`)
- Server actions: camelCase (`createUser.ts`)
- API routes: kebab-case (`/api/user-profiles`)
- DB models: PascalCase singular (`User`, `OrderItem`)

## Architecture Patterns
- App Router with server components by default; `use client` only when needed
- Server actions in `src/server/actions/` for mutations
- Repository layer in `src/server/repositories/` for data access
- Zod for all input validation (server and client)

## Test Conventions
- Unit tests alongside source files: `{name}.test.ts`
- Integration tests in `tests/integration/`
- Factories in `tests/factories/`
- Run: `pnpm test` (watch: `pnpm test:watch`, coverage: `pnpm test:coverage`)

## Key Third-Party Abstractions
- `useSession()` from next-auth — do NOT build custom auth  
- `prisma` client from `src/lib/prisma.ts` — single shared instance  
- `cn()` from `src/lib/utils.ts` — class name merging  
```

> **Strongly recommended:** Create an `AGENTS.md` file in your project root describing your stack, folder structure, naming conventions, and test tooling. DevFlow reads it automatically at the start of every Architect phase and skips general codebase exploration — significantly speeding up analysis and improving output accuracy. The more complete it is, the better DevFlow performs. See the format below.

---

## 📚 Key Features

✅ **TDD by Default** — Plan includes complete test code per task; Tester executes Red phase, Implementer executes Green phase.
✅ **UI Mockups** — Architect generates ASCII wireframes with component annotations for every frontend feature  
✅ **API Contracts** — Every endpoint defined explicitly (method, path, request/response shapes, error codes) before any code is written; Reviewer validates the implementation against the contract  
✅ **Risk Assessment** — Architect rates risk per design decision (HIGH/MEDIUM/LOW); Planner converts HIGH risks into task-level flags with rollback steps  
✅ **Definition of Done** — Brainstormer captures explicit success criteria; Finalizer verifies each one before closing the cycle  
✅ **Confirmation Gate** — Implementation never starts automatically; you decide when to proceed with `@devflow implement`  
✅ **Architecture First** — No code without a design spec  
✅ **Never Guesses** — Debugger performs systematic root cause analysis; patterns are persisted across cycles in `/memories/repo/debug-patterns.md`  
✅ **Accessibility Built-in** — Planner adds a11y checklist (WCAG 2.1 AA) to every UI task; Reviewer validates it  
✅ **Private Engineering Standards** — Operates as a Senior Engineering team applying 7 core standards (SOLID, Clean Architecture, Security, Performance, REST API, Project Design, UI Design) strictly during agent execution to guarantee high-quality output.  
✅ **No External Tools** — Pure VS Code + Copilot (no npm packages, no docker, nothing)  
✅ **Dynamic Stack Detection** — Tech-stack agnostic. Agents dynamically analyze your config files (package.json, pyproject.toml, go.mod, etc.) to extract the exact framework, ORM, and testing tools without relying on hardcoded mappings.  
✅ **AGENTS.md Support** — Place an `AGENTS.md` in your project root (or `docs/`) describing your stack, structure, and conventions. DevFlow reads it automatically at the start of every Architect phase and skips general codebase exploration, significantly speeding up the analysis.  
✅ **Stacked PRs** — Optional Stack Mode splits large features into layered PRs (~400 LOC each) for easier code review. Automatic branch management and PR creation via `gh` CLI  
✅ **Auto-Review** — Every implementation is automatically code-reviewed (includes API contract, accessibility, dependency audit)  
✅ **Documented Decisions** — Specs, plans, reviews, and debug logs saved to `docs/devflow/`  
✅ **Actionable Next Steps** — Finalizer outputs follow-up features as user stories, not vague suggestions  
✅ **Role Separation** — Each agent has clear, strict boundaries  

---

## 🔐 Privacy & Security

- ✅ No data sent to external services (uses your local VS Code Copilot)
- ✅ No tracking, no analytics
- ✅ Open source — audit the code yourself
- ✅ Scripts are simple bash (inspect before running)

---

## 📖 Documentation

- **[Wiki](../../wiki)** — Detailed guides for each phase
- **[Examples](./examples)** — Real-world use cases
- **[Contributing](./CONTRIBUTING.md)** — How to extend DevFlow
- **[Architecture](./docs/ARCHITECTURE.md)** — Internal design

---

## 🤝 Contributing

Pull requests welcome! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

### Ideas for Extensions
- Custom agents for your domain (e.g., DevOps, Data Science)
- Integration with Jira, Linear, GitHub Issues
- Custom review rules per project
- Performance profiling agent
- Documentation generation agent

---

## 📄 License

MIT License — See [LICENSE](./LICENSE)

---

## ⚡ Performance

- **Install time:** ~5 seconds
- **First use:** Automatic workspace type detection
- **Response time:** Depends on feature complexity (typically 2-10 minutes per full lifecycle)

---

## 🐛 Troubleshooting

### Commands not showing up?
1. Reload VS Code: `Ctrl+Shift+P` → Developer: Reload Window
2. Verify installation: `~/.config/Code/User/.agents/skills/`
3. Restart VS Code completely

### "garbled" or "permission denied" on install?
Check that the path is writable:
```bash
ls -la ~/.config/Code/User/.agents/skills/
```

### Want to update?
Run the install script again — it will overwrite with the latest version.

---

## 🌟 Star if you find DevFlow useful! 🌟

---

**Built with ❤️ for developers who want to level up their AI-assisted development workflow.**
