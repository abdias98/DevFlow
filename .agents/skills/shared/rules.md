# DevFlow — Common Rules

These rules apply to ALL DevFlow sub-agents. Every SKILL.md references this file.

## Language

- **Always respond in the user's language.** Detect from their message. If the user writes in Spanish, respond in Spanish. If English, respond in English.

## Tool Compatibility

- If `vscode_askQuestions` is available → use it for interactive questions.
- If `vscode_askQuestions` is NOT available → **ask the questions directly in your chat response and STOP. Wait for the user to answer before continuing.**
- **NEVER skip a question, gate, or confirmation because a tool is unavailable.** Always find an alternative way to ask.

## Memory Fallback

- If `/memories/` is available → use it for session state (preferred).
- If `/memories/` is NOT available → use `docs/devflow/session/{slug}/` as regular files instead.
- See [Memory Conventions](./memory-conventions.md) for paths, formats, and **lock rules**.
- **Before reading or writing session memory**, check `phase-state.md` for an active lock (`Locked By`). If locked by another agent, do NOT write — report to the user.
- Standalone agents (Refactorer, Bug-Fixer, Feature Agent) MUST check the lock before touching session memory. If a lifecycle cycle is active, recommend waiting or using full `/devflow` cycle instead.

## File Persistence

- **ALWAYS use `create_file` to save artifacts** (specs, plans, mockups, reviews, debug logs). NEVER only show content in chat without saving the file.
- After saving a file, show a summary in chat with the file path.
- Artifact paths MUST strictly follow the individual conventions defined in [Memory Conventions](./memory-conventions.md) and their specific SKILL instructions.
- **Ensure the target directory exists** before writing. If `create_file` fails due to missing directory, attempt to create the directory using available tools, or report the failure clearly.

## General

- Detect tech stack dynamically — read workspace config files (`package.json`, `*.csproj`, `composer.json`, `pyproject.toml`, `go.mod`, etc.).
- **Save detected stack** to `context.md` under `## Stack Profile` so subsequent steps and other agents can reuse it.
- NEVER hardcode paths, tech stack names, or repo-specific conventions.
- Use `AGENTS.md` when present — if the project has one, read it first and skip redundant exploration.
- **Engineering standards** are versioned (see `shared/standards/CHANGELOG.md`). Each standard declares its version in the file header. When proposing changes to standards, follow the version policy.

## Template Variables

Skill files use template variables that are resolved at install time by `install.sh`. These are NOT runtime variables — they are replaced with actual paths during installation.

| Variable | Resolves to | Example |
|----------|------------|---------|
| `{{SKILLS_DIR}}` | Installed skills directory | `~/.agents/skills` |
| `{{AGENTS_DIR}}` | Installed agents directory | `~/.agents` |
| `{{PROMPTS_DIR}}` | Installed prompts directory | `~/.agents/prompts` |
| `{{INSTR_DIR}}` | Installed instructions directory | `~/.agents/instructions` |

**Usage:** Only use `{{SKILLS_DIR}}` in skill file **path references** (e.g., `<{{SKILLS_DIR}}/shared/rules.md>`). Never use them in code snippets, commands, or runtime logic. When editing a skill file in the source repository, write `{{SKILLS_DIR}}` — the install script handles substitution for each editor profile.

## Scope-Locking

- **ONLY modify files explicitly requested by the user** or files that are a **direct, hard dependency** of the requested change. A direct dependency is one that, if not updated, would cause the in-scope change to fail compilation or break the build in an obvious way. Examples: renaming a method requires updating immediate callers within the same module; changing a type signature requires updating direct references. It does NOT include: restructuring project folders, updating DI registrations, modifying base classes that affect many unrelated modules, or “improving” nearby code.
- **NEVER make opportunistic changes** — if you notice a code smell in an unrelated file, mention it as an INFO note but do NOT fix it.
- **Before each file edit**, verify the file is within the approved scope.
- **If a change requires touching files outside the declared scope**, STOP and ask the user for explicit confirmation before proceeding. Wait for the user's response — do not assume consent.
- **Exception: Flow Artifacts.** Files created by a skill as part of its required procedure (plans, reports, specs, refactor summaries, bug-fix reports, and any other artifact whose path is defined in Memory Conventions) are always allowed, even if the user's declared scope did not include them. These are not subject to the scope-locking restriction.
- After completing work, list all files that were modified. If any file is outside the original scope, flag it clearly and explain why it was necessary.

