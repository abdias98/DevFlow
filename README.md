# DevFlow — Multi-Agent AI Engineering Framework

A portable, **framework for professional software development using multiple AI sub-agents** working as a coordinated team. Build production-quality features following the DevFlow lifecycle: Architecture → Planning → TDD Testing → Implementation → Code Review → Debug → Finalize.

Designed for **any tech stack**, integrated directly into **VS Code Copilot** (no external tools needed).

![DevFlow Lifecycle](docs/flow.png)

## 🚀 Quick Start

### Step 1: Install globally (one-time)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)
```

Installs the `@devflow` agent globally — available in **every VS Code workspace** without extra setup.

### Step 2: Reload VS Code

`Ctrl+Shift+P` → **Developer: Reload Window**

### Step 3: Use DevFlow in any workspace

```
@devflow Implement user authentication with JWT tokens
```

✅ Done. DevFlow orchestrates 6 sub-agents: Architect → Planner → Tester → Implementer → Reviewer → Debugger.

> **Need skills in a specific project?** Run once inside that workspace:
> ```bash
> cd ~/your/project && devflow-init
> ```

---

## 📋 What Is DevFlow?

DevFlow is a **multi-agent framework** that simulates a professional engineering team:

| Agent | Responsibility | Output |
|-------|----------------|--------|
| 🧩 **Architect** | Requirements analysis, system design | Architecture specification |
| 📋 **Planner** | Task breakdown, execution planning | Implementation plan with code snippets |
| 🧪 **Tester** | **TDD:** Write failing tests FIRST | Failing test cases (red phase) |
| ⚙️ **Implementer** | Write minimal code to pass tests | Production code (green phase) |
| 🔍 **Reviewer** | Code quality, security, architecture validation | Code review findings |
| 🐞 **Debugger** | Root cause analysis (never guesses) | Debug logs + fixes |

Each agent has **clear responsibilities**, **strict role separation**, and **persistent memory** between phases.

---

## 💻 Usage in Copilot Chat

### Full lifecycle (recommended)
```
@devflow Build a REST API for managing users
```
Runs all phases: Architect → Plan → Test (TDD) → Implement → Review → Debug

### Individual phases via slash commands
```
/devflow-architect   Design a component
/devflow-plan        Break down a feature
/devflow-test        Write failing tests
/devflow-implement   Implement code
/devflow-review      Review code quality & security
/devflow-debug       Debug a failing test
```

---

## 🔄 How It Works

```
Your Request
     │
     ▼
┌──────────────┐
│ 🧩 Architect  │ ──► Design Spec
└──────┬───────┘
       ▼
┌──────────────┐
│ 📋 Planner    │ ──► Implementation Plan
└──────┬───────┘
       ▼
┌──────────────┐
│ 🧪 Tester     │ ──► Failing Tests (TDD)
└──────┬───────┘
       ▼
┌──────────────┐     ┌──────────────┐
│ ⚙️ Implement  │────►│ 🔍 Reviewer   │
└──────┬───────┘     └──────┬───────┘
       │                    │
       │ ◄─── BLOCK ────────┘ (fix findings)
       │
       │ Tests FAIL?
       ▼
┌──────────────┐
│ 🐞 Debugger   │ (conditional)
└──────┬───────┘
       ▼
   ✅ DONE
```

### Iteration Rules

- **Tests FAIL** → Debugger → Implementer (retry)
- **Review blocker** → Implementer (fix issues)
- **Architecture flaw** → Architect (redesign)
- Max 3 retries per phase before escalating

---

## 📦 Installation Methods

### Method 1: Quick Install (Recommended)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)
```

### Method 2: From Cloned Repo
```bash
git clone https://github.com/abdias98/DevFlow.git
cd DevFlow
bash install.sh
```

### Method 3: Uninstall
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/uninstall.sh)
```

---

## 📍 What Gets Installed

DevFlow is installed **globally** in VS Code, available in **all workspaces**:

| OS | Location |
|----|----------|
| macOS | `~/Library/Application Support/Code/User/globalStorage/github.copilot-dev/` |
| Linux | `~/.config/Code/User/globalStorage/github.copilot-dev/` |
| Windows | `%APPDATA%\Code\User\globalStorage\github.copilot-dev\` |

**Installed items:**
- 6 sub-agent skills
- 7 prompts (1 for full lifecycle + 6 for individual phases)
- ~150 KB total (lightweight)

---

## 🔧 Tech Stack Compatibility

DevFlow **detects your workspace's tech stack automatically**:

| Stack | Detection |
|-------|-----------|
| Node.js / TypeScript | `package.json`, `tsconfig.json` |
| .NET / C# | `*.csproj`, `*.sln` |
| Python | `requirements.txt`, `pyproject.toml` |
| Go | `go.mod` |
| Rust | `Cargo.toml` |
| Java | `pom.xml`, `build.gradle` |
| React | `vite.config.*`, `jest.config.*`, `vitest.config.*` |

Works with **any** language and framework.

---

## 📚 Key Features

✅ **TDD by Default** — Tests written BEFORE implementation (always)  
✅ **Architecture First** — No code without design spec  
✅ **Never Guesses** — Debugger performs systematic root cause analysis  
✅ **No External Tools** — Pure VS Code + Copilot (no npm packages, no docker, nothing)  
✅ **Portable** — Tech-stack agnostic, works anywhere  
✅ **Auto-Review** — Every implementation is automatically code-reviewed  
✅ **Documented Decisions** — Specs, plans, reviews, debug logs are saved  
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
2. Verify installation: `~/.config/Code/User/globalStorage/github.copilot-dev/skills/`
3. Restart VS Code completely

### "garbled" or "permission denied" on install?
Check that the path is writable:
```bash
ls -la ~/.config/Code/User/globalStorage/github.copilot-dev/
```

### Want to update?
Run the install script again — it will overwrite with the latest version.

---

## 🌟 Star if you find DevFlow useful! 🌟

---

**Built with ❤️ for developers who want to level up their AI-assisted development workflow.**
