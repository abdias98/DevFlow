---
id: 006-config-env-overrides
title: Let environment variables override a configuration file
complexity: routine
category: behavior
project: library
classes: caller-contract, data-limits
threshold: 90
---

## Prompt

> `loadConfig()` reads `config.json` and the server setup in `src/server.js`
> uses the result. Let the environment variables `HOST`, `PORT` and `DEBUG`
> override the corresponding values from the file. Cover the new behaviour with
> tests.

Seed the workspace first — `devflow-eval init 006-config-env-overrides <dir>` —
then give this exact prompt to the run under evaluation: once through `/devflow`
(or `/devflow-feature`) and once as a bare prompt to the same model. Score both
workspaces.

**Do not add anything to the prompt.** In particular, do not mention the
scenarios in *What the checks probe* below: the task measures whether the run
discovers them on its own.

## Definition of Done

- With no variable set, the values in the file apply as before.
- `HOST`, `PORT` and `DEBUG` each override their value from the file.
- What `loadConfig()` returns is still accepted by the server setup that
  consumes it.
- Tests cover the overrides and the suite passes.

## What the checks probe

`loadConfig()` has a consumer: `src/server.js` validates the shape of what it
receives. Checks drive both through `probe.js` (kept outside the workspace),
setting `process.env` and passing the loader's result to the real server setup.
Most outcome weight sits on behaviour the request **implies** but does not spell
out — the defect classes a correctness review is expected to find (see
`docs/devflow-audit-review-quality.md` §1.1):

| Class | Scenario |
|---|---|
| Caller contract | An environment value is always a string, but the server needs `port` as a number |
| Caller contract | `DEBUG=false` must give `debug: false` — the string `'false'` is truthy, and the file says `debug: true`, so a wrong conversion leaves debugging silently on |
| Data limits | A `PORT` that is not a number is rejected, not turned into `NaN` |

The `DEBUG` scenario is the quiet one: converting with `Boolean(env.DEBUG)`
produces a valid boolean, the server accepts it, nothing throws — and the
override does the opposite of what was asked.

## Calibration

`reference/naive/` converts `PORT` correctly but `DEBUG` with `Boolean()`;
`reference/correct/` parses `DEBUG` explicitly. The checks are calibrated so
that the fixture alone, the naive reference and the correct reference score
clearly apart — `tests/devflow-eval.bats` asserts it.

## Scoring

Requires `node` ≥ 18. No service is started.
