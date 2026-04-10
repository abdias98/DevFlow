# Changelog — DevFlow

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

- **Removed `devflow-init` command** — No longer needed. DevFlow is now fully global.
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
  - v1.2.x: `install.sh` + `devflow-init` (per workspace)
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
  - Auto-removes `devflow-init` command from PATH

- `devflow-init.sh`: **Removed entirely** (no longer needed)

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
- Per-workspace setup via `devflow-init`
- Automated `/devflow` command in Copilot Chat

---

## [0.x.x] — Pre-release

Early development and testing phases.
