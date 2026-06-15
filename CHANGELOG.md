# Changelog — DevFlow

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### 🔄 Changed

- **Standalone agents load standards on demand (quick-card-first)** — the Feature, Bug-Fix, Refactor, and Reviewer agents previously mandated reading all six-to-seven full engineering standards (~50–70 KB) upfront on every invocation, contradicting the context-saving design of `standards-quick-card.md` / `critical-friend.md`. Their Rules now instruct: scan the Standards Quick Card first (fast BLOCK-trigger scan) and load a full standard only when a red flag matches or the change falls in its domain. The Reviewer keeps full depth (loads every standard that applies to the changed files, skipping only clearly-irrelevant domains). Also standardized the loadable set across all four agents and added `testing.md` to it. Frees context for the agents to reason about the actual code.

---

## [2.10.1] — 2026-06-15

> Wave 1 of the framework improvement roadmap — correctness fixes to lifecycle consistency and mode-aware test execution. No behavior change to public commands.

### 🐛 Fixed

- **Phase numbering consistency** — corrected a systemic off-by-one in lifecycle phase labels across the framework. The canonical scheme (Orchestrator) is Reviewer = Phase 6, Debugger = Phase 7, Finalizer = Phase 8; several files labeled them 5/6/7. Aligned: `devflow-review/SKILL.md`, `devflow-tutorial/SKILL.md`, `shared/i18n-es.md`, `shared/output-format.md`, `shared/traceability-matrix.md`, `devflow/stack-mode.md`, `docs/devflow/knowledge-base/learnings.md`, and the `devflow-review` / `devflow-debug` / `devflow-finalize` prompt descriptions. (#40)
- **Bug-Fixer step numbering** — `devflow-bug-fix/SKILL.md` had two steps labeled "Step 9" (Finalize Document and Auto-Invoke Reviewer), making the procedure order ambiguous. Renumbered the Reviewer step to Step 10 and corrected the stale "Step 8 MUST overwrite" cross-reference (now Step 9). (#41)
- **Reference template library wired into the Architect** — the six pre-defined architecture templates in `shared/templates/` (`web-frontend`, `api-rest`, `fullstack`, `mobile-app`, `cli-tool`, `library-sdk`) were effectively orphaned: the Architect referenced them only via a generic `shared/templates/{type}.md` glob buried inside the "project template found" conditional, so four of them were unreachable and `validate-framework.sh` flagged them as unreferenced. Replaced the glob with an explicit `Feature Type → template` mapping table (literal filenames) that loads the matching reference checklist unconditionally, based on the detected stack. Validator now passes with zero warnings. (#42)
- **Cycle test execution respects the active mode (Debugger + Finalizer)** — the Debugger (Phase 7) and Finalizer (Phase 8) unconditionally asked the user to run tests/commit/audit, even inside a Standard-mode cycle where the Implementer auto-executes. This broke the auto-execution promise: a cycle ran tests automatically until a failure routed to the Debugger (or reached the Finalizer), which then stalled waiting for manual input. Aligned both with the Implementer's TDD procedure — the Debugger's Steps 2 (Reproduce), 4 (Commit), 5 (Verify) and the Finalizer's Step 2 (full-suite verification + dependency audit) now auto-execute in Standard/CI mode and fall back to asking the user in Pair mode (and, for the Debugger, standalone invocation), resolved via `devflow-ctl config get pair_mode` and the `CI` env var. The Orchestrator's Phase 8 health check now states this mode-aware expectation explicitly. `git push` / `gh pr create` remain never auto-executed.

---

## [2.10.0] — 2026-06-12

### ⚙️ Deterministic Enforcement — `devflow-ctl`

Gate verification, scope checks, iteration limits, locks, and rollback checkpoints are no longer LLM self-assessment — they are binary checks performed by a new CLI, working identically across all editor profiles (VS Code, Claude Code, opencode, Antigravity, generic).

### ✨ Added

- **Editor permission auto-configuration** — each editor profile now declares a `permissions` section (`strategy: json-merge | manual | none`) and install.sh merges a per-editor snippet (`editor-profiles/permissions/{id}.json`) into the editor's native settings file, so DevFlow actions (reading installed skills, writing `docs/devflow/*`, running `devflow-ctl` and read-only git) no longer prompt for confirmation. The merge is non-destructive: existing user values win and arrays are unioned, with a `.devflow-backup` copy kept. Claude Code → `~/.claude/settings.json` (`permissions.allow`), VS Code → user `settings.json` (`chat.tools.terminal.autoApprove`), opencode → `~/.config/opencode/opencode.json` (`permission.bash`); Antigravity prints a manual one-time instruction; generic is a no-op. `validate-framework.sh` gains a section validating every profile's permissions declaration and snippet JSON.
- **`devflow-ctl` CLI** (`shared/bin/devflow-ctl`) — deterministic session-state tool invoked by agents at every gate transition: `init`, `status`, `gate check/set`, `scope check/add`, `iterate`, `lock check/acquire/release`, `config`, `checkpoint`, `artifacts check`. Exit codes make checks incontestable; illegal state transitions (e.g., approving the Confirmation Gate while Validation is blocked) are rejected by the CLI itself.
- **Machine-readable session state** — `phase-state.md` now starts with a YAML frontmatter (schema v1: slug, mode, phase, gates, scope, iterations, checkpoints, lock) managed exclusively through `devflow-ctl`. The markdown body remains the human-readable session log.
- **Deterministic iteration limits** — `devflow-ctl iterate {loop}` increments counters and fails when the limit is exceeded, replacing manual loop counting (`implement_review`, `implement_debug`, `plan_revision`, `validation_brainstorm`).
- **Standalone agent sessions** — Feature Agent, Refactorer, and Bug-Fixer now initialize lightweight sessions (`init --mode {feature|refactor|bug-fix}`) with a `plan_approval` gate and scope enforcement, so standalone cycles get the same guarantees as the full lifecycle without requiring commits or branches.
- **Artifact completeness checks** — `devflow-ctl artifacts check {spec|plan|review|validation} {path}` validates required sections before phase transitions (used by the Finalizer health check).
- **Framework validation** — `validate-framework.sh` gains a `devflow-ctl integrity` section: script presence, executable bit, `bash -n`, and verification that every `devflow-ctl` subcommand referenced in skill files exists in the CLI dispatcher.

### 🔄 Changed

- **Orchestrator (`devflow`)** — Step 0 uses `devflow-ctl init`; the Validation and Confirmation Gates persist state via `gate set`; phase entries verify via `gate check`; loops route through `iterate`; checkpoints through `checkpoint set/get`.
- **Implementer** — verifies the Confirmation Gate with `gate check confirmation` before writing any code, and runs `scope check` before each file edit (Flow Artifacts always pass).
- **`rules.md`** — new canonical section "Deterministic Enforcement (`devflow-ctl`)" with the command table and execution policy: the CLI only touches session state, so it may be auto-executed in all modes, including Pair mode.
- **`memory-conventions.md`** — `phase-state.md` format documents the frontmatter schema; iteration counters and checkpoint tables moved from markdown into the frontmatter.
- **`install.sh`** — files under `shared/bin/` are copied verbatim (no tool/path substitutions, which would corrupt shell code) and keep their executable bit.

### 🔧 Fixed

- **Version sync** — Backfilled missing CHANGELOG entries for v2.7.5, v2.8.7, and v2.9.0 (the package version had moved ahead of the CHANGELOG). `install.sh` no longer hardcodes the version in the legacy-cleanup message (now read from `package.json`), and the README "What's new" section reflects the current release. `validate-framework.sh` gains a version-sync check so `package.json`, `package-lock.json`, and the CHANGELOG can no longer drift apart silently.

---

## [2.9.0] — 2026-06-10

### ✨ Added

- **Claude Code editor profile** (`editor-profiles/claude-code.yaml`) — installs DevFlow skills as global slash commands under `~/.claude/commands/`, with tool-name mappings (`Read`, `Write`, `Edit`, `Bash`) and `/memories` path removal (session state falls back to `docs/devflow/session/`). (#35)

---

## [2.8.7] — 2026-06-10

> Consolidates releases v2.8.5 and v2.8.6 (2026-05-23).

### ✨ Added

- **Validation Gate (Phase 1.5)** — A mandatory gate between Brainstormer and Architect where the Orchestrator challenges assumptions, scans against engineering standards, flags contradictions, and raises BLOCK/WARN findings before any design work. BLOCK findings require explicit user resolution (accept risks, revise, or cancel).
- **Framework robustness v2.2–v2.3** — Deterministic standards application (explicit BLOCK/WARN triggers with standard citations), agent self-validation steps, and the cross-cycle learning loop. (#34)
- **Standard mode auto-execution** — At the Confirmation Gate the user chooses Standard mode (auto-executes branch creation, tests, commits, and rollback SHAs) or Pair mode (interactive, user runs commands). Push and PR creation are never auto-executed in any mode. (#33)
- **Reverse Engineering Agent** (`/devflow-reverse`) — Analyzes undocumented projects and generates `AGENTS.md`, Stack Profile, and architecture specs. (#32)
- **Tutorial Agent** (`/devflow-tutorial`) — Interactive onboarding that walks new users through a complete DevFlow cycle. (#30)
- **Template Agent** (`/devflow-templates`) — Generates and maintains project-specific architecture templates from accumulated DevFlow artifacts. (#29)
- **Documentation Agent** (`/devflow-docs`) — Generates README, API docs, and CHANGELOG from DevFlow artifacts. (#31)
- **Contract Agent** (`/devflow-contract`) — Validates API endpoints against the architecture spec contract. (#27)
- **Migration Agent** (`/devflow-migrate`) — Database migration generation with forward/backward compatibility checks and zero-downtime strategies. (#26)

---

## [2.7.5] — 2026-05-22

> Consolidates releases v2.7.1 through v2.7.4 (2026-04-30 → 2026-05-22).

### ✨ Added

- **Pair Mode** — Interactive task-by-task approval during implementation (`DEVFLOW_PAIR=true` or chosen at the Confirmation Gate).
- **Performance Agent** (`/devflow-perf`) — Anti-pattern analysis, benchmark guidance, and optimization recommendations.
- **opencode editor profile** — Installation and tool mappings for the opencode CLI agent.
- **CI/CD mode** — Non-interactive execution when `CI=true`: auto-approvals, fail-fast iterations, auto-executed tests.
- **Memory locking** — Lightweight lock in `phase-state.md` preventing concurrent session writes, with stale-lock detection.
- **Git checkpointing & rollback** — Pre-phase SHAs recorded for safe rollback at cycle, implementation, and debug boundaries.
- **Traceability matrix** — Requirements → spec → tasks → tests → files cross-reference, enforced at the Finalizer health check.
- **Metrics tracking** — Per-cycle quality metrics persisted to `docs/devflow/metrics/`.
- **Artifact validation checklist** — Required-section checklists for spec, plan, and review documents.
- **Cross-cycle knowledge base** — `docs/devflow/knowledge-base/learnings.md` appended per cycle.
- **Spanish i18n** — Canonical Spanish translations for user-facing framework messages (`shared/i18n-es.md`).
- **Audit Command, Watch Command, layered test commands & monorepo Stack Profiles** — Extended stack detection and Definition of Done criteria.
- **Escalation logging** — Structured `## Escalation Log` recorded when iteration limits are exhausted.
- **AGENTS.md** — DevFlow's own agent architecture documentation.

### 🔄 Changed

- **UI Design standard overhauled** with comprehensive design principles. (#23)
- **Agent directories renamed** to remove redundant suffixes; install/uninstall globs tightened to `devflow/` and `devflow-*/`. (#21, #22)
- **Plan persistence before approval** for Refactorer, Feature Agent, and Bug-Fixer standardized via dedicated plan templates. (#20)

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
