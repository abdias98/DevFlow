## ⚡ Feature Plan: project-tasks-tab

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript · none · node:test
**Rigor:** standard — routine change: one state slice mirroring an existing one, two files

### Plan Digest

- **Tasks:** 2 tasks
- **Files to create:** none
- **Files to modify:** `src/panel.js`, `test/panel.test.js`
- **Key dependencies:** Task 2 builds on Task 1
- **Test strategy:** unit tests per task with a fake api; Task 2 adds in-flight sequence tests (superseded results)
- **Scope:** Overview behavior, the api module and any rendering are out of scope

### Summary

**Goal:** Add a Tasks tab to the project panel that loads `api.getTasks(projectId)` into a `tasks` slice with the Overview conventions.

**Definition of Done:**
- [ ] 1. `selectTab('tasks')` is accepted; `getState().tasks` is `{ status, data, error }`, initially `idle`.
- [ ] 2. With a project selected and Tasks active, `api.getTasks(projectId)` is called with the selected id; state goes `loading` then `ready` (data) or `error` (error).
- [ ] 3. Tasks load only when the Tasks tab is active and a project is selected; selecting a project resets `tasks`.
- [ ] 4. `npm test` passes with new tests covering the above.

### Scope

- **In:** `src/panel.js` (TABS, `tasks` slice, `loadTasks`, dispatch in `loadActiveTab`, reset in `selectProject`, copy in `getState`); `test/panel.test.js`.
- **Out:** Overview behavior (including its missing in-flight guard, deferred to backlog), rendering, task mutation/filter/pagination.

### Reference Implementation

- **File/Pattern:** `src/panel.js` Overview slice — `emptySlice()`, `loadOverview`, `loadActiveTab`; `test/panel.test.js` — `fakeApi`, `tick`, `node:test` style.

### Affected Files

**Create:** none

**Modify:**
- `src/panel.js` — Tasks slice and loader
- `test/panel.test.js` — new tests

### Standards constraints (applied)

- `state-lifecycle.md` §4, §6, §7 — reset `tasks` in `selectProject` before loading; tag each tasks request and apply only the latest; load only when Tasks is the active tab.
- `error-handling.md` §2 — a failed request is stored as the `error` state (surfaced), never swallowed.
- `design-principles.md` §1, §5 — mirror `loadOverview`; two similar loaders is below the rule of three, so no shared helper yet.
- `testing.md` §2, §9 — behavior-level assertions; each test seen failing for the right reason first.
- `concurrency.md` §4 — the async result is always observed (awaited inside try/catch).

### Behavior Scenarios

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|
| S1 | Tasks active, p1 tasks request pending | select p2, then p1's request resolves after p2's | state shows p2's tasks; p1's never appear | Task 2 | `test/panel.test.js` |
| S2 | Tasks active, p1 tasks request pending | p1's request fails after select p2 | `tasks` is not `error`; p2's data stands | Task 2 | `test/panel.test.js` |
| S3 | Tasks active, request A pending | `selectTab('tasks')` again (request B) and A resolves last | state shows B's result | Task 2 | `test/panel.test.js` |
| S4 | p1 tasks `ready` | select p2 (Tasks active) | `tasks` is `loading` with `data: null` immediately, never p1's data | Task 2 | `test/panel.test.js` |
| S5 | No project selected | `selectTab('tasks')`, then `selectProject('p1')` | no request until p1 selected; then loads | Task 1 | `test/panel.test.js` |
| S6 | Overview active with project | project selected | `getTasks` not called; after `selectTab('tasks')` it is | Task 1 | `test/panel.test.js` |
| S7 | Tasks `ready`, Overview and Tasks tabs | select overview, tasks failed independently | overview slice unaffected by a tasks failure | Task 1 | `test/panel.test.js` |

### Tasks

#### Task 1: Tasks tab loads and exposes its slice

- [ ] **Test file:** `test/panel.test.js` — tests: starts idle with `tasks` slice; `selectTab('tasks')` loads `getTasks(projectId)` -> loading -> ready; failure -> error; no request without a project (S5); Overview active does not call `getTasks` (S6); tasks failure leaves overview slice untouched (S7); `getState().tasks` is a copy.
- [ ] **Production code:** `src/panel.js` — `TABS = ['overview', 'tasks']`, `tasks: emptySlice()`, `getState` copies `tasks`, `loadTasks`, `loadActiveTab` dispatch, `selectProject` resets `tasks`.
- [ ] **Commit:** `feat(panel): add Tasks tab loading api.getTasks`

**Test command:** `node --test test/panel.test.js`

#### Task 2: Tasks results are ignored once superseded

- [ ] **Test file:** `test/panel.test.js` — sequence tests S1, S2, S3, S4 using controllable deferred promises.
- [ ] **Production code:** `src/panel.js` — per-slice request counter (`tasksRequest`), incremented by `loadTasks` and `selectProject`; a result or error is applied and emitted only if its token is still the latest.
- [ ] **Commit:** `feat(panel): ignore superseded Tasks responses`

**Test command:** `node --test test/panel.test.js`

### Verification

**All new tests:** `node --test test/panel.test.js`
**Full suite:** `npm test`

---

## 🚦 Confirmation

CI mode: plan auto-approved.
