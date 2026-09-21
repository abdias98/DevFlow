# Eval baselines — history 4.10.0 → 4.14.1

One file per DevFlow version records what the eval harness measured for it.
This page is the index: which tasks exist, how each one calibrates, and — the
part that matters — which versions actually have **run** scorecards and which
only have calibration.

> **Read this before quoting a number.** Calibration and run scorecards answer
> different questions. *Calibration* scores the task's own reference
> implementations and proves the checks discriminate; it does not depend on the
> framework version. A *run scorecard* scores what a model actually produced
> through `/devflow-feature` or a bare prompt; only that can show whether a
> framework version changed an outcome.

## 1. The behavioural suite

Six behavioural tasks, four project types, all six defect classes the
Correctness & Behavior dimension is built around
(`devflow-review/correctness-guide.md`). `tests/devflow-eval.bats` asserts the
coverage, so removing or retyping a task shows up as a failing test.

| Task | Project | Defect classes probed | Fixture | Naive reference (misses) | Correct reference |
|------|---------|-----------------------|:-------:|--------------------------|:-----------------:|
| `003-order-payment-lifecycle` | backend | state transitions, side effects, partial failure, data limits | 3/18 = 16% | 15/18 = 83% — `[concurrency]` | 18/18 = 100% |
| `004-project-panel-tab` | ui | state transitions, side effects, partial failure | 2/17 = 11% | 14/17 = 82% — `[ordering]` | 17/17 = 100% |
| `005-stats-median-cli` | cli | **logic**, data limits | 3/16 = 18% | 13/16 = 81% — `[logic]` numeric ordering | 16/16 = 100% |
| `006-config-env-overrides` | library | **caller contract**, data limits | 3/14 = 21% | 11/14 = 78% — `[caller contract]` `DEBUG=false` | 14/14 = 100% |
| `007-notes-import-cli` | cli | partial failure, data limits | 3/13 = 23% | 10/13 = 76% — `[partial failure]` atomic import | 13/13 = 100% |
| `008-customer-lookup-cache` | backend | state transitions, side effects, partial failure | 3/15 = 20% | 12/15 = 80% — `[state transitions]` cache key | 15/15 = 100% |

Tasks `001` and `002` are routine first-shot work and are not part of the
behavioural suite (see `eval/README.md`).

Each naive reference fails **exactly one** outcome check — the one it was written
to miss — and `tests/devflow-eval.bats` asserts that too. A task whose naive
reference failed several checks would not say *which* class a run missed.

## 2. Versions

| Version | Wave | What changed in the framework | Tasks calibrated | Run scorecards |
|---------|------|-------------------------------|:----------------:|:--------------:|
| [4.10.0](./4.10.0.md) | — | Reference point, before any Wave 18 change | 003, 004 | none — pending |
| [4.11.0](./4.11.0.md) | 18 | Review: Correctness & Behavior dimension, scenario evidence, Behavioral Impact Severity | 003, 004 | none — pending |
| [4.12.0](./4.12.0.md) | 19 | Upstream: Behavior Scenarios in spec/plan, Implementer handles missing cases, standards loaded by domain | 003, 004 | 003, 004 (self-run — did not reproduce blind, see below) |
| [4.13.0](./4.13.0.md) | 20 | Coverage: four new standards (state lifecycle, integration consumption, data persistence, design patterns) | 003, 004 | none — see note |
| [4.14.0](./4.14.0.md) | 21 | Escape analysis; `runtime` verification primitive | 003–008 (005–008 added after the release) | **003–008** (blind, 12 runs) |
| [4.14.1](./4.14.1.md) | — | No framework change; eval suite completed to six tasks and the first blind runs recorded | 003–008 | 003–008 (as 4.14.0 — same framework) |

Calibration for a task is the same on every version — it scores the task's own
references, not the framework — so the fixture/naive/correct columns in §1 hold
for any version that ships the task. What a version row can add is a run
scorecard.

## 3. Recorded run scorecards

Two sets exist.

**4.12.0 — tasks 003, 004.** Claude (Sonnet 5) driving the installed
`devflow-feature` skill. A self-run, not a blind evaluation: the same session that
designed the tasks executed and scored them (`4.12.0.md` §2). **Not reproduced:**
re-run blind (below), the bare runs score 100%.

| Task | `/devflow-feature` outcome | Bare outcome (self-run) | Check the bare run missed |
|------|:--------------------------:|:-----------------------:|---------------------------|
| `003-order-payment-lifecycle` | 18/18 = 100% | 15/18 = 83% | `[concurrency]` two simultaneous payments charge once |
| `004-project-panel-tab` | 17/17 = 100% | 14/17 = 82% | `[ordering]` a late response for an old selection is ignored |

**4.14.0 — all six behavioural tasks.** Twelve fresh subagents with no context,
each given only the task's exact prompt; same model; blindness verified from the
transcripts (`4.14.0.md` §2).

| Task | `/devflow-feature` outcome | Bare outcome |
|------|:--------------------------:|:------------:|
| `003-order-payment-lifecycle` | 18/18 = 100% | 18/18 = 100% |
| `004-project-panel-tab` | 17/17 = 100% | 17/17 = 100% |
| `005-stats-median-cli` | 16/16 = 100% | 16/16 = 100% |
| `006-config-env-overrides` | 14/14 = 100% | 14/14 = 100% |
| `007-notes-import-cli` | 13/13 = 100% | 13/13 = 100% |
| `008-customer-lookup-cache` | 15/15 = 100% | 15/15 = 100% |

Every bare run avoided the trap its task was built around. The `/devflow-feature`
runs cost about 4.4× the tokens and ~17× the wall time for the same outcome.

## 4. What this table cannot say

- **It does not show an improvement over 4.10.0.** 4.10.0 and 4.11.0 have no run
  scorecards, so there is nothing to compare later versions against.
- **It shows no benefit from DevFlow on any task — and cannot.** A model that
  passes every task bare leaves no room for the framework to add outcome. That is
  a property of these tasks for this model, not evidence about DevFlow in general.
  It also retracts the 4.12.0 reading: the bare failures on 003/004 were a
  self-run artefact.
- **One run per cell.** A single 100% cannot be told from a lucky one; no variance
  is measured.
- **One model.** A weaker model may separate the runs.
- **It says nothing about Waves 20 and 21.** Neither the four Wave 20 standards
  nor escape analysis and runtime verification were run against a task designed
  to need them.
- **Escape rate needs real cycles.** `devflow-ctl metrics aggregate` computes it
  from escapes recorded after real approvals; no baseline snapshot can simulate
  that.

## 5. Adding a version row

1. Re-run calibration (`bats tests/devflow-eval.bats`) on the release tree and
   record it in `<version>.md`.
2. For a run scorecard, follow `eval/README.md` → *Comparing versions*: same
   tasks, same prompts, **same model and editor**, DevFlow reinstalled from the
   version's commit. Store the artifacts under `runs/<version>/`.
3. Add the row above, marking scorecards `none` unless real runs are stored.
