---
id: 003-order-payment-lifecycle
title: Add pay and cancel operations to an order service
complexity: routine
category: behavior
project: backend
classes: state-transitions, side-effects, partial-failure, data-limits
threshold: 90
---

## Prompt

> Orders in this service can currently be created and read. Add two operations:
>
> - `POST /orders/:id/pay` charges the order amount through the existing
>   payments module and marks the order `paid`.
> - `POST /orders/:id/cancel` marks the order `cancelled`.
>
> An order can only be paid or cancelled while it is `pending`. Respond with the
> updated order on success and an appropriate error status otherwise. Cover the
> new behaviour with tests.

Seed the workspace first — `devflow-eval init 003-order-payment-lifecycle <dir>`
— then give this exact prompt to the run under evaluation: once through
`/devflow` (or `/devflow-feature`) and once as a bare prompt to the same model.
Score both workspaces.

**Do not add anything to the prompt.** In particular, do not mention the
scenarios in *What the checks probe* below: the task measures whether the run
discovers them on its own.

## Definition of Done

- Both operations exist and follow the stated lifecycle rule.
- Every successful payment corresponds to exactly one charge in the ledger, and
  no charge exists for an order that did not end up `paid`.
- Existing create/read behaviour is unchanged.
- Tests cover the new operations and the suite passes.

## What the checks probe

The prompt states a functional requirement. Most outcome weight sits on
behaviour that requirement **implies** but does not spell out — the defect
classes a correctness review is expected to find (see
`docs/devflow-audit-review-quality.md` §1.1):

| Class | Scenario |
|---|---|
| Repetition | Paying the same order twice |
| Transitions | Paying a cancelled order; cancelling a paid order |
| Partial failure | The payments module declines the charge (it rejects amounts above its provider limit — existing behaviour in `src/payments.js`) |
| Concurrency | Two payment requests for the same order at the same time — the charge is asynchronous |
| Data limits | Unknown order id |

## Calibration

`reference/naive/` is the straightforward implementation (guard, await the
charge, set status) with happy-path tests; `reference/correct/` claims the order
before awaiting and releases the claim on a declined charge. The checks are
calibrated so that the fixture alone, the naive reference and the correct
reference score clearly apart — `tests/devflow-eval.bats` asserts it.

## Scoring

Checks start the service with `EVAL_SERVE` (default `npm start --silent`) on an
isolated `EVAL_PORT`. Requires `node` ≥ 18, `curl` and `jq`.
