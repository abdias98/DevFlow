# Reference Template: CLI Tool

> **This is a reference guide, not a rigid spec.** Adapt to the language and argument parsing library (commander, click, cobra, clap). Priority: AGENTS.md → project template → exploration → this reference.
>
> **Project-specific idioms win.** When `docs/devflow/knowledge-base/standards-profile.md` exists, it records how *this* project actually expresses each pattern, with real files. Use this reference only to know what to look for; generate the profile with `/devflow-templates standards-profile`.

## Typical Structure

```
src/
├── commands/         # One file per command/subcommand
├── services/         # Business logic shared across commands
├── config/           # Config file parsing, env vars, defaults
├── output/           # Output formatters: table, JSON, plain text, colored
├── utils/            # Pure utilities: validators, transformers
└── cli.js            # Entry point: argument parsing, command dispatch

tests/
├── commands/         # Test each command's behavior
├── services/         # Unit test business logic
└── integration/      # Test CLI end-to-end (spawn process, check stdout/stderr/exit code)
```

## Design Principles

| Principle | Why |
|-----------|-----|
| **Single binary / entry point** | One command to install, one command to run |
| **Subcommand structure** | `tool [global-flags] <command> [command-flags] [args]` |
| **stdin/stdout pipeline** | Accept input from stdin, output to stdout. Compose with other tools. |
| **User-facing behavior** | Help, output streams and formats, color, prompts, confirmations, dry-run, exit codes and secrets are normative in [user-experience.md §10](../standards/user-experience.md) — the Reviewer applies it; this template does not restate it |

## Common Patterns

| Pattern | Example |
|---------|---------|
| **Command classes** | Each command is a class with `execute(args, flags)` method |
| **Config cascade** | Defaults → config file → env vars → CLI flags (flags win) |
| **Version** | `--version` prints semver from package.json/Cargo.toml/etc. |

## Common Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Hardcoded paths | Derive from config, env, or XDG conventions |
| Ignoring the user-facing rules | Exit 0 on error, results mixed with diagnostics, no `--help`, required prompts — see `user-experience.md §10` |

## Test Architecture

| What | How |
|------|-----|
| Command behavior | Given flags → expect correct service called, correct output |
| Output formatting | Given data → expect correct format (JSON, table, plain) |
| Error handling | Given invalid input → expect non-zero exit, message on stderr |
| Integration | Spawn CLI process with args → check stdout, stderr, exit code |
