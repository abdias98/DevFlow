# Changelog — DevFlow

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [2.7.0] — 2026-04-29

### 🧠 Framework-Wide Refinement

Complete review and hardening of the entire DevFlow framework to enforce consistency, eliminate duplication, reinforce the "never execute commands" policy, and ensure full technology agnosticism across all agents, standards, and prompts.

### ✨ Added

- **Scope-Locking reinforcements** — All skills and rules now define explicit boundaries for file modifications, with mandatory INFO comments for violations found outside the approved scope.
- **Flow Artifacts Exception** — Plan documents, refactor reports, bug-fix reports, feature summaries, and all other artifacts defined in Memory Conventions are always allowed, regardless of declared scope.
- **Limited Scope sections** — Added "Applying This Standard with a Limited Scope" to all 7 engineering standards (SOLID, Clean Architecture, Performance, Security, REST API, UI Design, Project Design).
- **Complexity Gates** — Refactorer and Bug-Fixer now assess complexity before proceeding and recommend the full `/devflow` cycle for large changes.
- **Questions templates** — Feature Agent and Bug-Fixer now have structured question templates (like Brainstormer and Refactorer).
- **Quick Reference table** — Added to `memory-conventions.md` showing exactly which agent reads/writes each session file.

### 🔄 Changed

- **Single Source of Truth** — Eliminated duplication across the framework. `memory-conventions.md` is the canonical source for paths and formats. `rules.md` is the canonical source for shared rules. All other files reference these instead of copying.
- **Technology agnosticism** — Removed all technology-specific references (POCOs/POJOs, HttpContext, DbSet, ILogger\<T\>, Serilog, npm/pip commands, Android-specific attributes) from standards and guides. All examples are now generic or explicitly marked as illustrative.
- **Stack Mode is now conditional** — The Planner only asks the Stack Mode question for large features (>5 tasks or >3 layers). For small features, it proceeds directly to planning.
- **PRs are always manual** — The Planner and Implementer never create PRs automatically. They provide branch creation commands and the user decides if and when to push and open PRs.
- **Standard loading is conditional** — REST API Design is only loaded when API endpoints are involved. UI Design is only loaded when the feature has a UI. All skills follow this pattern.
- **All 12 prompts simplified** — Reduced from ~85 lines to ~45 lines on average. Removed duplication of procedures already defined in SKILL.md files. Added references to `rules.md`.
- **Architecture spec updated** — `ARCHITECTURE.md` now reflects the actual directory structure, standalone agents, conditional standard loading, and manual PR policy.
- **Convention instructions simplified** — `devflow-conventions.instructions.md` reduced from ~350 to ~120 lines. Templates and session memory formats now link to canonical sources instead of duplicating them.
- **Exploration guide simplified** — Stack-specific patterns replaced with generic area-based patterns (Backend, Frontend, Mobile, CLI/Library).
- **Review checklist simplified** — Reduced from ~150 to ~80 lines. Technology-specific examples removed. Universal/UI/API checks separated.

### 🔧 Fixed

- **Test execution policy enforced globally** — Replaced all instances of "run the test", "execute the command", and "verify tests PASS" with "inform the user of the command" across all skills (Implementer, Debugger, Finalizer, Tester). Every skill now has an explicit "NEVER execute commands" rule.
- **Plan persistence before approval** — Refactorer, Feature Agent, and Bug-Fixer now save their plan/report to the artifact path BEFORE asking for user approval, enabling review of the persisted file.
- **Inconsistent step naming unified** — All skills with similar steps now use identical names (e.g., "Brainstorming (Problem Understanding)" in Refactorer, Feature Agent, and Bug-Fixer).
- **Confirmation Gate duplication removed** — The Implementer no longer asks for a second confirmation (the Orchestrator handles this at the Confirmation Gate).
- **"Spec PR" concept removed** — Eliminated all references to an undefined "Spec PR" from Planner and Orchestrator.
- **Tester agent aligned** — Removed automatic test execution. Now only creates test files and informs the user.
- **All routes use `{{SKILLS_DIR}}`** — Replaced relative paths (`../shared/`) with the canonical variable across all skills, templates, and guides.
- **Stack Flow and TDD Procedure aligned** — Both now instruct the user to run tests instead of executing them. Stack Flow no longer creates PRs automatically.

