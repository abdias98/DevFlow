# Feature Report: Project Panel Tasks Tab

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (CommonJS) · none · node:test

## Summary

**Goal:** Add a Tasks tab to the project panel that loads `api.getTasks(projectId)` into a `tasks` slice (`{ status, data, error }`), selectable with `selectTab('tasks')`, following the Overview conventions.

## Definition of Done

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | `selectTab('tasks')` accepted; `getState().tasks` is `{ status, data, error }`, initially `idle` | ✅ | `starts with an idle tasks slice`; `selecting the tasks tab loads the selected project's tasks`; src/panel.js:13 (`TABS`) |
| 2 | With a project selected and Tasks active, `api.getTasks(projectId)` is called with the selected id; `loading` then `ready` (data) or `error` (error) | ✅ | `selecting the tasks tab loads the selected project's tasks`; `a failed tasks request surfaces an error state`; src/panel.js `loadTasks` |
| 3 | Tasks load only when Tasks is active and a project is selected; selecting a project resets `tasks` | ✅ | `selecting the tasks tab without a project does not load until one is selected`; `tasks are not requested while the overview tab is active`; `selecting another project clears the previous project's tasks immediately` |
| 4 | `npm test` passes with new tests covering the above | ✅ | `npm test`: 19 tests, 19 pass, 0 fail |

**Result:** 4/4 criteria met.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/panel.js` | Modified | `'tasks'` in `TABS`; `tasks` slice; `loadTasks` with a latest-request guard; reset in `selectProject`; `getState` copies the slice |
| `test/panel.test.js` | Modified | 15 new tests (slice, loading, error, gating, isolation, snapshot copy, superseded responses); `fakeApi` gains `getTasks` |

## Tasks Completed

- [x] Task 1: Tasks tab loads and exposes its slice (commit `feat(panel): add Tasks tab loading api.getTasks`)
- [x] Task 2: Tasks results are ignored once superseded (commit `feat(panel): ignore superseded Tasks responses`)

## Behavior Scenarios

| # | Scenario | Test |
|---|----------|------|
| S1 | p1 pending, select p2, p1 resolves late -> p2 data stands | `tasks of a previous project never appear once another project is selected`, `a late tasks response ... does not replace the loading state` |
| S2 | p1 fails late -> no error shown | `a late tasks failure for a previous project does not surface as an error` |
| S3 | tab re-selected, older response last -> newer stands | `when the tasks tab is selected again, the older response cannot overwrite the newer one` |
| S4 | project change resets tasks immediately | `selecting another project clears the previous project's tasks immediately` |
| S5 | no project -> no request | `selecting the tasks tab without a project ...` |
| S6 | Overview active -> no `getTasks` (and vice versa) | `tasks are not requested while the overview tab is active`, `the overview is not requested while the tasks tab is active` |
| S7 | tasks failure does not touch overview | `a failed tasks request leaves the overview slice untouched` |
| (extra) | project replaced while another tab active, pending tasks dropped; no notification for superseded result | `a pending tasks response for a project that was replaced ...`, `subscribers are not notified ...` |

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `test/panel.test.js` | 15 new tests (see above) | ✅ Created, passing |

Note: `selecting another project clears the previous project's tasks immediately` passed on its first run because the reset was already implemented in Task 1; it is kept as the S4 guard. All others were seen failing first.

**Verify with:**
- Single file: `node --test test/panel.test.js`
- Full suite: `npm test`

## Self-Review

| Check | Result |
|-------|--------|
| Security | ✅ no external input, secrets or injection surface |
| Naming conventions | ✅ mirrors `loadOverview` / `overview` |
| SOLID principles | ✅ one added responsibility (Tasks slice) in the existing controller |
| State lifecycle (§4, §6, §7) | ✅ reset before load, latest-request guard, load only when the tab is active |
| Error handling | ✅ failure stored as `error` state, never swallowed; stale failures intentionally dropped |
| Test coverage | ✅ happy, failure, gating and sequence scenarios |
| Lint/typecheck | n/a — project defines none (`node --check src/panel.js` ok) |

## Notes

### Additional Recommendations
- **Overview in-flight guard (backlog D1, info):** `loadOverview` (src/panel.js) has no superseded-result guard. Repro: Overview active, `selectProject('p1')`, `selectProject('p2')`, p1's response resolves last -> p1's overview is stored while p2 is selected (`state-lifecycle.md §6`). Left unchanged because it is outside the request; when it is fixed, the same token mechanism can be shared by both loaders (a third tab would make extracting a helper worthwhile, `design-principles.md §1`).
- Two loaders now differ in behavior (`loadTasks` guarded, `loadOverview` not); the inconsistency is deliberate and recorded above.
