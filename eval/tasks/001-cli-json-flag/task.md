---
id: 001-cli-json-flag
title: Add a --json output flag to an existing CLI
complexity: routine
category: cli
threshold: 80
---

## Prompt

> Add a `--json` flag to the project's CLI. When passed, the command must print
> its result as a single JSON object to stdout (and nothing else), so the output
> can be piped into `jq`. Without the flag, behaviour is unchanged. Cover it with
> a test.

Give this exact prompt to the run under evaluation — once through `/devflow`
(or the relevant standalone agent) and, for the baseline, once through a bare
prompt to the same model with no framework. Then score both result workspaces.

## Definition of Done

- A `--json` flag exists and is documented in the CLI help.
- With `--json`, stdout is a single valid JSON object and nothing else.
- Default (no flag) output is unchanged.
- A test exercises the JSON path and the project test suite passes.

## Scoring

Checks live in `checks.sh`. They assume the CLI entrypoint is discoverable via
`package.json` `bin`/`scripts` or a `./bin/` script — adjust the entrypoint
variable at the top of `checks.sh` for the target project before running.