### 📚 Documentation

- `rules.md` — Scope-Locking precision, Flow Artifacts Exception, INFO notes format, Approval & Confirmation section.
- `memory-conventions.md` — Stack Mode field documented, Quick Reference added, directory creation instructions, Scope-Locking note.
- `standards/solid.md` — v2 with technology-agnostic examples, interactions & tensions, code review checklist, limited scope section.
- `standards/clean-architecture.md` — v2 with technology-agnostic examples, limited scope section.
- `standards/performance.md` — v2 with async/resource/caching interactions, checklist, limited scope section.
- `standards/security.md` — v2 with transport security, data protection at rest, rate limiting, checklist, limited scope section.
- `standards/rest-api.md` — v2 with idempotency, documentation, security & safety, checklist, limited scope section.
- `standards/project-design.md` — v2 with Architecture Spec documentation, checklist, limited scope section.
- `standards/ui-design.md` — v2 with interactions & trade-offs, checklist, limited scope section.
- `ARCHITECTURE.md` — Updated directory tree, standalone agents, conditional standards, manual PR policy.
- `CHANGELOG.md` — This entry.

---

## [2.6.2] — 2026-04-25

### ✨ Features

- **Version Bump** — Updated project version to 2.6.2.
- **Documentation Overhaul** — Updated README.md, CONTRIBUTING.md, and CHANGELOG.md to reflect the current project structure, including the private standards library and multi-editor profiles.

---

## [2.6.0] — 2026-04-20

### ✨ Features

- **Private Standards Library** — Migrated from global editor instructions to a private agent library (`.agents/skills/shared/standards/`) to enforce architecture-grade output exclusively during DevFlow agent runs.
- **7 Core Engineering Standards** — Added and formalized SOLID, Clean Architecture, Security, Performance, REST API, Project Design, and UI Design using a strict `DO/DON'T` format.
- **Dynamic Tech Stack Detection** — Agents now dynamically analyze workspace config files to determine the full technology profile (frameworks, ORMs, test runners).
- **Smart Design Approaches** — Project Design and UI Design standards now intelligently adapt to existing patterns and recommend approaches based on `Feature Type` and detected stack.
- **Stack Profile in Session Memory** — The Architect now persists a structured `## Stack Profile` table in `context.md` (language, runtime, framework, package manager, test runner, test command, source/test roots, utilities). All downstream agents read this instead of re-exploring the codebase.
- **Quick Stack Detection** — New `shared/stack-detection.md` reference for standalone agents to detect the stack from workspace config files without a prior Architect cycle.
- **Scope-Locking Rule** — New shared rule enforcing that agents ONLY touch files explicitly requested, with a mandatory "Out of Scope" declaration.
- **Test Execution Policy** — New shared rule: agents NEVER auto-run tests. They create test files and provide the detected command for the user to run.

### 🆕 New Standalone Agents

- **🔧 Refactorer** (`/devflow-refactor`) — Scope-locked code improvement without changing external behavior. Requires user approval before applying any change. Creates regression tests when none exist.
- **🩹 Bug-Fixer** (`/devflow-bug-fix`) — Resolves reported bugs following Reproduce → Isolate → Fix. Creates a failing reproduction test before any fix is applied. Persists root cause patterns to `debug-patterns.md`.
- **⚡ Feature Agent** (`/devflow-feature`) — Lightweight TDD cycle for small-to-medium features. Includes a complexity gate that recommends the full `/devflow` cycle for large features.

---


## [2.3.1] — 2026-04-12

### ✨ Features

- **Version Bump** — Updated version to 2.3.1.
- **Profile-Based User Directory Resolution** — Installation now resolves `user_dir` from the selected editor profile instead of relying on a single shared location.
- **Updated Uninstall Behavior** — `uninstall.sh` now follows the same profile-specific path resolution so installed files are removed from the correct editor user directory.

---

## [2.3.0] — 2026-04-09

### ✨ Features

- **Multi-Editor Support** — Unified framework across VS Code and CLI via YAML-driven profiles.
- **Improved Installation Flow** — Interactive editor selection with installation status.
- **Global Management** — Skills and instructions are now managed globally for all workspaces.
- **Unified Release** — Consolidated recent framework improvements into a single stable release.

