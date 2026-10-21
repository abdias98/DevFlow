---
id: 009-review-intake-underrated
title: Bring an external PR review back into DevFlow after the cycle closed
complexity: routine
category: intake
threshold: 90
---

## Prompt

> `/devflow-review intake` — PR #42 (branch `feat/quote-header/stack-1`) was
> reviewed after its DevFlow cycle closed. The review and my replies are in
> `external-review.md`. Bring it back into DevFlow.

Seed the workspace first — `devflow-eval init 009-review-intake-underrated <dir>` —
then open the editor in `<dir>` with `DEVFLOW_HOME="<dir>/.devflow-home"`, so the
framework memory the run writes is scored with the workspace, and give this exact
prompt. When the agent proposes a classification, answer as the PR's author
would: confirm what matches the replies in `external-review.md`, correct what
does not. **Do not volunteer the classes** listed below.

There is no bare run for this task: without DevFlow there is no escape log,
cycle metric or framework memory to update. It measures the intake itself —
run it on each version that changes Intake Mode or `escape-analysis.md`.

## Definition of Done

- Every comment of the review is classified and recorded where it belongs.
- What the internal review should have seen is recorded against the cycle that
  approved the code.
- The cycle's metrics, its knowledge-base entry and the framework memory reflect it.

## What the checks probe

The workspace is a closed cycle (`quote-header`): spec, an APPROVED internal
review, metrics and a knowledge-base entry. The external review has four comments:

| # | Comment | Internal review | Expected |
|---|---------|-----------------|----------|
| 1 | Any seller can read a customer's tax id | Reported as INFO "deliberate", on the premise "same policy as `GET /orders/{id}`" — which the comment shows is false | **Underrated** → escape (`reviewer:*`) + backlog; the author accepting the risk does not cancel it |
| 2 | A missing company answers the order's 404, against the documented contract | Not reported | **Defect** → escape + backlog, although the author accepts the risk |
| 3 | Happy-path test does not assert `createdAt` | Not reported | **Defect** → escape (fixed) |
| 4 | `caller` may be undefined | — | **Disagreement** (the author's reply shows it cannot be) → nothing recorded |

Before Wave 25 the intake recorded only #3, against cycle `unknown`, and sent #1
and #2 to the backlog alone: the two lessons that mattered never reached the
framework.

## Calibration

`reference/naive/` is what the intake produced before Wave 25; `reference/correct/`
is the expected state. `tests/devflow-eval.bats` asserts that the fixture and the
naive reference fail and the correct one passes.

## Scoring

Needs only `bash`, `awk` and `grep`.
