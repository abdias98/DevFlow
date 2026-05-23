# Reference Template: CLI Tool

> **This is a reference guide, not a rigid spec.** Adapt to the language and argument parsing library (commander, click, cobra, clap). Priority: AGENTS.md → project template → exploration → this reference.

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
| **Consistent output** | `--json` flag for machine-readable, default is human-readable |
| **Exit codes matter** | 0 = success, 1 = error, 2 = misuse. Scripts depend on this. |
| **--help everywhere** | Every command and subcommand has clear help text |
| **stdin/stdout pipeline** | Accept input from stdin, output to stdout. Compose with other tools. |

## Common Patterns

| Pattern | Example |
|---------|---------|
| **Command classes** | Each command is a class with `execute(args, flags)` method |
| **Config cascade** | Defaults → config file → env vars → CLI flags (flags win) |
| **Progress indicators** | Spinner for long operations, progress bar for batches |
| **Dry run** | `--dry-run` flag that shows what would happen without doing it |
| **Interactive prompts** | Confirm destructive actions. `--yes`/`-y` to skip (CI-friendly) |
| **Version** | `--version` prints semver from package.json/Cargo.toml/etc. |

## Common Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Silent failures (exit 0 on error) | Always use non-zero exit codes for errors |
| Hardcoded paths | Derive from config, env, or XDG conventions |
| Mixing output and logging | stdout = output, stderr = logs/diagnostics |
| No --help | Always provide usage text |
| Synchronous only | Support async operations with progress feedback |

## Test Architecture

| What | How |
|------|-----|
| Command behavior | Given flags → expect correct service called, correct output |
| Output formatting | Given data → expect correct format (JSON, table, plain) |
| Error handling | Given invalid input → expect non-zero exit, message on stderr |
| Integration | Spawn CLI process with args → check stdout, stderr, exit code |
