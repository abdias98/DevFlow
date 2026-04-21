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
- If `/memories/` is NOT available → use `docs/devflow/session/` as regular files instead.
- See [Memory Conventions](./memory-conventions.md) for paths and formats.

## File Persistence

- **ALWAYS use `create_file` to save artifacts** (specs, plans, mockups, reviews, debug logs). NEVER only show content in chat without saving the file.
- After saving a file, show a summary in chat with the file path.
- Artifact paths MUST strictly follow the individual conventions defined in [Memory Conventions](./memory-conventions.md) and their specific SKILL instructions.

## General

- Detect tech stack dynamically — read workspace config files (`package.json`, `*.csproj`, `composer.json`, `pyproject.toml`, `go.mod`, etc.).
- NEVER hardcode paths, tech stack names, or repo-specific conventions.
- Use `AGENTS.md` when present — if the project has one, read it first and skip redundant exploration.

## Scope-Locking

- **ONLY modify files explicitly requested by the user** or files that are a direct, mandatory dependency of the requested change.
- **NEVER make opportunistic changes** — if you notice a code smell in an unrelated file, mention it as an INFO note but do NOT fix it.
- **Before each file edit**, verify the file is within the approved scope.
- **If a change requires touching files outside the declared scope**, STOP and ask the user for explicit confirmation before proceeding.
- After completing work, list all files that were modified. If any file is outside the original scope, flag it clearly.

## Test Execution Policy

- **NEVER auto-run tests.** Agents MUST NOT execute test commands autonomously.
- When a test file is created (regression test, reproduction test), the agent MUST:
  1. Create the test file using `create_file`.
  2. Read the `## Stack Profile` from `context.md` to obtain `Test Command` and `Test Command (single file)`.
  3. If Stack Profile is not in session memory, perform [Quick Stack Detection](./stack-detection.md).
  4. Inform the user with the exact command to run, but **do not run it**:
     > "Test created at `{path}`. To verify, use `Test Command (single file)` with `{file}` replaced by `{path}`."
     > Example: if `Test Command (single file)` is `npx jest {file}`, run `npx jest {path}`.
- The test command is **always derived from the project's own configuration** — NEVER hardcoded.