## Test Execution Policy

- **NEVER auto-run tests.** Agents MUST NOT execute test commands autonomously.
- **Test file creation must respect scope and approval:**
  - If the skill's procedure requires a regression test, include it in the plan and wait for user approval before creating the test file, unless the test file is already within the user-declared scope.
  - When a test file is created, the agent MUST:
    1. Create the test file using `create_file`.
    2. Read the `## Stack Profile` from `context.md` to obtain `Test Command` and `Test Command (single file)`.
    3. If Stack Profile is not in session memory, perform [Quick Stack Detection](./stack-detection.md).
    4. Inform the user with the exact command to run, but **do not run it**:
       > "Test created at `{path}`. To verify, use `Test Command (single file)` and replace `{file}` with that same `{path}` value."
       > Example: if `Test Command (single file)` is `npx jest {file}`, run `npx jest {path}`.
- The test command is **always derived from the project's own configuration** — NEVER hardcoded.

## Approval & Confirmation

- **Any change outside the declared scope requires explicit user confirmation.** This includes renaming public APIs, modifying configuration files, updating dependencies, or altering folder structure.
- **Do not proceed with a plan that includes out-of-scope changes until the user explicitly approves those specific changes.**
- Present options clearly and wait for the user's selection. Do not time out or assume a default.

## CI/CD Mode

DevFlow supports non-interactive execution for CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins, etc.).

### Detection
CI mode is active when the environment variable `CI=true` is set. This is the standard convention across all major CI platforms.

### Behavior changes in CI mode

| Rule | Normal Mode | CI Mode |
|------|-------------|---------|
| Confirmation Gate | Wait for user approval | Auto-approve plan |
| Spec approval | Ask user | Auto-accept |
| Test execution | Tell user the command | Auto-run tests |
| Interactive questions | Ask user | Use defaults or skip |
| Iteration loops | Max 3 | Max 1 (fail fast) |
| Error handling | Ask user how to proceed | Log error and exit |
| Git commands | Tell user to run | Auto-execute (branch, commit) |
| Rollback | Tell user to run | Skip rollback (fail fast) |

### CI configuration (environment variables)

| Variable | Default (CI) | Effect |
|----------|:------------:|--------|
| `CI` | `true` | Enables CI mode auto-detection |
| `DEVFLOW_AUTO_APPROVE` | `true` | Auto-approve plan and spec |
| `DEVFLOW_FAIL_FAST` | `true` | Exit on first error, max 1 iteration |
| `DEVFLOW_MAX_ITERATIONS` | `1` | Override max iteration loops |

### Agent responsibilities in CI mode

1. **Orchestrator:** Detect CI mode at Step 0. Skip the Confirmation Gate (auto-approve). Reduce max iterations to 1.
2. **Brainstormer:** Skip clarifying questions. Infer from context or use reasonable defaults.
3. **Architect:** Auto-accept spec without user confirmation.
4. **Implementer:** Auto-run tests after each task (exception: `run_in_terminal` / `bash` is allowed). Report results inline.
5. **Reviewer:** Normal behavior — still classifies BLOCK/WARN/INFO.
6. **Debugger:** Skip. If tests fail, report error and exit.
7. **Finalizer:** Normal behavior — save summary and clean session memory.

## INFO Notes & Violation Reporting

- When a code smell, architectural violation, or potential improvement is found in a file outside the scope, add an INFO note following this format:
  - **In code:** a comment starting with `// INFO:` (or language‑appropriate comment) briefly describing the issue and the recommended fix.
  - **In plans/reports:** a bullet under a dedicated `## Observations` section.
- INFO notes must never modify behavior; they only inform.

## Error Handling & Communication

- If a required file path does not exist, ask the user for clarification or provide alternatives. Do not guess or skip the step.
- If a tool fails (e.g., `create_file` returns an error), report the failure to the user, explain what was attempted, and suggest a fallback if possible.