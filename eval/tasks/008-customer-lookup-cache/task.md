---
id: 008-customer-lookup-cache
title: Cache customer lookups in a service over a slow store
complexity: routine
category: behavior
project: backend
classes: state-transitions, side-effects, partial-failure
threshold: 90
---

## Prompt

> `getCustomer` in `src/customers.js` is slow because every call reads the
> store. Cache the lookups so that asking for the same customer again does not
> go to the store. Cover the new behaviour with tests.

Seed the workspace first — `devflow-eval init 008-customer-lookup-cache <dir>` —
then give this exact prompt to the run under evaluation: once through `/devflow`
(or `/devflow-feature`) and once as a bare prompt to the same model. Score both
workspaces.

**Do not add anything to the prompt.** In particular, do not mention the
scenarios in *What the checks probe* below: the task measures whether the run
discovers them on its own.

## Definition of Done

- Asking for the same customer twice reads the store once.
- What `getCustomer` returns is the same as it would be without the cache — after
  updates, and for every way the customer can be asked for.
- Existing lookup behaviour is unchanged.
- Tests cover the cache and the suite passes.

## What the checks probe

`src/customers.js` is a service over an injected store. Checks drive it through
`probe.js` (kept outside the workspace) with a fake store that counts its calls
and can be made to fail, so what the cache does is directly observable. Most
outcome weight sits on behaviour the request **implies** but does not spell out —
the defect classes a correctness review is expected to find (see
`docs/devflow-audit-review-quality.md` §1.1):

| Class | Scenario |
|---|---|
| Side effects | A repeated lookup is served without a second store read |
| State transitions | An update, or archiving, is visible to the next lookup — a cache must be invalidated by the operations that change what it holds |
| State transitions | `getCustomer(id)` and `getCustomer(id, { includeArchived: true })` are different questions with different answers — a cache keyed by `id` alone answers the second with the first |
| Partial failure | A store read that fails is not remembered: the next call tries again |

The key scenario is the quiet one: with the obvious `Map` keyed by `id`, every
example that uses one option at a time passes, and the wrong answer only appears
when the same customer is asked for both ways.

## Calibration

`reference/naive/` caches the caller's view of the customer keyed by `id`;
`reference/correct/` caches the record the slow call returns and applies the
option afterwards. The checks are calibrated so that the fixture alone, the
naive reference and the correct reference score clearly apart —
`tests/devflow-eval.bats` asserts it.

## Scoring

Requires `node` ≥ 18. No service is started.
