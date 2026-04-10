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
- Artifact paths follow the convention: `docs/devflow/{type}/YYYY-MM-DD-{slug}-{name}.{ext}`

## General

- Detect tech stack dynamically — read workspace config files (`package.json`, `*.csproj`, `composer.json`, `pyproject.toml`, `go.mod`, etc.).
- NEVER hardcode paths, tech stack names, or repo-specific conventions.
- Use `AGENTS.md` when present — if the project has one, read it first and skip redundant exploration.
