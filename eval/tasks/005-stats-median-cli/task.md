---
id: 005-stats-median-cli
title: Add a median command to a statistics CLI
complexity: routine
category: behavior
project: cli
classes: logic, data-limits
threshold: 90
---

## Prompt

> The `stats` CLI computes `sum`, `mean` and `max` over the numbers it is given.
> Add a `median` command: `stats median 3 1 2` prints `2`. Cover the new
> behaviour with tests.

Seed the workspace first — `devflow-eval init 005-stats-median-cli <dir>` — then
give this exact prompt to the run under evaluation: once through `/devflow` (or
`/devflow-feature`) and once as a bare prompt to the same model. Score both
workspaces.

**Do not add anything to the prompt.** In particular, do not mention the
scenarios in *What the checks probe* below: the task measures whether the run
discovers them on its own.

## Definition of Done

- `stats median <numbers...>` prints the median of the numbers given.
- The command behaves like the existing ones for empty and invalid input.
- The existing commands are unchanged.
- Tests cover the new command and the suite passes.

## What the checks probe

`bin/stats.js` is a real executable. Checks drive it through `probe.js` (kept
outside the workspace) as a child process and inspect stdout, stderr and the exit
code. Most outcome weight sits on behaviour the request **implies** but does not
spell out — the defect classes a correctness review is expected to find (see
`docs/devflow-audit-review-quality.md` §1.1):

| Class | Scenario |
|---|---|
| Logic | An even count has no middle value — the median is the mean of the two middle ones |
| Logic | Numbers are ordered as numbers: `[10, 9, 100]` sorted as text puts `100` in the middle |
| Data limits | No numbers, and a non-numeric argument, follow the convention already in `src/commands.js` and `src/parse.js` — a usage error naming the problem, never `NaN` |

The numeric-ordering scenario is the one a reflexive `.sort()` gets wrong: it
passes every example small enough to be a single digit.

## Calibration

`reference/naive/` sorts with the default comparator; `reference/correct/`
sorts numerically. The checks are calibrated so that the fixture alone, the
naive reference and the correct reference score clearly apart —
`tests/devflow-eval.bats` asserts it.

## Scoring

Requires `node` ≥ 18. No service is started.