---


## [2.0.0] — 2026-04-02

### 🚨 BREAKING CHANGES

- **Workspace-local `.agents/` and `.github/prompts/` directories are no longer used**
  - All skills, prompts, and instructions are now installed globally
  - Existing projects should remove `.agents/` and `.github/prompts/` directories (optional, they won't be used)

### ✨ New Architecture

- **Single Global Installation** — Install once, use in all workspaces
  - Skills: `~/.config/Code/User/.agents/skills/`
  - Instructions: `~/.config/Code/User/.github/instructions/`
  - Prompts: `~/.config/Code/User/prompts/`
- **Automatic Cleanup** — Installer automatically detects and removes v1.2.x installation
- **Simpler Installation Flow**
  - v2.0.0: `install.sh` only (one time)

### 📝 Migration Guide

If upgrading from **v1.2.x**:

1. Run the installer (will auto-detect and cleanup):
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/abdias98/DevFlow/main/install.sh)
   ```

2. Reload VS Code:
   - `Ctrl+Shift+P` → **Developer: Reload Window**

3. (Optional) Remove old workspace directories:
   ```bash
   cd ~/your/project
   rm -rf .agents .github/prompts .github/instructions
   ```

4. Use DevFlow as normal:
   ```
   @devflow <feature request>
   ```

### 🔧 Technical Changes

- `install.sh`:
  - Now copies skills to global `~/.config/Code/User/.agents/skills/`
  - Now copies instructions to global `~/.config/Code/User/.github/instructions/`
  - Auto-detects and removes DEVFLOW_STORE (`~/.devflow/`)

- `uninstall.sh`:
  - Updated to remove global skills and instructions
  - No longer references DEVFLOW_STORE

### ✅ Benefits

- ✨ Simpler installation (one command, works everywhere)
- 🚀 Faster skill updates (global = all projects get latest immediately)
- 🔒 Centralized control (framework updates don't require per-project syncing)
- 📦 Reduced git noise (no more `.agents/` or `.github/prompts/` in projects)

### 📋 Known Issues

None reported yet. Please [file an issue](https://github.com/abdias98/DevFlow/issues) if you encounter problems during migration.

---

## [1.2.1] — 2026-04-01

### 🐛 Bug Fixes

- Fixed frontmatter in `devflow-brainstorm.prompt.md`, `devflow-implement.prompt.md`, `devflow-finalize.prompt.md` (`agent: agent` → `mode: agent`)
- Removed duplicate prompt registration between global and DevFlow store

### ⚙️ Improvements

- Improved Stack PR branch setup: explicit `git checkout` + `git pull` before branching
- Fixed manual fallback PR URL placeholder: `{base}` → `{stack-base-branch}`
- Clearer base branch detection with user confirmation in Planner Step 6

---

## [1.2.0] — 2026-03-28

### ✨ Features

- Added Stack Mode support for stacked PRs
- Implemented automatic base branch detection with user confirmation
- Added explicit branch checkout and pull in Stack PR workflow

### 📚 Documentation

- Updated Planner Step 6 with base branch confirmation flow
- Clarified Stack Mode branches and dependencies
- Added merge-base documentation in Reviewer Step 2

---

## [1.1.0] — 2026-03-15

### ✨ Features

- Added support for `AGENTS.md` file reading in Architect phase
  - Skip exhaustive stack analysis when `AGENTS.md` is present
  - Speeds up architecture analysis for documented stacks
- Added `git diff` command standardization in Reviewer

### 📚 Documentation

- Updated README with AGENTS.md feature explanation
- Added architecture documentation for stack detection

---

## [1.0.0] — 2026-03-01

### ✨ Initial Release

- 🎯 Multi-agent framework with 7 specialized sub-agents
- 📋 TDD workflow (Red → Green cycle) built into Implementer
- 🔍 Automated code review with security checks (OWASP)
- 🐞 Systematic debugging with root cause analysis
- 💾 Persistent phase memory between sessions
- 📦 Stack Mode support for stacked PRs
- 🔧 Cross-language, cross-framework compatibility

### 📦 Installation

- Global VS Code installation via `install.sh`
- Automated `/devflow` command in Copilot Chat

---

## [0.x.x] — Pre-release

Early development and testing phases.
