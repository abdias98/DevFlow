---
id: 004-project-panel-tab
title: Add a Tasks tab to a project panel's state layer
complexity: routine
category: behavior
threshold: 90
---

## Prompt

> The project panel (`src/panel.js`) currently has an Overview tab. Add a Tasks
> tab that shows the selected project's tasks, loaded with
> `api.getTasks(projectId)`. Follow the conventions of the Overview tab: expose
> its state as `tasks` with the same `{ status, data, error }` shape, and make it
> selectable with `selectTab('tasks')`. Cover the new behaviour with tests.

Seed the workspace first — `devflow-eval init 004-project-panel-tab <dir>` —
then give this exact prompt to the run under evaluation: once through `/devflow`
(or `/devflow-feature`) and once as a bare prompt to the same model. Score both
workspaces.

**Do not add anything to the prompt.** In particular, do not mention the
scenarios in *What the checks probe* below: the task measures whether the run
discovers them on its own.

## Definition of Done

- `selectTab('tasks')` shows the selected project's tasks in `getState().tasks`,
  with loading and error states like the Overview tab.
- The panel only ever shows tasks belonging to the currently selected project.
- The Overview tab keeps working.
- Tests cover the new tab and the suite passes.

## What the checks probe

`src/panel.js` is the framework-free state layer of a UI: the view renders
`getState()`. Checks drive it through `probe.js` (kept outside the workspace)
with a fake API whose responses are resolved by hand, so timing is
deterministic. Most outcome weight sits on behaviour the request **implies** but
does not spell out — the defect classes a correctness review is expected to find
(see `docs/devflow-audit-review-quality.md` §1.1):

| Class | Scenario |
|---|---|
| Side effects | A tab requests data only while it is active (the documented convention in `src/panel.js`) |
| Transitions | Switching project while on the Tasks tab |
| Ordering | The response for a previous selection arrives after the current one |
| Partial failure | The request for the new selection fails after a successful one |

The Overview tab — which the prompt says to follow — does not guard against
out-of-order responses. Copying the convention faithfully therefore copies that
flaw too: the task also measures whether the run notices a defect in the pattern
it was told to follow instead of propagating it.

## Calibration

`reference/naive/` mirrors the Overview tab exactly; `reference/correct/` uses a
single loader that discards superseded responses. The checks are calibrated so
that the fixture alone, the naive reference and the correct reference score
clearly apart — `tests/devflow-eval.bats` asserts it.

## Scoring

Requires `node` ≥ 18. No service is started.
