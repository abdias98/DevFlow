# Code Review: Project Panel Tasks Tab

**Date:** 2026-09-20
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** Standalone (invoked by Feature Agent)
**Invoking Agent:** Feature Agent
**Reference:** `docs/devflow/features/2026-09-20-project-tasks-tab-feature.md`

## Summary

The Tasks slice mirrors the Overview conventions and adds the reset-before-load and latest-request guard that `state-lifecycle.md` requires; every traced sequence (project change, repeated tab select, late success/failure) behaves correctly and is pinned by a test. No blocking findings.

## Findings

> **Evidence** is `{standard}.md §{N}` or `scenario: {precondition} → {sequence} → observed {X}, expected {Y} per {source}` — see rules.md → Finding Evidence.

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| — | — | — | none | — | — |

### 🟡 WARN (should fix)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| — | — | — | none | — | — |

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 1 | src/panel.js | 39-64 | `loadOverview` and `loadTasks` are now near-identical loaders that differ only by the guard; the divergence is recorded in the feature report | `design-principles.md §1` → INFO (below rule of three; extraction premature) | Extract a shared guarded `loadSlice` when a third tab arrives; fixing the Overview guard (backlog D1) is the natural moment |
| 2 | src/panel.js | 60 | The catch branch drops a superseded request's error with no comment at that line; the reason is only stated at the counter declaration (:27) | `error-handling.md §2` (intentional ignore should state why) → INFO; scenario impact none: the stale error is unobservable by design per `state-lifecycle.md §6` | Add a one-line comment at :57/:60, e.g. `// superseded: a newer request owns this slice` |
| 3 | src/panel.js | 39-48 (pre-existing) | `loadOverview` has no superseded-result guard: Overview active, `selectProject('p1')`, `selectProject('p2')`, p1 resolves last → p1's overview stored while p2 is selected | scenario: as stated → observed `state.overview` = p1 data at :44, expected p2 data per `state-lifecycle.md §6`; not part of this diff | Already deferred: `devflow-ctl backlog` D1 (info). Not a regression of this change |

### ❓ Open Questions
- src/panel.js:56 — `api.getTasks` has no panel-level timeout, so a hung request leaves `tasks` at `loading` until a newer request supersedes it. Defect only if the injected api does not enforce its own timeout (`integration-consumption.md §1`); check the api implementation, which is outside this repository.

## Correctness & Behavior — walk-through

Blind pass recorded before the feature report was re-read for this review. Units inventoried: `loadTasks`, `loadActiveTab`, `selectProject`, `selectTab`, `getState` (state: `tasks` slice + `tasksRequest` counter; side effect: `api.getTasks(projectId)` + subscriber emits; consumers: the view via `getState`/`subscribe`, and tests).

Scenarios traced (all behave as expected): p1→p2 with p1 resolving last (:57 drops); p1 failing after p2 selected (:60 drops); repeated `selectTab('tasks')` with older response last; `selectProject(null)` while a request is pending (counter bump at :84 drops it); project replaced while Overview active (counter bump, slice idle); superseded result emits nothing; synchronous throw from `getTasks` is caught by the same try.

Test adequacy (mutation reasoning): removing :57 or :60 fails tests 13-16; removing :84 fails test 18; removing :83 fails test 18; dropping the `tasks` copy in `getState` fails test 12; removing the `'tasks'` dispatch or `TABS` entry fails tests 5-11; passing the wrong id to `getTasks` fails test 6. No surviving mutation on a behavior-relevant path.

Contrast pass: findings 1-3 are implementation/deliberate-decision items, none contradict the plan or the DoD; no plan gap identified.

## Coverage

> What this review actually examined. An APPROVED verdict is only as strong as this section: a dimension, standard or consumer that is not listed here was not reviewed.

| Dimension | Ran? | Standards loaded in full | Notes |
|-----------|------|--------------------------|-------|
| 1 — Security & Safety | ✅ (inline) | security.md quick-card triggers scanned (no external input, secrets, queries); error-handling.md | no security surface |
| 2 — Performance, Concurrency & Data | ✅ (inline) | concurrency.md, state-lifecycle.md; performance.md not loaded in full: no data access, loops or caching in the diff | data persistence n/a |
| 3 — Architecture & Design | ✅ (inline) | design-principles.md, testing.md; solid.md / clean-architecture.md / project-design.md scanned via quick card | Reference implementation compared: `src/panel.js` Overview slice and existing `test/panel.test.js` style |
| 4 — Correctness & Behavior | ✅ (inline, blind-first order) | — | Consumers read: none in repo besides tests (searched `grep createProjectPanel` — only `test/panel.test.js`); scenarios walked: 8; open questions: 1 |
| 5a — Interfaces | ✅ | integration-consumption.md (injected `api.getTasks`) | timeout question recorded as Open Question |
| 5b/5c/5d | ⏭ no trigger | — | no UI, logs, manifests or new abstraction |

- **Review path:** inline (deviation: the diff shows signals S1, S2, S3, S4, so the skip criteria were not met and the skill calls for parallel subagents; this run used the skill's sequential fallback instead, in a session where spawning further subagents was not authorised — the Correctness & Behavior blind pass therefore was not isolated from the author's context, which weakens its independence) — **diff signals present:** S1, S2, S3, S4
- **Deterministic checks:** `scan all` clean (semgrep SAST skipped: not installed) · `scope audit` clean · `traceability check` file missing (Feature Agent cycles do not generate one)
- **Visual diff:** skipped — no UI, no mockup
- **Runtime verification:** skipped — rigor `standard`
- **Git conventions:** branch `feat/project-tasks-tab`; commits `feat(panel): add Tasks tab loading api.getTasks` and `feat(panel): ignore superseded Tasks responses` — scoped, imperative, one concern each (`git-conventions.md §1, §2`) ✅
- **Not covered:** the real `api` implementation and the view (not in this repository)

## Verdict
✅ APPROVED — no blockers
